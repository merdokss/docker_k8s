# Ćwiczenia: Affinity, Anti-Affinity, Taint i Tolerations w Kubernetes

## Ćwiczenie 1: Node Affinity

### Zadanie
Utwórz deployment, który będzie uruchamiał Pody tylko na węzłach z etykietą `environment=production`. (lub znajdź odpowiedni istniejący Label na nodes z Azure)

### Rozwiązanie
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: affinity-example
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
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

## Ćwiczenie 2: Pod Affinity

### Zadanie
Utwórz dwa deploymenty: `cache` i `web`. Pody z deploymentu `web` powinny być uruchamiane na tych samych węzłach co Pody z deploymentu `cache`.

### Rozwiązanie
```yaml
# Deployment cache
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cache
spec:
  replicas: 2
  selector:
    matchLabels:
      app: cache
  template:
    metadata:
      labels:
        app: cache
    spec:
      containers:
      - name: redis
        image: redis:latest

---
# Deployment web
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      affinity:
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - cache
            topologyKey: "kubernetes.io/hostname"
      containers:
      - name: nginx
        image: nginx:latest
```

## Ćwiczenie 3: Pod Anti-Affinity

### Zadanie
Utwórz deployment, który zapewni, że Pody nie będą uruchamiane na tym samym węźle (wysoka dostępność).

### Rozwiązanie
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ha-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ha-app
  template:
    metadata:
      labels:
        app: ha-app
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - ha-app
            topologyKey: "kubernetes.io/hostname"
      containers:
      - name: nginx
        image: nginx:latest
```

## Ćwiczenie 4: Taint i Tolerations

### Zadanie 1: Oznacz węzeł jako dedykowany dla aplikacji produkcyjnych
```bash
# Oznacz węzeł jako dedykowany dla aplikacji produkcyjnych
kubectl taint nodes node1 environment=production:NoSchedule
```

### Zadanie 2: Utwórz deployment, który będzie tolerował taint na węźle produkcyjnym
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
      containers:
      - name: nginx
        image: nginx:latest
```

## Ćwiczenie 5: Kombinacja Affinity i Taint

### Zadanie
Utwórz deployment, który:
1. Będzie tolerował taint `environment=production:NoSchedule`
2. Będzie preferował węzły z etykietą `disk=ssd`
3. Nie będzie uruchamiał więcej niż 2 Pody na tym samym węźle

### Rozwiązanie
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: complex-app
spec:
  replicas: 4
  selector:
    matchLabels:
      app: complex-app
  template:
    metadata:
      labels:
        app: complex-app
    spec:
      tolerations:
      - key: "environment"
        operator: "Equal"
        value: "production"
        effect: "NoSchedule"
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            preference:
              matchExpressions:
              - key: disk
                operator: In
                values:
                - ssd
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - complex-app
              topologyKey: "kubernetes.io/hostname"
      containers:
      - name: nginx
        image: nginx:latest
```

## Zadania do wykonania

1. **Zadanie 1:**
   - Utwórz klaster z 3 węzłami
   - Oznacz jeden węzeł jako dedykowany dla aplikacji produkcyjnych
   - Utwórz deployment, który będzie działał tylko na węźle produkcyjnym

2. **Zadanie 2:**
   - Utwórz dwa deploymenty: `database` i `app`
   - Zadbaj o to, aby Pody z `database` były rozłożone na różnych węzłach
   - Pody z `app` powinny być uruchamiane na tych samych węzłach co `database`

3. **Zadanie 3:**
   - Utwórz deployment z 5 replikami
   - Zaimplementuj strategię, która zapewni, że Pody będą równomiernie rozłożone na węzłach
   - Dodaj preferencję dla węzłów z większą ilością pamięci RAM

4. **Zadanie 4:**
   - Utwórz klaster z węzłami o różnych charakterystykach (CPU, RAM, dysk)
   - Oznacz węzły odpowiednimi taintami
   - Utwórz deploymenty, które będą tolerować odpowiednie tainty

## Wskazówki do zadań

1. Użyj `kubectl describe node` aby sprawdzić dostępne zasoby węzłów
2. Użyj `kubectl get nodes --show-labels` aby zobaczyć etykiety węzłów
3. Użyj `kubectl describe pod` aby sprawdzić, dlaczego Pod nie został zaplanowany
4. Pamiętaj o różnych operatorach w regułach affinity:
   - `In`
   - `NotIn`
   - `Exists`
   - `DoesNotExist`
   - `Gt`
   - `Lt`

## Przydatne komendy

```bash
# Sprawdź etykiety węzłów
kubectl get nodes --show-labels

# Dodaj etykietę do węzła
kubectl label nodes node1 disk=ssd

# Dodaj taint do węzła
kubectl taint nodes node1 environment=production:NoSchedule

# Usuń taint z węzła
kubectl taint nodes node1 environment=production:NoSchedule-

# Sprawdź status Podów
kubectl get pods -o wide

# Sprawdź szczegóły Poda
kubectl describe pod <pod-name>
``` 