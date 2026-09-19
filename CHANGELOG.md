# Changelog

## 3.0.0 — 2026-09-19
* The eye is the cursor: the system pointer is hidden while the eye is up (it comes back on the option rows).
* LXRCore v3 release line: every resource ships as 3.0.0 from here (the entries below are the road to it).

## 1.1.2 — 2026-09-19
* Fix: the eye crashed on its first scan — `GetActiveScreenResolution` does not exist in RDR3; `GET_SCREEN_RESOLUTION` now. With 1.1.1 this is the first build where the card, the prompts and the eye all run.

## 1.1.1 — 2026-09-19
* Fix: the card scan loop crashed on the first tick (`attempt to index a nil value 'eye'`) — the eye's state was declared below the loop that reads it. No card, no prompt, no eye until now.

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
