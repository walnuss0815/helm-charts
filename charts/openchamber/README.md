# openchamber

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v2.1.1](https://img.shields.io/badge/AppVersion-v2.1.1-informational?style=flat-square)

A Helm chart for OpenChamber, a web workspace for running and reviewing AI coding work with OpenCode

**Homepage:** <https://openchamber.dev>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| walnuss0815 | <walnuss0815@gmail.com> | <https://github.com/walnuss0815> |

## Source Code

* <https://github.com/openchamber/openchamber>
* <https://github.com/coyotle/openchamber>

> **Security:** OpenChamber runs AI agents that execute commands, and its UI
> includes a terminal. Anyone who can sign in has a shell in the pod and can
> read every credential stored in it. Keep the UI password enabled and expose
> the service only over HTTPS.

### Required

- A UI password via `auth.uiPassword.value` or `auth.uiPassword.secretKeyRef`.
  Rendering fails without one unless `auth.uiPassword.enabled` is explicitly
  set to `false`.

### Optional

- An Ingress controller or [Gateway API](https://gateway-api.sigs.k8s.io/) implementation
- A default StorageClass when enabling `persistence`

## Container image

OpenChamber does not publish an official container image. The chart defaults
to [`ghcr.io/coyotle/openchamber`](https://github.com/coyotle/openchamber), a
community image built daily from the unmodified upstream `Dockerfile` for every
upstream release (`linux/amd64`, `linux/arm64`). Override `image.repository`
to use your own build of the upstream `Dockerfile`.

## Quick start

```yaml
auth:
  uiPassword:
    secretKeyRef:
      name: openchamber-auth
      key: ui-password
  jwtSecret:
    secretKeyRef:
      name: openchamber-auth
      key: jwt-secret

# Model provider API keys, e.g. ANTHROPIC_API_KEY
envFrom:
  - secretRef:
      name: openchamber-provider-keys

persistence:
  data:
    enabled: true
  workspaces:
    enabled: true
```

## Persistence

Two volumes are used. When a volume is disabled, an `emptyDir` takes its place
and its content is lost whenever the pod is replaced.

| Volume | Path in the container | Content |
|--------|-----------------------|---------|
| `data` | `~/.config/openchamber` | Settings, project settings, passkeys, paired devices, GitHub/Linear tokens, environment variables set in the UI, session goals, themes, extensions, speech models, chats without a project |
| `data` | `~/.config/opencode` | OpenCode config, agents, commands, skills and plugins created in the UI |
| `data` | `~/.local/share/opencode` | Provider credentials (`auth.json`), session and message history, logs, undo snapshots |
| `data` | `~/.local/state/opencode` | Recently used models, prompt history |
| `data` | `~/.ssh` | SSH key generated on first start (or provided via `ssh.privateKey`) |
| `data` | `~/.cache/opencode` | Only with `persistence.cache.enabled`: downloaded provider SDKs and plugins |
| `workspaces` | `~/workspaces` | Cloned repositories, worktrees, dependencies and build output |

The `data` volume contains credentials; treat its backups accordingly.

## Reverse proxy requirements

OpenChamber uses WebSockets (`/api/event/ws`, `/api/global/event/ws`,
`/api/terminal/ws`) and Server-Sent Events (`/api/event`, `/api/global/event`,
`/api/notifications/stream`, `/api/openchamber/events`). The proxy in front of
it must:

- support WebSocket upgrades,
- not buffer responses (SSE),
- allow long read timeouts (e.g. 3600s),
- accept request bodies of at least 50 MB,
- compress responses in only one layer (see `openchamber.compressApi`).

Example for ingress-nginx:

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
    nginx.ingress.kubernetes.io/proxy-buffering: "off"
    nginx.ingress.kubernetes.io/proxy-request-buffering: "off"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
  hosts:
    - host: openchamber.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: openchamber-tls
      hosts:
        - openchamber.example.com
```

With an Ingress, `OPENCHAMBER_LAN_URL` is derived from the first host so device
pairing links point to it (wildcard hosts are skipped). With an HTTPRoute or a
wildcard Ingress host, set `openchamber.lanUrl`.

## Running without a UI password

Only do this behind an authenticating proxy (e.g. oauth2-proxy) or on a fully
trusted network:

```yaml
auth:
  uiPassword:
    enabled: false
```

The chart then sets `OPENCHAMBER_ALLOW_UNAUTHENTICATED_LAN=true`, without which
OpenChamber refuses to listen on all interfaces without authentication.

## SSH key

The image generates an SSH key on first start; add its public key (printed in
the container log) to your Git host. To use a key you manage, store it in a
Secret and reference it:

```yaml
ssh:
  privateKey:
    secretKeyRef:
      name: openchamber-ssh
      key: id_ed25519
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity rules for the pod |
| auth.jwtSecret | object | not set | Secret used to sign UI login tokens (`OPENCODE_JWT_SECRET`). When not set, OpenChamber generates one in `~/.config/openchamber/jwt-secret`, which only survives restarts with `persistence.data` enabled. Accepts an inline `value` (stored in a chart-managed Secret) or a `secretKeyRef`. |
| auth.sessionTtlHours | string | `""` | Browser sign-in lifetime in hours when "trust this device" is off (`OPENCHAMBER_UI_SESSION_TTL_HOURS`). Empty uses the app default (12). |
| auth.trustedSessionTtlDays | string | `""` | Sign-in lifetime in days on trusted devices (`OPENCHAMBER_UI_TRUSTED_SESSION_TTL_DAYS`). Empty uses the app default (7). |
| auth.uiPassword.enabled | bool | `true` | Protect the browser UI with a password (`OPENCHAMBER_UI_PASSWORD`). When `true`, either `value` or `secretKeyRef` must be set, otherwise rendering fails. Running without a password must be chosen explicitly by setting this to `false`; the chart then sets `OPENCHAMBER_ALLOW_UNAUTHENTICATED_LAN=true`, which OpenChamber requires to listen on all interfaces without authentication. |
| auth.uiPassword.secretKeyRef | object | `{"key":"","name":""}` | Reference to an existing Secret holding the password |
| auth.uiPassword.value | string | `""` | Inline password. Stored in a chart-managed Secret. Prefer `secretKeyRef`. |
| enterprise.allowLocalExtensions | bool | `false` | Allow installing extensions from a local folder (`OPENCHAMBER_ALLOW_LOCAL_EXTENSIONS=1`) |
| enterprise.allowNetworkAccess | bool | `true` | Allow connections from other machines (`OPENCHAMBER_ALLOW_NETWORK_ACCESS=1`). Must stay `true` in Kubernetes, otherwise OpenChamber refuses to listen beyond the container. |
| enterprise.allowedExtensions | list | `[]` | Repository URLs extensions may be installed from (`OPENCHAMBER_ALLOWED_EXTENSIONS`), e.g. `["https://github.com/acme/"]` |
| enterprise.enabled | bool | `false` | Enable enterprise mode (`OPENCHAMBER_ENTERPRISE_MODE=1`). Restricts model providers to the OpenCode config and turns off public tunnels, cloud speech and data-sending extensions unless allowed below. |
| enterprise.jev.apiKey | object | not set | API key for the classification endpoint (`OPENCHAMBER_JEV_API_KEY`). Accepts an inline `value` (stored in a chart-managed Secret) or a `secretKeyRef`. |
| enterprise.jev.model | string | `""` | Classification model (`OPENCHAMBER_JEV_MODEL`) |
| enterprise.jev.url | string | `""` | Classification (Jev) endpoint (`OPENCHAMBER_JEV_URL`) |
| enterprise.relayUrl | string | `""` | Self-hosted relay URL (`OPENCHAMBER_RELAY_URL`), e.g. `wss://relay.example.com/ws` |
| env | list | `[]` | Additional environment variables, e.g. model provider settings |
| envFrom | list | `[]` | Additional environment variables from Secrets or ConfigMaps, e.g. model provider API keys such as `ANTHROPIC_API_KEY` |
| extraInitContainers | list | `[]` | Additional init containers |
| extraManifests | list | `[]` | Additional Kubernetes manifests to deploy. Each entry is a string that is rendered with `tpl`. |
| extraVolumeMounts | list | `[]` | Additional volume mounts for the OpenChamber container |
| extraVolumes | list | `[]` | Additional volumes for the pod |
| fullnameOverride | string | `""` | Override the full resource name |
| httpRoute | object | `{"annotations":{},"enabled":false,"hostnames":["chart-example.local"],"parentRefs":[{"name":"gateway","sectionName":"http"}],"rules":[{"matches":[{"path":{"type":"PathPrefix","value":"/"}}]}]}` | Expose the service via a Gateway API HTTPRoute. Requires the Gateway API CRDs and a suitable controller in the cluster (see: https://gateway-api.sigs.k8s.io/guides/) |
| httpRoute.annotations | object | `{}` | HTTPRoute annotations |
| httpRoute.enabled | bool | `false` | Enable an HTTPRoute |
| httpRoute.hostnames | list | `["chart-example.local"]` | Hostnames matching the HTTP Host header |
| httpRoute.parentRefs | list | `[{"name":"gateway","sectionName":"http"}]` | Gateways this route is attached to |
| httpRoute.rules | list | `[{"matches":[{"path":{"type":"PathPrefix","value":"/"}}]}]` | Routing rules. Long-lived WebSocket and SSE connections need generous timeouts; with Gateway API v1.2+ add `timeouts: {request: "0s"}` to a rule. |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.repository | string | `"ghcr.io/coyotle/openchamber"` | Container image repository. OpenChamber does not publish an official image; the default is a community build of the unmodified upstream Dockerfile. |
| image.tag | string | `""` | Overrides the image tag whose default is the chart appVersion |
| imagePullSecrets | list | `[]` | Secrets for pulling an image from a private registry |
| ingress.annotations | object | `{}` | Ingress annotations. OpenChamber needs WebSockets, unbuffered SSE, long read timeouts and large request bodies. Example for ingress-nginx: ```yaml nginx.ingress.kubernetes.io/proxy-body-size: "50m" nginx.ingress.kubernetes.io/proxy-buffering: "off" nginx.ingress.kubernetes.io/proxy-request-buffering: "off" nginx.ingress.kubernetes.io/proxy-read-timeout: "3600" nginx.ingress.kubernetes.io/proxy-send-timeout: "3600" ``` |
| ingress.className | string | `""` | Ingress class name |
| ingress.enabled | bool | `false` | Enable an Ingress. OpenChamber gives shell access to the pod, so only expose it with `auth.uiPassword` enabled. |
| ingress.hosts | list | `[{"host":"chart-example.local","paths":[{"path":"/","pathType":"Prefix"}]}]` | Ingress hosts and paths |
| ingress.tls | list | `[]` | Ingress TLS configuration |
| livenessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/health","port":"http"},"periodSeconds":30,"timeoutSeconds":5}` | Liveness probe |
| nameOverride | string | `""` | Override the chart name |
| nodeSelector | object | `{}` | Node selector for the pod |
| ohMyOpencode.enabled | bool | `false` | Install and set up oh-my-opencode on first start (`OH_MY_OPENCODE=true`). Requires internet access. The setup marker is stored in `~/.config/opencode`, so enable `persistence.data` to avoid re-running it after every restart. |
| openchamber.apiOnly | bool | `false` | Serve only the API, without the browser UI (`OPENCHAMBER_API_ONLY`) |
| openchamber.compressApi | string | `""` | API response compression (`OPENCHAMBER_COMPRESS_API`): `"true"`, `"false"` or empty for the app default. Disable it if your proxy or CDN already compresses responses. |
| openchamber.extraArgs | list | `[]` | Additional arguments appended to the server command (`bun packages/web/bin/cli.js serve --foreground --port 3000`) |
| openchamber.frameAncestors | string | `""` | Origins allowed to embed OpenChamber in a frame, separated by spaces (`OPENCHAMBER_FRAME_ANCESTORS`) |
| openchamber.lanUrl | string | `""` | External origin other devices use to reach OpenChamber (`OPENCHAMBER_LAN_URL`), used in pairing links and QR codes, for example `https://openchamber.example.com`. When empty, it is derived from the first Ingress host if the Ingress is enabled and the host is not a wildcard. |
| openchamber.proxy | object | `{"httpProxy":"","httpsProxy":"","noProxy":""}` | Proxy for OpenChamber's and OpenCode's outgoing requests |
| openchamber.proxy.httpProxy | string | `""` | Proxy for plain HTTP requests (`HTTP_PROXY`) |
| openchamber.proxy.httpsProxy | string | `""` | Proxy for HTTPS requests (`HTTPS_PROXY`) |
| openchamber.proxy.noProxy | string | `""` | Hosts that bypass the proxy (`NO_PROXY`), e.g. `localhost,127.0.0.1,.svc,.cluster.local` |
| openchamber.terminalShell | string | `""` | Shell for terminal sessions (`OPENCHAMBER_TERMINAL_SHELL`), e.g. `/bin/bash` |
| openchamber.verboseRequestLogs | bool | `false` | Log every HTTP request (`OPENCHAMBER_VERBOSE_REQUEST_LOGS`) |
| opencode.config | object | `{}` | OpenCode configuration rendered as `opencode.json` into a ConfigMap and loaded via `OPENCODE_CONFIG`. OpenCode merges it with the global config in `~/.config/opencode`, so settings changed in the UI keep working. Example: ```yaml config:   $schema: https://opencode.ai/config.json   model: anthropic/claude-sonnet-4-5   autoupdate: false ``` |
| opencode.external.enabled | bool | `false` | Connect to an existing OpenCode server instead of starting one inside the container (`OPENCODE_HOST` and `OPENCODE_SKIP_START=true`) |
| opencode.external.host | string | `""` | OpenCode server origin with an explicit port and no path, e.g. `http://opencode:4096` |
| persistence.cache.enabled | bool | `false` | Store `~/.cache/opencode` (downloaded provider SDKs and plugins) on the data volume to speed up restarts. When disabled, the cache lives in the container and is downloaded again after a restart. |
| persistence.data.accessModes | list | `["ReadWriteOnce"]` | Access modes |
| persistence.data.annotations | object | `{}` | Annotations for the PVC |
| persistence.data.enabled | bool | `false` | Persist application state: `~/.config/openchamber` (settings, logins, paired devices, GitHub/Linear tokens), `~/.config/opencode` (OpenCode config), `~/.local/share/opencode` (provider credentials, session history), `~/.local/state/opencode` and `~/.ssh`. When disabled, an `emptyDir` is used and everything is lost when the pod is replaced. |
| persistence.data.existingClaim | string | `""` | Use an existing PVC instead of creating one |
| persistence.data.size | string | `"5Gi"` | Size of the PVC |
| persistence.data.storageClass | string | `""` | Storage class. Empty uses the cluster default; `-` sets `storageClassName: ""`. |
| persistence.workspaces.accessModes | list | `["ReadWriteOnce"]` | Access modes |
| persistence.workspaces.annotations | object | `{}` | Annotations for the PVC |
| persistence.workspaces.enabled | bool | `false` | Persist `~/workspaces`, where repositories, worktrees and build output live. When disabled, an `emptyDir` is used. |
| persistence.workspaces.existingClaim | string | `""` | Use an existing PVC instead of creating one |
| persistence.workspaces.size | string | `"20Gi"` | Size of the PVC |
| persistence.workspaces.storageClass | string | `""` | Storage class. Empty uses the cluster default; `-` sets `storageClassName: ""`. |
| podAnnotations | object | `{}` | Annotations to add to the pod |
| podLabels | object | `{}` | Labels to add to the pod |
| podSecurityContext | object | `{"fsGroup":1000,"fsGroupChangePolicy":"OnRootMismatch","runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | Pod security context. The image runs as user `openchamber` (UID/GID 1000). |
| policy.content | object | `{}` | Policy content rendered as JSON into a chart-managed Secret, e.g. `{enterpriseMode: true, organization: Acme}`. Ignored when `existingSecret.name` is set. |
| policy.enabled | bool | `false` | Mount a `policy.json` at `/etc/openchamber/policy.json`. The policy file works with or without enterprise mode (e.g. `opencodeBinary`, `hideBuiltinSkillCatalogs`). See https://github.com/openchamber/openchamber/blob/main/packages/docs/content/docs/security.mdx |
| policy.existingSecret.key | string | `"policy.json"` | Key of the policy file in the existing Secret |
| policy.existingSecret.name | string | `""` | Name of an existing Secret holding the policy file |
| readinessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/health","port":"http"},"periodSeconds":10,"timeoutSeconds":5}` | Readiness probe |
| resources | object | `{"limits":{"memory":"2Gi"},"requests":{"cpu":"100m","memory":"512Mi"}}` | Resource requests and limits. Agents, language servers and builds run inside this container, so raise the memory limit for larger projects. |
| securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":false,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000}` | Container security context. The root filesystem stays writable because git, npm, bun and the agent's tools write to several locations in the home directory and `/tmp`. |
| service.port | int | `80` | Service port. Traffic is forwarded to the container port 3000. |
| service.type | string | `"ClusterIP"` | Service type |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.automount | bool | `false` | Automatically mount the ServiceAccount's API credentials. OpenChamber does not need access to the Kubernetes API. |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template |
| ssh.privateKey.secretKeyRef | object | `{"key":"","name":""}` | Existing Secret holding an SSH private key (ed25519 recommended) to use for git over SSH. An init container copies it to `~/.ssh/id_ed25519` with mode 0600. When not set, the image generates a key on first start, which only survives restarts with `persistence.data` enabled. `name` and `key` are rendered with `tpl`, like all `secretKeyRef` values in this chart. |
| startupProbe | object | `{"failureThreshold":60,"httpGet":{"path":"/health","port":"http"},"periodSeconds":5,"timeoutSeconds":5}` | Startup probe. `/health` answers without authentication. The first start can be slow on small nodes, so up to 5 minutes are allowed. |
| tolerations | list | `[]` | Tolerations for the pod |
| tunnel.configPath | string | `""` | Path to a cloudflared config file for `managed-local` (`OPENCHAMBER_TUNNEL_CONFIG`). Mount the file with `extraVolumes`. |
| tunnel.enabled | bool | `false` | Start a tunnel together with OpenChamber |
| tunnel.hostname | string | `""` | Public hostname (`OPENCHAMBER_TUNNEL_HOSTNAME`), required for `managed-remote` |
| tunnel.mode | string | `"quick"` | Tunnel mode (`OPENCHAMBER_TUNNEL_MODE`): `quick`, `managed-remote` or `managed-local` |
| tunnel.ngrokAuthToken | object | not set | ngrok auth token (`NGROK_AUTHTOKEN`). Accepts an inline `value` (stored in a chart-managed Secret) or a `secretKeyRef`. |
| tunnel.provider | string | `"cloudflare"` | Tunnel provider (`OPENCHAMBER_TUNNEL_PROVIDER`), e.g. `cloudflare` |
| tunnel.token | object | not set | Tunnel token (`OPENCHAMBER_TUNNEL_TOKEN`), required for `managed-remote`. Accepts an inline `value` (stored in a chart-managed Secret) or a `secretKeyRef`. |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
