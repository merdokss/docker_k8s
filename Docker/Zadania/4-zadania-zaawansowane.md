# Zadania Docker - Zaawansowane Tematy

## Poziom 1: Docker Compose

### Zadanie 1.1: Pierwszy docker-compose.yml
**Cel:** Stworzenie prostej aplikacji z Docker Compose

1. Utwórz katalog `compose-app`
2. Utwórz aplikację Python (`app.py`):
   ```python
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
   ```

3. Utwórz `requirements.txt`:
   ```
   Flask==2.3.0
   redis==4.5.0
   ```

4. Utwórz `Dockerfile`:
   ```dockerfile
   FROM python:3.9-slim
   WORKDIR /app
   COPY requirements.txt .
   RUN pip install -r requirements.txt
   COPY . .
   EXPOSE 5000
   CMD ["python", "app.py"]
   ```

5. Utwórz `docker-compose.yml`:
   ```yaml
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
   ```

6. Uruchom aplikację:
   ```bash
   docker-compose up --build
   ```

7. Sprawdź czy aplikacja działa i czy licznik wizyt działa

### Zadanie 1.2: Aplikacja z bazą danych
**Cel:** Stworzenie aplikacji z PostgreSQL i Redis

1. Utwórz katalog `fullstack-app`
2. Utwórz aplikację backend (`backend/app.py`):
   ```python
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
       conn = get_db_connection()
       cursor = conn.cursor()
       cursor.execute('SELECT * FROM users')
       users = cursor.fetchall()
       conn.close()
       return jsonify(users)
   
   @app.route('/api/users', methods=['POST'])
   def create_user():
       data = request.get_json()
       conn = get_db_connection()
       cursor = conn.cursor()
       cursor.execute('INSERT INTO users (name, email) VALUES (%s, %s)', 
                     (data['name'], data['email']))
       conn.commit()
       conn.close()
       return jsonify({'message': 'User created'})
   
   if __name__ == '__main__':
       app.run(host='0.0.0.0', port=5000)
   ```

3. Utwórz `docker-compose.yml`:
   ```yaml
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
   ```

4. Utwórz skrypt inicjalizacji bazy danych (`backend/init.sql`):
   ```sql
   CREATE TABLE IF NOT EXISTS users (
       id SERIAL PRIMARY KEY,
       name VARCHAR(100) NOT NULL,
       email VARCHAR(100) UNIQUE NOT NULL,
       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );
   
   INSERT INTO users (name, email) VALUES 
   ('John Doe', 'john@example.com'),
   ('Jane Smith', 'jane@example.com');
   ```

5. Uruchom aplikację i przetestuj API

### Zadanie 1.3: Aplikacja z nginx jako reverse proxy
**Cel:** Konfiguracja nginx jako load balancer

1. Utwórz katalog `nginx-compose`
2. Utwórz aplikację backend (`backend/app.py`):
   ```python
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
   ```

3. Utwórz konfigurację nginx (`nginx/nginx.conf`):
   ```nginx
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
   ```

4. Utwórz `docker-compose.yml`:
   ```yaml
   version: '3.8'
   services:
     nginx:
       image: nginx:alpine
       ports:
         - "80:80"
       volumes:
         - ./nginx/nginx.conf:/etc/nginx/nginx.conf
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
   ```

5. Uruchom aplikację i sprawdź load balancing

## Poziom 2: Docker Swarm

### Zadanie 2.1: Inicjalizacja Swarm
**Cel:** Stworzenie klastra Docker Swarm

1. Inicjalizuj Swarm:
   ```bash
   docker swarm init
   ```

2. Sprawdź status Swarm:
   ```bash
   docker node ls
   ```

3. Pobierz token do dołączenia worker nodes:
   ```bash
   docker swarm join-token worker
   ```

4. Sprawdź szczegóły Swarm:
   ```bash
   docker info
   ```

### Zadanie 2.2: Deployowanie usług w Swarm
**Cel:** Uruchamianie usług w klastrze Swarm

1. Utwórz `docker-stack.yml`:
   ```yaml
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
   ```

2. Deployuj stack:
   ```bash
   docker stack deploy -c docker-stack.yml myapp
   ```

3. Sprawdź status usług:
   ```bash
   docker service ls
   docker service ps web
   ```

4. Sprawdź logi usługi:
   ```bash
   docker service logs web
   ```

### Zadanie 2.3: Skalowanie i aktualizacje
**Cel:** Zarządzanie usługami w Swarm

1. Skaluj usługę web do 5 replik:
   ```bash
   docker service scale web=5
   ```

2. Sprawdź status skalowania:
   ```bash
   docker service ps web
   ```

3. Zaktualizuj usługę:
   ```bash
   docker service update --image nginx:latest web
   ```

4. Sprawdź proces aktualizacji:
   ```bash
   docker service ps web
   ```

5. Usuń stack:
   ```bash
   docker stack rm myapp
   ```

## Poziom 3: Bezpieczeństwo

### Zadanie 3.1: Uruchamianie jako nieprivilegowany użytkownik
**Cel:** Bezpieczne uruchamianie kontenerów

1. Utwórz katalog `secure-app`
2. Utwórz aplikację Python (`app.py`):
   ```python
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
   ```

3. Utwórz `Dockerfile`:
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

4. Zbuduj i uruchom kontener
5. Sprawdź pod jakim użytkownikiem działa aplikacja

### Zadanie 3.2: Używanie secrets
**Cel:** Bezpieczne przechowywanie wrażliwych danych

1. Utwórz secret:
   ```bash
   echo "my-secret-password" | docker secret create db_password -
   ```

2. Sprawdź listę secrets:
   ```bash
   docker secret ls
   ```

3. Utwórz `docker-stack.yml` z secret:
   ```yaml
   version: '3.8'
   services:
     web:
       image: nginx:alpine
       secrets:
         - db_password
       environment:
         - DB_PASSWORD_FILE=/run/secrets/db_password
   
   secrets:
     db_password:
       external: true
   ```

4. Deployuj stack z secret

### Zadanie 3.3: Skanowanie obrazów pod kątem luk bezpieczeństwa
**Cel:** Analiza bezpieczeństwa obrazów Docker

1. Zainstaluj Trivy (jeśli dostępne):
   ```bash
   # Na macOS
   brew install trivy
   ```

2. Skanuj obraz pod kątem luk:
   ```bash
   trivy image nginx:alpine
   ```

3. Skanuj obraz z wysokim poziomem szczegółowości:
   ```bash
   trivy image --severity HIGH,CRITICAL nginx:alpine
   ```

4. Wyeksportuj raport do pliku:
   ```bash
   trivy image --format json --output nginx-report.json nginx:alpine
   ```

## Poziom 4: Monitoring i logowanie

### Zadanie 4.1: Konfiguracja ELK Stack
**Cel:** Stworzenie systemu logowania i monitorowania

1. Utwórz katalog `elk-stack`
2. Utwórz `docker-compose.yml`:
   ```yaml
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
   ```

3. Utwórz konfigurację Logstash (`logstash.conf`):
   ```ruby
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
   ```

4. Uruchom ELK stack:
   ```bash
   docker-compose up -d
   ```

5. Sprawdź czy wszystkie serwisy działają

### Zadanie 4.2: Aplikacja z logowaniem
**Cel:** Integracja aplikacji z systemem logowania

1. Utwórz aplikację Python (`app.py`):
   ```python
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
   
   if __name__ == '__main__':
       logger.info('Starting application')
       app.run(host='0.0.0.0', port=5000)
   ```

2. Utwórz `Dockerfile`:
   ```dockerfile
   FROM python:3.9-slim
   WORKDIR /app
   COPY requirements.txt .
   RUN pip install -r requirements.txt
   COPY . .
   EXPOSE 5000
   CMD ["python", "app.py"]
   ```

3. Uruchom aplikację i sprawdź logi

## Poziom 5: Optymalizacja i wydajność

### Zadanie 5.1: Optymalizacja rozmiaru obrazu
**Cel:** Stworzenie minimalnego obrazu produkcyjnego

1. Utwórz katalog `optimized-app`
2. Utwórz aplikację Go (`main.go`):
   ```go
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
   ```

3. Utwórz `Dockerfile` z multi-stage build:
   ```dockerfile
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
   ```

4. Zbuduj obraz i sprawdź jego rozmiar:
   ```bash
   docker build -t optimized-app .
   docker images optimized-app
   ```

5. Porównaj z obrazem bez optymalizacji

### Zadanie 5.2: Load testing
**Cel:** Testowanie wydajności aplikacji

1. Utwórz aplikację testową (`test-app.py`):
   ```python
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
   ```

2. Utwórz skrypt load test (`load_test.py`):
   ```python
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
   ```

3. Uruchom aplikację i wykonaj load test

### Zadanie 5.3: Monitoring zasobów
**Cel:** Monitorowanie wykorzystania zasobów przez kontenery

1. Uruchom kontener z limitami zasobów:
   ```bash
   docker run -d --name limited-container \
     --memory=512m \
     --cpus=0.5 \
     nginx:alpine
   ```

2. Sprawdź wykorzystanie zasobów:
   ```bash
   docker stats limited-container
   ```

3. Uruchom aplikację generującą obciążenie:
   ```bash
   docker run -d --name stress-test \
     --memory=256m \
     --cpus=0.25 \
     progrium/stress \
     --cpu 1 --timeout 60s
   ```

4. Monitoruj wykorzystanie zasobów w czasie rzeczywistym

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
```

