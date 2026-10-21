# Rift Hub · Superhero Arena · v6.0

Full animated standalone UI for [Superhero Arena by The Duelists](https://www.roblox.com/games/78710221869926/Superhero-Arena). Place `78710221869926`, universe `10765491459`.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Superhero-Arena/main/main.lua"))()
```

## Combined feature update

Rift's interface now includes the linked script's requested features, implemented through the existing game-aware controls:

- **Auto Farm** retains normal movement, target selection and hero skill scheduling. Cash rewards remain controlled by the game; no direct cash-grant feature is claimed.
- **Fast Attack** requests nearby basic attacks through the detected mobile/HUD controls. It works independently, or adjusts the farm scheduler's fallback request interval. Known game attack intervals, busy/canAttack gates and server cooldowns still apply.
- **Low-health retreat** replaces the linked script's arbitrary 300-stud upward teleport with a checked short walking escape. Health threshold is adjustable; it yields to joystick input and pauses Auto Farm while retreating.
- **Movement → WalkSpeed** applies the requested value once, restores only its own write and preserves game overrides. Turn it off/on or change the slider to make a new request after a game override.

The UI adds a Movement page, animated tab marker, subtle surface gradient, animated switches and button hover/press effects. Reduce motion remains available. Existing role ESP and optional Ultra Instinct controls are retained. All new automation starts off.

`build.py` synchronizes embedded feature modules and the full editable HTML code field. The separate diagnostic snippet remains a small read-only helper.

## Combat

**Auto Farm** contains the existing auto-play behavior: opponent selection, native movement and dash requests, ability selection, timing, combos and camera aiming. It starts off; PLAY starts it and STOP releases its controls.

**Ultra Instinct** starts off. **Teleport dodge** is the selected mode by default, with a 24-stud nearby cue range and a 12-stud Escape distance cap (adjustable 4–12). When a nearby attack cue is accepted, it makes one immediate local root-position translation to a checked escape destination. Facing, velocity, WalkSpeed and user input are preserved; no native dash request or speed burst is required. Walking controls remain enabled. The interface hides walking-speed/native test controls until Teleport dodge is turned off.

Destination planning uses expanded client-visible attack-part bounds when a recognized volume overlaps the character; otherwise it estimates a diagonal retreat from the observed attacker, preferring the configured cap and trying shorter clear alternatives. Ground, solid path/destination clearance and other detected volumes are checked. An oversized attack with no clear exit inside the cap is not escaped across the map. Client effects do not establish server damage geometry; the live reports exposed no recognized hitboxes.

**No universal dodge guarantee:** unreplicated/late attacks, unknown damage radii, fast follow-ups, already-applied damage and server corrections can defeat the teleport. The controller coalesces related cues and rate-limits local requests; it cannot promise a move for every server hit. Displacement and a possible return toward the starting position are reported. A snap-back does not trigger a continuous position-forcing loop.

Teleport requests do not wait for the walking `canRun`, `LOCKED_INPUTS` or ability/cutscene attributes to clear, and never rewrite those fields. This only permits a local relocation request; it does not defeat the game's actual locks or guarantee persistence. A missing/dead character, anchored root, unavailable hero/out-of-arena state or paused input/camera context still blocks requests. Native-dash-only tests retain the normal game movement gates. The game may reject or correct the teleport, especially while it owns movement.

**Use:** re-execute v6.0, enable Ultra Instinct under Combat, and leave Teleport dodge on. **Test teleport** previews the capped local move independently of automatic detection. **Record nearby attacks** observes a short encounter; recording alone does not enable automatic teleporting. **Copy dodge report** distinguishes teleport requests, automatic/manual tests, native/walking requests, movement gates and local displacement/correction observations. It does not prove server acceptance.

**Optional walking mode:** turning Teleport dodge off exposes Fast sidestep, Burst speed and Test game dash. Existing native dash timing and game gates remain enforced. A local burst defaults to speed 64, lasts at most 0.25 seconds, and restores only its owned speed changes. Game speed overrides are preserved and suspend further bursts on that character/controller session; bounded walking can continue at game-controlled speed. Manual movement-vector changes return control immediately. Death, focus/typing/dragging, game locks, disabling and unloading release owned walking/speed input.

**Controls and detection:** mobile game controls use touch dispatch rather than virtual keyboard events; no keyboard/mouse fallback follows a rejected touch. Estimated attack cues include cast locks, skill states, Action animations with cast/combat locks, independent swing/cast fields and short attribute transitions. New Auto Farm attacks yield to a fresh defensive threat. None of those cues establishes an unseen attack's exact damage volume or guarantees early warning.

The encounter trace retains 100 relevant events and roughly 10 seconds of processed client time. Reports stay in the client/clipboard. Interface and collision/geometry behavior still need live Roblox validation; simulated checks do not establish reliable server-accepted avoidance.

## Visuals

ESP shows only hero-colored chams, a hero role above the exact @username, and their toggles. There are no distance labels, boxes, tracers or health bars. Cham opacity is adjustable; Galactic Thanos uses a slow rainbow color.

Confirmed aliases: Water → Aquaman, Earth → Hulk, Knight → Thor, Samurai → Deadpool, Nature → Groot. Current `MorphCurrent` and `power` fields take priority. Direct roster names match automatically; explicit unambiguous menu ID/name pairs can supply additional mappings. Optional estimates are labelled **estimate**. Other IDs remain visible as **unmapped**; Angel is not assigned a fictional confirmed mapping. Settings → Copy diagnostics includes per-player role sources and defense state.

## Interface and full code

Combat, Visuals and Settings use graphite surfaces, violet accents, opening/tab fades, animated switches, sliders, and hover/press effects. The original Rift R emblem remains centered in the header and minimized button. Drag the header, minimize to the draggable emblem, or press RightShift. Phone portrait and landscape layouts adapt without shrinking normal-sized text. Settings include Reduce motion, Copy diagnostics, Rejoin and Unload. Credits identify N0VA_0100.

The universal [Rift Hub](https://github.com/copperpoppercms-sys/Rift-Hub) still launches this standalone script from Hub → Superhero Arena → Execute. It closes the universal hub and opens the new interface with Auto Farm and Ultra Instinct off. Closing or re-executing releases the script's controls, animation listeners, ESP and UI callbacks.

Download `docs/SuperheroArena_Editor.html`, open it in a browser, and use Copy all code or edit/download the complete Lua. The controller files under `src/` are embedded directly in `main.lua`, so no external UI library or module download is required. The game icon and original user-provided logo assets are preserved.

## Verification

Set `LUAU_BIN` and `LUAU_COMPILE_BIN` to native Luau executables, then run `python tests/run_checks.py`. The current suite passes 459 simulated checks covering the auto-play core, role sources, confidence labels, ESP toggles, native dash availability and request timing, walking fallback during cooldown, bounded steering/release, no defensive position writes, default teleport mode, instant capped travel, preservation of facing/input/speed/velocity, correction reporting without repeated forcing, checked destinations, walking-lock requests without attribute rewrites, anchored/oversized rejection, observational recording, continuation after game speed replacement, suppression of repeated rejected bursts, explicit local locks, observation while locked, native-only input test, defense priority and separate auto/test diagnostics, fast travel, original-speed restoration, preservation of game speed changes, cancellation/death/unload cleanup, delayed native fallback, touch dispatch without mobile keyboard/mouse fallback, farther walking travel and separation, held keyboard/joystick assistance, immediate changed-input override, restoration of live manual input, movement locks, obstacles, ground/destination checks, report-derived cast cues and configured range, independent attack sources, short transitions, geometry destination planning and recorder-only operation, mobile layout, drag limits, startup failure, re-execution and cleanup. These checks do not establish live Roblox rendering, replicated attack cue availability, hit registration or server acceptance.
