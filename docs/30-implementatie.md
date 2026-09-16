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

## Randvoorwaarde

Implementatiekeuzes vermijden substantiële investeringen die uitsluitend nodig zijn voor de huidige Windows 10-pc.

Waar mogelijk worden onderdelen zo gebouwd dat ze ook op de opvolger van de Nipper-pc bruikbaar blijven.

## Communicatie

De webapp en `NipperSessieService` communiceren via WSS volgens `10-ontwerp.md`.

Gedeelde .NET-types worden gebruikt voor het communicatiecontract.
