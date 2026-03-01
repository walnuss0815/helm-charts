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
