# kavita

![Version: 0.1.4](https://img.shields.io/badge/Version-0.1.4-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.9.1](https://img.shields.io/badge/AppVersion-0.9.1-informational?style=flat-square)

A Helm chart for Kavita

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| walnuss0815 | <walnuss0815@gmail.com> | <https://github.com/walnuss0815> |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity rules for pod scheduling |
| extraManifests | list | `[]` | Extra Kubernetes manifests to deploy alongside the chart. Each entry is rendered with `tpl` |
| fullnameOverride | string | `""` | Override the full resource name |
| httpRoute | object | `{"annotations":{},"enabled":false,"hostnames":["chart-example.local"],"parentRefs":[{"name":"gateway","sectionName":"http"}],"rules":[{"matches":[{"path":{"type":"PathPrefix","value":"/headers"}}]}]}` | Expose the service via a Gateway API HTTPRoute. Requires the Gateway API CRDs and a suitable controller in the cluster. See [Gateway API guides](https://gateway-api.sigs.k8s.io/guides/) |
| httpRoute.annotations | object | `{}` | HTTPRoute annotations |
| httpRoute.enabled | bool | `false` | Enable HTTPRoute |
| httpRoute.hostnames | list | `["chart-example.local"]` | Hostnames matching the HTTP Host header |
| httpRoute.parentRefs | list | `[{"name":"gateway","sectionName":"http"}]` | Gateways this route is attached to |
| httpRoute.rules | list | `[{"matches":[{"path":{"type":"PathPrefix","value":"/headers"}}]}]` | Routing rules and filters applied to matched requests |
| image | object | `{"pullPolicy":"IfNotPresent","repository":"jvmilazz0/kavita","tag":""}` | Container image configuration. See [Kubernetes docs](https://kubernetes.io/docs/concepts/containers/images/) |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.repository | string | `"jvmilazz0/kavita"` | Container image repository |
| image.tag | string | `""` | Image tag. Defaults to the chart's `appVersion` if not set |
| imagePullSecrets | list | `[]` | Secrets for pulling images from a private registry. See [Kubernetes docs](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) |
| ingress | object | `{"annotations":{},"className":"","enabled":false,"hosts":[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}],"tls":[]}` | Ingress configuration. See [Kubernetes docs](https://kubernetes.io/docs/concepts/services-networking/ingress/) |
| ingress.annotations | object | `{}` | Ingress annotations |
| ingress.className | string | `""` | Ingress class name |
| ingress.enabled | bool | `false` | Enable ingress |
| ingress.hosts | list | `[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | Ingress hosts and paths |
| ingress.tls | list | `[]` | Ingress TLS configuration |
| livenessProbe | object | `{"httpGet":{"path":"/","port":"http"}}` | Liveness probe configuration. Empty disables the probe. See [Kubernetes docs](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) |
| nameOverride | string | `""` | Override the chart name |
| nodeSelector | object | `{}` | Node selector for pod scheduling |
| persistence | object | `{"config":{"accessModes":["ReadWriteOnce"],"annotations":{},"size":"1Gi","storageClass":"-"},"library":{"accessModes":["ReadWriteOnce"],"annotations":{},"size":"1Gi","storageClass":"-"}}` | Persistence configuration for the Kavita volumes. Both PVCs are always created |
| persistence.config | object | `{"accessModes":["ReadWriteOnce"],"annotations":{},"size":"1Gi","storageClass":"-"}` | Config directory, mounted at `/kavita/config` (database, settings, covers) |
| persistence.config.accessModes | list | `["ReadWriteOnce"]` | Access modes for the config PVC |
| persistence.config.annotations | object | `{}` | Annotations for the config PVC |
| persistence.config.size | string | `"1Gi"` | Size of the config PVC |
| persistence.config.storageClass | string | `"-"` | Storage class for the config PVC. `-` leaves `storageClassName` unset, so the cluster's default StorageClass is used |
| persistence.library | object | `{"accessModes":["ReadWriteOnce"],"annotations":{},"size":"1Gi","storageClass":"-"}` | Library directory, mounted at `/library` (books, comics, manga) |
| persistence.library.accessModes | list | `["ReadWriteOnce"]` | Access modes for the library PVC |
| persistence.library.annotations | object | `{}` | Annotations for the library PVC |
| persistence.library.size | string | `"1Gi"` | Size of the library PVC |
| persistence.library.storageClass | string | `"-"` | Storage class for the library PVC. `-` leaves `storageClassName` unset, so the cluster's default StorageClass is used |
| podAnnotations | object | `{}` | Annotations to add to the pod. See [Kubernetes docs](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/) |
| podLabels | object | `{}` | Labels to add to the pod. See [Kubernetes docs](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) |
| podSecurityContext | object | `{}` | Pod-level security context |
| readinessProbe | object | `{"httpGet":{"path":"/","port":"http"}}` | Readiness probe configuration. Empty disables the probe |
| replicaCount | int | `1` | Number of replicas for the Kavita deployment. See [Kubernetes docs](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/) |
| resources | object | `{}` | Resource requests and limits for the Kavita container. See [Kubernetes docs](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) |
| securityContext | object | `{}` | Container-level security context |
| service | object | `{"port":5000,"type":"ClusterIP"}` | Kubernetes Service configuration. See [Kubernetes docs](https://kubernetes.io/docs/concepts/services-networking/service/) |
| service.port | int | `5000` | Service port. Also used as the container port, so it must match the port Kavita listens on (`5000`) |
| service.type | string | `"ClusterIP"` | Service type. See [service types](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| serviceAccount | object | `{"annotations":{},"automount":true,"create":true,"name":""}` | Service account configuration. See [Kubernetes docs](https://kubernetes.io/docs/concepts/security/service-accounts/) |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.automount | bool | `true` | Automatically mount the ServiceAccount's API credentials into the pod |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | Name of the service account to use. If not set and `create` is `true`, a name is generated using the fullname template |
| tolerations | list | `[]` | Tolerations for pod scheduling |
| volumeMounts | list | `[]` | Additional volume mounts for the Kavita container |
| volumes | list | `[]` | Additional volumes for the pod |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
