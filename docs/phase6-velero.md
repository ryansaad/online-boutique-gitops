# Phase 6 — Backup and Disaster Recovery with Velero

## Goal
Deploy Velero to back up the entire cluster state to MinIO
and prove full disaster recovery by restoring from backup.

## Status
Complete ✅

## Tools Used
- Velero v1.18.0
- MinIO (S3-compatible storage)
- velero-plugin-for-aws v1.10.0
- Helm v3.14.0

## What Was Built
- Velero installed on EKS in `velero` namespace via Helm
- Backup storage location pointing to MinIO `velero-backups` bucket
- Full cluster backup of `default` namespace completed
- Disaster recovery tested and proven — full restore in under 3 minutes

## Disaster Recovery Test Results
| Step | Result |
|---|---|
| Take backup of default namespace | ✅ Completed |
| Delete all Online Boutique resources | ✅ All pods deleted |
| Restore from Velero backup | ✅ Completed |
| Online Boutique accessible again | ✅ Confirmed in browser |

## Architecture
```
Online Boutique (default namespace)
        ↓
Velero backup job
        ↓
MinIO (velero-backups bucket)
        ↓ (on disaster)
Velero restore job
        ↓
Online Boutique restored
```

## How Velero Works
- Velero takes a snapshot of all Kubernetes resources
  (deployments, services, configmaps, secrets) in the namespace
- Snapshot is serialized and pushed to MinIO as JSON files
- On restore, Velero reads the JSON from MinIO and
  recreates all resources in the cluster
- Result is identical to the original cluster state

## Commands Used

### Install Velero via Helm
```bash
helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
helm repo update

helm install velero vmware-tanzu/velero \
  --namespace velero \
  --set configuration.backupStorageLocation[0].name=default \
  --set configuration.backupStorageLocation[0].provider=aws \
  --set configuration.backupStorageLocation[0].bucket=velero-backups \
  --set configuration.backupStorageLocation[0].config.region=minio \
  --set configuration.backupStorageLocation[0].config.s3ForcePathStyle=true \
  --set configuration.backupStorageLocation[0].config.s3Url=http://minio.minio.svc.cluster.local:9000 \
  --set configuration.volumeSnapshotLocation[0].name=default \
  --set configuration.volumeSnapshotLocation[0].provider=aws \
  --set configuration.volumeSnapshotLocation[0].config.region=us-east-1 \
  --set credentials.existingSecret=velero-credentials \
  --set initContainers[0].name=velero-plugin-for-aws \
  --set initContainers[0].image=velero/velero-plugin-for-aws:v1.10.0 \
  --set initContainers[0].volumeMounts[0].mountPath=/target \
  --set initContainers[0].volumeMounts[0].name=plugins
```

### Take a backup
```bash
kubectl apply -f velero/backup-schedule.yaml
kubectl get backup -n velero
```

### Simulate disaster
```bash
kubectl delete all --all -n default
```

### Restore from backup
```bash
kubectl apply -f velero/restore.yaml
kubectl get restore -n velero --watch
```

### Verify restore
```bash
kubectl get pods -n default
kubectl get service frontend-external -n default
```

## Issues Encountered
- Velero CLI not supported on Windows — used Helm install instead
- VolumeSnapshotLocation provider required even for MinIO-only setup
- Backup yaml applied via file instead of heredoc due to
  PowerShell not supporting << syntax

## Result
Full disaster recovery proven.
All 12 Online Boutique pods restored from MinIO backup.
Website accessible in browser after restore.
Restore completed in under 3 minutes.