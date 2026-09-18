# Implementatie

## Technologie

- C# / .NET
- ASP.NET Core voor de webapp
- .NET Windows Service voor `NipperSessieService`
- WinForms voor `NipperSessie.exe`

Target frameworks:

```text
NipperSessie.Web          net10.0
NipperSessieService       net48
NipperSessie.exe          net48
NipperSessie.Contracts    netstandard2.0
```

`NipperSessie.exe` wordt geïmplementeerd als WinForms-applicatie op .NET Framework 4.8. De applicatie verzorgt alleen de lokale 10-minutenmelding en het verzoek tot verlengen. Claimlogica blijft in `NipperSessieService`.

`NipperSessie.Contracts` bevat gedeelde types voor het communicatiecontract en moet bruikbaar zijn vanuit zowel .NET Framework 4.8 als .NET 10.

## Deployment

- webapp als container via Synology Container Manager
- publicatie via DSM Reverse Proxy
- `NipperSessieService` draait op de Nipper-pc
- `NipperSessie.exe` draait lokaal op de Nipper-pc

## Randvoorwaarde

Maak implementaties zoveel mogelijk herbruikbaar als de huidige Nipper-pc vervangen wordt door een Windows 11-pc.

Houd implementaties zo eenvoudig mogelijk, vooral wanneer ze specifiek nodig zijn voor de huidige Windows 10-pc.

## Communicatie

De webapp en `NipperSessieService` communiceren via WSS volgens `10-ontwerp.md`.

`NipperSessie.exe` en `NipperSessieService` communiceren lokaal via `System.IO.Pipes`, zonder WCF. `NipperSessieService` is de named-pipe-server en `NipperSessie.exe` is client.

Gedeelde .NET-types worden gebruikt voor het communicatiecontract.

## Persistente toestand

`NipperSessieService` bewaart de persistente toestand als JSON in:

```text
C:\ProgramData\NipperSessie\state.json
```

Het formaat bevat een versienummer en alleen de gegevens die nodig zijn voor herstel. `claimed_at` en `expires_at` worden in UTC opgeslagen.

De service schrijft updates via `state.json.tmp`, voert `Flush(true)` uit, sluit het bestand en vervangt daarna `state.json` in één filesystem-operatie. Bij de eerste opslag wordt het tijdelijke bestand naar `state.json` verplaatst.

Een achtergebleven tijdelijk bestand wordt niet als geldige toestand gebruikt. Als `state.json` ontbreekt of niet leesbaar is, maakt de service eerst AnyDesk en TeamViewer niet beschikbaar en schrijft pas daarna `VRIJ`.
