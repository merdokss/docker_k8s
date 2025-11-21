#!/bin/bash
# Skrypt instalacji MetalLB dla Kubernetes
# 
# Użycie:
#   chmod +x install.sh
#   ./install.sh [version]
#
# Przykład:
#   ./install.sh v0.15.2
#   ./install.sh  # użyje domyślnej wersji

set -e

# Domyślna wersja MetalLB
DEFAULT_VERSION="v0.15.2"
VERSION=${1:-$DEFAULT_VERSION}

# Kolory dla outputu
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}MetalLB Installation Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Sprawdź czy kubectl jest dostępny
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl nie jest zainstalowany${NC}"
    exit 1
fi

# Sprawdź połączenie z klastrem
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Brak połączenia z klastrem Kubernetes${NC}"
    exit 1
fi

echo -e "${YELLOW}Krok 1: Sprawdzanie klastra Kubernetes...${NC}"
kubectl cluster-info
echo ""

# Sprawdź czy MetalLB jest już zainstalowany
if kubectl get namespace metallb-system &> /dev/null; then
    echo -e "${YELLOW}MetalLB jest już zainstalowany w namespace metallb-system${NC}"
    read -p "Czy chcesz kontynuować instalację? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

echo -e "${YELLOW}Krok 2: Instalacja MetalLB wersji ${VERSION}...${NC}"
MANIFEST_URL="https://raw.githubusercontent.com/metallb/metallb/${VERSION}/config/manifests/metallb-native.yaml"

if ! kubectl apply -f "$MANIFEST_URL"; then
    echo -e "${RED}Error: Nie udało się zainstalować MetalLB${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Krok 3: Oczekiwanie na gotowość podów MetalLB...${NC}"
kubectl wait --namespace metallb-system \
    --for=condition=ready pod \
    --selector=app=metallb \
    --timeout=300s || {
    echo -e "${RED}Error: Pody MetalLB nie są gotowe${NC}"
    kubectl get pods -n metallb-system
    exit 1
}

echo ""
echo -e "${YELLOW}Krok 4: Sprawdzanie statusu instalacji...${NC}"
kubectl get pods -n metallb-system
kubectl get crd | grep metallb || echo -e "${YELLOW}CRD mogą być jeszcze w trakcie tworzenia...${NC}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}MetalLB został zainstalowany pomyślnie!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Następne kroki:${NC}"
echo "1. Skonfiguruj pulę adresów IP:"
echo "   kubectl apply -f metallb-config-l2.yaml"
echo ""
echo "2. Sprawdź konfigurację:"
echo "   kubectl get ipaddresspool -n metallb-system"
echo "   kubectl get l2advertisement -n metallb-system"
echo ""
echo "3. Utwórz testową usługę LoadBalancer:"
echo "   kubectl create deployment nginx --image=nginx"
echo "   kubectl expose deployment nginx --type=LoadBalancer --port=80"
echo "   kubectl get svc nginx"
echo ""
echo -e "${YELLOW}Przydatne komendy:${NC}"
echo "  kubectl get pods -n metallb-system"
echo "  kubectl logs -n metallb-system -l app=metallb-controller"
echo "  kubectl logs -n metallb-system -l app=metallb-speaker"
echo "  kubectl get ipaddresspool,l2advertisement,bgppeer -n metallb-system"
echo ""

