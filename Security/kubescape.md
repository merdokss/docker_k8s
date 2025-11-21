# Kubescape - Narzędzie do skanowania bezpieczeństwa Kubernetes

Kubescape to narzędzie do skanowania bezpieczeństwa dla Kubernetes, które pomaga w wykrywaniu potencjalnych problemów bezpieczeństwa w konfiguracji klastra.

## Instalacja

### Linux/macOS
```bash
curl -s https://raw.githubusercontent.com/kubescape/kubescape/master/install.sh | /bin/bash
```

### macOS (używając Homebrew)
```bash
brew install kubescape
```

### Windows (używając PowerShell)
```powershell
# Instalacja przez winget
winget install kubescape

# Lub przez Chocolatey
choco install kubescape
```

### Windows (instalacja ręczna)
1. Pobierz najnowszą wersję z [GitHub Releases](https://github.com/kubescape/kubescape/releases)
2. Rozpakuj archiwum
3. Dodaj ścieżkę do folderu z plikiem wykonywalnym do zmiennej środowiskowej PATH

## Podstawowe komendy

### Skanowanie całego klastra
```bash
kubescape scan
```

### Skanowanie konkretnego frameworka (np. NSA)
```bash
kubescape scan framework nsa
```

### Skanowanie konkretnego pliku YAML
```bash
kubescape scan yaml deployment.yaml
```

### Skanowanie z zapisem wyników do pliku
```bash
kubescape scan --format json --output results.json
```

## Najważniejsze flagi

- `--format` - format wyjściowy (json, junit, pdf, html)
- `--output` - ścieżka do pliku wyjściowego
- `--exclude-namespaces` - wykluczenie konkretnych namespace'ów
- `--include-namespaces` - skanowanie tylko wybranych namespace'ów
- `--verbose` - szczegółowe logi

## Przykłady użycia

### Skanowanie całego klastra z zapisem wyników do pliku HTML
```bash
kubescape scan --format html --output security-report.html
```

### Skanowanie tylko namespace'a "production"
```bash
kubescape scan --include-namespaces production
```

### Skanowanie z wykluczeniem namespace'ów systemowych
```bash
kubescape scan --exclude-namespaces kube-system,kube-public
```

## Integracja z CI/CD

Możesz dodać Kubescape do swojego pipeline'u CI/CD, aby automatycznie skanować konfigurację przed wdrożeniem:

```yaml
steps:
  - name: Security Scan
    run: |
      kubescape scan --format junit --output results.xml
```

## Ważne wskazówki

1. Zawsze aktualizuj Kubescape do najnowszej wersji, aby mieć dostęp do najnowszych reguł bezpieczeństwa
2. Regularnie skanuj swój klaster, najlepiej w ramach procesu CI/CD
3. Przeanalizuj wyniki i wprowadź niezbędne poprawki w konfiguracji
4. Rozważ skonfigurowanie alertów dla krytycznych problemów bezpieczeństwa

## Dodatkowe zasoby

- [Oficjalna dokumentacja Kubescape](https://github.com/kubescape/kubescape)
- [Framework NSA dla Kubernetes](https://github.com/nsacyber/k8s-security-controls)
- [Najlepsze praktyki bezpieczeństwa Kubernetes](https://kubernetes.io/docs/concepts/security/)

## Dostępne frameworki

Kubescape oferuje kilka wbudowanych frameworków do skanowania bezpieczeństwa. Każdy framework skupia się na różnych aspektach bezpieczeństwa:

### NSA (National Security Agency)
```bash
kubescape scan framework nsa
```
Framework NSA zawiera wytyczne bezpieczeństwa opracowane przez amerykańską Narodową Agencję Bezpieczeństwa. Skupia się na:
- Kontroli dostępu
- Zarządzaniu siecią
- Izolacji kontenerów
- Zarządzaniu sekretami
- Podstawowych praktykach bezpieczeństwa

### MITRE ATT&CK
```bash
kubescape scan framework mitre
```
Framework MITRE ATT&CK koncentruje się na technikach ataku i taktykach używanych przez cyberprzestępców:
- Techniki persystencji
- Techniki eskalacji uprawnień
- Techniki lateralnego ruchu
- Techniki exfiltracji danych

### Podstawowy (Default)
```bash
kubescape scan framework default
```
Podstawowy framework zawiera najważniejsze kontrole bezpieczeństwa:
- Sprawdzanie uprawnień
- Konfiguracja sieci
- Zarządzanie sekretami
- Podstawowe zabezpieczenia kontenerów

### Wszystkie frameworki
```bash
kubescape scan framework all
```
Skanowanie wszystkimi dostępnymi frameworkami jednocześnie.

### Lista dostępnych frameworków
```bash
kubescape list frameworks
```
Polecenie wyświetla wszystkie dostępne frameworki i ich opisy.

### CIS (Center for Internet Security)
```bash
kubescape scan framework cis-aks-t1.2.0
```
Framework CIS zawiera wytyczne bezpieczeństwa opracowane przez Center for Internet Security. Wersja `cis-aks-t1.2.0` jest specyficzna dla Azure Kubernetes Service (AKS) i zawiera:

- Kontrole poziomu 1 (Tier 1) - podstawowe zabezpieczenia
- Kontrole poziomu 2 (Tier 2) - zaawansowane zabezpieczenia
- Specyficzne kontrole dla AKS

Główne obszary kontroli CIS:
- Konfiguracja kontrolera
- Zarządzanie tożsamością i dostępem
- Zarządzanie siecią
- Zarządzanie sekretami
- Konfiguracja podów
- Zarządzanie politykami
- Monitorowanie i logowanie

Możliwe wersje frameworka CIS:
- `cis-aks-t1.2.0` - dla Azure Kubernetes Service
- `cis-eks-t1.2.0` - dla Amazon EKS
- `cis-gke-t1.2.0` - dla Google GKE
- `cis-t1.2.0` - ogólny framework dla Kubernetes 

## Interpretacja raportów

Raport z Kubescape zawiera tabelę z wynikami skanowania. Oto jak interpretować poszczególne kolumny:

### Struktura raportu

```
┌──────────┬───────────────────────────────────────────────────────┬──────────────────┬───────────────┬──────────────────────┐
│ Severity │ Control name                                          │ Failed resources │ All Resources │ Compliance score     │
├──────────┼───────────────────────────────────────────────────────┼──────────────────┼───────────────┼──────────────────────┤
│   High   │ CIS-5.5.1 Manage Kubernetes RBAC users...             │        0         │       0       │ Action Required **** │
└──────────┴───────────────────────────────────────────────────────┴──────────────────┴───────────────┴──────────────────────┘
```

### Kolumny raportu

1. **Severity (Poziom zagrożenia)**
   - `High` - Krytyczne problemy bezpieczeństwa
   - `Medium` - Średnie ryzyko
   - `Low` - Niskie ryzyko

2. **Control name (Nazwa kontroli)**
   - Identyfikator kontroli (np. CIS-5.5.1)
   - Opis sprawdzanej kontroli bezpieczeństwa

3. **Failed resources (Nieudane zasoby)**
   - Liczba zasobów, które nie spełniają danej kontroli
   - Im niższa liczba, tym lepiej

4. **All Resources (Wszystkie zasoby)**
   - Całkowita liczba sprawdzonych zasobów
   - Pozwala określić skalę problemu

5. **Compliance score (Wynik zgodności)**
   - Procentowy wynik zgodności (np. 98%)
   - `Action Required` - wymaga interwencji
   - Liczba gwiazdek (*) wskazuje na pilność działania

### Przykład interpretacji

```
│   High   │ CIS-4.7.2 Apply Security Context... │        46        │      59       │         22%          │
```

Ten wpis oznacza:
- Krytyczny problem bezpieczeństwa (High)
- Dotyczy kontekstu bezpieczeństwa podów (CIS-4.7.2)
- 46 z 59 podów nie spełnia wymagań
- Tylko 22% podów jest poprawnie skonfigurowanych

### Podsumowanie raportu

Na końcu raportu znajduje się podsumowanie:
```
│          │ Resource Summary                    │       151        │      599      │        39.85%        │
```

Oznacza to:
- 151 zasobów nie spełnia wymagań
- Sprawdzono łącznie 599 zasobów
- Ogólny wynik zgodności to 39.85%

### Zalecane działania

1. Zacznij od problemów oznaczonych jako `High`
2. Zwróć szczególną uwagę na kontrole z `Action Required`
3. Priorytetyzuj problemy z najniższym wynikiem zgodności
4. Użyj flagi `--verbose` aby zobaczyć szczegóły dla każdego zasobu:
```bash
kubescape scan framework cis-aks-t1.2.0 --verbose
``` 