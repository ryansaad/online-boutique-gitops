# Phase 1 — Infrastructure with Terraform and EKS

## Goal
Provision a production-style EKS cluster on AWS using Terraform and 
deploy Online Boutique to verify it works.

## Status
Complete ✅

## Tools Used
- Terraform v1.12.2
- AWS EKS v1.29
- AWS VPC
- eksctl v0.224.0
- kubectl v1.32.2

## What Was Built
- VPC with public and private subnets across 2 availability zones
- EKS cluster named `online-boutique` in `us-east-1`
- 2 worker nodes of type `t3.medium`
- Terraform state stored remotely in S3 bucket `ryansaad-online-boutique-tfstate`
- Online Boutique successfully deployed and accessible via AWS Load Balancer

## Resources Created by Terraform
- 1 VPC
- 4 subnets (2 public, 2 private)
- 1 NAT Gateway
- 1 EKS cluster
- 1 EKS managed node group (2 x t3.medium)
- IAM roles and policies
- KMS encryption key
- Security groups
- Total: 51 resources

## Commands Used

### Initialize Terraform
```bash
terraform init
```

### Preview infrastructure
```bash
terraform plan
```

### Create infrastructure
```bash
terraform apply
```

### Connect kubectl to cluster
```bash
aws eks update-kubeconfig --region us-east-1 --name online-boutique
```

### Grant IAM user cluster access
```bash
aws eks create-access-entry \
  --cluster-name online-boutique \
  --principal-arn arn:aws:iam::accountid:user/Ryansaad_IAM_Admin \
  --type STANDARD

aws eks associate-access-policy \
  --cluster-name online-boutique \
  --principal-arn arn:aws:iam::accountid:user/Ryansaad_IAM_Admin \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster
```

### Verify nodes
```bash
kubectl get nodes
```

### Deploy Online Boutique
```bash
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/main/release/kubernetes-manifests.yaml
```

### Get frontend URL
```bash
kubectl get service frontend-external
```

## Issues Encountered
- kubectl returned credentials error after cluster creation
- Fixed by creating an EKS access entry and associating AmazonEKSClusterAdminPolicy
  to the IAM user via aws eks create-access-entry and associate-access-policy commands

## Result
Online Boutique storefront accessible at:
http://LB_URL