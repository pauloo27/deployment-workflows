# Tech Challenge Summary

## Architecture Overview

The solution consists of five main components:

1. **Sample Java API** - Spring Boot application with a single `/health` endpoint
2. **K3s Cluster** - Lightweight Kubernetes cluster running on AWS EC2
  (ARM-based for efficiency and cost savings), provisioned with modular Terraform
3. **AWS Client VPN** - Managed VPN service securing access to the Kubernetes
  API (no public exposure)
4. **GitHub Container Registry (GHCR)** - Stores both Docker images and Helm
  charts as OCI artifacts
5. **GitHub Actions** - Reusable workflows for build, package, and deployment
  automation

## CI/CD Flow

### Trigger
- **PR checks**: Pull requests trigger Gradle build and test validation
- **Automatic deployment**: Push to `main` branch in `sample-java-api` repository
- **Manual promotion**: `workflow_dispatch` for promoting specific tags to production

### Step-by-Step Flow

1. **Build** (`sample-java-api` repository)
   - Gradle compiles and tests the Spring Boot application
   - Multi-stage Dockerfile builds runtime image with JRE 25

2. **Package** (calls `deployment-workflows/docker-build-push.yml`)
   - Builds Docker image for both amd64 and arm64 architectures
   - Tags image with first 7 characters of commit SHA (e.g., `abc1234`)
   - Pushes multi-arch manifest to `ghcr.io/pauloo27/sample-java-api`

3. **Deploy** (calls `deployment-workflows/helm-install.yml`)
   - Connects to EC2 VPC via OpenVPN
   - Pulls Helm chart from `ghcr.io/pauloo27/helm-charts/sample-java-api`
   - Runs `helm upgrade --install` with environment-specific values:
     - **Dev**: namespace `dev`, port 8080, 512Mi memory limit
     - **Prod**: namespace `prod`, port 8000, 1Gi memory limit
   - Health probes verify deployment success

### Repository Responsibilities

| Repository | Responsibility |
|------------|----------------|
| `sample-java-api` | Application code, Dockerfile, environment values files, CI/CD workflows |
| `helm-charts` | Helm chart templates and default values |
| `deployment-workflows` | Reusable GitHub Actions workflows (build, package, deploy) and Terraform infrastructure |

## Security Considerations

### Cluster Access Control
- **No public Kubernetes API**: K3s API server is only accessible within the VPC
- **VPN-only access**: All kubectl/Lens connections require active OpenVPN connection
- **Security group restrictions**: Only VPN subnet can access K3s API port (6443)

### Secrets Management
- **GitHub Secrets**: All sensitive data (kubeconfig, VPN config, registry tokens)
  stored as repository secrets
- **No committed credentials**: Zero secrets in Git history

### Network Security
- **Private VPC**: EC2 instance in dedicated VPC (10.0.0.0/16)
- **VPN subnet**: Separate subnet (10.8.0.0/24) for VPN client connections

## Reviewer Verification Guide

### 1. Connect to VPN

Use the provided OpenVPN configuration file:

```bash
sudo openvpn --config tech-challenge.ovpn
```

**Verify connection:**
```bash
# In a new terminal, check you received a 10.8.0.x IP
ip addr show tun0
```

### 2. Import kubeconfig into Lens

1. Open FreeLens
2. Click **File** → **Add Cluster**
3. Paste/load the provided file: `tech-challenge-k8s.yaml`
4. Click **Add Cluster**

### 3. Verify Workloads

Select to the `dev` namespace in FreeLens and verify:
- **Deployment**: `sample-java-api` (1/1 ready)
- **Pod**: `sample-java-api-xxxxxxxxxx-xxxxx` (Running)
- **Service**: `sample-java-api` (ClusterIP, port 8080)

Check pod logs in FreeLens to see Spring Boot startup logs indicating successful
deployment.

### 4. Test /health Endpoint

In FreeLens, find the `sample-java-api` service in the `dev` namespace and use 
the UI to port-forward port `8080` to your local machine.

Then test:
```bash
curl http://localhost:8080/health
```

**Expected response:**
```json
{"status":"UP"}
```

## Assumptions and Trade-offs

### Infrastructure Choices

- **K3s over EKS**: Cost-effective for demo purposes
- **Single-node cluster**: No high availability, acceptable for non-production demo
- **T3a.small instance**: Minimal specs, sufficient for simple workload
- **Modular Terraform**: Production-grade IaC with reusable modules (VPC, subnets, 
security groups, etc.) instead of single file

### CI/CD Decisions

- **Commit SHA tagging**: Simpler than semantic versioning for demo purposes
- **Multi-arch builds**: Supports both amd64 and arm64, allowing the image to
  run on x86 Linux, ARM-based EC2 Linux, Apple M-series MacBooks, etc.
- **Reusable workflows**: Use GitOps best practices despite single application
- **Same-cluster environments**: Dev and prod share infrastructure, separated 
  only by namespace
