# text-embeddings-inference

![Version: 0.1.2](https://img.shields.io/badge/Version-0.1.2-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: cpu-1.9.4](https://img.shields.io/badge/AppVersion-cpu--1.9.4-informational?style=flat-square)

A Helm chart for Hugging Face Text Embeddings Inference, a fast server for text embedding models with an OpenAI-compatible API

**Homepage:** <https://huggingface.co/docs/text-embeddings-inference>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| walnuss0815 | <walnuss0815@gmail.com> | <https://github.com/walnuss0815> |

## Source Code

* <https://github.com/huggingface/text-embeddings-inference>

[Text Embeddings Inference](https://github.com/huggingface/text-embeddings-inference)
(TEI) serves text embedding models behind an OpenAI-compatible API
(`/v1/embeddings`). Any client that supports an OpenAI-style embeddings
endpoint can use it, e.g. the `openai-like` embedding backend of paperless-ngx.

## Quick start

```yaml
model:
  id: BAAI/bge-m3

# On CPU, long-context models need a lower batch limit, see "Long-context models on CPU"
extraArgs:
  - --max-batch-tokens=2048

persistence:
  enabled: true

resources:
  limits:
    memory: 4Gi
```

Inside the cluster, use the base URL
`http://<release>-text-embeddings-inference:8080/v1`. To try it from your
machine:

```sh
kubectl port-forward svc/<release>-text-embeddings-inference 8080:8080
curl http://127.0.0.1:8080/v1/embeddings \
  -H "Content-Type: application/json" \
  -d '{"model": "BAAI/bge-m3", "input": "Hello world"}'
```

## Model cache

Models are downloaded from Hugging Face into `/data` on first start. The cache
only holds downloadable models and needs no backup. Without
`persistence.enabled`, an `emptyDir` is used and the model is downloaded again
on every pod start.

Pods are replaced with the `Recreate` strategy, so a new pod never waits for a
`ReadWriteOnce` cache volume that the old pod still holds. All replicas stop
together during an update, so expect a short outage while the model loads.

## Image tags

The default tag (`cpu-<version>`) runs on amd64 CPUs. For arm64, set
`image.tag` to `cpu-arm64-<version>`. For NVIDIA GPUs, use a tag without the
`cpu-` prefix that matches your GPU architecture (e.g. `89-<version>`) and
request the GPU:

```yaml
image:
  tag: 89-1.9.4

resources:
  limits:
    nvidia.com/gpu: "1"
```

## API key

Without an API key, anyone who can reach the service can use it. To require
one, set `apiKey.value` (stored in a chart-managed Secret) or, preferably,
reference an existing Secret:

```yaml
apiKey:
  secretKeyRef:
    name: tei-api-key
    key: api-key
```

Clients then send `Authorization: Bearer <key>`. `/health` and `/metrics` stay
public.

## Long-context models on CPU

On CPU, TEI warms up by running one sequence of
`min(the model's maximum input, --max-batch-tokens)` tokens. The default
`--max-batch-tokens` is 16384, so a model like `BAAI/bge-m3` (8192 tokens) warms
up with a full 8192-token sequence. Attention memory grows with the square of
the sequence length, which together with the weights exceeds 6Gi and gets the
container OOM-killed right after the "Warming up model" log line.

Set `--max-batch-tokens` a little above the longest input your client sends.
For example, paperless-ngx sends chunks of about 1024 tokens, and
`--max-batch-tokens=2048` keeps `BAAI/bge-m3` at about 2 GiB of memory (3.3 GiB
peak with file cache) on 2 CPU threads. Longer inputs are truncated, because
`--auto-truncate` is on by default. The log line "Backend does not support a
batch size > 8" is harmless.

## Resources

TEI runs inference on all CPU cores it can see. Set `env.RAYON_NUM_THREADS` to
match the CPU limit. On nodes with many cores, also limit the tokenizer threads,
e.g. `extraArgs: ["--tokenization-workers=2"]`; the default is the node's core
count.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity rules for the pod |
| apiKey | object | not set | API key clients must send as `Authorization: Bearer <key>` (`API_KEY`). Health and metrics endpoints stay public |
| apiKey.secretKeyRef.key | string | `""` | Key within the Secret |
| apiKey.secretKeyRef.name | string | `""` | Name of an existing Secret |
| apiKey.value | string | `""` | Plain-text value, stored in a chart-managed Secret. Ignored if `secretKeyRef.name` is set. Prefer `secretKeyRef` |
| env | object | `{"RAYON_NUM_THREADS":"1"}` | Additional environment variables as a map of variable name to value. Values are rendered with `tpl`. Overrides the chart-set `PORT`, `HF_HOME` and `HUGGINGFACE_HUB_CACHE` (changing `PORT` breaks the probes). `RAYON_NUM_THREADS` should match the CPU limit |
| envFrom | object | `{}` | Additional environment variables as a map of variable name to a Kubernetes `valueFrom` object, e.g. `MY_VAR: {secretKeyRef: {name: my-secret, key: my-key}}` |
| extraArgs | list | `[]` | Additional arguments for `text-embeddings-router`, e.g. `--max-batch-tokens=2048` (see the README on long-context models), `--auto-truncate` or `--tokenization-workers=2` |
| extraManifests | list | `[]` | Extra Kubernetes manifests to deploy alongside the chart. Each entry is a string or a map and is rendered with `tpl` |
| fullnameOverride | string | `""` | Override the full resource name |
| httpRoute | object | `{"annotations":{},"enabled":false,"hostnames":["chart-example.local"],"parentRefs":[{"name":"gateway","sectionName":"http"}],"rules":[{"matches":[{"path":{"type":"PathPrefix","value":"/"}}]}]}` | Expose the service via a Gateway API HTTPRoute. Requires the Gateway API CRDs and a suitable controller in the cluster (see: https://gateway-api.sigs.k8s.io/guides/) |
| httpRoute.annotations | object | `{}` | HTTPRoute annotations |
| httpRoute.enabled | bool | `false` | Enable an HTTPRoute |
| httpRoute.hostnames | list | `["chart-example.local"]` | Hostnames matching the HTTP Host header |
| httpRoute.parentRefs | list | `[{"name":"gateway","sectionName":"http"}]` | Gateways this route is attached to |
| httpRoute.rules | list | `[{"matches":[{"path":{"type":"PathPrefix","value":"/"}}]}]` | Routing rules |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.repository | string | `"ghcr.io/huggingface/text-embeddings-inference"` | Image repository. Tags are prefixed by hardware: `cpu-<version>` (amd64), `cpu-arm64-<version>` for arm64, and tags without `cpu-` (e.g. `89-<version>`) for NVIDIA GPUs |
| image.tag | string | `""` | Image tag. Defaults to the chart's `appVersion` if not set |
| imagePullSecrets | list | `[]` | Secrets for pulling images from a private registry |
| ingress.annotations | object | `{}` | Ingress annotations, e.g. `nginx.ingress.kubernetes.io/proxy-body-size: 10m` |
| ingress.className | string | `""` | Ingress class name |
| ingress.enabled | bool | `false` | Enable an Ingress |
| ingress.hosts | list | `[{"host":"chart-example.local","paths":[{"path":"/","pathType":"Prefix"}]}]` | Ingress hosts and paths |
| ingress.tls | list | `[]` | Ingress TLS configuration |
| livenessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/health","port":"http"},"periodSeconds":30,"timeoutSeconds":10}` | Liveness probe configuration. Empty disables the probe |
| model.id | string | `"sentence-transformers/all-MiniLM-L6-v2"` | Hugging Face model ID or local path passed as `--model-id`. The small default suits tests; e.g. `BAAI/bge-m3` is a strong multilingual model |
| model.revision | string | `""` | Model revision (commit, branch or tag) passed as `--revision`. Empty uses the default branch |
| nameOverride | string | `""` | Override the chart name |
| nodeSelector | object | `{}` | Node selector for the pod |
| persistence.accessModes | list | `["ReadWriteOnce"]` | Access modes |
| persistence.annotations | object | `{}` | Annotations for the PVC |
| persistence.enabled | bool | `false` | Store the model cache (`/data`) on a PVC so restarts skip the download. It only holds downloadable models and needs no backup. When disabled, an `emptyDir` is used |
| persistence.existingClaim | string | `""` | Use an existing PVC instead of creating one |
| persistence.size | string | `"5Gi"` | Size of the PVC |
| persistence.sizeLimit | string | `""` | Size limit of the `emptyDir` used when persistence is disabled |
| persistence.storageClass | string | `""` | Storage class. Empty uses the cluster default; `-` sets `storageClassName: ""` |
| podAnnotations | object | `{}` | Annotations to add to the pod |
| podLabels | object | `{}` | Labels to add to the pod |
| podSecurityContext | object | `{"fsGroup":1000,"fsGroupChangePolicy":"OnRootMismatch","runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | Pod security context. Runs as a non-root user; `fsGroup` makes the model cache writable |
| readinessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/health","port":"http"},"periodSeconds":10,"timeoutSeconds":5}` | Readiness probe configuration. Empty disables the probe |
| replicaCount | int | `1` | Number of replicas. Each replica downloads and caches the model on its own |
| resources | object | `{"limits":{"cpu":"1","memory":"1Gi"},"requests":{"cpu":"100m","memory":"256Mi"}}` | Resource requests and limits sized for the default small model. Larger models need more, e.g. about 3-4Gi memory for `BAAI/bge-m3` on CPU with `--max-batch-tokens=2048` (see the README) |
| securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000}` | Container security context. The root filesystem is read-only; the model cache (`/data`) and `/tmp` are writable volumes |
| service.port | int | `8080` | Service port. Traffic is forwarded to container port 8080 |
| service.type | string | `"ClusterIP"` | Service type |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.automount | bool | `false` | Automatically mount the ServiceAccount's API credentials. Text Embeddings Inference does not need access to the Kubernetes API |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | Name of the service account to use. If not set and `create` is `true`, a name is generated using the fullname template |
| startupProbe | object | `{"failureThreshold":60,"httpGet":{"path":"/health","port":"http"},"periodSeconds":10,"timeoutSeconds":5}` | Startup probe configuration. Empty disables the probe. The first start downloads the model, so up to 10 minutes are allowed |
| tolerations | list | `[]` | Tolerations for the pod |
| volumeMounts | list | `[]` | Additional volume mounts |
| volumes | list | `[]` | Additional volumes |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
