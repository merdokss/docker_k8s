# Ćwiczenie 04 – Vault Secrets Operator (VSO)

## Cel ćwiczenia

Użyć Vault Secrets Operator do synchronizacji sekretów z Vault do natywnych Kubernetes Secrets przy użyciu CRD.

## Jak działa Vault Secrets Operator?

```
Developer definiuje CRD (VaultStaticSecret)
         |
         ▼
VSO Controller (działa jako Deployment w K8s)
         |
         | Kubernetes Auth → Vault API → odczyt sekretu
         ▼
Kubernetes Secret (synchronizowany automatycznie)
         |
         ▼
Pod (standardowe envFrom / volumeMounts)
```

VSO to **GitOps-friendly** podejście: definicje CRD trafiają do repozytorium Git, a VSO pilnuje synchronizacji.

## Wymagania wstępne

- Ukończone ćwiczenia 01 i 02
- `VAULT_ADDR` i `VAULT_TOKEN` ustawione

## Krok 1 – Instalacja VSO przez Helm

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

helm install vault-secrets-operator hashicorp/vault-secrets-operator \
  --namespace vault-secrets-operator-system \
  --create-namespace \
  --values 01-vso-values.yaml \
  --wait

# Sprawdź CRD
kubectl get crd | grep vault
# vaultauths.secrets.hashicorp.com
# vaultconnections.secrets.hashicorp.com
# vaultdynamicsecrets.secrets.hashicorp.com
# vaultpkisecrets.secrets.hashicorp.com
# vaultstaticsecrets.secrets.hashicorp.com
```

## Krok 2 – Utwórz VaultAuth

`VaultAuth` definiuje jak VSO ma uwierzytelniać się do Vault:

```bash
kubectl apply -f 02-vaultauth.yaml

# Sprawdź status
kubectl get vaultauth -n demo-app
kubectl describe vaultauth default -n demo-app
```

## Krok 3 – Utwórz VaultStaticSecret

`VaultStaticSecret` definiuje który sekret Vault ma być zsynchronizowany:

```bash
kubectl apply -f 03-vaultstaticsecret.yaml

# Sprawdź status synchronizacji
kubectl get vaultstaticsecret -n demo-app
kubectl describe vaultstaticsecret myapp-config -n demo-app

# Sprawdź czy K8s Secret został utworzony
kubectl get secret myapp-config -n demo-app
kubectl get secret myapp-config -n demo-app -o jsonpath='{.data}' | jq 'to_entries[] | {(.key): (.value | @base64d)}'
```

## Krok 4 – Wdróż aplikację używającą K8s Secret

```bash
kubectl apply -f 04-deployment-using-vso.yaml

kubectl rollout status deployment/myapp-vso -n demo-app

# Sprawdź zmienne środowiskowe w pode
kubectl exec -n demo-app deployment/myapp-vso -- env | grep -E "DB_PASSWORD|API_KEY"
```

## Ćwiczenie – Automatyczna rotacja

VSO automatycznie synchronizuje zmiany z Vault:

```bash
# Zmień sekret w Vault
vault kv put secret/myapp/config \
  db_password="rotated-password-$(date +%s)" \
  api_key="new-key-$(date +%s)"

# VSO wykryje zmianę (po refreshInterval)
# Domyślny refreshInterval: 60s
# Obserwuj synchronizację
kubectl get vaultstaticsecret myapp-config -n demo-app -w

# Po synchronizacji sprawdź zaktualizowany K8s Secret
kubectl get secret myapp-config -n demo-app -o jsonpath='{.data.db_password}' | base64 -d

# Aby Pod odebrał nowe sekrety (envFrom), musi być zrestartowany
# VSO może automatycznie restartować deployment (rolloutRestartTargets)
kubectl rollout restart deployment/myapp-vso -n demo-app
kubectl exec -n demo-app deployment/myapp-vso -- env | grep DB_PASSWORD
```

## CRD – VaultStaticSecret parametry

| Pole | Opis | Przykład |
|------|------|---------|
| `vaultAuthRef` | Nazwa VaultAuth do użycia | `default` |
| `mount` | Secret Engine mount path | `secret` |
| `path` | Ścieżka do sekretu | `myapp/config` |
| `version` | Konkretna wersja (KV v2) | `2` |
| `destination.name` | Nazwa K8s Secret | `myapp-config` |
| `destination.create` | Utwórz Secret jeśli nie istnieje | `true` |
| `refreshAfter` | Częstotliwość synchronizacji | `60s` |
| `rolloutRestartTargets` | Automatyczny restart Deployments | `[{kind: Deployment, name: myapp}]` |

## Porównanie z Agent Injector

| Cecha | Agent Injector | VSO |
|-------|---------------|-----|
| Zmienne w Pod | Pliki `/vault/secrets/` | Env vars lub pliki (przez K8s Secret) |
| Standard K8s | Nie (annotacje) | Tak (Secret + CRD) |
| GitOps | Trudniejszy | Łatwy |
| Rotacja bez restartu | Tak (sidecar) | Tylko z rolloutRestartTargets |
| Dodatkowe zasoby | Sidecar per Pod | Jeden Operator dla klastra |

## Weryfikacja

```bash
# VSO Operator działa
kubectl get pods -n vault-secrets-operator-system

# VaultAuth skonfigurowany
kubectl get vaultauth -n demo-app -o wide

# VaultStaticSecret zsynchronizowany
kubectl get vaultstaticsecret -n demo-app
# NAME           SYNCED   LAST SYNC   VAULT PATH              AGE
# myapp-config   True     10s         secret/data/myapp/config  5m

# K8s Secret zawiera dane z Vault
kubectl get secret myapp-config -n demo-app

# Aplikacja czyta sekrety przez K8s Secret
kubectl exec -n demo-app deployment/myapp-vso -- env | grep DB_PASSWORD
# DB_PASSWORD=supersecret-from-vault
```
