# Rozwiązania - DaemonSet w Kubernetes

## Zadanie 1: Podstawowy DaemonSet

### 1. Utworzenie DaemonSet
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: logging-agent
  labels:
    app: logging-agent
spec:
  selector:
    matchLabels:
      app: logging-agent
  template:
    metadata:
      labels:
        app: logging-agent
    spec:
      containers:
      - name: fluentd
        image: fluent/fluentd:v1.12
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
```

### 2. Weryfikacja
```bash
kubectl get daemonset
kubectl get pods -o wide
kubectl describe daemonset logging-agent
```

## Zadanie 2: Node Selector i Tolerations

### 1. Modyfikacja DaemonSet z Node Selector i Tolerations
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: logging-agent
  labels:
    app: logging-agent
spec:
  selector:
    matchLabels:
      app: logging-agent
  template:
    metadata:
      labels:
        app: logging-agent
    spec:
      nodeSelector:
        monitoring: "enabled"
      tolerations:
      - key: monitoring
        operator: Equal
        value: "true"
        effect: NoSchedule
      containers:
      - name: fluentd
        image: fluent/fluentd:v1.12
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
```

### 2. Weryfikacja
```bash
# Dodanie etykiety do węzła
kubectl label nodes <nazwa-wezla> monitoring=enabled

# Dodanie tainta do węzła
kubectl taint nodes <nazwa-wezla> monitoring=true:NoSchedule

# Sprawdzenie statusu
kubectl get pods -o wide
kubectl describe daemonset logging-agent
```

## Zadanie 3: Rolling Update

### 1. Modyfikacja DaemonSet z Rolling Update
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: logging-agent
  labels:
    app: logging-agent
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  selector:
    matchLabels:
      app: logging-agent
  template:
    metadata:
      labels:
        app: logging-agent
    spec:
      containers:
      - name: fluentd
        image: fluent/fluentd:v1.12
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
```

### 2. Wykonanie update
```bash
kubectl set image daemonset/logging-agent fluentd=fluent/fluentd:v1.13
```

### 3. Weryfikacja
```bash
kubectl get pods -w
kubectl describe daemonset logging-agent
```

## Zadanie 4: DaemonSet z Volume Mounts

### 1. Modyfikacja DaemonSet z Volume Mounts
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: logging-agent
  labels:
    app: logging-agent
spec:
  selector:
    matchLabels:
      app: logging-agent
  template:
    metadata:
      labels:
        app: logging-agent
    spec:
      containers:
      - name: fluentd
        image: fluent/fluentd:v1.12
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
        - name: fluentd-config
          mountPath: /fluentd/etc
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
      - name: fluentd-config
        configMap:
          name: fluentd-config
```

### 2. Utworzenie ConfigMap
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
data:
  fluent.conf: |
    <source>
      @type tail
      path /var/log/containers/*.log
      pos_file /var/log/fluentd-containers.log.pos
      tag kubernetes.*
      read_from_head true
      <parse>
        @type json
        time_format %Y-%m-%dT%H:%M:%S.%NZ
      </parse>
    </source>
    <match kubernetes.**>
      @type stdout
    </match>
```

### 3. Weryfikacja
```bash
kubectl get configmap
kubectl get pods
kubectl logs <nazwa-poda>
```

## Zadanie 5: DaemonSet z Resource Limits

### 1. Modyfikacja DaemonSet z Resource Limits
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: logging-agent
  labels:
    app: logging-agent
spec:
  selector:
    matchLabels:
      app: logging-agent
  template:
    metadata:
      labels:
        app: logging-agent
    spec:
      containers:
      - name: fluentd
        image: fluent/fluentd:v1.12
        resources:
          limits:
            cpu: 200m
            memory: 300Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
```

### 2. Weryfikacja
```bash
kubectl get pods
kubectl top pods
kubectl describe pod <nazwa-poda>
```

## Przydatne wskazówki:
1. Zawsze definiuj limity zasobów dla kontenerów
2. Używaj node selector i tolerations do kontroli, gdzie uruchamiają się pody
3. Monitoruj zużycie zasobów przez DaemonSet
4. Pamiętaj o odpowiednich uprawnieniach do katalogów hosta
5. Używaj rolling update do bezpiecznej aktualizacji DaemonSet 