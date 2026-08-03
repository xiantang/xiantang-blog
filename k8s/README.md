# 在 k3s 中部署

这里的镜像是生产用的：Hugo 把站点编译成静态文件，再用 nginx 提供服务
（不同于仓库根目录 `Dockerfile`，那个是本地开发用的 `hugo server` + 挂载源码）。

已经在这台机器上按下面的步骤实际验证过一遍：build → import → apply →
通过 ClusterIP service 和 Traefik ingress（Host: vim0.com）都能正常访问到首页。

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

```bash
sudo k3s kubectl apply -f k8s/deployment.yaml
sudo k3s kubectl apply -f k8s/service.yaml
sudo k3s kubectl apply -f k8s/ingress.yaml
```

## 4. 验证

```bash
sudo k3s kubectl get pods -l app=xiantang-blog
sudo k3s kubectl port-forward svc/xiantang-blog 8080:80
# 浏览器打开 http://localhost:8080
```

Ingress 配的 host 是 `vim0.com`。本地测试不改 DNS 的话，用 curl 带 Host 头访问 k3s 节点的
80 端口（Traefik 默认监听宿主机 80/443）：

```bash
curl -H "Host: vim0.com" http://<k3s节点IP>/
```

## 更新站点内容

改了博客内容后，重新走一遍第 1、2 步（build + import），然后：

```bash
sudo k3s kubectl rollout restart deployment/xiantang-blog
```

## 关于 blog.conf

仓库里原来的 `blog.conf` 目前没有被任何地方引用，是历史遗留文件；
`k8s/nginx.conf` 是专门为这套容器写的，root 路径指向镜像里 nginx 的默认目录
（`/usr/share/nginx/html`），和 `blog.conf` 里假设的 `/app/public` 不同，别混用。
