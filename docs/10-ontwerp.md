# NipperSessie — geconsolideerd ontwerp

## 1. Doel

NipperSessie regelt het exclusieve gebruik op afstand van één Windows 10-pc van Stichting Concertzender: de **Nipper-pc**.

Er kan maximaal één NipperSessie tegelijk actief zijn.

Medewerkerstekst gebruikt steeds het begrip **sessie**. De zichtbare naam van het systeem is **NipperSessie**.

---

## 2. Sessiemodel

De sessietoestanden zijn:

```text
VRIJ
  ↓
Start NipperSessie
  ↓
IN_GEBRUIK
  ↓
Stop sessie
of sessietijd verlopen
  ↓
AFSLUITEN
  ↓
VRIJ

```

`WACHT_OP_VERBINDING` bestaat niet.

Een remote verbinding via AnyDesk, TeamViewer of Splashtop start geen NipperSessie en bepaalt de eigenaar niet.

Een sessie duurt standaard één uur.

De sessieduur wordt bepaald door `NipperSessieService`. De sessie begint bij een geslaagde `START_SESSION`; een remote verbinding hoeft daarvoor niet tot stand te zijn gekomen.

Een verbroken of opnieuw gemaakte remote verbinding verandert de sessieduur niet.

De formele toestandsmachine, inclusief overgangen, foutafhandeling en herstel na herstart, staat in `15-toestandsmachine.md`.

---

## 3. Eigenaar van de sessie

De Google Workspace-gebruiker die `Start NipperSessie` uitvoert, is eigenaar van de sessie.

De vier Windows-accounts op de Nipper-pc zijn gedeelde/functionele accounts en vormen geen identiteit binnen NipperSessie.

Ontwerpregel:

> De identiteit van een medewerker wordt uitsluitend bepaald via Google Workspace. Windows-accounts worden niet permanent aan medewerkers gekoppeld.

De vaste Google user id wordt gebruikt voor identificatie. De Google Workspace-weergavenaam wordt gebruikt voor presentatie aan medewerkers.

---

## 4. Authenticatie en autorisatie

NipperSessie beheert geen eigen gebruikers of wachtwoorden.

```text
Google Workspace login
        ↓
lid van nipper-groep?
        ↓
ja → toegang
nee → geen toegang

```

De medewerker gebruikt alleen een gewone browser. Op het eigen Windows-, macOS- of Linux-apparaat hoeft niets van NipperSessie te worden geïnstalleerd.

Een gebruiker die geen lid is van de groep ziet bijvoorbeeld:

```text
Nipper-pc niet beschikbaar:
Jan Jansen is geen lid van de nipper-groep

```

---

## 5. Webapp

Voorkeursadres:

```text
https://nippersessie.concertzender.nl

```

De webapp draait op de Synology NAS achter DSM Reverse Proxy.

De webapp:

- verzorgt de medewerker-UI;
- verzorgt Google Workspace-authenticatie en groepscontrole;
- stuurt opdrachten naar `NipperSessieService`;
- toont de door de service gemelde toestand;
- mag de laatst ontvangen toestand bewaren;
- beslist niet zelfstandig over de sessietoestand.

---

## 6. Autoriteit

`NipperSessieService` op de Nipper-pc is de enige autoriteit over:

- sessietoestand;
- eigenaar;
- starttijd;
- eindtijd;
- verlengen;
- verlopen;
- afsluiten;
- beschikbaarheid van AnyDesk en TeamViewer binnen NipperSessie.

De webapp vraagt; de service beslist en bevestigt.

---

## 7. Remote-tools

Op de Nipper-pc draaien:

```text
AnyDesk       service AnyDesk
TeamViewer    service TeamViewer
Splashtop     service SplashtopRemoteService

```

Alle drie draaien machinebreed als `LocalSystem`.

### Splashtop

Splashtop is de beheer-/noodroute.

NipperSessie:

- schakelt Splashtop nooit uit;
- schakelt Splashtop niet in;
- gebruikt Splashtop niet om een medewerker te identificeren;
- gebruikt Splashtop niet om een sessie te starten of beëindigen.

Onderhoud loopt buiten NipperSessie via het onderhoudsluik en zo nodig Splashtop.

### AnyDesk en TeamViewer

Bij `Start NipperSessie` maakt `NipperSessieService` AnyDesk en TeamViewer beschikbaar.

De sessie start alleen als beide beschikbaar kunnen worden gemaakt. Mislukt dat voor één van beide, dan wordt een eventuele gedeeltelijke wijziging teruggedraaid en start de sessie niet.

Bij `Stop sessie` en bij verlopen van de sessietijd beëindigt de service bestaande AnyDesk- en TeamViewer-verbindingen en maakt beide tools niet beschikbaar. Splashtop blijft ongemoeid.

Tijdens het afsluiten kan geen nieuwe sessie worden gestart. De toestandovergangen staan in `15-toestandsmachine.md`.

De medewerker ziet dan:

```text
Status: Nipper-pc is de vorige sessie nog aan het afsluiten

```

---

## 8. Verlengen

Tien minuten voor het eindtijdstip verschijnt lokaal op de Nipper-pc:

```text
NipperSessie

Je sessie verloopt over 10 minuten.

Verlengen met 1 uur?

[ Ja ]   [ Nee ]

```

`Ja`:

- verlengt `ends_at` met één uur;
- sluit de melding.

`Nee`:

- verandert niets;
- sluit de melding.

Er verschijnt geen aparte bevestiging.

Tien minuten voor het nieuwe eindtijdstip verschijnt dezelfde melding opnieuw.

Er is geen maximumaantal verlengingen.

Verlengen gebeurt lokaal tussen `NipperSessie.exe` en `NipperSessieService`; het is geen opdracht vanuit de webapp.

---

## 9. Herstart van de Nipper-pc

Een herstart verandert eigenaar en eindtijd van een lopende sessie niet.

De sessietoestand wordt lokaal persistent opgeslagen. `NipperSessieService` herstelt na een herstart de juiste toestand en beschikbaarheid van AnyDesk en TeamViewer. De herstelregels staan in `15-toestandsmachine.md`.

---

## 10. Uitval van NAS, webapp of netwerk

Een lopende sessie is niet afhankelijk van de Synology-webapp.

Bij verlies van contact:

- blijft de sessie lokaal doorlopen;
- blijven eigenaar en eindtijd gelijk;
- blijft de 10-minutenmelding werken;
- kan lokaal worden verlengd;
- beëindigt de service de sessie zelfstandig wanneer de tijd verloopt.

De webapp toont bij verlies van de verbinding:

```text
Status: Nipper-pc is niet bereikbaar

Probeer het later opnieuw.

```

Er zijn dan geen Start- of Stop-knoppen.

Na herstel stuurt `NipperSessieService` zijn volledige actuele toestand opnieuw.

---

## 11. Medewerker-UI

### Vrij

```text
NipperSessie

Status: Vrij

De Nipper-pc is beschikbaar.

[ Start NipperSessie ]

```

### Eigen sessie

```text
NipperSessie

Status: In gebruik

Jouw sessie loopt nog 42 minuten.

[ Stop sessie ]

```

### Sessie van iemand anders

```text
NipperSessie

Status: In gebruik

De Nipper-pc is in gebruik door Jan Jansen.

Nog 27 minuten.

```

### Afsluiten

```text
NipperSessie

Status: Nipper-pc is de vorige sessie nog aan het afsluiten

```

### Niet bereikbaar

```text
NipperSessie

Status: Nipper-pc is niet bereikbaar

Probeer het later opnieuw.

```

### Start wordt verwerkt

```text
NipperSessie

NipperSessie wordt gestart…

```

### Stop wordt verwerkt

```text
NipperSessie

NipperSessie wordt afgesloten…

```

### Start mislukt

```text
NipperSessie kon niet worden gestart.

```

Daarna wordt de actuele door de service gemelde toestand getoond.

De precieze formulering van medewerkersteksten kan later nog worden aangescherpt.

---

## 12. Automatische actualisering

Een open webpagina wordt automatisch bijgewerkt.

De resterende tijd kan in de browser aftellen, maar de door `NipperSessieService` gemelde `ends_at` blijft bepalend.

Bij verlenging wordt de nieuwe eindtijd automatisch in de UI verwerkt.

---

## 13. Communicatie webapp ↔ service

`NipperSessieService` onderhoudt zelf een permanente beveiligde WebSocket-verbinding met de webapp:

```text
NipperSessieService
        │
        │ WSS
        ▼
Synology :443
DSM Reverse Proxy
        │
        ▼
NipperSessie-webapp

```

Er hoeft geen aparte inkomende NipperSessie-poort op Windows te worden geopend.

De verbinding wordt gebruikt voor drie soorten berichten:

```text
webapp → service
    COMMAND

service → webapp
    COMMAND_RESULT

service → webapp
    STATUS

```

---

## 14. Opdrachten

### START\_SESSION

```text
command: START_SESSION
request_id: <unieke id>
user:
  id: <Google-user-id>
  display_name: Jan Jansen

```

### STOP\_SESSION

```text
command: STOP_SESSION
request_id: <unieke id>
user:
  id: <Google-user-id>

```

De webapp controleert Google-authenticatie en groepslidmaatschap.

De service vertrouwt de via de beveiligde verbinding aangeleverde Google-identiteit, maar controleert zelf of de opdracht past bij zijn actuele toestand.

`STOP_SESSION` wordt alleen geaccepteerd als `user.id` gelijk is aan de `owner.id` van de actieve sessie.

---

## 15. Opdrachtresultaat

Geslaagd:

```text
request_id: <id>
result: OK

```

Mislukt:

```text
request_id: <id>
result: FAILED
reason: <technische reden>

```

`reason` is bedoeld voor logging en diagnose, niet rechtstreeks voor medewerkerstekst.

Na verwerking stuurt de service altijd opnieuw zijn volledige actuele status.

`request_id` maakt opdrachten idempotent: dezelfde opdracht met dezelfde id wordt niet tweemaal uitgevoerd.

---

## 16. Statusbericht

Ieder statusbericht is een complete momentopname.

### Vrij

```text
status_id: <id>
state: VRIJ

```

### In gebruik

```text
status_id: <id>
state: IN_GEBRUIK

owner:
  id: <Google-user-id>
  display_name: Jan Jansen

started_at: <tijdstip>
ends_at: <tijdstip>

```

### Afsluiten

```text
status_id: <id>
state: AFSLUITEN

```

`status_id` verandert bij iedere relevante wijziging, waaronder starten, verlengen en toestandswisselingen.

De webapp vervangt zijn vorige status door het complete nieuwe statusbericht.

---

## 17. Gelijktijdige opdrachten

Wijzigingen aan de sessietoestand worden door `NipperSessieService` één voor één verwerkt.

Bij twee vrijwel gelijktijdige Start-opdrachten kan daarom maar één opdracht slagen.

De andere krijgt een foutresultaat en daarna de actuele toestand.

Er is geen wachtrij voor medewerkers.

---

## 18. Verbinding en heartbeat

`NipperSessieService` bouwt de WebSocket-verbinding zelf op.

Bij iedere nieuwe verbinding stuurt de service onmiddellijk een volledige `STATUS`.

Voor verbindingsbewaking:

- service stuurt iedere 20 seconden een heartbeat;
- na 60 seconden zonder bericht beschouwt de webapp de service als niet bereikbaar;
- bij een expliciet verbroken WebSocket kan dit direct worden vastgesteld;
- na herstel wordt opnieuw een volledige status gestuurd.

Heartbeats zijn geen onderdeel van de sessietoestand en hoeven niet afzonderlijk te worden gelogd.

---

## 19. Authenticatie service ↔ webapp

De WebSocket gebruikt TLS.

Daarnaast authenticeert `NipperSessieService` zich met een afzonderlijk willekeurig service-secret.

Dit secret:

- staat alleen op de Nipper-pc en bij de webapp;
- wordt nooit naar de browser gestuurd;
- heeft niets met Google Workspace-accounts te maken;
- kan worden vervangen als dat nodig is.

---

## 20. Logging

### `NipperSessieService`

De lokale logging bevat ten minste:

- starten van een sessie;
- stoppen;
- verlengen;
- verlopen;
- overgang naar `AFSLUITEN`;
- overgang naar `VRIJ`;
- acties op AnyDesk en TeamViewer;
- fouten daarbij;
- herstel na Windows-herstart;
- verbinden/verbreken met de webapp;
- overige relevante fouten.

Heartbeats worden niet afzonderlijk gelogd.

### Webapp

De webapp logt ten minste:

- Google-login geslaagd/mislukt;
- controle van lidmaatschap van de `nipper-groep`;
- verzonden `START_SESSION` en `STOP_SESSION`;
- ontvangen opdrachtresultaten;
- verbinden/verbreken van `NipperSessieService`;
- relevante communicatiefouten.

De webapp houdt geen eigen sessiegeschiedenis bij om daarmee de toestand te reconstrueren.

---

## 21. Geen beheer-UI

NipperSessie krijgt geen aparte beheerpagina.

Technische diagnose en onderhoud lopen via het bestaande onderhoudsluik en zo nodig Splashtop.

De medewerker-UI toont daarom niet:

- Windows-accounts;
- AnyDesk-/TeamViewer-/Splashtop-status;
- WebSocket-status;
- technische foutcodes;
- logs;
- beheerknoppen.

---

## 22. Scheiding van verantwoordelijkheden

```text
Google Workspace
    identiteit en groepslidmaatschap

Synology-webapp
    medewerker-UI
    authenticatie/autorisatie
    doorgeven van opdrachten
    tonen van actuele status

NipperSessieService
    autoriteit over sessie
    sessietijd
    lokale persistentie
    AnyDesk en TeamViewer
    communicatie met webapp

NipperSessie.exe
    lokale 10-minutenmelding
    verzoek tot verlengen

Splashtop / onderhoudsluik
    beheer en noodroute
    buiten NipperSessie

```
