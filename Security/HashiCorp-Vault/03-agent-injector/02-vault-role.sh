#!/usr/bin/env bash
# Konfiguracja polityki i roli Vault dla Agent Injector
# Użycie: ./02-vault-role.sh
# Wymagania: VAULT_ADDR i VAULT_TOKEN muszą być ustawione

set -euo pipefail

: "${VAULT_ADDR:?Ustaw zmienną VAULT_ADDR}"
: "${VAULT_TOKEN:?Ustaw zmienną VAULT_TOKEN}"

echo "==> Tworzenie polityki myapp-policy..."
vault policy write myapp-policy 01-vault-policy.hcl

echo "==> Konfiguracja roli Kubernetes Auth dla Agent Injector..."
vault write auth/kubernetes/role/myapp \
  bound_service_account_names=myapp \
  bound_service_account_namespaces=demo-app \
  policies=myapp-policy \
  ttl=1h

echo "==> Dodawanie testowego sekretu..."
vault secrets enable -path=secret kv-v2 2>/dev/null || true

vault kv put secret/myapp/config \
  db_password="supersecret-from-vault" \
  api_key="vault-api-key-123"

echo ""
echo "==> Gotowe! Teraz wdróż aplikację:"
echo "    kubectl apply -f 03-deployment-with-agent.yaml"
