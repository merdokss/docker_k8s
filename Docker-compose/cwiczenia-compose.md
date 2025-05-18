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

## Ćwiczenie 2: Aplikacja wielokontenerowa
### Cel
Stworzenie kompozycji z wieloma kontenerami - aplikacja webowa z bazą danych.

### Zadanie
1. Utwórz plik `docker-compose.yml` z dwoma usługami: (np: Docker-compose/3-docker-compose-shoppinglist)
   - Aplikacja webowa (np. Node.js lub Python)
   - Baza danych PostgreSQL
2. Skonfiguruj połączenie między aplikacją a bazą danych
3. Dodaj zmienne środowiskowe dla konfiguracji

### Wskazówki
- Użyj oficjalnych obrazów dla aplikacji i bazy danych
- Skonfiguruj sieć między kontenerami
- Wykorzystaj zmienne środowiskowe dla haseł i konfiguracji

### Oczekiwany efekt
- Aplikacja działa poprawnie
- Baza danych jest dostępna dla aplikacji
- Dane są persystowane między uruchomieniami

## Ćwiczenie 3: Skalowanie i zarządzanie
### Cel
Poznanie zaawansowanych funkcji Docker Compose - skalowanie i zarządzanie kontenerami.

### Zadanie
1. Rozszerz poprzednią kompozycję o:
   - Skalowanie aplikacji webowej do 3 instancji
   - Dodanie load balancera (np. Nginx)
   - Konfigurację healthchecków

### Wskazówki
- Użyj `docker-compose up --scale` do skalowania
- Skonfiguruj load balancer do rozdzielania ruchu
- Dodaj healthchecki dla każdej usługi

### Oczekiwany efekt
- Aplikacja działa w trybie skalowanym
- Ruch jest równomiernie rozdzielany
- System jest odporny na awarie pojedynczych instancji

## Ćwiczenie 4: Uruchomienie aplikacji ToDos
### Cel
Uruchomienie aplikacji ToDos przy użyciu docker-compose (Docker-compose/5-ToDos)

### Zadanie
1. Utwórz kompozycję zawierającą:
   - Frontend (aplikacja React)
   - Backend (aplikacja Node.js)
   - Bazę danych MongoDB
   - MongoDB Express (interfejs administracyjny)
2. Skonfiguruj połączenia między komponentami
3. Przetestuj funkcjonalność CRUD dla zadań

### Wskazówki
- Wykorzystaj volumes do montowania danych dla MongoDB
- Skonfiguruj zmienne środowiskowe dla połączeń

### Oczekiwany efekt
- Frontend dostępny pod adresem `http://localhost:3000`
- Backend API dostępne pod adresem `http://localhost:3001`
- MongoDB Express dostępny pod adresem `http://localhost:8081`
- Automatyczne odświeżanie zmian w kodzie frontendu i backendu
- Możliwość zarządzania danymi przez MongoDB Express
- Poprawne zapisywanie i odczytywanie zadań z bazy danych

## Ćwiczenie 5: Zbudowac i wypchac obrazy docker dla aplikacji ToDos(FE, BE) do zewnętrzego Registry