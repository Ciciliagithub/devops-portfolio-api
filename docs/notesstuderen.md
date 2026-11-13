# 13/11/2026
Docker
Stage 1: bouwen (met het SDK-image)

Je begint met het SDK-image: een klein besturingssysteem plus de .NET SDK, met de compiler en de bouwtools.
Je kopieert de .csproj erin, en doet restore. Daarmee worden de packages (de bibliotheken die je app gebruikt) gedownload.
Je kopieert je code erin.
dotnet publish compileert je code tot een kant-en-klare app: een paar .dll-bestanden.

Stage 2: draaien (met het runtime-image)

Je begint opnieuw, met het kleine runtime-image: alleen de “motor” om .NET-apps te draaien.
Je kopieert alleen de gebouwde .dll-bestanden uit stage 1. Geen broncode, en geen SDK.
Start de container, dan draait de runtime je NotesApi.dll.

Begrip	Wat het is	Vergelijking
Dockerfile	Een recept: de stappen om het pakket te maken	Het recept
Image	Het kant-en-klare pakket: je app, de .NET-runtime en een klein besturingssysteem. Het verandert niet meer	Een maaltijd die verpakt in de vriezer ligt
Container	Een draaiend exemplaar van een image	De maaltijd die je opwarmt en opeet. Uit één image kun je er veel tegelijk draaien
Registry	De opslag voor images, zoals GHCR	De supermarkt waar de verpakte maaltijden liggen




registry / naam : tag:

Deel	Bij jou	Betekenis
mcr.microsoft.com	registry	Microsoft Container Registry, de “winkel” waar Microsoft zijn images neerzet
dotnet/sdk	naam	welk image je wilt
11.0	tag	welke versie



Eerst twee foutjes in je code:

dockerfile
FROM mcr.microsoft.com/dotnet/sdk:11.0 AS build
WORKDIR /src
COPY src/NotesApi/NotesApi.csproj src/NotesApi/
mcr, niet mc. Anders vindt Docker de registry niet.
De / aan het eind van src/NotesApi/ is belangrijk. Zonder die slash denkt Docker dat je een bestand bedoelt dat NotesApi heet, in plaats van een map.
Schrijf AS in hoofdletters. as werkt ook, maar dan geeft Docker een waarschuwing.

Je vragen:

WORKDIR: ja, je mag kiezen wat je wilt (/build, /app, /werk). /src is gewoon een gewoonte, omdat er broncode in komt. In stage 2 gebruiken we straks /app.
Waarom de .csproj: ja, precies. Daarin staat welke packages je app nodig heeft en welke .NET-versie hij gebruikt. restore leest dat bestand om te weten wat het moet downloaden.
Daarna packages ophalen: ja, en dat doe je met een RUN-regel: