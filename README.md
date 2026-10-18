# Rift Hub · Superhero Arena · v5.8

Full animated standalone UI for [Superhero Arena by The Duelists](https://www.roblox.com/games/78710221869926/Superhero-Arena). Place `78710221869926`, universe `10765491459`.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Superhero-Arena/main/main.lua"))()
```

## Combat

**Auto Farm** contains the existing auto-play behavior: opponent selection, native movement and dash requests, ability selection, timing, combos and camera aiming. It starts off; PLAY starts it and STOP releases its controls.

**Ultra Instinct** is independent of Auto Farm and starts off. The v5.7 live report established two separate problems: the character was in a game-controlled input/ability lock (`LOCKED_INPUTS=true`, `cutsceneLock=true`, `canRun=false`), and requested burst speed was replaced by a value around 21. These fields do not identify anti-cheat; skill, stun or movement controllers can also own them. Increasing the requested speed does not remove a locked skill/cutscene or make a replaced WalkSpeed persist.

**v5.8 corrections:** when the game replaces burst speed, the controller preserves that value and continues its bounded sidestep at game-controlled speed, instead of canceling the entire maneuver. Further burst writes are suspended for that character/controller session after an override, and the UI reports **boost overridden by game**. A new character or re-execution can try again. This does not make a rejected boost work; fast movement then depends on an accepted native dash.

Defensive native dash requests no longer wait for Auto Farm's own planner recovery timer when game state allows a dash. The normal game locks, exposed cooldown and conservative shared dash request timing still apply. Existing attack recovery scheduling is preserved. Auto Farm holds new attacks while the defender has a fresh nearby threat, so its own skill requests do not immediately compete with defense. Already active game-locked abilities are not canceled or bypassed.

**Movement gates and observation:** status names the actual blocking input/cutscene/canRun field. Nearby opponents continue to be watched while the local character is locked. Old attack cues still expire; the controller does not replay an old dodge after a long cutscene. It never rewrites game lock attributes. A reported ready camera/input context is separate from the character's movement gate.

**Testing:** while the character can move normally, Combat → **Test game dash** requests the detected native control and never substitutes a speed burst. If it is cooling down or unavailable, that reason is reported. **Test sidestep** separately tries the configured fallback. Reports keep the latest automatic dash reason separate from manual tests, show configured versus last requested burst speed, and preserve attack/action traces without flooding them with generic Core/Movement animation starts or footstep effects. A sent native input remains unverified until its live effect is observed.

**Fast sidestep** remains on by default at speed 64 (adjustable 24–96). Accepted local bursts last at most 0.25 seconds and restore the previous value only if it is still owned by the burst. A game speed replacement is preserved. Without a usable boost, ordinary movement can continue for up to 0.5 seconds. Walking destinations are capped by Sidestep limit (4–12 studs, default 10), with diagonal retreats generally planning up to 8 studs for melee or 10 for abilities. Direction strength is reduced near the destination, and speed-dependent clearance checks bound the local route. No defensive position/CFrame/velocity writes are used. The game determines native dash distance and may reject or correct local movement.

**Controls:** mobile HUD controls receive touches rather than virtual keyboard events, including Q/E/etc key hints. Rejected touches do not fall through to mouse/keyboard. Held movement does not pause defense. Changing or releasing the camera-relative movement vector by more than 0.35 magnitude returns manual control. ControlModule stays enabled. Typing, dragging, focus loss, death, game movement locks, disabling defense/fast sidestep and unloading release owned steering and speed changes.

Report-backed cues include cast locks, skill states, Action animations combined with cast/combat locks, independent swing/cast fields and short attribute transitions. Nearby range applies to melee and abilities. ClientFX does not establish server damage geometry; the reports exposed no recognized attack hitboxes. Automatic avoidance, native mobile input activation and fast server-accepted movement remain unverified live.

Record nearby attacks and Copy dodge report retain local observations only. The recorder is observational and does not enable automatic movement by itself. Its trace retains 100 events and roughly 10 seconds of processed client time. Both wall-clock and processed-time deadlines bound steering.

## Visuals

ESP shows only hero-colored chams, a hero role above the exact @username, and their toggles. There are no distance labels, boxes, tracers or health bars. Cham opacity is adjustable; Galactic Thanos uses a slow rainbow color.

Confirmed aliases: Water → Aquaman, Earth → Hulk, Knight → Thor, Samurai → Deadpool, Nature → Groot. Current `MorphCurrent` and `power` fields take priority. Direct roster names match automatically; explicit unambiguous menu ID/name pairs can supply additional mappings. Optional estimates are labelled **estimate**. Other IDs remain visible as **unmapped**; Angel is not assigned a fictional confirmed mapping. Settings → Copy diagnostics includes per-player role sources and defense state.

## Interface and full code

Combat, Visuals and Settings use graphite surfaces, violet accents, opening/tab fades, animated switches, sliders, and hover/press effects. The original Rift R emblem remains centered in the header and minimized button. Drag the header, minimize to the draggable emblem, or press RightShift. Phone portrait and landscape layouts adapt without shrinking normal-sized text. Settings include Reduce motion, Copy diagnostics, Rejoin and Unload. Credits identify N0VA_0100.

The universal [Rift Hub](https://github.com/copperpoppercms-sys/Rift-Hub) still launches this standalone script from Hub → Superhero Arena → Execute. It closes the universal hub and opens the new interface with Auto Farm and Ultra Instinct off. Closing or re-executing releases the script's controls, animation listeners, ESP and UI callbacks.

Download `docs/SuperheroArena_Editor.html`, open it in a browser, and use Copy all code or edit/download the complete Lua. The controller files under `src/` are embedded directly in `main.lua`, so no external UI library or module download is required. The game icon and original user-provided logo assets are preserved.

## Verification

Set `LUAU_BIN` and `LUAU_COMPILE_BIN` to native Luau executables, then run `python tests/run_checks.py`. The current suite passes 437 simulated checks covering the auto-play core, role sources, confidence labels, ESP toggles, native dash availability and request timing, walking fallback during cooldown, bounded steering/release, no defensive position writes, continuation after game speed replacement, suppression of repeated rejected bursts, explicit local locks, observation while locked, native-only input test, defense priority and separate auto/test diagnostics, fast travel, original-speed restoration, preservation of game speed changes, cancellation/death/unload cleanup, delayed native fallback, touch dispatch without mobile keyboard/mouse fallback, farther walking travel and separation, held keyboard/joystick assistance, immediate changed-input override, restoration of live manual input, movement locks, obstacles, ground/destination checks, report-derived cast cues and configured range, independent attack sources, short transitions, geometry destination planning and recorder-only operation, mobile layout, drag limits, startup failure, re-execution and cleanup. These checks do not establish live Roblox rendering, replicated attack cue availability, hit registration or server acceptance.
