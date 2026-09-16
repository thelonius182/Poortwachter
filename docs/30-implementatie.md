# Implementatie

## Technologie

- C# / .NET
- ASP.NET Core voor de webapp
- .NET Windows Service voor `NipperSessieService`
- .NET Windows-app voor `NipperSessie.exe`

Target frameworks:

```text
NipperSessie.Web          net10.0
NipperSessieService       net48
NipperSessie.exe          net48
NipperSessie.Contracts    netstandard2.0
```

`NipperSessie.Contracts` bevat gedeelde types voor het communicatiecontract en moet bruikbaar zijn vanuit zowel .NET Framework 4.8 als .NET 10.

## Deployment

- webapp als container via Synology Container Manager
- publicatie via DSM Reverse Proxy
- `NipperSessieService` draait op de Nipper-pc
- `NipperSessie.exe` draait lokaal op de Nipper-pc

## Randvoorwaarde

Maak implementaties zoveel mogelijk herbruikbaar als de huidige Nipper-pc (Win-10) vervangen wordt door een Windows-11 machine.

Maak implementaties zo eenvoudig mogelijk, zeker als ze specifiek zijn voor de huidige Win-10 versie van de Nipper-pc.

## Communicatie

De webapp en `NipperSessieService` communiceren via WSS volgens `10-ontwerp.md`.

Gedeelde .NET-types worden gebruikt voor het communicatiecontract.
