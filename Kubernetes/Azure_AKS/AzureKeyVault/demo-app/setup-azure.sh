#!/bin/bash

# Skrypt do konfiguracji Azure Key Vault dla AKS
# Automatyzuje proces opisany w dokumentacji

set -e

echo "🔧 Konfiguracja Azure Key Vault dla AKS"
echo "======================================="
echo ""

# Parametry (dostosuj do swojego środowiska)
RESOURCE_GROUP="rg_dawid"
AKS_CLUSTER="dama-operator2"
LOCATION="polandcentral"
KEYVAULT_NAME="kv-aks-demo-$(date +%s)"
IDENTITY_NAME="id-keyvault-demo"
NAMESPACE="default"
SERVICE_ACCOUNT_NAME="workload-identity-sa"

echo "📋 Parametry:"
echo "   Resource Group: $RESOURCE_GROUP"
echo "   AKS Cluster: $AKS_CLUSTER"
echo "   Location: $LOCATION"
echo "   Key Vault Name: $KEYVAULT_NAME"
echo "   Identity Name: $IDENTITY_NAME"
echo ""

# Pobierz informacje o klastrze
echo "1️⃣  Pobieram informacje o klastrze AKS..."
AKS_OIDC_ISSUER=$(az aks show \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_CLUSTER \
  --query "oidcIssuerProfile.issuerUrl" \
  --output tsv)

TENANT_ID=$(az account show --query tenantId --output tsv)

echo "   ✅ OIDC Issuer: $AKS_OIDC_ISSUER"
echo "   ✅ Tenant ID: $TENANT_ID"
echo ""

# Utwórz Key Vault
echo "2️⃣  Tworzę Azure Key Vault..."
az keyvault create \
  --name $KEYVAULT_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --enable-rbac-authorization true \
  --output none

echo "   ✅ Key Vault utworzony: $KEYVAULT_NAME"

# Nadaj uprawnienia użytkownikowi do zarządzania secretami
CURRENT_USER_ID=$(az ad signed-in-user show --query id -o tsv)
KEYVAULT_SCOPE=$(az keyvault show \
  --name $KEYVAULT_NAME \
  --query id \
  --output tsv)

echo "   📝 Nadaję uprawnienia użytkownikowi..."
az role assignment create \
  --role "Key Vault Secrets Officer" \
  --assignee $CURRENT_USER_ID \
  --scope $KEYVAULT_SCOPE \
  --output none

echo "   ⏳ Czekam 10s na propagację uprawnień..."
sleep 10
echo ""

# Dodaj sekrety
echo "3️⃣  Dodaję przykładowe sekrety do Key Vault..."
az keyvault secret set \
  --vault-name $KEYVAULT_NAME \
  --name db-password \
  --value "P@ssw0rd123!SecureDB" \
  --output none

az keyvault secret set \
  --vault-name $KEYVAULT_NAME \
  --name api-key \
  --value "sk_live_abc123xyz789demo" \
  --output none

az keyvault secret set \
  --vault-name $KEYVAULT_NAME \
  --name connection-string \
  --value "Server=myserver.database.windows.net;Database=mydb;User=admin;Password=SecretPass123!" \
  --output none

echo "   ✅ Dodano 3 sekrety: db-password, api-key, connection-string"
echo ""

# Utwórz Managed Identity
echo "4️⃣  Tworzę User-Assigned Managed Identity..."
az identity create \
  --resource-group $RESOURCE_GROUP \
  --name $IDENTITY_NAME \
  --location $LOCATION \
  --output none

USER_ASSIGNED_CLIENT_ID=$(az identity show \
  --resource-group $RESOURCE_GROUP \
  --name $IDENTITY_NAME \
  --query clientId \
  --output tsv)

USER_ASSIGNED_PRINCIPAL_ID=$(az identity show \
  --resource-group $RESOURCE_GROUP \
  --name $IDENTITY_NAME \
  --query principalId \
  --output tsv)

echo "   ✅ Identity utworzona"
echo "   Client ID: $USER_ASSIGNED_CLIENT_ID"
echo "   Principal ID: $USER_ASSIGNED_PRINCIPAL_ID"
echo ""

# Nadaj uprawnienia do Key Vault
echo "5️⃣  Nadaję uprawnienia do Key Vault..."
KEYVAULT_SCOPE=$(az keyvault show \
  --name $KEYVAULT_NAME \
  --query id \
  --output tsv)

az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee $USER_ASSIGNED_CLIENT_ID \
  --scope $KEYVAULT_SCOPE \
  --output none

echo "   ✅ Nadano rolę 'Key Vault Secrets User'"
echo ""

# Utwórz Federated Identity Credential
echo "6️⃣  Tworzę Federated Identity Credential..."
az identity federated-credential create \
  --name "kubernetes-federated-credential" \
  --identity-name $IDENTITY_NAME \
  --resource-group $RESOURCE_GROUP \
  --issuer $AKS_OIDC_ISSUER \
  --subject "system:serviceaccount:${NAMESPACE}:${SERVICE_ACCOUNT_NAME}" \
  --output none

echo "   ✅ Federated Credential utworzony"
echo ""

# Zapisz konfigurację do pliku
echo "7️⃣  Zapisuję konfigurację..."
cat > config.env <<EOF
export RESOURCE_GROUP="$RESOURCE_GROUP"
export AKS_CLUSTER="$AKS_CLUSTER"
export KEYVAULT_NAME="$KEYVAULT_NAME"
export USER_ASSIGNED_CLIENT_ID="$USER_ASSIGNED_CLIENT_ID"
export TENANT_ID="$TENANT_ID"
export NAMESPACE="$NAMESPACE"
export SERVICE_ACCOUNT_NAME="$SERVICE_ACCOUNT_NAME"
EOF

echo "   ✅ Konfiguracja zapisana w pliku config.env"
echo ""

# Generuj pliki Kubernetes
echo "8️⃣  Generuję pliki Kubernetes..."

cat > serviceaccount.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $SERVICE_ACCOUNT_NAME
  namespace: $NAMESPACE
  annotations:
    azure.workload.identity/client-id: "$USER_ASSIGNED_CLIENT_ID"
EOF

cat > secretproviderclass.yaml <<EOF
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-keyvault-secrets
  namespace: $NAMESPACE
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
          objectName: connection-string
          objectType: secret
          objectAlias: CONNECTION_STRING
  secretObjects:
  - secretName: app-secrets
    type: Opaque
    data:
    - objectName: DB_PASSWORD
      key: db-password
    - objectName: API_KEY
      key: api-key
    - objectName: CONNECTION_STRING
      key: connection-string
EOF

echo "   ✅ Pliki Kubernetes wygenerowane"
echo ""

echo "✅ Konfiguracja zakończona!"
echo ""
echo "📝 Następne kroki:"
echo "   1. Źródło konfiguracji: source config.env"
echo "   2. Zastosuj zasoby: kubectl apply -f ."
echo "   3. Wdróż aplikację: kubectl apply -f deployment.yaml"
echo ""
echo "🔍 Weryfikacja:"
echo "   kubectl get secretproviderclass"
echo "   kubectl get serviceaccount workload-identity-sa"
echo "   kubectl get pods"
echo ""

