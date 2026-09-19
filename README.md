<img src="https://raw.githubusercontent.com/LXRCore/.github/main/profile/lxrcore-logo.png" alt="LXRCore" width="72" align="left" style="margin-right:12px">

# lxr-interact — the interaction layer for LXRCore

One way to act on the world. A resource registers what can be acted on — a
point, a zone, a model, one entity, or every stranger, person, horse, wagon or
object — with a list of options. The player looks at it or stands in it, a
card lists the options with their keys, a key runs the option. Options are
gated by job, gang, item and a callback before they are shown, and options
that call the server go through one relay that checks the distance first.
Doors, shops, the bank, the law and the trades all sit on this.

![The interaction card](docs/img/card.png)

## What it does

* **Targets** — `AddPoint` (coords + reach), `AddZone` (sphere or rotated
  box), `AddModel` (one or many models), `AddEntity` (handle or network id),
  `AddGlobal` (`player` · `ped` · `horse` · `vehicle` · `object`).
  Registrations die with the resource that made them.
* **Looking wins** — the entity in the crosshair (one synchronous ray from
  the camera) is picked over a nearby point; points and zones rank by distance.
* **Gates** — `job = 'vallaw' | { 'a', 'b' } | { vallaw = 2 }`, `gang` in the
  same shapes, `item = 'lockpick' | { 'a', 'b' } (all) | { any = { 'a', 'b' } } (one) | { rope = 2 }`,
  `canInteract(entity, distance, option)`.
* **Keys** — an option names its key (`'G'` or a control hash) or takes the
  next free one from `Config.Keys`; never two rows on one key.
* **Actions** — `onSelect(data)`, a client `event`, or a `serverEvent`
  relayed with the target's network id after a server-side distance check.
* **Card or prompts** — `Config.Display.mode = 'card'` (the kit card, tap or
  hold) or `'prompts'` for the game's own prompt group.
* **Cost** — one scan every 250 ms while idle; per-frame only while a card is up.

## Install

```cfg
ensure lxr-core
ensure lxr-interact
```

## Use

```lua
local I = exports['lxr-interact']

I:AddPoint('vallaw:door', vector3(-275.6, 806.5, 119.4), { label = 'Sheriff\'s Office Door', options = {
    { label = 'Open the door', job = { 'vallaw' }, serverEvent = 'lxr-doors:server:toggle', args = { door = 'vallaw_front' } },
    { label = 'Pick the lock', item = 'lockpick', key = 'G', event = 'lxr-lockpick:client:start', args = { door = 'vallaw_front' } },
    { label = 'Knock', onSelect = function(d) TriggerEvent('lxr-me:client:say', 'knocks on the door') end },
}})

I:AddGlobal('lawman:player', 'player', { options = {
    { label = 'Search', job = 'vallaw', serverEvent = 'lxr-lawman:server:search' },
    { label = 'Cuff', job = 'vallaw', item = 'handcuffs', serverEvent = 'lxr-lawman:server:cuff' },
}})

I:AddModel('post:box', { 'p_postbox01x', 'p_postbox02x' }, { label = 'Post box', options = { { label = 'Send a letter', event = 'lxr-post:client:open' } } })
```

`data` handed to an action: `{ entity, netId, coords, kind, distance, args, label }`.
A relayed server event receives `(src, { entity, netId, coords, args })`.

## Configuration

`config.lua` — `Config.Lang`, `Config.Scan` (reach, ray flags, aim-only,
dead / cuffed), `Config.Display` (card or prompts, anchor, hold, marker),
`Config.Keys`, `Config.Kinds`, `Config.Security` (relay distance, rate limit).

## API

| Name | Side | Purpose |
|---|---|---|
| `AddPoint(id, coords, opts)` · `AddZone(id, zone, opts)` · `AddModel(id, models, opts)` · `AddEntity(id, entity, opts)` · `AddGlobal(id, kind, opts)` | client | register targets (`opts = { label, distance, options }`) |
| `Remove(id)` · `Disable(bool)` · `IsActive()` | client | housekeeping |
| `lxr-interact:server:relay` | server | internal — carries `serverEvent` options after the distance check |

## Licence

© 2026 iBoss21 / LXRCore — All Rights Reserved. See `LICENSE`.
