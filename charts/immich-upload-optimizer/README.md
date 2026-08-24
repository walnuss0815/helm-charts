# immich-upload-optimizer

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v0.5.5](https://img.shields.io/badge/AppVersion-v0.5.5-informational?style=flat-square)

A Helm chart for Immich Upload Optimizer, the smart upload proxy that optimizes images losslessly and transcodes videos with hardware acceleration before they reach Immich.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| walnuss0815 | <walnuss0815@gmail.com> | <https://github.com/walnuss0815> |

### Required

- A running [Immich](https://immich.app) server (the proxy forwards uploads to it).

### Optional

- An Ingress controller (e.g. [ingress-nginx](https://kubernetes.github.io/ingress-nginx/)) when exposing the proxy via `ingress`
- [Gateway API](https://gateway-api.sigs.k8s.io/) when exposing the proxy via `httpRoute`
- GPU device plugins when requesting an accelerator device in `resources`

## Quick start

`upstream` (the Immich server this proxy fronts) is required:

```yaml
upstream: "http://immich-server:2283"

service:
  port: 2283
```

This chart is a proxy: point the Immich client at this chart's Service and let it
optimize images / transcode videos before they are stored on the Immich server.

## Tasks configuration

Immich Upload Optimizer maps file extensions to shell commands in a YAML tasks
file. Configure it via `config.tasks` (rendered into a ConfigMap at
`/config/tasks.yaml` and referenced by `IUO_TASKS_FILE`):

```yaml
config:
  tasks:
    - name: jpeg-xl
      command: cjxl --lossless_jpeg=1 {{.folder}}/{{.name}}.{{.extension}} {{.folder}}/{{.name}}-new.jxl && rm {{.folder}}/{{.name}}.{{.extension}}
      extensions: [jpeg, jpg, png]
    - name: passthrough-videos
      command: ""
      extensions: [mp4, mov]
```

> `${TOKEN}`-style placeholders in a `command` are shell-expanded by the proxy at
> runtime, so values from `extraEnv`/`extraEnvFrom` (e.g. Kubernetes Secrets) are
> available directly. The base tasks ConfigMap stays plaintext - never put real
> secrets in `command` itself; reference them via `extraEnv`/`extraEnvFrom`.

## Hardware acceleration

The bundled image (amd64: jlesage/handbrake; arm64: plain Ubuntu) includes
HandBrakeCLI, FFmpeg, ImageMagick/libjxl, etc. Hardware video transcoding (NVIDIA
NVENC, Intel QSV/VAAPI, AMD VAAPI) is achieved by giving the proxy pod access to
the accelerator and driving it via task flags. Set the device resource directly in
the root `resources` block and schedule the pod on the right node:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
    nvidia.com/gpu: "1"
  limits:
    memory: 512Mi
    nvidia.com/gpu: "1"

nodeSelector:
  nvidia.com/gpu.present: "true"
tolerations:
  - key: nvidia.com/gpu
    operator: Exists
```

The `nvidia.com/gpu` device resource lets the cluster device plugin inject the
accelerator into the container. See the
[immich-upload-optimizer docs](https://github.com/miguelangel-nubla/immich-upload-optimizer)
for encoder flags to use inside task commands.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity rules for pod scheduling |
| config.tasks | list | `[{"command":"cjxl --lossless_jpeg=1 {{.folder}}/{{.name}}.{{.extension}} {{.folder}}/{{.name}}-new.jxl && rm {{.folder}}/{{.name}}.{{.extension}}","extensions":["jpeg","jpg","png","pgx","pam","pnm","pgm","ppm","pfm","gif","exr"],"name":"jpeg-xl"},{"command":"caesiumclt --keep-dates --exif --quality=0 --output-dir={{.folder}} {{.folder}}/{{.name}}.{{.extension}}","extensions":["jpeg","jpg","png","tiff","tif","webp","gif"],"name":"caesium"},{"command":"","extensions":["avif","bmp","heic","heif","insp","jxl","psd","raw","rw2","svg"],"name":"passthrough-images"},{"command":"","extensions":["3gp","3gpp","avi","flv","m4v","mkv","mts","m2ts","m2t","mp4","insv","mpg","mpe","mpeg","mov","webm","wmv"],"name":"passthrough-videos"}]` | Task definitions (see TASKS.md / README), rendered under the `tasks` key of the generated `/config/tasks.yaml`. `${TOKEN}`-style placeholders in a task `command` are shell-expanded at runtime by `sh -c`, so values from `extraEnv`/`extraEnvFrom` (e.g. Kubernetes Secrets) are available directly. |
| extraEnv | object | `{}` | Extra environment variables, rendered with `tpl`. Values must be strings (e.g. quote numbers) and may reference chart values (e.g. `{{ .Release.Namespace }}`); a literal `{{`/`}}` in a value will be parsed as a Go template and must be escaped (e.g. `{{ "{{" }}`) or it will fail to render. |
| extraEnvFrom | object | `{}` | Extra environment variables sourced from ConfigMaps/Secrets |
| extraManifests | list | `[]` | Extra Kubernetes manifests to deploy alongside the chart. Each entry is rendered with the Helm template engine, so it can reference chart values such as `.Release.Namespace`. Only trusted manifests should be used here. |
| extraVolumeMounts | list | `[]` | Extra volume mounts (for the extra volumes) |
| extraVolumes | list | `[]` | Extra volumes |
| filterFormKey | string | `"assetData"` | Only process uploads with this multipart form key. Maps to `IUO_FILTER_FORM_KEY` |
| filterPath | string | `"/api/assets"` | Only process uploads to this backend path. Maps to `IUO_FILTER_PATH` |
| fullnameOverride | string | `""` | Override the full chart name |
| httpRoute | object | `{"annotations":{},"enabled":false,"hostnames":["chart-example.local"],"parentRefs":[{"name":"gateway","sectionName":"http"}],"rules":[{"matches":[{"path":{"type":"PathPrefix","value":"/"}}]}]}` | Expose via Gateway API HTTPRoute |
| httpRoute.annotations | object | `{}` | HTTPRoute annotations |
| httpRoute.enabled | bool | `false` | Enable HTTPRoute |
| httpRoute.hostnames | list | `["chart-example.local"]` | Hostnames |
| httpRoute.parentRefs | list | `[{"name":"gateway","sectionName":"http"}]` | Parent refs |
| httpRoute.rules | list | `[{"matches":[{"path":{"type":"PathPrefix","value":"/"}}]}]` | Rules |
| image | object | `{"pullPolicy":"IfNotPresent","repository":"ghcr.io/miguelangel-nubla/immich-upload-optimizer","tag":""}` | Container image configuration |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.repository | string | `"ghcr.io/miguelangel-nubla/immich-upload-optimizer"` | Image repository. The default ships a multi-arch manifest: the amd64 variant is based on jlesage/handbrake (includes the HandBrake GUI + CLI and all codecs); the arm64 variant is a plain Ubuntu base with the CLI tools only. Pin a release tag (e.g. v0.5.5) for reproducibility. |
| image.tag | string | `""` | Image tag. Overrides the chart appVersion when set |
| imagePullSecrets | list | `[]` | Image pull secrets for pulling from a private registry. See [Kubernetes docs](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) |
| ingress | object | `{"annotations":{},"className":"","enabled":false,"hosts":[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}],"tls":[]}` | Ingress |
| ingress.annotations | object | `{}` | Ingress annotations |
| ingress.className | string | `""` | Ingress class name |
| ingress.enabled | bool | `false` | Enable ingress |
| ingress.hosts | list | `[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | Ingress hosts |
| ingress.tls | list | `[]` | Ingress TLS |
| listen | string | `":2283"` | Address the proxy listens on inside the container. Maps to `IUO_LISTEN` |
| livenessProbe | object | `{"periodSeconds":30,"tcpSocket":{"port":"http"}}` | Liveness probe configuration. The proxy exposes no unauthenticated health endpoint (the /_immich-upload-optimizer/* routes require job parameters), so a TCP socket check against the listener is used. |
| livenessProbe.tcpSocket | object | `{"port":"http"}` | TCP socket probe configuration |
| nameOverride | string | `""` | Override the chart name |
| nodeSelector | object | `{}` | Node selector for pod scheduling |
| podAnnotations | object | `{}` | Annotations to add to the pod |
| podLabels | object | `{}` | Labels to add to the pod |
| podSecurityContext | object | `{"fsGroup":1000}` | Pod security context |
| readinessProbe | object | `{"periodSeconds":10,"tcpSocket":{"port":"http"}}` | Readiness probe configuration. Gates the Service endpoints so traffic is only routed to a proxy that is accepting connections. |
| readinessProbe.tcpSocket | object | `{"port":"http"}` | TCP socket probe configuration |
| replicaCount | int | `1` | Number of proxy replicas |
| resources | object | `{"limits":{"memory":"512Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}` | Resource requests/limits for the proxy container. For hardware video transcoding (NVIDIA NVENC, Intel QSV/VAAPI, AMD VAAPI), request the accelerator device here (e.g. `nvidia.com/gpu: "1"`, `gpu.intel.com/i915: "1"`, `amd.com/gpu: "1"`) and schedule the pod onto an accelerator node via `nodeSelector`/`tolerations`; drive the encoder via task flags. The bundled image variants (amd64: jlesage/handbrake; arm64: plain Ubuntu) already include HandBrakeCLI, FFmpeg, ImageMagick/libjxl etc. |
| securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | Container security context |
| service | object | `{"port":2283,"type":"ClusterIP"}` | Kubernetes Service |
| service.port | int | `2283` | Service port |
| service.type | string | `"ClusterIP"` | Service type |
| serviceAccount | object | `{"annotations":{},"automount":false,"create":true,"name":""}` | Service account configuration. See [Kubernetes docs](https://kubernetes.io/docs/concepts/security/service-accounts/) |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.automount | bool | `false` | Automatically mount a ServiceAccount's API credentials |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | Name of the service account to use. If not set and `create` is true, a name is generated using the fullname template |
| startupProbe | object | `{}` | Startup probe |
| tasksPath | string | `""` | Override the tasks file path mounted from the ConfigMap at `/config/tasks.yaml`. Maps to `IUO_TASKS_FILE` This is mostly useful for the bundled ConfigMap `/config` mount path. |
| tolerations | list | `[]` | Tolerations for pod scheduling |
| upstream | string | `""` | Upstream Immich server URL, e.g. `http://immich-server:2283`. Maps to `IUO_UPSTREAM`. Required. Must be set. Rendered with Helm's `tpl`, so it may reference chart values (e.g. `{{ .Release.Namespace }}`). A literal `{{`/`}}` in the URL (e.g. in an encoded query string) will be parsed as a Go template and must be escaped (e.g. `{{ "{{" }}`) or it will fail to render. |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
