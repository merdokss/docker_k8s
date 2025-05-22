# ResourceQuota i LimitRange w Kubernetes

## ResourceQuota

ResourceQuota to mechanizm w Kubernetes, który pozwala na ograniczenie całkowitej ilości zasobów, które mogą być używane w przestrzeni nazw (namespace). Jest to szczególnie przydatne w środowiskach wielodostępowych, gdzie chcemy zapewnić sprawiedliwy podział zasobów między różnych użytkowników lub zespoły.

### Główne cechy ResourceQuota:
- Ogranicza całkowitą ilość zasobów w namespace
- Może ograniczać:
  - CPU
  - Pamięć
  - Liczbę podów
  - Liczbę serwisów
  - Liczbę PersistentVolumeClaims
  - I inne zasoby

### Przykład ResourceQuota:
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-resources
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 4Gi
    limits.cpu: "8"
    limits.memory: 8Gi
    pods: "10"
```

## LimitRange

LimitRange to mechanizm, który pozwala na ustawienie domyślnych limitów zasobów dla podów i kontenerów w namespace. Jeśli pod nie określa własnych limitów, zostaną zastosowane wartości domyślne z LimitRange.

### Główne cechy LimitRange:
- Ustawia domyślne limity zasobów
- Definiuje minimalne i maksymalne wartości zasobów
- Może ustawiać domyślne wartości dla:
  - CPU
  - Pamięci
  - Request/limit ratio
  - Storage

### Przykład LimitRange:
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: resource-limits
spec:
  limits:
  - default:
      cpu: 500m
      memory: 512Mi
    defaultRequest:
      cpu: 100m
      memory: 128Mi
    type: Container
```

## Różnice między ResourceQuota a LimitRange

1. **Zakres działania**:
   - ResourceQuota: działa na poziomie całego namespace
   - LimitRange: działa na poziomie pojedynczych podów i kontenerów

2. **Cel**:
   - ResourceQuota: ogranicza całkowitą ilość zasobów
   - LimitRange: definiuje domyślne i minimalne/maksymalne wartości zasobów

3. **Zastosowanie**:
   - ResourceQuota: kontrola kosztów i sprawiedliwy podział zasobów
   - LimitRange: zapewnienie spójności i bezpieczeństwa w konfiguracji zasobów

## Najlepsze praktyki

1. Zawsze definiuj ResourceQuota dla produkcyjnych namespace'ów
2. Używaj LimitRange do zapewnienia spójnych limitów zasobów
3. Regularnie monitoruj wykorzystanie zasobów
4. Dostosowuj limity w zależności od rzeczywistego zapotrzebowania
5. Dokumentuj polityki dotyczące zasobów
