{{/*
Fail fast on invalid or removed values. Included once from the server
Deployment, which is always rendered.
*/}}
{{- define "immich.validateValues" -}}
{{- if and (not .Values.postgres.enabled) (not (include "immich.databasePasswordProvided" .)) }}
{{- fail "postgres.password (value or secretKeyRef) is required when postgres.enabled is false" }}
{{- end }}
{{- with .Values.postgres }}
{{- if and .enabled (not .bootstrapSecretOverride) .password.secretKeyRef.name .password.secretKeyRef.key (ne .password.secretKeyRef.key "password") }}
{{- fail (printf "postgres.password.secretKeyRef.key must be \"password\" when postgres.enabled is true (got %q): CloudNativePG bootstraps the database from the keys `username` and `password` of the same Secret. Rename the key or set postgres.bootstrapSecretOverride" .password.secretKeyRef.key) }}
{{- end }}
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
{{- range .Values.postgres.extensions }}
{{- if ne .name "vchord" }}
{{- fail "postgres.extensions was removed: vchord is configured via postgres.vchord (image and paths are derived from postgres.image.tag). Move additional extensions to postgres.extraExtensions" }}
{{- end }}
{{- end }}
{{- range .Values.postgres.sharedPreloadLibraries }}
{{- if ne . "vchord.so" }}
{{- fail "postgres.sharedPreloadLibraries was removed: vchord.so is always preloaded. Move additional libraries to postgres.extraSharedPreloadLibraries" }}
{{- end }}
{{- end }}
{{- if and .Values.server .Values.server.transcodingDevice }}
{{- fail "server.transcodingDevice was removed: Immich does not read IMMICH_TRANSCODING_HW_DEVICE. Configure hardware transcoding via config.content.ffmpeg.accel (or the admin UI) instead" }}
{{- end }}
{{- end }}
