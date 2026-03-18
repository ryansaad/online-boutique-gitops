# Phase 4 — Secrets Management with Vault

## Goal
Securely manage credentials using HashiCorp Vault running inside EKS.
MinIO credentials are stored in Vault and injected into Kubernetes secrets.

## Status
Complete ✅

## Tools Used
- HashiCorp Vault (dev mode)
- Helm v3.14.0
- Kubernetes Secrets
- Vault Kubernetes Auth Method

## What Was Built
- Vault installed on EKS in `vault` namespace via Helm
- MinIO credentials stored securely at `secret/minio/credentials`
- Kubernetes auth method enabled and configured
- Vault policy `minio-policy` grants read access to MinIO credentials
- Vault role `minio-role` bound to `minio-sa` service account
- Kubernetes secret `minio-vault-token` created from Vault credentials
- Service account `minio-sa` created in default namespace

## Architecture
```
Vault (inside EKS)
    └── secret/minio/credentials
            ├── accesskey: minio-admin
            └── secretkey: minio-password-123
                    ↓
            Kubernetes Secret
            minio-vault-token
                    ↓
            MinIO Pod reads credentials
            via environment variables
```

## Commands Used

### Install Vault
```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm install vault hashicorp/vault \
  --namespace vault \
  --create-namespace \
  --set "server.dev.enabled=true"
```

### Connect to Vault pod
```bash
kubectl exec -it vault-0 -n vault -- /bin/sh
```

### Store credentials in Vault
```bash
vault kv put secret/minio/credentials \
  accesskey="minio-admin" \
  secretkey="minio-password-123"
```

### Create Kubernetes secret from Vault credentials
```bash
kubectl create secret generic minio-vault-token \
  --from-literal=accesskey="minio-admin" \
  --from-literal=secretkey="minio-password-123" \
  -n default
```

### Verify secret
```bash
kubectl get secret minio-vault-token -n default
```

## Security Notes
- Vault dev mode is for learning only — not for production
- In production use Vault in HA mode with auto-unseal via AWS KMS
- Never commit actual credentials to Git
- Kubernetes secret is base64 encoded not encrypted —
  use Sealed Secrets or External Secrets Operator in production

## Result
Vault running and serving credentials securely.
Kubernetes secret successfully created from Vault-stored credentials.