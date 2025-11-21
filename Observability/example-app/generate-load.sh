#!/bin/bash

# Skrypt do generowania różnorodnego load na aplikację

APP_URL="${APP_URL:-http://example-app.default.svc.cluster.local:8080}"

echo "🚀 Generowanie load na aplikację: $APP_URL"
echo "Naciśnij Ctrl+C aby zatrzymać"
echo ""

# Funkcja do generowania różnych typów requestów
generate_load() {
    local counter=0
    while true; do
        counter=$((counter + 1))
        
        # Różne endpointy
        case $((counter % 4)) in
            0)
                echo "[$counter] GET /api/hello?name=User$counter"
                curl -s "$APP_URL/api/hello?name=User$counter" > /dev/null
                ;;
            1)
                num1=$((RANDOM % 100))
                num2=$((RANDOM % 100))
                num3=$((RANDOM % 100))
                echo "[$counter] GET /api/calculate?numbers=$num1&numbers=$num2&numbers=$num3"
                curl -s "$APP_URL/api/calculate?numbers=$num1&numbers=$num2&numbers=$num3" > /dev/null
                ;;
            2)
                echo "[$counter] GET /api/connection?action=connect"
                curl -s "$APP_URL/api/connection?action=connect" > /dev/null
                ;;
            3)
                echo "[$counter] GET /api/connection?action=disconnect"
                curl -s "$APP_URL/api/connection?action=disconnect" > /dev/null
                ;;
        esac
        
        # Czasami generuj błąd
        if [ $((counter % 20)) -eq 0 ]; then
            echo "[$counter] GET /api/error (generowanie błędu)"
            curl -s "$APP_URL/api/error" > /dev/null
        fi
        
        sleep 0.5
    done
}

# Sprawdź czy aplikacja jest dostępna
if ! curl -s "$APP_URL/health" > /dev/null; then
    echo "❌ Aplikacja nie jest dostępna pod adresem: $APP_URL"
    echo "   Sprawdź czy aplikacja jest uruchomiona: kubectl get pods -l app=example-app"
    exit 1
fi

echo "✅ Aplikacja jest dostępna"
echo ""

generate_load

