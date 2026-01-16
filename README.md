# Deployment Workflows

Reusable GitHub Actions workflows for building, packaging, and deploying containers.

## Workflows

- [**docker-build-push.yml**](./.github/workflows/docker-build-push.yml): Build and push multi-arch Docker images to GHCR
- [**helm-chart-push.yml**](./.github/workflows/helm-chart-push.yml): Package and push Helm charts to OCI registry
- [**helm-install.yml**](./.github/workflows/helm-install.yml): Deploy applications to Kubernetes using Helm

## Usage

Reference these workflows in your repository:

```yaml
jobs:
  build:
    uses: pauloo27/deployment-workflows/.github/workflows/docker-build-push.yml@main
    with:
      # ... inputs
```
