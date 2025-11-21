#!/bin/bash
# Skrypt instalacji CloudNativePG Operator

set -e

echo "=== Instalacja CloudNativePG Operator ==="

# Wersja operatora
OPERATOR_VERSION="1.23.0"
NAMESPACE="cnpg-system"

echo "1. Tworzenie namespace dla operatora..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

echo "2. Instalacja CloudNativePG Operator v${OPERATOR_VERSION}..."
kubectl apply -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.23/releases/cnpg-${OPERATOR_VERSION}.yaml

echo "3. Oczekiwanie na gotowość operatora..."
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=cloudnative-pg \
  -n ${NAMESPACE} \
  --timeout=300s

echo "4. Sprawdzanie zainstalowanych CRD..."
kubectl get crd | grep postgresql

echo "5. Tworzenie namespace dla PostgreSQL..."
kubectl create namespace postgres --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "=== Instalacja zakończona pomyślnie! ==="
echo ""
echo "Sprawdź status:"
echo "  kubectl get pods -n ${NAMESPACE}"
echo "  kubectl get crd | grep postgresql"
echo ""
echo "Teraz możesz utworzyć klaster PostgreSQL:"
echo "  kubectl apply -f postgres-cluster-basic.yaml"

