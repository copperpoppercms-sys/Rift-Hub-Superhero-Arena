# Rift Hub · Superhero Arena

Standalone v4.6 for **Superhero Arena by The Duelists**. The current interface is the compact PLAY/STOP panel; a full game UI can be added later.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Superhero-Arena/main/main.lua"))()
```

Join [Superhero Arena](https://www.roblox.com/games/78710221869926/Superhero-Arena), execute the script, then tap **PLAY**. STOP releases the script's inputs; × unloads it. Re-executing replaces the previous copy.

The universal [Rift Hub](https://github.com/copperpoppercms-sys/Rift-Hub) includes a matching game card beside MM2. Its Execute button fetches `main.lua` from this repository, closes the universal hub and opens this panel. It does not start PLAY automatically.

This version includes the working mobile HUD mappings, varied ability distances, defensive dash requests, sidesteps, side runs, flanking, group target selection and pursuit/backpedal movement. Game cooldowns and server decisions still apply; simulated checks do not establish live gameplay quality.

Download `docs/SuperheroArena_Editor.html` and open it in a browser to edit or copy the complete code. The game icon is Roblox's published icon for this experience; `assets/icon_source.json` records its source.

## Validation

Set `LUAU_BIN` and `LUAU_COMPILE_BIN` to native Luau executables and run `python tests/run_checks.py`. Tests simulate Roblox; live controls, hit registration and movement need in-game checking.

## Rift branding

The header uses the user-supplied Rift Hub R emblem from `assets/rift_logo.jpg`. Existing minimized controls use the same emblem. The original JPEG is preserved unchanged; logo cache names include its content hash. If custom images are unavailable, text branding remains usable.
