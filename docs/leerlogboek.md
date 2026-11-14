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