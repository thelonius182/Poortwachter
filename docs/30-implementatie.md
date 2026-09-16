# Implementatie

## Technologie

- C# / .NET
- ASP.NET Core voor de webapp
- .NET Windows Service voor `NipperSessieService`
- .NET Windows-app voor `NipperSessie.exe`

## Deployment

- webapp als container via Synology Container Manager
- publicatie via DSM Reverse Proxy
- `NipperSessieService` draait op de Nipper-pc
- `NipperSessie.exe` draait lokaal op de Nipper-pc

## Communicatie

De webapp en `NipperSessieService` communiceren via WSS volgens `10-ontwerp.md`.

Gedeelde .NET-types worden gebruikt voor het communicatiecontract.
