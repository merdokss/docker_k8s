# Downward API w Kubernetes - proste wytłumaczenie

Downward API to mechanizm w Kubernetes, który pozwala **przekazać informacje o Podzie do samego kontenera**, który w tym Podzie działa. To jak dać aplikacji "lustro" - może zobaczyć własne metadane i parametry środowiska, w którym się uruchomiła.

## Po co to w ogóle?

Wyobraź sobie, że Twoja aplikacja działa w kontenerze i potrzebuje wiedzieć:
- "Jak się nazywam?" (nazwa Poda)
- "Ile pamięci mam do dyspozycji?" (limity zasobów)
- "Jakie mam etykiety?" (labels)
- "W jakim namespace żyję?"

Bez Downward API musiałbyś to "zahardcodować" albo skomplikować konfigurację. Z Downward API - Kubernetes sam przekaże te informacje.

## Dwa sposoby użycia

### 1️⃣ **Zmienne środowiskowe** (najprostszy sposób)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: moj-pod
  labels:
    app: demo
    env: prod
spec:
  containers:
  - name: moja-app
    image: nginx
    env:
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    - name: POD_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    - name: MEMORY_LIMIT
      valueFrom:
        resourceFieldRef:
          containerName: moja-app
          resource: limits.memory
```

Teraz wewnątrz kontenera możesz zrobić:
```bash
echo $POD_NAME        # wypisze: moj-pod
echo $POD_NAMESPACE   # wypisze: default
echo $MEMORY_LIMIT    # wypisze: limit pamięci
```

### 2️⃣ **Volume (pliki)** - dla bardziej złożonych danych

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: moj-pod
  labels:
    app: demo
    tier: frontend
  annotations:
    build: "12345"
spec:
  containers:
  - name: moja-app
    image: nginx
    volumeMounts:
    - name: podinfo
      mountPath: /etc/podinfo
  volumes:
  - name: podinfo
    downwardAPI:
      items:
      - path: "labels"
        fieldRef:
          fieldPath: metadata.labels
      - path: "annotations"
        fieldRef:
          fieldPath: metadata.annotations
```

Teraz w kontenerze znajdziesz:
- `/etc/podinfo/labels` - plik z wszystkimi labelami
- `/etc/podinfo/annotations` - plik z wszystkimi adnotacjami

## Co możesz "wyciągnąć" przez Downward API?

### **Z metadata:**
- `metadata.name` - nazwa Poda
- `metadata.namespace` - namespace
- `metadata.uid` - unikalny identyfikator
- `metadata.labels` - wszystkie labels (tylko volume)
- `metadata.annotations` - wszystkie annotations (tylko volume)
- `metadata.labels['klucz']` - konkretny label (env)

### **Ze status:**
- `status.podIP` - IP Poda
- `status.hostIP` - IP Node'a

### **Zasoby:**
- `requests.cpu` / `limits.cpu`
- `requests.memory` / `limits.memory`

## Praktyczny przykład zastosowania

**Scenariusz:** Masz aplikację logującą, która powinna zapisywać w logach nazwę Poda, namespace i wersję (z labela).

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: logger-app
  labels:
    version: "2.1.5"
spec:
  containers:
  - name: app
    image: mojafirma/logger:latest
    env:
    - name: LOG_POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    - name: LOG_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
    - name: APP_VERSION
      valueFrom:
        fieldRef:
          fieldPath: metadata.labels['version']
```

Teraz Twoja aplikacja może w logach pisać:
```
[2025-10-23] [logger-app] [default] [v2.1.5] Request processed
```

## 🎯 Kluczowe zalety

✅ **Brak hardcoded wartości** - aplikacja nie musi "wiedzieć" gdzie działa  
✅ **Elastyczność** - te same obrazy działają w różnych środowiskach  
✅ **Debugging** - łatwiej śledzić logi z wielu Podów  
✅ **Monitoring** - możesz tagować metryki nazwą Poda automatycznie

## ⚠️ Ograniczenia

- Nie możesz dostać **wszystkiego** (np. danych z innych Podów)
- Labels/annotations tylko przez volume, nie przez env
- To dane **read-only** - nie możesz ich zmienić z poziomu kontenera

