# Ćwiczenia Docker Compose

## Wprowadzenie
Ten zestaw ćwiczeń pomoże Ci zrozumieć praktyczne aspekty pracy z Docker Compose. Zadania są ułożone według rosnącego poziomu trudności. Każde ćwiczenie zawiera opis zadania, wskazówki oraz oczekiwany efekt.

## Ćwiczenie 1: Pierwsza kompozycja
### Cel
Stworzenie prostej kompozycji Docker z jednym kontenerem nginx.

### Zadanie
1. Utwórz plik `docker-compose.yml`
2. Skonfiguruj usługę nginx działającą na porcie 8080
3. Dodaj własną stronę HTML, która będzie serwowana przez nginx

### Wskazówki
- Użyj oficjalnego obrazu nginx
- Wykorzystaj volumes do podmontowania plików HTML
- Pamiętaj o przekierowaniu portów

### Oczekiwany efekt
- Strona jest dostępna pod adresem `http://localhost:8080`
- Wyświetla się własna treść HTML
- Kompozycja uruchamia się bez błędów

## Ćwiczenie 2: Multi-container setup
### Cel
Stworzenie aplikacji składającej się z frontendu (nginx) i backendu (python).

### Zadanie
1. Stwórz prosty backend w Pythonie (Flask) zwracający JSON
2. Skonfiguruj nginx jako proxy do backendu
3. Połącz oba kontenery w jednej kompozycji

### Wskazówki
- Backend powinien nasłuchiwać na porcie 5000
- Nginx powinien przekierowywać żądania do `/api` na backend
- Użyj networks do komunikacji między kontenerami

### Oczekiwany efekt
- Endpoint `/api/status` zwraca JSON ze statusem
- Frontend może komunikować się z backendem
- Oba kontenery są w tej samej sieci

## Ćwiczenie 3: Zarządzanie zależnościami
### Cel
Stworzenie aplikacji z bazą danych i mechanizmem wait-for-it.

### Zadanie
1. Dodaj bazę danych PostgreSQL do kompozycji
2. Skonfiguruj backend do łączenia z bazą
3. Zaimplementuj mechanizm oczekiwania na gotowość bazy

### Wskazówki
- Użyj depends_on w docker-compose
- Zaimplementuj skrypt healthcheck
- Dodaj zmienne środowiskowe dla konfiguracji bazy

### Oczekiwany efekt
- Aplikacja uruchamia się w prawidłowej kolejności
- Backend czeka na gotowość bazy
- Dane są prawidłowo zapisywane w bazie

## Ćwiczenie 4: Środowiska deweloperskie
### Cel
Konfiguracja środowiska developerskiego z hot-reload.

### Zadanie
1. Skonfiguruj środowisko dla frontendu (np. React) z hot-reload
2. Dodaj volumes dla kodu źródłowego
3. Zaimplementuj automatyczne przeładowanie backendu

### Wskazówki
- Użyj odpowiednich volumes dla node_modules
- Skonfiguruj nodemon dla backendu
- Pamiętaj o zmiennych środowiskowych dla trybów dev/prod

### Oczekiwany efekt
- Zmiany w kodzie są widoczne bez restartu kontenerów
- node_modules nie są synchronizowane z hostem
- Debugger działa poprawnie

## Ćwiczenie 5: Deployment stack
### Cel
Przygotowanie stacku deploymentowego z monitoringiem.

### Zadanie
1. Dodaj Prometheus do monitorowania
2. Skonfiguruj Grafana dla wizualizacji metryk
3. Zaimplementuj backup bazy danych

### Wskazówki
- Użyj named volumes dla danych Prometheus i Grafana
- Skonfiguruj retention policy dla backupów
- Dodaj basic auth dla dostępu do monitoringu

### Oczekiwany efekt
- Metryki są zbierane i wizualizowane
- Backup działa automatycznie
- Stack jest zabezpieczony podstawowym auth

## Zadanie dodatkowe: Load Balancing
### Cel
Implementacja load balancingu dla aplikacji.

### Zadanie
1. Skonfiguruj wiele instancji backendu
2. Dodaj nginx jako load balancer
3. Zaimplementuj sticky sessions

### Wskazówki
- Użyj scale w docker-compose
- Skonfiguruj upstream w nginx
- Rozważ użycie redis dla sesji

### Oczekiwany efekt
- Load balancing działa poprawnie
- Sesje są zachowane między requestami
- System zachowuje wysoką dostępność

## Wskazówki do rozwiązywania problemów

### Debugowanie kompozycji
1. Używaj `docker-compose logs` do sprawdzania logów
2. Sprawdzaj status kontenerów przez `docker-compose ps`
3. Testuj pojedyncze komponenty przed integracją

### Najczęstsze problemy
1. Problemy z uprawnieniami do volumes
   - Sprawdź uprawnienia w kontenerze
   - Zweryfikuj właściciela plików na hoście

2. Problemy z siecią
   - Sprawdź konfigurację networks
   - Zweryfikuj nazwy hostów między kontenerami

3. Problemy z zależnościami
   - Użyj wait-for-it lub podobnych skryptów
   - Dodaj proper healthchecks

## Przydatne komendy

```bash
# Sprawdzanie logów
docker-compose logs -f service_name

# Skalowanie usługi
docker-compose up -d --scale backend=3

# Czyszczenie środowiska
docker-compose down -v --remove-orphans

# Debugowanie pojedynczego kontenera
docker-compose exec service_name bash
```

## Rozwiązania

Rozwiązania do ćwiczeń znajdują się w katalogu `solutions/`. Staraj się najpierw rozwiązać zadania samodzielnie, a dopiero potem sprawdzać rozwiązania.

Pamiętaj, że może być wiele poprawnych sposobów rozwiązania każdego zadania. Rozwiązania w repozytorium są tylko jednym z możliwych podejść.