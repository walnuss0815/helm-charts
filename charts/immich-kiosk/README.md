# immich-kiosk

![Version: 0.2.2](https://img.shields.io/badge/Version-0.2.2-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.43.1](https://img.shields.io/badge/AppVersion-0.43.1-informational?style=flat-square)

A Helm chart for Immich Kiosk

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| walnuss0815 | <walnuss0815@gmail.com> | <https://github.com/walnuss0815> |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity rules for pod scheduling. |
| config | object | `{}` | Immich Kiosk application configuration. ref: https://docs.immichkiosk.app/configuration/ |
| customCSS | string | `""` | Custom CSS injected into the kiosk UI. |
| env | object | `{}` | Additional environment variables to set on the container. |
| envFrom | object | `{}` | Additional environment variables sourced from ConfigMaps or Secrets. |
| extraManifests | list | `[]` | Extra Kubernetes manifests to deploy alongside the chart. |
| fullnameOverride | string | `""` | Override the full chart name. |
| httpRoute | object | `{"annotations":{},"enabled":false,"hostnames":["chart-example.local"],"parentRefs":[{"name":"gateway","sectionName":"http"}],"rules":[{"matches":[{"path":{"type":"PathPrefix","value":"/headers"}}]}]}` | Expose the service via Gateway API HTTPRoute. Requires Gateway API resources and a suitable controller installed in the cluster. ref: https://gateway-api.sigs.k8s.io/guides/ |
| httpRoute.annotations | object | `{}` | HTTPRoute annotations. |
| httpRoute.enabled | bool | `false` | Enable HTTPRoute. |
| httpRoute.hostnames | list | `["chart-example.local"]` | Hostnames matching the HTTP host header. |
| httpRoute.parentRefs | list | `[{"name":"gateway","sectionName":"http"}]` | Gateways this route is attached to. |
| httpRoute.rules | list | `[{"matches":[{"path":{"type":"PathPrefix","value":"/headers"}}]}]` | List of routing rules and filters applied to matched requests. |
| image | object | `{"pullPolicy":"IfNotPresent","repository":"ghcr.io/damongolding/immich-kiosk","tag":""}` | Container image configuration. |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy. |
| image.repository | string | `"ghcr.io/damongolding/immich-kiosk"` | Image repository. |
| image.tag | string | `""` | Image tag. Defaults to the chart's `appVersion` if not set. |
| imagePullSecrets | list | `[]` | Secrets for pulling images from a private registry. ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/ |
| immich | object | `{"apiKey":{"secretKeyRef":{"key":"","name":""},"value":""},"externalURL":"","url":""}` | Immich server connection configuration. |
| immich.apiKey | object | `{"secretKeyRef":{"key":"","name":""},"value":""}` | Immich API key configuration. |
| immich.apiKey.secretKeyRef | object | `{"key":"","name":""}` | Reference to a Kubernetes Secret containing the API key. |
| immich.apiKey.secretKeyRef.key | string | `""` | Key within the secret. |
| immich.apiKey.secretKeyRef.name | string | `""` | Name of the secret. |
| immich.apiKey.value | string | `""` | API key value (plaintext). Use `secretKeyRef` instead for production. |
| immich.externalURL | string | `""` | External URL of the Immich server, used for generating links. |
| immich.url | string | `""` | URL of the Immich server (internal cluster URL). |
| ingress | object | `{"annotations":{},"className":"","enabled":false,"hosts":[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}],"tls":[]}` | Ingress configuration. ref: https://kubernetes.io/docs/concepts/services-networking/ingress/ |
| ingress.annotations | object | `{}` | Ingress annotations. |
| ingress.className | string | `""` | Ingress class name. |
| ingress.enabled | bool | `false` | Enable ingress. |
| ingress.hosts | list | `[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | Ingress hosts configuration. |
| ingress.tls | list | `[]` | Ingress TLS configuration. |
| lang | string | `"en_GB"` | Locale for Immich Kiosk display formatting. ref: https://www.localeplanet.com/icu/ |
| livenessProbe | object | `{"exec":{"command":["/kiosk","--healthcheck"]}}` | Liveness probe configuration. ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ |
| nameOverride | string | `""` | Override the chart name. |
| nodeSelector | object | `{}` | Node selector for pod scheduling. |
| password | object | `{"secretKeyRef":{"key":"","name":""},"value":""}` | Password protection for the kiosk UI. ref: https://docs.immichkiosk.app/configuration/additional-options/#password |
| password.secretKeyRef | object | `{"key":"","name":""}` | Reference to a Kubernetes Secret containing the password. |
| password.secretKeyRef.key | string | `""` | Key within the secret. |
| password.secretKeyRef.name | string | `""` | Name of the secret. |
| password.value | string | `""` | Password value (plaintext). Use `secretKeyRef` instead for production. |
| podAnnotations | object | `{}` | Annotations to add to the pod. ref: https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/ |
| podLabels | object | `{}` | Labels to add to the pod. ref: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/ |
| podSecurityContext | object | `{}` | Pod-level security context. ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod |
| readinessProbe | object | `{"exec":{"command":["/kiosk","--healthcheck"]}}` | Readiness probe configuration. |
| replicaCount | int | `1` | Number of replicas for the deployment. |
| resources | object | `{}` | Resource requests and limits for the container. ref: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ |
| securityContext | object | `{}` | Container-level security context. ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container |
| service | object | `{"port":3000,"type":"ClusterIP"}` | Kubernetes Service configuration. ref: https://kubernetes.io/docs/concepts/services-networking/service/ |
| service.port | int | `3000` | Service port. |
| service.type | string | `"ClusterIP"` | Service type. |
| serviceAccount | object | `{"annotations":{},"automount":true,"create":true,"name":""}` | Service account configuration. ref: https://kubernetes.io/docs/concepts/security/service-accounts/ |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account. |
| serviceAccount.automount | bool | `true` | Automatically mount the ServiceAccount's API credentials into the pod. |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created. |
| serviceAccount.name | string | `""` | Name of the service account to use. If not set and `create` is true, a name is generated using the fullname template. |
| timeZone | string | `"UTC"` | Time zone for Immich Kiosk. ref: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List |
| tolerations | list | `[]` | Tolerations for pod scheduling. |
| weather | object | `{"apiKey":{"secretKeyRef":{"key":"","name":""},"value":""}}` | Weather configuration. ref: https://docs.immichkiosk.app/configuration/weather/ |
| weather.apiKey | object | `{"secretKeyRef":{"key":"","name":""},"value":""}` | OpenWeatherMap API key configuration. The key is injected into each configured weather location at startup via the app's `KIOSK_WEATHER_API_KEY_FILE` docker-secret mechanism; leave the `api` field of the locations in `config` empty. |
| weather.apiKey.secretKeyRef | object | `{"key":"","name":""}` | Reference to a Kubernetes Secret containing the weather API key. |
| weather.apiKey.secretKeyRef.key | string | `""` | Key within the secret. |
| weather.apiKey.secretKeyRef.name | string | `""` | Name of the secret. |
| weather.apiKey.value | string | `""` | Weather API key value (plaintext). Use `secretKeyRef` instead for production. |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
