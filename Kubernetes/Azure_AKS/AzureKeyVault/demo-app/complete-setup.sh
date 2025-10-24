#!/bin/bash

# Kontynuacja konfiguracji - Managed Identity i Federated Credential

set -e

KEYVAULT_NAME="kv-aks-demo-1761282322"
RESOURCE_GROUP="rg_dawid"
AKS_CLUSTER="dama-operator2"
LOCATION="polandcentral"
IDENTITY_NAME="id-keyvault-demo"
NAMESPACE="default"
SERVICE_ACCOUNT_NAME="workload-identity-sa"

echo "🔧 Dokańczam konfigurację Azure Key Vault dla AKS"
echo "================================================"
echo ""

# Pobierz OIDC Issuer i Tenant ID
AKS_OIDC_ISSUER=$(az aks show \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_CLUSTER \
  --query "oidcIssuerProfile.issuerUrl" \
  --output tsv)

TENANT_ID=$(az account show --query tenantId --output tsv)

echo "📋 Parametry:"
echo "   Key Vault: $KEYVAULT_NAME"
echo "   OIDC Issuer: $AKS_OIDC_ISSUER"
echo "   Tenant ID: $TENANT_ID"
echo ""

# Utwórz Managed Identity
echo "1️⃣  Tworzę User-Assigned Managed Identity..."
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
echo "2️⃣  Nadaję uprawnienia do Key Vault..."
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
echo "3️⃣  Tworzę Federated Identity Credential..."
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
echo "4️⃣  Zapisuję konfigurację..."
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
echo "5️⃣  Generuję pliki Kubernetes..."

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

echo "   ✅ Pliki Kubernetes wygenerowane:"
echo "      - serviceaccount.yaml"
echo "      - secretproviderclass.yaml"
echo ""

echo "✅ Konfiguracja zakończona pomyślnie!"
echo ""
echo "📝 Następne kroki:"
echo ""
echo "1. Zastosuj zasoby Kubernetes:"
echo "   kubectl apply -f serviceaccount.yaml"
echo "   kubectl apply -f secretproviderclass.yaml"
echo "   kubectl apply -f deployment.yaml"
echo ""
echo "2. Sprawdź status:"
echo "   kubectl get pods -l app=keyvault-demo"
echo "   kubectl get secret app-secrets"
echo ""
echo "3. Pobierz External IP LoadBalancera:"
echo "   kubectl get svc keyvault-demo"
echo ""
echo "4. Weryfikuj działanie:"
echo "   kubectl exec -it deployment/keyvault-demo -- ls -la /mnt/secrets"
echo ""

