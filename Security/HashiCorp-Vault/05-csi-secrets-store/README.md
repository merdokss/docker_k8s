# Ćwiczenie 05 – CSI Secrets Store Provider dla Vault

## Cel ćwiczenia

Użyć Secrets Store CSI Driver z Vault Provider do montowania sekretów jako wolumeny w podach – bez sidecar, bez operator, jako natywny CSI volume.

## Jak działa CSI Secrets Store?

```
SecretProviderClass (CRD)
  – wskazuje: provider=vault, ścieżka sekretu
         |
         ▼
Secrets Store CSI Driver (DaemonSet na każdym węźle)
         |
         | kubelet montuje wolumen → CSI driver pyta Vault
         ▼
Vault API (przez Kubernetes Auth)
         |
         ▼
Pliki zamontowane w /mnt/secrets-store/ wewnątrz poda
         |
         ▼ (opcjonalnie)
K8s Secret (synchronizacja przez secretObjects)
```

## Wymagania wstępne

- Ukończone ćwiczenia 01 i 02
- `VAULT_ADDR` i `VAULT_TOKEN` ustawione

## Krok 1 – Instalacja Secrets Store CSI Driver

```bash
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm repo update

helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver \
  --namespace kube-system \
  --set syncSecret.enabled=true \
  --set enableSecretRotation=true \
  --set rotationPollInterval=120s

# Sprawdź DaemonSet
kubectl get daemonset -n kube-system -l app=secrets-store-csi-driver
```

## Krok 2 – Instalacja Vault CSI Provider

```bash
# Vault CSI Provider instaluje się razem z Helm chart Vault
# Jeśli nie jest zainstalowany, zaktualizuj Vault Helm:
helm upgrade vault hashicorp/vault \
  --namespace vault \
  --reuse-values \
  --set "csi.enabled=true"

# Sprawdź DaemonSet
kubectl get daemonset -n vault -l app.kubernetes.io/name=vault-csi-provider
```

## Krok 3 – Utwórz SecretProviderClass

```bash
kubectl apply -f 01-secretproviderclass.yaml

kubectl get secretproviderclass -n demo-app
kubectl describe secretproviderclass vault-myapp-config -n demo-app
```

## Krok 4 – Wdróż aplikację z CSI wolumenem

```bash
kubectl apply -f 02-deployment-with-csi.yaml

kubectl rollout status deployment/myapp-csi -n demo-app

# Sprawdź zamontowane pliki
kubectl exec -n demo-app deployment/myapp-csi -- ls -la /mnt/secrets-store/
kubectl exec -n demo-app deployment/myapp-csi -- cat /mnt/secrets-store/db_password
kubectl exec -n demo-app deployment/myapp-csi -- cat /mnt/secrets-store/api_key
```

## Krok 5 – Synchronizacja do K8s Secret (opcjonalnie)

`SecretProviderClass` z polem `secretObjects` synchronizuje pliki do K8s Secret:

```bash
# Sprawdź czy K8s Secret został utworzony
kubectl get secret myapp-csi-secret -n demo-app
kubectl get secret myapp-csi-secret -n demo-app -o jsonpath='{.data.db_password}' | base64 -d
```

## Parametry SecretProviderClass dla Vault

| Parametr | Opis | Przykład |
|----------|------|---------|
| `provider` | Provider CSI | `vault` |
| `vaultAddress` | Adres Vault | `http://vault.vault.svc:8200` |
| `roleName` | Rola Vault K8s Auth | `myapp` |
| `objects` | Lista sekretów do zamontowania | YAML lista |
| `objectName` | Nazwa pliku na wolumenie | `db_password` |
| `secretPath` | Ścieżka KV v2 | `secret/data/myapp/config` |
| `secretKey` | Klucz w sekrecie | `db_password` |

## Porównanie metod

| Cecha | Agent Injector | VSO | CSI Provider |
|-------|---------------|-----|--------------|
| Pliki w Pod | `/vault/secrets/` | Nie (env vars) | `/mnt/secrets-store/` |
| K8s Secret | Nie | Tak | Opcjonalnie |
| Dodatkowe zasoby | Sidecar per Pod | Operator | DaemonSet (raz) |
| Rotacja | Automatyczna | refreshAfter | rotationPollInterval |
| Multi-provider | Nie | Nie | Tak (Vault + AWS SM) |
| GitOps | Annotacje | CRD | CRD |

## Weryfikacja

```bash
# DaemonSet CSI Driver działa
kubectl get daemonset -n kube-system -l app=secrets-store-csi-driver

# Vault CSI Provider działa
kubectl get daemonset -n vault

# SecretProviderClass skonfigurowany
kubectl get secretproviderclass -n demo-app

# Pod ma zamontowany wolumen
kubectl exec -n demo-app deployment/myapp-csi -- ls /mnt/secrets-store/
# api_key  db_password

# Pliki zawierają wartości z Vault
kubectl exec -n demo-app deployment/myapp-csi -- cat /mnt/secrets-store/db_password
# supersecret-from-vault
```

## Kiedy używać CSI Provider?

**Zalety:**
- Jeden DaemonSet dla całego klastra (nie sidecar per Pod)
- Obsługa wielu providerów jednocześnie (Vault + AWS Secrets Manager)
- Natywna integracja z CSI (standard K8s)

**Wady:**
- Sekrety tylko jako pliki (chyba że użyjesz secretObjects)
- Bardziej złożona konfiguracja niż VSO
- Wymaga Node-level DaemonSet

**Rekomendacja:** Multi-cloud, potrzeba montowania plików konfiguracyjnych, środowiska z wieloma providerami sekretów.
