# Kubernetes - Ćwiczenia: Storage (PVC, PV, SC)

> **Wprowadzenie:** Te ćwiczenia pomogą Ci zrozumieć zarządzanie przechowywaniem danych w Kubernetes. Poznasz PersistentVolume, PersistentVolumeClaim i StorageClass.

**Co to jest Storage?** Kubernetes oferuje kilka obiektów do zarządzania przechowywaniem danych:
- **PersistentVolume (PV)** - zasób przechowywania w klastrze
- **PersistentVolumeClaim (PVC)** - żądanie użytkownika dotyczące przechowywania
- **StorageClass (SC)** - opisuje klasy przechowywania i sposób ich dynamicznego provisioningu

## Ćwiczenie 6.1: PersistentVolumeClaim (PVC)

**Zadanie:** Utwórz PVC `app-data-pvc` w namespace `cwiczenia` z:
- Dostępem `ReadWriteOnce`
- Rozmiarem `1Gi`
- StorageClass `default` (lub domyślną w twoim środowisku)

Następnie utwórz Pod `app-pod` z obrazem `nginx:latest` w tym samym namespace, który montuje ten PVC do `/data`.

> **Uwaga:** W AKS użyj StorageClass `default`. W innych środowiskach sprawdź dostępne StorageClass: `kubectl get storageclass`

**Wskazówki:**
- Użyj `apiVersion: v1` i `kind: PersistentVolumeClaim`
- W `spec.accessModes` określ tryb dostępu
- W `spec.resources.requests.storage` określ rozmiar
- W Pod użyj `spec.volumes` i `spec.containers[].volumeMounts`

**Cel:** Zrozumienie podstawowej konfiguracji PVC i montowania w Podach.

**Weryfikacja:**
```bash
# Sprawdź PVC
kubectl get pvc app-data-pvc

# Sprawdź szczegóły (zobacz STATUS - powinien być Bound)
kubectl describe pvc app-data-pvc

# Sprawdź Pod
kubectl get pod app-pod

# Sprawdź, że wolumen jest zamontowany
kubectl exec app-pod -- df -h | grep /data

# Utwórz plik w wolumenie
kubectl exec app-pod -- touch /data/test.txt

# Sprawdź, że plik istnieje
kubectl exec app-pod -- ls -la /data
```

---

## Ćwiczenie 6.2: PersistentVolume (PV) statyczny

> **⚠️ UWAGA:** To ćwiczenie używa `hostPath`, który działa **tylko w środowiskach lokalnych** (Kind, Minikube). W AKS i innych środowiskach chmurowych użyj dynamicznego provisioningu przez StorageClass (patrz ćwiczenie 6.3).

**Zadanie:** Utwórz statyczny PersistentVolume `local-pv` używając hostPath (dla środowiska lokalnego) z:
- Rozmiarem `2Gi`
- Dostępem `ReadWriteOnce`
- StorageClass `local-storage`

Następnie utwórz PVC `local-pvc`, który wiąże się z tym PV.

**Wskazówki:**
- PV to zasób w klastrze (nie w namespace) - nie wymaga namespace
- `hostPath` działa tylko w środowiskach lokalnych (Kind, Minikube)
- W środowiskach chmurowych (AKS, EKS, GKE) użyj dynamicznego provisioningu
- PVC automatycznie wiąże się z PV, jeśli pasują `accessModes` i rozmiar
- Możesz użyć `spec.claimRef` w PV, aby zarezerwować go dla konkretnego PVC

**Cel:** Zrozumienie statycznego provisioningu PV i wiązania z PVC.

**Weryfikacja:**
```bash
# Sprawdź PV
kubectl get pv local-pv

# Sprawdź szczegóły (zobacz STATUS - powinien być Available, potem Bound)
kubectl describe pv local-pv

# Utwórz PVC
kubectl get pvc local-pvc

# Sprawdź, że PVC jest związany z PV
kubectl get pv local-pv
# STATUS powinien być Bound, a CLAIM powinien wskazywać na namespace/local-pvc

# Sprawdź szczegóły PVC
kubectl describe pvc local-pvc
```

---

## Ćwiczenie 6.3: StorageClass (SC)

**Zadanie:** Utwórz StorageClass `fast-ssd` z:
- Provisionerem odpowiednim dla twojego środowiska:
  - **AKS:** `disk.csi.azure.com`
  - **EKS:** `ebs.csi.aws.com`
  - **GKE:** `pd.csi.storage.gke.io`
  - **Lokalne (Kind/Minikube):** `kubernetes.io/no-provisioner`
- `volumeBindingMode: WaitForFirstConsumer`
- ReclaimPolicy `Retain`

Następnie utwórz PVC `fast-pvc` używający tej StorageClass.

> **Uwaga:** W AKS użyj `disk.csi.azure.com` jako provisioner. W innych środowiskach dostosuj provisioner do swojego dostawcy chmury.

**Wskazówki:**
- StorageClass definiuje klasę przechowywania
- `provisioner` określa, jak PV są tworzone (dynamicznie)
- `volumeBindingMode: WaitForFirstConsumer` - PV jest tworzony dopiero, gdy Pod używa PVC
- `reclaimPolicy` określa, co się dzieje z PV po usunięciu PVC (Retain/Delete)

**Cel:** Zrozumienie StorageClass i dynamicznego provisioningu.

**Weryfikacja:**
```bash
# Sprawdź StorageClass
kubectl get storageclass fast-ssd

# Sprawdź szczegóły
kubectl describe storageclass fast-ssd

# Utwórz PVC używający tej StorageClass
# W PVC w spec.storageClassName określ: fast-ssd

# Sprawdź PVC
kubectl get pvc fast-pvc

# Zauważ, że PVC może być w stanie Pending, dopóki nie zostanie użyty przez Pod
# Utwórz Pod używający tego PVC i sprawdź, że PV został utworzony
kubectl get pv
```

---

## Ćwiczenie 6.4: PVC z różnymi trybami dostępu

**Zadanie:** Utwórz trzy PVC z różnymi trybami dostępu:
1. `pvc-rwo` - `ReadWriteOnce` (RWO)
2. `pvc-rwm` - `ReadWriteMany` (RWM) - jeśli wspierane
3. `pvc-rom` - `ReadOnlyMany` (ROM)

Następnie utwórz Deployment z 3 replikami, które próbują zamontować wszystkie trzy PVC.

**Wskazówki:**
- `ReadWriteOnce` - może być zamontowany do odczytu i zapisu przez jeden node
- `ReadWriteMany` - może być zamontowany do odczytu i zapisu przez wiele nodów (wymaga wsparcia storage)
- `ReadOnlyMany` - może być zamontowany tylko do odczytu przez wiele nodów
- Nie wszystkie storage backends wspierają wszystkie tryby

**Cel:** Zrozumienie różnych trybów dostępu do wolumenów.

**Weryfikacja:**
```bash
# Sprawdź wszystkie PVC
kubectl get pvc

# Sprawdź szczegóły każdego
kubectl describe pvc pvc-rwo
kubectl describe pvc pvc-rwm
kubectl describe pvc pvc-rom

# Sprawdź Deployment
kubectl get deployment

# Sprawdź Pody
kubectl get pods

# Sprawdź, które wolumeny są zamontowane w każdym Podzie
kubectl describe pod <pod-name> | grep -A 10 Mounts

# Przetestuj zapis do wolumenów
kubectl exec <pod-name> -- touch /data-rwo/test.txt
kubectl exec <pod-name> -- touch /data-rwm/test.txt
# ROM powinien być tylko do odczytu
```

---

## Ćwiczenie 6.5: StatefulSet z PVC (szablon wolumenów)

**Zadanie:** Utwórz StatefulSet `db-sts` z 3 replikami (obraz `nginx:latest`), który używa `volumeClaimTemplates` do automatycznego tworzenia PVC dla każdego Poda. Każdy Pod powinien mieć własny wolumen o rozmiarze `500Mi`.

**Wskazówki:**
- W StatefulSet użyj `spec.volumeClaimTemplates` zamiast `spec.volumes`
- Każdy Pod otrzyma własny PVC: `db-sts-0-pvc`, `db-sts-1-pvc`, `db-sts-2-pvc`
- PVC są tworzone automatycznie wraz z Podami
- To jest typowy wzorzec dla baz danych i aplikacji stateful

**Cel:** Zrozumienie automatycznego tworzenia PVC w StatefulSet.

**Weryfikacja:**
```bash
# Sprawdź StatefulSet
kubectl get statefulset db-sts

# Sprawdź utworzone PVC (powinny być 3)
kubectl get pvc

# Zauważ nazwy: db-sts-0-pvc, db-sts-1-pvc, db-sts-2-pvc

# Sprawdź Pody
kubectl get pods -l app=db

# Sprawdź, że każdy Pod ma własny wolumen
kubectl exec db-sts-0 -- df -h
kubectl exec db-sts-1 -- df -h
kubectl exec db-sts-2 -- df -h

# Utwórz plik w jednym Podzie i sprawdź, że nie jest widoczny w innych
kubectl exec db-sts-0 -- touch /data/pod-0.txt
kubectl exec db-sts-1 -- ls /data
# Powinien być pusty (każdy Pod ma własny wolumen)
```

---

## Podsumowanie

Po wykonaniu ćwiczeń ze Storage powinieneś:
- ✅ Rozumieć różnicę między PV, PVC i StorageClass
- ✅ Umieć tworzyć i montować PVC w Podach
- ✅ Rozumieć statyczny i dynamiczny provisioning
- ✅ Znać różne tryby dostępu do wolumenów
- ✅ Umieć używać volumeClaimTemplates w StatefulSet

## Przydatne komendy

```bash
# PersistentVolume
kubectl get pv
kubectl get pv <name>
kubectl describe pv <name>

# PersistentVolumeClaim
kubectl get pvc
kubectl get pvc <name>
kubectl describe pvc <name>

# StorageClass
kubectl get storageclass
kubectl get storageclass <name>
kubectl describe storageclass <name>

# Sprawdzanie montowania
kubectl describe pod <pod-name> | grep -A 10 Mounts
kubectl exec <pod-name> -- df -h
```

## Tryby dostępu - szybka referencja

- **ReadWriteOnce (RWO)** - może być zamontowany do odczytu i zapisu przez jeden node
- **ReadWriteMany (RWM)** - może być zamontowany do odczytu i zapisu przez wiele nodów
- **ReadOnlyMany (ROM)** - może być zamontowany tylko do odczytu przez wiele nodów

**Uwaga:** Nie wszystkie storage backends wspierają wszystkie tryby dostępu. Sprawdź dokumentację swojego dostawcy storage.

