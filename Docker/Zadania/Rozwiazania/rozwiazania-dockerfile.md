# Rozwiązania - Zadania Dockerfile i Budowanie Obrazów

## Poziom 1: Podstawy Dockerfile

### Rozwiązanie Zadania 1.1: Pierwszy Dockerfile

```bash
# 1. Utworzenie katalogu
mkdir moja-aplikacja
cd moja-aplikacja

# 2. Utworzenie Dockerfile
cat > Dockerfile << 'EOF'
FROM alpine:latest
RUN echo "Witaj w moim kontenerze!" > /powitanie.txt
CMD cat /powitanie.txt
EOF

# 3. Zbudowanie obrazu
docker build -t moja-aplikacja:v1.0 .

# 4. Uruchomienie kontenera
docker run moja-aplikacja:v1.0

# 5. Sprawdzenie czy wyświetla się komunikat powitalny
# Powinien wyświetlić: "Witaj w moim kontenerze!"
```

**Wyjaśnienie:**
- `FROM alpine:latest` - używa Alpine Linux jako obraz bazowy
- `RUN echo "..." > /powitanie.txt` - tworzy plik tekstowy podczas budowania
- `CMD cat /powitanie.txt` - wyświetla zawartość pliku przy uruchomieniu
- `docker build -t moja-aplikacja:v1.0 .` - buduje obraz z tagiem

### Rozwiązanie Zadania 1.2: Aplikacja webowa z nginx

```bash
# 1. Utworzenie pliku index.html
cat > index.html << 'EOF'
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
EOF

# 2. Utworzenie Dockerfile
cat > Dockerfile << 'EOF'
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
EOF

# 3. Zbudowanie obrazu
docker build -t moja-strona:v1.0 .

# 4. Uruchomienie kontenera
docker run -d -p 8080:80 moja-strona:v1.0

# 5. Sprawdzenie czy strona jest dostępna
curl http://localhost:8080
# lub otwórz przeglądarkę i wejdź na http://localhost:8080

# 6. Czyszczenie
docker stop $(docker ps -q --filter ancestor=moja-strona:v1.0)
docker rm $(docker ps -aq --filter ancestor=moja-strona:v1.0)
```

**Wyjaśnienie:**
- `FROM nginx:alpine` - używa nginx w wersji alpine
- `COPY index.html /usr/share/nginx/html/index.html` - kopiuje plik HTML do katalogu nginx
- `EXPOSE 80` - informuje o porcie, na którym aplikacja nasłuchuje
- `-p 8080:80` - mapuje port 8080 hosta na port 80 kontenera

### Rozwiązanie Zadania 1.3: Aplikacja Node.js

```bash
# 1. Utworzenie katalogu
mkdir node-app
cd node-app

# 2. Utworzenie package.json
cat > package.json << 'EOF'
{
  "name": "node-app",
  "version": "1.0.0",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  },
  "dependencies": {
    "express": "^4.18.0"
  }
}
EOF

# 3. Utworzenie app.js
cat > app.js << 'EOF'
const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.send('Hello from Docker Node.js app!');
});

app.listen(3000, () => {
  console.log('App running on port 3000');
});
EOF

# 4. Utworzenie Dockerfile
cat > Dockerfile << 'EOF'
FROM node:16
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
EOF

# 5. Zbudowanie obrazu
docker build -t node-app:v1.0 .

# 6. Uruchomienie kontenera
docker run -d -p 3000:3000 node-app:v1.0

# 7. Sprawdzenie czy aplikacja odpowiada
curl http://localhost:3000

# 8. Czyszczenie
docker stop $(docker ps -q --filter ancestor=node-app:v1.0)
docker rm $(docker ps -aq --filter ancestor=node-app:v1.0)
```

**Wyjaśnienie:**
- `WORKDIR /usr/src/app` - ustawia katalog roboczy
- `COPY package*.json ./` - kopiuje pliki zależności przed kodem
- `RUN npm install` - instaluje zależności
- `COPY . .` - kopiuje resztę plików aplikacji

## Poziom 2: Optymalizacja Dockerfile

### Rozwiązanie Zadania 2.1: Optymalizacja warstw

```bash
# 1. Utworzenie katalogu
mkdir optimized-app
cd optimized-app

# 2. Utworzenie nieoptymalnego Dockerfile
cat > Dockerfile.bad << 'EOF'
FROM ubuntu:20.04
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y wget
RUN apt-get install -y vim
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*
CMD ["bash"]
EOF

# 3. Zbudowanie nieoptymalnego obrazu
docker build -f Dockerfile.bad -t optimized-app:bad .

# 4. Sprawdzenie rozmiaru
docker images optimized-app:bad

# 5. Utworzenie zoptymalizowanego Dockerfile
cat > Dockerfile.good << 'EOF'
FROM ubuntu:20.04
RUN apt-get update && \
    apt-get install -y curl wget vim && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
CMD ["bash"]
EOF

# 6. Zbudowanie zoptymalizowanego obrazu
docker build -f Dockerfile.good -t optimized-app:good .

# 7. Porównanie rozmiarów
docker images optimized-app

# 8. Sprawdzenie historii warstw
docker history optimized-app:bad
docker history optimized-app:good

# 9. Czyszczenie
docker rmi optimized-app:bad optimized-app:good
```

**Wyjaśnienie:**
- Nieoptymalny Dockerfile tworzy 6 warstw (każde RUN to nowa warstwa)
- Zoptymalizowany Dockerfile tworzy 2 warstwy (łączy polecenia RUN)
- Mniejsza liczba warstw = mniejszy rozmiar obrazu

### Rozwiązanie Zadania 2.2: Używanie .dockerignore

```bash
# 1. Przejście do katalogu node-app
cd ../node-app

# 2. Utworzenie .dockerignore
cat > .dockerignore << 'EOF'
node_modules
npm-debug.log
.git
.gitignore
README.md
.env
EOF

# 3. Utworzenie plików testowych
echo "Test file" > test.txt
echo "# Test README" > README.md
mkdir -p node_modules/test
echo "Test module" > node_modules/test/index.js

# 4. Zbudowanie obrazu
docker build -t node-app:with-dockerignore .

# 5. Sprawdzenie czy niepotrzebne pliki nie zostały skopiowane
docker run --rm node-app:with-dockerignore ls -la

# 6. Sprawdzenie rozmiaru kontekstu budowania
docker build --progress=plain -t node-app:with-dockerignore . 2>&1 | grep "transferring context"

# 7. Czyszczenie
rm test.txt README.md
rm -rf node_modules
docker rmi node-app:with-dockerignore
```

**Wyjaśnienie:**
- `.dockerignore` wyklucza pliki z kontekstu budowania
- Mniejszy kontekst = szybsze budowanie
- `node_modules` nie powinien być kopiowany (instaluje się przez npm install)

### Rozwiązanie Zadania 2.3: Multi-stage build

```bash
# 1. Utworzenie katalogu
mkdir multistage-app
cd multistage-app

# 2. Utworzenie aplikacji Go
cat > main.go << 'EOF'
package main

import (
    "fmt"
    "net/http"
)

func handler(w http.ResponseWriter, r *http.Request) {
    fmt.Fprintf(w, "Hello from Go container!")
}

func main() {
    http.HandleFunc("/", handler)
    http.ListenAndServe(":8080", nil)
}
EOF

# 3. Utworzenie Dockerfile z multi-stage build
cat > Dockerfile << 'EOF'
# Build stage
FROM golang:1.19 AS builder
WORKDIR /app
COPY . .
RUN go build -o main .

# Production stage
FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/main .
EXPOSE 8080
CMD ["./main"]
EOF

# 4. Zbudowanie obrazu
docker build -t multistage-app .

# 5. Sprawdzenie rozmiaru obrazu
docker images multistage-app

# 6. Uruchomienie kontenera
docker run -d -p 8080:8080 multistage-app

# 7. Sprawdzenie czy aplikacja działa
curl http://localhost:8080

# 8. Czyszczenie
docker stop $(docker ps -q --filter ancestor=multistage-app)
docker rm $(docker ps -aq --filter ancestor=multistage-app)
docker rmi multistage-app
```

**Wyjaśnienie:**
- Multi-stage build używa dwóch etapów: build i production
- Build stage kompiluje aplikację
- Production stage zawiera tylko skompilowaną aplikację
- Rezultat: mniejszy obraz produkcyjny

## Poziom 3: Zaawansowane techniki

### Rozwiązanie Zadania 3.1: Zmienne środowiskowe i ARG

```bash
# 1. Utworzenie katalogu
mkdir configurable-app
cd configurable-app

# 2. Utworzenie aplikacji Python
cat > app.py << 'EOF'
import os
from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    name = os.getenv('APP_NAME', 'Docker App')
    version = os.getenv('APP_VERSION', '1.0')
    return f'Hello from {name} v{version}!'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# 3. Utworzenie requirements.txt
cat > requirements.txt << 'EOF'
Flask==2.3.0
EOF

# 4. Utworzenie Dockerfile z ARG i ENV
cat > Dockerfile << 'EOF'
FROM python:3.9-slim

ARG APP_NAME=Docker App
ARG APP_VERSION=1.0

ENV APP_NAME=${APP_NAME}
ENV APP_VERSION=${APP_VERSION}

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .

EXPOSE 5000
CMD ["python", "app.py"]
EOF

# 5. Zbudowanie obrazu z domyślnymi wartościami
docker build -t configurable-app:v1.0 .

# 6. Uruchomienie z domyślnymi wartościami
docker run -d -p 5000:5000 configurable-app:v1.0
curl http://localhost:5000

# 7. Zatrzymanie kontenera
docker stop $(docker ps -q --filter ancestor=configurable-app:v1.0)
docker rm $(docker ps -aq --filter ancestor=configurable-app:v1.0)

# 8. Zbudowanie obrazu z niestandardowymi wartościami
docker build --build-arg APP_NAME="My Custom App" --build-arg APP_VERSION="2.0" -t configurable-app:v2.0 .

# 9. Uruchomienie z niestandardowymi wartościami
docker run -d -p 5000:5000 configurable-app:v2.0
curl http://localhost:5000

# 10. Czyszczenie
docker stop $(docker ps -q --filter ancestor=configurable-app:v2.0)
docker rm $(docker ps -aq --filter ancestor=configurable-app:v2.0)
docker rmi configurable-app:v1.0 configurable-app:v2.0
```

**Wyjaśnienie:**
- `ARG` definiuje zmienne dostępne podczas budowania
- `ENV` definiuje zmienne środowiskowe w kontenerze
- `--build-arg` pozwala przekazać wartości ARG podczas budowania

### Rozwiązanie Zadania 3.2: Healthcheck i monitoring

```bash
# 1. Utworzenie katalogu
mkdir monitored-app
cd monitored-app

# 2. Utworzenie aplikacji Node.js z endpointem health
cat > app.js << 'EOF'
const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.send('Hello from monitored app!');
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', timestamp: new Date() });
});

app.listen(3000, () => {
  console.log('App running on port 3000');
});
EOF

# 3. Utworzenie package.json
cat > package.json << 'EOF'
{
  "name": "monitored-app",
  "version": "1.0.0",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  },
  "dependencies": {
    "express": "^4.18.0"
  }
}
EOF

# 4. Utworzenie Dockerfile z healthcheck
cat > Dockerfile << 'EOF'
FROM node:16
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
COPY . .

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

CMD ["npm", "start"]
EOF

# 5. Zbudowanie obrazu
docker build -t monitored-app:v1.0 .

# 6. Uruchomienie kontenera
docker run -d --name monitored-container -p 3000:3000 monitored-app:v1.0

# 7. Sprawdzenie statusu healthcheck
docker ps
docker inspect monitored-container | grep -A 10 Health

# 8. Sprawdzenie logów healthcheck
docker logs monitored-container

# 9. Test endpointu health
curl http://localhost:3000/health

# 10. Czyszczenie
docker stop monitored-container
docker rm monitored-container
docker rmi monitored-app:v1.0
```

**Wyjaśnienie:**
- `HEALTHCHECK` definiuje sposób sprawdzania zdrowia kontenera
- `--interval=30s` - sprawdza co 30 sekund
- `--timeout=3s` - timeout na odpowiedź
- `--start-period=5s` - czas na uruchomienie aplikacji
- `--retries=3` - liczba prób przed oznaczeniem jako niezdrowy

### Rozwiązanie Zadania 3.3: Użytkownik nieprivilegowany

```bash
# 1. Utworzenie katalogu
mkdir secure-app
cd secure-app

# 2. Utworzenie aplikacji Python
cat > app.py << 'EOF'
import os
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def hello():
    return jsonify({
        'message': 'Hello from secure app',
        'user': os.getenv('USER', 'unknown'),
        'uid': os.getuid(),
        'gid': os.getgid()
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# 3. Utworzenie requirements.txt
cat > requirements.txt << 'EOF'
Flask==2.3.0
EOF

# 4. Utworzenie Dockerfile z nieprivilegowanym użytkownikiem
cat > Dockerfile << 'EOF'
FROM python:3.9-slim

# Utwórz użytkownika nieprivilegowanego
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .

# Zmień właściciela plików
RUN chown -R appuser:appuser /app

# Przełącz na użytkownika nieprivilegowanego
USER appuser

EXPOSE 5000
CMD ["python", "app.py"]
EOF

# 5. Zbudowanie obrazu
docker build -t secure-app .

# 6. Uruchomienie kontenera
docker run -d -p 5000:5000 secure-app

# 7. Sprawdzenie pod jakim użytkownikiem działa aplikacja
curl http://localhost:5000

# 8. Sprawdzenie użytkownika w kontenerze
docker exec $(docker ps -q --filter ancestor=secure-app) whoami
docker exec $(docker ps -q --filter ancestor=secure-app) id

# 9. Czyszczenie
docker stop $(docker ps -q --filter ancestor=secure-app)
docker rm $(docker ps -aq --filter ancestor=secure-app)
docker rmi secure-app
```

**Wyjaśnienie:**
- `groupadd -r appuser` - tworzy grupę systemową
- `useradd -r -g appuser appuser` - tworzy użytkownika systemowego
- `chown -R appuser:appuser /app` - zmienia właściciela plików
- `USER appuser` - przełącza na użytkownika nieprivilegowanego

## Poziom 4: Praktyczne scenariusze

### Rozwiązanie Zadania 4.1: Aplikacja z bazą danych

```bash
# 1. Utworzenie katalogu
mkdir webapp-with-db
cd webapp-with-db

# 2. Utworzenie aplikacji Python
cat > app.py << 'EOF'
import os
import sqlite3
from flask import Flask, jsonify

app = Flask(__name__)

def init_db():
    conn = sqlite3.connect('/app/data.db')
    cursor = conn.cursor()
    cursor.execute('CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT)')
    cursor.execute('INSERT OR IGNORE INTO users (name) VALUES (?)', ('John Doe',))
    conn.commit()
    conn.close()

@app.route('/')
def hello():
    return 'Hello from webapp with database!'

@app.route('/users')
def get_users():
    conn = sqlite3.connect('/app/data.db')
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM users')
    users = cursor.fetchall()
    conn.close()
    return jsonify(users)

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000)
EOF

# 3. Utworzenie requirements.txt
cat > requirements.txt << 'EOF'
Flask==2.3.0
EOF

# 4. Utworzenie Dockerfile
cat > Dockerfile << 'EOF'
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
RUN mkdir -p /app/data
EXPOSE 5000
CMD ["python", "app.py"]
EOF

# 5. Zbudowanie obrazu
docker build -t webapp-with-db .

# 6. Utworzenie wolumenu dla bazy danych
docker volume create webapp-data

# 7. Uruchomienie kontenera z wolumenem
docker run -d --name webapp-container -p 5000:5000 -v webapp-data:/app/data webapp-with-db

# 8. Sprawdzenie czy aplikacja działa
curl http://localhost:5000
curl http://localhost:5000/users

# 9. Sprawdzenie czy dane są persystentne
docker stop webapp-container
docker rm webapp-container

# 10. Uruchomienie nowego kontenera z tym samym wolumenem
docker run -d --name webapp-container2 -p 5000:5000 -v webapp-data:/app/data webapp-with-db

# 11. Sprawdzenie czy dane przetrwały
curl http://localhost:5000/users

# 12. Czyszczenie
docker stop webapp-container2
docker rm webapp-container2
docker rmi webapp-with-db
docker volume rm webapp-data
```

**Wyjaśnienie:**
- Aplikacja tworzy bazę danych SQLite w wolumenie
- Wolumen zapewnia persystencję danych między kontenerami
- `INSERT OR IGNORE` zapobiega duplikatom przy ponownym uruchomieniu

### Rozwiązanie Zadania 4.2: Aplikacja z reverse proxy

```bash
# 1. Utworzenie katalogu
mkdir nginx-proxy
cd nginx-proxy

# 2. Utworzenie aplikacji backend
mkdir backend
cat > backend/app.py << 'EOF'
from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/api/hello')
def hello():
    return jsonify({
        'message': 'Hello from backend',
        'instance': os.getenv('INSTANCE_ID', 'unknown')
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# 3. Utworzenie requirements.txt dla backend
cat > backend/requirements.txt << 'EOF'
Flask==2.3.0
EOF

# 4. Utworzenie Dockerfile dla backend
cat > backend/Dockerfile << 'EOF'
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "app.py"]
EOF

# 5. Utworzenie konfiguracji nginx
mkdir nginx
cat > nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream backend {
        server backend:5000;
    }
    
    server {
        listen 80;
        
        location /api/ {
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
        
        location / {
            return 200 'Hello from Nginx!';
            add_header Content-Type text/plain;
        }
    }
}
EOF

# 6. Utworzenie Dockerfile dla nginx
cat > nginx/Dockerfile << 'EOF'
FROM nginx:alpine
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
EOF

# 7. Zbudowanie obrazów
docker build -t python-backend ./backend
docker build -t nginx-gateway ./nginx

# 8. Utworzenie sieci
docker network create proxy-network

# 9. Uruchomienie backend
docker run -d --name backend --network proxy-network python-backend

# 10. Uruchomienie nginx
docker run -d --name nginx --network proxy-network -p 8080:80 nginx-gateway

# 11. Sprawdzenie czy reverse proxy działa
curl http://localhost:8080
curl http://localhost:8080/api/hello

# 12. Czyszczenie
docker stop nginx backend
docker rm nginx backend
docker network rm proxy-network
docker rmi nginx-gateway python-backend
```

**Wyjaśnienie:**
- Nginx działa jako reverse proxy dla backend
- `upstream backend` definiuje serwery backend
- `proxy_pass` przekierowuje żądania do backend
- Sieć umożliwia komunikację między kontenerami

## Poziom 5: Debugging i optymalizacja

### Rozwiązanie Zadania 5.1: Debugowanie Dockerfile

```bash
# 1. Utworzenie katalogu
mkdir debug-app
cd debug-app

# 2. Utworzenie Dockerfile z celowym błędem
cat > Dockerfile << 'EOF'
FROM ubuntu:20.04
WORKDIR /app
COPY nonexistent-file.txt .
RUN apt-get update && apt-get install -y curl
CMD ["curl", "http://localhost"]
EOF

# 3. Próba zbudowania obrazu (powinno się nie udać)
docker build -t debug-app .

# 4. Naprawienie Dockerfile
cat > Dockerfile << 'EOF'
FROM ubuntu:20.04
WORKDIR /app
RUN apt-get update && apt-get install -y curl
CMD ["curl", "http://localhost"]
EOF

# 5. Zbudowanie obrazu ponownie
docker build -t debug-app .

# 6. Uruchomienie kontenera
docker run debug-app

# 7. Czyszczenie
docker rmi debug-app
```

**Wyjaśnienie:**
- Pierwszy Dockerfile zawiera błąd - próbuje skopiować nieistniejący plik
- Drugi Dockerfile jest poprawiony - usunięto błędną linię COPY
- `docker build` pokazuje szczegółowe informacje o błędach

### Rozwiązanie Zadania 5.2: Analiza rozmiaru obrazu

```bash
# 1. Utworzenie katalogu
mkdir size-analysis
cd size-analysis

# 2. Utworzenie Dockerfile z dużą ilością zależności
cat > Dockerfile.big << 'EOF'
FROM ubuntu:20.04
RUN apt-get update && apt-get install -y \
    curl wget vim nano emacs \
    python3 python3-pip \
    nodejs npm \
    openjdk-11-jdk \
    golang-go \
    && rm -rf /var/lib/apt/lists/*
CMD ["bash"]
EOF

# 3. Zbudowanie obrazu
docker build -f Dockerfile.big -t size-analysis:big .

# 4. Sprawdzenie rozmiaru obrazu
docker images size-analysis:big

# 5. Utworzenie zoptymalizowanej wersji
cat > Dockerfile.small << 'EOF'
FROM alpine:latest
RUN apk add --no-cache curl wget vim
CMD ["sh"]
EOF

# 6. Zbudowanie zoptymalizowanego obrazu
docker build -f Dockerfile.small -t size-analysis:small .

# 7. Porównanie rozmiarów obrazów
docker images size-analysis

# 8. Analiza historii warstw
docker history size-analysis:big
docker history size-analysis:small

# 9. Czyszczenie
docker rmi size-analysis:big size-analysis:small
```

**Wyjaśnienie:**
- Ubuntu z wieloma pakietami tworzy duży obraz
- Alpine Linux z minimalnymi pakietami tworzy mały obraz
- `docker history` pokazuje rozmiar każdej warstwy
- Alpine Linux jest znacznie mniejszy niż Ubuntu

## Wskazówki i najlepsze praktyki

### Najlepsze praktyki Dockerfile:

1. **Używaj oficjalnych obrazów bazowych:**
   ```dockerfile
   FROM python:3.9-slim  # Dobrze
   FROM ubuntu:20.04     # Źle (jeśli nie potrzebujesz Ubuntu)
   ```

2. **Minimalizuj liczbę warstw:**
   ```dockerfile
   # Źle
   RUN apt-get update
   RUN apt-get install -y curl
   RUN apt-get clean
   
   # Dobrze
   RUN apt-get update && \
       apt-get install -y curl && \
       apt-get clean
   ```

3. **Używaj .dockerignore:**
   ```
   node_modules
   .git
   *.log
   ```

4. **Nie uruchamiaj jako root:**
   ```dockerfile
   RUN groupadd -r appuser && useradd -r -g appuser appuser
   USER appuser
   ```

5. **Używaj multi-stage builds:**
   ```dockerfile
   FROM node:16 AS builder
   # ... build steps
   
   FROM node:16-slim
   COPY --from=builder /app/dist ./dist
   ```

6. **Cache dependencies:**
   ```dockerfile
   COPY package*.json ./
   RUN npm install
   COPY . .
   ```

7. **Używaj specific tags:**
   ```dockerfile
   FROM python:3.9-slim  # Dobrze
   FROM python:latest    # Źle w produkcji
   ```

### Przydatne komendy do debugowania:

```bash
# Budowanie z verbose output
docker build --progress=plain -t myapp .

# Sprawdzenie historii warstw
docker history myapp

# Sprawdzenie szczegółów obrazu
docker inspect myapp

# Uruchomienie kontenera w trybie interaktywnym
docker run -it myapp /bin/bash

# Sprawdzenie rozmiaru obrazu
docker images myapp

# Sprawdzenie logów budowania
docker build --no-cache -t myapp .

# Sprawdzenie kontekstu budowania
docker build --progress=plain -t myapp . 2>&1 | grep "transferring context"
```

