#!/usr/bin/env bash
#
# 孤儿资源巡检 —— 找出"不用也在计费"的东西。
#
# 只读脚本，只跑 describe/list，不删任何东西。看到可疑的自己去删。
#
#   ./aws/check-orphans.sh              # 只查 ap-southeast-1
#   ./aws/check-orphans.sh --all        # 查所有启用的 region（慢，但手滑通常发生在你不看的 region）
#
# 环境变量：
#   AWS_PROFILE   默认 blog
#
set -uo pipefail

PROFILE="${AWS_PROFILE:-blog}"
HOME_REGION="ap-southeast-1"

# 粗略单价（USD/月，ap-southeast-1 量级，只用于让数字有体感，不是账单）
PRICE_EIP=3.6        # $0.005/h
PRICE_NAT=33         # $0.045/h，不含 $0.045/GB 处理费
PRICE_ALB=16         # $0.0225/h，不含 LCU
PRICE_EKS=73         # $0.10/h，零节点也收
PRICE_EBS_PER_GB=0.10

RED=$'\033[31m'; YEL=$'\033[33m'; GRN=$'\033[32m'; DIM=$'\033[2m'; OFF=$'\033[0m'

findings=0
est_total=0

note() { printf '%s\n' "${DIM}$*${OFF}"; }
hit()  { findings=$((findings + 1)); printf '%s\n' "${RED}$*${OFF}"; }
# 用 awk 而不是 bc —— bc 不是所有机器都装了
calc() { awk "BEGIN{printf \"%.2f\", $1}"; }

aws_q() { aws --profile "$PROFILE" --output text "$@" 2>/dev/null; }

check_region() {
  local region="$1"
  local region_findings=0
  local out

  printf '\n%s\n' "── ${region} ────────────────────────────────"

  # 1. 未关联的 Elastic IP —— 最纯粹的浪费，删了没有任何副作用
  out=$(aws_q ec2 describe-addresses --region "$region" \
    --query 'Addresses[?AssociationId==`null`].[PublicIp,AllocationId]')
  if [[ -n "$out" ]]; then
    local n; n=$(wc -l <<<"$out")
    hit "✗ 未关联的 Elastic IP × ${n}  (~\$$(calc "$n * $PRICE_EIP")/月)"
    sed 's/^/    /' <<<"$out"
    region_findings=$((region_findings + n))
    est_total=$(calc "$est_total + $n * $PRICE_EIP")
  fi

  # 2. available 状态的 EBS 卷 —— 没挂在任何实例上。删实例时数据卷默认不跟着删
  out=$(aws_q ec2 describe-volumes --region "$region" \
    --filters Name=status,Values=available \
    --query 'Volumes[].[VolumeId,Size,VolumeType,CreateTime]')
  if [[ -n "$out" ]]; then
    local n gb; n=$(wc -l <<<"$out"); gb=$(awk '{s+=$2} END{print s+0}' <<<"$out")
    hit "✗ available 状态的 EBS 卷 × ${n}，共 ${gb} GB  (~\$$(calc "$gb * $PRICE_EBS_PER_GB")/月)"
    sed 's/^/    /' <<<"$out"
    note "    删之前先确认不需要：aws ec2 create-snapshot --volume-id <id> 可以先留个快照"
    region_findings=$((region_findings + n))
    est_total=$(calc "$est_total + $gb * $PRICE_EBS_PER_GB")
  fi

  # 3. NAT Gateway —— Terraform 的 VPC module 默认建，且每 AZ 一个
  out=$(aws_q ec2 describe-nat-gateways --region "$region" \
    --filter Name=state,Values=available \
    --query 'NatGateways[].[NatGatewayId,VpcId]')
  if [[ -n "$out" ]]; then
    local n; n=$(wc -l <<<"$out")
    hit "✗ NAT Gateway × ${n}  (~\$$(calc "$n * $PRICE_NAT")/月 + 流量费)"
    sed 's/^/    /' <<<"$out"
    region_findings=$((region_findings + n))
    est_total=$(calc "$est_total + $n * $PRICE_NAT")
  fi

  # 4. 负载均衡器 —— 没有任何请求也照收小时费
  out=$(aws_q elbv2 describe-load-balancers --region "$region" \
    --query 'LoadBalancers[].[LoadBalancerName,Type,State.Code]')
  if [[ -n "$out" ]]; then
    local n; n=$(wc -l <<<"$out")
    hit "✗ 负载均衡器 × ${n}  (~\$$(calc "$n * $PRICE_ALB")/月 起)"
    sed 's/^/    /' <<<"$out"
    region_findings=$((region_findings + n))
    est_total=$(calc "$est_total + $n * $PRICE_ALB")
  fi

  # 5. EKS 集群 —— 控制面按集群收费，零节点的空集群也是全价
  out=$(aws_q eks list-clusters --region "$region" --query 'clusters[]')
  if [[ -n "$out" ]]; then
    local n; n=$(wc -w <<<"$out")
    hit "✗ EKS 集群 × ${n}  (~\$$(calc "$n * $PRICE_EKS")/月，零节点也收)"
    tr '\t' '\n' <<<"$out" | sed 's/^/    /'
    region_findings=$((region_findings + n))
    est_total=$(calc "$est_total + $n * $PRICE_EKS")
  fi

  if [[ $region_findings -eq 0 ]]; then
    printf '%s\n' "${GRN}✓ 干净${OFF}"
  fi
}

# ── main ──────────────────────────────────────────────

if ! aws --profile "$PROFILE" sts get-caller-identity >/dev/null 2>&1; then
  printf '%s\n' "${RED}凭据不可用：profile=${PROFILE}${OFF}" >&2
  printf '%s\n' "检查 ~/.aws/credentials，或换一个：AWS_PROFILE=xxx $0" >&2
  exit 1
fi

acct=$(aws_q sts get-caller-identity --query Account)
printf '账号 %s / profile %s\n' "$acct" "$PROFILE"

if [[ "${1:-}" == "--all" ]]; then
  regions=$(aws_q ec2 describe-regions --region "$HOME_REGION" \
    --query 'Regions[].RegionName' | tr '\t' '\n' | sort)
  note "扫描所有启用的 region（$(wc -l <<<"$regions") 个），会比较慢…"
else
  regions="$HOME_REGION"
  note "只扫 ${HOME_REGION}。加 --all 扫全部 —— 手滑通常发生在你不常看的 region。"
fi

for r in $regions; do
  check_region "$r"
done

printf '\n────────────────────────────────────────\n'
if [[ $findings -eq 0 ]]; then
  printf '%s\n' "${GRN}没有发现孤儿资源。${OFF}"
else
  printf '%s\n' "${YEL}发现 ${findings} 项，粗估 ~\$${est_total}/月。${OFF}"
  printf '%s\n' "${DIM}单价是量级估算，不是账单。准确数字看 Cost Explorer（README「按服务查开销」一节）。${OFF}"
fi

# 注意：EC2 实例本身不在这个列表里 —— 它不是"孤儿"，是你有意开的。
# 想知道钱花在哪，那是 Cost Explorer 的活；这个脚本只管"我是不是忘了什么东西没删"。
