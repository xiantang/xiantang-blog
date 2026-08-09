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

**规则 1（untagged）** 清理的是 `latest` 被覆盖后留下的孤儿镜像。CI 每次构建
都会把 `latest` 指向新镜像，旧的那个就失去了所有标签。它们不占多少空间，
但会让 `describe-images` 的输出越来越难看。

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

### 为什么不开 IMMUTABLE 标签

`aws ecr put-image-tag-mutability --image-tag-mutability IMMUTABLE` 能强制
「同一个 tag 不许覆盖推送」，正好匹配这套发布流程「`sha-<commit>` 不可变」
的前提。

**但现在开了 CI 会失败** —— `build-image.yml` 同时推 `latest`
（`type=raw,value=latest`），而 `latest` 天生要被覆盖。

要开的话得先把 `latest` 那行去掉。它现在没有任何东西在用（集群拉的是
`sha-` tag），留着纯粹是历史惯性。这件事排在 `TODO.md` 里。
