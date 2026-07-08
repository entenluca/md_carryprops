# md_carryprops

Modernes Prop- und Carry-System für FiveM Roleplay-Server.

Spieler können konfigurierte Props aufnehmen, tragen, schieben, im Bau-Modus platzieren und optional über ein Menü spawnen.

## Features

- **Alt-Auge-Interaktion** via ox_target / qb-target (Standard)
- Prop-Erkennung mit Whitelist und Auto-Kategorisierung
- Tragen mit Animation und Attach-Offsets
- Schieben für Rollwagen, Mülltonnen etc.
- Placement-/Bau-Modus mit Rotation und sicherem Boden-Snap
- Sichere Drop-Logik ohne Havok-Crashes
- Prop-Menü (`/propmenu`) mit ox_lib, qb-menu, ESX oder Fallback
- Job-Berechtigungen (ESX / QBCore / Standalone)
- Flexible Notifications
- Performance-optimiert (Idle ~0.00–0.01 ms)

## Ordnerstruktur

```
md_carryprops/
├── fxmanifest.lua
├── config.lua
├── README.md
├── shared/
│   └── utils.lua
├── client/
│   ├── framework.lua
│   ├── notify.lua
│   ├── push.lua
│   ├── carry.lua
│   ├── placement.lua
│   ├── interact.lua
│   ├── target.lua
│   ├── menu.lua
│   └── main.lua
└── server/
    ├── framework.lua
    └── main.lua
```

## Installation

1. Ordner `md_carryprops` in deinen `resources/`-Ordner kopieren
2. In `server.cfg` eintragen:

```cfg
ensure ox_target
ensure md_carryprops
```

3. Optional: `ox_lib`, `qb-menu` oder `es_extended` + `esx_menu_default` für erweiterte Menüs
4. `config.lua` nach Bedarf anpassen
5. Server neu starten

## Steuerung

### Alt-Auge (ox_target / qb-target) – Standard

1. **Linke Alt-Taste** gedrückt halten → Auge erscheint
2. Prop anvisieren → **„Prop aufnehmen“** wählen

### Nach dem Aufnehmen

| Taste | Aktion |
|-------|--------|
| `G` | Placement-Modus |
| `X` | Sicher ablegen |

### Placement-Modus

| Taste | Aktion |
|-------|--------|
| Linksklick | Platzieren |
| Rechtsklick / Backspace | Abbrechen |
| Mausrad | Rotieren |
| `/propmenu` | Prop-Menü |

### Fallback (ohne Target-System)

Automatischer Raycast-Modus mit `E`-Taste, wenn kein `ox_target` / `qb-target` gefunden wird.

```lua
Config.Interaction.mode = 'target'  -- 'target' | 'raycast' | 'both'
```

## Wichtige Config-Punkte

| Einstellung | Beschreibung |
|-------------|--------------|
| `Config.UseWhitelist` | `true` = nur Props aus `AllowedProps` |
| `Config.AllowedProps` | Liste erlaubter Prop-Namen/Hashes |
| `Config.Categories` | Schlüsselwörter und Modus (`carry`/`push`/`place`) |
| `Config.AttachOffsets` | Position beim Tragen pro Kategorie |
| `Config.PropMenu` | Menü aktivieren, Jobs, Berechtigungen |
| `Config.Interaction` | Alt-Auge: `mode`, `targetSystem`, `targetDistance` |
| `Config.MaxRaycastDistance` | Reichweite zum Anvisieren |
| `Config.RotationSpeed` | Grad pro Mausrad-Tick |
| `Config.Debug` | Debug-Logs in der Konsole |

### Job-Berechtigungen

```lua
Config.PropMenu = {
    enabled = true,
    permissionMode = 'jobs', -- 'everyone' | 'jobs' | 'disabled'
    allowedJobs = {
        police = true,
        mechanic = true,
    },
}
```

## Testen

1. `ensure ox_target` und `ensure md_carryprops` in der `server.cfg`
2. `Config.Debug = true` setzen
3. Zu einem Prop aus `AllowedProps` gehen (z. B. Mülltonne)
4. **Alt gedrückt halten** → Auge auf Prop → „Prop aufnehmen“
5. Kisten: Tragen testen; Tonnen: Schieben testen
6. `G` für Placement-Modus, Mausrad drehen, Linksklick platzieren
7. `X` zum sicheren Ablegen
8. `/propmenu` für Spawn-Menü testen

## Abhängigkeiten

Keine Pflicht-Abhängigkeiten. Empfohlen:

- `ox_target` oder `qb-target` (Alt-Auge-Interaktion)
- `ox_lib` (Menü + Notifications)
- `qb-core` + `qb-menu`
- `es_extended` + `esx_menu_default`

## Lizenz

Frei verwendbar für private und kommerzielle FiveM-Server.
