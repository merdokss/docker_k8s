# Ćwiczenie 02 – Kubernetes Auth Method

## Cel ćwiczenia

Skonfigurować Kubernetes Auth Method w Vault, który pozwala aplikacjom działającym w K8s na uwierzytelnienie do Vault za pomocą Service Account Token – bez konieczności zarządzania hasłami.

## Jak działa Kubernetes Auth Method?

```
Pod (aplikacja)
   |
   | 1. Wysyła JWT Service Account Token do Vault
   ▼
Vault Server
   |
   | 2. Weryfikuje token przez Kubernetes API (TokenReview)
   ▼
Kubernetes API Server
   |
   | 3. Potwierdza: "tak, ten SA istnieje w tym namespace"
   ▼
Vault Server
   |
   | 4. Sprawdza rolę Vault – czy ten SA/namespace ma dostęp?
   | 5. Zwraca Vault Token z odpowiednimi politykami
   ▼
Pod (aplikacja)
   |
   | 6. Używa Vault Token do odczytu sekretów
   ▼
Vault KV Secret
```

## Wymagania wstępne

- Ukończone ćwiczenie 01 (Vault zainstalowany i unsealed)
- `VAULT_ADDR` i `VAULT_TOKEN` ustawione w terminalu

```bash
kubectl port-forward -n vault svc/vault 8200:8200 &
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN=$(jq -r '.root_token' ../01-installation/vault-init.json)
```

## Krok 1 – Utwórz Service Account dla aplikacji

```bash
kubectl apply -f 01-serviceaccount.yaml
```

Tworzy namespace `demo-app` oraz Service Account `myapp` w tym namespace.

## Krok 2 – RBAC dla Vault (TokenReview)

```bash
kubectl apply -f 02-clusterrolebinding.yaml
```

Vault potrzebuje uprawnień do wykonywania `TokenReview` – weryfikacji tokenów SA przez K8s API.

## Krok 3 – Włącz Kubernetes Auth Method

```bash
# Włącz Kubernetes Auth
vault auth enable kubernetes

# Sprawdź czy włączony
vault auth list
```

## Krok 4 – Skonfiguruj Kubernetes Auth Method

```bash
# Pobierz adres Kubernetes API
K8S_HOST=$(kubectl config view --minify --output 'jsonpath={.clusters[0].cluster.server}')

# Skonfiguruj Vault
vault write auth/kubernetes/config \
  kubernetes_host="$K8S_HOST"

# Alternatywnie – Vault wewnątrz klastra używa automatycznej konfiguracji
# vault write auth/kubernetes/config \
#   kubernetes_host="https://kubernetes.default.svc"
```

## Krok 5 – Utwórz Policy Vault

```bash
# Utwórz politykę dostępu do sekretów aplikacji
vault policy write myapp-policy - <<EOF
path "secret/data/myapp/*" {
  capabilities = ["read", "list"]
}

path "secret/metadata/myapp/*" {
  capabilities = ["read", "list"]
}
EOF

vault policy read myapp-policy
```

## Krok 6 – Utwórz rolę Vault powiązaną z SA

```bash
vault write auth/kubernetes/role/myapp \
  bound_service_account_names=myapp \
  bound_service_account_namespaces=demo-app \
  policies=myapp-policy \
  ttl=1h

vault read auth/kubernetes/role/myapp
```

## Krok 7 – Dodaj testowy sekret

```bash
vault kv put secret/myapp/config \
  db_password="supersecret-from-vault" \
  api_key="vault-api-key-123"
```

## Krok 8 – Uruchom skrypt konfiguracyjny

Patrz: [03-vault-k8s-auth-setup.sh](./03-vault-k8s-auth-setup.sh) – wykonuje kroki 3-7 automatycznie.

```bash
chmod +x 03-vault-k8s-auth-setup.sh
./03-vault-k8s-auth-setup.sh
```

## Krok 9 – Weryfikacja uwierzytelnienia

```bash
# Pobierz token SA z działającego poda (lub utwórz tymczasowy pod)
kubectl run test-vault --image=curlimages/curl:latest \
  --namespace=demo-app \
  --serviceaccount=myapp \
  --restart=Never \
  --command -- sleep 3600

# Poczekaj na pod
kubectl wait --for=condition=ready pod/test-vault -n demo-app --timeout=30s

# Pobierz token SA
SA_TOKEN=$(kubectl exec -n demo-app test-vault -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)

# Zaloguj się do Vault przy użyciu SA Token
curl -s --request POST \
  --data "{\"jwt\": \"$SA_TOKEN\", \"role\": \"myapp\"}" \
  $VAULT_ADDR/v1/auth/kubernetes/login | jq .

# Zapisz token Vault
APP_VAULT_TOKEN=$(curl -s --request POST \
  --data "{\"jwt\": \"$SA_TOKEN\", \"role\": \"myapp\"}" \
  $VAULT_ADDR/v1/auth/kubernetes/login | jq -r '.auth.client_token')

# Odczytaj sekret używając tokenu aplikacji
curl -s --header "X-Vault-Token: $APP_VAULT_TOKEN" \
  $VAULT_ADDR/v1/secret/data/myapp/config | jq .data.data

# Sprzątanie
kubectl delete pod test-vault -n demo-app
```

## Weryfikacja

```bash
# Vault Token z logowania przez K8s SA powinien mieć politykę myapp-policy
vault token lookup <app-vault-token>
# policies: [default myapp-policy]

# Token powinien mieć dostęp do sekretów
vault kv get secret/myapp/config
```

## Najlepsze praktyki

- Używaj dedykowanego SA dla każdej aplikacji (nie `default`)
- Ogranicz `bound_service_account_namespaces` do konkretnego namespace
- Ustaw krótkie TTL tokenów (1h-24h)
- Używaj `token_bound_cidrs` jeśli znasz IP podów
