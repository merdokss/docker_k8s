#!/bin/bash

set -e

# Kolory dla outputu
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Instalacja Stack Observability${NC}"
echo ""

# Sprawdź czy Helm jest zainstalowany
if ! command -v helm &> /dev/null; then
    echo -e "${YELLOW}⚠️  Helm nie jest zainstalowany. Zainstaluj Helm 3.x${NC}"
    exit 1
fi

# Sprawdź czy kubectl jest skonfigurowany
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${YELLOW}⚠️  kubectl nie jest skonfigurowany lub klaster nie jest dostępny${NC}"
    exit 1
fi

NAMESPACE="monitoring"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}📦 Dodawanie repozytoriów Helm...${NC}"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

echo ""
echo -e "${BLUE}📁 Tworzenie namespace: ${NAMESPACE}${NC}"
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo -e "${BLUE}📊 Instalacja kube-prometheus-stack...${NC}"
helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace ${NAMESPACE} \
  --values ${SCRIPT_DIR}/prometheus-stack-values.yaml \
  --wait \
  --timeout 10m

echo ""
echo -e "${BLUE}🔍 Instalacja Grafana Tempo...${NC}"
helm upgrade --install tempo grafana/tempo \
  --namespace ${NAMESPACE} \
  --values ${SCRIPT_DIR}/tempo-values.yaml \
  --wait \
  --timeout 10m

echo ""
echo -e "${BLUE}📝 Instalacja Grafana Loki...${NC}"
helm upgrade --install loki grafana/loki \
  --namespace ${NAMESPACE} \
  --values ${SCRIPT_DIR}/loki-values.yaml \
  --wait \
  --timeout 10m

echo ""
echo -e "${BLUE}🔧 Konfiguracja datasources Grafana...${NC}"
kubectl apply -f ${SCRIPT_DIR}/grafana-datasources.yaml

# Czekaj na restart Grafana
echo -e "${YELLOW}⏳ Oczekiwanie na restart Grafana (30s)...${NC}"
sleep 30

echo ""
echo -e "${GREEN}✅ Stack Observability zainstalowany!${NC}"
echo ""
echo -e "${BLUE}📋 Status podów:${NC}"
kubectl get pods -n ${NAMESPACE}

echo ""
echo -e "${BLUE}🌐 Dostęp do Grafana:${NC}"
echo "   Grafana jest dostępna przez LoadBalancer:"
echo "   kubectl get svc -n ${NAMESPACE} prometheus-stack-grafana"
echo "   Otwórz przeglądarkę na adresie z kolumny EXTERNAL-IP"
echo ""
echo "   Alternatywa - port-forward:"
echo "   kubectl port-forward -n ${NAMESPACE} svc/prometheus-stack-grafana 3000:80"
echo ""
echo -e "${BLUE}🔑 Domyślne dane logowania:${NC}"
echo "   Username: admin"
echo "   Password: admin123"
echo ""
echo -e "${BLUE}📊 Dostęp do Prometheus:${NC}"
echo "   kubectl port-forward -n ${NAMESPACE} svc/prometheus-stack-kube-prom-prometheus 9090:9090"
echo ""
echo -e "${YELLOW}💡 Następne kroki:${NC}"
echo "   1. Zbuduj i zainstaluj przykładową aplikację:"
echo "      cd example-app && ./build.sh"
echo "      kubectl apply -f deployment.yaml"
echo "   2. Wygeneruj load na aplikację:"
echo "      kubectl run -it --rm load-gen --image=curlimages/curl --restart=Never -- \\"
echo "        sh -c 'while true; do curl http://example-app.default.svc.cluster.local:8080/api/hello; sleep 1; done'"

