# odoo

![Version: 0.3.0](https://img.shields.io/badge/Version-0.3.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 19.0](https://img.shields.io/badge/AppVersion-19.0-informational?style=flat-square)

A Helm chart for Odoo

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| walnuss0815 | <walnuss0815@gmail.com> | <https://github.com/walnuss0815> |

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://walnuss0815.github.io/helm-charts | postgres | 0.3.1 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity rules for pod scheduling |
| config | string | `"[options]\naddons_path = /mnt/extra-addons\ndata_dir = /var/lib/odoo\n\ndb_host = $DB_HOST\ndb_port = $DB_PORT\ndb_user = $DB_USER\ndb_password = $DB_PASSWORD\n\nlog_level = $LOG_LEVEL\n\n{{ tpl .Values.extraConfig . }}"` | Odoo configuration file content (supports Helm templating) |
| database | object | `{"host":"","password":{"secretKeyRef":{"key":"","name":""},"value":""},"port":5432,"username":{"secretKeyRef":{"key":"","name":""},"value":"odoo"}}` | External database connection config. Only used if `postgres.enabled` is `false` |
| database.host | string | `""` | Database hostname |
| database.password | object | `{"secretKeyRef":{"key":"","name":""},"value":""}` | Database password configuration |
| database.password.secretKeyRef | object | `{"key":"","name":""}` | Reference to an existing secret containing the database password |
| database.password.secretKeyRef.key | string | `""` | Key within the secret |
| database.password.secretKeyRef.name | string | `""` | Name of the secret |
| database.password.value | string | `""` | Plain-text password value. Ignored if `secretKeyRef.name` is set |
| database.port | int | `5432` | Database port |
| database.username | object | `{"secretKeyRef":{"key":"","name":""},"value":"odoo"}` | Database username configuration |
| database.username.secretKeyRef | object | `{"key":"","name":""}` | Reference to an existing secret containing the database username |
| database.username.secretKeyRef.key | string | `""` | Key within the secret |
| database.username.secretKeyRef.name | string | `""` | Name of the secret |
| database.username.value | string | `"odoo"` | Plain-text username value. Ignored if `secretKeyRef.name` is set |
| env | object | `{}` | Additional environment variables to set |
| envFrom | object | `{}` | Additional environment variables from ConfigMaps or Secrets |
| extraConfig | string | `""` | Extra content appended to the Odoo config file. Supports multiline INI-style options |
| extraManifests | list | `[]` | Extra Kubernetes manifests to deploy |
| fullnameOverride | string | `""` | Override the full chart name |
| httpRoute | object | `{"annotations":{},"enabled":false,"hostnames":["chart-example.local"],"parentRefs":[{"name":"gateway","sectionName":"http"}],"rules":[{"matches":[{"path":{"type":"PathPrefix","value":"/headers"}}]}]}` | Expose the service via Gateway API HTTPRoute. Requires Gateway API resources and a suitable controller installed within the cluster (see: https://gateway-api.sigs.k8s.io/guides/) |
| httpRoute.annotations | object | `{}` | HTTPRoute annotations |
| httpRoute.enabled | bool | `false` | Enable HTTPRoute |
| httpRoute.hostnames | list | `["chart-example.local"]` | Hostnames matching HTTP header |
| httpRoute.parentRefs | list | `[{"name":"gateway","sectionName":"http"}]` | Gateways this Route is attached to |
| httpRoute.rules | list | `[{"matches":[{"path":{"type":"PathPrefix","value":"/headers"}}]}]` | List of routing rules and filters |
| image | object | `{"pullPolicy":"IfNotPresent","repository":"odoo","tag":"19.0"}` | Odoo container image configuration |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.repository | string | `"odoo"` | Image repository |
| image.tag | string | `"19.0"` | Image tag |
| imagePullSecrets | list | `[]` | Image pull secrets for private registries |
| ingress | object | `{"annotations":{},"className":"","enabled":false,"hosts":[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}],"tls":[]}` | Ingress configuration for external HTTP access |
| ingress.annotations | object | `{}` | Ingress annotations |
| ingress.className | string | `""` | Ingress class name |
| ingress.enabled | bool | `false` | Enable ingress |
| ingress.hosts | list | `[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | Ingress hosts configuration |
| ingress.tls | list | `[]` | TLS configuration for ingress |
| initContainer | list | `[]` | Configuration of init containers |
| livenessProbe | object | `{"httpGet":{"path":"/","port":"http"},"initialDelaySeconds":5}` | Liveness probe configuration |
| logLevel | string | `"info"` | Odoo log level. See [documentation](https://www.odoo.com/documentation/19.0/de/developer/reference/cli.html#cmdoption-odoo-bin-log-level) |
| nameOverride | string | `""` | Override the chart name |
| nodeSelector | object | `{}` | Node selector for pod scheduling |
| persistence | object | `{"addons":{"accessModes":["ReadWriteOnce"],"annotations":{},"size":"1Gi","storageClass":"-"},"data":{"accessModes":["ReadWriteOnce"],"annotations":{},"size":"1Gi","storageClass":"-"}}` | Persistence configuration for Odoo volumes |
| persistence.addons | object | `{"accessModes":["ReadWriteOnce"],"annotations":{},"size":"1Gi","storageClass":"-"}` | Odoo addons directory persistence configuration |
| persistence.addons.accessModes | list | `["ReadWriteOnce"]` | Access modes for the Odoo addons PVC |
| persistence.addons.annotations | object | `{}` | Annotations for the Odoo addons PVC |
| persistence.addons.size | string | `"1Gi"` | Size of the Odoo addons PVC |
| persistence.addons.storageClass | string | `"-"` | Storage class for the Odoo addons PVC. Use `"-"` to disable dynamic provisioning |
| persistence.data | object | `{"accessModes":["ReadWriteOnce"],"annotations":{},"size":"1Gi","storageClass":"-"}` | Odoo data directory persistence configuration |
| persistence.data.accessModes | list | `["ReadWriteOnce"]` | Access modes for the Odoo data PVC |
| persistence.data.annotations | object | `{}` | Annotations for the Odoo data PVC |
| persistence.data.size | string | `"1Gi"` | Size of the Odoo data PVC |
| persistence.data.storageClass | string | `"-"` | Storage class for the Odoo data PVC. Use `"-"` to disable dynamic provisioning |
| podAnnotations | object | `{}` | Annotations to add to the Odoo pod |
| podLabels | object | `{}` | Labels to add to the Odoo pod |
| podSecurityContext | object | `{"fsGroup":101,"fsGroupChangePolicy":"OnRootMismatch"}` | Pod-level security context (e.g. fsGroup) |
| postgres | object | `{"database":"postgres","enabled":true,"secret":{"create":true,"name":"{{ .Release.Name }}-db"}}` | PostgreSQL subchart configuration. See [postgresql chart](../postgres) for all available options |
| postgres.database | string | `"postgres"` | Name of the PostgreSQL database to create |
| postgres.enabled | bool | `true` | Enable the PostgreSQL subchart. Set to `false` to use an external database via `database.*` |
| postgres.secret | object | `{"create":true,"name":"{{ .Release.Name }}-db"}` | Secret configuration for database credentials |
| postgres.secret.create | bool | `true` | Create a new secret for database credentials |
| postgres.secret.name | string | `"{{ .Release.Name }}-db"` | Name of the secret (supports Helm templating) |
| readinessProbe | object | `{"httpGet":{"path":"/","port":"http"},"initialDelaySeconds":5}` | Readiness probe configuration |
| replicaCount | int | `1` | Number of replicas for the Odoo deployment |
| resources | object | `{}` | Resource requests and limits for the Odoo container |
| securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsGroup":101,"runAsNonRoot":true,"runAsUser":100,"seccompProfile":{"type":"RuntimeDefault"}}` | Container-level security context |
| service | object | `{"port":8069,"type":"ClusterIP"}` | Kubernetes Service configuration |
| service.port | int | `8069` | Service port for Odoo web interface |
| service.type | string | `"ClusterIP"` | Service type |
| serviceAccount | object | `{"annotations":{},"automount":true,"create":true,"name":""}` | Service account configuration |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.automount | bool | `true` | Automatically mount the ServiceAccount's API credentials |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | Name of the service account to use. If not set and create is true, a name is generated using the fullname template |
| tolerations | list | `[]` | Tolerations for pod scheduling |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
