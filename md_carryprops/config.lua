Config = {}

-- =============================================================================
-- ALLGEMEIN
-- =============================================================================

Config.Debug = false -- Aktiviert Konsolen-Logs für Entwicklung

Config.Locale = 'de' -- 'de' oder 'en'

Config.Locales = {
    de = {
        pickup = 'Prop aufnehmen',
        place_mode = 'Platzierungsmodus',
        place = 'Platzieren',
        cancel = 'Abbrechen',
        drop = 'Ablegen',
        rotate = 'Rotieren',
        no_prop = 'Kein gültiges Prop gefunden.',
        already_carrying = 'Du trägst bereits ein Objekt.',
        cannot_pickup = 'Dieses Objekt kann nicht aufgenommen werden.',
        placed = 'Objekt platziert.',
        dropped = 'Objekt abgelegt.',
        cancelled = 'Aktion abgebrochen.',
        dead = 'Du kannst das im aktuellen Zustand nicht tun.',
        in_vehicle = 'Steig zuerst aus dem Fahrzeug aus.',
        menu_disabled = 'Das Prop-Menü ist deaktiviert.',
        no_permission = 'Du hast keine Berechtigung für das Prop-Menü.',
        no_framework = 'Job-Prüfung nicht möglich – kein Framework gefunden.',
        prop_spawned = 'Prop gespawnt.',
        search_prompt = 'Suche (Prop-Name):',
        menu_title = 'Prop-Menü',
        menu_search = 'Suchen',
        menu_close = 'Schließen',
        pushing = 'Objekt wird geschoben',
        carrying = 'Objekt wird getragen',
        placement_blocked_prop = 'Hier steht bereits ein Objekt.',
        placement_blocked_wall = 'Du kannst das nicht in die Wand stellen.',
        placement_invalid = 'Ungültige Position.',
    },
    en = {
        pickup = 'Pick up prop',
        place_mode = 'Placement mode',
        place = 'Place',
        cancel = 'Cancel',
        drop = 'Drop',
        rotate = 'Rotate',
        no_prop = 'No valid prop found.',
        already_carrying = 'You are already carrying an object.',
        cannot_pickup = 'This object cannot be picked up.',
        placed = 'Object placed.',
        dropped = 'Object dropped.',
        cancelled = 'Action cancelled.',
        dead = 'You cannot do that right now.',
        in_vehicle = 'Exit the vehicle first.',
        menu_disabled = 'The prop menu is disabled.',
        no_permission = 'You do not have permission for the prop menu.',
        no_framework = 'Job check not possible – no framework found.',
        prop_spawned = 'Prop spawned.',
        search_prompt = 'Search (prop name):',
        menu_title = 'Prop Menu',
        menu_search = 'Search',
        menu_close = 'Close',
        pushing = 'Pushing object',
        carrying = 'Carrying object',
        placement_blocked_prop = 'There is already an object here.',
        placement_blocked_wall = 'You cannot place that into a wall.',
        placement_invalid = 'Invalid position.',
    },
}

-- =============================================================================
-- INTERAKTION (Alt-Auge / Target)
-- =============================================================================

Config.Interaction = {
    -- 'target' = ox_target / qb-target (Alt-Auge)
    -- 'raycast' = klassisch mit E-Taste und Hand-Symbol
    -- 'both' = beides gleichzeitig
    mode = 'target',

  -- 'auto' erkennt ox_target oder qb-target automatisch
    targetSystem = 'auto', -- 'auto' | 'ox_target' | 'qb-target'
    targetDistance = 2.5,
    targetIcon = 'fa-solid fa-hand',
    targetLabel = nil, -- nil = Config.L('pickup')
}

-- =============================================================================
-- TASTEN (FiveM Control-IDs)
-- https://docs.fivem.net/docs/game-references/controls/
-- =============================================================================

Config.Keys = {
    pickup = 38,           -- E
    placementMode = 47,    -- G
    place = 24,            -- Linksklick (Attack)
    cancel = 177,          -- Backspace
    cancelAlt = 25,        -- Rechtsklick (Aim)
    drop = 73,             -- X
    scrollUp = 14,         -- Mausrad hoch
    scrollDown = 15,       -- Mausrad runter
}

-- =============================================================================
-- DISTANZEN & PERFORMANCE
-- =============================================================================

Config.MaxRaycastDistance = 3.5       -- Maximale Distanz zum Anvisieren (Meter)
Config.PlacementDistance = 4.0      -- Abstand vor dem Spieler im Placement-Modus
Config.PlacementHeight = 0.5        -- Zusätzliche Höhe über dem Boden beim Schweben
Config.RotationSpeed = 3.0          -- Grad pro Scroll-Tick
Config.GroundSnapAttempts = 5       -- Versuche für Bodenhöhen-Berechnung
Config.IdleWait = 750               -- Wait(ms) wenn nichts passiert
Config.ActiveWait = 0               -- Wait(ms) bei aktiver Interaktion
Config.NearbyWait = 100             -- Wait(ms) wenn Spieler in der Nähe von Props ist

-- =============================================================================
-- PROP-KATEGORIEN (automatische Erkennung per Schlüsselwort)
-- =============================================================================

Config.Categories = {
    trash = {
        keywords = { 'bin', 'wheelie', 'trash', 'garbage', 'dumpster' },
        mode = 'push', -- push | carry | place
        label = 'Mülltonne',
    },
    cart = {
        keywords = { 'trolley', 'cart', 'roll', 'dolly', 'handtruck' },
        mode = 'push',
        label = 'Rollwagen',
    },
    box = {
        keywords = { 'box', 'crate', 'case', 'parcel', 'package' },
        mode = 'carry',
        label = 'Kiste',
    },
    construction = {
        keywords = { 'sign', 'barrier', 'cone', 'roadwork', 'worklight', 'pylon' },
        mode = 'place',
        label = 'Baustelle',
    },
}

-- Fallback wenn kein Schlüsselwort passt
Config.DefaultCategory = 'box'

-- =============================================================================
-- ERLAUBTE PROPS
-- Prop-Name (String) oder Hash (Zahl) – leer = alle Props erlaubt (nur Kategorie-Filter)
-- =============================================================================

Config.UseWhitelist = true -- false = alle Props mit passender Kategorie erlaubt

Config.AllowedProps = {
    -- Mülltonnen / Schiebbar
    'prop_bin_05a',
    'prop_bin_08a',
    'prop_bin_08open',
    'prop_wheelie_bin',
    'prop_dumpster_01a',
    'prop_dumpster_02a',
    'prop_dumpster_02b',

    -- Rollwagen / Trolleys
    'prop_flattruck_01a',
    'prop_trolley_01a',
    'prop_trolley_02a',
    'prop_shopping_trolly',

    -- Kisten / Tragbar
    'prop_box_wood02a',
    'prop_box_wood04a',
    'prop_box_wood05a',
    'prop_box_wood07a',
    'prop_crate_01a',
    'prop_crate_08a',
    'prop_cs_cardbox_01',
    'prop_cs_cardbox_02',

    -- Baustelle / Platzierbar
    'prop_barrier_work05',
    'prop_barrier_work06a',
    'prop_roadcone02a',
    'prop_roadcone02b',
    'prop_sign_road_01a',
    'prop_sign_road_02a',
    'prop_worklight_03a',
}

-- =============================================================================
-- MENÜ-SPAWNS (für /propmenu)
-- =============================================================================

Config.MenuProps = {
    { label = 'Mülltonne', model = 'prop_bin_05a', category = 'trash' },
    { label = 'Wheelie Bin', model = 'prop_wheelie_bin', category = 'trash' },
    { label = 'Holzkiste', model = 'prop_box_wood02a', category = 'box' },
    { label = 'Karton', model = 'prop_cs_cardbox_01', category = 'box' },
    { label = 'Rollwagen', model = 'prop_trolley_01a', category = 'cart' },
    { label = 'Einkaufswagen', model = 'prop_shopping_trolly', category = 'cart' },
    { label = 'Absperrung', model = 'prop_barrier_work05', category = 'construction' },
    { label = 'Leitkegel', model = 'prop_roadcone02a', category = 'construction' },
    { label = 'Baustellenschild', model = 'prop_sign_road_01a', category = 'construction' },
    { label = 'Arbeitsleuchte', model = 'prop_worklight_03a', category = 'construction' },
}

-- =============================================================================
-- ANIMATIONEN
-- =============================================================================

Config.Animations = {
    carry = {
        dict = 'anim@heists@box_carry@',
        anim = 'idle',
        flag = 49, -- Upper body only, loop
    },
    push = {
        dict = 'anim@heists@box_carry@',
        anim = 'walk',
        flag = 49,
    },
}

-- =============================================================================
-- ATTACH-OFFSETS pro Kategorie (bone 57005 = SKEL_R_Hand)
-- =============================================================================

Config.AttachOffsets = {
    trash = { bone = 57005, x = 0.0, y = -0.45, z = -0.05, rx = 0.0, ry = 0.0, rz = 0.0 },
    cart = { bone = 57005, x = 0.0, y = -0.45, z = -0.05, rx = 0.0, ry = 0.0, rz = 0.0 },
    box = { bone = 57005, x = 0.15, y = 0.0, z = -0.05, rx = 280.0, ry = 0.0, rz = 0.0 },
    construction = { bone = 57005, x = 0.1, y = 0.0, z = -0.1, rx = 280.0, ry = 0.0, rz = 0.0 },
}

-- Schiebe-Offset vor dem Spieler (relativ zum Ped)
Config.PushOffset = { x = 0.0, y = 1.15, z = -0.95 }

-- =============================================================================
-- PROP-MENÜ
-- =============================================================================

Config.PropMenu = {
    enabled = true,
    command = 'propmenu',
    permissionMode = 'everyone', -- 'everyone' | 'jobs' | 'disabled'
    allowedJobs = {
        police = true,
        mechanic = true,
        builder = true,
        garbage = true,
        ambulance = false,
    },
    -- Bevorzugtes Menü: 'auto' erkennt automatisch ox_lib > qb-menu > esx
    menuType = 'auto',
}

-- =============================================================================
-- EINSCHRÄNKUNGEN
-- =============================================================================

Config.Restrictions = {
    disableSprint = true,           -- Kein Rennen beim Tragen/Schieben
    disableJump = true,             -- Kein Springen
    walkSpeedMultiplier = 0.9,      -- Etwas langsamer laufen (1.0 = normal)
    validatePlacement = true,       -- Platzierung auf Props / in Wände blockieren
    placementOverlapPadding = 0.2,  -- Abstand zu anderen Props (Meter)
    wallCheckDistance = 0.35,       -- Mindestabstand zu Wänden (Meter)
}

-- =============================================================================
-- UI – Hand-Symbol in Bildschirmmitte
-- =============================================================================

Config.HandIcon = {
    enabled = false, -- Bei target-Modus nicht nötig (ox_target zeigt Alt-Auge)
    text = '✋',           -- Angezeigtes Symbol
    color = { r = 80, g = 220, b = 100, a = 220 },
    scale = 0.65,
    offsetY = 0.0,        -- Vertikale Verschiebung (0.5 = Mitte)
}

-- =============================================================================
-- HILFSFUNKTION: Locale abrufen
-- =============================================================================

function Config.L(key)
    local locale = Config.Locales[Config.Locale] or Config.Locales['en']
    return locale[key] or key
end
