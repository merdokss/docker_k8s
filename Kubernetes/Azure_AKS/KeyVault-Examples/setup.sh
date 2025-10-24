#!/bin/bash

###############################################################################
# Skrypt do automatycznej konfiguracji Azure Key Vault + AKS
# Autor: Training Materials
# Wersja: 1.0
###############################################################################

set -e  # Przerwij przy błędzie

# Kolory dla outputu
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funkcje pomocnicze
print_header() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

###############################################################################
# KONFIGURACJA - ZMIEŃ TE WARTOŚCI
###############################################################################

RESOURCE_GROUP="rg-aks-keyvault-demo"
LOCATION="westeurope"
AKS_CLUSTER_NAME="aks-keyvault-demo"
KEYVAULT_NAME="kv-aks-demo-$RANDOM"  # Musi być globalnie unikalna
USER_ASSIGNED_IDENTITY_NAME="id-workload-keyvault"
SERVICE_ACCOUNT_NAME="workload-identity-sa"
SERVICE_ACCOUNT_NAMESPACE="default"

###############################################################################
# WERYFIKACJA WYMAGAŃ
###############################################################################

print_header "1. Weryfikacja wymagań"

# Sprawdź czy zalogowany do Azure
if ! az account show &> /dev/null; then
    print_error "Nie jesteś zalogowany do Azure. Uruchom: az login"
    exit 1
fi

print_success "Zalogowany do Azure"

# Pobierz Subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
print_info "Subscription ID: $SUBSCRIPTION_ID"
print_info "Tenant ID: $TENANT_ID"

# Sprawdź czy kubectl jest zainstalowany
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl nie jest zainstalowany"
    exit 1
fi

print_success "kubectl zainstalowany"

###############################################################################
# UTWORZENIE ZASOBÓW AZURE
###############################################################################

print_header "2. Tworzenie zasobów Azure"

# Utwórz Resource Group
print_info "Tworzenie Resource Group: $RESOURCE_GROUP..."
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION \
    --output none

print_success "Resource Group utworzona"

# Utwórz AKS Cluster (jeśli nie istnieje)
print_info "Sprawdzanie czy klaster AKS istnieje..."
if az aks show --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME &> /dev/null; then
    print_info "Klaster AKS już istnieje, pomijam tworzenie"
    
    # Upewnij się że Workload Identity jest włączone
    print_info "Włączanie Workload Identity w istniejącym klastrze..."
    az aks update \
        --resource-group $RESOURCE_GROUP \
        --name $AKS_CLUSTER_NAME \
        --enable-oidc-issuer \
        --enable-workload-identity \
        --output none
else
    print_info "Tworzenie klastra AKS (to może potrwać 5-10 minut)..."
    az aks create \
        --resource-group $RESOURCE_GROUP \
        --name $AKS_CLUSTER_NAME \
        --node-count 2 \
        --enable-oidc-issuer \
        --enable-workload-identity \
        --generate-ssh-keys \
        --output none
fi

print_success "Klaster AKS gotowy"

# Pobierz credentials
print_info "Pobieranie kubeconfig..."
az aks get-credentials \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_CLUSTER_NAME \
    --overwrite-existing \
    --output none

print_success "kubeconfig skonfigurowany"

# Pobierz OIDC Issuer URL
print_info "Pobieranie OIDC Issuer URL..."
AKS_OIDC_ISSUER=$(az aks show \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_CLUSTER_NAME \
    --query "oidcIssuerProfile.issuerUrl" \
    --output tsv)

print_info "OIDC Issuer: $AKS_OIDC_ISSUER"

###############################################################################
# INSTALACJA CSI DRIVER
###############################################################################

print_header "3. Instalacja Secrets Store CSI Driver"

print_info "Włączanie CSI Driver add-on..."
az aks enable-addons \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_CLUSTER_NAME \
    --addons azure-keyvault-secrets-provider \
    --output none

print_success "CSI Driver zainstalowany"

# Weryfikacja
print_info "Weryfikacja instalacji CSI Driver..."
kubectl wait --for=condition=Ready pod \
    -l app=secrets-store-csi-driver \
    -n kube-system \
    --timeout=60s

print_success "CSI Driver działa"

###############################################################################
# UTWORZENIE KEY VAULT
###############################################################################

print_header "4. Tworzenie Azure Key Vault"

print_info "Tworzenie Key Vault: $KEYVAULT_NAME..."
az keyvault create \
    --name $KEYVAULT_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --enable-rbac-authorization true \
    --output none

print_success "Key Vault utworzony"

# Pobierz Key Vault URL
KEYVAULT_URL=$(az keyvault show \
    --name $KEYVAULT_NAME \
    --query properties.vaultUri \
    --output tsv)

print_info "Key Vault URL: $KEYVAULT_URL"

# Dodaj przykładowe secrety
print_info "Dodawanie przykładowych secretów..."

az keyvault secret set \
    --vault-name $KEYVAULT_NAME \
    --name db-password \
    --value "P@ssw0rd123!Demo" \
    --output none

az keyvault secret set \
    --vault-name $KEYVAULT_NAME \
    --name api-key \
    --value "sk_test_demo_key_12345" \
    --output none

az keyvault secret set \
    --vault-name $KEYVAULT_NAME \
    --name database-url \
    --value "postgresql://user:pass@db.example.com:5432/mydb" \
    --output none

print_success "Secrety dodane do Key Vault"

###############################################################################
# UTWORZENIE MANAGED IDENTITY
###############################################################################

print_header "5. Tworzenie Managed Identity"

print_info "Tworzenie User-Assigned Managed Identity..."
az identity create \
    --resource-group $RESOURCE_GROUP \
    --name $USER_ASSIGNED_IDENTITY_NAME \
    --output none

print_success "Managed Identity utworzona"

# Pobierz Client ID i Principal ID
USER_ASSIGNED_CLIENT_ID=$(az identity show \
    --resource-group $RESOURCE_GROUP \
    --name $USER_ASSIGNED_IDENTITY_NAME \
    --query clientId \
    --output tsv)

USER_ASSIGNED_PRINCIPAL_ID=$(az identity show \
    --resource-group $RESOURCE_GROUP \
    --name $USER_ASSIGNED_IDENTITY_NAME \
    --query principalId \
    --output tsv)

print_info "Client ID: $USER_ASSIGNED_CLIENT_ID"
print_info "Principal ID: $USER_ASSIGNED_PRINCIPAL_ID"

###############################################################################
# UPRAWNIENIA DO KEY VAULT
###############################################################################

print_header "6. Nadawanie uprawnień do Key Vault"

print_info "Przypisywanie roli 'Key Vault Secrets User'..."

# Pobierz Key Vault scope
KEYVAULT_SCOPE=$(az keyvault show \
    --name $KEYVAULT_NAME \
    --query id \
    --output tsv)

# Poczekaj chwilę na propagację identity
sleep 10

az role assignment create \
    --role "Key Vault Secrets User" \
    --assignee-object-id $USER_ASSIGNED_PRINCIPAL_ID \
    --assignee-principal-type ServicePrincipal \
    --scope $KEYVAULT_SCOPE \
    --output none

print_success "Uprawnienia nadane"

###############################################################################
# FEDERATED IDENTITY CREDENTIAL
###############################################################################

print_header "7. Tworzenie Federated Identity Credential"

print_info "Łączenie Kubernetes Service Account z Managed Identity..."

az identity federated-credential create \
    --name "kubernetes-federated-credential" \
    --identity-name $USER_ASSIGNED_IDENTITY_NAME \
    --resource-group $RESOURCE_GROUP \
    --issuer $AKS_OIDC_ISSUER \
    --subject "system:serviceaccount:${SERVICE_ACCOUNT_NAMESPACE}:${SERVICE_ACCOUNT_NAME}" \
    --output none

print_success "Federated credential utworzony"

###############################################################################
# GENEROWANIE PLIKÓW YAML
###############################################################################

print_header "8. Generowanie plików Kubernetes YAML"

# Service Account
cat > 01-service-account.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $SERVICE_ACCOUNT_NAME
  namespace: $SERVICE_ACCOUNT_NAMESPACE
  annotations:
    azure.workload.identity/client-id: "$USER_ASSIGNED_CLIENT_ID"
EOF

print_success "Utworzono: 01-service-account.yaml"

# SecretProviderClass
cat > 02-secret-provider-class.yaml <<EOF
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-keyvault-secrets
  namespace: $SERVICE_ACCOUNT_NAMESPACE
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
        - |
          objectName: database-url
          objectType: secret
          objectAlias: DATABASE_URL
  secretObjects:
  - secretName: app-secrets
    type: Opaque
    data:
    - objectName: DB_PASSWORD
      key: db-password
    - objectName: API_KEY
      key: api-key
    - objectName: DATABASE_URL
      key: database-url
EOF

print_success "Utworzono: 02-secret-provider-class.yaml"

# Test Pod
cat > 03-test-pod.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: test-keyvault-pod
  namespace: $SERVICE_ACCOUNT_NAMESPACE
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: $SERVICE_ACCOUNT_NAME
  containers:
  - name: nginx
    image: nginx:latest
    ports:
    - containerPort: 80
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
    command: ["/bin/sh"]
    args: 
    - -c
    - |
      echo "=== Key Vault Secrets Test ==="
      echo "Secrety jako pliki:"
      ls -la /mnt/secrets/
      echo ""
      echo "Zawartość DB_PASSWORD (z pliku):"
      cat /mnt/secrets/DB_PASSWORD
      echo ""
      echo "Zawartość API_KEY (z env):"
      echo \$API_KEY
      echo ""
      echo "=== Test zakończony - nginx startuje ==="
      nginx -g 'daemon off;'
  volumes:
  - name: secrets-store
    csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: azure-keyvault-secrets
EOF

print_success "Utworzono: 03-test-pod.yaml"

# Deployment przykład
cat > 04-deployment-example.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-demo
  namespace: $SERVICE_ACCOUNT_NAMESPACE
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
        azure.workload.identity/use: "true"
    spec:
      serviceAccountName: $SERVICE_ACCOUNT_NAME
      containers:
      - name: app
        image: nginx:alpine
        ports:
        - containerPort: 80
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
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: database-url
      volumes:
      - name: secrets-store
        csi:
          driver: secrets-store.csi.k8s.io
          readOnly: true
          volumeAttributes:
            secretProviderClass: azure-keyvault-secrets
---
apiVersion: v1
kind: Service
metadata:
  name: web-app-service
  namespace: $SERVICE_ACCOUNT_NAMESPACE
spec:
  selector:
    app: web-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: LoadBalancer
EOF

print_success "Utworzono: 04-deployment-example.yaml"

###############################################################################
# APLIKACJA DO KUBERNETES
###############################################################################

print_header "9. Aplikacja zasobów do Kubernetes"

print_info "Tworzenie Service Account..."
kubectl apply -f 01-service-account.yaml

print_info "Tworzenie SecretProviderClass..."
kubectl apply -f 02-secret-provider-class.yaml

print_info "Tworzenie test pod..."
kubectl apply -f 03-test-pod.yaml

print_success "Zasoby zastosowane"

###############################################################################
# WERYFIKACJA
###############################################################################

print_header "10. Weryfikacja"

print_info "Czekanie na start poda (może potrwać do 2 minut)..."

# Poczekaj na pod
for i in {1..24}; do
    STATUS=$(kubectl get pod test-keyvault-pod -n $SERVICE_ACCOUNT_NAMESPACE -o jsonpath='{.status.phase}' 2>/dev/null || echo "Pending")
    
    if [ "$STATUS" == "Running" ]; then
        print_success "Pod jest Running!"
        break
    fi
    
    echo -n "."
    sleep 5
done

echo ""

# Sprawdź status
POD_STATUS=$(kubectl get pod test-keyvault-pod -n $SERVICE_ACCOUNT_NAMESPACE -o jsonpath='{.status.phase}' 2>/dev/null || echo "Failed")

if [ "$POD_STATUS" == "Running" ]; then
    print_success "✅ SUCCESS! Key Vault integration działa!"
    
    echo ""
    print_info "Sprawdzanie secretów w podzie..."
    
    echo ""
    echo "=== Pliki w /mnt/secrets: ==="
    kubectl exec test-keyvault-pod -n $SERVICE_ACCOUNT_NAMESPACE -- ls -la /mnt/secrets/
    
    echo ""
    echo "=== Zawartość DB_PASSWORD: ==="
    kubectl exec test-keyvault-pod -n $SERVICE_ACCOUNT_NAMESPACE -- cat /mnt/secrets/DB_PASSWORD
    
    echo ""
    echo "=== Kubernetes Secret (app-secrets): ==="
    kubectl get secret app-secrets -n $SERVICE_ACCOUNT_NAMESPACE -o jsonpath='{.data}' | jq
    
    echo ""
    print_success "Wszystko działa poprawnie! 🎉"
    
else
    print_error "Pod nie wystartował poprawnie"
    echo ""
    echo "Sprawdź logi:"
    echo "  kubectl describe pod test-keyvault-pod -n $SERVICE_ACCOUNT_NAMESPACE"
    echo "  kubectl logs test-keyvault-pod -n $SERVICE_ACCOUNT_NAMESPACE"
    echo ""
    echo "Sprawdź logi CSI Driver:"
    echo "  kubectl logs -n kube-system -l app=secrets-store-csi-driver --tail=50"
fi

###############################################################################
# PODSUMOWANIE
###############################################################################

print_header "PODSUMOWANIE"

cat <<EOF

📦 Utworzone zasoby Azure:
  - Resource Group: $RESOURCE_GROUP
  - AKS Cluster: $AKS_CLUSTER_NAME
  - Key Vault: $KEYVAULT_NAME
  - Managed Identity: $USER_ASSIGNED_IDENTITY_NAME

🔑 Key Vault secrety:
  - db-password
  - api-key  
  - database-url

📁 Utworzone pliki YAML:
  - 01-service-account.yaml
  - 02-secret-provider-class.yaml
  - 03-test-pod.yaml
  - 04-deployment-example.yaml

🧪 Testy:
  # Sprawdź secrety w podzie:
  kubectl exec test-keyvault-pod -- cat /mnt/secrets/DB_PASSWORD
  
  # Sprawdź Kubernetes Secret:
  kubectl get secret app-secrets -o yaml
  
  # Dodaj nowy secret do Key Vault:
  az keyvault secret set --vault-name $KEYVAULT_NAME --name new-secret --value "test123"
  
  # Deploy przykładowej aplikacji:
  kubectl apply -f 04-deployment-example.yaml

🧹 Czyszczenie (usuń wszystko):
  az group delete --name $RESOURCE_GROUP --yes --no-wait

📚 Dokumentacja:
  - Główny dokument: ../KeyVault_Integration.md
  - Azure Docs: https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-driver

EOF

print_success "Setup zakończony! 🚀"

