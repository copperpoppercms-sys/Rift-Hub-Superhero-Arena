# Rift Hub · Superhero Arena · v5.4

Full animated standalone UI for [Superhero Arena by The Duelists](https://www.roblox.com/games/78710221869926/Superhero-Arena). Place `78710221869926`, universe `10765491459`.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Superhero-Arena/main/main.lua"))()
```

## Combat

**Auto Farm** contains the existing auto-play behavior: opponent selection, native movement and dash requests, ability selection, timing, combos and camera aiming. It starts off; PLAY starts it and STOP releases its controls.

**Ultra Instinct** is independent of Auto Farm and starts off. It requests the game's normal dash input when its detected control is available. While dash is cooling down, unavailable or blocked by game state, it briefly sidesteps using ordinary `Humanoid:Move` input at the character's existing WalkSpeed. Defensive movement writes no character position, CFrame, velocity, WalkSpeed, anchor or humanoid-state properties. There is no cooldown bypass.

Native dash requests share conservative cooldown/retry timing with Auto Farm and consult exposed HUD cooldown attributes (`OnCooldown`, `Ready`, `CooldownRemaining`, `CooldownDuration`). If no duration is exposed, request timing defaults to 2.5 seconds. Hidden server cooldowns cannot be established from these client fields. Sending an input does not prove a dash was accepted, so normal walking steering remains available briefly after the request too. The game controls native dash distance and behavior.

Walking steering lasts at most 0.35 seconds, stops when its nearby destination is reached or passed, checks clearance while active, and releases its input afterward. The **Sidestep limit** caps the walking destination from 4–12 studs; it cannot guarantee a server/native dash distance cap. Normal walking might not reach the planned exit before the attack lands. Zero progress, movement locks, walls or an early warning that arrives too late can still prevent avoidance.

Real keyboard/joystick input takes priority and cancels the short defensive steering window. Dragging the hub, typing, losing focus, death/respawn, game movement locks, toggling defense off or unloading also release the owned input. ControlModule stays enabled. Auto Farm yields during the defense window and while the user moves manually.

The detector retains report-backed estimated ability cues (`castLocked`, `state=skill`, an Action animation plus cast lock with `busy=false`), independent swing/cast fields and short attribute transitions. The configured nearby range applies to both melee and ability cues. ClientFX footsteps, rock trails, tiny slam-radius parts and shield echoes do not establish real damage geometry. The report exposed no recognized attack hitboxes; automatic avoidance remains unverified live.

**Diagnosing a missed dodge:**

1. Re-execute v5.4, open Combat, and enable Ultra Instinct. Release the movement stick/keys while testing automation.
2. **Test normal sidestep** requests a brief normal-speed walk through the same clearance checks; it works with defense off and does not request a dash.
3. **Record nearby attacks · 10 sec** observes an encounter. The recorder alone does not start automatic movement.
4. **Copy dodge report** includes automatic/manual counts, native dash request and walking-fallback counts, the latest dash availability reason, cue filtering, clearance failures, observed attributes/animations/effects and local movement observations. These are requests and observations, not proof of a successful dodge. Reports stay in the client/clipboard.

The trace keeps at most 100 events. Recording stops after roughly 10 seconds of processed client time. Position returning near its starting point can be correction or later movement; the report cannot identify anti-cheat by itself.

## Visuals

ESP shows only hero-colored chams, a hero role above the exact @username, and their toggles. There are no distance labels, boxes, tracers or health bars. Cham opacity is adjustable; Galactic Thanos uses a slow rainbow color.

Confirmed aliases: Water → Aquaman, Earth → Hulk, Knight → Thor, Samurai → Deadpool, Nature → Groot. Current `MorphCurrent` and `power` fields take priority. Direct roster names match automatically; explicit unambiguous menu ID/name pairs can supply additional mappings. Optional estimates are labelled **estimate**. Other IDs remain visible as **unmapped**; Angel is not assigned a fictional confirmed mapping. Settings → Copy diagnostics includes per-player role sources and defense state.

## Interface and full code

Combat, Visuals and Settings use graphite surfaces, violet accents, opening/tab fades, animated switches, sliders, and hover/press effects. The original Rift R emblem remains centered in the header and minimized button. Drag the header, minimize to the draggable emblem, or press RightShift. Phone portrait and landscape layouts adapt without shrinking normal-sized text. Settings include Reduce motion, Copy diagnostics, Rejoin and Unload. Credits identify N0VA_0100.

The universal [Rift Hub](https://github.com/copperpoppercms-sys/Rift-Hub) still launches this standalone script from Hub → Superhero Arena → Execute. It closes the universal hub and opens the new interface with Auto Farm and Ultra Instinct off. Closing or re-executing releases the script's controls, animation listeners, ESP and UI callbacks.

Download `docs/SuperheroArena_Editor.html`, open it in a browser, and use Copy all code or edit/download the complete Lua. The controller files under `src/` are embedded directly in `main.lua`, so no external UI library or module download is required. The game icon and original user-provided logo assets are preserved.

## Verification

Set `LUAU_BIN` and `LUAU_COMPILE_BIN` to native Luau executables, then run `python tests/run_checks.py`. The current suite passes 353 simulated checks covering the auto-play core, role sources, confidence labels, ESP toggles, native dash availability and request timing, walking fallback during cooldown, bounded steering/release, no defensive position writes, manual override, movement locks, obstacles, ground/destination checks, report-derived cast cues and configured range, independent attack sources, short transitions, geometry destination planning and recorder-only operation, mobile layout, drag limits, startup failure, re-execution and cleanup. These checks do not establish live Roblox rendering, replicated attack cue availability, hit registration or server acceptance.
