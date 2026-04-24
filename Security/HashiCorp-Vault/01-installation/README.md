# Ćwiczenie 01 – Instalacja HashiCorp Vault na Kubernetes

## Cel ćwiczenia

Zainstalować Vault na klastrze Kubernetes przy użyciu Helm chart i przeprowadzić inicjalizację oraz unseal.

## Wymagania wstępne

- Działający klaster Kubernetes (minikube, k3d, kind lub AKS/GKE/EKS)
- Helm >= 3.x zainstalowany
- kubectl skonfigurowany do klastra

## Krok 1 – Namespace i repozytorium Helm

```bash
# Dodaj repozytorium HashiCorp
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# Utwórz namespace
kubectl apply -f 01-namespace.yaml

# Sprawdź dostępne wersje chart
helm search repo hashicorp/vault
```

## Krok 2 – Instalacja Vault (tryb standalone)

```bash
# Instalacja z niestandardowymi wartościami
helm install vault hashicorp/vault \
  --namespace vault \
  --values 02-vault-values.yaml \
  --wait

# Sprawdź status
kubectl get pods -n vault
kubectl get svc -n vault
```

Oczekiwany wynik – pod `vault-0` w statusie `Running` (ale `0/1 READY` bo vault jest sealed):

```
NAME                                    READY   STATUS    RESTARTS   AGE
vault-0                                 0/1     Running   0          30s
vault-agent-injector-6b7d8b9b8c-xk2jt  1/1     Running   0          30s
```

## Krok 3 – Inicjalizacja i Unseal

```bash
# Zainicjalizuj Vault (tylko raz!)
kubectl exec -n vault vault-0 -- vault operator init \
  -key-shares=1 \
  -key-threshold=1 \
  -format=json > vault-init.json

# WAŻNE: Zapisz zawartość vault-init.json w bezpiecznym miejscu!
cat vault-init.json

# Wyodrębnij klucz i root token
VAULT_UNSEAL_KEY=$(cat vault-init.json | jq -r '.unseal_keys_b64[0]')
VAULT_ROOT_TOKEN=$(cat vault-init.json | jq -r '.root_token')

# Unseal Vault
kubectl exec -n vault vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY

# Sprawdź status – Initialized: true, Sealed: false
kubectl exec -n vault vault-0 -- vault status
```

## Krok 4 – Pierwsze logowanie i konfiguracja

```bash
# Zaloguj się root tokenem
kubectl exec -n vault vault-0 -- vault login $VAULT_ROOT_TOKEN

# Lub ustaw zmienne środowiskowe lokalnie (z port-forward)
kubectl port-forward -n vault svc/vault 8200:8200 &
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN=$VAULT_ROOT_TOKEN

# Sprawdź dostępne secret engines
vault secrets list

# Włącz KV v2 secrets engine
vault secrets enable -path=secret kv-v2

# Dodaj pierwszy sekret
vault kv put secret/myapp/config \
  db_password="supersecret" \
  api_key="my-api-key-123"

# Odczytaj sekret
vault kv get secret/myapp/config

# Odczytaj konkretne pole
vault kv get -field=db_password secret/myapp/config
```

## Krok 5 – Dostęp do UI (opcjonalnie)

```bash
# Port-forward do UI Vault
kubectl port-forward -n vault svc/vault 8200:8200

# Otwórz w przeglądarce: http://localhost:8200
# Zaloguj się tokenem: $VAULT_ROOT_TOKEN
```

## Weryfikacja

```bash
# Vault jest unsealed i działa
kubectl exec -n vault vault-0 -- vault status | grep Sealed
# Sealed: false

# Sekret jest dostępny
vault kv get secret/myapp/config
# Key            Value
# db_password    supersecret
# api_key        my-api-key-123

# Lista sekretów
vault kv list secret/myapp/
```

## Wersjonowanie sekretów (KV v2)

KV v2 automatycznie wersjonuje sekrety:

```bash
# Zaktualizuj sekret
vault kv put secret/myapp/config db_password="newpassword"

# Sprawdź metadata (historia wersji)
vault kv metadata get secret/myapp/config

# Odczytaj konkretną wersję
vault kv get -version=1 secret/myapp/config

# Usuń (soft delete) wersję
vault kv delete -versions=1 secret/myapp/config

# Trwałe usunięcie
vault kv destroy -versions=1 secret/myapp/config
```

## Skrypt pomocniczy

Patrz: [03-vault-init-unseal.sh](./03-vault-init-unseal.sh) – automatyzacja kroków init i unseal.

## Tryby instalacji

| Tryb | Opis | Kiedy używać |
|------|------|--------------|
| `dev` | W pamięci, auto-unseal, brak TLS | Tylko lokalne testy |
| `standalone` | Jeden węzeł, trwały storage | Ćwiczenia, małe wdrożenia |
| `ha` | Wiele węzłów, Raft storage | Produkcja |

> **Uwaga:** W tym ćwiczeniu używamy trybu `standalone`. Na produkcji zawsze używaj HA z Auto Unseal.
