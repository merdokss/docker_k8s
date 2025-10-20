# Rozwiązania - Zadania Sieci i Wolumeny

## Poziom 1: Podstawy sieci Docker

### Rozwiązanie Zadania 1.1: Tworzenie i zarządzanie sieciami

```bash
# 1. Sprawdzenie domyślnych sieci Docker
docker network ls

# 2. Sprawdzenie szczegółów sieci bridge
docker network inspect bridge

# 3. Utworzenie nowej sieci typu bridge
docker network create moja-siec

# 4. Sprawdzenie szczegółów nowo utworzonej sieci
docker network inspect moja-siec

# 5. Utworzenie sieci z niestandardową konfiguracją
docker network create --subnet=172.20.0.0/16 --gateway=172.20.0.1 moja-siec-custom

# 6. Sprawdzenie szczegółów sieci z niestandardową konfiguracją
docker network inspect moja-siec-custom

# 7. Czyszczenie
docker network rm moja-siec moja-siec-custom
```

**Wyjaśnienie:**
- `docker network ls` pokazuje wszystkie sieci
- `docker network inspect` pokazuje szczegółowe informacje o sieci
- `--subnet` definiuje podsieć sieci
- `--gateway` definiuje bramę sieciową

### Rozwiązanie Zadania 1.2: Komunikacja między kontenerami

```bash
# 1. Utworzenie sieci
docker network create test-siec

# 2. Uruchomienie pierwszego kontenera Ubuntu
docker run -d --name ubuntu1 --network test-siec ubuntu:20.04 sleep infinity

# 3. Uruchomienie drugiego kontenera Ubuntu
docker run -d --name ubuntu2 --network test-siec ubuntu:20.04 sleep infinity

# 4. Instalacja ping w obu kontenerach
docker exec ubuntu1 apt-get update && docker exec ubuntu1 apt-get install -y iputils-ping
docker exec ubuntu2 apt-get update && docker exec ubuntu2 apt-get install -y iputils-ping

# 5. Test połączenia z ubuntu1 do ubuntu2
docker exec ubuntu1 ping -c 4 ubuntu2

# 6. Test połączenia z ubuntu2 do ubuntu1
docker exec ubuntu2 ping -c 4 ubuntu1

# 7. Sprawdzenie adresów IP kontenerów
docker exec ubuntu1 ip addr show
docker exec ubuntu2 ip addr show

# 8. Sprawdzenie konfiguracji DNS
docker exec ubuntu1 cat /etc/resolv.conf

# 9. Czyszczenie
docker stop ubuntu1 ubuntu2
docker rm ubuntu1 ubuntu2
docker network rm test-siec
```

**Wyjaśnienie:**
- Kontenery w tej samej sieci mogą się komunikować po nazwie
- `ping -c 4` wysyła 4 pakiety ping
- `ip addr show` pokazuje konfigurację sieci kontenera
- `/etc/resolv.conf` zawiera konfigurację DNS

### Rozwiązanie Zadania 1.3: Izolacja sieci

```bash
# 1. Utworzenie dwóch oddzielnych sieci
docker network create siec-a
docker network create siec-b

# 2. Uruchomienie kontenera w sieci siec-a
docker run -d --name kontener-a --network siec-a ubuntu:20.04 sleep infinity

# 3. Uruchomienie kontenera w sieci siec-b
docker run -d --name kontener-b --network siec-b ubuntu:20.04 sleep infinity

# 4. Instalacja ping w obu kontenerach
docker exec kontener-a apt-get update && docker exec kontener-a apt-get install -y iputils-ping
docker exec kontener-b apt-get update && docker exec kontener-b apt-get install -y iputils-ping

# 5. Próba pingowania między kontenerami z różnych sieci (powinno się nie udać)
docker exec kontener-a ping -c 2 kontener-b
# Powinno pokazać błąd: ping: kontener-b: Name or service not known

# 6. Podłączenie kontener-a do sieci siec-b
docker network connect siec-b kontener-a

# 7. Sprawdzenie czy teraz komunikacja działa
docker exec kontener-a ping -c 2 kontener-b

# 8. Sprawdzenie sieci kontener-a
docker network inspect siec-a
docker network inspect siec-b

# 9. Czyszczenie
docker stop kontener-a kontener-b
docker rm kontener-a kontener-b
docker network rm siec-a siec-b
```

**Wyjaśnienie:**
- Kontenery z różnych sieci są izolowane
- `docker network connect` pozwala podłączyć kontener do dodatkowej sieci
- Kontener może być podłączony do wielu sieci jednocześnie

## Poziom 2: Zaawansowane sieci

### Rozwiązanie Zadania 2.1: Host networking

```bash
# 1. Uruchomienie kontenera nginx w trybie host networking
docker run -d --name nginx-host --network host nginx:alpine

# 2. Sprawdzenie czy nginx jest dostępny na porcie 80 hosta
curl http://localhost:80
# lub otwórz przeglądarkę i wejdź na http://localhost

# 3. Sprawdzenie procesów sieciowych na hoście
netstat -tlnp | grep :80
# lub na macOS:
lsof -i :80

# 4. Zatrzymanie kontenera
docker stop nginx-host
docker rm nginx-host

# 5. Uruchomienie kontenera w trybie bridge
docker run -d --name nginx-bridge -p 8080:80 nginx:alpine

# 6. Sprawdzenie czy nginx jest dostępny na porcie 8080
curl http://localhost:8080

# 7. Porównanie różnic w dostępności
# Host networking: dostępny na porcie 80
# Bridge networking: dostępny na porcie 8080

# 8. Czyszczenie
docker stop nginx-bridge
docker rm nginx-bridge
```

**Wyjaśnienie:**
- Host networking używa sieci hosta bezpośrednio
- Kontener nasłuchuje na porcie 80 hosta
- Bridge networking używa mapowania portów
- Host networking jest szybszy ale mniej bezpieczny

### Rozwiązanie Zadania 2.2: Custom network driver

```bash
# 1. Utworzenie sieci z niestandardową konfiguracją
docker network create --driver bridge \
  --subnet=192.168.1.0/24 \
  --ip-range=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  --opt com.docker.network.bridge.name=br-custom \
  siec-custom

# 2. Sprawdzenie szczegółów sieci
docker network inspect siec-custom

# 3. Uruchomienie kontenera w tej sieci
docker run -d --name test-custom --network siec-custom ubuntu:20.04 sleep infinity

# 4. Sprawdzenie konfiguracji sieci kontenera
docker exec test-custom ip addr show
docker exec test-custom cat /etc/resolv.conf

# 5. Sprawdzenie routingu
docker exec test-custom ip route show

# 6. Sprawdzenie interfejsu sieciowego na hoście
ip addr show br-custom

# 7. Czyszczenie
docker stop test-custom
docker rm test-custom
docker network rm siec-custom
```

**Wyjaśnienie:**
- `--subnet` definiuje podsieć sieci
- `--ip-range` definiuje zakres adresów IP
- `--gateway` definiuje bramę sieciową
- `--opt com.docker.network.bridge.name` definiuje nazwę interfejsu bridge

### Rozwiązanie Zadania 2.3: Port forwarding i load balancing

```bash
# 1. Utworzenie sieci
docker network create load-balancer-siec

# 2. Uruchomienie trzech kontenerów nginx
docker run -d --name nginx1 --network load-balancer-siec nginx:alpine
docker run -d --name nginx2 --network load-balancer-siec nginx:alpine
docker run -d --name nginx3 --network load-balancer-siec nginx:alpine

# 3. Utworzenie konfiguracji nginx dla load balancera
mkdir nginx-config
cat > nginx-config/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream backend {
        server nginx1:80;
        server nginx2:80;
        server nginx3:80;
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

# 4. Utworzenie Dockerfile dla load balancera
cat > nginx-config/Dockerfile << 'EOF'
FROM nginx:alpine
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
EOF

# 5. Zbudowanie obrazu load balancera
docker build -t nginx-loadbalancer ./nginx-config

# 6. Uruchomienie load balancera
docker run -d --name load-balancer --network load-balancer-siec -p 8080:80 nginx-loadbalancer

# 7. Test load balancera
curl http://localhost:8080
# Wykonaj kilka razy aby zobaczyć różne odpowiedzi

# 8. Sprawdzenie logów load balancera
docker logs load-balancer

# 9. Czyszczenie
docker stop load-balancer nginx1 nginx2 nginx3
docker rm load-balancer nginx1 nginx2 nginx3
docker network rm load-balancer-siec
docker rmi nginx-loadbalancer
rm -rf nginx-config
```

**Wyjaśnienie:**
- `upstream backend` definiuje serwery backend
- `proxy_pass http://backend` przekierowuje żądania do upstream
- Load balancer rozdziela żądania między serwery

## Poziom 3: Podstawy wolumenów

### Rozwiązanie Zadania 3.1: Named volumes

```bash
# 1. Utworzenie named volume
docker volume create moj-wolumen

# 2. Sprawdzenie szczegółów wolumenu
docker volume inspect moj-wolumen

# 3. Uruchomienie kontenera z zamontowanym wolumenem
docker run -d --name test-volume -v moj-wolumen:/data ubuntu:20.04 sleep infinity

# 4. Wejście do kontenera i utworzenie pliku
docker exec -it test-volume bash
echo "Test data" > /data/test.txt
ls -la /data/
exit

# 5. Zatrzymanie i usunięcie kontenera
docker stop test-volume
docker rm test-volume

# 6. Uruchomienie nowego kontenera z tym samym wolumenem
docker run -d --name test-volume2 -v moj-wolumen:/data ubuntu:20.04 sleep infinity

# 7. Sprawdzenie czy plik nadal istnieje
docker exec test-volume2 cat /data/test.txt

# 8. Sprawdzenie szczegółów wolumenu
docker volume inspect moj-wolumen

# 9. Czyszczenie
docker stop test-volume2
docker rm test-volume2
docker volume rm moj-wolumen
```

**Wyjaśnienie:**
- `docker volume create` tworzy named volume
- `-v moj-wolumen:/data` montuje wolumen do katalogu w kontenerze
- Dane w named volume przetrwają usunięcie kontenera
- `docker volume inspect` pokazuje szczegóły wolumenu

### Rozwiązanie Zadania 3.2: Bind mounts

```bash
# 1. Utworzenie katalogu na hoście
mkdir -p ~/docker-data
echo "Host data" > ~/docker-data/host-file.txt

# 2. Uruchomienie kontenera z bind mount
docker run -d --name test-bind -v ~/docker-data:/container-data ubuntu:20.04 sleep infinity

# 3. Sprawdzenie czy plik z hosta jest widoczny w kontenerze
docker exec test-bind cat /container-data/host-file.txt

# 4. Utworzenie pliku w kontenerze
docker exec test-bind echo "Container data" > /container-data/container-file.txt

# 5. Sprawdzenie czy plik pojawił się na hoście
cat ~/docker-data/container-file.txt

# 6. Sprawdzenie uprawnień plików
ls -la ~/docker-data/

# 7. Sprawdzenie szczegółów montowania
docker inspect test-bind | grep -A 10 Mounts

# 8. Czyszczenie
docker stop test-bind
docker rm test-bind
rm -rf ~/docker-data
```

**Wyjaśnienie:**
- Bind mount montuje katalog hosta do kontenera
- Zmiany w kontenerze są widoczne na hoście i odwrotnie
- `-v ~/docker-data:/container-data` montuje katalog hosta do kontenera

### Rozwiązanie Zadania 3.3: Tmpfs mounts

```bash
# 1. Uruchomienie kontenera z tmpfs mount
docker run -d --name test-tmpfs --tmpfs /tmp-data ubuntu:20.04 sleep infinity

# 2. Wejście do kontenera i utworzenie pliku
docker exec -it test-tmpfs bash
echo "Temporary data" > /tmp-data/temp.txt
ls -la /tmp-data/
exit

# 3. Sprawdzenie czy plik istnieje
docker exec test-tmpfs ls -la /tmp-data/

# 4. Zatrzymanie kontenera
docker stop test-tmpfs

# 5. Uruchomienie kontenera ponownie
docker start test-tmpfs

# 6. Sprawdzenie czy plik zniknął
docker exec test-tmpfs ls -la /tmp-data/

# 7. Sprawdzenie szczegółów tmpfs
docker inspect test-tmpfs | grep -A 10 Tmpfs

# 8. Czyszczenie
docker stop test-tmpfs
docker rm test-tmpfs
```

**Wyjaśnienie:**
- Tmpfs mount tworzy tymczasowy system plików w pamięci
- Dane w tmpfs znikają po zatrzymaniu kontenera
- `--tmpfs /tmp-data` montuje tmpfs do katalogu w kontenerze

## Poziom 4: Zaawansowane wolumeny

### Rozwiązanie Zadania 4.1: Volume drivers

```bash
# 1. Sprawdzenie dostępnych volume drivers
docker volume ls

# 2. Utworzenie katalogu na hoście
mkdir -p /tmp/docker-volume

# 3. Utworzenie wolumenu z niestandardowymi opcjami
docker volume create --driver local \
  --opt type=none \
  --opt device=/tmp/docker-volume \
  --opt o=bind \
  custom-volume

# 4. Sprawdzenie szczegółów wolumenu
docker volume inspect custom-volume

# 5. Uruchomienie kontenera z niestandardowym wolumenem
docker run -d --name test-custom-volume -v custom-volume:/data ubuntu:20.04 sleep infinity

# 6. Utworzenie pliku w kontenerze
docker exec test-custom-volume echo "Custom volume data" > /data/custom.txt

# 7. Sprawdzenie czy plik pojawił się na hoście
cat /tmp/docker-volume/custom.txt

# 8. Sprawdzenie uprawnień
ls -la /tmp/docker-volume/

# 9. Czyszczenie
docker stop test-custom-volume
docker rm test-custom-volume
docker volume rm custom-volume
rm -rf /tmp/docker-volume
```

**Wyjaśnienie:**
- `--driver local` używa lokalnego drivera
- `--opt type=none` definiuje typ montowania
- `--opt device=/tmp/docker-volume` definiuje urządzenie
- `--opt o=bind` definiuje opcje montowania

### Rozwiązanie Zadania 4.2: Backup i restore wolumenów

```bash
# 1. Utworzenie wolumenu z danymi
docker volume create backup-test

# 2. Uruchomienie kontenera z danymi
docker run -d --name data-container -v backup-test:/data ubuntu:20.04 sleep infinity

# 3. Utworzenie plików testowych
docker exec data-container bash -c "echo 'Important data 1' > /data/file1.txt"
docker exec data-container bash -c "echo 'Important data 2' > /data/file2.txt"
docker exec data-container bash -c "mkdir -p /data/subdir && echo 'Subdirectory data' > /data/subdir/file3.txt"

# 4. Sprawdzenie zawartości wolumenu
docker exec data-container ls -la /data/
docker exec data-container ls -la /data/subdir/

# 5. Zatrzymanie kontenera
docker stop data-container
docker rm data-container

# 6. Utworzenie backupu wolumenu
docker run --rm -v backup-test:/data -v $(pwd):/backup ubuntu:20.04 tar czf /backup/backup.tar.gz -C /data .

# 7. Sprawdzenie czy backup został utworzony
ls -la backup.tar.gz

# 8. Usunięcie oryginalnego wolumenu
docker volume rm backup-test

# 9. Utworzenie nowego wolumenu
docker volume create restored-data

# 10. Przywrócenie danych z backupu
docker run --rm -v restored-data:/data -v $(pwd):/backup ubuntu:20.04 tar xzf /backup/backup.tar.gz -C /data

# 11. Sprawdzenie czy dane zostały przywrócone
docker run --rm -v restored-data:/data ubuntu:20.04 cat /data/file1.txt
docker run --rm -v restored-data:/data ubuntu:20.04 cat /data/file2.txt
docker run --rm -v restored-data:/data ubuntu:20.04 cat /data/subdir/file3.txt

# 12. Sprawdzenie struktury katalogów
docker run --rm -v restored-data:/data ubuntu:20.04 ls -la /data/
docker run --rm -v restored-data:/data ubuntu:20.04 ls -la /data/subdir/

# 13. Czyszczenie
docker volume rm restored-data
rm backup.tar.gz
```

**Wyjaśnienie:**
- `tar czf` tworzy skompresowany archiwum
- `tar xzf` rozpakowuje skompresowane archiwum
- Backup i restore używają tymczasowych kontenerów
- `-C /data` zmienia katalog przed wykonaniem tar

## Poziom 5: Praktyczne scenariusze

### Rozwiązanie Zadania 5.1: Aplikacja z bazą danych i persystencją

```bash
# 1. Utworzenie sieci dla aplikacji
docker network create app-network

# 2. Utworzenie wolumenu dla bazy danych
docker volume create postgres-data

# 3. Uruchomienie PostgreSQL z wolumenem
docker run -d --name postgres \
  --network app-network \
  -v postgres-data:/var/lib/postgresql/data \
  -e POSTGRES_DB=myapp \
  -e POSTGRES_USER=user \
  -e POSTGRES_PASSWORD=password \
  postgres:13

# 4. Utworzenie aplikacji Python
mkdir webapp-with-db
cd webapp-with-db

cat > app.py << 'EOF'
import psycopg2
from flask import Flask, jsonify
import os

app = Flask(__name__)

def get_db_connection():
    return psycopg2.connect(
        host='postgres',
        database='myapp',
        user='user',
        password='password'
    )

@app.route('/')
def hello():
    return 'Hello from app with database!'

@app.route('/users')
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

@app.route('/add-user/<name>')
def add_user(name):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute('INSERT INTO users (name) VALUES (%s)', (name,))
        conn.commit()
        conn.close()
        return jsonify({'message': f'User {name} added'})
    except Exception as e:
        return jsonify({'error': str(e)})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# 5. Utworzenie requirements.txt
cat > requirements.txt << 'EOF'
Flask==2.3.0
psycopg2-binary==2.9.0
EOF

# 6. Utworzenie Dockerfile
cat > Dockerfile << 'EOF'
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "app.py"]
EOF

# 7. Zbudowanie obrazu aplikacji
docker build -t my-app .

# 8. Uruchomienie aplikacji w sieci
docker run -d --name app --network app-network -p 5000:5000 my-app

# 9. Sprawdzenie czy aplikacja działa
curl http://localhost:5000

# 10. Utworzenie tabeli w bazie danych
docker exec postgres psql -U user -d myapp -c "CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, name VARCHAR(100));"

# 11. Dodanie użytkownika
curl http://localhost:5000/add-user/John

# 12. Sprawdzenie użytkowników
curl http://localhost:5000/users

# 13. Sprawdzenie czy dane są persystentne
docker stop app postgres
docker rm app postgres

# 14. Uruchomienie nowych kontenerów z tym samym wolumenem
docker run -d --name postgres2 \
  --network app-network \
  -v postgres-data:/var/lib/postgresql/data \
  -e POSTGRES_DB=myapp \
  -e POSTGRES_USER=user \
  -e POSTGRES_PASSWORD=password \
  postgres:13

docker run -d --name app2 --network app-network -p 5000:5000 my-app

# 15. Sprawdzenie czy dane przetrwały
curl http://localhost:5000/users

# 16. Czyszczenie
docker stop app2 postgres2
docker rm app2 postgres2
docker network rm app-network
docker volume rm postgres-data
docker rmi my-app
cd ..
rm -rf webapp-with-db
```

**Wyjaśnienie:**
- Aplikacja łączy się z PostgreSQL przez sieć
- Wolumen zapewnia persystencję danych bazy
- Dane przetrwają usunięcie i ponowne utworzenie kontenerów

### Rozwiązanie Zadania 5.2: Mikroserwisy z komunikacją

```bash
# 1. Utworzenie sieci dla mikroserwisów
docker network create microservices

# 2. Utworzenie serwisu API
mkdir api-service
cd api-service

cat > app.py << 'EOF'
from flask import Flask, jsonify
import requests

app = Flask(__name__)

@app.route('/api/data')
def get_data():
    try:
        response = requests.get('http://data-service:5001/data')
        return jsonify(response.json())
    except Exception as e:
        return jsonify({'error': 'Service unavailable', 'details': str(e)})

@app.route('/api/status')
def status():
    return jsonify({'status': 'API service running'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

cat > requirements.txt << 'EOF'
Flask==2.3.0
requests==2.28.0
EOF

cat > Dockerfile << 'EOF'
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "app.py"]
EOF

# 3. Utworzenie serwisu danych
cd ..
mkdir data-service
cd data-service

cat > app.py << 'EOF'
from flask import Flask, jsonify
import time

app = Flask(__name__)

@app.route('/data')
def get_data():
    return jsonify({
        'message': 'Data from service',
        'timestamp': time.time(),
        'service': 'data-service'
    })

@app.route('/status')
def status():
    return jsonify({'status': 'Data service running'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
EOF

cat > requirements.txt << 'EOF'
Flask==2.3.0
EOF

cat > Dockerfile << 'EOF'
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 5001
CMD ["python", "app.py"]
EOF

# 4. Zbudowanie obrazów
cd ..
docker build -t api-service ./api-service
docker build -t data-service ./data-service

# 5. Uruchomienie serwisu danych
docker run -d --name data-service --network microservices data-service

# 6. Uruchomienie serwisu API
docker run -d --name api-service --network microservices -p 5000:5000 api-service

# 7. Sprawdzenie czy serwisy działają
curl http://localhost:5000/api/status
curl http://localhost:5000/api/data

# 8. Sprawdzenie logów
docker logs api-service
docker logs data-service

# 9. Test komunikacji między serwisami
docker exec api-service curl http://data-service:5001/data

# 10. Czyszczenie
docker stop api-service data-service
docker rm api-service data-service
docker network rm microservices
docker rmi api-service data-service
rm -rf api-service data-service
```

**Wyjaśnienie:**
- Serwisy komunikują się przez sieć używając nazw kontenerów
- API service wywołuje data service przez HTTP
- Sieć umożliwia komunikację między kontenerami

### Rozwiązanie Zadania 5.3: Monitoring i logowanie

```bash
# 1. Utworzenie sieci dla monitoringu
docker network create monitoring

# 2. Utworzenie konfiguracji Prometheus
mkdir prometheus-config
cat > prometheus-config/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'docker'
    static_configs:
      - targets: ['host.docker.internal:9323']
  
  - job_name: 'nginx'
    static_configs:
      - targets: ['monitored-app:8080']
EOF

# 3. Uruchomienie Prometheus
docker run -d --name prometheus \
  --network monitoring \
  -p 9090:9090 \
  -v $(pwd)/prometheus-config/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus

# 4. Uruchomienie Grafana
docker run -d --name grafana \
  --network monitoring \
  -p 3000:3000 \
  grafana/grafana

# 5. Uruchomienie aplikacji do monitorowania
docker run -d --name monitored-app \
  --network monitoring \
  -p 8080:8080 \
  nginx:alpine

# 6. Sprawdzenie czy wszystkie serwisy działają
docker ps

# 7. Sprawdzenie logów
docker logs prometheus
docker logs grafana
docker logs monitored-app

# 8. Test aplikacji
curl http://localhost:8080

# 9. Sprawdzenie Prometheus
curl http://localhost:9090

# 10. Sprawdzenie Grafana
curl http://localhost:3000

# 11. Sprawdzenie sieci
docker network inspect monitoring

# 12. Czyszczenie
docker stop prometheus grafana monitored-app
docker rm prometheus grafana monitored-app
docker network rm monitoring
rm -rf prometheus-config
```

**Wyjaśnienie:**
- Prometheus zbiera metryki z aplikacji
- Grafana wizualizuje metryki
- Sieć umożliwia komunikację między serwisami monitorującymi

## Wskazówki i najlepsze praktyki

### Sieci:
- Używaj named networks zamiast domyślnej sieci bridge
- Izoluj aplikacje w oddzielnych sieciach
- Używaj host networking tylko gdy jest to konieczne
- Konfiguruj DNS i routing zgodnie z potrzebami

### Wolumeny:
- Używaj named volumes dla danych aplikacji
- Używaj bind mounts dla konfiguracji
- Regularnie twórz backup ważnych danych
- Monitoruj wykorzystanie miejsca na dysku

### Bezpieczeństwo:
- Ogranicz dostęp do sieci między kontenerami
- Używaj nieprivilegowanych użytkowników
- Szyfruj wrażliwe dane w wolumenach
- Regularnie aktualizuj obrazy bazowe

### Przydatne komendy:

```bash
# Zarządzanie sieciami
docker network ls
docker network inspect [nazwa-sieci]
docker network create [nazwa-sieci]
docker network rm [nazwa-sieci]

# Zarządzanie wolumenami
docker volume ls
docker volume inspect [nazwa-wolumenu]
docker volume create [nazwa-wolumenu]
docker volume rm [nazwa-wolumenu]

# Debugowanie sieci
docker exec [kontener] ip addr show
docker exec [kontener] cat /etc/resolv.conf
docker exec [kontener] nslookup [hostname]

# Debugowanie wolumenów
docker exec [kontener] df -h
docker exec [kontener] mount | grep volume

# Sprawdzenie połączeń sieciowych
docker exec [kontener] netstat -tlnp
docker exec [kontener] ss -tlnp

# Sprawdzenie routingu
docker exec [kontener] ip route show
docker exec [kontener] traceroute [hostname]
```

