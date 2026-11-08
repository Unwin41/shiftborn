# Shiftborn

A survivors-like where you **shift** between two forms mid-fight: a slow armored warrior who spins his axe around himself, and a fast mage who snipes the nearest enemy. Made with Godot 4.7 for [GitHub Game Off 2026](https://itch.io/jam/game-off-2026) (theme: **SHIFT**).

**[Play in your browser](https://unwin41.github.io/shiftborn/)** · **[Download for Windows, macOS and Linux](https://github.com/Unwin41/shiftborn/releases)** · itch.io page coming soon

> Work in progress. Art: [Ninja Adventure Asset Pack](https://pixel-boy.itch.io/ninja-adventure-asset-pack) by Pixel-boy and AAA (CC0).

## Download

Grab the zip for your system from [Releases](https://github.com/Unwin41/shiftborn/releases), unzip it and run the game. The builds are not code-signed, so your OS may warn you the first time:

- **Windows:** SmartScreen says "Windows protected your PC". Click **More info**, then **Run anyway**.
- **macOS:** open `Shiftborn.app`. If macOS blocks it, go to **System Settings > Privacy & Security** and click **Open Anyway**. Or run `xattr -dr com.apple.quarantine Shiftborn.app` in Terminal.
- **Linux:** run `./shiftborn.x86_64`. If it does not start, run `chmod +x shiftborn.x86_64` first.

Desktop builds run with extra effects: HDR glow and a light on every bolt. The browser version turns these off to stay smooth. To try the browser settings on desktop, start the game with `-- --low-quality`.

## Controls

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | WASD / arrow keys | Left stick / D-pad |
| Shift form | Space / Shift | A / RB |
| Restart | R / Enter | Start |
| Mute | M | |

Attacks are automatic. Mini-bosses arrive at 1:45 (a cyclops demon) and 3:15 (a giant spirit); at 4:30 the waves stop and **The Shifting Demon** appears. It swaps the form it resists every 8 seconds, dashes and fires bolt rings. Kill it to win.

Why shift:
- **Resistances.** Skulls shrug off magic and spirits shrug off the axe: the wrong form deals only 25% damage (grey numbers). The diamond above an enemy shows the color of the form that beats it.
- **Energy.** The active form tires and its damage drops to half; the resting form recovers twice as fast. The bars at the bottom show both.

## Horde Kit addon

The spawner and upgrade systems live in [`addons/horde_kit`](addons/horde_kit) and have no dependency on the game. They will be split into their own repository after the jam.

- **`HordeSpawner`**: a Node2D that spawns enemies on a ring around a target. You set up the waves as `SpawnWave` resources in the inspector, each with start/end time, interval, batch size and an alive cap.
- **`UpgradePool`**: weighted level-up offers with no duplicates. Handles max levels, prerequisites and tag filters, so each form only sees its own upgrades plus the shared ones.

```gdscript
var pool := UpgradePool.new(upgrades)
var choices := pool.offer(3, rng, ["knight"])  # knight + shared upgrades
pool.apply(choices[0].id)
```

## Development

Requires Godot 4.7.2.

```bash
godot --headless --import                                     # first run / CI
godot --headless -s res://tests/run_tests.gd                  # unit tests
godot --headless --fixed-fps 60 -s res://tests/smoke_test.gd  # gameplay smoke test
godot --path . -- --boss  # start a run with the boss already there
godot --headless -s res://tools/build_sprite_frames.gd        # rebuild SpriteFrames from assets/ninja
```

Every push to `main` runs the tests, exports Web/Linux/Windows builds and deploys the web build to GitHub Pages. Pushing a `v*` tag also uploads the builds to itch.io, once the `BUTLER_API_KEY` secret and the `ITCH_GAME` variable are set.

## License

Code: [MIT](LICENSE). Third-party assets are listed in [CREDITS.md](CREDITS.md).
