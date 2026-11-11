# paperless-ngx

![Version: 3.0.2](https://img.shields.io/badge/Version-3.0.2-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 3.4.2](https://img.shields.io/badge/AppVersion-3.4.2-informational?style=flat-square)

A Helm chart for Kubernetes

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| walnuss0815 | <walnuss0815@gmail.com> | <https://github.com/walnuss0815> |

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://valkey.io/valkey-helm/ | valkey | 0.12.1 |
| https://walnuss0815.github.io/helm-charts | gotenberg | 0.1.12 |
| https://walnuss0815.github.io/helm-charts | embeddings(text-embeddings-inference) | 0.1.2 |
| https://walnuss0815.github.io/helm-charts | tika | 0.2.0 |
| https://walnuss0815.github.io/helm-charts | webdav | 1.1.1 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity rules for pod assignment |
| ai | object | `{"enabled":false,"indexTaskCron":"10 2 * * *","llm":{"allowInternalEndpoints":true,"apiKey":{"secretKeyRef":{"key":"","name":""},"value":""},"backend":"","contextSize":8192,"embedding":{"backend":"","chunkSize":1024,"endpoint":"","model":""},"endpoint":"","extraParams":{},"model":"","outputLanguage":"","requestTimeout":120}}` | AI features configuration (LLM-powered suggestions, RAG, and document chat) |
| ai.enabled | bool | `false` | Enable AI features (master switch) |
| ai.indexTaskCron | string | `"10 2 * * *"` | Cron schedule for updating AI embeddings index |
| ai.llm.allowInternalEndpoints | bool | `true` | Allow AI endpoint URLs that resolve to private/loopback addresses. Must stay `true` when using `embeddings` |
| ai.llm.apiKey | object | `{"secretKeyRef":{"key":"","name":""},"value":""}` | API key for the LLM backend (required for OpenAI-compatible backends) |
| ai.llm.apiKey.secretKeyRef | object | `{"key":"","name":""}` | Reference to existing secret containing the API key |
| ai.llm.apiKey.secretKeyRef.key | string | `""` | Key within the secret |
| ai.llm.apiKey.secretKeyRef.name | string | `""` | Name of the secret |
| ai.llm.apiKey.value | string | `""` | API key value (use secretKeyRef in production) |
| ai.llm.backend | string | `""` | LLM backend to use ("openai-like" or "ollama") |
| ai.llm.contextSize | int | `8192` | Context size for AI prompts and RAG retrieval |
| ai.llm.embedding.backend | string | `""` | Embedding backend for RAG ("openai-like", "huggingface", or "ollama"). Instead of "huggingface", consider `embeddings.enabled`: the model stays out of the paperless data volume and backups and is not reloaded on every query. Must stay unset when `embeddings.enabled` is `true` |
| ai.llm.embedding.chunkSize | int | `1024` | Chunk size when splitting document text for RAG embeddings |
| ai.llm.embedding.endpoint | string | `""` | Embedding endpoint URL (defaults to LLM endpoint if not set). Must stay unset when `embeddings.enabled` is `true`; the chart sets it to the embeddings server |
| ai.llm.embedding.model | string | `""` | Embedding model (defaults depend on backend). With `embeddings.enabled`, defaults to `embeddings.model.id`; set it only to override the served-model name. Paperless rebuilds the LLM index when it changes |
| ai.llm.endpoint | string | `""` | Endpoint URL for the LLM backend (required for Ollama; optional for OpenAI-compatible) |
| ai.llm.extraParams | object | `{}` | Extra parameters passed to the LLM backend as JSON (`PAPERLESS_AI_LLM_EXTRA_PARAMS`), e.g. `{reasoning_effort: none}` |
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
| embeddings | object | `{"enabled":false}` | Text Embeddings Inference subchart configuration (embeddings server for the AI features). Requires `ai.enabled`. Wires the AI embeddings to this server through the `openai-like` backend, so the model stays out of the paperless data volume and its backups and is not reloaded on every query. `embeddings.model.id` is the served model (default `sentence-transformers/all-MiniLM-L6-v2`); for multilingual documents use e.g. `BAAI/bge-m3` with `embeddings.extraArgs: [--max-batch-tokens=2048]` and about 4Gi memory (`embeddings.resources`). Without the batch limit, the CPU warm-up of `BAAI/bge-m3` is OOM-killed even at 6Gi. The model is downloaded on start; enable `embeddings.persistence.enabled` to cache it |
| embeddings.enabled | bool | `false` | Enable the Text Embeddings Inference server |
| env | object | `{}` | Additional environment variables as a map of variable name to value. Values are rendered with `tpl` |
| envFrom | object | `{}` | Additional environment variables as a map of variable name to a Kubernetes `valueFrom` object, e.g. `MY_VAR: {secretKeyRef: {name: my-secret, key: my-key}}` |
| extraManifests | list | `[]` | Extra Kubernetes manifests to deploy alongside the chart. Each entry is a string or a map and is rendered with `tpl` |
| fullnameOverride | string | `""` | Override the fullname of the chart |
| gotenberg | object | `{"enabled":true}` | Gotenberg subchart configuration (for document conversion) |
| gotenberg.enabled | bool | `true` | Enable Gotenberg service |
| host | string | `"chart-example.local"` | Hostname for the paperless-ngx instance |
| httpRoute | object | `{"annotations":{},"enabled":false,"hostnames":["chart-example.local"],"parentRefs":[{"name":"gateway","sectionName":"http"}],"rules":[{"matches":[{"path":{"type":"PathPrefix","value":"/"}}]}]}` | Gateway API HTTPRoute configuration (requires Gateway API CRDs installed) |
| httpRoute.annotations | object | `{}` | HTTPRoute annotations |
| httpRoute.enabled | bool | `false` | Enable HTTPRoute |
| httpRoute.hostnames | list | `["chart-example.local"]` | Hostnames for HTTP header matching |
| httpRoute.parentRefs | list | `[{"name":"gateway","sectionName":"http"}]` | Parent gateway references to attach this route to |
| httpRoute.rules | list | `[{"matches":[{"path":{"type":"PathPrefix","value":"/"}}]}]` | Routing rules and filters |
| image | object | `{"pullPolicy":"IfNotPresent","repository":"ghcr.io/paperless-ngx/paperless-ngx","tag":""}` | Container image configuration |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.repository | string | `"ghcr.io/paperless-ngx/paperless-ngx"` | Container image repository |
| image.tag | string | `""` | Image tag. Defaults to the chart's `appVersion` if not set |
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
| ocr.languages | list | `["eng"]` | OCR languages to use (`PAPERLESS_OCR_LANGUAGE`, Tesseract codes such as `deu`). The image includes `eng`, `deu`, `fra`, `ita` and `spa`; other languages need a custom image, as `PAPERLESS_OCR_LANGUAGES` cannot install them in this rootless, read-only container. See [Tesseract language data](https://tesseract-ocr.github.io/tessdoc/Data-Files-in-different-versions.html) |
| parser | object | `{"datetime":["en"]}` | Document parser configuration |
| parser.datetime | list | `["en"]` | Date/time parsing locales. See [dateparser supported locales](https://dateparser.readthedocs.io/en/latest/supported_locales.html) |
| persistence | object | `{"consumption":{"accessModes":["ReadWriteOnce"],"annotations":{},"keep":true,"size":"512Mi","storageClass":""},"data":{"accessModes":["ReadWriteOnce"],"annotations":{},"keep":true,"size":"1Gi","storageClass":""},"media":{"accessModes":["ReadWriteOnce"],"annotations":{},"keep":true,"size":"8Gi","storageClass":""}}` | Persistence configuration for paperless-ngx volumes |
| persistence.consumption | object | `{"accessModes":["ReadWriteOnce"],"annotations":{},"keep":true,"size":"512Mi","storageClass":""}` | Consumption directory persistence configuration |
| persistence.consumption.accessModes | list | `["ReadWriteOnce"]` | Access modes for consumption PVC. Use `ReadWriteMany` when `webdav.enabled` and the webdav and paperless-ngx pods may run on different nodes |
| persistence.consumption.annotations | object | `{}` | Annotations for the consumption PVC |
| persistence.consumption.keep | bool | `true` | Keep the consumption PVC when the release is uninstalled or the Argo CD Application is deleted (`helm.sh/resource-policy: keep`). It holds the documents waiting to be consumed. Delete it manually with `kubectl delete pvc <fullname>-consumption` |
| persistence.consumption.size | string | `"512Mi"` | Size of the consumption PVC |
| persistence.consumption.storageClass | string | `""` | Storage class for consumption PVC. Empty uses the cluster's default StorageClass; `-` sets `storageClassName: ""`, which disables dynamic provisioning |
| persistence.data | object | `{"accessModes":["ReadWriteOnce"],"annotations":{},"keep":true,"size":"1Gi","storageClass":""}` | Data directory persistence configuration |
| persistence.data.accessModes | list | `["ReadWriteOnce"]` | Access modes for data PVC |
| persistence.data.annotations | object | `{}` | Annotations for the data PVC |
| persistence.data.keep | bool | `true` | Keep the data PVC when the release is uninstalled or the Argo CD Application is deleted (`helm.sh/resource-policy: keep`). It holds the search index, classification model and settings. Delete it manually with `kubectl delete pvc <fullname>-data` |
| persistence.data.size | string | `"1Gi"` | Size of the data PVC |
| persistence.data.storageClass | string | `""` | Storage class for data PVC. Empty uses the cluster's default StorageClass; `-` sets `storageClassName: ""`, which disables dynamic provisioning |
| persistence.media | object | `{"accessModes":["ReadWriteOnce"],"annotations":{},"keep":true,"size":"8Gi","storageClass":""}` | Media directory persistence configuration |
| persistence.media.accessModes | list | `["ReadWriteOnce"]` | Access modes for media PVC |
| persistence.media.annotations | object | `{}` | Annotations for the media PVC |
| persistence.media.keep | bool | `true` | Keep the media PVC when the release is uninstalled or the Argo CD Application is deleted (`helm.sh/resource-policy: keep`). It holds the archived documents and thumbnails. Delete it manually with `kubectl delete pvc <fullname>-media` |
| persistence.media.size | string | `"8Gi"` | Size of the media PVC |
| persistence.media.storageClass | string | `""` | Storage class for media PVC. Empty uses the cluster's default StorageClass; `-` sets `storageClassName: ""`, which disables dynamic provisioning |
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
| resources | object | `{"limits":{"memory":"2Gi"},"requests":{"cpu":"250m","memory":"1Gi"}}` | Resource requests and limits for the paperless-ngx container. Sized for the defaults (one web and one task worker, SQLite); raise the memory limit for many OCR threads, large scans or `ai.llm.embedding.backend: huggingface` |
| secretKey | object | `{"secretKeyRef":{"key":"","name":""},"value":""}` | Django secret key (`PAPERLESS_SECRET_KEY`) used to sign sessions and tokens. Required: set `value` or `secretKeyRef`, otherwise rendering fails. Use a long random string and keep it stable, changing it signs out all users |
| secretKey.secretKeyRef | object | `{"key":"","name":""}` | Reference to existing secret containing the secret key |
| secretKey.secretKeyRef.key | string | `""` | Key within the secret |
| secretKey.secretKeyRef.name | string | `""` | Name of the secret |
| secretKey.value | string | `""` | Plain-text secret key. Ignored if `secretKeyRef.name` and `secretKeyRef.key` are set. Prefer `secretKeyRef` |
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
| sso.enabled | bool | `false` | Enable SSO authentication. Sets `PAPERLESS_APPS` to the OpenID Connect provider app unless `PAPERLESS_APPS` is set in `env` or `envFrom` |
| tika | object | `{"enabled":true}` | Apache Tika subchart configuration (for document parsing) |
| tika.enabled | bool | `true` | Enable Apache Tika service |
| tolerations | list | `[]` | Tolerations for pod assignment |
| url | string | `"https://{{ .Values.host }}"` | URL for the paperless-ngx instance |
| valkey | object | `{"auth":{"enabled":false},"enabled":true,"resources":{"limits":{"cpu":"500m","memory":"256Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}}` | Valkey subchart configuration (Redis-compatible key-value store) |
| valkey.auth | object | `{"enabled":false}` | Valkey authentication configuration |
| valkey.auth.enabled | bool | `false` | Enable Valkey password authentication. Disabled by default; enable it for production and include the credentials in `valkeyKV.url` |
| valkey.enabled | bool | `true` | Enable Valkey as a subchart |
| valkey.resources | object | `{"limits":{"cpu":"500m","memory":"256Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}` | Resource limits/requests for the Valkey container |
| valkeyKV | object | `{"url":{"secretKeyRef":{"key":"","name":""},"value":"redis://{{ .Release.Name }}-valkey:6379"}}` | Valkey (Redis-compatible) key-value store configuration |
| valkeyKV.url | object | `{"secretKeyRef":{"key":"","name":""},"value":"redis://{{ .Release.Name }}-valkey:6379"}` | Valkey connection URL configuration |
| valkeyKV.url.secretKeyRef | object | `{"key":"","name":""}` | Reference to existing secret containing Valkey URL |
| valkeyKV.url.secretKeyRef.key | string | `""` | Key within the secret |
| valkeyKV.url.secretKeyRef.name | string | `""` | Name of the secret |
| valkeyKV.url.value | string | `"redis://{{ .Release.Name }}-valkey:6379"` | Valkey URL value (note: paperless-ngx expects the redis:// scheme even when connecting to Valkey) |
| webdav | object | See the webdav.* rows | WebDAV configuration for document consumption |
| webdav.enabled | bool | `false` | Enable WebDAV integration |
| webdav.persistence.data.claimName | string | `<fullname>-consumption` | Name of the consumption PVC mounted into WebDAV. Rendered with `tpl` in the webdav subchart, so it mirrors this chart's fullname (including its 63-character truncation) from the release name. Set it to `<fullname>-consumption` when `nameOverride` or `fullnameOverride` is set |
| workerTimeout | int | `nil` | Celery task hard time limit in seconds (`PAPERLESS_WORKER_TIMEOUT`). Paperless defaults to 1800 s. It also limits the LLM index build (`llmindex_index`); large embedding models on CPU can exceed it on the first build. Unset or `0` keeps the default |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
