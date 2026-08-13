# postgres

![Version: 0.3.3](https://img.shields.io/badge/Version-0.3.3-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 18.3](https://img.shields.io/badge/AppVersion-18.3-informational?style=flat-square)

A Helm chart for PostgreSQL

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| walnuss0815 | <walnuss0815@gmail.com> | <https://github.com/walnuss0815> |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity rules for pod scheduling |
| database | string | `"app"` | PostgreSQL database name |
| extraManifests | list | `[]` | Extra Kubernetes manifests to deploy |
| fullnameOverride | string | `""` | Override the full chart name |
| image | object | `{"pullPolicy":"IfNotPresent","repository":"postgres","tag":"18.6"}` | Container image configuration. See [Kubernetes docs](https://kubernetes.io/docs/concepts/containers/images/) |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.repository | string | `"postgres"` | Image repository |
| image.tag | string | `"18.6"` | Image tag. Overrides the chart appVersion when set |
| imagePullSecrets | list | `[]` | Secrets for pulling images from a private registry. See [Kubernetes docs](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) |
| initdb | object | `{}` | InitDB scripts to run on first startup. See [PostgreSQL Docker docs](https://github.com/docker-library/docs/blob/master/postgres/README.md#initialization-scripts) |
| livenessProbe | object | `{"exec":{"command":["sh","-c","pg_isready -U $POSTGRES_USER -d $POSTGRES_DB"]},"periodSeconds":5}` | Liveness probe configuration. See [Kubernetes docs](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) |
| nameOverride | string | `""` | Override the chart name |
| nodeSelector | object | `{}` | Node selector for pod scheduling |
| persistence | object | `{"pgdata":{"accessModes":["ReadWriteOnce"],"annotations":{},"size":"1Gi","storageClass":"-"}}` | Persistence configuration for PostgreSQL volumes |
| persistence.pgdata | object | `{"accessModes":["ReadWriteOnce"],"annotations":{},"size":"1Gi","storageClass":"-"}` | PostgreSQL data directory persistence configuration |
| persistence.pgdata.accessModes | list | `["ReadWriteOnce"]` | Access modes for the PostgreSQL data PVC |
| persistence.pgdata.annotations | object | `{}` | Annotations for the PostgreSQL data PVC |
| persistence.pgdata.size | string | `"1Gi"` | Size of the PostgreSQL data PVC |
| persistence.pgdata.storageClass | string | `"-"` | Storage class for the PostgreSQL data PVC. Use `"-"` to disable dynamic provisioning |
| podAnnotations | object | `{}` | Annotations to add to the Pod. See [Kubernetes docs](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/) |
| podLabels | object | `{}` | Labels to add to the Pod. See [Kubernetes docs](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) |
| podSecurityContext | object | `{}` | Pod-level security context |
| port | int | `5432` | PostgreSQL port |
| readinessProbe | object | `{"exec":{"command":["sh","-c","psql -U $POSTGRES_USER -d $POSTGRES_DB -c \"SELECT 1\""]},"initialDelaySeconds":5,"periodSeconds":5}` | Readiness probe configuration. See [Kubernetes docs](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) |
| resources | object | `{}` | Resource requests and limits for the PostgreSQL container. See [Kubernetes docs](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) |
| secret | object | `{"create":true,"name":""}` | Secret configuration for database credentials |
| secret.create | bool | `true` | Create a secret containing database credentials and connection details |
| secret.name | string | `""` | Name of the secret containing `username` and `password`. Auto-generated if `create` is `true` |
| securityContext | object | `{}` | Container-level security context |
| service | object | `{"port":5432,"type":"ClusterIP"}` | Kubernetes Service configuration. See [Kubernetes docs](https://kubernetes.io/docs/concepts/services-networking/service/) |
| service.port | int | `5432` | Service port |
| service.type | string | `"ClusterIP"` | Service type. See [service types](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| serviceAccount | object | `{"annotations":{},"automount":true,"create":true,"name":""}` | Service account configuration. See [Kubernetes docs](https://kubernetes.io/docs/concepts/security/service-accounts/) |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | Name of the service account to use. If not set and `create` is `true`, a name is generated using the fullname template |
| tolerations | list | `[]` | Tolerations for pod scheduling |
| username | string | `"app"` | PostgreSQL username |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
