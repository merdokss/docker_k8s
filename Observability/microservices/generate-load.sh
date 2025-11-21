#!/bin/bash

# Skrypt do generowania load na mikroserwisy
# Wywołuje frontend-service, który wywołuje cały łańcuch serwisów

FRONTEND_URL="${FRONTEND_URL:-http://frontend-service.default.svc.cluster.local:8080}"

echo "🚀 Generowanie load na mikroserwisy"
echo "Frontend URL: ${FRONTEND_URL}"
echo ""
echo "Wywołania będą wykonywane w pętli..."
echo "Naciśnij Ctrl+C aby zatrzymać"
echo ""

# Funkcja do wywołania endpointu
call_endpoint() {
    local endpoint=$1
    local params=$2
    echo "📞 Wywołanie: ${endpoint}${params:+?$params}"
    curl -s "${FRONTEND_URL}${endpoint}${params:+?$params}" | jq '.' 2>/dev/null || echo "Response received"
    echo ""
}

counter=0
while true; do
    counter=$((counter + 1))
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Iteracja #${counter}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Wywołaj różne endpointy
    call_endpoint "/api/order" "order_id=order-${counter}"
    sleep 1
    
    call_endpoint "/api/user" "user_id=user-123"
    sleep 1
    
    # Co 5 iteracji wywołaj też główny endpoint
    if [ $((counter % 5)) -eq 0 ]; then
        call_endpoint "/"
        sleep 1
    fi
    
    sleep 0.5
done

