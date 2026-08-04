# TODO

k8s / 基础设施部分的待办。博客内容相关的不记在这里。

最后更新:2026-08-04

---

## 运维(影响站点可用性)

### [ ] 加资源监控和告警 ← 最该做的一件事

**为什么**:2026-08-03 23:02 根卷用满(93%)触发 kubelet DiskPressure,所有 Pod 被驱逐,
站点挂了 **4 小时**才被发现。整个过程没有任何东西报警。

根因链条:

```
几个月前用 nerdctl 本地构建镜像
  → buildkit 缓存 677M 留在盘上,没人清
  → 后来改用 CI 构建,那套工具再没用过,缓存还在
  → 根卷只有 6.7G,k3s 镜像慢慢涨
  → 越过 kubelet 驱逐阈值(nodefs 可用 <10%)
  → DiskPressure → 驱逐所有 Pod → 站点挂了
```

真正的教训不是"buildkit 占空间",而是**一个缓慢增长的资源没有人看着它**。

**怎么做**(由简到繁,先做第一个就够):

1. cron + 邮件:每小时检查 `df -h /` 和 `kubectl get nodes`,超阈值就发邮件
2. 加 node-exporter + 一个轻量告警
3. 完整的 Prometheus + Alertmanager(注意内存开销,见下面「资源天花板」)

比继续学新的 k8s 组件实用得多。

### [ ] 扩根卷到 20-30GB

当前 6.7G,已用 6.1G(93%)。6.7G 跑 k8s 本来就太小,光 k3s 镜像就 852M。

在线扩容不用停机:控制台 Modify volume → `growpart` + `resize2fs`。
gp3 约 $0.08/GB/月,扩到 30G 每月多约 $1.9。
顺手把 gp2 改成 gp3(便宜约 20%,基线 3000 IOPS)。

⚠️ 同一个卷 **6 小时内只能修改一次**,一次调到位。

### [ ] 清掉 buildkit / 独立 containerd 死重

`/var/lib/buildkit` 677M + `/var/lib/containerd` 314M ≈ **1G 磁盘**,外加约 60Mi 内存。

镜像已全部由 CI 构建推 GHCR,nerdctl-full 那套本地构建流程
(`k8s/README.md` 第 1、2 步)不会再用到。

```bash
systemctl list-units --type=service --state=running | grep -iE 'containerd|buildkit'
sudo systemctl disable --now buildkit containerd
sudo rm -rf /var/lib/buildkit /var/lib/containerd
```

⚠️ **k3s 自己的 containerd 是 k3s 进程的子进程,不在 systemd 里。**
`systemctl` 能看到的那个是 nerdctl-full 装的。停错了整个集群就没了,
先用 `systemctl show containerd -p MainPID -p ExecStart` 确认指向 `/usr/local/bin/containerd`。

### [ ] 绑定 Elastic IP

现在是自动分配的公网 IP,实例一 stop/start 就变,每次都要改 Cloudflare 的 A 记录。
绑 EIP 之后就固定了。

费用上不亏:2024 年起 AWS 对所有在用的公网 IPv4 都收费(~$3.6/月),
现在这个自动分配的 IP 已经在收了,换成 EIP 不额外增加。
(但实例长期 stopped 时 EIP 仍计费,自动分配的则会被回收。)

---

## 资源天花板(决策依据,不是待办)

节点是 **t3.small(2 vCPU / 2GB)**,x86_64。实测:

| | |
|---|---|
| `k3s server` 进程 | ~686Mi(不可压缩,这就是控制面本身) |
| 所有业务 Pod 加起来 | ~168Mi |
| 博客单个 Pod | **3Mi**(nginx 发静态文件就是这么省) |
| 可用内存 | ~286Mi |
| 根卷 | 6.7G |

**结论:不要再往集群里加常驻组件。**

- ArgoCD 需要 ~1GB(5-7 个 Pod)→ 装不下
- Flux 最小集 ~200Mi → 塞得进但零余量,不值得

76% 内存被 k8s 控制面自己吃掉,真正跑业务的不到 5%。
这是单节点 k8s 的固有成本 —— 用 k8s 跑个人博客从工程角度不划算,
但作为学习平台是划算的。**在为学习付费,不是在为博客的可用性付费。**

---

## 学习方向(不影响线上)

### [ ] 在本地开发机用 kind/k3d 学 ArgoCD / GitOps

EC2 那台装不下(见上面天花板)。kind 免费、内存随便用、玩坏了一秒重建。
`k8s/charts/blog/` 可以直接拿去当第一个 Application,只要覆盖几个 values
(关掉 TLS、换 host)。

⚠️ 要知道的前提:**ArgoCD 不用 Helm 安装**,它跑 `helm template` 再自己 apply。
所以集群里没有 Helm release,`helm list` / `history` / `rollback` / `get values` 全失效,
回滚改在 ArgoCD 里做。**但 chart 本身完全复用。**

### [ ] 把 nginx.conf 抽成 ConfigMap

现在烤在镜像里,改一行配置要重新构建整个镜像。
抽成 ConfigMap 之后能学到 `checksum/config` annotation —— 配置变了怎么让 Pod 自动重启。
这是 Helm 模板能力的真实用武之地。

### [ ] 加第二个节点

现在所有"高可用"都是纸面上的:3 个副本全在同一台机器上,机器挂了就是全挂。
多节点之后 `topologySpreadConstraints`、`PodDisruptionBudget` 才有意义。
比继续深挖 Helm 是更大的一块。

### [ ] 决定要不要自动回填 appVersion

现在发布要手动把 commit sha 填进 `Chart.yaml` 的 `appVersion`。

可以让 CI 自动 commit(`paths-ignore` 已覆盖 `k8s/charts/**`,不会触发循环构建),
但代价是:仓库里多一堆 bot commit、本地每次要先 pull、
而且失去"改 appVersion 才算发布"这个闸口(push 即上线)。

**先手动跑一段,觉得烦了再说**——那时候对代价的判断会比现在准。

---

## 收尾

### [ ] 处理 `k8s/` 下被 chart 取代的静态 manifest

`deployment.yaml` / `service.yaml` / `ingress.yaml` 已经被 `k8s/charts/blog/` 取代,
改它们对线上没有任何影响。目前只在 `k8s/README.md` 里加了注释说明,文件还在。

要么删掉,要么留着当"模板化前后对照"的教学材料——留着也有价值,但要确保注释足够醒目。

`cluster-issuer.yaml` 和 `nginx.conf` **不要删**:前者是集群级资源不归 chart 管,
后者被 `Dockerfile.k8s` COPY 进镜像。

### [ ] k3s 配 ECR 的 imagePullSecret

CI 同时推 GHCR 和 ECR,但集群只拉 GHCR。想切到 ECR 需要额外配凭据
(ECR token 12 小时过期,要么定时刷新 secret,要么用 IRSA 之类的方案)。
目前没有实际需求,记着而已。

---

## 已完成

- [x] **干掉 `:latest`**(`f8cba5a7`,2026-08-04)
  chart 的 `image.tag` 留空回退到 `Chart.yaml` 的 `appVersion`,指向不可变的
  `sha-<commit>` tag。这是 `helm rollback` 能真正工作的前提 ——
  用 `latest` 时每个 revision 的 manifest 写的都是同一个字符串,回滚等于没回滚。
  同时把 `pullPolicy` 从 `Always` 改成 `IfNotPresent`。

- [x] **把静态 manifest 改写成 Helm chart**(`b013d7a4`,2026-08-04)
  `k8s/charts/blog/`。资源名跟随 release 名,replicas / 镜像 tag / ingress host /
  TLS 开关都抽到 `values.yaml`。ClusterIssuer 故意没放进 chart(集群级、多应用共享)。

- [x] **CI 加 `paths-ignore`**(`f8cba5a7`)
  只改 chart 或文档不再触发镜像构建。**没有**忽略整个 `k8s/**` ——
  `Dockerfile.k8s` 里有 `COPY k8s/nginx.conf`,改 nginx 配置必须重新构建。
