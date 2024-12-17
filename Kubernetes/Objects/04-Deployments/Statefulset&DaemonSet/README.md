# StatefulSet i DaemonSet w Kubernetes

## StatefulSet

### Definicja
StatefulSet jest kontrolerem zarządzającym wdrażaniem i skalowaniem zestawu Podów z gwarancją zachowania unikalnej tożsamości i trwałego stanu dla każdego Poda. W przeciwieństwie do Deployment, StatefulSet utrzymuje stałą nazwę i trwałe storage dla każdego Poda, nawet po jego ponownym uruchomieniu.

### Główne cechy
StatefulSet zapewnia:
1. Stabilną, unikalną tożsamość sieciową dla każdego Poda
2. Trwałe przechowywanie danych
3. Uporządkowane wdrażanie i skalowanie
4. Uporządkowane aktualizacje i rollbacki

### Przykład użycia
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongodb
spec:
  serviceName: mongodb-service
  replicas: 3
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
      - name: mongodb
        image: mongo:4.4
        ports:
        - containerPort: 27017
        volumeMounts:
        - name: data
          mountPath: /data/db
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi
```

### Typowe przypadki użycia
- Bazy danych (MongoDB, PostgreSQL, MySQL)
- Systemy kolejkowe (Kafka, RabbitMQ)
- Aplikacje wymagające stabilnych nazw hostów
- Systemy rozproszone wymagające koordynacji

## DaemonSet

### Definicja
DaemonSet to kontroler zapewniający, że kopia Poda działa na każdym (lub wybranych) węźle klastra. Gdy nowy węzeł jest dodawany do klastra, Pod jest automatycznie na nim tworzony. Gdy węzeł jest usuwany, jego Pody są automatycznie czyszczone.

### Główne cechy
DaemonSet zapewnia:
1. Automatyczne wdrażanie na wszystkich węzłach
2. Automatyczne skalowanie wraz z klastrem
3. Możliwość wyboru konkretnych węzłów poprzez node selectors
4. Gwarancję jednej instancji na węzeł

### Przykład użycia
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: monitoring-agent
spec:
  selector:
    matchLabels:
      app: monitoring-agent
  template:
    metadata:
      labels:
        app: monitoring-agent
    spec:
      containers:
      - name: prometheus-node-exporter
        image: prom/node-exporter
        ports:
        - containerPort: 9100
        volumeMounts:
        - name: proc
          mountPath: /host/proc
          readOnly: true
      volumes:
      - name: proc
        hostPath:
          path: /proc
```

### Typowe przypadki użycia
- Agenty monitoringu (Prometheus Node Exporter)
- Kolektory logów (Fluentd, Logstash)
- Agenty bezpieczeństwa
- Sterowniki storage i sieciowe


## Porównanie z Deployment

### Deployment vs StatefulSet

| Cecha | Deployment | StatefulSet |
|-------|------------|-------------|
| Identyfikator Poda | Losowy | Przewidywalny, sekwencyjny |
| Storage | Współdzielony | Dedykowany dla każdego Poda |
| Skalowanie | Równoległe | Sekwencyjne |
| Aktualizacje | Równoległe | Sekwencyjne |
| Nazwy hostów | Losowe | Stałe |
| Load Balancing | Przez Service | Headless Service |

### Deployment vs DaemonSet

| Cecha | Deployment | DaemonSet |
|-------|------------|-----------|
| Liczba replik | Określona ręcznie | Jedna na węzeł |
| Skalowanie | Manualne/HPA | Automatyczne z klastrem |
| Umiejscowienie | Dowolne węzły | Wszystkie lub wybrane węzły |
| Przypadki użycia | Aplikacje bezstanowe | Agenty i narzędzia infrastruktury |
| Load Balancing | Przez Service | Zwykle niepotrzebne |

## Wybór odpowiedniego kontrolera

1. **Użyj StatefulSet gdy:**
   - Potrzebujesz stabilnych, unikalnych nazw sieciowych
   - Wymagasz trwałego storage dla każdego Poda
   - Potrzebujesz uporządkowanego wdrażania i skalowania
   - Wdrażasz aplikacje stanowe

2. **Użyj DaemonSet gdy:**
   - Potrzebujesz uruchomić Pod na każdym węźle
   - Wdrażasz komponenty monitoringu lub logowania
   - Instalujesz sterowniki węzłów
   - Potrzebujesz jednej instancji na węzeł

3. **Użyj Deployment gdy:**
   - Wdrażasz aplikacje bezstanowe
   - Nie potrzebujesz unikalnych identyfikatorów Podów
   - Chcesz elastycznego skalowania
   - Potrzebujesz szybkich aktualizacji i rollbacków

## Dobre praktyki

### Dla StatefulSet:
1. Zawsze używaj persistent storage
2. Skonfiguruj odpowiednią strategię aktualizacji
3. Użyj Headless Service dla komunikacji między Podami
4. Zaimplementuj proper health checks

### Dla DaemonSet:
1. Używaj node selectors dla precyzyjnego targetowania
2. Limituj zasoby dla Podów
3. Implementuj proper monitoring
4. Uważaj na konflikty zasobów z innymi Podami