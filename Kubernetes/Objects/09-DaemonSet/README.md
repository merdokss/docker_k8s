## DaemonSet w Kubernetes

`DaemonSet` to obiekt API Kubernetes, który zapewnia, że kopia Poda działa na każdym (lub określonym zestawie) węźle w klastrze. Gdy węzły są dodawane do klastra, Pody są do nich dodawane. Gdy węzły są usuwane z klastra, te Pody są usuwane (garbage collected).

Usunięcie `DaemonSet` spowoduje wyczyszczenie Podów, które stworzył.

### Kluczowe cechy i zastosowania DaemonSet:

1.  **Uruchamianie na każdym węźle:** Gwarantuje, że dokładnie jedna kopia Poda (lub więcej, jeśli specyfikacja Poda na to pozwala i nie ma konfliktów portów) działa na każdym węźle w klastrze, który pasuje do selektora węzłów `DaemonSet`.
2.  **Automatyczne zarządzanie Podami:** Kubernetes automatycznie zarządza cyklem życia Podów `DaemonSet`. Jeśli węzeł ulegnie awarii, Pod `DaemonSet` na tym węźle zostanie usunięty. Jeśli nowy węzeł zostanie dodany do klastra i pasuje do selektora, nowy Pod zostanie na nim utworzony.
3.  **Typowe przypadki użycia:**
    *   **Agenty monitorowania klastra:** Uruchamianie agenta zbierającego logi (np. Fluentd, Logstash) lub metryki (np. Prometheus Node Exporter, Datadog agent) na każdym węźle.
    *   **Agenty sieciowe:** Uruchamianie wtyczek sieciowych (np. Calico, Flannel) lub proxy sieciowych na każdym węźle.
    *   **Agenty pamięci masowej:** Uruchamianie demonów zarządzających lokalną pamięcią masową na węzłach.
    *   **Narzędzia bezpieczeństwa:** Uruchamianie systemów detekcji intruzów lub skanerów bezpieczeństwa na każdym węźle.

### Jak działają DaemonSety?

*   `DaemonSet` tworzy Pody na węzłach na podstawie selektora węzłów (`spec.template.spec.nodeSelector`) oraz tolerancji (`spec.template.spec.tolerations`).
*   Domyślnie `DaemonSet` uruchomi Poda na każdym węźle w klastrze, chyba że węzeł ma `taint`, którego Pod `DaemonSet` nie toleruje, lub nie pasuje do `nodeSelector`.

### Aktualizacje DaemonSet

Podobnie jak `Deployment`, `DaemonSet` obsługuje strategie aktualizacji:

*   **`RollingUpdate` (domyślna):** Pody są aktualizowane stopniowo, jeden po drugim. Po zaktualizowaniu Poda na węźle i jego przejściu w stan `Ready`, kontroler `DaemonSet` przechodzi do aktualizacji Poda na następnym węźle.
*   **`OnDelete`:** Pody są aktualizowane tylko wtedy, gdy zostaną ręcznie usunięte. Nowe Pody zostaną utworzone z nową konfiguracją.

Można również kontrolować proces `RollingUpdate` za pomocą `maxUnavailable` (ile Podów może być niedostępnych podczas aktualizacji) i `maxSurge` (ile dodatkowych Podów można utworzyć ponad żądaną liczbę, chociaż dla `DaemonSet` `maxSurge` często nie jest tak istotne, ponieważ celem jest jeden Pod na węzeł).

### Przykład: Prosty DaemonSet z Fluentd (jako przykład agenta logowania)

Poniżej znajduje się przykład `DaemonSet`, który mógłby uruchamiać agenta Fluentd na każdym węźle w klastrze w celu zbierania logów.

**Definicja DaemonSet (`daemonset-example.yaml`):**

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd-elasticsearch
  namespace: kube-system # Często DaemonSety systemowe są umieszczane w kube-system
  labels:
    k8s-app: fluentd-logging
spec:
  selector:
    matchLabels:
      name: fluentd-elasticsearch
  template:
    metadata:
      labels:
        name: fluentd-elasticsearch
    spec:
      # Tolerancje są często potrzebne, aby DaemonSet mógł działać na węzłach master/control-plane
      # jeśli jest to wymagane. Poniższa tolerancja pozwala na uruchomienie na węzłach master.
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      - key: node-role.kubernetes.io/master # Starsza etykieta dla master
        operator: Exists
        effect: NoSchedule
      containers:
      - name: fluentd
        image: fluent/fluentd-kubernetes-daemonset:v1.16-debian-elasticsearch7-1.0 # Przykładowy obraz
        # W rzeczywistym scenariuszu, tutaj byłaby konfiguracja Fluentd,
        # często poprzez ConfigMap i montowanie woluminów.
        env:
          - name: FLUENT_ELASTICSEARCH_HOST
            value: "elasticsearch-logging.kube-system.svc.cluster.local" # Przykład
          - name: FLUENT_ELASTICSEARCH_PORT
            value: "9200" # Przykład
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
      terminationGracePeriodSeconds: 30
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
```

**Wyjaśnienie kluczowych pól:**

*   `metadata.namespace: kube-system`: `DaemonSety` często wdraża się w przestrzeni nazw `kube-system`, ponieważ są to zwykle komponenty infrastrukturalne klastra.
*   `spec.selector`: Określa, które Pody są zarządzane przez ten `DaemonSet`.
*   `spec.template.spec.tolerations`: Pozwala Podom `DaemonSet` być planowanym na węzłach, które mają określone `taints`. Na przykład, węzły `control-plane` (master) często mają `taint`, który uniemożliwia planowanie zwykłych Podów. `DaemonSety` często potrzebują działać również na tych węzłach.
*   `spec.template.spec.containers.volumeMounts` i `spec.template.spec.volumes`: W tym przykładzie Fluentd montuje katalogi `/var/log` i `/var/lib/docker/containers` z hosta (węzła), aby uzyskać dostęp do logów kontenerów i systemu.
*   `hostPath` volumes: Umożliwiają dostęp do systemu plików węzła. Należy używać ich ostrożnie, ponieważ wiążą Poda z konkretnym węzłem i mogą stwarzać zagrożenia bezpieczeństwa, jeśli Pod zostanie skompromitowany.

### Uruchamianie przykładu:

1.  Zapisz powyższą definicję jako `daemonset-example.yaml`.
2.  Zastosuj ją w klastrze:
    ```bash
    kubectl apply -f daemonset-example.yaml
    ```
3.  Sprawdź status:
    ```bash
    kubectl get daemonset fluentd-elasticsearch -n kube-system
    kubectl get pods -n kube-system -l name=fluentd-elasticsearch -o wide
    # Powinieneś zobaczyć Poda fluentd-elasticsearch uruchomionego na każdym (lub wybranym) węźle.
    ```

### Kiedy nie używać DaemonSet?

*   Jeśli potrzebujesz uruchomić aplikację, która nie musi działać na każdym węźle (użyj `Deployment` lub `StatefulSet`).
*   Jeśli zadanie ma być wykonane tylko raz na każdym węźle (rozważ `Job` z odpowiednim targetowaniem lub skryptem uruchamianym przy starcie węzła).

### Podsumowanie

`DaemonSet` jest idealnym rozwiązaniem do wdrażania agentów i demonów, które muszą działać na wszystkich lub wybranych węzłach w klastrze Kubernetes, zapewniając spójne środowisko i usługi na poziomie węzła. 