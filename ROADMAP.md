# 🚀 vim0.com Cloud Native Roadmap

> 在 AWS 上用 Kubernetes / GitOps / IaC 搭一套生产级平台。
>
> 最后更新:2026-08-09

**Target Stack**:AWS · EKS · Terraform · Argo CD · GitHub Actions · Helm ·
Prometheus · Grafana · Loki · cert-manager

---

## 两条贯穿全程的原则

**1. 成本是一等公民,不是脚注**

EKS 那套组合(控制面 + NAT Gateway + ALB + 节点组)默认路径是 **~$180/月**。
在碰任何 EKS 相关的东西之前,预算告警必须先就位。见 [成本](#成本)。

**2. EKS 是可销毁的练习环境,不是博客的归宿**

博客留在现有的 k3s 上(月费十几刀,已经跑得很稳)。EKS 单独建、练完 `destroy`。
两边共用同一个 Helm chart —— chart 已经参数化了,换 values 就行。

这样做的好处:站点不会因为学习而不稳定;没有"迁完了不敢拆"的心理负担;
而且**对比着看**才能分清哪些是 k8s 本身、哪些是 AWS 的特化(VPC CNI、IRSA、
ALB Controller、EBS CSI)。

---

## 现状快照

| | |
|---|---|
| 集群 | 单节点 **k3s**,跑在一台 EC2 上 |
| Ingress | **Traefik**(k3s 自带),**不是** ingress-nginx |
| 镜像 | **ECR**(集群拉这个)+ GHCR(同步推,留作回退),tag 只有不可变的 `sha-<完整commit>` |
| 部署 | Helm chart(`k8s/charts/blog/`)+ Argo CD 自动同步 |
| 发布 | CI 构建后自动回填 `Chart.yaml` 的 `appVersion` → **push 即上线** |
| TLS | cert-manager + Let's Encrypt,Cloudflare DNS-01 |
| 域名 | `k8s.vim0.com`(k3s)、`vim0.com`(GitHub Pages) |

未完成的具体事项见 `TODO.md`,这份文件只管学习路线。

---

# Phase 0 — AWS 基础与成本护栏

## 账号

- [x] 创建 AWS 账号
- [x] 开启 MFA
- [x] 创建 IAM User(不用 root)
- [x] 安装并配置 AWS CLI
- [x] 了解 Region / AZ

## 💰 成本护栏 ← 新增,做 Phase 9 之前必须完成

- [x] **AWS Budgets 告警**(邮件通知)—— 建了**两个,口径相反**,配置见 `aws/README.md`
      - `monthly-gross-spend` $60,不看抵扣 → 异常检测(挖矿、手滑建 NAT)
      - `net-spend-tripwire` $5,看抵扣 → **credit 烧完的绊线**
      两个都要,因为 gross 那个在 credit 用完时数字不会变(用量没变,变的是谁在付)。
      **一开始设的 $20 是错的**:低于 $40 的正常速率 → 每月必响 → 三个月后你会
      条件反射删掉它,连带真出事那次。**阈值必须设在正常情况下不会响的地方。**
- [x] 会用 Cost Explorer 按服务查开销
      `aws ce get-cost-and-usage`。**坑**:它默认把 credit 净掉,所以有抵扣时
      按服务查全是 0 —— 要 `--filter RECORD_TYPE=Usage` 才看得到真实用量。
      **每次调用收 $0.01**,别写进脚本。
- [x] 知道哪些资源"不用也在计费":EKS 控制面、NAT Gateway、
      ALB、未挂载的 EBS 卷、未关联的 Elastic IP
      补一个 2024 年新增的:**公网 IPv4 地址 $0.005/小时,正在用的也收**
      (本账号里就是那笔挂在 VPC 名下的 ~$1.9/月)。
- [ ] 定期检查孤儿资源(`available` 状态的 EBS 卷是最常见的)
      工具有了:`./aws/check-orphans.sh`(只读,查 EIP / EBS / NAT / LB / EKS / S3 六类,
      `--all` 扫全 region)。**打勾的条件是养成习惯,不是有脚本** —— 至少手动跑过
      一轮 `--all`,确认基线是干净的。

> ⏰ **2026-10-30:credit 见底**(余额 $106.49 ÷ $1.30/天 ≈ 82 天,算于 2026-08-09)。
> 控制台写的「180 天后过期」轮不到 —— 先烧完。那天起账单从 $0 变成约 **$40/月**,
> 其中 **91% 是 EC2 实例本身**。
>
> 在那之前要回答:**为了学习,值不值得每月付 $40?** 值就签 Savings Plan 或降配,
> 不值就把 k3s 和 EKS 都改成「用完就 destroy」。**别现在签一年期** ——
> Phase 9/10 要用 Terraform 重建、上 EKS,基础设施半年内会变形。

> **为什么排这么前**:之前还在算 30GB EBS 会不会超免费额度,
> 而 EKS 那套默认路径是每月两百刀。没有告警的话,发现时已经是账单了。

---

# Phase 1 — Dockerize

- [x] 写 Dockerfile
- [x] 多阶段构建
- [x] `docker build` / `docker run`
- [x] 多架构构建(amd64 + arm64)

**注**:仓库里有两个 Dockerfile。`Dockerfile` 是本地开发用(`hugo server` +
挂载源码),`Dockerfile.k8s` 是生产用(Hugo 编译成静态文件 → nginx)。

---

# Phase 2 — Kubernetes 基础

- [x] k3s 装起来
- [x] Namespace
- [x] Deployment / ReplicaSet
- [x] Service
- [x] Liveness / Readiness Probe
- [x] Secret(cert-manager 的 Cloudflare token、TLS 证书)
- [ ] **ConfigMap** ← 还没做
- [ ] **PersistentVolume / PVC** ← 还没做

> **修正**:原计划把 ConfigMap 和 PV/PVC 勾了,但实际都没碰过。
> nginx.conf 现在是**烤进镜像**的,改一行配置要重新构建整个镜像。
>
> 抽成 ConfigMap 会顺带学到 `checksum/config` annotation —— 配置变了
> 怎么让 Pod 自动重启(改 ConfigMap 不会自动重启 Pod,这是 k8s 的通用行为)。
>
> PV/PVC 博客用不上(无状态),但迟早会遇到有状态应用。可以拿别的东西练,
> 别用假的 ✅ 把它盖过去。

---

# Phase 3 — Ingress

- [x] Host 规则
- [x] TLS
- [x] 通过 Ingress 访问站点
- [ ] Path 规则 / Rewrite 规则 ← 没配过
- [ ] **对比 ingress-nginx 和 Traefik** ← 原计划写的是装 ingress-nginx

> **修正**:实际用的是 k3s 自带的 **Traefik**,不是 ingress-nginx。
> 两者的 annotation 体系差别不小,换的时候要重写。
>
> 不用特意去装 ingress-nginx —— 等 Phase 10 上 EKS 时会用 ALB Controller,
> 那时候正好三者对比。

---

# Phase 4 — GitHub Actions

- [x] 构建镜像并推送
- [x] GHCR
- [x] AWS ECR(OIDC 联合身份,没有长期凭据)
- [x] 多架构构建
- [x] `paths-ignore` 避免无谓构建
- [x] 构建后自动回填 chart 的 `appVersion`
- [ ] Run Tests ← Hugo 站点没什么可测的,`checker.yml` 是死链检查不算测试

---

# Phase 5 — Helm

- [x] Chart 结构、`values.yaml`、模板语法
- [x] `_helpers.tpl` 与 label 设计
- [x] Release 管理:`install` / `upgrade` / `diff` / `history` / `rollback`
- [x] 镜像 tag 不可变(干掉 `:latest`)

> **踩过的坑**(细节见 `TODO.md` 和各 commit message):
> `--set` 的值会**永久留在 release 里**,要 `--reset-values` 才清得掉;
> `helm diff` 默认不看 live 状态;`spec.selector` 是不可变字段,
> selector labels 里绝不能放会变的东西。

---

# Phase 6 — Argo CD

- [x] 安装(版本钉死,不用 `stable`)
- [x] Application
- [x] Sync / Auto Sync / selfHeal / prune
- [x] Rollback
- [x] Health Status
- [x] **Ingress** —— `argocd.vim0.com`(`k8s/argocd/ingress.yaml`)。
      要点:ArgoCD server 必须先跑在 `--insecure` 下,否则它自己也做 HTTPS 跳转,
      和 Traefik 的终止叠在一起变成重定向死循环。
- [x] GitHub webhook(把 3 分钟轮询变成秒级)
- [x] **让 Argo CD 管理它自己**(app-of-apps)
      `k8s/argocd/root-application.yaml`。**坑**:别在 spec 里写等于默认值的字段
      (比如 `directory.recurse: false`)—— ArgoCD 存 spec 时会丢掉它们,git 里有、
      集群里没有,`root` 会永久 OutOfSync 且 sync 多少次都好不了。

> **踩过的坑**:装的时候要 `kubectl apply --server-side`(ApplicationSet 的
> CRD 会撞 annotation 256KB 上限);Application 的名字同时充当 Helm release 名
> **和**资源追踪 label,而那个 label 在 Deployment 的不可变 selector 里 ——
> 名字起错会导致渲染出一整套新资源。
>
> **Argo CD 不用 Helm 安装**,它跑 `helm template` 再自己 apply。
> 所以集群里没有 Helm release,`helm list` 是空的。

---

# Phase 7 — 基础监控告警 ← 从原 Phase 14 提前

**不是**完整的 Prometheus 栈,就是"挂了我能立刻知道"。

- [x] cron + 邮件:定时检查 `df -h` 和 `kubectl get nodes`
      `k8s/scripts/healthcheck.sh`,六项检查。**告警链路实测过**(临时把阈值设成 1%)。
- [x] 站点可用性外部探测 —— Healthchecks.io,**dead man's switch**:
      脚本主动上报「我还活着」,超时不报到才告警。这比「出事了发邮件」强的地方在于
      **机器彻底挂了就发不出邮件**,而没上报本身就是信号。
- [x] 调小 pod GC 阈值,让 Evicted Pod 自动清理
      `terminated-pod-gc-threshold` 默认 12500(等于形同虚设)。改在
      `/etc/rancher/k3s/config.yaml`,**不是**改 systemd unit。

> **为什么提前**:2026-08-03 23:02 根卷用满触发 kubelet DiskPressure,
> 所有 Pod 被驱逐,**站点挂了 4 小时才被发现**。根因是几个月前用 nerdctl
> 本地构建留下的 buildkit 缓存从没清理过。
>
> 真正的教训不是"buildkit 占空间",而是**一个缓慢增长的资源没有人看着它**。
>
> 完整的 kube-prometheus-stack 留在 Phase 14,但基础告警半小时就能做,
> 而且和整个计划正交,不该等到第 14 阶段。

---

# Phase 8 — AWS 核心服务 ← 和原 Phase 7 对调

- [x] IAM(User / Role / Policy / 信任策略 / STS)
      关键分辨:身份策略没有 `Principal`("谁"由挂在哪决定),资源策略有;
      信任策略就是挂在 Role 上的资源策略。评估顺序:默认拒绝 → 显式允许 → 显式拒绝优先。
      已落地:`github-actions-ecr`(OIDC 联合)、`k3s-node`(实例配置文件)。
- [x] VPC(CIDR 规划、子网、路由表)
      默认 VPC `172.31.0.0/16`,三个全公网 `/20` 子网。VPC 属于 region,子网属于 AZ(1:1)。
      AWS 每个子网保留 5 个 IP。路由表按最长前缀匹配,`local` 那条是 VPC 内互通。
- [x] Internet Gateway vs NAT Gateway(**注意 NAT 的费用**)
      IGW 免费、做 1:1 NAT(OS 里永远只看得到私网 IP);NAT Gateway 约 $33/月 + $0.045/GB。
      **当前没有 NAT Gateway,不要手滑建一个。** 走 S3/DynamoDB 用 Gateway Endpoint 是免费的。
- [x] Security Group vs NACL
      SG 有状态(回包自动放行)、只有允许、多条取并集、可以引用另一个 SG;
      NACL 无状态(必须自己放行 1024-65535 临时端口)、按编号首个匹配、有拒绝、只认 CIDR。
- [ ] EC2 / EBS
- [x] Route53(Hosted Zone、A / Alias 记录)
      **实际用的是 Cloudflare,没建 hosted zone**($0.50/区/月)。概念对应:
      Route53 的 Alias ≈ Cloudflare 的 CNAME Flattening,都是绕开「顶级域不能用 CNAME」。
- [ ] S3
- [x] ECR
      没有用户名密码,`GetAuthorizationToken` 换一个 **12 小时**的 token —— 所以集群里有个
      CronJob 每 8 小时重建 imagePullSecret(`k8s/charts/blog/templates/ecr-credentials.yaml`)。
      仓库必须先存在,推之前不会自动创建。生命周期策略见 `aws/README.md`。
- [x] CloudWatch
      结论是**这个账号基本不用它**:EC2 的基础指标里没有内存和文件系统使用率
      (hypervisor 看不到 guest OS 内部),要就得装 Agent —— 而 `k8s/scripts/healthcheck.sh`
      已经用 `df -h` 覆盖了。成本告警走 Budgets 更合适(见 Phase 0)。
      记住两条:custom metric 按 **dimension 组合**计费,别拿用户 ID / 路径当 dimension;
      Log Group 默认 **Never Expire**,建了就设 `put-retention-policy`。

> **为什么和 Terraform 对调**:原计划 Phase 7 让你用 Terraform 建 VPC、
> 子网、IGW、NAT、安全组、IAM Role,但这些概念在 Phase 8 才学。
>
> 结果会是"照抄一段 HCL,apply 成功了,但不知道自己建了什么"。
> VPC 和 IAM 必须先理解再写代码,尤其 IAM —— 写错了要么不工作,要么权限过大。

---

# Phase 9 — Terraform

## 概念

- [x] Provider / Resource / Variable / Output
- [x] **State**(以及为什么要放 S3 + 加锁)
      state 在 `xiantang-tfstate-20260809`,用 **S3 原生锁**(`use_lockfile`)
      而不是 DynamoDB —— 后者在 Terraform 1.11 起已废弃。
      存 state 的桶【故意】不归 Terraform 管(鸡生蛋),手动建的。
- [x] `plan` 和 `apply` 的关系,为什么永远先看 plan
      不加 `-out` 的 apply 会重新 plan 一次,所以看到的和执行的之间仍有缝隙。
      CI 里的标准姿势是 `plan -out=tfplan` → 人审 → `apply tfplan`。
- [x] Module —— **学了,但现在【不用】**
      module 就是一个装 .tf 的目录,`variable` 是入参、`output` 是返回值。
      只调用一次的东西抽成 module 是纯亏(多一层间接,改个字段要动三处)。
      **同样的东西建第三遍时再抽**。第一个可能真需要的地方是 Phase 10 的 EKS。
- [x] `import` 块(Terraform 1.5+),把已有资源纳管
      `plan -generate-config-out=x.tf` 能读真实资源生成配置,把"猜字段"
      变成"删多余的"。生成物要清掉 `tags_all`(只读属性,写了会报错)、
      值为 `null` 的字段、和 provider 重复的 `region`。

## 建议的入门顺序 ← 别一上来就 import EC2

1. [x] **从零建一个无害资源**(比如 S3 bucket),跑通
       `init / plan / apply / destroy`,理解 state 是什么
       ← 2026-08-09 完成,`infra/playground/`
2. [x] **纳管"删了也不心疼"的**:ECR 仓库、IAM Role ← 2026-08-09 完成
       `infra/blog/ecr.tf`(仓库 + 生命周期策略)、`infra/blog/iam.tf`
       (OIDC provider + Role + `ecr-push` 内联策略)。
       **一课**:IAM 在 Terraform 里的结构不对称 —— 信任策略是 role 的一个
       *字段*(`assume_role_policy`),而权限策略是*独立资源*
       (`aws_iam_role_policy`)。而 ECR 那边仓库和生命周期策略都是独立资源。
       所以"这个东西要不要单独 import"没法凭直觉判断,只能查文档。
3. [x] **最后才碰 EC2 / EBS / EIP**,只用 `import` 块,
       反复看 plan 直到显示 `No changes`。**看到任何 `destroy` 就停下**
       ← 2026-08-10 全部完成
    1. [x] EIP ← 2026-08-09
    2. [x] EBS ← 2026-08-09 判定不适用:是根卷,跟 EC2 一起进来(见下方清单)
    3. [x] 安全组 ← 2026-08-09
    4. [x] EC2 ← 2026-08-10,`infra/blog/ec2.tf`。带
           `lifecycle { prevent_destroy = true }`,
           让任何会销毁它的 plan 在 **plan 阶段就报错**,而不是等 apply 问 yes/no。
           这台机器挂了没法重建,根卷又是 DeleteOnTermination=true。

    > **这一步最值钱的两课**,都关于 `-generate-config-out`:
    >
    > **① 它会吐出互斥字段。** 它是从 state 反推的,不管 schema 的
    > `ConflictsWith`。EIP 碰到一对(`instance` / `network_interface`),
    > EC2 碰到三对,严重到直接让生成失败:
    > `primary_network_interface` ↔ `associate_public_ip_address`、
    > `ipv6_address_count` ↔ `ipv6_addresses`。
    > **这是工具的固有行为,不是偶发**,下次直接预期它。
    >
    > **② 有一类冲突 `validate` 抓不到。** `security_groups`(按名字)和
    > `vpc_security_group_ids`(按 ID)是同一件事的两种写法,schema 层面
    > 没标 `ConflictsWith`,所以 `validate` 通过、生成器照吐不误 ——
    > 但两个同时写会让**每次 plan 都想改**,而它的变更是 ForceNew。
    > 照抄下去就是「几周后某次 plan 突然要重建你的 k3s」。
    > 前者是 EC2-Classic 时代的遗留,在 VPC 里只该用后者。
    >
    > 通用做法:**删到最简,用 plan 验证,不够再加回来**。
    > Optional+Computed 的字段删掉不影响 plan,真实值仍在 state 里。
    > EC2 这次删了二十多个,一次就 `0 to add / 0 to change / 0 to destroy`。
4. [x] 加 Cloudflare provider 管 DNS 记录 ← 2026-08-10,`infra/blog/dns.tf`
       14 条记录。**纳管线路到此收官**,state 里 AWS 12 个 + Cloudflare 14 个。

    > **这一步的价值不在"记录现状",在跨 provider 引用**:
    >
    > ```hcl
    > content = aws_eip.k3s.public_ip   # k8s / argocd 的 A 记录
    > ```
    >
    > 两朵云进同一个 state 之后,EIP 和 DNS 在代码层面绑定,换 IP 不会漏改。
    > 这是前面几步(各自记录现状)拿不到的东西。
    >
    > **凭据**:provider 块故意留空,token 走 `CLOUDFLARE_API_TOKEN` 环境变量。
    > 和集群里 cert-manager 那个是两个独立 token(权限都是 `Zone:DNS:Edit`
    > 限定 vim0.com),分开隔离爆炸半径。token **不进 state** ——
    > provider 配置不持久化,state 里只有记录本身。
    > ⚠️ 环境变量只活在当前 shell,换个终端跑 plan 会认证失败,那不是配置坏了。
    >
    > **三个踩到的点**:
    > ① provider v5 是大改写(`cloudflare_record` → `cloudflare_dns_record`、
    > `value` → `content`),网上多数示例还是 v4 写法;
    > ② TXT 内容自带引号(SPF / DKIM 要转义),但 google 验证那条没有 ——
    > 不是笔误,是 Cloudflare 存的就不一样;
    > ③ MX 的 `priority` 是独有的必填字段,查记录时漏了不会报错,
    > 但猜错会悄悄改变邮件路由。

> 📌 **纪律补一条**:纳管存量资源时,plan 里出现 **`to add` 就是错的**。
> 意图是 import,唯一正确的输出是 `to import`。
>
> 这条比"看到 destroy 就停"更容易漏,因为 `to add` 看起来人畜无害。
> 但有些资源没有唯一性约束 —— `aws_instance` 的 "创建" 会真的**再开一台**,
> 你以为在纳管,实际在复制,而且它不会被 `check-orphans.sh` 抓到
> (它不是孤儿,它正被 Terraform 管着)。
>
> 2026-08-09 就踩了一次:收尾步骤(删 import 块)提前到 apply 之前做了,
> plan 于是显示 `1 to add`。ECR 策略是幂等覆盖所以无害,换成 EC2 就是双倍账单。

## 要纳管的现有资源

现在全是控制台点出来的,**没有任何记录**。EC2 挂了没法重建:

- [x] EC2 实例(AMI、机型)← 2026-08-10,`infra/blog/ec2.tf`
      `i-0ce7898e977b18717`,c7i-flex.large,ap-southeast-1a。
      ⚠️ **`user_data` 故意没纳管**。它是 ForceNew,而 import 后 state 里
      存的是哈希,配置里写的值只要对不上就触发重建 —— 重建 = k3s 连同根卷
      一起消失。不写则 Terraform 不管它,plan 才干净。
      想纳管它是另一件需要小心的事,不要顺手做。
- [x] 安全组规则 ← 2026-08-09,`infra/blog/security-group.tf`
      资源此前已在 state 里,只是 `.tf` 一直没进版本库。
      **一课**:`ingress = [...]` 这种属性式写法(generate-config-out 的默认产物)
      把整组规则变成一个原子值,加一条规则时 plan 显示的是整个 list 被替换。
      后续该拆成独立的 `aws_vpc_security_group_ingress_rule`。
      ⚠️ `name` 和 `description` 是 ForceNew,改动 = 销毁重建。
- [x] EBS 卷 ← 2026-08-09 判定为**不适用**,不单独纳管。
      `vol-0951edfb52473db5b`,30GB gp3,挂在 `/dev/sda1` 上 = 根卷。
      根卷会作为 `aws_instance` 的 `root_block_device` 块跟着实例一起进来;
      单独 import 成 `aws_ebs_volume` 会让同一块盘被两个资源描述,
      plan 反复横跳,最坏情况是删实例时把卷从 `aws_ebs_volume` 脚下抽走。
      ⚠️ 它的 `DeleteOnTermination` 是 `true`(根卷的默认值),
      实例一旦 terminate,k3s 的全部状态(etcd、PV、镜像)当场消失。
      **注意这和数据卷的默认值方向相反**(数据卷默认 `false`,所以才会变孤儿),
      这一对很容易记反 —— 见本文件"孤儿资源"一节和 `aws/README.md`。
- [x] Elastic IP ← 2026-08-09,`infra/blog/eip.tf`
      **一课**:`instance` 和 `network_interface` 是同一绑定关系的两种写法、
      schema 里互斥,但 `-generate-config-out` 从 state 反推时不管这个约束,
      两个都会吐出来,直接用会报 Conflicting configuration arguments。
      ⚠️ 它的破坏形态不是"重建"是【换 IP】:EIP 一旦 release 就要不回来,
      k8s.vim0.com 和 ssh 会同时失效。
- [x] ECR 仓库 + 生命周期策略 ← 2026-08-09,`infra/blog/ecr.tf`
- [x] GitHub OIDC 的 IAM Role 和信任策略 ← 2026-08-09,`infra/blog/iam.tf`
      三个资源:OIDC provider、Role(信任策略是它的字段)、`ecr-push` 内联策略
- [x] Cloudflare DNS 记录 ← 2026-08-10,`infra/blog/dns.tf`,14 条。
      **故意留在外面的两类,这个判断比纳管本身更值得记**:
      - `_acme-challenge.{k8s,argocd}.vim0.com` TXT ×2 ——
        cert-manager 在 DNS-01 校验时自建自删。记录长在 Cloudflare,
        但**所有者是集群**。写进来会变成拉锯战:cert-manager 删掉 →
        plan 要求重建 → 续期时又被改内容。
        对应下面那条边界:云资源归 Terraform,集群的东西归集群。
      - `my` / `inve` / `zjd` / 四条 ACM 验证 CNAME —— 属于别的项目。
        这个 state 的边界是「博客 + k3s」,混进来就说不清它管的是什么了。

> ⚠️ **不要用 Terraform 的 kubernetes provider 管 k8s 资源。**
> 那会和 Argo CD 打架,而且 Terraform 的 state 模型不适合调谐型资源。
> **边界:云资源归 Terraform,集群里的东西归 Argo CD。**

> ⚠️ Terraform 不做配置管理。"机器里装什么"是 cloud-init / Ansible 的活,
> 边界在"机器交付那一刻"。

---

# Phase 10 — Amazon EKS(可销毁的练习环境)

- [x] 用 Terraform 建 EKS 集群 ← 2026-08-10,`infra/eks/`(独立 state)
- [x] Managed Node Group ← 1 × t3.small,`v1.35.6-eks`
- [x] kubeconfig
- [x] AWS VPC CNI / CoreDNS / kube-proxy
- [x] 把博客用**同一个 chart**部署上去(只覆盖 values)
      ← `k8s/values-eks.yaml`,`templates/` 一行没改
- [x] **`terraform destroy` 并确认能重建** ← 建毁各跑过两轮

## ⏱ 实测数字(2026-08-10)

| 操作 | 耗时 |
|---|---|
| `terraform apply`(从零建 11 个资源) | **8m03s** |
| `terraform destroy` | **3m44s** |
| 完整一轮「建 → 用 → 毁」 | **≈ 12 分钟** |

> **毁比建快一倍以上**,这个方向对纪律有利:退出成本低于进入成本,
> 就不容易拖着不关。而 8 分钟这个数字直接决定了「练完就关」能不能执行 ——
> 换成 40 分钟,人就会倾向于让它开着。

## 📌 这一期学到的

**① chart 的可移植性成立,而且代价比想象中小。**
`helm template` 本地渲染对比(零成本,不需要集群):

| | 资源数 |
|---|---|
| k3s 默认 values | 7(Deployment/Service/Ingress/CronJob/SA/Role/RoleBinding) |
| `values-eks.yaml` | 2(Deployment/Service) |

消失的 5 个里 4 个是 ECR 凭据机制。**chart 里最复杂的那个组件,
在 EKS 上根本不是问题** —— k3s 需要 CronJob 每 8 小时重建
imagePullSecret(ECR token 只有 12 小时有效期),而 EKS 优化版 AMI 的
kubelet 自带 ECR credential provider,直接用节点 instance role 认证。
那套机制不是 k8s 的通用需求,是 k3s 环境的补丁。

**② 版本滑进 EXTENDED_SUPPORT,控制面费率翻 6 倍。**
$0.10/小时 → $0.60/小时(约 $438/月),**费率自己涨,你什么都不用做**。
原本随手写的默认版本 1.33 正好踩在扩展支持上,查表才发现。
每次建集群前跑 `aws eks describe-cluster-versions`,选
`STANDARD_SUPPORT` 里**不是最新**的那个(addon 兼容版本会滞后几周)。

**③ pod 数上限由网卡数决定,不是内存。**
VPC CNI 给每个 pod 分配 VPC 里的真实 IP,所以 t3.small ≈ 11 个 pod,
系统组件占掉 5 个,只剩 6 个位置 —— 而它有 2GB 内存,跑几十个静态站
绰绰有余。**先耗尽的是 IP 不是内存**,这在 k3s(flannel 覆盖网络)上
永远不会遇到。

**④ 两个 state 必须分开。**
`terraform destroy` 是**目录级**的,没有「只销毁一部分」。`eks/` 和
`blog/` 共用 state 的话,某次想清掉 EKS 会连博客一起端走。
同一个 S3 bucket、不同的 key 就够了。

**⑤ 省下的两笔:** 不建 NAT Gateway(-$33/月,也省掉一堆网络复杂度,
节点放公有子网直接出网);不开控制面日志(CloudWatch 按量收费,练习用不上)。

## 💰 省钱的具体做法

- [ ] **学习期跳过 NAT Gateway**,只用公有子网 + 安全组(省 ~$33/月,
      也省掉大量复杂度)
- [ ] 节点组 **1 台** `t3.small` 起步
- [ ] **练完就 `destroy`**。EKS 控制面按小时计费,每天开 2 小时和常开差 12 倍
- [ ] Terraform 写好之后重建只要十几分钟 ——
      **"能随时重建"本身就是不常开的底气**

---

# Phase 11 — AWS Controllers

- [x] AWS Load Balancer Controller(ALB 集成)← 2026-08-11
      AWS 侧 `infra/eks/alb-controller.tf`(IRSA + 官方 IAM 策略 + 子网标签),
      controller 用 Helm 装(边界:云资源归 Terraform,集群里的归 Helm),
      Ingress 配置 `k8s/values-eks-alb.yaml`。
      验收:Ingress → ALB 自动创建 → `curl -H "Host: ..."` 拿到 HTML。
- [ ] EBS CSI Driver(动态卷供给)← 顺带补上 Phase 2 欠的 PV/PVC

## 📌 这一期的四个坑

**① `vpcId` / `region` 必须显式传给 controller,否则启动即崩。**
不传它会去 IMDS 自动发现,而托管节点组的 `HttpPutResponseHopLimit`
默认是 **1** —— pod 里的包多走一跳(pod netns → 宿主机)就把 TTL 耗尽,
报 `ec2imds GetMetadata, context deadline exceeded`。

hop limit=1 是**故意的安全设计**:节点 instance role 的凭据挂在 IMDS 上,
任何 pod 能读 IMDS 就等于能拿节点权限(和 `blog/ec2.tf` 里 IMDSv2 那段
注释是同一件事)。**修法不是放宽 hop limit**,而是让 controller 不必去问 ——
它用 IRSA 拿凭据,本来就不需要 IMDS。

> 三个设计单看都对,凑一起就是启动即崩。而错误信息只说
> `context deadline exceeded`,完全没提「权限」或「安全策略」,看起来像
> 网络不通。**防护生效了但报错像故障**,是云上排障最费时间的一类。

**② 复用默认 VPC 就要自己给子网打标。**
标准教程里子网是 Terraform 自建的顺手打了标签。没有
`kubernetes.io/role/elb=1` 的话 Ingress 一直没有 ADDRESS,
日志报 `unable to discover at least one subnet`。

**③ `target-type` 和 Service 类型是绑死的。**
`ip` → ALB 直接打到 pod IP,Service 用 ClusterIP;
`instance` → 打到 NodePort,Service 必须是 NodePort。
写错的表现是 ALB 建出来了但 target group 一直不健康。

选 `ip` 能成立,是因为 VPC CNI 给 pod 分配了 VPC 真实 IP,ALB 在同一个
VPC 里直接路由得到 —— 目标组里注册的确实是两个 pod IP,不是节点 IP。
**k3s 的覆盖网络做不到这点**,只能走 NodePort 多一跳。
代价就是 Phase 10 记的那条:pod 数被网卡数卡在 11 个。

**④ Helm 对 map 是深度合并不是替换。**
base `values.yaml` 里的 `cert-manager.io/cluster-issuer` 注解会漏进
EKS 的 Ingress。要显式写 `cert-manager.io/cluster-issuer: null` 才删得掉。
不删功能上无害(没装 cert-manager),但这类**继承下来的僵尸配置**
是多环境 values 最容易积累的脏东西。

> ⚠️ **ALB 不在 Terraform state 里**(是 controller 通过 AWS API 建的)。
> 销毁顺序必须是:`kubectl delete ingress` / `helm uninstall blog`
> → 确认 `describe-load-balancers` 返回 0 → 卸 controller
> → `terraform destroy`。顺序反了 ENI 拆不掉,控制面删除卡死。

---

# Phase 12 — IRSA

- [x] ServiceAccount / IAM Role / OIDC / STS ← 2026-08-11,**被 Phase 11 提前带出来了**
- [x] Pod 安全地访问 AWS 服务 ← ALB Controller 就是第一个例子

> 和 Phase 4 里 GitHub Actions 的 OIDC 是**同一套机制**的不同应用:
> 用短期凭据换掉长期 AK/SK。对比着看会很快。
>
> **确实很快 —— 做 ALB Controller 时顺手就做完了**,因为 controller 必须
> 有 AWS 权限,而给 pod 权限只有三条路:
>
> | 方式 | 问题 |
> |---|---|
> | 塞 AK/SK 进 Secret | 长期凭据,泄漏就完蛋 |
> | 用节点的 instance role | 节点上**所有** pod 共享同样权限,没有隔离 |
> | **IRSA** | ServiceAccount ↔ IAM Role 绑定,只有这个 pod 有权限 |
>
> 三件套和 `blog/iam.tf` 一模一样,区别只在签发方:
> 那边是 `token.actions.githubusercontent.com`,这边是集群自己的
> OIDC issuer(`data.tls_certificate` 算指纹,不硬编码)。
>
> ⚠️ **第一号故障**:信任策略里的 `sub` 必须和 helm 装出来的
> ServiceAccount 完全一致 ——
> `system:serviceaccount:kube-system:aws-load-balancer-controller`。
> 对不上的报错是 `WebIdentityErr`,而且它**出现得比较晚**:要等 controller
> 真正开始调 AWS API 才暴露,启动阶段的崩溃(见 Phase 11 坑①)是另一回事。
>
> 补一句:AWS 后来出了 **EKS Pod Identity**,不用建 OIDC provider,比 IRSA
> 简单。这里选 IRSA 是为了和 Phase 4 对照 —— 理解了 IRSA 再看 Pod Identity
> 只是省了几步。

---

# Phase 13 — HTTPS / DNS(EKS 侧)

- [x] cert-manager ← **原计划漏勾了,k3s 上已经全做完**
- [x] Let's Encrypt / ClusterIssuer / DNS-01
- [ ] 在 EKS 上重做一遍(ALB 场景不一样,可以用 ACM 而不是 cert-manager)
- [ ] Route53 Hosted Zone + Alias 记录指向 ALB
- [ ] ExternalDNS(自动管 DNS 记录)

> **踩过的坑**:删 Ingress 会级联删掉 Certificate,但 Secret 会留着
> (cert-manager 默认 `--enable-certificate-owner-ref=false`),
> 所以重建时能复用证书。这很重要 ——
> **Let's Encrypt 对同一组域名有"每周 5 张重复证书"的限流**,反复重装会被锁一周。

---

# Phase 14 — 完整可观测性

- [ ] kube-prometheus-stack
- [ ] Prometheus / Grafana / Alertmanager
- [ ] Dashboard:CPU、内存、Pod 状态、HTTP 请求量、响应时间
- [ ] Loki + Promtail(或 Fluent Bit)集中日志

> ⚠️ **现有的 k3s 那台装不下**。基础告警见 Phase 7,
> 完整栈放到 EKS 上练,或者等 k3s 节点扩容之后。

---

# Phase 15 — Secrets 管理 ← 新增

- [ ] External Secrets Operator
- [ ] AWS Secrets Manager / Parameter Store

> **为什么单独列**:这个洞**现在已经存在**。Cloudflare token 是手动
> `kubectl create secret` 塞进集群的,git 里没有任何记录,
> 换台机器重建就得翻文档重来。原计划把它放在 Phase 17,太靠后了。
>
> ⚠️ k8s Secret 只是 **base64 编码,不是加密**。任何能读那个 Secret 的人
> 都能拿到明文。它相对 ConfigMap 的区别只在 RBAC 默认更严。

---

# Phase 16 — 备份与灾难恢复 ← 从 Stretch 提前

- [ ] Velero(集群资源 + PV 备份)
- [ ] 演练一次完整恢复
- [ ] 写下 RTO / RPO 的实际数字

> **为什么提前**:原计划把 DR 放在 Stretch Goals,但 Chaos Engineering 也在那里。
> 在"EC2 挂了怎么重建"都还没答案的时候,**先能恢复,再谈主动搞破坏**。

---

# Phase 17 — 文档

## README

- [ ] 项目介绍
- [ ] 架构图
- [ ] 部署指南
- [ ] GitOps 工作流
- [ ] 回滚策略
- [ ] 监控
- [ ] 故障排查

## 架构图

- [ ] 基础设施拓扑
- [ ] 部署流程
- [ ] 网络拓扑

> 建议**边做边写**,别攒到最后。今天所有的坑都记在了 commit message
> 和 `TODO.md` 里,三个月后回来能看懂为什么这么做 —— 这比事后补文档有效得多。

---

# Phase 18 — 进阶

## 发布策略

- [ ] Argo Rollouts
- [ ] 金丝雀 / 蓝绿

## 弹性伸缩

- [ ] HPA
- [ ] Cluster Autoscaler / Karpenter

## 安全

- [ ] Kyverno 或 Gatekeeper(策略即代码)
- [ ] NetworkPolicy

## 混沌工程

- [ ] LitmusChaos ← **在 Phase 16 备份能力就位之后再做**

---

# 成本

## 各项参考价(us-east-1 按需,按自己 region 核实)

| 资源 | 大致月费 | 备注 |
|---|---|---|
| EKS 控制面 | ~$73 | **空集群也照收**,$0.10/小时 |
| NAT Gateway | ~$33 + 流量 | 学习期可以完全不用 |
| ALB | ~$16 + LCU | |
| t3.small 节点 | ~$15 | |
| t3.medium 节点 | ~$30 | |
| EBS gp3 | ~$0.08/GB | 30GB ≈ $2.4 |
| 公网 IPv4 | ~$3.6 | 2024 年起所有在用的 IPv4 都收费 |
| **EKS 完整栈(默认路径)** | **~$180** | |
| **EKS 精简版(无 NAT、1 节点)** | **~$105** | |
| **按需开关(每天 2 小时)** | **~$15** | 这才是学习该有的形态 |

## 纪律

1. **预算告警先于一切**(Phase 0)
2. **练完就 `destroy`**
3. **每周检查一次孤儿资源**:`available` 的 EBS 卷、没关联的 EIP、
   忘了删的 NAT Gateway
4. `terraform destroy` 之前 `terraform plan -destroy` 看清楚要删什么

---

# 目标目录结构

```text
vim0-platform/                 # 建议单开一个 repo
├── terraform/
│   ├── bootstrap/             # state 用的 S3 + DynamoDB
│   ├── shared/                # ECR、IAM、Route53
│   ├── k3s/                   # 现有那台 EC2(import 进来)
│   └── eks/                   # 可销毁的练习环境
├── helm/                      # 或直接复用博客仓库里的 chart
├── argocd/
│   ├── applications/
│   └── app-of-apps.yaml
├── docs/
│   ├── architecture.md
│   ├── deployment.md
│   ├── troubleshooting.md
│   └── images/
└── .github/workflows/
```

> **为什么单开 repo**:Terraform 的 state、provider lock、模块结构会把
> 博客仓库搅乱。而且博客内容和基础设施的变更节奏完全不同,
> 混在一起 CI 的 `paths-ignore` 会越来越难维护。

---

# 交付物

## 基础设施

- [ ] Terraform 管理全部云资源
- [ ] EKS(可销毁 / 可重建)
- [ ] IAM / Route53 / ALB / ECR

## Kubernetes

- [x] Helm
- [x] Argo CD
- [x] Ingress
- [x] cert-manager
- [ ] IRSA

## DevOps

- [x] GitHub Actions
- [x] GitOps
- [x] Docker(多架构)
- [x] 不可变镜像 tag

## 可观测性

- [ ] 基础告警(Phase 7)
- [ ] Prometheus / Grafana
- [ ] Loki

## 文档

- [ ] 架构图
- [ ] 部署指南
- [ ] 博客文章(把踩过的坑写出来 —— 这是最有价值的部分)

---

# Stretch Goals

- [ ] 多环境(dev / staging / prod,同一个 chart 不同 values)
- [ ] 多集群
- [ ] 成本优化 Dashboard
- [ ] 开源这个项目
