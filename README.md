# Rift Hub · Superhero Arena · v5.0

Full animated standalone UI for [Superhero Arena by The Duelists](https://www.roblox.com/games/78710221869926/Superhero-Arena). Place `78710221869926`, universe `10765491459`.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Superhero-Arena/main/main.lua"))()
```

## Combat

**Auto Farm** contains the existing auto-play behavior: opponent selection, native movement and dash requests, ability selection, timing, combos and camera aiming. It starts off; PLAY starts it and STOP releases its controls.

**Ultra Instinct** is independent of Auto Farm and starts off. It observes nearby opponents' replicated attack states, swing/cast counters, and recognizable attack animation names or explicit attack tags. When an opponent is facing the player, within range, and visible, it checks clear ground and body clearance before requesting a short sidestep. It can request the game's dash when available. Ability cue range is adjustable; melee cues use a smaller range. Idle animations, busy alone, obstructed opponents, unsafe ground, typing, cutscenes and movement locks do not trigger movement. It cannot anticipate hidden server-only attacks or unknown animation IDs, guarantee dodges, or bypass native cooldowns.

## Visuals

ESP shows only hero-colored chams, a hero role above the exact @username, and their toggles. There are no distance labels, boxes, tracers or health bars. Cham opacity is adjustable; Galactic Thanos uses a slow rainbow color.

Confirmed aliases: Water → Aquaman, Earth → Hulk, Knight → Thor, Samurai → Deadpool, Nature → Groot. Current `MorphCurrent` and `power` fields take priority. Direct roster names match automatically; explicit unambiguous menu ID/name pairs can supply additional mappings. Optional estimates are labelled **estimate**. Other IDs remain visible as **unmapped**; Angel is not assigned a fictional confirmed mapping. Settings → Copy diagnostics includes per-player role sources and defense state.

## Interface and full code

Combat, Visuals and Settings use graphite surfaces, violet accents, opening/tab fades, animated switches, sliders, and hover/press effects. The original Rift R emblem remains centered in the header and minimized button. Drag the header, minimize to the draggable emblem, or press RightShift. Phone portrait and landscape layouts adapt without shrinking normal-sized text. Settings include Reduce motion, Copy diagnostics, Rejoin and Unload. Credits identify N0VA_0100.

The universal [Rift Hub](https://github.com/copperpoppercms-sys/Rift-Hub) still launches this standalone script from Hub → Superhero Arena → Execute. It closes the universal hub and opens the new interface with Auto Farm and Ultra Instinct off. Closing or re-executing releases the script's controls, animation listeners, ESP and UI callbacks.

Download `docs/SuperheroArena_Editor.html`, open it in a browser, and use Copy all code or edit/download the complete Lua. The controller files under `src/` are embedded directly in `main.lua`, so no external UI library or module download is required. The game icon and original user-provided logo assets are preserved.

## Verification

Set `LUAU_BIN` and `LUAU_COMPILE_BIN` to native Luau executables, then run `python tests/run_checks.py`. The current suite passes 281 simulated checks covering the auto-play core, role sources, confidence labels, ESP toggles, independent defensive steering, animation cues, ranged windups, cooldowns, obstructions, ground checks, mobile layout, drag limits, startup failure, re-execution and cleanup. These checks do not establish live Roblox rendering, replicated attack cue availability, hit registration or server acceptance.
