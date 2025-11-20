# Kubernetes - Ćwiczenia: Network Policy

> **Wprowadzenie:** Te ćwiczenia pomogą Ci zrozumieć Network Policy w Kubernetes. Network Policy kontroluje przepływ ruchu sieciowego między Podami w klastrze.

**Co to jest Network Policy?** Network Policy kontroluje przepływ ruchu sieciowego między Podami w klastrze. Działa jak firewall, określając, które Pody mogą komunikować się ze sobą.

**Ważne:** Network Policy wymaga Network Policy provider (Calico, Weave Net itp.). W wielu klastrach domyślnie wszystkie Pody mogą komunikować się ze sobą (brak restrykcji).

**Sprawdź, czy Twój klaster ma Network Policy provider:**
```bash
kubectl get networkpolicy -A
# Jeśli zwraca błąd lub brak wyników, sprawdź:
kubectl get pods -n kube-system | grep -i calico
kubectl get pods -n kube-system | grep -i weave
```

## Przygotowanie środowiska

```bash
# Utwórz namespace (jeśli jeszcze nie istnieje)
kubectl create namespace cwiczenia

# Sprawdź, czy Network Policy provider jest zainstalowany
kubectl get networkpolicy -A
```

---

## Ćwiczenie 6.1: Podstawowa Network Policy - Deny All

**Zadanie:** Utwórz Network Policy `deny-all` w namespace `cwiczenia`, która blokuje cały ruch przychodzący i wychodzący do/w z Podów z etykietą `app: web`. Następnie utwórz Deployment `web-app` z 2 replikami (obraz `nginx:latest`, etykieta `app: web`). Sprawdź, czy Pody mogą komunikować się z innymi Podami.

**Wskazówki:**
- Network Policy bez reguł blokuje cały ruch
- Dla ruchu przychodzącego: `ingress: []` - brak reguł = blokada
- Dla ruchu wychodzącego: `egress: []` - brak reguł = blokada
- Dla egress: jeśli nie określisz `egress`, domyślnie pozwala na cały ruch wychodzący (zależnie od provider)

**Cel:** Zrozumienie podstawowej konfiguracji Network Policy i efektu "deny all".

**Weryfikacja:**
```bash
# Sprawdź Network Policy
kubectl get networkpolicy deny-all -n cwiczenia
kubectl describe networkpolicy deny-all -n cwiczenia

# Sprawdź Pody
kubectl get pods -n cwiczenia -l app=web -o wide

# Spróbuj połączyć się między Podami (z innego Poda)
kubectl run test-pod --image=busybox:latest --rm -it --restart=Never -n cwiczenia -- wget -O- --timeout=2 <pod-ip>:80 || echo "Połączenie zablokowane"
```

---

## Ćwiczenie 6.2: Network Policy - Zezwól na ruch z określonych Podów

**Zadanie:** Utwórz Deployment `backend` z 2 replikami (obraz `nginx:latest`, etykieta `app: backend`). Utwórz Deployment `frontend` z 2 replikami (obraz `nginx:latest`, etykieta `app: frontend`). Utwórz Network Policy `allow-frontend-to-backend`, która pozwala Pody z etykietą `app: frontend` na komunikację z Podami `app: backend` na porcie 80.

**Wskazówki:**
- `ingress` - ruch przychodzący do Podów `app: backend`
- `from` - źródło (Pody z etykietą `app: frontend`)
- `ports` - dozwolone porty (80)
- Bez Network Policy na frontend, frontend nadal może komunikować się z backend (Network Policy działa tylko dla docelowych Podów)

**Cel:** Zrozumienie kontroli ruchu przychodzącego przez Network Policy.

**Weryfikacja:**
```bash
# Sprawdź Network Policy
kubectl get networkpolicy allow-frontend-to-backend -n cwiczenia

# Sprawdź Pody
kubectl get pods -n cwiczenia -l 'app in (frontend,backend)' -o wide

# Przetestuj połączenie z frontend do backend (powinno działać)
kubectl exec -it <frontend-pod> -n cwiczenia -- wget -O- --timeout=2 <backend-pod-ip>:80

# Przetestuj połączenie z test-pod do backend (powinno być zablokowane)
kubectl run test-pod --image=busybox:latest --rm -it --restart=Never -n cwiczenia -- wget -O- --timeout=2 <backend-pod-ip>:80 || echo "Połączenie zablokowane"
```

---

## Ćwiczenie 6.3: Network Policy - Zezwól na ruch z namespace

**Zadanie:** Utwórz Network Policy `allow-from-namespace` w namespace `cwiczenia`, która pozwala na ruch przychodzący tylko z namespace `monitoring` (zakładając, że istnieje taki namespace lub utwórz go). Utwórz Deployment `monitored-app` z etykietą `app: monitored`. Sprawdź, czy Pody z innych namespace mogą komunikować się z tymi Podami.

**Wskazówki:**
- `namespaceSelector` - wybiera namespace jako źródło
- Możesz użyć etykiet namespace: `matchLabels: {name: monitoring}`
- Namespace domyślnie ma etykietę `name` równą nazwie namespace

**Cel:** Zrozumienie kontroli dostępu na podstawie namespace.

**Weryfikacja:**
```bash
# Utwórz namespace monitoring (jeśli nie istnieje)
kubectl create namespace monitoring

# Sprawdź etykiety namespace
kubectl get namespace monitoring --show-labels

# Sprawdź Network Policy
kubectl get networkpolicy allow-from-namespace -n cwiczenia

# Utwórz Pod w namespace monitoring
kubectl run test-pod --image=busybox:latest --rm -it --restart=Never -n monitoring -- wget -O- --timeout=2 <monitored-app-pod-ip>:80

# Przetestuj z namespace default (powinno być zablokowane)
kubectl run test-pod --image=busybox:latest --rm -it --restart=Never -- wget -O- --timeout=2 <monitored-app-pod-ip>:80 || echo "Połączenie zablokowane"
```

---

## Ćwiczenie 6.4: Network Policy - Egress (ruch wychodzący)

**Zadanie:** Utwórz Network Policy `restrict-egress` w namespace `cwiczenia`, która ogranicza ruch wychodzący z Podów `app: restricted` tylko do:
- DNS (port 53 UDP/TCP)
- HTTPS (port 443 TCP)
- Wewnętrzne Pody w namespace `cwiczenia` na porcie 80

Utwórz Deployment `restricted-app` z etykietą `app: restricted`. Sprawdź, czy Pody mogą komunikować się tylko z dozwolonymi celami.

**Wskazówki:**
- `egress` - kontrola ruchu wychodzącego
- DNS jest potrzebny do rozwiązywania nazw (np. `kubernetes.default.svc.cluster.local`)
- `to` - docelowe Pody (można użyć `podSelector` lub `namespaceSelector`)
- `to` dla DNS: `namespaceSelector: {}` i `podSelector: {}` z portem 53

**Cel:** Zrozumienie kontroli ruchu wychodzącego przez Network Policy.

**Weryfikacja:**
```bash
# Sprawdź Network Policy
kubectl get networkpolicy restrict-egress -n cwiczenia
kubectl describe networkpolicy restrict-egress -n cwiczenia

# Sprawdź Pody
kubectl get pods -n cwiczenia -l app=restricted

# Przetestuj DNS (powinno działać)
kubectl exec -it <restricted-pod> -n cwiczenia -- nslookup kubernetes.default

# Przetestuj HTTPS (powinno działać)
kubectl exec -it <restricted-pod> -n cwiczenia -- wget -O- --timeout=2 https://www.google.com || echo "Sprawdź dostępność"

# Przetestuj HTTP na porcie 80 wewnętrznie (powinno działać do Podów w namespace)
# Przetestuj połączenie z zewnętrznym HTTP (port 80) - powinno być zablokowane
kubectl exec -it <restricted-pod> -n cwiczenia -- wget -O- --timeout=2 http://www.google.com || echo "Połączenie zablokowane (oczekiwane)"
```

---

## Podsumowanie

Po wykonaniu ćwiczeń z Network Policy powinieneś:
- ✅ Rozumieć podstawową konfigurację Network Policy (deny all)
- ✅ Umieć kontrolować ruch przychodzący na podstawie etykiet Podów
- ✅ Umieć kontrolować dostęp na podstawie namespace
- ✅ Rozumieć kontrolę ruchu wychodzącego (egress)

## Przydatne komendy

```bash
# Network Policy
kubectl get networkpolicy -n <namespace>
kubectl describe networkpolicy <name> -n <namespace>
kubectl get networkpolicy -A

# Testowanie połączeń
kubectl exec -it <pod-name> -n <namespace> -- wget -O- --timeout=2 <target-ip>:<port>
kubectl exec -it <pod-name> -n <namespace> -- nslookup <hostname>
```

## Uwagi

- Network Policy wymaga Network Policy provider (Calico, Weave Net itp.)
- Bez provider Network Policy nie zadziała (Pody nadal będą mogły się komunikować)
- W AKS możesz użyć Azure CNI z Network Policy
- W EKS wymaga CNI wspierającego Network Policy

