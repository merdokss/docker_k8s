# Ćwiczenia: Network Policies w Kubernetes

## Ćwiczenie 1: Podstawowa Network Policy

### Zadanie
Utwórz Network Policy, która ograniczy ruch przychodzący do Poda tylko z Poda z etykietą `app=frontend`.

### Rozwiązanie
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: basic-network-policy
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
```

## Ćwiczenie 2: Network Policy z Namespace

### Zadanie
Utwórz Network Policy, która pozwoli na ruch tylko z określonego namespace.

### Rozwiązanie
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: namespace-network-policy
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: frontend-namespace
```

## Ćwiczenie 3: Network Policy z Portami

### Zadanie
Utwórz Network Policy, która ograniczy ruch do określonych portów.

### Rozwiązanie
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: port-network-policy
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
    ports:
    - protocol: TCP
      port: 5432
```

## Ćwiczenie 4: Network Policy z CIDR

### Zadanie
Utwórz Network Policy, która pozwoli na ruch tylko z określonego zakresu IP.

### Rozwiązanie
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: cidr-network-policy
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - ipBlock:
        cidr: 10.0.0.0/24
        except:
        - 10.0.0.1/32
```

## Ćwiczenie 5: Egress Network Policy

### Zadanie
Utwórz Network Policy, która ograniczy ruch wychodzący z Poda.

### Rozwiązanie
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: egress-network-policy
spec:
  podSelector:
    matchLabels:
      app: restricted
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
```

## Zadania do wykonania

1. **Zadanie 1:**
   - Utwórz trzy deploymenty: `frontend`, `api` i `database`
   - Zaimplementuj Network Policy, która:
     - Pozwoli `frontend` komunikować się tylko z `api`
     - Pozwoli `api` komunikować się tylko z `database`
     - Zablokuje bezpośrednią komunikację między `frontend` a `database`

2. **Zadanie 2:**
   - Utwórz dwa namespace: `prod` i `dev`
   - W każdym namespace utwórz deployment `app`
   - Zaimplementuj Network Policy, która:
     - Pozwoli na komunikację między Poda w namespace `prod`
     - Zablokuje komunikację między namespace `prod` i `dev`

3. **Zadanie 3:**
   - Utwórz deployment `api` z kilkoma portami (np. 80, 443, 8080)
   - Zaimplementuj Network Policy, która:
     - Pozwoli na dostęp do portu 80 tylko z wewnątrz klastra
     - Pozwoli na dostęp do portu 443 tylko z określonego zakresu IP
     - Zablokuje dostęp do portu 8080

4. **Zadanie 4:**
   - Utwórz deployment `restricted-app`
   - Zaimplementuj Network Policy, która:
     - Pozwoli na wychodzące połączenia tylko do określonych domen
     - Zablokuje wszystkie inne połączenia wychodzące

## Wskazówki do zadań

1. Użyj `kubectl get networkpolicy` aby sprawdzić istniejące Network Policies
2. Użyj `kubectl describe networkpolicy` aby zobaczyć szczegóły Network Policy
3. Pamiętaj o sprawdzeniu, czy twój klastr wspiera Network Policies
4. Użyj `kubectl exec` do testowania połączeń między Podami
5. Pamiętaj o różnych typach polityk:
   - `Ingress` - ruch przychodzący
   - `Egress` - ruch wychodzący
6. Możesz łączyć różne selektory w jednej Network Policy:
   - `podSelector`
   - `namespaceSelector`
   - `ipBlock` 