# md_carryprops

Modernes Prop- und Carry-System für FiveM Roleplay-Server.

Spieler können konfigurierte Props aufnehmen, tragen, schieben, im Bau-Modus platzieren und optional über ein Menü spawnen.

## Features

- Prop-Erkennung per Raycast mit Whitelist und Auto-Kategorisierung
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
ensure md_carryprops
```

3. Optional: `ox_lib`, `qb-menu` oder `es_extended` + `esx_menu_default` für erweiterte Menüs
4. `config.lua` nach Bedarf anpassen
5. Server neu starten

## Steuerung

| Taste | Aktion |
|-------|--------|
| `E` | Prop aufnehmen |
| `G` | Placement-Modus |
| `Linksklick` | Platzieren |
| `Rechtsklick` / `Backspace` | Abbrechen |
| `Mausrad` | Rotieren |
| `X` | Sicher ablegen |
| `/propmenu` | Prop-Menü öffnen |

Alle Tasten sind in `Config.Keys` änderbar.

## Wichtige Config-Punkte

| Einstellung | Beschreibung |
|-------------|--------------|
| `Config.UseWhitelist` | `true` = nur Props aus `AllowedProps` |
| `Config.AllowedProps` | Liste erlaubter Prop-Namen/Hashes |
| `Config.Categories` | Schlüsselwörter und Modus (`carry`/`push`/`place`) |
| `Config.AttachOffsets` | Position beim Tragen pro Kategorie |
| `Config.PropMenu` | Menü aktivieren, Jobs, Berechtigungen |
| `Config.Keys` | Tastenbelegung |
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

1. Auf einem Test-Server mit `ensure md_carryprops` starten
2. `Config.Debug = true` setzen für Konsolen-Logs
3. Zu einem Map-Prop aus `AllowedProps` gehen (z. B. Mülltonne)
4. Grünes Hand-Symbol erscheint → `E` drücken
5. Bei Kisten: Tragen testen; bei Tonnen: Schieben testen
6. `G` für Placement-Modus, Mausrad drehen, Linksklick platzieren
7. `X` zum sicheren Ablegen testen
8. `/propmenu` für Spawn-Menü testen

## Abhängigkeiten

Keine Pflicht-Abhängigkeiten. Optional:

- `ox_lib` (Menü + Notifications)
- `qb-core` + `qb-menu`
- `es_extended` + `esx_menu_default`

## Lizenz

Frei verwendbar für private und kommerzielle FiveM-Server.
