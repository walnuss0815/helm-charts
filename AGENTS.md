# Repository Guidance for AI Agents

## Core Mission
This repository contains a collection of Helm charts for various containerized applications. All charts are designed with a GitOps-first approach (specifically optimized for ArgoCD).

## 1. Chart Creation Protocol
- **Foundation:** All new Helm charts **must** be generated using the default Helm starter template (`helm create <chart-name>`). Do not use custom starters or write templates from scratch unless absolutely necessary.
- **Modifications:** Modify the default starter templates only to add necessary features or fix GitOps-related issues. Keep the standard Helm structure intact.

## 2. GitOps & ArgoCD Compatibility
- **Deterministic Output:** Templates must render deterministically. Avoid using functions like `randAlphaNum` for critical resources (like passwords or secrets) as this causes ArgoCD to continuously report the app as "Out of Sync".
- **Namespaces:** Do not hardcode `namespace:` inside the templates. Allow ArgoCD to manage the namespace injection during deployment.
- **Hooks:** Use Helm hooks (`helm.sh/hook`) sparingly and carefully, as they can sometimes conflict with ArgoCD's lifecycle management. Prefer ArgoCD sync phases/waves if deployment ordering is required.

## 3. Sensible Defaults
- The `values.yaml` file must contain **only sensible defaults**. 
- **Security:** Run as non-root by default if the application allows it. 
- **Resources:** Provide minimal, sensible resource requests/limits.
- **Toggles:** Components like Ingress, PersistentVolumeClaims (PVCs), and ServiceMonitors should exist in the templates but must be set to `enabled: false` by default.

## 4. Best Practices & Compatibility
- **Kubernetes Support:** Charts must be compatible with the **last 3 minor versions** of Kubernetes.
- **API Versions:** Always use up-to-date Kubernetes API versions. Avoid deprecated APIs (e.g., ensure Ingress uses `networking.k8s.io/v1`). 
- **Linting:** Act as if `helm lint --strict` is always enforced. Ensure all templates render valid YAML and standard labels are applied consistently.

## 5. Documentation Standard (`helm-docs`)
- **Format:** The `values.yaml` file **must** be documented using the [helm-docs](https://github.com/norwoodj/helm-docs) format.
- **Comments:** Use standard `helm-docs` comment blocks (e.g., `## @param`, `## @extra`) above configuration blocks so that README files can be automatically generated.
- **Clarity:** Keep descriptions concise but highly informative, explaining what the value does and providing examples for complex objects.

## 6. Branch Naming and Commit Messages
- **Branch Naming:** Always use the [conventional branch](https://conventional-branch.github.io/#specification) specification for naming branches in Git.
- **Commit Messages:** Always use the [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/#specification) specification for writing Git commit messages.
- **Pull Request/Merge Request Titles:** Always use the [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/#specification) specification for Pull Request/merge Requests titles. The related issue must be added to the end of the title in braces and prefixed with a hashtag.

---

### Agent Instructions summary:

Whenever you are asked to create, modify, or review a chart in this repository, strictly adhere to the GitOps principles above, ensure `helm-docs` comments are updated, and verify that you are building on top of the standard `helm create` output.
