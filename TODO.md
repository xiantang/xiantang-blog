# TODO

k8s / 基础设施部分的待办。博客内容相关的不记在这里。

最后更新:2026-08-04

---

## 运维(影响站点可用性)

### [x] 加资源监控和告警 ← 已完成 2026-08-08,详见「已完成」一节

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

**做的是第 1 档的变体**:cron 每 5 分钟跑 `k8s/scripts/healthcheck.sh`,
但上报改成心跳而不是发邮件(理由见「已完成」)。往上还可以做:

2. 加 node-exporter + 一个轻量告警
3. 完整的 Prometheus + Alertmanager(注意内存开销,见下面「资源天花板」)

**但先别急着上 2/3。** 现在这套已经能抓到磁盘、节点、Pod、站点四类问题,
且成本为零。上 Prometheus 是为了看**趋势**(增长率、容量预测),
不是为了看**状态** —— 等真的想回答"照这个速度多久会满"再说。

### [x] 扩根卷到 20-30GB ← 已完成

已扩到 **28G,用量 29%**(2026-08-08 巡检脚本上报)。
DiskPressure 的根因消失了。

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

### [ ] 调小 pod GC 阈值,让 Evicted Pod 自动清理

2026-08-03 磁盘事故留下了 50+ 个 `Evicted` Pod 墓碑,几小时后还在 `kubectl get pods`
里刷屏。它们不占资源(容器早没了,只剩 API 对象),但严重干扰排查。

**为什么不会自动消失**:清理由 controller-manager 的 pod GC 负责,
默认阈值是**已终止 Pod 超过 12500 个**才开始清 —— 对单节点小集群等于永不触发。

零代码解法,给 k3s 透传参数。**改 `/etc/rancher/k3s/config.yaml`,
不要改 systemd unit** —— 前者是 k3s 官方的配置入口,升级不会被覆盖:

```yaml
kube-controller-manager-arg:
  - "terminated-pod-gc-threshold=100"
```

`sudo systemctl restart k3s` 生效。
⚠️ 重启 k3s 会让 apiserver 断十几秒,已在跑的容器不受影响(由 containerd 管着)。
⚠️ 这个文件如果已存在是**合并不是覆盖**。

完整步骤记在 `k8s/README.md` 第 0.2 节 —— 它不在 git 里,重装机器就没了。

手动清理(phase 要分两次,field-selector 不支持 `in`):

```bash
kubectl delete pods -n default --field-selector status.phase=Failed
kubectl delete pods -n default --field-selector status.phase=Succeeded
```

⚠️ 用 `--field-selector`,**别用 `--all`**,那会把正在跑的一起删掉。

想更进一步就自己写 controller,见「学习方向」一节 —— 但先用上面的方案把问题解决掉。

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

> ⚠️ **以上是 2026-08-04 升配前的数字,已经过时。** 之后机器和根卷都扩过,
> ArgoCD 的 7 个 Pod 已经跑在这台上了。
>
> 已知的新数字(2026-08-08,来自巡检脚本的上报):**根卷 28G,用量 29%**。
> 磁盘从此不再是瓶颈 —— 上次那次 DiskPressure 大驱逐的根因已经消失。
> **内存还没重新量**(`free -h`),待办。结论那句话仍然成立:
> 76% 内存被 k8s 控制面吃掉,业务不到 5%,单节点 k8s 的固有成本就是这样。

76% 内存被 k8s 控制面自己吃掉,真正跑业务的不到 5%。
这是单节点 k8s 的固有成本 —— 用 k8s 跑个人博客从工程角度不划算,
但作为学习平台是划算的。**在为学习付费,不是在为博客的可用性付费。**

---

## 学习方向(不影响线上)

### [ ] 写一个清理 Evicted Pod 的 controller

**先说清楚:对这个需求本身,写 controller 是杀鸡用牛刀。**
零代码的解法见运维一节的「调 pod GC 阈值」,或者一个跑 `kubectl delete` 的 CronJob。
**先用那个把问题解决掉,再把 controller 当独立的学习项目慢慢写**,
别让一个碍眼的真实问题等着代码写完。

但作为**第一个 controller** 这题目选得很好:

- 不需要 CRD,直接 watch 内置的 Pod 资源,省掉一大块概念负担
- 逻辑一句话说完:看到 `phase=Failed` 且 `reason=Evicted` 的 Pod 就删
- 和主线是连着的 —— **ArgoCD 本身就是一个 controller**,只是它调谐的是
  「git 和集群」而不是「Pod 状态」。自己写一遍才算真懂调谐循环

会学到:Informer/Watch(不是轮询,apiserver 推送变更 + 本地缓存)、
WorkQueue(事件去重 + 失败重试 + 限速)、Reconcile 幂等、最小权限 RBAC、
leader election。

选型:**Go + controller-runtime**,ArgoCD 和 cert-manager 用的就是这套。
kubebuilder 的脚手架是围绕「你要定义 CRD」设计的,这个用不上 CRD,
直接用 controller-runtime 的 manager 手写更清爽,大概 100 行。

⚠️ 一定会踩的坑:

- **别写成 `for { list(); delete(); sleep() }`** —— 那是轮询脚本不是 controller,会压垮 apiserver
- **`Failed` 不等于 `Evicted`** —— Job 跑失败的 Pod 也是 `Failed`,而且那些是
  **故意留着给人看的**。必须同时判断 `status.reason == "Evicted"`
- **删除要容忍 404** —— Reconcile 时对象可能已被别人删掉,这是正常的不是错误
- RBAC 只给 `pods: list/watch/delete`,别图省事绑 cluster-admin

放哪:倾向**单开一个 repo**,博客仓库里塞个 Go controller 有点怪。

### [ ] 把 nginx.conf 抽成 ConfigMap

现在烤在镜像里,改一行配置要重新构建整个镜像。
抽成 ConfigMap 之后能学到 `checksum/config` annotation —— 配置变了怎么让 Pod 自动重启。
这是 Helm 模板能力的真实用武之地。

### [ ] 加第二个节点

现在所有"高可用"都是纸面上的:3 个副本全在同一台机器上,机器挂了就是全挂。
多节点之后 `topologySpreadConstraints`、`PodDisruptionBudget` 才有意义。
比继续深挖 Helm 是更大的一块。

### [ ] 想清楚要不要把发布闸口加回来

自动回填 appVersion 之后(见「已完成」),**push 到 `code` 就等于上线**,
中间没有任何人工确认。这是主动选的,但要知道换掉了什么:

之前「改 appVersion 才算发布」是一道闸——写文章 push 只是构建镜像,
你可以先看看、放几天、再决定上不上。现在没有这一步了。

如果哪天想加回来,常见做法:

- **分支策略**:日常推 `dev`,合到 `code` 才发布
- **environment + required reviewers**:GitHub Actions 的部署审批,回填那步挂在
  environment 上,需要人点一下才继续
- **给 ArgoCD 关掉 automated**:退回手动 `argocd app sync`,但那又要 ssh 上节点

现在一个人写博客,push 即上线是合理的。**等到某次手滑把半成品推上线了,再回来看这条。**

---

## 博客前端

> ⚠️ 这一节不属于本文件开头声明的范围(k8s / 基础设施)。暂时放这里是因为
> 没有更合适的地方,觉得碍事就挪走。

### [ ] 决定要不要做「英文页显示英文译文」的评论

现在中英文**共用同一个 thread**(主题 even 的设计:identifier 用
`.File.Dir + .TranslationBaseName`,并把 permalink 里的 `/en` 前缀剥掉)。
所以英文页看到的是中文评论原文。

**Disqus 给不了这个能力** —— 它只有 `this.language`,那是界面文案本地化,
评论正文不翻译。官方文档反而建议按语言分开讨论区:

> "Avoid letting the user pick the language for the discussion."

要做只能绕过 iframe(评论渲染在 disqus.com 的跨域 iframe 里,JS 碰不到它的 DOM):

1. **构建期预翻译** —— CI 里用 Disqus API 拉评论 → 复用现有的 `OPENAI_API_KEY`
   翻译 → 写成 Hugo data 文件 → 英文页静态渲染译文,下面保留 iframe 用于发表。
   无前端密钥、无运行时成本,但新评论要等下次构建才有译文。
2. **运行时前端翻译** —— 浏览器直接调 API。新评论立刻有译文,但 key 暴露、
   有 CORS 和限流、每次浏览都产生费用。
3. **放弃翻译,中英文评论分开** —— 改 identifier 加语言。最简单,
   但现有评论会从英文页消失。

**没做决定,三条路都没动。** 真要做,倾向 1(和仓库现有的构建期翻译流水线同构)。

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

- [x] **监控告警上线**(2026-08-08)
  `k8s/scripts/healthcheck.sh` + root cron 每 5 分钟,上报到 Healthchecks.io,
  邮件通知。安装步骤记在 `k8s/README.md` 第 0.3 节(**装机这步不在 git 里**)。

  **没用 SMTP 发邮件**,因为机器挂了就发不出邮件 —— 一个只会「出事时通知你」
  的系统,恰恰在最该通知你的时候是哑的。改成心跳后,「没声音」本身就是告警,
  这是纯邮件方案覆盖不了的第三种情况。

  查六项:磁盘(阈值 80%)、节点 Ready、节点 Condition、博客 Pod、
  Evicted 堆积、站点 HTTP 200。最后一项从外部真实请求,能抓到「前五项全绿
  但 nginx 返回 500」。报告塞在 ping 的 body 里,邮件正文直接看得到,不用 ssh。

  ✅ **已用 `DISK_WARN_PCT=1` 实际触发验证过告警会响。** 没验证过的告警系统
  等于没有 —— 这步别省。

- [x] **app-of-apps:ArgoCD 管理 `k8s/argocd/` 目录**(`004e52d7`,2026-08-08)
  `root` Application 指向本目录(包含它自己),手动 `apply` 从此变成一次性引导。

  ⚠️ 踩到一个只有「Application 管自己」才会暴露的坑:写 `directory: {recurse: false}`
  会导致永久 `OutOfSync` 且 sync 不掉 —— `recurse: false` 是默认值,ArgoCD 存
  spec 时把它丢掉了,于是 git 里有、集群里没有。修法是整段删掉(`f67399cf`)。

  ⚠️ 这是「ArgoCD 管我写的 manifest」,**不是「ArgoCD 管自己的安装」**。
  那 7 个 Pod 仍是手动 `apply -f install.yaml` 装的,升级还得手动。

  ⚠️ 待查:`k -n argocd get ingress argocd-server -o jsonpath='{.metadata.labels}'`
  是空的,说明 3.4.6 的资源追踪**可能不是标签式而是注解式**。如果确认是注解式,
  `blog-application.yaml` 里那段「名字必须叫 xiantang-blog」的注释有一半理由
  不成立(Helm release 名那个理由仍然成立),要去改准。

- [x] **把 ArgoCD UI 暴露到 https://argocd.vim0.com**(`a445ed24`,2026-08-08)
  Ingress 在 `k8s/argocd/ingress.yaml`,操作步骤在同目录 README。

  关键的一步是先给 argocd-server 开 `--insecure`(改 `argocd-cmd-params-cm`)。
  argocd-server 默认自己也终止 TLS 并把 HTTP 301 到 HTTPS,而 Traefik 已经在
  入口终止了 TLS、回源是明文 —— 两边都要求对方升级,浏览器就 `ERR_TOO_MANY_REDIRECTS`。
  加密没有变弱:少的只有集群内部那一跳,和博客 Pod 一样。

  证书没有额外配置就签下来了,因为 ClusterIssuer 走的是 Cloudflare **DNS-01**
  (`k8s/cluster-issuer.yaml`),校验靠 TXT 记录,和 A 记录开不开橙云无关。

  ⚠️ **这个 Ingress 是命令式管理的**,和博客的 GitOps 流程不一致 —— 改了
  `k8s/argocd/` 下的文件 push 上去,集群里什么都不会变,必须手动 apply。
  根治办法是 app-of-apps(见「学习方向」)。

  ⚠️ 现在 `admin` 是暴露在公网上的账号。**初始密码必须轮换**(它在聊天记录里
  明文出现过),轮换后删掉 `argocd-initial-admin-secret`。长期做法是接 SSO
  之后在 `argocd-cm` 里 `admin.enabled: "false"`。

- [x] **修好 Disqus 评论**(`b4485d94` / `2d36c044`,2026-08-04)
  `k8s.vim0.com` 和所有英文页的评论一直是 0 条。两个原因叠加:

  1. Disqus 后台的 trusted domain 没有 `k8s.vim0.com`(已在后台补上,不在 git 里)
  2. **主题 even 把 `var disqus_config` 写在 IIFE 内部**,它是函数局部变量,
     从来没成为全局。Disqus 的 embed.js 读的是 `window.disqus_config`,
     读不到就回退用 `window.location.href` 当 thread key。

  第 2 条才是根因,而且**一直是坏的**。中文页看起来正常纯属巧合 ——
  只有 `vim0.com/post/xxx/` 的 `location.href` 恰好等于规范 URL;
  英文页(`/en/...`)和 k8s 域名都不满足,于是各自开了空 thread。

  修法是项目级 partial 覆盖(`layouts/partials/comments.html`),
  把 `var` 改成 `window.`。顺带按 `.Lang` 设了 `this.language`。

  ⚠️ **`this.language` 要用 Django 风格 locale 码**:Hugo 的 `zh-cn` 传进去
  会被降级成通用 `zh`,必须映射成 `zh_CN`。这点文档没写,是打 embed 接口试出来的。

  ⚠️ 排查时走过一次弯路:先以为是 `hugo --minify` 把变量名压掉了(现象确实存在,
  压缩后变成 `var c`),加了 `[minify] disableJS = true`。**那是必要不充分的** ——
  局部变量就算保住名字 Disqus 也读不到。改成 `window.` 之后属性名不会被重命名,
  那条配置已撤回。**教训:验证到「HTML 里有这几个字符」不等于验证到「它生效了」**,
  真正的证据是浏览器 Network 里 embed 请求带没带 `t_i` 参数。

  遗留:Disqus 后台多了几个空 thread(修复前回退建的,如
  `https://k8s.vim0.com/post/university/`)。留着无害,介意可在
  Community → Discussions 删掉。

- [x] **CI 自动回填 appVersion**(2026-08-04)
  `build-image.yml` 最后加了一步:镜像推成功后把 `Chart.yaml` 的 `appVersion`
  改成 `sha-${GITHUB_SHA}`,用 `github-actions[bot]` 身份 commit 并 push。
  ArgoCD 轮询到就自动滚动更新,**发布全程零人工介入**。

  不会循环触发构建,两层保护:`k8s/charts/**` 在 `paths-ignore` 里;
  而且用 `GITHUB_TOKEN` 推的 commit,GitHub 本身就不会再触发 workflow。

  ⚠️ **本地下次 push 前必须先 `git pull`** —— 远端会多出 bot 的 commit,
  不 pull 会被拒绝。这是自动化的固有代价。

  ⚠️ **push 即上线,发布闸口没了。** 取舍见上面「想清楚要不要把发布闸口加回来」。

- [x] **装上 ArgoCD 并把博客迁过去**(2026-08-04)
  版本钉在 **v3.4.6**(不是 `stable`,那是会移动的指针,和 `:latest` 同一类问题)。
  装的时候要用 `kubectl apply --server-side`,否则 ApplicationSet 的 CRD 会撞上
  annotation 256KB 上限;第一次失败后重试还要 `--force-conflicts` 接管
  自己上一次 client-side apply 留下的字段所有权。

  Application 定义在 `k8s/argocd/blog-application.yaml`,**名字必须是 `xiantang-blog`**
  (原因写在文件注释里:ArgoCD 拿 Application 名当 release 名,且拿它当资源追踪
  label,而那个 label 在 Deployment 的不可变 selector 里)。

  迁移是零停机的:名字对齐后 ArgoCD 直接认领现有资源,`argocd app get` 一上来就是
  `Synced` + `Healthy`,一次 sync 都不用做。然后只删 Helm 的记账、不动资源:
  `kubectl delete secret -n default -l owner=helm,name=xiantang-blog`。

  🚫 **从此不要再对博客跑 `helm upgrade` / `rollback` / `get values`** ——
  集群里已经没有 release 了,这些命令会报 `release: not found`。变更一律走 git → ArgoCD。

  目前 **`syncPolicy.automated` 没开**,是手动 sync。开之前想清楚:
  开了之后 push 即上线,会失去「改 `Chart.yaml` 的 appVersion 才算发布」这个闸口。

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
