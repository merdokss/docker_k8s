# Jak działają wiele Network Policy jednocześnie?

## 🔑 Kluczowe zasady działania Network Policy

### 1. **Logika OR (addytywna)**
Network Policy działają **addytywnie** - jeśli pod jest objęty przez wiele polityk, ruch jest **dozwolony gdy KTÓRAKOLWIEK z nich go pozwala**.

### 2. **Selektory podów określają zakres**
Każda polityka ma `podSelector`, który określa do jakich podów się odnosi.

### 3. **Brak możliwości blokowania**
Network Policy **nie mają logiki DENY**, tylko **ALLOW**. Nie można zablokować tego, co inna polityka już dozwoliła.

---

## 📊 Reguły podstawowe

| Sytuacja | Zachowanie |
|----------|------------|
| Brak polityki dla poda | ✅ Wszystko dozwolone |
| Jedna polityka dla poda | ❌ Default deny (dozwolone tylko to co w polityce) |
| Wiele polityk dla poda | ✅ Dozwolone to co KTÓRAKOLWIEK polityka zezwala (OR) |

---

## 📋 Przykład: Dwie Network Policy w namespace `default`

### **Polityka 1: `allow-same-namespace`**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-same-namespace
  namespace: default
spec:
  podSelector: {}  # <-- WSZYSTKIE pody w namespace default
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector: {}  # <-- Ruch z podów w tym samym namespace
  egress:
  - ports:
    - port: 53
      protocol: UDP
    - port: 53
      protocol: TCP
    to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
  - to:
    - podSelector: {}
```

**Dotyczy:** WSZYSTKICH podów w namespace `default`  
**Pozwala na Ingress:** Ruch z innych podów w namespace `default`  
**Pozwala na Egress:** DNS (kube-system) + ruch do innych podów w namespace `default`

---

### **Polityka 2: `allow-ingress-controller`**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-controller
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: nginx-demo  # <-- TYLKO pody z tym labelem
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: app-routing-system
    ports:
    - protocol: TCP
      port: 80
```

**Dotyczy:** TYLKO podów z labelem `app: nginx-demo`  
**Pozwala na Ingress:** Ruch z namespace `app-routing-system` na port 80

---

## 🎯 Jak to działa razem dla podów nginx-demo?

Pody `nginx-demo` są objęte **OBIEMA** politykami, więc mogą przyjmować ruch z:

1. ✅ **Z namespace `default`** (dzięki `allow-same-namespace`)
2. ✅ **Z namespace `app-routing-system`** (dzięki `allow-ingress-controller`)

### Logika OR:
```
Dozwolony ruch = (Polityka 1) OR (Polityka 2)
```

### Wizualizacja:

```
┌─────────────────────────────────────────────────┐
│  Pod: nginx-demo (app=nginx-demo)               │
├─────────────────────────────────────────────────┤
│  Objęty przez 2 polityki:                       │
│                                                  │
│  1️⃣  allow-same-namespace                       │
│      ├─ podSelector: {} (wszystkie pody)        │
│      └─ Ingress FROM: namespace default ✅      │
│                                                  │
│  2️⃣  allow-ingress-controller                  │
│      ├─ podSelector: app=nginx-demo             │
│      └─ Ingress FROM: app-routing-system ✅     │
│                                                  │
│  Dozwolony ruch = Polityka 1 OR Polityka 2      │
│  ✅ namespace: default                           │
│  ✅ namespace: app-routing-system                │
│  ❌ namespace: test (brak reguły)                │
└─────────────────────────────────────────────────┘
```

---

## 🧪 Testy praktyczne

### Test 1: Ruch z tego samego namespace (default)
```bash
kubectl run test-pod --image=nginx:alpine --rm -it --restart=Never -- \
  sh -c "curl -s -o /dev/null -w '%{http_code}' http://nginx-demo-service"
```

**Wynik:** `200` ✅  
**Powód:** Polityka `allow-same-namespace` pozwala na ruch między podami w namespace `default`

---

### Test 2: Ruch z innego namespace (test)
```bash
kubectl run test-pod -n test --image=nginx:alpine --rm -it --restart=Never -- \
  sh -c "curl -s -m 5 -o /dev/null -w '%{http_code}' http://nginx-demo-service.default"
```

**Wynik:** `000` (TIMEOUT) ❌  
**Powód:** Brak polityki pozwalającej na ruch z namespace `test`

---

### Test 3: Ruch z Ingress Controller (app-routing-system)
```bash
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://todos.local
```

**Wynik:** `200` ✅  
**Powód:** Polityka `allow-ingress-controller` pozwala na ruch z namespace `app-routing-system`

---

## 📊 Tabela wyników testów

| Źródło ruchu | Namespace źródłowy | Namespace docelowy | Wynik | Która polityka? |
|--------------|-------------------|-------------------|-------|-----------------|
| Pod w default | `default` | `default` | ✅ **200 OK** | `allow-same-namespace` |
| Pod w test | `test` | `default` | ❌ **TIMEOUT** | Brak polityki |
| Ingress Controller | `app-routing-system` | `default` | ✅ **200 OK** | `allow-ingress-controller` |

---

## 💡 Praktyczne wnioski

### ✅ Co jest możliwe:
1. **Network Policy są addytywne** - więcej polityk = więcej dozwolonych połączeń
2. **Każda polityka działa niezależnie** - nie mogą się wzajemnie blokować
3. **Selektory podów mogą się nakładać** - jeden pod może być objęty wieloma politykami
4. **Wystarczy jedna pasująca reguła** - aby ruch został dozwolony

### ❌ Co NIE jest możliwe:
1. **Nie można zablokować tego co inna polityka dozwala** - brak logiki DENY
2. **Nie można nadpisać reguł innej polityki** - działają niezależnie
3. **Nie można "wyłączyć" polityki dla konkretnego poda** - działa dla wszystkich pasujących

---

## 🔍 Sprawdzanie aktywnych Network Policy

### Lista polityk w namespace:
```bash
kubectl get networkpolicy -n default
```

### Szczegóły konkretnej polityki:
```bash
kubectl describe networkpolicy allow-ingress-controller -n default
```

### Pełna konfiguracja YAML:
```bash
kubectl get networkpolicy -n default -o yaml
```

---

## 🎓 Best Practices

### 1. **Używaj konkretnych selektorów**
Zamiast `podSelector: {}` dla wszystkich podów, używaj labelów:
```yaml
podSelector:
  matchLabels:
    app: my-app
    tier: frontend
```

### 2. **Dokumentuj polityki**
Dodawaj annotations wyjaśniające cel:
```yaml
metadata:
  annotations:
    description: "Pozwala ingress controllerowi na dostęp do podów nginx"
```

### 3. **Testuj po każdej zmianie**
Po dodaniu nowej polityki, przetestuj wszystkie scenariusze ruchu.

### 4. **Stosuj zasadę najmniejszych uprawnień**
Dozwalaj tylko na niezbędny ruch, np. konkretne porty:
```yaml
ports:
- protocol: TCP
  port: 80
```

### 5. **Organizuj polityki logicznie**
- Osobne polityki dla różnych źródeł ruchu
- Osobne polityki dla różnych aplikacji
- Unikaj jednej wielkiej polityki "do wszystkiego"

---

## 🚨 Typowe problemy

### Problem 1: Ingress Controller nie może połączyć się z podami
**Objaw:** 504 Gateway Timeout  
**Przyczyna:** Network Policy blokuje ruch z innego namespace  
**Rozwiązanie:** Dodaj politykę pozwalającą na ruch z namespace ingress controllera

### Problem 2: DNS nie działa w podach
**Objaw:** Cannot resolve hostname  
**Przyczyna:** Brak reguły egress do kube-system (DNS)  
**Rozwiązanie:** Dodaj egress do namespace kube-system na porty 53/UDP i 53/TCP

### Problem 3: Pod nie może połączyć się z API Server
**Objaw:** Connection refused do kubernetes.default  
**Przyczyna:** Brak reguły egress do API Server  
**Rozwiązanie:** Dodaj odpowiednią regułę egress
