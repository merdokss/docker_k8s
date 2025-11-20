# Kubernetes - Ćwiczenia: ResourceQuota i LimitRange

> **Wprowadzenie:** Te ćwiczenia pomogą Ci zrozumieć ResourceQuota i LimitRange w Kubernetes. ResourceQuota ogranicza całkowitą ilość zasobów w namespace, a LimitRange ustawia domyślne limity i requesty dla kontenerów.

**Co to jest ResourceQuota?** ResourceQuota ogranicza całkowitą ilość zasobów (CPU, pamięć, PVC itp.), które mogą być używane w namespace.

**Co to jest LimitRange?** LimitRange ustawia domyślne limity i requesty dla kontenerów w namespace, a także ogranicza maksymalne i minimalne wartości.

## Przygotowanie środowiska

```bash
# Utwórz namespace (jeśli jeszcze nie istnieje)
kubectl create namespace cwiczenia
```

---

## Ćwiczenie 5.1: ResourceQuota - Podstawowe limity

**Zadanie:** Utwórz ResourceQuota `compute-quota` w namespace `cwiczenia`, która ogranicza:
- CPU requests: 4 cores
- CPU limits: 8 cores
- Memory requests: 8Gi
- Memory limits: 16Gi

Następnie utwórz Deployment `nginx-quota` z 3 replikami, gdzie każdy kontener ma request: CPU 500m, Memory 512Mi i limit: CPU 1, Memory 1Gi. Sprawdź, czy wszystkie repliki mogą się uruchomić.

**Wskazówki:**
- ResourceQuota sumuje wszystkie requests i limits w namespace
- Jeśli suma przekroczy limit, nowe Pody nie zostaną utworzone
- 3 repliki × 500m = 1.5 cores (OK, mieści się w 4)
- 3 repliki × 1 CPU = 3 cores (OK, mieści się w 8)
- Sprawdź status ResourceQuota: `kubectl describe resourcequota compute-quota -n cwiczenia`

**Cel:** Zrozumienie podstawowej konfiguracji ResourceQuota i jak ogranicza zasoby w namespace.

**Weryfikacja:**
```bash
# Sprawdź ResourceQuota
kubectl get resourcequota compute-quota -n cwiczenia
kubectl describe resourcequota compute-quota -n cwiczenia

# Sprawdź Deployment
kubectl get deployment nginx-quota -n cwiczenia

# Sprawdź Pody (wszystkie powinny być uruchomione)
kubectl get pods -n cwiczenia -l app=nginx-quota

# Sprawdź użycie zasobów
kubectl top pods -n cwiczenia -l app=nginx-quota
```

---

## Ćwiczenie 5.2: ResourceQuota - Przekroczenie limitu

**Zadanie:** Po wykonaniu ćwiczenia 5.1, spróbuj zwiększyć Deployment `nginx-quota` do 6 replik. Sprawdź, co się stanie z nowymi Podami (nie powinny się uruchomić z powodu przekroczenia ResourceQuota).

**Wskazówki:**
- 6 replik × 500m = 3 cores (OK, mieści się w 4)
- Ale 6 replik × 1 CPU = 6 cores (OK, mieści się w 8)
- Spróbuj zwiększyć do 10 replik: 10 replik × 500m = 5 cores (przekroczy limit 4 cores dla requests)
- Nowe Pody pozostaną w stanie Pending
- Sprawdź wydarzenia: `kubectl describe pod <nazwa-poda> -n cwiczenia`
- W wydarzeniach powinieneś zobaczyć informację o przekroczeniu ResourceQuota

**Cel:** Zrozumienie, jak ResourceQuota blokuje tworzenie Podów po przekroczeniu limitów.

**Weryfikacja:**
```bash
# Zwiększ liczbę replik do 10 (przekroczy limit ResourceQuota)
kubectl scale deployment nginx-quota --replicas=10 -n cwiczenia

# Sprawdź Pody (niektóre powinny być w stanie Pending)
kubectl get pods -n cwiczenia -l app=nginx-quota

# Sprawdź szczegóły Poda w stanie Pending
kubectl describe pod <nazwa-poda-w-pending> -n cwiczenia | grep -A 10 Events

# Sprawdź ResourceQuota (powinna pokazywać wykorzystanie blisko lub przekraczające limit)
kubectl describe resourcequota compute-quota -n cwiczenia
```

---

## Ćwiczenie 5.3: LimitRange - Domyślne wartości

**Zadanie:** Utwórz LimitRange `default-limits` w namespace `cwiczenia`, która ustawia:
- Domyślne request: CPU 100m, Memory 128Mi
- Domyślny limit: CPU 500m, Memory 512Mi
- Maksymalny limit: CPU 2, Memory 2Gi
- Minimalny request: CPU 50m, Memory 64Mi

Następnie utwórz Pod `nginx-limitrange` bez określonych requestów i limitów. Sprawdź, czy automatycznie otrzymał domyślne wartości.

**Wskazówki:**
- LimitRange automatycznie wstrzykuje domyślne wartości do kontenerów bez określonych requestów/limitów
- Jeśli kontener ma określone wartości, LimitRange ich nie zmienia
- LimitRange waliduje, czy wartości mieszczą się w zakresie min-max

**Cel:** Zrozumienie automatycznego ustawiania domyślnych requestów i limitów przez LimitRange.

**Weryfikacja:**
```bash
# Sprawdź LimitRange
kubectl get limitrange default-limits -n cwiczenia
kubectl describe limitrange default-limits -n cwiczenia

# Sprawdź Pod (powinien mieć automatycznie wstrzyknięte requesty i limity)
kubectl get pod nginx-limitrange -n cwiczenia -o yaml | grep -A 10 resources

# Porównaj z Pody bez LimitRange (w innym namespace) - różnica powinna być widoczna
```

---

## Ćwiczenie 5.4: LimitRange - Walidacja limitów

**Zadanie:** Po wykonaniu ćwiczenia 5.3, spróbuj utworzyć Pod `nginx-invalid` z request CPU 10m (poniżej minimum 50m) lub limit CPU 5 (powyżej maksimum 2). Sprawdź, czy Pod zostanie utworzony (nie powinien - LimitRange zablokuje).

**Wskazówki:**
- LimitRange waliduje wartości przed utworzeniem Poda
- Jeśli wartości są poza zakresem, Pod nie zostanie utworzony
- Sprawdź wydarzenia: `kubectl describe pod nginx-invalid -n cwiczenia`
- Powinieneś zobaczyć błąd walidacji

**Cel:** Zrozumienie walidacji limitów przez LimitRange i jak blokuje nieprawidłowe wartości.

**Weryfikacja:**
```bash
# Spróbuj utworzyć Pod z request poniżej minimum
kubectl run nginx-invalid --image=nginx:latest \
  --requests=cpu=10m,memory=64Mi \
  -n cwiczenia

# Sprawdź status Poda (powinien być w stanie Failed lub nie utworzony)
kubectl get pod nginx-invalid -n cwiczenia

# Sprawdź szczegóły błędu
kubectl describe pod nginx-invalid -n cwiczenia | grep -A 10 Events

# Spróbuj z limitem powyżej maksimum
kubectl run nginx-invalid2 --image=nginx:latest \
  --limits=cpu=5,memory=4Gi \
  -n cwiczenia

# Sprawdź błąd
kubectl describe pod nginx-invalid2 -n cwiczenia | grep -A 10 Events
```

---

## Podsumowanie

Po wykonaniu ćwiczeń z ResourceQuota i LimitRange powinieneś:
- ✅ Rozumieć, jak ResourceQuota ogranicza zasoby w namespace
- ✅ Umieć używać LimitRange do ustawiania domyślnych wartości
- ✅ Rozumieć walidację limitów przez LimitRange

## Przydatne komendy

```bash
# ResourceQuota
kubectl get resourcequota -n <namespace>
kubectl describe resourcequota <name> -n <namespace>

# LimitRange
kubectl get limitrange -n <namespace>
kubectl describe limitrange <name> -n <namespace>

# Sprawdzanie użycia zasobów
kubectl top pods -n <namespace>
kubectl top nodes
```

