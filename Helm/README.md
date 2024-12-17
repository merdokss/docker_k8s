# Helm - Menedżer pakietów dla Kubernetes

## Czym jest Helm?

Helm to menedżer pakietów dla Kubernetes, który można porównać do apt/yum dla Linuxa lub npm dla Node.js. Wyobraźmy sobie, że mamy złożoną aplikację składającą się z wielu komponentów Kubernetes (deployments, services, configmaps, itp.). Zamiast zarządzać każdym z tych komponentów osobno, Helm pozwala nam traktować je jako jeden pakiet, który nazywamy "chartem".

## Podstawowe koncepcje

### Chart
Chart w Helm jest jak przepis na danie - zawiera wszystkie instrukcje i składniki potrzebne do utworzenia działającej aplikacji w Kubernetes. Składa się z:

```plaintext
mychart/
  ├── Chart.yaml           # Metadane chartu
  ├── values.yaml          # Domyślne wartości konfiguracyjne
  ├── templates/           # Szablony Kubernetes
  │   ├── deployment.yaml
  │   ├── service.yaml
  │   └── ingress.yaml
  └── charts/             # Zależne charty (opcjonalnie)
```

### Release
Release to konkretna instancja chartu uruchomiona w klastrze. Jeden chart może mieć wiele releases, podobnie jak jeden przepis może być użyty do przygotowania wielu porcji dania.

## Instalacja Helm

```bash
# Na Linux (przez apt)
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

# Na MacOS (przez Homebrew)
brew install helm

# Na Windows (przez Chocolatey)
choco install kubernetes-helm
```

## Podstawowe komendy

### Zarządzanie repozytoriami
```bash
# Dodawanie repozytorium
helm repo add bitnami https://charts.bitnami.com/bitnami

# Aktualizacja listy dostępnych chartów
helm repo update

# Lista repozytoriów
helm repo list
```

### Szukanie i przeglądanie chartów
```bash
# Szukanie chartu
helm search repo nginx

# Szczegóły chartu
helm show values bitnami/nginx
```

### Instalacja i zarządzanie
```bash
# Instalacja chartu
helm install my-release bitnami/nginx

# Aktualizacja release'u
helm upgrade my-release bitnami/nginx --values custom-values.yaml

# Lista zainstalowanych releases
helm list

# Usunięcie release'u
helm uninstall my-release
```

## Tworzenie własnego chartu

### Inicjalizacja nowego chartu
```bash
helm create mychart
```

### Przykładowa struktura values.yaml
```yaml
# values.yaml
replicaCount: 2
image:
  repository: nginx
  tag: "1.16.0"
  pullPolicy: IfNotPresent
service:
  type: ClusterIP
  port: 80
```

### Przykładowy szablon deployment.yaml
```yaml
# templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-deployment
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - containerPort: {{ .Values.service.port }}
```

## Zalety używania Helm

### 1. Zarządzanie złożonymi aplikacjami
Helm upraszcza zarządzanie aplikacjami składającymi się z wielu komponentów Kubernetes. Zamiast zarządzać każdym zasobem osobno, traktujemy je jako jedną całość.

### 2. Wersjonowanie i kontrola zmian
```bash
# Historia wdrożeń
helm history my-release

# Rollback do poprzedniej wersji
helm rollback my-release 1
```

### 3. Powtarzalność wdrożeń
Dzięki szablonom i wartościom konfiguracyjnym, możemy łatwo wdrażać tę samą aplikację w różnych środowiskach.

### 4. Współdzielenie konfiguracji
Chart może być współdzielony między zespołami i projektami, zapewniając spójne wdrożenia.

## Dobre praktyki

### Organizacja wartości
```yaml
# values.yaml
global:
  environment: production
  
application:
  name: myapp
  version: 1.0.0
  
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 200m
    memory: 256Mi
```

### Walidacja i testowanie
```bash
# Walidacja chartu
helm lint mychart

# Podgląd generowanych manifestów
helm template mychart

# Test instalacji
helm install --dry-run --debug mychart
```

### Dokumentacja
```yaml
# Chart.yaml
apiVersion: v2
name: mychart
description: A Helm chart for Kubernetes
version: 0.1.0
appVersion: "1.16.0"
maintainers:
  - name: John Doe
    email: john@example.com
```

## Zaawansowane funkcje

### Hooks
Hooks pozwalają na wykonywanie akcji w określonych momentach cyklu życia release'u:
```yaml
annotations:
  "helm.sh/hook": pre-install
  "helm.sh/hook-weight": "0"
```

### Zależności
Definiowanie zależności między chartami:
```yaml
# Chart.yaml
dependencies:
  - name: nginx
    version: 1.2.3
    repository: https://charts.bitnami.com/bitnami
```

## Rozwiązywanie problemów

### Debugowanie instalacji
```bash
# Szczegółowe logi
helm install --debug --dry-run my-release ./mychart

# Status release'u
helm status my-release
```

### Weryfikacja szablonów
```bash
# Sprawdzenie renderowanych manifestów
helm template --debug ./mychart

# Weryfikacja wartości
helm get values my-release
```

Helm znacznie upraszcza proces wdrażania i zarządzania aplikacjami w Kubernetes, jednocześnie wprowadzając standardy i dobre praktyki w zespole. Jest szczególnie przydatny w większych projektach, gdzie mamy wiele podobnych wdrożeń lub potrzebujemy powtarzalnego procesu deploymentu.