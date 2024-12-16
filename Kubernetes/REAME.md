# Podstawy Kubernetes (K8s)

## Co to jest Kubernetes?

Kubernetes (K8s) to otwartoźródłowy system do automatyzacji wdrażania, skalowania i zarządzania aplikacjami kontenerowymi. Został pierwotnie zaprojektowany przez Google i jest obecnie rozwijany przez Cloud Native Computing Foundation.

Główne cechy Kubernetes:
- Automatyczne zarządzanie kontenerami
- Skalowanie horyzontalne
- Samonaprawa
- Zarządzanie konfiguracją
- Odkrywanie usług i równoważenie obciążenia
- Automatyczne aktualizacje i wycofywanie zmian

## Praca z Kubernetes CLI (kubectl)

Kubectl to narzędzie wiersza poleceń do kontrolowania klastrów Kubernetes. Poniżej znajduje się lista najważniejszych komend wraz z ich opisami.

### Cluster

- `kubectl get nodes` - Wyświetla listę wszystkich węzłów w klastrze
- `kubectl cluster-info` - Wyświetla informacje o klastrze, w tym adresy API serwera i DNS
- `kubectl version` - Pokazuje wersję klienta kubectl i serwera Kubernetes
- `kubectl config view` - Wyświetla bieżącą konfigurację kubectl
- `kubectl api-resources` - Lista wszystkich dostępnych zasobów API w klastrze
- `kubectl get all --all-namespaces` - Wyświetla wszystkie zasoby we wszystkich przestrzeniach nazw
- `kubectl get namespaces` - Lista wszystkich przestrzeni nazw w klastrze

### Pod, Jobs, Services
- `kubectl get pods` - Wyświetla listę wszystkich podów w bieżącej przestrzeni nazw
- `kubectl logs my-pod` - Wyświetla logi z określonego poda
- `kubectl get pod my-pod -o yaml` - Pokazuje szczegółowy opis definicji poda w formacie YAML, wraz z jego statusem
- `kubectl describe pod my-pod` - Wyświetla szczegółowe informacje o podzie, w tym zdarzenia i stan
- `kubectl port-forward my-pod 5000:6000` - Przekierowuje port 5000 na lokalnym hoście do portu 6000 w podzie
- `kubectl port-forward svc/my-service-clusterip 8888:88` - Przekierowuje port 8888 na lokalnym hoście do portu 88 w usłudze ClusterIP
- `kubectl exec -it my-pod -- ls` - Wykonuje polecenie 'ls' w interaktywnym trybie wewnątrz poda
- `kubectl exec my-pod -c my-container -- ls` - Wykonuje polecenie 'ls' w określonym kontenerze wewnątrz poda
- `kubectl top pod POD_NAME --containers` - Pokazuje zużycie zasobów (CPU i pamięci) dla określonego poda i jego kontenerów

### Deployment
- `kubectl scale --replicas=3 deployment/nginx` - Skaluje deployment nginx do 3 replik
- `kubectl autoscale deployment/nginx --min=2 --max=6 --cpu-percent=80` - Konfiguruje autoskalowanie dla deploymentu nginx
- `kubectl set image deploy/nginx nginx=nginx:1.18-alpine --record=true` - Aktualizuje obraz kontenera w deploymencie nginx
- `kubectl set resources deploy/nginx -c=nginx --limits=cpu=200m,memory=512Mi` - Ustawia limity zasobów dla kontenerów w deploymencie nginx
- `kubectl rollout history deploy/nginx` - Wyświetla historię wdrożeń dla deploymentu nginx
- `kubectl rollout status deploy/nginx` - Pokazuje status bieżącego wdrożenia
- `kubectl rollout undo deploy/nginx` - Cofa ostatnie wdrożenie
- `kubectl rollout undo deploy/nginx --to-revision=2` - Cofa wdrożenie do określonej rewizji

### Secrets
- `kubectl create secret docker-registry external-registry --docker-server=testk8sworkshop.azurecr.io --docker-username=testk8sworkshop --docker-password=LwN5mAqTGOz4YH7h84Yd6xgGSQ/zjgVf` - Tworzy sekret do uwierzytelniania w prywatnym rejestrze kontenerów
- `kubectl create secret generic mysql --from-literal=root-password='ir2pYdwKea'` - Tworzy ogólny sekret z hasłem do MySQL

###  ConfigMaps
- `kubectl create configmap httpd-conf --from-file=Kubernetes/Objects/05-SecretsConfigMaps/httpd.conf` - Tworzy ConfigMap z pliku konfiguracyjnego Apache

### Dodatkowe przydatne komendy

- `kubectl apply -f filename.yaml` - Tworzy lub aktualizuje zasoby zdefiniowane w pliku YAML
- `kubectl delete -f filename.yaml` - Usuwa zasoby zdefiniowane w pliku YAML
- `kubectl get events` - Wyświetla zdarzenia w klastrze
- `kubectl get pv` - Lista wszystkich trwałych wolumenów (Persistent Volumes)
- `kubectl get pvc` - Lista wszystkich żądań trwałych wolumenów (Persistent Volume Claims)
- `kubectl get ingress` - Wyświetla listę wszystkich zasobów Ingress

### Materiały i linki

- Kubernetes - CheatSheet - https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Deployment Strategy - https://spot.io/resources/kubernetes-autoscaling/5-kubernetes-deployment-strategies-roll-out-like-the-pros/
- Secrets - https://medium.com/avmconsulting-blog/secrets-management-in-kubernetes-378cbf8171d0
- Kubernetes Storage Class - https://kubernetes.io/docs/concepts/storage/storage-classes/
- Kuberetes CronJob - https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/
- Kubernetes Liveness, Readiness Probes - https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- Kubectx & Kubens - zmiana context klastra + zmiana namespaces -  https://github.com/ahmetb/kubectx