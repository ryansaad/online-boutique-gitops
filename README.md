# Online Boutique — Production-Style GitOps on AWS

> A complete end-to-end DevOps and GitOps implementation deploying Google's 
> [Online Boutique](https://github.com/GoogleCloudPlatform/microservices-demo) 
> microservices application on AWS using industry-standard tooling.

---

## What This Project Demonstrates

This project simulates a real-world production Kubernetes environment built from scratch on AWS.
Every layer — from infrastructure provisioning to disaster recovery — is automated, documented,
and reproducible.

| Concept | Implementation |
|---|---|
| Infrastructure as Code | Terraform provisions EKS, VPC, subnets, IAM |
| CI/CD Pipeline | GitHub Actions builds and pushes Docker images to ECR |
| GitOps | ArgoCD syncs cluster state from Git automatically |
| Config Management | Kustomize manages environment-specific overlays |
| Secrets Management | HashiCorp Vault stores and injects credentials |
| Object Storage | MinIO provides S3-compatible storage inside the cluster |
| Backup & DR | Velero backs up cluster state and restores on demand |

---

## Architecture
```
                        ┌─────────────────────────────────────────┐
                        │              AWS Cloud                   │
                        │                                          │
  Developer             │   ┌──────────┐      ┌───────────────┐   │
  pushes code  ──────► │   │  GitHub  │      │     ECR       │   │
                        │   │ Actions  │─────►│ Docker Images │   │
                        │   └──────────┘      └───────┬───────┘   │
                        │                             │           │
                        │   ┌──────────┐             │           │
                        │   │  ArgoCD  │◄────────────┘           │
                        │   │  GitOps  │                          │
                        │   └────┬─────┘                          │
                        │        │ syncs                          │
                        │        ▼                                │
                        │   ┌─────────────────────────────────┐   │
                        │   │         EKS Cluster             │   │
                        │   │                                 │   │
                        │   │  ┌────────┐  ┌───────────────┐ │   │
                        │   │  │ Vault  │  │ Online Boutique│ │   │
                        │   │  │Secrets │  │ 11 services   │ │   │
                        │   │  └────────┘  └───────────────┘ │   │
                        │   │                                 │   │
                        │   │  ┌────────┐  ┌───────────────┐ │   │
                        │   │  │ MinIO  │  │    Velero     │ │   │
                        │   │  │Storage │◄─│    Backup     │ │   │
                        │   │  └────────┘  └───────────────┘ │   │
                        │   └─────────────────────────────────┘   │
                        └─────────────────────────────────────────┘
```

---

## Tech Stack

### Infrastructure
![Terraform](https://img.shields.io/badge/Terraform-1.12-7B42BC?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazonaws)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.29-326CE5?logo=kubernetes)

### CI/CD & GitOps
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-CI-2088FF?logo=githubactions)
![ArgoCD](https://img.shields.io/badge/ArgoCD-GitOps-EF7B4D?logo=argo)
![Docker](https://img.shields.io/badge/Docker-ECR-2496ED?logo=docker)

### Platform Tools
![Vault](https://img.shields.io/badge/Vault-Secrets-FFEC6E?logo=vault)
![MinIO](https://img.shields.io/badge/MinIO-Storage-C72E49?logo=minio)
![Velero](https://img.shields.io/badge/Velero-Backup-00AEEF)

---

## Project Phases

### ✅ Phase 1 — Infrastructure with Terraform
Provisioned a production-style EKS cluster on AWS using Terraform modules.
Built a VPC with public and private subnets across 2 availability zones,
managed node groups, IAM roles, and remote state in S3.

→ [Phase 1 Documentation](docs/phase1-terraform.md)

### ✅ Phase 2 — CI Pipeline with GitHub Actions
Automated Docker image builds triggered on every push to main.
Images are tagged with both `latest` and the git commit SHA for
precise version tracking and rollback capability. Pushed to AWS ECR.

→ [Phase 2 Documentation](docs/phase2-ci.md)

### ✅ Phase 3 — GitOps with ArgoCD + Kustomize
Implemented GitOps — Git is the single source of truth for cluster state.
ArgoCD continuously monitors the repo and automatically syncs any changes
to the cluster. Self-heal enabled means manual cluster changes are reverted.

→ [Phase 3 Documentation](docs/phase3-gitops.md)

### ✅ Phase 4 — Secrets Management with Vault
Deployed HashiCorp Vault inside the cluster. MinIO credentials stored
securely in Vault, accessed via Kubernetes auth method with policies
and roles — equivalent to IAM roles for EC2 in AWS.

→ [Phase 4 Documentation](docs/phase4-vault.md)

### ✅ Phase 5 — Object Storage with MinIO
Deployed MinIO inside EKS as an S3-compatible storage backend.
Credentials sourced from Vault via Kubernetes secrets. 10Gi persistent
volume provisioned via EBS CSI driver.

→ [Phase 5 Documentation](docs/phase5-minio.md)

### ✅ Phase 6 — Backup & Disaster Recovery with Velero
Configured Velero to back up the entire cluster state to MinIO.
Proved full disaster recovery — deleted all Online Boutique resources
and restored the complete application from backup in under 3 minutes.

→ [Phase 6 Documentation](docs/phase6-velero.md)

---

## Key Results
```
✅ EKS cluster provisioned with Terraform — 51 resources, fully automated
✅ CI pipeline builds and pushes Docker image in under 60 seconds
✅ ArgoCD syncs cluster from Git — any push updates the cluster automatically  
✅ Secrets managed in Vault — no plaintext credentials anywhere in the codebase
✅ Full disaster recovery proven — cluster restored from backup in under 3 minutes
✅ 17 real-world issues hit and resolved — documented in troubleshooting guide
```

---

## Repository Structure
```
online-boutique-gitops/
├── terraform/          # EKS cluster infrastructure
├── src/                # Online Boutique application source
├── k8s/                # Base Kubernetes manifests
├── kustomize/          # Environment overlays (dev/prod)
├── argocd/             # ArgoCD application config
├── vault/              # Vault policies and setup scripts
├── minio/              # MinIO deployment manifests
├── velero/             # Velero backup and restore configs
├── .github/workflows/  # GitHub Actions CI pipeline
└── docs/               # Phase-by-phase documentation
```

---

## How to Reproduce This Project

### Prerequisites
- AWS account with IAM credentials
- Terraform >= 1.5
- kubectl
- eksctl
- Helm
- Git

### Quick Start
```bash
# 1. Clone the repo
git clone https://github.com/ryansaad/online-boutique-gitops.git
cd online-boutique-gitops

# 2. Provision infrastructure
cd terraform
terraform init
terraform apply

# 3. Connect to cluster
aws eks update-kubeconfig --region us-east-1 --name online-boutique

# 4. Follow phase documentation in order
# docs/phase1-terraform.md → docs/phase6-velero.md
```

> ⚠️ Remember to run `terraform destroy` when done to avoid AWS charges.
> Estimated cost: $3-4/day with cluster running, $15-25 for the full project.

---

## Troubleshooting

Hit 17 real issues during this build. Every problem and solution is documented:

→ [Full Troubleshooting Guide](docs/troubleshooting.md)

---

## Lessons Learned

- GitOps fundamentally changes how you think about cluster management —
  the cluster becomes a reflection of Git, not the other way around
- Vault's Kubernetes auth method is conceptually identical to AWS IAM roles
  for EC2 — once that clicked, the setup became intuitive
- EBS CSI driver on EKS requires explicit IAM setup via OIDC —
  not documented clearly in most tutorials
- Velero backup/restore is remarkably fast — 3 minutes to restore
  a 12-service application from scratch is impressive for DR

---

*Built on AWS EKS · Deployed with ArgoCD · Backed up with Velero*