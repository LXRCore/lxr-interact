# Changelog

## 1.1.0 — 2026-09-19
* The eye: hold Left Alt (`Config.Eye`), a cursor, point at any registered entity / model / global kind / point within reach, click, pick. The card and prompt modes stay.
* Item gate accepts `{ any = { … } }` — one of them is enough.

## 1.0.0 — 2026-09-17

New resource, written on the LXRCore v3 native API (replaces the retired targeting build; the repository was renamed from lxr-target).

* Points, zones (sphere / rotated box), models, entities, global kinds (player, ped, horse, vehicle, object)
* Options gated by job, gang, item, `canInteract`; distinct keys per row; `onSelect` / client event / relayed server event
* The kit card (tap or hold) or the game's prompt group, `Config.Display.mode`
* One relay on the server with a distance check and rate limit
* Locales EN / KA, offline tests, LXR Night / LXR Morning
