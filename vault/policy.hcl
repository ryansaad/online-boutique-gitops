# Vault policy for MinIO credentials
# Allows read access to MinIO credentials stored in Vault

path "secret/data/minio/credentials" {
  capabilities = ["read"]
}