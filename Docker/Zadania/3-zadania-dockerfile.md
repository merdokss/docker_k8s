# Zadania Docker - Dockerfile i Budowanie Obrazów

## Poziom 1: Podstawy Dockerfile

### Zadanie 1.1: Pierwszy Dockerfile
**Cel:** Stworzenie prostego obrazu Docker

1. Utwórz katalog `moja-aplikacja`
2. W katalogu utwórz plik `Dockerfile` z następującą zawartością:
   ```dockerfile
   FROM alpine:latest
   RUN echo "Witaj w moim kontenerze!" > /powitanie.txt
   CMD cat /powitanie.txt
   ```
3. Zbuduj obraz z tagiem `moja-aplikacja:v1.0`
4. Uruchom kontener z nowo utworzonego obrazu
5. Sprawdź czy wyświetla się komunikat powitalny

### Zadanie 1.2: Aplikacja webowa z nginx
**Cel:** Stworzenie obrazu z aplikacją webową

1. W katalogu `moja-aplikacja` utwórz plik `index.html`:
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

2. Utwórz nowy `Dockerfile`:
   ```dockerfile
   FROM nginx:alpine
   COPY index.html /usr/share/nginx/html/index.html
   EXPOSE 80
   ```

3. Zbuduj obraz z tagiem `moja-strona:v1.0`
4. Uruchom kontener mapując port 8080 na 80
5. Sprawdź czy strona jest dostępna pod `http://localhost:8080`

### Zadanie 1.3: Aplikacja Node.js
**Cel:** Stworzenie obrazu z aplikacją Node.js

1. Utwórz katalog `node-app`
2. W katalogu utwórz plik `package.json`:
   ```json
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
   ```

3. Utwórz plik `app.js`:
   ```javascript
   const express = require('express');
   const app = express();
   
   app.get('/', (req, res) => {
     res.send('Hello from Docker Node.js app!');
   });
   
   app.listen(3000, () => {
     console.log('App running on port 3000');
   });
   ```

4. Utwórz `Dockerfile`:
   ```dockerfile
   FROM node:16
   WORKDIR /usr/src/app
   COPY package*.json ./
   RUN npm install
   COPY . .
   EXPOSE 3000
   CMD ["npm", "start"]
   ```

5. Zbuduj obraz z tagiem `node-app:v1.0`
6. Uruchom kontener mapując port 3000
7. Sprawdź czy aplikacja odpowiada na `http://localhost:3000`

## Poziom 2: Optymalizacja Dockerfile

### Zadanie 2.1: Optymalizacja warstw
**Cel:** Nauka optymalizacji liczby warstw w obrazie

1. Utwórz katalog `optimized-app`
2. Utwórz `Dockerfile` z nieoptymalną strukturą:
   ```dockerfile
   FROM ubuntu:20.04
   RUN apt-get update
   RUN apt-get install -y curl
   RUN apt-get install -y wget
   RUN apt-get install -y vim
   RUN apt-get clean
   RUN rm -rf /var/lib/apt/lists/*
   CMD ["bash"]
   ```

3. Zbuduj obraz i sprawdź jego rozmiar
4. Utwórz zoptymalizowaną wersję `Dockerfile`:
   ```dockerfile
   FROM ubuntu:20.04
   RUN apt-get update && \
       apt-get install -y curl wget vim && \
       apt-get clean && \
       rm -rf /var/lib/apt/lists/*
   CMD ["bash"]
   ```

5. Zbuduj zoptymalizowany obraz i porównaj rozmiary
6. Sprawdź historię warstw używając `docker history`

### Zadanie 2.2: Używanie .dockerignore
**Cel:** Optymalizacja kontekstu budowania

1. W katalogu `node-app` utwórz plik `.dockerignore`:
   ```
   node_modules
   npm-debug.log
   .git
   .gitignore
   README.md
   .env
   ```

2. Utwórz kilka plików testowych (np. `test.txt`, `README.md`)
3. Zbuduj obraz i sprawdź czy niepotrzebne pliki nie zostały skopiowane
4. Sprawdź rozmiar kontekstu budowania

### Zadanie 2.3: Multi-stage build
**Cel:** Stworzenie zoptymalizowanego obrazu produkcyjnego

1. Utwórz katalog `multistage-app`
2. Utwórz aplikację Go (`main.go`):
   ```go
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
   ```

3. Utwórz `Dockerfile` z multi-stage build:
   ```dockerfile
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
   ```

4. Zbuduj obraz i sprawdź jego rozmiar
5. Uruchom kontener i sprawdź czy aplikacja działa

## Poziom 3: Zaawansowane techniki

### Zadanie 3.1: Zmienne środowiskowe i ARG
**Cel:** Konfiguracja aplikacji za pomocą zmiennych

1. Utwórz katalog `configurable-app`
2. Utwórz aplikację Python (`app.py`):
   ```python
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
   ```

3. Utwórz `requirements.txt`:
   ```
   Flask==2.3.0
   ```

4. Utwórz `Dockerfile` z ARG i ENV:
   ```dockerfile
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
   ```

5. Zbuduj obraz z domyślnymi wartościami
6. Zbuduj obraz z niestandardowymi wartościami:
   ```bash
   docker build --build-arg APP_NAME="My Custom App" --build-arg APP_VERSION="2.0" -t configurable-app:v2.0 .
   ```

### Zadanie 3.2: Healthcheck i monitoring
**Cel:** Dodanie healthcheck do obrazu

1. Utwórz katalog `monitored-app`
2. Utwórz aplikację Node.js z endpointem health (`app.js`):
   ```javascript
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
   ```

3. Utwórz `Dockerfile` z healthcheck:
   ```dockerfile
   FROM node:16
   WORKDIR /usr/src/app
   COPY package*.json ./
   RUN npm install
   COPY . .
   
   EXPOSE 3000
   
   HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
     CMD curl -f http://localhost:3000/health || exit 1
   
   CMD ["npm", "start"]
   ```

4. Zbuduj obraz z tagiem `monitored-app:v1.0`
5. Uruchom kontener i sprawdź status healthcheck:
   ```bash
   docker ps
   docker inspect [container_id] | grep -A 10 Health
   ```

### Zadanie 3.3: Użytkownik nieprivilegowany
**Cel:** Bezpieczne uruchamianie aplikacji

1. Utwórz katalog `secure-app`
2. Utwórz prostą aplikację Python (`app.py`):
   ```python
   import os
   from flask import Flask
   
   app = Flask(__name__)
   
   @app.route('/')
   def hello():
       user = os.getenv('USER', 'unknown')
       return f'Hello! Running as user: {user}'
   
   if __name__ == '__main__':
       app.run(host='0.0.0.0', port=5000)
   ```

3. Utwórz `Dockerfile` z nieprivilegowanym użytkownikiem:
   ```dockerfile
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
   ```

4. Zbuduj obraz i uruchom kontener
5. Sprawdź pod jakim użytkownikiem działa aplikacja

## Poziom 4: Praktyczne scenariusze

### Zadanie 4.1: Aplikacja z bazą danych
**Cel:** Stworzenie aplikacji z połączeniem do bazy danych

1. Utwórz katalog `webapp-with-db`
2. Utwórz aplikację Python (`app.py`):
   ```python
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
   ```

3. Utwórz `Dockerfile`:
   ```dockerfile
   FROM python:3.9-slim
   
   WORKDIR /app
   COPY requirements.txt .
   RUN pip install -r requirements.txt
   COPY . .
   
   # Utwórz katalog dla bazy danych
   RUN mkdir -p /app/data
   
   EXPOSE 5000
   CMD ["python", "app.py"]
   ```

4. Utwórz `requirements.txt`:
   ```
   Flask==2.3.0
   ```

5. Zbuduj obraz i uruchom kontener z wolumenem dla bazy danych
6. Sprawdź czy aplikacja działa i czy dane są persystentne

### Zadanie 4.2: Aplikacja z reverse proxy
**Cel:** Konfiguracja nginx jako reverse proxy

1. Utwórz katalog `nginx-proxy`
2. Utwórz aplikację backend (`backend/app.py`):
   ```python
   from flask import Flask, jsonify
   
   app = Flask(__name__)
   
   @app.route('/api/hello')
   def hello():
       return jsonify({'message': 'Hello from backend!'})
   
   if __name__ == '__main__':
       app.run(host='0.0.0.0', port=5000)
   ```

3. Utwórz `Dockerfile` dla backend:
   ```dockerfile
   FROM python:3.9-slim
   WORKDIR /app
   COPY requirements.txt .
   RUN pip install -r requirements.txt
   COPY . .
   EXPOSE 5000
   CMD ["python", "app.py"]
   ```

4. Utwórz konfigurację nginx (`nginx/nginx.conf`):
   ```nginx
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
   ```

5. Utwórz `Dockerfile` dla nginx:
   ```dockerfile
   FROM nginx:alpine
   COPY nginx.conf /etc/nginx/nginx.conf
   EXPOSE 80
   ```

6. Zbuduj oba obrazy i uruchom je w sieci
7. Sprawdź czy reverse proxy działa poprawnie

## Poziom 5: Debugging i optymalizacja

### Zadanie 5.1: Debugowanie Dockerfile
**Cel:** Rozwiązywanie problemów z budowaniem obrazów

1. Utwórz katalog `debug-app`
2. Utwórz `Dockerfile` z celowym błędem:
   ```dockerfile
   FROM ubuntu:20.04
   WORKDIR /app
   COPY nonexistent-file.txt .
   RUN apt-get update && apt-get install -y curl
   CMD ["curl", "http://localhost"]
   ```

3. Spróbuj zbudować obraz i zobacz błąd
4. Napraw `Dockerfile` i zbuduj obraz ponownie
5. Uruchom kontener i sprawdź czy działa

### Zadanie 5.2: Analiza rozmiaru obrazu
**Cel:** Optymalizacja rozmiaru obrazu

1. Utwórz katalog `size-analysis`
2. Utwórz `Dockerfile` z dużą ilością zależności:
   ```dockerfile
   FROM ubuntu:20.04
   RUN apt-get update && apt-get install -y \
       curl wget vim nano emacs \
       python3 python3-pip \
       nodejs npm \
       openjdk-11-jdk \
       golang-go \
       && rm -rf /var/lib/apt/lists/*
   CMD ["bash"]
   ```

3. Zbuduj obraz i sprawdź jego rozmiar
4. Utwórz zoptymalizowaną wersję używając alpine:
   ```dockerfile
   FROM alpine:latest
   RUN apk add --no-cache curl wget vim
   CMD ["sh"]
   ```

5. Porównaj rozmiary obrazów
6. Użyj `docker history` do analizy warstw

## Wskazówki i najlepsze praktyki

### Najlepsze praktyki Dockerfile:

1. **Używaj oficjalnych obrazów bazowych**
2. **Minimalizuj liczbę warstw** - łącz polecenia RUN
3. **Używaj .dockerignore** - wyklucz niepotrzebne pliki
4. **Nie uruchamiaj jako root** - używaj USER
5. **Używaj multi-stage builds** - dla aplikacji produkcyjnych
6. **Cache dependencies** - kopiuj pliki zależności przed kodem
7. **Używaj specific tags** - nie używaj `latest` w produkcji

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
```

