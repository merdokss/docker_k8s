#!/bin/bash
set -euo pipefail

# ── NGINX Ingress Controller ──────────────────────────────────────────────────
echo "==> Instalacja NGINX Ingress Controller"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.replicaCount=2 \
  --set controller.nodeSelector."kubernetes\.io/os"=linux

kubectl -n ingress-nginx rollout status deployment ingress-nginx-controller
echo "NGINX Ingress: OK"
echo "Zewnętrzne IP: $(kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"

# ── cert-manager (TLS w Ingress) ──────────────────────────────────────────────
echo ""
echo "==> Instalacja cert-manager"
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true

kubectl -n cert-manager rollout status deployment cert-manager
echo "cert-manager: OK"

# ── KEDA (event-driven autoscaling) ──────────────────────────────────────────
echo ""
echo "==> Instalacja KEDA"
helm repo add kedacore https://kedacore.github.io/charts
helm repo update

helm upgrade --install keda kedacore/keda \
  --namespace keda \
  --create-namespace

kubectl -n keda rollout status deployment keda-operator
echo "KEDA: OK"

echo ""
echo "Wszystkie addony zainstalowane."
