# paperless-ai

![Version: 0.1.1](https://img.shields.io/badge/Version-0.1.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 3.0.9](https://img.shields.io/badge/AppVersion-3.0.9-informational?style=flat-square)

A Helm chart for Kubernetes

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| walnuss0815 | <walnuss0815@gmail.com> | <https://github.com/walnuss0815> |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity rules for pod assignment |
| fullnameOverride | string | `""` | Override the fullname of the chart |
| httpRoute | object | `{"annotations":{},"enabled":false,"hostnames":["chart-example.local"],"parentRefs":[{"name":"gateway","sectionName":"http"}],"rules":[{"matches":[{"path":{"type":"PathPrefix","value":"/headers"}}]}]}` | Gateway API HTTPRoute configuration (requires Gateway API CRDs installed) |
| httpRoute.annotations | object | `{}` | HTTPRoute annotations |
| httpRoute.enabled | bool | `false` | Enable HTTPRoute |
| httpRoute.hostnames | list | `["chart-example.local"]` | Hostnames for HTTP header matching |
| httpRoute.parentRefs | list | `[{"name":"gateway","sectionName":"http"}]` | Parent gateway references to attach this route to |
| httpRoute.rules | list | `[{"matches":[{"path":{"type":"PathPrefix","value":"/headers"}}]}]` | Routing rules and filters |
| image | object | `{"pullPolicy":"IfNotPresent","repository":"clusterzx/paperless-ai","tag":""}` | Container image configuration |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.repository | string | `"clusterzx/paperless-ai"` | Container image repository |
| image.tag | string | `""` | Image tag. Defaults to the chart's `appVersion` if not set |
| imagePullSecrets | list | `[]` | Image pull secrets for private registries |
| ingress | object | `{"annotations":{},"className":"","enabled":false,"hosts":[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}],"tls":[]}` | Ingress configuration |
| ingress.annotations | object | `{}` | Ingress annotations |
| ingress.className | string | `""` | Ingress class name |
| ingress.enabled | bool | `false` | Enable ingress |
| ingress.hosts | list | `[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | Ingress hosts configuration |
| ingress.hosts[0] | object | `{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}` | Hostname for ingress |
| ingress.hosts[0].paths | list | `[{"path":"/","pathType":"ImplementationSpecific"}]` | Paths configuration for the host |
| ingress.hosts[0].paths[0] | object | `{"path":"/","pathType":"ImplementationSpecific"}` | Path to route |
| ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` | Path type (ImplementationSpecific, Exact, Prefix) |
| ingress.tls | list | `[]` | TLS configuration |
| livenessProbe | object | `{"httpGet":{"path":"/","port":"http"}}` | Liveness probe configuration |
| nameOverride | string | `""` | Override the name of the chart |
| nodeSelector | object | `{}` | Node selector for pod assignment |
| persistence | object | `{"data":{"accessModes":["ReadWriteOnce"],"annotations":{},"size":"1Gi","storageClass":"-"}}` | Persistence configuration for paperless-ai data |
| persistence.data | object | `{"accessModes":["ReadWriteOnce"],"annotations":{},"size":"1Gi","storageClass":"-"}` | Data directory persistence configuration |
| persistence.data.accessModes | list | `["ReadWriteOnce"]` | Access modes for data PVC |
| persistence.data.annotations | object | `{}` | Annotations for the data PVC |
| persistence.data.size | string | `"1Gi"` | Size of the data PVC |
| persistence.data.storageClass | string | `"-"` | Storage class for data PVC |
| podAnnotations | object | `{}` | Annotations to add to the pod |
| podLabels | object | `{}` | Labels to add to the pod |
| podSecurityContext | object | `{}` | Pod security context configuration |
| readinessProbe | object | `{"httpGet":{"path":"/","port":"http"}}` | Readiness probe configuration |
| replicaCount | int | `1` | Number of replicas for the paperless-ai deployment |
| resources | object | `{}` | Resource limits and requests for the paperless-ai container |
| securityContext | object | `{}` | Container security context configuration |
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
