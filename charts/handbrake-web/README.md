# handbrake-web

![Version: 0.1.1](https://img.shields.io/badge/Version-0.1.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.8.1](https://img.shields.io/badge/AppVersion-0.8.1-informational?style=flat-square)

A Helm chart for HandBrake Web

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| walnuss0815 | <walnuss0815@gmail.com> | <https://github.com/walnuss0815> |

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://walnuss0815.github.io/helm-charts | webdav | 0.1.11 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| extraManifests | list | `[]` | Extra Kubernetes manifests to deploy |
| fullnameOverride | string | `""` | Override the fullname of the chart |
| httpRoute | object | `{"annotations":{},"enabled":false,"hostnames":["chart-example.local"],"parentRefs":[{"name":"gateway","sectionName":"http"}],"rules":[{"matches":[{"path":{"type":"PathPrefix","value":"/headers"}}]}]}` | Expose the server component via gateway-api HTTPRoute Requires Gateway API resources and suitable controller installed within the cluster (see: https://gateway-api.sigs.k8s.io/guides/) |
| httpRoute.annotations | object | `{}` | HTTPRoute annotations |
| httpRoute.enabled | bool | `false` | HTTPRoute enabled |
| httpRoute.hostnames | list | `["chart-example.local"]` | Hostnames matching HTTP header |
| httpRoute.parentRefs | list | `[{"name":"gateway","sectionName":"http"}]` | Which Gateways this Route is attached to |
| httpRoute.rules | list | `[{"matches":[{"path":{"type":"PathPrefix","value":"/headers"}}]}]` | List of rules and filters applied |
| imagePullSecrets | list | `[]` | Image pull secrets for private registries |
| ingress | object | `{"annotations":{},"className":"","enabled":false,"hosts":[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}],"tls":[]}` | Ingress configuration for the server component |
| ingress.annotations | object | `{}` | Ingress annotations |
| ingress.className | string | `""` | Ingress class name |
| ingress.enabled | bool | `false` | Enable ingress |
| ingress.hosts | list | `[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | Ingress hosts configuration |
| ingress.tls | list | `[]` | TLS configuration |
| nameOverride | string | `""` | Override the name of the chart |
| persistence | object | `{"data":{"accessModes":["ReadWriteOnce"],"annotations":{},"mountPath":"/data","size":"1Gi","storageClass":"-"},"video":{"accessModes":["ReadWriteMany"],"annotations":{},"mountPath":"/video","size":"16Gi","storageClass":"-"}}` | Persistence configuration, shared between the server and worker workloads (and optionally the webdav subchart) |
| persistence.data | object | `{"accessModes":["ReadWriteOnce"],"annotations":{},"mountPath":"/data","size":"1Gi","storageClass":"-"}` | Config/data directory persistence configuration |
| persistence.data.accessModes | list | `["ReadWriteOnce"]` | Access modes for the data PVC |
| persistence.data.annotations | object | `{}` | Annotations for the data PVC |
| persistence.data.mountPath | string | `"/data"` | Mount path for this volume within the server/worker containers |
| persistence.data.size | string | `"1Gi"` | Size of the data PVC |
| persistence.data.storageClass | string | `"-"` | Storage class for the data PVC |
| persistence.video | object | `{"accessModes":["ReadWriteMany"],"annotations":{},"mountPath":"/video","size":"16Gi","storageClass":"-"}` | Video library persistence configuration |
| persistence.video.accessModes | list | `["ReadWriteMany"]` | Access modes for the video PVC. Defaults to `ReadWriteMany` because the server, worker, and the optional webdav subchart all mount this PVC concurrently. Most default/local-path StorageClasses (including `kind`'s) only support `ReadWriteOnce` - make sure your StorageClass actually supports RWX before relying on this default, or override it if server/worker/webdav never run on different nodes at once. |
| persistence.video.annotations | object | `{}` | Annotations for the video PVC |
| persistence.video.mountPath | string | `"/video"` | Mount path for this volume within the server/worker containers |
| persistence.video.size | string | `"16Gi"` | Size of the video PVC |
| persistence.video.storageClass | string | `"-"` | Storage class for the video PVC |
| server | object | `{"affinity":{},"image":{"pullPolicy":"IfNotPresent","repository":"ghcr.io/thenickoftime/handbrake-web-server","tag":""},"livenessProbe":{"httpGet":{"path":"/","port":"http"},"initialDelaySeconds":10},"nodeSelector":{},"podAnnotations":{},"podLabels":{},"podSecurityContext":{"fsGroup":1000,"fsGroupChangePolicy":"OnRootMismatch"},"readinessProbe":{"httpGet":{"path":"/","port":"http"},"initialDelaySeconds":10},"replicaCount":1,"resources":{},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}},"service":{"port":9999,"type":"ClusterIP"},"tolerations":[]}` | Server workload configuration |
| server.affinity | object | `{}` | Affinity rules for server pod assignment |
| server.image | object | `{"pullPolicy":"IfNotPresent","repository":"ghcr.io/thenickoftime/handbrake-web-server","tag":""}` | Container image configuration |
| server.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| server.image.repository | string | `"ghcr.io/thenickoftime/handbrake-web-server"` | Container image repository |
| server.image.tag | string | `""` | Image tag. Defaults to the chart's `appVersion` if not set |
| server.livenessProbe | object | `{"httpGet":{"path":"/","port":"http"},"initialDelaySeconds":10}` | Liveness probe configuration |
| server.nodeSelector | object | `{}` | Node selector for server pod assignment |
| server.podAnnotations | object | `{}` | Annotations to add to the server pod |
| server.podLabels | object | `{}` | Labels to add to the server pod |
| server.podSecurityContext | object | `{"fsGroup":1000,"fsGroupChangePolicy":"OnRootMismatch"}` | Pod security context configuration |
| server.readinessProbe | object | `{"httpGet":{"path":"/","port":"http"},"initialDelaySeconds":10}` | Readiness probe configuration |
| server.replicaCount | int | `1` | Number of replicas for the server deployment |
| server.resources | object | `{}` | Resource limits and requests for the server container |
| server.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | Container security context configuration |
| server.service | object | `{"port":9999,"type":"ClusterIP"}` | Service configuration |
| server.service.port | int | `9999` | Service port |
| server.service.type | string | `"ClusterIP"` | Service type (ClusterIP, NodePort, LoadBalancer) |
| server.tolerations | list | `[]` | Tolerations for server pod assignment |
| serviceAccount | object | `{"annotations":{},"automount":true,"create":true,"name":""}` | Service account configuration |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use (if not set and create is true, a name is generated using the fullname template) |
| webdav | object | `{"enabled":true,"persistence":{"data":{"claimName":"{{ if contains \"handbrake-web\" .Release.Name }}{{ .Release.Name }}{{ else }}{{ .Release.Name }}-handbrake-web{{ end }}-video"}}}` | webdav subchart configuration, exposing the shared video library over WebDAV. See [webdav chart](../webdav) for all available options |
| webdav.enabled | bool | `true` | Enable the bundled webdav subchart |
| webdav.persistence | object | `{"data":{"claimName":"{{ if contains \"handbrake-web\" .Release.Name }}{{ .Release.Name }}{{ else }}{{ .Release.Name }}-handbrake-web{{ end }}-video"}}` | Persistence configuration passed to the webdav subchart |
| webdav.persistence.data.claimName | string | `"{{ if contains \"handbrake-web\" .Release.Name }}{{ .Release.Name }}{{ else }}{{ .Release.Name }}-handbrake-web{{ end }}-video"` | Name of the existing `video` PVC (created by this chart) to mount into webdav |
| worker | object | `{"affinity":{},"image":{"pullPolicy":"IfNotPresent","repository":"ghcr.io/thenickoftime/handbrake-web-worker","tag":""},"livenessProbe":{},"nodeSelector":{},"podAnnotations":{},"podLabels":{},"podSecurityContext":{"fsGroup":1000,"fsGroupChangePolicy":"OnRootMismatch"},"readinessProbe":{},"replicaCount":1,"resources":{},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}},"terminationGracePeriodSeconds":300,"tolerations":[]}` | Worker workload configuration |
| worker.affinity | object | `{}` | Affinity rules for worker pod assignment |
| worker.image | object | `{"pullPolicy":"IfNotPresent","repository":"ghcr.io/thenickoftime/handbrake-web-worker","tag":""}` | Container image configuration |
| worker.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| worker.image.repository | string | `"ghcr.io/thenickoftime/handbrake-web-worker"` | Container image repository |
| worker.image.tag | string | `""` | Image tag. Defaults to the chart's `appVersion` if not set |
| worker.livenessProbe | object | `{}` | Liveness probe configuration (disabled by default) |
| worker.nodeSelector | object | `{}` | Node selector for worker pod assignment |
| worker.podAnnotations | object | `{}` | Annotations to add to the worker pod |
| worker.podLabels | object | `{}` | Labels to add to the worker pod |
| worker.podSecurityContext | object | `{"fsGroup":1000,"fsGroupChangePolicy":"OnRootMismatch"}` | Pod security context configuration |
| worker.readinessProbe | object | `{}` | Readiness probe configuration (disabled by default) |
| worker.replicaCount | int | `1` | Number of replicas for the worker deployment |
| worker.resources | object | `{}` | Resource limits and requests for the worker container |
| worker.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | Container security context configuration |
| worker.terminationGracePeriodSeconds | int | `300` | Grace period (in seconds) given to the worker to finish an in-progress transcode before it is forcibly killed on termination (rolling updates, node drains, etc.). The Kubernetes default of 30s is very likely too short for a video transcode to finish or checkpoint. |
| worker.tolerations | list | `[]` | Tolerations for worker pod assignment |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
