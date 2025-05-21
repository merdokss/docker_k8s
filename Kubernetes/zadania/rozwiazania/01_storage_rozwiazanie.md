# Rozwiązania - Storage w Kubernetes

## Zadanie 1: PersistentVolume i PersistentVolumeClaim

### 1. Utworzenie PersistentVolume
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-demo
spec:
  capacity:
    storage: 1Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: "/mnt/data"
```

### 2. Utworzenie PersistentVolumeClaim
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-demo
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: manual
  resources:
    requests:
      storage: 500Mi
```

### 3. Weryfikacja
```bash
kubectl get pv
kubectl get pvc
kubectl describe pv pv-demo
kubectl describe pvc pvc-demo
```

## Zadanie 2: StorageClass

### 1. Utworzenie StorageClass
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
```

### 2. Modyfikacja PVC
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-demo
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: fast-storage
  resources:
    requests:
      storage: 500Mi
```

### 3. Weryfikacja
```bash
kubectl get sc
kubectl get pv
kubectl get pvc
```

## Zadanie 3: Dynamiczne Provisioning

### 1. Konfiguracja StorageClass dla AWS EBS
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-sc
provisioner: ebs.csi.aws.com
parameters:
  type: gp2
  encrypted: "true"
```

### 2. Utworzenie PVC
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ebs-sc
  resources:
    requests:
      storage: 1Gi
```

### 3. Weryfikacja
```bash
kubectl get pv
kubectl get pvc
aws ec2 describe-volumes
```

## Zadanie 4: Volume Mounts

### 1. Utworzenie Deployment z PVC
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-with-pvc
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-with-pvc
  template:
    metadata:
      labels:
        app: app-with-pvc
    spec:
      containers:
      - name: app
        image: nginx
        volumeMounts:
        - name: data-volume
          mountPath: /data
      volumes:
      - name: data-volume
        persistentVolumeClaim:
          claimName: pvc-demo
```

### 2. Weryfikacja
```bash
kubectl get pods
kubectl exec -it <nazwa-poda> -- ls /data
kubectl exec -it <nazwa-poda> -- touch /data/test.txt
```


## Przydatne wskazówki:
1. Zawsze sprawdzaj status PV i PVC przed ich użyciem
2. Używaj `kubectl describe` do debugowania problemów
3. Pamiętaj o odpowiednich uprawnieniach do katalogów hosta
4. W przypadku dynamicznego provisioning, upewnij się, że masz odpowiednie uprawnienia w chmurze
5. Regularnie wykonuj backupy ważnych danych 