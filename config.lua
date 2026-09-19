--[[
    ██╗     ██╗  ██╗██████╗       ██╗███╗   ██╗████████╗███████╗██████╗  █████╗  ██████╗████████╗
    ██║     ╚██╗██╔╝██╔══██╗      ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗██╔══██╗██╔════╝╚══██╔══╝
    ██║      ╚███╔╝ ██████╔╝█████╗██║██╔██╗ ██║   ██║   █████╗  ██████╔╝███████║██║        ██║
    ██║      ██╔██╗ ██╔══██╗╚════╝██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗██╔══██║██║        ██║
    ███████╗██╔╝ ██╗██║  ██║      ██║██║ ╚████║   ██║   ███████╗██║  ██║██║  ██║╚██████╗   ██║
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝      ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝   ╚═╝

    LXR Core - Interact

    One interaction layer for the whole framework. A resource registers what
    can be acted on — a point, a zone, a model, an entity, or every ped /
    horse / wagon / player — with a list of options. The player looks at it
    or walks up to it, a card lists the options with their keys, a key press
    runs the option. Options are filtered by job, gang, item and a callback
    before they are ever shown.

    Brand:       LXRCore — Lux Empire eXperience RedM Core
    Product:     wolves.land / The Land of Wolves
    Developer:   iBoss21 / LXRCore
    Website:     https://www.lxrcore.com
    Discord:     https://discord.gg/GAhk8cgXe9
    GitHub:      https://github.com/LXRCore

    Version: 1.0.0
    Performance Target: 0.00 ms idle (one scan thread at Config.Scan.idleMs; per-frame only while a card is up)

    © 2026 iBoss21 / LXRCore | lxrcore.com | All Rights Reserved
]]

Config = Config or {}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ LANGUAGE ██████████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████
Config.Lang = 'en'

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ SCANNING ══════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
Config.Scan = {
    idleMs = 250,               -- how often the world is checked while nothing is targeted
    activeMs = 100,             -- while a card is up
    lookDistance = 3.0,         -- default reach for entity / model targets
    pointDistance = 2.0,        -- default reach for points and zone edges
    rayFlags = 1 | 2 | 4 | 8 | 16, -- map, vehicles, peds, ragdolls, objects
    aimOnly = false,            -- true: entity targets only while the free aim key is held
    preferLookAt = true,        -- the entity in the crosshair wins over a nearby point
    whileDead = false,
    whileCuffed = false,
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ DISPLAY ═══════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
-- 'card'    the kit card (NUI) with option rows and their keys — input read by this resource
-- 'prompts' the game's prompt group (core prompts) — no NUI
Config.Display = {
    mode = 'card',
    anchor = 'right',           -- 'right' | 'left' | 'center'
    marker = true,              -- small floor ring at points while their card is up
    maxOptions = 8,
    holdMs = 0,                 -- 0 tap; >0 hold to confirm (card mode shows a fill)
}

-- The eye: hold a key, a cursor appears, point it at anything registered, click, pick an option.
-- Works on top of the card (walking up to a point still shows its card).
Config.Eye = {
    enabled  = true,
    key      = 'LMENU',         -- RegisterKeyMapping name (players rebind it in the game's settings)
    reach    = 7.0,             -- how far the eye sees (metres)
    pointHit = 1.5,             -- a point counts when the ray lands within this of it
}

-- keys handed to options in order when an option does not name its own (control hashes)
Config.Keys = {
    { hash = 0xF3830D8E, label = 'J' },
    { hash = 0xCEFD9220, label = 'E' },
    { hash = 0x760A9C6F, label = 'G' },
    { hash = 0xE30CD707, label = 'R' },
    { hash = 0xD9D0E1C0, label = 'SPACE' },
    { hash = 0x8CC9CD42, label = 'X' },
    { hash = 0x9959A6F0, label = 'B' },
    { hash = 0x4CC0E2FE, label = 'H' },
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ GLOBAL TARGETS ════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
-- What counts as which kind when a resource registers AddGlobal(kind, …).
Config.Kinds = {
    player  = { label = 'Stranger' },
    ped     = { label = 'Person' },
    horse   = { label = 'Horse' },
    vehicle = { label = 'Wagon' },
    object  = { label = 'Object' },
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ SECURITY ══════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
-- Options that name a `serverEvent` are relayed through this resource with the target
-- entity's network id; the receiving resource must still validate distance and state.
Config.Security = {
    rateLimit = { windowMs = 2000, burst = 10 },
    maxRelayDistance = 6.0,     -- the server refuses relays for targets further than this
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ DEBUG ═════════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
Config.Debug = { printBanner = true, drawZones = false }
