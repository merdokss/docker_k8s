# Zadania Docker - Sieci i Wolumeny

## Poziom 1: Podstawy sieci Docker

### Zadanie 1.1: Tworzenie i zarządzanie sieciami
**Cel:** Zapoznanie się z różnymi typami sieci Docker

1. Sprawdź domyślne sieci Docker:
   ```bash
   docker network ls
   ```

2. Sprawdź szczegóły sieci bridge:
   ```bash
   docker network inspect bridge
   ```

3. Utwórz nową sieć typu bridge o nazwie `moja-siec`:
   ```bash
   docker network create moja-siec
   ```

4. Sprawdź szczegóły nowo utworzonej sieci:
   ```bash
   docker network inspect moja-siec
   ```

5. Utwórz sieć z niestandardową konfiguracją:
   ```bash
   docker network create --subnet=172.20.0.0/16 --gateway=172.20.0.1 moja-siec-custom
   ```

6. Sprawdź szczegóły sieci z niestandardową konfiguracją

### Zadanie 1.2: Komunikacja między kontenerami
**Cel:** Uruchamianie kontenerów w sieci i testowanie komunikacji

1. Utwórz sieć o nazwie `test-siec`
2. Uruchom pierwszy kontener Ubuntu w tej sieci:
   ```bash
   docker run -d --name ubuntu1 --network test-siec ubuntu:20.04 sleep infinity
   ```

3. Uruchom drugi kontener Ubuntu w tej samej sieci:
   ```bash
   docker run -d --name ubuntu2 --network test-siec ubuntu:20.04 sleep infinity
   ```

4. Zainstaluj `ping` w obu kontenerach:
   ```bash
   docker exec ubuntu1 apt-get update && docker exec ubuntu1 apt-get install -y iputils-ping
   docker exec ubuntu2 apt-get update && docker exec ubuntu2 apt-get install -y iputils-ping
   ```

5. Z kontenera `ubuntu1` sprawdź połączenie z `ubuntu2`:
   ```bash
   docker exec ubuntu1 ping -c 4 ubuntu2
   ```

6. Z kontenera `ubuntu2` sprawdź połączenie z `ubuntu1`:
   ```bash
   docker exec ubuntu2 ping -c 4 ubuntu1
   ```

7. Sprawdź adresy IP kontenerów:
   ```bash
   docker exec ubuntu1 ip addr show
   docker exec ubuntu2 ip addr show
   ```

### Zadanie 1.3: Izolacja sieci
**Cel:** Zrozumienie izolacji sieci między różnymi sieciami

1. Utwórz dwie oddzielne sieci:
   ```bash
   docker network create siec-a
   docker network create siec-b
   ```

2. Uruchom kontener w sieci `siec-a`:
   ```bash
   docker run -d --name kontener-a --network siec-a ubuntu:20.04 sleep infinity
   ```

3. Uruchom kontener w sieci `siec-b`:
   ```bash
   docker run -d --name kontener-b --network siec-b ubuntu:20.04 sleep infinity
   ```

4. Zainstaluj `ping` w obu kontenerach
5. Spróbuj pingować między kontenerami z różnych sieci (powinno się nie udać)
6. Podłącz kontener `kontener-a` do sieci `siec-b`:
   ```bash
   docker network connect siec-b kontener-a
   ```

7. Sprawdź czy teraz komunikacja działa

## Poziom 2: Zaawansowane sieci

### Zadanie 2.1: Host networking
**Cel:** Używanie sieci hosta

1. Uruchom kontener nginx w trybie host networking:
   ```bash
   docker run -d --name nginx-host --network host nginx:alpine
   ```

2. Sprawdź czy nginx jest dostępny na porcie 80 hosta
3. Sprawdź procesy sieciowe na hoście:
   ```bash
   netstat -tlnp | grep :80
   ```

4. Zatrzymaj kontener i uruchom go w trybie bridge:
   ```bash
   docker run -d --name nginx-bridge -p 8080:80 nginx:alpine
   ```

5. Porównaj różnice w dostępności

### Zadanie 2.2: Custom network driver
**Cel:** Tworzenie sieci z niestandardowymi ustawieniami

1. Utwórz sieć z niestandardową konfiguracją DNS:
   ```bash
   docker network create --driver bridge \
     --subnet=192.168.1.0/24 \
     --ip-range=192.168.1.0/24 \
     --gateway=192.168.1.1 \
     --opt com.docker.network.bridge.name=br-custom \
     siec-custom
   ```

2. Sprawdź szczegóły sieci:
   ```bash
   docker network inspect siec-custom
   ```

3. Uruchom kontener w tej sieci:
   ```bash
   docker run -d --name test-custom --network siec-custom ubuntu:20.04 sleep infinity
   ```

4. Sprawdź konfigurację sieci kontenera:
   ```bash
   docker exec test-custom ip addr show
   docker exec test-custom cat /etc/resolv.conf
   ```

### Zadanie 2.3: Port forwarding i load balancing
**Cel:** Konfiguracja zaawansowanego routingu

1. Utwórz sieć o nazwie `load-balancer-siec`
2. Uruchom trzy kontenery nginx w tej sieci:
   ```bash
   docker run -d --name nginx1 --network load-balancer-siec nginx:alpine
   docker run -d --name nginx2 --network load-balancer-siec nginx:alpine
   docker run -d --name nginx3 --network load-balancer-siec nginx:alpine
   ```

3. Utwórz kontener z nginx jako load balancer:
   ```bash
   docker run -d --name load-balancer --network load-balancer-siec -p 8080:80 nginx:alpine
   ```

4. Skonfiguruj nginx jako load balancer (będzie to wymagało wejścia do kontenera i edycji konfiguracji)

## Poziom 3: Podstawy wolumenów

### Zadanie 3.1: Named volumes
**Cel:** Tworzenie i zarządzanie named volumes

1. Utwórz named volume o nazwie `moj-wolumen`:
   ```bash
   docker volume create moj-wolumen
   ```

2. Sprawdź szczegóły wolumenu:
   ```bash
   docker volume inspect moj-wolumen
   ```

3. Uruchom kontener z zamontowanym wolumenem:
   ```bash
   docker run -d --name test-volume -v moj-wolumen:/data ubuntu:20.04 sleep infinity
   ```

4. Wejdź do kontenera i utwórz plik w wolumenie:
   ```bash
   docker exec -it test-volume bash
   echo "Test data" > /data/test.txt
   ls -la /data/
   exit
   ```

5. Zatrzymaj i usuń kontener:
   ```bash
   docker stop test-volume
   docker rm test-volume
   ```

6. Uruchom nowy kontener z tym samym wolumenem:
   ```bash
   docker run -d --name test-volume2 -v moj-wolumen:/data ubuntu:20.04 sleep infinity
   ```

7. Sprawdź czy plik nadal istnieje:
   ```bash
   docker exec test-volume2 cat /data/test.txt
   ```

### Zadanie 3.2: Bind mounts
**Cel:** Montowanie katalogów hosta do kontenera

1. Utwórz katalog na hoście:
   ```bash
   mkdir -p ~/docker-data
   echo "Host data" > ~/docker-data/host-file.txt
   ```

2. Uruchom kontener z bind mount:
   ```bash
   docker run -d --name test-bind -v ~/docker-data:/container-data ubuntu:20.04 sleep infinity
   ```

3. Sprawdź czy plik z hosta jest widoczny w kontenerze:
   ```bash
   docker exec test-bind cat /container-data/host-file.txt
   ```

4. Utwórz plik w kontenerze i sprawdź czy pojawił się na hoście:
   ```bash
   docker exec test-bind echo "Container data" > /container-data/container-file.txt
   cat ~/docker-data/container-file.txt
   ```

5. Zatrzymaj i usuń kontener

### Zadanie 3.3: Tmpfs mounts
**Cel:** Używanie tmpfs dla tymczasowych danych

1. Uruchom kontener z tmpfs mount:
   ```bash
   docker run -d --name test-tmpfs --tmpfs /tmp-data ubuntu:20.04 sleep infinity
   ```

2. Wejdź do kontenera i utwórz plik w tmpfs:
   ```bash
   docker exec -it test-tmpfs bash
   echo "Temporary data" > /tmp-data/temp.txt
   ls -la /tmp-data/
   exit
   ```

3. Zatrzymaj kontener:
   ```bash
   docker stop test-tmpfs
   ```

4. Uruchom kontener ponownie i sprawdź czy plik zniknął:
   ```bash
   docker start test-tmpfs
   docker exec test-tmpfs ls -la /tmp-data/
   ```

## Poziom 4: Zaawansowane wolumeny

### Zadanie 4.1: Volume drivers
**Cel:** Używanie różnych driverów wolumenów

1. Sprawdź dostępne volume drivers:
   ```bash
   docker volume ls
   ```

2. Utwórz wolumen z niestandardowymi opcjami:
   ```bash
   docker volume create --driver local \
     --opt type=none \
     --opt device=/tmp/docker-volume \
     --opt o=bind \
     custom-volume
   ```

3. Sprawdź szczegóły wolumenu:
   ```bash
   docker volume inspect custom-volume
   ```

4. Uruchom kontener z niestandardowym wolumenem:
   ```bash
   docker run -d --name test-custom-volume -v custom-volume:/data ubuntu:20.04 sleep infinity
   ```

5. Przetestuj działanie wolumenu

### Zadanie 4.2: Backup i restore wolumenów
**Cel:** Tworzenie kopii zapasowych danych

1. Utwórz wolumen z danymi:
   ```bash
   docker volume create backup-test
   docker run -d --name data-container -v backup-test:/data ubuntu:20.04 sleep infinity
   docker exec data-container bash -c "echo 'Important data' > /data/important.txt"
   ```

2. Utwórz backup wolumenu:
   ```bash
   docker run --rm -v backup-test:/data -v $(pwd):/backup ubuntu:20.04 tar czf /backup/backup.tar.gz -C /data .
   ```

3. Sprawdź czy backup został utworzony:
   ```bash
   ls -la backup.tar.gz
   ```

4. Usuń oryginalny wolumen i kontener:
   ```bash
   docker stop data-container
   docker rm data-container
   docker volume rm backup-test
   ```

5. Przywróć dane z backupu:
   ```bash
   docker volume create restored-data
   docker run --rm -v restored-data:/data -v $(pwd):/backup ubuntu:20.04 tar xzf /backup/backup.tar.gz -C /data
   ```

6. Sprawdź czy dane zostały przywrócone:
   ```bash
   docker run --rm -v restored-data:/data ubuntu:20.04 cat /data/important.txt
   ```

## Poziom 5: Praktyczne scenariusze

### Zadanie 5.1: Aplikacja z bazą danych i persystencją
**Cel:** Stworzenie aplikacji z persystentną bazą danych

1. Utwórz sieć dla aplikacji:
   ```bash
   docker network create app-network
   ```

2. Utwórz wolumen dla bazy danych:
   ```bash
   docker volume create postgres-data
   ```

3. Uruchom PostgreSQL z wolumenem:
   ```bash
   docker run -d --name postgres \
     --network app-network \
     -v postgres-data:/var/lib/postgresql/data \
     -e POSTGRES_DB=myapp \
     -e POSTGRES_USER=user \
     -e POSTGRES_PASSWORD=password \
     postgres:13
   ```

4. Utwórz aplikację Python (`app.py`):
   ```python
   import psycopg2
   from flask import Flask, jsonify
   
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
       conn = get_db_connection()
       cursor = conn.cursor()
       cursor.execute('SELECT * FROM users')
       users = cursor.fetchall()
       conn.close()
       return jsonify(users)
   
   if __name__ == '__main__':
       app.run(host='0.0.0.0', port=5000)
   ```

5. Utwórz `Dockerfile` dla aplikacji:
   ```dockerfile
   FROM python:3.9-slim
   WORKDIR /app
   COPY requirements.txt .
   RUN pip install -r requirements.txt
   COPY . .
   EXPOSE 5000
   CMD ["python", "app.py"]
   ```

6. Utwórz `requirements.txt`:
   ```
   Flask==2.3.0
   psycopg2-binary==2.9.0
   ```

7. Zbuduj i uruchom aplikację w sieci:
   ```bash
   docker build -t my-app .
   docker run -d --name app --network app-network -p 5000:5000 my-app
   ```

8. Sprawdź czy aplikacja działa i czy dane są persystentne

### Zadanie 5.2: Mikroserwisy z komunikacją
**Cel:** Stworzenie architektury mikroserwisów

1. Utwórz sieć dla mikroserwisów:
   ```bash
   docker network create microservices
   ```

2. Utwórz serwis API (`api/app.py`):
   ```python
   from flask import Flask, jsonify
   import requests
   
   app = Flask(__name__)
   
   @app.route('/api/data')
   def get_data():
       # Komunikacja z innym serwisem
       try:
           response = requests.get('http://data-service:5001/data')
           return jsonify(response.json())
       except:
           return jsonify({'error': 'Service unavailable'})
   
   if __name__ == '__main__':
       app.run(host='0.0.0.0', port=5000)
   ```

3. Utwórz serwis danych (`data/app.py`):
   ```python
   from flask import Flask, jsonify
   
   app = Flask(__name__)
   
   @app.route('/data')
   def get_data():
       return jsonify({'message': 'Data from service', 'timestamp': '2023-01-01'})
   
   if __name__ == '__main__':
       app.run(host='0.0.0.0', port=5001)
   ```

4. Utwórz `Dockerfile` dla obu serwisów
5. Zbuduj i uruchom oba serwisy w sieci `microservices`
6. Sprawdź komunikację między serwisami

### Zadanie 5.3: Monitoring i logowanie
**Cel:** Konfiguracja monitoringu kontenerów

1. Utwórz sieć dla monitoringu:
   ```bash
   docker network create monitoring
   ```

2. Uruchom Prometheus:
   ```bash
   docker run -d --name prometheus \
     --network monitoring \
     -p 9090:9090 \
     prom/prometheus
   ```

3. Uruchom Grafana:
   ```bash
   docker run -d --name grafana \
     --network monitoring \
     -p 3000:3000 \
     grafana/grafana
   ```

4. Uruchom aplikację do monitorowania:
   ```bash
   docker run -d --name monitored-app \
     --network monitoring \
     -p 8080:8080 \
     nginx:alpine
   ```

5. Sprawdź czy wszystkie serwisy działają i są dostępne

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
```

