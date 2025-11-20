# Kubernetes - Ćwiczenia: Affinity i Anti-affinity

> **Wprowadzenie:** Te ćwiczenia pomogą Ci zrozumieć Affinity i Anti-affinity w Kubernetes. Affinity pozwala określić reguły, gdzie Pody powinny być uruchomione w oparciu o etykiety nodów lub innych Podów.

**Co to jest Affinity?** Affinity pozwala określić reguły, gdzie Pody powinny być uruchomione w oparciu o etykiety nodów lub innych Podów.

**Typy Affinity:**
- **nodeAffinity** - umieszczanie Podów na określonych nodach
- **podAffinity** - umieszczanie Podów razem z innymi Podami
- **podAntiAffinity** - unikanie umieszczania Podów razem

## Przygotowanie środowiska

```bash
# Utwórz namespace (jeśli jeszcze nie istnieje)
kubectl create namespace cwiczenia

# Sprawdź dostępne nody i ich etykiety
kubectl get nodes --show-labels

# Sprawdź liczbę nodów
kubectl get nodes
```

---

## Ćwiczenie 3.1: Node Affinity - Required

**Zadanie:** Oznacz jeden z nodów etykietą `disktype=ssd`, a następnie utwórz Deployment `nginx-ssd` z 3 replikami (obraz `nginx:latest`), który używa `requiredDuringSchedulingIgnoredDuringExecution` nodeAffinity, aby umieścić Pody tylko na nodach z etykietą `disktype=ssd`.

**Wskazówki:**
- Najpierw sprawdź dostępne nody: `kubectl get nodes`
- Oznacz jeden z nodów etykietą: `kubectl label nodes <node-name> disktype=ssd`
- Sprawdź czy etykieta została dodana: `kubectl get nodes --show-labels | grep disktype`
- `requiredDuringSchedulingIgnoredDuringExecution` - wymagane podczas planowania
- Jeśli nie ma odpowiednich nodów, Pody pozostaną w stanie Pending
- Sprawdź dostępne nody: `kubectl get nodes --show-labels`

**Cel:** Zrozumienie wymuszonego umieszczania Podów na określonych nodach.

**Weryfikacja:**
```bash
# Sprawdź etykiety nodów
kubectl get nodes --show-labels | grep disktype

# Sprawdź Deployment
kubectl get deployment nginx-ssd -n cwiczenia

# Sprawdź Pody i na jakich nodach są uruchomione
kubectl get pods -n cwiczenia -l app=nginx-ssd -o wide

# Wszystkie Pody powinny być na nodzie z etykietą disktype=ssd
```

---

## Ćwiczenie 3.2: Node Affinity - Preferred

**Zadanie:** Utwórz Deployment `nginx-preferred` z 3 replikami (obraz `nginx:latest`), który używa `preferredDuringSchedulingIgnoredDuringExecution` nodeAffinity, aby preferować nody z etykietą `environment=production`. Jeśli nie ma takich nodów, Pody mogą być uruchomione gdziekolwiek.

**Wskazówki:**
- `preferredDuringSchedulingIgnoredDuringExecution` - preferowane, ale nie wymagane
- Możesz określić wagę (`weight: 100`) dla różnych preferencji
- Pody będą planowane normalnie, ale scheduler będzie preferował pasujące nody

**Cel:** Zrozumienie preferowanego umieszczania Podów na nodach.

**Weryfikacja:**
```bash
# Sprawdź Deployment
kubectl get deployment nginx-preferred -n cwiczenia

# Sprawdź Pody (powinny być uruchomione, nawet jeśli nie ma nodów z environment=production)
kubectl get pods -n cwiczenia -l app=nginx-preferred -o wide

# Sprawdź wydarzenia (events)
kubectl describe deployment nginx-preferred -n cwiczenia
```

---

## Ćwiczenie 3.3: Pod Anti-Affinity

**Zadanie:** Utwórz Deployment `nginx-distributed` z 5 replikami (obraz `nginx:latest`), który używa `requiredDuringSchedulingIgnoredDuringExecution` podAntiAffinity, aby zapewnić, że każdy Pod jest uruchomiony na innym nodzie (rozkład Podów między nodami).

> **Uwaga:** Jeśli masz mniej niż 5 nodów w klastrze, niektóre Pody mogą pozostać w stanie Pending, ponieważ anti-affinity wymaga, aby każdy Pod był na innym nodzie. W takim przypadku możesz zmniejszyć liczbę replik do liczby nodów w klastrze.

**Wskazówki:**
- Sprawdź liczbę nodów: `kubectl get nodes`
- `topologyKey: kubernetes.io/hostname` - różne nody (hostname jest unikalny dla każdego noda)
- `labelSelector` - wybierz Pody tego samego Deployment
- Anti-affinity zapobiega umieszczaniu Podów razem

**Cel:** Zrozumienie zapewniania wysokiej dostępności przez rozkład Podów między nodami.

**Weryfikacja:**
```bash
# Sprawdź Deployment
kubectl get deployment nginx-distributed -n cwiczenia

# Sprawdź Pody i nody (każdy Pod powinien być na innym nodzie)
kubectl get pods -n cwiczenia -l app=nginx-distributed -o wide

# Sprawdź ile Podów jest na każdym nodzie
kubectl get pods -n cwiczenia -l app=nginx-distributed -o wide | awk '{print $7}' | sort | uniq -c
```

---

## Podsumowanie

Po wykonaniu ćwiczeń z Affinity i Anti-affinity powinieneś:
- ✅ Rozumieć nodeAffinity - wymagane i preferowane umieszczanie Podów
- ✅ Rozumieć podAntiAffinity - rozkład Podów między nodami
- ✅ Umieć używać Affinity do zapewnienia wysokiej dostępności

## Przydatne komendy

```bash
# Sprawdzanie nodów i etykiet
kubectl get nodes --show-labels
kubectl label nodes <node-name> <key>=<value>
kubectl label nodes <node-name> <key>-

# Sprawdzanie Podów i ich umieszczenia
kubectl get pods -o wide -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
```

