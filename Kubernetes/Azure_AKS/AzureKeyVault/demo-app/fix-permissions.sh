#!/bin/bash

KEYVAULT_NAME="kv-aks-demo-1761282322"
RESOURCE_GROUP="rg_dawid"

echo "Nadawanie uprawnień do Key Vault..."

CURRENT_USER_ID=$(az ad signed-in-user show --query id -o tsv)
echo "User ID: $CURRENT_USER_ID"

KEYVAULT_SCOPE=$(az keyvault show --name $KEYVAULT_NAME --query id --output tsv)
echo "Key Vault Scope: $KEYVAULT_SCOPE"

az role assignment create \
  --role "Key Vault Secrets Officer" \
  --assignee $CURRENT_USER_ID \
  --scope $KEYVAULT_SCOPE

echo "Czekam 10s na propagację uprawnień..."
sleep 10

echo "Dodawanie secretów..."
az keyvault secret set \
  --vault-name $KEYVAULT_NAME \
  --name db-password \
  --value "P@ssw0rd123!SecureDB"

az keyvault secret set \
  --vault-name $KEYVAULT_NAME \
  --name api-key \
  --value "sk_live_abc123xyz789demo"

az keyvault secret set \
  --vault-name $KEYVAULT_NAME \
  --name connection-string \
  --value "Server=myserver.database.windows.net;Database=mydb;User=admin;Password=SecretPass123!"

echo "✅ Sekrety dodane pomyślnie!"

