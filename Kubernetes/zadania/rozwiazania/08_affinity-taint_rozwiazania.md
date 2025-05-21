# Rozwiązania zadań: Affinity, Anti-Affinity, Taint i Tolerations

## Rozwiązanie zadania 1: Klaster z dedykowanym węzłem produkcyjnym

### 1. Przygotowanie klastra
```bash
# Sprawdź węzły
kubectl get nodes

# Oznacz węzeł jako produkcyjny
kubectl taint nodes node1 environment=production:NoSchedule

# Dodaj etykietę do węzła (opcjonalnie)
kubectl label nodes node1 environment=production
```

### 2. Deployment dla aplikacji produkcyjnej
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: production-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: production-app
  template:
    metadata:
      labels:
        app: production-app
    spec:
      tolerations:
      - key: "environment"
        operator: "Equal"
        value: "production"
        effect: "NoSchedule"
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: environment
                operator: In
                values:
                - production
      containers:
      - name: nginx
        image: nginx:latest
```

## Rozwiązanie zadania 2: Database i App deploymenty

### 1. Deployment bazy danych z Anti-Affinity
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
spec:
  replicas: 3
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - database
            topologyKey: "kubernetes.io/hostname"
      containers:
      - name: postgres
        image: postgres:latest
```

### 2. Deployment aplikacji z Pod Affinity
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: app
  template:
    metadata:
      labels:
        app: app
    spec:
      affinity:
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - database
            topologyKey: "kubernetes.io/hostname"
      containers:
      - name: nginx
        image: nginx:latest
```

## Rozwiązanie zadania 3: Równomierny rozkład Podów

### 1. Przygotowanie węzłów
```bash
# Dodaj etykiety z informacją o RAM
kubectl label nodes node1 memory=high
kubectl label nodes node2 memory=medium
kubectl label nodes node3 memory=low
```

### 2. Deployment z równomiernym rozkładem
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: balanced-app
spec:
  replicas: 5
  selector:
    matchLabels:
      app: balanced-app
  template:
    metadata:
      labels:
        app: balanced-app
    spec:
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            preference:
              matchExpressions:
              - key: memory
                operator: In
                values:
                - high
          - weight: 50
            preference:
              matchExpressions:
              - key: memory
                operator: In
                values:
                - medium
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - balanced-app
            topologyKey: "kubernetes.io/hostname"
            maxSkew: 1
      containers:
      - name: nginx
        image: nginx:latest
```

## Rozwiązanie zadania 4: Klaster z różnymi charakterystykami węzłów

### 1. Przygotowanie węzłów
```bash
# Oznacz węzły odpowiednimi taintami
kubectl taint nodes node1 compute=high:NoSchedule
kubectl taint nodes node2 memory=high:NoSchedule
kubectl taint nodes node3 storage=ssd:NoSchedule

# Dodaj etykiety
kubectl label nodes node1 compute=high
kubectl label nodes node2 memory=high
kubectl label nodes node3 storage=ssd
```

### 2. Deployment dla aplikacji wymagającej dużej mocy obliczeniowej
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: compute-intensive
spec:
  replicas: 2
  selector:
    matchLabels:
      app: compute-intensive
  template:
    metadata:
      labels:
        app: compute-intensive
    spec:
      tolerations:
      - key: "compute"
        operator: "Equal"
        value: "high"
        effect: "NoSchedule"
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: compute
                operator: In
                values:
                - high
      containers:
      - name: app
        image: nginx:latest
```

### 3. Deployment dla aplikacji wymagającej dużej ilości pamięci
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: memory-intensive
spec:
  replicas: 2
  selector:
    matchLabels:
      app: memory-intensive
  template:
    metadata:
      labels:
        app: memory-intensive
    spec:
      tolerations:
      - key: "memory"
        operator: "Equal"
        value: "high"
        effect: "NoSchedule"
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: memory
                operator: In
                values:
                - high
      containers:
      - name: app
        image: nginx:latest
```

### 4. Deployment dla aplikacji wymagającej szybkiego dostępu do dysku
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: storage-intensive
spec:
  replicas: 2
  selector:
    matchLabels:
      app: storage-intensive
  template:
    metadata:
      labels:
        app: storage-intensive
    spec:
      tolerations:
      - key: "storage"
        operator: "Equal"
        value: "ssd"
        effect: "NoSchedule"
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: storage
                operator: In
                values:
                - ssd
      containers:
      - name: app
        image: nginx:latest
```

## Weryfikacja rozwiązań

### Sprawdzenie rozmieszczenia Podów
```bash
# Sprawdź status Podów i ich rozmieszczenie
kubectl get pods -o wide

# Sprawdź szczegóły Poda
kubectl describe pod <pod-name>

# Sprawdź etykiety węzłów
kubectl get nodes --show-labels

# Sprawdź tainty węzłów
kubectl describe node <node-name>
```

### Przydatne komendy do debugowania
```bash
# Sprawdź events w namespace
kubectl get events

# Sprawdź szczegóły deploymentu
kubectl describe deployment <deployment-name>

# Sprawdź logi Poda
kubectl logs <pod-name>
``` 