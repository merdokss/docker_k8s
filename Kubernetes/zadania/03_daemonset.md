# Zadania - DaemonSet w Kubernetes

## Zadanie 1: Podstawowy DaemonSet
1. Utwórz DaemonSet o nazwie `logging-agent`, który będzie uruchamiał kontener z Fluentd na każdym węźle.
2. Skonfiguruj DaemonSet tak, aby używał obrazu `fluent/fluentd:v1.12`.
3. Zweryfikuj, czy DaemonSet został poprawnie wdrożony na wszystkich węzłach.

## Zadanie 2: Node Selector i Tolerations
1. Dodaj node selector do DaemonSet, aby uruchamiał się tylko na węzłach z etykietą `monitoring=enabled`.
2. Skonfiguruj tolerations, aby DaemonSet mógł działać na węzłach z taintem `monitoring:NoSchedule`.
3. Zweryfikuj, czy DaemonSet działa tylko na wybranych węzłach.

## Zadanie 3: Rolling Update
1. Wykonaj rolling update DaemonSet do nowej wersji obrazu.
2. Skonfiguruj strategię aktualizacji, aby pody były aktualizowane jeden po drugim.
3. Monitoruj proces aktualizacji i zweryfikuj, czy wszystkie pody zostały poprawnie zaktualizowane.

## Zadanie 4: DaemonSet z Volume Mounts
1. Skonfiguruj DaemonSet, aby montował katalog `/var/log` z hosta do kontenera.
2. Dodaj konfigurację, która będzie zbierać logi z zamontowanego katalogu.
3. Zweryfikuj, czy logi są poprawnie zbierane przez agenta.

## Zadanie 5: DaemonSet z Resource Limits
1. Dodaj limity zasobów (CPU i pamięć) do kontenerów w DaemonSet.
2. Skonfiguruj requests dla zasobów.
3. Zweryfikuj, czy limity są poprawnie stosowane przez sprawdzenie metryk podów.

## Wymagania:
- Znajomość podstawowych konceptów Kubernetes
- Dostęp do klastra Kubernetes
- Narzędzia: kubectl, metrics-server (opcjonalnie)

## Przydatne komendy:
```bash
kubectl get daemonset
kubectl get pods -o wide
kubectl describe daemonset <nazwa-daemonset>
kubectl logs <nazwa-poda>
kubectl top pods
``` 