# Kubernetes Network Policy - Kompletny Przewodnik

## Spis treści
1. [Jak działa Network Policy?](#jak-działa-network-policy)
2. [Podstawowe koncepcje](#podstawowe-koncepcje)
3. [Praktyczne przykłady](#praktyczne-przykłady)
4. [Jak dobrze przetestować Network Policy?](#jak-dobrze-przetestować-network-policy)
5. [Namespace i labelki](#namespace-i-labelki)
6. [Dokładna analiza polityki](#dokładna-analiza-polityki)
7. [Najlepsze praktyki](#najlepsze-praktyki)

---

## Jak działa Network Policy?

**Network Policy** to "firewall" wewnątrz klastra Kubernetes. Domyślnie wszystkie pody mogą się ze sobą komunikować - Network Policy pozwala to ograniczyć.

### Prosty model mentalny:
Wyobraź sobie biurowiec:
- **Bez Network Policy**: każdy może chodzić do każdego biura
- **Z Network Policy**: tylko osoby z odpowiednim dostępem mogą wejść do konkretnych pomieszczeń

---

## Podstawowe koncepcje

Network Policy działa na zasadzie **selektorów** i **reguł**:

1. **podSelector** - wybiera, które pody chronisz
2. **Ingress** - kto MOŻE do Ciebie przychodzić (ruch przychodzący)
3. **Egress** - do kogo TY możesz wychodzić (ruch wychodzący)

### Ważne: Domyślne zachowanie
- Jeśli pod NIE ma żadnej Network Policy → wszystko dozwolone
- Jeśli pod MA Network Policy → **domyślnie wszystko zablokowane** (except co wprost zezwolisz)

---

## Praktyczne przykłady

### Przykład 1: Podstawowa polityka

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend  # Chronię pody z labelką app=backend
  
  policyTypes:
  - Ingress
  - Egress
  
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend  # Tylko frontend może się połączyć
    ports:
    - protocol: TCP
      port: 8080
  
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database  # Backend może tylko do bazy
    ports:
    - protocol: TCP
      port: 5432
  - to:  # Zezwól na DNS
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
```

---

## Jak dobrze przetestować Network Policy?

### 1. Przygotowanie środowiska testowego

```bash
# Utwórz namespace testowy
kubectl create namespace netpol-test

# Deploy trzech podów: frontend, backend, database
kubectl run frontend --image=nginx -n netpol-test --labels=app=frontend
kubectl run backend --image=nginx -n netpol-test --labels=app=backend
kubectl run database --image=nginx -n netpol-test --labels=app=database

# Opcjonalnie: testowy pod "hacker"
kubectl run hacker --image=nginx -n netpol-test --labels=app=hacker
```

### 2. Test PRZED zastosowaniem Network Policy

```bash
# Sprawdź, że wszystko może się łączyć (baseline)
kubectl exec -n netpol-test frontend -- curl -m 3 backend
kubectl exec -n netpol-test frontend -- curl -m 3 database
kubectl exec -n netpol-test hacker -- curl -m 3 backend
```

**Oczekiwany wynik**: Wszystkie połączenia powinny działać ✅

### 3. Zastosuj Network Policy

```yaml
# netpol-backend.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
  namespace: netpol-test
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
    ports:
    - protocol: TCP
      port: 80
```

```bash
kubectl apply -f netpol-backend.yaml
```

### 4. Test PO zastosowaniu Network Policy

```bash
# Frontend POWINIEN się połączyć
kubectl exec -n netpol-test frontend -- curl -m 3 backend
# ✅ Powinno działać

# Hacker NIE POWINIEN się połączyć
kubectl exec -n netpol-test hacker -- curl -m 3 backend
# ❌ Powinien timeout

# Database NIE POWINNA się połączyć
kubectl exec -n netpol-test database -- curl -m 3 backend
# ❌ Powinien timeout
```

---

## Narzędzia do testowania

### 1. **netcat/curl w podach**
Najprostszy sposób - jak pokazałem wyżej.

### 2. **netshoot** - szwajcarski scyzoryk
```bash
# Pod z wieloma narzędziami sieciowymi
kubectl run tmp-shell --rm -i --tty \
  --image=nicolaka/netshoot \
  -n netpol-test \
  --labels=app=test \
  -- /bin/bash

# W środku masz: curl, dig, netcat, tcpdump, etc.
```

### 3. **cyclonus** - automatyczne testowanie
```bash
# Narzędzie do automatycznego testowania Network Policies
# https://github.com/mattfenwick/cyclonus

kubectl create ns netpol-test
kubectl apply -f your-netpol.yaml
cyclonus generate --mode walkthrough
```

### 4. **kubectl plugin: kubectl-np-viewer**
```bash
# Wizualizacja Network Policies
kubectl krew install np-viewer
kubectl np-viewer -n netpol-test
```

---

## Checklist testowania

✅ **Przed testem:**
1. Upewnij się, że masz CNI wspierające Network Policy (Calico, Cilium, Weave)
   ```bash
   kubectl get pods -n kube-system | grep -E 'calico|cilium|weave'
   ```

✅ **Co testować:**
1. **Pozytywne przypadki** - czy dozwolony ruch przechodzi
2. **Negatywne przypadki** - czy zablokowany ruch jest faktycznie zablokowany
3. **Namespace isolation** - czy polityki działają między namespace'ami
4. **DNS** - czy nie zablokowałeś DNS (częsty błąd!)
5. **Egress do internetu** - jeśli potrzebny

✅ **Struktura testu:**
```bash
# 1. Stan początkowy (wszystko działa)
# 2. Zastosuj Network Policy
# 3. Test pozytywny (powinno działać)
# 4. Test negatywny (nie powinno działać)
# 5. Sprawdź logi/metryki
```

---

## Częste pułapki

### 🚨 Pułapka 1: Zapomnienie o DNS
```yaml
# Zawsze dodaj egress do DNS!
egress:
- to:
  - namespaceSelector:
      matchLabels:
        name: kube-system
    podSelector:
      matchLabels:
        k8s-app: kube-dns
  ports:
  - protocol: UDP
    port: 53
```

### 🚨 Pułapka 2: Puste podSelector
```yaml
podSelector: {}  # To znaczy: wszystkie pody w namespace!
```

### 🚨 Pułapka 3: CNI nie wspiera Network Policy
```bash
# Sprawdź, czy twoje CNI wspiera:
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.containerRuntimeVersion}'
```

---

## Skrypt do kompleksowego testowania

```bash
#!/bin/bash
# test-netpol.sh

NAMESPACE="netpol-test"

echo "=== Test Network Policy ==="

# Test 1: Frontend -> Backend (POWINNO DZIAŁAĆ)
echo -n "Test 1 (frontend->backend): "
if kubectl exec -n $NAMESPACE frontend -- curl -s -m 3 backend > /dev/null 2>&1; then
    echo "✅ PASS"
else
    echo "❌ FAIL"
fi

# Test 2: Hacker -> Backend (NIE POWINNO DZIAŁAĆ)
echo -n "Test 2 (hacker->backend): "
if kubectl exec -n $NAMESPACE hacker -- curl -s -m 3 backend > /dev/null 2>&1; then
    echo "❌ FAIL (połączenie przeszło, a nie powinno!)"
else
    echo "✅ PASS (timeout jak należy)"
fi

# Test 3: Backend -> Database (sprawdź egress)
echo -n "Test 3 (backend->database): "
if kubectl exec -n $NAMESPACE backend -- curl -s -m 3 database > /dev/null 2>&1; then
    echo "✅ PASS"
else
    echo "❌ FAIL"
fi
```

---

## Namespace i labelki

### Automatyczne labelki namespace

Kubernetes **automatycznie** dodaje labelkę do każdego namespace od wersji 1.21+:

```bash
kubectl describe ns pawel
```

```
Name:         pawel
Labels:       kubernetes.io/metadata.name=pawel  # 👈 AUTOMATYCZNA labelka
Annotations:  <none>
Status:       Active
```

### ⚠️ Problem z automatyczną labelką

Labelka `kubernetes.io/metadata.name` może się zmienić lub być usunięta w przyszłych wersjach K8s. **Lepiej dodać własną labelkę**.

### ✅ REKOMENDACJA: Dodaj własną labelkę

```bash
# Dodaj czytelną, własną labelkę
kubectl label namespace pawel name=pawel

# Albo bardziej opisową
kubectl label namespace pawel env=dev owner=pawel

# Sprawdź
kubectl describe ns pawel
```

**Po dodaniu labelki:**
```bash
Name:         pawel
Labels:       kubernetes.io/metadata.name=pawel
              name=pawel          # 👈 Twoja własna labelka
              env=dev             # 👈 Dodatkowe labelki
              owner=pawel
Annotations:  <none>
Status:       Active
```

### Porównanie: automatyczna vs własna labelka

| Labelka | Przykład | Zalety | Wady |
|---------|----------|--------|------|
| **Automatyczna** | `kubernetes.io/metadata.name=pawel` | Nie musisz dodawać ręcznie | Długa nazwa, może się zmienić w przyszłości |
| **Własna** | `name=pawel` | Czytelna, kontrolowana przez Ciebie | Musisz dodać ręcznie |

---

## Dokładna analiza polityki

### Polityka cross-namespace

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: isolate-pod
  namespace: prod  # 👈 Określ namespace
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    # Reguła 1: api z tego samego namespace
    - podSelector:
        matchLabels:
          app: api
    # Reguła 2: api z namespace staging  
    - namespaceSelector:
        matchLabels:
          name: staging
      podSelector:
        matchLabels:
          app: api
```

### Dokładne wyjaśnienie każdej sekcji:

#### 1️⃣ **Gdzie działa ta polityka?**

```yaml
metadata:
  namespace: prod
```

Ta polityka **istnieje** i **działa TYLKO** w namespace `prod`. Nie ma wpływu na inne namespace.

#### 2️⃣ **Których podów dotyczy?**

```yaml
spec:
  podSelector:
    matchLabels:
      app: database
```

**Tłumaczenie**: "Ta polityka chroni wszystkie pody, które mają labelkę `app=database` w namespace `prod`"

**Przykład**: Jeśli masz:
```bash
# W namespace prod
kubectl run db-1 -n prod --labels=app=database    # ✅ CHRONIONY
kubectl run db-2 -n prod --labels=app=database    # ✅ CHRONIONY
kubectl run api-1 -n prod --labels=app=api        # ❌ NIE CHRONIONY (inna labelka)

# W namespace staging
kubectl run db-3 -n staging --labels=app=database # ❌ NIE CHRONIONY (inny namespace)
```

#### 3️⃣ **Co jest domyślnie zablokowane?**

```yaml
policyTypes:
- Ingress
```

**BARDZO WAŻNE**: Gdy tylko zastosujemy tę politykę, automatycznie:
- ❌ **Cały ruch przychodzący (Ingress) do podów app=database jest ZABLOKOWANY**
- ✅ **Ruch wychodzący (Egress) z podów app=database jest DOZWOLONY** (bo nie ma `policyTypes: Egress`)

```
PRZED zastosowaniem polityki:
[WSZYSCY] ──────────> [database] ✅ Wszystko działa

PO zastosowaniu polityki:
[WSZYSCY] ────X────> [database] ❌ ZABLOKOWANE!
```

#### 4️⃣ **Kto może się połączyć? (Reguły Ingress)**

```yaml
ingress:
- from:
  - podSelector: {...}           # REGUŁA 1
  - namespaceSelector: {...}     # REGUŁA 2
```

**⚠️ KLUCZOWA ZASADA: To jest OR (LUB)!**

**Myśl o tym jak o "białej liście":**
```
Kto może wejść do database?
- Reguła 1 LUB Reguła 2 LUB Reguła 3...
```

---

## REGUŁA 1 - szczegółowo

```yaml
- podSelector:
    matchLabels:
      app: api
```

### Co to znaczy?

**Bez `namespaceSelector`** = automatycznie oznacza **"z tego samego namespace"** (czyli `prod`)

**Pełne tłumaczenie**: 
> "Zezwól na połączenia z podów, które mają labelkę `app=api` i znajdują się w namespace `prod`"

### Przykłady:

| Pod | Namespace | Labelka | Czy może połączyć się z database? | Dlaczego? |
|-----|-----------|---------|-----------------------------------|-----------|
| api-pod-1 | prod | app=api | ✅ **TAK** | Pasuje do Reguły 1 |
| api-pod-2 | prod | app=api | ✅ **TAK** | Pasuje do Reguły 1 |
| api-pod-3 | **staging** | app=api | ❌ NIE (jeszcze...) | Inny namespace (ale patrz Reguła 2!) |
| frontend | prod | app=frontend | ❌ **NIE** | Zła labelka |
| database | prod | app=database | ❌ **NIE** | Database nie może łączyć się sama ze sobą (chyba że dodasz regułę) |

---

## REGUŁA 2 - szczegółowo

```yaml
- namespaceSelector:
    matchLabels:
      name: staging
  podSelector:
    matchLabels:
      app: api
```

### Co to znaczy?

**Oba selektory razem** = **AND** (I)

**Pełne tłumaczenie**:
> "Zezwól na połączenia z podów, które:
> 1. Znajdują się w namespace z labelką `name=staging` **AND**
> 2. Mają labelkę `app=api`"

### ⚠️ Najpierw namespace MUSI mieć labelkę!

```bash
# Sprawdź labelki namespace
kubectl get namespace staging --show-labels

# Jeśli nie ma, dodaj:
kubectl label namespace staging name=staging
```

### Przykłady:

| Pod | Namespace | Labelka poda | Labelka namespace | Czy może? | Dlaczego? |
|-----|-----------|--------------|-------------------|-----------|-----------|
| api-1 | staging | app=api | name=staging | ✅ **TAK** | Pasuje do Reguły 2 (AND spełnione) |
| api-2 | staging | app=frontend | name=staging | ❌ **NIE** | Zła labelka poda |
| api-3 | dev | app=api | name=dev | ❌ **NIE** | Zła labelka namespace |
| api-4 | staging | app=api | (brak labelki) | ❌ **NIE** | Namespace nie ma wymaganej labelki! |

---

## Podsumowanie: Kto MOŻE się połączyć?

Po zastosowaniu polityki, z podem `app=database` w namespace `prod` mogą się połączyć:

### ✅ DOZWOLONE połączenia:

1. **Pody z prod** z labelką `app=api`
   ```
   [api-pod w prod] ──────> [database w prod] ✅
   ```

2. **Pody ze staging** z labelką `app=api` (jeśli namespace staging ma labelkę `name=staging`)
   ```
   [api-pod w staging] ──────> [database w prod] ✅
   ```

### ❌ ZABLOKOWANE połączenia:

1. **Wszystkie inne pody z prod** (bez labelki app=api)
   ```
   [frontend w prod] ────X──> [database w prod] ❌
   ```

2. **Pody z innych namespace** (poza staging)
   ```
   [api-pod w dev] ────X──> [database w prod] ❌
   ```

3. **Zewnętrzne połączenia** (spoza klastra)
   ```
   [Internet] ────X──> [database w prod] ❌
   ```

---

## Wizualizacja końcowa:

```
┌─────────────────────────────────────────────────────┐
│  Namespace: prod                                    │
│                                                     │
│  ┌──────────┐              ┌──────────────┐        │
│  │ api-pod  │─────✅──────>│  database    │        │
│  │ app=api  │              │  app=database│        │
│  └──────────┘              └──────────────┘        │
│                                    ▲                │
│  ┌──────────┐                      │                │
│  │ frontend │────X────────────────┘                │
│  │ app=front│         (BLOCKED)                    │
│  └──────────┘                                       │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│  Namespace: staging (labelka: name=staging)         │
│                                                     │
│  ┌──────────┐                                       │
│  │ api-pod  │─────✅────┐                          │
│  │ app=api  │           │                          │
│  └──────────┘           │                          │
│                         │                          │
│  ┌──────────┐           │                          │
│  │ frontend │────X──────┤ (BLOCKED)                │
│  │ app=front│           │                          │
│  └──────────┘           │                          │
└─────────────────────────┼──────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────┐
│  Namespace: prod                                    │
│              ┌──────────────┐                       │
│              │  database    │                       │
│              │  app=database│                       │
│              └──────────────┘                       │
└─────────────────────────────────────────────────────┘
```

---

## Praktyczny test krok po kroku:

```bash
# ═══════════════════════════════════════════════════
# KROK 1: Przygotowanie
# ═══════════════════════════════════════════════════
kubectl create namespace prod
kubectl create namespace staging

# Dodaj labelkę do namespace staging (WAŻNE!)
kubectl label namespace staging name=staging

# Sprawdź labelki
kubectl get ns staging --show-labels

# ═══════════════════════════════════════════════════
# KROK 2: Deploy podów
# ═══════════════════════════════════════════════════

# Database w prod
kubectl run database -n prod --image=nginx --labels=app=database

# API w prod
kubectl run api-prod -n prod --image=nginx --labels=app=api

# Frontend w prod
kubectl run frontend-prod -n prod --image=nginx --labels=app=frontend

# API w staging
kubectl run api-staging -n staging --image=nginx --labels=app=api

# ═══════════════════════════════════════════════════
# KROK 3: Test PRZED Network Policy (wszystko działa)
# ═══════════════════════════════════════════════════

echo "TEST 1: api-prod -> database"
kubectl exec -n prod api-prod -- curl -s -m 3 database
# ✅ DZIAŁA

echo "TEST 2: frontend-prod -> database"
kubectl exec -n prod frontend-prod -- curl -s -m 3 database
# ✅ DZIAŁA

echo "TEST 3: api-staging -> database"
kubectl exec -n staging api-staging -- curl -s -m 3 database.prod.svc.cluster.local
# ✅ DZIAŁA

# ═══════════════════════════════════════════════════
# KROK 4: Zastosuj Network Policy
# ═══════════════════════════════════════════════════

cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: isolate-pod
  namespace: prod
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
    - namespaceSelector:
        matchLabels:
          name: staging
      podSelector:
        matchLabels:
          app: api
EOF

# ═══════════════════════════════════════════════════
# KROK 5: Test PO Network Policy
# ═══════════════════════════════════════════════════

echo "TEST 1: api-prod -> database (REGUŁA 1)"
kubectl exec -n prod api-prod -- curl -s -m 3 database
# ✅ DZIAŁA (Reguła 1: api z tego samego namespace)

echo "TEST 2: frontend-prod -> database"
kubectl exec -n prod frontend-prod -- curl -s -m 3 database
# ❌ TIMEOUT (brak pasującej reguły)

echo "TEST 3: api-staging -> database (REGUŁA 2)"
kubectl exec -n staging api-staging -- curl -s -m 3 database.prod.svc.cluster.local
# ✅ DZIAŁA (Reguła 2: api z namespace staging)

# ═══════════════════════════════════════════════════
# KROK 6: Sprawdź szczegóły Network Policy
# ═══════════════════════════════════════════════════

kubectl describe networkpolicy isolate-pod -n prod
```

---

## Najlepsze praktyki

### ✅ Dodaj opisowe labelki do namespace:

```bash
# Podstawowa identyfikacja
kubectl label namespace pawel name=pawel

# Środowisko
kubectl label namespace pawel env=dev        # lub prod, staging

# Zespół/właściciel
kubectl label namespace pawel team=backend owner=pawel

# Poziom bezpieczeństwa
kubectl label namespace pawel security=restricted

# Sprawdź wszystkie labelki
kubectl get ns pawel --show-labels
```

### Przykład dobrze oznaczonego namespace:

```bash
Name:         pawel
Labels:       kubernetes.io/metadata.name=pawel
              name=pawel
              env=dev
              team=backend
              owner=pawel
              security=restricted
Annotations:  <none>
Status:       Active
```

---

## Network Policy z wieloma warunkami:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-policy
  namespace: prod
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
  - Ingress
  ingress:
  # Reguła 1: Zezwól z namespace pawel (tylko api)
  - from:
    - namespaceSelector:
        matchLabels:
          name: pawel
      podSelector:
        matchLabels:
          app: api
  
  # Reguła 2: Zezwól ze wszystkich namespace env=dev
  - from:
    - namespaceSelector:
        matchLabels:
          env: dev
      podSelector:
        matchLabels:
          app: api
  
  # Reguła 3: Zezwól z namespace prod (monitoring)
  - from:
    - namespaceSelector:
        matchLabels:
          name: prod
      podSelector:
        matchLabels:
          app: monitoring
```

---

## Częste nieporozumienia:

### ❌ Błąd 1: "Reguły są AND"
```yaml
- from:
  - podSelector: {...}
  - namespaceSelector: {...}
```
To jest **OR**, nie AND!

### ❌ Błąd 2: "namespace automatycznie ma labelki"
Namespace **NIE MA** automatycznie labelek (poza jedną systemową). Musisz je dodać:
```bash
kubectl label namespace staging name=staging
```

### ❌ Błąd 3: Selector wewnątrz jednego `from` vs osobne
```yaml
# To jest AND (namespace staging AND pod app=api)
- from:
  - namespaceSelector:
      matchLabels:
        name: staging
    podSelector:
      matchLabels:
        app: api

# To jest OR (namespace staging LUB pod app=api z tego samego ns)
- from:
  - namespaceSelector:
      matchLabels:
        name: staging
  - podSelector:
      matchLabels:
        app: api
```

---

## Podsumowanie

**Network Policy** = firewall wewnątrz K8s, działający na labelkach

**Dobre testowanie** = zawsze testuj przed i po + pozytywne i negatywne przypadki

**Pamiętaj o DNS** = 90% problemów to zapomnienie o egress do DNS 😊

**Labelki namespace** = zawsze dodawaj własne, proste labelki do namespace

**Reguły ingress** = działają na zasadzie OR (białej listy)

**namespaceSelector + podSelector** = razem działają jako AND
