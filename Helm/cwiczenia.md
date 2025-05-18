1. Zainstaluj Postgresql (https://artifacthub.io/), nadaj haslo "postgresPassword" i stwórz przykladowa DB - spróbuj zalogowac się do tej DB.
2. Zainstaluj Wordpress-a (https://artifacthub.io/), sprawdź czy działa prawidłowo portal.
3. Stwórz własny Helm chart dla nginx i wystaw do values.yaml:
    - livenessProbe
    - readinessProbe
    - env (zmienne środowiskowe)
4. Opcjonalnie - instalacja - https://artifacthub.io/packages/helm/fluent/fluentd
