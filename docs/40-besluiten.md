# Besluiten

## 2026-09-16 — Implementatiestack

**Besluit**

C# / .NET voor alle onderdelen:

- ASP.NET Core voor de webapp
- .NET Windows Service voor `PoortwachterService`
- .NET Windows-app voor `Poortwachter.exe`

**Reden**

- één toolchain;
- aansluiting op Windows Service en Windows-UI;
- ASP.NET Core kan als container op de Synology draaien;
- gedeelde .NET-types voor het communicatiecontract.

## 2026-09-16 — .NET-targets

**Besluit**

- `Poortwachter.Web`: .NET 10 (`net10.0`)
- `PoortwachterService`: .NET Framework 4.8 (`net48`)
- `Poortwachter.exe`: .NET Framework 4.8 (`net48`)
- `Poortwachter.Contracts`: .NET Standard 2.0 (`netstandard2.0`)

**Reden**

De huidige Nipper-pc draait Windows 10 Pro N 22H2 en kan niet naar Windows 11 worden geüpgraded. De Windows-onderdelen blijven daarom op .NET Framework 4.8. De webapp draait op de Synology en kan .NET 10 gebruiken. `netstandard2.0` maakt gedeelde contracttypes bruikbaar vanuit beide runtimes.

## 2026-09-16 — Deployment webapp

**Besluit**

De webapp draait als container via Synology Container Manager en wordt gepubliceerd via DSM Reverse Proxy.

**Reden**

De DS918+ heeft Container Manager en Reverse Proxy beschikbaar; er is geen bestaande eigen webapp-stack waarmee rekening moet worden gehouden.

## 2026-09-18 — Publieke hostname en certificaat

**Besluit**

De webapp wordt gepubliceerd als:

```text
https://poortwachter.concertzender.nl
```

Hiervoor wordt op de Synology een afzonderlijk Let's Encrypt-certificaat gebruikt, tenzij bij inrichting blijkt dat een bestaand certificaat deze hostname al dekt.

Het certificaat wordt aan de NipperSessie reverse proxy toegewezen.

**Randvoorwaarde**

Voor uitrol moet `poortwachter.concertzender.nl` in DNS naar het publieke adres van de Synology verwijzen.

**Reden**

Poort 80 en 443 worden al vanaf de Ziggo-router naar de Synology doorgestuurd. Daardoor kan DSM een Let's Encrypt-certificaat voor deze hostname aanvragen en vernieuwen.

## 2026-09-18 — Lokale IPC

**Besluit**

`Poortwachter.exe` en `PoortwachterService` communiceren lokaal via `System.IO.Pipes`, zonder WCF.

`PoortwachterService` is de named-pipe-server en `Poortwachter.exe` is client.

**Reden**

De communicatie betreft twee processen op dezelfde Windows-pc en heeft een klein protocol nodig voor de lokale melding en verlengen. Directe named-pipe-IPC lost dit op zonder extra broker, netwerkservice of WCF-laag. Dit sluit aan bij de projectcriteria proportionaliteit en subsidiariteit.

## 2026-09-18 — Persistente toestand

**Besluit**

`PoortwachterService` bewaart de persistente toestand als één JSON-bestand in:

```text
C:\ProgramData\Poortwachter\state.json
```

Het formaat bevat een versienummer en alleen de gegevens die voor herstel nodig zijn. `claimed_at` en `expires_at` worden in UTC opgeslagen.

Updates worden via een tijdelijk bestand geschreven, met `Flush(true)`, en daarna wordt `state.json` in één filesystem-operatie vervangen. Er is geen automatische fallback naar een oude backup.

Als `state.json` ontbreekt of ongeldig is, wordt fail-closed hersteld: AnyDesk en TeamViewer worden eerst niet beschikbaar gemaakt; pas daarna wordt `VRIJ` opgeslagen.

**Reden**

Voor één lokale toestandrecord is een JSON-bestand eenvoudiger dan registry of een database. De schrijfstrategie voorkomt in-place overschrijven van de enige geldige toestand. Fail-closed herstel voorkomt dat beschadigde persistentie remote toegang vrijgeeft.


## 2026-09-19 — Applicatienaam en claimterminologie

**Besluit**

De zichtbare naam van de applicatie is **Poortwachter**.

Intern heet het tijdelijke gebruiksrecht op de Nipper-pc een **claim**. In medewerkerstekst blijft daarvoor het woord **sessie** gebruikt worden.

De interne opdrachten heten:

- `CREATE_CLAIM`

De tijdvelden heten:

- `claimed_at`
- `expires_at`

De technische componentnamen, het opslagpad en de hostname worden in een volgend besluit gelijkgetrokken met de applicatienaam.

**Reden**

De applicatienaam en het domeinbegrip waren beide gebaseerd op het woord sessie. Dat werd onduidelijk zodra remote sessies en de toestand van de Nipper-pc afzonderlijk moesten worden beschreven. De term claim onderscheidt het tijdelijke gebruiksrecht van een remote verbinding; medewerkerstekst kan het kortere begrip sessie blijven gebruiken.


## 2026-09-19 — Technische namen en hostname

**Besluit**

De technische namen worden gelijkgetrokken met de applicatienaam:

- `Poortwachter.Web`
- `PoortwachterService`
- `Poortwachter.exe`
- `Poortwachter.Contracts`

Het opslagpad wordt:

```text
C:\ProgramData\Poortwachter\state.json
```

De publieke hostname wordt:

```text
poortwachter.concertzender.nl
```

**Reden**

De implementatie is nog niet ver genoeg gevorderd om compatibiliteitsnamen of migraties nodig te maken. Eén naam voorkomt blijvende technische verwijzingen naar de oude applicatienaam.


## 2026-09-19 — Remote-app en claimlevenscyclus

**Besluit**

AnyDesk, TeamViewer en Splashtop worden gezamenlijk **remote-apps** genoemd.

De webapp kent alleen de opdracht `CREATE_CLAIM`; er is geen `RELEASE_CLAIM`-opdracht en de medewerker-UI bevat geen knop om een sessie te stoppen.

Na `CREATE_CLAIM` moet binnen twee minuten een remote verbinding via een remote-app tot stand komen. Gebeurt dat niet, dan laat `PoortwachterService` de claim vervallen en gaat de pc naar `AFSLUITEN`.

Als een remote verbinding wordt verbroken, beëindigt `PoortwachterService` de claim en gaat de pc naar `AFSLUITEN`.

`expires_at` blijft de uiterste eindtijd van de claim.

**Reden**

De medewerker beëindigt het gebruik door de remote verbinding op de Nipper-pc te verbreken. De web-UI hoeft daarom geen aparte stopactie te bieden. De termijn van twee minuten voorkomt dat een aangemaakte claim de Nipper-pc langdurig blokkeert zonder dat een remote verbinding tot stand komt.
