# Besluiten

## 2026-09-16 — Implementatiestack

**Besluit**

C# / .NET voor alle onderdelen:

- ASP.NET Core voor de webapp
- .NET Windows Service voor `NipperSessieService`
- .NET Windows-app voor `NipperSessie.exe`

**Reden**

- één toolchain;
- aansluiting op Windows Service en Windows-UI;
- ASP.NET Core kan als container op de Synology draaien;
- gedeelde .NET-types voor het communicatiecontract.

## 2026-09-16 — Deployment webapp

**Besluit**

De webapp draait als container via Synology Container Manager en wordt gepubliceerd via DSM Reverse Proxy.

**Reden**

De DS918+ heeft Container Manager en Reverse Proxy beschikbaar; er is geen bestaande eigen webapp-stack waarmee rekening moet worden gehouden.
