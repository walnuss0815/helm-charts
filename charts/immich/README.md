# immich

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v3.3.1](https://img.shields.io/badge/AppVersion-v3.3.1-informational?style=flat-square)

A Helm chart for Immich, the high performance self-hosted photo and video management solution.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| walnuss0815 | <walnuss0815@gmail.com> | <https://github.com/walnuss0815> |

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://valkey.io/valkey-helm/ | valkey | 0.12.0 |
| https://walnuss0815.github.io/helm-charts | upload-optimizer(immich-upload-optimizer) | 0.1.1 |

### Required

None

### Optional

- [CloudNativePG](https://cloudnative-pg.io/) operator (1.30+) when using the bundled PostgreSQL cluster (`postgres.enabled: true`, the default). The chart relies on the operator to provision and manage the database. The bundled cluster injects the `vchord` extension through the CNPG ImageVolume extension mechanism, which additionally requires Kubernetes 1.35+ with containerd 2.1+
- [Barman Cloud Plugin](https://cloudnative-pg.io/plugin-barman-cloud/) when using `postgres.backup.method: plugin`, or CSI volume snapshots for `method: volumeSnapshot`
- [Prometheus Operator](https://prometheus-operator.dev/) (CRDs) when enabling `monitoring.serviceMonitors`
- [metrics-server](https://github.com/kubernetes-sigs/metrics-server) or similar when using Horizontal Pod Autoscaling (`autoscaling`)
- An Ingress controller (e.g. [ingress-nginx](https://kubernetes.github.io/ingress-nginx/)) when exposing the server via `server.ingress`
- [Gateway API](https://gateway-api.sigs.k8s.io/) when exposing the server via `server.httpRoute`
- An external PostgreSQL instance when disabling the bundled cluster (`postgres.enabled: false`)
- Storage supporting `ReadWriteMany` access modes for the media volume and, with `persistence.modelCache.type: pvc` (the default), the machine-learning model cache
- GPU device plugins when running the machine-learning workload with hardware acceleration

## Quick start

Prerequisites: The CloudNativePG operator, an Ingress controller and `ReadWriteMany` storage.

The chart works out of the box with sensible defaults. The bundled CloudNativePG
cluster generates a random database password itself, which the workloads resolve
from the operator-managed `<fullname>-postgresql-app` Secret, so no credentials
need to be supplied. The only values you typically need to set are for external
access:

```yaml
server:
  ingress:
    enabled: true
    hosts:
      - host: immich.example.com
        paths:
          - path: /
            pathType: Prefix
```

Most ingress controllers limit the request body size by default, which breaks
video uploads; see [Reverse proxy](#reverse-proxy) for the required settings.

## Reverse proxy

Immich must be served on the root path of a (sub)domain; sub-paths such as
`/immich` are not supported. The proxy in front of the server must allow large
uploads, long requests and WebSockets, and forward the `Host`, `X-Real-IP`,
`X-Forwarded-Proto` and `X-Forwarded-For` headers
([Immich docs](https://docs.immich.app/administration/reverse-proxy)).
Otherwise photos upload but videos fail, or the web UI shows *Server Offline*.

Set `server.trustedProxies` to the addresses of the proxy (e.g. the pod CIDR of
the ingress controller), so Immich uses the forwarded client IP.

Ingress (example annotations for ingress-nginx; other controllers have
equivalents):

```yaml
server:
  trustedProxies:
    - 10.244.0.0/16
  ingress:
    enabled: true
    className: nginx
    annotations:
      nginx.ingress.kubernetes.io/proxy-body-size: "0"
      nginx.ingress.kubernetes.io/proxy-request-buffering: "off"
      nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
      nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
    hosts:
      - host: immich.example.com
        paths:
          - path: /
            pathType: Prefix
    tls:
      - secretName: immich-tls
        hosts:
          - immich.example.com
```

Gateway API (request body limits are implementation-specific, e.g. a
`ClientTrafficPolicy` in Envoy Gateway):

```yaml
server:
  httpRoute:
    enabled: true
    parentRefs:
      - name: gateway
        sectionName: https
    hostnames:
      - immich.example.com
    rules:
      - matches:
          - path:
              type: PathPrefix
              value: /
        timeouts:
          request: 600s
```

If the proxy uses the Let's Encrypt `http-01` challenge, make sure
`/.well-known/immich` is still routed to Immich; the mobile app relies on it.

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

Video transcoding is executed by the microservices worker. Hardware transcoding
needs two things:

1. Device access for the microservices pods, usually through a device plugin
   resource (e.g. the NVIDIA GPU Operator or the Intel GPU plugin). The pod may
   also need the GID of the host `render` group in
   `microservices.podSecurityContext.supplementalGroups`.
2. The acceleration API, selected in the admin UI (*Administration > Settings >
   Video Transcoding Settings > Hardware Acceleration*) or, when the config file
   is used, via `config.content.ffmpeg.accel` (`nvenc`, `qsv`, `vaapi` or
   `rkmpp`).

```yaml
# Intel (Quick Sync) with the Intel GPU device plugin
microservices:
  resources:
    limits:
      gpu.intel.com/i915: "1"
```

```yaml
# NVIDIA (NVENC) with the NVIDIA GPU Operator, configured via the config file
microservices:
  resources:
    limits:
      nvidia.com/gpu: "1"
config:
  content:
    ffmpeg:
      accel: nvenc
      accelDecode: true
```

> Setting `config.content` makes the whole admin settings UI read-only (see
> [Configuration file](#configuration-file)). Prefer the admin UI if you do not
> manage the remaining settings through the config file.

For prerequisites, vendor-specific setup (e.g. `/dev/dri` access, NVIDIA
Container Toolkit, libmali firmware) and supported codecs, see the
[Immich hardware transcoding docs](https://docs.immich.app/features/hardware-transcoding).

## External libraries

[External libraries](https://docs.immich.app/features/libraries) import existing
photo folders without copying them. Mount the folder into both the server and the
microservices workloads at the same path with `extraVolumes`/`extraVolumeMounts`,
then add that path as an import path in the admin UI:

```yaml
server:
  extraVolumes: &photos
    - name: photos
      nfs:
        server: nas.example.com
        path: /volume1/photos
  extraVolumeMounts: &photosMount
    - name: photos
      mountPath: /mnt/photos
      readOnly: true
microservices:
  extraVolumes: *photos
  extraVolumeMounts: *photosMount
```

## Scaling machine learning

The machine-learning workload is stateless: the server reaches all replicas
through a single Service, which spreads the requests. It can therefore run
several replicas on different nodes, scaled manually (`replicaCount`) or by
the HorizontalPodAutoscaler (`autoscaling`). The model cache must not be bound
to a node, so `persistence.modelCache.type` offers two options:

| `type` | Volume | Trade-off |
|--------|--------|-----------|
| `pvc` (default) | `ReadWriteMany` PVC shared by all replicas | Models are downloaded once; requires RWX storage (e.g. NFS, CephFS) |
| `emptyDir` | Per pod, up to `sizeLimit` | Works on any cluster; each new pod downloads the models again |

```yaml
machineLearning:
  autoscaling:
    enabled: true
    minReplicas: 1
    maxReplicas: 4
  podDisruptionBudget:
    enabled: true
  topologySpreadConstraints:
    - maxSkew: 1
      topologyKey: kubernetes.io/hostname
      whenUnsatisfiable: ScheduleAnyway
      labelSelector:
        matchLabels:
          app.kubernetes.io/component: machine-learning
persistence:
  modelCache:
    type: emptyDir
```

Keep in mind:

- **Job concurrency limits throughput.** Each microservices replica processes
  only as many ML jobs in parallel as configured (defaults: `smartSearch: 2`,
  `faceDetection: 2`, `ocr: 1`), so more ML replicas only help if the job
  concurrency (*Administration > Settings > Job Settings* or
  `config.content.job`) or the number of microservices replicas is raised too.
- **Scale on CPU.** Loaded models stay in memory until
  `MACHINE_LEARNING_MODEL_TTL` (default 300 s) expires, so memory-based scaling
  rarely scales down. The default `behavior` delays scale-down by 10 minutes.
- **Cold starts.** A new replica loads (and with `emptyDir` downloads) models on
  its first request. Preload them via `machineLearning.extraEnv`, e.g.
  `MACHINE_LEARNING_PRELOAD__CLIP__TEXTUAL: ViT-B-32__openai`.
- **GPUs.** CPU utilization does not reflect GPU load. Scale GPU replicas
  manually or with external metrics (e.g. KEDA with DCGM metrics).

See the [Immich environment variables](https://docs.immich.app/install/environment-variables#machine-learning)
for all machine-learning tuning options.

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

See the [immich-upload-optimizer chart](https://github.com/walnuss0815/helm-charts/tree/main/charts/immich-upload-optimizer)
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

> Setting `config.content` sets `IMMICH_CONFIG_FILE`, which makes the admin
> settings UI read-only: every setting is then managed through `config.content`
> (unset keys use the Immich defaults). Leave `config.content` empty (the default)
> to configure Immich through the web UI instead.

At pod start an init container in both the server and the microservices pods
replaces every `${TOKEN}` placeholder with the value of the matching environment
variable set on the init container (`config.env` provides those variables) and
writes the final file to an in-memory volume (`emptyDir` with `medium: Memory`)
that Immich reads via `IMMICH_CONFIG_FILE` at the fixed path
`/config/immich.yaml`. The ConfigMap therefore never contains secrets.
Both workloads need the file: the microservices worker runs the jobs (e.g.
`ffmpeg`, `machineLearning`, `notifications`) that read these settings.
Placeholders must occupy an entire YAML scalar (e.g. `clientSecret: ${OAUTH_CLIENT_SECRET}`);
the value is YAML-quoted on substitution. A `${TOKEN}` with no matching
`config.env` entry (i.e. no matching environment variable) is left unresolved.

> Prefer `secretKeyRef`/`configMapRef` for real secrets. A plain `value` ends up
> in your chart values / GitOps repository and is only recommended for testing.

## Persistence

The media volume (`persistence.media`, mounted at `/data`) holds the original
photos and videos. It is annotated with `helm.sh/resource-policy: keep`
(`persistence.media.keep: true`), so Helm keeps the PVC on `helm uninstall` and
Argo CD treats it like `Delete=false` when the Application is deleted. A
reinstall with the same release name adopts the kept PVC again. Delete it
manually once it is no longer needed:

```sh
kubectl delete pvc <fullname>-media
```

The annotation protects the PVC object, not the underlying volume. As a second
layer, provision the media volume from a StorageClass with
`reclaimPolicy: Retain`, so the PersistentVolume and its data survive even if the
PVC is deleted (re-binding it then requires manual steps).

## Database

By default the chart deploys a CloudNativePG `Cluster` (`postgres.enabled: true`).

### PostgreSQL and VectorChord versions

The PostgreSQL major version is declared exactly once, as the leading number of
`postgres.image.tag`. The `vchord` ImageVolume extension image
(`<postgres.vchord.repository>:pg<major>-v<postgres.vchord.version>`) and its
library/control paths are derived from it, so the PostgreSQL image and the
extension always match:

```yaml
postgres:
  image:
    tag: "18.6-standard-trixie"   # PostgreSQL 18 -> vchord-scratch:pg18-v1.1.1
  vchord:
    version: "1.1.1"
```

Both values are tracked by Renovate (`renovate-custom-managers.json`):

- PostgreSQL minor/patch updates are proposed; major updates are disabled,
  because changing the major version makes CloudNativePG perform an offline
  in-place major upgrade. Bump the major version deliberately; `vchord` follows
  automatically.
- `vchord` updates are limited to `< 2.0`, the range Immich supports.

Every update runs through the CI install test, which bootstraps the CNPG
cluster and creates the `vchord` extension, so an incompatible combination
fails before it reaches `main`.

### Superuser

Immich expects superuser privileges in its database
([Immich docs](https://docs.immich.app/administration/postgres-standalone/)):
its built-in daily database dump uses `pg_dumpall`, and after a `vchord`
upgrade it runs `ALTER EXTENSION vchord UPDATE` and reindexes automatically.
The chart therefore grants the `postgres.user` role superuser privileges through
CNPG declarative role management (`postgres.superuser: true`). The role is
dedicated to this cluster.

With `postgres.superuser: false`, Immich's database backups fail and you must
run the following after every `vchord` upgrade:

```sql
ALTER EXTENSION vchord UPDATE;
REINDEX INDEX face_index;
REINDEX INDEX clip_index;
```

### Backups and recovery

Immich creates a daily logical dump of its database in `/data/backups` on the
media volume by default (*Administration > Settings > Database Dump Settings*). It
requires `postgres.superuser: true`. Back up the media volume (at least
`library`, `upload`, `profile` and `backups`) with your storage or backup tooling;
see the [Immich backup docs](https://docs.immich.app/administration/backup-and-restore).

For point-in-time recovery, enable physical CNPG backups. With
`method: plugin` the chart creates a Barman Cloud `ObjectStore`, enables WAL
archiving and schedules base backups with a `ScheduledBackup`. This requires the
[Barman Cloud Plugin](https://cloudnative-pg.io/plugin-barman-cloud/docs/installation/)
next to the CNPG operator:

```yaml
postgres:
  backup:
    enabled: true
    method: plugin
    schedule: "0 0 3 * * *"   # six fields, including seconds
    objectStore:
      retentionPolicy: 30d
      configuration:
        destinationPath: s3://immich-backups/
        endpointURL: https://s3.example.com
        s3Credentials:
          accessKeyId:
            name: immich-s3
            key: ACCESS_KEY_ID
          secretAccessKey:
            name: immich-s3
            key: ACCESS_SECRET_KEY
        wal:
          compression: gzip
```

With `method: volumeSnapshot` the chart schedules CSI volume snapshots instead
(set `postgres.backup.volumeSnapshot.className`). If
`postgres.backup.objectStore.configuration` is set as well, WAL archiving to the
object store is enabled for point-in-time recovery.

To restore, bootstrap a new cluster from the backup. Recovery only applies when
the `Cluster` is created, so delete the existing `Cluster` (and its PVCs) first
or install a new release. Archive the new cluster's WAL to a different
`serverName`, because CloudNativePG refuses to write into a non-empty archive:

```yaml
postgres:
  backup:
    objectStore:
      serverName: immich-postgresql-v2   # new archive folder
  recovery:
    enabled: true
    serverName: immich-postgresql        # folder of the backup to restore
    # recoveryTarget:
    #   targetTime: "2026-01-01 00:00:00+00"
```

Restore the media volume from the same point in time. If they differ, a
database that is older than the media volume is the safer state (see
[backup ordering](https://docs.immich.app/administration/backup-and-restore#backup-ordering)).

### Credentials

Without a password source, CloudNativePG generates a random password in the
`<fullname>-postgresql-app` Secret. To provide your own credentials with the
bundled cluster, reference a Secret with the keys `username` (equal to
`postgres.user`) and `password`; CloudNativePG bootstraps the database from it:

```yaml
postgres:
  password:
    secretKeyRef:
      name: immich-db-credentials
      key: password   # must be "password"
```

## Upgrading

### From 0.1.x

Removed or renamed values fail rendering with a hint instead of being ignored.

- `jwtSecret` and `server.transcodingDevice` were removed; Immich reads neither.
  Configure hardware transcoding via `ffmpeg.accel` (admin UI or
  `config.content`).
- `IMMICH_CONFIG_FILE` is only set when `config.content` is not empty, so the
  admin settings UI is editable again by default.
- `postgres.image.tag` now pins the CNPG image (PostgreSQL 18 by default). If
  your cluster runs another major version, set the tag to that version first;
  otherwise CloudNativePG performs a major upgrade.
- `postgres.extensions`/`postgres.sharedPreloadLibraries` were replaced by
  `postgres.vchord`, `postgres.extraExtensions` and
  `postgres.extraSharedPreloadLibraries`.
- The database role is a superuser by default (`postgres.superuser`).
- `postgres.backup.barmanObjectStore`/`retentionPolicy` were replaced by
  `postgres.backup.objectStore` (Barman Cloud Plugin).
- `persistence.modelCache.enabled`/`accessModes` were replaced by
  `persistence.modelCache.type` (`pvc` with `ReadWriteMany`, or `emptyDir`). The
  model cache PVC is recreated as `<fullname>-machine-learning-cache`; models are
  downloaded once again.

## Values

### Configuration file

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| config.content | object | `{}` | Config file content as a YAML map (same structure as the Immich default config). When set, the file is mounted into the server and microservices workloads at `/config/immich.yaml` and `IMMICH_CONFIG_FILE` is set, which makes the admin settings UI read-only. Write sensitive values as `${UPPER_SNAKE_CASE}` placeholders (an entire YAML scalar, e.g. `clientSecret: ${OAUTH_CLIENT_SECRET}`) and provide them via `config.env` |
| config.env | object | `{}` | Values substituted for the `${TOKEN}` placeholders in `content` at pod start. Map of placeholder name to a value source: `value` (plain text, testing only), `secretKeyRef` or `configMapRef` (each with `name` and `key`). Resolved values are written to an in-memory volume and never stored in a ConfigMap |

### Other

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| extraManifests | list | `[]` | Extra Kubernetes manifests to deploy alongside the chart. Each entry is rendered with the Helm template engine, so it can reference chart values such as `.Release.Namespace`. Only trusted manifests should be used here. |

### Global

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| fullnameOverride | string | `""` | Override the full chart name |
| image | object | `{"pullPolicy":"IfNotPresent","repository":"ghcr.io/immich-app/immich-server","tag":""}` | Container image configuration shared by the server and microservices workloads. |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.repository | string | `"ghcr.io/immich-app/immich-server"` | Image repository |
| image.tag | string | `""` | Image tag. Overrides the chart appVersion when set |
| imagePullSecrets | list | `[]` | Secrets for pulling images from a private registry. See [Kubernetes docs](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) |
| nameOverride | string | `""` | Override the chart name |

### Common

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| logLevel | string | `"log"` | Immich log level. One of `verbose`, `debug`, `log`, `warn`, `error` |
| redis | object | `{"dbindex":0,"host":"","password":{"secretKeyRef":{"key":"","name":""},"value":""},"port":6379,"username":""}` | Redis/Valkey connection configuration used by the server and microservices workloads. |
| redis.dbindex | int | `0` | Redis/Valkey database index |
| redis.host | string | `""` | Redis/Valkey host. Uses the bundled valkey subchart when empty |
| redis.password | object | `{"secretKeyRef":{"key":"","name":""},"value":""}` | Redis/Valkey password injected into the server and microservices workloads. Only needed when authentication is enabled on Valkey. Accepts either an inline `value` (stored in a chart-managed Secret named `<fullname>-redis-password`) or a `secretKeyRef` referencing an existing Secret |
| redis.password.secretKeyRef | object | `{"key":"","name":""}` | Reference to an existing Secret containing the password |
| redis.password.secretKeyRef.key | string | `""` | Key within the secret |
| redis.password.secretKeyRef.name | string | `""` | Name of the secret |
| redis.password.value | string | `""` | Inline password value. Stored in a chart-managed Secret when set |
| redis.port | int | `6379` | Redis/Valkey port |
| redis.username | string | `""` | Redis/Valkey username (`REDIS_USERNAME`). Required for ACL users other than `default` |
| timezone | string | `"UTC"` | Timezone used by all Immich workers. See [tz database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) |

### Machine learning

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| machineLearning.affinity | object | `{}` | Affinity rules for machine-learning pod scheduling |
| machineLearning.autoscaling.behavior | object | `{"scaleDown":{"stabilizationWindowSeconds":600}}` | Scale-up/down behavior. The default delays scale-down by 10 minutes so replicas are not removed between job bursts. See [Kubernetes docs](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#configurable-scaling-behavior) |
| machineLearning.autoscaling.enabled | bool | `false` | Enable the HorizontalPodAutoscaler of the machine-learning workload. Replicas on different nodes require `persistence.modelCache.type: emptyDir` or a `pvc` backed by `ReadWriteMany` storage |
| machineLearning.autoscaling.maxReplicas | int | `5` | Upper limit for the number of machine-learning replicas |
| machineLearning.autoscaling.minReplicas | int | `1` | Lower limit for the number of machine-learning replicas |
| machineLearning.autoscaling.targetCPUUtilizationPercentage | int | `80` | Target CPU utilization percentage to scale on |
| machineLearning.autoscaling.targetMemoryUtilizationPercentage | string | `""` | Target memory utilization percentage to scale on. Disabled when empty. Not recommended: loaded models stay in memory until their TTL expires |
| machineLearning.enabled | bool | `true` | Enable the machine-learning workload |
| machineLearning.extraEnv | object | `{}` | Additional environment variables for the machine-learning container. Machine learning device overrides like `MACHINE_LEARNING_DEVICES` belong here. |
| machineLearning.extraEnvFrom | object | `{}` | Additional environment variables sourced from ConfigMaps or Secrets for the machine-learning container. Mapping of variable names to Kubernetes `valueFrom` objects, e.g. `MY_VAR: {secretKeyRef: {name: my-secret, key: my-key}}` |
| machineLearning.extraVolumeMounts | list | `[]` | Additional volume mounts for the machine-learning container |
| machineLearning.extraVolumes | list | `[]` | Additional volumes for the machine-learning pods, e.g. an external library or host devices |
| machineLearning.image.repository | string | `"ghcr.io/immich-app/immich-machine-learning"` | Image repository |
| machineLearning.image.tag | string | `""` | Image tag. Defaults to the chart `appVersion` |
| machineLearning.image.tagSuffix | string | `""` | Hardware-acceleration tag suffix appended to the image tag, e.g. `-cuda`, `-rocm`, `-openvino`, `-armnn` or `-rknn` |
| machineLearning.livenessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/ping","port":"http"},"initialDelaySeconds":30,"periodSeconds":10,"timeoutSeconds":5}` | Liveness probe configuration for the machine-learning container. |
| machineLearning.nodeSelector | object | `{}` | Node selector for machine-learning pod scheduling |
| machineLearning.podAnnotations | object | `{}` | Extra annotations to add to the machine-learning pods |
| machineLearning.podDisruptionBudget.enabled | bool | `false` | Create a PodDisruptionBudget for the machine-learning pods |
| machineLearning.podDisruptionBudget.maxUnavailable | int | `1` | Maximum number of unavailable machine-learning pods during voluntary disruptions |
| machineLearning.podLabels | object | `{}` | Extra labels to add to the machine-learning pods |
| machineLearning.podSecurityContext | object | `{"fsGroup":1000,"fsGroupChangePolicy":"OnRootMismatch"}` | Pod-level security context for the machine-learning pods |
| machineLearning.readinessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/ping","port":"http"},"initialDelaySeconds":10,"periodSeconds":10,"timeoutSeconds":5}` | Readiness probe configuration for the machine-learning container. |
| machineLearning.replicaCount | int | `1` | Number of machine-learning replicas |
| machineLearning.resources | object | `{"limits":{"memory":"3Gi"},"requests":{"cpu":"250m","memory":"1Gi"}}` | Resource requests and limits for the machine-learning container. |
| machineLearning.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | Container-level security context for the machine-learning container. |
| machineLearning.service.port | int | `3003` | Service port |
| machineLearning.startupProbe | object | `{"failureThreshold":30,"httpGet":{"path":"/ping","port":"http"},"initialDelaySeconds":5,"periodSeconds":10,"timeoutSeconds":5}` | Startup probe configuration for the machine-learning container. |
| machineLearning.strategy | object | `{}` | Deployment update strategy of the machine-learning workload. Empty uses `RollingUpdate` |
| machineLearning.tolerations | list | `[]` | Tolerations for machine-learning pod scheduling |
| machineLearning.topologySpreadConstraints | list | `[]` | Topology spread constraints for the machine-learning pods, e.g. to spread replicas across nodes. See [Kubernetes docs](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/) |

### Microservices

| Key | Type | Default | Description |
|-----|------|---------|-------------|
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
| microservices.extraVolumeMounts | list | `[]` | Additional volume mounts for the microservices container |
| microservices.extraVolumes | list | `[]` | Additional volumes for the microservices pods, e.g. an external library or host devices |
| microservices.image.repository | string | `""` | Image repository. Defaults to the global `image.repository` |
| microservices.image.tag | string | `""` | Image tag. Defaults to the global `image.tag` or the chart `appVersion` |
| microservices.livenessProbe | object | `{}` | Liveness probe configuration for the microservices container. |
| microservices.nodeSelector | object | `{}` | Node selector for microservices pod scheduling |
| microservices.podAnnotations | object | `{}` | Extra annotations to add to the microservices pods |
| microservices.podLabels | object | `{}` | Extra labels to add to the microservices pods |
| microservices.podSecurityContext | object | `{"fsGroup":1000,"fsGroupChangePolicy":"OnRootMismatch"}` | Pod-level security context for the microservices pods |
| microservices.readinessProbe | object | `{}` | Readiness probe configuration for the microservices container. |
| microservices.replicaCount | int | `1` | Number of microservices replicas |
| microservices.resources | object | `{"limits":{"memory":"2Gi"},"requests":{"cpu":"200m","memory":"512Mi"}}` | Resource requests and limits for the microservices container. |
| microservices.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | Container-level security context for the microservices container. |
| microservices.service.annotations | object | `{}` | Service annotations |
| microservices.service.enabled | bool | `false` | Enable the microservices Service. Only required for scraping its metrics. The Service only exposes a metrics port. |
| microservices.startupProbe | object | `{}` | Startup probe configuration for the microservices container. |
| microservices.strategy | object | `{}` | Deployment update strategy of the microservices workload. Empty uses `RollingUpdate` |
| microservices.tolerations | list | `[]` | Tolerations for microservices pod scheduling |
| microservices.topologySpreadConstraints | list | `[]` | Topology spread constraints for the microservices pods. See [Kubernetes docs](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/) |

### Monitoring

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| monitoring.annotations | object | `{}` | Annotations to add to the ServiceMonitors |
| monitoring.apiMetricsPort | int | `8081` | Port the server exposes API metrics on. Also sets `IMMICH_API_METRICS_PORT` |
| monitoring.enabled | bool | `false` | Enable metrics scraping. Sets `IMMICH_TELEMETRY_INCLUDE=all` on the workloads |
| monitoring.honorLabels | bool | `true` | HonorLabels for the ServiceMonitors. Keeps exported labels of the workload over server-generated names |
| monitoring.interval | string | `"30s"` | Scrape interval for the ServiceMonitors |
| monitoring.labels | object | `{}` | Extra labels to add to the ServiceMonitors |
| monitoring.microservicesMetricsPort | int | `8082` | Port the microservices workload exposes metrics on. Also sets `IMMICH_MICROSERVICES_METRICS_PORT` |
| monitoring.namespaceSelector | object | `{}` | NamespaceSelector for the ServiceMonitors. Empty selects the namespace the ServiceMonitors are deployed in. |
| monitoring.scrapeTimeout | string | `"10s"` | Scrape timeout for the ServiceMonitors |
| monitoring.serviceMonitors.enabled | bool | `false` | Create ServiceMonitors for the server and microservices services. Enable this only when a Prometheus Operator (CRDs) is installed in the cluster |

### Persistence

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| persistence.media | object | `{"accessModes":["ReadWriteMany"],"annotations":{},"enabled":true,"existingClaim":"","keep":true,"size":"100Gi","storageClass":""}` | Shared library media volume mounted by the server and microservices workloads at the fixed container path `/data` (the Immich `IMMICH_MEDIA_LOCATION` default). The volume must support sharing across pods (`ReadWriteMany`). |
| persistence.media.accessModes | list | `["ReadWriteMany"]` | Access modes for the media volume |
| persistence.media.annotations | object | `{}` | Annotations for the media volume PVC |
| persistence.media.enabled | bool | `true` | Enable dynamic provisioning of the media volume. Set to `false` when using an `existingClaim` |
| persistence.media.existingClaim | string | `""` | Name of an existing PVC to use instead of creating a new one |
| persistence.media.keep | bool | `true` | Keep the media PVC when the release is uninstalled or the Argo CD Application is deleted (`helm.sh/resource-policy: keep`). It holds the original photos and videos |
| persistence.media.size | string | `"100Gi"` | Size of the media volume |
| persistence.media.storageClass | string | `""` | Storage class for the media volume. Empty uses the cluster's default StorageClass; `-` sets `storageClassName: ""`, which disables dynamic provisioning |
| persistence.modelCache.annotations | object | `{}` | Annotations for the model cache PVC |
| persistence.modelCache.existingClaim | string | `""` | Name of an existing PVC to use instead of creating one. Only used with `type: pvc`. Must support `ReadWriteMany` to run replicas on several nodes |
| persistence.modelCache.size | string | `"5Gi"` | Size of the model cache PVC |
| persistence.modelCache.sizeLimit | string | `"10Gi"` | Size limit of the `emptyDir`. Only used with `type: emptyDir` |
| persistence.modelCache.storageClass | string | `""` | Storage class for the model cache PVC. Empty uses the cluster's default StorageClass; `-` sets `storageClassName: ""`, which disables dynamic provisioning |
| persistence.modelCache.type | string | `"pvc"` | Model cache volume type: `pvc` (a `ReadWriteMany` PVC shared by all replicas) or `emptyDir` (per pod; models are downloaded again on each pod start) |

### PostgreSQL

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| postgres.affinity | object | `{}` | Affinity rules for PostgreSQL instance scheduling |
| postgres.annotations | object | `{}` | Annotations to add to the CNPG Cluster |
| postgres.backup.enabled | bool | `false` | Enable scheduled physical backups of the CNPG cluster (`ScheduledBackup`). Requires the [Barman Cloud Plugin](https://cloudnative-pg.io/plugin-barman-cloud/) for `method: plugin`, or CSI volume snapshots for `method: volumeSnapshot` |
| postgres.backup.immediate | bool | `false` | Take a backup immediately when the `ScheduledBackup` is created |
| postgres.backup.method | string | `"plugin"` | Backup method: `plugin` (Barman Cloud Plugin, object storage) or `volumeSnapshot` (Kubernetes CSI volume snapshots) |
| postgres.backup.objectStore.configuration | object | `{}` | `ObjectStore` configuration (`destinationPath`, `endpointURL`, `s3Credentials`, `wal`, `data`, ...). See the [plugin docs](https://cloudnative-pg.io/plugin-barman-cloud/docs/object_stores/). When set, WAL archiving is enabled even with `method: volumeSnapshot` |
| postgres.backup.objectStore.create | bool | `true` | Create a Barman Cloud `ObjectStore` named `<fullname>-postgresql` from `configuration`. Set to `false` to reference an existing one via `name` |
| postgres.backup.objectStore.instanceSidecarConfiguration | object | `{}` | Barman Cloud sidecar settings of the `ObjectStore` (e.g. `resources`) |
| postgres.backup.objectStore.name | string | `""` | Name of an existing `ObjectStore`. Only used when `create` is `false` |
| postgres.backup.objectStore.retentionPolicy | string | `"30d"` | Recovery window of the backups in the `ObjectStore` (e.g. `30d`) |
| postgres.backup.objectStore.serverName | string | `""` | Folder name of this cluster inside the object store. Defaults to the Cluster name. Change it when restoring into the same object store |
| postgres.backup.schedule | string | `"0 0 3 * * *"` | Backup schedule as a six-field cron expression including seconds (e.g. `0 0 3 * * *` = daily at 03:00) |
| postgres.backup.target | string | `""` | Instance to back up from: `prefer-standby` or `primary`. Empty uses the CNPG default (`prefer-standby`) |
| postgres.backup.volumeSnapshot | object | `{}` | CNPG `volumeSnapshot` backup configuration (e.g. `className`). Only used with `method: volumeSnapshot` |
| postgres.bootstrapSecretOverride | string | `""` | Name of an existing Secret with `username` and `password` keys used to bootstrap the CNPG cluster and as `DB_PASSWORD`. Takes precedence over `password` |
| postgres.database | string | `"immich"` | Name of the Immich database |
| postgres.enabled | bool | `true` | Deploy a CloudNativePG `Cluster`. Set to `false` to use an external database |
| postgres.extraExtensions | list | `[]` | Additional ImageVolume extensions in the CNPG `ExtensionConfiguration` format. See [CNPG docs](https://cloudnative-pg.io/docs/1.30/imagevolume_extensions) |
| postgres.extraSharedPreloadLibraries | list | `[]` | Additional shared preload libraries. `vchord.so` is always preloaded |
| postgres.host | string | `""` | Host of an external database. Only used when `enabled` is `false` |
| postgres.image.repository | string | `"ghcr.io/cloudnative-pg/postgresql"` | PostgreSQL image repository for the CNPG cluster instances |
| postgres.image.tag | string | `"18.6-standard-trixie"` | PostgreSQL image tag. Must start with the PostgreSQL major version (e.g. `18.6-standard-trixie`), which selects the matching `vchord` image and paths. Changing the major version triggers a CNPG major upgrade |
| postgres.instances | int | `1` | Number of PostgreSQL instances in the CNPG cluster |
| postgres.monitoring.enablePodMonitor | bool | `false` | Enable CNPG PodMonitor for PostgreSQL |
| postgres.nodeSelector | object | `{}` | Node selector for PostgreSQL instance scheduling |
| postgres.password | object | `{"secretKeyRef":{"key":"","name":""},"value":""}` | PostgreSQL password of `user`. If no source is set and `enabled` is `true`, CloudNativePG generates a random password in the `<fullname>-postgresql-app` Secret. Required when `enabled` is `false` |
| postgres.password.secretKeyRef.key | string | `""` | Key within the Secret |
| postgres.password.secretKeyRef.name | string | `""` | Name of an existing Secret. With the bundled cluster, the Secret also bootstraps the database: it must contain the keys `username` (equal to `user`) and `password`, so `key` must be `password` |
| postgres.password.value | string | `""` | Plain-text value, stored in a chart-managed Secret. Ignored if `secretKeyRef.name` is set. Prefer `secretKeyRef` |
| postgres.podSecurityContext | object | `{}` | Pod-level security context for the PostgreSQL instances. Empty applies the CloudNativePG defaults (UID/GID `26`) |
| postgres.port | int | `5432` | Port of an external database. Only used when `enabled` is `false` |
| postgres.postInitApplicationSQL | list | `["CREATE EXTENSION IF NOT EXISTS vector","CREATE EXTENSION IF NOT EXISTS vchord","CREATE EXTENSION IF NOT EXISTS cube","CREATE EXTENSION IF NOT EXISTS earthdistance"]` | SQL statements executed in the Immich database after the bootstrap |
| postgres.recovery.enabled | bool | `false` | Bootstrap the CNPG cluster from a backup instead of an empty database. Only applies when the Cluster is created |
| postgres.recovery.objectStoreName | string | `""` | Barman Cloud `ObjectStore` holding the backup. Defaults to the backup object store |
| postgres.recovery.recoveryTarget | object | `{}` | Point-in-time recovery target in the CNPG `recoveryTarget` format (e.g. `targetTime: "2026-01-01 00:00:00+00"`). Empty restores the latest state |
| postgres.recovery.serverName | string | `""` | Folder name of the source cluster inside the object store. Defaults to the Cluster name |
| postgres.recovery.volumeSnapshots | object | `{}` | Recover from CSI volume snapshots instead of an object store, in the CNPG `bootstrap.recovery.volumeSnapshots` format |
| postgres.resources | object | `{}` | Resource requests and limits for the PostgreSQL instances |
| postgres.securityContext | object | `{}` | Container-level security context for the PostgreSQL instance container. Merged with the CloudNativePG defaults |
| postgres.sslMode | string | `""` | SSL mode of the database connection (`DB_SSL_MODE`), e.g. `require` for an external database. Empty uses the Immich default |
| postgres.storage.size | string | `"100Gi"` | Size of the PostgreSQL PVC |
| postgres.storage.storageClass | string | `""` | Storage class for the PostgreSQL PVCs |
| postgres.superuser | bool | `true` | Grant the database role superuser privileges (via CNPG declarative role management). Immich expects this: its built-in database backups use `pg_dumpall` and it updates the `vchord` extension and reindexes automatically after a `vchord` upgrade. Without it, run `ALTER EXTENSION vchord UPDATE` and the reindex manually after each upgrade |
| postgres.tolerations | list | `[]` | Tolerations for PostgreSQL instance scheduling |
| postgres.user | string | `"immich"` | Name of the role that owns the Immich database (also used as `DB_USERNAME`) |
| postgres.vchord.enabled | bool | `true` | Inject the `vchord` extension via an ImageVolume extension. Disable only if `image` already ships `vchord` |
| postgres.vchord.repository | string | `"ghcr.io/tensorchord/vchord-scratch"` | `vchord` extension image repository. The tag is `pg<major>-v<version>` |
| postgres.vchord.version | string | `"1.1.1"` | `vchord` version. Immich accepts `>= 0.3, < 2.0` |

### Server

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| server.affinity | object | `{}` | Affinity rules for server pod scheduling |
| server.extraEnv | object | `{}` | Additional environment variables for the server container |
| server.extraEnvFrom | object | `{}` | Additional environment variables sourced from ConfigMaps or Secrets for the server container. Mapping of variable names to Kubernetes `valueFrom` objects, e.g. `MY_VAR: {secretKeyRef: {name: my-secret, key: my-key}}` |
| server.extraVolumeMounts | list | `[]` | Additional volume mounts for the server container |
| server.extraVolumes | list | `[]` | Additional volumes for the server pods, e.g. an external library or host devices |
| server.httpRoute | object | `{"annotations":{},"enabled":false,"hostnames":["chart-example.local"],"parentRefs":[{"name":"gateway","sectionName":"http"}],"rules":[{"matches":[{"path":{"type":"PathPrefix","value":"/"}}]}]}` | Expose the server via a Gateway API HTTPRoute. |
| server.httpRoute.annotations | object | `{}` | HTTPRoute annotations |
| server.httpRoute.enabled | bool | `false` | Enable HTTPRoute |
| server.httpRoute.hostnames | list | `["chart-example.local"]` | Hostnames matching the HTTP host header |
| server.httpRoute.parentRefs | list | `[{"name":"gateway","sectionName":"http"}]` | Gateways this route is attached to |
| server.httpRoute.rules | list | `[{"matches":[{"path":{"type":"PathPrefix","value":"/"}}]}]` | List of routing rules applied to matched requests. Each rule supports `matches`, `filters` and `timeouts` |
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
| server.podSecurityContext | object | `{"fsGroup":1000,"fsGroupChangePolicy":"OnRootMismatch"}` | Pod-level security context for the server pods |
| server.readinessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/api/server/ping","port":"http"},"initialDelaySeconds":10,"periodSeconds":10,"timeoutSeconds":5}` | Readiness probe configuration for the server container. |
| server.replicaCount | int | `1` | Number of server replicas |
| server.resources | object | `{"limits":{"memory":"2Gi"},"requests":{"cpu":"100m","memory":"512Mi"}}` | Resource requests and limits for the server container. |
| server.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | Container-level security context for the server container. |
| server.service | object | `{"annotations":{},"port":2283,"type":"ClusterIP"}` | Kubernetes Service configuration for the server. |
| server.service.annotations | object | `{}` | Service annotations |
| server.service.port | int | `2283` | Service port |
| server.service.type | string | `"ClusterIP"` | Service type. See [service types](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| server.startupProbe | object | `{"failureThreshold":30,"httpGet":{"path":"/api/server/ping","port":"http"},"initialDelaySeconds":5,"periodSeconds":10,"timeoutSeconds":5}` | Startup probe configuration for the server container. |
| server.strategy | object | `{}` | Deployment update strategy of the server workload. Empty uses `RollingUpdate` |
| server.tolerations | list | `[]` | Tolerations for server pod scheduling |
| server.topologySpreadConstraints | list | `[]` | Topology spread constraints for the server pods. See [Kubernetes docs](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/) |
| server.trustedProxies | list | `[]` | IPs or CIDRs of trusted reverse proxies (`IMMICH_TRUSTED_PROXIES`), e.g. the pod CIDR of the ingress controller. Required for correct client IPs behind a proxy |

### Service account

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| serviceAccount | object | `{"annotations":{},"automount":false,"create":true,"name":""}` | Service account configuration. See [Kubernetes docs](https://kubernetes.io/docs/concepts/security/service-accounts/) |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.automount | bool | `false` | Automatically mount a ServiceAccount's API credentials |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | Name of the service account to use. If not set and `create` is `true`, a name is generated using the fullname template |

### Upload optimizer

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| upload-optimizer.enabled | bool | `false` | Deploy the bundled immich-upload-optimizer sub-chart in front of the server |
| upload-optimizer.upstream | string | `"http://{{ if contains \"immich\" .Release.Name }}{{ .Release.Name }}{{ else }}{{ printf \"%s-immich\" .Release.Name }}{{ end }}:2283"` | Upstream Immich server URL the proxy forwards optimized uploads to. Defaults to the bundled server Service, assuming the top-level `nameOverride`/`fullnameOverride` are left unset (the sub-chart cannot see those values directly, only its own). If you set either of those, override this to match the server Service name. |

### Valkey

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| valkey.auth | object | `{"enabled":false}` | Valkey ACL authentication. |
| valkey.auth.enabled | bool | `false` | Enable ACL-based authentication. Requires `aclUsers` and the password in `redis.password` |
| valkey.enabled | bool | `true` | Deploy the bundled Valkey sub-chart (official Valkey Helm Chart) |
| valkey.replica.enabled | bool | `false` | Deploy Valkey replicas (master-replica mode). Requires `replica.persistence.size`, and `auth.aclUsers` when authentication is enabled |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
