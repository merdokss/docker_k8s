# Tainty w Kubernetes

Tainty (skazy) w Kubernetes to mechanizm, który pozwala na oznaczenie węzłów w taki sposób, że Pody nie mogą być na nich planowane, chyba że mają odpowiednie toleracje. Jest to potężne narzędzie do kontrolowania, gdzie Pody mogą być uruchamiane w klastrze.

## Rodzaje efektów (effects) dla taintów

W Kubernetes istnieją trzy rodzaje efektów dla taintów:

### 1. `NoSchedule`
- Najbardziej restrykcyjny efekt
- Kompletnie blokuje planowanie nowych Podów na węźle
- Istniejące Pody na węźle pozostają bez zmian
- Używany gdy:
  - Węzeł jest dedykowany dla specjalnych obciążeń
  - Węzeł ma problemy z zasobami
  - Chcemy zarezerwować węzeł dla konkretnych aplikacji

### 2. `PreferNoSchedule`
- Mniej restrykcyjny niż `NoSchedule`
- Scheduler będzie starał się unikać planowania Podów na tym węźle
- Jeśli nie ma innych dostępnych węzłów, Pod może zostać zaplanowany na węźle z taintem
- Używany gdy:
  - Chcemy preferować inne węzły, ale nie blokować całkowicie
  - Mamy miękkie wymagania dotyczące rozmieszczenia Podów

### 3. `NoExecute`
- Najbardziej agresywny efekt
- Blokuje planowanie nowych Podów
- Wyrzuca istniejące Pody z węzła, które nie mają odpowiedniej toleracji
- Używany gdy:
  - Węzeł jest w trakcie konserwacji
  - Węzeł ma problemy z wydajnością
  - Chcemy natychmiastowo przenieść obciążenie z węzła

## Przykłady użycia

### Dodawanie taintów
```bash
# NoSchedule - całkowita blokada
kubectl taint nodes node1 environment=production:NoSchedule

# PreferNoSchedule - preferencja unikania
kubectl taint nodes node1 environment=staging:PreferNoSchedule

# NoExecute - natychmiastowe wyrzucenie Podów
kubectl taint nodes node1 maintenance=true:NoExecute
```

### Usuwanie taintów
```bash
# Usuń taint
kubectl taint nodes node1 environment=production:NoSchedule-
```

## Toleracje w Podach

Aby Pod mógł być uruchomiony na węźle z taintem, musi mieć odpowiednią tolerację:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: example-app
spec:
  replicas: 3
  template:
    spec:
      tolerations:
      # Toleracja dla NoSchedule
      - key: "environment"
        operator: "Equal"
        value: "production"
        effect: "NoSchedule"
      
      # Toleracja dla PreferNoSchedule
      - key: "environment"
        operator: "Equal"
        value: "staging"
        effect: "PreferNoSchedule"
      
      # Toleracja dla NoExecute
      - key: "maintenance"
        operator: "Equal"
        value: "true"
        effect: "NoExecute"
        tolerationSeconds: 3600  # Opcjonalnie: czas toleracji w sekundach
      
      # Toleracja dla wszystkich efektów
      - key: "key"
        operator: "Exists"
        effect: "NoExecute"
      
      containers:
      - name: nginx
        image: nginx:latest
```

## Typowe scenariusze użycia

### 1. Scenariusz produkcyjny
```bash
# Oznacz węzły produkcyjne
kubectl taint nodes node1 environment=production:NoSchedule
kubectl taint nodes node2 environment=production:NoSchedule
```

### 2. Scenariusz konserwacji
```bash
# Oznacz węzeł jako w konserwacji
kubectl taint nodes node1 maintenance=true:NoExecute
```

### 3. Scenariusz preferencji
```bash
# Preferuj węzły z większą ilością RAM
kubectl taint nodes node1 memory=high:PreferNoSchedule
```

## Weryfikacja i debugowanie

### Sprawdzanie taintów
```bash
# Sprawdź tainty na węźle
kubectl describe node node1 | grep Taints

# Sprawdź wszystkie węzły i ich tainty
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
```

### Sprawdzanie statusu Podów
```bash
# Sprawdź status Podów
kubectl get pods -o wide

# Sprawdź szczegóły Poda
kubectl describe pod <pod-name>
```

## Wskazówki i najlepsze praktyki

1. **Wybór odpowiedniego efektu:**
   - Używaj `NoSchedule` gdy chcesz całkowicie zarezerwować węzeł
   - Używaj `PreferNoSchedule` gdy chcesz preferować inne węzły, ale nie blokować całkowicie
   - Używaj `NoExecute` gdy chcesz natychmiastowo przenieść obciążenie z węzła

2. **Toleracje:**
   - Zawsze dodawaj odpowiednie toleracje w Podach, które mają działać na węzłach z taintami
   - Możesz używać `tolerationSeconds` z `NoExecute` aby dać Podom czas na bezpieczne zakończenie pracy
   - Używaj operatora `Exists` gdy chcesz tolerować wszystkie wartości danego klucza

3. **Planowanie:**
   - Pamiętaj, że tainty są sprawdzane przed innymi regułami planowania
   - Tainty działają w połączeniu z etykietami i selektorami
   - Możesz używać taintów do tworzenia "dedykowanych pul" węzłów

4. **Bezpieczeństwo:**
   - Używaj taintów do izolacji krytycznych obciążeń
   - Implementuj tainty jako część strategii bezpieczeństwa klastra
   - Regularnie przeglądaj i aktualizuj tainty w klastrze 