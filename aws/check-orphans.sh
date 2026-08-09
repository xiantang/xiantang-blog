#!/usr/bin/env bash
#
# 孤儿资源巡检 —— 找出"不用也在计费"的东西。
#
# 只读脚本，只跑 describe/list，不删任何东西。看到可疑的自己去删。
#
#   ./aws/check-orphans.sh              # 只查 ap-southeast-1
#   ./aws/check-orphans.sh --all        # 查所有启用的 region（慢，但手滑通常发生在你不看的 region）
#
# S3 是全局服务（桶列表不分 region），所以不管加不加 --all 都只查一遍。
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
PRICE_S3_PER_GB=0.025

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

# S3 单独一个函数，不进 region 循环 —— 桶列表是全局的，
# 塞进循环的话 --all 会把同一个桶报 30 遍。
check_s3() {
  local buckets b br out n bytes gb since now
  local empty_buckets=""

  printf '\n%s\n' "── S3（全局）───────────────────────────────"

  buckets=$(aws_q s3api list-buckets --query 'Buckets[].Name' | tr '\t' '\n')
  if [[ -z "$buckets" ]]; then
    printf '%s\n' "${GRN}✓ 一个桶都没有${OFF}"
    return
  fi

  # CloudWatch 的 BucketSizeBytes 是【每天一个点】的指标，所以要往回捞两天，
  # 取最后一个数据点。比 list-objects 累加快几个数量级，而且不花钱
  # （GetMetricStatistics 每月前 100 万次请求免费）。
  since=$(date -u -d '2 days ago' +%Y-%m-%dT%H:%M:%SZ)
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  for b in $buckets; do
    # 桶的 region 要单独查：分段上传和 CloudWatch 都必须打到桶所在的 region。
    # us-east-1 的 LocationConstraint 是空的（历史原因），CLI 会返回 None。
    br=$(aws_q s3api get-bucket-location --bucket "$b" --query LocationConstraint)
    [[ -z "$br" || "$br" == "None" ]] && br="us-east-1"

    # ① 未完成的分段上传 —— S3 最隐蔽的浪费。
    # 上传中断后分片留在桶里，【控制台的对象列表看不到】，但照常按存储计费。
    out=$(aws_q s3api list-multipart-uploads --bucket "$b" --region "$br" \
      --query 'Uploads[].[Initiated,Key]')
    if [[ -n "$out" ]]; then
      n=$(wc -l <<<"$out")
      hit "✗ ${b} (${br})：未完成的分段上传 × ${n}"
      sed 's/^/    /' <<<"$out" | head -5
      [[ $n -gt 5 ]] && note "    …还有 $((n - 5)) 个"
      note "    这些分片在控制台对象列表里看不到。大小要 list-parts 逐个查，未计入下方估算。"
      note "    清掉：aws s3api abort-multipart-upload --bucket ${b} --key <key> --upload-id <id>"
      note "    治本：给桶加一条 AbortIncompleteMultipartUpload 的 lifecycle 规则，让它自动过期"
      findings=$((findings + n))
    fi

    # ② 桶大小。不是"孤儿"，但一个在悄悄长大又没人看的桶，
    # 和 2026-08-03 那次磁盘写满是同一类问题：缓慢增长 + 无人监视。
    bytes=$(aws_q cloudwatch get-metric-statistics --region "$br" \
      --namespace AWS/S3 --metric-name BucketSizeBytes \
      --dimensions Name=BucketName,Value="$b" Name=StorageType,Value=StandardStorage \
      --start-time "$since" --end-time "$now" --period 86400 \
      --statistics Average --query 'Datapoints[-1].Average')

    if [[ -z "$bytes" || "$bytes" == "None" ]]; then
      # 新建的桶还没有指标（CloudWatch 每天才出一个点），空桶也一样。
      empty_buckets+="    ${b} (${br})"$'\n'
      continue
    fi

    gb=$(calc "$bytes / 1073741824")
    # 只有超过 1GB 才值得说 —— 再小的桶，存储费还不够看一眼的时间成本。
    if awk "BEGIN{exit !($gb > 1)}"; then
      note "· ${b} (${br})  ${gb} GB  ~\$$(calc "$gb * $PRICE_S3_PER_GB")/月"
      # 没有生命周期规则 = 这个桶只会一直涨。查不到规则时 CLI 报错，aws_q 吞掉后返回空。
      if [[ -z "$(aws_q s3api get-bucket-lifecycle-configuration --bucket "$b" --region "$br" --query 'Rules[].ID')" ]]; then
        note "    ↑ 没有 lifecycle 规则，只进不出"
      fi
    fi
  done

  if [[ -n "$empty_buckets" ]]; then
    note "空桶 / 无 CloudWatch 数据（不计费，仅列出）："
    printf '%s' "$empty_buckets"
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

check_s3

printf '\n────────────────────────────────────────\n'
if [[ $findings -eq 0 ]]; then
  printf '%s\n' "${GRN}没有发现孤儿资源。${OFF}"
else
  printf '%s\n' "${YEL}发现 ${findings} 项，粗估 ~\$${est_total}/月。${OFF}"
  printf '%s\n' "${DIM}单价是量级估算，不是账单。准确数字看 Cost Explorer（README「按服务查开销」一节）。${OFF}"
fi

# 注意：EC2 实例本身不在这个列表里 —— 它不是"孤儿"，是你有意开的。
# 想知道钱花在哪，那是 Cost Explorer 的活；这个脚本只管"我是不是忘了什么东西没删"。
