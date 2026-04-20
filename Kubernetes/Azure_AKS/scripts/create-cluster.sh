#!/bin/bash
set -euo pipefail

RG="rg-aks-training"
CLUSTER="aks-training"
LOCATION="polandcentral"

# Sprawdź aktualną wersję: az aks get-versions -l polandcentral -o table
K8S_VERSION="1.31"

echo "==> Tworzenie Resource Group: $RG"
az group create \
  --name "$RG" \
  --location "$LOCATION"

echo "==> Tworzenie klastra AKS: $CLUSTER (może trwać 5-10 min)"
az aks create \
  --resource-group "$RG" \
  --name "$CLUSTER" \
  --location "$LOCATION" \
  --kubernetes-version "$K8S_VERSION" \
  --node-count 3 \
  --node-vm-size Standard_D4s_v3 \
  --os-disk-size-gb 128 \
  --network-plugin azure \
  --network-policy calico \
  --load-balancer-sku standard \
  --enable-oidc-issuer \
  --enable-workload-identity \
  --enable-addons azure-keyvault-secrets-provider \
  --enable-secret-rotation \
  --generate-ssh-keys \
  --tags env=training purpose=kubernetes-workshop

echo "==> Pobieranie credentials"
az aks get-credentials \
  --resource-group "$RG" \
  --name "$CLUSTER" \
  --overwrite-existing

echo "==> Weryfikacja klastra"
kubectl get nodes
kubectl get pods -A

echo ""
echo "Klaster gotowy! Uruchom kolejne skrypty:"
echo "  ./install-addons.sh       -- NGINX Ingress, cert-manager, KEDA"
echo "  ./create-participants.sh  -- namespace'y dla uczestników"
echo ""
echo "Po szkoleniu zatrzymaj klaster:"
echo "  az aks stop --name $CLUSTER --resource-group $RG"
