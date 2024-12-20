# Rozwiązania Ćwiczeń Docker

## Poziom 1: Podstawy Dockera

### Rozwiązanie Ćwiczenia 1: Budowanie prostego obrazu Docker

Przeanalizujmy każdy element Dockerfile:

```dockerfile
# Używamy Alpine Linux jako bazowego obrazu ze względu na jego mały rozmiar
# Alpine to minimalistyczna dystrybucja Linuxa, idealna dla kontenerów
FROM alpine:latest

# Komenda RUN wykonuje się podczas budowania obrazu
# Używamy echo do utworzenia pliku tekstowego
# Przekierowanie > zapisuje wynik do pliku
RUN echo "Witaj w moim kontenerze!" > /powitanie.txt

# CMD definiuje domyślne polecenie wykonywane przy starcie kontenera
# W tym przypadku wyświetlamy zawartość utworzonego wcześniej pliku
CMD cat /powitanie.txt
```

Proces budowania i uruchamiania:

```bash
# Budowanie obrazu
# -t nadaje tag (nazwę) naszemu obrazowi
# . oznacza, że Dockerfile znajduje się w bieżącym katalogu
docker build -t moj-pierwszy-obraz .

# Uruchamianie kontenera
# Kontener wykona polecenie CMD i zakończy działanie
docker run moj-pierwszy-obraz
```

### Rozwiązanie Ćwiczenia 2: Budowanie i uruchamianie aplikacji webowej

Przeanalizujmy strukturę rozwiązania:

index.html:
```html
<!DOCTYPE html>
<html>
<head>
    <!-- Tytuł strony widoczny w zakładce przeglądarki -->
    <title>Moja strona Docker</title>
</head>
<body>
    <!-- Prosty content strony -->
    <h1>Witaj w świecie Docker!</h1>
    <p>To jest prosta strona hostowana w kontenerze.</p>
</body>
</html>
```

Dockerfile:
```dockerfile
# Używamy oficjalnego obrazu nginx w wersji alpine dla mniejszego rozmiaru
FROM nginx:alpine

# Kopiujemy nasz plik HTML do domyślnego katalogu nginx
# Pierwszy parametr to ścieżka źródłowa (względem kontekstu budowania)
# Drugi parametr to ścieżka docelowa w kontenerze
COPY index.html /usr/share/nginx/html/index.html

# EXPOSE informuje, że kontener będzie nasłuchiwał na porcie 80
# Jest to tylko dokumentacja - faktyczne wystawienie portu następuje przy uruchomieniu
EXPOSE 80
```

Komendy do uruchomienia:
```bash
# Budowanie obrazu
docker build -t moja-strona-web .

# Uruchamianie kontenera
# -d uruchamia kontener w tle (detached mode)
# -p mapuje port 8080 hosta na port 80 kontenera
docker run -d -p 8080:80 moja-strona-web

# Sprawdzenie czy kontener działa
docker ps

# Sprawdzenie logów kontenera
docker logs $(docker ps -q --filter ancestor=moja-strona-web)
```

### Rozwiązanie Ćwiczenia 3: Uruchamianie kontenerów Ubuntu w sieci

Proces krok po kroku:

```bash
# Tworzenie nowej sieci bridge
# Bridge to domyślny typ sieci umożliwiający komunikację między kontenerami
docker network create moja-siec

# Uruchamianie pierwszego kontenera Ubuntu
# --name nadaje nazwę kontenerowi
# --network przyłącza kontener do utworzonej sieci
# sleep infinity utrzymuje kontener w działaniu
docker run -d --name ubuntu1 --network moja-siec ubuntu:latest sleep infinity

# Uruchamianie drugiego kontenera
docker run -d --name ubuntu2 --network moja-siec ubuntu:latest sleep infinity

# Instalacja curl w kontenerach
# Aktualizacja repozytoriów i instalacja curl w pierwszym kontenerze
docker exec ubuntu1 bash -c "apt-get update && apt-get install -y curl"

# To samo dla drugiego kontenera
docker exec ubuntu2 bash -c "apt-get update && apt-get install -y curl"

# Test połączenia między kontenerami
# Uwaga: curl nie zadziała bez serwera HTTP, lepiej użyć ping
docker exec ubuntu1 ping -c 4 ubuntu2
docker exec ubuntu2 ping -c 4 ubuntu1
```

## Poziom 2: Praca z Wolumenami i Zmiennymi Środowiskowymi

### Rozwiązanie Ćwiczenia 4: Persystencja danych w MongoDB

Szczegółowe wyjaśnienie rozwiązania:

```bash
# Tworzenie nazwanego wolumenu
# Named volume będzie przechowywał dane MongoDB niezależnie od życia kontenera
docker volume create mongodb_data

# Uruchamianie MongoDB z wolumenem
docker run -d \
  --name mongodb \
  -v mongodb_data:/data/db \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=secret \
  mongo:latest

# Wejście do powłoki mongo i dodanie danych testowych
docker exec -it mongodb mongosh -u admin -p secret

# Komendy w konsoli mongo:
use testdb
db.users.insertOne({
  name: "Test User",
  email: "test@example.com",
  createdAt: new Date()
})

# Wyjście z konsoli mongo
exit

# Zatrzymanie i usunięcie kontenera
docker stop mongodb
docker rm mongodb

# Uruchomienie nowego kontenera z tym samym wolumenem
docker run -d \
  --name mongodb-new \
  -v mongodb_data:/data/db \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=secret \
  mongo:latest

# Sprawdzenie czy dane przetrwały
docker exec -it mongodb-new mongosh -u admin -p secret --eval 'use testdb; db.users.find()'
```

## Poziom 3: Multi-stage Builds i Optymalizacja

### Rozwiązanie Ćwiczenia 5: Optymalizacja obrazu aplikacji Node.js

Struktura projektu i pliki:

package.json:
```json
{
  "name": "node-app",
  "version": "1.0.0",
  "main": "app.js",
  "dependencies": {
    "express": "^4.17.1"
  }
}
```

app.js:
```javascript
const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.send('Hello from optimized Node.js container!');
});

app.listen(3000, () => {
  console.log('App running on port 3000');
});
```

Dockerfile z komentarzami:
```dockerfile
# Stage 1: Instalacja zależności
FROM node:16 AS deps
WORKDIR /app
# Kopiujemy tylko pliki package*.json, aby wykorzystać cache podczas budowania
COPY package*.json ./
# Używamy npm ci zamiast npm install dla bardziej przewidywalnych instalacji
RUN npm ci --only=production

# Stage 2: Finalny obraz
FROM node:16-slim
WORKDIR /app
# Kopiujemy node_modules z poprzedniego etapu
COPY --from=deps /app/node_modules ./node_modules
# Kopiujemy kod źródłowy
COPY . .
# Zmieniamy użytkownika na nieprivilegowanego
USER node
# Informujemy o porcie aplikacji
EXPOSE 3000
# Uruchamiamy aplikację
CMD ["node", "app.js"]
```

Komendy do zbudowania i uruchomienia:
```bash
# Budowanie obrazu
docker build -t node-app:v1 .

# Sprawdzenie rozmiaru obrazu
docker images node-app:v1

# Uruchomienie kontenera
docker run -d -p 3000:3000 node-app:v1

# Sprawdzenie działania
curl http://localhost:3000
```

## Poziom 4: Debugging i Monitorowanie

### Rozwiązanie Ćwiczenia 6: Konfiguracja Monitoringu z Prometheus i Grafana

Konfiguracja Prometheus (prometheus.yml):
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'docker'
    static_configs:
      - targets: ['host.docker.internal:9323']
```

Uruchomienie stosu monitorującego:
```bash
# Uruchomienie Prometheus
docker run -d \
  --name prometheus \
  -p 9090:9090 \
  -v $(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus

# Uruchomienie Grafana
docker run -d \
  --name grafana \
  -p 3000:3000 \
  grafana/grafana

# Sprawdzenie statusu kontenerów
docker ps

# Sprawdzenie logów
docker logs prometheus
docker logs grafana
```

Konfiguracja Grafana:
1. Otwórz http://localhost:3000 (login: admin, hasło: admin)
2. Dodaj źródło danych Prometheus:
   - URL: http://prometheus:9090
   - Access: Browser
3. Importuj dashboard dla Docker:
   - Dashboard ID: 893
   - Wybierz źródło danych Prometheus

## Poziom 5: Wdrożenie Mikroserwisów

### Rozwiązanie Ćwiczenia 7: Aplikacja z API Gateway

Struktura projektu:
```
microservices/
├── gateway/
│   ├── Dockerfile
│   └── nginx.conf
├── auth-service/
│   ├── Dockerfile
│   └── app.py
└── api-service/
    ├── Dockerfile
    └── app.py
```

nginx.conf dla API Gateway:
```nginx
events {
    worker_connections 1024;
}

http {
    # Definicje upstream dla mikrousług
    upstream auth_service {
        server auth:5000;
    }
    
    upstream api_service {
        server api:5001;
    }
    
    server {
        listen 80;
        
        # Routing dla auth service
        location /auth {
            proxy_pass http://auth_service;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
        
        # Routing dla api service
        location /api {
            proxy_pass http://api_service;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
```

Uruchomienie wszystkich komponentów:
```bash
# Tworzenie sieci dla mikroserwisów
docker network create microservices

# Uruchomienie auth service
docker run -d \
  --name auth \
  --network microservices \
  -e SERVICE_NAME=auth \
  python-auth-service

# Uruchomienie api service
docker run -d \
  --name api \
  --network microservices \
  -e SERVICE_NAME=api \
  python-api-service

# Uruchomienie gateway
docker run -d \
  --name gateway \
  --network microservices \
  -p 8080:80 \
  nginx-gateway

# Sprawdzenie statusu wszystkich usług
docker ps

# Test działania
curl http://localhost:8080/auth/status
curl http://localhost:8080/api/status
```

## Wskazówki do rozwiązywania problemów

Debugging kontenerów:
```bash
# Sprawdzenie szczegółowych informacji o kontenerze
docker inspect container_name

# Sprawdzenie logów kontenera
docker logs -f container_name

# Wejście do działającego kontenera
docker exec -it container_name bash

# Sprawdzenie wykorzystania zasobów
docker stats container_name
```

Zarządzanie siecią:
```bash
# Lista wszystkich sieci
docker network ls

# Szczegóły sieci
docker network inspect network_name

# Podłączenie kontenera do sieci
docker network connect network_name container_name
```

Zarządzanie wolumenami:
```bash
# Lista wolumenów
docker volume ls

# Szczegóły wolumenu
docker volume inspect volume_name

# Usunięcie nieużywanych wolumenów
docker volume prune
```