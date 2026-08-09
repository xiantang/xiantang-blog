# 在 k3s 中部署

这里的镜像是生产用的：Hugo 把站点编译成静态文件，再用 nginx 提供服务
（不同于仓库根目录 `Dockerfile`，那个是本地开发用的 `hugo server` + 挂载源码）。

已经在这台机器上按下面的步骤实际验证过一遍：build → import → apply →
通过 ClusterIP service 和 Traefik ingress（Host: k8s.vim0.com）都能正常访问到首页。

## 0. 节点级配置（换机器时照做）

⚠️ **这一节的东西都不在 git 里** —— 它们是 k3s 节点本地的文件和 crontab，
重装机器就全没了。所以才要记在这，否则只能靠回忆。

### 0.1 kubectl 环境

配完之后本文档（以及所有对话里给的命令）里的 `k` 就是 `kubectl`，
**不需要 `sudo`**。

```bash
# 1) 把 kubeconfig 复制到自己 home，去掉 sudo
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown "$(id -u):$(id -g)" ~/.kube/config
chmod 600 ~/.kube/config

# 2) 追加到 ~/.bashrc（顺序不能反，见下）
export KUBECONFIG="$HOME/.kube/config"
source <(kubectl completion bash)
alias k=kubectl
complete -o default -F __start_kubectl k
```

⚠️ **`export KUBECONFIG` 必须在 `kubectl completion` 之前。**
`/usr/local/bin/kubectl` 是指向 k3s 二进制的软链，行为等同 `k3s kubectl`：
`KUBECONFIG` 没设置时它**硬编码**去读 `/etc/rancher/k3s/k3s.yaml`（`0600 root:root`），
而不是标准的 `~/.kube/config`。顺序反了的话，`completion` 那行自己会执行一次
kubectl，把 `permission denied` 打进你的 shell。

⚠️ `complete` 里的 `-o default` 不能省，否则 `k apply -f <TAB>` 补不了文件路径。

⚠️ **`~/.kube/config` 里是 admin 凭据**，别 scp 到别处，更别进 git。
没走 `--write-kubeconfig-mode 644` 就是为了不让机器上其他用户拿到它。

### 0.2 k3s 启动参数：让 Evicted Pod 自动清理

`/etc/rancher/k3s/config.yaml`：

```yaml
kube-controller-manager-arg:
  - "terminated-pod-gc-threshold=100"
```

改完 `sudo systemctl restart k3s`。

⚠️ **这个文件如果已存在，是往里合并，不是覆盖** —— 里面可能有装集群时设的
其它参数。

⚠️ 重启 k3s 会让控制平面中断十几秒（API server 重启），但**不影响线上**：
已经在跑的容器由 containerd 管着，kubelet 重连之前照常服务。这期间 `k` 连不上、
ArgoCD 报错，都会自己恢复。

`terminated-pod-gc-threshold` 默认 **12500**，意思是要攒够 12500 个终态 Pod 才
开始按时间顺序清理 —— 按这个集群的速度基本等于永不触发，所以 Evicted Pod
会一直堆着。

**这只治标。** 驱逐的根因是磁盘写满（已通过扩 EBS 解决），GC 阈值只负责收尸。
它的价值是下次再出问题时 `k get pods` 不会被几十行垃圾淹没，能更快看清状态。

验证：

```bash
sudo journalctl -u k3s | grep -o 'terminated-pod-gc-threshold=[0-9]*' | tail -1
```

### 0.3 巡检 + 告警

脚本在 `k8s/scripts/healthcheck.sh`（在 git 里），但**装到机器上这步不在**。

```bash
sudo install -m 755 k8s/scripts/healthcheck.sh /usr/local/bin/blog-healthcheck

# HC_URL 有密钥性质（拿到就能伪造心跳），单独放，不进 git
sudo sh -c 'echo HC_URL=https://hc-ping.com/<uuid> > /etc/blog-healthcheck.env'
sudo chmod 600 /etc/blog-healthcheck.env

sudo /usr/local/bin/blog-healthcheck        # 先手动跑一次，看输出
sudo crontab -e                             # root 的 crontab，脚本要读 k3s.yaml
# */5 * * * * /usr/local/bin/blog-healthcheck >/dev/null 2>&1
```

Healthchecks.io 那边 **Period 5 分钟、Grace 5 分钟**。

⚠️ **Period 别留默认的 1 day。** 那样机器挂了要沉默超过 24 小时才告警，而
"自动发现没声音"正是这套方案唯一比发邮件强的地方 —— 主动报错谁都能做，
机器死了发不出邮件才是要解决的问题。

⚠️ **装完必须验证告警真的会响**，没验证过的告警系统等于没有：

```bash
sudo DISK_WARN_PCT=1 /usr/local/bin/blog-healthcheck   # 故意触发
sudo /usr/local/bin/blog-healthcheck                   # 再恢复成绿
```

几秒内应该收到邮件，正文里带着完整报告（哪一项挂了、`df -h` 输出），
不用 ssh 上去查。

## 1. 构建镜像

这台机器上没有 docker，装的是 `nerdctl-full`（独立的 containerd + buildkit + CNI，
和 k3s 自带的 containerd 是分开的两套，跑在各自的 systemd service 里，不冲突）：

```bash
cd /home/ubuntu/xiantang-blog
sudo nerdctl build -f Dockerfile.k8s -t xiantang-blog:latest .
```

如果换到装了 docker 的机器上构建，把上面这条换成
`docker build -f Dockerfile.k8s -t xiantang-blog:latest .` 即可，后面步骤一样。

## 2. 把镜像导入 k3s

k3s 用它自己内置的 containerd 实例，不认识 nerdctl/docker 那套 containerd 里的镜像，
需要手动导入：

```bash
sudo nerdctl save xiantang-blog:latest -o /tmp/xiantang-blog.tar
sudo k3s ctr images import /tmp/xiantang-blog.tar
sudo rm /tmp/xiantang-blog.tar
```

（docker 版本对应是 `docker save xiantang-blog:latest | sudo k3s ctr images import -`。
如果以后要频繁更新，更省事的做法是搭一个本地镜像仓库，把 image 改成
`localhost:5000/xiantang-blog:latest` 并 push/pull，而不用每次手动 import。）

## 3. 部署

> **现在用 Helm 部署，见下面「用 Helm 发布」一节。**
> `k8s/deployment.yaml`、`service.yaml`、`ingress.yaml` 三个静态 manifest 已经被
> `k8s/charts/blog/` 取代，留在这里只是历史参考，改它们对线上没有任何影响。
> （`cluster-issuer.yaml` 和 `nginx.conf` 仍然有效：前者是集群级资源不归 chart 管，
> 后者被 `Dockerfile.k8s` COPY 进镜像。）

## 4. 验证

```bash
sudo k3s kubectl get pods -l app.kubernetes.io/instance=xiantang-blog
sudo k3s kubectl port-forward svc/xiantang-blog 8080:80
# 在节点上 curl -I http://localhost:8080/
# 想用本机浏览器看，再套一层：ssh -L 8080:localhost:8080 ubuntu@<k3s节点IP>
```

注意 `port-forward` 不走 Service 的负载均衡，它直连某一个 Pod，所以只能验证
「应用活着」，验证不了 Service 配置或多副本轮询。

Ingress 配的 host 是 `k8s.vim0.com`。本地测试不改 DNS 的话，用 curl 带 Host 头访问 k3s 节点的
80 端口（Traefik 默认监听宿主机 80/443）：

```bash
curl -H "Host: k8s.vim0.com" http://<k3s节点IP>/
```

## 5. 配置 TLS（cert-manager + Cloudflare DNS-01）

用 [cert-manager](https://cert-manager.io/) 自动向 Let's Encrypt 申请证书，走 DNS-01
校验（而不是 HTTP-01），这样即使域名开着 Cloudflare 代理（橙色云）也不受影响，
也不用额外为校验开放 80 端口。

### 5.1 装 cert-manager

```bash
sudo k3s kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.3/cert-manager.yaml
sudo k3s kubectl get pods -n cert-manager   # 等三个 pod 都 Running 再继续
```

### 5.2 建 Cloudflare API Token

Cloudflare 控制台 → My Profile → API Tokens → Create Token，用 "Edit zone DNS" 模板，
Zone Resources 限定到 `vim0.com`（不要用 Global API Key，权限太大）。

拿到 token 后直接在集群里建 secret，**不要把 token 写进仓库里提交**：

```bash
sudo k3s kubectl create secret generic cloudflare-api-token-secret \
  --from-literal=api-token=<你的-token> \
  -n cert-manager
```

（`k8s/cluster-issuer.yaml` 里引用的就是这个 secret 名字和 key。）

### 5.3 下发 ClusterIssuer 和更新后的 Ingress

```bash
sudo k3s kubectl apply -f k8s/cluster-issuer.yaml
sudo k3s kubectl apply -f k8s/ingress.yaml
```

`k8s/ingress.yaml` 已经加了 `cert-manager.io/cluster-issuer` annotation 和 `tls` 段，
cert-manager 会看到这个 annotation 自动创建 Certificate 资源并申请证书。

### 5.4 验证

```bash
sudo k3s kubectl get certificate                 # 等 READY 变 True，通常几十秒到几分钟
sudo k3s kubectl describe certificate xiantang-blog-tls
sudo k3s kubectl get challenge                   # 卡住的话看这个排查（DNS 传播延迟、token 权限等）
curl -v https://k8s.vim0.com/                    # 证书签发完成后验证
```

## 用 Helm 发布

chart 在 `k8s/charts/blog/`。镜像由 GitHub Actions 构建并推到 GHCR，
不再需要本地 build + import（第 1、2 步只在没有 CI 的场景下才用得上）。

### 发布一个新版本

1. **在本地开发机**改内容 / 代码，commit 后 push 到 `code` 分支。
   CI 会构建镜像并打上 `sha-<完整40位commit>` 这个不可变 tag。

2. 等 CI 绿了，拿到这次的 commit sha：

   ```bash
   git rev-parse HEAD
   ```

3. 把 `k8s/charts/blog/Chart.yaml` 的 `appVersion` 改成 `"sha-<上面那串>"`，
   commit 并 push。这次 push 只动 chart，`build-image.yml` 的 `paths-ignore`
   会跳过构建，不会白跑一次 CI。

4. **在 k3s 节点**上下发：

   ```bash
   cd ~/xiantang-blog && git pull
   helm diff upgrade xiantang-blog k8s/charts/blog          # 先看要改什么
   helm upgrade xiantang-blog k8s/charts/blog --atomic --timeout 3m
   ```

`--atomic` 是关键：它隐含 `--wait`，会一直等到所有 Pod 真的 Ready 才返回；
超时或失败则**自动回滚到上一个 revision**。不加的话 `helm upgrade` 在把 YAML
提交给 apiserver 的那一刻就返回成功了，镜像拉不动、探针不过这类问题它一概不知道，
你会以为发布成功了但站点其实是坏的。

（`--atomic` 触发的自动回滚**也会产生一个新的 revision**，不是当作没发生过，
看 `helm history` 时别被绕晕。）

### 为什么 tag 不能是 latest

`values.yaml` 的 `image.tag` 留空，回退到 `Chart.yaml` 的 `appVersion`，
指向一个不可变的 `sha-<commit>` tag。这是 `helm rollback` 能真正工作的前提：

- 用 `latest` 的话，每个 revision 的 manifest 里都写着同一个 `latest`，
  回滚重新 apply 出来的东西和当前完全一样，**拉到的还是最新镜像**，等于没回滚。
- 用 `latest` + `imagePullPolicy: Always` + 多副本，还可能出现部分 Pod 跑旧代码、
  部分跑新代码，而 `helm get manifest` 显示一切正常。

### 回滚

```bash
helm history xiantang-blog
helm rollback xiantang-blog <revision> --wait
```

回滚只管 Helm 管的资源。默认只保留 10 个 revision，更早的回不去；
而且 revision 存在集群的 Secret 里，集群没了历史就没了——**git 才是真相来源**。

### 排查配置漂移

线上和预期不一致时，依次看这三个数字，对不上的地方就是问题所在：

```bash
git -C ~/xiantang-blog log --oneline -1          # git 说应该是什么
helm get values xiantang-blog                    # Helm 记了什么（--set 会永久留在这里）
sudo kubectl get deploy xiantang-blog -o yaml    # 集群里实际是什么
```

`helm get values` 输出 `null` 才是干净状态。如果里面有东西，是之前某次
`--set` 留下的，它的优先级高于 `values.yaml`，要用 `helm upgrade --reset-values` 清掉。

## 镜像从哪来（ECR + 凭据自动刷新）

集群拉的是 **ECR**，不是 GHCR：

```
521218410956.dkr.ecr.ap-southeast-1.amazonaws.com/xiantang-blog:sha-<commit>
```

CI 仍然**同时推 GHCR 和 ECR**，两边 tag 一致。所以把 `values.yaml` 的
`image.repository` 改回 `ghcr.io/xiantang/xiantang-blog` 再 push，就是完整的回退。

### 凭据链

集群里**没有任何长期密钥**。整条链全是临时凭据：

```
EC2 实例挂着 k3s-node 这个 instance profile
      ↓ IMDS 提供实例凭据（1 小时，自动续）
CronJob xiantang-blog-ecr-refresher（每 8 小时）
      ↓ aws ecr get-login-password
写成 Secret ecr-pull-secret（docker-registry 类型）
      ↓
Deployment 的 imagePullSecrets → kubelet 拉镜像
```

模板在 `k8s/charts/blog/templates/ecr-credentials.yaml`，开关是
`values.yaml` 里的 `ecr.enabled`。

前置条件（一次性，不在 git 里）：

```bash
aws iam attach-role-policy --role-name k3s-node \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
```

### 三个踩过的坑

**1. ECR 的登录 token 只有 12 小时有效期。**
所以不能建一次 imagePullSecret 就完事，必须定期重建 —— CronJob 存在的全部理由。
（GHCR 不需要这些，因为镜像是 public 的，压根不用凭据。）
刷新周期设成 8 小时是为了留 4 小时余量，一次失败不会立刻导致拉不到镜像。

**2. Pod 访问 IMDS 会多一跳，默认被拦。**
实例的 `HttpPutResponseHopLimit` 默认是 1，而 Pod 在容器网络里到 IMDS 多一跳，
IMDSv2 的 PUT 请求会被丢弃，取不到凭据。

解法是给这个 CronJob 开 `hostNetwork: true`（共享宿主机网络栈，没有额外跳数）。

⚠️ **不要改成把 hop limit 调到 2** —— 那等于允许集群里**所有** Pod 读 IMDS，
一个有 SSRF 的应用就能偷走节点的 AWS 凭据。Capital One 2019 年那次一亿多条
数据泄露就是这个路径。只给一个可信的 CronJob 开 hostNetwork 是小得多的口子。

**3. `rancher/kubectl` 没有 `/bin/sh`。**
它是精简镜像，entrypoint 就是 kubectl 二进制。写
`command: ["/bin/sh", "-c", ...]` 会失败在：

```
exec: "/bin/sh": stat /bin/sh: no such file or directory
```

⚠️ 这个报错**不是** `ImagePullBackOff` —— 镜像拉到了，是容器起不来。
事件里会同时出现 `Container image ... already present on machine`，
看到这行就说明问题不在拉取。distroless / scratch 基础镜像越来越常见，
`/bin/sh` 不能想当然。

绕开的办法：让带 shell 的 aws-cli initContainer 直接把完整的 Secret YAML
生成到共享 volume，kubectl 容器只剩一条 `args: ["apply", "-f", ...]`，
不需要 shell 也不需要管道。

### 排查

```bash
k get cronjob xiantang-blog-ecr-refresher
k get secret ecr-pull-secret                     # 类型该是 kubernetes.io/dockerconfigjson

# 手动跑一次，不等 8 小时
k delete job ecr-test --ignore-not-found
k create job --from=cronjob/xiantang-blog-ecr-refresher ecr-test
k logs job/ecr-test --all-containers
```

⚠️ `--from=cronjob` 复制的是**集群里当前的** CronJob 模板。改了 chart 之后
要先确认 ArgoCD 同步完，否则测的还是旧版本。

Pod 报错的对应关系：

| 症状 | 原因 |
|---|---|
| `401` / `no basic auth credentials` | Secret 过期或 registry 地址不匹配 |
| `denied` / `not authorized` | `k3s-node` Role 少了 ECR 读权限 |
| initContainer 取不到凭据 | `hostNetwork` 没生效（见坑 2） |

生命周期策略和 `latest` 标签的问题见 `aws/README.md`。

## 关于 blog.conf

仓库里原来的 `blog.conf` 目前没有被任何地方引用，是历史遗留文件；
`k8s/nginx.conf` 是专门为这套容器写的，root 路径指向镜像里 nginx 的默认目录
（`/usr/share/nginx/html`），和 `blog.conf` 里假设的 `/app/public` 不同，别混用。
