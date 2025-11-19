#!/bin/bash

# =============================================================================
# KONFIGURACJA - zmień te wartości na swoje
# =============================================================================
RESOURCE_GROUP="sages-k8s"
LOCATION="northeurope"                    # lub: northeurope, eastus
AKS_NAME="sages-aks"
NODE_COUNT=2
NODE_SIZE="Standard_D2s_v3"              # 2 vCPU, 8GB RAM - wystarczy do szkoleń
K8S_VERSION="1.33"                       # lub sprawdź: az aks get-versions -l westeurope -o table

# =============================================================================
# INSTALACJA
# =============================================================================


echo ""
echo "🚀 Tworzę klaster AKS"

az aks create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$AKS_NAME" \
    --location "$LOCATION" \
    --kubernetes-version "$K8S_VERSION" \
    \
    `# === NODES ===` \
    --node-count $NODE_COUNT \
    --node-vm-size "$NODE_SIZE" \
    --max-pods 30 \
    \
    `# === NETWORKING (Azure CNI dla Network Policies) ===` \
    --network-plugin azure \
    --network-policy azure \
    \
    `# === IDENTITY (nowoczesne podejście - bez Service Principal) ===` \
    --enable-managed-identity \
    --enable-workload-identity \
    --enable-oidc-issuer \
    \
    `# === SECURITY ADD-ONS ===` \
    --enable-addons azure-policy,azure-keyvault-secrets-provider,monitoring \
    # --enable-defender \
    \
    `# === RBAC ===` \
    `# Aby użyć Azure RBAC, odkomentuj poniższe linie:` \
    `# --enable-aad \` \
    `# --enable-azure-rbac \` \
    `# --aad-admin-group-object-ids "$(az ad signed-in-user show --query id -o tsv)" \` \
    \
    `# === MISC ===` \
    `# --generate-ssh-keys \` \
    `# --tags "Environment=Training" "Purpose=Security-Labs" "Owner=$(az account show --query user.name -o tsv)" \` \
    `# --yes`

echo "✅ Klaster utworzony!"
echo ""
echo "📥 Pobieram credentials..."
az aks get-credentials \
    --resource-group "$RESOURCE_GROUP" \
    --name "$AKS_NAME" \
    --overwrite-existing

echo ""
echo "🎉 Gotowe! Sprawdź:"
kubectl get nodes
kubectl get pods -A