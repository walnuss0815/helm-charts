# Helm Charts

Repository for Helm Charts. Charts live in the `charts/` directory.

Structure:
- `charts/` — Helm charts (each chart in its own subdirectory)
- `.github/workflows/ci.yaml` — CI that lints and tests charts
- `.github/workflows/release.yaml` — Releases packaged charts on tag (v*)

Quickstart (locally):

1. Install Helm 3 (if not installed):
```bash
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

1. Lint a chart:
```bash
helm lint charts/<chart-name>
```

1. Render templates:
```bash
helm template charts/<chart-name> --values charts/<chart-name>/values.yaml
```

1. Package a chart:
```bash
helm package charts/<chart-name>
# packages created as <chart-name>-<version>.tgz
```
