{{/*
Expand the name of the chart.
*/}}
{{- define "openchamber.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "openchamber.fullname" -}}
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
{{- define "openchamber.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "openchamber.labels" -}}
helm.sh/chart: {{ include "openchamber.chart" . }}
{{ include "openchamber.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "openchamber.selectorLabels" -}}
app.kubernetes.io/name: {{ include "openchamber.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "openchamber.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "openchamber.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Home directory of the user in the image
*/}}
{{- define "openchamber.home" -}}
/home/openchamber
{{- end }}

{{/*
Name of the chart-managed Secret
*/}}
{{- define "openchamber.secretName" -}}
{{- include "openchamber.fullname" . }}
{{- end }}

{{/*
Name of the data PVC
*/}}
{{- define "openchamber.dataClaimName" -}}
{{- default (printf "%s-data" (include "openchamber.fullname" .)) .Values.persistence.data.existingClaim }}
{{- end }}

{{/*
Name of the workspaces PVC
*/}}
{{- define "openchamber.workspacesClaimName" -}}
{{- default (printf "%s-workspaces" (include "openchamber.fullname" .)) .Values.persistence.workspaces.existingClaim }}
{{- end }}

{{/*
Returns "true" when a {value, secretKeyRef} object has a secretKeyRef
*/}}
{{- define "openchamber.hasSecretRef" -}}
{{- if and . .secretKeyRef .secretKeyRef.name .secretKeyRef.key }}true{{ end }}
{{- end }}

{{/*
Returns "true" when a {value, secretKeyRef} object is configured
*/}}
{{- define "openchamber.hasSecret" -}}
{{- if or (include "openchamber.hasSecretRef" .) (and . .value) }}true{{ end }}
{{- end }}

{{/*
Secret-backed values that are configured, as a dict of
<chart Secret key> => {env, item}. Only enabled features are included.
*/}}
{{- define "openchamber.secretItems" -}}
{{- $items := dict }}
{{- if .Values.auth.uiPassword.enabled }}
{{- $_ := set $items "ui-password" (dict "env" "OPENCHAMBER_UI_PASSWORD" "item" .Values.auth.uiPassword) }}
{{- end }}
{{- $_ := set $items "jwt-secret" (dict "env" "OPENCODE_JWT_SECRET" "item" .Values.auth.jwtSecret) }}
{{- if .Values.tunnel.enabled }}
{{- $_ := set $items "tunnel-token" (dict "env" "OPENCHAMBER_TUNNEL_TOKEN" "item" .Values.tunnel.token) }}
{{- $_ := set $items "ngrok-authtoken" (dict "env" "NGROK_AUTHTOKEN" "item" .Values.tunnel.ngrokAuthToken) }}
{{- end }}
{{- if .Values.enterprise.enabled }}
{{- $_ := set $items "jev-api-key" (dict "env" "OPENCHAMBER_JEV_API_KEY" "item" .Values.enterprise.jev.apiKey) }}
{{- end }}
{{- $configured := dict }}
{{- range $key, $entry := $items }}
{{- if include "openchamber.hasSecret" $entry.item }}
{{- $_ := set $configured $key $entry }}
{{- end }}
{{- end }}
{{- toYaml $configured }}
{{- end }}

{{/*
Environment variables for secret-backed values. Inline values are read from
the chart-managed Secret, references from the referenced Secret.
*/}}
{{- define "openchamber.secretEnv" -}}
{{- $items := include "openchamber.secretItems" . | fromYaml }}
{{- range $key, $entry := $items }}
- name: {{ $entry.env }}
  valueFrom:
    secretKeyRef:
      {{- if include "openchamber.hasSecretRef" $entry.item }}
      name: {{ include "openchamber.secretRefName" (dict "ref" $entry.item.secretKeyRef "ctx" $) }}
      key: {{ include "openchamber.secretRefKey" (dict "ref" $entry.item.secretKeyRef "ctx" $) }}
      {{- else }}
      name: {{ include "openchamber.secretName" $ }}
      key: {{ $key }}
      {{- end }}
{{- end }}
{{- end }}

{{/*
External URL used for pairing links (OPENCHAMBER_LAN_URL)
*/}}
{{- define "openchamber.lanUrl" -}}
{{- if .Values.openchamber.lanUrl }}
{{- .Values.openchamber.lanUrl }}
{{- else if and .Values.ingress.enabled .Values.ingress.hosts }}
{{- $host := (first .Values.ingress.hosts).host }}
{{- /* A wildcard host is not a reachable origin; set openchamber.lanUrl instead */}}
{{- if and $host (not (hasPrefix "*" $host)) }}
{{- $tls := false }}
{{- range .Values.ingress.tls }}
{{- if has $host .hosts }}{{ $tls = true }}{{ end }}
{{- end }}
{{- printf "%s://%s" (ternary "https" "http" $tls) $host }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Name and key of a secretKeyRef, rendered with tpl.
Usage: include "openchamber.secretRefName" (dict "ref" .secretKeyRef "ctx" $)
*/}}
{{- define "openchamber.secretRefName" -}}
{{- tpl .ref.name .ctx }}
{{- end }}

{{- define "openchamber.secretRefKey" -}}
{{- tpl .ref.key .ctx }}
{{- end }}

{{/*
Validate values and fail early on unsafe or incomplete configuration
*/}}
{{- define "openchamber.validate" -}}
{{- if and .Values.auth.uiPassword.enabled (not (include "openchamber.hasSecret" .Values.auth.uiPassword)) }}
{{- fail "auth.uiPassword.enabled=true requires auth.uiPassword.value or auth.uiPassword.secretKeyRef (name and key). To run without a UI password, explicitly set auth.uiPassword.enabled=false." }}
{{- end }}
{{- if and .Values.opencode.external.enabled (not .Values.opencode.external.host) }}
{{- fail "opencode.external.enabled=true requires opencode.external.host (e.g. http://opencode:4096)." }}
{{- end }}
{{- if and .Values.tunnel.enabled (eq .Values.tunnel.mode "managed-remote") }}
{{- if or (not .Values.tunnel.hostname) (not (include "openchamber.hasSecret" .Values.tunnel.token)) }}
{{- fail "tunnel.mode=managed-remote requires tunnel.hostname and tunnel.token (value or secretKeyRef)." }}
{{- end }}
{{- end }}
{{- if and .Values.policy.enabled (not .Values.policy.existingSecret.name) (not .Values.policy.content) }}
{{- fail "policy.enabled=true requires policy.content or policy.existingSecret.name." }}
{{- end }}
{{- end }}
