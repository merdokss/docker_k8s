# Helm - Ćwiczenia dla Początkujących

## Wprowadzenie

Te ćwiczenia zostały przygotowane dla osób, które dopiero zaczynają przygodę z Helm. Każde ćwiczenie zawiera szczegółowe instrukcje krok po kroku, wyjaśnienia i przykłady.

## Wymagania wstępne

- Zainstalowany Helm (wersja 3.x)
- Dostęp do klastra Kubernetes
- Podstawowa znajomość Kubernetes (Pods, Deployments, Services)
- Terminal z dostępem do `kubectl` i `helm`

## Ważne uwagi przed rozpoczęciem

### Różne środowiska shell
Ćwiczenia używają komend bash/zsh. Jeśli używasz PowerShell (Windows), niektóre komendy mogą wymagać modyfikacji:
- Heredoc (`<<EOF`) może nie działać - użyj edytora do tworzenia plików
- Zmienne środowiskowe: w PowerShell użyj `$env:NAZWA_ZMIENNEJ` zamiast `$NAZWA_ZMIENNEJ`

### Tworzenie plików
W ćwiczeniach używamy heredoc do tworzenia plików. Jeśli to nie działa:
1. Użyj edytora tekstowego (nano, vim, VS Code)
2. Skopiuj zawartość z ćwiczeń
3. Zapisz plik z odpowiednią nazwą

### Czas oczekiwania
Niektóre operacje (instalacja baz danych) mogą zająć kilka minut. Bądź cierpliwy i sprawdzaj status używając `kubectl get pods -w`.

## Ćwiczenie 1: Pierwsze kroki z Helm - Instalacja prostego chartu

### Cel
Nauczysz się jak wyszukiwać, instalować i zarządzać prostymi chartami Helm.

### Krok 1: Dodaj repozytorium Bitnami
```bash
# Bitnami to popularne repozytorium z gotowymi chartami
helm repo add bitnami https://charts.bitnami.com/bitnami
```

### Krok 2: Zaktualizuj listę dostępnych chartów
```bash
helm repo update
```

### Krok 3: Wyszukaj chart PostgreSQL
```bash
helm search repo postgresql
```

### Krok 4: Sprawdź dostępne wartości konfiguracyjne
```bash
# Wyświetl wszystkie dostępne opcje konfiguracji
helm show values bitnami/postgresql
```

### Krok 5: Zainstaluj PostgreSQL z własną konfiguracją
```bash
# Utwórz plik z wartościami
cat > postgres-values.yaml <<'EOF'
auth:
  postgresPassword: "moje-super-haslo"
  database: "moja-baza"
primary:
  persistence:
    enabled: true
    size: 8Gi
EOF

# Zainstaluj PostgreSQL
helm install moja-postgres bitnami/postgresql -f postgres-values.yaml
```

**Alternatywnie** (jeśli heredoc nie działa):
```bash
# Utwórz plik ręcznie
nano postgres-values.yaml
# lub użyj edytora i wklej zawartość:
```

Zawartość pliku `postgres-values.yaml`:
```yaml
auth:
  postgresPassword: "moje-super-haslo"
  database: "moja-baza"
primary:
  persistence:
    enabled: true
    size: 8Gi
```

Następnie zainstaluj:
```bash
helm install moja-postgres bitnami/postgresql -f postgres-values.yaml
```

### Krok 6: Sprawdź status instalacji
```bash
# Lista zainstalowanych releases
helm list

# Szczegółowy status
helm status moja-postgres

# Sprawdź pody (może zająć kilka minut aż będą gotowe)
kubectl get pods -l app.kubernetes.io/name=postgresql

# Poczekaj aż pod będzie gotowy
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgresql --timeout=300s

# Sprawdź logi jeśli są problemy
kubectl logs -l app.kubernetes.io/name=postgresql --tail=50
```

### Krok 7: Połącz się z bazą danych
```bash
# Pobierz hasło z secretu
# Uwaga: nazwa secretu to {release-name}-postgresql
export POSTGRES_PASSWORD=$(kubectl get secret --namespace default moja-postgres-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)

# Wyświetl hasło (do weryfikacji)
echo "Hasło: $POSTGRES_PASSWORD"

# Uruchom klienta PostgreSQL
kubectl run postgresql-client --rm --tty -i --restart='Never' --namespace default --image docker.io/bitnami/postgresql:15 --env="PGPASSWORD=$POSTGRES_PASSWORD" --command -- psql --host moja-postgres-postgresql -U postgres -d moja-baza -p 5432
```

**Alternatywnie** (jeśli powyższa komenda nie działa):
```bash
# Użyj bezpośrednio hasła z pliku values
kubectl run postgresql-client --rm --tty -i --restart='Never' --namespace default --image docker.io/bitnami/postgresql:15 --env="PGPASSWORD=moje-super-haslo" --command -- psql --host moja-postgres-postgresql -U postgres -d moja-baza -p 5432
```

W konsoli PostgreSQL wykonaj:
```sql
CREATE TABLE test (id INT, name VARCHAR(50));
INSERT INTO test VALUES (1, 'Hello Helm!');
SELECT * FROM test;
\q
```

### Krok 8: Odinstaluj release
```bash
helm uninstall moja-postgres
```

### Co się nauczyłeś?
- Jak dodawać repozytoria Helm
- Jak wyszukiwać charty
- Jak sprawdzać dostępne opcje konfiguracji
- Jak instalować charty z własnymi wartościami
- Jak sprawdzać status i zarządzać releases

---

## Ćwiczenie 2: Instalacja WordPress z MySQL

### Cel
Nauczysz się instalować złożoną aplikację składającą się z wielu komponentów.

### Krok 1: Zainstaluj WordPress
```bash
# WordPress wymaga bazy danych, więc użyjemy wbudowanej opcji
helm install moj-wordpress bitnami/wordpress \
  --set wordpressUsername=admin \
  --set wordpressPassword=admin123 \
  --set mariadb.auth.rootPassword=rootpassword \
  --set mariadb.auth.database=wordpress
```

### Krok 2: Sprawdź status
```bash
# Poczekaj aż wszystkie pody będą gotowe
kubectl get pods -w

# Sprawdź serwisy
kubectl get svc
```

### Krok 3: Uzyskaj dostęp do WordPress
```bash
# Sprawdź typ serwisu
kubectl get svc --namespace default moj-wordpress

# Jeśli masz LoadBalancer, pobierz adres URL
export SERVICE_IP=$(kubectl get svc --namespace default moj-wordpress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Adres WordPress: http://$SERVICE_IP"

# Jeśli nie masz LoadBalancer (lub SERVICE_IP jest pusty), użyj port-forward
# Uruchom w osobnym terminalu lub w tle:
kubectl port-forward --namespace default svc/moj-wordpress 8080:80

# Teraz otwórz przeglądarkę: http://localhost:8080
# Uwaga: port-forward będzie działał dopóki nie przerwiesz go (Ctrl+C)
```

### Krok 4: Sprawdź wartości użyte podczas instalacji
```bash
helm get values moj-wordpress
```

### Krok 5: Zaktualizuj konfigurację
```bash
# Zmień liczbę replik
helm upgrade moj-wordpress bitnami/wordpress \
  --set replicaCount=2 \
  --reuse-values
```

### Krok 6: Sprawdź historię zmian
```bash
helm history moj-wordpress
```

### Krok 7: Cofnij zmiany (rollback)
```bash
# Jeśli coś poszło nie tak, możesz wrócić do poprzedniej wersji
helm rollback moj-wordpress
```

### Co się nauczyłeś?
- Jak instalować złożone aplikacje
- Jak używać parametrów `--set` i `--reuse-values`
- Jak aktualizować releases
- Jak korzystać z historii i rollback

---

## Ćwiczenie 3: Instalacja MongoDB dla aplikacji ToDos

### Cel
Zainstalujesz MongoDB, który będzie używany przez aplikację ToDos.

### Krok 1: Wyszukaj chart MongoDB
```bash
helm search repo mongodb
```

### Krok 2: Sprawdź dostępne opcje
```bash
helm show values bitnami/mongodb
```

### Krok 3: Utwórz plik konfiguracyjny
```bash
# Utwórz plik mongodb-todos-values.yaml
cat > mongodb-todos-values.yaml <<'EOF'
auth:
  enabled: true
  rootUser: root
  rootPassword: password
  # Uwaga: usernames, passwords i databases to listy
  usernames:
    - todosuser
  passwords:
    - todospass
  databases:
    - todos
persistence:
  enabled: true
  size: 10Gi
service:
  type: ClusterIP
  ports:
    mongodb: 27017
EOF
```

**Alternatywnie** (jeśli heredoc nie działa w Twoim shellu):
```bash
# Utwórz plik ręcznie lub użyj edytora
nano mongodb-todos-values.yaml
# lub
vim mongodb-todos-values.yaml
```

Zawartość pliku `mongodb-todos-values.yaml`:
```yaml
auth:
  enabled: true
  rootUser: root
  rootPassword: password
  usernames:
    - todosuser
  passwords:
    - todospass
  databases:
    - todos
persistence:
  enabled: true
  size: 10Gi
service:
  type: ClusterIP
  ports:
    mongodb: 27017
```

### Krok 4: Zainstaluj MongoDB
```bash
helm install mongo-todos bitnami/mongodb -f mongodb-todos-values.yaml
```

### Krok 5: Sprawdź czy działa
```bash
# Poczekaj aż pod będzie gotowy (może zająć kilka minut)
kubectl get pods -l app.kubernetes.io/name=mongodb -w
# Naciśnij Ctrl+C gdy pod będzie w stanie Running

# Sprawdź serwis
kubectl get svc mongo-todos-mongodb

# Sprawdź czy pod jest gotowy
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=mongodb --timeout=300s

# Przetestuj połączenie
# Uwaga: nowsze wersje MongoDB używają 'mongosh' zamiast 'mongo'
kubectl run --rm -it --restart=Never mongodb-client --image=bitnami/mongodb:latest -- mongosh --host mongo-todos-mongodb -u root -p password --authenticationDatabase admin

# Jeśli powyższa komenda nie działa, spróbuj z 'mongo' (starsze wersje):
# kubectl run --rm -it --restart=Never mongodb-client --image=bitnami/mongodb:latest -- mongo --host mongo-todos-mongodb -u root -p password --authenticationDatabase admin
```

### Krok 6: W konsoli MongoDB wykonaj:
```javascript
use todos
db.tasks.insertOne({title: "Test task", completed: false})
db.tasks.find()
exit
```

### Co się nauczyłeś?
- Jak konfigurować MongoDB przez Helm
- Jak ustawiać autentykację
- Jak konfigurować persistent storage
- Jak testować połączenie z bazą danych

---

## Ćwiczenie 4: Tworzenie własnego Helm Chart dla aplikacji ToDos

### Cel
Stworzysz własny Helm chart dla aplikacji ToDos, ucząc się podstaw tworzenia chartów.

### Krok 1: Utwórz nowy chart
```bash
# Przejdź do katalogu Helm (dostosuj ścieżkę do swojego środowiska)
cd <ścieżka-do-katalogu-Helm>
# Przykład: cd ~/Documents/Projects/Sages/Szkolenia/Kuberenetes-17-21.11.2025/docker_k8s/Helm

# Utwórz nowy chart
helm create todos-chart
```

### Krok 2: Przeanalizuj strukturę
```bash
tree todos-chart
# lub
ls -la todos-chart/
ls -la todos-chart/templates/
```

### Krok 3: Edytuj Chart.yaml
```bash
# Edytuj plik Chart.yaml
cat > todos-chart/Chart.yaml <<'EOF'
apiVersion: v2
name: todos-chart
description: Helm chart dla aplikacji ToDos
type: application
version: 0.1.0
appVersion: "1.0.0"
EOF
```

**Alternatywnie** użyj edytora:
```bash
nano todos-chart/Chart.yaml
# lub
vim todos-chart/Chart.yaml
```

Zawartość pliku `todos-chart/Chart.yaml`:
```yaml
apiVersion: v2
name: todos-chart
description: Helm chart dla aplikacji ToDos
type: application
version: 0.1.0
appVersion: "1.0.0"
```

### Krok 4: Skonfiguruj values.yaml dla backend API
```bash
# Utwórz plik values.yaml
cat > todos-chart/values.yaml <<'EOF'
# Konfiguracja głównej aplikacji
replicaCount: 1

# Backend API
backend:
  enabled: true
  image:
    repository: dawidsages.azurecr.io/cezary-api
    tag: "latest"
    pullPolicy: Always
  service:
    type: ClusterIP
    port: 3001
  resources:
    requests:
      memory: "128Mi"
      cpu: "1m"
    limits:
      memory: "256Mi"
      cpu: "200m"
  env:
    - name: MONGODB_URI
      value: "mongodb://root:password@mongo-todos-mongodb:27017/todos?authSource=admin"
  livenessProbe:
    httpGet:
      path: /api
      port: 3001
    initialDelaySeconds: 20
    periodSeconds: 5
  readinessProbe:
    httpGet:
      path: /api
      port: 3001
    initialDelaySeconds: 10
    periodSeconds: 5

# Frontend Web
frontend:
  enabled: true
  image:
    repository: dawidsages.azurecr.io/cezary-web
    tag: "latest"
    pullPolicy: Always
  service:
    type: ClusterIP
    port: 3000
  resources:
    requests:
      memory: "512Mi"
      cpu: "1m"
    limits:
      memory: "1000Mi"
      cpu: "100m"
  env:
    - name: REACT_APP_API_URL
      value: "/api"

# Image pull secrets (jeśli potrzebne)
imagePullSecrets:
  - name: azurecr
EOF
```

**Alternatywnie** użyj edytora:
```bash
nano todos-chart/values.yaml
# lub
vim todos-chart/values.yaml
```

Zawartość pliku `todos-chart/values.yaml` (pełna wersja):
```yaml
# Konfiguracja głównej aplikacji
replicaCount: 1

# Backend API
backend:
  enabled: true
  image:
    repository: dawidsages.azurecr.io/cezary-api
    tag: "latest"
    pullPolicy: Always
  service:
    type: ClusterIP
    port: 3001
  resources:
    requests:
      memory: "128Mi"
      cpu: "1m"
    limits:
      memory: "256Mi"
      cpu: "200m"
  env:
    - name: MONGODB_URI
      value: "mongodb://root:password@mongo-todos-mongodb:27017/todos?authSource=admin"
  livenessProbe:
    httpGet:
      path: /api
      port: 3001
    initialDelaySeconds: 20
    periodSeconds: 5
  readinessProbe:
    httpGet:
      path: /api
      port: 3001
    initialDelaySeconds: 10
    periodSeconds: 5

# Frontend Web
frontend:
  enabled: true
  image:
    repository: dawidsages.azurecr.io/cezary-web
    tag: "latest"
    pullPolicy: Always
  service:
    type: ClusterIP
    port: 3000
  resources:
    requests:
      memory: "512Mi"
      cpu: "1m"
    limits:
      memory: "1000Mi"
      cpu: "100m"
  env:
    - name: REACT_APP_API_URL
      value: "/api"

# Image pull secrets (jeśli potrzebne)
imagePullSecrets:
  - name: azurecr
```

### Krok 5: Utwórz szablon Deployment dla backend
```bash
# Utwórz plik backend-deployment.yaml
cat > todos-chart/templates/backend-deployment.yaml <<'EOF'
{{- if .Values.backend.enabled }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "todos-chart.fullname" . }}-backend
  labels:
    {{- include "todos-chart.labels" . | nindent 4 }}
    component: backend
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "todos-chart.selectorLabels" . | nindent 6 }}
      component: backend
  template:
    metadata:
      labels:
        {{- include "todos-chart.selectorLabels" . | nindent 8 }}
        component: backend
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
        - name: backend
          image: "{{ .Values.backend.image.repository }}:{{ .Values.backend.image.tag }}"
          imagePullPolicy: {{ .Values.backend.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.backend.service.port }}
              protocol: TCP
          env:
            {{- toYaml .Values.backend.env | nindent 12 }}
          {{- if .Values.backend.livenessProbe }}
          livenessProbe:
            {{- toYaml .Values.backend.livenessProbe | nindent 12 }}
          {{- end }}
          {{- if .Values.backend.readinessProbe }}
          readinessProbe:
            {{- toYaml .Values.backend.readinessProbe | nindent 12 }}
          {{- end }}
          resources:
            {{- toYaml .Values.backend.resources | nindent 12 }}
{{- end }}
EOF
```

**Uwaga**: Jeśli heredoc nie działa, utwórz plik ręcznie używając edytora (nano, vim, VS Code) i skopiuj zawartość powyżej.

### Krok 6: Utwórz szablon Service dla backend
```bash
cat > todos-chart/templates/backend-service.yaml <<'EOF'
{{- if .Values.backend.enabled }}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "todos-chart.fullname" . }}-backend
  labels:
    {{- include "todos-chart.labels" . | nindent 4 }}
    component: backend
spec:
  type: {{ .Values.backend.service.type }}
  ports:
    - port: {{ .Values.backend.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "todos-chart.selectorLabels" . | nindent 4 }}
    component: backend
{{- end }}
EOF
```

### Krok 7: Utwórz szablon Deployment dla frontend
```bash
cat > todos-chart/templates/frontend-deployment.yaml <<'EOF'
{{- if .Values.frontend.enabled }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "todos-chart.fullname" . }}-frontend
  labels:
    {{- include "todos-chart.labels" . | nindent 4 }}
    component: frontend
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "todos-chart.selectorLabels" . | nindent 6 }}
      component: frontend
  template:
    metadata:
      labels:
        {{- include "todos-chart.selectorLabels" . | nindent 8 }}
        component: frontend
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
        - name: frontend
          image: "{{ .Values.frontend.image.repository }}:{{ .Values.frontend.image.tag }}"
          imagePullPolicy: {{ .Values.frontend.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.frontend.service.port }}
              protocol: TCP
          {{- if .Values.frontend.env }}
          env:
            {{- toYaml .Values.frontend.env | nindent 12 }}
          {{- end }}
          resources:
            {{- toYaml .Values.frontend.resources | nindent 12 }}
{{- end }}
EOF
```

### Krok 8: Utwórz szablon Service dla frontend
```bash
cat > todos-chart/templates/frontend-service.yaml <<'EOF'
{{- if .Values.frontend.enabled }}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "todos-chart.fullname" . }}-frontend
  labels:
    {{- include "todos-chart.labels" . | nindent 4 }}
    component: frontend
spec:
  type: {{ .Values.frontend.service.type }}
  ports:
    - port: {{ .Values.frontend.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "todos-chart.selectorLabels" . | nindent 4 }}
    component: frontend
{{- end }}
EOF
```

### Krok 9: Zweryfikuj chart
```bash
cd todos-chart
# Sprawdź składnię
helm lint .

# Zobacz wygenerowane manifesty
helm template test-release .

# Symulacja instalacji
helm install test-release . --dry-run --debug
```

### Krok 10: Zainstaluj chart
```bash
# Upewnij się, że MongoDB jest zainstalowany (z ćwiczenia 3)
helm install todos-app . --namespace default
```

### Krok 11: Sprawdź status
```bash
helm status todos-app
kubectl get pods -l app.kubernetes.io/name=todos-chart
kubectl get svc -l app.kubernetes.io/name=todos-chart
```

### Krok 12: Przetestuj aplikację
```bash
# Port-forward do frontend (uruchom w osobnym terminalu lub w tle)
kubectl port-forward svc/todos-app-todos-chart-frontend 3000:3000

# W drugim terminalu port-forward do backend
kubectl port-forward svc/todos-app-todos-chart-backend 3001:3001

# Otwórz przeglądarkę: http://localhost:3000
# Uwaga: port-forward będzie działał dopóki nie przerwiesz go (Ctrl+C)
```

**Uwaga**: Jeśli nazwy serwisów są inne, sprawdź je używając:
```bash
kubectl get svc -l app.kubernetes.io/name=todos-chart
```

### Co się nauczyłeś?
- Jak tworzyć własne Helm charty
- Jak definiować wartości w values.yaml
- Jak tworzyć szablony Deployment i Service
- Jak używać funkcji pomocniczych z _helpers.tpl
- Jak konfigurować livenessProbe i readinessProbe
- Jak definiować zmienne środowiskowe
- Jak walidować i testować charty

---

## Ćwiczenie 5: Zaawansowane - Secrets i ConfigMaps

### Cel
Nauczysz się jak bezpiecznie zarządzać sekretami i konfiguracją w Helm.

### Krok 1: Utwórz Secret dla MongoDB
```bash
# Utwórz plik z wartościami secret
cat > todos-chart/values-secrets.yaml <<'EOF'
backend:
  env:
    - name: MONGODB_URI
      valueFrom:
        secretKeyRef:
          name: mongodb-secret
          key: uri
  imagePullSecrets:
    - name: azurecr
EOF
```

### Krok 2: Dodaj szablon Secret
```bash
cat > todos-chart/templates/secret.yaml <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "todos-chart.fullname" . }}-mongodb
  labels:
    {{- include "todos-chart.labels" . | nindent 4 }}
type: Opaque
data:
  uri: {{ .Values.mongodb.uri | b64enc | quote }}
{{- if .Values.mongodb.username }}
  username: {{ .Values.mongodb.username | b64enc | quote }}
  password: {{ .Values.mongodb.password | b64enc | quote }}
{{- end }}
EOF
```

### Krok 3: Zaktualizuj values.yaml
```bash
# Dodaj sekcję mongodb do values.yaml
cat >> todos-chart/values.yaml <<'EOF'

# MongoDB connection
mongodb:
  uri: "mongodb://root:password@mongo-todos-mongodb:27017/todos?authSource=admin"
  username: "root"
  password: "password"
EOF
```

### Krok 4: Zaktualizuj backend deployment aby używał Secret
```bash
# Zmień w backend-deployment.yaml sekcję env na:
env:
  - name: MONGODB_URI
    valueFrom:
      secretKeyRef:
        name: {{ include "todos-chart.fullname" . }}-mongodb
        key: uri
```

### Krok 5: Utwórz ConfigMap dla konfiguracji
```bash
cat > todos-chart/templates/configmap.yaml <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "todos-chart.fullname" . }}-config
  labels:
    {{- include "todos-chart.labels" . | nindent 4 }}
data:
  app.properties: |
    api.url={{ .Values.frontend.service.port }}
    environment={{ .Values.environment | default "development" }}
EOF
```

### Krok 6: Zweryfikuj i zainstaluj
```bash
helm lint .
helm template test-release . | grep -A 20 "kind: Secret"
helm upgrade --install todos-app . --set mongodb.password="nowe-haslo"
```

### Co się nauczyłeś?
- Jak tworzyć i używać Secrets w Helm
- Jak używać funkcji b64enc do kodowania
- Jak tworzyć ConfigMaps
- Jak bezpiecznie zarządzać danymi wrażliwymi

---

## Ćwiczenie 6: Opcjonalne - Instalacja Fluentd dla logowania

### Cel
Zainstalujesz Fluentd do zbierania i przetwarzania logów.

### Krok 1: Dodaj repozytorium Fluentd
```bash
helm repo add fluent https://fluent.github.io/helm-charts
helm repo update
```

### Krok 2: Sprawdź dostępne opcje
```bash
helm show values fluent/fluentd
```

### Krok 3: Zainstaluj Fluentd
```bash
helm install fluentd fluent/fluentd \
  --set rbac.create=true \
  --set daemonset.enabled=true
```

### Krok 4: Sprawdź status
```bash
kubectl get pods -l app=fluentd
kubectl logs -l app=fluentd
```

### Co się nauczyłeś?
- Jak instalować narzędzia do observability
- Jak konfigurować DaemonSet przez Helm

---

## Podsumowanie

Po ukończeniu tych ćwiczeń powinieneś umieć:

✅ Instalować i zarządzać chartami Helm z repozytoriów  
✅ Konfigurować aplikacje przez values.yaml  
✅ Tworzyć własne Helm charty  
✅ Definiować Deployments, Services, Secrets i ConfigMaps  
✅ Konfigurować livenessProbe i readinessProbe  
✅ Zarządzać zmiennymi środowiskowymi  
✅ Wykonywać upgrade, rollback i zarządzać historią  
✅ Walidować i testować charty przed instalacją  

## Przydatne komendy - Podsumowanie

```bash
# Repozytoria
helm repo add <nazwa> <url>
helm repo update
helm repo list

# Wyszukiwanie i instalacja
helm search repo <nazwa>
helm show values <chart>
helm install <release> <chart> -f values.yaml

# Zarządzanie
helm list
helm status <release>
helm get values <release>
helm upgrade <release> <chart>
helm rollback <release>
helm history <release>
helm uninstall <release>

# Tworzenie i walidacja
helm create <nazwa>
helm lint .
helm template <release> .
helm install <release> . --dry-run --debug
```

## Rozwiązywanie typowych problemów

### Problem: "Error: INSTALLATION FAILED"
**Rozwiązanie**: Sprawdź logi i status podów:
```bash
helm status <release-name>
kubectl get pods
kubectl describe pod <nazwa-poda>
kubectl logs <nazwa-poda>
```

### Problem: "secret not found" przy pobieraniu hasła
**Rozwiązanie**: Poczekaj aż secret zostanie utworzony, sprawdź nazwę:
```bash
kubectl get secrets | grep postgresql
# Użyj dokładnej nazwy secretu
```

### Problem: Heredoc nie działa w PowerShell
**Rozwiązanie**: Użyj edytora do tworzenia plików lub:
```powershell
# W PowerShell użyj @"
@" > plik.yaml
zawartość
"@
```

### Problem: Port-forward nie działa
**Rozwiązanie**: Sprawdź czy serwis istnieje i czy port jest poprawny:
```bash
kubectl get svc
kubectl describe svc <nazwa-serwisu>
```

### Problem: Chart nie może znaleźć funkcji pomocniczych
**Rozwiązanie**: Upewnij się, że `_helpers.tpl` zawiera potrzebne definicje:
```bash
helm create test-chart
cat test-chart/templates/_helpers.tpl
# Skopiuj potrzebne funkcje do swojego chartu
```

## Dodatkowe zasoby

- [Oficjalna dokumentacja Helm](https://helm.sh/docs/)
- [Artifact Hub - repozytorium chartów](https://artifacthub.io/)
- [Best Practices Helm](https://helm.sh/docs/chart_best_practices/)
- Pliki w tym katalogu: README.md, HELM_SYNTAX.md, dependencies.md
