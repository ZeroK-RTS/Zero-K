# Experimental portal worlds (WIP)

This mode runs independent duels on regions of one composed map. A commander loss
opens a connection: the defeated-side mouth uses the death position and its partner
uses a free site near the next map's centre. The graph, starts, region rectangles,
resources and visual profiles come from `mapconfig/portal_worlds.lua` in the map.
There are no map coordinates in the game rules/UI. The example composition is four
native 8×8 maps with a 512-elmo gap, arranged in a 2×2 grid and connected in a ring.
The resulting physical map is 18×18. The same code has also run a reordered
three-map, one-column composition.

## Requirements and setup

Use a Recoil build with `Engine.FeatureSupport.mapRegionViews`: `Spring.SetWorldDrawBounds`,
`Spring.SetCameraBounds` and `Spring.SetMiniMapView` are the engine-side presentation support.
`Engine.FeatureSupport.sensorRegions` and synced `Spring.SetSensorRegions` are
also required. `Engine.FeatureSupport.mapDamageRegions` and synced
`Spring.SetMapDamageRegions` provide native crater boundaries. Initialization supplies the map's region rectangles before native
sensor updates; the rectangles must align to the engine's coarsest sensor cell.
A portal match ends immediately with a diagnostic on an unsupported engine.
Normal ZK is unaffected with the `zk_duels=baseline` default. Enable
`zk_duels=duels` only on a composed map. The map fetcher, packer, manifest, map
helper templates and launch/verification scripts are included in
[tools/portal_worlds](../tools/portal_worlds/README.md). They fetch/check the original
maps and generate the composed archive; map media and engine binaries are not
committed.

From the game checkout on Linux (Python 3.9+, `lua5.1`, `7z`; `cc` for offscreen
rendering):

```sh
cd tools/portal_worlds
portal_venv="${XDG_CACHE_HOME:-$HOME/.cache}/zero-k/portal-tools-venv"
python3 -m venv "$portal_venv"
. "$portal_venv/bin/activate"
python3 -m pip install -r requirements.txt
python3 fetch_portal_maps.py
python3 build_portal_worlds.py --engine-dir /path/engine
python3 verify_four_worlds.py
python3 play_duels.py --engine-dir /path/RecoilEngine/build-amd64-linux/install --play
```

`--game-dir` defaults to this checkout. Generated maps, downloads and diagnostic
runs stay outside the game in `$XDG_CACHE_HOME/zero-k/portal-worlds` (normally
`~/.cache/zero-k/portal-worlds`). Set `ZK_PORTAL_WORKSPACE=/absolute/path` to use
another location. All scripts share that workspace; original map credits are
retained in the generated `ATTRIBUTION.txt`. The supplied manifest describes four
8×8 maps and 512-elmo cubicle barriers; edit it or pass `--manifest` and `--target`
to pack a different composition.

The launcher prints fresh log/recording/screenshot paths. With `--record --headless` or `--record --watch`, the launcher also records all-team
[dots playback](../tools/portal_worlds/dots/README.md). It can be shared as one offline
HTML file, showing all worlds together with seeking, orders and unit inspection.
`--duel-income-multiplier` gives one AI per map an explicit setup advantage; it is
1 by default. `--ai-dir` selects a separately built native AI without altering the
engine installation. The companion `build_circuit.py` builds Circuit’s optional
portal missions in an isolated cache. Ordinary Circuit remains usable, but does
not deliberately plan ground invasions after a local win.

F12 also records camera,
viewport, GL state and visible projectile diagnostics. It does not suppress logs.

## Orders and viewing

The selector and N switching remain absent/unavailable before a connection opens,
then show only regions reachable from the player's home. Camera state is remembered
per region. Minimap events, native icons and game overlays follow the viewed region;
material/DNTS bindings, sun, lighting, atmosphere and water visuals switch with it.
`WG.PortalWorldView` exposes the active rectangle for custom widgets.

A unit travels only for an explicit move/fight/attack destination in a reachable
other region, or an explicit portal interaction. Proximity alone never activates
it. Portal attack/guard/repair/reclaim/capture/load orders become the registered
`PORTAL_TRAVEL` command; beacons cannot be weapon targets or receive damage/status
effects. Portal travel respects command queues and the queue key, including the inverted
queue-key setting. Portal right-click defers to the normal controls while a command
is selected. Removing the original travel/move/fight/attack order also removes its
internal portal approach; remaining local waypoints continue without teleporting.
Inserting a command ahead of travel pauses it and removes the old approach;
travel resumes when the original request reaches the front again.
On arrival, approach and source-region waypoints, wreck reclaim/resurrect orders
and cargo orders are removed and destination orders continue. A replaced approach
cancels travel. Transports carry their cargo and carriers bring their drone roster, including nanoframes. Aircraft release old pad reservations. Velocity/weapon targets are
cleared, and multi-hop routes use the open graph. Building in another region still
requires moving the builder there first. Djinn beacon placement and wait orders
stay in their current region. A Djinn that travels retains its old beacon but
cannot deploy that link across regions; stale wait queues are removed. Ordinary
local Djinn teleportation, including inserted and shifted orders, remains usable.

## Weapon boundaries

Isolation is enforced in synced rules; render clipping is not used as a damage
boundary. Same-region target acquisition is checked before firing. Projectiles
retain launch provenance after owner death/travel. Root scripted projectiles must
spawn in their owner's region; child effects inherit their parent's region during
explosion/destruction dispatch. Foreign targets, boundary crossings and foreign
interception are rejected. Unknown/unowned environmental effects are handled by
their physical position; future scripted weapons still need audit.

Native ground/air LOS, radar, sonar, seismic and both jammer types are restricted
to the emitter's region. Coverage follows units after travel through ordinary
native sensor updates. View switching does not grant sensor coverage. Global LOS,
spectator privileges and explicitly always-visible units retain their native
overrides; view cropping is not a client security boundary.

The gadget dispatcher rejects foreign damage *before* capture, impulse, fire,
slow/disarm and other side-effect gadgets receive it. Setting final health damage
to zero alone is insufficient. Explosion and shield callbacks are gated too.
Persistent area effects use their origin, while attached burning follows its
victim. Scoped provenance survives nested callbacks and restores on errors.
Wreck damage is filtered as well.

Native crater deformation is clipped by the engine to the impact region,
including delayed height changes. Impacts in the strip cannot crater either map.
Foreign buildings and footprints straddling the boundary do not move with a
neighboring explosion. These cubicle barriers use 512-elmo strips; strip width no longer
needs to exceed the largest crater radius. Terrain/build masks reject ground
pathfinding and construction through the strip; the existing synced rules handle
projectile provenance, interception, damage, explicit travel and escaped units.
Player and scripted terraform area/wall/ramp entry points reject foreign regions
and mixed-region constructors. Ramp width must fit the region; terraform slopes
cannot spread into the separating strip. Local terraform remains available. Lua terrain explosions and smoothing also restrict their samples, structure movement and detachment effects to the impact region. See [the mechanics audit](portal-mechanics-audit.md) for the normal-game coverage and remaining scenario limits. The regions still share engine
gravity/water height, pathfinding storage,
team/unit limits, economy and a single simulation. This is not independent-map
loading or a client information-security boundary.

## Tests and review limits

`--test factories` queues real native ground/air production on each world and
checks finished children and inherited membership. The normal-map control uses
`--normal --test factories`. Native factory validation has no build position;
the portal check validates the producer rather than rejecting that queue.


Opt-in `zk_duels_test` modes are used only by the opt-in launcher:

- `four`: opening/view locks, native resources, direct and queued routes, no
  proximity travel, both directions on every edge for ground/air units, mixed
  selections, multi-hop orders, map materials, minimap events and selection views.
- `weapons`: actual stockpiled nuke launches and anti-nuke interception, forced
  foreign targeting, owner transit during flight, and native wreck damage.
- `isolation`: foreign capture/impulse/EMP/slow/flame/ordinary damage on every map
  is stopped before any side-effect callback; local callbacks remain active.
  Includes scripted projectile provenance, damage-scope reset after errors, beacon
  interactions, shift queuing and source-waypoint cleanup.
- `combat`: actual Scorcher/Dante/Lotus/Harpy hits on all maps, with paused
  overview/oblique/top captures. Flattened firing lanes exist only in this fixture.
- `layout`: the alternate map count/order/grid configuration.
- `mechanics-full`: shield links/batteries, pylon grids, cloak/scans, native build/reclaim/transport callbacks, factory plates, bomber pads, carrier drones, jump/throw/retargeting, smoothing and the weapon-definition damage catalogue. Also run with `shield_merge=share` and `shield_merge=penetrate`.
- `mechanics`: Djinn local/remote links, inserted/shifted/stale wait queues and
  portal transit; real local terraform and rejection of foreign commands/scripted
  area/wall/ramp operations; shield callback isolation for foreign beams and
  projectiles, plus actual local beam interception and shield-charge loss.
- `replacements`: real mobile morph and commander upgrade commands, physical
  membership away from the team start, upgrade suppression of portal opening,
  and a later real upgraded-commander death opening its connection. Morph
  progress is accelerated only in this opt-in fixture.
- `orders`: ground/air order cancellation, replacement and queue-tag removal,
  including cancellation immediately before portal activation. Surviving local
  and destination waypoints are retained; removing only the internal approach
  retries a still-queued travel request. Inserted waypoints pause travel, and
  retained requests resume afterward. Terrain and activation-range positioning
  are controlled only in this opt-in fixture.
- `mechanics-baseline`: ordinary Djinn/queued teleport and terraform on an
  original map with both portal rule tables absent. Run with `--normal` and an
  explicit `--game-dir` pointing to this checkout, since a clean ZK checkout does
  not contain the diagnostic gadget.
- `barriers`: cubicle barriers between metadata-derived horizontal/vertical neighbors on compact strips,
  five ground movement classes and building masks, actual local/foreign paths,
  escaped aircraft, and real nuke impacts near each edge. Checks local craters
  still work while foreign terrain, barrier samples and building health/height
  remain unchanged. Flattened lanes exist only in this opt-in fixture.
- `network`: two separate human-player clients send real networked portal
  orders from different regions. Checks sender ownership, closed/open view locks,
  queued travel and source-waypoint cleanup, sensor isolation and visibility after
  arrival. The clients use different local views and compare synced witnesses.

From `tools/portal_worlds`, run the two-client fixture with:

```sh
python3 network_playtest.py portal-network --game-dir /path/Zero-K --engine-dir /path/RecoilEngine/build-amd64-linux/install
# Repeat real group orders in both directions with independent local views:
python3 network_playtest.py portal-network-groups --game-dir /path/Zero-K --engine-dir /path/RecoilEngine/build-amd64-linux/install --rounds 8 --units 32 --seconds 240
```

`lua5.1 tests/portal_worlds.lua` checks metadata geometry, graph routing and the
physical separation independently of a running engine. The engine's own native
sensor fixtures cover all seven sensor types, two clients and a fresh-process
save/load of the sensor configuration.

These automated checks and single-process Circuit matches are not a substitute for
human playtesting. A representative two-client match passes with matching synced
witnesses and different local views. Before merge: broaden network coverage to
longer/larger matches and mixed platforms, extend the normal-game
mechanics coverage in portal-mechanics-audit.md, review performance
under large projectile counts and UI/camera/minimap rotation with custom widgets,
and broaden save/reload coverage across AI implementations and long-match states.
Full-game fresh-process save/reload passes in the portal fixture and ordinary
single-map control with the separate engine weak-key serialization fix applied.
The modoption remains WIP and disabled by default.

AI assistance: OpenAI Codex implemented the prototype and automated fixtures.
The contributor must review/edit the PR description and verify the code in human
use before submission, as required by `ai_policy.md`.

The broader mechanics audit and test coverage are in [portal-mechanics-audit.md](portal-mechanics-audit.md). It includes fresh-process full-game save/load and its scenario limits.


The opt-in `aircraft`, `aircraft-diagonal` and `aircraft-multihop` fixtures
exercise real flight orders through one and several connections. They caught
an immediately completed approach being confused with the original travel
request. The router now tracks those tags separately and uses a stopping radius
inside the activation radius, preserving the remaining multi-hop order. These
fixtures open connections by scripted commander destruction and are labelled
fixtures, separate from the autonomous AI recordings.
