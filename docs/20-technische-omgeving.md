# Technische omgeving

## Synology NAS

Model:

```text
Synology DS918+
```

DSM-versie:

```text
DSM 7.3.1-86003 Update 1
```

Beschikbaar:

- Container Manager
- DSM Reverse Proxy
- bestaand Synology DDNS-adres
- bestaande certificaten voor andere `concertzender.nl`-diensten

Netwerk:

- poort 80 wordt vanaf de Ziggo-router doorgestuurd naar de Synology;
- poort 443 wordt vanaf de Ziggo-router doorgestuurd naar de Synology.

## Nipper-pc

Besturingssysteem:

```text
Windows 10 Pro N
versie 22H2
build 19045
```

De Nipper-pc kan niet naar Windows 11 worden geüpgraded.

Stichting Concertzender gebruikt Extended Security Updates (ESU) voor Windows 10. De ESU-einddata zijn:

- jaar 1: 13 oktober 2026;
- jaar 2: 12 oktober 2027;
- jaar 3: 10 oktober 2028.

Op de Nipper-pc draaien de volgende remote-tools machinebreed als `LocalSystem`-service:

```text
AnyDesk       service AnyDesk
TeamViewer    service TeamViewer
Splashtop     service SplashtopRemoteService
```

Er zijn vier gedeelde/functionele Windows-accounts.

## Medewerkers

Medewerkers gebruiken hun eigen Windows-, macOS- of Linux-apparaat.

Voor Poortwachter is daarop alleen een gewone webbrowser nodig.

Identiteit en autorisatie lopen via de Google Workspace van Stichting Concertzender.

## Publieke toegang

Adres voor de webapp:

```text
https://nippersessie.concertzender.nl
```

Voor deze hostname wordt op de Synology een afzonderlijk Let's Encrypt-certificaat gebruikt, tenzij bij inrichting blijkt dat een bestaand certificaat de hostname al dekt.

Voor uitrol moet `nippersessie.concertzender.nl` in DNS naar het publieke adres van de Synology verwijzen.
