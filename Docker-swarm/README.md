# Przewodnik po Docker Swarm

## Wprowadzenie

Docker Swarm to wbudowany w Docker system orkiestracji kontenerów, który pozwala na zarządzanie klastrami kontenerów Docker. Wyobraźmy sobie, że mamy aplikację, którą chcemy uruchomić na wielu serwerach jednocześnie, zapewniając jej wysoką dostępność i skalowalność - właśnie do tego służy Docker Swarm.

## Podstawowe koncepcje

### Nodes (Węzły)

W Docker Swarm mamy dwa typy węzłów:

1. Manager Nodes - węzły zarządzające, które:
   - Kontrolują stan klastra
   - Planują rozmieszczenie kontenerów
   - Utrzymują stan konfiguracji
   - Minimum 3 węzły dla zapewnienia wysokiej dostępności

2. Worker Nodes - węzły robocze, które:
   - Wykonują rzeczywistą pracę
   - Uruchamiają kontenery
   - Nie podejmują decyzji zarządczych

### Services (Usługi)

Usługa w Docker Swarm to abstrakcja wysokiego poziomu reprezentująca logiczną aplikację. Podczas definiowania usługi określamy:
- Obraz kontenera
- Liczbę replik
- Politykę aktualizacji
- Ograniczenia zasobów
- Sieci i wolumeny

### Tasks (Zadania)

Zadanie to najmniejsza jednostka pracy w Swarm. Każda replika usługi to osobne zadanie, które:
- Jest przypisane do konkretnego węzła
- Uruchamia jeden kontener
- Jest zarządzane automatycznie przez Swarm

## Konfiguracja klastra Swarm

### Inicjalizacja klastra

```bash
# Na pierwszym węźle (manager)
docker swarm init --advertise-addr <IP_MANAGERA>

# Komenda zwróci token do dołączenia nowych węzłów
# Przykład odpowiedzi:
# docker swarm join --token SWMTKN-1-123abc... 192.168.1.10:2377
```

### Dołączanie węzłów

```bash
# Na węzłach worker
docker swarm join --token <TOKEN> <IP_MANAGERA>:2377

# Sprawdzenie statusu węzłów (na managerze)
docker node ls
```

## Zarządzanie usługami

### Tworzenie usługi

```bash
# Podstawowe utworzenie usługi
docker service create --name webapp \
  --replicas 3 \
  --publish 80:80 \
  nginx:latest

# Usługa z dodatkowymi parametrami
docker service create --name backend \
  --replicas 5 \
  --network backend-network \
  --mount type=volume,source=data,target=/app/data \
  --update-delay 10s \
  --limit-cpu 0.5 \
  --limit-memory 512M \
  myapp:latest
```

### Skalowanie usług

```bash
# Zmiana liczby replik
docker service scale webapp=5

# Skalowanie wielu usług jednocześnie
docker service scale webapp=5 backend=3
```

### Aktualizacja usług

```bash
# Aktualizacja obrazu
docker service update --image nginx:new webapp

# Aktualizacja z dodatkowymi parametrami
docker service update \
  --image myapp:v2 \
  --update-parallelism 2 \
  --update-delay 10s \
  backend
```

## Zaawansowane koncepcje

### Ograniczenia rozmieszczenia (Placement Constraints)

```bash
# Uruchomienie usługi na konkretnych węzłach
docker service create --name webapp \
  --constraint 'node.role==worker' \
  --constraint 'node.labels.environment==production' \
  nginx
```

### Sieci overlay

```bash
# Tworzenie sieci overlay
docker network create --driver overlay backend-network

# Tworzenie usługi w sieci overlay
docker service create --name api \
  --network backend-network \
  myapi:latest
```

### Secrets (Sekrety)

```bash
# Tworzenie sekretu
echo "mojTajnyKlucz" | docker secret create api_key -

# Używanie sekretu w usłudze
docker service create --name api \
  --secret api_key \
  myapi:latest
```

## Przykładowy stack aplikacji

### Definicja stack'a (stack.yml)

```yaml
version: '3.8'

services:
  webapp:
    image: nginx:latest
    deploy:
      replicas: 3
      update_config:
        parallelism: 2
        delay: 10s
      restart_policy:
        condition: on-failure
    ports:
      - "80:80"
    networks:
      - frontend

  api:
    image: myapi:latest
    deploy:
      replicas: 5
      placement:
        constraints:
          - node.role == worker
    networks:
      - frontend
      - backend
    secrets:
      - api_key
    environment:
      - DB_HOST=db

  db:
    image: postgres:13
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.labels.role == database
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - backend

networks:
  frontend:
    driver: overlay
  backend:
    driver: overlay
    internal: true

volumes:
  db-data:

secrets:
  api_key:
    external: true
```

### Wdrażanie stack'a

```bash
# Wdrożenie stack'a
docker stack deploy -c stack.yml myapp

# Sprawdzenie statusu
docker stack services myapp
docker stack ps myapp
```

## Monitoring i zarządzanie

### Monitorowanie stanu klastra

```bash
# Stan węzłów
docker node ls

# Stan usług
docker service ls
docker service ps <service_name>

# Logi usługi
docker service logs <service_name>
```

### Zarządzanie węzłami

```bash
# Oznaczenie węzła jako niedostępnego do planowania
docker node update --availability drain <node_name>

# Dodanie etykiety do węzła
docker node update --label-add environment=production <node_name>

# Awansowanie węzła do roli managera
docker node promote <node_name>
```

## Najlepsze praktyki

### Wysoka dostępność

1. Manager Nodes:
   - Używaj nieparzystej liczby managerów (3, 5, 7)
   - Rozmieść managerów w różnych lokalizacjach
   - Ogranicz liczbę managerów do 7

2. Worker Nodes:
   - Równomiernie rozmieszczaj obciążenie
   - Używaj ograniczeń rozmieszczenia
   - Monitoruj zużycie zasobów

### Bezpieczeństwo

1. Sieć:
   - Używaj sieci overlay z szyfrowaniem
   - Separuj ruch frontendowy od backendowego
   - Ogranicz dostęp do portów

2. Sekrety:
   - Używaj Docker secrets zamiast zmiennych środowiskowych
   - Regularnie rotuj sekrety
   - Ogranicz dostęp do sekretów

### Wydajność

1. Obrazy:
   - Używaj lekkich obrazów bazowych
   - Optymalizuj warstwy obrazów
   - Implementuj cache-aware building

2. Aktualizacje:
   - Używaj rolling updates
   - Implementuj health checks
   - Testuj strategie aktualizacji

## Rozwiązywanie problemów

### Typowe problemy

1. Problemy z połączeniem:
   - Sprawdź porty (2377, 7946, 4789)
   - Zweryfikuj konfigurację firewalla
   - Sprawdź dostępność sieci overlay

2. Problemy z rozmieszczeniem:
   - Sprawdź ograniczenia zasobów
   - Zweryfikuj placement constraints
   - Sprawdź stan węzłów

### Komendy diagnostyczne

```bash
# Sprawdzanie stanu klastra
docker node inspect <node_name>
docker service inspect <service_name>

# Debugowanie sieci
docker network inspect <network_name>

# Analiza logów
docker service logs --tail 100 <service_name>
```