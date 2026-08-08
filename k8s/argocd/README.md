# `k8s/argocd/`

这个目录是**引导层**：ArgoCD 自己还没有被 ArgoCD 管理，所以这里的 manifest
一律用 `kubectl apply` 手动下发，改了不会自动生效。

| 文件 | 谁下发 |
|---|---|
| `blog-application.yaml` | 手动 `kubectl apply`(之后博客的一切由它接管) |
| `ingress.yaml` | 手动 `kubectl apply` |

`xiantang-blog` 这个 Application 的 `path` 是 `k8s/charts/blog`,**不包含本目录**。
push 到 `code` 只是把文件放进了 git,集群里什么都不会变。

想去掉这层手动操作,做法是 app-of-apps:再建一个 Application 指向本目录,
让 ArgoCD 管理自己 —— 见 `ROADMAP.md` Phase 6。

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
