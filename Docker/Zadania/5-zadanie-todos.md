
## 1. Uruchomienie aplikacji ToDos
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

## 2. Zbudowac i wypchac obrazy docker dla aplikacji ToDos(FE, BE) do zewnętrzego Registry