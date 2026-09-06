# immich

![Version: 0.1.1](https://img.shields.io/badge/Version-0.1.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v3.1.0](https://img.shields.io/badge/AppVersion-v3.1.0-informational?style=flat-square)

A Helm chart for Immich, the high performance self-hosted photo and video management solution.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| walnuss0815 | <walnuss0815@gmail.com> | <https://github.com/walnuss0815> |

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://valkey.io/valkey-helm/ | valkey | 0.12.0 |
| https://walnuss0815.github.io/helm-charts | upload-optimizer(immich-upload-optimizer) | 0.1.0 |

### Required

None

### Optional

- [CloudNativePG](https://cloudnative-pg.io/) operator (1.30+) when using the bundled PostgreSQL cluster (`postgres.enabled: true`, the default). The chart relies on the operator to provision and manage the database. The bundled cluster injects the `vchord` extension through the CNPG ImageVolume extension mechanism, which additionally requires Kubernetes 1.35+ with containerd 2.1+
- [Prometheus Operator](https://prometheus-operator.dev/) (CRDs) when enabling `monitoring.serviceMonitors`
- [metrics-server](https://github.com/kubernetes-sigs/metrics-server) or similar when using Horizontal Pod Autoscaling (`autoscaling`)
- An Ingress controller (e.g. [ingress-nginx](https://kubernetes.github.io/ingress-nginx/)) when exposing the server via `server.ingress`
- [Gateway API](https://gateway-api.sigs.k8s.io/) when exposing the server via `server.httpRoute`
- An external PostgreSQL instance when disabling the bundled cluster (`postgres.enabled: false`)
- Storage supporting `ReadWriteMany` access modes when scaling the workloads horizontally
- GPU device plugins when running the machine-learning workload with hardware acceleration

## Quick start

Prerequisites: The CloudNativePG operator and an Ingress controller.

The chart works out of the box with sensible defaults. The bundled CloudNativePG
cluster generates a random database password itself, which the workloads resolve
from the operator-managed `<fullname>-postgresql-app` Secret, so no credentials
need to be supplied. The only values you typically need to set are a JWT secret
and the ingress for external access:

```yaml
jwtSecret:
  value: "<generate-a-long-random-string>"

server:
  ingress:
    enabled: true
    hosts:
      - host: immich.example.com
        paths:
          - path: /
            pathType: Prefix
```

## Hardware acceleration

Both the machine-learning workload (smart search, face recognition) and the
server/microservices workloads (video transcoding is executed by the
microservices worker) can be hardware accelerated. Each manufacturer uses
a dedicated image tag suffix for machine learning and a matching backend for
transcoding, as summarized below:

| Manufacturer | ML image suffix | ML backend | Transcoding backend |
|--------------|-----------------|------------|---------------------|
| NVIDIA       | `-cuda`         | CUDA       | `nvenc`             |
| AMD          | `-rocm`         | ROCm       | `vaapi`             |
| Intel        | `-openvino`     | OpenVINO   | `qsv` (or `vaapi`)  |
| Rockchip     | `-rknn`         | RKNN       | `rkmpp`             |
| ARM Mali     | `-armnn`        | ARM NN     | `vaapi`             |

### Machine learning per manufacturer

Single out the accelerator, request its device resource, pin the pods to GPU
nodes and tolerate node taints.

> The device resource names below are vendor-specific examples. `nvidia.com/gpu`
> is the standard NVIDIA resource; `amd.com/gpu`, `gpu.intel.com/i915`,
> `rockchip.com/rknpu` and `mali.com/gpu` are only available if the matching
> device plugin/operator is installed in your cluster. If no plugin advertises a
> resource, omit `resources` entirely — selecting a node via `nodeSelector` and
> `tolerations` is then sufficient:

```yaml
# NVIDIA
machineLearning:
  image:
    tagSuffix: "-cuda" # requires compute capability >= 5.2
  resources:
    requests:
      nvidia.com/gpu: "1"
    limits:
      nvidia.com/gpu: "1"
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: "nvidia.com/gpu"
      operator: "Exists"
```

```yaml
# AMD (ROCm)
machineLearning:
  image:
    tagSuffix: "-rocm" # requires an AMDGPU driver and ~35GiB free disk space
  resources:
    requests:
      amd.com/gpu: "1"
    limits:
      amd.com/gpu: "1"
  nodeSelector:
    feature.gpu.availability: "amd-roc"
  tolerations:
    - key: "amd.com/gpu"
      operator: "Exists"
```

```yaml
# Intel (OpenVINO)
machineLearning:
  image:
    tagSuffix: "-openvino" # for Iris Xe, Arc and iGPUs
  resources:
    requests:
      gpu.intel.com/i915: "1"
    limits:
      gpu.intel.com/i915: "1"
  nodeSelector:
    hardware-type: "intel"
  tolerations:
    - key: "intel-gpu"
      operator: "Exists"
```

```yaml
# Rockchip (RKNN)
machineLearning:
  image:
    tagSuffix: "-rknn" # RK3566, RK3568, RK3576 or RK3588 (RKNPU driver >= 0.9.8)
  resources:
    requests:
      rockchip.com/rknpu: "1"
    limits:
      rockchip.com/rknpu: "1"
  extraEnv:
    MACHINE_LEARNING_RKNN_THREADS: "3"
```

```yaml
# ARM Mali (ARM NN)
machineLearning:
  image:
    tagSuffix: "-armnn" # /dev/mali0 required on the host
  resources:
    requests:
      mali.com/gpu: "1"
    limits:
      mali.com/gpu: "1"
  extraEnv:
    MACHINE_LEARNING_ANN_FP16_TURBO: "true"
```

For multiple GPUs, pin device IDs and spawn a worker per device via
`MACHINE_LEARNING_DEVICE_IDS` and `MACHINE_LEARNING_WORKERS`:

```yaml
machineLearning:
  image:
    tagSuffix: "-cuda"
  extraEnv:
    MACHINE_LEARNING_DEVICE_IDS: "0,1"
    MACHINE_LEARNING_WORKERS: "2"
```

### Transcoding per manufacturer

Enable hardware transcoding by setting `server.transcodingDevice` (defaults to
`null`, i.e. no hardware transcoding). The value maps to
`IMMICH_TRANSCODING_HW_DEVICE` and is injected via the shared ConfigMap into
both the server and the microservices workload — the latter actually executes
the transcoding jobs, so both containers see the same configuration.

Note that actual hardware access usually
requires exposing host devices (e.g. `/dev/dri`, `/dev/mali0`) to the pod. The
chart does not provide dedicated device-mount values yet, so use a custom
device plugin / vendor driver where available, or extend the chart:

```yaml
# NVIDIA (NVENC)
server:
  transcodingDevice: "nvenc"
```

```yaml
# AMD (VAAPI)
server:
  transcodingDevice: "vaapi"
```

```yaml
# Intel (Quick Sync)
server:
  transcodingDevice: "qsv"
```

```yaml
# Rockchip (RKMPP)
server:
  transcodingDevice: "rkmpp"
```

For prerequisites, vendor-specific setup (e.g. `/dev/dri` access, NVIDIA
Container Toolkit, libmali firmware) and supported codecs, see the
[Immich hardware transcoding docs](https://immich.app/docs/features/hardware-transcoding).

## Upload optimizer

[Immich Upload Optimizer](https://github.com/miguelangel-nubla/immich-upload-optimizer)
is a smart upload proxy that losslessly recompresses images and transcodes videos
(optionally hardware accelerated) before they reach Immich. Enable the bundled
sub-chart with:

```yaml
upload-optimizer:
  enabled: true
```

`upstream` defaults to the bundled server Service, computed from `.Release.Name`
(matching this chart's own default naming). If you set the top-level `nameOverride`
or `fullnameOverride`, override `upload-optimizer.upstream` to match the server
Service name.

Enabling `upload-optimizer` does **not** change `server.ingress`/`server.httpRoute`.
Point clients at the proxy instead of the server directly by configuring the
sub-chart's own `upload-optimizer.ingress`/`upload-optimizer.httpRoute` (disabled by
default, same as `server.ingress`/`server.httpRoute`):

```yaml
upload-optimizer:
  enabled: true
  ingress:
    enabled: true
    hosts:
      - host: immich.example.com
        paths:
          - path: /
            pathType: Prefix
```

See the [immich-upload-optimizer chart](https://github.com/RocketPadPlatforms/helm-charts/tree/main/charts/immich-upload-optimizer)
for the full set of values (`config.tasks`, `resources`, hardware acceleration, ...).

## Configuration file

Immich features that are not exposed as dedicated values (e.g. `oauth`, `ffmpeg`,
`job` concurrency, `notifications.smtp`, `machineLearning` tuning, `theme`,
`trash`, ...) can be provided through the [Immich config file](https://docs.immich.app/install/config-file).
Configure the base settings in `config.content` as a YAML map. The base config is
stored in a plaintext ConfigMap, so any sensitive values must NOT be hardcoded
there - write them as `${UPPER_SNAKE_CASE}` placeholders and provide the matching
values under `config.env`:

```yaml
config:
  content:
    oauth:
      enabled: true
      clientId: "<client-id>"
      clientSecret: ${OAUTH_CLIENT_SECRET}      # placeholder, not the value
      issuerUrl: "https://idp.example.com"
    notifications:
      smtp:
        enabled: true
        from: "immich@example.com"
        transport:
          host: "smtp.example.com"
          password: ${SMTP_PASSWORD}            # placeholder, not the value
  env:
    OAUTH_CLIENT_SECRET:
      value: "<client-secret>"                  # plain value
    SMTP_PASSWORD:
      secretKeyRef:                             # existing Kubernetes Secret
        name: smtp-secret
        key: password
    THEME_CSS:
      configMapRef:                             # existing ConfigMap
        name: theme-cm
        key: brand
```

At pod start an init step replaces every `${TOKEN}` placeholder with the value of
the matching environment variable set on the init container
(`config.env` provides those variables) and writes the final file to an ephemeral
in-memory volume that the server reads via `IMMICH_CONFIG_FILE` at the fixed path
`/config/immich.yaml`. The ConfigMap therefore never contains secrets.
Placeholders must occupy an entire YAML scalar (e.g. `clientSecret: ${OAUTH_CLIENT_SECRET}`);
the value is YAML-quoted on substitution. A `${TOKEN}` with no matching
`config.env` entry (i.e. no matching environment variable) is left unresolved.

> Prefer `secretKeyRef`/`configMapRef` for real secrets. A plain `value` ends up
> in your chart values / GitOps repository and is only recommended for testing.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| config.content | object | `{}` | Base config file content as a YAML map (mirrors the default Immich config, see the [Immich docs](https://docs.immich.app/install/config-file)). Sensitive values must NOT be hardcoded here; use `${UPPER_SNAKE_CASE}` placeholders and provide the matching values under `config.env`. The file is rendered to the fixed container path `/config/immich.yaml`. Example: ``` content:   oauth:     enabled: true     clientId: "<id>"     clientSecret: ${OAUTH_CLIENT_SECRET}     issuerUrl: "https://..."   notifications:     smtp:       enabled: true       from: "immich@example.com"       transport:         host: "smtp.example.com"         password: ${SMTP_PASSWORD}   trash:     enabled: true     days: 30 ``` |
| config.env | object | `{}` | Values injected into the config file at runtime. Each placeholder `${TOKEN}` in `content` is matched to the entry with the same `TOKEN` key, so the map keys are the placeholder names. Each entry provides its value via either a plain `value` (simplest, fine for testing), an existing `secretKeyRef` or a `configMapRef`. > Do not use `value` for production secrets: it is stored in plaintext in the > chart values / GitOps repository. Prefer `secretKeyRef` (or `configMapRef`) > so the value never lands in the chart's rendered manifests. Example: ``` env:   OAUTH_CLIENT_SECRET:     value: "<client-secret>"   SMTP_PASSWORD:     secretKeyRef:       name: smtp-secret       key: password   THEME_CSS:     configMapRef:       name: theme-cm       key: brand ``` |
| extraManifests | list | `[]` | Extra Kubernetes manifests to deploy alongside the chart. Each entry is rendered with the Helm template engine, so it can reference chart values such as `.Release.Namespace`. Only trusted manifests should be used here. |
| fullnameOverride | string | `""` | Override the full chart name |
| image | object | `{"pullPolicy":"IfNotPresent","repository":"ghcr.io/immich-app/immich-server","tag":""}` | Container image configuration shared by the server and microservices workloads. |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.repository | string | `"ghcr.io/immich-app/immich-server"` | Image repository |
| image.tag | string | `""` | Image tag. Overrides the chart appVersion when set |
| imagePullSecrets | list | `[]` | Secrets for pulling images from a private registry. See [Kubernetes docs](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) |
| jwtSecret | object | `{"secretKeyRef":{"key":"","name":""},"value":""}` | JWT secret used to sign session tokens. Accepts either an inline `value` (stored in a chart-managed Secret named `<fullname>-jwt-secret`) or a `secretKeyRef` referencing an existing Secret. Strongly recommended: when unset, Immich falls back to a temporary secret and existing sessions are invalidated whenever the workload restarts. |
| jwtSecret.secretKeyRef | object | `{"key":"","name":""}` | Reference to an existing Secret containing the secret |
| jwtSecret.secretKeyRef.key | string | `""` | Key within the secret |
| jwtSecret.secretKeyRef.name | string | `""` | Name of the secret |
| jwtSecret.value | string | `""` | Inline secret value. Stored in a chart-managed Secret when set |
| logLevel | string | `"log"` | Immich log level. One of `verbose`, `debug`, `log`, `warn`, `error` |
| machineLearning.affinity | object | `{}` | Affinity rules for machine-learning pod scheduling |
| machineLearning.autoscaling | object | `{"behavior":{},"enabled":false,"maxReplicas":5,"minReplicas":1,"targetCPUUtilizationPercentage":80,"targetMemoryUtilizationPercentage":80}` | Horizontal Pod Autoscaler for the machine-learning workload. Every scaled-up replica mounts the same model cache volume (models are downloaded once and reused). Enable autoscaling only when `persistence.modelCache` is backed by storage that supports multi-pod access (`ReadWriteMany`), otherwise replicas cannot be scheduled on other nodes. See [Immich docs](https://docs.immich.app/guides/scaling-immich) |
| machineLearning.autoscaling.behavior | object | `{}` | Scale-up/down behavior. See [Kubernetes docs](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#configurable-scaling-behavior) |
| machineLearning.autoscaling.enabled | bool | `false` | Enable autoscaling of the machine-learning deployment |
| machineLearning.autoscaling.maxReplicas | int | `5` | Upper limit for the number of machine-learning replicas |
| machineLearning.autoscaling.minReplicas | int | `1` | Lower limit for the number of machine-learning replicas |
| machineLearning.autoscaling.targetCPUUtilizationPercentage | int | `80` | Target CPU utilization percentage to scale on |
| machineLearning.autoscaling.targetMemoryUtilizationPercentage | int | `80` | Target memory utilization percentage to scale on. Models are loaded into memory, so scaling on memory is usually more reactive than on CPU |
| machineLearning.enabled | bool | `true` | Enable the machine-learning workload |
| machineLearning.extraEnv | object | `{}` | Additional environment variables for the machine-learning container. Machine learning device overrides like `MACHINE_LEARNING_DEVICES` belong here. |
| machineLearning.extraEnvFrom | object | `{}` | Additional environment variables sourced from ConfigMaps or Secrets for the machine-learning container. Mapping of variable names to Kubernetes `valueFrom` objects, e.g. `MY_VAR: {secretKeyRef: {name: my-secret, key: my-key}}` |
| machineLearning.image.repository | string | `"ghcr.io/immich-app/immich-machine-learning"` | Image repository |
| machineLearning.image.tag | string | `""` | Image tag. Defaults to the chart `appVersion` |
| machineLearning.image.tagSuffix | string | `""` | Hardware-acceleration tag suffix appended to the image tag, e.g. `-cuda`, `-rocm`, `-openvino`, `-armnn` or `-rknn` |
| machineLearning.livenessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/ping","port":"http"},"initialDelaySeconds":30,"periodSeconds":10,"timeoutSeconds":5}` | Liveness probe configuration for the machine-learning container. |
| machineLearning.nodeSelector | object | `{}` | Node selector for machine-learning pod scheduling |
| machineLearning.podAnnotations | object | `{}` | Extra annotations to add to the machine-learning pods |
| machineLearning.podLabels | object | `{}` | Extra labels to add to the machine-learning pods |
| machineLearning.podSecurityContext | object | `{"fsGroup":1000}` | Pod-level security context for the machine-learning pods |
| machineLearning.readinessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/ping","port":"http"},"initialDelaySeconds":10,"periodSeconds":10,"timeoutSeconds":5}` | Readiness probe configuration for the machine-learning container. |
| machineLearning.replicaCount | int | `1` | Number of machine-learning replicas |
| machineLearning.resources.limits.memory | string | `"3Gi"` |  |
| machineLearning.resources.requests.cpu | string | `"250m"` |  |
| machineLearning.resources.requests.memory | string | `"1Gi"` |  |
| machineLearning.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | Container-level security context for the machine-learning container. |
| machineLearning.service.port | int | `3003` | Service port |
| machineLearning.startupProbe | object | `{"failureThreshold":30,"httpGet":{"path":"/ping","port":"http"},"initialDelaySeconds":5,"periodSeconds":10,"timeoutSeconds":5}` | Startup probe configuration for the machine-learning container. |
| machineLearning.tolerations | list | `[]` | Tolerations for machine-learning pod scheduling |
| microservices.affinity | object | `{}` | Affinity rules for microservices pod scheduling |
| microservices.autoscaling | object | `{"behavior":{},"enabled":false,"maxReplicas":5,"minReplicas":1,"targetCPUUtilizationPercentage":80,"targetMemoryUtilizationPercentage":""}` | Horizontal Pod Autoscaler for the microservices workload. Every scaled-up replica must be connected to the same Postgres and Redis instances and mount the same media volume, so make sure `persistence.media` is backed by storage that supports multi-pod access (`ReadWriteMany`). See [Immich docs](https://docs.immich.app/guides/scaling-immich) |
| microservices.autoscaling.behavior | object | `{}` | Scale-up/down behavior. See [Kubernetes docs](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#configurable-scaling-behavior) |
| microservices.autoscaling.enabled | bool | `false` | Enable autoscaling of the microservices deployment |
| microservices.autoscaling.maxReplicas | int | `5` | Upper limit for the number of microservices replicas |
| microservices.autoscaling.minReplicas | int | `1` | Lower limit for the number of microservices replicas |
| microservices.autoscaling.targetCPUUtilizationPercentage | int | `80` | Target CPU utilization percentage to scale on |
| microservices.autoscaling.targetMemoryUtilizationPercentage | string | `""` | Target memory utilization percentage to scale on. Disabled when empty |
| microservices.extraEnv | object | `{}` | Additional environment variables for the microservices container |
| microservices.extraEnvFrom | object | `{}` | Additional environment variables sourced from ConfigMaps or Secrets for the microservices container. Mapping of variable names to Kubernetes `valueFrom` objects, e.g. `MY_VAR: {secretKeyRef: {name: my-secret, key: my-key}}` |
| microservices.image.repository | string | `""` | Image repository. Defaults to the global `image.repository` |
| microservices.image.tag | string | `""` | Image tag. Defaults to the global `image.tag` or the chart `appVersion` |
| microservices.livenessProbe | object | `{}` | Liveness probe configuration for the microservices container. |
| microservices.nodeSelector | object | `{}` | Node selector for microservices pod scheduling |
| microservices.podAnnotations | object | `{}` | Extra annotations to add to the microservices pods |
| microservices.podLabels | object | `{}` | Extra labels to add to the microservices pods |
| microservices.podSecurityContext | object | `{"fsGroup":1000}` | Pod-level security context for the microservices pods |
| microservices.readinessProbe | object | `{}` | Readiness probe configuration for the microservices container. |
| microservices.replicaCount | int | `1` | Number of microservices replicas |
| microservices.resources.limits.memory | string | `"2Gi"` |  |
| microservices.resources.requests.cpu | string | `"200m"` |  |
| microservices.resources.requests.memory | string | `"512Mi"` |  |
| microservices.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | Container-level security context for the microservices container. |
| microservices.service.annotations | object | `{}` | Service annotations |
| microservices.service.enabled | bool | `false` | Enable the microservices Service. Only required for scraping its metrics. The Service only exposes a metrics port. |
| microservices.startupProbe | object | `{}` | Startup probe configuration for the microservices container. |
| microservices.tolerations | list | `[]` | Tolerations for microservices pod scheduling |
| microservices.topologySpreadConstraints | list | `[]` | Topology spread constraints for the microservices pods. See [Kubernetes docs](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/) |
| monitoring.annotations | object | `{}` | Annotations to add to the ServiceMonitors |
| monitoring.apiMetricsPort | int | `8081` | Port the server exposes API metrics on. Also sets `IMMICH_API_METRICS_PORT` |
| monitoring.enabled | bool | `false` | Enable metrics scraping. Sets `IMMICH_TELEMETRY_INCLUDE=all` on the workloads |
| monitoring.honorLabels | bool | `true` | HonorLabels for the ServiceMonitors. Keeps exported labels of the workload over server-generated names |
| monitoring.interval | string | `"30s"` | Scrape interval for the ServiceMonitors |
| monitoring.labels | object | `{}` | Extra labels to add to the ServiceMonitors |
| monitoring.microservicesMetricsPort | int | `8082` | Port the microservices workload exposes metrics on. Also sets `IMMICH_MICROSERVICES_METRICS_PORT` |
| monitoring.namespaceSelector | object | `{}` | NamespaceSelector for the ServiceMonitors. Empty selects the namespace the ServiceMonitors are deployed in. |
| monitoring.scrapeTimeout | string | `"10s"` | Scrape timeout for the ServiceMonitors |
| monitoring.serviceMonitors | object | `{"enabled":false}` | Create ServiceMonitors for the server and microservices services. Enable this only when a Prometheus Operator (CRDs) is installed in the cluster |
| nameOverride | string | `""` | Override the chart name |
| persistence.media | object | `{"accessModes":["ReadWriteMany"],"annotations":{},"enabled":true,"existingClaim":"","size":"100Gi","storageClass":""}` | Shared library media volume mounted by the server and microservices workloads at the fixed container path `/data` (the Immich `IMMICH_MEDIA_LOCATION` default). The volume must support sharing across pods (`ReadWriteMany`). |
| persistence.media.accessModes | list | `["ReadWriteMany"]` | Access modes for the media volume |
| persistence.media.annotations | object | `{}` | Annotations for the media volume PVC |
| persistence.media.enabled | bool | `true` | Enable dynamic provisioning of the media volume. Set to `false` when using an `existingClaim` |
| persistence.media.existingClaim | string | `""` | Name of an existing PVC to use instead of creating a new one |
| persistence.media.size | string | `"100Gi"` | Size of the media volume |
| persistence.media.storageClass | string | `""` | Storage class for the media volume. Use `"-"` to disable dynamic provisioning |
| persistence.modelCache | object | `{"accessModes":["ReadWriteOnce"],"annotations":{},"enabled":true,"existingClaim":"","size":"5Gi","storageClass":""}` | Machine learning model cache volume, mounted at `/cache` inside the container (`MACHINE_LEARNING_CACHE_FOLDER` default). Downloaded models are shared across all machine-learning replicas. Use `ReadWriteMany` access modes when scaling the machine-learning workload horizontally (`autoscaling`) |
| persistence.modelCache.accessModes | list | `["ReadWriteOnce"]` | Access modes for the model cache volume |
| persistence.modelCache.annotations | object | `{}` | Annotations for the model cache volume PVC |
| persistence.modelCache.enabled | bool | `true` | Enable dynamic provisioning of the model cache volume. Set to `false` when using an `existingClaim` |
| persistence.modelCache.existingClaim | string | `""` | Name of an existing PVC to use instead of creating a new one |
| persistence.modelCache.size | string | `"5Gi"` | Size of the model cache volume |
| persistence.modelCache.storageClass | string | `""` | Storage class for the model cache volume |
| postgres.affinity | object | `{}` | Affinity rules for PostgreSQL instance scheduling |
| postgres.annotations | object | `{}` | Annotations to add to the CNPG Cluster |
| postgres.backup | object | `{"barmanObjectStore":{},"enabled":false,"retentionPolicy":"30d"}` | CNPG backup configuration. |
| postgres.backup.barmanObjectStore | object | `{}` | Barman object store configuration. See [CNPG docs](https://cloudnative-pg.io/documentation/current/backup/) |
| postgres.backup.enabled | bool | `false` | Enable backups. Requires a Barman object store for `barmanObjectStore` |
| postgres.backup.retentionPolicy | string | `"30d"` | Backup retention policy (e.g. `30d`) |
| postgres.bootstrapSecretOverride | string | `""` | Name of an existing Secret containing `username` and `password` keys used to bootstrap the CNPG cluster. Defaults to the chart-managed or referenced db password |
| postgres.database | string | `"immich"` | Name of the Immich database |
| postgres.enabled | bool | `true` | Enable CNPG Cluster creation. Set to `false` to use an external database |
| postgres.extensions | list | `[{"dynamic_library_path":["/usr/lib/postgresql/18/lib"],"extension_control_path":["/usr/share/postgresql/18/"],"image":{"reference":"ghcr.io/tensorchord/vchord-scratch:pg18-v1.1.1"},"name":"vchord"}]` | PostgreSQL extensions injected via the CNPG ImageVolume extension mechanism. See [CNPG docs](https://cloudnative-pg.io/documentation/current/imagevolume_extensions/). Set to `[]` to disable ImageVolume extensions (e.g. when using a prebuilt image) |
| postgres.extensions[0] | object | `{"dynamic_library_path":["/usr/lib/postgresql/18/lib"],"extension_control_path":["/usr/share/postgresql/18/"],"image":{"reference":"ghcr.io/tensorchord/vchord-scratch:pg18-v1.1.1"},"name":"vchord"}` | Extension name |
| postgres.extensions[0].dynamic_library_path | list | `["/usr/lib/postgresql/18/lib"]` | Directories to search for the extension libraries |
| postgres.extensions[0].extension_control_path | list | `["/usr/share/postgresql/18/"]` | Directories to search for the extension control files |
| postgres.extensions[0].image.reference | string | `"ghcr.io/tensorchord/vchord-scratch:pg18-v1.1.1"` | Image reference containing the extension files renovate: image=ghcr.io/tensorchord/vchord-scratch |
| postgres.host | string | `""` | Host of an external database. Only used when `enabled` is `false` |
| postgres.image.repository | string | `""` | Image repository for the CNPG cluster instances. Empty by default so the CloudNativePG operator applies its own default image. `imageName` is only rendered in the Cluster CR when this is set. Use a standard image with the `-trixie` tag (PostgreSQL 18) for `vchord` support via ImageVolume extensions |
| postgres.image.tag | string | `""` | Image tag for the CNPG cluster instances. Only rendered together with `repository` |
| postgres.instances | int | `1` | Number of PostgreSQL instances in the CNPG cluster |
| postgres.monitoring.enablePodMonitor | bool | `false` | Enable CNPG PodMonitor for PostgreSQL |
| postgres.nodeSelector | object | `{}` | Node selector for PostgreSQL instance scheduling |
| postgres.password.secretKeyRef | object | `{"key":"","name":""}` | Reference to an existing Secret containing the password |
| postgres.password.secretKeyRef.key | string | `""` | Key within the secret |
| postgres.password.secretKeyRef.name | string | `""` | Name of the secret |
| postgres.password.value | string | `""` | Inline password value. Stored in a chart-managed Secret when set |
| postgres.podSecurityContext | object | `{}` | Pod-level security context for the PostgreSQL instances. Empty by default so CloudNativePG applies its hardened defaults (the official images run the `postgres` user as UID/GID `26`) |
| postgres.port | int | `5432` | Port of an external database. Only used when `enabled` is `false` |
| postgres.postInitApplicationSQL | list | `["CREATE EXTENSION IF NOT EXISTS vector","CREATE EXTENSION IF NOT EXISTS vchord","CREATE EXTENSION IF NOT EXISTS cube","CREATE EXTENSION IF NOT EXISTS earthdistance"]` | List of SQL statements executed after the database bootstrap. Creates the required extensions inside the Immich database |
| postgres.resources | object | `{}` | Resource requests and limits for the PostgreSQL instances |
| postgres.securityContext | object | `{}` | Container-level security context for the PostgreSQL instance container. Merged with CloudNativePG's hardened defaults; no overrides by default |
| postgres.sharedPreloadLibraries | list | `["vchord.so"]` | Shared preload libraries loaded at PostgreSQL server start. `vchord` must be preloaded for the extension to work |
| postgres.storage.size | string | `"100Gi"` | Size of the PostgreSQL PVC |
| postgres.storage.storageClass | string | `""` | Storage class for the PostgreSQL PVCs |
| postgres.tolerations | list | `[]` | Tolerations for PostgreSQL instance scheduling |
| postgres.user | string | `"immich"` | Name of the role that owns the Immich database (also used as `DB_USERNAME`) |
| redis | object | `{"dbindex":0,"host":"","password":{"secretKeyRef":{"key":"","name":""},"value":""},"port":6379}` | Redis/Valkey connection configuration used by the server and microservices workloads. |
| redis.dbindex | int | `0` | Redis/Valkey database index |
| redis.host | string | `""` | Redis/Valkey host. Uses the bundled valkey subchart when empty |
| redis.password | object | `{"secretKeyRef":{"key":"","name":""},"value":""}` | Redis/Valkey password injected into the server and microservices workloads. Only needed when authentication is enabled on Valkey. Accepts either an inline `value` (stored in a chart-managed Secret named `<fullname>-redis-password`) or a `secretKeyRef` referencing an existing Secret |
| redis.password.secretKeyRef | object | `{"key":"","name":""}` | Reference to an existing Secret containing the password |
| redis.password.secretKeyRef.key | string | `""` | Key within the secret |
| redis.password.secretKeyRef.name | string | `""` | Name of the secret |
| redis.password.value | string | `""` | Inline password value. Stored in a chart-managed Secret when set |
| redis.port | int | `6379` | Redis/Valkey port |
| server.affinity | object | `{}` | Affinity rules for server pod scheduling |
| server.extraEnv | object | `{}` | Additional environment variables for the server container |
| server.extraEnvFrom | object | `{}` | Additional environment variables sourced from ConfigMaps or Secrets for the server container. Mapping of variable names to Kubernetes `valueFrom` objects, e.g. `MY_VAR: {secretKeyRef: {name: my-secret, key: my-key}}` |
| server.httpRoute | object | `{"annotations":{},"enabled":false,"hostnames":["chart-example.local"],"parentRefs":[{"name":"gateway","sectionName":"http"}],"rules":[{"matches":[{"path":{"type":"PathPrefix","value":"/"}}]}]}` | Expose the server via a Gateway API HTTPRoute. |
| server.httpRoute.annotations | object | `{}` | HTTPRoute annotations |
| server.httpRoute.enabled | bool | `false` | Enable HTTPRoute |
| server.httpRoute.hostnames | list | `["chart-example.local"]` | Hostnames matching the HTTP host header |
| server.httpRoute.parentRefs | list | `[{"name":"gateway","sectionName":"http"}]` | Gateways this route is attached to |
| server.httpRoute.rules | list | `[{"matches":[{"path":{"type":"PathPrefix","value":"/"}}]}]` | List of routing rules applied to matched requests |
| server.image.repository | string | `""` | Image repository. Defaults to the global `image.repository` |
| server.image.tag | string | `""` | Image tag. Defaults to the global `image.tag` or the chart `appVersion` |
| server.ingress | object | `{"annotations":{},"className":"","enabled":false,"hosts":[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}],"tls":[]}` | Ingress configuration for the server. |
| server.ingress.annotations | object | `{}` | Ingress annotations |
| server.ingress.className | string | `""` | Ingress class name |
| server.ingress.enabled | bool | `false` | Enable ingress |
| server.ingress.hosts | list | `[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | Ingress hosts configuration |
| server.ingress.tls | list | `[]` | Ingress TLS configuration |
| server.livenessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/api/server/ping","port":"http"},"initialDelaySeconds":30,"periodSeconds":10,"timeoutSeconds":5}` | Liveness probe configuration for the server container. |
| server.nodeSelector | object | `{}` | Node selector for server pod scheduling |
| server.podAnnotations | object | `{}` | Extra annotations to add to the server pods |
| server.podLabels | object | `{}` | Extra labels to add to the server pods |
| server.podSecurityContext | object | `{"fsGroup":1000}` | Pod-level security context for the server pods |
| server.readinessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/api/server/ping","port":"http"},"initialDelaySeconds":10,"periodSeconds":10,"timeoutSeconds":5}` | Readiness probe configuration for the server container. |
| server.replicaCount | int | `1` | Number of server replicas |
| server.resources | object | `{"limits":{"memory":"2Gi"},"requests":{"cpu":"100m","memory":"512Mi"}}` | Resource requests and limits for the server container. |
| server.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | Container-level security context for the server container. |
| server.service | object | `{"annotations":{},"port":2283,"type":"ClusterIP"}` | Kubernetes Service configuration for the server. |
| server.service.annotations | object | `{}` | Service annotations |
| server.service.port | int | `2283` | Service port |
| server.service.type | string | `"ClusterIP"` | Service type. See [service types](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| server.startupProbe | object | `{"failureThreshold":30,"httpGet":{"path":"/api/server/ping","port":"http"},"initialDelaySeconds":5,"periodSeconds":10,"timeoutSeconds":5}` | Startup probe configuration for the server container. |
| server.tolerations | list | `[]` | Tolerations for server pod scheduling |
| server.transcodingDevice | string | `nil` | Hardware device used for transcoding. Maps to `IMMICH_TRANSCODING_HW_DEVICE`, which is injected via the shared ConfigMap into both the server and microservices workloads (the microservices worker executes the actual transcoding jobs). Set to `null` (default) to disable hardware transcoding. Supported values: `nvenc` (NVIDIA), `qsv` (Intel), `vaapi` (AMD/NVIDIA/Intel), `rkmpp` (Rockchip). If the same variable is also set in `extraEnv`, the `extraEnv` value takes precedence (container `env` overrides `envFrom`). |
| serviceAccount | object | `{"annotations":{},"automount":false,"create":true,"name":""}` | Service account configuration. See [Kubernetes docs](https://kubernetes.io/docs/concepts/security/service-accounts/) |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.automount | bool | `false` | Automatically mount a ServiceAccount's API credentials |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | Name of the service account to use. If not set and `create` is `true`, a name is generated using the fullname template |
| timezone | string | `"UTC"` | Timezone used by all Immich workers. See [tz database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) |
| upload-optimizer.enabled | bool | `false` | Deploy the bundled immich-upload-optimizer sub-chart in front of the server |
| upload-optimizer.upstream | string | `"http://{{ if contains \"immich\" .Release.Name }}{{ .Release.Name }}{{ else }}{{ printf \"%s-immich\" .Release.Name }}{{ end }}:2283"` | Upstream Immich server URL the proxy forwards optimized uploads to. Defaults to the bundled server Service, assuming the top-level `nameOverride`/`fullnameOverride` are left unset (the sub-chart cannot see those values directly, only its own). If you set either of those, override this to match the server Service name. |
| valkey.auth | object | `{"enabled":false}` | Valkey ACL authentication. |
| valkey.auth.enabled | bool | `false` | Enable ACL-based authentication. Requires `aclUsers` and the password in `redis.password` |
| valkey.enabled | bool | `true` | Deploy the bundled Valkey sub-chart (official Valkey Helm Chart) |
| valkey.replica | object | `{"enabled":false}` | Number of Valkey replicas (master-replica mode). Requires `replica.persistence.size` and `auth.aclUsers` when authentication is enabled |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
