# Remote-sessiedetectie

Dit document legt prototypebevindingen op de Nipper-pc vast. De betekenis van deze detectie voor pc-toestand en claimlogica staat in `10-ontwerp.md` en `15-toestandsmachine.md`; de precieze rol van Splashtop wordt opnieuw uitgewerkt.

## AnyDesk

Logbestand:

```text
C:\ProgramData\AnyDesk\ad_svc.trace
```

Start:

```text
app.session - <id>: Entering processing loop.
```

Einde:

```text
app.session - <id>: Processing done.
```

Het interne nummer kan als sessie-ID worden gebruikt.

Getest bij normaal verbreken en abrupt afsluiten van de AnyDesk-client.

## TeamViewer

Logbestand:

```text
C:\Program Files (x86)\TeamViewer\TeamViewer15_Logfile.log
```

Start:

```text
BaseSessionEndpoint::StartProcessingCommands Start processing commands for session <id>
```

Einde:

```text
WorkstationLocker::OnSessionEnd: ... TVSessionID: <id>
```

Niet matchen op alleen `OnSessionEnd`: tijdens de sessiestart komt ook `SetAutoLockOnSessionEnd` voor.

Getest bij normaal verbreken en abrupt afsluiten van de TeamViewer-client.

## Splashtop

Er is geen bruikbaar sessielog gevonden. De prototype-detectie gebruikt `SRApp.exe`:

```text
SRApp.exe count > 0                         → verbinding actief
SRApp.exe count = 0 gedurende minimaal 5 s → verbinding beëindigd
```

De vijf seconden zijn debounce omdat de `SRApp.exe`-processen na elkaar verdwijnen.

Getest bij normaal verbreken en abrupt afsluiten van de Splashtop-client. Dit is geobserveerd procesgedrag, geen gedocumenteerde sessie-API.

De rol van Splashtop in de toegangsregeling en toestandsmachine wordt opnieuw uitgewerkt; zie `50-open-punten.md`.

## Prototype

De gecombineerde PowerShell-watcher staat in deze repository als:

```text
prototype/remote_session_watch.ps1
```

De geteste kopie op de Nipper-pc staat als:

```text
C:\Users\Gebruiker\Documents\WindowsPowerShell\Scripts\remote_session_watch.ps1
```

De repository bevat bewust de oorspronkelijke prototypeversie. De watcher combineert de drie bovenstaande detectors. De daarin aanwezige oude claim- en toestandslogica is achterhaald en is geen onderdeel van het huidige ontwerp.

De detectieproeven kunnen bij de implementatie worden gebruikt voor diagnose en, voor AnyDesk en TeamViewer, voor het vaststellen of verbindingen tijdens `AFSLUITEN` zijn beëindigd.
