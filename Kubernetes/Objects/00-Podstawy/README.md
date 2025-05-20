# Podstawowe komendy Kubernetes

## Sprawdzanie konfiguracji

### Wyświetlenie aktualnej konfiguracji
```bash
# Wyświetlenie aktualnego kontekstu
kubectl config current-context

# Wyświetlenie wszystkich kontekstów
kubectl config get-contexts

# Wyświetlenie szczegółowej konfiguracji
kubectl config view

# Wyświetlenie konfiguracji w formacie YAML
kubectl config view --raw
```

### Zarządzanie kontekstami
```bash
# Przełączanie kontekstu
kubectl config use-context nazwa-kontekstu

# Dodawanie nowego kontekstu
kubectl config set-context nazwa-kontekstu --cluster=nazwa-klastra --user=nazwa-uzytkownika

# Usuwanie kontekstu
kubectl config delete-context nazwa-kontekstu
```

## Sprawdzanie wersji API

### Informacje o wersji
```bash
# Wyświetlenie wersji klienta i serwera
kubectl version

# Wyświetlenie wersji w formacie JSON
kubectl version -o json

# Wyświetlenie wersji klienta
kubectl version --client

# Wyświetlenie wersji serwera
kubectl version --server
```

### Dostępne zasoby API
```bash
# Lista wszystkich dostępnych zasobów API
kubectl api-resources

# Lista wszystkich wersji API
kubectl api-versions

# Sprawdzenie dostępności API
kubectl get --raw /

# Wyświetlenie szczegółowych informacji
kubectl explain [obiekt]
```

## Weryfikacja eventów

### Podstawowe komendy do eventów
```bash
# Wyświetlenie wszystkich eventów
kubectl get events

# Wyświetlenie eventów w formacie YAML
kubectl get events -o yaml

# Wyświetlenie eventów w formacie JSON
kubectl get events -o json
```

### Filtrowanie eventów
```bash
# Filtrowanie po typie eventu
kubectl get events --field-selector type=Warning
kubectl get events --field-selector type=Normal

# Filtrowanie po namespace
kubectl get events -n default

# Filtrowanie po zasobie
kubectl get events --field-selector involvedObject.kind=Pod
kubectl get events --field-selector involvedObject.name=nazwa-poda

# Filtrowanie po czasie
kubectl get events --field-selector lastTimestamp>$(date -d "5 minutes ago" -Iseconds)
```

### Sortowanie eventów
```bash
# Sortowanie po czasie
kubectl get events --sort-by='.lastTimestamp'

# Sortowanie po typie
kubectl get events --sort-by='.type'
```


## Przykłady użycia

### Sprawdzenie stanu klastra
```bash
# Sprawdzenie węzłów
kubectl get nodes

# Sprawdzenie podów
kubectl get pods --all-namespaces

# Sprawdzenie usług
kubectl get services --all-namespaces
```

### Debugowanie
```bash
# Sprawdzenie logów poda
kubectl logs nazwa-poda

# Sprawdzenie opisu poda
kubectl describe pod nazwa-poda

# Sprawdzenie eventów dla konkretnego poda
kubectl events --field-selector involvedObject.kind=Pod,involvedObject.name=nazwa-poda
```
