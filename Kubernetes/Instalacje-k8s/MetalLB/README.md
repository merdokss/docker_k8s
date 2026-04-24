# MetalLB – Load Balancer dla Kubernetes Bare-Metal

MetalLB to implementacja równoważnika obciążenia (load balancer) przeznaczona dla klastrów Kubernetes działających na infrastrukturze **bare-metal** lub lokalnych środowiskach (Kind, Minikube, K3s), gdzie brakuje natywnego wsparcia dla usług typu `LoadBalancer`.

---

## 🗂️ Spis treści

1. [Co to jest MetalLB?](#co-to-jest-metallb)
2. [Do czego służy?](#do-czego-służy)
3. [Wymagania](#wymagania)
4. [Tryby działania](#tryby-działania)
5. [Instalacja](#instalacja)
6. [Skąd wziąć adresy IP do puli?](#skąd-wziąć-adresy-ip-do-puli)
7. [Konfiguracja](#konfiguracja)
8. [Przykłady użycia](#przykłady-użycia)
9. [Rozwiązywanie problemów](#rozwiązywanie-problemów)
10. [Porównanie z alternatywami](#porównanie-z-alternatywami)

---

## Co to jest MetalLB?

MetalLB to **open-source'owy load balancer** dla Kubernetes, który umożliwia przypisywanie zewnętrznych adresów IP do usług typu `LoadBalancer` w środowiskach, gdzie nie ma natywnego wsparcia dostawcy chmurowego (AWS ELB, Azure Load Balancer, GCP Load Balancer).

### Kluczowe cechy:

- ✅ **Darmowy i open-source** – bez licencji komercyjnych
- ✅ **Lekki** – minimalne zużycie zasobów
- ✅ **Elastyczny** – dwa tryby działania (Layer 2 i BGP)
- ✅ **Natywna integracja** – używa standardowych protokołów sieciowych
- ✅ **CRD-based** – konfiguracja przez Custom Resource Definitions (od wersji 0.13+)

---

## Do czego służy?

### Problem bez MetalLB

W klastrach Kubernetes na bare-metal lub lokalnych środowiskach:

```bash
kubectl get svc
NAME         TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
nginx-svc    LoadBalancer   10.96.123.45    <pending>     80:30001/TCP   5m
```

Usługa typu `LoadBalancer` pozostaje w stanie **`<pending>`** – nie otrzymuje zewnętrznego adresu IP.

### Rozwiązanie z MetalLB

Po zainstalowaniu MetalLB:

```bash
kubectl get svc
NAME         TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)        AGE
nginx-svc    LoadBalancer   10.96.123.45    192.168.1.100  80:30001/TCP   5m
```

Usługa otrzymuje **rzeczywisty zewnętrzny adres IP** z puli zdefiniowanej w MetalLB.

### Główne zastosowania:

| Zastosowanie | Opis |
|--------------|------|
| **Bare-metal Kubernetes** | Klastry na fizycznych serwerach bez wsparcia chmurowego |
| **Lokalne środowiska dev/test** | Kind, Minikube, K3s, Kubeadm |
| **Hybrid cloud** | Klastry łączące bare-metal z chmurą |
| **Edge computing** | Wdrożenia na brzegu sieci |
| **On-premises** | Lokalne centra danych |

---

## Wymagania

| Składnik | Wymaganie | Uwaga |
|----------|-----------|-------|
| **Kubernetes** | ≥ 1.13.0 | Zalecana wersja ≥ 1.24+ |
| **CNI Plugin** | Kompatybilny z MetalLB | Flannel, Calico, Cilium, Weave Net |
| **Adresy IP** | Zakres wolnych adresów IPv4 | Do przypisania usługom LoadBalancer |
| **Porty (Layer 2)** | 7946 TCP/UDP | Między węzłami dla Serf |
| **Routery (BGP)** | Obsługa protokołu BGP | Tylko dla trybu BGP |
| **RBAC** | Włączone | MetalLB wymaga uprawnień |

### Niezgodne CNI:

- ❌ **Kubenet** – brak wsparcia
- ❌ **Docker bridge** – konflikty z ARP
- ⚠️ **Weave** – wymaga dodatkowej konfiguracji

---

## Tryby działania

MetalLB oferuje **dwa tryby działania**, różniące się mechanizmem ogłaszania adresów IP w sieci.

### Porównanie trybów

| Cecha | Layer 2 (L2) | BGP |
|------|--------------|-----|
| **Złożoność konfiguracji** | ⭐ Prosta | ⭐⭐⭐ Zaawansowana |
| **Wymagania sprzętowe** | Brak specjalnego sprzętu | Routery z BGP |
| **Równoważenie obciążenia** | ❌ Single point (jeden węzeł) | ✅ Prawdziwe LB między węzłami |
| **Failover** | ⚠️ ~10 sekund (ARP timeout) | ✅ Szybki (BGP convergence) |
| **Skalowalność** | ⚠️ Ograniczona | ✅ Wysoka |
| **Protokół** | ARP (IPv4) / NDP (IPv6) | BGP (Border Gateway Protocol) |
| **Przypadek użycia** | Małe/średnie klastry, dev/test | Produkcja, duże środowiska |
| **Koszt** | Darmowy | Wymaga routerów BGP |

### Tryb Layer 2 (L2)

**Na czym polega "Layer 2"?**

Layer 2 odnosi się do warstwy łącza danych w modelu OSI — MetalLB działa na poziomie protokołu **ARP** (Address Resolution Protocol), który mapuje adresy IP na adresy MAC w obrębie jednej sieci lokalnej. Nie wymaga routerów ze specjalnymi możliwościami — wystarcza zwykły switch lub router domowy.

**Jak działa krok po kroku:**

```
Klient chce połączyć się z 192.168.1.245 (External IP usługi)
         │
         ▼
[Klient wysyła ARP broadcast]
"Kto ma adres 192.168.1.245? Podaj mi swój MAC!"
         │
         ▼
[MetalLB speaker na węźle "leader" odpowiada]
"To ja! Mój MAC to aa:bb:cc:dd:ee:ff"
         │
         ▼
[Klient wysyła pakiet na MAC węzła]
         │
         ▼
[Węzeł odbiera pakiet i przekazuje go do odpowiedniego Poda przez kube-proxy]
```

**Kluczowe konsekwencje tego mechanizmu:**
- Adresy IP z puli MetalLB **muszą być w tej samej podsieci** co węzły klastra (ARP działa tylko lokalnie, nie przechodzi przez routery)
- Jeden węzeł ("leader") przejmuje odpowiedzialność za dany adres IP
- Ruch trafia zawsze do jednego węzła — kube-proxy dopiero potem rozdziela go między Pody
- W razie awarii węzła inny speaker przejmuje adres (po ~10 sekundach — tyle trwa wygaśnięcie ARP cache)

**Zalety:**
- ✅ Prosta konfiguracja
- ✅ Brak wymagań sprzętowych
- ✅ Działa z każdym switchem/ruterem
- ✅ Idealny dla dev/test

**Wady:**
- ❌ Single point of failure (jeden węzeł obsługuje ruch)
- ❌ Brak prawdziwego równoważenia obciążenia
- ❌ Failover ~10 sekund (ARP timeout)
- ❌ Ograniczona przepustowość jednego węzła

### Tryb BGP

**Na czym polega tryb BGP?**

BGP (Border Gateway Protocol) to protokół routingu używany w internecie do wymiany informacji o trasach między sieciami. W trybie BGP każdy węzeł klastra ogłasza routerom "znam trasę do tych adresów IP". Router kieruje ruch do **wszystkich węzłów jednocześnie** — to prawdziwe równoważenie obciążenia na poziomie sieci.

**Jak działa krok po kroku:**

```
[Każdy węzeł nawiązuje sesję BGP z routerem]
Węzeł-1: "Mam trasę do 10.0.0.100-200 przez mnie"
Węzeł-2: "Mam trasę do 10.0.0.100-200 przez mnie"
Węzeł-3: "Mam trasę do 10.0.0.100-200 przez mnie"
         │
         ▼
[Router zna 3 trasy do tej samej puli IP]
         │
         ▼
[Klient wysyła pakiet do 10.0.0.150]
         │
         ▼
[Router rozdziela ruch ECMP między węzły-1, węzeł-2, węzeł-3]
```

**Kluczowe konsekwencje:**
- Wymaga routera obsługującego BGP (nie każdy router domowy to potrafi)
- Adresy IP z puli **nie muszą być** w tej samej podsieci co węzły
- Wszystkie węzły aktywnie obsługują ruch równolegle
- Failover jest natychmiastowy (router przestaje używać trasy przez awaryiny węzeł)

**Zalety:**
- ✅ Prawdziwe równoważenie obciążenia
- ✅ Wysoka dostępność (wszystkie węzły aktywne)
- ✅ Szybki failover
- ✅ Skalowalność
- ✅ Kontrola routingu przez polityki BGP

**Wady:**
- ❌ Wymaga routerów z obsługą BGP
- ❌ Złożona konfiguracja
- ❌ Wymaga wiedzy o BGP
- ❌ Może wymagać dodatkowego sprzętu

---

## Instalacja

MetalLB można zainstalować na **trzy sposoby**. Zalecana jest metoda manifestów Kubernetes.

### Metoda 1: Manifesty Kubernetes (Zalecana)

Najprostsza i najbardziej niezawodna metoda.

#### Krok 1: Instalacja MetalLB

```bash
# Pobierz i zastosuj manifesty MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml
```

**Lub dla konkretnej wersji:**

```bash
# Sprawdź najnowszą wersję na GitHub
# https://github.com/metallb/metallb/releases

# Przykład dla wersji 0.15.2
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml
```

#### Krok 2: Sprawdź instalację

```bash
# Sprawdź namespace
kubectl get namespace metallb-system

# Sprawdź pody
kubectl get pods -n metallb-system
# Oczekiwany wynik:
# NAME                          READY   STATUS    RESTARTS   AGE
# controller-xxx                1/1     Running   0          2m
# speaker-xxx                   1/1     Running   0          2m
# speaker-xxx                   1/1     Running   0          2m

# Sprawdź CRD
kubectl get crd | grep metallb
# Oczekiwany wynik:
# ipaddresspools.metallb.io
# l2advertisements.metallb.io
# bgppeers.metallb.io
# bgpadvertisements.metallb.io
```

#### Krok 3: Konfiguracja (patrz sekcja [Konfiguracja](#konfiguracja))

---

### Metoda 2: Helm

Dla użytkowników preferujących Helm charts.

#### Krok 1: Dodaj repozytorium Helm

```bash
helm repo add metallb https://metallb.github.io/metallb
helm repo update
```

#### Krok 2: Zainstaluj MetalLB

```bash
# Podstawowa instalacja
helm install metallb metallb/metallb -n metallb-system --create-namespace

# Z wartościami (values.yaml)
helm install metallb metallb/metallb \
  -n metallb-system \
  --create-namespace \
  -f values.yaml
```

#### Przykładowy plik `values.yaml`:

```yaml
controller:
  image:
    repository: quay.io/metallb/controller
    tag: v0.15.2
  resources:
    requests:
      cpu: 100m
      memory: 100Mi
    limits:
      cpu: 100m
      memory: 100Mi

speaker:
  image:
    repository: quay.io/metallb/speaker
    tag: v0.15.2
  resources:
    requests:
      cpu: 100m
      memory: 100Mi
    limits:
      cpu: 100m
      memory: 100Mi
```

#### Krok 3: Sprawdź instalację

```bash
helm list -n metallb-system
kubectl get pods -n metallb-system
```

---

### Metoda 3: Kustomize

Dla zaawansowanych użytkowników korzystających z Kustomize.

#### Utwórz `kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: metallb-system

resources:
  - https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml

# Opcjonalnie: dodaj własne konfiguracje
# configMapGenerator:
#   - name: metallb-config
```

#### Zastosuj:

```bash
kubectl apply -k .
```

---

### Porównanie metod instalacji

| Metoda | Zalety | Wady | Zalecane dla |
|--------|--------|------|--------------|
| **Manifesty** | ✅ Proste, bez zależności<br>✅ Oficjalna metoda<br>✅ Łatwe do debugowania | ⚠️ Ręczna aktualizacja | Wszystkich użytkowników |
| **Helm** | ✅ Łatwe zarządzanie wersjami<br>✅ Parametryzacja<br>✅ Upgrade/downgrade | ⚠️ Wymaga Helm<br>⚠️ Dodatkowa warstwa abstrakcji | Środowisk produkcyjnych z Helm |
| **Kustomize** | ✅ GitOps friendly<br>✅ Łatwe override'y | ⚠️ Wymaga Kustomize<br>⚠️ Mniej popularne | Zaawansowanych użytkowników |

---

## Skąd wziąć adresy IP do puli?

To jedno z pierwszych pytań przy konfiguracji MetalLB. Odpowiedź zależy od trybu i środowiska.

### Zasada dla trybu Layer 2 (najczęstszy przypadek lokalnie)

**Adresy w puli muszą spełniać dwa warunki:**
1. Być w **tej samej podsieci** co węzły Kubernetes (bo ARP działa tylko lokalnie)
2. Być **wolne** — nieprzypisane do żadnego urządzenia ani przez DHCP

```bash
# Krok 1: sprawdź adresy węzłów
kubectl get nodes -o wide
# NAME     STATUS   INTERNAL-IP    ...
# node-1   Ready    192.168.1.10   ← jesteś w sieci 192.168.1.0/24
# node-2   Ready    192.168.1.11

# Krok 2: wybierz zakres z końca tej samej podsieci
# Końcówka zakresu (.240-.250) zazwyczaj jest poza pulą DHCP routera
# → pula MetalLB: 192.168.1.240-192.168.1.250
```

> **Dlaczego końcówka zakresu?** Domowy router domyślnie przydziela DHCP od początku (np. `.100`–`.200`). Końcówka (`.240`–`.250`) jest zazwyczaj wolna. Możesz też jawnie ustawić w routerze "exclusion range" dla adresów MetalLB.

**Przed wdrożeniem sprawdź, czy adresy są rzeczywiście wolne:**

```bash
# Sprawdź czy adres jest zajęty (brak odpowiedzi = wolny)
ping -c 2 192.168.1.245
arp -a | grep 192.168.1.24
```

### Adresy IP dla popularnych środowisk lokalnych

#### Kind

```bash
# Sprawdź podsieć sieci Kind (Docker)
docker network inspect kind | grep Subnet
# "Subnet": "172.18.0.0/16"

# Pula MetalLB dla Kind:
# 172.18.255.200-172.18.255.250
# (górny fragment sieci /16, z dala od adresów węzłów)
```

#### Minikube

```bash
# Sprawdź adres IP Minikube
minikube ip
# 192.168.49.2  ← węzeł jest w sieci 192.168.49.0/24

# Pula MetalLB dla Minikube:
# 192.168.49.100-192.168.49.120
```

#### K3s / kubeadm na VM-ach w sieci domowej

```bash
# Sprawdź adres i maskę węzła
ip addr show eth0
# inet 192.168.1.20/24  ← sieć 192.168.1.0/24

# Pula MetalLB:
# 192.168.1.240-192.168.1.250
```

### Zasada dla trybu BGP

W trybie BGP adresy IP z puli **nie muszą być** w podsieci węzłów — router zna trasę do nich przez BGP. Typowo używa się osobnego zakresu dedykowanego dla usług, np. `10.0.0.100-10.0.0.200`, który router ogłasza dalej do internetu lub sieci firmowej.

---

## Konfiguracja

Po instalacji MetalLB wymaga konfiguracji **puli adresów IP** oraz **trybu ogłaszania** (Layer 2 lub BGP).

### Konfiguracja Layer 2 (L2) – Zalecana dla początkujących

#### Krok 1: Utwórz pulę adresów IP

Utwórz plik `ip-pool.yaml`:

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
    # Zakres adresów IP do przypisania usługom LoadBalancer
    - 192.168.1.240-192.168.1.250
    # Można też podać pojedyncze adresy
    # - 192.168.1.100
    # - 192.168.1.101
  autoAssign: true  # Automatyczne przypisywanie (domyślnie true)
```

#### Krok 2: Utwórz L2Advertisement

Utwórz plik `l2-advertisement.yaml`:

```yaml
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default-l2
  namespace: metallb-system
spec:
  ipAddressPools:
    - default-pool  # Referencja do puli IP
  # Opcjonalnie: ograniczenie do konkretnych węzłów
  # nodeSelectors:
  #   - matchLabels:
  #       kubernetes.io/hostname: node-1
```

#### Krok 3: Zastosuj konfigurację

```bash
kubectl apply -f ip-pool.yaml
kubectl apply -f l2-advertisement.yaml

# Sprawdź status
kubectl get ipaddresspool -n metallb-system
kubectl get l2advertisement -n metallb-system
```

#### Pełny przykład konfiguracji L2

Plik `metallb-config-l2.yaml`:

```yaml
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: production-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.168.1.100-192.168.1.150
  autoAssign: true
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: development-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.168.1.200-192.168.1.210
  autoAssign: true
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: production-l2
  namespace: metallb-system
spec:
  ipAddressPools:
    - production-pool
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: development-l2
  namespace: metallb-system
spec:
  ipAddressPools:
    - development-pool
```

---

### Konfiguracja BGP

#### Krok 1: Utwórz pulę adresów IP

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: bgp-pool
  namespace: metallb-system
spec:
  addresses:
    - 10.0.0.100-10.0.0.200
```

#### Krok 2: Skonfiguruj BGP Peer

Utwórz plik `bgp-peer.yaml`:

```yaml
apiVersion: metallb.io/v1beta1
kind: BGPPeer
metadata:
  name: router-peer
  namespace: metallb-system
spec:
  peerAddress: 192.168.1.1      # Adres routera BGP
  peerASN: 64512                # ASN routera
  myASN: 64513                   # ASN klastra Kubernetes
  # Opcjonalnie: ograniczenie do konkretnych węzłów
  # nodeSelectors:
  #   - matchLabels:
  #       kubernetes.io/hostname: node-1
  # Opcjonalnie: password dla MD5 authentication
  # password: "secret-password"
```

#### Krok 3: Utwórz BGPAdvertisement

```yaml
apiVersion: metallb.io/v1beta1
kind: BGPAdvertisement
metadata:
  name: bgp-advertisement
  namespace: metallb-system
spec:
  ipAddressPools:
    - bgp-pool
  peers:
    - router-peer
  # Opcjonalnie: community BGP
  # communities:
  #   - 64512:100
```

#### Krok 4: Zastosuj konfigurację

```bash
kubectl apply -f ip-pool.yaml
kubectl apply -f bgp-peer.yaml
kubectl apply -f bgp-advertisement.yaml

# Sprawdź status
kubectl get bgppeer -n metallb-system
kubectl get bgpadvertisement -n metallb-system
```

#### Pełny przykład konfiguracji BGP

Plik `metallb-config-bgp.yaml`:

```yaml
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: bgp-pool
  namespace: metallb-system
spec:
  addresses:
    - 10.0.0.100-10.0.0.200
---
apiVersion: metallb.io/v1beta1
kind: BGPPeer
metadata:
  name: router-1
  namespace: metallb-system
spec:
  peerAddress: 192.168.1.1
  peerASN: 64512
  myASN: 64513
---
apiVersion: metallb.io/v1beta1
kind: BGPPeer
metadata:
  name: router-2
  namespace: metallb-system
spec:
  peerAddress: 192.168.1.2
  peerASN: 64512
  myASN: 64513
---
apiVersion: metallb.io/v1beta1
kind: BGPAdvertisement
metadata:
  name: bgp-advertisement
  namespace: metallb-system
spec:
  ipAddressPools:
    - bgp-pool
  peers:
    - router-1
    - router-2
```

---

### Zaawansowane opcje konfiguracji

#### 1. Wiele pul IP z różnymi przeznaczeniami

```yaml
---
# Pula dla aplikacji produkcyjnych
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: prod-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.168.1.100-192.168.1.120
  autoAssign: true
---
# Pula dla aplikacji deweloperskich
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: dev-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.168.1.200-192.168.1.210
  autoAssign: true
---
# Ogłoszenie tylko dla puli produkcyjnej
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: prod-l2
  namespace: metallb-system
spec:
  ipAddressPools:
    - prod-pool
```

#### 2. Przypisanie konkretnej puli do usługi

W definicji Service dodaj adnotację:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app
  annotations:
    metallb.universe.tf/ip-allocated-from-pool: prod-pool
spec:
  type: LoadBalancer
  ports:
    - port: 80
  selector:
    app: my-app
```

#### 3. Ograniczenie do konkretnych węzłów

```yaml
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: node-specific-l2
  namespace: metallb-system
spec:
  ipAddressPools:
    - default-pool
  nodeSelectors:
    - matchLabels:
        node-role.kubernetes.io/worker: ""
    - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
            - node-1
            - node-2
```

#### 4. Wyłączenie automatycznego przypisywania

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: manual-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.168.1.100
  autoAssign: false  # Tylko ręczne przypisanie przez adnotację
```

---

## Przykłady użycia

### Przykład 1: Podstawowa usługa LoadBalancer

```bash
# Utwórz deployment
kubectl create deployment nginx --image=nginx

# Wystaw jako LoadBalancer
kubectl expose deployment nginx \
  --type=LoadBalancer \
  --name=nginx-lb \
  --port=80

# Sprawdź adres IP
kubectl get svc nginx-lb
# NAME       TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)        AGE
# nginx-lb   LoadBalancer   10.96.123.45   192.168.1.240   80:30001/TCP   1m

# Przetestuj dostępność
curl http://192.168.1.240
```

### Przykład 2: Usługa z konkretną pulą IP

Plik `nginx-service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-prod
  annotations:
    metallb.universe.tf/ip-allocated-from-pool: prod-pool
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
  selector:
    app: nginx
```

```bash
kubectl apply -f nginx-service.yaml
kubectl get svc nginx-prod
```

### Przykład 3: Wieloportowa usługa

```yaml
apiVersion: v1
kind: Service
metadata:
  name: multi-port-service
spec:
  type: LoadBalancer
  ports:
    - name: http
      port: 80
      targetPort: 8080
      protocol: TCP
    - name: https
      port: 443
      targetPort: 8443
      protocol: TCP
  selector:
    app: my-app
```

### Przykład 4: Usługa z zewnętrznym IP (bez puli)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: static-ip-service
  annotations:
    metallb.universe.tf/loadBalancerIPs: 192.168.1.100
spec:
  type: LoadBalancer
  ports:
    - port: 80
  selector:
    app: my-app
```

### Przykład 5: Kompletny przykład z deploymentem

Plik `complete-example.yaml`:

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: web-app-lb
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
  selector:
    app: web-app
```

```bash
# Zastosuj
kubectl apply -f complete-example.yaml

# Sprawdź status
kubectl get deployment web-app
kubectl get svc web-app-lb

# Przetestuj
EXTERNAL_IP=$(kubectl get svc web-app-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl http://$EXTERNAL_IP
```

---

## Rozwiązywanie problemów

### Tabela typowych problemów

| Symptom | Przyczyna | Rozwiązanie |
|---------|-----------|-------------|
| Usługa LoadBalancer w stanie `<pending>` | MetalLB nie zainstalowany lub nie skonfigurowany | Zainstaluj MetalLB i skonfiguruj pulę IP |
| `EXTERNAL-IP` pozostaje `<pending>` | Brak dostępnych adresów w puli | Sprawdź `kubectl get ipaddresspool` i zwiększ zakres |
| Pody MetalLB w stanie `CrashLoopBackOff` | Konflikt z CNI lub brak uprawnień | Sprawdź logi: `kubectl logs -n metallb-system -l app=metallb` |
| Adres IP przypisany, ale brak dostępu | Firewall lub routing | Sprawdź firewall, routing i ARP: `arp -a \| grep <IP>` |
| BGP nie działa | Nieprawidłowa konfiguracja BGP | Sprawdź `kubectl get bgppeer` i logi speakera |
| Duplikacja adresów IP | Konflikt z innymi usługami | Sprawdź czy IP nie jest używany: `ping <IP>` |

### Komendy diagnostyczne

```bash
# Sprawdź status MetalLB
kubectl get pods -n metallb-system
kubectl get all -n metallb-system

# Sprawdź konfigurację
kubectl get ipaddresspool -n metallb-system -o yaml
kubectl get l2advertisement -n metallb-system -o yaml
kubectl get bgppeer -n metallb-system -o yaml

# Sprawdź logi
kubectl logs -n metallb-system -l app=metallb-controller
kubectl logs -n metallb-system -l app=metallb-speaker

# Sprawdź events
kubectl get events -n metallb-system --sort-by='.lastTimestamp'

# Sprawdź szczegóły usługi
kubectl describe svc <service-name>

# Sprawdź ARP (dla Layer 2)
arp -a | grep <EXTERNAL-IP>

# Sprawdź routing (dla BGP)
# Na routerze BGP:
# show ip bgp neighbors
# show ip bgp routes
```

### Debugowanie Layer 2

```bash
# Sprawdź który węzeł odpowiada za adres IP
kubectl get nodes -o wide
kubectl logs -n metallb-system -l app=metallb-speaker | grep <EXTERNAL-IP>

# Sprawdź ARP na hoście
arp -a | grep <EXTERNAL-IP>

# Test ping
ping <EXTERNAL-IP>

# Sprawdź porty Serf (7946)
netstat -tuln | grep 7946
```

### Debugowanie BGP

```bash
# Sprawdź status sesji BGP
kubectl logs -n metallb-system -l app=metallb-speaker | grep BGP

# Na routerze sprawdź sesje BGP
# show ip bgp neighbors
# show ip bgp summary

# Sprawdź ogłoszone prefiksy
# show ip bgp routes advertised-to <neighbor>
```

### Częste błędy i rozwiązania

#### Błąd: "no available IPs"

```bash
# Sprawdź dostępne adresy
kubectl get ipaddresspool -n metallb-system -o yaml

# Zwiększ zakres adresów w puli
kubectl edit ipaddresspool default-pool -n metallb-system
```

#### Błąd: "address already in use"

```bash
# Sprawdź czy IP nie jest używany
ping <IP>
arp -a | grep <IP>

# Zmień zakres w puli na wolne adresy
```

#### Błąd: "speaker pod not ready"

```bash
# Sprawdź logi
kubectl logs -n metallb-system -l app=metallb-speaker

# Sprawdź uprawnienia
kubectl get clusterrolebinding | grep metallb
kubectl get rolebinding -n metallb-system
```

#### Błąd: "BGP session not established"

```bash
# Sprawdź konfigurację BGP
kubectl get bgppeer -n metallb-system -o yaml

# Sprawdź connectivity do routera
kubectl exec -n metallb-system <speaker-pod> -- ping <router-ip>

# Sprawdź ASN i password
kubectl describe bgppeer <peer-name> -n metallb-system
```

---

## Porównanie z alternatywami

### MetalLB vs inne rozwiązania

| Rozwiązanie | Typ | Zalety | Wady | Przypadek użycia |
|-------------|-----|--------|------|-------------------|
| **MetalLB** | Load Balancer | ✅ Open-source<br>✅ Prosty (L2)<br>✅ Elastyczny (L2/BGP)<br>✅ Lekki | ⚠️ L2: single point<br>⚠️ BGP: wymaga routerów | Bare-metal, lokalne środowiska |
| **NodePort** | Service Type | ✅ Wbudowany w K8s<br>✅ Brak instalacji | ❌ Wysokie porty (30000+)<br>❌ Brak prawdziwego LB<br>❌ Trudne zarządzanie | Dev/test, szybkie prototypy |
| **Ingress Controller** | Ingress | ✅ HTTP/HTTPS routing<br>✅ SSL termination<br>✅ Path-based routing | ❌ Tylko HTTP/HTTPS<br>❌ Wymaga dodatkowej konfiguracji | Aplikacje web, API |
| **Cloud Load Balancer** | Managed Service | ✅ Zarządzany<br>✅ Wysoka dostępność<br>✅ Auto-scaling | ❌ Koszt<br>❌ Vendor lock-in<br>❌ Nie działa on-prem | Chmura publiczna |
| **Keepalived + HAProxy** | Custom Solution | ✅ Pełna kontrola<br>✅ Sprawdzone rozwiązanie | ❌ Złożona konfiguracja<br>❌ Wymaga zarządzania<br>❌ Nie natywne dla K8s | Zaawansowane wymagania |

### Kiedy używać MetalLB?

| Scenariusz | Zalecane rozwiązanie |
|------------|----------------------|
| **Bare-metal Kubernetes** | ✅ MetalLB (Layer 2 lub BGP) |
| **Kind/Minikube dev** | ✅ MetalLB (Layer 2) |
| **On-premises production** | ✅ MetalLB (BGP) lub Ingress + MetalLB |
| **Cloud Kubernetes** | ❌ Użyj natywnego Load Balancer |
| **Tylko HTTP/HTTPS** | ⚠️ Rozważ Ingress Controller |
| **Szybki prototyp** | ⚠️ NodePort może wystarczyć |

---

## Dodatkowe zasoby

### Oficjalna dokumentacja

- **Strona główna**: https://metallb.io/
- **GitHub**: https://github.com/metallb/metallb
- **Instalacja**: https://metallb.io/installation/
- **Konfiguracja**: https://metallb.io/configuration/
- **Layer 2**: https://metallb.io/concepts/layer2/
- **BGP**: https://metallb.io/concepts/bgp/

### Przydatne komendy

```bash
# Aktualizacja MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml

# Usunięcie MetalLB
kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml

# Sprawdź wersję
kubectl get deployment -n metallb-system controller -o jsonpath='{.spec.template.spec.containers[0].image}'

# Eksport konfiguracji
kubectl get ipaddresspool,l2advertisement,bgppeer,bgpadvertisement -n metallb-system -o yaml > metallb-backup.yaml
```

---

## Podsumowanie

MetalLB to **niezbędne narzędzie** dla klastrów Kubernetes działających na infrastrukturze bare-metal lub lokalnych środowiskach. Umożliwia pełne wykorzystanie usług typu `LoadBalancer` bez konieczności korzystania z chmurowych dostawców.

**Kluczowe punkty:**
- ✅ **Layer 2** – prosty, idealny dla dev/test i małych środowisk
- ✅ **BGP** – zaawansowany, dla produkcji z prawdziwym równoważeniem obciążenia
- ✅ **CRD-based** – nowoczesna konfiguracja przez Custom Resources
- ✅ **Elastyczny** – wiele pul IP, różne tryby, zaawansowane opcje

**Zalecany workflow:**
1. Zainstaluj MetalLB przez manifesty
2. Skonfiguruj pulę IP (Layer 2 dla początkujących)
3. Utwórz usługę typu LoadBalancer
4. Przetestuj dostępność
5. Rozważ BGP dla środowisk produkcyjnych

