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

4. **Open a Pull Request** against `main`. Use a [Conventional Commits](https://www.conventionalcommits.org/) title; if a related issue exists, append it, e.g. `(#123)`. The CI pipeline lints and installs all changed charts. Do not bump `version`. For branches in this repository, CI regenerates the chart `README.md` in the pull request and may push a `docs:` commit to your branch, so pull before pushing again; for forks this happens after the merge. After the merge, CI on `main` bumps the chart version from the commit messages since the chart's last release (major for `!` or `BREAKING CHANGE`, minor for `feat`, otherwise patch) and releases the chart. Commits of pull requests land on `main` as they are, so every commit message counts. A `version` set by hand in `Chart.yaml` is released as is. A chart that depends on a new version of a sibling chart can only be updated once that sibling is released.

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

To preview the generated `README.md` locally, run:

```bash
helm-docs
```

## License

Apache 2.0
