{{/*
Expand the name of the chart.
*/}}
{{- define "immich.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "immich.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "immich.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "immich.labels" -}}
helm.sh/chart: {{ include "immich.chart" . }}
{{ include "immich.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "immich.selectorLabels" -}}
app.kubernetes.io/name: {{ include "immich.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Selector labels scoped to a workload component (server, microservices, machine-learning).
Usage: include "immich.componentSelectorLabels" (dict "root" $ "component" "server")
*/}}
{{- define "immich.componentSelectorLabels" -}}
{{ include "immich.selectorLabels" .root }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "immich.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "immich.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Resolve the Immich server container image (shared by the server and
microservices workloads). Usage: include "immich.image" (dict "root" $ "workload" $sub)
*/}}
{{- define "immich.image" -}}
{{- $root := .root -}}
{{- $workload := .workload -}}
{{- $repository := $workload.image.repository | default $root.Values.image.repository -}}
{{- $tag := $workload.image.tag | default $root.Values.image.tag | default $root.Chart.AppVersion -}}
{{- $suffix := $workload.image.tagSuffix | default "" -}}
{{- printf "%s:%s%s" $repository $tag $suffix -}}
{{- end }}

{{/*
Resolve the Redis/Valkey host. When the bundled valkey subchart is enabled and no
explicit host is given, the subchart service name (<release>-valkey) is used.
*/}}
{{- define "immich.redisHost" -}}
{{- if .Values.redis.host -}}
{{- .Values.redis.host -}}
{{- else if .Values.valkey.enabled -}}
{{- printf "%s-valkey" .Release.Name -}}
{{- else -}}
{{- fail "redis.host must be configured when valkey.enabled is false" -}}
{{- end -}}
{{- end }}

{{/*
Resolve the Redis/Valkey port.
*/}}
{{- define "immich.redisPort" -}}
{{- if .Values.redis.port -}}
{{- .Values.redis.port | toString -}}
{{- else -}}
{{- "6379" -}}
{{- end -}}
{{- end }}

{{/*
Resolve the PostgreSQL host. When the bundled CNPG cluster is enabled, the cluster's
read-write service (<fullname>-postgresql-rw) is used; otherwise the external host
configured via `postgres.host` is required.
*/}}
{{- define "immich.databaseHost" -}}
{{- if .Values.postgres.enabled -}}
{{- printf "%s-postgresql-rw" (include "immich.fullname" .) -}}
{{- else -}}
{{- .Values.postgres.host | default "postgres" -}}
{{- end -}}
{{- end }}

{{/*
Resolve the PostgreSQL port.
*/}}
{{- define "immich.databasePort" -}}
{{- if .Values.postgres.enabled -}}
{{- "5432" -}}
{{- else if .Values.postgres.port -}}
{{- .Values.postgres.port | toString -}}
{{- else -}}
{{- "5432" -}}
{{- end -}}
{{- end }}

{{/*
Resolve the PostgreSQL username.
*/}}
{{- define "immich.databaseUser" -}}
{{- .Values.postgres.user | default "immich" -}}
{{- end }}

{{/*
Resolve the PostgreSQL database name.
*/}}
{{- define "immich.databaseName" -}}
{{- .Values.postgres.database | default "immich" -}}
{{- end }}

{{/*
Resolve the PostgreSQL container image (only used when the CNPG cluster is enabled).
Returns an empty string when no repository is configured, so the CloudNativePG
operator applies its default image.
*/}}
{{- define "immich.databaseImage" -}}
{{- if .Values.postgres.image.repository -}}
{{- printf "%s:%s" .Values.postgres.image.repository (.Values.postgres.image.tag | default "") -}}
{{- end -}}
{{- end }}

{{/*
Returns "true" when a secret entry is configured, i.e. an inline `value` is set
or a fully populated `secretKeyRef` is provided.
*/}}
{{- define "immich.secretConfigured" -}}
{{- if or .value (and .secretKeyRef .secretKeyRef.name .secretKeyRef.key) -}}true{{- end -}}
{{- end }}

{{/*
Render a valueFrom block referencing a secret entry. When `secretKeyRef` is fully
populated it is used directly; otherwise the inline `value` is resolved from the
chart-managed Secret named by `.secret` at key `.key`.
*/}}
{{- define "immich.secretEnvVar" -}}
{{- if and .entry.secretKeyRef.name .entry.secretKeyRef.key -}}
valueFrom:
  secretKeyRef:
    name: {{ tpl .entry.secretKeyRef.name .root }}
    key: {{ tpl .entry.secretKeyRef.key .root }}
{{- else if .entry.value -}}
valueFrom:
  secretKeyRef:
    name: {{ .secret }}
    key: {{ .key }}
{{- end }}
{{- end }}

{{/*
Name of the chart-managed Secret carrying the PostgreSQL credentials (`password`
and, for the CNPG bootstrap, `username` keys). Created when `postgres.password.value`
is set.
*/}}
{{- define "immich.databaseCredentialName" -}}
{{- include "immich.fullname" . }}-postgresql-credentials
{{- end }}

{{/*
Name of the chart-managed Secret carrying the Redis/Valkey password.
Created when `redis.password.value` is set.
*/}}
{{- define "immich.redisPasswordName" -}}
{{- include "immich.fullname" . }}-redis-password
{{- end }}

{{/*
Name of the chart-managed Secret carrying the JWT secret.
Created when `jwtSecret.value` is set.
*/}}
{{- define "immich.jwtSecretName" -}}
{{- include "immich.fullname" . }}-jwt-secret
{{- end }}

{{/*
Name of the shared non-sensitive configuration ConfigMap.
*/}}
{{- define "immich.configName" -}}
{{- include "immich.fullname" . }}-config
{{- end }}

{{/*
Name of the CNPG bootstrap initdb Secret. Either the chart-managed Secret (when the
db password is provided inline), the Secret referenced by `postgres.password.secretKeyRef`
or a user-supplied existing Secret.
*/}}
{{- define "immich.bootstrapSecretName" -}}
{{- if .Values.postgres.bootstrapSecretOverride -}}
{{- .Values.postgres.bootstrapSecretOverride -}}
{{- else if and .Values.postgres.password.secretKeyRef.name .Values.postgres.password.secretKeyRef.key -}}
{{- .Values.postgres.password.secretKeyRef.name -}}
{{- else -}}
{{- include "immich.databaseCredentialName" . -}}
{{- end -}}
{{- end }}

{{/*
Returns "true" when an explicit database password source is configured: an
inline `value`, a fully populated `secretKeyRef` or a `bootstrapSecretOverride`.
*/}}
{{- define "immich.databasePasswordProvided" -}}
{{- if or .Values.postgres.password.value (and .Values.postgres.password.secretKeyRef.name .Values.postgres.password.secretKeyRef.key) .Values.postgres.bootstrapSecretOverride -}}
true
{{- end -}}
{{- end }}

{{/*
Render the valueFrom block for DB_PASSWORD. It follows the same precedence as
the CNPG bootstrap secret so the workloads always authenticate with the
credentials the database was bootstrapped with. When no password source is
configured and the chart-managed CNPG cluster is used, the operator generates
the `<fullname>-postgresql-app` Secret itself (random password, stable across
updates).
*/}}
{{- define "immich.databasePasswordEnv" -}}
{{- if .Values.postgres.bootstrapSecretOverride -}}
valueFrom:
  secretKeyRef:
    name: {{ .Values.postgres.bootstrapSecretOverride }}
    key: password
{{- else if and .Values.postgres.password.secretKeyRef.name .Values.postgres.password.secretKeyRef.key -}}
valueFrom:
  secretKeyRef:
    name: {{ tpl .Values.postgres.password.secretKeyRef.name . }}
    key: {{ tpl .Values.postgres.password.secretKeyRef.key . }}
{{- else if .Values.postgres.password.value -}}
valueFrom:
  secretKeyRef:
    name: {{ include "immich.databaseCredentialName" . }}
    key: password
{{- else -}}
valueFrom:
  secretKeyRef:
    name: {{ include "immich.fullname" . }}-postgresql-app
    key: password
{{- end }}
{{- end }}

{{/*
Name of the media library volume / PVC referenced by the server and microservices workloads.
*/}}
{{- define "immich.mediaVolumeName" -}}
{{- if .Values.persistence.media.existingClaim -}}
{{- .Values.persistence.media.existingClaim -}}
{{- else -}}
{{- printf "%s-media" (include "immich.fullname" .) -}}
{{- end -}}
{{- end }}

{{/*
Returns "true" when a `config.env.*` entry is configured with a value source: an
inline `value`, a fully populated `secretKeyRef` or a fully populated
`configMapRef`. Used to fail fast when an entry carries no source.
Usage: include "immich.configEnvConfigured" (dict "entry" $entry)
*/}}
{{- define "immich.configEnvConfigured" -}}
{{- $secretRef := false -}}
{{- if .entry.secretKeyRef }}{{- if and .entry.secretKeyRef.name .entry.secretKeyRef.key }}{{- $secretRef = true }}{{- end }}{{- end }}
{{- $cmRef := false -}}
{{- if .entry.configMapRef }}{{- if and .entry.configMapRef.name .entry.configMapRef.key }}{{- $cmRef = true }}{{- end }}{{- end }}
{{- if or .entry.value $secretRef $cmRef -}}true{{- end -}}
{{- end }}

{{/*
Render the value source for a single `config.env.*` entry. Supports a plain
`value`, an existing `secretKeyRef` (rendered via `secretKeyRef`) or a
`configMapRef` (rendered via `configMapKeyRef`).
Usage: include "immich.configEnvVar" (dict "root" $ "entry" $entry)
*/}}
{{- define "immich.configEnvVar" -}}
{{- $secretRef := false -}}
{{- if .entry.secretKeyRef }}{{- if and .entry.secretKeyRef.name .entry.secretKeyRef.key }}{{- $secretRef = true }}{{- end }}{{- end }}
{{- $cmRef := false -}}
{{- if .entry.configMapRef }}{{- if and .entry.configMapRef.name .entry.configMapRef.key }}{{- $cmRef = true }}{{- end }}{{- end }}
{{- if $secretRef -}}
valueFrom:
  secretKeyRef:
    name: {{ tpl .entry.secretKeyRef.name .root }}
    key: {{ tpl .entry.secretKeyRef.key .root }}
{{- else if $cmRef -}}
valueFrom:
  configMapKeyRef:
    name: {{ tpl .entry.configMapRef.name .root }}
    key: {{ tpl .entry.configMapRef.key .root }}
{{- else -}}
value: {{ tpl .entry.value .root | quote }}
{{- end -}}
{{- end }}

{{/*
Name of the ConfigMap carrying the substitution script (`<fullname>-scripts`).
*/}}
{{- define "immich.configScriptsName" -}}
{{- include "immich.fullname" . }}-scripts
{{- end }}

{{/*
Fixed filename of the rendered Immich config file inside the container.
*/}}
{{- define "immich.configFilename" -}}
immich.yaml
{{- end }}

{{/*
Fixed container path of the final config file, exposed to the server
via `IMMICH_CONFIG_FILE`.
*/}}
{{- define "immich.configFilePath" -}}
/config/{{ include "immich.configFilename" . }}
{{- end }}

{{/*
Name of the machine learning model cache volume / PVC.
*/}}
{{- define "immich.modelCacheVolumeName" -}}
{{- if .Values.persistence.modelCache.existingClaim -}}
{{- .Values.persistence.modelCache.existingClaim -}}
{{- else -}}
{{- printf "%s-model-cache" (include "immich.fullname" .) -}}
{{- end -}}
{{- end }}
