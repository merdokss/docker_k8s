# Rozwiązania - Zadania Zaawansowane

## Poziom 1: Docker Compose

### Rozwiązanie Zadania 1.1: Pierwszy docker-compose.yml

```bash
# 1. Utworzenie katalogu
mkdir compose-app
cd compose-app

# 2. Utworzenie aplikacji Python
cat > app.py << 'EOF'
from flask import Flask, jsonify
import redis

app = Flask(__name__)
redis_client = redis.Redis(host='redis', port=6379, db=0)

@app.route('/')
def hello():
    return 'Hello from Docker Compose!'

@app.route('/visits')
def visits():
    visits = redis_client.incr('visits')
    return jsonify({'visits': visits})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# 3. Utworzenie requirements.txt
cat > requirements.txt << 'EOF'
Flask==2.3.0
redis==4.5.0
EOF

# 4. Utworzenie Dockerfile
cat > Dockerfile << 'EOF'
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "app.py"]
EOF

# 5. Utworzenie docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  web:
    build: .
    ports:
      - "5000:5000"
    depends_on:
      - redis
    environment:
      - FLASK_ENV=development
  
  redis:
    image: redis:alpine
    ports:
      - "6379:6379"
EOF

# 6. Uruchomienie aplikacji
docker-compose up --build

# 7. W nowym terminalu sprawdzenie czy aplikacja działa
curl http://localhost:5000
curl http://localhost:5000/visits

# 8. Zatrzymanie aplikacji (Ctrl+C w terminalu z docker-compose)

# 9. Uruchomienie w tle
docker-compose up -d

# 10. Sprawdzenie statusu
docker-compose ps

# 11. Sprawdzenie logów
docker-compose logs

# 12. Zatrzymanie i usunięcie
docker-compose down
```

**Wyjaśnienie:**
- `docker-compose up --build` buduje i uruchamia serwisy
- `depends_on` definiuje zależności między serwisami
- `environment` ustawia zmienne środowiskowe
- `docker-compose down` zatrzymuje i usuwa kontenery

### Rozwiązanie Zadania 1.2: Aplikacja z bazą danych

```bash
# 1. Utworzenie katalogu
mkdir fullstack-app
cd fullstack-app

# 2. Utworzenie aplikacji backend
mkdir backend
cat > backend/app.py << 'EOF'
from flask import Flask, jsonify, request
import psycopg2
import redis

app = Flask(__name__)
redis_client = redis.Redis(host='redis', port=6379, db=0)

def get_db_connection():
    return psycopg2.connect(
        host='postgres',
        database='myapp',
        user='user',
        password='password'
    )

@app.route('/api/users', methods=['GET'])
def get_users():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute('SELECT * FROM users')
        users = cursor.fetchall()
        conn.close()
        return jsonify(users)
    except Exception as e:
        return jsonify({'error': str(e)})

@app.route('/api/users', methods=['POST'])
def create_user():
    try:
        data = request.get_json()
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute('INSERT INTO users (name, email) VALUES (%s, %s)', 
                      (data['name'], data['email']))
        conn.commit()
        conn.close()
        return jsonify({'message': 'User created'})
    except Exception as e:
        return jsonify({'error': str(e)})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# 3. Utworzenie requirements.txt dla backend
cat > backend/requirements.txt << 'EOF'
Flask==2.3.0
psycopg2-binary==2.9.0
redis==4.5.0
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

# 5. Utworzenie docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  postgres:
    image: postgres:13
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
  
  redis:
    image: redis:alpine
    ports:
      - "6379:6379"
  
  backend:
    build: ./backend
    ports:
      - "5000:5000"
    depends_on:
      - postgres
      - redis
    environment:
      - FLASK_ENV=development

volumes:
  postgres_data:
EOF

# 6. Uruchomienie aplikacji
docker-compose up --build

# 7. W nowym terminalu utworzenie tabeli w bazie danych
docker-compose exec postgres psql -U user -d myapp -c "CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, name VARCHAR(100), email VARCHAR(100));"

# 8. Test API
curl http://localhost:5000/api/users
curl -X POST http://localhost:5000/api/users -H "Content-Type: application/json" -d '{"name": "John Doe", "email": "john@example.com"}'
curl http://localhost:5000/api/users

# 9. Zatrzymanie aplikacji
docker-compose down
```

**Wyjaśnienie:**
- `volumes` definiuje named volumes
- `depends_on` zapewnia, że backend uruchamia się po postgres i redis
- `docker-compose exec` wykonuje polecenia w działających kontenerach

### Rozwiązanie Zadania 1.3: Aplikacja z nginx jako reverse proxy

```bash
# 1. Utworzenie katalogu
mkdir nginx-compose
cd nginx-compose

# 2. Utworzenie aplikacji backend
mkdir backend
cat > backend/app.py << 'EOF'
from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
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
        server backend1:5000;
        server backend2:5000;
    }
    
    server {
        listen 80;
        
        location / {
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
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

# 7. Utworzenie docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  nginx:
    build: ./nginx
    ports:
      - "80:80"
    depends_on:
      - backend1
      - backend2
  
  backend1:
    build: ./backend
    environment:
      - INSTANCE_ID=backend1
  
  backend2:
    build: ./backend
    environment:
      - INSTANCE_ID=backend2
EOF

# 8. Uruchomienie aplikacji
docker-compose up --build

# 9. W nowym terminalu test load balancera
curl http://localhost
# Wykonaj kilka razy aby zobaczyć różne odpowiedzi

# 10. Sprawdzenie logów
docker-compose logs nginx
docker-compose logs backend1
docker-compose logs backend2

# 11. Zatrzymanie aplikacji
docker-compose down
```

**Wyjaśnienie:**
- Nginx działa jako load balancer dla dwóch instancji backend
- `upstream backend` definiuje serwery backend
- Load balancer rozdziela żądania między serwery

## Poziom 2: Docker Swarm

### Rozwiązanie Zadania 2.1: Inicjalizacja Swarm

```bash
# 1. Inicjalizacja Swarm
docker swarm init

# 2. Sprawdzenie statusu Swarm
docker node ls

# 3. Pobranie tokenu do dołączenia worker nodes
docker swarm join-token worker

# 4. Sprawdzenie szczegółów Swarm
docker info | grep -A 20 "Swarm:"

# 5. Sprawdzenie szczegółów węzła
docker node inspect $(docker node ls -q)

# 6. Sprawdzenie sieci Swarm
docker network ls | grep swarm
```

**Wyjaśnienie:**
- `docker swarm init` inicjalizuje Swarm na manager node
- `docker node ls` pokazuje węzły w klastrze
- `docker swarm join-token worker` generuje token dla worker nodes

### Rozwiązanie Zadania 2.2: Deployowanie usług w Swarm

```bash
# 1. Utworzenie docker-stack.yml
cat > docker-stack.yml << 'EOF'
version: '3.8'
services:
  web:
    image: nginx:alpine
    ports:
      - "80:80"
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
  
  redis:
    image: redis:alpine
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.role == manager
EOF

# 2. Deployowanie stack
docker stack deploy -c docker-stack.yml myapp

# 3. Sprawdzenie statusu usług
docker service ls

# 4. Sprawdzenie szczegółów usługi web
docker service ps web

# 5. Sprawdzenie logów usługi
docker service logs web

# 6. Sprawdzenie szczegółów usługi
docker service inspect web

# 7. Test aplikacji
curl http://localhost

# 8. Sprawdzenie replik
docker service ps web --no-trunc
```

**Wyjaśnienie:**
- `docker stack deploy` wdraża stack w Swarm
- `deploy` sekcja definiuje konfigurację wdrożenia
- `replicas` definiuje liczbę replik usługi
- `placement.constraints` definiuje ograniczenia rozmieszczenia

### Rozwiązanie Zadania 2.3: Skalowanie i aktualizacje

```bash
# 1. Skalowanie usługi web do 5 replik
docker service scale web=5

# 2. Sprawdzenie statusu skalowania
docker service ps web

# 3. Sprawdzenie szczegółów usługi
docker service inspect web --pretty

# 4. Zaktualizowanie usługi
docker service update --image nginx:latest web

# 5. Sprawdzenie procesu aktualizacji
docker service ps web

# 6. Sprawdzenie logów aktualizacji
docker service logs web

# 7. Sprawdzenie szczegółów aktualizacji
docker service inspect web --pretty

# 8. Sprawdzenie statusu usług
docker service ls

# 9. Usunięcie stack
docker stack rm myapp

# 10. Sprawdzenie czy usługi zostały usunięte
docker service ls
```

**Wyjaśnienie:**
- `docker service scale` skaluje usługę
- `docker service update` aktualizuje usługę
- Rolling update jest domyślnym trybem aktualizacji
- `docker stack rm` usuwa cały stack

## Poziom 3: Bezpieczeństwo

### Rozwiązanie Zadania 3.1: Uruchamianie jako nieprivilegowany użytkownik

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
docker run -d --name secure-container -p 5000:5000 secure-app

# 7. Sprawdzenie pod jakim użytkownikiem działa aplikacja
curl http://localhost:5000

# 8. Sprawdzenie użytkownika w kontenerze
docker exec secure-container whoami
docker exec secure-container id

# 9. Sprawdzenie uprawnień
docker exec secure-container ls -la /app

# 10. Sprawdzenie procesów
docker exec secure-container ps aux

# 11. Czyszczenie
docker stop secure-container
docker rm secure-container
docker rmi secure-app
```

**Wyjaśnienie:**
- `groupadd -r appuser` tworzy grupę systemową
- `useradd -r -g appuser appuser` tworzy użytkownika systemowego
- `chown -R appuser:appuser /app` zmienia właściciela plików
- `USER appuser` przełącza na użytkownika nieprivilegowanego

### Rozwiązanie Zadania 3.2: Używanie secrets

```bash
# 1. Utworzenie secret
echo "my-secret-password" | docker secret create db_password -

# 2. Sprawdzenie listy secrets
docker secret ls

# 3. Sprawdzenie szczegółów secret
docker secret inspect db_password

# 4. Utworzenie docker-stack.yml z secret
cat > docker-stack.yml << 'EOF'
version: '3.8'
services:
  web:
    image: nginx:alpine
    secrets:
      - db_password
    environment:
      - DB_PASSWORD_FILE=/run/secrets/db_password
    deploy:
      replicas: 1

secrets:
  db_password:
    external: true
EOF

# 5. Deployowanie stack z secret
docker stack deploy -c docker-stack.yml myapp

# 6. Sprawdzenie statusu usług
docker service ls

# 7. Sprawdzenie szczegółów usługi
docker service inspect web --pretty

# 8. Sprawdzenie secret w kontenerze
docker exec $(docker ps -q --filter name=myapp_web) cat /run/secrets/db_password

# 9. Usunięcie stack
docker stack rm myapp

# 10. Usunięcie secret
docker secret rm db_password
```

**Wyjaśnienie:**
- `docker secret create` tworzy secret
- `secrets` sekcja w docker-stack.yml definiuje secrets dla usługi
- Secret jest dostępny w kontenerze jako plik w `/run/secrets/`

### Rozwiązanie Zadania 3.3: Skanowanie obrazów pod kątem luk bezpieczeństwa

```bash
# 1. Sprawdzenie czy Trivy jest zainstalowane
trivy --version

# 2. Skanowanie obrazu nginx:alpine
trivy image nginx:alpine

# 3. Skanowanie obrazu z wysokim poziomem szczegółowości
trivy image --severity HIGH,CRITICAL nginx:alpine

# 4. Skanowanie obrazu z formatem JSON
trivy image --format json nginx:alpine

# 5. Wyeksportowanie raportu do pliku
trivy image --format json --output nginx-report.json nginx:alpine

# 6. Sprawdzenie zawartości raportu
cat nginx-report.json | jq '.Results[0].Vulnerabilities[] | select(.Severity == "HIGH" or .Severity == "CRITICAL")'

# 7. Skanowanie obrazu z pominięciem cache
trivy image --no-cache nginx:alpine

# 8. Skanowanie obrazu z określeniem exit code
trivy image --exit-code 1 --severity HIGH,CRITICAL nginx:alpine

# 9. Czyszczenie
rm nginx-report.json
```

**Wyjaśnienie:**
- `trivy image` skanuje obraz pod kątem luk bezpieczeństwa
- `--severity` filtruje luki według poziomu ważności
- `--format json` generuje raport w formacie JSON
- `--exit-code 1` zwraca kod błędu jeśli znajdzie luki

## Poziom 4: Monitoring i logowanie

### Rozwiązanie Zadania 4.1: Konfiguracja ELK Stack

```bash
# 1. Utworzenie katalogu
mkdir elk-stack
cd elk-stack

# 2. Utworzenie docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.15.0
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ports:
      - "9200:9200"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
  
  kibana:
    image: docker.elastic.co/kibana/kibana:7.15.0
    ports:
      - "5601:5601"
    depends_on:
      - elasticsearch
  
  logstash:
    image: docker.elastic.co/logstash/logstash:7.15.0
    ports:
      - "5044:5044"
    depends_on:
      - elasticsearch
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf

volumes:
  elasticsearch_data:
EOF

# 3. Utworzenie konfiguracji Logstash
cat > logstash.conf << 'EOF'
input {
  beats {
    port => 5044
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
  }
}
EOF

# 4. Uruchomienie ELK stack
docker-compose up -d

# 5. Sprawdzenie czy wszystkie serwisy działają
docker-compose ps

# 6. Sprawdzenie logów
docker-compose logs elasticsearch
docker-compose logs kibana
docker-compose logs logstash

# 7. Test Elasticsearch
curl http://localhost:9200

# 8. Test Kibana
curl http://localhost:5601

# 9. Sprawdzenie indeksów w Elasticsearch
curl http://localhost:9200/_cat/indices

# 10. Zatrzymanie ELK stack
docker-compose down

# 11. Czyszczenie
docker volume rm elk-stack_elasticsearch_data
```

**Wyjaśnienie:**
- ELK Stack składa się z Elasticsearch, Logstash i Kibana
- Elasticsearch przechowuje i indeksuje logi
- Logstash przetwarza i przesyła logi
- Kibana wizualizuje logi

### Rozwiązanie Zadania 4.2: Aplikacja z logowaniem

```bash
# 1. Utworzenie katalogu
mkdir logged-app
cd logged-app

# 2. Utworzenie aplikacji Python z logowaniem
cat > app.py << 'EOF'
import logging
import json
from flask import Flask, jsonify

app = Flask(__name__)

# Konfiguracja logowania
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@app.route('/')
def hello():
    logger.info('Hello endpoint accessed')
    return jsonify({'message': 'Hello from logged app'})

@app.route('/error')
def error():
    logger.error('Error endpoint accessed')
    return jsonify({'error': 'This is an error'}), 500

@app.route('/warning')
def warning():
    logger.warning('Warning endpoint accessed')
    return jsonify({'warning': 'This is a warning'})

if __name__ == '__main__':
    logger.info('Starting application')
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
EXPOSE 5000
CMD ["python", "app.py"]
EOF

# 5. Zbudowanie obrazu
docker build -t logged-app .

# 6. Uruchomienie kontenera
docker run -d --name logged-container -p 5000:5000 logged-app

# 7. Test aplikacji
curl http://localhost:5000
curl http://localhost:5000/error
curl http://localhost:5000/warning

# 8. Sprawdzenie logów
docker logs logged-container

# 9. Sprawdzenie logów w czasie rzeczywistym
docker logs -f logged-container

# 10. Czyszczenie
docker stop logged-container
docker rm logged-container
docker rmi logged-app
```

**Wyjaśnienie:**
- Aplikacja używa standardowego modułu logging Python
- Logi są wyświetlane w konsoli i można je zobaczyć przez `docker logs`
- Różne poziomy logowania (INFO, ERROR, WARNING)

## Poziom 5: Optymalizacja i wydajność

### Rozwiązanie Zadania 5.1: Optymalizacja rozmiaru obrazu

```bash
# 1. Utworzenie katalogu
mkdir optimized-app
cd optimized-app

# 2. Utworzenie aplikacji Go
cat > main.go << 'EOF'
package main

import (
    "fmt"
    "net/http"
)

func handler(w http.ResponseWriter, r *http.Request) {
    fmt.Fprintf(w, "Hello from optimized Go app!")
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
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Production stage
FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/main .
EXPOSE 8080
CMD ["./main"]
EOF

# 4. Zbudowanie obrazu
docker build -t optimized-app .

# 5. Sprawdzenie rozmiaru obrazu
docker images optimized-app

# 6. Sprawdzenie historii warstw
docker history optimized-app

# 7. Uruchomienie kontenera
docker run -d --name optimized-container -p 8080:8080 optimized-app

# 8. Test aplikacji
curl http://localhost:8080

# 9. Porównanie z obrazem bez optymalizacji
cat > Dockerfile.big << 'EOF'
FROM golang:1.19
WORKDIR /app
COPY . .
RUN go build -o main .
EXPOSE 8080
CMD ["./main"]
EOF

# 10. Zbudowanie obrazu bez optymalizacji
docker build -f Dockerfile.big -t optimized-app:big .

# 11. Porównanie rozmiarów
docker images optimized-app

# 12. Czyszczenie
docker stop optimized-container
docker rm optimized-container
docker rmi optimized-app optimized-app:big
```

**Wyjaśnienie:**
- Multi-stage build używa dwóch etapów: build i production
- Build stage kompiluje aplikację
- Production stage zawiera tylko skompilowaną aplikację
- Rezultat: mniejszy obraz produkcyjny

### Rozwiązanie Zadania 5.2: Load testing

```bash
# 1. Utworzenie katalogu
mkdir load-test
cd load-test

# 2. Utworzenie aplikacji testowej
cat > test-app.py << 'EOF'
from flask import Flask, jsonify
import time

app = Flask(__name__)

@app.route('/')
def hello():
    return jsonify({'message': 'Hello from test app'})

@app.route('/slow')
def slow():
    time.sleep(1)  # Symulacja wolnej operacji
    return jsonify({'message': 'Slow response'})

if __name__ == '__main__':
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
EXPOSE 5000
CMD ["python", "test-app.py"]
EOF

# 5. Zbudowanie obrazu
docker build -t test-app .

# 6. Uruchomienie aplikacji
docker run -d --name test-container -p 5000:5000 test-app

# 7. Utworzenie skryptu load test
cat > load_test.py << 'EOF'
import requests
import threading
import time

def make_request():
    try:
        response = requests.get('http://localhost:5000/slow')
        print(f"Status: {response.status_code}, Time: {response.elapsed.total_seconds()}")
    except Exception as e:
        print(f"Error: {e}")

def run_load_test():
    threads = []
    for i in range(10):  # 10 równoczesnych żądań
        thread = threading.Thread(target=make_request)
        threads.append(thread)
        thread.start()
    
    for thread in threads:
        thread.join()

if __name__ == '__main__':
    run_load_test()
EOF

# 8. Instalacja requests
pip install requests

# 9. Uruchomienie load test
python load_test.py

# 10. Sprawdzenie logów aplikacji
docker logs test-container

# 11. Sprawdzenie wykorzystania zasobów
docker stats test-container

# 12. Czyszczenie
docker stop test-container
docker rm test-container
docker rmi test-app
```

**Wyjaśnienie:**
- Load test symuluje równoczesne żądania do aplikacji
- `time.sleep(1)` symuluje wolne operacje
- `docker stats` pokazuje wykorzystanie zasobów w czasie rzeczywistym

### Rozwiązanie Zadania 5.3: Monitoring zasobów

```bash
# 1. Uruchomienie kontenera z limitami zasobów
docker run -d --name limited-container \
  --memory=512m \
  --cpus=0.5 \
  nginx:alpine

# 2. Sprawdzenie wykorzystania zasobów
docker stats limited-container

# 3. Sprawdzenie szczegółów kontenera
docker inspect limited-container | grep -A 10 "Memory\|Cpu"

# 4. Uruchomienie aplikacji generującej obciążenie
docker run -d --name stress-test \
  --memory=256m \
  --cpus=0.25 \
  progrium/stress \
  --cpu 1 --timeout 60s

# 5. Monitorowanie wykorzystania zasobów w czasie rzeczywistym
docker stats stress-test

# 6. Sprawdzenie logów stress test
docker logs stress-test

# 7. Sprawdzenie szczegółów stress test
docker inspect stress-test | grep -A 10 "Memory\|Cpu"

# 8. Sprawdzenie wszystkich kontenerów
docker stats --no-stream

# 9. Sprawdzenie wykorzystania zasobów przez system
docker system df

# 10. Czyszczenie
docker stop limited-container stress-test
docker rm limited-container stress-test
```

**Wyjaśnienie:**
- `--memory=512m` ogranicza pamięć do 512MB
- `--cpus=0.5` ogranicza CPU do 0.5 rdzenia
- `docker stats` pokazuje wykorzystanie zasobów w czasie rzeczywistym
- `progrium/stress` generuje obciążenie dla testów

## Wskazówki i najlepsze praktyki

### Docker Compose:
- Używaj wersji 3.8 lub nowszej
- Definiuj zależności między serwisami
- Używaj zmiennych środowiskowych dla konfiguracji
- Grupuj powiązane serwisy w jednym pliku

### Docker Swarm:
- Używaj manager nodes tylko do zarządzania
- Konfiguruj health checks dla usług
- Używaj rolling updates dla aktualizacji
- Monitoruj stan klastra

### Bezpieczeństwo:
- Uruchamiaj kontenery jako nieprivilegowani użytkownicy
- Używaj secrets dla wrażliwych danych
- Regularnie skanuj obrazy pod kątem luk
- Używaj minimalnych obrazów bazowych

### Monitoring:
- Konfiguruj centralne logowanie
- Używaj health checks
- Monitoruj wykorzystanie zasobów
- Ustaw alerty dla krytycznych metryk

### Optymalizacja:
- Używaj multi-stage builds
- Minimalizuj liczbę warstw
- Używaj .dockerignore
- Cache dependencies

### Przydatne komendy:

```bash
# Docker Compose
docker-compose up -d
docker-compose down
docker-compose logs -f
docker-compose ps

# Docker Swarm
docker swarm init
docker stack deploy -c stack.yml myapp
docker service ls
docker service ps web

# Monitoring
docker stats
docker logs -f container
docker exec -it container top

# Bezpieczeństwo
docker secret create name secret
docker secret ls
trivy image image:tag

# Optymalizacja
docker system df
docker image prune -a
docker container prune
docker volume prune
```

