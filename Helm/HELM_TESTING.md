# Testowanie w Helm

## 1. Testy jednostkowe (Unit Tests)

### Weryfikacja szablonów
```bash
# Sprawdza poprawność składni szablonów
helm lint ./mychart

# Wyświetla wygenerowane manifesty bez instalacji
helm template myrelease ./mychart

# Wyświetla manifesty z konkretnymi wartościami
helm template myrelease ./mychart --set image.tag=1.0.0
```

### Testowanie wartości domyślnych
```bash
# Sprawdza wartości domyślne
helm get values myrelease

# Porównuje wartości z plikiem
helm get values myrelease -o yaml > current-values.yaml
diff current-values.yaml expected-values.yaml
```

## 2. Testy integracyjne

### Testy podów
```yaml
# templates/tests/test-connection.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "mychart.fullname" . }}-test-connection"
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test
spec:
  containers:
    - name: wget
      image: busybox
      command: ['wget']
      args: ['{{ include "mychart.fullname" . }}:{{ .Values.service.port }}']
  restartPolicy: Never
```

### Testy HTTP
```yaml
# templates/tests/test-http.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "mychart.fullname" . }}-test-http"
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test
spec:
  containers:
    - name: curl
      image: curlimages/curl
      command: ['curl']
      args: ['-f', 'http://{{ include "mychart.fullname" . }}:{{ .Values.service.port }}/health']
  restartPolicy: Never
```

### Uruchamianie testów
```bash
# Uruchamia wszystkie testy
helm test myrelease

# Uruchamia testy z timeoutem
helm test myrelease --timeout 5m

# Usuwa pod testowe po zakończeniu
helm test myrelease --cleanup
```

## 3. Testy regresji

### Porównywanie wersji
```bash
# Generuje manifesty dla dwóch wersji
helm template myrelease ./mychart --version 1.0.0 > v1.yaml
helm template myrelease ./mychart --version 2.0.0 > v2.yaml

# Porównuje manifesty
diff v1.yaml v2.yaml
```

### Testowanie upgrade
```bash
# Instaluje starszą wersję
helm install myrelease ./mychart --version 1.0.0

# Testuje upgrade
helm upgrade myrelease ./mychart --version 2.0.0 --dry-run
```

## 4. Testy bezpieczeństwa

### Sprawdzanie uprawnień
```yaml
# templates/tests/test-rbac.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "mychart.fullname" . }}-test-rbac"
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test
spec:
  serviceAccountName: {{ include "mychart.serviceAccountName" . }}
  containers:
    - name: kubectl
      image: bitnami/kubectl
      command: ['kubectl']
      args: ['auth', 'can-i', 'get', 'pods']
  restartPolicy: Never
```

### Testowanie secretów
```yaml
# templates/tests/test-secrets.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "mychart.fullname" . }}-test-secrets"
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test
spec:
  containers:
    - name: test-secrets
      image: busybox
      command: ['sh', '-c']
      args: ['test -f /secrets/mysecret']
      volumeMounts:
        - name: secrets
          mountPath: /secrets
  volumes:
    - name: secrets
      secret:
        secretName: {{ include "mychart.fullname" . }}
  restartPolicy: Never
```

## 5. Automatyzacja testów

### Skrypt testowy
```bash
#!/bin/bash
# test-helm.sh

# Test lint
echo "Running helm lint..."
helm lint ./mychart

# Test template
echo "Generating templates..."
helm template myrelease ./mychart > generated.yaml

# Test installation
echo "Testing installation..."
helm install myrelease ./mychart --dry-run

# Run tests
echo "Running tests..."
helm test myrelease

# Cleanup
echo "Cleaning up..."
helm delete myrelease
```

### CI/CD Pipeline (GitHub Actions)
```yaml
# .github/workflows/helm-test.yml
name: Helm Tests

on:
  push:
    paths:
      - 'mychart/**'
  pull_request:
    paths:
      - 'mychart/**'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Set up Helm
        uses: azure/setup-helm@v1
        
      - name: Run Helm lint
        run: helm lint ./mychart
        
      - name: Run Helm template
        run: helm template myrelease ./mychart
        
      - name: Run Helm tests
        run: |
          helm install myrelease ./mychart
          helm test myrelease
          helm delete myrelease
```

## 6. Best Practices

1. **Testy jednostkowe**
   - Używaj `helm lint` do sprawdzania składni
   - Testuj szablony z różnymi wartościami
   - Weryfikuj generowane manifesty

2. **Testy integracyjne**
   - Twórz testy podów dla krytycznych funkcjonalności
   - Testuj połączenia między komponentami
   - Weryfikuj konfigurację i zmienne środowiskowe

3. **Testy regresji**
   - Porównuj manifesty między wersjami
   - Testuj proces upgrade
   - Weryfikuj kompatybilność wsteczną

4. **Testy bezpieczeństwa**
   - Sprawdzaj uprawnienia RBAC
   - Weryfikuj konfigurację secretów
   - Testuj izolację komponentów

5. **Automatyzacja**
   - Integruj testy z CI/CD
   - Automatyzuj czyszczenie zasobów
   - Dokumentuj proces testowania 