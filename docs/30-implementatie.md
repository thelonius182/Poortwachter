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

`NipperSessie.exe` wordt geïmplementeerd als WinForms-applicatie op .NET Framework 4.8. De applicatie verzorgt alleen de lokale 10-minutenmelding en het verzoek tot verlengen. Sessielogica blijft in `NipperSessieService`.

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

Gedeelde .NET-types worden gebruikt voor het communicatiecontract.
