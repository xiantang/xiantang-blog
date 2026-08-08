# `k8s/argocd/`

这个目录是**引导层**。用 app-of-apps 之后，手动操作被压缩成了**一次性**的
`k apply -f root-application.yaml`；之后往这里加/改 manifest，push 就生效。

| 文件 | 谁下发 |
|---|---|
| `root-application.yaml` | 手动 apply **一次**做引导，之后由它自己管自己 |
| `blog-application.yaml` | `root`(它再去接管博客的一切) |
| `ingress.yaml` | `root` |
| `README.md` | 没人 —— ArgoCD 的目录源只读 `.yaml`/`.yml`/`.json` |

引导顺序不能反:**先 commit + push,再 apply**。root 的 source 指向 git 里的
本目录,如果 git 里还没有 `root-application.yaml`,它一上来就会发现"集群里有个
root 而 git 里没有"。

```bash
git pull                                   # 在节点上
k apply -f k8s/argocd/root-application.yaml
k -n argocd get app                        # 两个 Application 都该是 Synced/Healthy
```

⚠️ **引导之后别再手动 `kubectl edit` 本目录里的东西**，`selfHeal` 会把你的改动
改回去。这正是目的，但第一次撞上会以为改动丢了。

⚠️ `root` 的 `prune` 故意关着，原因写在 `root-application.yaml` 的注释里。

### 还没做到的

这是「ArgoCD 管理我写的 manifest」，不是「ArgoCD 管理它自己的安装」。
那 7 个 Pod 仍然是 `kubectl apply -f install.yaml` 装的，升级还得手动 ——
把官方 manifest 也变成一个 Application 会遇到先有鸡还是先有蛋的问题
（升级到一半时，执行升级的 argocd-server 自己在重启）。见 `ROADMAP.md`。

---

## 把 ArgoCD UI 暴露到 https://argocd.vim0.com

### 1. DNS

在 Cloudflare 给 `argocd` 加一条 A 记录指向 k3s 节点的公网 IP,和 `k8s.vim0.com` 一样。
橙色云(代理)开不开都行:证书走 cert-manager 的 DNS-01,不受代理影响。

⚠️ 但如果开代理,`argocd` CLI 要加 `--grpc-web` —— Cloudflare 不转发原生 gRPC。
浏览器 UI 不受影响。

### 2. 先把 argocd-server 切到 `--insecure`

**这步必须在 apply ingress 之前做,否则浏览器会 `ERR_TOO_MANY_REDIRECTS`。**
原因写在 `ingress.yaml` 的注释里。

```bash
kubectl -n argocd patch configmap argocd-cmd-params-cm \
  --type merge -p '{"data":{"server.insecure":"true"}}'
kubectl -n argocd rollout restart deployment argocd-server
kubectl -n argocd rollout status deployment argocd-server
```

### 3. 下发 Ingress

```bash
kubectl apply -f k8s/argocd/ingress.yaml
```

### 4. 验证

```bash
kubectl -n argocd get ingress argocd-server
kubectl -n argocd get certificate argocd-server-tls   # 等 READY=True,几十秒到几分钟
kubectl -n argocd get challenge                       # 卡住了看这个
curl -I https://argocd.vim0.com/                      # 期望 200,不是 301 循环
```

拿初始密码:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
```

⚠️ **UI 一旦公网可达,`admin` 就是暴露在互联网上的账号。**
第一件事是改掉初始密码(`argocd account update-password`),
并把 `argocd-initial-admin-secret` 删掉。长期做法是接 SSO 之后
在 `argocd-cm` 里 `admin.enabled: "false"`。
