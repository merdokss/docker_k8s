## StatefulSet w Kubernetes

`StatefulSet` to obiekt API Kubernetes używany do zarządzania aplikacjami stanowymi. Podobnie jak `Deployment`, `StatefulSet` zarządza Podami, które są oparte na identycznej specyfikacji kontenera. Jednak w przeciwieństwie do `Deployment`, `StatefulSet` utrzymuje stałą tożsamość dla każdego ze swoich Podów. Te Pody są tworzone z tej samej specyfikacji, ale nie są wymienne: każdy ma trwały identyfikator, który utrzymuje przez jakiekolwiek przeplanowanie.

Jeśli chcesz używać woluminów pamięci masowej do zapewnienia trwałości dla swojego obciążenia, możesz użyć `StatefulSet` jako części rozwiązania. Chociaż poszczególne Pody w `StatefulSet` są podatne na awarie, trwałe identyfikatory Podów ułatwiają dopasowanie istniejących trwałych woluminów do nowych Podów, które zastępują te, które uległy awarii.

### Kluczowe cechy i zastosowania StatefulSet:

1.  **Stabilne, unikalne identyfikatory sieciowe:**
    *   Każdy Pod w `StatefulSet` otrzymuje stabilną nazwę hosta opartą na jego nazwie i porządkowym indeksie (np. `web-0`, `web-1`).
    *   Te nazwy hosta są rozwiązywalne wewnątrz klastra (jeśli używasz `Headless Service`).

2.  **Stabilne, trwałe przechowywanie danych:**
    *   Dla każdego Poda w `StatefulSet` można dynamicznie lub statycznie zaalokować `PersistentVolume`.
    *   `PersistentVolumeClaim` (PVC) jest tworzony dla każdego Poda (np. `data-web-0`, `data-web-1`).
    *   Gdy Pod jest przeplanowywany (np. z powodu awarii węzła), ten sam PVC jest ponownie montowany do Poda o tym samym identyfikatorze, zapewniając ciągłość danych.

3.  **Uporządkowane, płynne wdrażanie i skalowanie (Ordered, graceful deployment and scaling):**
    *   Pody są tworzone, aktualizowane i usuwane w ściśle określonej kolejności (od 0 do N-1 dla tworzenia/aktualizacji, od N-1 do 0 dla usuwania).
    *   Przed utworzeniem/aktualizacją/usunięciem następnego Poda, poprzedni Pod musi być w stanie `Running` i `Ready` (lub całkowicie zakończony w przypadku usuwania).
    *   Jest to przydatne dla aplikacji, które wymagają stabilnego porządku uruchamiania lub zamykania, np. bazy danych z replikacją master-slave.

4.  **Uporządkowane, automatyczne aktualizacje (Ordered, automated rolling updates):**
    *   Aktualizacje są stosowane do Podów w odwrotnej kolejności porządkowej (od N-1 do 0) lub zgodnie ze strategią partycjonowania.

### Kiedy używać StatefulSet?

`StatefulSet` jest odpowiedni dla aplikacji, które wymagają jednego lub więcej z poniższych:

*   Stabilnych, unikalnych identyfikatorów sieciowych.
*   Stabilnego, trwałego przechowywania danych.
*   Uporządkowanego, płynnego wdrażania i skalowania.
*   Uporządkowanych, automatycznych aktualizacji.

Przykłady aplikacji to:
*   Bazy danych klastrowe (np. Cassandra, MySQL, PostgreSQL, MongoDB) z replikacją.
*   Systemy kolejkowania wiadomości (np. Kafka, RabbitMQ).
*   Inne aplikacje stanowe, które polegają na stabilnej tożsamości sieciowej lub trwałym przechowywaniu danych per instancja.

### Headless Service dla StatefulSet

`StatefulSet` często wymaga `Headless Service` do kontrolowania domeny swoich Podów i umożliwienia innym aplikacjom komunikacji z konkretnymi instancjami Poda poprzez ich stabilne nazwy DNS.
`Headless Service` nie posiada `ClusterIP` i zamiast tego, gdy jest wyszukiwany przez DNS, zwraca adresy IP Podów, które są częścią tego serwisu i pasują do jego selektora.

Nazwa `Headless Service` jest podawana w polu `serviceName` specyfikacji `StatefulSet`.

### Przykład: Prosty StatefulSet z Nginx

Poniżej znajduje się przykład prostego `StatefulSet`, który uruchamia 3 repliki Nginx. Każda replika będzie miała stabilną nazwę hosta i (w bardziej zaawansowanym przykładzie) mogłaby mieć własny, trwały wolumin.

**1. Definicja Headless Service (`headless-service.yaml`):**

Ten serwis jest potrzebny, aby Pody `StatefulSet` miały unikalne wpisy DNS.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-headless
  labels:
    app: nginx-sts
spec:
  ports:
  - port: 80
    name: web
  clusterIP: None # Kluczowe dla Headless Service
  selector:
    app: nginx-sts # Musi pasować do etykiet Podów StatefulSet
```

**2. Definicja StatefulSet (`statefulset-example.yaml`):**

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: "nginx-headless" # Nazwa Headless Service
  replicas: 3
  selector:
    matchLabels:
      app: nginx-sts # Musi pasować do etykiet w szablonie Poda i selektorze Headless Service
  template:
    metadata:
      labels:
        app: nginx-sts
    spec:
      terminationGracePeriodSeconds: 10
      containers:
      - name: nginx
        image: registry.k8s.io/nginx-slim:0.8
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  # Definicja szablonu PersistentVolumeClaim (opcjonalna, ale typowa dla StatefulSet)
  # W tym prostym przykładzie bez PV, Pody nie będą miały trwałego przechowywania danych.
  # Aby dodać trwałe przechowywanie, odkomentuj i dostosuj poniższą sekcję:
  volumeClaimTemplates:
  - metadata:
      name: www # Nazwa PVC, np. www-web-0, www-web-1
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "standard" # Użyj odpowiedniej StorageClass dla Twojego klastra
      resources:
        requests:
          storage: 1Gi
```

**Wyjaśnienie `volumeClaimTemplates`:**

*   Jeśli sekcja `volumeClaimTemplates` jest zdefiniowana, `StatefulSet` automatycznie utworzy `PersistentVolumeClaim` dla każdej repliki.
*   Nazwa PVC będzie miała format `<nazwa-volumeClaimTemplate>-<nazwa-StatefulSet>-<indeks-repliki>` (np. `www-web-0`, `www-web-1`).
*   Każdy PVC będzie żądał woluminu zgodnie ze specyfikacją (accessModes, storageClassName, resources).
*   Aby to działało, musisz mieć skonfigurowany dynamiczny provisioner pamięci masowej w klastrze lub ręcznie utworzone `PersistentVolumes`, które pasują do tych żądań.

### Uruchamianie przykładu:

1.  Zapisz powyższe definicje jako `headless-service.yaml` i `statefulset-example.yaml`.
2.  Zastosuj je w klastrze:
    ```bash
    kubectl apply -f headless-service.yaml
    kubectl apply -f statefulset-example.yaml
    ```
3.  Sprawdź status:
    ```bash
    kubectl get service nginx-headless
    kubectl get statefulset web
    kubectl get pods -l app=nginx-sts # Zobaczysz pody web-0, web-1, web-2
    # Jeśli użyłeś volumeClaimTemplates:
    kubectl get pvc -l app=nginx-sts
    ```
4.  Testowanie stabilnych nazw hosta (z innego Poda w klastrze):
    ```bash
    # Uruchom tymczasowego Poda do testów DNS
    kubectl run dns-utils --image=registry.k8s.io/e2e-test-images/jessie-dnsutils:1.3 --rm -it -- /bin/bash

    # Wewnątrz Poda dns-utils:
    # nslookup web-0.nginx-headless
    # nslookup web-1.nginx-headless
    # nslookup web-2.nginx-headless
    # Każde z tych poleceń powinno zwrócić adres IP odpowiedniego Poda.
    # exit
    ```

### Skalowanie StatefulSet:

```bash
kubectl scale statefulset web --replicas=5
# Pody web-3 i web-4 zostaną utworzone (oraz ich PVC, jeśli zdefiniowano).

kubectl scale statefulset web --replicas=2
# Pody web-2 (a następnie web-1, jeśli skalujesz dalej) zostaną usunięte (oraz ich PVC, jeśli polityka odzyskiwania to Delete).
```

### Aktualizacja StatefulSet:

Aktualizacje `StatefulSet` (np. zmiana obrazu kontenera) są stosowane w sposób uporządkowany, podobnie jak przy skalowaniu. Domyślną strategią jest `RollingUpdate`.
Można kontrolować proces aktualizacji za pomocą pola `spec.updateStrategy.rollingUpdate.partition`.

### Podsumowanie

`StatefulSet` jest potężnym narzędziem do zarządzania aplikacjami stanowymi w Kubernetes, zapewniając stabilne identyfikatory, trwałe przechowywanie danych oraz uporządkowane operacje. Jest kluczowym komponentem dla wielu typów aplikacji rozproszonych, takich jak bazy danych czy systemy kolejkowania. 