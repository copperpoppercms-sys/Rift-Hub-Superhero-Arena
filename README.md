# Rift Hub · Superhero Arena · v5.1

Full animated standalone UI for [Superhero Arena by The Duelists](https://www.roblox.com/games/78710221869926/Superhero-Arena). Place `78710221869926`, universe `10765491459`.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Superhero-Arena/main/main.lua"))()
```

## Combat

**Auto Farm** contains the existing auto-play behavior: opponent selection, native movement and dash requests, ability selection, timing, combos and camera aiming. It starts off; PLAY starts it and STOP releases its controls.

**Ultra Instinct** is independent of Auto Farm and starts off. It now makes one local position change instead of repeatedly steering the character or pressing dash. For replicated active attack/projectile parts overlapping the player's expanded body bounds, it computes a nearby horizontal exit, checks solid clearance and ground, and keeps the destination outside other detected attack volumes. The maximum displacement is adjustable from 4–12 studs (10 by default). If no clear exit fits the cap, it stays in place instead of moving across the map.

Active-volume detection uses explicit attack/hitbox metadata, ownership when exposed, and named attack volumes in runtime effects/ability folders. It ignores known own/team attacks, inactive volumes, ordinary character body hitboxes and unrelated static parts. Nearby spatial queries and newly spawned parts are monitored, including non-queryable parts and metadata that arrives shortly after parenting. These are client-visible bounds, not a guaranteed representation of a hidden server damage hitbox.

When no attack volume is exposed, observed nearby attack states, swing/cast counters, combo advances and recognizable attack animations can request a short fallback dodge. A generic high-priority action animation needs a simultaneous combat lock before it counts as evidence. Busy alone is not an attack cue. The fallback is explicitly labelled **hitbox unknown** and is not a promise that the destination lies outside an unseen hitbox. The nearby cue range is adjustable from 6–24 studs. Every move stays within the displacement cap. The server can still reject or correct local movement.

**Normal controls stay enabled.** Ultra Instinct never disables ControlModule, calls Humanoid:Move, anchors the root, changes WalkSpeed, forces a humanoid state or holds a dash key. Auto Farm now yields to real keyboard/joystick movement; releasing movement resumes it. This replaces v5.0's ControlModule takeover and repeated defensive steering.

## Visuals

ESP shows only hero-colored chams, a hero role above the exact @username, and their toggles. There are no distance labels, boxes, tracers or health bars. Cham opacity is adjustable; Galactic Thanos uses a slow rainbow color.

Confirmed aliases: Water → Aquaman, Earth → Hulk, Knight → Thor, Samurai → Deadpool, Nature → Groot. Current `MorphCurrent` and `power` fields take priority. Direct roster names match automatically; explicit unambiguous menu ID/name pairs can supply additional mappings. Optional estimates are labelled **estimate**. Other IDs remain visible as **unmapped**; Angel is not assigned a fictional confirmed mapping. Settings → Copy diagnostics includes per-player role sources and defense state.

## Interface and full code

Combat, Visuals and Settings use graphite surfaces, violet accents, opening/tab fades, animated switches, sliders, and hover/press effects. The original Rift R emblem remains centered in the header and minimized button. Drag the header, minimize to the draggable emblem, or press RightShift. Phone portrait and landscape layouts adapt without shrinking normal-sized text. Settings include Reduce motion, Copy diagnostics, Rejoin and Unload. Credits identify N0VA_0100.

The universal [Rift Hub](https://github.com/copperpoppercms-sys/Rift-Hub) still launches this standalone script from Hub → Superhero Arena → Execute. It closes the universal hub and opens the new interface with Auto Farm and Ultra Instinct off. Closing or re-executing releases the script's controls, animation listeners, ESP and UI callbacks.

Download `docs/SuperheroArena_Editor.html`, open it in a browser, and use Copy all code or edit/download the complete Lua. The controller files under `src/` are embedded directly in `main.lua`, so no external UI library or module download is required. The game icon and original user-provided logo assets are preserved.

## Verification

Set `LUAU_BIN` and `LUAU_COMPILE_BIN` to native Luau executables, then run `python tests/run_checks.py`. The current suite passes 288 simulated checks covering the auto-play core, role sources, confidence labels, ESP toggles, bounded geometry escapes, rotated hitboxes, own/inactive/oversized attacks, non-queryable effects, late metadata, manual input, obstructions, ground checks, mobile layout, drag limits, startup failure, re-execution and cleanup. These checks do not establish live Roblox rendering, replicated attack cue availability, hit registration or server acceptance.
