#!/bin/sh
# Vault setup script
# Run these commands inside the vault-0 pod:
# kubectl exec -it vault-0 -n vault -- /bin/sh

# Step 1 - Store MinIO credentials
vault kv put secret/minio/credentials \
  accesskey="minio-admin" \
  secretkey="minio-password-123"

# Step 2 - Enable Kubernetes auth
vault auth enable kubernetes

# Step 3 - Configure Kubernetes auth
vault write auth/kubernetes/config \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"

# Step 4 - Create policy
vault policy write minio-policy - <<EOF
path "secret/data/minio/credentials" {
  capabilities = ["read"]
}
EOF

# Step 5 - Create role
vault write auth/kubernetes/role/minio-role \
  bound_service_account_names=minio-sa \
  bound_service_account_namespaces=default \
  policies=minio-policy \
  ttl=24h