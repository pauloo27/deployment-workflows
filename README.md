# Deployment Workflows

Reusable GitHub Actions workflows for building Docker images, packaging Helm 
charts, and deploying applications to Kubernetes. This repository provides 
CI/CD automation as shared workflows that can be called from other repositories.

## Infrastructure

Terraform configuration for provisioning the AWS infrastructure (VPC, EC2 
k3s cluster, VPN) is located in the `infra/` directory. See 
[infra/README.md](infra/README.md) for setup instructions.

## How It Works

This repository contains three reusable workflows:

1. **docker-build-push.yml** - Builds multi-architecture (amd64/arm64) Docker
images, then creates a multi-arch manifest and pushes to GitHub 
Container Registry (GHCR)

2. **helm-chart-push.yml** - Packages a Helm chart and pushes it to an 
OCI-compatible registry (GHCR by default)

3. **helm-install.yml** - Deploys applications to Kubernetes via Helm over 
a VPN connection. Connects to OpenVPN, configures kubectl, 
and runs `helm upgrade --install`

All workflows use `workflow_call` triggers, making them reusable across multiple 
repositories.

## Configuration

### Docker Build & Push

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `image` | Yes | - | Full image name (e.g., `ghcr.io/org/app`) |
| `tag` | No | `latest` | Image tag |
| `dockerfile` | No | `./Dockerfile` | Path to Dockerfile |
| `context` | No | `.` | Build context directory |

### Helm Chart Push

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `chart_path` | Yes | - | Path to Helm chart directory |
| `chart_name` | Yes | - | Helm chart name |
| `version` | Yes | - | Chart version |
| `registry` | No | `ghcr.io` | OCI registry URL |
| `repository` | Yes | - | Repository name (e.g., `org/chart-name`) |

### Helm Install

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `release_name` | Yes | - | Helm release name |
| `chart` | Yes | - | Chart reference (e.g., `oci://ghcr.io/org/chart:version`) |
| `namespace` | Yes | - | Kubernetes namespace |
| `image_tag` | Yes | - | Docker image tag to deploy |
| `values_file` | Yes | - | Path to values file |

| Secret | Required | Description |
|--------|----------|-------------|
| `kubeconfig` | Yes | Kubeconfig file content for K8s cluster access |
| `openvpn_config` | Yes | OpenVPN configuration file content (.ovpn) |

## How to Use

Reference these workflows from your repository's `.github/workflows` directory
using the `uses` keyword. Provide the required inputs (see Configuration section
above) and any necessary secrets.

```yaml
jobs:
  your-job:
    uses: pauloo27/deployment-workflows/.github/workflows/<workflow-name>.yml@main
    with:
      # See Configuration section above for required and optional inputs
    secrets:
      # Required secrets (if applicable to the workflow)
```

## Integration with Other Repos

### Used in

**sample-java-api**
- Uses `docker-build-push.yml` to build the Docker image and push it to GHCR
- Uses `helm-install.yml` to deploy the application to Kubernetes using the
  Helm chart from helm-charts repo

**helm-charts**
- Uses `helm-chart-push.yml` to package and push Helm charts to GHCR, which
  are then consumed by sample-java-api during deployment

## Assumptions and Shortcuts

- **Multi-arch builds**: Builds for both amd64 and arm64 to ensure broader
  compatibility. Uses GitHub's native arm64 runners (`ubuntu-22.04-arm`)
- **Registry**: Assumes GitHub Container Registry (GHCR). Other registries
  would need authentication adjustments
- **VPN requirement**: Kubernetes cluster is not publicly accessible - requires
  OpenVPN connection before deployment
- **Existing actions**: Uses community and official GitHub Actions (Docker,
  Azure Helm/K8s, OpenVPN) for simplicity rather than custom scripts
