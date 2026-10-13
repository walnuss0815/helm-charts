# keycloak

![Version: 0.1.1](https://img.shields.io/badge/Version-0.1.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 26.8.1](https://img.shields.io/badge/AppVersion-26.8.1-informational?style=flat-square)

A Helm chart for Keycloak, the open source identity and access management solution, with an optional CloudNativePG database.

**Homepage:** <https://www.keycloak.org>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| walnuss0815 | <walnuss0815@gmail.com> | <https://github.com/walnuss0815> |

## Source Code

* <https://github.com/keycloak/keycloak>

## Requirements

### Required

- Keycloak 26.6 or newer. The chart passes secrets as `KCRAW_` environment
  variables, which older versions do not know.
- `keycloak.hostname`: the public URL of Keycloak, e.g. `https://sso.example.com`.
- A password source for the temporary bootstrap admin
  (`bootstrapAdmin.user.password`), or the bootstrap admin disabled.
- The [CloudNativePG operator](https://cloudnative-pg.io/) when `postgres.enabled`
  is `true` (default), or an external PostgreSQL 14 to 18.

### Optional

- An Ingress controller or a [Gateway API](https://gateway-api.sigs.k8s.io/) implementation
- The [Barman Cloud Plugin](https://cloudnative-pg.io/plugin-barman-cloud/) for
  backups to object storage, or CSI volume snapshots
- The Prometheus Operator for `serviceMonitor` and `postgres.podMonitor`
- cert-manager for the certificate of `tls.secretName`

## Quick start

A GitOps setup with all credentials in existing Secrets (e.g. from External
Secrets or Sealed Secrets):

```yaml
keycloak:
  hostname: https://sso.example.com

bootstrapAdmin:
  user:
    password:
      secretKeyRef:
        name: keycloak-bootstrap-admin
        key: password

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: sso.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: sso-example-com-tls
      hosts:
        - sso.example.com
```

The chart deploys a CloudNativePG cluster `<fullname>-postgresql`. Keycloak
becomes ready once the database is running.

## Optimized start

Keycloak persists some options, the build options (`db`, `health-enabled`,
`metrics-enabled`, `features`, `features-disabled`, `http-relative-path`, ...),
in an optimized build. Starting with `--optimized` skips the build step and is
the recommended way to run Keycloak in production. The stock image is built
with the default build options, which do not match this chart, so
`build.mode` decides where the build happens:

| `build.mode` | Build | Start | Root filesystem |
|--------------|-------|-------|-----------------|
| `initContainer` (default) | Init container on every pod start (about 10-30s) | `start --optimized` | Read-only |
| `prebuilt` | In your custom image | `start --optimized` | Read-only |
| `auto` | Keycloak rebuilds itself on start when build options changed | `start` | Writable |

With `initContainer`, the init container copies the Keycloak distribution of
`image` into the `emptyDir` volume `keycloak-home` and runs `kc.sh build` with
the same environment ConfigMap the Keycloak container loads, so the build
options always match.

### Providers

For themes, see [Themes](#themes). With `build.mode: initContainer`, add other
providers with an init container that writes into `keycloak-home` before the
build:

```yaml
initContainers:
  - name: providers
    image: ghcr.io/example/keycloak-providers:1.0.0
    command: [sh, -c, "mkdir -p /keycloak-home/providers && cp /providers/*.jar /keycloak-home/providers/"]
    volumeMounts:
      - name: keycloak-home
        mountPath: /keycloak-home
```

### Custom optimized image

For `build.mode: prebuilt`, the build options of the image must match the
chart's values, otherwise Keycloak refuses to start:

```dockerfile
FROM quay.io/keycloak/keycloak:26.8.1 AS builder
ENV KC_DB=postgres \
    KC_HEALTH_ENABLED=true \
    KC_METRICS_ENABLED=false
# Providers, themes, KC_FEATURES, KC_HTTP_RELATIVE_PATH, ...
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:26.8.1
COPY --from=builder /opt/keycloak/ /opt/keycloak/
```

## Themes

Keycloak themes customize the login, account, admin and email pages and the
welcome page ([themes guide](https://www.keycloak.org/ui-customization/themes)).
`themes.custom` adds themes in two formats:

- `type: directory` (default): a theme directory with one subdirectory per
  theme type (`login/theme.properties`, ...). It is mounted read-only at
  `/opt/keycloak/themes/<name>` and needs no build.
- `type: jar`: a theme archive with `META-INF/keycloak-themes.json`, e.g. built
  with [Keycloakify](https://www.keycloakify.dev/). It is added as
  `providers/<name>.jar` before the build. Not supported with
  `build.mode: prebuilt`; add the JAR to your image instead.

Each theme comes from one source:

| Source | Settings | Notes |
|--------|----------|-------|
| Image, copied | `image` | An init container copies `path` from the image. The image needs `sh` and `cp` (e.g. based on busybox), and the files must be readable by UID `1000` |
| Image volume | `image`, `imageVolume: true` | Mounted as a Kubernetes [image volume](https://kubernetes.io/docs/concepts/storage/volumes/#image), so scratch images work. Requires a Kubernetes version and container runtime with image volume support |
| ConfigMap | `configMap` | Directory themes only. Map flat ConfigMap keys to paths with `items`. Changes are not picked up until the pods restart |

`path` is the location of the theme directory or JAR in the image (default
`/theme` or `/theme.jar`).

```yaml
themes:
  custom:
    # Directory theme copied from an image
    - name: acme
      image:
        repository: ghcr.io/acme/keycloak-theme
        tag: 1.2.0
      path: /theme
    # Keycloakify JAR from a scratch image
    - name: acme-keycloakify
      type: jar
      imageVolume: true
      image:
        repository: ghcr.io/acme/keycloakify-theme
        tag: 3.0.0
      path: /keycloak-theme.jar
    # Small directory theme from a ConfigMap
    - name: branding
      configMap:
        name: keycloak-branding
        items:
          - key: login-theme.properties
            path: login/theme.properties
          - key: login-styles.css
            path: login/resources/css/styles.css
  # The welcome page theme is set server-wide
  welcomeTheme: acme
```

Login, account, admin and email themes are selected per realm, in the Admin
Console (*Realm settings* > *Themes*) or declaratively, e.g. with
`spec.themes` (`loginTheme`, `accountTheme`, `adminConsoleTheme`,
`emailTheme`) of an edp-keycloak-operator `KeycloakRealm`. Clients can
override the login theme.

Set `themes.cache: false` only while developing a theme: it disables the
theme, template and static resource caches.

> Themes contain FreeMarker templates that Keycloak executes. Only use themes
> from trusted sources.

## Exposing Keycloak

Keycloak serves the public endpoints and the Admin Console on the `http` port
(`8080`), or `https` (`8443`) with `tls.enabled`, through the Service
`<fullname>`. Health checks and metrics are served on the `management` port
(`9000`) by the separate Service `<fullname>-management`, which is always of
type `ClusterIP`, so a `LoadBalancer` or `NodePort` `service.type` never
publishes them. Never route the management port through an Ingress or a
Gateway.

### Reverse proxy

- **Edge termination** (default): the proxy terminates TLS and forwards plain
  HTTP to port `8080`.
- **Re-encrypt** (`tls.enabled`): the proxy terminates TLS and opens a new TLS
  connection to port `8443`. Configure the proxy for HTTPS to the backend, e.g.
  `nginx.ingress.kubernetes.io/backend-protocol: HTTPS`, or a `BackendTLSPolicy`
  for an HTTPRoute.

In both modes the proxy must **overwrite** the `X-Forwarded-*` headers
(`keycloak.proxyHeaders: xforwarded`) or the `Forwarded` header (`forwarded`).
Restrict `keycloak.proxyTrustedAddresses` to the proxy addresses where possible,
and use `networkPolicy.ingressFrom` so clients cannot bypass the proxy.

### Paths

Keycloak only needs these paths to be public
([reverse proxy guide](https://www.keycloak.org/server/reverseproxy)):

| Path | Public |
|------|--------|
| `/realms/` | Yes (`/realms/master/` only internally) |
| `/resources/` | Yes |
| `/.well-known/` | Yes |
| `/admin/` | Only internally |

Example HTTPRoute exposing only the public paths. Serve the Admin Console on an
internal hostname with `keycloak.hostnameAdmin`:

```yaml
httpRoute:
  enabled: true
  parentRefs:
    - name: public-gateway
      namespace: gateway
      sectionName: https
  hostnames:
    - sso.example.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /realms/
        - path:
            type: PathPrefix
            value: /resources/
        - path:
            type: PathPrefix
            value: /.well-known/
```

Requests to `/realms/master/` still match `/realms/`; block them with an
additional rule or at the Gateway if the `master` realm must not be public.

## Bootstrap admin

Keycloak creates the bootstrap admin user (`bootstrapAdmin.user`) and service
account client (`bootstrapAdmin.client`) in the `master` realm **only on its
first start**. Later changes to these values have no effect. The accounts are
marked as temporary: create permanent admin accounts and delete the temporary
ones afterwards.

The chart stores the usernames and inline or generated values in the Secret
`<fullname>-bootstrap-admin` with the keys `username`, `password`, `client-id`
and `client-secret`. Values from `secretKeyRef` stay in their Secret.

### Generated credentials

`bootstrapAdmin.user.password.generate` and
`bootstrapAdmin.client.clientSecret.generate` create random values on the first
install and keep them on upgrades by reading the existing Secret (`lookup`).
The Secret is annotated with `helm.sh/resource-policy: keep`, so that a
`helm uninstall` followed by an install against a kept database does not
replace the credentials. Note the consequences:

- The Secret outlives the release. If you also remove the database (an
  uninstall deletes the bundled CNPG cluster and, by default, its volumes), the
  kept credentials belong to an account that no longer exists. Delete the
  Secret manually before reinstalling, so that new credentials are generated.
- Reinstalling under the same release name and namespace adopts the Secret.
  Under another name that resolves to the same Secret name (e.g. with
  `fullnameOverride`), the install fails because the Secret already exists.

> **Only use `generate` with the Helm CLI or in CI.** Argo CD and
> `helm template` cannot read the existing Secret: every render produces new
> values, the application stays out of sync and the Secret no longer matches
> the account Keycloak created on its first start. With Argo CD, reference a
> Secret created by a generator instead, e.g. the External Secrets
> [`Password` generator](https://external-secrets.io/latest/api/generator/password/).

## Managing Keycloak with the edp-keycloak-operator

The chart does not depend on any operator. To manage realms, clients, users
and more declaratively with the
[edp-keycloak-operator](https://github.com/epam/edp-keycloak-operator),
install the operator separately and create a `Keycloak` resource pointing to
the internal Service. Let Keycloak resolve backchannel URLs from the request,
so token requests via the internal URL work:

```yaml
keycloak:
  hostname: https://sso.example.com
  hostnameBackchannelDynamic: true

bootstrapAdmin:
  client:
    enabled: true
    clientSecret:
      secretKeyRef:
        name: keycloak-operator-client
        key: client-secret
```

```yaml
apiVersion: v1.edp.epam.com/v1
kind: Keycloak
metadata:
  name: keycloak
spec:
  url: http://<fullname>.<namespace>.svc:8080
  auth:
    clientCredentials:
      clientId:
        value: temp-admin
      clientSecretRef:
        name: keycloak-operator-client
        key: client-secret
```

With `tls.enabled`, use `https://<fullname>.<namespace>.svc:8443` and set
`caCert` or `insecureSkipVerify`. For a password grant, use `auth.passwordGrant`
with the `username` and `password` keys of the bootstrap admin Secret.

The bootstrap accounts are temporary: create a permanent admin service account
(e.g. with the operator) and switch the `Keycloak` resource to it.

## High availability

Replicas form a cluster through the database (`jdbc-ping` stack, encrypted with
mTLS). No headless Service is required. The pods must reach each other on the
TCP ports `7800` and `57800`. For high availability:

- set `replicaCount` to 2 or more and spread the pods with
  `topologySpreadConstraints`,
- enable `podDisruptionBudget`,
- run 2 or more PostgreSQL instances (`postgres.instances`).

Keep `replicas * postgres.poolMaxSize` below the `max_connections` of the
database (CNPG default: `100`, raise it with `postgres.parameters`).

## Upgrades

Keycloak only supports rolling updates between **patch** releases of the same
minor version. Minor and major upgrades migrate the database schema, require
all nodes to be stopped and **cannot be rolled back**. The default
`strategy.type: Recreate` stops all pods before starting the new version.
`RollingUpdate` is only safe for configuration changes and patch upgrades.

Back up the database before a minor or major upgrade. Keycloak minor upgrades
are released as a minor version of this chart.

## Database

### Bundled CloudNativePG cluster

By default the chart creates the CNPG `Cluster` `<fullname>-postgresql` and
Keycloak connects to its read-write Service `<fullname>-postgresql-rw`.

The connection is encrypted and the server certificate is verified against the
CNPG CA (Secret `<fullname>-postgresql-ca`, `postgres.tls.mode: verify-server`).

The database password comes from, in this order:

1. `postgres.bootstrapSecretOverride`: an existing Secret with `username` and `password`,
2. `postgres.password.secretKeyRef`: an existing Secret with `username` and `password` (`key` must be `password`),
3. `postgres.password.value`: stored in the Secret `<fullname>-postgresql-credentials`,
4. otherwise the Secret `<fullname>-postgresql-app` generated by CloudNativePG.

The PostgreSQL major version is pinned by `postgres.image.tag`. Changing it
starts a CNPG major upgrade.

### External database

```yaml
postgres:
  enabled: false
  host: postgres.example.com
  database: keycloak
  username: keycloak
  password:
    secretKeyRef:
      name: keycloak-db
      key: password
  tls:
    mode: verify-server
    caSecretKeyRef:
      name: postgres-ca
      key: ca.crt
```

### Backups and recovery

Physical backups use the CNPG `ScheduledBackup`:

- `postgres.backup.method: plugin` stores base backups and the WAL archive in
  object storage through the Barman Cloud Plugin, which enables point-in-time
  recovery. The chart creates the `ObjectStore` from
  `postgres.backup.objectStore.configuration`.
- `postgres.backup.method: volumeSnapshot` uses CSI volume snapshots
  (`postgres.backup.volumeSnapshot.className`). Add an `ObjectStore`
  configuration to archive WAL files as well.

Example with S3-compatible storage:

```yaml
postgres:
  backup:
    enabled: true
    objectStore:
      configuration:
        destinationPath: s3://backups/keycloak
        endpointURL: https://s3.example.com
        s3Credentials:
          accessKeyId:
            name: keycloak-backup-s3
            key: ACCESS_KEY_ID
          secretAccessKey:
            name: keycloak-backup-s3
            key: ACCESS_SECRET_KEY
        wal:
          compression: gzip
```

To restore, the CNPG cluster must be created again: uninstall the release (or
delete the `Cluster` and its PVCs), then install with `postgres.recovery`
enabled. A WAL archive must start empty, so the restored cluster has to archive
into a new folder:

```yaml
postgres:
  backup:
    objectStore:
      # Folder the restored cluster archives to
      serverName: <fullname>-postgresql-2
  recovery:
    enabled: true
    # Folder of the backup to restore, defaults to <fullname>-postgresql
    serverName: <fullname>-postgresql
    # Optional point-in-time recovery
    recoveryTarget:
      targetTime: "2026-01-01 00:00:00+00"
```

Test the restore regularly.

## Network policy

`networkPolicy.enabled` restricts the ingress traffic of the Keycloak pods:

- the HTTP(S) port from `networkPolicy.ingressFrom` (all sources if empty),
- the cluster ports between Keycloak pods,
- the management port from `networkPolicy.managementFrom` only, e.g. Prometheus.

Kubelet probes are not affected with most network plugins.
`networkPolicy.egress.enabled` additionally restricts egress traffic to DNS,
the bundled database and the other Keycloak pods. Add identity providers, LDAP,
SMTP or an external database with `networkPolicy.egress.extraEgress`.

## Values

### Pod

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity rules for pod scheduling |
| extraEnv | object | `{}` | Additional environment variables as a map of variable name to value. Values are rendered with `tpl`. Also set in the build init container |
| extraEnvFrom | object | `{}` | Additional environment variables as a map of variable name to a Kubernetes `valueFrom` object, e.g. `MY_VAR: {secretKeyRef: {name: my-secret, key: my-key}}`. Use `KCRAW_*` names for secrets that may contain `$` |
| extraVolumeMounts | list | `[]` | Additional volume mounts of the Keycloak container |
| extraVolumes | list | `[]` | Additional volumes |
| initContainers | list | `[]` | Additional init containers, run before the theme and build init containers. With `build.mode: initContainer`, mount the volume `keycloak-home` to add providers (`providers/`) before the build. For themes, prefer `themes.custom` |
| livenessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/health/live","port":"management"},"periodSeconds":10,"timeoutSeconds":2}` | Liveness probe configuration. Empty disables the probe |
| nodeSelector | object | `{}` | Node selector for pod scheduling |
| podAnnotations | object | `{}` | Annotations to add to the pods |
| podLabels | object | `{}` | Labels to add to the pods |
| podSecurityContext | object | `{"fsGroup":1000,"fsGroupChangePolicy":"OnRootMismatch","runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | Pod-level security context |
| priorityClassName | string | `""` | Priority class name of the pods |
| readinessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/health/ready","port":"management"},"periodSeconds":10,"timeoutSeconds":2}` | Readiness probe configuration. Empty disables the probe |
| replicaCount | int | `1` | Number of Keycloak replicas. Replicas form a cluster through the database (`jdbc-ping`). Ignored when `autoscaling.enabled` is `true` |
| resources | object | `{"limits":{"memory":"1Gi"},"requests":{"cpu":"250m","memory":"1Gi"}}` | Resource requests and limits. Always set a memory limit: the JVM sizes its heap relative to it. Use at least `2Gi` for production |
| securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | Container-level security context of the Keycloak and build containers. `readOnlyRootFilesystem` is ignored (always `false`) with `build.mode: auto` |
| startupProbe | object | `{"failureThreshold":60,"httpGet":{"path":"/health/started","port":"management"},"periodSeconds":5,"timeoutSeconds":2}` | Startup probe configuration. Empty disables the probe. Paths of probes on the `management` port are prefixed with `keycloak.httpRelativePath` and the scheme follows `tls.enabled` |
| strategy | object | `{"type":"Recreate"}` | Deployment update strategy. `Recreate` stops all pods before starting the new version, which minor and major Keycloak upgrades require. `RollingUpdate` is only safe for configuration changes and patch upgrades with 2+ replicas |
| terminationGracePeriodSeconds | int | `30` | Grace period for the pod shutdown. Must be longer than Keycloak's `shutdown-delay` plus `shutdown-timeout` (default `1s` + `10s`) |
| tmpSizeLimit | string | `"256Mi"` | Size limit of the `emptyDir` mounted at `/tmp`. Empty for no limit |
| tolerations | list | `[]` | Tolerations for pod scheduling |
| topologySpreadConstraints | list | `[]` | Topology spread constraints, e.g. to spread replicas across nodes |

### Availability

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| autoscaling.behavior | object | `{}` | Scaling behavior of the HorizontalPodAutoscaler |
| autoscaling.enabled | bool | `false` | Create a HorizontalPodAutoscaler. Requires at least one of the two utilization targets |
| autoscaling.maxReplicas | int | `4` | Maximum number of replicas |
| autoscaling.minReplicas | int | `2` | Minimum number of replicas |
| autoscaling.targetCPUUtilizationPercentage | int | `80` | Target average CPU utilization in percent. Empty disables the CPU metric |
| autoscaling.targetMemoryUtilizationPercentage | string | `""` | Target average memory utilization in percent. Empty disables the memory metric |
| podDisruptionBudget.enabled | bool | `false` | Create a PodDisruptionBudget. Useful with 2+ replicas |
| podDisruptionBudget.maxUnavailable | int | `1` | Maximum number of unavailable pods, used if `minAvailable` is not set. `0` blocks voluntary evictions, which makes node drains wait until the pod is moved manually |
| podDisruptionBudget.minAvailable | string | `""` | Minimum number of available pods, e.g. `1`. Takes precedence over `maxUnavailable` if set. Empty is unset; `0` is a valid value |

### Bootstrap admin

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| bootstrapAdmin.client.clientId | string | `"temp-admin"` | Client ID of the temporary admin service account |
| bootstrapAdmin.client.clientSecret.generate | bool | `false` | Generate a random client secret on the first install and keep it on upgrades (via `lookup`). Only for the Helm CLI or CI: Argo CD and `helm template` generate a new value on every render |
| bootstrapAdmin.client.clientSecret.secretKeyRef.key | string | `""` | Key within the Secret |
| bootstrapAdmin.client.clientSecret.secretKeyRef.name | string | `""` | Name of an existing Secret |
| bootstrapAdmin.client.clientSecret.value | string | `""` | Plain-text value, stored in a chart-managed Secret. Ignored if `secretKeyRef.name` is set. Prefer `secretKeyRef` |
| bootstrapAdmin.client.enabled | bool | `false` | Create a temporary admin service account client (`KC_BOOTSTRAP_ADMIN_CLIENT_ID` and `_SECRET`) for the client credentials grant |
| bootstrapAdmin.user.enabled | bool | `true` | Create a temporary admin user (`KC_BOOTSTRAP_ADMIN_USERNAME` and `_PASSWORD`) |
| bootstrapAdmin.user.password.generate | bool | `false` | Generate a random password on the first install and keep it on upgrades (via `lookup`). Only for the Helm CLI or CI: Argo CD and `helm template` generate a new value on every render |
| bootstrapAdmin.user.password.secretKeyRef.key | string | `""` | Key within the Secret |
| bootstrapAdmin.user.password.secretKeyRef.name | string | `""` | Name of an existing Secret |
| bootstrapAdmin.user.password.value | string | `""` | Plain-text value, stored in a chart-managed Secret. Ignored if `secretKeyRef.name` is set. Prefer `secretKeyRef` |
| bootstrapAdmin.user.username | string | `"admin"` | Username of the temporary admin user |

### Build

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| build.mode | string | `"initContainer"` | How the optimized Keycloak build is created. `initContainer`: an init container copies the Keycloak distribution of `image` into an `emptyDir`, runs `kc.sh build` with the chart's build options and Keycloak starts with `--optimized` from there. Works with the stock image and a read-only root filesystem. `prebuilt`: `image` already contains an optimized build whose build options match the chart's values, Keycloak starts with `--optimized`. `auto`: Keycloak starts without `--optimized` and rebuilds itself on start when build options differ, which needs a writable root filesystem |
| build.resources | object | `{"limits":{"memory":"1Gi"},"requests":{"cpu":"250m","memory":"512Mi"}}` | Resource requests and limits of the build init container. The build runs a JVM, which sizes its heap relative to the memory limit |
| build.sizeLimit | string | `"1Gi"` | Size limit of the `emptyDir` holding the Keycloak distribution (about 200Mi) and the Keycloak data directory. Only used with `mode: initContainer` |

### Other

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| extraManifests | list | `[]` | Extra Kubernetes manifests to deploy alongside the chart. Each entry is rendered with `tpl` |

### Global

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| fullnameOverride | string | `""` | Override the full resource name |
| nameOverride | string | `""` | Override the chart name |

### Gateway API

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| httpRoute.annotations | object | `{}` | Annotations to add to the HTTPRoute |
| httpRoute.enabled | bool | `false` | Create a Gateway API HTTPRoute. With `tls.enabled`, a `BackendTLSPolicy` is needed for HTTPS to the backend |
| httpRoute.hostnames | list | `["chart-example.local"]` | Hostnames matched by the HTTPRoute |
| httpRoute.parentRefs | list | `[{"name":"gateway","sectionName":"http"}]` | Gateways the HTTPRoute attaches to |
| httpRoute.rules | list | `[{"matches":[{"path":{"type":"PathPrefix","value":"/"}}]}]` | HTTPRoute rules. Each rule supports `matches`, `filters` and `timeouts`; the backend is always the Keycloak Service |

### Image

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.repository | string | `"quay.io/keycloak/keycloak"` | Keycloak image repository |
| image.tag | string | `""` | Image tag. Defaults to the chart's `appVersion` if not set. The chart requires Keycloak 26.6 or newer (`KCRAW_` environment variables); this is only checked for plain `X.Y.Z` tags of the official image |
| imagePullSecrets | list | `[]` | Secrets for pulling images from a private registry |

### Ingress

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| ingress.annotations | object | `{}` | Annotations to add to the Ingress. With `tls.enabled`, configure the controller to use HTTPS to the backend (e.g. `nginx.ingress.kubernetes.io/backend-protocol: HTTPS`) |
| ingress.className | string | `""` | Ingress class name |
| ingress.enabled | bool | `false` | Create an Ingress |
| ingress.hosts | list | `[{"host":"chart-example.local","paths":[{"path":"/","pathType":"Prefix"}]}]` | Ingress hosts and paths |
| ingress.tls | list | `[]` | Ingress TLS configuration |

### Keycloak

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| keycloak.config | object | `{"spi-sticky-session-encoder--infinispan--should-attach-route":"false"}` | Additional Keycloak options as a map of option name to value, rendered as `KC_*` environment variables in a ConfigMap, e.g. `http-max-queued-requests: 1000`. See [all configuration](https://www.keycloak.org/server/all-config). Do not put secrets here; use `extraEnvFrom`. The default disables the deprecated sticky session route |
| keycloak.features | list | `[]` | Features to enable (`KC_FEATURES`, a build option), e.g. `token-exchange` |
| keycloak.featuresDisabled | list | `[]` | Features to disable (`KC_FEATURES_DISABLED`, a build option) |
| keycloak.hostname | string | `""` | Public address of Keycloak (`KC_HOSTNAME`), preferably a full URL such as `https://sso.example.com`. Required unless `hostnameStrict` is `false` |
| keycloak.hostnameAdmin | string | `""` | Address of the Admin Console (`KC_HOSTNAME_ADMIN`), e.g. an internal-only URL. Empty serves it on `hostname` |
| keycloak.hostnameBackchannelDynamic | bool | `false` | Resolve backchannel URLs (token, userinfo, ...) from the request (`KC_HOSTNAME_BACKCHANNEL_DYNAMIC`). Enable when clients, e.g. the edp-keycloak-operator, reach Keycloak via the internal Service URL. Requires `hostname` to be a full URL |
| keycloak.hostnameStrict | bool | `true` | Only accept the configured `hostname` (`KC_HOSTNAME_STRICT`). Set to `false` only if the proxy overwrites the `Host` header |
| keycloak.httpRelativePath | string | `""` | Path Keycloak serves its resources under (`KC_HTTP_RELATIVE_PATH`, a build option), e.g. `/auth`. Empty serves them under `/`. The management interface and the probes inherit it |
| keycloak.javaOptsAppend | string | `""` | Additional JVM options (`JAVA_OPTS_APPEND`), e.g. `-Djava.net.preferIPv4Stack=true` |
| keycloak.javaOptsHeap | string | `""` | JVM heap options (`JAVA_OPTS_KC_HEAP`). Empty uses the image default, which sizes the heap relative to the container memory limit (`-XX:MaxRAMPercentage=70 -XX:InitialRAMPercentage=50`) |
| keycloak.logConsoleOutput | string | `"default"` | Console log format (`KC_LOG_CONSOLE_OUTPUT`): `default` or `json` |
| keycloak.logLevel | string | `"info"` | Log level (`KC_LOG_LEVEL`), e.g. `info` or `info,org.keycloak:debug` |
| keycloak.metricsEnabled | bool | `false` | Expose Prometheus metrics on the management port under `/metrics` (`KC_METRICS_ENABLED`, a build option). Also enables the database health check |
| keycloak.proxyHeaders | string | `"xforwarded"` | Reverse proxy headers Keycloak trusts (`KC_PROXY_HEADERS`): `xforwarded`, `forwarded` or empty. The proxy must overwrite these headers. Must be empty with TLS passthrough |
| keycloak.proxyTrustedAddresses | list | `[]` | IP addresses or CIDRs of the proxies whose headers are trusted (`KC_PROXY_TRUSTED_ADDRESSES`). Empty trusts all addresses |

### Network policy

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| networkPolicy.egress.enabled | bool | `false` | Restrict egress traffic. Allows DNS, the bundled database, the Keycloak cluster traffic and `extraEgress` |
| networkPolicy.egress.extraEgress | list | `[]` | Additional egress rules, e.g. for an external database, identity providers, LDAP or SMTP |
| networkPolicy.enabled | bool | `false` | Create a NetworkPolicy for the Keycloak pods. It always allows the cluster traffic (ports 7800 and 57800) between Keycloak pods |
| networkPolicy.ingressFrom | list | `[]` | Peers allowed to reach the HTTP(S) port, in the NetworkPolicy `from` format, e.g. the namespace of the Ingress controller. Empty allows all sources |
| networkPolicy.managementFrom | list | `[]` | Peers allowed to reach the management port (health, metrics), e.g. Prometheus. Empty allows no source besides the Keycloak pods |

### PostgreSQL

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| postgres.affinity | object | `{}` | Scheduling of the PostgreSQL instances in the CNPG `AffinityConfiguration` format (`nodeSelector`, `tolerations`, `enablePodAntiAffinity`, `topologyKey`, `nodeAffinity`, ...). See the [CNPG docs](https://cloudnative-pg.io/docs/1.30/scheduling) |
| postgres.annotations | object | `{}` | Annotations to add to the CNPG Cluster |
| postgres.backup.enabled | bool | `false` | Enable scheduled physical backups of the CNPG cluster (`ScheduledBackup`). Requires the [Barman Cloud Plugin](https://cloudnative-pg.io/plugin-barman-cloud/) for `method: plugin`, or CSI volume snapshots for `method: volumeSnapshot` |
| postgres.backup.immediate | bool | `false` | Take a backup immediately when the `ScheduledBackup` is created |
| postgres.backup.method | string | `"plugin"` | Backup method: `plugin` (Barman Cloud Plugin, object storage) or `volumeSnapshot` (Kubernetes CSI volume snapshots) |
| postgres.backup.objectStore.configuration | object | `{}` | `ObjectStore` configuration (`destinationPath`, `endpointURL`, `s3Credentials`, `wal`, `data`, ...). See the [plugin docs](https://cloudnative-pg.io/plugin-barman-cloud/docs/object_stores/). When set, WAL archiving is enabled even with `method: volumeSnapshot` |
| postgres.backup.objectStore.create | bool | `true` | Create a Barman Cloud `ObjectStore` named `<fullname>-postgresql` from `configuration`. Set to `false` to reference an existing one via `name` |
| postgres.backup.objectStore.instanceSidecarConfiguration | object | `{}` | Barman Cloud sidecar settings of the `ObjectStore` (e.g. `resources`) |
| postgres.backup.objectStore.name | string | `""` | Name of an existing `ObjectStore`. Only used when `create` is `false` |
| postgres.backup.objectStore.retentionPolicy | string | `"30d"` | Recovery window of the backups in the `ObjectStore` (e.g. `30d`) |
| postgres.backup.objectStore.serverName | string | `""` | Folder name of this cluster inside the object store. Defaults to the Cluster name. Must differ from `recovery.serverName` when restoring from the same object store |
| postgres.backup.schedule | string | `"0 0 3 * * *"` | Backup schedule as a six-field cron expression including seconds (e.g. `0 0 3 * * *` = daily at 03:00) |
| postgres.backup.target | string | `""` | Instance to back up from: `prefer-standby` or `primary`. Empty uses the CNPG default (`prefer-standby`) |
| postgres.backup.volumeSnapshot | object | `{}` | CNPG `volumeSnapshot` backup configuration (e.g. `className`). Only used with `method: volumeSnapshot` |
| postgres.bootstrapSecretOverride | string | `""` | Name of an existing Secret of type `kubernetes.io/basic-auth` with `username` and `password` keys, used to bootstrap the CNPG cluster and as the Keycloak database password. Takes precedence over `password` |
| postgres.database | string | `"keycloak"` | Name of the Keycloak database |
| postgres.enablePDB | bool | `true` | Create the PodDisruptionBudgets of the CNPG cluster (`enablePDB`). With a single instance, they block node drains until the instance is moved manually |
| postgres.enabled | bool | `true` | Deploy a CloudNativePG `Cluster`. Set to `false` to use an external database |
| postgres.host | string | `""` | Host of an external database. Required when `enabled` is `false` |
| postgres.image.repository | string | `"ghcr.io/cloudnative-pg/postgresql"` | PostgreSQL image repository of the CNPG cluster instances |
| postgres.image.tag | string | `"18.6-standard-trixie"` | PostgreSQL image tag. Keycloak supports PostgreSQL 14 to 18. Changing the major version triggers a CNPG major upgrade |
| postgres.initdb | object | `{}` | Additional fields of the CNPG `bootstrap.initdb` section, e.g. `localeCollate`, `localeCType` or `postInitApplicationSQL`. `database`, `owner` and `secret` are set by the chart |
| postgres.instances | int | `1` | Number of PostgreSQL instances in the CNPG cluster. Use 2+ for high availability |
| postgres.parameters | object | `{}` | PostgreSQL parameters (`postgresql.parameters` of the Cluster), e.g. `max_connections: "200"` |
| postgres.password | object | `{"secretKeyRef":{"key":"","name":""},"value":""}` | PostgreSQL password of `username`. If no source is set and `enabled` is `true`, CloudNativePG generates a random password in the `<fullname>-postgresql-app` Secret. Required when `enabled` is `false` |
| postgres.password.secretKeyRef.key | string | `""` | Key within the Secret |
| postgres.password.secretKeyRef.name | string | `""` | Name of an existing Secret. With the bundled cluster, the Secret also bootstraps the database: it must be of type `kubernetes.io/basic-auth` with the keys `username` (equal to `username`) and `password`, so `key` must be `password` |
| postgres.password.value | string | `""` | Plain-text value, stored in a chart-managed Secret. Ignored if `secretKeyRef.name` is set. Prefer `secretKeyRef` |
| postgres.podMonitor.enabled | bool | `false` | Create a Prometheus Operator PodMonitor for the PostgreSQL instances (replaces the deprecated CNPG `enablePodMonitor`) |
| postgres.podMonitor.labels | object | `{}` | Extra labels to add to the PodMonitor |
| postgres.podSecurityContext | object | `{}` | Pod-level security context of the PostgreSQL instances. Empty applies the CloudNativePG defaults (UID/GID `26`) |
| postgres.poolMaxSize | int | `50` | Maximum size of the Keycloak connection pool per replica (`KC_DB_POOL_MAX_SIZE`). Keep `replicas * poolMaxSize` below the `max_connections` of the database |
| postgres.port | int | `5432` | Port of an external database. Only used when `enabled` is `false` |
| postgres.recovery.enabled | bool | `false` | Bootstrap the CNPG cluster from a backup instead of an empty database. Only applies when the Cluster is created |
| postgres.recovery.objectStoreName | string | `""` | Barman Cloud `ObjectStore` holding the backup. Defaults to the backup object store |
| postgres.recovery.recoveryTarget | object | `{}` | Point-in-time recovery target in the CNPG `recoveryTarget` format (e.g. `targetTime: "2026-01-01 00:00:00+00"`). Empty restores the latest state |
| postgres.recovery.serverName | string | `""` | Folder name of the source cluster inside the object store. Defaults to the Cluster name |
| postgres.recovery.volumeSnapshots | object | `{}` | Recover from CSI volume snapshots instead of an object store, in the CNPG `bootstrap.recovery.volumeSnapshots` format |
| postgres.resources | object | `{"limits":{"memory":"1Gi"},"requests":{"cpu":"100m","memory":"256Mi"}}` | Resource requests and limits of the PostgreSQL instances |
| postgres.securityContext | object | `{}` | Container-level security context of the PostgreSQL instance container. Merged with the CloudNativePG defaults |
| postgres.storage.size | string | `"10Gi"` | Size of the PostgreSQL PVC |
| postgres.storage.storageClass | string | `""` | Storage class of the PostgreSQL PVCs. Empty uses the cluster's default StorageClass |
| postgres.tls.caSecretKeyRef.key | string | `""` | Key within the Secret. Defaults to `ca.crt` |
| postgres.tls.caSecretKeyRef.name | string | `""` | Name of the Secret with the CA certificate (PEM) of the database server. Defaults to the CNPG CA Secret `<fullname>-postgresql-ca` with the bundled cluster. Required for `verify-server` with an external database |
| postgres.tls.mode | string | `""` | TLS mode of the database connection (`KC_DB_TLS_MODE`): `disabled` (driver default, encrypts if the server offers TLS without verifying it) or `verify-server` (requires TLS and verifies the server certificate). Empty uses `verify-server` with the bundled cluster and `disabled` with an external database |
| postgres.urlProperties | string | `""` | Additional JDBC URL properties (`KC_DB_URL_PROPERTIES`), including the leading `?`, e.g. `?ApplicationName=keycloak` |
| postgres.username | string | `"keycloak"` | Name of the database role Keycloak uses (`KC_DB_USERNAME`). Owns the database in the CNPG cluster |

### Service

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| service.annotations | object | `{}` | Annotations to add to the Service |
| service.httpsPort | int | `8443` | HTTPS port of the Service. Only exposed with `tls.enabled` |
| service.managementPort | int | `9000` | Management port (health and metrics). It is served by the separate `<fullname>-management` Service, which is always of type `ClusterIP`. Never route it through an Ingress or a Gateway |
| service.port | int | `8080` | HTTP port of the Service. Only exposed when HTTP is enabled |
| service.type | string | `"ClusterIP"` | Service type |

### Service account

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.automount | bool | `false` | Automatically mount the service account token. Keycloak does not need the Kubernetes API |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | Name of the service account to use. If not set and `create` is `true`, a name is generated using the fullname template |

### Monitoring

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| serviceMonitor.annotations | object | `{}` | Annotations to add to the ServiceMonitor |
| serviceMonitor.enabled | bool | `false` | Create a Prometheus Operator ServiceMonitor for the management port. Requires `keycloak.metricsEnabled` |
| serviceMonitor.honorLabels | bool | `false` | Keep the labels of the scraped metrics over the server-side labels |
| serviceMonitor.interval | string | `"30s"` | Scrape interval |
| serviceMonitor.labels | object | `{}` | Extra labels to add to the ServiceMonitor |
| serviceMonitor.scrapeTimeout | string | `"10s"` | Scrape timeout |

### Themes

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| themes.cache | bool | `true` | Cache themes, templates and static resources. Set to `false` only while developing a theme |
| themes.custom | list | `[]` | Custom themes. Each entry needs a `name` and one source: `image` (copied by an init container, or mounted as an ImageVolume with `imageVolume: true`) or `configMap` (directory themes only). `type` is `directory` (default, mounted at `themes/<name>`) or `jar` (a theme archive such as Keycloakify output, added as `providers/<name>.jar`; not with `build.mode: prebuilt`). `path` is the theme location in the image, default `/theme` or `/theme.jar`. `image.repository` and `image.tag` are rendered with `tpl` |
| themes.initContainerResources | object | `{"limits":{"memory":"64Mi"},"requests":{"cpu":"10m","memory":"16Mi"}}` | Resource requests and limits of the init containers copying themes from images |
| themes.sizeLimit | string | `"512Mi"` | Size limit of the `emptyDir` the theme init containers copy into. Empty for no limit |
| themes.welcomeTheme | string | `""` | Theme of the welcome page (`spi-theme--welcome-theme`). Empty uses the default theme |

### TLS

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| tls.enabled | bool | `false` | Serve HTTPS on port 8443 with the certificate from `secretName`. The management interface (health, metrics) then uses HTTPS as well |
| tls.httpEnabled | bool | `false` | Keep the plain HTTP listener on port 8080 in addition to HTTPS |
| tls.secretName | string | `""` | Name of an existing `kubernetes.io/tls` Secret with `tls.crt` and `tls.key`, e.g. issued by cert-manager. Keycloak reloads it periodically |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
