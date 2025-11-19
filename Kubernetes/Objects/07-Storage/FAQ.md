## ❓ FAQ - Często zadawane pytania

### Q1: Jeśli PV ma 100GB, a PVC żąda 50GB, co się dzieje z pozostałymi 50GB?

**Odpowiedź:** Pozostałe 50GB "przepada" - nie może być użyte przez inny PVC.

#### Szczegóły:

**Co się dzieje przy binding:**
```bash
# PV utworzony na 100GB
kubectl get pv
# NAME    CAPACITY   STATUS      
# my-pv   100Gi      Available

# PVC żąda tylko 50GB
kubectl get pvc
# NAME     STATUS   VOLUME   CAPACITY
# my-pvc   Bound    my-pv    100Gi    ← Dostaje cały PV!
```

**Kluczowe punkty:**
- ✅ PVC binduje się z **całym PV** (nie z częścią)
- ✅ Aplikacja w Podzie **może używać wszystkich 100GB**
- ❌ Żaden inny PVC **nie może** użyć pozostałych 50GB
- 💰 W cloud **płacisz za całe 100GB**

#### Przykład - co widzi aplikacja:

```yaml
# PVC żąda 50GB, PV ma 100GB
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  resources:
    requests:
      storage: 50Gi
  storageClassName: manual
```

```bash
# W Podzie sprawdzamy dostępne miejsce
kubectl exec -it my-pod -- df -h /data
# Filesystem      Size  Used Avail Use% Mounted on
# /dev/sda1       100G  1.0G   99G   1% /data  ← Pełne 100GB dostępne!
```

#### Implikacje kosztowe w cloud:

```
AWS/GCP/Azure:
- Utworzono fizyczny disk: 100GB
- PVC "wie" o: 50GB  
- Kubernetes quota: 50GB
- Faktury: 💰 100GB!
- Marnotrawstwo: 50GB
```

#### ✅ Jak tego uniknąć?

**Rozwiązanie 1: Dynamic Provisioning (NAJLEPSZE!)**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  storageClassName: fast-ssd  # ✅ Automatycznie utworzy PV dokładnego rozmiaru!
  resources:
    requests:
      storage: 50Gi  # Dostaniesz DOKŁADNIE 50GB
```

**Rezultat:**
```bash
kubectl get pv,pvc
# PV: 50Gi  ✅ Dokładny rozmiar!
# PVC: 50Gi ✅ Zero marnotrawstwa!
```

**Rozwiązanie 2: Dopasuj rozmiary PV i PVC**

```yaml
# ✅ DOBRZE - ten sam rozmiar
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-50gb
spec:
  capacity:
    storage: 50Gi  # Dokładnie tyle ile potrzeba
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-50gb
spec:
  resources:
    requests:
      storage: 50Gi  # Ten sam rozmiar
```

**Rozwiązanie 3: Volume Expansion**

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: expandable
provisioner: kubernetes.io/gce-pd
allowVolumeExpansion: true  # ✅ Można zwiększać!
```

```bash
# Zacznij od mniejszego
# Później zwiększ gdy potrzeba
kubectl patch pvc my-pvc -p '{"spec":{"resources":{"requests":{"storage":"100Gi"}}}}'
```

#### 📊 Porównanie: Static vs Dynamic

| Aspekt | Static (ręczny PV) | Dynamic (StorageClass) |
|--------|-------------------|------------------------|
| **Marnotrawstwo** | ⚠️ Wysokie ryzyko | ✅ Zero marnotrawstwa |
| **Elastyczność** | ❌ Musisz przewidzieć rozmiar | ✅ Dokładny rozmiar |
| **Koszty** | 💰 Płacisz za nadmiar | 💰 Płacisz za dokładne użycie |
| **Zarządzanie** | 😓 Ręczna praca | 😊 Automatyczne |

#### 🎯 Złota zasada:

> **PV i PVC powinny być tego samego rozmiaru!**
> 
> Jeśli używasz static provisioning i PV jest większy niż PVC - marnujesz storage (i pieniądze w cloud).

---

### Q2: Co to jest provisioner `kubernetes.io/no-provisioner`?

**Odpowiedź:** To specjalny "pseudo-provisioner" sygnalizujący, że StorageClass **NIE obsługuje** dynamic provisioning i PV muszą być tworzone ręcznie.

#### Co to oznacza?

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner  # ← "Nie twórz automatycznie PV!"
volumeBindingMode: WaitForFirstConsumer
```

**Komunikat do Kubernetes:**
> "Ta StorageClass nie ma automatycznego provisionera. Administrator musi ręcznie utworzyć PV."

#### 🔄 Różnica w przepływie:

**Dynamic Provisioning (normalny provisioner):**
```
PVC → StorageClass → (AUTO-TWORZY PV) → Binding → Pod
```

**No-Provisioner:**
```
Admin ręcznie tworzy PV
       ↓
PVC → StorageClass → (SZUKA ISTNIEJĄCEGO PV) → Binding → Pod
```

#### 🎯 Kiedy używać?

**✅ GŁÓWNY USE CASE: Local Storage**

Local volumes to dyski przywiązane do konkretnego Node (np. SSD zainstalowany lokalnie).

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-local
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer  # ✅ KRYTYCZNE dla local storage!
```

**Dlaczego `no-provisioner`?**
- Nie można automatycznie "stworzyć" dysku na Node
- Admin musi fizycznie przygotować dyski
- Kubernetes tylko zarządza bindings

#### 📋 Kompletny przykład: Local Storage

**Krok 1: Przygotowanie Node**

```bash
# Na Node
ssh node1
sudo mkdir -p /mnt/disks/ssd1

# Opcjonalnie: zamontuj fizyczny dysk
sudo mkfs.ext4 /dev/sdb
sudo mount /dev/sdb /mnt/disks/ssd1
```

**Krok 2: StorageClass**

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-local
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Retain
```

**Krok 3: PV (ręcznie przez admina)**

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv-node1
spec:
  capacity:
    storage: 100Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: fast-local
  local:
    path: /mnt/disks/ssd1
  nodeAffinity:  # ✅ WYMAGANE dla local volumes!
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - node1  # PV przywiązany do tego Node
```

**Krok 4: PVC (user)**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-local-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: fast-local
  resources:
    requests:
      storage: 50Gi
```

```bash
kubectl apply -f pvc.yaml

# PVC pozostaje w Pending!
kubectl get pvc
# NAME            STATUS    VOLUME   STORAGECLASS
# my-local-pvc    Pending            fast-local
```

**Dlaczego Pending?** 
- `volumeBindingMode: WaitForFirstConsumer`
- Czeka na utworzenie Poda

**Krok 5: Pod**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: storage
      mountPath: /data
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: my-local-pvc
```

```bash
kubectl apply -f pod.yaml

# Teraz następuje binding!
kubectl get pvc
# NAME            STATUS   VOLUME           STORAGECLASS
# my-local-pvc    Bound    local-pv-node1   fast-local

kubectl get pod -o wide
# NAME     READY   STATUS    NODE
# my-app   1/1     Running   node1  ← Schedulowany na node1!
```

#### ⚡ volumeBindingMode - KRYTYCZNE!

**WaitForFirstConsumer (✅ ZALECANE dla local storage)**

```yaml
volumeBindingMode: WaitForFirstConsumer
```

**Przepływ:**
```
1. PVC created → Pending (czeka)
2. Pod created → Scheduler wybiera Node (np. node2)
3. Kubernetes wybiera PV na node2
4. Binding PVC ↔ PV
5. Pod startuje
```

**Immediate (❌ PROBLEMATYCZNE dla local storage)**

```yaml
volumeBindingMode: Immediate
```

**Problem:**
```
1. PVC created → Binduje z random PV (np. na node1)
2. Pod created → MUSI być na node1 (bo volume tam jest)
3. Co jeśli node1 nie ma resources? Pod Pending forever!
```

#### 📊 Porównanie provisionerów

| Aspekt | no-provisioner | Prawdziwy provisioner |
|--------|----------------|----------------------|
| **Auto-tworzenie PV** | ❌ Nie | ✅ Tak |
| **Admin musi tworzyć PV** | ✅ Tak | ❌ Nie |
| **Use case** | Local storage, manual | Cloud storage, auto-scaling |
| **Elastyczność** | ⚠️ Ograniczona | ✅ Pełna |
| **Kontrola** | ✅ Pełna | ⚠️ Mniej kontroli |
| **Overhead** | 😓 Duży (ręczna praca) | 😊 Minimalny |

#### 🎯 Kiedy używać `no-provisioner`?

**✅ UŻYWAJ gdy:**
- Local storage (SSD/NVMe na Nodes)
- Wysokowydajne bazy danych wymagające local disks
- Specjalne wymagania security/compliance
- Legacy storage bez CSI driver

**❌ NIE UŻYWAJ gdy:**
- Masz dostęp do cloud storage (AWS EBS, GCE PD, Azure Disk)
- Potrzebujesz szybkiego skalowania
- Masz mały team ops (ręczne zarządzanie jest czasochłonne)

#### 💡 Best Practices dla local storage

**✅ DO:**

1. **Zawsze używaj WaitForFirstConsumer**
```yaml
volumeBindingMode: WaitForFirstConsumer
```

2. **Dodawaj nodeAffinity**
```yaml
spec:
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - node1
```

3. **Label PV dla zarządzania**
```yaml
metadata:
  labels:
    storage-type: local-ssd
    node: node1
    disk: ssd1
```

**❌ DON'T:**

1. **Nie używaj Immediate dla local storage**
2. **Nie zapominaj o nodeAffinity**
3. **Nie używaj local storage dla stateless apps**

#### 🛠️ Narzędzie pomocnicze

**Local Volume Static Provisioner** - automatyzuje tworzenie local PV:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: local-volume-provisioner
  namespace: kube-system
spec:
  selector:
    matchLabels:
      app: local-volume-provisioner
  template:
    metadata:
      labels:
        app: local-volume-provisioner
    spec:
      serviceAccountName: local-storage-admin
      containers:
      - name: provisioner
        image: quay.io/external_storage/local-volume-provisioner:v2.5.0
        volumeMounts:
        - name: discovery-vol
          mountPath: /mnt/disks
      volumes:
      - name: discovery-vol
        hostPath:
          path: /mnt/disks
```

**Co robi:**
- Skanuje `/mnt/disks` na każdym Node
- Automatycznie tworzy PV dla znalezionych dysków
- Redukuje ręczną pracę admina

---

## 📖 Dodatkowe zasoby

### Oficjalna dokumentacja:
- [Kubernetes Storage](https://kubernetes.io/docs/concepts/storage/)
- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [Dynamic Volume Provisioning](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/)
- [Local Persistent Volumes](https://kubernetes.io/docs/concepts/storage/volumes/#local)

### Provisionerzy dla różnych platform:
- **AWS EBS CSI Driver**: `ebs.csi.aws.com`
- **Azure Disk CSI Driver**: `disk.csi.azure.com`
- **GCE PD CSI Driver**: `pd.csi.storage.gke.io`
- **NFS**: `nfs.csi.k8s.io`
- **Ceph RBD**: `rbd.csi.ceph.com`
- **Local volumes**: `kubernetes.io/no-provisioner`