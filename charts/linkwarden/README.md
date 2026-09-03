# linkwarden

![Version: 0.1.1](https://img.shields.io/badge/Version-0.1.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2.16.2](https://img.shields.io/badge/AppVersion-2.16.2-informational?style=flat-square)

A Helm chart for Linkwarden

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| walnuss0815 | <walnuss0815@gmail.com> | <https://github.com/walnuss0815> |

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://walnuss0815.github.io/helm-charts | postgres | 0.3.4 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity rules for pod assignment |
| auth | object | `{"disableRegistration":false}` | Authentication configuration |
| auth.disableRegistration | bool | `false` | Disable new user registration |
| database | object | `{"enabled":false,"host":"","name":"linkwarden","password":{"secretKeyRef":{"key":"","name":""},"value":""},"port":5432,"url":{"secretKeyRef":{"key":"","name":""},"value":"postgresql://$(DATABASE_USER):$(DATABASE_PASSWORD)@$(DATABASE_HOST):$(DATABASE_PORT)/$(DATABASE_NAME)"},"username":{"secretKeyRef":{"key":"","name":""},"value":""}}` | External database connection configuration. Only used if `postgres.enabled` is `false` |
| database.enabled | bool | `false` | Enable configuring an external database connection |
| database.host | string | `""` | Database hostname |
| database.name | string | `"linkwarden"` | Database name |
| database.password | object | `{"secretKeyRef":{"key":"","name":""},"value":""}` | Database password configuration. Must be set via `.value` or `.secretKeyRef` - there is no default |
| database.password.secretKeyRef | object | `{"key":"","name":""}` | Reference to an existing secret containing the database password |
| database.password.secretKeyRef.key | string | `""` | Key within the secret |
| database.password.secretKeyRef.name | string | `""` | Name of the secret |
| database.password.value | string | `""` | Plain-text password value. Ignored if `secretKeyRef.name` is set |
| database.port | int | `5432` | Database port |
| database.url | object | `{"secretKeyRef":{"key":"","name":""},"value":"postgresql://$(DATABASE_USER):$(DATABASE_PASSWORD)@$(DATABASE_HOST):$(DATABASE_PORT)/$(DATABASE_NAME)"}` | Full database connection URL configuration. Defaults to composing the URL from the individual host/port/name/username/password fields below via Kubernetes env var interpolation |
| database.url.secretKeyRef | object | `{"key":"","name":""}` | Reference to an existing secret containing the full database URL |
| database.url.secretKeyRef.key | string | `""` | Key within the secret |
| database.url.secretKeyRef.name | string | `""` | Name of the secret |
| database.url.value | string | `"postgresql://$(DATABASE_USER):$(DATABASE_PASSWORD)@$(DATABASE_HOST):$(DATABASE_PORT)/$(DATABASE_NAME)"` | Plain-text URL value. Ignored if `secretKeyRef.name` is set |
| database.username | object | `{"secretKeyRef":{"key":"","name":""},"value":""}` | Database username configuration. Must be set via `.value` or `.secretKeyRef` - there is no default |
| database.username.secretKeyRef | object | `{"key":"","name":""}` | Reference to an existing secret containing the database username |
| database.username.secretKeyRef.key | string | `""` | Key within the secret |
| database.username.secretKeyRef.name | string | `""` | Name of the secret |
| database.username.value | string | `""` | Plain-text username value. Ignored if `secretKeyRef.name` is set |
| env | object | `{}` | Extra environment variables (templated), keyed by variable name |
| envFrom | list | `[]` | Populate environment variables in bulk from existing ConfigMaps and/or Secrets. Follows the standard Kubernetes envFrom schema: https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/#configure-all-key-value-pairs-in-a-secret-as-container-environment-variables |
| extraManifests | list | `[]` | Extra Kubernetes manifests to deploy |
| fullnameOverride | string | `""` | Override the fullname of the chart |
| httpRoute | object | `{"annotations":{},"enabled":false,"hostnames":["chart-example.local"],"parentRefs":[{"name":"gateway","sectionName":"http"}],"rules":[{"matches":[{"path":{"type":"PathPrefix","value":"/headers"}}]}]}` | Expose the service via gateway-api HTTPRoute Requires Gateway API resources and suitable controller installed within the cluster (see: https://gateway-api.sigs.k8s.io/guides/) |
| httpRoute.annotations | object | `{}` | HTTPRoute annotations |
| httpRoute.enabled | bool | `false` | HTTPRoute enabled |
| httpRoute.hostnames | list | `["chart-example.local"]` | Hostnames matching HTTP header |
| httpRoute.parentRefs | list | `[{"name":"gateway","sectionName":"http"}]` | Which Gateways this Route is attached to |
| httpRoute.rules | list | `[{"matches":[{"path":{"type":"PathPrefix","value":"/headers"}}]}]` | List of rules and filters applied |
| image | object | `{"pullPolicy":"IfNotPresent","repository":"ghcr.io/linkwarden/linkwarden","tag":""}` | Container image configuration |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.repository | string | `"ghcr.io/linkwarden/linkwarden"` | Container image repository |
| image.tag | string | `""` | Image tag. Defaults to `v<Chart.AppVersion>` if not set |
| imagePullSecrets | list | `[]` | Image pull secrets for private registries |
| ingress | object | `{"annotations":{},"className":"","enabled":false,"hosts":[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}],"tls":[]}` | Ingress configuration |
| ingress.annotations | object | `{}` | Ingress annotations |
| ingress.className | string | `""` | Ingress class name |
| ingress.enabled | bool | `false` | Enable ingress |
| ingress.hosts | list | `[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | Ingress hosts configuration |
| ingress.tls | list | `[]` | TLS configuration |
| livenessProbe | object | `{"httpGet":{"path":"/","port":"http"},"initialDelaySeconds":10}` | Liveness probe configuration |
| nameOverride | string | `""` | Override the name of the chart |
| nextauth | object | `{"secret":{"secretKeyRef":{"key":"","name":""},"value":""},"url":"http://localhost:3000/api/v1/auth"}` | NextAuth configuration |
| nextauth.secret | object | `{"secretKeyRef":{"key":"","name":""},"value":""}` | NextAuth session-signing secret configuration. Must be set via `.value` or `.secretKeyRef` - there is no default |
| nextauth.secret.secretKeyRef | object | `{"key":"","name":""}` | Reference to an existing secret containing the NextAuth secret |
| nextauth.secret.secretKeyRef.key | string | `""` | Key within the secret |
| nextauth.secret.secretKeyRef.name | string | `""` | Name of the secret |
| nextauth.secret.value | string | `""` | Plain-text secret value. Ignored if `secretKeyRef.name` is set |
| nextauth.url | string | `"http://localhost:3000/api/v1/auth"` | Public URL of the NextAuth API endpoint. Must be set to the real, externally-reachable URL in any non-local deployment - NextAuth uses this for redirect/callback validation, so a stale/incorrect value here is a functional and security concern (e.g. behind an Ingress, this must match the Ingress host, not localhost) |
| nodeSelector | object | `{}` | Node selector for pod assignment |
| persistence | object | `{"data":{"accessModes":["ReadWriteOnce"],"annotations":{},"size":"2Gi","storageClass":"-"}}` | Persistence configuration for the linkwarden data directory |
| persistence.data.accessModes | list | `["ReadWriteOnce"]` | Access modes for the data PVC |
| persistence.data.annotations | object | `{}` | Annotations for the data PVC |
| persistence.data.size | string | `"2Gi"` | Size of the data PVC |
| persistence.data.storageClass | string | `"-"` | Storage class for the data PVC |
| podAnnotations | object | `{}` | Annotations to add to the pod |
| podLabels | object | `{}` | Labels to add to the pod |
| podSecurityContext | object | `{"fsGroup":1000,"fsGroupChangePolicy":"OnRootMismatch"}` | Pod security context configuration |
| postgres | object | `{"enabled":false,"secret":{"create":true,"name":"{{ .Release.Name }}-db"}}` | Bundled PostgreSQL subchart configuration (disabled by default; mainly intended for testing/CI - see [postgres chart](../postgres) for all available options). When enabled, this takes precedence over `database.*` for wiring the DATABASE_* env vars. |
| postgres.enabled | bool | `false` | Enable the bundled PostgreSQL subchart instead of an external database via `database.*` |
| postgres.secret | object | `{"create":true,"name":"{{ .Release.Name }}-db"}` | Secret configuration for database credentials, also used by this chart to know which secret to read DATABASE_* env vars from |
| postgres.secret.create | bool | `true` | Create a new secret for database credentials |
| postgres.secret.name | string | `"{{ .Release.Name }}-db"` | Name of the secret (supports Helm templating) |
| readinessProbe | object | `{"httpGet":{"path":"/","port":"http"},"initialDelaySeconds":10}` | Readiness probe configuration |
| replicaCount | int | `1` | Number of replicas for the linkwarden deployment |
| resources | object | `{}` | Resource limits and requests for the linkwarden container |
| securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | Container security context configuration |
| service | object | `{"port":3000,"type":"ClusterIP"}` | Service configuration |
| service.port | int | `3000` | Service port |
| service.type | string | `"ClusterIP"` | Service type (ClusterIP, NodePort, LoadBalancer) |
| serviceAccount | object | `{"annotations":{},"automount":true,"create":true,"name":""}` | Service account configuration |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use (if not set and create is true, a name is generated using the fullname template) |
| tolerations | list | `[]` | Tolerations for pod assignment |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
