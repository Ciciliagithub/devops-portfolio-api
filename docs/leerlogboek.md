# Leerlogboek

## 12-11-2026 – Projectstructuur, health-endpoint en eerste test
- Solution met een app-project (src/) en een testproject (tests/) opgezet.
- /health endpoint toegevoegd en getest met WebApplicationFactory.
- Fout: "No test is available" → HealthTests.cs was niet opgeslagen. Opgelost met Ctrl+S.

- Learned the DevOps cycle and how all the pieces fit together
- Planned the project and picked the tech stack
- Set up the repo structure: solution, API project, test project, references, .gitignore
- Added the /health endpoint plus a test, and got dotnet build, dotnet run and dotnet test working (only need to spend extra time on the unit tests)
- Started docs/leerlogboek.md
- Learned how Docker and multi-stage builds work, and the first half of the Dockerfile

Moeilijkheden: De test, niet eerder dit gedaan. Meer tijd besteden aan andere endpoints toevoegen en tests ervoor maken, puur om te begrijpen hoe tests werken. 

Geleerd: Hiernaast begreep ik alles al, endspoints waren geen moeite.

## 13-11-2026 – Dockerfile (stage 1)

### Wat ik heb geleerd
- **Image-naam** = registry / naam : tag. `mcr.microsoft.com` is de registry van Microsoft;
  zonder registry gebruikt Docker standaard Docker Hub (bijv. `node:22`).
- **Dockerfile** = stappenplan. `FROM` geeft een basis-image (Linux + SDK), elke regel
  daarna voegt een laag toe.
- **Multi-stage build**: bouwen met de SDK, draaien met alleen de runtime.
  Het eindimage wordt kleiner en veiliger (geen SDK, compiler of broncode).
- **Layer caching**: eerst `.csproj` kopiëren + `restore`, daarna pas de code.
  Wat zelden verandert bovenaan, wat vaak verandert onderaan.
- `COPY [laptop] [image]`: alleen het eerste pad is op mijn laptop, de rest gebeurt in het image.
- `WORKDIR` werkt als `cd`. Pad met `/` vooraan = absoluut, zonder = relatief aan WORKDIR.
- `RUN` voert een commando uit tijdens het bouwen (≠ `docker run`).
- `dotnet publish -c Release -o /app/publish`: compileert in productiestand en zet alles
  wat de app nodig heeft in één map.

### Fouten die ik maakte
- `mcr.microsoft` i.p.v. `mcr.microsoft.com`, en `WKDIR`/`MKDIR` i.p.v. `WORKDIR`.
- `COPY` zonder `/` aan het eind → Docker ziet het als bestand i.p.v. map.
- Paden met of zonder `/` vooraan door elkaar → bestanden komen op de verkeerde plek.
- `dotnet build` i.p.v. `dotnet publish` (build compileert alleen, publish maakt een complete map).

### Volgende stap
- Stage 2 (runtime) schrijven, `.dockerignore` toevoegen, `docker build` en `docker run`, /health testen.


## 13-11-2026 – Dockerfile afgemaakt + CI-pipeline (dag 1 & 2)

### Wat ik heb gedaan
- Multi-stage Dockerfile geschreven (build stage met SDK, runtime stage met aspnet) en `.dockerignore` toegevoegd.
- Image gebouwd met `docker build -t notes-api:local .` en gedraaid met
  `docker run --rm -p 8080:8080 notes-api:local` → `/health` gaf `healthy`.
- CI-pipeline gemaakt in `.github/workflows/ci.yml`:
  checkout → setup .NET 11 → restore → build → test → docker build.
- Gewerkt via een feature branch (`feature/ci-pipeline`) en een pull request.
- Branch protection (ruleset) op `main`: PR verplicht + `build-and-test` moet groen zijn.

### Wat ik heb geleerd
- **Relatief vs. absoluut pad:** met `/` vooraan = vanaf de root, zonder = vanaf WORKDIR.
  Niet mixen. Bron van `COPY` is altijd relatief aan mijn repo (build context).
- **Slash aan het eind** bij COPY-bestemming = map. Eén bestand kopiëren neemt de mappen eromheen niet mee.
- **`COPY --from=build`** haalt bestanden uit een eerdere stage i.p.v. van mijn laptop.
- **`RUN`** = tijdens het bouwen, **`ENTRYPOINT`** = bij het starten van de container.
- **`EXPOSE`** documenteert alleen de poort; `-p laptop:container` opent hem echt.
- **`aspnet`** i.p.v. `runtime`, omdat het een web-API is. **`USER $APP_UID`** = niet als root draaien.
- **Pipeline-opbouw:** trigger (`on`) → job → runner (`runs-on`) → steps (`uses` = kant-en-klare actie, `run` = eigen commando).
- **Volgorde:** elke stap heeft de vorige nodig + *fail fast* (snelle checks eerst).
- **Triggers:** `pull_request` = quality gate vóór mergen, `push` naar `main` = test de gecombineerde code na mergen.
- **Image-tag `${{ github.sha }}`:** elk image is te herleiden naar de commit.
- **GitHub Flow:** `main` + korte feature branches; dev/prod zijn omgevingen, geen branches.
- Commando's en flags hoef ik niet te stampen; ik moet wel kunnen uitleggen wat elke stap doet.

### Fouten die ik maakte
- Typfouten: `mrc`/`mc` i.p.v. `mcr`, `sdl`, `Restore`, `Csproj` (Linux is hoofdlettergevoelig).
- `dotnet build` i.p.v. `dotnet publish`, `-n` i.p.v. `-c`.
- Relatieve en absolute paden door elkaar → bestand staat ergens anders dan waar ik het zoek.
- `--from=build` vergeten → Docker zocht `/app/publish` op mijn laptop.
- `ci.yml` gecommit terwijl hij nog leeg was → GitHub: "No event triggers defined in `on`".
  **Les:** altijd `git status` checken vóór het committen.
- Eerst gemerged, daarna branch protection ingesteld (geen schade, pipeline was groen).

### Volgende stap (dag 3)
- Image pushen naar GHCR met de commit-SHA als tag (alleen op `main`).
- Trivy-scan op het image, Dependabot aanzetten, README met uitleg.


## 14-11-2026 – Trivy, GHCR en CodeQL (dag 3)

### Wat ik heb gedaan
- **Trivy** toegevoegd aan `ci.yml`: scant het image op HIGH/CRITICAL (alleen kwetsbaarheden met een fix),
  pipeline faalt bij een vondst (`exit-code: '1'`). Resultaat als SARIF-artifact opgeslagen (`if: always()`).
- **Image naar GHCR**: image krijgt direct de volledige naam `ghcr.io/ciciliagithub/notes-api:<commit-sha>`,
  wordt gescand en daarna precies dát image gepusht. Inloggen en pushen alleen na een merge naar `main`.
- **CodeQL (SAST)** als aparte workflow `codeql.yml` (advanced setup): scant mijn C#-code en mijn workflow-bestanden.
- Zelf een kapotte versie van mijn workflow gerepareerd en per fout uitgelegd waaróm het fout was.

### Wat ik heb geleerd
- **SAST** = eigen code (CodeQL), **SCA** = packages van anderen (Dependabot, Trivy),
  **image scanning** = het hele image (Trivy), **DAST** = draaiende app van buitenaf (later, optioneel).
- **Build once, scan, push hetzelfde image**: anders push je iets wat niet gescand is.
- **Het adres zit in de imagenaam**: `ghcr.io/...` vertelt Docker waarheen. Zonder adres = Docker Hub.
- **`GITHUB_TOKEN`** i.p.v. persoonlijk token: bestaat alleen tijdens de run. Rechten via `permissions:`
  (`packages: write`), en alleen wat nodig is (least privilege).
- **`env:`-variabelen** roep je aan met `${{ env.NAAM }}`; één naam op één plek voorkomt typfouten.
- **`github.sha`** = commit-ID, als tag: elk image is te herleiden naar de code, en terugrollen kan.
- **`if:`-expressies** (`github.event_name == 'push' && github.ref_name == 'main'`):
  PR's worden getest, maar pas na een merge wordt er gepubliceerd.
- **Actions vastzetten op een commit-SHA** (`@65b78e6...`) is veiliger dan een tag (supply chain).
- **Elke `.yml` in `.github/workflows/`** is een eigen workflow die los en parallel draait.
- **CodeQL-workflow:** `schedule` met cron (wekelijks), matrix (`csharp` + `actions`), `build-mode: none`.
- **Debuggen:** ga naar de stap die faalde, lees wát er misging, beredeneer vanuit de YAML,
  en kijk naar de environment variables die echt worden meegegeven.

### Fouten die ik maakte
- Trivy: `version: latest` (beter vastzetten), severity-filter werd genegeerd bij SARIF
  (opgelost met `limit-severities-for-sarif: true`), en het rapport werd nergens opgeslagen.
- GHCR: `docker/build-push-action` onder `run:` gezet (acties horen onder `uses:`), en die action
  zou het image opnieuw bouwen. Vervangen door `docker push`.
- Image-naam in build, scan en push kwam niet overeen; hoofdletters in de naam (GHCR wil kleine letters).
- `${{IMAGE}}` i.p.v. `${{ env.IMAGE }}`; `github_event_name` i.p.v. `github.event_name`.
- Onnodige `id-token: write`-permissie (alleen voor OIDC).
- Verkeerde "Build"-stap aangepast; opgelost door duidelijke stapnamen ("Compile .NET", "Build Docker image").
- **`action.yml` verward met mijn workflow:** `inputs:`, `outputs:` en `runs:` uit de menukaart van de
  actie gekopieerd. Les: in mijn workflow alleen `uses:` + `with:`.
- CodeQL eerst per ongeluk op **default setup** gezet (geen bestand in de repo), daarna advanced.


## 16-11-2026 – Kubernetes lokaal met kind (dag 4)

### Wat heb ik gedaan
- Eerst de theorie: wat Kubernetes is, de architectuur (control plane + worker nodes)
  en wat er stap voor stap gebeurt bij `kubectl apply`. Alles vastgelegd in een glossary.
- kind geïnstalleerd en een lokaal cluster `notes` aangemaakt (1 node: `notes-control-plane`).
- `k8s/deployment.yaml` geschreven: 2 replicas van `ghcr.io/ciciliagithub/notes-api:<commit-SHA>`,
  poort 8080, liveness- en readiness-probe op `/health`, resource requests en limits.
- `k8s/services.yaml` geschreven: Service van het type ClusterIP, selector `app: notes-api`,
  port en targetPort 8080.
- Toegepast met `kubectl apply` en gecontroleerd met `get pods`, `get endpoints`,
  en via `port-forward` → `/health` gaf `{"status":"healthy"}`.
- **Self-healing**: een pod verwijderd → de ReplicaSet maakte meteen een nieuwe pod
  (nieuwe naam, nieuw IP), en de Service nam het nieuwe IP vanzelf op in de endpoints.
- **Rolling update** naar een andere SHA: eerst een nieuwe pod ready, pas dan een oude weg →
  geen downtime. Er ontstond een nieuwe ReplicaSet; de oude bleef bestaan met 0 pods.
- **Rollback** met `kubectl rollout undo`, en `rollout status` / `rollout history` bekeken.

### Wat heb ik geleerd
- Kubernetes werkt met een **desired state**: ik beschrijf in YAML wat ik wil,
  controllers lossen het verschil met de werkelijkheid op (reconciliation loop).
- Alle componenten praten via de **API server**; self-healing is dezelfde keten als `apply`,
  alleen begint die bij de ReplicaSet-controller.
- Een podnaam bestaat uit: Deployment-naam – hash van de pod-template (ReplicaSet) – willekeurig deel.
  Verandert de template (bijvoorbeeld het image), dan komt er een nieuwe ReplicaSet.
- **Readiness** bepaalt of een pod verkeer krijgt (en in de endpoints staat);
  **liveness** bepaalt of de container herstart wordt. Zonder readiness probe kan een rolling update
  verkeer sturen naar een app die nog niet klaar is.
- Waarom ik een **commit-SHA** als tag gebruik en geen `latest`: traceerbaar (welke commit, CI-run
  en Trivy-scan), een rollback is mogelijk, en Kubernetes ziet een wijziging alleen als de tag verandert.
- `rollout undo` gaat naar de **vorige** revisie (twee keer undo = heen en terug),
  en een rollback krijgt een nieuw revisienummer.
- **Drift**: `undo` past alleen het cluster aan, niet mijn YAML in Git. Bij de volgende `apply`
  wordt de rollback ongedaan gemaakt. Dit is het probleem dat GitOps (Argo CD) oplost.
- `port-forward` naar een Service gaat naar één pod; het test dus geen load balancing.

### Fouten die ik maakte
- **Indentation**: mijn probes stonden op het niveau van de pod in plaats van de container.
  In YAML is de indentation de structuur.
- **Readiness probe vergeten** in de eerste versie.
- **`targetPort: 9376` overgenomen uit het voorbeeld** in de docs, terwijl mijn app op 8080 luistert.
- **Verkeerde selector**: eerst `src/NotesApi`, daarna `apps:` in plaats van `app:`.
  Dit is een stille fout: `apply` slaagt, maar de Service vindt 0 pods (endpoints `<none>`).
- **`type: ClusterIP` bovenaan gezet** in plaats van onder `spec`.
  Ezelsbruggetje: bovenaan staan alleen `apiVersion`, `kind`, `metadata`, `spec`.
- `kubectl apply -f deployment.yaml` vanuit de root → bestand niet gevonden (het staat in `k8s/`).
- Per ongeluk twee keer `rollout undo` gedaan → zo geleerd dat undo heen en weer gaat.

### Volgende stap
- Bespreken in het gesprek: "CI bouwt, scant en pusht het image; deployen naar Kubernetes doe ik
  nu met de hand. De volgende stap is Argo CD, zodat Git de bron van waarheid wordt."
- Later: Helm, Argo CD, en dezelfde manifests naar AKS via Terraform.