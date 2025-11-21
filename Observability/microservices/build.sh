#!/bin/bash

# Skrypt do budowania wszystkich obrazów Docker dla mikroserwisów
# Używa registry: dawidsages.azurecr.io

set -e

REGISTRY="dawidsages.azurecr.io"
SERVICES=("frontend-service" "service-a" "service-b" "service-c")

echo "🔨 Budowanie obrazów Docker dla mikroserwisów"
echo "Registry: ${REGISTRY}"
echo ""

for service in "${SERVICES[@]}"; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 Budowanie: ${service}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    cd "${service}"
    
    # Buduj obraz
    docker build -t ${service}:latest .
    docker tag ${service}:latest ${REGISTRY}/${service}:latest
    
    echo "✅ Obraz zbudowany: ${service}:latest"
    echo "✅ Otagowany: ${REGISTRY}/${service}:latest"
    
    # Opcjonalnie: załaduj do kind (jeśli używasz kind)
    if command -v kind &> /dev/null; then
        echo "📦 Ładowanie obrazu do kind..."
        kind load docker-image ${service}:latest
        echo "✅ Obraz załadowany do kind"
    fi
    
    cd ..
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Wszystkie obrazy zbudowane!"
echo ""
echo "💡 Aby wypchnąć obrazy do registry:"
echo "   docker login ${REGISTRY}"
for service in "${SERVICES[@]}"; do
    echo "   docker push ${REGISTRY}/${service}:latest"
done
echo ""
echo "💡 Aby zainstalować w Kubernetes:"
echo "   kubectl apply -f deployment.yaml"

