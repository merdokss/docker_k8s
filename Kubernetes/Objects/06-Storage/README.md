# Kubernetes Storage: PV, PVC i StorageClass

Kompleksowy przewodnik po zarządzaniu storage w Kubernetes - od podstaw do zaawansowanych scenariuszy.

---

## 📚 Spis treści

- [Wprowadzenie](#wprowadzenie)
- [Podstawowe koncepcje](#podstawowe-koncepcje)
  - [PersistentVolume (PV)](#persistentvolume-pv)
  - [PersistentVolumeClaim (PVC)](#persistentvolumeclaim-pvc)
  - [StorageClass](#storageclass)
- [Jak to działa razem](#jak-to-działa-razem)
- [Tryby dostępu](#tryby-dostępu-access-modes)
- [Reclaim Policy](#reclaim-policy)
- [Czy StorageClass jest wymagana w PVC](#czy-storageclass-jest-wymagana-w-pvc)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [Przykłady](#przykłady)

---

## Wprowadzenie

Storage w Kubernetes składa się z trzech głównych komponentów, które współpracują ze sobą aby zapewnić trwałe przechowywanie danych dla aplikacji.

### 🏪 Analogia

Wyobraź sobie system storage jak sklep:

- **PersistentVolume (PV)** = konkretny magazyn/przestrzeń dyskowa (półka w magazynie)
- **PersistentVolumeClaim (PVC)** = zamówienie/rezerwacja przestrzeni (zamówienie w sklepie)
- **StorageClass** = kategoria/typ magazynu z automatycznym zaopatrzeniem (sklep internetowy z auto-dostawą)

---

## Podstawowe koncepcje

### PersistentVolume (PV)

**Definicja:** PV to faktyczna przestrzeń dyskowa dostępna w klastrze. To zasób na poziomie klastra (cluster-level), nie należy do żadnego namespace.

#### Kluczowe cechy:
- ✅ Tworzy go **administrator klastra**
- ✅ Reprezentuje rzeczywisty storage (NFS, iSCSI, cloud disk, local disk)
- ✅ Ma określoną pojemność
- ✅ Ma tryby dostępu (ReadWriteOnce, ReadOnlyMany, ReadWriteMany)
- ✅ Istnieje niezależnie od Podów

#### Przykład PV:
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-example
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce  # Tylko jeden Pod może pisać
  persistentVolumeReclaimPolicy: Retain  # Co się stanie po usunięciu PVC
  storageClassName: manual
  hostPath:  # Typ storage - tutaj lokalny folder
    path: /mnt/data
```

---

### PersistentVolumeClaim (PVC)

**Definicja:** PVC to **żądanie** użytkownika o przydzielenie storage. To sposób, w jaki Pody "proszą" o przestrzeń dyskową.

#### Kluczowe cechy:
- ✅ Tworzy go **użytkownik/developer**
- ✅ Należy do konkretnego namespace
- ✅ Określa wymagania: ile miejsca potrzebuje, jaki tryb dostępu
- ✅ Kubernetes automatycznie znajduje pasujący PV (binding)

#### Przykład PVC:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-example
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi  # Proszę o 5GB
  storageClassName: manual  # Z jakiej "kategorii"
```

---

### StorageClass

**Definicja:** StorageClass to definicja **jak automatycznie tworzyć** PV. To jak fabryka, która na żądanie produkuje storage.

#### Kluczowe cechy:
- ✅ Umożliwia **Dynamic Provisioning** - automatyczne tworzenie PV
- ✅ Definiuje typ storage i parametry (SSD, HDD, replikacja, etc.)
- ✅ Różni provisionerzy dla różnych platform (AWS EBS, Azure Disk, GCE PD)

#### Przykład StorageClass (AWS):
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp3  # SSD
  iopsPerGB: "10"
  encrypted: "true"
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
```

---

## Jak to działa razem

### Scenariusz 1: Static Provisioning (ręczne)
```
1. Admin tworzy PV (fizyczny storage jest już gotowy)
2. User tworzy PVC z wymaganiami
3. Kubernetes znajduje pasujący PV i łączy je (binding)
4. Pod używa PVC jako volume
```

**Diagram przepływu:**
```
PV (10Gi) ←---binding---→ PVC (5Gi) ←---używa---→ Pod
```

### Scenariusz 2: Dynamic Provisioning (automatyczne)
```
1. Admin tworzy StorageClass
2. User tworzy PVC wskazujący na StorageClass
3. Kubernetes automatycznie tworzy PV używając StorageClass
4. Pod używa PVC jako volume
```

**Diagram przepływu:**
```
StorageClass → (auto-tworzy) → PV ←---binding---→ PVC ←---używa---→ Pod
```

---

## Tryby dostępu (Access Modes)

| Tryb | Skrót | Opis |
|------|-------|------|
| ReadWriteOnce | RWO | Jeden Node może montować do zapisu |
| ReadOnlyMany | ROX | Wiele Nodów może montować do odczytu |
| ReadWriteMany | RWX | Wiele Nodów może montować do zapisu |
| ReadWriteOncePod | RWOP | Tylko jeden Pod może montować do zapisu (K8s 1.22+) |

### Przykład użycia:
```yaml
spec:
  accessModes:
    - ReadWriteOnce  # Najczęściej używany
```

---

## Reclaim Policy

Określa co się dzieje z PV po usunięciu PVC:

| Policy | Opis | Użycie |
|--------|------|--------|
| **Retain** | PV pozostaje, dane zachowane, wymaga ręcznego czyszczenia | Produkcja, ważne dane |
| **Delete** | PV i dane są automatycznie usuwane | Rozwój, dane tymczasowe |
| **Recycle** | Dane są czyszczone (rm -rf), PV gotowy do użycia | ⚠️ Deprecated |

### Przykład:
```yaml
spec:
  persistentVolumeReclaimPolicy: Retain  # Bezpieczna opcja
```

---

## Czy StorageClass jest wymagana w PVC?

### ❌ Krótka odpowiedź: NIE, ale...

PVC **nie musi** mieć zdefiniowanej StorageClass, ale zachowanie będzie różne w zależności od konfiguracji klastra.

### 📋 Cztery scenariusze

#### 1️⃣ PVC Z określoną StorageClass
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-with-sc
spec:
  storageClassName: fast-ssd  # ✅ Jawnie określona
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

**Wynik:** Kubernetes użyje StorageClass `fast-ssd` do utworzenia PV (dynamic provisioning)

---

#### 2️⃣ PVC BEZ StorageClass (pusty string)
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-no-sc
spec:
  storageClassName: ""  # ✅ Jawnie wyłączone dynamic provisioning
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

**Wynik:** Static provisioning - Kubernetes szuka istniejącego PV

---

#### 3️⃣ PVC BEZ pola storageClassName
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-default
spec:
  # storageClassName: <brak tego pola>
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

**Wynik zależy od klastra:**

**A) Jeśli istnieje default StorageClass:**
```bash
kubectl get storageclass
# NAME                 PROVISIONER
# standard (default)   kubernetes.io/gce-pd
```
→ Użyje default StorageClass (dynamic provisioning)

**B) Jeśli NIE MA default StorageClass:**
→ Static provisioning (szuka istniejącego PV)

---

#### 4️⃣ PVC z selektorem (zaawansowane)
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-with-selector
spec:
  storageClassName: ""  # Static provisioning
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  selector:  # ✅ Dodatkowe kryteria wyboru PV
    matchLabels:
      environment: production
      tier: gold
```

---

### 📊 Tabela porównawcza

| Scenariusz | storageClassName | Default SC w klastrze | Wynik |
|------------|------------------|----------------------|-------|
| Jawnie określona SC | `storageClassName: fast-ssd` | Nieważne | Użyje `fast-ssd`, dynamic provisioning |
| Pusty string | `storageClassName: ""` | Nieważne | Static provisioning, szuka PV |
| Brak pola | (pole nie istnieje) | ✅ TAK | Użyje default SC, dynamic provisioning |
| Brak pola | (pole nie istnieje) | ❌ NIE | Static provisioning, szuka PV |

---

### 🎯 Default StorageClass

#### Sprawdzenie default StorageClass:
```bash
kubectl get storageclass
```

Przykładowy wynik:
```
NAME                 PROVISIONER             AGE
standard (default)   kubernetes.io/gce-pd    30d
fast-ssd            kubernetes.io/gce-pd    30d
```

#### Ustawienie StorageClass jako default:
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"  # ✅ Klucz do sukcesu
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-standard
```

#### Usunięcie default:
```bash
kubectl patch storageclass standard -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
```

---

## Best Practices

### ✅ ZALECANE

#### 1. Zawsze jawnie określaj StorageClass w produkcji
```yaml
spec:
  storageClassName: fast-ssd  # Jasne, explicit, przewidywalne
```

**Dlaczego?**
- Brak niespodzianek
- Łatwiejsze debugowanie
- Kontrola kosztów (różne SC = różne ceny)
- Niezależność od konfiguracji klastra

#### 2. Dla static provisioning używaj pustego stringa
```yaml
spec:
  storageClassName: ""  # Jasne: chcę ręcznie utworzonego PV
```

#### 3. Używaj sensownych nazw
```yaml
# ✅ DOBRZE
storageClassName: prod-fast-ssd
storageClassName: dev-standard-hdd

# ❌ ŹLE
storageClassName: sc1
storageClassName: storage
```

#### 4. Dokumentuj wymagania storage
```yaml
metadata:
  name: database-storage
  annotations:
    description: "High-performance SSD for PostgreSQL"
    backup-policy: "daily"
    retention: "30-days"
spec:
  storageClassName: prod-fast-ssd
  resources:
    requests:
      storage: 100Gi
```

#### 5. Używaj odpowiednich Reclaim Policy
```yaml
# Produkcja - ważne dane
persistentVolumeReclaimPolicy: Retain

# Development/Testing
persistentVolumeReclaimPolicy: Delete
```

---

### ❌ UNIKAJ

#### 1. Polegania na default StorageClass w produkcji
```yaml
# ❌ ŹLE - co się stanie?
spec:
  # storageClassName: ???
  resources:
    requests:
      storage: 10Gi
```

**Dlaczego?**
- Default może się zmienić
- Nie wiadomo, jakie parametry storage
- Różne klastry = różne defaulty
- Trudne debugowanie

#### 2. Używania hostPath w produkcji
```yaml
# ❌ ŹLE dla produkcji
spec:
  hostPath:
    path: /mnt/data
```

**Dlaczego?**
- Dane przywiązane do konkretnego node
- Brak redundancji
- Problem przy skalowaniu

#### 3. Nadmiernych uprawnień dostępu
```yaml
# ❌ Unikaj jeśli nie potrzebne
accessModes:
  - ReadWriteMany  # Często niepotrzebne i droższe
```

---

## Troubleshooting

### Problem 1: PVC w stanie Pending
```bash
kubectl get pvc
# NAME        STATUS    VOLUME   CAPACITY   STORAGECLASS
# my-pvc      Pending                        
```

#### Diagnoza:
```bash
kubectl describe pvc my-pvc
```

#### Możliwe przyczyny i rozwiązania:

##### A) Brak StorageClass

**Objaw:**
```
Events:
  Type     Reason              Message
  ----     ------              -------
  Warning  ProvisioningFailed  storageclass.storage.k8s.io "standard" not found
```

**Rozwiązanie:**
```bash
# Sprawdź dostępne StorageClasses
kubectl get storageclass

# Dodaj storageClassName do PVC lub utwórz StorageClass
```

##### B) Brak pasującego PV (static provisioning)

**Objaw:**
```
Events:
  Type     Reason         Message
  ----     ------         -------
  Normal   FailedBinding  no persistent volumes available for this claim
```

**Rozwiązanie:**
```bash
# Sprawdź dostępne PV
kubectl get pv

# Utwórz pasujący PV lub zmień na dynamic provisioning
```

##### C) Niekompatybilne accessModes

**Objaw:**
```
Events:
  Normal   FailedBinding  Cannot bind to requested volume
```

**Rozwiązanie:**
```bash
# Sprawdź accessModes w PV
kubectl get pv pv-name -o yaml | grep accessModes -A 5

# Dostosuj accessModes w PVC
```

---

### Problem 2: Pod nie może zamontować volume
```bash
kubectl describe pod my-pod
```

**Objaw:**
```
Events:
  Warning  FailedMount  MountVolume.SetUp failed: PVC "my-pvc" not found
```

**Rozwiązanie:**
```bash
# Sprawdź czy PVC istnieje w tym samym namespace
kubectl get pvc -n <namespace>

# Sprawdź czy PVC jest bound
kubectl get pvc my-pvc
```

---

### Problem 3: Volume pozostaje po usunięciu PVC

**Objaw:**
```bash
kubectl get pv
# NAME      STATUS     CLAIM           RECLAIMPOLICY
# pv-xyz    Released   default/my-pvc  Retain
```

**Wyjaśnienie:** To normalne zachowanie dla `Retain` policy

**Rozwiązanie:**
```bash
# 1. Zapisz dane jeśli potrzebne
# 2. Usuń PV ręcznie
kubectl delete pv pv-xyz

# Lub zmień reclaim policy (jeśli to możliwe)
kubectl patch pv pv-xyz -p '{"spec":{"persistentVolumeReclaimPolicy":"Delete"}}'
```

---

### Przydatne komendy diagnostyczne
```bash
# Sprawdź wszystkie PV
kubectl get pv

# Sprawdź wszystkie PVC w namespace
kubectl get pvc -n <namespace>

# Szczegóły PV
kubectl describe pv <pv-name>

# Szczegóły PVC
kubectl describe pvc <pvc-name>

# Sprawdź StorageClasses
kubectl get storageclass

# Sprawdź default StorageClass
kubectl get storageclass -o jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}'

# Sprawdź logi provisioner (dla dynamic provisioning)
kubectl logs -n kube-system -l app=<provisioner-name>

# Sprawdź eventy w namespace
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

---

## Przykłady

### Przykład 1: Kompletna aplikacja z storage

#### 1. StorageClass (dynamiczny)
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-storage
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-ssd
  replication-type: regional-pd
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

#### 2. PVC (żądanie storage)
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: webapp-storage
  namespace: production
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: fast-storage
  resources:
    requests:
      storage: 20Gi
```

#### 3. Deployment (używa PVC)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  namespace: production
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        volumeMounts:
        - name: data
          mountPath: /usr/share/nginx/html
        ports:
        - containerPort: 80
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: webapp-storage
```

#### Deployment:
```bash
kubectl apply -f storageclass.yaml
kubectl apply -f pvc.yaml
kubectl apply -f deployment.yaml

# Weryfikacja
kubectl get pvc -n production
kubectl get pods -n production
```

---

### Przykład 2: Static Provisioning z NFS

#### 1. PV z NFS
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-pv
spec:
  capacity:
    storage: 100Gi
  accessModes:
    - ReadWriteMany  # NFS wspiera RWX
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nfs
  nfs:
    server: 192.168.1.100
    path: /exported/path
```

#### 2. PVC dla NFS
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-claim
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs
  resources:
    requests:
      storage: 50Gi
```

#### 3. StatefulSet używający NFS
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: "nginx"
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        volumeMounts:
        - name: shared-data
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: shared-data
    spec:
      accessModes:
        - ReadWriteMany
      storageClassName: nfs
      resources:
        requests:
          storage: 10Gi
```

---

### Przykład 3: Multi-tier aplikacja z różnymi storage
```yaml
---
# Fast SSD dla bazy danych
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: db-storage
  namespace: app
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: fast-ssd
  resources:
    requests:
      storage: 50Gi
---
# Standard storage dla aplikacji
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-storage
  namespace: app
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: standard
  resources:
    requests:
      storage: 20Gi
---
# Shared storage dla media
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: media-storage
  namespace: app
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs
  resources:
    requests:
      storage: 100Gi
---
# Database Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:14
        env:
        - name: POSTGRES_PASSWORD
          value: "secret"
        volumeMounts:
        - name: db-data
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: db-data
        persistentVolumeClaim:
          claimName: db-storage
---
# Application Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  namespace: app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: app
        image: myapp:latest
        volumeMounts:
        - name: app-data
          mountPath: /app/data
        - name: media
          mountPath: /app/media
      volumes:
      - name: app-data
        persistentVolumeClaim:
          claimName: app-storage
      - name: media
        persistentVolumeClaim:
          claimName: media-storage
```

---

### Przykład 4: Volume Snapshot (backup)

#### 1. VolumeSnapshotClass
```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: csi-snapclass
driver: pd.csi.storage.gke.io
deletionPolicy: Delete
```

#### 2. Utworzenie snapshot
```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: db-snapshot-20231201
  namespace: production
spec:
  volumeSnapshotClassName: csi-snapclass
  source:
    persistentVolumeClaimName: db-storage
```

#### 3. Przywrócenie z snapshot
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: db-storage-restored
  namespace: production
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: fast-ssd
  resources:
    requests:
      storage: 50Gi
  dataSource:
    name: db-snapshot-20231201
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
```

---

## 💡 Kluczowe punkty do zapamiętania

1. **PV** = fizyczny storage (admin zarządza) - cluster-wide
2. **PVC** = prośba o storage (developer zarządza) - namespace-scoped
3. **StorageClass** = automatyczna fabryka PV - cluster-wide
4. Dynamic provisioning > Static provisioning (mniej pracy ręcznej)
5. **Zawsze określaj StorageClass explicit w produkcji**
6. `storageClassName: ""` = wymusza static provisioning
7. Brak pola storageClassName = użyje default SC (jeśli istnieje)
8. Jeden klaster może mieć tylko jedną default StorageClass
9. Wybieraj odpowiedni Reclaim Policy dla środowiska
10. ReadWriteMany jest droższe i nie wszędzie dostępne

---

## 📖 Dodatkowe zasoby

### Oficjalna dokumentacja:
- [Kubernetes Storage](https://kubernetes.io/docs/concepts/storage/)
- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [Dynamic Volume Provisioning](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/)

### Provisionerzy dla różnych platform:
- **AWS EBS CSI Driver**: `ebs.csi.aws.com`
- **Azure Disk CSI Driver**: `disk.csi.azure.com`
- **GCE PD CSI Driver**: `pd.csi.storage.gke.io`
- **NFS**: `nfs.csi.k8s.io`
- **Ceph RBD**: `rbd.csi.ceph.com`

---

## 🎓 Ćwiczenia praktyczne

### Ćwiczenie 1: Basic Dynamic Provisioning

**Cel:** Utworzenie aplikacji z dynamic storage

**Zadania:**
1. Sprawdź czy w klastrze jest default StorageClass
2. Utwórz PVC z 10Gi storage
3. Utwórz Pod z nginx, który używa tego PVC
4. Zapisz plik HTML w volume
5. Usuń Pod i utwórz nowy - sprawdź czy plik nadal istnieje

### Ćwiczenie 2: Static Provisioning

**Cel:** Ręczne tworzenie PV i binding

**Zadania:**
1. Utwórz PV z hostPath (5Gi)
2. Utwórz PVC z `storageClassName: ""`
3. Sprawdź czy PVC automatycznie się zbindował
4. Utwórz Pod używający tego PVC

### Ćwiczenie 3: Troubleshooting

**Cel:** Debugowanie problemów ze storage

**Zadania:**
1. Utwórz PVC z nieistniejącą StorageClass
2. Zidentyfikuj problem używając `kubectl describe`
3. Napraw problem
4. Utwórz PVC z większym storage niż dostępny PV
5. Zdiagnozuj i napraw

### Ćwiczenie 4: Multi-pod Access

**Cel:** Praca z różnymi access modes

**Zadania:**
1. Utwórz PVC z ReadWriteMany (jeśli wspierane)
2. Utwórz 3 Pody, które jednocześnie piszą do tego volume
3. Sprawdź czy wszystkie Pody widzą te same dane
4. Porównaj z ReadWriteOnce

---

## ⚡ Quick Reference

### Podstawowe komendy
```bash
# PersistentVolumes
kubectl get pv
kubectl describe pv <name>
kubectl delete pv <name>

# PersistentVolumeClaims
kubectl get pvc
kubectl get pvc -n <namespace>
kubectl describe pvc <name>
kubectl delete pvc <name>

# StorageClasses
kubectl get sc
kubectl get storageclass
kubectl describe sc <name>

# Sprawdź binding
kubectl get pv,pvc

# Sprawdź wydarzenia
kubectl get events --sort-by='.lastTimestamp'
```

### Access Modes - szybka ściąga
```yaml
# Jeden node, zapis
accessModes: [ReadWriteOnce]

# Wiele nodów, odczyt
accessModes: [ReadOnlyMany]

# Wiele nodów, zapis (wymaga specjalnego storage)
accessModes: [ReadWriteMany]
```

### Reclaim Policies - szybka ściąga
```yaml
# Zachowaj dane (produkcja)
persistentVolumeReclaimPolicy: Retain

# Usuń automatycznie (development)
persistentVolumeReclaimPolicy: Delete
```

---

