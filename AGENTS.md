# AGENTS.md

## 这个项目对我意味着什么

仓库本身是一个 Hugo 静态博客(`content/`、`themes/`、`config.toml`),内容部分就是普通博客,
按常规方式帮忙即可。

但 **`k8s/`、`Dockerfile.k8s`、`.github/workflows/` 这些基础设施部分,存在的目的是让我学习
Kubernetes / CI / 云服务**,而不是为了把站点跑起来 —— 站点本身早就有 GitHub Pages 那条路了
(`.github/workflows/deploy.yml`)。

这个区别很重要:在这些部分,**"快速把事情做完"不是目标,"我搞懂了"才是**。

## 最重要的一条:让我自己执行

涉及集群、云资源、部署的操作,**不要直接替我跑命令**。请改成:

1. 说明这一步要达成什么、为什么需要它
2. 给出我可以直接复制粘贴的命令
3. 说明预期输出长什么样,以及怎么判断成功
4. 提示常见的失败模式和排查方向

然后**停下来等我执行完反馈**,不要连续假设我已经跑完了后面几步。

理由很简单:命令是你敲的,肌肉记忆和踩坑经验就都是你的,不是我的。

### 具体边界

**不要执行**(给命令让我自己跑):
- `kubectl` / `k3s kubectl` 的任何写操作:`apply`、`delete`、`patch`、`rollout`、`create`
- `helm install` / `upgrade` / `uninstall`
- `aws` 的任何写操作:`create-*`、`put-*`、`delete-*`、`attach-*`
- `docker push`、`docker login`
- 往集群里装任何东西(cert-manager、ArgoCD、ingress controller 等)

**可以直接做**:
- 读仓库里的文件、搜代码
- 编辑仓库内的文件(YAML、Dockerfile、workflow、文档)—— 改文件不等于生效,我还得自己 apply
- `git` 的读操作(`status`、`diff`、`log`)
- 解释概念、画架构、对比方案

**先问我**:
- `git commit` / `git push`
- 任何只读但要连到我集群或云账号的命令(`kubectl get`、`aws describe-*`)—— 想看的话
  告诉我命令,我跑完贴给你,通常更快

## 教学上的偏好

- **先讲为什么,再讲怎么做**。一条 `kubectl apply` 背后发生了什么,比这条命令本身更重要。
- **不要跳过中间状态**。比如"装 ArgoCD"不是一步,而是:装组件 → 看 pod 起来 → 拿初始密码 →
  登录 → 建 Application → 观察 sync。每一步我都想看到。
- **踩坑是有价值的**。如果某个做法有经典陷阱(比如 ArgoCD 放在终止 TLS 的 Traefik 后面会
  重定向循环),提前告诉我陷阱是什么、为什么会发生,而不是直接给一个绕过它的配置。
- **诚实评价方案**。如果我想用的东西对这个场景是杀鸡用牛刀,直说,但也要说清楚"为了学习值不值得
  做"是另一个问题 —— 通常值得。
- 中文回复。

## 当前环境事实

### 这是两台机器,别搞混

- **本地开发机**(你现在看到的这个仓库,`/home/neo/project/xiantang-blog`):写代码、改 YAML、
  跑 git、跑 `aws` CLI。**这里没有 k3s,也没有集群的 kubeconfig。**
- **k3s 节点**:一台独立的小云主机,集群跑在上面。所有 `kubectl` 都要 ssh 上去执行。

所以:**不要在本地直接跑 `kubectl`**,它要么不存在,要么连的不是这个集群。涉及集群的操作,
给出命令并说明"这条要在 k3s 那台机器上跑",由我 ssh 过去执行。

因为是小云主机,**资源紧张是常态**。建议任何要往集群里装的东西,都先估算内存开销,
并优先考虑精简安装(关掉用不到的组件、显式设 requests/limits),而不是照搬官方的完整 manifest。

省得每次重新查:

| 项 | 值 |
|---|---|
| 集群 | 单节点 k3s,跑在独立的小云主机上,自带 Traefik ingress + containerd |
| kubectl | ssh 到 k3s 节点后用 **`k`**(= `kubectl`,已配 alias + 补全)。kubeconfig 复制到了 `~/.kube/config`,`~/.bashrc` 里 `export KUBECONFIG` 指向它,**不再需要 `sudo`**。给我命令时一律写 `k`,别写 `sudo k3s kubectl`(见 `k8s/README.md`) |
| 域名 | `k8s.vim0.com`(k3s),`vim0.com`(GitHub Pages) |
| TLS | cert-manager + Let's Encrypt,Cloudflare DNS-01,ClusterIssuer 名 `letsencrypt-prod` |
| 镜像仓库 | AWS ECR(集群在拉这个) + GHCR(同步推送,留作回退) |
| ECR | `521218410956.dkr.ecr.ap-southeast-1.amazonaws.com/xiantang-blog` |
| AWS profile | `blog`,region `ap-southeast-1` |
| CI | `.github/workflows/build-image.yml`,push 到 `code` 分支触发,多架构 amd64+arm64 |
| 镜像 tag | 只有 `sha-<完整 commit sha>`。**不推 `latest`** —— 它没有消费者,又挡着 ECR 的 IMMUTABLE |

### 已知的粗糙点

- **不带 tag 拉镜像会失败**:没有 `latest` 了,`docker pull .../xiantang-blog` 默认找
  `:latest` 会 404。手动拉要带 `sha-<commit>`,或者从 `k8s/charts/blog/Chart.yaml` 的
  `appVersion` 里抄当前线上那个。
- **`k8s/deployment.yaml` / `service.yaml` / `ingress.yaml` 是死文件**,已被
  `k8s/charts/blog/` 取代,改它们对线上没有影响(见 `k8s/README.md` 第 3 节)。

### 聊天记录在 `agent-history/`

我和 agent 的历次对话导出在 **`agent-history/`**,文件名是
`<日期>-<时间>-<话题>.txt`。

**这是给你用的**:接手一个话题前,如果我提到"上次聊过""之前那个坑",
先去这个目录里搜,别让我重讲一遍。里面有推导过程和当时的真实输出
(集群状态、AWS 返回值),比事后总结的文档更完整。

用 `grep` 搜,**别整个读** —— 单个文件通常 15000+ 行、800KB 以上,
一次读完会把上下文吃光。

⚠️ **这个目录在 `.gitignore` 里,只存在于本地。不要提交,也不要建议我提交。**

原因:对话里全是命令的**真实输出** —— `kubectl get secret`、`aws sts`、
IMDS 响应,任何一条都可能把凭据带进去。这个仓库是公开的,而"每次导出都
记得扫一遍密钥"是那种迟早会忘的纪律。**把安全性建立在人的记性上不划算**,
何况泄漏一次就得 rewrite git 历史。

真正值得留下的结论一律往 `TODO.md` / `ROADMAP.md` / 各 `README.md` 里写 ——
那些是经过筛选、可以公开的。聊天记录是原始素材,不是产出。

（`/export` 默认导到仓库根目录,记得移进 `agent-history/`。
留在根目录的话,它不在 ignore 规则里,下次 `git add -A` 就进去了。）

### 仓库里两个 Dockerfile 别混

- `Dockerfile` —— 本地开发用,`hugo server` + 挂载源码
- `Dockerfile.k8s` —— 生产用,Hugo 编译成静态文件后交给 nginx;build stage 钉了
  `--platform=$BUILDPLATFORM`,因为 Hugo 0.91.2 extended 没有 arm64 版本

## 不要碰的东西

- `themes/` 是 git submodule,不要直接改里面的文件
- `blog.conf` 是历史遗留,没有任何地方引用,别拿它当参考(`k8s/nginx.conf` 才是在用的)
- 任何密钥都不要写进仓库:Cloudflare token、AWS 凭据都用集群 secret 或 GitHub secret
