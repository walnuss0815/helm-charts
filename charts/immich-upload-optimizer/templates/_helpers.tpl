{{/*
Expand the name of the chart.
*/}}
{{- define "immich-upload-optimizer.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "immich-upload-optimizer.fullname" -}}
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
{{- define "immich-upload-optimizer.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "immich-upload-optimizer.labels" -}}
helm.sh/chart: {{ include "immich-upload-optimizer.chart" . }}
{{ include "immich-upload-optimizer.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "immich-upload-optimizer.selectorLabels" -}}
app.kubernetes.io/name: {{ include "immich-upload-optimizer.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "immich-upload-optimizer.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "immich-upload-optimizer.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Name of the tasks ConfigMap.
*/}}
{{- define "immich-upload-optimizer.configName" -}}
{{- include "immich-upload-optimizer.fullname" . }}-tasks
{{- end }}

{{/*
Fixed filename of the tasks file inside the config volume.
*/}}
{{- define "immich-upload-optimizer.configFilename" -}}
tasks.yaml
{{- end }}

{{/*
Resolve the container image.
*/}}
{{- define "immich-upload-optimizer.image" -}}
{{- printf "%s:%s" .Values.image.repository (.Values.image.tag | default .Chart.AppVersion) -}}
{{- end }}
