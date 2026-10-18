# Rift Hub · Superhero Arena · v5.6

Full animated standalone UI for [Superhero Arena by The Duelists](https://www.roblox.com/games/78710221869926/Superhero-Arena). Place `78710221869926`, universe `10765491459`.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Superhero-Arena/main/main.lua"))()
```

## Combat

**Auto Farm** contains the existing auto-play behavior: opponent selection, native movement and dash requests, ability selection, timing, combos and camera aiming. It starts off; PLAY starts it and STOP releases its controls.

**Ultra Instinct** is independent of Auto Farm and starts off. It requests the game's native dash when its detected control is available, and otherwise steers ordinary walking at the character's existing WalkSpeed. It never writes defensive position, CFrame, velocity, WalkSpeed, anchor or humanoid-state properties. Native dash requests respect the exposed cooldown attributes and share conservative request/retry timing with Auto Farm; there is no cooldown bypass. Without exposed duration, timing defaults to 2.5 seconds. Input dispatch is not proof that the server accepted a dash.

**Mobile input:** controls with key hints (`Q`, `E`, etc.) now receive touches on their actual game HUD buttons on touch devices, including controls handled through InputBegan. The script no longer emits virtual keyboard input on touch clients, which can switch Roblox's preferred input away from touch and hide its joystick. A rejected touch does not fall through to a mouse event. A keyboard-only action without a mobile button is unavailable on touch, so defense uses walking instead. Desktop key bindings remain supported. This addresses a likely input-mode cause; live TouchGui behavior and actual mobile ability activation still need confirmation in Delta.

**Escape distance:** estimated attack cues now prefer diagonal movement away from the attacker, planning up to 8 studs for melee and 10 for abilities within the Sidestep limit. Smaller clear alternatives are tried when the preferred path is blocked. Known exposed bounds still use a geometry-planned exit. Steering may run for up to 0.5 seconds to travel farther than the prior 0.18-second window; it stops at the planned destination, after passing it, at its distance cap, or at the time deadline. Actual walking distance depends on current speed, collisions and game movement restrictions. The game determines native dash distance.

**Manual control:** held movement does not pause defense. The script snapshots the current camera-relative movement vector at the start of a dodge. Changing or releasing that input by more than 0.35 magnitude immediately ends the assist and restores live user input. Keyboard direction is a fallback when ControlModule cannot be read; if a touch direction is unavailable, the normal control frame resumes it. ControlModule stays enabled throughout. Typing, dragging, losing focus, death/respawn, game movement locks, toggling defense off or unloading release steering. Auto Farm separately yields while the user moves manually.

Report-backed estimated cues include `castLocked`, `state=skill`, Action animations plus a cast/combat lock, independent swing/cast fields and short attribute transitions. The configured nearby range applies to melee and abilities. ClientFX footsteps, rock trails, tiny slam-radius parts and shield echoes are not verified damage geometry. The reports exposed no recognized attack hitboxes; longer travel does not guarantee avoiding an unseen server attack.

**Diagnosing a missed dodge:**

1. Re-execute v5.6, open Combat, and enable Ultra Instinct. Minimize the interface while testing the game's mobile buttons.
2. **Test normal sidestep** requests a short ordinary walk with defense on or off, without a dash.
3. **Record nearby attacks · 10 sec** observes an encounter; recording alone does not enable automatic movement.
4. **Copy dodge report** includes movement/clearance counts, native-dash and walking requests, current input/window, observed travel, cue sources and filtering, clearance failures and observed attributes/animations/effects. These are local observations and requests, not proof of successful avoidance. Reports stay in the client/clipboard.

The trace retains at most 100 events. Recording stops after roughly 10 seconds of processed client time. Both processed-time and wall-clock deadlines bound a steering action. A return near the starting position can be correction or later movement; the report does not establish anti-cheat behavior.

## Visuals

ESP shows only hero-colored chams, a hero role above the exact @username, and their toggles. There are no distance labels, boxes, tracers or health bars. Cham opacity is adjustable; Galactic Thanos uses a slow rainbow color.

Confirmed aliases: Water → Aquaman, Earth → Hulk, Knight → Thor, Samurai → Deadpool, Nature → Groot. Current `MorphCurrent` and `power` fields take priority. Direct roster names match automatically; explicit unambiguous menu ID/name pairs can supply additional mappings. Optional estimates are labelled **estimate**. Other IDs remain visible as **unmapped**; Angel is not assigned a fictional confirmed mapping. Settings → Copy diagnostics includes per-player role sources and defense state.

## Interface and full code

Combat, Visuals and Settings use graphite surfaces, violet accents, opening/tab fades, animated switches, sliders, and hover/press effects. The original Rift R emblem remains centered in the header and minimized button. Drag the header, minimize to the draggable emblem, or press RightShift. Phone portrait and landscape layouts adapt without shrinking normal-sized text. Settings include Reduce motion, Copy diagnostics, Rejoin and Unload. Credits identify N0VA_0100.

The universal [Rift Hub](https://github.com/copperpoppercms-sys/Rift-Hub) still launches this standalone script from Hub → Superhero Arena → Execute. It closes the universal hub and opens the new interface with Auto Farm and Ultra Instinct off. Closing or re-executing releases the script's controls, animation listeners, ESP and UI callbacks.

Download `docs/SuperheroArena_Editor.html`, open it in a browser, and use Copy all code or edit/download the complete Lua. The controller files under `src/` are embedded directly in `main.lua`, so no external UI library or module download is required. The game icon and original user-provided logo assets are preserved.

## Verification

Set `LUAU_BIN` and `LUAU_COMPILE_BIN` to native Luau executables, then run `python tests/run_checks.py`. The current suite passes 371 simulated checks covering the auto-play core, role sources, confidence labels, ESP toggles, native dash availability and request timing, walking fallback during cooldown, bounded steering/release, no defensive position writes, touch dispatch without mobile keyboard/mouse fallback, farther walking travel and separation, held keyboard/joystick assistance, immediate changed-input override, restoration of live manual input, movement locks, obstacles, ground/destination checks, report-derived cast cues and configured range, independent attack sources, short transitions, geometry destination planning and recorder-only operation, mobile layout, drag limits, startup failure, re-execution and cleanup. These checks do not establish live Roblox rendering, replicated attack cue availability, hit registration or server acceptance.
