@"
# Online Boutique — GitOps + DevOps on AWS

A production-style Kubernetes deployment of Google's [Online Boutique](https://github.com/GoogleCloudPlatform/microservices-demo) microservices demo, built with a complete GitOps and CI/CD workflow on AWS.

## Architecture

| Layer | Tool |
|---|---|
| Infrastructure | Terraform + EKS |
| CI Pipeline | GitHub Actions + ECR |
| GitOps | ArgoCD + Kustomize |
| Secrets | HashiCorp Vault |
| Object Storage | MinIO |
| Backup and DR | Velero |

## Project Status

- [ ] Phase 1 — EKS cluster with Terraform
- [ ] Phase 2 — CI pipeline with GitHub Actions
- [ ] Phase 3 — GitOps with ArgoCD + Kustomize
- [ ] Phase 4 — Secrets management with Vault
- [ ] Phase 5 — Object storage with MinIO
- [ ] Phase 6 — Backup and DR with Velero

## Prerequisites

- AWS account with IAM credentials
- Terraform >= 1.5
- kubectl
- eksctl
- Helm
"@ | Out-File -FilePath "README.md" -Encoding utf8