#!/bin/bash

# Skrypt do budowania obrazu Docker dla example-app

IMAGE_NAME="example-app"
IMAGE_TAG="latest"

echo "🔨 Budowanie obrazu Docker: ${IMAGE_NAME}:${IMAGE_TAG}"

docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

echo "✅ Obraz zbudowany: ${IMAGE_NAME}:${IMAGE_TAG}"

# Opcjonalnie: załaduj do kind (jeśli używasz kind)
if command -v kind &> /dev/null; then
    echo "📦 Ładowanie obrazu do kind..."
    kind load docker-image ${IMAGE_NAME}:${IMAGE_TAG}
    echo "✅ Obraz załadowany do kind"
fi

echo ""
echo "💡 Aby użyć obrazu w Kubernetes:"
echo "   kubectl apply -f deployment.yaml"

