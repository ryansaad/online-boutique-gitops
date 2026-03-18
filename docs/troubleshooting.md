# Troubleshooting & Issues Encountered

This document captures every issue hit during the project
and exactly how it was resolved. Useful for anyone reproducing
this setup or debugging similar problems.

---

## Phase 1 — Terraform & EKS

### Issue 1 — kubectl credentials error after cluster creation
**Error:**
```
error: You must be logged in to the server
(the server has asked for the client to provide credentials)
```
**Cause:**
The IAM user that created the cluster was not automatically
granted access to the EKS cluster. EKS requires explicit
access entry configuration.

**Fix:**
```bash
aws eks create-access-entry \
  --cluster-name online-boutique \
  --principal-arn arn:aws:iam::ACCOUNT_ID:user/YOUR_IAM_USER \
  --type STANDARD

aws eks associate-access-policy \
  --cluster-name online-boutique \
  --principal-arn arn:aws:iam::ACCOUNT_ID:user/YOUR_IAM_USER \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster
```

---

## Phase 2 — GitHub Actions & ECR

### Issue 2 — ECR repository already exists
**Error:**
```
RepositoryAlreadyExistsException: The repository with name
'online-boutique/frontend' already exists
```
**Cause:**
ECR repository was already created during the initial
Online Boutique deployment in Phase 1.

**Fix:**
No action needed — used the existing repository directly.

---

## Phase 3 — ArgoCD & Kustomize

### Issue 3 — Kustomize deprecated fields
**Error:**
```
'bases' is deprecated. Please use 'resources' instead.
'commonLabels' is deprecated. Please use 'labels' instead.
'patchesStrategicMerge' is deprecated. Please use 'patches' instead.
```
**Cause:**
ArgoCD uses a strict version of Kustomize that doesn't
accept deprecated fields.

**Fix:**
Replace deprecated fields in all kustomization.yaml files:
- `bases` → `resources`
- `commonLabels` → `labels` with `pairs:` block
- `patchesStrategicMerge` → `patches`

---

### Issue 4 — ArgoCD security blocks path traversal
**Error:**
```
accumulation err: file is not in or below repo root
```
**Cause:**
ArgoCD's security model does not allow `../` paths that
traverse outside the repo root. Our kustomize base was
referencing `../../../k8s/base/online-boutique/` which
went above the repo root from ArgoCD's perspective.

**Fix:**
Moved `kubernetes-manifests.yaml` directly into
`kustomize/base/` folder and updated the reference to
just `kubernetes-manifests.yaml` — no path traversal needed.

---

## Phase 4 — Vault

### Issue 5 — Vault secrets path already in use
**Error:**
```
Error enabling: path is already in use at secret/
```
**Cause:**
Vault dev mode pre-enables the `secret/` KV engine by default.

**Fix:**
Ignore the error — the path is already available and ready
to use. Skip the `vault secrets enable` command.

---

## Phase 5 — MinIO & EBS CSI

### Issue 6 — MinIO pod stuck in Pending
**Cause:**
EBS CSI driver not installed — Kubernetes could not provision
a PersistentVolume for the MinIO PVC.

**Fix:**
Install the EBS CSI driver addon:
```bash
aws eks create-addon \
  --cluster-name online-boutique \
  --addon-name aws-ebs-csi-driver \
  --region us-east-1
```

---

### Issue 7 — EBS CSI addon stuck in CREATING for 15+ minutes
**Cause:**
The EBS CSI controller pods were crashing due to missing
IAM permissions. The controller needs `sts:AssumeRoleWithWebIdentity`
to authenticate with AWS.

**Fix:**
Create an IAM service account with the correct policy:
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
Then delete the old crashing pods so they pick up the new
service account:
```bash
kubectl delete pod -n kube-system -l app=ebs-csi-controller
```

---

### Issue 8 — EBS CSI CrashLoopBackOff after service account fix
**Error:**
```
AccessDenied: Not authorized to perform sts:AssumeRoleWithWebIdentity
```
**Cause:**
Old pods were still using the old service account without
the IAM role annotation.

**Fix:**
Delete the old pods to force recreation with the new
service account:
```bash
kubectl delete pod -n kube-system -l app=ebs-csi-controller
```
Verify the service account has the correct IAM role:
```bash
kubectl get serviceaccount ebs-csi-controller-sa \
  -n kube-system \
  -o jsonpath="{.metadata.annotations}"
```

---

### Issue 9 — MinIO pod CreateContainerConfigError
**Error:**
```
CreateContainerConfigError
```
**Cause:**
The `minio-vault-token` Kubernetes secret was created in
the `default` namespace but MinIO is deployed in the
`minio` namespace. Secrets are namespace-scoped in Kubernetes.

**Fix:**
Create the secret in the correct namespace:
```bash
kubectl create secret generic minio-vault-token \
  --from-literal=accesskey="minio-admin" \
  --from-literal=secretkey="minio-password-123" \
  -n minio
```

---

## Phase 6 — Velero

### Issue 10 — Velero CLI not available on Windows
**Cause:**
Velero does not officially support Windows for its CLI.
The zip download URLs for Windows versions did not exist.

**Fix:**
Installed Velero directly on the cluster via Helm instead
of using the CLI:
```bash
helm install velero vmware-tanzu/velero \
  --namespace velero \
  --set configuration.backupStorageLocation[0].provider=aws \
  ...
```

---

### Issue 11 — Helm install failed with VolumeSnapshotLocation error
**Error:**
```
VolumeSnapshotLocation.velero.io "default" is invalid:
spec.provider: Required value
```
**Cause:**
Velero Helm chart requires a VolumeSnapshotLocation provider
to be specified even if you are not using volume snapshots.

**Fix:**
Add the volumeSnapshotLocation config to the Helm install:
```bash
--set configuration.volumeSnapshotLocation[0].name=default \
--set configuration.volumeSnapshotLocation[0].provider=aws \
--set configuration.volumeSnapshotLocation[0].config.region=us-east-1
```

---

### Issue 12 — Cannot reuse Helm release name
**Error:**
```
cannot reuse a name that is still in use
```
**Cause:**
First Helm install failed but left partial resources behind.

**Fix:**
Uninstall the failed release first then reinstall:
```bash
helm uninstall velero -n velero
helm install velero vmware-tanzu/velero ...
```

---

### Issue 13 — Heredoc syntax not supported in PowerShell
**Error:**
```
Missing file specification after redirection operator
```
**Cause:**
PowerShell does not support the `<<EOF` heredoc syntax
used in bash.

**Fix:**
Save YAML content to a file first then apply:
```powershell
@"
apiVersion: velero.io/v1
...
"@ | Out-File -FilePath "velero\restore.yaml" -Encoding utf8

kubectl apply -f velero\restore.yaml
```

---

### Issue 14 — Cannot delete default namespace
**Error:**
```
namespaces "default" is forbidden: this namespace may not be deleted
```
**Cause:**
Kubernetes protects the `default` namespace from deletion
as it is a system namespace.

**Fix:**
Simulate disaster by deleting all resources inside the
namespace instead:
```bash
kubectl delete all --all -n default
```

---

## Windows-Specific Issues

### Issue 15 — eksctl and helm not in PATH after install
**Cause:**
Tools were installed to custom directories not in the
system PATH. Changes to User PATH require terminal restart.

**Fix:**
Set PATH for current session immediately after install:
```powershell
$env:PATH += ";C:\eksctl"
$env:PATH += ";C:\helm\windows-amd64"
```

Set permanently for future sessions:
```powershell
[System.Environment]::SetEnvironmentVariable(
  "PATH",
  [System.Environment]::GetEnvironmentVariable("PATH", "User") + ";C:\eksctl;C:\helm\windows-amd64",
  [System.EnvironmentVariableTarget]::User
)
```

---

### Issue 16 — curl command not working in PowerShell
**Cause:**
`curl` in PowerShell is an alias for `Invoke-WebRequest`
and does not support the same flags as Linux curl (`-LO`).

**Fix:**
Use PowerShell native syntax:
```powershell
Invoke-WebRequest -Uri "https://..." -OutFile "filename.zip"
```

---

### Issue 17 — base64 command not available in PowerShell
**Cause:**
PowerShell does not have a `base64` binary like Linux/Mac.

**Fix:**
Use PowerShell's built-in Base64 decoding:
```powershell
$encoded = kubectl -n argocd get secret argocd-initial-admin-secret `
  -o jsonpath="{.data.password}"
[System.Text.Encoding]::UTF8.GetString(
  [System.Convert]::FromBase64String($encoded)
)
```