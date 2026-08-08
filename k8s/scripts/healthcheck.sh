#!/usr/bin/env bash
#
# k3s 节点的巡检脚本，由 cron 每 5 分钟跑一次（在节点上，不是开发机）。
#
# 设计要点：这不是"出事发邮件"，而是 dead man's switch（死人开关）。
#   正常 → ping .../<uuid>        服务端看到心跳，安静
#   异常 → ping .../<uuid>/fail   立刻告警，body 里带上失败详情
#   宕机 → 什么都发不出            服务端超时没收到心跳，自动告警  ← 关键
#
# 第三种情况是纯邮件方案覆盖不了的：机器挂了的时候，机器自己发不出邮件。
# 上次磁盘写满、系统濒死那种场景，脚本大概率根本起不来。
#
# 安装（在 k3s 节点上执行）：
#   sudo install -m 755 healthcheck.sh /usr/local/bin/blog-healthcheck
#   # HC_URL 是密钥性质的（拿到就能伪造心跳），放这里，不进 git
#   sudo sh -c 'echo HC_URL=https://hc-ping.com/<你的-uuid> > /etc/blog-healthcheck.env'
#   sudo chmod 600 /etc/blog-healthcheck.env
#   sudo /usr/local/bin/blog-healthcheck   # 先手动跑一次，看输出
#   # 然后加 cron（root 的 crontab）：
#   sudo crontab -e
#   */5 * * * * /usr/local/bin/blog-healthcheck >/dev/null 2>&1
#
# Healthchecks.io 那边把 Period 设成 5 分钟、Grace 设成 5 分钟：
# 连着两次没心跳才告警，避免一次网络抖动就把你吵醒。

set -uo pipefail
# 故意不加 -e：某一项检查失败要继续跑完剩下的，最后一起上报。

export KUBECONFIG=${KUBECONFIG:-/etc/rancher/k3s/k3s.yaml}
export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"

# ---- 可调阈值 ----
DISK_WARN_PCT=${DISK_WARN_PCT:-80}     # 根分区用量超过这个就告警
SITE_URL=${SITE_URL:-https://k8s.vim0.com/}

[ -f /etc/blog-healthcheck.env ] && . /etc/blog-healthcheck.env

FAILURES=0
REPORT=""

log() { REPORT="${REPORT}$*"$'\n'; }
fail() { FAILURES=$((FAILURES + 1)); log "❌ $*"; }
ok()   { log "✅ $*"; }

# ---- 1. 磁盘 ----
# 上次宕机就是这里：buildkit 缓存把根分区吃到 93%，kubelet 触发 DiskPressure，
# 开始驱逐 Pod。等到"网站打不开"才发现就太晚了，80% 就该动手。
DISK_PCT=$(df --output=pcent / | tail -1 | tr -dc '0-9')
if [ "${DISK_PCT:-0}" -ge "$DISK_WARN_PCT" ]; then
  fail "磁盘 / 用量 ${DISK_PCT}%（阈值 ${DISK_WARN_PCT}%）"
  log "$(df -h /)"
  log "--- 根目录下最大的几项 ---"
  log "$(du -xh -d 2 / 2>/dev/null | sort -rh | head -10)"
else
  ok "磁盘 / 用量 ${DISK_PCT}%"
fi

# ---- 2. 节点 ----
# 只要 Ready 就行。注意 grep -c 是数"含 Ready 的行"，NotReady 也含 Ready，
# 所以要匹配带空格的 " Ready"。
NODES=$(kubectl get nodes --no-headers 2>&1)
if [ $? -ne 0 ]; then
  fail "kubectl get nodes 失败（API server 挂了？）"
  log "$NODES"
else
  NOT_READY=$(echo "$NODES" | awk '$2 != "Ready" {print}')
  if [ -n "$NOT_READY" ]; then
    fail "有节点不是 Ready"
    log "$NODES"
  else
    ok "节点全部 Ready"
  fi
fi

# ---- 3. 节点 Condition ----
# DiskPressure/MemoryPressure 是 kubelet 自己的判断，比 df 更贴近"会不会被驱逐"。
# 它有 5 分钟的 eviction-pressure-transition-period，所以清完磁盘也不会立刻转 False。
PRESSURE=$(kubectl get nodes -o json 2>/dev/null | \
  jq -r '.items[] | .metadata.name as $n |
         .status.conditions[] |
         select(.type != "Ready" and .status == "True") |
         "\($n): \(.type)=True"' 2>/dev/null)
if [ -n "$PRESSURE" ]; then
  fail "节点有异常 Condition"
  log "$PRESSURE"
else
  ok "无 DiskPressure / MemoryPressure"
fi

# ---- 4. 博客 Pod ----
# 用 ArgoCD Application 名做 label 选择器（Helm chart 里 instance = release 名）。
BAD_PODS=$(kubectl get pods -n default \
  -l app.kubernetes.io/instance=xiantang-blog \
  --no-headers 2>/dev/null | awk '$3 != "Running"')
READY_PODS=$(kubectl get pods -n default \
  -l app.kubernetes.io/instance=xiantang-blog \
  --no-headers 2>/dev/null | awk '$3 == "Running"' | wc -l)
if [ -n "$BAD_PODS" ] || [ "$READY_PODS" -eq 0 ]; then
  fail "博客 Pod 异常（Running ${READY_PODS} 个）"
  log "$BAD_PODS"
else
  ok "博客 Pod Running ${READY_PODS} 个"
fi

# ---- 5. Evicted 垃圾堆积 ----
# 不算失败，只是提醒。堆到 12500 个（kubelet 默认的 pod GC 阈值）之前该清一清。
EVICTED=$(kubectl get pods -A --field-selector status.phase=Failed \
  --no-headers 2>/dev/null | wc -l)
[ "$EVICTED" -gt 20 ] && log "⚠️  有 ${EVICTED} 个 Failed/Evicted Pod，该清理了"

# ---- 6. 网站本身 ----
# 前面全绿但网站 500 也是有可能的（nginx 配置错、Ingress 路由错），
# 所以最后从外部真实请求一次。--max-time 防止 cron 任务挂死。
CODE=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 15 "$SITE_URL" 2>&1)
if [ "$CODE" = "200" ]; then
  ok "网站 ${SITE_URL} 返回 200"
else
  fail "网站 ${SITE_URL} 返回 ${CODE}"
fi

# ---- 上报 ----
echo "$REPORT"

if [ -z "${HC_URL:-}" ]; then
  echo "（HC_URL 未设置，只在本地打印，不上报）"
  exit $((FAILURES > 0))
fi

if [ "$FAILURES" -gt 0 ]; then
  ENDPOINT="${HC_URL}/fail"
else
  ENDPOINT="${HC_URL}"
fi

# --data-raw 把上面的报告塞进 body，Healthchecks.io 会原样显示在告警里，
# 于是收到通知就已经知道是哪一项挂了，不用先 ssh 上来查。
# -m/--retry：上报本身不能因为一次网络抖动就变成"没心跳"。
curl -fsS -m 10 --retry 3 --data-raw "$REPORT" "$ENDPOINT" >/dev/null

exit $((FAILURES > 0))
