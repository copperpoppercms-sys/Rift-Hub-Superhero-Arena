# Rift Hub · Superhero Arena · v5.7

Full animated standalone UI for [Superhero Arena by The Duelists](https://www.roblox.com/games/78710221869926/Superhero-Arena). Place `78710221869926`, universe `10765491459`.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Superhero-Arena/main/main.lua"))()
```

## Combat

**Auto Farm** contains the existing auto-play behavior: opponent selection, native movement and dash requests, ability selection, timing, combos and camera aiming. It starts off; PLAY starts it and STOP releases its controls.

**Ultra Instinct** is independent of Auto Farm and starts off. **Fast sidestep** is enabled by default, with **Burst speed = 64** (adjustable from 24–96). During a fallback, it briefly requests that local WalkSpeed and steers toward the nearby escape destination. The burst lasts at most 0.25 seconds and its walking destination remains capped by Sidestep limit (4–12 studs, default 10). This changes speed, rather than merely increasing the requested walking distance.

The previous WalkSpeed is restored after completion, changed manual input, an obstruction, typing/focus loss, game movement locks, death, disabling defense/fast sidestep or unloading. Restoration only replaces a value still owned by this burst. If the game changes speed during the maneuver, the assist stops and preserves that newer value. There is no repeated forcing of the boosted speed. The game/server can reject or correct this client-side speed request; it does not establish a cooldown bypass or guaranteed dodge.

The normal native dash is requested first when available, respecting exposed cooldown attributes and conservative shared request timing. When a native request is sent, the controller waits briefly before boosting: the fallback engages only if the game has not changed WalkSpeed or produced fast travel. This avoids treating input dispatch as proof of activation and avoids overwriting a speed set by the native dash. Actual native dash distance is controlled by the game.

With Fast sidestep off, fallback uses ordinary walking for up to 0.5 seconds. Destination planning prefers diagonal retreats of up to 8 studs for melee and 10 for abilities, with smaller clear alternatives when blocked. Direction input is reduced near the endpoint to limit overshooting, and path clearance is rechecked with a speed-dependent lookahead. No defensive position, CFrame or velocity writes are used.

**Mobile input:** mobile HUD buttons receive touches instead of virtual keyboard events, including controls with Q/E/etc key hints. A rejected touch does not fall back to mouse/keyboard. Keyboard-only actions without mobile buttons are unavailable on touch. This addresses a likely input-mode cause of the joystick disappearing, but actual mobile ability activation still needs live confirmation. Minimize the hub during play so its window does not cover game buttons.

**Manual control:** holding movement does not pause defense. Changing or releasing the camera-relative movement vector by more than 0.35 magnitude ends steering and restores current user input. ControlModule remains enabled. A held-key fallback is used if the module cannot be read; unknown touch direction resumes through the normal control frame. Auto Farm separately yields while the user moves manually.

Report-backed cues include cast locks, skill states, Action animations plus combat/cast locks, independent swing/cast fields and short attribute transitions. Nearby range applies to melee and abilities. ClientFX effects do not establish server damage geometry; the reports exposed no recognized attack hitboxes. Live avoidance remains unverified.

**Testing and diagnostics:** enable Ultra Instinct under Combat, leave Fast sidestep on, and adjust Burst speed if needed. Test sidestep uses the configured fallback without requesting a native dash. Record nearby attacks and Copy dodge report include burst counts, requested speed, restoration/game-override status, actual observed travel, native requests, cue filtering and clearance reasons. These are local observations, not proof of server acceptance. Reports stay in the client/clipboard. The trace keeps 100 events and recording lasts roughly 10 seconds of processed time. Both wall-clock and processed-time deadlines bound steering.

## Visuals

ESP shows only hero-colored chams, a hero role above the exact @username, and their toggles. There are no distance labels, boxes, tracers or health bars. Cham opacity is adjustable; Galactic Thanos uses a slow rainbow color.

Confirmed aliases: Water → Aquaman, Earth → Hulk, Knight → Thor, Samurai → Deadpool, Nature → Groot. Current `MorphCurrent` and `power` fields take priority. Direct roster names match automatically; explicit unambiguous menu ID/name pairs can supply additional mappings. Optional estimates are labelled **estimate**. Other IDs remain visible as **unmapped**; Angel is not assigned a fictional confirmed mapping. Settings → Copy diagnostics includes per-player role sources and defense state.

## Interface and full code

Combat, Visuals and Settings use graphite surfaces, violet accents, opening/tab fades, animated switches, sliders, and hover/press effects. The original Rift R emblem remains centered in the header and minimized button. Drag the header, minimize to the draggable emblem, or press RightShift. Phone portrait and landscape layouts adapt without shrinking normal-sized text. Settings include Reduce motion, Copy diagnostics, Rejoin and Unload. Credits identify N0VA_0100.

The universal [Rift Hub](https://github.com/copperpoppercms-sys/Rift-Hub) still launches this standalone script from Hub → Superhero Arena → Execute. It closes the universal hub and opens the new interface with Auto Farm and Ultra Instinct off. Closing or re-executing releases the script's controls, animation listeners, ESP and UI callbacks.

Download `docs/SuperheroArena_Editor.html`, open it in a browser, and use Copy all code or edit/download the complete Lua. The controller files under `src/` are embedded directly in `main.lua`, so no external UI library or module download is required. The game icon and original user-provided logo assets are preserved.

## Verification

Set `LUAU_BIN` and `LUAU_COMPILE_BIN` to native Luau executables, then run `python tests/run_checks.py`. The current suite passes 411 simulated checks covering the auto-play core, role sources, confidence labels, ESP toggles, native dash availability and request timing, walking fallback during cooldown, bounded steering/release, no defensive position writes, fast travel, original-speed restoration, preservation of game speed changes, cancellation/death/unload cleanup, delayed native fallback, touch dispatch without mobile keyboard/mouse fallback, farther walking travel and separation, held keyboard/joystick assistance, immediate changed-input override, restoration of live manual input, movement locks, obstacles, ground/destination checks, report-derived cast cues and configured range, independent attack sources, short transitions, geometry destination planning and recorder-only operation, mobile layout, drag limits, startup failure, re-execution and cleanup. These checks do not establish live Roblox rendering, replicated attack cue availability, hit registration or server acceptance.
