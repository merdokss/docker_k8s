# Trivy - Narzędzie do skanowania bezpieczeństwa

Trivy to wszechstronne narzędzie do skanowania bezpieczeństwa, które może być używane do:
- Skanowania obrazów Docker
- Analizy plików konfiguracyjnych Kubernetes
- Skanowania kodu źródłowego
- Wykrywania podatności w zależnościach

## Instalacja

### Windows
```powershell
# Używając winget (Windows Package Manager)
winget install AquaSecurity.Trivy

# Używając Chocolatey
choco install trivy

# Lub używając Scoop
scoop install trivy

# Lub ręcznie pobierając najnowszą wersję z GitHub
# 1. Pobierz najnowszą wersję z https://github.com/aquasecurity/trivy/releases
# 2. Rozpakuj archiwum
# 3. Dodaj ścieżkę do zmiennej środowiskowej PATH
```

### macOS
```bash
brew install aquasecurity/trivy/trivy
```

### Linux
```bash
sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy
```

## Podstawowe użycie

### Skanowanie obrazu Docker
```bash
trivy image nazwa_obrazu:tag
```

### Skanowanie plików konfiguracyjnych Kubernetes
```bash
trivy config ./Kubernetes
```

### Skanowanie katalogu z kodem
```bash
trivy fs .
```

### Skanowanie z określonym poziomem szczegółowości
```bash
trivy image --severity HIGH,CRITICAL nazwa_obrazu:tag
```

### Generowanie raportu w formacie JSON
```bash
trivy image -f json -o results.json nazwa_obrazu:tag
```

## Integracja z CI/CD

### GitHub Actions
```yaml
name: Security Scan
on: [push, pull_request]
jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'nazwa_obrazu:tag'
          format: 'table'
          exit-code: '1'
          ignore-unfixed: true
          vuln-type: 'os,library'
          severity: 'CRITICAL,HIGH'
```

## Przydatne flagi

- `--severity`: Określa poziom zagrożenia (CRITICAL, HIGH, MEDIUM, LOW, UNKNOWN)
- `-f, --format`: Format wyjściowy (table, json, template)
- `--exit-code`: Kod wyjścia w przypadku znalezienia podatności
- `--ignore-unfixed`: Ignoruj podatności bez dostępnych poprawek
- `--vuln-type`: Typ podatności do skanowania (os, library, config)

## Dodatkowe zasoby

- [Oficjalna dokumentacja Trivy](https://aquasecurity.github.io/trivy/latest/)
- [GitHub Repository](https://github.com/aquasecurity/trivy)
- [Przykłady użycia](https://aquasecurity.github.io/trivy/latest/examples/)