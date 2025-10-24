# 🚀 Kubernetes Maintenance & Upgrade - Kompletne Podsumowanie


### **Zakres**
- ✅ Zero downtime maintenance
- ✅ Upgrade Control Plane i Worker Nodes
- ✅ Scaling zasobów (vertical & horizontal)
- ✅ Strategie dla różnych środowisk

---

## 💡 Filozofia maintenance w K8s

### **"Cattle, not Pets"**

```
❌ STARE PODEJŚCIE (Pets):          ✅ NOWE PODEJŚCIE (Cattle):
┌────────────────────┐              ┌────────────────────┐
│ Napraw serwer      │              │ Wymień node        │
│ Debuguj problem    │              │ Automatyzuj proces │
│ Ręczna konfiguracja│              │ Infrastructure as Code │
│ Długi downtime     │              │ Zero downtime      │
└────────────────────┘              └────────────────────┘
```

### **Kluczowe zasady:**
1. **Node'y są zastępowalne** - nie naprawiamy, tylko wymieniamy
2. **Automatyzacja first** - wszystko w kodzie (Terraform, Ansible)
3. **Rolling updates** - zawsze po jednym node'ie
4. **Test na non-prod** - nigdy nie eksperymentuj na produkcji
5. **Backup etcd** - zawsze przed upgrade

---

## 🔧 Strategie maintenance klastra

### **Główne strategie**

```
┌────────────────────────────────────────────────────┐
│  1. NODE POOL ROTATION (⭐ Najlepsze)              │
│     Stwórz nowy pool → Migruj → Usuń stary        │
│                                                    │
│  2. ROLLING UPDATE                                 │
│     Node po node: Cordon → Drain → Upgrade        │
│                                                    │
│  3. BLUE-GREEN DEPLOYMENT                          │
│     Dwa pełne środowiska, przełączenie ruchu      │
│                                                    │
│  4. IN-PLACE UPGRADE                               │
│     Upgrade na żywym node (tylko emergency)       │
└────────────────────────────────────────────────────┘
```

---

### **1️⃣ Node Pool Rotation** ⭐ Rekomendowane

**Proces:**

```
KROK 1: Stary pool              KROK 2: Dodaj nowy pool
┌──────────────┐                ┌──────────────┐
│ Node 1 (old) │                │ Node 1 (old) │
│ Node 2 (old) │         +      │ Node 2 (old) │
│ Node 3 (old) │                │ Node 4 (new) │
└──────────────┘                │ Node 5 (new) │
                                └──────────────┘
         ⬇️                              ⬇️
KROK 3: Drain stary             KROK 4: Usuń stary
┌──────────────┐                ┌──────────────┐
│ Node 1 💨    │                │ Node 4 ✅    │
│ Node 2 💨    │                │ Node 5 ✅    │
│ Node 4 ⬆️    │                │ Node 6 ✅    │
│ Node 5 ⬆️    │                └──────────────┘
└──────────────┘
```

**Zalety:**
- ✅ Zero downtime
- ✅ Łatwy rollback (zostaw oba pools)
- ✅ Testowanie przed pełną migracją

**Wady:**
- ❌ Wyższy koszt (2x zasoby przez moment)
- ❌ Więcej kroków

---

### **2️⃣ Rolling Update**

**Podstawowe komendy:**

```bash
# 1. Zablokuj node (nie przyjmuje nowych podów)
kubectl cordon <node-name>

# 2. Ewakuuj wszystkie pody z graceful shutdown
kubectl drain <node-name> \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --grace-period=60

# 3. Wykonaj maintenance/upgrade na node
# (upgrade OS, K8s components, dodaj RAM, etc.)

# 4. Przywróć node do puli
kubectl uncordon <node-name>
```

**Timeline:**

```
Node 1: Cordon → Drain → Upgrade → Uncordon (20 min)
   ⬇️ czekaj 5-10 min, sprawdź stabilność
Node 2: Cordon → Drain → Upgrade → Uncordon (20 min)
   ⬇️ czekaj 5-10 min, sprawdź stabilność
Node 3: Cordon → Drain → Upgrade → Uncordon (20 min)
```

**Zalety:**
- ✅ Niższy koszt (nie potrzebujesz dodatkowych zasobów)
- ✅ Prosty proces

**Wady:**
- ⚠️ Dłuższy czas całkowitego upgrade
- ⚠️ Wymaga wystarczającej capacity na pozostałych nodes

---

### **3️⃣ Blue-Green Deployment**

```
BLUE (produkcja)                GREEN (nowe)
┌───────────────┐              ┌───────────────┐
│ Pool v1.28    │              │ Pool v1.29    │
│ ┌───┐ ┌───┐  │              │ ┌───┐ ┌───┐  │
│ │Pod│ │Pod│  │   Przełącz   │ │Pod│ │Pod│  │
│ └───┘ └───┘  │   ────────>  │ └───┘ └───┘  │
│      ↑        │              │      ↑        │
└──────┼────────┘              └──────┼────────┘
       │                              │
    Ruch produkcyjny          Ruch produkcyjny
```

**Zalety:**
- ✅ Natychmiastowy rollback
- ✅ Pełne testowanie przed przełączeniem
- ✅ Zero downtime

**Wady:**
- ❌ Najwyższy koszt (2x wszystkie zasoby)
- ❌ Złożoność zarządzania

---

## 🎛️ Upgrade Master Nodes (Control Plane)

### **Architektura Control Plane**

```
┌─────────────────────────────────────────┐
│         CONTROL PLANE                   │
├─────────────────────────────────────────┤
│  📡 kube-apiserver                      │
│     └─> API Gateway                     │
│  🧠 kube-controller-manager             │
│     └─> Zarządza kontrolerami          │
│  📅 kube-scheduler                      │
│     └─> Planuje pody na nodes          │
│  💾 etcd                                │
│     └─> Baza klastra (CRITICAL!)       │
└─────────────────────────────────────────┘
```

---

### **On-Premises: Single Master**

```
┌────────────────────────────────────────┐
│  ⚠️ UWAGA: Będzie krótki downtime!    │
│  API Server: ~30-60s niedostępny      │
│  Workloady: Działają normalnie ✅     │
└────────────────────────────────────────┘
```

**Proces upgrade:**

```bash
# ============================================
# FAZA 1: Backup etcd (KLUCZOWE!)
# ============================================
ETCDCTL_API=3 etcdctl snapshot save \
  /backup/etcd-$(date +%Y%m%d-%H%M%S).db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# ============================================
# FAZA 2: Upgrade kubeadm
# ============================================
apt-get update
apt-mark unhold kubeadm
apt-get install -y kubeadm=1.29.0-00
apt-mark hold kubeadm

# Sprawdź plan
kubeadm upgrade plan

# ============================================
# FAZA 3: Upgrade Control Plane
# ⚠️ Ten krok restartuje API Server!
# ============================================
kubeadm upgrade apply v1.29.0

# ============================================
# FAZA 4: Upgrade kubelet
# ============================================
apt-mark unhold kubelet kubectl
apt-get install -y kubelet=1.29.0-00 kubectl=1.29.0-00
apt-mark hold kubelet kubectl

systemctl daemon-reload
systemctl restart kubelet

# ============================================
# FAZA 5: Weryfikacja
# ============================================
kubectl get nodes
kubectl version
```

**Timeline:**

```
┌─────────────────────────────────────────────┐
│ 0-5 min:   Upgrade kubeadm                  │
│ 5-15 min:  Upgrade control plane            │
│            ⚠️ API unavailable: 30-60s       │
│ 15-20 min: Upgrade kubelet                  │
│ 20-25 min: Weryfikacja                      │
└─────────────────────────────────────────────┘
Total: ~25 minut
```

---

### **On-Premises: HA Masters (3 nodes)**

```
                ┌──────────────┐
                │Load Balancer │
                └──────┬───────┘
                       │
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
   ┌────────┐     ┌────────┐    ┌────────┐
   │Master 1│     │Master 2│    │Master 3│
   └────────┘     └────────┘    └────────┘

   ✅ Zero downtime podczas upgrade!
```

**Proces (node po node):**

```bash
# ============================================
# MASTER 1 (pierwszy)
# ============================================
ssh master-1

# Upgrade kubeadm
apt-get update && apt-mark unhold kubeadm
apt-get install -y kubeadm=1.29.0-00
apt-mark hold kubeadm

# Upgrade control plane
# UWAGA: "apply" tylko na pierwszym!
kubeadm upgrade apply v1.29.0

# Upgrade kubelet
apt-mark unhold kubelet kubectl
apt-get install -y kubelet=1.29.0-00 kubectl=1.29.0-00
apt-mark hold kubelet kubectl
systemctl daemon-reload
systemctl restart kubelet

# Czekaj 5-10 minut, sprawdź stabilność!

# ============================================
# MASTER 2 i 3 (kolejne mastery)
# ============================================
ssh master-2  # potem master-3

# Upgrade kubeadm
apt-get update && apt-mark unhold kubeadm
apt-get install -y kubeadm=1.29.0-00
apt-mark hold kubeadm

# Upgrade control plane
# UWAGA: "node" zamiast "apply"!
kubeadm upgrade node

# Upgrade kubelet
apt-mark unhold kubelet kubectl
apt-get install -y kubelet=1.29.0-00 kubectl=1.29.0-00
apt-mark hold kubelet kubectl
systemctl daemon-reload
systemctl restart kubelet
```

**Etcd cluster pozostaje dostępny:**

```
PRZED:          PODCZAS:        PO:
M1: etcd ✅     M1: etcd ✅     M1: etcd ✅
M2: etcd ✅  →  M2: etcd ⚠️  →  M2: etcd ✅
M3: etcd ✅     M3: etcd ✅     M3: etcd ✅

Quorum: 3/3     Quorum: 2/3     Quorum: 3/3
                (wystarczy!)
```

---

### **Azure AKS: Managed Control Plane**

```
┌─────────────────────────────────────────┐
│    AZURE MANAGED CONTROL PLANE          │
│    (nie masz dostępu SSH)               │
├─────────────────────────────────────────┤
│  🔒 Microsoft zarządza:                 │
│     - API Server (HA + Load Balanced)   │
│     - etcd (auto backups)               │
│     - Scheduler + Controller Manager    │
│                                         │
│  ✅ Zawsze HA (99.95% SLA)              │
│  ✅ Zero downtime upgrade               │
│  ✅ Automatyczne backupy                │
└─────────────────────────────────────────┘
```

**Metoda 1: Basic upgrade**

```bash
# Upgrade control plane + wszystkie node pools
az aks upgrade \
  --resource-group my-rg \
  --name my-cluster \
  --kubernetes-version 1.29.0
```

**Metoda 2: Control plane osobno (rekomendowane)**

```bash
# KROK 1: Upgrade tylko control plane
az aks upgrade \
  --resource-group my-rg \
  --name my-cluster \
  --kubernetes-version 1.29.0 \
  --control-plane-only

# ✅ Zero downtime
# ✅ Workloady nie dotknięte
# ⚠️ Version skew: Master v1.29, Nodes v1.28 (OK!)

# KROK 2: Upgrade node pools później (w swoim czasie)
az aks nodepool upgrade \
  --resource-group my-rg \
  --cluster-name my-cluster \
  --name nodepool1 \
  --kubernetes-version 1.29.0
```

**Metoda 3: Blue-Green w AKS**

```bash
# 1. Upgrade control plane
az aks upgrade \
  --resource-group my-rg \
  --name my-cluster \
  --kubernetes-version 1.29.0 \
  --control-plane-only

# 2. Dodaj nowy node pool (green)
az aks nodepool add \
  --resource-group my-rg \
  --cluster-name my-cluster \
  --name greenpool \
  --kubernetes-version 1.29.0 \
  --node-count 3

# 3. Oznacz stary pool jako NoSchedule
kubectl taint nodes -l agentpool=bluepool \
  upgrade=in-progress:NoSchedule

# 4. Drain stary pool (stopniowo)
kubectl drain <node-name> \
  --ignore-daemonsets \
  --delete-emptydir-data

# 5. Usuń stary pool
az aks nodepool delete \
  --resource-group my-rg \
  --cluster-name my-cluster \
  --name bluepool
```

---

## 👷 Upgrade Worker Nodes

### **On-Premises**

```bash
# Dla każdego worker node (po kolei!):

# 1. Cordon
kubectl cordon worker-1

# 2. Drain
kubectl drain worker-1 \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --grace-period=60

# 3. SSH do node i upgrade
ssh worker-1
apt-get update
apt-mark unhold kubeadm kubelet kubectl
apt-get install -y \
  kubeadm=1.29.0-00 \
  kubelet=1.29.0-00 \
  kubectl=1.29.0-00
apt-mark hold kubeadm kubelet kubectl

# 4. Upgrade node config
kubeadm upgrade node

# 5. Restart kubelet
systemctl daemon-reload
systemctl restart kubelet

# 6. Uncordon
kubectl uncordon worker-1

# 7. Weryfikacja
kubectl get nodes
```

---

### **Azure AKS: Max-Surge**

```bash
# Konfiguruj max-surge dla bezpiecznego upgrade
az aks nodepool update \
  --resource-group my-rg \
  --cluster-name my-cluster \
  --name nodepool1 \
  --max-surge 33%

# Upgrade z automatycznym rolling update
az aks nodepool upgrade \
  --resource-group my-rg \
  --cluster-name my-cluster \
  --name nodepool1 \
  --kubernetes-version 1.29.0
```

**Jak działa max-surge:**

```
Masz 3 nodes + max-surge 33% = +1 tymczasowy node

FAZA 1: Dodaj surge node
┌────────────────────────────────────────┐
│ Node 1 (old)  Node 2 (old)  Node 3    │
│                                        │
│            + Node 4-temp (new) ✨      │
│                                        │
│ Capacity: 133%                         │
└────────────────────────────────────────┘

FAZA 2-4: Rolling upgrade każdego node
┌────────────────────────────────────────┐
│ Node 1 💨 drain                        │
│ Node 1 ✨ upgrade                      │
│ Node 2 💨 drain                        │
│ Node 2 ✨ upgrade                      │
│ Node 3 💨 drain                        │
│ Node 3 ✨ upgrade                      │
└────────────────────────────────────────┘

FAZA 5: Usuń surge node
┌────────────────────────────────────────┐
│ Node 1 (new)  Node 2 (new)  Node 3    │
│ Node 4-temp ❌ deleted                 │
└────────────────────────────────────────┘
```

---

## 🛡️ Mechanizmy ochrony przed downtime

### **1. PodDisruptionBudget (PDB)** ⭐ MUST HAVE

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: my-app-pdb
spec:
  minAvailable: 2    # Minimum 2 pody ZAWSZE muszą działać
  selector:
    matchLabels:
      app: my-app
```

**Przykład działania:**

```
BEZ PDB:                        Z PDB:
┌──────────────────┐           ┌──────────────────┐
│ kubectl drain    │           │ kubectl drain    │
│                  │           │                  │
│ Usuwa wszystkie  │           │ Czeka aż będzie  │
│ pody             │           │ bezpiecznie      │
│                  │           │                  │
│ 3 → 0 podów      │           │ 3 → 2 → 3 podów  │
│ ❌ DOWNTIME!     │           │ ✅ Zero DT!      │
└──────────────────┘           └──────────────────┘
```

---

### **2. Readiness & Liveness Probes**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: app
        image: my-app:1.0
        
        # Czy aplikacja żyje?
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        
        # Czy aplikacja gotowa na ruch?
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          periodSeconds: 5
          failureThreshold: 3
```

**Jak to działa podczas drain:**

```
┌────────────────────────────────────────┐
│ 1. kubectl drain node                  │
│    ↓                                   │
│ 2. Pod otrzymuje SIGTERM               │
│    ↓                                   │
│ 3. Readiness probe = false             │
│    ↓                                   │
│ 4. Service przestaje kierować ruch     │
│    ↓                                   │
│ 5. PreStop hook (jeśli jest)           │
│    ↓                                   │
│ 6. Czeka terminationGracePeriod (30s)  │
│    ↓                                   │
│ 7. Aplikacja zamyka się gracefully     │
│    ↓                                   │
│ 8. Pod usunięty                        │
└────────────────────────────────────────┘

✅ Zero utraconych requestów!
```

---

### **3. Graceful Shutdown**

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      terminationGracePeriodSeconds: 60  # Czas na zamknięcie
      
      containers:
      - name: app
        lifecycle:
          preStop:
            exec:
              # Poczekaj 15s na zakończenie requestów
              command: ["/bin/sh", "-c", "sleep 15"]
```

**Timeline shutdown:**

```
0s         15s              60s
│          │                │
▼          ▼                ▼
SIGTERM → PreStop → Graceful → SIGKILL
          hook     shutdown   (force)

           ├────────────────┤
           terminationGrace
           PeriodSeconds
```

---

### **4. Replicas >= 2**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3  # Minimum 2, lepiej 3+
  
  selector:
    matchLabels:
      app: my-app
```

**Dlaczego >= 2?**

```
1 replica:                  3+ replicas:
┌──────────┐               ┌──────────┐
│ Pod 1    │               │ Pod 1    │ ← drain
│ ▼        │               │ Pod 2    │ ← obsługuje ruch
│ Drain    │               │ Pod 3    │ ← obsługuje ruch
│ ❌ DOWN! │               │ ✅ OK!   │
└──────────┘               └──────────┘
```

---

### **5. Anti-Affinity Rules**

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app: my-app
            topologyKey: kubernetes.io/hostname
```

**Co to daje:**

```
BEZ Anti-Affinity:              Z Anti-Affinity:
┌─────────────────────┐         ┌─────────────────────┐
│ Node 1:             │         │ Node 1:             │
│  - Pod 1            │         │  - Pod 1            │
│  - Pod 2            │         │                     │
│  - Pod 3            │         │ Node 2:             │
│                     │         │  - Pod 2            │
│ ❌ Single point     │         │                     │
│    of failure!      │         │ Node 3:             │
│                     │         │  - Pod 3            │
│                     │         │                     │
│                     │         │ ✅ Rozproszone      │
└─────────────────────┘         └─────────────────────┘
```

---

## 📊 Porównanie: On-Premises vs Azure AKS

### **Szybkie porównanie**

| Aspekt | 🏢 On-Premises | ☁️ Azure AKS |
|--------|---------------|-------------|
| **Control Plane downtime** | ⚠️ 30-60s (single)<br>✅ 0s (HA) | ✅ Zawsze 0s |
| **Czas upgrade** | 🔴 1-3h | 🟢 15-30min |
| **Złożoność** | 🔴 Wysoka | 🟢 Niska |
| **Wymagana wiedza** | 🔴 Głęboka | 🟢 Podstawowa |
| **Automatyzacja** | 🟡 Musisz zbudować | ✅ Wbudowana |
| **Rollback** | 🔴 Trudny (etcd restore) | 🟢 Łatwiejszy |
| **Backup etcd** | ⚠️ Musisz sam | ✅ Automatyczny |
| **Kontrola** | 🟢 Pełna | 🟡 Ograniczona |
| **Koszt operacyjny** | 🟡 Czas zespołu | 🟢 Niski |
| **Koszt finansowy** | 🟢 Stały (hardware) | 🔴 Surge = wyższy |
| **Monitoring** | ⚠️ Musisz skonfigurować | ✅ Wbudowany (Azure Monitor) |
| **SLA** | ⚠️ Twoja odpowiedzialność | ✅ 99.95% (uptime SLA) |

---

### **Kiedy wybrać On-Premises?**

✅ **Wybierz On-Prem gdy:**
- Masz wymagania compliance (dane w kraju)
- Masz już infrastrukturę i zespół
- Potrzebujesz pełnej kontroli
- Koszty chmury są zbyt wysokie
- Specyficzne wymagania hardware

❌ **Nie wybieraj On-Prem gdy:**
- Brak doświadczonego zespołu
- Potrzebujesz szybkiego startu
- Chcesz skupić się na aplikacjach, nie infrastrukturze

---

### **Kiedy wybrać Azure AKS?**

✅ **Wybierz AKS gdy:**
- Chcesz szybki start
- Brak zespołu infrastrukturalnego
- Potrzebujesz elastyczności (scale up/down)
- Ważna jest automatyzacja
- Chcesz integracji z Azure services

❌ **Nie wybieraj AKS gdy:**
- Wymagania compliance uniemożliwiają cloud
- Masz już dużą inwestycję w on-prem
- Potrzebujesz specyficznych customizacji control plane

---

## 💡 Best Practices

### **🔐 Bezpieczeństwo**

```
┌─────────────────────────────────────────────┐
│ ✅ BACKUP etcd przed każdym upgrade         │
│ ✅ Test restore na non-prod                 │
│ ✅ Zaszyfruj backupy                        │
│ ✅ Przechowuj backupy w innej lokalizacji   │
│ ✅ Automatyczne backupy (cron/Azure)        │
└─────────────────────────────────────────────┘
```

---

### **🧪 Testowanie**

```
┌─────────────────────────────────────────────┐
│ ✅ ZAWSZE testuj na dev/staging             │
│ ✅ Testuj pełny flow (upgrade + rollback)   │
│ ✅ Load testing po upgrade                  │
│ ✅ Chaos engineering (opcjonalnie)          │
│ ✅ Dokumentuj każdy test                    │
└─────────────────────────────────────────────┘
```

---

### **📋 Planowanie**

```
┌─────────────────────────────────────────────┐
│ ✅ Zaplanuj okno maintenance                │
│ ✅ Komunikuj z zespołem i stakeholders      │
│ ✅ Przygotuj rollback plan                  │
│ ✅ Sprawdź K8s release notes                │
│ ✅ Sprawdź version skew policy              │
│ ✅ Przygotuj runbook (krok po kroku)        │
└─────────────────────────────────────────────┘
```

---

### **🔄 Podczas upgrade**

```
┌─────────────────────────────────────────────┐
│ ✅ Upgrade po kolei (node po node)          │
│ ✅ Czekaj 5-10 min między nodes             │
│ ✅ Monitoruj metryki (CPU, RAM, errors)     │
│ ✅ Sprawdzaj logi aplikacji                 │
│ ✅ Watch kubectl get pods -A                │
│ ✅ Miej zespół on-call gotowy               │
└─────────────────────────────────────────────┘
```

---

### **✅ Po upgrade**

```
┌─────────────────────────────────────────────┐
│ ✅ Weryfikuj wszystkie komponenty           │
│ ✅ Test aplikacji end-to-end                │
│ ✅ Sprawdź metryki przez 24h                │
│ ✅ Nowy backup etcd                         │
│ ✅ Dokumentuj zmiany i incydenty            │
│ ✅ Retrospektywa z zespołem                 │
└─────────────────────────────────────────────┘
```

---

### **📊 Monitoring**

**Kluczowe metryki do obserwacji:**

```yaml
┌─────────────────────────────────────────┐
│ CONTROL PLANE:                          │
│  - API Server response time             │
│  - API Server error rate                │
│  - etcd latency                         │
│  - etcd DB size                         │
│  - Controller Manager lag               │
│  - Scheduler latency                    │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ NODES:                                  │
│  - CPU utilization                      │
│  - Memory utilization                   │
│  - Disk I/O                             │
│  - Network bandwidth                    │
│  - Pod count per node                   │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ APLIKACJE:                              │
│  - Pod restart count                    │
│  - Pod eviction rate                    │
│  - Application error rate               │
│  - Application response time            │
│  - Request rate                         │
└─────────────────────────────────────────┘
```

---


### **📚 Dokumentacja**

- [Kubernetes Official Documentation](https://kubernetes.io/docs/)
- [kubeadm Upgrade Guide](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)
- [Azure AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [etcd Disaster Recovery](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/)
- [Kubernetes Version Skew Policy](https://kubernetes.io/releases/version-skew-policy/)


---

## 🎬 Podsumowanie końcowe

### **Złote zasady Kubernetes Maintenance:**

```
┌──────────────────────────────────────────────────┐
│  1️⃣  "Cattle, not Pets"                         │
│     Node'y wymieniaj, nie naprawiaj             │
│                                                  │
│  2️⃣  Backup etcd ZAWSZE przed zmianami          │
│     To Twoja siatka bezpieczeństwa              │
│                                                  │
│  3️⃣  Test na non-prod NAJPIERW                  │
│     Nigdy nie eksperymentuj na produkcji        │
│                                                  │
│  4️⃣  PodDisruptionBudget dla WSZYSTKICH aplikacji│
│     To gwarancja zero downtime                  │
│                                                  │
│  5️⃣  Upgrade po kolei, czekaj i monitoruj       │
│     Lepiej wolniej, ale bezpiecznie             │
│                                                  │
│  6️⃣  Automatyzuj wszystko co się da             │
│     Infrastructure as Code                      │
│                                                  │
│  7️⃣  Dokumentuj każdą zmianę                    │
│     Przyszły Ty podziękuje                      │
│                                                  │
│  8️⃣  Zawsze miej rollback plan                  │
│     Nadzieja nie jest strategią                 │
└──────────────────────────────────────────────────┘
```

---

