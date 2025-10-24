# Jak sprawdzić blokowania przez Network Policy w Azure AKS

## 📋 Spis treści
1. [Wprowadzenie](#wprowadzenie)
2. [Podstawowe informacje](#podstawowe-informacje)
3. [Metody sprawdzania](#metody-sprawdzania)
4. [Praktyczne przykłady](#praktyczne-przykłady)
5. [Interpretacja wyników](#interpretacja-wyników)
6. [Troubleshooting](#troubleshooting)

---

## Wprowadzenie

Azure AKS używa **Azure Network Policy Manager (NPM)** do implementacji Network Policies. NPM działa jako DaemonSet w namespace `kube-system` i zarządza regułami iptables na każdym node.

### ⚠️ Ważne informacje:
- Azure NPM **nie loguje** zablokowanych pakietów w domyślnej konfiguracji
- Logi Azure NPM pokazują tylko operacje na regułach (tworzenie/usuwanie policy)
- Musisz sprawdzać **liczniki iptables**, aby zobaczyć rzeczywiste blokowania
- Każdy node ma własne liczniki

---

## Podstawowe informacje

### Sprawdzenie czy Azure NPM działa

```bash
# Sprawdź pod'y Azure NPM
kubectl get pods -n kube-system -l k8s-app=azure-npm

# Sprawdź logi Azure NPM (tylko operacje na regułach)
kubectl logs -n kube-system -l k8s-app=azure-npm --tail=50
```

### Sprawdzenie aktywnych Network Policies

```bash
# Wszystkie Network Policies w klastrze
kubectl get networkpolicies -A

# Szczegóły konkretnej policy
kubectl describe networkpolicy <nazwa> -n <namespace>
```

---

## Metody sprawdzania

### 🎯 Metoda 1: Sprawdzenie liczników iptables (NAJLEPSZA!)

To jest **główny sposób** sprawdzenia czy Network Policy blokuje ruch.

#### Ruch przychodzący (INGRESS):
```bash
# Sprawdź DROP dla ruchu przychodzącego
kubectl exec -n kube-system <azure-npm-pod> -- \
  iptables -L AZURE-NPM-INGRESS -n -v | grep DROP
```

**Przykładowy wynik:**
```
 3332  181K DROP  0  --  *  *  0.0.0.0/0  0.0.0.0/0  mark match 0x400/0x400
 ^^^^  ^^^^
 |     |
 |     +--- Zablokowane bajty
 +--------- Zablokowane pakiety
```

#### Ruch wychodzący (EGRESS):
```bash
# Sprawdź DROP dla ruchu wychodzącego
kubectl exec -n kube-system <azure-npm-pod> -- \
  iptables -L AZURE-NPM-EGRESS -n -v | grep DROP
```

#### Wszystkie reguły INGRESS z licznikami:
```bash
# Pełny widok wszystkich reguł INGRESS
kubectl exec -n kube-system <azure-npm-pod> -- \
  iptables -L AZURE-NPM-INGRESS -n -v

# Pełny widok wszystkich reguł EGRESS
kubectl exec -n kube-system <azure-npm-pod> -- \
  iptables -L AZURE-NPM-EGRESS -n -v
```

---

### 🔍 Metoda 2: Sprawdzenie wszystkich node'ów

Ponieważ Azure NPM działa jako DaemonSet, każdy node ma własne liczniki.

```bash
# 1. Pobierz listę wszystkich Azure NPM pod'ów
kubectl get pods -n kube-system -l k8s-app=azure-npm -o wide

# 2. Sprawdź każdy node osobno
for pod in $(kubectl get pods -n kube-system -l k8s-app=azure-npm -o name); do
  echo "=== $pod ==="
  kubectl exec -n kube-system $pod -- \
    iptables -L AZURE-NPM-INGRESS -n -v 2>/dev/null | grep DROP
done
```

**PowerShell (Windows):**
```powershell
kubectl get pods -n kube-system -l k8s-app=azure-npm -o name | ForEach-Object {
  Write-Host "=== $_ ==="
  kubectl exec -n kube-system $_ -- iptables -L AZURE-NPM-INGRESS -n -v 2>$null | Select-String "DROP"
}
```

---

### 📊 Metoda 3: Monitor w czasie rzeczywistym

Najlepszy sposób na potwierdzenie, że konkretne połączenie jest blokowane.

```bash
# 1. Zapisz obecny stan liczników
echo "=== PRZED TESTEM ==="
kubectl exec -n kube-system <azure-npm-pod> -- \
  iptables -L AZURE-NPM-INGRESS -n -v | grep DROP

# 2. Wykonaj test połączenia (które ma być zablokowane)
kubectl exec -n <namespace> <pod> -- \
  wget -O- --timeout=2 http://service.other-namespace:port

# 3. Sprawdź liczniki ponownie (powinny wzrosnąć!)
echo "=== PO TEŚCIE ==="
kubectl exec -n kube-system <azure-npm-pod> -- \
  iptables -L AZURE-NPM-INGRESS -n -v | grep DROP
```

**Jeśli liczniki wzrosły** = Network Policy zablokowała Twoje połączenie! ✅

---

### 🧪 Metoda 4: Test połączeń

#### Test połączenia wewnątrz namespace (powinno działać):
```bash
kubectl exec -n <namespace> <pod> -- \
  wget -v -O- --timeout=2 http://service-in-same-namespace:port 2>&1
```

#### Test połączenia między namespace'ami (może być zablokowane):
```bash
kubectl exec -n namespace1 <pod> -- \
  wget -v -O- --timeout=2 http://service.namespace2:port 2>&1
```

**Objawy zablokowania:**
- `Connection refused`
- `Connection timed out`
- `wget: can't connect to remote host`
- Timeout po kilku sekundach

---

### 📈 Metoda 5: Zerowanie liczników (dla czystego testu)

**⚠️ UWAGA:** To wpłynie na statystyki całego node!

```bash
# Wyzeruj liczniki iptables
kubectl exec -n kube-system <azure-npm-pod> -- iptables -Z

# Teraz wykonaj testy - liczniki zaczną od 0
```

---

## Praktyczne przykłady

### Przykład 1: Sprawdzenie czy policy blokuje ruch

```bash
# Masz Network Policy:
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-same-namespace
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}  # Tylko z tego samego namespace

# Sprawdź czy blokuje:
# 1. Zobacz aktualny stan
kubectl exec -n kube-system azure-npm-xxxxx -- \
  iptables -L AZURE-NPM-INGRESS -n -v | grep DROP

# Wynik PRZED testem: 100 pakietów zablokowanych

# 2. Test z innego namespace (POWINIEN BYĆ ZABLOKOWANY)
kubectl exec -n staging test-pod -- \
  curl -m 2 http://api.production:3000

# 3. Sprawdź ponownie
kubectl exec -n kube-system azure-npm-xxxxx -- \
  iptables -L AZURE-NPM-INGRESS -n -v | grep DROP

# Wynik PO teście: 101 pakietów zablokowanych (+1!) ✅
```

---

### Przykład 2: Identyfikacja która policy blokuje

```bash
# Sprawdź szczegółowy widok z nazwami policy
kubectl exec -n kube-system azure-npm-xxxxx -- \
  iptables -L AZURE-NPM-INGRESS -n -v | grep -E "pkts|POLICY"

# Wynik pokazuje:
# pkts bytes target  ...  /* INGRESS-POLICY-production/allow-same-namespace-TO-ns-production-IN-ns-production */
# 3332  181K  ...     /* INGRESS-POLICY-staging/deny-all-TO-ns-staging-IN-ns-staging */
```

Reguła z największą liczbą pakietów prawdopodobnie blokuje najwięcej ruchu!

---

### Przykład 3: Debugowanie konkretnego połączenia

```bash
# Masz problem: Frontend nie może połączyć się z Backend

# 1. Sprawdź czy pod'y działają
kubectl get pods -n myapp

# 2. Sprawdź Network Policies
kubectl get networkpolicies -n myapp
kubectl describe networkpolicy -n myapp

# 3. Test połączenia z frontend do backend
kubectl exec -n myapp frontend-pod -- \
  wget -v -O- --timeout=5 http://backend-service:8080/health 2>&1

# 4. Sprawdź liczniki przed i po teście
kubectl exec -n kube-system azure-npm-xxxxx -- \
  iptables -L AZURE-NPM-INGRESS -n -v | grep DROP

# 5. Jeśli licznik wzrósł, sprawdź która policy blokuje
kubectl exec -n kube-system azure-npm-xxxxx -- \
  iptables -L AZURE-NPM-INGRESS -n -v | grep -B2 "ns-myapp"
```

---

## Interpretacja wyników

### Zrozumienie wyjścia iptables

```
 pkts bytes target     prot opt in  out  source       destination
 3332  181K DROP       0    --  *   *    0.0.0.0/0    0.0.0.0/0    mark match 0x400/0x400
```

**Kolumny:**
- `pkts`: **Liczba zablokowanych pakietów** (to główna metryka!)
- `bytes`: Liczba zablokowanych bajtów
- `target`: `DROP` = pakiet został odrzucony
- `mark match 0x400/0x400`: Azure NPM markuje pakiety do zablokowania

### Przykładowe wartości:

| Liczba pakietów | Interpretacja |
|-----------------|---------------|
| 0 | Policy istnieje, ale nic nie blokowała (lub nie ma ruchu) |
| 1-100 | Niewielka liczba prób połączeń zablokowanych |
| 100-1000 | Umiarkowana liczba blokad |
| 1000+ | Dużo ruchu jest blokowane - sprawdź czy to zamierzone! |

---

## Troubleshooting

### Problem: Liczniki są na 0, ale połączenie nie działa

**Możliwe przyczyny:**
1. **Pod docelowy nie działa** - Sprawdź: `kubectl get pods`
2. **Service nie istnieje** - Sprawdź: `kubectl get svc`
3. **DNS nie działa** - Test: `kubectl exec <pod> -- nslookup <service>`
4. **Problem z aplikacją** - Sprawdź logi: `kubectl logs <pod>`
5. **Policy blokuje na innym node** - Sprawdź wszystkie Azure NPM pod'y

---

### Problem: Nie mogę połączyć się do Azure NPM pod'a

```bash
# Sprawdź status pod'ów
kubectl get pods -n kube-system -l k8s-app=azure-npm

# Jeśli są problemy, sprawdź logi
kubectl logs -n kube-system -l k8s-app=azure-npm --tail=100
```

---

### Problem: Chcę włączyć bardziej szczegółowe logowanie

Azure NPM nie wspiera szczegółowego logowania zablokowanych pakietów w iptables.

**Alternatywy:**
1. Użyj liczników iptables (opisane powyżej)
2. Sprawdzaj logi aplikacji (często pokazują connection refused)
3. Użyj tcpdump na node (wymaga dostępu do node)
4. Rozważ migrację na Cilium (ma lepsze możliwości monitorowania)

---

## Skrypt pomocniczy

Zapisz jako `check-netpol-blocks.sh`:

```bash
#!/bin/bash
# Skrypt do sprawdzania blokowania przez Network Policy w Azure AKS

echo "=== Azure Network Policy Manager - Sprawdzanie blokad ==="
echo ""

# Sprawdź czy Azure NPM działa
echo "1. Status Azure NPM pod'ów:"
kubectl get pods -n kube-system -l k8s-app=azure-npm -o wide
echo ""

# Pobierz listę pod'ów
NPM_PODS=$(kubectl get pods -n kube-system -l k8s-app=azure-npm -o jsonpath='{.items[*].metadata.name}')

echo "2. Liczba zablokowanych pakietów na każdym node:"
echo "================================================"

TOTAL_INGRESS=0
TOTAL_EGRESS=0

for pod in $NPM_PODS; do
    echo ""
    echo "Node: $pod"
    echo "---"
    
    # INGRESS
    INGRESS=$(kubectl exec -n kube-system $pod -- iptables -L AZURE-NPM-INGRESS -n -v 2>/dev/null | grep DROP | awk '{print $1}')
    if [ ! -z "$INGRESS" ]; then
        echo "  INGRESS (przychodzące): $INGRESS pakietów"
        TOTAL_INGRESS=$((TOTAL_INGRESS + INGRESS))
    else
        echo "  INGRESS (przychodzące): 0 pakietów"
    fi
    
    # EGRESS
    EGRESS=$(kubectl exec -n kube-system $pod -- iptables -L AZURE-NPM-EGRESS -n -v 2>/dev/null | grep DROP | awk '{print $1}')
    if [ ! -z "$EGRESS" ]; then
        echo "  EGRESS (wychodzące):    $EGRESS pakietów"
        TOTAL_EGRESS=$((TOTAL_EGRESS + EGRESS))
    else
        echo "  EGRESS (wychodzące):    0 pakietów"
    fi
done

echo ""
echo "================================================"
echo "PODSUMOWANIE:"
echo "  Łącznie zablokowanych pakietów INGRESS: $TOTAL_INGRESS"
echo "  Łącznie zablokowanych pakietów EGRESS:  $TOTAL_EGRESS"
echo "  RAZEM:                                   $((TOTAL_INGRESS + TOTAL_EGRESS))"
echo ""

echo "3. Aktywne Network Policies w klastrze:"
kubectl get networkpolicies -A
echo ""

echo "Użycie:"
echo "  - Jeśli liczniki > 0: Network Policies AKTYWNIE blokują ruch"
echo "  - Aby zobaczyć szczegóły: kubectl describe networkpolicy <nazwa> -n <namespace>"
echo "  - Aby testować: kubectl exec -n <ns> <pod> -- wget -O- --timeout=2 http://target:port"
```

**Użycie:**
```bash
chmod +x check-netpol-blocks.sh
./check-netpol-blocks.sh
```

---

## Podsumowanie - Quick Reference

### Szybkie sprawdzenie:
```bash
# 1. Sprawdź czy są blokady (zamień nazwę pod'a)
kubectl exec -n kube-system azure-npm-xxxxx -- \
  iptables -L AZURE-NPM-INGRESS -n -v | grep DROP

# 2. Zobacz aktywne policies
kubectl get networkpolicies -A

# 3. Test połączenia
kubectl exec -n <ns> <pod> -- wget -O- --timeout=2 http://target:port
```

### Interpretacja:
- **Licznik > 0** = Network Policy blokuje ruch ✅
- **Connection refused/timeout** = Prawdopodobnie zablokowane przez policy
- **Licznik = 0** = Sprawdź inne node'y lub przyczyny (DNS, service, pod)

---

## Dodatkowe zasoby

- [Azure AKS Network Policies](https://learn.microsoft.com/en-us/azure/aks/use-network-policies)
- [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Azure NPM GitHub](https://github.com/Azure/azure-container-networking)

---

**Autor:** Wygenerowane automatycznie  
**Data:** 2025-10-24  
**Wersja:** 1.0

