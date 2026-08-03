{{/*
资源名。用 release 名而不是写死 "xiantang-blog"，这样同一个 chart 可以在同一集群里
装两份（比如 blog 和 blog-staging）而不撞名。
truncate 63 是因为 k8s 的 label value 上限就是 63 字符。
*/}}
{{- define "blog.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
selector labels：Deployment.spec.selector 是**不可变字段**，一旦创建就改不了。
所以这组 label 必须保持最小、稳定，绝对不能包含版本号之类会变的东西。
*/}}
{{- define "blog.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
完整 label 集：selector labels + 会变化的元信息。
用在 metadata.labels 上（可变），不能用在 selector 上。
*/}}
{{- define "blog.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
{{ include "blog.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
