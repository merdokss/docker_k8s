# Ćwiczenia Helm

1. Zainstaluj Postgresql z [Artifact Hub](https://artifacthub.io/), nadaj hasło "postgresPassword" i stwórz przykładową DB - spróbuj zalogować się do tej DB.
2. Zainstaluj Wordpress-a z [Artifact Hub](https://artifacthub.io/), sprawdź czy działa prawidłowo portal.
3. Zainstaluj MongoDB dla ToDos
4. Stwórz własny Helm chart dla ToDos i wystaw do values.yaml:
    - livenessProbe
    - readinessProbe
    - env (zmienne środowiskowe)
    - secret
5. Opcjonalnie - instalacja [Fluentd](https://artifacthub.io/packages/helm/fluent/fluentd)
