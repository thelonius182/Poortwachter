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

## 2026-09-16 — .NET-targets

**Besluit**

- `NipperSessie.Web`: .NET 10 (`net10.0`)
- `NipperSessieService`: .NET Framework 4.8 (`net48`)
- `NipperSessie.exe`: .NET Framework 4.8 (`net48`)
- `NipperSessie.Contracts`: .NET Standard 2.0 (`netstandard2.0`)

**Reden**

De huidige Nipper-pc draait Windows 10 Pro N 22H2 en kan niet naar Windows 11 worden geüpgraded. De Windows-onderdelen blijven daarom op .NET Framework 4.8. De webapp draait op de Synology en kan .NET 10 gebruiken. `netstandard2.0` maakt gedeelde contracttypes bruikbaar vanuit beide runtimes.

## 2026-09-16 — Deployment webapp

**Besluit**

De webapp draait als container via Synology Container Manager en wordt gepubliceerd via DSM Reverse Proxy.

**Reden**

De DS918+ heeft Container Manager en Reverse Proxy beschikbaar; er is geen bestaande eigen webapp-stack waarmee rekening moet worden gehouden.
