# 在 k3s 中部署

这里的镜像是生产用的：Hugo 把站点编译成静态文件，再用 nginx 提供服务
（不同于仓库根目录 `Dockerfile`，那个是本地开发用的 `hugo server` + 挂载源码）。

已经在这台机器上按下面的步骤实际验证过一遍：build → import → apply →
通过 ClusterIP service 和 Traefik ingress（Host: k8s.vim0.com）都能正常访问到首页。

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

## 关于 blog.conf

仓库里原来的 `blog.conf` 目前没有被任何地方引用，是历史遗留文件；
`k8s/nginx.conf` 是专门为这套容器写的，root 路径指向镜像里 nginx 的默认目录
（`/usr/share/nginx/html`），和 `blog.conf` 里假设的 `/app/public` 不同，别混用。
