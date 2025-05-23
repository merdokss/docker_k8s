# Instalacja i konfiguracja stacku ELK dla Kubernetes

## Wprowadzenie
Stack ELK (Elasticsearch, Logstash, Kibana) to popularne rozwiązanie do zbierania, przetwarzania i wizualizacji logów. W kontekście Kubernetes, możemy wykorzystać Elasticsearch do przechowywania logów, Filebeat do ich zbierania z podów, a Kibana do ich wizualizacji.

## Wymagania
- Kubernetes cluster
- Helm 3
- kubectl
- Minimum 4GB RAM na node
- Minimum 2 CPU cores na node

## Instalacja

### 1. Dodanie repozytorium Elastic Helm
```bash
helm repo add elastic https://helm.elastic.co
helm repo update
```

### 2. Instalacja Elasticsearch
```bash
helm install elasticsearch elastic/elasticsearch \
  --namespace logging \
  --create-namespace \
  --set replicas=1 \
  --set resources.requests.memory=1Gi \
  --set resources.requests.cpu=500m \
  --set resources.limits.memory=2Gi \
  --set resources.limits.cpu=1000m
```

### 3. Instalacja Kibana
```bash
helm install kibana elastic/kibana \
  --namespace logging \
  --set service.type=NodePort \
  --set resources.requests.memory=512Mi \
  --set resources.requests.cpu=250m \
  --set resources.limits.memory=1Gi \
  --set resources.limits.cpu=500m
```

### 4. Instalacja Filebeat
```bash
helm install filebeat elastic/filebeat \
  --namespace logging \
  --set daemonset.enabled=true \
  --set daemonset.filebeatConfig.filebeat\.yml=filebeat\.yml
```

## Konfiguracja Filebeat

Utwórz plik konfiguracyjny `filebeat.yml`:

```yaml
filebeat.inputs:
- type: container
  paths:
    - /var/log/containers/*.log
  processors:
    - add_kubernetes_metadata:
        host: ${NODE_NAME}
        matchers:
        - logs_path:
            logs_path: "/var/log/containers/"

output.elasticsearch:
  hosts: ["elasticsearch-master:9200"]

setup.kibana:
  host: "kibana-kibana:5601"
```

## Weryfikacja instalacji

1. Sprawdź status podów:
```bash
kubectl get pods -n logging
```

2. Uzyskaj dostęp do Kibana:
```bash
kubectl port-forward -n logging svc/kibana-kibana 5601:5601
```

3. Otwórz przeglądarkę i przejdź do `http://localhost:5601`

## Konfiguracja indeksów w Kibana

1. Przejdź do sekcji "Stack Management" w Kibana
2. Wybierz "Index Patterns"
3. Utwórz nowy indeks pattern dla logów: `filebeat-*`
4. Wybierz pole `@timestamp` jako Time field

## Monitorowanie logów

1. Przejdź do sekcji "Discover" w Kibana
2. Wybierz utworzony indeks pattern
3. Możesz teraz przeglądać i filtrować logi z wszystkich podów

## Uwagi dotyczące produkcyjnego środowiska

1. Zwiększ liczbę replik Elasticsearch do minimum 3
2. Skonfiguruj persistent volumes dla Elasticsearch
3. Dostosuj limity zasobów według potrzeb
4. Włącz monitoring i alerting
5. Skonfiguruj backup danych

## Rozwiązywanie problemów

1. Sprawdź logi podów:
```bash
kubectl logs -n logging -l app=elasticsearch-master
kubectl logs -n logging -l app=kibana
kubectl logs -n logging -l app=filebeat
```

2. Sprawdź status Elasticsearch:
```bash
kubectl exec -n logging -it elasticsearch-master-0 -- curl -X GET "localhost:9200/_cluster/health?pretty"
```

## Czyszczenie

Aby usunąć stack ELK:
```bash
helm uninstall filebeat -n logging
helm uninstall kibana -n logging
helm uninstall elasticsearch -n logging
kubectl delete namespace logging
``` 