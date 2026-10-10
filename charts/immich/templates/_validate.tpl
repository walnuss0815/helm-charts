{{/*
Fail fast on invalid or removed values. Included once from the server
Deployment, which is always rendered.
*/}}
{{- define "immich.validateValues" -}}
{{- if and (not .Values.postgres.enabled) (not (include "immich.databasePasswordProvided" .)) }}
{{- fail "postgres.password (value or secretKeyRef) is required when postgres.enabled is false" }}
{{- end }}
{{- if and .Values.config.env (not (include "immich.configFileEnabled" .)) }}
{{- fail "config.env is set but config.content is empty: the placeholders are only used by the config file" }}
{{- end }}
{{- range $token, $entry := .Values.config.env }}
{{- if not (include "immich.configEnvConfigured" (dict "entry" $entry)) }}
{{- fail (printf "config.env.%s must set either value, secretKeyRef or configMapRef" $token) }}
{{- end }}
{{- end }}
{{- /* Removed values: fail instead of silently ignoring them */ -}}
{{- with .Values.jwtSecret }}
{{- if or .value (and .secretKeyRef .secretKeyRef.name) }}
{{- fail "jwtSecret was removed: Immich does not read a JWT secret (sessions are stored in the database). Remove the value" }}
{{- end }}
{{- end }}
{{- if and .Values.server .Values.server.transcodingDevice }}
{{- fail "server.transcodingDevice was removed: Immich does not read IMMICH_TRANSCODING_HW_DEVICE. Configure hardware transcoding via config.content.ffmpeg.accel (or the admin UI) instead" }}
{{- end }}
{{- end }}
