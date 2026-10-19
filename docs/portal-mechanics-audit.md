# Portal mechanics audit

This tracks normal Zero-K gameplay on composed maps with cubicle barriers. It is
an implementation/verification matrix, not a claim that every possible unit,
modoption and order sequence has been exhaustively playtested. The ordinary game
path remains enabled when portal mode is absent.

| Mechanic | Boundary enforcement | Verification |
| --- | --- | --- |
| Weapons, commander modules, superweapons, EMP/disarm/slow/capture/fire/impulse | Target acquisition, launch provenance and early damage/shield/explosion dispatch gates | All 793 loaded weapon definitions reject foreign damage before gadget callbacks; real combat/status controls, stockpiled nuke/anti-nuke and edge-crater fixtures |
| Persistent area damage and child explosions | Origin scopes survive owner travel/death and nested callbacks; attached statuses belong to the victim | Isolation fixture, local controls and error restoration |
| Homing, prediction, scripted move-controlled projectiles | Check launch region before retargeting, moving or forcing collision; quarantine before deferred deletion | A real tracked projectile is rejected when its target travels; ordinary weapon regressions |
| Shields and shared batteries | Same-region link discovery and point-of-transfer checks, including cached neighbors | Real local/foreign charge flow; default/share/penetrate modes and stale-link drain checks |
| Native LOS, air LOS, radar, sonar, seismic and jammers | Initialization-only engine sensor partitions | Native coverage, movement, removal, void and independent-client fixtures |
| Proximity detection/decloaking | Native nearest-enemy search filters candidates before choosing a target | Native isolated/whole-map proximity controls |
| Area cloak, transported cloakees and scan sweep | Filter recipients and scan effects by source region, including periodic/expiry decloak | Real area cloak through the commander-upgrade configuration hook; enlarged radius; real immediate/repeated/expiry scan calls with local controls |
| Pylon grids and overdrive | Filter intersection lists before reverse links/grid merges | Real same-team pylons connect locally and remain separate across the cubicle barrier; team resource pools remain shared |
| Factory plates and field factories | Region check before parent eligibility or blueprint copying | Real local/foreign plate activation; native build/creation gates |
| Build/assist/repair/capture/reclaim/resurrection | Native action callbacks gated before gadget resource/status side effects; creation footprint must fit builder's region | Positive/negative unit and wreck build-step controls, local/foreign/straddling creation; source order cleanup |
| Transports and amphibious pickup | Native transport/load/unload checks and recursive cargo membership on travel | Local/foreign callback controls and actual cargo portal travel |
| Carrier drones, including nanoframes | Carrier-owned roster travels together; construction stays attached; owner gadget resets private drone queues to guard carrier | Real carrier creates drones, travels and retains drone membership, positions and guard orders |
| Aircraft rearm/repair | Region-aware pad search, reservation cleanup on travel, live landing checks | Real bomber requests a local pad, travels, releases it and finds the destination pad |
| Retreat havens, area/circle guard and priority targets | Local-only candidate selection; reject stale targets and clear stored target state on arrival | Stored-target rejection and travel queue tests; reviewed haven/guard selection paths |
| Jumps, Lobster launches and Puppy flights | Reject foreign goals; travel waits for active scripted flight to finish | Real ordinary jump/Lobster launch, foreign jump rejection, escaped-aircraft fixture |
| Grey Goo and resurrection displacement | Region-filter resource sharing/wreck consumption and push recipients/destinations | Reviewed local spatial entry points; native reclaim/build and movement controls |
| Player/scripted terraform, smoothing and death terrain effects | Validate constructors, target footprint, ramp width and slope expansion; smoothing samples/moves structures only in impact region | Local/foreign area/wall/ramp tests and enlarged-radius smoothing with unchanged foreign terrain |
| Native craters and flattened buildings | Engine clips queued deformation and eligible building footprints to impact region | Edge nukes on all four adjacencies, two clients and native fresh-process persistence |
| Morph/upgrade replacements and deferred explosion spawns | Replacement membership comes from physical region, not team start; morph deletion does not count as commander death; deferred spawn uses validated impact position | Real command-driven mobile morph away from team home and commander upgrade; upgrade leaves portals closed, subsequent real commander death opens one. Damage/child provenance fixtures cover spawns. Extended sequences still need human playtesting |
| Portal queue cancellation and interruption | Removing the originating request cancels its internal approach; an inserted local command pauses travel until the original request reaches front again; active UI commands retain normal right-click controls | 136 ground/air order assertions, including removal just before activation, local/destination queue preservation and resumed travel. Three active-command cases in the in-engine UI fixture |
| Map materials, DNTS, lighting, sun, water presentation, minimap and overlays | Metadata-driven view/profile switching, local presentation bounds and region-aware event widgets | Four-map gameplay/UI/material captures and two independent local views |

Campaign, PlanetWars, chickens, zombie modes, cheats and arbitrary third-party
Lua scripts are not the normal duel ruleset. Their custom spawning/teleportation
needs separate scenario validation before advertising portal support there.
The example's 512-elmo cubicle barriers are tested; arbitrary narrower strips are
not a universal native physics partition. Gravity and simulation water height,
team resources, unit limits and pathfinding storage remain shared.

## Reproduce

From the separate map-tools checkout, supply the game checkout and prepared engine
install to `play_duels.py`:

```sh
python3 play_duels.py --game-dir /path/Zero-K --engine-dir /path/engine/install --test mechanics-full --offscreen-gpu --frames 1000 --speed 6
# Also run with --modoption shield_merge=share and shield_merge=penetrate.
```

`tests/portal_relations.lua` tests no-op ordinary-game behavior, invalid inputs,
physical creation fallback and membership changes without cached positions.
The opt-in mechanics fixture records a completion count and failures; startup or
an early clean exit alone is insufficient. The catalogue check tests dispatch
isolation, not the accuracy of every weapon's visuals or native trajectory.

Complete Zero-K save/load is covered by a fresh-process roundtrip, alongside an
ordinary Living Lands control with portal mode disabled. The engine needs the
separate empty-weak-table-key serialization fix: Lua can retain a collected
coroutine key in a nil-valued slot, which the old serializer dereferenced. That
maintenance fix is independent of the portal feature.

Run the portable tooling against this WIP game checkout (the fixtures are opt-in):

```sh
python3 verify_save_load.py --game-dir /path/Zero-K --engine-dir /path/engine/install --output runs/save-portals
python3 verify_save_load.py --game-dir /path/Zero-K --engine-dir /path/engine/install --output runs/save-normal --normal
```

The source fixture saves after portal travel with an active jump, scan and pending
portal approach. A new engine process reloads the native save. Checks cover the
portal graph, bomber/carrier/drone membership, shield/pylon/damage separation,
jump continuation and arrival, scan continuation/isolation/expiry, and the pending
traveler completing its order without a source-map order left in its queue.
The normal-map control continues ordinary Djinn and queued teleport orders.
The runner records separate source/load logs, actual commands, exit codes and
completion markers; producing a save file alone is not a pass.

`dbg_portal_save_test.lua` selects save mode with `zk_duels_save=1`; the fresh
loading process sets `PortalFixtureReloaded=1` in its config. Native sensor/crater
roundtrips remain separate coverage. These scripted scenarios do not establish
persistence for every AI implementation or all possible long-match states.
