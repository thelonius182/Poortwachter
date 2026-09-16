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
Windows 10
```

Op de Nipper-pc draaien de volgende remote-tools machinebreed als `LocalSystem`-service:

```text
AnyDesk       service AnyDesk
TeamViewer    service TeamViewer
Splashtop     service SplashtopRemoteService
```

Er zijn vier gedeelde/functionele Windows-accounts.

## Medewerkers

Medewerkers gebruiken hun eigen Windows-, macOS- of Linux-apparaat.

Voor NipperSessie is daarop alleen een gewone webbrowser nodig.

Identiteit en autorisatie lopen via de Google Workspace van Stichting Concertzender.

## Publieke toegang

Voorkeursadres voor de webapp:

```text
https://nippersessie.concertzender.nl
```

Of dit adres al door een bestaand certificaat wordt gedekt, moet nog worden gecontroleerd.
