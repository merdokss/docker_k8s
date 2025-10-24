# 🔐 Azure Key Vault Demo - Aplikacja dla AKS

Przykładowa aplikacja demonstrująca użycie Azure Key Vault z Secrets Store CSI Driver i Workload Identity na AKS.

## 📋 Co zawiera ten przykład?

1. **Aplikacja Node.js** - wyświetla sekrety pobrane z Key Vault
2. **Azure Key Vault** - przechowuje sekrety
3. **Workload Identity** - bezpieczne uwierzytelnianie bez kluczy
4. **Secrets Store CSI Driver** - montuje sekrety jako pliki i synchronizuje z K8s Secrets

## 🚀 Szybki start

### Wymagania wstępne

- ✅ Klaster AKS z włączonym OIDC Issuer i Workload Identity
- ✅ Azure CLI zainstalowane
- ✅ kubectl skonfigurowane
- ✅ Secrets Store CSI Driver zainstalowany na klastrze

### Krok 1: Uruchom skrypt konfiguracji Azure

```bash
cd demo-app
chmod +x setup-azure.sh
./setup-azure.sh
```

Skrypt automatycznie utworzy:
- Azure Key Vault z 3 przykładowymi secretami
- User-Assigned Managed Identity
- Federated Identity Credential dla Workload Identity
- Uprawnienia do Key Vault (RBAC)
- Pliki Kubernetes (serviceaccount.yaml, secretproviderclass.yaml)

### Krok 2: Zastosuj konfigurację Kubernetes

```bash
# Załaduj zmienne środowiskowe
source config.env

# Zastosuj Service Account i SecretProviderClass
kubectl apply -f serviceaccount.yaml
kubectl apply -f secretproviderclass.yaml

# Wdróż aplikację
kubectl apply -f deployment.yaml
```

### Krok 3: Sprawdź status

```bash
# Sprawdź czy pody działają
kubectl get pods -l app=keyvault-demo

# Sprawdź czy Secret został utworzony
kubectl get secret app-secrets

# Sprawdź logi aplikacji
kubectl logs -l app=keyvault-demo --tail=20
```

### Krok 4: Dostęp do aplikacji

```bash
# Pobierz External IP LoadBalancera
kubectl get svc keyvault-demo

# Otwórz w przeglądarce
# http://<EXTERNAL-IP>
```

## 📁 Struktura plików

```
demo-app/
├── README.md                    # Ten plik
├── setup-azure.sh              # Skrypt konfiguracji Azure
├── deployment.yaml             # Deployment + Service + ConfigMap
├── app.js                      # Kod aplikacji Node.js
├── package.json                # Zależności npm
├── Dockerfile                  # Dockerfile (opcjonalnie)
└── (generowane przez setup-azure.sh):
    ├── config.env              # Zmienne środowiskowe
    ├── serviceaccount.yaml     # Service Account z Workload Identity
    └── secretproviderclass.yaml # SecretProviderClass
```

## 🔍 Weryfikacja działania

### 1. Sprawdź zamontowane sekrety jako pliki

```bash
kubectl exec -it deployment/keyvault-demo -- sh

# W podzie:
ls -la /mnt/secrets
cat /mnt/secrets/DB_PASSWORD
cat /mnt/secrets/API_KEY
cat /mnt/secrets/CONNECTION_STRING
exit
```

### 2. Sprawdź zmienne środowiskowe

```bash
kubectl exec -it deployment/keyvault-demo -- env | grep -E "(DB_PASSWORD|API_KEY|CONNECTION_STRING)"
```

### 3. Sprawdź Kubernetes Secret

```bash
kubectl get secret app-secrets -o yaml
kubectl describe secret app-secrets
```

### 4. Sprawdź logi CSI Driver (w przypadku problemów)

```bash
kubectl logs -n kube-system -l app=secrets-store-csi-driver --tail=50
kubectl logs -n kube-system -l app=csi-secrets-store-provider-azure --tail=50
```

## 🧪 Testowanie rotacji secretów

### 1. Zmień secret w Key Vault

```bash
source config.env

az keyvault secret set \
  --vault-name $KEYVAULT_NAME \
  --name db-password \
  --value "NoweHaslo123!Zmienione"
```

### 2. Poczekaj ~2 minuty (domyślny czas rotacji)

```bash
# Sprawdź czy wartość się zmieniła w podzie
kubectl exec -it deployment/keyvault-demo -- cat /mnt/secrets/DB_PASSWORD
```

### 3. Restart poda (jeśli aplikacja cache'uje wartości)

```bash
kubectl rollout restart deployment/keyvault-demo
```

## 🧹 Czyszczenie zasobów

### Usuń aplikację z Kubernetes

```bash
kubectl delete -f deployment.yaml
kubectl delete -f secretproviderclass.yaml
kubectl delete -f serviceaccount.yaml
kubectl delete secret app-secrets
```

### Usuń zasoby Azure

```bash
source config.env

# Usuń Key Vault
az keyvault delete --name $KEYVAULT_NAME --resource-group $RESOURCE_GROUP
az keyvault purge --name $KEYVAULT_NAME  # Trwałe usunięcie

# Usuń Managed Identity
az identity delete --name id-keyvault-demo --resource-group $RESOURCE_GROUP
```

## 🔧 Troubleshooting

### Problem: Pod nie startuje - "FailedMount"

```bash
# Sprawdź logi CSI Driver
kubectl logs -n kube-system -l app=secrets-store-csi-driver --tail=50

# Sprawdź czy SecretProviderClass istnieje
kubectl get secretproviderclass

# Sprawdź czy Service Account ma poprawny annotation
kubectl get sa workload-identity-sa -o yaml
```

### Problem: "Permission denied" - Key Vault

```bash
source config.env

# Sprawdź czy RBAC jest włączony
az keyvault show --name $KEYVAULT_NAME --query properties.enableRbacAuthorization

# Sprawdź uprawnienia
az role assignment list --scope $(az keyvault show --name $KEYVAULT_NAME --query id -o tsv)
```

### Problem: Workload Identity nie działa

```bash
# Sprawdź czy label jest na podzie
kubectl get pods -l app=keyvault-demo -o jsonpath='{.items[0].metadata.labels}'

# Musi zawierać: azure.workload.identity/use: "true"

# Sprawdź Federated Credential
az identity federated-credential list \
  --identity-name id-keyvault-demo \
  --resource-group $RESOURCE_GROUP
```

## 📚 Więcej informacji

- [Azure Key Vault - Główna dokumentacja](../README.md)
- [Oficjalna dokumentacja Microsoft](https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-driver)
- [GitHub CSI Driver](https://github.com/Azure/secrets-store-csi-driver-provider-azure)

## 💡 Najlepsze praktyki zastosowane w tym przykładzie

✅ **Workload Identity** zamiast Service Principal  
✅ **RBAC** w Key Vault (najniższe uprawnienia)  
✅ **Secrets synchronizacja** do Kubernetes Secrets  
✅ **Health checks** (liveness + readiness probes)  
✅ **Resource limits** dla podów  
✅ **LoadBalancer** dla łatwego dostępu  
✅ **Replicas: 2** dla wysokiej dostępności  

## 🎯 Następne kroki

Po przetestowaniu podstawowej konfiguracji możesz:

1. **Dodać więcej secretów** - edytuj `secretproviderclass.yaml`
2. **Konfigurować automatyczną rotację** - dodaj `rotationPollInterval`
3. **Użyć Ingress** zamiast LoadBalancer
4. **Dodać monitoring** - Azure Monitor queries dla Key Vault
5. **Implementować w produkcji** - osobne Key Vaults per środowisko

---

**Autor:** AKS Training  
**Wersja:** 1.0  
**Data:** 2025

