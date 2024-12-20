# Rozwiązania Ćwiczeń Docker Compose

## Rozwiązanie 1: Pierwsza kompozycja

### Struktura projektu
```
exercise1/
├── docker-compose.yml
└── website/
    └── index.html
```

### docker-compose.yml
```yaml
version: '3'
services:
  webserver:
    # Używamy oficjalnego obrazu nginx w stabilnej wersji
    image: nginx:stable
    # Nadajemy własną nazwę dla lepszej identyfikacji
    container_name: exercise1-nginx
    # Mapujemy port 8080 hosta na port 80 kontenera
    ports:
      - "8080:80"
    # Montujemy naszą stronę HTML do odpowiedniego katalogu w nginx
    volumes:
      - ./website:/usr/share/nginx/html
```

### website/index.html
```html
<!DOCTYPE html>
<html>
<head>
    <title>Docker Compose Exercise 1</title>
</head>
<body>
    <h1>Hello from Nginx container!</h1>
    <p>This page is served from a Docker container using Nginx.</p>
</body>
</html>
```

## Rozwiązanie 2: Multi-container setup

### Struktura projektu
```
exercise2/
├── docker-compose.yml
├── backend/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── app.py
└── nginx/
    └── nginx.conf
```

### docker-compose.yml
```yaml
version: '3'

services:
  backend:
    # Budujemy backend z lokalnego Dockerfile
    build: ./backend
    container_name: exercise2-backend
    # Nie publikujemy portu na zewnątrz - tylko dla nginx
    expose:
      - "5000"
    # Dołączamy do sieci dla komunikacji między serwisami
    networks:
      - app-network

  nginx:
    image: nginx:stable
    container_name: exercise2-nginx
    # Port dostępny na zewnątrz
    ports:
      - "8080:80"
    # Konfiguracja nginx
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf
    # Zależność od backendu
    depends_on:
      - backend
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
```

### backend/Dockerfile
```dockerfile
FROM python:3.9-slim

WORKDIR /app

# Instalujemy zależności
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

CMD ["python", "app.py"]
```

### backend/requirements.txt
```
flask==2.0.1
```

### backend/app.py
```python
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/api/status')
def status():
    return jsonify({
        'status': 'ok',
        'message': 'Backend is running'
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

### nginx/nginx.conf
```nginx
server {
    listen 80;
    server_name localhost;

    # Przekierowanie /api na backend
    location /api {
        proxy_pass http://backend:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Rozwiązanie 3: Zarządzanie zależnościami

### Struktura projektu
```
exercise3/
├── docker-compose.yml
├── backend/
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── app.py
│   └── wait-for-it.sh
└── .env
```

### docker-compose.yml
```yaml
version: '3'

services:
  database:
    image: postgres:13
    container_name: exercise3-db
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - db-data:/var/lib/postgresql/data
    # Healthcheck dla bazy danych
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER} -d ${DB_NAME}"]
      interval: 5s
      timeout: 5s
      retries: 5

  backend:
    build: ./backend
    container_name: exercise3-backend
    environment:
      DATABASE_URL: postgresql://${DB_USER}:${DB_PASSWORD}@database:5432/${DB_NAME}
    depends_on:
      database:
        condition: service_healthy
    # Używamy skryptu wait-for-it
    command: ["./wait-for-it.sh", "database:5432", "--", "python", "app.py"]

volumes:
  db-data:
```
### wait-for-it.sh

```
#!/bin/bash

# Host i port z argumentów
host="$1"
port="$2"

# Funkcja testująca połączenie
until nc -z "$host" "$port"; do
  echo "Czekam na $host:$port..."
  sleep 1
done

echo "$host:$port jest dostępny"

# Uruchom właściwą komendę (wszystko po --)
exec "${@:2}"
```

### .env
```
DB_NAME=testdb
DB_USER=testuser
DB_PASSWORD=testpass
```

### backend/app.py
```python
from flask import Flask
import psycopg2
import os

app = Flask(__name__)

def get_db_connection():
    return psycopg2.connect(os.environ['DATABASE_URL'])

@app.route('/health')
def health():
    conn = get_db_connection()
    conn.close()
    return {'status': 'healthy', 'database': 'connected'}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

## Rozwiązanie 4: Środowiska deweloperskie

### docker-compose.yml
```yaml
version: '3'

services:
  frontend:
    build:
      context: ./frontend
      target: development
    volumes:
      # Montujemy kod źródłowy
      - ./frontend/src:/app/src
      # Volume dla node_modules
      - frontend-modules:/app/node_modules
    environment:
      - NODE_ENV=development
    ports:
      - "3000:3000"
    command: npm run start

  backend:
    build:
      context: ./backend
      target: development
    volumes:
      - ./backend:/app
      - backend-modules:/app/node_modules
    environment:
      - NODE_ENV=development
    command: npm run dev
    ports:
      - "5000:5000"
      # Port dla debuggera
      - "9229:9229"

volumes:
  frontend-modules:
  backend-modules:
```

### frontend/Dockerfile
```dockerfile
# Stage dla developmentu
FROM node:16 AS development

WORKDIR /app

# Instalujemy zależności
COPY package*.json ./
RUN npm install

# Kopiujemy kod źródłowy
COPY . .

# Stage dla produkcji
FROM node:16 AS production

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build
```

## Rozwiązanie 5: Deployment stack

### docker-compose.yml
```yaml
version: '3'

services:
  app:
    build: .
    ports:
      - "8080:8080"
    # Eksportujemy metryki dla Prometheusa
    expose:
      - "9090"
    labels:
      - "prometheus.scrape=true"
      - "prometheus.port=9090"

  prometheus:
    image: prom/prometheus
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    ports:
      - "9091:9090"
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.retention.time=15d'

  grafana:
    image: grafana/grafana
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
    ports:
      - "3000:3000"
    depends_on:
      - prometheus

  backup:
    image: postgres:13
    volumes:
      - db-data:/source/data:ro
      - ./backups:/backup
    command: |
      bash -c 'pg_dump -h database -U $$POSTGRES_USER $$POSTGRES_DB > /backup/dump_$$(date +%Y%m%d_%H%M%S).sql'
    environment:
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - POSTGRES_DB=${DB_NAME}

volumes:
  prometheus-data:
  grafana-data:
  db-data:
```

### prometheus/prometheus.yml
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'app'
    static_configs:
      - targets: ['app:9090']
```

## Zadanie dodatkowe: Load Balancing

### docker-compose.yml
```yaml
version: '3'

services:
  load-balancer:
    image: nginx
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
    ports:
      - "80:80"
    depends_on:
      - backend

  backend:
    build: ./backend
    # Skalujemy do 3 instancji
    deploy:
      replicas: 3
    environment:
      - REDIS_HOST=redis

  redis:
    image: redis:alpine
    volumes:
      - redis-data:/data

volumes:
  redis-data:
```

### nginx/nginx.conf
```nginx
events {
    worker_connections 1024;
}

http {
    upstream backend {
        # Włączamy sticky sessions
        ip_hash;
        server backend:8080;
    }

    server {
        listen 80;
        
        location / {
            proxy_pass http://backend;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
}
```

## Wskazówki do uruchamiania rozwiązań

Dla każdego rozwiązania:

1. Przejdź do odpowiedniego katalogu z rozwiązaniem:
```bash
cd exerciseX
```

2. Zbuduj i uruchom kontenery:
```bash
docker-compose up --build
```

3. Sprawdź logi:
```bash
docker-compose logs -f
```

4. Zatrzymaj i wyczyść środowisko:
```bash
docker-compose down -v
```

## Najważniejsze elementy w rozwiązaniach

1. Wykorzystanie networks do izolacji usług
2. Prawidłowa konfiguracja volumes dla persystencji danych
3. Wykorzystanie zmiennych środowiskowych
4. Implementacja healthchecks
5. Konfiguracja wait-for-it dla zależności
6. Separacja konfiguracji dev/prod
7. Implementacja backupów
8. Konfiguracja monitoringu

## Testowanie rozwiązań

Dla każdego rozwiązania warto przeprowadzić testy:

1. Sprawdź dostępność usług:
```bash
curl http://localhost:8080/health
```

2. Zweryfikuj logi:
```bash
docker-compose logs backend
```

3. Sprawdź połączenia sieciowe:
```bash
docker network inspect exercise2_app-network
```

4. Przetestuj persystencję danych:
```bash
docker-compose down
docker-compose up -d
# Sprawdź czy dane przetrwały restart
```

Te rozwiązania można dostosować do konkretnych potrzeb projektu, modyfikując konfiguracje i dodając dodatkowe funkcjonalności według potrzeb.