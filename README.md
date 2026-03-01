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

**1. Install Helm 3** (if not installed):
```bash
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

**2. Lint a chart:**
```bash
helm lint charts/<chart-name>
```

**3. Render templates:**
```bash
helm template charts/<chart-name> --values charts/<chart-name>/values.yaml
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

3. **Bump the chart version** in `Chart.yaml` according to [SemVer](https://semver.org/):
   - Patch (`0.1.x`) – bug fixes
   - Minor (`0.x.0`) – new features, backwards compatible
   - Major (`x.0.0`) – breaking changes

4. **Lint your chart** before opening a PR:
   ```bash
   helm lint charts/<chart-name>
   ```

5. **Open a Pull Request** against `main`. The CI pipeline will automatically lint and test all changed charts.

### Commit Style

Please use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(odoo): add init container for database initialization
fix(postgres): correct readiness probe user reference
docs(readme): update contributing guide
```

### Chart Documentation

All `values.yaml` parameters should be documented with `helm-docs`-style comments:

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
