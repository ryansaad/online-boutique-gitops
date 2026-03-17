# Phase 3 — GitOps with ArgoCD and Kustomize

## Goal
Automatically sync Kubernetes manifests from Git to EKS using ArgoCD,
so Git is always the single source of truth for cluster state.

## Status
Complete ✅

## Tools Used
- ArgoCD
- Kustomize v5.5.0
- kubectl v1.32.2
- Helm v3.14.0

## What Was Built
- ArgoCD installed on EKS cluster in `argocd` namespace
- ArgoCD application watching `kustomize/overlays/dev` in GitHub repo
- Kustomize base with Online Boutique manifests
- Dev and prod overlays with environment-specific image tags
- Automated sync with self-heal enabled — cluster always matches Git

## Folder Structure