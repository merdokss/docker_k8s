#!/usr/bin/env bash
# Skrypt inicjalizacji i unseal Vault na Kubernetes
# Użycie: ./03-vault-init-unseal.sh

set -euo pipefail

NAMESPACE="vault"
POD_NAME="vault-0"
INIT_FILE="vault-init.json"

echo "==> Oczekiwanie na pod $POD_NAME..."
kubectl wait --for=condition=ready pod/$POD_NAME -n $NAMESPACE --timeout=120s 2>/dev/null || true

echo "==> Sprawdzanie statusu Vault..."
INIT_STATUS=$(kubectl exec -n $NAMESPACE $POD_NAME -- vault status -format=json 2>/dev/null | jq -r '.initialized' || echo "false")

if [ "$INIT_STATUS" = "true" ]; then
  echo "==> Vault jest już zainicjalizowany."
  echo "    Jeśli chcesz ponownie zainicjalizować, usuń PVC i poda."
else
  echo "==> Inicjalizacja Vault (1 key share, próg = 1)..."
  kubectl exec -n $NAMESPACE $POD_NAME -- vault operator init \
    -key-shares=1 \
    -key-threshold=1 \
    -format=json > "$INIT_FILE"

  echo "==> Inicjalizacja zakończona. Dane zapisano do: $INIT_FILE"
  echo ""
  echo "    !!! WAŻNE: W środowisku produkcyjnym przechowuj klucze i root token"
  echo "    !!! w bezpiecznym miejscu (np. HSM, menedżer haseł)!"
  echo ""
fi

echo "==> Odczyt kluczy unseal z $INIT_FILE..."
VAULT_UNSEAL_KEY=$(jq -r '.unseal_keys_b64[0]' "$INIT_FILE")
VAULT_ROOT_TOKEN=$(jq -r '.root_token' "$INIT_FILE")

SEALED_STATUS=$(kubectl exec -n $NAMESPACE $POD_NAME -- vault status -format=json 2>/dev/null | jq -r '.sealed' || echo "true")

if [ "$SEALED_STATUS" = "false" ]; then
  echo "==> Vault jest już odblokowany (unsealed)."
else
  echo "==> Odblokowywanie Vault (unseal)..."
  kubectl exec -n $NAMESPACE $POD_NAME -- vault operator unseal "$VAULT_UNSEAL_KEY"
  echo "==> Vault odblokowany."
fi

echo ""
echo "==> Status Vault:"
kubectl exec -n $NAMESPACE $POD_NAME -- vault status

echo ""
echo "==> Dane dostępowe:"
echo "    Root Token: $VAULT_ROOT_TOKEN"
echo ""
echo "==> Aby połączyć się lokalnie, uruchom:"
echo "    kubectl port-forward -n $NAMESPACE svc/vault 8200:8200 &"
echo "    export VAULT_ADDR='http://localhost:8200'"
echo "    export VAULT_TOKEN='$VAULT_ROOT_TOKEN'"
echo ""
echo "==> UI dostępne pod: http://localhost:8200 (po port-forward)"
