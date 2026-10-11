{{/*
Fail the render on invalid or incomplete values. Included once by deployment.yaml.
*/}}
{{- define "keycloak.validateValues" -}}
{{- $kc := .Values.keycloak -}}
{{- $pg := .Values.postgres -}}

{{- if not (has .Values.build.mode (list "initContainer" "prebuilt" "auto")) -}}
{{- fail (printf "build.mode must be one of initContainer, prebuilt or auto, got %q" (toString .Values.build.mode)) -}}
{{- end -}}

{{- if and $kc.hostnameStrict (not $kc.hostname) -}}
{{- fail "keycloak.hostname is required (e.g. https://sso.example.com), unless keycloak.hostnameStrict is false" -}}
{{- end -}}
{{- if and $kc.hostnameBackchannelDynamic (not (regexMatch "^https?://" (toString $kc.hostname))) -}}
{{- fail "keycloak.hostnameBackchannelDynamic requires keycloak.hostname to be a full URL (e.g. https://sso.example.com)" -}}
{{- end -}}
{{- if not (has (toString $kc.proxyHeaders) (list "" "xforwarded" "forwarded")) -}}
{{- fail (printf "keycloak.proxyHeaders must be xforwarded, forwarded or empty, got %q" (toString $kc.proxyHeaders)) -}}
{{- end -}}
{{- if and $kc.httpRelativePath (not (hasPrefix "/" (toString $kc.httpRelativePath))) -}}
{{- fail "keycloak.httpRelativePath must start with /" -}}
{{- end -}}

{{- range $name, $entry := dict "bootstrapAdmin.user.password" .Values.bootstrapAdmin.user.password "bootstrapAdmin.client.clientSecret" .Values.bootstrapAdmin.client.clientSecret -}}
{{- $sources := 0 -}}
{{- if $entry.value }}{{ $sources = add1 $sources }}{{ end -}}
{{- if $entry.generate }}{{ $sources = add1 $sources }}{{ end -}}
{{- if include "keycloak.secretRefSet" $entry }}{{ $sources = add1 $sources }}{{ end -}}
{{- if gt $sources 1 -}}
{{- fail (printf "%s: set only one of value, generate or secretKeyRef" $name) -}}
{{- end -}}
{{- end -}}
{{- if and .Values.bootstrapAdmin.user.enabled (not (include "keycloak.secretConfigured" .Values.bootstrapAdmin.user.password)) -}}
{{- fail "bootstrapAdmin.user.password is required: set secretKeyRef, value or generate, or disable bootstrapAdmin.user" -}}
{{- end -}}
{{- if and .Values.bootstrapAdmin.user.enabled (not .Values.bootstrapAdmin.user.username) -}}
{{- fail "bootstrapAdmin.user.username is required" -}}
{{- end -}}
{{- if and .Values.bootstrapAdmin.client.enabled (not (include "keycloak.secretConfigured" .Values.bootstrapAdmin.client.clientSecret)) -}}
{{- fail "bootstrapAdmin.client.clientSecret is required: set secretKeyRef, value or generate, or disable bootstrapAdmin.client" -}}
{{- end -}}
{{- if and .Values.bootstrapAdmin.client.enabled (not .Values.bootstrapAdmin.client.clientId) -}}
{{- fail "bootstrapAdmin.client.clientId is required" -}}
{{- end -}}

{{- $themeNames := list -}}
{{- range $i, $t := .Values.themes.custom -}}
{{- $name := toString ($t.name | default "") -}}
{{- if not (regexMatch "^[a-zA-Z0-9][a-zA-Z0-9._-]{0,62}$" $name) -}}
{{- fail (printf "themes.custom[%d].name %q must start with a letter or digit and contain only letters, digits, '.', '_' and '-'" $i $name) -}}
{{- end -}}
{{- if has $name $themeNames -}}
{{- fail (printf "themes.custom: duplicate theme name %q" $name) -}}
{{- end -}}
{{- $themeNames = append $themeNames $name -}}
{{- $type := $t.type | default "directory" -}}
{{- if not (has $type (list "directory" "jar")) -}}
{{- fail (printf "themes.custom[%d].type must be directory or jar, got %q" $i (toString $type)) -}}
{{- end -}}
{{- if eq (empty $t.image) (empty $t.configMap) -}}
{{- fail (printf "themes.custom[%d] (%s): set exactly one of image or configMap" $i $name) -}}
{{- end -}}
{{- if $t.image -}}
{{- if not (and $t.image.repository $t.image.tag) -}}
{{- fail (printf "themes.custom[%d] (%s): image.repository and image.tag are required" $i $name) -}}
{{- end -}}
{{- $path := toString ($t.path | default "") -}}
{{- if and $path (not (regexMatch "^/[A-Za-z0-9._/-]*$" $path)) -}}
{{- fail (printf "themes.custom[%d] (%s): path must be an absolute path of letters, digits, '.', '_', '-' and '/'" $i $name) -}}
{{- end -}}
{{- if and $path (regexMatch "(^|/)\\.\\.(/|$)" $path) -}}
{{- fail (printf "themes.custom[%d] (%s): path must not contain '..' segments" $i $name) -}}
{{- end -}}
{{- if and (not $t.imageVolume) $path (eq (trimSuffix "/" $path | default "/") "/") -}}
{{- fail (printf "themes.custom[%d] (%s): path / would copy the whole image; set the theme directory, or use imageVolume" $i $name) -}}
{{- end -}}
{{- else -}}
{{- if $t.imageVolume -}}
{{- fail (printf "themes.custom[%d] (%s): imageVolume requires image" $i $name) -}}
{{- end -}}
{{- if not $t.configMap.name -}}
{{- fail (printf "themes.custom[%d] (%s): configMap.name is required" $i $name) -}}
{{- end -}}
{{- if eq $type "jar" -}}
{{- fail (printf "themes.custom[%d] (%s): jar themes cannot come from a ConfigMap, use image" $i $name) -}}
{{- end -}}
{{- end -}}
{{- if and (eq $type "jar") (eq $.Values.build.mode "prebuilt") -}}
{{- fail (printf "themes.custom[%d] (%s): jar themes need a build and are not supported with build.mode prebuilt; add the JAR to the image instead" $i $name) -}}
{{- end -}}
{{- end -}}

{{- if and .Values.tls.enabled (not .Values.tls.secretName) -}}
{{- fail "tls.secretName is required with tls.enabled" -}}
{{- end -}}

{{- if and .Values.serviceMonitor.enabled (not $kc.metricsEnabled) -}}
{{- fail "serviceMonitor.enabled requires keycloak.metricsEnabled" -}}
{{- end -}}

{{- if and .Values.podDisruptionBudget.enabled (not (include "keycloak.isSet" .Values.podDisruptionBudget.minAvailable)) (not (include "keycloak.isSet" .Values.podDisruptionBudget.maxUnavailable)) -}}
{{- fail "podDisruptionBudget requires minAvailable or maxUnavailable" -}}
{{- end -}}

{{- if and .Values.autoscaling.enabled (not .Values.autoscaling.targetCPUUtilizationPercentage) (not .Values.autoscaling.targetMemoryUtilizationPercentage) -}}
{{- fail "autoscaling requires targetCPUUtilizationPercentage or targetMemoryUtilizationPercentage" -}}
{{- end -}}

{{- /* KCRAW_ variables (used for secrets) exist since Keycloak 26.6. Only the official image is checked: other images may use their own tags */ -}}
{{- $tag := toString (.Values.image.tag | default .Chart.AppVersion) -}}
{{- if and (eq .Values.image.repository "quay.io/keycloak/keycloak") (regexMatch "^[0-9]+\\.[0-9]+\\.[0-9]+$" $tag) (semverCompare "<26.6.0" $tag) -}}
{{- fail (printf "image.tag %s is too old: the chart requires Keycloak 26.6.0 or newer (KCRAW_ environment variables)" $tag) -}}
{{- end -}}

{{- if not $pg.enabled -}}
{{- if not $pg.host -}}
{{- fail "postgres.host is required when postgres.enabled is false" -}}
{{- end -}}
{{- if not (include "keycloak.databasePasswordProvided" .) -}}
{{- fail "postgres.password (value or secretKeyRef) or postgres.bootstrapSecretOverride is required when postgres.enabled is false" -}}
{{- end -}}
{{- end -}}
{{- if and $pg.enabled (include "keycloak.secretRefSet" $pg.password) (ne (toString $pg.password.secretKeyRef.key) "password") -}}
{{- fail "postgres.password.secretKeyRef.key must be \"password\" with the bundled CNPG cluster: the Secret also bootstraps the database and needs the keys username and password" -}}
{{- end -}}
{{- if not (has (include "keycloak.databaseTlsMode" .) (list "disabled" "verify-server")) -}}
{{- fail (printf "postgres.tls.mode must be disabled, verify-server or empty, got %q" (toString $pg.tls.mode)) -}}
{{- end -}}
{{- if and (eq (include "keycloak.databaseTlsMode" .) "verify-server") (not (include "keycloak.databaseCaSecretName" .)) -}}
{{- fail "postgres.tls.caSecretKeyRef.name is required for postgres.tls.mode verify-server with an external database" -}}
{{- end -}}

{{- if $pg.enabled -}}
{{- $bk := $pg.backup -}}
{{- $rec := $pg.recovery -}}
{{- if not (has (toString $bk.method) (list "plugin" "volumeSnapshot")) -}}
{{- fail (printf "postgres.backup.method must be plugin or volumeSnapshot, got %q" (toString $bk.method)) -}}
{{- end -}}
{{- if and $bk.enabled (eq $bk.method "plugin") $bk.objectStore.create (not $bk.objectStore.configuration) -}}
{{- fail "postgres.backup.objectStore.configuration is required for postgres.backup.method plugin (or set objectStore.create to false and objectStore.name)" -}}
{{- end -}}
{{- if and $bk.enabled (not $bk.objectStore.create) (eq $bk.method "plugin") (not $bk.objectStore.name) -}}
{{- fail "postgres.backup.objectStore.name is required when postgres.backup.objectStore.create is false" -}}
{{- end -}}
{{- if and $bk.enabled (eq $bk.method "volumeSnapshot") (not $bk.volumeSnapshot.className) -}}
{{- fail "postgres.backup.volumeSnapshot.className is required for postgres.backup.method volumeSnapshot" -}}
{{- end -}}
{{- if and $rec.enabled (not $rec.volumeSnapshots) (not $rec.objectStoreName) (not (include "keycloak.backupObjectStoreCreate" .)) (not $bk.objectStore.name) -}}
{{- fail "postgres.recovery requires recovery.objectStoreName, recovery.volumeSnapshots or a backup object store" -}}
{{- end -}}
{{- /* A WAL archive must start empty: never archive into the folder the cluster is restored from */ -}}
{{- if and $rec.enabled (not $rec.volumeSnapshots) (include "keycloak.walArchivingEnabled" .) -}}
{{- $recStore := $rec.objectStoreName | default (include "keycloak.backupObjectStoreName" .) -}}
{{- $recServer := $rec.serverName | default (include "keycloak.databaseClusterName" .) -}}
{{- $bkServer := $bk.objectStore.serverName | default (include "keycloak.databaseClusterName" .) -}}
{{- if and (eq $recStore (include "keycloak.backupObjectStoreName" .)) (eq $recServer $bkServer) -}}
{{- fail "postgres.recovery restores from the folder the backup archives to: set postgres.backup.objectStore.serverName to a new folder name (e.g. <fullname>-postgresql-2)" -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end }}
