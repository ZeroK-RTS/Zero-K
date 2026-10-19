# Portal map tools (WIP)

Compose existing Spring/Recoil SMF maps into independent gameplay regions without
resizing their terrain or diffuse tiles. These tools are included with the
experimental Zero-K portal mode. The engine
region APIs must be built separately; see [the game setup](../../docs/portal-worlds.md).

Requirements: Python 3.9+, Pillow 11.2.1+ (`python3 -m pip install -r requirements.txt`),
Lua 5.1 (`lua5.1` executable), `7z`, and a Recoil source checkout. The launch and
network/save diagnostic scripts currently target Linux. Offscreen GPU tests also
need a C compiler (`cc`); the software-rendering fallback needs Xvfb. Building uses
the engine source's bundled classic detail texture when a source map has no DNTS.
Original map downloads and all generated content remain outside version control.

Run from this directory (`tools/portal_worlds` in the game checkout):

```sh
portal_venv="${XDG_CACHE_HOME:-$HOME/.cache}/zero-k/portal-tools-venv"
python3 -m venv "$portal_venv"
. "$portal_venv/bin/activate"
python3 -m pip install -r requirements.txt
python3 fetch_portal_maps.py
python3 build_portal_worlds.py --engine-source /path/RecoilEngine
python3 verify_four_worlds.py
python3 play_duels.py --engine-dir /path/RecoilEngine/build-amd64-linux/install --play
```

`--game-dir` defaults to the checkout containing these scripts. To use another
checkout, pass it explicitly. Downloads, extracted sources, generated maps,
compiled diagnostic helpers and run output go to
`$XDG_CACHE_HOME/zero-k/portal-worlds` (normally
`~/.cache/zero-k/portal-worlds`). Set `ZK_PORTAL_WORKSPACE=/absolute/path` before
running the commands to choose another location. This keeps generated map media
outside the game archive. Every script uses the same workspace.

`portal_maps.json` is the composition manifest: map archive names, source folders,
grid columns, physical gap, style labels, authored starts, surface hazards and the
connection graph. Its 512-elmo cubicle barriers create an 18×18 physical map.
The included example uses four native 8×8 maps: Living Lands
4.1, Barren 2, FrozenPlanetV3 and Calayo2. The manifest pins each example archive filename, SpringFiles mirror and MD5.
Downloads are checked against that checksum. Entries without an `archive` object
query SpringFiles by their exact map name; pin the resulting provenance when
adding a reproducible composition. Source Lua metadata is
executed with Lua 5.1; use trusted map archives. Generated output retains author
credits in `ATTRIBUTION.txt`. No original map media is committed here.

Default output is `content/maps/portal_worlds_v3.sdd` inside the
workspace. The generated map includes
`mapconfig/portal_worlds.lua` (the game-facing geometry/graph/material contract)
and `composition.json` (starts and provenance for the launcher and verification).
No game-specific coordinates belong in the engine.

Offscreen GPU checks are selected with `--offscreen-gpu`; `--headless` exercises
simulation. Scripted fixtures default to passive NullAI; ordinary matches default
to Circuit. Portal graphical fixtures use a human-controlled team so actual UI orders
can be tested without spectator privileges. `--watch` explicitly opens an eight-AI match. All other launches stay
offscreen. Logs, recordings, captures and exit status remain in a fresh workspace `runs/`
folder, whose paths are printed. GPU rendering defaults to a 30fps cap and two
engine workers to avoid monopolising a desktop. `--nano geometry` or
`--nano instanced` exercises Recoil's native nano renderer. For normal single-map
ZK, use `--normal --play --game-dir /path/to/clean/Zero-K` with the same engine.
The WIP game's `--test mechanics` covers Djinn, terraform and shields. To verify
its disabled-mode behavior on an original map, use `--normal --test
mechanics-baseline --game-dir /path/to/WIP/Zero-K --offscreen-gpu`; normal diagnostic
runs use AI teams so they can start without a human ready click.

`--prepare-only` creates the isolated content, configuration and start script
without launching an engine or display. The two-client regression uses this to
launch two independent processes, each limited to one worker and 15 FPS:

```sh
python3 network_playtest.py portal-network --game-dir /path/to/WIP/Zero-K --engine-dir /path/RecoilEngine/build-amd64-linux/install
```

Both clients issue real player orders, use different local views and verify
synced witnesses, portal queues and sensor isolation. `--rounds` repeats group
travel in alternating directions; `--units` chooses the number controlled by each
client. The runner checks every command sender, every arrival and cleaned queue,
exact transit/assertion counts, all local view changes and identical synced
witnesses. For example:

```sh
python3 network_playtest.py portal-network-groups --game-dir /path/to/WIP/Zero-K --engine-dir /path/RecoilEngine/build-amd64-linux/install --rounds 8 --units 32 --seconds 240
```

The fixture checks queued orders, stops the arriving groups and places nearby
non-firing enemy targets for the visibility checks. It does not assume that an
early-arriving group still covers the portal while the other group catches up. `network-result.json`
records both exit codes, assertions, commands and witness comparison; each process
has its own console log and writable data directory. This opt-in fixture uses the
example composition's first two connected regions.

The game PR is experimental: weapon isolation and simulation interactions still
need human review. Compact strips require the engine's synced sensor and native
crater-region APIs as well as the game's movement/projectile/damage rules.
Native craters cannot deform the strip or another region. `--test barriers`
checks path/build masks, local/foreign paths, escaped aircraft and real edge nukes
on horizontal and vertical neighbors.
Map-specific lava and visual
profiles are metadata; shared engine gravity/water height are not independent
per-region physics.

Full-game persistence has its own fresh-process runner:

```sh
python3 verify_save_load.py --game-dir /path/to/WIP/Zero-K --engine-dir /path/RecoilEngine/build-amd64-linux/install
python3 verify_save_load.py --game-dir /path/to/WIP/Zero-K --engine-dir /path/RecoilEngine/build-amd64-linux/install --normal
```

Both use the selected WIP checkout's opt-in fixtures; `--normal` disables portal
mode and uses the original Living Lands map. The engine also needs the separate
empty-weak-table-key save fix. The source saves while gameplay is active, exits,
and a fresh process loads the file with its own writable directory. The portal
case checks continuing jump/scan/travel state and region separation after load.
Each run keeps commands, logs, the native save and a machine-readable result.
Timeout cleanup targets only the runner's own process group. Rendering is
windowless GPU with a 30 FPS cap; `--only-local` avoids binding a game-server port.

The scripts and composition were developed with OpenAI Codex assistance. Original
map media remains under its authors' terms; consult the generated attribution.

The small `diagnostic-tools/` SDL helpers are compiled automatically into the
workspace when needed. `--play` never injects them or starts a private display.
Use an engine containing the offscreen cursor fallback for GPU offscreen tests.
The example map verifier checks unchanged terrain heights, diffuse tiles and
mipmaps, authored start positions and optional engine assertion logs. A successful
startup alone is not treated as a passing gameplay test.

Pillow 11.2.1 introduced the [DXT1 encoder](https://pillow.readthedocs.io/en/stable/releasenotes/11.2.1.html#saving-compressed-dds-images) used by the native minimap writer.
