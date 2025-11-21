# Autoskalowanie Węzłów w Kubernetes - Przegląd Rozwiązań

## 📌 Spis Treści

1. [Podstawowe Pojęcia](#podstawowe-pojęcia)
2. [Rozwiązania Cloud](#rozwiązania-cloud)
3. [Rozwiązania On-Premise](#rozwiązania-on-premise)
4. [Porównanie Wszystkich Rozwiązań](#porównanie-wszystkich-rozwiązań)
5. [Kiedy Co Używać](#kiedy-co-używać)
6. [Rekomendacje](#rekomendacje)

---

## Podstawowe Pojęcia

### Czym jest autoskalowanie węzłów?

**Autoskalowanie węzłów (nodes)** to automatyczne dodawanie lub usuwanie maszyn (serwerów) w klastrze Kubernetes w odpowiedzi na zapotrzebowanie.

### Różnica: Skalowanie Podów vs Skalowanie Węzłów

| Aspekt | Skalowanie Podów (HPA) | Skalowanie Węzłów (CA) |
|--------|----------------------|----------------------|
| **Co skaluje?** | Aplikacje (kontenery) | Serwery (maszyny) |
| **Trigger** | CPU/Memory/Custom metrics | Pody w stanie Pending |
| **Czas reakcji** | 15-30 sekund | 2-5 minut |
| **Koszt** | Darmowe (używa istniejących węzłów) | Płatne (nowe maszyny) |
| **Gdzie działa?** | Wszędzie | Wymaga integracji z providerem |

---

## Rozwiązania Cloud

### 1. Cluster Autoscaler (CA)

**Opis:** Oficjalny projekt Kubernetes do automatycznego skalowania węzłów.

**Jak działa:**
```
Pod czeka (Pending) → CA wykrywa → Wywołuje Cloud API → 
Nowy węzeł się tworzy → Pod zostaje zaplanowany
```

**Wsparcie:**

| Cloud Provider | Wsparcie | Trudność Setup | Dojrzałość |
|---------------|----------|---------------|-----------|
| AWS (EKS) | ✅ Natywne | Łatwe | Produkcyjne |
| Azure (AKS) | ✅ Natywne (managed) | Bardzo łatwe | Produkcyjne |
| GCP (GKE) | ✅ Natywne (managed) | Bardzo łatwe | Produkcyjne |
| Alibaba Cloud | ✅ Natywne | Średnie | Produkcyjne |
| DigitalOcean | ✅ Natywne | Łatwe | Produkcyjne |

**Cechy:**
- ✅ Najpopularniejsze rozwiązanie (od 2016)
- ✅ Stabilne i sprawdzone
- ✅ Działa z wieloma providerami
- ❌ Wolniejsze niż nowsze rozwiązania (30-60s decision)
- ❌ Podstawowa optymalizacja kosztów

---

### 2. Karpenter

**Opis:** Nowoczesny autoscaler od AWS, skupiony na szybkości i optymalizacji kosztów.

**Jak działa:**
```
Pod czeka (Pending) → Karpenter analizuje wymagania →
Wybiera optymalny typ instancji → Tworzy węzeł (< 30s)
```

**Wsparcie:**

| Platform | Status | Uwagi |
|----------|--------|-------|
| AWS | ✅ Production Ready | Najlepsza integracja |
| Azure | 🟡 Preview/Beta | W rozwoju |
| GCP | 🟡 Community/Experimental | Wczesna faza |
| On-Premise | ❌ Nie wspierane | Brak planów |

**Cechy:**
- ✅ Bardzo szybkie skalowanie (< 30s)
- ✅ Inteligentny wybór typu instancji (cost optimization)
- ✅ Lepsze "bin packing" (pakowanie podów)
- ✅ Spot/Preemptible instances out-of-the-box
- ❌ Wymaga AWS (głównie)
- ❌ Młodsze (2021+), mniej sprawdzone

**Różnice vs Cluster Autoscaler:**

| Aspekt | Cluster Autoscaler | Karpenter |
|--------|-------------------|-----------|
| **Szybkość** | 30-60 sekund | < 30 sekund |
| **Optymalizacja kosztów** | Podstawowa | Zaawansowana |
| **Typ instancji** | Predefiniowany (node groups) | Dynamiczny wybór |
| **Bin packing** | Standardowe | Inteligentne |
| **Dojrzałość** | Bardzo dojrzałe | Rosnące |
| **Cloud support** | Wszystkie główne | Głównie AWS |

---

### 3. Managed Autoscaling (Cloud-Native)

**Opis:** Wbudowane rozwiązania providerów chmurowych.

| Provider | Nazwa | Opis |
|----------|-------|------|
| **Azure AKS** | AKS Cluster Autoscaler | Wbudowany, włączany jedną komendą CLI |
| **GCP GKE** | GKE Node Auto-provisioning | Automatyczne tworzenie node pools |
| **AWS EKS** | EKS Auto Scaling Groups | Integracja z ASG + CA |

**Cechy:**
- ✅ Zero maintenance (zarządzane przez providera)
- ✅ Najprostszy setup (często 1 komenda)
- ✅ Integracja z innymi usługami providera
- ❌ Vendor lock-in
- ❌ Mniej elastyczne niż self-managed

---

## Rozwiązania On-Premise

### 1. Cluster Autoscaler + Cluster API

**Opis:** Oficjalne rozwiązanie Kubernetes dla środowisk on-premise wykorzystujące Cluster API.

**Jak działa:**
```
Cluster API → Abstrakcja zarządzania maszynami →
Provider (vSphere, Metal³, OpenStack) → Tworzenie maszyn
```

**Wsparcie dla platform:**

| Platforma | Provider | Dojrzałość | Trudność | Uwagi |
|-----------|----------|------------|----------|-------|
| **VMware vSphere** | cluster-api-provider-vsphere | ✅ Production | Średnia | Najpopularniejsze |
| **OpenStack** | cluster-api-provider-openstack | ✅ Production | Średnia | Dojrzałe |
| **Bare Metal** | Metal³ (Metal Kubed) | 🟡 Beta | Wysoka | Zarządza fizycznymi serwerami |
| **Proxmox** | cluster-api-provider-proxmox | 🟡 Community | Średnia | Community driven |
| **oVirt/RHEV** | cluster-api-provider-ovirt | 🟡 Beta | Średnia | Red Hat ecosystem |
| **Nutanix** | cluster-api-provider-nutanix | ✅ Production | Średnia | Enterprise ready |

**Cechy:**
- ✅ Oficjalne rozwiązanie Kubernetes
- ✅ Wspiera wiele platform
- ✅ Standardowy interfejs (Cluster API)
- ❌ Złożony setup (wymaga Cluster API)
- ❌ Potrzebna integracja z systemem wirtualizacji
- ❌ Wolniejsze niż cloud (5-10 minut)

**Architektura:**
```
┌─────────────────────────────────────────┐
│    Management Cluster (K8s)             │
│  ┌───────────────────────────────────┐  │
│  │   Cluster API Controller          │  │
│  │   + Cluster Autoscaler            │  │
│  └────────────┬──────────────────────┘  │
└───────────────┼─────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────┐
│  Infrastructure Provider                │
│  (vSphere API / OpenStack API / IPMI)   │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│  Nowa Maszyna Wirtualna / Fizyczna      │
│  → Instalacja OS → Join do klastra      │
└─────────────────────────────────────────┘
```

---

### 2. Metal³ (Metal Kubed)

**Opis:** Projekt Kubernetes do zarządzania bare metal serwerami jak "cloudem".

**Jak działa:**
```
Bare Metal Inventory → Ironic (zarządzanie serwerami) →
PXE Boot / IPMI → Provisioning → Join do klastra
```

**Cechy:**
- ✅ Zarządza fizycznymi serwerami
- ✅ Integracja z Cluster API
- ✅ PXE boot + IPMI/Redfish
- ❌ Wymaga IPMI/BMC na serwerach
- ❌ Skomplikowany setup
- ❌ Wolne (10-20 minut na provisioning)
- 🟡 Beta status (nie dla wszystkich)

**Wymagania:**
- Serwery z IPMI/Redfish
- Sieć PXE boot
- DHCP server
- Image registry
- Cluster API

---

### 3. Kubevirt + Cluster Autoscaler

**Opis:** Wirtualizacja wewnątrz Kubernetes - tworzy VM jako pody.

**Jak działa:**
```
K8s pod w stanie Pending → Kubevirt tworzy VM →
VM działa jako węzeł K8s → Pod zostaje zaplanowany
```

**Cechy:**
- ✅ "Cloud-like" experience on-premise
- ✅ Szybsze niż tradycyjne VM (nested)
- ✅ Integracja z K8s native tools
- ❌ VM-in-VM (nested virtualization)
- ❌ Overhead wydajności
- ❌ Wymaga potężnego klastra bazowego
- 🎯 Dobre dla dev/test, nie production

---

### 4. Virtual Kubelet

**Opis:** "Fake" węzły - przekierowuje workloady do zewnętrznych systemów.

**Integracje:**

| Backend | Opis | Use Case |
|---------|------|----------|
| **Azure Container Instances** | Serverless containers | Burst workloads w Azure |
| **AWS Fargate** | Serverless EKS | Burst w AWS |
| **Alibaba ECI** | Elastic Container Instance | Burst w Alibaba |
| **Custom** | Własna implementacja | Integracja z legacy systems |

**Cechy:**
- ✅ Instant skalowanie (brak provisioning)
- ✅ Elastyczne (różne backendy)
- ❌ Wymaga zewnętrznego systemu
- ❌ Nie dla wszystkich workloadów
- 🎯 Dobre dla burst capacity

---

### 5. Federation / Multi-Cluster (Liqo)

**Opis:** Federacja klastrów - "pożycza" capacity z innych klastrów.

**Jak działa:**
```
Klaster A pełny → Liqo wykrywa → 
"Virtual node" z klastra B → Workload w klastrze B
```

**Cechy:**
- ✅ Wykorzystuje istniejące klastry
- ✅ Brak provisioning nowych maszyn
- ✅ Multi-cloud / hybrid cloud
- ❌ Złożona konfiguracja sieci
- ❌ Latency między klastrami
- 🎯 Dobre dla organizacji z wieloma klastrami

---

## Porównanie Wszystkich Rozwiązań

### Tabela Główna

| Rozwiązanie | Środowisko | Szybkość | Złożoność Setup | Dojrzałość | Koszt Maintenance |
|-------------|-----------|----------|-----------------|-----------|-------------------|
| **Cluster Autoscaler (Cloud)** | AWS/Azure/GCP | Średnia (30-60s) | Niska | Bardzo wysoka | Niski |
| **Karpenter** | AWS głównie | Wysoka (< 30s) | Średnia | Średnia | Średni |
| **Managed Autoscaling** | Cloud native | Średnia | Bardzo niska | Wysoka | Bardzo niski |
| **CA + Cluster API** | vSphere/OpenStack | Niska (5-10m) | Wysoka | Średnia | Wysoki |
| **Metal³** | Bare Metal | Bardzo niska (10-20m) | Bardzo wysoka | Niska (Beta) | Bardzo wysoki |
| **Kubevirt** | On-premise | Średnia | Wysoka | Średnia | Wysoki |
| **Virtual Kubelet** | Hybrid | Bardzo wysoka | Średnia | Niska | Średni |
| **Liqo (Federation)** | Multi-cluster | Wysoka | Wysoka | Niska | Wysoki |

---

### Cloud vs On-Premise - Szczegółowe Porównanie

| Aspekt | Cloud (AWS/Azure/GCP) | On-Premise |
|--------|----------------------|------------|
| **Setup** | ✅ 10-30 minut | ❌ Dni do tygodni |
| **Szybkość skalowania** | ✅ 2-5 minut | ❌ 5-20 minut |
| **Koszt początkowy** | ✅ Niski (pay-as-you-go) | ❌ Wysoki (infrastruktura) |
| **Koszt operacyjny** | 🟡 Płacisz za użycie | ✅ Stały (po zakupie) |
| **Elastyczność** | ✅ Nieograniczona | ❌ Ograniczona sprzętem |
| **Maintenance** | ✅ Zarządzane przez providera | ❌ Wymaga zespołu |
| **Vendor lock-in** | ❌ Tak | ✅ Nie |
| **Compliance** | 🟡 Zależy od providera | ✅ Pełna kontrola |
| **Latency** | 🟡 Zmienna | ✅ Przewidywalna |
| **Bezpieczeństwo danych** | 🟡 W rękach providera | ✅ Pełna kontrola |

---

### Porównanie On-Premise - Szczegóły

| Rozwiązanie | Platforma | Czas Provisioning | Wymagania | Przypadki Użycia |
|-------------|-----------|-------------------|-----------|------------------|
| **CA + vSphere** | VMware | 5-8 minut | vCenter, template VM | Enterprise z VMware |
| **CA + OpenStack** | OpenStack | 5-10 minut | OpenStack cloud | Telco, duże org |
| **Metal³** | Bare Metal | 10-20 minut | IPMI/BMC, PXE | HPC, performance critical |
| **CA + Proxmox** | Proxmox VE | 5-8 minut | Proxmox cluster | SMB, budżetowe |
| **Kubevirt** | Kubernetes | 3-5 minut | Duży klaster K8s | Dev/Test środowiska |

---

### Możliwości vs Ograniczenia

#### Cloud Solutions

| Możliwość | Cluster Autoscaler | Karpenter | Managed |
|-----------|-------------------|-----------|---------|
| Multi-node groups | ✅ Tak | ✅ Tak | ✅ Tak |
| Spot/Preemptible | 🟡 Manual config | ✅ Automatic | ✅ Automatic |
| Cost optimization | 🟡 Podstawowa | ✅ Zaawansowana | 🟡 Podstawowa |
| Custom metrics | ❌ Nie | ❌ Nie | ❌ Nie |
| Integracja z HPA | ✅ Tak | ✅ Tak | ✅ Tak |
| Scale to zero | ✅ Tak (do min) | ✅ Tak | ✅ Tak (do min) |

#### On-Premise Solutions

| Możliwość | CA + Cluster API | Metal³ | Kubevirt |
|-----------|-----------------|--------|----------|
| Bare metal | ❌ Nie (tylko VM) | ✅ Tak | ❌ Nie |
| Wirtualizacja | ✅ Tak | ❌ Nie | ✅ Tak (nested) |
| Szybki provisioning | 🟡 5-10 min | ❌ 10-20 min | 🟡 3-5 min |
| Wymaga hardware BMC | ❌ Nie | ✅ Tak (IPMI) | ❌ Nie |
| Skalowalność | ✅ Wysoka | 🟡 Średnia | 🟡 Ograniczona |
| Produkcyjny status | ✅ Tak | 🟡 Beta | 🟡 Selective |

---

## Kiedy Co Używać

### Scenariusze Cloud

| Scenariusz | Rekomendowane Rozwiązanie | Dlaczego? |
|-----------|--------------------------|-----------|
| **Startup, nowy projekt** | Managed Autoscaling (AKS/GKE) | Najprostsze, zero maintenance |
| **AWS z budżetem na optymalizację** | Karpenter | Najlepsza cost optimization |
| **Multi-cloud strategy** | Cluster Autoscaler | Działa wszędzie |
| **Enterprise z compliance** | Cluster Autoscaler (self-managed) | Więcej kontroli |
| **Burst workloads** | Virtual Kubelet + ACI/Fargate | Instant capacity |

---

### Scenariusze On-Premise

| Scenariusz | Rekomendowane Rozwiązanie | Dlaczego? |
|-----------|--------------------------|-----------|
| **VMware datacenter** | CA + Cluster API (vSphere) | Najdojrzalsze, production ready |
| **OpenStack cloud** | CA + Cluster API (OpenStack) | Natywna integracja |
| **Bare metal dla HPC/ML** | Metal³ | Maksymalna wydajność |
| **Proxmox (budget)** | CA + Cluster API (Proxmox) | Cost-effective |
| **Dev/Test środowisko** | Kubevirt | Szybkie, elastyczne |
| **Hybrid (on-prem + cloud)** | Virtual Kubelet lub Liqo | Burst do cloud |
| **Istniejące klastry** | Liqo (Federation) | Wykorzystaj to co masz |

---

### Decision Tree - On-Premise

```
Masz środowisko on-premise?
│
├─► TAK, VMware vSphere
│   └─► Użyj: Cluster API + vSphere Provider
│       ✅ Production ready
│       ✅ 5-8 min provisioning
│
├─► TAK, OpenStack
│   └─► Użyj: Cluster API + OpenStack Provider
│       ✅ Production ready
│       ✅ Dobra integracja
│
├─► TAK, Bare Metal z IPMI
│   ├─► Performance critical? (HPC, ML)
│   │   └─► Użyj: Metal³
│   │       ⚠️  Beta, skomplikowane
│   │       ✅ Maksymalna wydajność
│   │
│   └─► Standardowe workloady?
│       └─► Rozważ: VM layer (vSphere/Proxmox)
│
├─► TAK, Proxmox
│   └─► Użyj: Cluster API + Proxmox Provider
│       🟡 Community support
│       ✅ Cost-effective
│
├─► TAK, mam inne klastry K8s
│   └─► Użyj: Liqo (Federation)
│       ✅ Wykorzystaj istniejące
│       ⚠️  Networking complexity
│
└─► NIE, używam Cloud
    ├─► AWS → Karpenter (lub CA)
    ├─► Azure → AKS Managed CA
    └─► GCP → GKE Managed CA
```

---

## Rekomendacje

### Dla Cloud

#### 🥇 Najprostsze (Beginners)
**Azure AKS Managed Autoscaler lub GKE Autoscaling**
- Jedna komenda: `az aks update --enable-cluster-autoscaler`
- Zero konfiguracji
- Zarządzane przez providera

#### 🥈 Standardowe (Intermediate)
**Cluster Autoscaler (Helm)**
- Sprawdzone, stabilne
- Działa wszędzie
- Bogata dokumentacja

#### 🥉 Zaawansowane (Advanced)
**Karpenter (AWS)**
- Najlepsza optymalizacja kosztów
- Wymaga wiedzy o AWS
- Najbardziej efektywne

---

### Dla On-Premise

#### 🥇 Najprostsze (Beginners)
**Nie ma prostego rozwiązania!**
- ⚠️ Wszystkie wymagają znacznego wysiłku
- Rozważ: Managed Kubernetes w cloud dla początkujących

#### 🥈 Realistyczne (Intermediate)
**Cluster API + vSphere/OpenStack**
- Production ready
- Najlepsza dokumentacja
- Community support

**Wymagania:**
- Zespół DevOps/Platform
- 2-4 tygodnie na setup
- Znajomość Cluster API

#### 🥉 Dla Specific Cases
**Metal³** - tylko dla:
- Bare metal requirement (compliance, performance)
- Zespół z ekspercją
- Budget na R&D

---

### Praktyczne Rady

#### ✅ DO (Zalecane):

1. **Cloud → Zacznij od Managed**
   - Azure: `az aks update --enable-cluster-autoscaler`
   - GCP: `gcloud container clusters update --enable-autoscaling`
   - AWS: Helm install CA lub Karpenter

2. **On-Premise → Oceń czy naprawdę potrzebujesz**
   - Może wystarczy manualne skalowanie?
   - Może burst do cloud (hybrid)?
   - Czy koszt maintenance się opłaca?

3. **Jeśli On-Premise jest konieczne:**
   - Wybierz vSphere/OpenStack (najprostsze)
   - Zacznij od małego (2-3 node pools)
   - Przetestuj dokładnie przed produkcją

4. **Zawsze:**
   - Monitoruj koszty (cloud) lub utilization (on-prem)
   - Ustaw rozsądne min/max
   - Testuj scale down (często problematyczne)

---

#### ❌ DON'T (Unikaj):

1. **Nie używaj CA jeśli:**
   - Masz statyczny workload (brak zmienności)
   - Małe środowisko (< 10 nodes)
   - Nie masz budżetu na maintenance (on-prem)

2. **Nie używaj Metal³ jeśli:**
   - To twój pierwszy autoscaler
   - Nie masz zespołu z expertise
   - Można użyć wirtualizacji

3. **Nie używaj Karpenter jeśli:**
   - Nie jesteś na AWS (lub Azure preview)
   - Nie rozumiesz EC2 instance types
   - Nie monitorujesz kosztów

---

## Podsumowanie Kluczowe

### Cloud - Proste ✅
- **Setup:** 10-30 minut
- **Maintenance:** Niski (managed) do Średni (self-managed)
- **Rekomendacja:** Cluster Autoscaler (uniwersalny) lub Karpenter (AWS, zaawansowani)

### On-Premise - Trudne ⚠️
- **Setup:** Dni do tygodni
- **Maintenance:** Wysoki (wymaga zespołu)
- **Rekomendacja:** 
  - **Najlepsze:** Cluster API + vSphere/OpenStack
  - **Alternatywa:** Manual scaling + cloud burst (hybrid)
  - **Ostateczność:** Metal³ (tylko bare metal)

### Najważniejsza Lekcja 💡

> **W cloud:** Autoskalowanie nodów jest standardem - używaj go.
> 
> **On-premise:** Autoskalowanie nodów jest zaawansowane - oceń czy naprawdę potrzebujesz. Często lepiej:
> - Mieć więcej statycznych nodów
> - Skalować tylko pody (HPA)
> - Burst do cloud w razie potrzeby

---

## Materiały Uzupełniające

### Linki do Dokumentacji

#### Cloud
- **Cluster Autoscaler:** https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler
- **Karpenter:** https://karpenter.sh/
- **AKS CA:** https://learn.microsoft.com/azure/aks/cluster-autoscaler
- **GKE CA:** https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-autoscaler

#### On-Premise
- **Cluster API:** https://cluster-api.sigs.k8s.io/
- **Metal³:** https://metal3.io/
- **Kubevirt:** https://kubevirt.io/
- **Liqo:** https://liqo.io/

---

## Quick Reference - Komendy (tylko dla orientacji)

### Azure AKS (Managed)
```bash
# Włącz autoscaling
az aks update --enable-cluster-autoscaler --min-count 1 --max-count 10

# Aktualizuj limity
az aks nodepool update --update-cluster-autoscaler --min-count 2 --max-count 20

# Wyłącz
az aks nodepool update --disable-cluster-autoscaler
```

### GCP GKE (Managed)
```bash
# Włącz autoscaling
gcloud container clusters update CLUSTER_NAME --enable-autoscaling \
  --min-nodes 1 --max-nodes 10

# Wyłącz
gcloud container clusters update CLUSTER_NAME --no-enable-autoscaling
```

### AWS EKS (Helm - Cluster Autoscaler)
```bash
# Instalacja
helm install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set autoDiscovery.clusterName=CLUSTER_NAME \
  --set awsRegion=us-east-1
```

### Weryfikacja (wszystkie platformy)
```bash
# Sprawdź status poda
kubectl get pods -n kube-system | grep autoscaler

# Logi
kubectl logs -n kube-system -l app=cluster-autoscaler -f

# Sprawdź węzły
kubectl get nodes -w
```

