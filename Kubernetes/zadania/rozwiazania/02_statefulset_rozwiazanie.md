# Rozwiązania - StatefulSet w Kubernetes

## Zadanie 1: Podstawowy StatefulSet

### 1. Utworzenie Headless Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app
  labels:
    app: web-app
spec:
  ports:
  - port: 80
    name: web
  clusterIP: None
  selector:
    app: web-app
```

### 2. Utworzenie StatefulSet
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web-app
spec:
  serviceName: "web-app"
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
        image: nginx:1.21
        ports:
        - containerPort: 80
          name: web
```

### 3. Weryfikacja
```bash
kubectl get statefulset
kubectl get pods
kubectl get svc
```

## Zadanie 2: Persistent Storage dla StatefulSet

### 1. Utworzenie StorageClass
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
```
#### Utwórz odpowiednie PV
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-sts1
spec:
  capacity:
    storage: 1Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: fast-storage
  hostPath:
    path: "/mnt/data"
```
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-sts2
spec:
  capacity:
    storage: 1Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: fast-storage
  hostPath:
    path: "/mnt/data"
```

### 2. Modyfikacja StatefulSet z volumeClaimTemplates
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web-app
spec:
  serviceName: "web-app"
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
        image: nginx:1.21
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "fast-storage"
      resources:
        requests:
          storage: 1Gi
```

### 3. Weryfikacja
```bash
kubectl get pvc
kubectl get pods
kubectl describe statefulset web-app
```

## Zadanie 3: Konfiguracja Pod Management Policy

### 1. Modyfikacja StatefulSet z Parallel Policy
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web-app
spec:
  serviceName: "web-app"
  replicas: 3
  podManagementPolicy: Parallel
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
        image: nginx:1.21
        ports:
        - containerPort: 80
          name: web
```

### 2. Wykonanie rolling update
```bash
kubectl set image statefulset/web-app nginx=nginx:1.22
```

### 3. Weryfikacja
```bash
kubectl get pods -w
kubectl describe statefulset web-app
```

## Zadanie 4: StatefulSet z Init Containers

### 1. Modyfikacja StatefulSet z Init Container
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web-app
spec:
  serviceName: "web-app"
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      initContainers:
      - name: init-data
        image: busybox
        command: ["sh", "-c", "echo 'Hello from $(hostname)' > /usr/share/nginx/html/index.html"]
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "fast-storage"
      resources:
        requests:
          storage: 1Gi
```

### 2. Weryfikacja
```bash
kubectl get pods
kubectl logs web-app-0 -c init-data
kubectl exec -it web-app-0 -- cat /usr/share/nginx/html/index.html
```

## Zadanie 5: StatefulSet z Readiness Probe

### 1. Modyfikacja StatefulSet z Readiness Probe
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web-app
spec:
  serviceName: "web-app"
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
        image: nginx:1.21
        ports:
        - containerPort: 80
          name: web
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
```

### 2. Weryfikacja
```bash
kubectl get pods
kubectl describe pod web-app-0
kubectl get endpoints web-app
```

## Przydatne wskazówki:
1. Zawsze używaj headless service dla StatefulSet
2. Pamiętaj o odpowiedniej konfiguracji volumeClaimTemplates
3. Używaj readiness probe do zapewnienia poprawnego działania aplikacji
4. Monitoruj status podów podczas rolling update
5. Zwracaj uwagę na kolejność uruchamiania podów w StatefulSet 