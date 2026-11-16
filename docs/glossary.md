## Glossary notes
# Dit bestand houdt alle begrippen en definities bij die ik in dit project leer, als spiekbriefje.

---------------------------------------------------------------
## NODIG voor het project en het interview
---------------------------------------------------------------

## KUBERNETES
### Basis Geleerd
**Kubernetes (K8s)**
Een container-orchestrator: draait en beheert containers (gemaakt van images) verdeeld over
meerdere machines (nodes). Je beschrijft wat je wilt, Kubernetes zorgt dat het zo wordt en blijft.

**Desired state**
De gewenste toestand die je in YAML vastlegt, bijvoorbeeld "2 kopieën van notes-api, elk max 256 MB geheugen".
Kubernetes vergelijkt dit steeds met wat er echt draait en lost het verschil op.

**Reconciliation loop**
De lus waarin een controller steeds de desired state vergelijkt met de echte toestand en het verschil oplost.
Declaratief ("zo hoort het eruit te zien") in plaats van imperatief ("start container A").

**YAML (manifest)**
Bestand waarin je Kubernetes-objecten (Deployment, Service, ...) en hun desired state beschrijft.
In mijn project: k8s/deployment.yaml en k8s/service.yaml.

### Waarvoor gebruik je Kubernetes? Geleerd
**Self-healing**
Crasht een container, of faalt de liveness probe, dan herstart de kubelet hem. Verdwijnt een pod,
dan maakt de ReplicaSet een nieuwe aan.

**Schalen**
Het aantal kopieën (replicas) aanpassen, bijvoorbeeld van 2 naar 10, met één wijziging.
Automatisch schalen kan met de Horizontal Pod Autoscaler (HPA), maar die moet je zelf instellen.

**Rolling updates en rollbacks**
Kubernetes vervangt pods van de oude versie stap voor stap door de nieuwe, zonder downtime.
Een rollback (kubectl rollout undo) zet de vorige versie terug; dat doe je zelf, het gebeurt niet automatisch.

**Service discovery en load balancing**
Apps vinden elkaar via een vaste naam (de Service), en het verkeer wordt verdeeld over de gezonde pods.

### Architectuur
**Cluster**
De verzameling machines die samen één Kubernetes-omgeving vormen: control plane + worker nodes.
In mijn project: een lokaal kind-cluster.

**Control plane**
Het "brein" van het cluster; beslist en bewaakt. Bestaat uit API server, etcd, scheduler en controller manager.

➕ **API server**
De voordeur van de control plane. Alles (kubectl, kubelet, controllers) praat via de API server.

**etcd**
Key-value database in de control plane. Slaat de desired state en de huidige toestand van het cluster op.
Beheert zelf niets.

➕ **Scheduler**
Kiest op welke node een nieuwe pod komt, onder andere op basis van de resource requests.

➕ **Controller manager**
Draait de controllers (de reconciliation loops), bijvoorbeeld de Deployment- en de ReplicaSet-controller.

**Node**
Een (virtuele) machine in het cluster waarop pods draaien. Op elke node draaien kubelet, containerd en kube-proxy.

➕ **kubelet**
Agent op elke node: krijgt pods toegewezen, laat de containers starten en voert de probes uit.

➕ **Container runtime (containerd)**
Software die de containers echt draait. Docker-images werken hierop omdat ze een standaardformaat hebben (OCI).

➕ **kube-proxy**
Regelt het netwerk op elke node, zodat verkeer naar een Service bij de juiste pods terechtkomt.

### Objecten Geleerd
**Pod**
De kleinste deploybare eenheid in Kubernetes: een "jasje" om meestal één container heen
(soms meer, bijvoorbeeld met een sidecar). Pods zijn tijdelijk en krijgen bij elke nieuwe pod een nieuw IP-adres.

**Deployment** (deployment.yaml)
Beschrijft welk image (welke versie) en hoeveel replicas je wilt. Maakt zelf een ReplicaSet aan
en regelt rolling updates en rollbacks.
In mijn project: 2 replicas van ghcr.io/ciciliagithub/notes-api:<sha>.

**ReplicaSet**
Zorgt dat er altijd precies X identieke pods draaien. Wordt door de Deployment aangemaakt; die maak je niet zelf.

**Service** (service.yaml)
Geeft een vast adres en een vaste naam aan een groep pods, en verdeelt het verkeer over de gezonde pods.
Waarom nodig: pods komen en gaan met steeds een ander IP-adres. De Service vindt ze via labels.

➕ **Label / selector**
Label = "sticker" op een object (bijvoorbeeld app: notes-api). Selector = filter dat objecten met die sticker zoekt.
Zo weten de Deployment en de Service welke pods bij hen horen.

➕ **Namespace**
Een aparte "map" binnen een cluster om objecten te scheiden. Later: dev en prod.

### Gezondheid en resources Geleerd
**Readiness probe**
Bepaalt of een pod klaar is om verkeer van de Service te krijgen. Faalt hij, dan krijgt de pod tijdelijk geen verkeer
(er wordt niet herstart).
In mijn project: GET /health op poort 8080 moet 200 teruggeven.

**Liveness probe**
Bepaalt of een container nog werkt. Faalt hij herhaaldelijk, dan herstart de kubelet de container.
In mijn project: ook /health.

➕ **Resource requests / limits**
Request = gegarandeerd minimum aan CPU en geheugen (de scheduler gebruikt dit om een node te kiezen).
Limit = maximum. Gaat een container over de geheugenlimiet, dan wordt hij gestopt (OOMKilled).

### Tools Geleerd
➕ **kubectl**
Command-line tool waarmee je met de API server praat (apply, get, describe, logs, rollout).

➕ **kind (Kubernetes in Docker)**
Draait een Kubernetes-cluster lokaal, waarbij elke node een Docker-container is. Alleen om te leren en testen,
niet voor productie (daar gebruik je bijvoorbeeld AKS).

---------------------------------------------------------------
## NIET NODIG (nu) – alleen bij naam kennen
---------------------------------------------------------------

**Configuratie en secrets (ConfigMap / Secret)**
Configuratie en gevoelige gegevens buiten het image beheren. ConfigMap = gewone instellingen,
Secret = gevoelige gegevens (standaard alleen base64, dus niet versleuteld).

**Cluster Autoscaler**
Voegt automatisch nodes toe of haalt ze weg, afhankelijk van de belasting. Vooral in de cloud (bijvoorbeeld AKS).
Niet te verwarren met de HPA, die pods schaalt.

**High availability**
Het systeem blijft beschikbaar als er iets uitvalt, door meerdere replicas, meerdere nodes
en eventueel meerdere control-plane-nodes.

**Persistent storage (PersistentVolume)**
Opslag die blijft bestaan als een pod verdwijnt. Mijn API heeft dit niet nodig.

**Ingress**
Eén toegangspunt van buiten het cluster naar meerdere Services, op basis van URL of host.

**Helm / Argo CD**
Helm = package manager voor Kubernetes-manifests (templates). Argo CD = GitOps: synchroniseert het cluster met Git.
Staan op mijn roadmap.


### Wat gebeurt er bij `kubectl apply`? (de architectuur in 7 stappen)
1. **kubectl → API server**: kubectl zet mijn YAML om naar JSON en stuurt het naar de API server
   (adres en inloggegevens komen uit mijn kubeconfig).
2. **API server → etcd**: de API server controleert wie ik ben, of ik het mag, en of de YAML klopt.
   Daarna slaat hij de desired state op in etcd.
3. **Deployment-controller**: ziet de nieuwe Deployment `notes-api` en maakt een ReplicaSet aan.
4. **ReplicaSet-controller**: ziet "0 pods, moet 2" en maakt 2 pod-objecten aan.
   Die staan op Pending, want ze hebben nog geen node.
5. **Scheduler**: kiest voor elke pod een node (op basis van resources) en schrijft die op de pod.
   Bij mij: `notes-control-plane`.
6. **kubelet + containerd**: de kubelet op die node laat containerd het image
   `ghcr.io/ciciliagithub/notes-api:<sha>` pullen en de container starten.
7. **Ready + Service**: de readiness probe op `/health` slaagt → pod wordt `1/1`.
   De endpoints-controller zet de pod in de endpoints van de Service,
   en kube-proxy past het netwerk aan zodat verkeer aankomt.

Kernregel: componenten praten niet rechtstreeks met elkaar; alles loopt via de API server.
Self-healing = dezelfde keten vanaf stap 4 ("is 1, moet 2").

### Projectstappen: Kubernetes lokaal met kind
1. kind installeren
2. Cluster `notes` aanmaken en bekijken (kubectl get nodes, docker ps)
3. Feature branch + map k8s/
4. k8s/deployment.yaml schrijven (2 replicas, SHA-tag, probes, resources)
5. k8s/service.yaml schrijven (ClusterIP, selector app: notes-api, port/targetPort 8080)
6. Applyen en testen (get pods, get endpoints, port-forward → /health)
7. Self-healing: pod verwijderen, nieuwe pod zien verschijnen
8. Rolling update naar een andere SHA
9. Rollback met kubectl rollout undo
10. Afronden: commit, push, PR, CI groen, merge, logboek

### Kubernetes-commando's (gebruikt in dit project)

**Cluster (kind)**
- `kind create cluster --name notes` – maakt een lokaal cluster (één node als Docker-container)
- `kubectl get nodes` – toont de nodes en of ze Ready zijn
- `docker ps` – toont de kind-node als Docker-container

**Hulp bij YAML schrijven**
- `kubectl explain service.spec` – toont welke velden er bestaan en waar ze horen
- `kubectl api-resources` – lijst van alle objecten met hun apiVersion

**Toepassen**
- `kubectl apply -f k8s/` – stuurt alle YAML in de map naar de API server (desired state)

**Bekijken**
- `kubectl get pods` – pods met READY, STATUS en RESTARTS
- `kubectl get pods -o wide` – plus IP-adres en node
- `kubectl get pods -w` – blijft live meekijken (watch)
- `kubectl get pods --show-labels` – toont de labels van elke pod
- `kubectl get replicasets` – ReplicaSets met DESIRED / CURRENT / READY
- `kubectl get svc` – Services met hun ClusterIP
- `kubectl get endpoints notes-api` – welke pod-IP's achter de Service zitten
- `kubectl describe pod <naam>` – details en events; eerste stap bij problemen
- `kubectl describe deployment notes-api` – details, o.a. welk image er draait

**Testen**
- `kubectl port-forward svc/notes-api 8080:8080` – tijdelijke tunnel van localhost naar de Service
- `curl.exe http://localhost:8080/health` – health-endpoint testen (curl.exe in PowerShell)

**Self-healing**
- `kubectl delete pod <naam>` – verwijdert een pod; de ReplicaSet maakt meteen een nieuwe

**Updates en rollbacks**
- `kubectl rollout status deployment/notes-api` – wacht tot de rollout klaar is (of faalt)
- `kubectl rollout history deployment/notes-api` – toont de revisies
- `kubectl rollout undo deployment/notes-api` – terug naar de vorige revisie
- `kubectl rollout undo deployment/notes-api --to-revision=<nr>` – terug naar een specifieke revisie