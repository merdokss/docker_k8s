#!/usr/bin/env bash
# Konfiguracja Kubernetes Auth Method w Vault
# Użycie: ./03-vault-k8s-auth-setup.sh
# Wymagania: VAULT_ADDR i VAULT_TOKEN muszą być ustawione

set -euo pipefail

: "${VAULT_ADDR:?Ustaw zmienną VAULT_ADDR, np. export VAULT_ADDR=http://localhost:8200}"
: "${VAULT_TOKEN:?Ustaw zmienną VAULT_TOKEN (root token z vault-init.json)}"

echo "==> Włączanie Kubernetes Auth Method..."
vault auth enable kubernetes 2>/dev/null || echo "    Kubernetes auth już włączony, kontynuuję..."

echo "==> Konfiguracja Kubernetes Auth Method..."
K8S_HOST=$(kubectl config view --minify --output 'jsonpath={.clusters[0].cluster.server}')
echo "    Kubernetes API: $K8S_HOST"

vault write auth/kubernetes/config \
  kubernetes_host="$K8S_HOST"

echo "==> Tworzenie polityki Vault dla myapp..."
vault policy write myapp-policy - <<'EOF'
path "secret/data/myapp/*" {
  capabilities = ["read", "list"]
}

path "secret/metadata/myapp/*" {
  capabilities = ["read", "list"]
}
EOF

echo "==> Tworzenie roli Vault powiązanej z ServiceAccount myapp/demo-app..."
vault write auth/kubernetes/role/myapp \
  bound_service_account_names=myapp \
  bound_service_account_namespaces=demo-app \
  policies=myapp-policy \
  ttl=1h

echo "==> Włączanie KV v2 secrets engine (jeśli nie włączony)..."
vault secrets enable -path=secret kv-v2 2>/dev/null || echo "    KV v2 już włączony, kontynuuję..."

echo "==> Dodawanie testowego sekretu..."
vault kv put secret/myapp/config \
  db_password="supersecret-from-vault" \
  api_key="vault-api-key-123"

echo ""
echo "==> Konfiguracja zakończona!"
echo ""
echo "    Polityki:       $(vault policy list | tr '\n' ' ')"
echo "    Role K8s Auth:  $(vault list auth/kubernetes/role | tr '\n' ' ')"
echo ""
echo "==> Weryfikacja – odczytaj sekret:"
echo "    vault kv get secret/myapp/config"
