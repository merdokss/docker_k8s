# Azure Key Vault - Integracja z Kubernetes

## Wprowadzenie

Azure Key Vault to usługa do bezpiecznego przechowywania i zarządzania:
- **Secrets** - hasła, connection stringi, klucze API
- **Keys** - klucze kryptograficzne (RSA, EC)
- **Certificates** - certyfikaty SSL/TLS

Integracja z Kubernetes pozwala na:
- ✅ Centralne zarządzanie secretami
- ✅ Automatyczną rotację secretów
- ✅ Audyt dostępu w Azure
- ✅ Unikanie hardcoded secrets w YAML
- ✅ Compliance i governance

---

## Rozwiązania integracji

### 1. Secrets Store CSI Driver (REKOMENDOWANE ⭐)
- **Status:** Aktywne, wspierane przez Microsoft
- **Sposób działania:** Montuje secrety jako volume w podzie
- **Zalety:** Native Kubernetes integration, automatic rotation
- **Workload Identity:** Używa Managed Identity dla podów

### 2. External Secrets Operator
- **Status:** CNCF projekt, wieloplatformowy
- **Sposób działania:** Synchronizuje secrety do Kubernetes Secrets
- **Zalety:** Działa z wieloma providerami (AWS, GCP, Vault)

### 3. Azure Key Vault FlexVolume (DEPRECATED)
- **Status:** ⚠️ Przestarzałe, nie używaj w nowych projektach
- **Migracja:** Przejdź na CSI Driver

---

## Secrets Store CSI Driver - Szczegóły

### Architektura

```
┌──────────────────────────────────────────────────────────────┐
│                         Pod                                  │
│                                                              │
│  ┌────────────────┐         ┌──────────────────────┐       │
│  │  Application   │────────►│  /mnt/secrets/       │       │
│  │  Container     │  reads  │  - db-password       │       │
│  └────────────────┘         │  - api-key           │       │
│                             │  (CSI Volume)        │       │
│                             └──────────────────────┘       │
└──────────────────────────────────────────────────────────────┘
                                    │
                                    │ CSI Driver
                                    ▼
                        ┌───────────────────────┐
                        │  Secrets Store        │
                        │  CSI Driver           │
                        │  (DaemonSet)          │
                        └───────────────────────┘
                                    │
                                    │ Workload Identity
                                    ▼
                        ┌───────────────────────┐
                        │  Azure Key Vault      │
                        │  - Secret: db-pwd     │
                        │  - Secret: api-key    │
                        │  - Cert: tls-cert     │
                        └───────────────────────┘
```

### Jak to działa?

1. **Pod startuje** z CSI volume mount
2. **CSI Driver** (DaemonSet na node) przechwytuje request
3. **Workload Identity** uwierzytelnia pod do Azure
4. **Azure Key Vault** zwraca secrety
5. **Secrety są montowane** jako pliki w podzie
6. **Opcjonalnie:** Tworzy Kubernetes Secret dla sync

---

## Instalacja - Krok po kroku

### Wymagania wstępne

- **AKS cluster** z włączonym OIDC Issuer i Workload Identity
- **Azure Key Vault** z secretami
- **Azure CLI** zainstalowany lokalnie
- **kubectl** zainstalowany i skonfigurowany

### Krok 1: Włącz Workload Identity w AKS

```bash
# Dla nowego klastra
az aks create \
  --resource-group myResourceGroup \
  --name myAKSCluster \
  --enable-oidc-issuer \
  --enable-workload-identity \
  --network-plugin azure

# Dla istniejącego klastra
az aks update \
  --resource-group myResourceGroup \
  --name myAKSCluster \
  --enable-oidc-issuer \
  --enable-workload-identity
```

### Krok 2: Pobierz OIDC Issuer URL

```bash
export AKS_OIDC_ISSUER="$(az aks show \
  --resource-group myResourceGroup \
  --name myAKSCluster \
  --query "oidcIssuerProfile.issuerUrl" \
  --output tsv)"

echo $AKS_OIDC_ISSUER
# Wynik: https://eastus.oic.prod-aks.azure.com/abc123.../
```

### Krok 3: Zainstaluj Secrets Store CSI Driver

#### Opcja A: Przez AKS add-on (ZALECANE)

```bash
az aks enable-addons \
  --resource-group myResourceGroup \
  --name myAKSCluster \
  --addons azure-keyvault-secrets-provider
```

#### Opcja B: Przez Helm

```bash
helm repo add csi-secrets-store-provider-azure \
  https://azure.github.io/secrets-store-csi-driver-provider-azure/charts

helm install csi-secrets-store-provider-azure/csi-secrets-store-provider-azure \
  --generate-name \
  --namespace kube-system \
  --set secrets-store-csi-driver.syncSecret.enabled=true
```

### Krok 4: Weryfikacja instalacji

```bash
# Sprawdź czy Driver działa
kubectl get pods -n kube-system -l app=secrets-store-csi-driver

# Sprawdź Azure Provider
kubectl get pods -n kube-system -l app=csi-secrets-store-provider-azure

# Powinny być w stanie Running
```

### Krok 5: Utwórz Azure Key Vault

```bash
# Utwórz Resource Group (jeśli nie istnieje)
az group create --name myResourceGroup --location eastus

# Utwórz Key Vault
export KEYVAULT_NAME="kv-aks-demo-$RANDOM"
az keyvault create \
  --name $KEYVAULT_NAME \
  --resource-group myResourceGroup \
  --location eastus

# Dodaj przykładowe secrety
az keyvault secret set \
  --vault-name $KEYVAULT_NAME \
  --name db-password \
  --value "SuperSecretPassword123!"

az keyvault secret set \
  --vault-name $KEYVAULT_NAME \
  --name api-key \
  --value "sk_live_abc123xyz789"

# Zapisz URL Key Vault
export KEYVAULT_URL=$(az keyvault show \
  --name $KEYVAULT_NAME \
  --query properties.vaultUri \
  --output tsv)

echo $KEYVAULT_URL
```

### Krok 6: Utwórz Managed Identity

```bash
# Utwórz User-Assigned Managed Identity
export USER_ASSIGNED_IDENTITY_NAME="id-workload-keyvault"

az identity create \
  --resource-group myResourceGroup \
  --name $USER_ASSIGNED_IDENTITY_NAME

# Pobierz Client ID
export USER_ASSIGNED_CLIENT_ID=$(az identity show \
  --resource-group myResourceGroup \
  --name $USER_ASSIGNED_IDENTITY_NAME \
  --query clientId \
  --output tsv)

echo $USER_ASSIGNED_CLIENT_ID
```

### Krok 7: Nadaj uprawnienia do Key Vault

```bash
# Nadaj uprawnienia do odczytu secretów
az keyvault set-policy \
  --name $KEYVAULT_NAME \
  --object-id $(az identity show \
    --resource-group myResourceGroup \
    --name $USER_ASSIGNED_IDENTITY_NAME \
    --query principalId \
    --output tsv) \
  --secret-permissions get list
```

**ALTERNATYWNIE (RBAC model - zalecany dla nowych Key Vault):**

```bash
# Włącz RBAC w Key Vault
az keyvault update \
  --name $KEYVAULT_NAME \
  --resource-group myResourceGroup \
  --enable-rbac-authorization true

# Przypisz rolę "Key Vault Secrets User"
export KEYVAULT_SCOPE=$(az keyvault show \
  --name $KEYVAULT_NAME \
  --query id \
  --output tsv)

az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee $USER_ASSIGNED_CLIENT_ID \
  --scope $KEYVAULT_SCOPE
```

### Krok 8: Utwórz Federated Identity Credential

To łączy Kubernetes Service Account z Azure Managed Identity (Workload Identity).

```bash
# Namespace i Service Account (użyjesz w Kubernetes)
export SERVICE_ACCOUNT_NAMESPACE="default"
export SERVICE_ACCOUNT_NAME="workload-identity-sa"

# Utwórz federated credential
az identity federated-credential create \
  --name "kubernetes-federated-credential" \
  --identity-name $USER_ASSIGNED_IDENTITY_NAME \
  --resource-group myResourceGroup \
  --issuer $AKS_OIDC_ISSUER \
  --subject "system:serviceaccount:${SERVICE_ACCOUNT_NAMESPACE}:${SERVICE_ACCOUNT_NAME}"
```

---

## Konfiguracja w Kubernetes

### Krok 9: Utwórz Service Account

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: workload-identity-sa
  namespace: default
  annotations:
    azure.workload.identity/client-id: "<USER_ASSIGNED_CLIENT_ID>"  # Zastąp!
```

Zastosuj:
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: workload-identity-sa
  namespace: default
  annotations:
    azure.workload.identity/client-id: "$USER_ASSIGNED_CLIENT_ID"
EOF
```

### Krok 10: Utwórz SecretProviderClass

To definiuje **co** pobrać z Key Vault i **jak** to zmapować.

```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-keyvault-secrets
  namespace: default
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"                # Nie używamy starszego Pod Identity
    useVMManagedIdentity: "false"          # Nie używamy node identity
    clientID: "<USER_ASSIGNED_CLIENT_ID>"  # Workload Identity
    keyvaultName: "<KEYVAULT_NAME>"        # Nazwa Key Vault
    tenantId: "<TENANT_ID>"                # Tenant ID
    objects: |
      array:
        - |
          objectName: db-password          # Nazwa secretu w Key Vault
          objectType: secret               # Typ: secret, key, cert
          objectAlias: DB_PASSWORD         # Opcjonalnie: alias w filesystemie
        - |
          objectName: api-key
          objectType: secret
          objectAlias: API_KEY
  # OPCJONALNIE: Sync do Kubernetes Secret
  secretObjects:
  - secretName: app-secrets                # Nazwa Kubernetes Secret
    type: Opaque
    data:
    - objectName: DB_PASSWORD              # objectAlias z góry
      key: db-password                     # Klucz w K8s Secret
    - objectName: API_KEY
      key: api-key
```

Zastosuj z wypełnionymi wartościami:
```bash
# Pobierz Tenant ID
export TENANT_ID=$(az account show --query tenantId --output tsv)

cat <<EOF | kubectl apply -f -
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-keyvault-secrets
  namespace: default
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "false"
    clientID: "$USER_ASSIGNED_CLIENT_ID"
    keyvaultName: "$KEYVAULT_NAME"
    tenantId: "$TENANT_ID"
    objects: |
      array:
        - |
          objectName: db-password
          objectType: secret
          objectAlias: DB_PASSWORD
        - |
          objectName: api-key
          objectType: secret
          objectAlias: API_KEY
  secretObjects:
  - secretName: app-secrets
    type: Opaque
    data:
    - objectName: DB_PASSWORD
      key: db-password
    - objectName: API_KEY
      key: api-key
EOF
```

### Krok 11: Utwórz Pod używający secretów

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-secrets
  namespace: default
  labels:
    azure.workload.identity/use: "true"  # WAŻNE! Włącza Workload Identity
spec:
  serviceAccountName: workload-identity-sa
  containers:
  - name: app
    image: nginx:latest
    volumeMounts:
    - name: secrets-store
      mountPath: "/mnt/secrets"
      readOnly: true
    # Secrety będą dostępne jako pliki:
    # /mnt/secrets/DB_PASSWORD
    # /mnt/secrets/API_KEY
    
    # ALTERNATYWNIE: Użyj jako zmienne środowiskowe
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: app-secrets       # Kubernetes Secret (z secretObjects)
          key: db-password
    - name: API_KEY
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: api-key
  volumes:
  - name: secrets-store
    csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: azure-keyvault-secrets  # Nazwa SecretProviderClass
```

Zastosuj:
```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: app-with-secrets
  namespace: default
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: workload-identity-sa
  containers:
  - name: app
    image: nginx:latest
    volumeMounts:
    - name: secrets-store
      mountPath: "/mnt/secrets"
      readOnly: true
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: db-password
    - name: API_KEY
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: api-key
  volumes:
  - name: secrets-store
    csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: azure-keyvault-secrets
EOF
```

### Krok 12: Weryfikacja

```bash
# Sprawdź czy pod działa
kubectl get pod app-with-secrets

# Sprawdź secrety jako pliki
kubectl exec app-with-secrets -- ls /mnt/secrets
# Wynik: API_KEY  DB_PASSWORD

kubectl exec app-with-secrets -- cat /mnt/secrets/DB_PASSWORD
# Wynik: SuperSecretPassword123!

# Sprawdź zmienne środowiskowe
kubectl exec app-with-secrets -- env | grep -E "(DB_PASSWORD|API_KEY)"

# Sprawdź czy Kubernetes Secret został utworzony
kubectl get secret app-secrets
kubectl describe secret app-secrets
```

---

## Przykłady zaawansowane

### Przykład 1: Deployment z secretami

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
        azure.workload.identity/use: "true"  # Workload Identity
    spec:
      serviceAccountName: workload-identity-sa
      containers:
      - name: app
        image: myacr.azurecr.io/web-app:v1.0
        ports:
        - containerPort: 8080
        env:
        # Secrety z Key Vault
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: database-url
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: redis-password
        # Zwykłe ConfigMap
        - name: APP_ENV
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: environment
        volumeMounts:
        - name: secrets-store
          mountPath: "/mnt/secrets"
          readOnly: true
        # Secrety jako pliki dla aplikacji która czyta pliki
        - name: tls-certs
          mountPath: "/etc/ssl/certs"
          readOnly: true
      volumes:
      - name: secrets-store
        csi:
          driver: secrets-store.csi.k8s.io
          readOnly: true
          volumeAttributes:
            secretProviderClass: azure-keyvault-secrets
      - name: tls-certs
        csi:
          driver: secrets-store.csi.k8s.io
          readOnly: true
          volumeAttributes:
            secretProviderClass: azure-keyvault-tls-certs  # Oddzielna klasa dla certów
```

### Przykład 2: Certyfikaty TLS dla Ingress

**SecretProviderClass dla certyfikatu:**

```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-tls-cert
  namespace: default
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "false"
    clientID: "<CLIENT_ID>"
    keyvaultName: "<KEYVAULT_NAME>"
    tenantId: "<TENANT_ID>"
    objects: |
      array:
        - |
          objectName: tls-cert       # Certyfikat w Key Vault
          objectType: cert
  secretObjects:
  - secretName: ingress-tls-secret   # Kubernetes Secret dla Ingress
    type: kubernetes.io/tls          # WAŻNE: Typ TLS
    data:
    - objectName: tls-cert
      key: tls.key                   # Klucz prywatny
    - objectName: tls-cert
      key: tls.crt                   # Certyfikat publiczny
```

**Ingress używający certyfikatu:**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-app-ingress
  namespace: default
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - myapp.example.com
    secretName: ingress-tls-secret   # Secret z Key Vault
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-app-service
            port:
              number: 80
```

**Pod synchronizujący certyfikat** (musi działać aby Secret się utworzył):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cert-syncer
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cert-syncer
  template:
    metadata:
      labels:
        app: cert-syncer
        azure.workload.identity/use: "true"
    spec:
      serviceAccountName: workload-identity-sa
      containers:
      - name: syncer
        image: gcr.io/google_containers/pause:3.2  # Dummy container
        volumeMounts:
        - name: secrets-store
          mountPath: "/mnt/secrets"
          readOnly: true
      volumes:
      - name: secrets-store
        csi:
          driver: secrets-store.csi.k8s.io
          readOnly: true
          volumeAttributes:
            secretProviderClass: azure-tls-cert
```

### Przykład 3: Multiple Key Vaults

```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: multi-keyvault-secrets
  namespace: default
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    clientID: "<CLIENT_ID>"
    tenantId: "<TENANT_ID>"
    objects: |
      array:
        - |
          objectName: db-password
          objectType: secret
          keyvaultName: kv-shared-prod     # Pierwszy Key Vault
        - |
          objectName: api-key
          objectType: secret
          keyvaultName: kv-app-specific    # Drugi Key Vault
```

⚠️ **Uwaga:** Managed Identity musi mieć uprawnienia do obu Key Vaults!

### Przykład 4: Automatyczna rotacja secretów

CSI Driver **automatycznie** aktualizuje pliki w volume gdy secret się zmieni w Key Vault.

**Domyślny interwał rotacji:** 2 minuty

**Zmiana interwału:**

```yaml
# W Deployment/Pod
spec:
  template:
    spec:
      volumes:
      - name: secrets-store
        csi:
          driver: secrets-store.csi.k8s.io
          readOnly: true
          volumeAttributes:
            secretProviderClass: azure-keyvault-secrets
            rotationPollInterval: "30s"  # Sprawdzaj co 30 sekund
```

**Aplikacja musi:**
- Odczytywać pliki przy każdym użyciu (nie cache'ować w pamięci)
- LUB nasłuchiwać na zmianę plików (inotify)
- LUB restart gdy Secret się zmieni (użyj Reloader)

**Automatyczny restart przy zmianie Secret - Stakater Reloader:**

```bash
# Instalacja Reloader
kubectl apply -f https://raw.githubusercontent.com/stakater/Reloader/master/deployments/kubernetes/reloader.yaml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  annotations:
    secret.reloader.stakater.com/reload: "app-secrets"  # Restartuj gdy się zmieni
spec:
  # ... reszta konfiguracji
```

---

## Troubleshooting - Najczęstsze problemy

### Problem 1: Pod nie startuje - "FailedMount"

```
MountVolume.SetUp failed for volume "secrets-store" : 
rpc error: code = Unknown desc = failed to mount secrets store objects for pod
```

**Diagnoza:**
```bash
# Sprawdź logi CSI Driver
kubectl logs -n kube-system -l app=secrets-store-csi-driver --tail=50

# Sprawdź logi Azure Provider
kubectl logs -n kube-system -l app=csi-secrets-store-provider-azure --tail=50
```

**Możliwe przyczyny:**
1. Błędny Client ID w SecretProviderClass
2. Brak federated credential dla Service Account
3. Brak uprawnień do Key Vault
4. Błędna nazwa Key Vault lub secretu

### Problem 2: "Permission denied" - Key Vault

```
Error: keyvault.BaseClient#GetSecret: Failure responding to request: 
StatusCode=403 -- Original Error: autorest/azure: error response cannot be parsed
```

**Rozwiązanie:**
```bash
# Sprawdź czy Managed Identity ma uprawnienia
az keyvault show --name $KEYVAULT_NAME --query properties.enableRbacAuthorization

# Jeśli true (RBAC):
az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee $USER_ASSIGNED_CLIENT_ID \
  --scope $(az keyvault show --name $KEYVAULT_NAME --query id -o tsv)

# Jeśli false (Access Policy):
az keyvault set-policy \
  --name $KEYVAULT_NAME \
  --object-id $(az identity show --name $USER_ASSIGNED_IDENTITY_NAME --resource-group myResourceGroup --query principalId -o tsv) \
  --secret-permissions get list
```

### Problem 3: Workload Identity nie działa

```
Error: failed to acquire token: FromAssertion(): http call(https://login.microsoftonline.com/...): 
400 Bad Request
```

**Diagnoza:**
```bash
# Sprawdź czy label jest na podzie
kubectl get pod app-with-secrets -o jsonpath='{.metadata.labels}'
# Musi być: azure.workload.identity/use: "true"

# Sprawdź Service Account annotation
kubectl get sa workload-identity-sa -o yaml
# Musi być: azure.workload.identity/client-id: "<CLIENT_ID>"

# Sprawdź federated credential
az identity federated-credential list \
  --identity-name $USER_ASSIGNED_IDENTITY_NAME \
  --resource-group myResourceGroup
```

### Problem 4: Secret się nie synchronizuje do K8s Secret

**Sprawdź:**
```bash
# Czy włączone w instalacji?
kubectl get deployment -n kube-system csi-secrets-store-provider-azure -o jsonpath='{.spec.template.spec.containers[0].args}'
# Szukaj: --enable-secret-rotation=true

# Sprawdź SecretProviderClass
kubectl get secretproviderclass azure-keyvault-secrets -o yaml
# Musi mieć sekcję: secretObjects
```

### Problem 5: "Tenant ID mismatch"

```bash
# Upewnij się że używasz właściwego Tenant ID
az account show --query tenantId -o tsv

# Sprawdź w SecretProviderClass
kubectl get secretproviderclass azure-keyvault-secrets -o jsonpath='{.spec.parameters.tenantId}'
```

---

## Best Practices

### 1. Organizacja Key Vaults

```
📦 Struktura rekomendowana:

kv-shared-prod           # Shared secrets (DB, Redis)
  ├─ postgres-password
  ├─ redis-password
  └─ rabbitmq-password

kv-app1-prod             # App-specific secrets
  ├─ stripe-api-key
  └─ sendgrid-api-key

kv-app2-prod
  ├─ aws-access-key
  └─ oauth-client-secret

kv-certs-prod            # Certyfikaty TLS
  ├─ wildcard-cert
  └─ api-cert
```

### 2. Nazewnictwo secretów

**Konsystentne prefixes:**
```
db-postgres-password
db-mysql-username
cache-redis-password
api-stripe-key-live
api-stripe-key-test
cert-wildcard-example-com
```

### 3. RBAC i uprawnienia

```bash
# Jedna Managed Identity na namespace
az identity create --name id-namespace-production --resource-group myRG

# Przypisz minimalne uprawnienia (Principle of Least Privilege)
# TYLKO "get" i "list", NIE "set" czy "delete"
az keyvault set-policy \
  --name $KEYVAULT_NAME \
  --object-id $IDENTITY_PRINCIPAL_ID \
  --secret-permissions get list
```

### 4. Separacja środowisk

```yaml
# production namespace
apiVersion: v1
kind: Namespace
metadata:
  name: production
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: workload-identity-sa
  namespace: production
  annotations:
    azure.workload.identity/client-id: "<PROD_CLIENT_ID>"
---
# SecretProviderClass wskazujący na kv-prod
```

```yaml
# development namespace
apiVersion: v1
kind: Namespace
metadata:
  name: development
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: workload-identity-sa
  namespace: development
  annotations:
    azure.workload.identity/client-id: "<DEV_CLIENT_ID>"
---
# SecretProviderClass wskazujący na kv-dev
```

### 5. Monitoring i alerting

**Azure Monitor Queries:**

```kusto
// Wszystkie odczyty z Key Vault
AzureDiagnostics
| where ResourceType == "VAULTS"
| where OperationName == "SecretGet"
| project TimeGenerated, CallerIPAddress, identity_claim_appid_g, ResultSignature
| order by TimeGenerated desc

// Nieudane próby dostępu
AzureDiagnostics
| where ResourceType == "VAULTS"
| where ResultSignature == "Forbidden"
| summarize FailedAttempts=count() by identity_claim_appid_g, bin(TimeGenerated, 5m)
```

**Azure Alerts:**
```bash
# Alert na 403 Forbidden
az monitor metrics alert create \
  --name "KeyVault-AccessDenied" \
  --resource-group myResourceGroup \
  --scopes $(az keyvault show --name $KEYVAULT_NAME --query id -o tsv) \
  --condition "total ServiceApiResult where ResultType == 'Forbidden' > 10" \
  --window-size 5m \
  --evaluation-frequency 1m
```

### 6. Backup i Disaster Recovery

```bash
# Soft-delete (włączone domyślnie) - 90 dni retention
az keyvault update \
  --name $KEYVAULT_NAME \
  --resource-group myResourceGroup \
  --enable-soft-delete true \
  --retention-days 90

# Purge protection - zapobiega usunięciu
az keyvault update \
  --name $KEYVAULT_NAME \
  --resource-group myResourceGroup \
  --enable-purge-protection true

# Backup secretu
az keyvault secret backup \
  --vault-name $KEYVAULT_NAME \
  --name db-password \
  --file backup-db-password.blob

# Restore secretu
az keyvault secret restore \
  --vault-name $KEYVAULT_NAME \
  --file backup-db-password.blob
```

### 7. Rotacja secretów

**Automatyczna rotacja w Key Vault:**

```bash
# Włącz automatyczną rotację dla secretu
az keyvault secret set-attributes \
  --vault-name $KEYVAULT_NAME \
  --name db-password \
  --expires "2025-12-31T23:59:59Z"

# Dodaj notification przed expiration
az keyvault secret set \
  --vault-name $KEYVAULT_NAME \
  --name db-password \
  --value "NewPassword123!" \
  --expires "2025-12-31T23:59:59Z" \
  --not-before "2025-01-01T00:00:00Z"
```

**Event Grid notification:**

```bash
# Subskrypcja na zmiany w Key Vault
az eventgrid event-subscription create \
  --name keyvault-secret-change \
  --source-resource-id $(az keyvault show --name $KEYVAULT_NAME --query id -o tsv) \
  --endpoint https://mywebhook.example.com/api/keyvault-notification \
  --included-event-types Microsoft.KeyVault.SecretNewVersionCreated
```

---

## Porównanie: CSI Driver vs Kubernetes Secrets

| Aspekt | CSI Driver + Key Vault | Native K8s Secrets |
|--------|----------------------|-------------------|
| **Bezpieczeństwo** | ⭐⭐⭐ Encrypted at rest w Azure | ⭐⭐ Base64 (nie encrypted domyślnie) |
| **Audyt** | ⭐⭐⭐ Azure Activity Logs | ⭐ K8s audit logs |
| **Rotacja** | ⭐⭐⭐ Automatyczna | ⭐ Manualna (update YAML) |
| **Zarządzanie** | ⭐⭐⭐ Centralne w Azure | ⭐ Per cluster |
| **Performance** | ⭐⭐ Sieć call do Azure | ⭐⭐⭐ Lokalne |
| **Cost** | 💰 Key Vault pricing | 💰 Darmowe |
| **Prostota** | ⭐⭐ Więcej konfiguracji | ⭐⭐⭐ Prosty YAML |

---

## Migracja z Kubernetes Secrets do Key Vault

### Krok 1: Zidentyfikuj istniejące secrety

```bash
# Lista wszystkich Secrets
kubectl get secrets --all-namespaces -o json \
  | jq -r '.items[] | select(.type=="Opaque") | "\(.metadata.namespace)/\(.metadata.name)"'
```

### Krok 2: Eksportuj secrety

```bash
# Funkcja eksportu
export_secret_to_keyvault() {
  local namespace=$1
  local secret_name=$2
  local keyvault=$3
  
  # Pobierz wszystkie klucze z secretu
  keys=$(kubectl get secret $secret_name -n $namespace -o json | jq -r '.data | keys[]')
  
  for key in $keys; do
    value=$(kubectl get secret $secret_name -n $namespace -o json | jq -r ".data.\"$key\"" | base64 -d)
    keyvault_name="${secret_name}-${key}"
    
    # Upload do Key Vault
    az keyvault secret set \
      --vault-name $keyvault \
      --name $keyvault_name \
      --value "$value"
    
    echo "✅ Migrated: $namespace/$secret_name/$key → $keyvault/$keyvault_name"
  done
}

# Użycie
export_secret_to_keyvault "production" "app-secrets" "$KEYVAULT_NAME"
```

### Krok 3: Utwórz SecretProviderClass

```bash
# Generuj SecretProviderClass z istniejącego secretu
kubectl get secret app-secrets -n production -o json | jq -r '
{
  "apiVersion": "secrets-store.csi.x-k8s.io/v1",
  "kind": "SecretProviderClass",
  "metadata": {
    "name": "migrated-\(.metadata.name)",
    "namespace": .metadata.namespace
  },
  "spec": {
    "provider": "azure",
    "parameters": {
      "usePodIdentity": "false",
      "clientID": "<CLIENT_ID>",
      "keyvaultName": "<KEYVAULT_NAME>",
      "tenantId": "<TENANT_ID>",
      "objects": ("array:\n" + (
        .data | keys | map("  - |\n    objectName: app-secrets-\(.)\n    objectType: secret\n    objectAlias: \(.)") | join("\n")
      ))
    },
    "secretObjects": [
      {
        "secretName": .metadata.name,
        "type": "Opaque",
        "data": (.data | keys | map({"objectName": ., "key": .}))
      }
    ]
  }
}' | kubectl apply -f -
```

### Krok 4: Aktualizuj Deployments stopniowo

**Strategia Blue-Green:**

1. Deploy nowej wersji z CSI volume (green)
2. Test green deployment
3. Przełącz traffic na green
4. Usuń starą wersję (blue)

---

## Checklist implementacji

```
✅ Przygotowanie:
  □ AKS cluster z Workload Identity
  □ Azure Key Vault utworzony
  □ Managed Identity utworzona
  □ Federated Credential skonfigurowany
  □ Uprawnienia do Key Vault nadane

✅ Instalacja:
  □ CSI Driver zainstalowany (add-on lub Helm)
  □ Pods CSI Driver w stanie Running
  □ Azure Provider pods w stanie Running

✅ Konfiguracja K8s:
  □ Service Account z annotation client-id
  □ SecretProviderClass utworzona
  □ Test pod deployed i działa
  □ Secrety widoczne w /mnt/secrets

✅ Produkcja:
  □ RBAC najniższe uprawnienia (get, list only)
  □ Soft-delete i purge-protection włączone
  □ Monitoring i alerty skonfigurowane
  □ Dokumentacja procedur rotacji
  □ Disaster recovery plan
  □ Runbook troubleshooting

✅ Security:
  □ Disable local accounts w Key Vault
  □ Network policies dla podów
  □ Private endpoint dla Key Vault (opcjonalnie)
  □ Audit logs włączone
```

---

## Dodatkowe zasoby

- **Oficjalna dokumentacja:** https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-driver
- **GitHub CSI Driver:** https://github.com/Azure/secrets-store-csi-driver-provider-azure
- **Workload Identity:** https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview
- **Key Vault best practices:** https://learn.microsoft.com/en-us/azure/key-vault/general/best-practices

---

## Podsumowanie

Azure Key Vault + Secrets Store CSI Driver to **rekomendowane rozwiązanie** dla bezpiecznego zarządzania secretami w AKS:

✅ **Zalety:**
- Centralne zarządzanie secretami
- Automatyczna rotacja
- Audyt w Azure
- Compliance i governance
- Workload Identity (bez kluczy w kodzie)

⚠️ **Uwagi:**
- Wymaga połączenia z Azure
- Dodatkowa konfiguracja (Managed Identity, federated credentials)
- Key Vault pricing ($0.03 per 10,000 operations)

**Start small:**
1. Zacznij od 1-2 secretów w dev environment
2. Przetestuj rotację i monitoring
3. Rozszerz na więcej aplikacji
4. Migruj produkcję stopniowo

**Powodzenia! 🚀**

