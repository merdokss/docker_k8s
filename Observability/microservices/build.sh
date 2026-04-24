#!/bin/bash

# Skrypt do budowania wszystkich obrazów Docker dla mikroserwisów
# Używa registry: dawidsages.azurecr.io
# Buduje obrazy multi-platform (amd64 + arm64) za pomocą buildx

set -e

REGISTRY="dawidsages.azurecr.io"
SERVICES=("frontend-service" "service-a" "service-b" "service-c")
PLATFORMS="linux/amd64,linux/arm64"
BUILDER_NAME="multiarch"

echo "🔨 Budowanie obrazów Docker dla mikroserwisów"
echo "Registry: ${REGISTRY}"
echo "Platforms: ${PLATFORMS}"
echo ""

# Upewnij się, że builder multi-platform istnieje
if ! docker buildx inspect ${BUILDER_NAME} &> /dev/null; then
    echo "📐 Tworzenie buildera multi-platform: ${BUILDER_NAME}"
    docker buildx create --name ${BUILDER_NAME} --driver docker-container --use
    docker buildx inspect --bootstrap
else
    docker buildx use ${BUILDER_NAME}
fi

for service in "${SERVICES[@]}"; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 Budowanie: ${service}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    cd "${service}"

    docker buildx build \
        --platform ${PLATFORMS} \
        -t ${REGISTRY}/${service}:latest \
        --push \
        .

    echo "✅ Obraz zbudowany i wypchnięty: ${REGISTRY}/${service}:latest"

    cd ..
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Wszystkie obrazy zbudowane i wypchnięte!"
echo ""
echo "💡 Aby zainstalować w Kubernetes:"
echo "   kubectl apply -f deployment.yaml"

