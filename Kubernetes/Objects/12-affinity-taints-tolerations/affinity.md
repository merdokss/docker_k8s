# NodeAffinity - Operators 🎯


## Operatory wyjaśnione

### 1. **In** - "Pod musi trafić na node z JEDNĄ z tych wartości"
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: frontend
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd
            - nvme
  containers:
  - name: nginx
    image: nginx
```

**Znaczenie:** Pod trafi TYLKO na nody, które mają label `disktype=ssd` LUB `disktype=nvme`

---

### 2. **NotIn** - "Pod NIE MOŻE trafić na nody z tymi wartościami"
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: batch-job
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: workload
            operator: NotIn
            values:
            - production
            - critical
  containers:
  - name: processor
    image: batch-processor
```

**Znaczenie:** Pod trafi na node, który NIE ma labela `workload=production` ani `workload=critical`

---

### 3. **Exists** - "Pod potrzebuje noda z tym labelem (wartość nieważna)"
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: monitoring
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: monitoring-enabled
            operator: Exists
  containers:
  - name: prometheus
    image: prometheus
```

**Znaczenie:** Pod trafi na node, który ma label `monitoring-enabled` (wartość może być DOWOLNA: true, false, yes, xyz - nieważne!)

---

### 4. **DoesNotExist** - "Pod potrzebuje noda BEZ tego labela"
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: public-app
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: restricted-zone
            operator: DoesNotExist
  containers:
  - name: webapp
    image: public-webapp
```

**Znaczenie:** Pod trafi TYLKO na nody, które NIE MAJĄ labela `restricted-zone`

---

### 5. **Gt** (Greater than) - "Wartość musi być większa od"
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: memory-intensive
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: memory-gb
            operator: Gt
            values:
            - "64"
  containers:
  - name: big-data
    image: spark
```

**Znaczenie:** Pod trafi na node z labelem `memory-gb` większym niż 64

---

### 6. **Lt** (Less than) - "Wartość musi być mniejsza od"
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: small-workload
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: cpu-cores
            operator: Lt
            values:
            - "8"
  containers:
  - name: lightweight
    image: small-app
```

**Znaczenie:** Pod trafi na node z labelem `cpu-cores` mniejszym niż 8

---

## Tabela porównawcza operatorów

| Operator | Potrzebuje wartości? | Przykład użycia |
|----------|---------------------|-----------------|
| **In** | TAK (lista) | "Chcę SSD lub NVMe" |
| **NotIn** | TAK (lista) | "Nie chcę na produkcji" |
| **Exists** | NIE | "Musi mieć GPU (dowolne)" |
| **DoesNotExist** | NIE | "Nie może mieć ograniczeń" |
| **Gt** | TAK (jedna liczba) | "Więcej niż 64GB RAM" |
| **Lt** | TAK (jedna liczba) | "Mniej niż 8 rdzeni" |

--