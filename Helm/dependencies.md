# Zależności w Helm

## Struktura katalogów
```
mychart/
├── Chart.yaml        # Definicja zależności
├── values.yaml       # Wartości domyślne
├── templates/        # Szablony
└── charts/          # Pobrane zależności
```

## Definiowanie zależności

### Podstawowa struktura (Chart.yaml)
```yaml
apiVersion: v2
name: moja-aplikacja
version: 1.0.0
dependencies:
  - name: mysql
    version: "8.0.0"
    repository: "https://charts.bitnami.com/bitnami"
    condition: mysql.enabled
```

### Typy zależności
- **Zewnętrzne** - pobierane z repozytoriów Helm
- **Lokalne** - znajdujące się w tym samym projekcie
- **Podwójne** (alias) - ta sama zależność używana w różnych miejscach

## Zarządzanie zależnościami

### Podstawowe komendy
```bash
# Pobieranie zależności
helm dependency update

# Pobieranie zależności dla konkretnego charta
helm dependency update ./mychart

# Sprawdzanie zależności
helm dependency list

# Sprawdzanie zależności dla konkretnego charta
helm dependency list ./mychart
```

### Warunkowe włączanie zależności
```yaml
# values.yaml
mysql:
  enabled: true
  database: myapp
  username: user
  password: secret

# Chart.yaml
dependencies:
  - name: mysql
    version: "8.0.0"
    condition: mysql.enabled
```

### Importowanie wartości
```yaml
# Chart.yaml
dependencies:
  - name: mysql
    import-values:
      - child: mysql
        parent: database
```

### Tagi (tags)
```yaml
# Chart.yaml
dependencies:
  - name: mysql
    tags:
      - database
      - backend

# values.yaml
tags:
  database: true
  backend: true
```

## Przykład kompleksowy

### Chart.yaml
```yaml
apiVersion: v2
name: myapp
version: 1.0.0
dependencies:
  - name: mysql
    version: "8.0.0"
    repository: "https://charts.bitnami.com/bitnami"
    condition: mysql.enabled
    tags:
      - database
    import-values:
      - child: mysql
        parent: database
  - name: redis
    version: "15.0.0"
    repository: "https://charts.bitnami.com/bitnami"
    condition: redis.enabled
    tags:
      - cache
```

### values.yaml
```yaml
mysql:
  enabled: true
  database: myapp
  username: user
  password: secret

redis:
  enabled: true
  password: redis-password

tags:
  database: true
  cache: true
```

## Proces instalacji

### Krok po kroku
```bash
# 1. Pobieranie zależności
helm dependency update

# 2. Sprawdzenie zależności
helm dependency list

# 3. Instalacja
helm install myapp . \
  --set mysql.database=nowa-baza \
  --set redis.password=nowe-haslo
```

## Ważne aspekty

1. **Struktura**:
   - Zależności są pobierane do katalogu `charts/`
   - Plik `Chart.lock` zawiera dokładne wersje zależności

2. **Kontrola instalacji**:
   - Warunki (`condition`) kontrolują czy zależność zostanie zainstalowana
   - Tagi (`tags`) pozwalają na grupowanie zależności
   - Wartości można importować między chartami

3. **Best practices**:
   - Zawsze określaj wersje zależności
   - Używaj warunków do kontrolowania instalacji
   - Grupuj powiązane zależności tagami
   - Dokumentuj wymagane zależności
   - Używaj repozytoriów zaufanych źródeł

## Rozwiązywanie problemów

### Podstawowe komendy
```bash
# Sprawdzenie statusu zależności
helm dependency list

# Wymuszenie aktualizacji zależności
helm dependency update --force

# Sprawdzenie konfliktu wersji
helm dependency build --verify
```

### Typowe problemy
1. **Konflikty wersji**:
   - Użyj `helm dependency build --verify`
   - Sprawdź kompatybilność wersji

2. **Brakujące zależności**:
   - Upewnij się, że repozytorium jest dodane
   - Sprawdź dostępność charta

3. **Problemy z wartościami**:
   - Sprawdź poprawność importowanych wartości
   - Zweryfikuj warunki w `values.yaml` 