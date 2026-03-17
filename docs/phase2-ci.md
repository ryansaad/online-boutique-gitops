# Phase 2 — CI Pipeline with GitHub Actions

## Goal
Automatically build a Docker image and push it to AWS ECR 
every time code is pushed to the main branch.

## Status
Complete ✅

## Tools Used
- GitHub Actions
- AWS ECR (Elastic Container Registry)
- Docker
- aws-actions/configure-aws-credentials@v4
- aws-actions/amazon-ecr-login@v2

## What Was Built
- ECR repository at:
  `861276082757.dkr.ecr.us-east-1.amazonaws.com/online-boutique/frontend`
- GitHub Actions workflow that triggers on every push to main
- Pipeline builds the frontend Docker image from `src/frontend`
- Image is tagged with both `latest` and the git commit SHA
- Full pipeline runs in under 60 seconds

## Pipeline Stages
1. Checkout code
2. Configure AWS credentials from GitHub Secrets
3. Login to Amazon ECR
4. Build Docker image
5. Push image to ECR (both latest and commit SHA tags)
6. Print image URI

## GitHub Secrets Added
| Secret | Purpose |
|---|---|
| `AWS_ACCESS_KEY_ID` | Authenticate to AWS |
| `AWS_SECRET_ACCESS_KEY` | Authenticate to AWS |
| `AWS_REGION` | Target region (us-east-1) |
| `AWS_ACCOUNT_ID` | ECR registry prefix |

## Image Tagging Strategy
- `latest` — always points to the most recent build
- `<commit-sha>` — immutable tag for exact version tracking,
   enables precise rollbacks per commit

## Commands Used

### Create ECR repository
```bash