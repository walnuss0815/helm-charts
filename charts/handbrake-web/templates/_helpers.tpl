{{/*
Expand the name of the chart.
*/}}
{{- define "handbrake-web.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "handbrake-web.fullname" -}}
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
{{- define "handbrake-web.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "handbrake-web.labels" -}}
helm.sh/chart: {{ include "handbrake-web.chart" . }}
{{ include "handbrake-web.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "handbrake-web.selectorLabels" -}}
app.kubernetes.io/name: {{ include "handbrake-web.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Worker labels
*/}}
{{- define "handbrake-web.worker.labels" -}}
helm.sh/chart: {{ include "handbrake-web.chart" . }}
{{ include "handbrake-web.worker.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Worker selector labels
*/}}
{{- define "handbrake-web.worker.selectorLabels" -}}
app.kubernetes.io/name: {{ include "handbrake-web.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: worker
{{- end }}

{{/*
Server labels
*/}}
{{- define "handbrake-web.server.labels" -}}
helm.sh/chart: {{ include "handbrake-web.chart" . }}
{{ include "handbrake-web.server.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Server selector labels
*/}}
{{- define "handbrake-web.server.selectorLabels" -}}
app.kubernetes.io/name: {{ include "handbrake-web.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: server
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "handbrake-web.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "handbrake-web.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Validate that webdav.persistence.data.claimName accounts for fullnameOverride.
That value is rendered via `tpl` inside the webdav subchart's own template
context, which cannot see this (parent) chart's .Values.fullnameOverride, so
it cannot auto-adjust. If fullnameOverride is set and this value still equals
its untouched default expression, fail loudly rather than let webdav silently
mount a PVC that doesn't exist.
*/}}
{{- define "handbrake-web.validateWebdavClaimName" -}}
{{- $defaultClaimName := `{{ if contains "handbrake-web" .Release.Name }}{{ .Release.Name }}{{ else }}{{ .Release.Name }}-handbrake-web{{ end }}-video` -}}
{{- if and .Values.fullnameOverride .Values.webdav.enabled (eq .Values.webdav.persistence.data.claimName $defaultClaimName) }}
{{- fail (printf "fullnameOverride is set to %q, but webdav.persistence.data.claimName still uses its default expression, which does not account for fullnameOverride. Update webdav.persistence.data.claimName in your values to reference '%s-video' instead." .Values.fullnameOverride .Values.fullnameOverride) }}
{{- end }}
{{- end }}
