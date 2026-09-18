# Toestandsmachine

De pc-toestand en actieve claim worden uitsluitend beheerd door `PoortwachterService`.

De toestanden zijn:

```text
VRIJ
IN_GEBRUIK
AFSLUITEN
```

## VRIJ

Er is geen actieve claim. AnyDesk en TeamViewer zijn niet beschikbaar.

### CREATE_CLAIM

Bij een geldige `CREATE_CLAIM`:

1. maak AnyDesk beschikbaar;
2. maak TeamViewer beschikbaar;
3. alleen als beide acties slagen:
   - leg eigenaar vast;
   - zet `claimed_at = nu`;
   - zet `expires_at = nu + 1 uur`;
   - ga naar `IN_GEBRUIK`.

Als één van beide remote-tools niet beschikbaar kan worden gemaakt:

1. draai een eventuele gedeeltelijke wijziging terug;
2. blijf `VRIJ`;
3. geef `FAILED` terug.

Wijzigingen aan de pc-toestand en claim worden één voor één verwerkt.

## IN_GEBRUIK

Er is één actieve claim. Vastgelegd zijn:

```text
owner
claimed_at
expires_at
```

Na `CREATE_CLAIM` moet binnen twee minuten een remote verbinding via een remote-app tot stand komen.

Een remote verbinding:
- maakt geen claim aan;
- wijzigt de eigenaar niet;
- wijzigt `claimed_at` niet;
- wijzigt `expires_at` niet.

Als binnen twee minuten geen remote verbinding tot stand komt:

```text
IN_GEBRUIK
→ AFSLUITEN
```

Als de remote verbinding wordt verbroken:

```text
IN_GEBRUIK
→ AFSLUITEN
```

### Verlengen

Tien minuten voor `expires_at` kan `Poortwachter.exe` lokaal om verlenging vragen.

Bij akkoord:

```text
expires_at = expires_at + 1 uur
```

De toestand blijft `IN_GEBRUIK`.

### Tijd verlopen

Als:

```text
nu >= expires_at
```

dan:

```text
IN_GEBRUIK
→ AFSLUITEN
```

## AFSLUITEN

Een nieuwe claim kan niet worden aangemaakt.

`PoortwachterService`:

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

De claim en pc-toestand worden persistent opgeslagen volgens `30-implementatie.md`.

### Geen actieve claim

Na een herstart zorgt de service dat AnyDesk en TeamViewer niet beschikbaar zijn. Daarna is de toestand `VRIJ`.

### Actieve claim, eindtijd nog niet bereikt

Als:

```text
state = IN_GEBRUIK
en
nu < expires_at
```

dan:

1. behoud eigenaar, `claimed_at` en `expires_at`;
2. maak AnyDesk en TeamViewer beschikbaar;
3. herstel `IN_GEBRUIK`.

Het gedrag als AnyDesk of TeamViewer hierbij niet beschikbaar kan worden gemaakt, is nog niet bepaald; zie `50-open-punten.md`.

### Actieve claim, eindtijd verstreken

Als:

```text
state = IN_GEBRUIK
en
nu >= expires_at
```

dan wordt de toestand `AFSLUITEN`. De verlopen claim wordt niet opnieuw actief gemaakt.

### Herstart tijdens AFSLUITEN

Als de persistente toestand `AFSLUITEN` is, hervat de service het afsluiten totdat AnyDesk en TeamViewer beide niet beschikbaar zijn. Daarna wordt de toestand `VRIJ`.

## Overgangen

```text
VRIJ
  │
  │ CREATE_CLAIM geslaagd
  ▼
IN_GEBRUIK
  │
  ├─ binnen 2 minuten geen remote verbinding
  ├─ remote verbinding verbroken
  └─ expires_at bereikt
       │
       ▼
   AFSLUITEN
       │
       │ AnyDesk en TeamViewer afgesloten
       ▼
      VRIJ
```

Remote verbindingen via AnyDesk, TeamViewer en Splashtop worden door `PoortwachterService` gedetecteerd en beïnvloeden de claim zoals hierboven beschreven.

## Persistente toestand

`PoortwachterService` bewaart de persistente toestand in:

```text
C:\ProgramData\Poortwachter\state.json
```

Het bestand bevat een versie en alleen de gegevens die nodig zijn om de claim en pc-toestand na herstart te herstellen. `claimed_at` en `expires_at` worden in UTC opgeslagen.

Updates worden niet in-place geschreven:

1. schrijf de volledige nieuwe toestand naar `state.json.tmp`;
2. flush het bestand naar disk met `Flush(true)`;
3. sluit het tijdelijke bestand;
4. vervang daarna `state.json` in één filesystem-operatie; bij de eerste opslag wordt het tijdelijke bestand naar `state.json` verplaatst.

Een achtergebleven `state.json.tmp` wordt bij startup niet als geldige toestand gebruikt.

Als `state.json` ontbreekt of niet betrouwbaar kan worden gelezen, gaat de service fail-closed te werk: AnyDesk en TeamViewer worden eerst niet beschikbaar gemaakt. Pas nadat dat is gelukt, wordt `VRIJ` opgeslagen.
