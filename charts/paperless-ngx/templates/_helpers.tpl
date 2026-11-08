{{/*
Expand the name of the chart.
*/}}
{{- define "paperless-ngx.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "paperless-ngx.fullname" -}}
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
{{- define "paperless-ngx.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "paperless-ngx.labels" -}}
helm.sh/chart: {{ include "paperless-ngx.chart" . }}
{{ include "paperless-ngx.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "paperless-ngx.selectorLabels" -}}
app.kubernetes.io/name: {{ include "paperless-ngx.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "paperless-ngx.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "paperless-ngx.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create environment variable for secret value
Usage: include "paperless-ngx.secretEnvVar" (dict "root" $ "secret" .Values.<secret>)
*/}}
{{- define "paperless-ngx.secretEnvVar" -}}
{{- if and .secret.secretKeyRef.name .secret.secretKeyRef.key }}
valueFrom:
  secretKeyRef:
    name: {{ tpl (toString .secret.secretKeyRef.name) .root | quote }}
    key: {{ tpl (toString .secret.secretKeyRef.key) .root | quote }}
{{- else }}
value: {{ tpl (toString .secret.value) .root | quote }}
{{- end }}
{{- end }}

{{/*
Name of the embeddings subchart Service. Mirrors the text-embeddings-inference
fullname helper, whose chart name is the "embeddings" alias.
*/}}
{{- define "paperless-ngx.embeddings.fullname" -}}
{{- $values := .Values.embeddings }}
{{- if $values.fullnameOverride }}
{{- $values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "embeddings" $values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Validate that webdav.persistence.data.claimName matches the consumption PVC.
That value is rendered via `tpl` inside the webdav subchart's own template
context, which cannot see this (parent) chart's nameOverride or
fullnameOverride. If an override changes the fullname and the value still
equals its untouched default expression, fail loudly rather than let webdav
silently mount a PVC that doesn't exist.
*/}}
{{- define "paperless-ngx.validateWebdavClaimName" -}}
{{- $defaultClaimName := `{{ ternary .Release.Name (printf "%s-paperless-ngx" .Release.Name) (contains "paperless-ngx" .Release.Name) | trunc 63 | trimSuffix "-" }}-consumption` -}}
{{- $claimName := printf "%s-consumption" (include "paperless-ngx.fullname" .) -}}
{{- if and .Values.webdav.enabled (eq .Values.webdav.persistence.data.claimName $defaultClaimName) (ne (tpl $defaultClaimName .) $claimName) }}
{{- fail (printf "webdav.persistence.data.claimName must be set to %q when nameOverride or fullnameOverride is set" $claimName) }}
{{- end }}
{{- end }}
