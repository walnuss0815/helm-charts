# webdav

![Version: 0.1.6](https://img.shields.io/badge/Version-0.1.6-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v5.8.0](https://img.shields.io/badge/AppVersion-v5.8.0-informational?style=flat-square)

A Helm chart for Kubernetes

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| walnuss0815 | <walnuss0815@gmail.com> | <https://github.com/walnuss0815> |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity rules for pod assignment |
| config | object | `{"behindProxy":true,"cors":{"enabled":false},"debug":false,"directory":"/data","log":{"format":"json"},"noSniff":false,"permissions":"CRUD","port":6060,"users":[{"password":"{env}USER_PASSWORD","username":"{env}USER_USERNAME"}]}` | WebDAV server configuration |
| extraManifests | list | `[]` | Extra Kubernetes manifests to deploy |
| fullnameOverride | string | `""` | Override the fullname of the chart |
| httpRoute | object | `{"annotations":{},"enabled":false,"hostnames":["chart-example.local"],"parentRefs":[{"name":"gateway","sectionName":"http"}],"rules":[{"matches":[{"path":{"type":"PathPrefix","value":"/headers"}}]}]}` | Gateway API HTTPRoute configuration (requires Gateway API CRDs installed) |
| httpRoute.annotations | object | `{}` | HTTPRoute annotations |
| httpRoute.enabled | bool | `false` | Enable HTTPRoute |
| httpRoute.hostnames | list | `["chart-example.local"]` | Hostnames for HTTP header matching |
| httpRoute.parentRefs | list | `[{"name":"gateway","sectionName":"http"}]` | Parent gateway references to attach this route to |
| httpRoute.rules | list | `[{"matches":[{"path":{"type":"PathPrefix","value":"/headers"}}]}]` | Routing rules and filters |
| image | object | `{"pullPolicy":"IfNotPresent","repository":"hacdias/webdav","tag":"v5.13.0"}` | Container image configuration |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.repository | string | `"hacdias/webdav"` | Container image repository |
| image.tag | string | `"v5.13.0"` | Overrides the image tag whose default is the chart appVersion |
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
| livenessProbe | object | `{}` | Liveness probe configuration (disabled by default) livenessProbe:   httpGet:     path: /     port: http |
| nameOverride | string | `""` | Override the name of the chart |
| nodeSelector | object | `{}` | Node selector for pod assignment |
| persistence | object | `{"data":{"accessModes":["ReadWriteOnce"],"annotations":{},"claimName":"","size":"1Gi","storageClass":"-"}}` | Persistence configuration for WebDAV |
| persistence.data | object | `{"accessModes":["ReadWriteOnce"],"annotations":{},"claimName":"","size":"1Gi","storageClass":"-"}` | Data directory persistence configuration |
| persistence.data.accessModes | list | `["ReadWriteOnce"]` | Access modes for data PVC |
| persistence.data.annotations | object | `{}` | Annotations for the data PVC |
| persistence.data.claimName | string | `""` | Existing PVC claim name to use (if empty, creates new PVC) |
| persistence.data.size | string | `"1Gi"` | Size of the data PVC |
| persistence.data.storageClass | string | `"-"` | Storage class for data PVC |
| podAnnotations | object | `{}` | Annotations to add to the pod |
| podLabels | object | `{}` | Labels to add to the pod |
| podSecurityContext | object | `{"fsGroup":1000,"fsGroupChangePolicy":"OnRootMismatch"}` | Pod security context configuration |
| podSecurityContext.fsGroup | int | `1000` | Set filesystem group ownership for mounted volumes |
| podSecurityContext.fsGroupChangePolicy | string | `"OnRootMismatch"` | Define behavior when fsGroup changes |
| readinessProbe | object | `{}` | Readiness probe configuration (disabled by default) readinessProbe:   httpGet:     path: /     port: http |
| replicaCount | int | `1` | Number of replicas for the WebDAV deployment |
| resources | object | `{}` | Resource limits and requests for the WebDAV container |
| securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | Container security context configuration |
| securityContext.allowPrivilegeEscalation | bool | `false` | Prevent privilege escalation |
| securityContext.capabilities | object | `{"drop":["ALL"]}` | Linux capabilities to drop |
| securityContext.readOnlyRootFilesystem | bool | `true` | Mount root filesystem as read-only |
| securityContext.runAsGroup | int | `1000` | Group ID to run the container as |
| securityContext.runAsNonRoot | bool | `true` | Run container as non-root user |
| securityContext.runAsUser | int | `1000` | User ID to run the container as |
| securityContext.seccompProfile | object | `{"type":"RuntimeDefault"}` | Seccomp profile configuration |
| service | object | `{"port":6060,"type":"ClusterIP"}` | Service configuration |
| service.port | int | `6060` | Service port (WebDAV default port) |
| service.type | string | `"ClusterIP"` | Service type (ClusterIP, NodePort, LoadBalancer) |
| serviceAccount | object | `{"annotations":{},"automount":true,"create":true,"name":""}` | Service account configuration |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use (if not set and create is true, a name is generated using the fullname template) |
| tolerations | list | `[]` | Tolerations for pod assignment |
| user | object | `{"password":{"secretKeyRef":{"key":"","name":""},"value":""},"username":{"secretKeyRef":{"key":"","name":""},"value":""}}` | WebDAV user authentication configuration |
| user.password | object | `{"secretKeyRef":{"key":"","name":""},"value":""}` | Password configuration |
| user.password.secretKeyRef | object | `{"key":"","name":""}` | Reference to existing secret containing password |
| user.password.secretKeyRef.key | string | `""` | Key within the secret |
| user.password.secretKeyRef.name | string | `""` | Name of the secret |
| user.password.value | string | `""` | Password value (use secretKeyRef in production) |
| user.username | object | `{"secretKeyRef":{"key":"","name":""},"value":""}` | Username configuration |
| user.username.secretKeyRef | object | `{"key":"","name":""}` | Reference to existing secret containing username |
| user.username.secretKeyRef.key | string | `""` | Key within the secret |
| user.username.secretKeyRef.name | string | `""` | Name of the secret |
| user.username.value | string | `""` | Username value |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
