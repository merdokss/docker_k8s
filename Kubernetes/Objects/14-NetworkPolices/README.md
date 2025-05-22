# Network Policies w Kubernetes

## Wprowadzenie

Network Policies w Kubernetes to mechanizm, który pozwala na kontrolowanie przepływu ruchu sieciowego między Podami w klastrze. Działają one podobnie do firewalli, ale na poziomie klastra Kubernetes.

## Podstawowe zasady działania

1. **Domyślne zachowanie:**
   - Bez Network Policy: wszystkie połączenia są dozwolone
   - Z Network Policy: wszystkie połączenia są domyślnie blokowane (deny by default)

2. **Typy polityk:**
   - `Ingress` - kontroluje ruch przychodzący do Poda
   - `Egress` - kontroluje ruch wychodzący z Poda

## Selektory w Network Policies

1. **PodSelector:**
   ```yaml
   podSelector:
     matchLabels:
       app: frontend
   ```
   - Wybiera Pody na podstawie ich etykiet
   - Może być używany w sekcjach `from` i `to`

2. **NamespaceSelector:**
   ```yaml
   namespaceSelector:
     matchLabels:
       name: prod
   ```
   - Wybiera Pody z określonych namespace'ów
   - Przydatne przy izolacji środowisk

3. **IPBlock:**
   ```yaml
   ipBlock:
     cidr: 10.0.0.0/24
     except:
     - 10.0.0.1/32
   ```
   - Pozwala na określenie zakresów IP
   - Można wykluczyć konkretne adresy IP

## Porty i protokoły

1. **Definiowanie portów:**
   ```yaml
   ports:
   - protocol: TCP
     port: 80
   - protocol: UDP
     port: 53
   ```
   - Można określić protokół (TCP/UDP)
   - Można określić konkretny port lub zakres portów

## Przykłady użycia

1. **Izolacja Poda:**
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: isolate-pod
   spec:
     podSelector:
       matchLabels:
         app: database
     policyTypes:
     - Ingress
     ingress:
     - from:
       - podSelector:
           matchLabels:
             app: api
   ```

2. **Izolacja Namespace:**
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: isolate-namespace
   spec:
     podSelector: {}
     policyTypes:
     - Ingress
     ingress:
     - from:
       - namespaceSelector:
           matchLabels:
             name: prod
   ```

3. **Kontrola ruchu wychodzącego:**
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: egress-policy
   spec:
     podSelector:
       matchLabels:
         app: restricted
     policyTypes:
     - Egress
     egress:
     - to:
       - ipBlock:
           cidr: 8.8.8.8/32
       ports:
       - protocol: TCP
         port: 443
   ```

## Ważne aspekty do rozważenia

1. **DNS:**
   - Pamiętaj o dodaniu reguł dla DNS (port 53/UDP)
   - Bez tego Pody nie będą mogły rozwiązywać nazw

2. **Kube-system:**
   - Niektóre usługi wymagają dostępu do namespace kube-system
   - Dodaj odpowiednie reguły jeśli jest to potrzebne

3. **Health checks:**
   - Upewnij się, że health checks mogą dotrzeć do Poda
   - Dotyczy to zarówno readiness jak i liveness probes

## Testowanie Network Policies

1. **Podstawowe komendy:**
   ```bash
   # Sprawdź istniejące Network Policies
   kubectl get networkpolicy
   
   # Zobacz szczegóły Network Policy
   kubectl describe networkpolicy <nazwa>
   ```

2. **Testowanie połączeń:**
   ```bash
   # Test połączenia z innego Poda
   kubectl exec -it <pod> -- curl <cel>
   
   # Test połączenia z określonego namespace
   kubectl exec -it -n <namespace> <pod> -- curl <cel>
   ```

## Najlepsze praktyki

1. **Planowanie:**
   - Zacznij od najbardziej restrykcyjnych reguł
   - Stopniowo dodawaj potrzebne połączenia
   - Dokumentuj powody dla każdej reguły

2. **Testowanie:**
   - Testuj Network Policies w środowisku deweloperskim
   - Używaj narzędzi do testowania sieci
   - Monitoruj logi pod kątem blokowanych połączeń

3. **Bezpieczeństwo:**
   - Regularnie przeglądaj i aktualizuj reguły
   - Usuwaj nieużywane Network Policies
   - Używaj najmniejszych możliwych uprawnień

## Ograniczenia

1. **Wymagania:**
   - Network Policies wymagają wsparcia od sieciowego pluginu CNI
   - Nie wszystkie pluginy CNI wspierają wszystkie funkcje

2. **Wydajność:**
   - Duża liczba Network Policies może wpływać na wydajność
   - Złożone reguły mogą być trudne do debugowania

3. **Debugowanie:**
   - Brak wbudowanych narzędzi do debugowania
   - Trudne do testowania w izolacji

## Przydatne narzędzia

1. **Debugowanie:**
   - `kubectl exec` - testowanie połączeń
   - `kubectl describe networkpolicy` - szczegóły polityki
   - `kubectl get networkpolicy` - lista polityk

2. **Monitoring:**
   - Logi kubelet
   - Logi CNI plugin
   - Network policy metrics (jeśli dostępne)

## Podsumowanie

Network Policies są potężnym narzędziem do kontroli ruchu sieciowego w klastrze Kubernetes. Pozwalają na:
- Izolację aplikacji
- Kontrolę dostępu do usług
- Bezpieczną komunikację między komponentami
- Implementację zasad bezpieczeństwa

Pamiętaj, że Network Policies działają na zasadzie "deny by default" i wymagają dokładnego planowania oraz testowania przed wdrożeniem na produkcję.