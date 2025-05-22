# Rozwiązania: Network Policies w Kubernetes

## Zadanie 1: Komunikacja między frontend, api i database

### Deploymenty
```yaml
# Deployment frontend
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:latest
---
# Deployment api
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: nginx:latest
---
# Deployment database
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
spec:
  replicas: 1
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
    spec:
      containers:
      - name: postgres
        image: postgres:latest
```

### Network Policies
```yaml
# Network Policy dla frontend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-policy
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: api
---
# Network Policy dla api
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-policy
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
---
# Network Policy dla database
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-policy
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: api
```

## Zadanie 2: Izolacja namespace'ów

### Namespace'y i Deploymenty
```yaml
# Namespace prod
apiVersion: v1
kind: Namespace
metadata:
  name: prod
  labels:
    name: prod
---
# Namespace dev
apiVersion: v1
kind: Namespace
metadata:
  name: dev
  labels:
    name: dev
---
# Deployment w namespace prod
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  namespace: prod
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app
  template:
    metadata:
      labels:
        app: app
    spec:
      containers:
      - name: nginx
        image: nginx:latest
---
# Deployment w namespace dev
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  namespace: dev
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app
  template:
    metadata:
      labels:
        app: app
    spec:
      containers:
      - name: nginx
        image: nginx:latest
```

### Network Policy
```yaml
# Network Policy dla namespace prod
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: prod-network-policy
  namespace: prod
spec:
  podSelector:
    matchLabels:
      app: app
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: prod
```

## Zadanie 3: Kontrola dostępu do portów

### Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: nginx:latest
        ports:
        - containerPort: 80
        - containerPort: 443
        - containerPort: 8080
```

### Network Policy
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-port-policy
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  ingress:
  # Dostęp do portu 80 tylko z wewnątrz klastra
  - ports:
    - protocol: TCP
      port: 80
    from:
    - podSelector: {}
  # Dostęp do portu 443 tylko z określonego zakresu IP
  - ports:
    - protocol: TCP
      port: 443
    from:
    - ipBlock:
        cidr: 10.0.0.0/24
  # Brak reguły dla portu 8080 = brak dostępu
```

## Zadanie 4: Ograniczenie połączeń wychodzących

### Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: restricted-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: restricted-app
  template:
    metadata:
      labels:
        app: restricted-app
    spec:
      containers:
      - name: nginx
        image: nginx:latest
```

### Network Policy
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: restricted-app-policy
spec:
  podSelector:
    matchLabels:
      app: restricted-app
  policyTypes:
  - Egress
  egress:
  # Pozwól na połączenia DNS
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
    ports:
    - protocol: UDP
      port: 53
  # Pozwól na połączenia do określonych domen
  - to:
    - ipBlock:
        cidr: 8.8.8.8/32
    ports:
    - protocol: TCP
      port: 443
  - to:
    - ipBlock:
        cidr: 1.1.1.1/32
    ports:
    - protocol: TCP
      port: 443
```

## Wskazówki do testowania

1. Testowanie połączeń między Podami:
```bash
# Sprawdź połączenie z frontend do api
kubectl exec -it $(kubectl get pod -l app=frontend -o jsonpath='{.items[0].metadata.name}') -- curl api:80

# Sprawdź połączenie z api do database
kubectl exec -it $(kubectl get pod -l app=api -o jsonpath='{.items[0].metadata.name}') -- curl database:5432

# Sprawdź połączenie z frontend do database (powinno być zablokowane)
kubectl exec -it $(kubectl get pod -l app=frontend -o jsonpath='{.items[0].metadata.name}') -- curl database:5432
```

2. Testowanie połączeń między namespace'ami:
```bash
# Sprawdź połączenie między Podami w namespace prod
kubectl exec -it -n prod $(kubectl get pod -n prod -l app=app -o jsonpath='{.items[0].metadata.name}') -- curl app.prod.svc.cluster.local

# Sprawdź połączenie z prod do dev (powinno być zablokowane)
kubectl exec -it -n prod $(kubectl get pod -n prod -l app=app -o jsonpath='{.items[0].metadata.name}') -- curl app.dev.svc.cluster.local
```

3. Testowanie dostępu do portów:
```bash
# Sprawdź dostęp do portu 80
kubectl exec -it $(kubectl get pod -l app=api -o jsonpath='{.items[0].metadata.name}') -- curl localhost:80

# Sprawdź dostęp do portu 443
kubectl exec -it $(kubectl get pod -l app=api -o jsonpath='{.items[0].metadata.name}') -- curl localhost:443

# Sprawdź dostęp do portu 8080 (powinien być zablokowany)
kubectl exec -it $(kubectl get pod -l app=api -o jsonpath='{.items[0].metadata.name}') -- curl localhost:8080
```

4. Testowanie połączeń wychodzących:
```bash
# Sprawdź połączenie do dozwolonej domeny
kubectl exec -it $(kubectl get pod -l app=restricted-app -o jsonpath='{.items[0].metadata.name}') -- curl https://8.8.8.8

# Sprawdź połączenie do niedozwolonej domeny (powinno być zablokowane)
kubectl exec -it $(kubectl get pod -l app=restricted-app -o jsonpath='{.items[0].metadata.name}') -- curl https://example.com
``` 