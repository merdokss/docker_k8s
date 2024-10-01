## PersistentVolume (PV) i PersistentVolumeClaim (PVC)

PersistentVolume (PV) i PersistentVolumeClaim (PVC) to obiekty w Kubernetes, które umożliwiają zarządzanie trwałym przechowywaniem danych. PV reprezentuje zasób pamięci, który został udostępniony przez administratora klastra, natomiast PVC to żądanie zasobu pamięci przez użytkownika.

### Jak działa PersistentVolume (PV)?

1. **Definicja PV**: Administrator klastra definiuje PersistentVolume, określając szczegóły dotyczące zasobu pamięci, takie jak rozmiar, typ pamięci (np. NFS, AWS EBS) i dostępność.
2. **Przydzielanie PV**: PV jest przydzielane do klastra i staje się dostępne dla użytkowników.

Przykład definicji PersistentVolume:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
```

### Jak działa PersistentVolumeClaim (PVC)?

1. **Definicja PVC**: Użytkownik tworzy PersistentVolumeClaim, określając wymagany rozmiar i typ pamięci.
2. **Przydzielanie PVC**: PVC jest przydzielane do klastra, a Kubernetes próbuje znaleźć odpowiedni PV, który może spełnić wymagania.
3. **Powiązanie PVC z PV**: Jeśli odpowiedni PV istnieje, PVC jest powiązane z PV, a użytkownik może korzystać z PV.

Przykład definicji PersistentVolumeClaim:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

### ReclaimPolicy

ReclaimPolicy określa, co stanie się z PV po usunięciu PVC. Można wybrać między trzema opcjami:

1. **Retain**: PV pozostaje w klastrze po usunięciu PVC i może być ponownie użyty.
2. **Delete**: PV jest usuwane po usunięciu PVC.
3. **Recycle**: PV jest usuwane po usunięciu PVC, ale jest dostępny do ponownego użycia.

### StorageClass

StorageClass jest opcjonalnym obiektem, który definiuje sposób tworzenia PV. Można go użyć do grupowania PV o podobnych właściwościach.

Przykład definicji StorageClass:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: manual
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
```

### Przykład użycia PV i PVC

1. **Tworzenie PV i PVC**:
   - Użytkownik tworzy PVC, a Kubernetes próbuje znaleźć odpowiedni PV.
   - Jeśli odpowiedni PV nie istnieje, Kubernetes tworzy nowy PV na podstawie StorageClass.

2. **Powiązanie PVC z PV**:
   - Jeśli odpowiedni PV istnieje, PVC jest powiązane z PV, a użytkownik może korzystać z PV.



