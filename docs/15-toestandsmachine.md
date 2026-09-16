# Toestandsmachine

De sessietoestand wordt uitsluitend beheerd door `NipperSessieService`.

De toestanden zijn:

```text
VRIJ
IN_GEBRUIK
AFSLUITEN
```

## VRIJ

Er is geen actieve NipperSessie. AnyDesk en TeamViewer zijn niet beschikbaar.

### START_SESSION

Bij een geldige `START_SESSION`:

1. maak AnyDesk beschikbaar;
2. maak TeamViewer beschikbaar;
3. alleen als beide acties slagen:
   - leg eigenaar vast;
   - zet `started_at = nu`;
   - zet `ends_at = nu + 1 uur`;
   - ga naar `IN_GEBRUIK`.

Als één van beide remote-tools niet beschikbaar kan worden gemaakt:

1. draai een eventuele gedeeltelijke wijziging terug;
2. blijf `VRIJ`;
3. geef `FAILED` terug.

Wijzigingen aan de sessietoestand worden één voor één verwerkt.

## IN_GEBRUIK

Er is één actieve NipperSessie. Vastgelegd zijn:

```text
owner
started_at
ends_at
```

Een remote-verbinding via AnyDesk of TeamViewer:

- start de NipperSessie niet;
- wijzigt de eigenaar niet;
- wijzigt `started_at` niet;
- wijzigt `ends_at` niet.

Een verbroken remote-verbinding beëindigt de NipperSessie niet.

Splashtop heeft geen invloed op de sessietoestand.

### Verlengen

Tien minuten voor `ends_at` kan `NipperSessie.exe` lokaal om verlenging vragen.

Bij akkoord:

```text
ends_at = ends_at + 1 uur
```

De toestand blijft `IN_GEBRUIK`.

### STOP_SESSION

`STOP_SESSION` wordt alleen geaccepteerd als `user.id` gelijk is aan `owner.id`.

Bij een geldige `STOP_SESSION`:

```text
IN_GEBRUIK
→ AFSLUITEN
```

### Tijd verlopen

Als:

```text
nu >= ends_at
```

dan:

```text
IN_GEBRUIK
→ AFSLUITEN
```

## AFSLUITEN

Een nieuwe NipperSessie kan niet worden gestart.

`NipperSessieService`:

1. beëindigt bestaande AnyDesk-verbindingen;
2. beëindigt bestaande TeamViewer-verbindingen;
3. maakt AnyDesk niet beschikbaar;
4. maakt TeamViewer niet beschikbaar;
5. laat Splashtop ongemoeid.

Als AnyDesk en TeamViewer beide zijn afgesloten en niet beschikbaar zijn:

```text
AFSLUITEN
→ VRIJ
```

Als dat niet lukt, blijft de toestand `AFSLUITEN`. De service blijft proberen de vereiste eindtoestand te bereiken.

## Herstart van Windows

De sessietoestand wordt persistent opgeslagen.

### Geen actieve sessie

Na een herstart zorgt de service dat AnyDesk en TeamViewer niet beschikbaar zijn. Daarna is de toestand `VRIJ`.

### Actieve sessie, eindtijd nog niet bereikt

Als:

```text
state = IN_GEBRUIK
en
nu < ends_at
```

dan:

1. behoud eigenaar, `started_at` en `ends_at`;
2. maak AnyDesk en TeamViewer beschikbaar;
3. herstel `IN_GEBRUIK`.

Het gedrag als AnyDesk of TeamViewer hierbij niet beschikbaar kan worden gemaakt, is nog niet bepaald; zie `50-open-punten.md`.

### Actieve sessie, eindtijd verstreken

Als:

```text
state = IN_GEBRUIK
en
nu >= ends_at
```

dan wordt de toestand `AFSLUITEN`. De verlopen sessie wordt niet opnieuw beschikbaar gemaakt.

### Herstart tijdens AFSLUITEN

Als de persistente toestand `AFSLUITEN` is, hervat de service het afsluiten totdat AnyDesk en TeamViewer beide niet beschikbaar zijn. Daarna wordt de toestand `VRIJ`.

## Overgangen

```text
VRIJ
  │
  │ START_SESSION geslaagd
  ▼
IN_GEBRUIK
  │
  ├─ STOP_SESSION
  │
  └─ ends_at bereikt
       │
       ▼
   AFSLUITEN
       │
       │ AnyDesk en TeamViewer afgesloten
       ▼
      VRIJ
```

Remote-verbindingen vormen geen toestanden en veroorzaken geen toestandsovergangen.
