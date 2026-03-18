# Phase 5 — Object Storage with MinIO

## Goal
Deploy MinIO inside EKS as an S3-compatible storage backend
for Velero cluster backups.

## Status
Complete ✅

## Tools Used
- MinIO (latest)
- AWS EBS CSI Driver
- Kubernetes PersistentVolumeClaim
- Kubernetes Secrets

## What Was Built
- MinIO deployed in `minio` namespace
- 10Gi persistent volume provisioned via EBS CSI driver
- MinIO credentials sourced from Kubernetes secret `minio-vault-token`
- MinIO console exposed via AWS Load Balancer
- `velero-backups` bucket created for Phase 6

## Architecture
```
Vault
  └── minio credentials
        ↓
Kubernetes Secret (minio-vault-token)
        ↓
MinIO Pod (minio namespace)
  ├── API:     port 9000
  └── Console: port 9001
        ↓
EBS Volume (10Gi) — persistent storage
        ↓
velero-backups bucket — stores cluster backups
```

## Why MinIO
MinIO is S3-compatible — it speaks the exact same API as AWS S3.
Velero is configured to use S3 for backups. By running MinIO
inside the cluster we keep everything self-contained without
needing a real S3 bucket.

## Issues Encountered
- EBS CSI driver stuck in CREATING — fixed by associating
  OIDC provider and creating IAM service account via eksctl
- EBS CSI controller CrashLoopBackOff — fixed by deleting
  old pods to pick up new service account with correct IAM role
- MinIO pod CreateContainerConfigError — fixed by creating
  minio-vault-token secret in minio namespace (not default)

## Commands Used

### Install EBS CSI driver
```bash
aws eks create-addon \
  --cluster-name online-boutique \
  --addon-name aws-ebs-csi-driver \
  --region us-east-1
```

### Create IAM service account for EBS CSI
```bash
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster online-boutique \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --override-existing-serviceaccounts \
  --region us-east-1
```

### Set default storage class
```bash
kubectl patch storageclass gp2 \
  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

### Create secret in minio namespace
```bash
kubectl create secret generic minio-vault-token \
  --from-literal=accesskey="minio-admin" \
  --from-literal=secretkey="*********" \
  -n minio
```

### Deploy MinIO
```bash
kubectl apply -f minio/minio-deployment.yaml
```

### Get console URL
```bash
kubectl get service minio-external -n minio
```

## Access Details
- Console URL: http://LB_URL:9001
- Username: minio-admin
- Bucket created: velero-backups

## Result
MinIO running and accessible.
velero-backups bucket ready for Velero cluster backups.