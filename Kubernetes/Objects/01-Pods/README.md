# Przykłady Podów - Materiały demonstracyjne

Ten katalog zawiera przykłady Podów do demonstracji podczas zajęć. Przykłady pokazują różne aspekty i możliwości konfiguracji Podów w Kubernetes.

## Lista przykładów

### Podstawowe przykłady

1. **pod.yaml** - Najprostszy przykład Poda z nginx
   - Podstawowa struktura
   - Etykiety
   - Port kontenera

2. **pod-limits.yaml** - Pod z limitami zasobów
   - Requests i limits dla CPU i pamięci
   - Przykład zarządzania zasobami

### Zaawansowane przykłady

3. **pod-multi-container.yaml** - Pod z wieloma kontenerami
   - Dwa kontenery w jednym Podzie
   - Współdzielony volume (emptyDir)
   - Komunikacja między kontenerami

4. **pod-env-vars.yaml** - Pod ze zmiennymi środowiskowymi
   - Definicja zmiennych środowiskowych
   - Przykładowe wartości

5. **pod-command-args.yaml** - Pod z command i args
   - Nadpisywanie ENTRYPOINT i CMD
   - Różnica między command a args
   - Różnica między Dockerem a Kubernetes

6. **pod-restart-policy.yaml** - Pod z różnymi restart policies
   - Always, OnFailure, Never
   - Przykład OnFailure

