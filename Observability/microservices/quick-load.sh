#!/bin/bash
# Szybki skrypt do generowania load na mikroserwisy

echo "🚀 Generowanie load na mikroserwisy..."
echo ""

# Liczba requestów (domyślnie 20)
REQUESTS=${1:-20}
DELAY=${2:-1}

echo "Requesty: $REQUESTS, Opóźnienie: ${DELAY}s"
echo ""

kubectl run -it --rm load-gen-quick --image=curlimages/curl --restart=Never -- \
  sh -c "
    echo '🚀 Generowanie $REQUESTS requestów...'
    for i in \$(seq 1 $REQUESTS); do
      echo \"[Request \$i] Wywołuję /api/order...\"
      curl -s \"http://frontend-service.default.svc.cluster.local:8080/api/order?order_id=test-\$i\" > /dev/null
      echo \"  ✓ OK\"
      sleep $DELAY
    done
    echo ''
    echo '✅ Wygenerowano $REQUESTS requestów'
    echo '💡 Sprawdź traces w Grafana: Explore → Tempo → service.name=frontend-service'
  "

