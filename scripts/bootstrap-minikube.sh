#!/usr/bin/env bash
set -euo pipefail

if ! command -v minikube >/dev/null 2>&1; then
  echo "minikube is required"
  exit 1
fi

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required"
  exit 1
fi

if ! command -v devspace >/dev/null 2>&1; then
  echo "devspace is required"
  exit 1
fi

minikube start --driver=docker --cpus=4 --memory=8192
kubectl apply -f k8s/base/namespace.yaml
kubectl apply -f k8s/base/db/secret.sample.yaml
devspace use namespace the-forge-dev
devspace deploy

echo "Use 'devspace dev' to start port-forwarded dev mode"
