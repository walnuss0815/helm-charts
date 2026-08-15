{{/*
Expand the name of the chart.
*/}}
{{- define "immich-kiosk.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "immich-kiosk.fullname" -}}
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
{{- define "immich-kiosk.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "immich-kiosk.labels" -}}
helm.sh/chart: {{ include "immich-kiosk.chart" . }}
{{ include "immich-kiosk.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "immich-kiosk.selectorLabels" -}}
app.kubernetes.io/name: {{ include "immich-kiosk.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "immich-kiosk.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "immich-kiosk.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create environment variable for secret value
*/}}
{{- define "immich-kiosk.secretEnvVar" -}}
{{- if and .secretKeyRef.name .secretKeyRef.key }}
valueFrom:
  secretKeyRef:
    name: {{ tpl .secretKeyRef.name . }}
    key: {{ tpl .secretKeyRef.key . }}
{{- else }}
value: {{ tpl .value . }}
{{- end }}
{{- end }}

{{/*
Returns "true" when a secret entry is configured, i.e. an inline `value` is set
or a fully populated `secretKeyRef` is provided.
Usage: include "immich-kiosk.secretConfigured" .Values.password
*/}}
{{- define "immich-kiosk.secretConfigured" -}}
{{- if or .value (and .secretKeyRef .secretKeyRef.name .secretKeyRef.key) -}}true{{- end -}}
{{- end }}

{{/*
Resolve the name of the Kubernetes Secret backing a secret entry.
A fully populated `secretKeyRef` wins; otherwise the chart-managed Secret
named `<fullname>-<suffix>` is used.
Usage: include "immich-kiosk.secretName" (dict "root" $ "config" .Values.password "suffix" "password")
*/}}
{{- define "immich-kiosk.secretName" -}}
{{- if and .config.secretKeyRef.name .config.secretKeyRef.key -}}
{{- .config.secretKeyRef.name -}}
{{- else -}}
{{- include "immich-kiosk.fullname" .root }}-{{ .suffix }}
{{- end -}}
{{- end -}}

{{/*
Resolve the key within a Secret backing a secret entry.
Falls back to the chart-managed key given via `default`.
Usage: include "immich-kiosk.secretKey" (dict "config" .Values.password "default" "password")
*/}}
{{- define "immich-kiosk.secretKey" -}}
{{- if and .config.secretKeyRef.name .config.secretKeyRef.key -}}
{{- .config.secretKeyRef.key -}}
{{- else -}}
{{- .default -}}
{{- end -}}
{{- end -}}
