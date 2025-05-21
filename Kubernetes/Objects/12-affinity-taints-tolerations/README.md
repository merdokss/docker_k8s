# Kubernetes: Affinity, Anti-affinity, Taints i Tolerations

Te mechanizmy w Kubernetes pozwalają na zaawansowane zarządzanie tym, gdzie i jak Pody są uruchamiane na węzłach (Nodes) w klastrze. Pomagają optymalizować wykorzystanie zasobów, zapewniać wysoką dostępność i spełniać specyficzne wymagania aplikacji.

## Affinity i Anti-affinity

Mechanizmy **Affinity** i **Anti-affinity** pozwalają wpływać na decyzje schedulera Kubernetes dotyczące umieszczania Podów na węzłach. Działają na podstawie etykiet (labels) przypisanych do węzłów lub innych Podów.

Istnieją dwa główne typy affinity/anti-affinity:

1.  **Node Affinity/Anti-affinity:**
    *   Pozwala określić, na jakich węzłach Pod powinien (lub nie powinien) być uruchomiony, bazując na etykietach węzłów.
    *   **`requiredDuringSchedulingIgnoredDuringExecution`**: Twarde wymaganie. Pod zostanie uruchomiony tylko na węźle spełniającym warunki. Jeśli żaden węzeł nie spełnia warunków, Pod nie zostanie uruchomiony. Zmiany etykiet węzła w trakcie działania Poda nie mają wpływu.
    *   **`preferredDuringSchedulingIgnoredDuringExecution`**: Miękkie wymaganie (preferencja). Scheduler postara się umieścić Poda na węźle spełniającym warunki, ale jeśli to niemożliwe, Pod zostanie uruchomiony na innym węźle. Zmiany etykiet węzła w trakcie działania Poda nie mają wpływu.

2.  **Pod Affinity/Anti-affinity:**
    *   Pozwala określić, że Pody powinny (lub nie powinny) być uruchamiane na tym samym węźle (lub w tej samej strefie/regionie), co inne Pody spełniające określone kryteria (bazujące na ich etykietach).
    *   Przydatne do kolokacji Podów, które często ze sobą komunikują (affinity) lub do rozpraszania Podów w celu zapewnienia wysokiej dostępności (anti-affinity).
    *   Podobnie jak Node Affinity, posiada typy `requiredDuringSchedulingIgnoredDuringExecution` i `preferredDuringSchedulingIgnoredDuringExecution`.
    *   Wymaga zdefiniowania `topologyKey`, która określa "domenę" grupowania (np. `kubernetes.io/hostname` dla tego samego węzła, `topology.kubernetes.io/zone` dla tej samej strefy dostępności).

### Przykłady użycia Affinity/Anti-affinity:
*   **Node Affinity:** Uruchamianie Podów wymagających specjalistycznego sprzętu (np. GPU) tylko na węzłach z tym sprzętem.
*   **Node Anti-affinity:** Unikanie uruchamiania Podów na węzłach, które są przeznaczone do innych celów.
*   **Pod Affinity:** Umieszczanie frontendu aplikacji blisko jej backendu na tym samym węźle, aby zminimalizować opóźnienia sieciowe.
*   **Pod Anti-affinity:** Rozmieszczanie replik bazy danych na różnych węzłach (lub w różnych strefach), aby zapobiec utracie danych w przypadku awarii jednego węzła/strefy.

## Taints i Tolerations

**Taints** (skażenia) i **Tolerations** (tolerancje) to mechanizm pozwalający na "odpychanie" Podów od określonych węzłów, chyba że Pody te mają odpowiednią tolerancję dla danego skażenia.

*   **Taint:** Jest to właściwość przypisywana do węzła. Oznacza, że żaden Pod nie będzie mógł być uruchomiony na tym węźle, chyba że jawnie toleruje to skażenie.
    *   Każdy Taint składa się z klucza (`key`), wartości (`value`) i efektu (`effect`).
    *   Efekty Taint:
        *   `NoSchedule`: Nowe Pody nie będą planowane na tym węźle, jeśli nie tolerują skażenia. Istniejące Pody nie są usuwane.
        *   `PreferNoSchedule`: Scheduler postara się nie umieszczać Podów na tym węźle, jeśli nie tolerują skażenia. Jest to "miękka" wersja `NoSchedule`.
        *   `NoExecute`: Nowe Pody nie będą planowane na tym węźle, a istniejące Pody, które nie tolerują skażenia, zostaną z niego usunięte (eksmitowane).

*   **Toleration:** Jest to właściwość przypisywana do Poda. Pozwala Podowi być uruchomionym na węźle z pasującym skażeniem.
    *   Tolerancja musi pasować do skażenia (klucz, wartość, efekt), aby Pod mógł zostać zaplanowany na skażonym węźle.
    *   Można zdefiniować `tolerationSeconds` dla efektu `NoExecute`, co oznacza, jak długo Pod może pozostać na węźle po dodaniu skażenia lub po tym, jak tolerancja przestanie pasować, zanim zostanie usunięty.

### Przykłady użycia Taints i Tolerations:
*   **Dedykowane węzły:** Można oznaczyć grupę węzłów skażeniem (np. `dedicated=gpu:NoSchedule`), a następnie pozwolić tylko Podom z odpowiednią tolerancją (np. tolerującym `dedicated=gpu`) na uruchamianie się na tych węzłach. To zapewnia, że węzły z GPU są używane tylko przez Pody, które ich potrzebują.
*   **Węzły specjalnego przeznaczenia:** Oznaczanie węzłów master skażeniem `node-role.kubernetes.io/master:NoSchedule`, aby zapobiec uruchamianiu na nich zwykłych aplikacji.
*   **Obsługa awarii węzłów:** Kubernetes automatycznie dodaje tainy takie jak `node.kubernetes.io/unreachable` z efektem `NoExecute`, gdy węzeł staje się niedostępny. Pody mogą mieć tolerancję dla tego skażenia przez określony czas (`tolerationSeconds`), zanim zostaną usunięte i przeniesione na inny węzeł.
