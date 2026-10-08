# ⎈ Helm Charts

A collection of Helm Charts for self-hosted applications on Kubernetes.
Charts live in the `charts/` directory and are published via GitHub Pages.

## Repository

```bash
helm repo add walnuss0815 https://walnuss0815.github.io/helm-charts
helm repo update
helm search repo walnuss0815
```

## Local Development

**1. Get the tools.** With [Nix](https://nixos.org) and [direnv](https://direnv.net), `direnv allow` (or `nix develop`) provides `helm`, `kubectl`, `ct`, `helm-docs` and `yq`. Otherwise install [Helm](https://helm.sh/docs/intro/install/), [chart-testing](https://github.com/helm/chart-testing) and [helm-docs](https://github.com/norwoodj/helm-docs) yourself.

**2. Lint a chart** the same way CI does:
```bash
helm lint --strict charts/<chart-name>
ct lint --config ct.yaml --charts charts/<chart-name>
```

**3. Render templates:**
```bash
helm template charts/<chart-name>
```

**4. Package a chart:**
```bash
helm package charts/<chart-name>
# creates <chart-name>-<version>.tgz
```

## Contributing

Contributions are welcome! Please follow these steps:

### Adding or Modifying a Chart

1. **Fork** the repository and create a new branch:
   ```bash
   git checkout -b feat/my-chart
   ```

2. **Make your changes** in the `charts/` directory. Each chart must have:
   - `Chart.yaml` – with `name`, `version`, `appVersion` and `description`
   - `values.yaml` – with documented default values (using `helm-docs` `# --` comments)
   - `templates/` – Kubernetes manifests

3. **Lint your chart** before opening a PR:
   ```bash
   helm lint --strict charts/<chart-name>
   ```

4. **Open a Pull Request** against `main`. Use a [Conventional Commits](https://www.conventionalcommits.org/) title; if a related issue exists, append it, e.g. `(#123)`. The CI pipeline lints and installs all changed charts, regenerates their `README.md` and bumps the chart version. Do not bump `version` yourself.

### Commit Style

Please use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(odoo): add init container for database initialization
fix(postgres): correct readiness probe user reference
docs(readme): update contributing guide
```

### Chart Documentation

All `values.yaml` parameters must be documented with [`helm-docs`-style](https://github.com/norwoodj/helm-docs) comments:

```yaml
# -- Number of replicas for the deployment
replicaCount: 1
```

Regenerate docs after changes:

```bash
helm-docs
```

## License

Apache 2.0
