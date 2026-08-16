# paperless-ngx

![Version: 0.3.0](https://img.shields.io/badge/Version-0.3.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2.20.8](https://img.shields.io/badge/AppVersion-2.20.8-informational?style=flat-square)

A Helm chart for Kubernetes

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| walnuss0815 | <walnuss0815@gmail.com> | <https://github.com/walnuss0815> |

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://valkey.io/valkey-helm/ | valkey | 0.11.0 |
| https://walnuss0815.github.io/helm-charts | gotenberg | 0.1.5 |
| https://walnuss0815.github.io/helm-charts | tika | 0.1.2 |
| https://walnuss0815.github.io/helm-charts | webdav | 0.1.4 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity rules for pod assignment |
| ai | object | `{"enabled":false,"indexTaskCron":"10 2 * * *","llm":{"allowInternalEndpoints":true,"apiKey":{"secretKeyRef":{"key":"","name":""},"value":""},"backend":"","contextSize":8192,"embedding":{"backend":"","chunkSize":1024,"endpoint":"","model":""},"endpoint":"","model":"","outputLanguage":"","requestTimeout":120}}` | AI features configuration (LLM-powered suggestions, RAG, and document chat) |
| ai.enabled | bool | `false` | Enable AI features (master switch) |
| ai.indexTaskCron | string | `"10 2 * * *"` | Cron schedule for updating AI embeddings index |
| ai.llm.allowInternalEndpoints | bool | `true` | Allow AI endpoint URLs that resolve to private/loopback addresses |
| ai.llm.apiKey | object | `{"secretKeyRef":{"key":"","name":""},"value":""}` | API key for the LLM backend (required for OpenAI-compatible backends) |
| ai.llm.apiKey.secretKeyRef | object | `{"key":"","name":""}` | Reference to existing secret containing the API key |
| ai.llm.apiKey.secretKeyRef.key | string | `""` | Key within the secret |
| ai.llm.apiKey.secretKeyRef.name | string | `""` | Name of the secret |
| ai.llm.apiKey.value | string | `""` | API key value (use secretKeyRef in production) |
| ai.llm.backend | string | `""` | LLM backend to use ("openai-like" or "ollama") |
| ai.llm.contextSize | int | `8192` | Context size for AI prompts and RAG retrieval |
| ai.llm.embedding.backend | string | `""` | Embedding backend for RAG ("openai-like", "huggingface", or "ollama") |
| ai.llm.embedding.chunkSize | int | `1024` | Chunk size when splitting document text for RAG embeddings |
| ai.llm.embedding.endpoint | string | `""` | Embedding endpoint URL (defaults to LLM endpoint if not set) |
| ai.llm.embedding.model | string | `""` | Embedding model (defaults depend on backend) |
| ai.llm.endpoint | string | `""` | Endpoint URL for the LLM backend (required for Ollama; optional for OpenAI-compatible) |
| ai.llm.model | string | `""` | LLM model to use (defaults to "gpt-3.5-turbo" for OpenAI-compatible or "llama3.1" for Ollama) |
| ai.llm.outputLanguage | string | `""` | Language for AI suggestions (defaults to user's UI language) |
| ai.llm.requestTimeout | int | `120` | Timeout in seconds for requests to the AI backend |
| database | object | `{"enabled":false,"engine":"postgresql","host":"","name":"paperless","password":{"secretKeyRef":{"key":"","name":""},"value":"paperless"},"port":5432,"username":{"secretKeyRef":{"key":"","name":""},"value":"paperless"}}` | External database configuration |
| database.enabled | bool | `false` | Enable external database (if false, uses SQLite) |
| database.engine | string | `"postgresql"` | Database engine (postgresql, mysql, mariadb) |
| database.host | string | `""` | Database host |
| database.name | string | `"paperless"` | Database name |
| database.password | object | `{"secretKeyRef":{"key":"","name":""},"value":"paperless"}` | Database password configuration |
| database.password.secretKeyRef | object | `{"key":"","name":""}` | Reference to existing secret containing database password |
| database.password.secretKeyRef.key | string | `""` | Key within the secret |
| database.password.secretKeyRef.name | string | `""` | Name of the secret |
| database.password.value | string | `"paperless"` | Database password value (use secretKeyRef in production) |
| database.port | int | `5432` | Database port |
| database.username | object | `{"secretKeyRef":{"key":"","name":""},"value":"paperless"}` | Database username configuration |
| database.username.secretKeyRef | object | `{"key":"","name":""}` | Reference to existing secret containing database username |
| database.username.secretKeyRef.key | string | `""` | Key within the secret |
| database.username.secretKeyRef.name | string | `""` | Name of the secret |
| database.username.value | string | `"paperless"` | Database username value |
| env | object | `{}` | Additional environment variables to set |
| envFrom | object | `{}` | Additional environment variables from ConfigMaps or Secrets |
| extraManifests | list | `[]` | Extra Kubernetes manifests to deploy |
| fullnameOverride | string | `""` | Override the fullname of the chart |
| gotenberg | object | `{"enabled":true}` | Gotenberg subchart configuration (for document conversion) |
| gotenberg.enabled | bool | `true` | Enable Gotenberg service |
| host | string | `"chart-example.local"` | Hostname for the paperless-ngx instance |
| httpRoute | object | `{"annotations":{},"enabled":false,"hostnames":["chart-example.local"],"parentRefs":[{"name":"gateway","sectionName":"http"}],"rules":[{"matches":[{"path":{"type":"PathPrefix","value":"/headers"}}]}]}` | Gateway API HTTPRoute configuration (requires Gateway API CRDs installed) |
| httpRoute.annotations | object | `{}` | HTTPRoute annotations |
| httpRoute.enabled | bool | `false` | Enable HTTPRoute |
| httpRoute.hostnames | list | `["chart-example.local"]` | Hostnames for HTTP header matching |
| httpRoute.parentRefs | list | `[{"name":"gateway","sectionName":"http"}]` | Parent gateway references to attach this route to |
| httpRoute.rules | list | `[{"matches":[{"path":{"type":"PathPrefix","value":"/headers"}}]}]` | Routing rules and filters |
| image | object | `{"pullPolicy":"IfNotPresent","repository":"ghcr.io/paperless-ngx/paperless-ngx","tag":"3.0.3"}` | Container image configuration |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.repository | string | `"ghcr.io/paperless-ngx/paperless-ngx"` | Container image repository |
| image.tag | string | `"3.0.3"` | Overrides the image tag whose default is the chart appVersion |
| imagePullSecrets | list | `[]` | Image pull secrets for private registries |
| ingress | object | `{"annotations":{},"className":"","enabled":false,"host":"{{ .Values.host }}","tls":[]}` | Ingress configuration |
| ingress.annotations | object | `{}` | Ingress annotations |
| ingress.className | string | `""` | Ingress class name |
| ingress.enabled | bool | `false` | Enable ingress |
| ingress.host | string | `"{{ .Values.host }}"` | Ingress hostname |
| ingress.tls | list | `[]` | TLS configuration |
| livenessProbe | object | `{"httpGet":{"path":"/","port":"http"},"initialDelaySeconds":30,"timeoutSeconds":5}` | Liveness probe configuration |
| livenessProbe.httpGet | object | `{"path":"/","port":"http"}` | HTTP GET configuration for liveness probe |
| livenessProbe.initialDelaySeconds | int | `30` | Initial delay before starting probes |
| livenessProbe.timeoutSeconds | int | `5` | Timeout in seconds for the probe |
| nameOverride | string | `""` | Override the name of the chart |
| nodeSelector | object | `{}` | Node selector for pod assignment |
| ocr | object | `{"languages":["eng"]}` | OCR (Optical Character Recognition) configuration |
| ocr.languages | list | `["eng"]` | OCR languages to install (3-letter ISO 639-2 codes). See [Tesseract language data](https://tesseract-ocr.github.io/tessdoc/Data-Files-in-different-versions.html) |
| parser | object | `{"datetime":["en"]}` | Document parser configuration |
| parser.datetime | list | `["en"]` | Date/time parsing locales. See [dateparser supported locales](https://dateparser.readthedocs.io/en/latest/supported_locales.html) |
| persistence | object | `{"consumption":{"accessModes":["ReadWriteMany"],"annotations":{},"size":"512Mi","storageClass":"-"},"data":{"accessModes":["ReadWriteOnce"],"annotations":{},"size":"1Gi","storageClass":"-"},"media":{"accessModes":["ReadWriteOnce"],"annotations":{},"size":"8Gi","storageClass":"-"}}` | Persistence configuration for paperless-ngx volumes |
| persistence.consumption | object | `{"accessModes":["ReadWriteMany"],"annotations":{},"size":"512Mi","storageClass":"-"}` | Consumption directory persistence configuration |
| persistence.consumption.accessModes | list | `["ReadWriteMany"]` | Access modes for consumption PVC |
| persistence.consumption.annotations | object | `{}` | Annotations for the consumption PVC |
| persistence.consumption.size | string | `"512Mi"` | Size of the consumption PVC |
| persistence.consumption.storageClass | string | `"-"` | Storage class for consumption PVC |
| persistence.data | object | `{"accessModes":["ReadWriteOnce"],"annotations":{},"size":"1Gi","storageClass":"-"}` | Data directory persistence configuration |
| persistence.data.accessModes | list | `["ReadWriteOnce"]` | Access modes for data PVC |
| persistence.data.annotations | object | `{}` | Annotations for the data PVC |
| persistence.data.size | string | `"1Gi"` | Size of the data PVC |
| persistence.data.storageClass | string | `"-"` | Storage class for data PVC |
| persistence.media | object | `{"accessModes":["ReadWriteOnce"],"annotations":{},"size":"8Gi","storageClass":"-"}` | Media directory persistence configuration |
| persistence.media.accessModes | list | `["ReadWriteOnce"]` | Access modes for media PVC |
| persistence.media.annotations | object | `{}` | Annotations for the media PVC |
| persistence.media.size | string | `"8Gi"` | Size of the media PVC |
| persistence.media.storageClass | string | `"-"` | Storage class for media PVC |
| podAnnotations | object | `{}` | Annotations to add to the pod |
| podLabels | object | `{}` | Labels to add to the pod |
| podSecurityContext | object | `{"fsGroup":1000,"fsGroupChangePolicy":"OnRootMismatch"}` | Pod security context configuration |
| podSecurityContext.fsGroup | int | `1000` | Set filesystem group ownership for mounted volumes |
| podSecurityContext.fsGroupChangePolicy | string | `"OnRootMismatch"` | Define behavior when fsGroup changes |
| readinessProbe | object | `{"httpGet":{"path":"/","port":"http"},"initialDelaySeconds":30,"timeoutSeconds":5}` | Readiness probe configuration |
| readinessProbe.httpGet | object | `{"path":"/","port":"http"}` | HTTP GET configuration for readiness probe |
| readinessProbe.initialDelaySeconds | int | `30` | Initial delay before starting probes |
| readinessProbe.timeoutSeconds | int | `5` | Timeout in seconds for the probe |
| replicaCount | int | `1` | Number of replicas for the paperless-ngx deployment |
| resources | object | `{}` | Resource limits and requests for the paperless-ngx container |
| secretKey | object | `{"secretKeyRef":{"key":"","name":""},"value":"FQdWQr5xKy8ZYTD4YB5rJAE9e2CbWb3E"}` | Secret key configuration for Django |
| secretKey.secretKeyRef | object | `{"key":"","name":""}` | Reference to existing secret containing the secret key |
| secretKey.secretKeyRef.key | string | `""` | Key within the secret |
| secretKey.secretKeyRef.name | string | `""` | Name of the secret |
| secretKey.value | string | `"FQdWQr5xKy8ZYTD4YB5rJAE9e2CbWb3E"` | Secret key value (use secretKeyRef in production) |
| securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | Container security context configuration |
| securityContext.allowPrivilegeEscalation | bool | `false` | Prevent privilege escalation |
| securityContext.capabilities | object | `{"drop":["ALL"]}` | Linux capabilities to drop |
| securityContext.readOnlyRootFilesystem | bool | `true` | Mount root filesystem as read-only |
| securityContext.runAsGroup | int | `1000` | Group ID to run the container as |
| securityContext.runAsNonRoot | bool | `true` | Run container as non-root user |
| securityContext.runAsUser | int | `1000` | User ID to run the container as |
| securityContext.seccompProfile | object | `{"type":"RuntimeDefault"}` | Seccomp profile configuration |
| service | object | `{"port":8000,"type":"ClusterIP"}` | Service configuration |
| service.port | int | `8000` | Service port |
| service.type | string | `"ClusterIP"` | Service type (ClusterIP, NodePort, LoadBalancer) |
| serviceAccount | object | `{"annotations":{},"automount":true,"create":true,"name":""}` | Service account configuration |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use (if not set and create is true, a name is generated using the fullname template) |
| smtp | object | `{"emailFrom":"","enabled":false,"host":"","password":{"secretKeyRef":{"key":"","name":""},"value":""},"port":25,"useSSL":false,"useTLS":false,"username":{"secretKeyRef":{"key":"","name":""},"value":""}}` | SMTP email configuration |
| smtp.emailFrom | string | `""` | Email address to use in 'From' field |
| smtp.enabled | bool | `false` | Enable SMTP email functionality |
| smtp.host | string | `""` | SMTP server hostname |
| smtp.password | object | `{"secretKeyRef":{"key":"","name":""},"value":""}` | SMTP password configuration |
| smtp.password.secretKeyRef | object | `{"key":"","name":""}` | Reference to existing secret containing SMTP password |
| smtp.password.secretKeyRef.key | string | `""` | Key within the secret |
| smtp.password.secretKeyRef.name | string | `""` | Name of the secret |
| smtp.password.value | string | `""` | SMTP password value (use secretKeyRef in production) |
| smtp.port | int | `25` | SMTP server port |
| smtp.useSSL | bool | `false` | Use SSL for SMTP connection |
| smtp.useTLS | bool | `false` | Use TLS for SMTP connection |
| smtp.username | object | `{"secretKeyRef":{"key":"","name":""},"value":""}` | SMTP username configuration |
| smtp.username.secretKeyRef | object | `{"key":"","name":""}` | Reference to existing secret containing SMTP username |
| smtp.username.secretKeyRef.key | string | `""` | Key within the secret |
| smtp.username.secretKeyRef.name | string | `""` | Name of the secret |
| smtp.username.value | string | `""` | SMTP username value |
| sso | object | `{"autoSignup":false,"config":{},"enabled":false}` | Single Sign-On (SSO) configuration |
| sso.autoSignup | bool | `false` | Automatically create user accounts on first SSO login |
| sso.config | object | `{}` | SSO provider configuration (OpenID Connect). See [django-allauth documentation](https://docs.allauth.org/en/latest/socialaccount/providers/openid_connect.html) |
| sso.enabled | bool | `false` | Enable SSO authentication |
| tika | object | `{"enabled":true}` | Apache Tika subchart configuration (for document parsing) |
| tika.enabled | bool | `true` | Enable Apache Tika service |
| tolerations | list | `[]` | Tolerations for pod assignment |
| url | string | `"https://{{ .Values.host }}"` | URL for the paperless-ngx instance |
| valkey | object | `{"auth":{"enabled":false},"enabled":true,"resources":{"limits":{"cpu":"500m","memory":"256Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}}` | Valkey subchart configuration (Redis-compatible key-value store) |
| valkey.auth | object | `{"enabled":false}` | Valkey authentication configuration |
| valkey.auth.enabled | bool | `false` | Enable Valkey password authentication (TODO: Enable in production) |
| valkey.enabled | bool | `true` | Enable Valkey as a subchart |
| valkey.resources | object | `{"limits":{"cpu":"500m","memory":"256Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}` | Resource limits/requests for the Valkey container |
| valkeyKV | object | `{"url":{"secretKeyRef":{"key":"","name":""},"value":"redis://{{ .Release.Name }}-valkey:6379"}}` | Valkey (Redis-compatible) key-value store configuration |
| valkeyKV.url | object | `{"secretKeyRef":{"key":"","name":""},"value":"redis://{{ .Release.Name }}-valkey:6379"}` | Valkey connection URL configuration |
| valkeyKV.url.secretKeyRef | object | `{"key":"","name":""}` | Reference to existing secret containing Valkey URL |
| valkeyKV.url.secretKeyRef.key | string | `""` | Key within the secret |
| valkeyKV.url.secretKeyRef.name | string | `""` | Name of the secret |
| valkeyKV.url.value | string | `"redis://{{ .Release.Name }}-valkey:6379"` | Valkey URL value (note: paperless-ngx expects the redis:// scheme even when connecting to Valkey) |
| webdav | object | `{"enabled":false,"persistence":{"data":{"claimName":"{{ .Release.Name }}-consumption"}}}` | WebDAV configuration for document consumption |
| webdav.enabled | bool | `false` | Enable WebDAV integration |
| webdav.persistence | object | `{"data":{"claimName":"{{ .Release.Name }}-consumption"}}` | WebDAV persistence configuration |
| webdav.persistence.data | object | `{"claimName":"{{ .Release.Name }}-consumption"}` | Data directory configuration |
| webdav.persistence.data.claimName | string | `"{{ .Release.Name }}-consumption"` | PVC claim name for WebDAV consumption |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
