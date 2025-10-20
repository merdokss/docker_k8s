# Rozwiązania - Zadania Docker Podstawy

## Poziom 1: Pierwsze kroki z Docker

### Rozwiązanie Zadania 1.1: Uruchamianie pierwszego kontenera

```bash
# 1. Sprawdzenie wersji Docker
docker --version

# 2. Pobranie obrazu hello-world
docker pull hello-world

# 3. Uruchomienie kontenera
docker run hello-world

# 4. Sprawdzenie listy wszystkich kontenerów
docker ps -a

# 5. Usunięcie kontenera (jeśli ma nazwę, użyj nazwy, w przeciwnym razie użyj ID)
docker rm $(docker ps -a -q --filter ancestor=hello-world)
```

**Wyjaśnienie:**
- `docker pull` pobiera obraz z Docker Hub
- `docker run` uruchamia kontener z obrazu
- `docker ps -a` pokazuje wszystkie kontenery (uruchomione i zatrzymane)
- `docker rm` usuwa zatrzymany kontener

### Rozwiązanie Zadania 1.2: Praca z obrazami

```bash
# 1. Pobranie obrazu Ubuntu
docker pull ubuntu:20.04

# 2. Sprawdzenie listy obrazów
docker images

# 3. Uruchomienie kontenera w trybie interaktywnym
docker run -it ubuntu:20.04 /bin/bash

# W kontenerze wykonaj:
# ls -la
# whoami
# exit

# 4. Sprawdzenie statusu kontenera
docker ps -a

# 5. Usunięcie zatrzymanego kontenera
docker rm $(docker ps -a -q --filter ancestor=ubuntu:20.04)
```

**Wyjaśnienie:**
- `-it` uruchamia kontener w trybie interaktywnym z terminalem
- `/bin/bash` uruchamia bash w kontenerze
- `exit` kończy sesję w kontenerze

### Rozwiązanie Zadania 1.3: Uruchamianie serwera webowego

```bash
# 1. Pobranie obrazu nginx
docker pull nginx:alpine

# 2. Uruchomienie kontenera w trybie odłączonym
docker run -d --name moj-nginx -p 8080:80 nginx:alpine

# 3. Sprawdzenie czy kontener działa
docker ps

# 4. Sprawdzenie czy strona jest dostępna
curl http://localhost:8080
# lub otwórz przeglądarkę i wejdź na http://localhost:8080

# 5. Sprawdzenie logów kontenera
docker logs moj-nginx

# 6. Zatrzymanie i usunięcie kontenera
docker stop moj-nginx
docker rm moj-nginx
```

**Wyjaśnienie:**
- `-d` uruchamia kontener w tle (detached mode)
- `--name` nadaje nazwę kontenerowi
- `-p 8080:80` mapuje port 8080 hosta na port 80 kontenera
- `docker logs` pokazuje logi kontenera

## Poziom 2: Zarządzanie kontenerami

### Rozwiązanie Zadania 2.1: Praca z wolumenami

```bash
# 1. Utworzenie named volume
docker volume create moj-wolumen

# 2. Uruchomienie kontenera z wolumenem
docker run -d --name nginx-volume -v moj-wolumen:/usr/share/nginx/html nginx:alpine

# 3. Wejście do kontenera i utworzenie pliku
docker exec -it nginx-volume sh
echo "Test z wolumenu" > /usr/share/nginx/html/test.txt
exit

# 4. Zatrzymanie i usunięcie kontenera
docker stop nginx-volume
docker rm nginx-volume

# 5. Uruchomienie nowego kontenera z tym samym wolumenem
docker run -d --name nginx-volume2 -v moj-wolumen:/usr/share/nginx/html nginx:alpine

# 6. Sprawdzenie czy plik nadal istnieje
docker exec nginx-volume2 cat /usr/share/nginx/html/test.txt

# 7. Czyszczenie
docker stop nginx-volume2
docker rm nginx-volume2
docker volume rm moj-wolumen
```

**Wyjaśnienie:**
- `docker volume create` tworzy named volume
- `-v moj-wolumen:/usr/share/nginx/html` montuje wolumen do katalogu w kontenerze
- Dane w named volume przetrwają usunięcie kontenera

### Rozwiązanie Zadania 2.2: Zmienne środowiskowe

```bash
# 1. Uruchomienie kontenera MySQL z zmiennymi środowiskowymi
docker run -d --name mysql-container \
  -e MYSQL_ROOT_PASSWORD=haslo123 \
  -e MYSQL_DATABASE=testdb \
  -e MYSQL_USER=uzytkownik \
  -e MYSQL_PASSWORD=haslo456 \
  mysql:8.0

# 2. Sprawdzenie logów kontenera
docker logs mysql-container

# 3. Wejście do kontenera i połączenie z bazą danych
docker exec -it mysql-container mysql -u uzytkownik -p
# Wprowadź hasło: haslo456

# W konsoli MySQL:
# SHOW DATABASES;
# USE testdb;
# SHOW TABLES;
# exit

# 4. Sprawdzenie czy baza testdb została utworzona
docker exec mysql-container mysql -u uzytkownik -phaslo456 -e "SHOW DATABASES;"

# 5. Zatrzymanie i usunięcie kontenera
docker stop mysql-container
docker rm mysql-container
```

**Wyjaśnienie:**
- `-e` ustawia zmienne środowiskowe w kontenerze
- MySQL używa zmiennych do konfiguracji bazy danych
- `docker logs` pokazuje logi inicjalizacji bazy danych

### Rozwiązanie Zadania 2.3: Zarządzanie siecią

```bash
# 1. Utworzenie nowej sieci
docker network create moja-siec

# 2. Sprawdzenie szczegółów sieci
docker network inspect moja-siec

# 3. Uruchomienie pierwszego kontenera Ubuntu
docker run -d --name ubuntu1 --network moja-siec ubuntu:20.04 sleep infinity

# 4. Uruchomienie drugiego kontenera Ubuntu
docker run -d --name ubuntu2 --network moja-siec ubuntu:20.04 sleep infinity

# 5. Instalacja ping w obu kontenerach
docker exec ubuntu1 apt-get update && docker exec ubuntu1 apt-get install -y iputils-ping
docker exec ubuntu2 apt-get update && docker exec ubuntu2 apt-get install -y iputils-ping

# 6. Test połączenia z ubuntu1 do ubuntu2
docker exec ubuntu1 ping -c 4 ubuntu2

# 7. Test połączenia z ubuntu2 do ubuntu1
docker exec ubuntu2 ping -c 4 ubuntu1

# 8. Sprawdzenie adresów IP
docker exec ubuntu1 ip addr show
docker exec ubuntu2 ip addr show

# 9. Czyszczenie
docker stop ubuntu1 ubuntu2
docker rm ubuntu1 ubuntu2
docker network rm moja-siec
```

**Wyjaśnienie:**
- `docker network create` tworzy nową sieć
- `--network moja-siec` przyłącza kontener do sieci
- Kontenery w tej samej sieci mogą się komunikować po nazwie

## Poziom 3: Debugging i monitorowanie

### Rozwiązanie Zadania 3.1: Analiza kontenerów

```bash
# 1. Uruchomienie kontenera Redis
docker run -d --name redis-container redis:alpine

# 2. Sprawdzenie szczegółowych informacji o kontenerze
docker inspect redis-container

# 3. Sprawdzenie wykorzystania zasobów
docker stats redis-container

# 4. Wejście do kontenera i sprawdzenie procesów
docker exec -it redis-container sh
ps aux
exit

# 5. Sprawdzenie logów w trybie follow
docker logs -f redis-container
# Naciśnij Ctrl+C aby wyjść

# 6. Zatrzymanie kontenera
docker stop redis-container
docker rm redis-container
```

**Wyjaśnienie:**
- `docker inspect` pokazuje szczegółowe informacje o kontenerze
- `docker stats` pokazuje wykorzystanie zasobów w czasie rzeczywistym
- `docker logs -f` pokazuje logi w trybie follow

### Rozwiązanie Zadania 3.2: Rozwiązywanie problemów

```bash
# 1. Uruchomienie kontenera z nieprawidłową konfiguracją portu
docker run -d --name nginx-bad -p 80:80 nginx:alpine
# To może się nie udać jeśli port 80 jest już zajęty

# 2. Sprawdzenie dlaczego kontener się nie uruchamia
docker logs nginx-bad

# 3. Sprawdzenie statusu kontenera
docker ps -a

# 4. Usunięcie problematycznego kontenera
docker rm nginx-bad

# 5. Uruchomienie kontenera z poprawną konfiguracją
docker run -d --name nginx-good -p 8080:80 nginx:alpine

# 6. Sprawdzenie czy kontener działa
docker ps
curl http://localhost:8080

# 7. Czyszczenie
docker stop nginx-good
docker rm nginx-good
```

**Wyjaśnienie:**
- Port 80 może być zajęty przez inny proces
- `docker logs` pomaga zdiagnozować problemy
- `docker ps -a` pokazuje wszystkie kontenery, w tym zatrzymane

## Poziom 4: Optymalizacja i najlepsze praktyki

### Rozwiązanie Zadania 4.1: Czyszczenie systemu

```bash
# 1. Sprawdzenie wykorzystania miejsca na dysku
docker system df

# 2. Usunięcie wszystkich zatrzymanych kontenerów
docker container prune -f

# 3. Usunięcie wszystkich nieużywanych obrazów
docker image prune -a -f

# 4. Usunięcie wszystkich nieużywanych wolumenów
docker volume prune -f

# 5. Usunięcie wszystkich nieużywanych sieci
docker network prune -f

# 6. Sprawdzenie ponownie wykorzystania miejsca
docker system df

# 7. Kompleksowe czyszczenie (opcjonalne)
docker system prune -a -f --volumes
```

**Wyjaśnienie:**
- `docker system df` pokazuje wykorzystanie miejsca przez Docker
- `docker container prune` usuwa zatrzymane kontenery
- `docker image prune -a` usuwa wszystkie nieużywane obrazy
- `docker system prune -a` wykonuje kompleksowe czyszczenie

### Rozwiązanie Zadania 4.2: Tagowanie obrazów

```bash
# 1. Pobranie obrazu nginx
docker pull nginx:latest

# 2. Utworzenie tagu moja-wersja
docker tag nginx:latest nginx:moja-wersja

# 3. Utworzenie tagu 1.0
docker tag nginx:latest nginx:1.0

# 4. Sprawdzenie listy obrazów i ich tagów
docker images nginx

# 5. Usunięcie obrazu nginx:latest
docker rmi nginx:latest

# 6. Sprawdzenie czy obrazy z tagami nadal działają
docker run --rm nginx:moja-wersja nginx -v
docker run --rm nginx:1.0 nginx -v

# 7. Czyszczenie
docker rmi nginx:moja-wersja nginx:1.0
```

**Wyjaśnienie:**
- `docker tag` tworzy nowy tag dla istniejącego obrazu
- Usunięcie obrazu z tagiem `latest` nie usuwa obrazów z innymi tagami
- Obrazy z tagami nadal działają po usunięciu `latest`

## Poziom 5: Zaawansowane scenariusze

### Rozwiązanie Zadania 5.1: Multi-container aplikacja

```bash
# 1. Utworzenie sieci dla aplikacji
docker network create aplikacja-siec

# 2. Uruchomienie PostgreSQL z wolumenem
docker run -d --name postgres-db \
  --network aplikacja-siec \
  -v postgres-data:/var/lib/postgresql/data \
  -e POSTGRES_DB=appdb \
  -e POSTGRES_USER=appuser \
  -e POSTGRES_PASSWORD=apppass \
  postgres:13

# 3. Uruchomienie aplikacji webowej
docker run -d --name web-app \
  --network aplikacja-siec \
  -p 5000:5000 \
  -e DATABASE_URL=postgresql://appuser:apppass@postgres-db:5432/appdb \
  python:3.9-slim python -c "
import time
import psycopg2
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    try:
        conn = psycopg2.connect('postgresql://appuser:apppass@postgres-db:5432/appdb')
        return 'Connected to database!'
    except:
        return 'Database connection failed'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
"

# 4. Sprawdzenie czy oba kontenery działają
docker ps

# 5. Sprawdzenie logów obu kontenerów
docker logs postgres-db
docker logs web-app

# 6. Test aplikacji
curl http://localhost:5000

# 7. Czyszczenie
docker stop postgres-db web-app
docker rm postgres-db web-app
docker network rm aplikacja-siec
docker volume rm postgres-data
```

**Wyjaśnienie:**
- Kontenery w tej samej sieci mogą się komunikować po nazwie
- Wolumen zapewnia persystencję danych bazy
- Aplikacja próbuje połączyć się z bazą danych

### Rozwiązanie Zadania 5.2: Backup i restore

```bash
# 1. Utworzenie wolumenu z danymi
docker volume create backup-data

# 2. Uruchomienie kontenera z wolumenem
docker run -d --name data-container -v backup-data:/data ubuntu:20.04 sleep infinity

# 3. Utworzenie plików testowych w kontenerze
docker exec data-container bash -c "echo 'Important data 1' > /data/file1.txt"
docker exec data-container bash -c "echo 'Important data 2' > /data/file2.txt"

# 4. Zatrzymanie kontenera
docker stop data-container
docker rm data-container

# 5. Utworzenie backupu wolumenu
docker run --rm -v backup-data:/data -v $(pwd):/backup ubuntu:20.04 tar czf /backup/backup.tar.gz -C /data .

# 6. Sprawdzenie czy backup został utworzony
ls -la backup.tar.gz

# 7. Usunięcie oryginalnego wolumenu
docker volume rm backup-data

# 8. Przywrócenie danych z backupu
docker volume create restored-data
docker run --rm -v restored-data:/data -v $(pwd):/backup ubuntu:20.04 tar xzf /backup/backup.tar.gz -C /data

# 9. Sprawdzenie czy dane zostały przywrócone
docker run --rm -v restored-data:/data ubuntu:20.04 cat /data/file1.txt
docker run --rm -v restored-data:/data ubuntu:20.04 cat /data/file2.txt

# 10. Czyszczenie
docker volume rm restored-data
rm backup.tar.gz
```

**Wyjaśnienie:**
- `tar czf` tworzy skompresowany archiwum
- `tar xzf` rozpakowuje skompresowane archiwum
- Backup i restore używają tymczasowych kontenerów

## Wskazówki do rozwiązywania problemów

### Typowe problemy i rozwiązania:

1. **Kontener się nie uruchamia:**
   ```bash
   # Sprawdź logi
   docker logs [nazwa-kontenera]
   
   # Sprawdź status
   docker ps -a
   
   # Sprawdź konfigurację portów
   docker port [nazwa-kontenera]
   ```

2. **Brak dostępu do aplikacji:**
   ```bash
   # Sprawdź mapowanie portów
   docker port [nazwa-kontenera]
   
   # Sprawdź czy kontener działa
   docker ps
   
   # Sprawdź logi aplikacji
   docker logs [nazwa-kontenera]
   ```

3. **Problemy z wolumenami:**
   ```bash
   # Sprawdź uprawnienia
   ls -la [ścieżka-wolumenu]
   
   # Sprawdź szczegóły wolumenu
   docker volume inspect [nazwa-wolumenu]
   
   # Sprawdź montowanie
   docker inspect [nazwa-kontenera] | grep -A 10 Mounts
   ```

4. **Problemy z siecią:**
   ```bash
   # Sprawdź konfigurację sieci
   docker network inspect [nazwa-sieci]
   
   # Sprawdź połączenia kontenera
   docker inspect [nazwa-kontenera] | grep -A 10 NetworkSettings
   
   # Test połączenia
   docker exec [kontener1] ping [kontener2]
   ```

### Przydatne komendy do debugowania:

```bash
# Sprawdzenie szczegółów kontenera
docker inspect [nazwa-kontenera]

# Sprawdzenie logów w czasie rzeczywistym
docker logs -f [nazwa-kontenera]

# Wejście do działającego kontenera
docker exec -it [nazwa-kontenera] /bin/bash

# Sprawdzenie wykorzystania zasobów
docker stats [nazwa-kontenera]

# Sprawdzenie procesów w kontenerze
docker top [nazwa-kontenera]

# Sprawdzenie zmian w systemie plików
docker diff [nazwa-kontenera]

# Sprawdzenie wykorzystania miejsca
docker system df

# Sprawdzenie szczegółów sieci
docker network inspect [nazwa-sieci]

# Sprawdzenie szczegółów wolumenu
docker volume inspect [nazwa-wolumenu]
```

