# Rift Hub · Superhero Arena · v5.3

Full animated standalone UI for [Superhero Arena by The Duelists](https://www.roblox.com/games/78710221869926/Superhero-Arena). Place `78710221869926`, universe `10765491459`.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Superhero-Arena/main/main.lua"))()
```

## Combat

**Auto Farm** contains the existing auto-play behavior: opponent selection, native movement and dash requests, ability selection, timing, combos and camera aiming. It starts off; PLAY starts it and STOP releases its controls.

**Ultra Instinct** is independent of Auto Farm and starts off. It requests one bounded local escape from detected client-visible attack volumes, or a short estimated sidestep when only an attack cue is available. Maximum displacement is adjustable from 4–12 studs (10 by default), and nearby cue range from 6–24 studs. It checks ground, path and destination clearance. It stays in place if no clear local exit fits the cap. Visible effects are not necessarily the game's damage hitboxes, and a property write does not prove the server accepted a dodge.

v5.3 responds to the live report's missing signals: a rising `castLocked` flag is an estimated ability cue, `state=skill` counts as ability use, and an unknown high-priority Action animation can combine with `castLocked` even when `busy=false` and `canAttack=true`. Attribute listeners observe cast-lock transitions. Sustained flags alone do not request repeated moves. Nearby range now applies consistently to both melee and ability cues; the hidden fixed 10-stud melee cutoff is removed. Related source changes are coalesced briefly to avoid multiple reactions to one attack.

The report exposed **no recognized attack hitboxes**. `Workspace.ClientFX` entries such as tiny slam-radius parts, rock trails, footsteps and shield echoes remain visual observations; their names and bounds do not establish real damage geometry. The new cast cues provide an estimated dodge, not a proven exit from a server hitbox. Animation IDs are not assigned fictional move names.

Automatic moves and manual tests now have separate counters in Combat and diagnostics. Encounter reports also show changes in those counters since recording started. Rejected automatic cues report range, elevation, obstruction, expiry or the short movement cooldown, instead of disappearing silently. Attack fields retain independent baselines, and listeners preserve short transitions between heartbeat samples. Failed clearance does not immediately consume a cue.

**Diagnosing a missed dodge:**

1. Re-execute v5.3, open Combat, and enable Ultra Instinct.
2. Tap **Test dodge · 4 studs** once on open ground. This explicitly requests a short move through the same clearance and displacement checks; it does not test automatic attack recognition.
3. Tap **Record nearby attacks · 10 sec** and encounter a nearby attack. The recorder itself only observes; it can also run with Ultra Instinct off without making automatic moves.
4. Tap **Copy dodge report** and paste the result. It includes raw nearby character attributes, animation names/IDs/priorities, nearby new-part names/attributes, attack cue sources, automatic/manual counts, cue filter decisions, clearance rejection reasons and a brief observation of the resulting movement. Reports stay in the client/clipboard; there is no upload.

The trace keeps at most 100 recent events. Recording stops after roughly 10 seconds of processed client time. Reports label returned movement as a possible correction or later movement; they cannot identify anti-cheat from a position change alone. General Settings → Copy diagnostics includes the same defense report.

Active-volume classification still uses explicit attack/hitbox metadata, ownership when exposed, and named attack volumes in runtime effects/ability folders. It ignores known own/team attacks, inactive volumes and ordinary character parts. With no exposed volume, nearby attack states, independent swing/cast counters, combo advances and recognizable attack animations can request the estimated fallback. A generic high-priority animation also needs combat-lock evidence; busy alone is insufficient. Unfamiliar animation IDs and parts are recorded without being automatically treated as attacks.

**Normal controls stay enabled.** Ultra Instinct never disables ControlModule, calls Humanoid:Move, anchors the root, changes WalkSpeed, forces humanoid state or holds a dash key. Auto Farm yields to real keyboard/joystick movement. Automatic dodging remains unverified in the live game after the reported failures; the new diagnostics distinguish absent evidence, clearance rejection and movement that was not retained.

## Visuals

ESP shows only hero-colored chams, a hero role above the exact @username, and their toggles. There are no distance labels, boxes, tracers or health bars. Cham opacity is adjustable; Galactic Thanos uses a slow rainbow color.

Confirmed aliases: Water → Aquaman, Earth → Hulk, Knight → Thor, Samurai → Deadpool, Nature → Groot. Current `MorphCurrent` and `power` fields take priority. Direct roster names match automatically; explicit unambiguous menu ID/name pairs can supply additional mappings. Optional estimates are labelled **estimate**. Other IDs remain visible as **unmapped**; Angel is not assigned a fictional confirmed mapping. Settings → Copy diagnostics includes per-player role sources and defense state.

## Interface and full code

Combat, Visuals and Settings use graphite surfaces, violet accents, opening/tab fades, animated switches, sliders, and hover/press effects. The original Rift R emblem remains centered in the header and minimized button. Drag the header, minimize to the draggable emblem, or press RightShift. Phone portrait and landscape layouts adapt without shrinking normal-sized text. Settings include Reduce motion, Copy diagnostics, Rejoin and Unload. Credits identify N0VA_0100.

The universal [Rift Hub](https://github.com/copperpoppercms-sys/Rift-Hub) still launches this standalone script from Hub → Superhero Arena → Execute. It closes the universal hub and opens the new interface with Auto Farm and Ultra Instinct off. Closing or re-executing releases the script's controls, animation listeners, ESP and UI callbacks.

Download `docs/SuperheroArena_Editor.html`, open it in a browser, and use Copy all code or edit/download the complete Lua. The controller files under `src/` are embedded directly in `main.lua`, so no external UI library or module download is required. The game icon and original user-provided logo assets are preserved.

## Verification

Set `LUAU_BIN` and `LUAU_COMPILE_BIN` to native Luau executables, then run `python tests/run_checks.py`. The current suite passes 317 simulated checks covering the auto-play core, role sources, confidence labels, ESP toggles, report-derived cast-lock and skill states, melee range beyond 10 studs, automatic/manual counts, cue filter reasons, independent attack sources, short attribute transitions, retry after blocked clearance, recorder-only operation, unknown animation/effect capture, movement observation, bounded geometry escapes, rotated hitboxes, own/inactive/oversized attacks, non-queryable effects, late metadata, manual input, obstructions, ground checks, mobile layout, drag limits, startup failure, re-execution and cleanup. These checks do not establish live Roblox rendering, replicated attack cue availability, hit registration or server acceptance.
