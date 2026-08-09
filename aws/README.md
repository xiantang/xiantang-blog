# `aws/`

账号级的配置，**不由 ArgoCD 管理** —— 这些是 AWS 资源，不是 k8s 对象。
放在这里是为了让配置有个可读、可 diff 的出处，以后转 Terraform 时直接就是
对应资源的输入。

下发一律手动，改了不会自动生效。

| 文件 | 对应资源 |
|---|---|
| `ecr-lifecycle-policy.json` | `xiantang-blog` 仓库的生命周期策略 |

## ECR 生命周期策略

CI 每次提交都推一个新镜像，ECR 存储约 $0.10/GB/月，只增不减。这个策略负责收尾。

⚠️ **先 preview，再 apply。过期是不可逆的。**

```bash
# 1. 预览会删掉哪些（不实际删除）
aws ecr start-lifecycle-policy-preview \
  --repository-name xiantang-blog \
  --lifecycle-policy-text "$(cat aws/ecr-lifecycle-policy.json)"

# 稍等几秒，看结果
aws ecr get-lifecycle-policy-preview \
  --repository-name xiantang-blog \
  --query 'previewResults[].{Tags:imageTags,Action:action.type}' --output table

# 2. 确认无误后正式生效
aws ecr put-lifecycle-policy \
  --repository-name xiantang-blog \
  --lifecycle-policy-text "$(cat aws/ecr-lifecycle-policy.json)"
```

查看当前生效的策略：

```bash
aws ecr get-lifecycle-policy --repository-name xiantang-blog --query 'lifecyclePolicyText' --output text | jq
```

### 两条规则的取舍

**规则 1（untagged）** 原本清理的是 `latest` 被覆盖后留下的孤儿镜像 —— CI 每次
构建都把 `latest` 指向新镜像，旧的那个就失去了所有标签。现在 CI 不推 `latest`
了，这条基本不会再命中，留着是兜底（比如手动推错一个 tag 之后重推）。

⚠️ 这里有个跟多架构构建相关的坑要留意：镜像是 `linux/amd64,linux/arm64` 一起
推的，顶层是一个 manifest list，底下两个平台镜像自己**没有 tag**。如果 ECR 把
它们算作 untagged 并按这条规则删掉，manifest list 就会指向不存在的层。
**每次改这条规则都先跑 preview 确认删的是什么** —— preview 会把具体 digest
列出来，比在这里猜可靠。

**规则 2（保留 20 个）** 是回滚窗口。`git revert` 一个旧 commit 会把
`appVersion` 指回那个 `sha-`，如果对应镜像已经被清掉，回滚就会失败在
`ImagePullBackOff`。20 次提交按当前节奏够用几周。

⚠️ **ECR 不知道哪个镜像正在被集群使用。** 生命周期策略纯粹按时间和数量算，
不会因为「这个镜像正跑在生产上」而跳过它。目前安全是因为
`appVersion` 每次提交都会更新，线上跑的永远是最新的那个 ——
**但如果哪天你长期停在一个旧版本上不发布，然后又推了 20 次别的提交，
那个正在服务的镜像会被删掉。**（已经拉到节点上的镜像不受影响，
但新 Pod 起不来，扩容和重启会挂。）

真要固定在旧版本运行，先把 `countNumber` 调大，或者给那个 tag 单独加一条
保留规则。

### IMMUTABLE 标签

`aws ecr put-image-tag-mutability --image-tag-mutability IMMUTABLE` 强制
「同一个 tag 不许覆盖推送」，正好匹配这套发布流程「`sha-<commit>` 不可变」
的前提 —— 这样「`Chart.yaml` 里写的 tag 指向哪个镜像」就由 ECR 保证，
不再只是一个约定。

前提条件已经满足：`build-image.yml` 不再推 `latest`（那行去掉了，因为
`latest` 天生要被覆盖，跟 IMMUTABLE 互斥）。

```bash
# 先确认 CI 真的不推 latest 了 —— 去掉那行之后至少跑过一次构建再开
aws ecr describe-images --repository-name xiantang-blog \
  --query 'sort_by(imageDetails,&imagePushedAt)[-3:].{Pushed:imagePushedAt,Tags:imageTags}' \
  --output table

aws ecr put-image-tag-mutability \
  --repository-name xiantang-blog --image-tag-mutability IMMUTABLE
```

开了之后，重跑一次同一个 commit 的构建会在 push 阶段失败
（`ImageTagAlreadyExistsException`）—— 这是预期行为，不是 CI 坏了。
真需要重推同一个 tag，只能先 `batch-delete-image` 删掉旧的。

历史上那个 `latest` tag 不用特意处理：它挂在某个 `sha-` 镜像上，
等规则 2 把那个镜像淘汰掉时会一起消失。
