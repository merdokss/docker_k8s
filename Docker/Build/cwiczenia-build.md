# Kompletny Zestaw Ćwiczeń Docker

## Poziom 1: Podstawy Dockera

### Ćwiczenie 1: Budowanie prostego obrazu Docker

1. Utwórz plik o nazwie `Dockerfile` z następującą zawartością:
   ```
   FROM alpine:latest
   RUN echo "Witaj w moim kontenerze!" > /powitanie.txt
   CMD cat /powitanie.txt
   ```

2. Zbuduj obraz Docker używając polecenia:
   ```
   docker build -t moj-pierwszy-obraz .
   ```

3. Uruchom kontener z nowo utworzonego obrazu:
   ```
   docker run moj-pierwszy-obraz
   ```

### Ćwiczenie 2: Budowanie i uruchamianie aplikacji webowej

1. Utwórz plik `index.html` z prostą stroną internetową:
   ```html
   <!DOCTYPE html>
   <html>
   <head>
       <title>Moja strona Docker</title>
   </head>
   <body>
       <h1>Witaj w świecie Docker!</h1>
       <p>To jest prosta strona hostowana w kontenerze.</p>
   </body>
   </html>
   ```

2. Utwórz `Dockerfile` z następującą zawartością:
   ```
   FROM nginx:alpine
   COPY index.html /usr/share/nginx/html/index.html
   EXPOSE 80
   ```

3. Zbuduj obraz Docker:
   ```
   docker build -t moja-strona-web .
   ```

4. Uruchom kontener, mapując port 8080 hosta na port 80 kontenera:
   ```
   docker run -d -p 8080:80 moja-strona-web

5. Otwórz przeglądarkę i wejdź na adres `http://localhost:8080`, aby zobaczyć swoją stronę.

### Ćwiczenie 3: Uruchamianie kontenerów Ubuntu w sieci

1. Utwórz nową sieć Docker o nazwie `moja-siec`:
   ```
   docker network create moja-siec
   ```

2. Uruchom pierwszy kontener Ubuntu o nazwie `ubuntu1`:
   ```
   docker run -d --name ubuntu1 --network moja-siec ubuntu:latest sleep infinity
   ```

3. Uruchom drugi kontener Ubuntu o nazwie `ubuntu2`:
   ```
   docker run -d --name ubuntu2 --network moja-siec ubuntu:latest sleep infinity
   ```

4. Zainstaluj `curl` w obu kontenerach:
   ```
   docker exec ubuntu1 apt-get update && docker exec ubuntu1 apt-get install -y curl
   docker exec ubuntu2 apt-get update && docker exec ubuntu2 apt-get install -y curl
   ```

5. Sprawdź połączenie między kontenerami używając `curl`:
   ```
   docker exec ubuntu1 curl ubuntu2
   docker exec ubuntu2 curl ubuntu1

## Poziom 2: Praca z Wolumenami i Zmiennymi Środowiskowymi

### Ćwiczenie 4: Persystencja danych w MongoDB

Cel: Zrozumienie koncepcji wolumenów i persystencji danych.

1. Utwórz named volume dla danych MongoDB:
   ```bash
   docker volume create mongodb_data
   ```

2. Uruchom kontener MongoDB z wolumenem:
   ```bash
   docker run -d \
     --name mongodb \
     -v mongodb_data:/data/db \
     -e MONGO_INITDB_ROOT_USERNAME=admin \
     -e MONGO_INITDB_ROOT_PASSWORD=secret \
     mongo:latest
   ```

3. Dodaj przykładowe dane:
   ```bash
   docker exec -it mongodb mongosh -u admin -p secret
   # W konsoli mongo:
   use testdb
   db.users.insertOne({name: "Test User", email: "test@example.com"})
   ```

4. Zatrzymaj i usuń kontener:
   ```bash
   docker stop mongodb
   docker rm mongodb
   ```

5. Uruchom nowy kontener z tym samym wolumenem i sprawdź, czy dane są nadal dostępne.

## Poziom 3: Multi-stage Builds i Optymalizacja

### Ćwiczenie 5: Optymalizacja obrazu aplikacji Node.js

Cel: Nauka tworzenia zoptymalizowanych obrazów przy użyciu multi-stage builds.

1. Utwórz przykładową aplikację Node.js:
   ```bash
   mkdir node-app && cd node-app
   npm init -y
   npm install express
   ```

2. Stwórz plik `app.js`:
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

3. Utwórz Dockerfile z multi-stage build:
   ```dockerfile
   # Stage 1: Dependencies
   FROM node:16 AS deps
   WORKDIR /app
   COPY package*.json ./
   RUN npm ci --only=production
   
   # Stage 2: Runtime
   FROM node:16-slim
   WORKDIR /app
   COPY --from=deps /app/node_modules ./node_modules
   COPY . .
   USER node
   EXPOSE 3000
   CMD ["node", "app.js"]
   ```

4. Zbuduj i porównaj rozmiary obrazów:
   ```bash
   docker build -t node-app:v1 .
   docker images | grep node-app
   ```

## Poziom 4: Debugging i Monitorowanie

### Ćwiczenie 6: Konfiguracja Monitoringu z Prometheus i Grafana

Cel: Nauka monitorowania kontenerów i zbierania metryk.

1. Utwórz plik `prometheus.yml`:
   ```yaml
   global:
     scrape_interval: 15s
   
   scrape_configs:
     - job_name: 'docker'
       static_configs:
         - targets: ['host.docker.internal:9323']
   ```

2. Uruchom Prometheus:
   ```bash
   docker run -d \
     --name prometheus \
     -p 9090:9090 \
     -v $(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml \
     prom/prometheus
   ```

3. Uruchom Grafana:
   ```bash
   docker run -d \
     --name grafana \
     -p 3000:3000 \
     grafana/grafana
   ```

4. Skonfiguruj dashboard w Grafana (dostęp przez http://localhost:3000):
   - Dodaj źródło danych Prometheus
   - Zaimportuj dashboard dla metryk Dockera

## Poziom 5: Wdrożenie Mikroserwisów

### Ćwiczenie 7: Aplikacja z API Gateway

Cel: Zrozumienie architektury mikroserwisów i routingu.

1. Utwórz sieć dla mikroserwisów:
   ```bash
   docker network create microservices
   ```

2. Dockerfile dla API Gateway (nginx):
   ```dockerfile
   FROM nginx:alpine
   COPY nginx.conf /etc/nginx/nginx.conf
   ```

3. Konfiguracja nginx (`nginx.conf`):
   ```nginx
   events {
       worker_connections 1024;
   }
   
   http {
       upstream auth_service {
           server auth:5000;
       }
       
       upstream api_service {
           server api:5001;
       }
       
       server {
           listen 80;
           
           location /auth {
               proxy_pass http://auth_service;
           }
           
           location /api {
               proxy_pass http://api_service;
           }
       }
   }
   ```

4. Uruchom wszystkie serwisy:
   ```bash
   # Auth service
   docker run -d --name auth --network microservices \
     -e SERVICE_NAME=auth python-auth-service
   
   # API service
   docker run -d --name api --network microservices \
     -e SERVICE_NAME=api python-api-service
   
   # Gateway
   docker run -d --name gateway --network microservices \
     -p 8080:80 nginx-gateway
   ```

## Wskazówki i Dobre Praktyki

### Debugowanie:
- Używaj `docker logs [container]` do sprawdzania logów
- `docker exec -it [container] sh` do wejścia do kontenera
- `docker inspect [container]` do sprawdzenia szczegółów kontenera

### Optymalizacja:
- Używaj `.dockerignore` do wykluczenia niepotrzebnych plików
- Łącz polecenia RUN aby zmniejszyć liczbę warstw
- Używaj multi-stage builds dla aplikacji produkcyjnych

### Bezpieczeństwo:
- Nie uruchamiaj kontenerów jako root
- Używaj obrazów bazowych z zaufanych źródeł
- Regularnie aktualizuj obrazy ze względu na poprawki bezpieczeństwa

## Rozwiązywanie Problemów

1. Problem: Kontener się nie uruchamia
   Rozwiązanie: 
   - Sprawdź logi: `docker logs [container]`
   - Sprawdź status: `docker ps -a`
   - Zweryfikuj konfigurację sieci

2. Problem: Brak dostępu do wolumenów
   Rozwiązanie:
   - Sprawdź uprawnienia na hoście
   - Zweryfikuj ścieżki montowania
   - Użyj `docker volume inspect`

3. Problem: Problemy z siecią
   Rozwiązanie:
   - Sprawdź konfigurację DNS
   - Zweryfikuj reguły firewalla
   - Użyj `docker network inspect`

