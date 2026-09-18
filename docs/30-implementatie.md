# Implementatie

## Technologie

- C# / .NET
- ASP.NET Core voor de webapp
- .NET Windows Service voor `PoortwachterService`
- WinForms voor `Poortwachter.exe`

Target frameworks:

```text
Poortwachter.Web          net10.0
PoortwachterService       net48
Poortwachter.exe          net48
Poortwachter.Contracts    netstandard2.0
```

`Poortwachter.exe` wordt geïmplementeerd als WinForms-applicatie op .NET Framework 4.8. De applicatie verzorgt alleen de lokale 10-minutenmelding en het verzoek tot verlengen. Claimlogica blijft in `PoortwachterService`.

`Poortwachter.Contracts` bevat gedeelde types voor het communicatiecontract en moet bruikbaar zijn vanuit zowel .NET Framework 4.8 als .NET 10.

## Deployment

- webapp als container via Synology Container Manager
- publicatie via DSM Reverse Proxy
- `PoortwachterService` draait op de Nipper-pc
- `Poortwachter.exe` draait lokaal op de Nipper-pc

## Randvoorwaarde

Maak implementaties zoveel mogelijk herbruikbaar als de huidige Nipper-pc vervangen wordt door een Windows 11-pc.

Houd implementaties zo eenvoudig mogelijk, vooral wanneer ze specifiek nodig zijn voor de huidige Windows 10-pc.

## Communicatie

De webapp en `PoortwachterService` communiceren via WSS volgens `10-ontwerp.md`.

`Poortwachter.exe` en `PoortwachterService` communiceren lokaal via `System.IO.Pipes`, zonder WCF. `PoortwachterService` is de named-pipe-server en `Poortwachter.exe` is client.

Gedeelde .NET-types worden gebruikt voor het communicatiecontract.

## Persistente toestand

`PoortwachterService` bewaart de persistente toestand als JSON in:

```text
C:\ProgramData\Poortwachter\state.json
```

Het formaat bevat een versienummer en alleen de gegevens die nodig zijn voor herstel. `claimed_at` en `expires_at` worden in UTC opgeslagen.

De service schrijft updates via `state.json.tmp`, voert `Flush(true)` uit, sluit het bestand en vervangt daarna `state.json` in één filesystem-operatie. Bij de eerste opslag wordt het tijdelijke bestand naar `state.json` verplaatst.

Een achtergebleven tijdelijk bestand wordt niet als geldige toestand gebruikt. Als `state.json` ontbreekt of niet leesbaar is, maakt de service eerst AnyDesk en TeamViewer niet beschikbaar en schrijft pas daarna `VRIJ`.
