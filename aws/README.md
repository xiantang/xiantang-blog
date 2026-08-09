# `aws/`

账号级的配置，**不由 ArgoCD 管理** —— 这些是 AWS 资源，不是 k8s 对象。
放在这里是为了让配置有个可读、可 diff 的出处，以后转 Terraform 时直接就是
对应资源的输入。

下发一律手动，改了不会自动生效。

| 文件 | 对应资源 |
|---|---|
| `ecr-lifecycle-policy.json` | `xiantang-blog` 仓库的生命周期策略 |
| `budget.json` + `budget-notifications.json` | 成本异常告警（gross 口径，$60/月） |
| `budget-net-tripwire.json` + `budget-net-tripwire-notifications.json` | credit 烧完的绊线（net 口径，$5/月） |

## 成本护栏（AWS Budgets）

账号的成本护栏，也是笔记本上那把 `AdministratorAccess` access key 的兜底：
key 要是泄漏被拿去挖矿，这是你**唯一**会知道的途径。

用 Budgets 而不是 CloudWatch Alarm 的原因：Budgets 除了当月实际花费，还会算
**预测的月末花费** —— 挖矿在第 3 天就能触发 FORECASTED 告警，而
CloudWatch 的 `EstimatedCharges` 要等实际累计真的超标才响。

### 两个 budget，口径相反

| budget | 口径 | 额度 | 作用 |
|---|---|---|---|
| `monthly-gross-spend` | **gross**（`IncludeCredit: false`） | $60 | 异常检测：挖矿、手滑建 NAT Gateway |
| `net-spend-tripwire` | **net**（`IncludeCredit: true`） | $5 | **credit 烧完的绊线** |

为什么要两个 —— 这是 2026-08-09 排查出来的，值得写清楚：

账号现在有 credit，**实付是 $0，但真实用量约 $40/月**。gross 那个 budget 报的是
$40（因为它不看抵扣），这正是我们要的信号：credit 会用完，到时候 $40 就是真金白银。

但也正因为它不看抵扣，**credit 烧完的那天它的数字不会有任何变化** —— 之前 $40，
之后还是 $40。用量没变，变的是谁在付。光靠它，你只会在收到第一张真实账单时才发现。

所以加了第二个，口径相反：net 口径在 credit 用完前永远是 $0，从不打扰；
credit 一断，当月净额爬过 $5 立刻响。**「开始真的花钱了」这个事件需要它自己的探针。**

⚠️ **前 2 个 budget 免费**，之后 $0.02/天/个（约 $0.60/月）。正好用满，不多花钱。

### 额度是怎么定的

**gross $60**：真实速率 $40/月，留 1.5 倍余量。

⚠️ 一开始设的是 $20，**这是错的** —— 低于正常速率意味着 ACTUAL 100% 每个月固定触发。
**每月必响的告警等于没有告警**：三个月后你会条件反射删掉它，然后真出事那次也一起删了。
告警阈值必须设在「正常情况下不会响」的地方，否则它训练你忽略它。

**net $5**：只要不是 $0 就说明 credit 没了，$5 是防止零星尾数误报的缓冲。

### 下发

```bash
# Budgets 是全局服务，endpoint 固定在 us-east-1（跟资源在哪个 region 无关，
# 写成 ap-southeast-1 会直接报错）
# 邮箱不写进仓库（公开仓库），apply 时替换进去
sed 's/__EMAIL__/你的邮箱/' aws/budget-notifications.json > /tmp/n1.json
sed 's/__EMAIL__/你的邮箱/' aws/budget-net-tripwire-notifications.json > /tmp/n2.json

aws budgets create-budget --account-id 521218410956 --region us-east-1 \
  --budget file://aws/budget.json \
  --notifications-with-subscribers file:///tmp/n1.json

aws budgets create-budget --account-id 521218410956 --region us-east-1 \
  --budget file://aws/budget-net-tripwire.json \
  --notifications-with-subscribers file:///tmp/n2.json

rm /tmp/n1.json /tmp/n2.json
```

⚠️ **`create-budget` 不幂等**，对已存在的 budget 报 `DuplicateRecordException`。
改额度用 `update-budget`；**改名字只能删了重建**（名字是主键）：

```bash
# 早期那个 monthly-20-usd 已经改名成 monthly-gross-spend，要先删掉旧的
aws budgets delete-budget --account-id 521218410956 \
  --budget-name monthly-20-usd --region us-east-1

aws budgets update-budget --account-id 521218410956 --region us-east-1 \
  --new-budget file://aws/budget.json
```

（budget 名字里刻意不写金额 —— 写了的话每次调额度都得删了重建。）

核对：

```bash
aws budgets describe-budgets --account-id 521218410956 --region us-east-1 \
  --query 'Budgets[].{Name:BudgetName,Limit:BudgetLimit.Amount,Actual:CalculatedSpend.ActualSpend.Amount,Forecast:CalculatedSpend.ForecastedSpend.Amount}' \
  --output table

aws budgets describe-notifications-for-budget --account-id 521218410956 \
  --budget-name monthly-gross-spend --region us-east-1 \
  --query 'Notifications[].{Type:NotificationType,Threshold:Threshold}' --output table
```

### gross budget 的三条告警

| 类型 | 阈值 | 意义 |
|---|---|---|
| ACTUAL | 50%（$30） | 早期信号 |
| ACTUAL | 100%（$60） | 已经超了 |
| **FORECASTED** | 100%（$60） | **按当前速率月末会超** ← 最有价值的一条 |

### 几个要知道的前提

⚠️ **不是实时的。** Budgets 的数据来自账单系统，**8～12 小时刷新一次**。
被拿去开一堆 GPU 实例的话，等你收到邮件可能已经烧掉几百刀了。
这是**事后兜底，不是实时防御** —— 真正的防线是给 root 和 `Jed` 开 MFA、
以及别把长期 access key 放在笔记本上。这两件都还欠着，见 `TODO.md`。

⚠️ **邮件不需要确认。** 跟 SNS 订阅不一样，Budgets 的邮件订阅直接生效，
没有「点链接确认」那一步 —— 所以**地址写错了不会有任何提示**，
告警会安静地发到不存在的邮箱。下发完照着上面的命令核对一遍。

⚠️ **FORECASTED 需要历史数据才准。** 新账号或刚变更过用量时 AWS 样本不够，
这条可能一开始不触发（`describe-budgets` 里 `ForecastedSpend` 是空的）。
跑满一两个账期后才可靠。

---

## 成本构成与 credit 跑道（2026-08-09 实测）

### 钱花在哪

8 月 1–9 日，**gross** 口径：

| 服务 | 9 天 | 折月 | 占比 |
|---|---|---|---|
| **EC2 Compute** | $10.57 | ~$36 | **91%** |
| VPC（公网 IPv4 地址费） | $0.55 | ~$1.9 | 5% |
| EC2 - Other（28G EBS） | $0.55 | ~$1.9 | 5% |
| ECR | $0.008 | ~$0.03 | ~0 |

**实例本身就是全部。** ECR、S3 加起来一个月三分钱 —— ECR 生命周期策略在成本上
几乎没意义（它防的是「几年后积累几十 GB」，那个价值仍在，但别指望它省钱）。

VPC 那笔是 **公网 IPv4 地址费**：2024 年 2 月起 AWS 对每个公网 IPv4 收
$0.005/小时，**包括正在使用的**。你需要公网 IP，这笔避不掉；
但**多出来一个未关联的 EIP 就是纯浪费**，值得定期查。

### ⏰ credit 什么时候烧完

```
余额 $106.49 ÷ 燃烧速率 $1.30/天 ≈ 82 天
```

**≈ 2026-10-30 见底。** 控制台显示的「180 天后过期」（2027-02）轮不到 ——
**先烧完，而不是先过期**。那天起账单从 $0 变成约 $40/月。

查余额（**没有 CLI/API，只能看控制台**）：
`Billing and Cost Management → Credits`，看 Amount Remaining 和 Expiration Date。

### 2026-10-30 之前要做的决定

**为了学习，值不值得每月付 $40？**

- 值 → 签 1 年期 Compute Savings Plan（省三成左右，$36 → ~$25），或者降配
- 不值 → 把 k3s 和 EKS 练习都改成「用完就 destroy」，只在动手时开机

⚠️ **现在别签 Savings Plan。** 一年期锁定的前提是「我确定一年后还要这台机器」，
而 ROADMAP Phase 9/10 要用 Terraform 重建、上 EKS —— 基础设施在未来半年会变形。
credit 期间实付 $0，提前签也不会更省。**这 82 天是用来做决定的，不是用来做承诺的。**

⚠️ 降配要小心：`TODO.md` 里记过「76% 内存被 k8s 控制面吃掉」。
降到 2G 大概率跑不动 k3s + cert-manager + ArgoCD，**别为了省钱把学习环境搞崩**。

### 为什么 budget 和 Cost Explorer 对不上

排查时踩的坑，记下来免得重踩：`describe-budgets` 说花了 $12.43，
`get-cost-and-usage` 说花了 $0.0003。差四个数量级。

原因是**两边默认口径相反**：

- `get-cost-and-usage` **默认把 credit 算进去**（净额）→ 用量 +11.67、抵扣 −11.67 ≈ 0
- 我们的 budget 设了 `IncludeCredit: false`（gross）→ 报 $12.43

拆开验证（`RECORD_TYPE` 分组是关键）：

```bash
aws ce get-cost-and-usage --time-period Start=2026-08-01,End=2026-08-10 \
  --granularity MONTHLY --metrics UnblendedCost \
  --group-by Type=DIMENSION,Key=RECORD_TYPE --region us-east-1 \
  --query 'ResultsByTime[0].Groups[].{Type:Keys[0],Cost:Metrics.UnblendedCost.Amount}' \
  --output table
```

只看真实用量，要显式过滤掉 credit：

```bash
aws ce get-cost-and-usage --time-period Start=2026-08-01,End=2026-08-10 \
  --granularity MONTHLY --metrics UnblendedCost \
  --filter '{"Dimensions":{"Key":"RECORD_TYPE","Values":["Usage"]}}' \
  --group-by Type=DIMENSION,Key=SERVICE --region us-east-1 \
  --query 'ResultsByTime[0].Groups[].{Service:Keys[0],Cost:Metrics.UnblendedCost.Amount}' \
  --output table
```

⚠️ **Cost Explorer API 每次调用收 $0.01**（控制台界面免费）。
查账单本身要钱 —— 别写进循环或监控脚本。

⚠️ `ce` 和 `budgets` 一样是全局服务，`--region us-east-1` 是必须的。

---

## ECR 生命周期策略

CI 每次提交都推一个新镜像，ECR 存储约 $0.10/GB/月，只增不减。这个策略负责收尾。

⚠️ **先 preview，再 apply。过期是不可逆的。**

```bash
# 1. 预览会删掉哪些（不实际删除）
aws ecr start-lifecycle-policy-preview \
  --repository-name xiantang-blog \
  --lifecycle-policy-text "$(cat aws/ecr-lifecycle-policy.json)"

# 稍等几秒，看结果
aws ecr get-lifecycle-policy-preview \
  --repository-name xiantang-blog \
  --query 'previewResults[].{Tags:imageTags,Action:action.type}' --output table

# 2. 确认无误后正式生效
aws ecr put-lifecycle-policy \
  --repository-name xiantang-blog \
  --lifecycle-policy-text "$(cat aws/ecr-lifecycle-policy.json)"
```

查看当前生效的策略：

```bash
aws ecr get-lifecycle-policy --repository-name xiantang-blog \
  --region ap-southeast-1 --query 'lifecyclePolicyText' --output text | jq
```

### 两条规则的取舍

**规则 1（untagged）** 原本清理的是 `latest` 被覆盖后留下的孤儿镜像 —— CI 每次
构建都把 `latest` 指向新镜像，旧的那个就失去了所有标签。现在 CI 不推 `latest`
了，这条基本不会再命中，留着是兜底（比如手动推错一个 tag 之后重推）。

⚠️ **未解决的问题：这条规则可能会打断多架构镜像。**

镜像是 `linux/amd64,linux/arm64` 一起推的，一次构建在 ECR 里是**三个条目**
（2026-08-09 实测，时间戳相差不到一秒）：

```
14:09:42.130   Tags: None                       ← 平台镜像
14:09:42.759   Tags: None                       ← 平台镜像
14:09:43.401   Tags: ['sha-03086bc8...']        ← manifest list，只有它带 tag
```

两个平台镜像**自己没有 tag**。如果 ECR 把它们当成普通 untagged 并按这条规则
删掉，manifest list 就会指向不存在的层 —— tag 还在，但拉不下来。
已经在节点上的镜像不受影响，**新 Pod、扩容、重启会全部挂在拉取失败上**。

**间接证据倾向于 ECR 会保护它们**：仓库里现在有 104 个镜像，其中只有约 20 个
带 tag（规则 2 的上限），剩下 80 多个无 tag 的如果真被每天清理，不可能积到这个量。
但策略是异步执行的（约每 24 小时一轮），也可能只是还没轮到。

**没有定论之前不要改这条规则。** 要确认就跑 preview，它会列出具体 digest：

```bash
aws ecr start-lifecycle-policy-preview --repository-name xiantang-blog \
  --region ap-southeast-1 \
  --lifecycle-policy-text "$(cat aws/ecr-lifecycle-policy.json)"

aws ecr get-lifecycle-policy-preview --repository-name xiantang-blog \
  --region ap-southeast-1 \
  --query 'previewResults[].{Tags:imageTags,Action:action.type,Rule:appliedRulePriority}' \
  --output table
```

判读：**preview 里出现无 tag 的条目 = 危险**，规则 1 得改（最省事的做法是直接
删掉它 —— 现在不推 `latest` 了，它本来就没什么可清理的）。
**只列出老的带 tag 镜像 = 当前配置安全**，把这段结论改成确定的。

**规则 2（保留 20 个）** 是回滚窗口。`git revert` 一个旧 commit 会把
`appVersion` 指回那个 `sha-`，如果对应镜像已经被清掉，回滚就会失败在
`ImagePullBackOff`。20 次提交按当前节奏够用几周。

⚠️ **ECR 不知道哪个镜像正在被集群使用。** 生命周期策略纯粹按时间和数量算，
不会因为「这个镜像正跑在生产上」而跳过它。目前安全是因为
`appVersion` 每次提交都会更新，线上跑的永远是最新的那个 ——
**但如果哪天你长期停在一个旧版本上不发布，然后又推了 20 次别的提交，
那个正在服务的镜像会被删掉。**（已经拉到节点上的镜像不受影响，
但新 Pod 起不来，扩容和重启会挂。）

真要固定在旧版本运行，先把 `countNumber` 调大，或者给那个 tag 单独加一条
保留规则。

### IMMUTABLE 标签（已开启，2026-08-09）

仓库现在是 `IMMUTABLE`：**同一个 tag 不许覆盖推送**。这样「`Chart.yaml` 里写的
`sha-abc` 指向哪个镜像」由 ECR 从服务端保证，不再只是一个约定 ——
`helm rollback` 和 `git revert` 能真正工作的前提。

```bash
# 确认当前状态
aws ecr describe-repositories --repository-names xiantang-blog \
  --region ap-southeast-1 --query 'repositories[0].imageTagMutability' --output text
```

开启的前提是先去掉 CI 里的 `latest`（`fa95a73e`）——「同一个 tag 不许覆盖」和
「`latest` 天生要被覆盖」互斥，不去掉的话每次构建都会挂在 push 阶段。

⚠️ **在 GitHub Actions 页面点 "Re-run jobs" 重跑同一个 commit 会失败**，
报 `ImageTagAlreadyExistsException`。**这是预期行为，不是 CI 坏了。**
真需要重推同一个 tag，只能先删掉旧的：

```bash
aws ecr batch-delete-image --repository-name xiantang-blog --region ap-southeast-1 \
  --image-ids imageTag=sha-<那个commit>
```

⚠️ **GHCR 那边不受影响**，仍然是可变的。回退路径（把 `values.yaml` 的
`repository` 改回 GHCR）还在，但那条路上没有这层保证。

历史上那个 `latest` tag 不用特意处理：它挂在某个 `sha-` 镜像上，
等规则 2 把那个镜像淘汰掉时会一起消失。
