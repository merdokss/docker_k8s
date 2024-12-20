# Docker Compose - Podstawy

## Spis treści
- [Wprowadzenie](#wprowadzenie)
- [Podstawowe operacje](#podstawowe-operacje)
- [Kluczowe flagi i ich zastosowanie](#kluczowe-flagi-i-ich-zastosowanie)
- [Przykłady praktyczne](#przykłady-praktyczne)
- [Najlepsze praktyki](#najlepsze-praktyki)

## Wprowadzenie

Docker Compose to narzędzie do definiowania i uruchamiania aplikacji składających się z wielu kontenerów Docker. Pozwala na zarządzanie całym stosem aplikacji poprzez jeden plik konfiguracyjny `docker-compose.yml`.

## Podstawowe operacje

### Uruchamianie usług
```bash
# Uruchomienie wszystkich usług
docker-compose up

# Uruchomienie w tle
docker-compose up -d

# Uruchomienie z wymuszonym przebudowaniem
docker-compose up --build
```

### Budowanie obrazów
```bash
# Zbudowanie wszystkich obrazów
docker-compose build

# Zbudowanie konkretnej usługi
docker-compose build nazwa-uslugi

# Zbudowanie bez użycia cache
docker-compose build --no-cache
```

## Kluczowe flagi i ich zastosowanie

### --build
Flaga `--build` wymusza przebudowanie obrazów przed uruchomieniem kontenerów. Jest to szczególnie istotne w następujących przypadkach:

- Gdy wprowadziliśmy zmiany w kodzie źródłowym
- Po modyfikacji plików Dockerfile
- Gdy chcemy mieć pewność, że używamy najnowszej wersji kodu

Bez użycia tej flagi, Docker użyje istniejących obrazów z cache, nawet jeśli pliki źródłowe uległy zmianie.

### Przykład różnicy między standardowym uruchomieniem a --build:

```yaml
# docker-compose.yml
version: '3'
services:
  webapp:
    build: ./webapp
    ports:
      - "3000:3000"
```

Przy standardowym uruchomieniu:
```bash
docker-compose up
# Używa istniejącego obrazu, ignorując ewentualne zmiany w Dockerfile
```

Z flagą --build:
```bash
docker-compose up --build
# Zawsze przebudowuje obraz przed uruchomieniem
```

## Przykłady praktyczne

### Podstawowa konfiguracja dla aplikacji webowej

```yaml
version: '3'
services:
  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
    
  backend:
    build: ./backend
    ports:
      - "8080:8080"
    environment:
      - DB_HOST=database
    
  database:
    image: postgres:13
    environment:
      - POSTGRES_PASSWORD=sekret
    volumes:
      - db-data:/var/lib/postgresql/data

volumes:
  db-data:
```

### Proces developmentu

Typowy przepływ pracy podczas developmentu:

1. Wprowadzenie zmian w kodzie
2. Przebudowanie konkretnej usługi:
   ```bash
   docker-compose build backend
   ```
3. Sprawdzenie logów z budowania
4. Uruchomienie zaktualizowanej usługi:
   ```bash
   docker-compose up backend
   ```

## Najlepsze praktyki

1. **Kontrola procesu budowania**
   - Używaj `docker-compose build` do testowania zmian w obrazach
   - Stosuj `--no-cache` gdy potrzebujesz czystego buildu
   - Buduj pojedyncze usługi zamiast całego stosu, gdy to możliwe

2. **Zarządzanie zmianami**
   - Zawsze używaj `--build` gdy zmieniasz Dockerfile
   - Dokumentuj zmiany w konfiguracji
   - Regularnie czyść nieużywane obrazy

3. **Debugowanie**
   - Wykorzystuj `docker-compose logs` do sprawdzania błędów
   - Monitoruj proces budowania obrazów
   - Sprawdzaj warstwy cache przy problemach z buildem

## Rozwiązywanie problemów

Najczęstsze problemy i ich rozwiązania:

1. **Obraz nie aktualizuje się pomimo zmian**
   - Użyj `docker-compose build --no-cache`
   - Sprawdź, czy zmiany są w odpowiednim kontekście budowania

2. **Problemy z cache**
   - Wyczyść wszystkie obrazy: `docker system prune`
   - Użyj `--force-recreate` przy uruchamianiu

3. **Konflikt portów**
   - Sprawdź, czy porty nie są już zajęte
   - Zmień mapowanie portów w docker-compose.yml

## Konfiguracja docker-compose.yml

Docker Compose wykorzystuje plik YAML do konfiguracji usług, sieci, wolumenów i innych zasobów. Poniżej znajduje się szczegółowy opis najważniejszych pól konfiguracyjnych.

### Podstawowa struktura

```yaml
version: '3'  # Wersja składni docker-compose
services:     # Definicje usług
networks:     # Definicje sieci (opcjonalne)
volumes:      # Definicje wolumenów (opcjonalne)
```

### Konfiguracja usług

Każda usługa może zawierać następujące pola:

#### build
Konfiguracja procesu budowania obrazu:
```yaml
services:
  webapp:
    build: 
      context: ./dir      # Ścieżka do kontekstu budowania
      dockerfile: Dockerfile.dev  # Nazwa pliku Dockerfile
      args:               # Argumenty przekazywane podczas budowania
        ENV: development
```

#### image
Określa obraz Docker do użycia:
```yaml
services:
  database:
    image: postgres:13.4  # Nazwa i tag obrazu
```

#### container_name
Ustawia niestandardową nazwę kontenera:
```yaml
services:
  webapp:
    container_name: my-webapp  # Domyślnie Docker generuje nazwę automatycznie
```

#### ports
Mapowanie portów między hostem a kontenerem:
```yaml
services:
  webapp:
    ports:
      - "3000:3000"  # port_hosta:port_kontenera
      - "9229:9229"  # Można mapować wiele portów
```

#### environment
Zmienne środowiskowe:
```yaml
services:
  webapp:
    environment:
      - NODE_ENV=development
      - API_KEY=secret
    # lub
    env_file:
      - .env  # Plik ze zmiennymi środowiskowymi
```

#### volumes
Montowanie wolumenów:
```yaml
services:
  webapp:
    volumes:
      - ./src:/app/src  # Montowanie katalogu z hosta
      - data:/app/data  # Montowanie nazwanego wolumenu
```

#### depends_on
Definiuje zależności między usługami:
```yaml
services:
  webapp:
    depends_on:
      - database  # webapp poczeka na uruchomienie database
```

#### networks
Przypisanie usługi do sieci:
```yaml
services:
  webapp:
    networks:
      - frontend
      - backend
```

#### restart
Polityka restartu kontenera:
```yaml
services:
  webapp:
    restart: always  # Zawsze restartuj
    # Możliwe wartości: no, always, on-failure, unless-stopped
```

#### command
Nadpisuje domyślne polecenie z Dockerfile:
```yaml
services:
  webapp:
    command: npm run dev  # Zastępuje CMD z Dockerfile
```

#### healthcheck
Konfiguracja sprawdzania stanu kontenera:
```yaml
services:
  webapp:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### Konfiguracja sieci

```yaml
networks:
  frontend:
    driver: bridge  # Domyślny driver
  backend:
    driver: overlay  # Dla trybu swarm
    internal: true   # Sieć bez dostępu do internetu
```

### Konfiguracja wolumenów

```yaml
volumes:
  data:
    driver: local  # Lokalny storage
  db-data:
    driver_opts:
      type: nfs
      o: addr=10.0.0.1
```

### Zmienne środowiskowe i podstawienie

Docker Compose pozwala na używanie zmiennych środowiskowych z pliku .env:

```yaml
services:
  webapp:
    image: nginx:${NGINX_VERSION}  # Użycie zmiennej z .env
    environment:
      - API_KEY=${API_KEY}
```

### Przykład pełnej konfiguracji

```yaml
version: '3'

services:
  webapp:
    build:
      context: ./frontend
      dockerfile: Dockerfile.dev
    container_name: my-webapp
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
    volumes:
      - ./src:/app/src
    depends_on:
      - api
    networks:
      - frontend
    restart: unless-stopped

  api:
    build: ./backend
    ports:
      - "8080:8080"
    environment:
      - DB_HOST=database
    depends_on:
      - database
    networks:
      - frontend
      - backend

  database:
    image: postgres:13
    environment:
      - POSTGRES_PASSWORD_FILE=/run/secrets/db_password
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - backend
    secrets:
      - db_password

networks:
  frontend:
  backend:
    internal: true

volumes:
  db-data:

secrets:
  db_password:
    file: ./password.txt
```

Ta konfiguracja pokazuje zaawansowane wykorzystanie Docker Compose z wieloma usługami, sieciami, wolumenami i sekretami.

### Restart 

Pole `restart` w pliku `docker-compose` określa, kiedy Docker powinien automatycznie restartować kontener. Oto szczegółowy opis każdej opcji wraz z przykładami:

- `no`: Kontener nie będzie restartowany automatycznie.
  Przykład: Kontener zakończy się z kodem wyjścia 0 lub innym, nie zostanie ponownie uruchomiony.
- `always`: Kontener będzie zawsze restartowany, niezależnie od kodu wyjścia.
  Przykład: Kontener zakończy się z kodem wyjścia 0 lub innym, Docker natychmiast go uruchomi ponownie.
- `on-failure`: Kontener będzie restartowany tylko wtedy, gdy zakończy się niepowodzeniem (z kodem wyjścia innym niż zero).
  Przykład: Kontener zakończy się z kodem wyjścia 1, Docker uruchomi go ponownie. Jeśli zakończy się z kodem 0, nie zostanie ponownie uruchomiony.
- `unless-stopped`: Kontener będzie restartowany zawsze, chyba że zostanie ręcznie zatrzymany.
  Przykład: Kontener zakończy się z kodem wyjścia 0 lub innym, Docker uruchomi go ponownie, chyba że został zatrzymany za pomocą docker stop.
