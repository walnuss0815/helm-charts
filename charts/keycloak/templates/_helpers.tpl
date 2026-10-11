{{/*
Expand the name of the chart.
*/}}
{{- define "keycloak.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "keycloak.fullname" -}}
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
{{- define "keycloak.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "keycloak.labels" -}}
helm.sh/chart: {{ include "keycloak.chart" . }}
{{ include "keycloak.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "keycloak.selectorLabels" -}}
app.kubernetes.io/name: {{ include "keycloak.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Selector labels of the Keycloak pods. The component label keeps other pods of
the release (e.g. the Helm test pod) out of the Service and the NetworkPolicy.
*/}}
{{- define "keycloak.serverSelectorLabels" -}}
{{ include "keycloak.selectorLabels" . }}
app.kubernetes.io/component: server
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "keycloak.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "keycloak.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Keycloak container image.
*/}}
{{- define "keycloak.image" -}}
{{- printf "%s:%s" .Values.image.repository (.Values.image.tag | default .Chart.AppVersion | toString) -}}
{{- end }}

{{/*
Returns "true" when Keycloak starts with `--optimized`.
*/}}
{{- define "keycloak.optimized" -}}
{{- if has .Values.build.mode (list "initContainer" "prebuilt") -}}true{{- end -}}
{{- end }}

{{/*
Returns "true" when the plain HTTP listener is enabled.
*/}}
{{- define "keycloak.httpEnabled" -}}
{{- if or (not .Values.tls.enabled) .Values.tls.httpEnabled -}}true{{- end -}}
{{- end }}

{{/*
Returns "true" when a value is set, i.e. neither null nor an empty string.
Unlike a plain truthiness check, `0` counts as set.
*/}}
{{- define "keycloak.isSet" -}}
{{- if not (or (kindIs "invalid" .) (eq (toString .) "")) -}}true{{- end -}}
{{- end }}

{{/*
`emptyDir` volume source with an optional size limit.
Usage: include "keycloak.emptyDir" .Values.tmpSizeLimit
*/}}
{{- define "keycloak.emptyDir" -}}
{{- if . -}}
emptyDir:
  sizeLimit: {{ . }}
{{- else -}}
emptyDir: {}
{{- end -}}
{{- end }}

{{/*
Name of the internal Service exposing the management port (health, metrics).
*/}}
{{- define "keycloak.managementServiceName" -}}
{{- printf "%s-management" (include "keycloak.fullname" . | trunc 53 | trimSuffix "-") -}}
{{- end }}

{{/*
Name of the Service port the Ingress and the HTTPRoute route to.
*/}}
{{- define "keycloak.backendPort" -}}
{{- if .Values.tls.enabled -}}
{{- .Values.service.httpsPort -}}
{{- else -}}
{{- .Values.service.port -}}
{{- end -}}
{{- end }}

{{/*
Container security context. `readOnlyRootFilesystem` is forced to `false` with
`build.mode: auto`, because Keycloak rebuilds itself into `/opt/keycloak`.
*/}}
{{- define "keycloak.securityContext" -}}
{{- $ctx := deepCopy (.Values.securityContext | default dict) -}}
{{- if eq .Values.build.mode "auto" -}}
{{- $_ := set $ctx "readOnlyRootFilesystem" false -}}
{{- end -}}
{{- toYaml $ctx -}}
{{- end }}

{{/*
Path prefix of the management interface. It inherits `http-relative-path`.
*/}}
{{- define "keycloak.managementPathPrefix" -}}
{{- .Values.keycloak.httpRelativePath | default "" | trimSuffix "/" -}}
{{- end }}

{{/*
Render a probe. HTTP probes on the `management` port get the management path
prefix and, with TLS, the HTTPS scheme, unless a scheme is set explicitly.
Usage: include "keycloak.probe" (dict "root" $ "probe" .Values.startupProbe)
*/}}
{{- define "keycloak.probe" -}}
{{- $probe := deepCopy .probe -}}
{{- if and $probe.httpGet (eq (toString $probe.httpGet.port) "management") -}}
{{- $_ := set $probe.httpGet "path" (printf "%s%s" (include "keycloak.managementPathPrefix" .root) $probe.httpGet.path) -}}
{{- if and .root.Values.tls.enabled (not $probe.httpGet.scheme) -}}
{{- $_ := set $probe.httpGet "scheme" "HTTPS" -}}
{{- end -}}
{{- end -}}
{{- toYaml $probe -}}
{{- end }}

{{/*
Environment variable name of a Keycloak option, e.g. `http-max-queued-requests`
becomes `KC_HTTP_MAX_QUEUED_REQUESTS`.
*/}}
{{- define "keycloak.optionEnvName" -}}
{{- printf "KC_%s" (regexReplaceAll "[^A-Za-z0-9]" . "_" | upper) -}}
{{- end }}

{{/*
Name of the shared non-sensitive environment ConfigMap. The build init
container and the Keycloak container both load it, so the build options of
the optimized build always match the ones at startup.
*/}}
{{- define "keycloak.envConfigName" -}}
{{- include "keycloak.fullname" . }}-env
{{- end }}

{{/*
Name of the chart-managed Secret with the bootstrap admin credentials.
*/}}
{{- define "keycloak.bootstrapAdminSecretName" -}}
{{- include "keycloak.fullname" . }}-bootstrap-admin
{{- end }}

{{/*
Returns "true" when a secret entry is configured, i.e. an inline `value` is set,
`generate` is enabled or a fully populated `secretKeyRef` is provided.
*/}}
{{- define "keycloak.secretConfigured" -}}
{{- if or .value .generate (and .secretKeyRef .secretKeyRef.name .secretKeyRef.key) -}}true{{- end -}}
{{- end }}

{{/*
Returns "true" when a secret entry references an existing Secret.
*/}}
{{- define "keycloak.secretRefSet" -}}
{{- if and .secretKeyRef .secretKeyRef.name .secretKeyRef.key -}}true{{- end -}}
{{- end }}

{{/*
Render a valueFrom block for a secret entry. A fully populated `secretKeyRef`
is used directly; otherwise the value is read from the chart-managed Secret
named by `.secret` at key `.key`.
Usage: include "keycloak.secretEnvVar" (dict "root" $ "entry" $entry "secret" $name "key" $key)
*/}}
{{- define "keycloak.secretEnvVar" -}}
{{- if include "keycloak.secretRefSet" .entry -}}
valueFrom:
  secretKeyRef:
    name: {{ tpl .entry.secretKeyRef.name .root }}
    key: {{ tpl .entry.secretKeyRef.key .root }}
{{- else -}}
valueFrom:
  secretKeyRef:
    name: {{ .secret }}
    key: {{ .key }}
{{- end }}
{{- end }}

{{/*
Value of a bootstrap admin secret entry stored in the chart-managed Secret: the
inline `value`, or with `generate` the value of the existing Secret (via
`lookup`) or a new random one.
Usage: include "keycloak.bootstrapAdminSecretValue" (dict "root" $ "entry" $entry "key" "password")
*/}}
{{- define "keycloak.bootstrapAdminSecretValue" -}}
{{- if .entry.value -}}
{{- .entry.value -}}
{{- else if .entry.generate -}}
{{- $existing := lookup "v1" "Secret" .root.Release.Namespace (include "keycloak.bootstrapAdminSecretName" .root) -}}
{{- $data := (get ($existing | default dict) "data") | default dict -}}
{{- if hasKey $data .key -}}
{{- index $data .key | b64dec -}}
{{- else -}}
{{- randAlphaNum 32 -}}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Returns "true" when the chart-managed bootstrap admin Secret is rendered.
*/}}
{{- define "keycloak.bootstrapAdminSecretEnabled" -}}
{{- if or .Values.bootstrapAdmin.user.enabled .Values.bootstrapAdmin.client.enabled -}}true{{- end -}}
{{- end }}

{{/*
Returns "true" when a bootstrap admin secret is generated.
*/}}
{{- define "keycloak.bootstrapAdminGenerate" -}}
{{- $b := .Values.bootstrapAdmin -}}
{{- if or (and $b.user.enabled $b.user.password.generate) (and $b.client.enabled $b.client.clientSecret.generate) -}}true{{- end -}}
{{- end }}

{{/*
Name of the CNPG Cluster.
*/}}
{{- define "keycloak.databaseClusterName" -}}
{{- include "keycloak.fullname" . }}-postgresql
{{- end }}

{{/*
Database host: the read-write Service of the bundled cluster or the external host.
*/}}
{{- define "keycloak.databaseHost" -}}
{{- if .Values.postgres.enabled -}}
{{- printf "%s-rw" (include "keycloak.databaseClusterName" .) -}}
{{- else -}}
{{- .Values.postgres.host -}}
{{- end -}}
{{- end }}

{{/*
Database port.
*/}}
{{- define "keycloak.databasePort" -}}
{{- if .Values.postgres.enabled -}}
{{- "5432" -}}
{{- else -}}
{{- .Values.postgres.port | default 5432 | toString -}}
{{- end -}}
{{- end }}

{{/*
Name of the chart-managed Secret with the database credentials (`username` and
`password`). Created when `postgres.password.value` is set.
*/}}
{{- define "keycloak.databaseCredentialName" -}}
{{- include "keycloak.fullname" . }}-postgresql-credentials
{{- end }}

{{/*
Returns "true" when a database password source is configured.
*/}}
{{- define "keycloak.databasePasswordProvided" -}}
{{- if or .Values.postgres.password.value (include "keycloak.secretRefSet" .Values.postgres.password) .Values.postgres.bootstrapSecretOverride -}}true{{- end -}}
{{- end }}

{{/*
Name of the Secret that bootstraps the CNPG cluster role (`username`/`password`).
*/}}
{{- define "keycloak.bootstrapSecretName" -}}
{{- if .Values.postgres.bootstrapSecretOverride -}}
{{- .Values.postgres.bootstrapSecretOverride -}}
{{- else if include "keycloak.secretRefSet" .Values.postgres.password -}}
{{- tpl .Values.postgres.password.secretKeyRef.name . -}}
{{- else -}}
{{- include "keycloak.databaseCredentialName" . -}}
{{- end -}}
{{- end }}

{{/*
valueFrom block of the database password. Falls back to the Secret
CloudNativePG generates for the application role.
*/}}
{{- define "keycloak.databasePasswordEnv" -}}
{{- if .Values.postgres.bootstrapSecretOverride -}}
valueFrom:
  secretKeyRef:
    name: {{ .Values.postgres.bootstrapSecretOverride }}
    key: password
{{- else if include "keycloak.secretRefSet" .Values.postgres.password -}}
valueFrom:
  secretKeyRef:
    name: {{ tpl .Values.postgres.password.secretKeyRef.name . }}
    key: {{ tpl .Values.postgres.password.secretKeyRef.key . }}
{{- else if .Values.postgres.password.value -}}
valueFrom:
  secretKeyRef:
    name: {{ include "keycloak.databaseCredentialName" . }}
    key: password
{{- else -}}
valueFrom:
  secretKeyRef:
    name: {{ include "keycloak.databaseClusterName" . }}-app
    key: password
{{- end }}
{{- end }}

{{/*
Effective TLS mode of the database connection.
*/}}
{{- define "keycloak.databaseTlsMode" -}}
{{- if .Values.postgres.tls.mode -}}
{{- .Values.postgres.tls.mode -}}
{{- else if .Values.postgres.enabled -}}
verify-server
{{- else -}}
disabled
{{- end -}}
{{- end }}

{{/*
Secret name and key of the database CA certificate.
*/}}
{{- define "keycloak.databaseCaSecretName" -}}
{{- if .Values.postgres.tls.caSecretKeyRef.name -}}
{{- tpl .Values.postgres.tls.caSecretKeyRef.name . -}}
{{- else if .Values.postgres.enabled -}}
{{- include "keycloak.databaseClusterName" . }}-ca
{{- end -}}
{{- end }}

{{- define "keycloak.databaseCaSecretKey" -}}
{{- .Values.postgres.tls.caSecretKeyRef.key | default "ca.crt" -}}
{{- end }}

{{/*
PostgreSQL image of the CNPG cluster. It is always pinned so the PostgreSQL
major version cannot change with an operator upgrade.
*/}}
{{- define "keycloak.databaseImage" -}}
{{- printf "%s:%s" (required "postgres.image.repository is required" .Values.postgres.image.repository) (required "postgres.image.tag is required" (toString .Values.postgres.image.tag)) -}}
{{- end }}

{{/*
Name of the Barman Cloud ObjectStore used for WAL archiving and base backups.
*/}}
{{- define "keycloak.backupObjectStoreName" -}}
{{- if .Values.postgres.backup.objectStore.create -}}
{{- include "keycloak.databaseClusterName" . -}}
{{- else -}}
{{- .Values.postgres.backup.objectStore.name -}}
{{- end -}}
{{- end }}

{{/*
Returns "true" when the chart creates the Barman Cloud ObjectStore.
*/}}
{{- define "keycloak.backupObjectStoreCreate" -}}
{{- $bk := .Values.postgres.backup -}}
{{- if and .Values.postgres.enabled $bk.objectStore.create $bk.objectStore.configuration (or $bk.enabled .Values.postgres.recovery.enabled) -}}true{{- end -}}
{{- end }}

{{/*
Returns "true" when WAL archiving through the Barman Cloud Plugin is enabled:
always for `method: plugin`, and for `method: volumeSnapshot` when an object
store is configured.
*/}}
{{- define "keycloak.walArchivingEnabled" -}}
{{- $bk := .Values.postgres.backup -}}
{{- if and .Values.postgres.enabled $bk.enabled -}}
{{- if or (eq $bk.method "plugin") (and $bk.objectStore.create $bk.objectStore.configuration) (and (not $bk.objectStore.create) $bk.objectStore.name) -}}true{{- end -}}
{{- end -}}
{{- end }}

{{/*
Normalized list of `themes.custom` as YAML. Each entry has `name`, `type`
(`directory` or `jar`), `path`, `source` (`copy`, `imageVolume` or
`configMap`), `index` (used for container names, as theme names may not be
valid DNS labels), `volume` (the volume the theme is mounted from) and the
source settings.
Usage: fromYamlArray (include "keycloak.themes" .)
*/}}
{{- define "keycloak.themes" -}}
{{- $list := list -}}
{{- range $i, $t := .Values.themes.custom -}}
{{- $type := $t.type | default "directory" -}}
{{- $source := "configMap" -}}
{{- if $t.image -}}
{{- $source = ternary "imageVolume" "copy" (eq (toString $t.imageVolume) "true") -}}
{{- end -}}
{{- $image := dict -}}
{{- if $t.image -}}
{{- $image = dict "reference" (printf "%s:%s" (tpl (toString $t.image.repository) $) (tpl (toString $t.image.tag) $)) "pullPolicy" ($t.image.pullPolicy | default "IfNotPresent") -}}
{{- end -}}
{{- $volume := ternary "themes" (printf "theme-%d" $i) (eq $source "copy") -}}
{{- $list = append $list (dict "index" $i "volume" $volume "name" (toString $t.name) "type" $type "path" ($t.path | default (ternary "/theme.jar" "/theme" (eq $type "jar"))) "source" $source "image" $image "configMap" ($t.configMap | default dict)) -}}
{{- end -}}
{{- toYaml $list -}}
{{- end }}

{{/*
Returns "true" when a theme is copied into the `themes` emptyDir.
*/}}
{{- define "keycloak.themesCopy" -}}
{{- range fromYamlArray (include "keycloak.themes" .) -}}
{{- if eq .source "copy" -}}true{{- end -}}
{{- end -}}
{{- end }}
