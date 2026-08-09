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

- [ ] Provider / Resource / Variable / Output
- [ ] **State**(以及为什么要放 S3 + 加锁)
- [ ] `plan` 和 `apply` 的关系,为什么永远先看 plan
- [ ] Module
- [ ] `import` 块(Terraform 1.5+),把已有资源纳管

## 建议的入门顺序 ← 别一上来就 import EC2

1. [ ] **从零建一个无害资源**(比如 S3 bucket),跑通
       `init / plan / apply / destroy`,理解 state 是什么
2. [ ] **纳管"删了也不心疼"的**:ECR 仓库、IAM Role
3. [ ] **最后才碰 EC2 / EBS / EIP**,只用 `import` 块,
       反复看 plan 直到显示 `No changes`。**看到任何 `destroy` 就停下**
4. [ ] 加 Cloudflare provider 管 DNS 记录

## 要纳管的现有资源

现在全是控制台点出来的,**没有任何记录**。EC2 挂了没法重建:

- [ ] EC2 实例(AMI、机型、user_data)
- [ ] 安全组规则
- [ ] EBS 卷
- [ ] Elastic IP
- [ ] ECR 仓库
- [ ] GitHub OIDC 的 IAM Role 和信任策略
- [ ] Cloudflare DNS 记录

> ⚠️ **不要用 Terraform 的 kubernetes provider 管 k8s 资源。**
> 那会和 Argo CD 打架,而且 Terraform 的 state 模型不适合调谐型资源。
> **边界:云资源归 Terraform,集群里的东西归 Argo CD。**

> ⚠️ Terraform 不做配置管理。"机器里装什么"是 cloud-init / Ansible 的活,
> 边界在"机器交付那一刻"。

---

# Phase 10 — Amazon EKS(可销毁的练习环境)

- [ ] 用 Terraform 建 EKS 集群
- [ ] Managed Node Group
- [ ] kubeconfig
- [ ] AWS VPC CNI / CoreDNS / kube-proxy
- [ ] 把博客用**同一个 chart**部署上去(只覆盖 values)
- [ ] **`terraform destroy` 并确认能重建**

## 💰 省钱的具体做法

- [ ] **学习期跳过 NAT Gateway**,只用公有子网 + 安全组(省 ~$33/月,
      也省掉大量复杂度)
- [ ] 节点组 **1 台** `t3.small` 起步
- [ ] **练完就 `destroy`**。EKS 控制面按小时计费,每天开 2 小时和常开差 12 倍
- [ ] Terraform 写好之后重建只要十几分钟 ——
      **"能随时重建"本身就是不常开的底气**

---

# Phase 11 — AWS Controllers

- [ ] AWS Load Balancer Controller(ALB 集成)
- [ ] EBS CSI Driver(动态卷供给)← 顺带补上 Phase 2 欠的 PV/PVC

---

# Phase 12 — IRSA

- [ ] ServiceAccount / IAM Role / OIDC / STS
- [ ] Pod 安全地访问 AWS 服务

> 和 Phase 4 里 GitHub Actions 的 OIDC 是**同一套机制**的不同应用:
> 用短期凭据换掉长期 AK/SK。对比着看会很快。

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
