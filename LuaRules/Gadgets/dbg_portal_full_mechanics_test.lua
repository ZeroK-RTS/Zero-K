-- This file is part of Zero-K (GPL v2 or later), see LICENSE.
function gadget:GetInfo()
	return { name = "Portal extended mechanics regression", layer = -100, enabled = true }
end
if not gadgetHandler:IsSyncedCode() or Spring.GetModOptions().zk_duels_test ~= "mechanics-full" then
	return false
end
local units, pokes = {}, {}
local damageCallbacks = 0
local sawJump, sawThrow = false, false
local savedScanPokes, expiredScanPokes
local saveJumpPosition
local retargetProjectile
function gadget:UnitPreDamaged(id, def, team, damage)
	damageCallbacks = damageCallbacks + 1
	return damage
end
local world = VFS.Include("LuaRules/Utilities/portal_worlds.lua")
local a, b = world.regions[1], world.regions[2]
local ax, bx = a.x1 - 64, b.x0 + 64
local checks, failures = 0, 0
local function Check(name, pass, detail)
	checks = checks + 1
	if not pass then
		failures = failures + 1
	end
	Spring.Echo(
		"[FULL_MECHANICS] ASSERT "
			.. name
			.. " pass="
			.. tostring(not not pass)
			.. " "
			.. tostring(detail or "")
	)
end
local function Spawn(key, name, x, z, team)
	local id = Spring.CreateUnit(name, x, Spring.GetGroundHeight(x, z), z, 0, team or 0)
	assert(id, "Failed to create " .. name)
	units[key] = id
	Spring.GiveOrderToUnit(id, CMD.FIRE_STATE, { 0 }, 0)
	Spring.GiveOrderToUnit(id, CMD.MOVE_STATE, { 0 }, 0)
	return id
end
local function Charge(key)
	return select(2, Spring.GetUnitShieldState(units[key]))
end
local function SetCharge(key, amount)
	Spring.SetUnitShieldState(units[key], -1, true, amount)
end
local function DispatchChecks()
	local handler = gadgetHandler.gadgetHandler
	local builder, localUnit, foreign = units.builder, units.localUnit, units.foreign
	for _, part in ipairs({ 0.2, -0.2 }) do
		Check(
			"local_build_reclaim_" .. part,
			handler:AllowUnitBuildStep(builder, 0, localUnit, UnitDefNames.cloakraid.id, part)
		)
		Check(
			"foreign_build_reclaim_" .. part,
			not handler:AllowUnitBuildStep(builder, 0, foreign, UnitDefNames.cloakraid.id, part)
		)
	end
	for _, part in ipairs({ 0.2, -0.2 }) do
		Check(
			"local_feature_step_" .. part,
			handler:AllowFeatureBuildStep(builder, 0, units.localWreck, units.wreckDef, part)
		)
		Check(
			"foreign_feature_step_" .. part,
			not handler:AllowFeatureBuildStep(builder, 0, units.foreignWreck, units.wreckDef, part)
		)
	end
	Check(
		"foreign_build_creation",
		not handler:AllowUnitCreation(UnitDefNames.energysolar.id, builder, 0, bx, 200, 2000, 0)
	)
	Check(
		"local_build_creation",
		handler:AllowUnitCreation(UnitDefNames.energysolar.id, builder, 0, ax - 200, 200, 2000, 0)
	)
	Check(
		"straddling_build_creation",
		not handler:AllowUnitCreation(UnitDefNames.energysolar.id, builder, 0, a.x1 - 8, 200, 2000, 1)
	)
	local trans, td = units.transport, UnitDefNames.gunshiptrans.id
	Check(
		"local_transport",
		handler:AllowUnitTransport(trans, td, 0, localUnit, UnitDefNames.cloakraid.id, 0)
	)
	Check(
		"foreign_transport",
		not handler:AllowUnitTransport(trans, td, 0, foreign, UnitDefNames.cloakraid.id, 0)
	)
	Check(
		"foreign_transport_load",
		not handler:AllowUnitTransportLoad(trans, td, 0, foreign, UnitDefNames.cloakraid.id, 0, bx, 200, 2000)
	)
	Check(
		"foreign_transport_unload",
		not handler:AllowUnitTransportUnload(
			trans,
			td,
			0,
			localUnit,
			UnitDefNames.cloakraid.id,
			0,
			bx,
			200,
			2000
		)
	)
	Check(
		"local_transport_unload",
		handler:AllowUnitTransportUnload(
			trans,
			td,
			0,
			localUnit,
			UnitDefNames.cloakraid.id,
			0,
			ax - 100,
			200,
			2200
		)
	)
end
function gadget:GameFrame(f)
	if units.jumper and Spring.GetUnitRulesParam(units.jumper, "is_jumping") == 1 then
		sawJump = true
	end
	if units.thrown and GG.Thrower.IsFlying(units.thrown) then
		sawThrow = true
	end
	if f == 1 then
		for _, r in ipairs(world.regions) do
			Spring.LevelHeightMap(r.x0, r.z0, r.x1, r.z1, 200)
		end
		for _, id in ipairs(Spring.GetAllUnits()) do
			Spring.GiveOrderToUnit(id, CMD.FIRE_STATE, { 0 }, 0)
		end
		Spring.SetTeamResource(0, "e", 1000000)
		Spring.SetTeamResource(0, "m", 1000000)
	end
	if f == 60 then
		Spawn("shieldA", "staticshield", ax, 3400)
		Spawn("shieldB", "staticshield", bx, 3400)
		Spawn("shieldLocalA", "staticshield", ax - 400, 600)
		Spawn("shieldLocalB", "staticshield", ax - 700, 600)
		Spawn("pylonA", "energypylon", ax, 1300)
		Spawn("pylonB", "energypylon", bx, 1300)
		Spawn("pylonLocal", "energypylon", ax - 200, 1300)
		Spawn("builder", "cloakcon", ax - 200, 2000)
		Spawn("localUnit", "cloakraid", ax - 100, 2200)
		Spawn("foreign", "cloakraid", bx, 2200)
		Spawn("transport", "gunshiptrans", ax - 350, 2400)
		units.wreckDef = UnitDefNames.cloakraid.wreckName
		units.localWreck = Spring.CreateFeature(units.wreckDef, ax - 200, 200, 2600, 0, 0)
		units.foreignWreck = Spring.CreateFeature(units.wreckDef, bx, 200, 2600, 0, 0)
		assert(units.localWreck and units.foreignWreck, "Missing wreck fixtures")
		units.wreckDef = Spring.GetFeatureDefID(units.localWreck)
		-- Exercise enlarged ability radii through the normal commander-upgrade
		-- configuration hook, without replacing the cloak implementation.
		local original = GG.Upgrades_UnitCloakShieldDef
		GG.Upgrades_UnitCloakShieldDef = function()
			return {
				energy = 0,
				maxrad = 1400,
				growRate = 1e8,
				shrinkRate = 1e8,
				recloakRate = 1e6,
				level = 4,
				init = true,
				selfCloak = true,
				draw = false,
			}
		end
		Spawn("cloaker", "cloakraid", ax - 50, 2000)
		Spring.SetUnitCOBValue(units.cloaker, COB.ACTIVATION, 1)
		GG.Upgrades_UnitCloakShieldDef = original
		Spawn("carrier", "nebula", 1800, 1800)
		Spawn("padLocal", "staticrearm", ax - 500, 2800)
		Spawn("padForeign", "staticrearm", bx, 2800)
		Spawn("bomber", "bomberprec", ax - 200, 2900)
		Spawn("jumper", "jumpraid", 1400, 900)
		Spawn("thrower", "amphlaunch", 2000, 900)
		Spawn("thrown", "cloakraid", 2070, 900)
		Spawn("tracker", "hoverdepthcharge", 1200, 1200)
		Spawn("tracked", "cloakraid", 1700, 1200)
		Spawn("factory", "factorycloak", ax - 100, 500)
		Spawn("plateLocal", "platecloak", ax - 350, 500)
		Spawn("plateForeign", "platecloak", bx, 500)
		local originalPoke = GG.PokeDecloakUnit
		GG.PokeDecloakUnit = function(id, ...)
			pokes[id] = (pokes[id] or 0) + 1
			return originalPoke(id, ...)
		end
	end
	if f == 90 then
		Spring.GiveOrderToUnit(units.jumper, Spring.Utilities.CMD.JUMP, { 1600, 200, 900 }, 0)
		Spring.GiveOrderToUnit(units.thrower, CMD.MANUALFIRE, { 2500, 200, 900 }, 0)
		retargetProjectile = Spring.SpawnProjectile(WeaponDefNames.hoverdepthcharge_depthcharge.id, {
			pos = { 1200, 500, 1200 },
			speed = { 1, 0, 0 },
			owner = units.tracker,
			team = 0,
			ttl = 300,
		})
		Spring.SetProjectileTarget(retargetProjectile, units.tracked, string.byte("u"))
	end
	if f == 100 then
		local x, y, z = Spring.GetUnitPosition(units.tracked)
		Spring.SetUnitPosition(units.tracked, bx, y, z)
		GG.PortalWorlds.home[units.tracked] = 2
	end
	if f == 105 then
		local x, _, z = Spring.GetProjectilePosition(retargetProjectile)
		Check("retarget_cannot_follow_travelled_target", not x or world.Region(x, z) == nil)
	end
	if f == 150 then
		DispatchChecks()
		Check("plate_local_enabled", Spring.GetUnitRulesParam(units.plateLocal, "nofactory") == 0)
		Check("plate_foreign_disabled", Spring.GetUnitRulesParam(units.plateForeign, "nofactory") == 1)
		Check("airpad_search_local", GG.FindBestAirpadAt(units.bomber, bx, 2800, 2000) == units.padLocal)
		Spring.SetUnitRulesParam(units.bomber, "noammo", 1)
		local selectedPad = GG.RequestRearm(units.bomber, nil, true, true)
		local queue = Spring.GetUnitCommands(units.bomber, -1)
		for _, cmd in ipairs(queue) do
			if cmd.id == Spring.Utilities.CMD.REARM then
				selectedPad = cmd.params[1]
			end
		end
		Check("bomber_rearm_local", selectedPad == units.padLocal, selectedPad)
		local health = Spring.GetUnitHealth(units.foreign)
		local callbacks = damageCallbacks
		for weapon = 1, #WeaponDefs do
			Spring.AddUnitDamage(units.foreign, 1, 0, units.builder, weapon)
		end
		Check(
			"all_weapon_defs_foreign_damage_blocked",
			health == Spring.GetUnitHealth(units.foreign),
			#WeaponDefs
		)
		Check("all_weapon_defs_foreign_callbacks_blocked", damageCallbacks == callbacks)

		SetCharge("shieldA", 0)
		SetCharge("shieldB", 4000)
		SetCharge("shieldLocalA", 0)
		SetCharge("shieldLocalB", 4000)
		Check("cloak_local_applied", Spring.GetUnitRulesParam(units.localUnit, "areacloaked") == 1)
		Check("cloak_foreign_rejected", Spring.GetUnitRulesParam(units.foreign, "areacloaked") ~= 1)
		GG.ScanSweep.AddArea("scoutPlane", 0, ax, 2200, 1200, 90)
		Check("scan_local_immediate", (pokes[units.localUnit] or 0) > 0)
		Check("scan_foreign_immediate", not pokes[units.foreign])
	end
	if f == 270 then
		Check("ordinary_jump_executed", sawJump)
		Check("ordinary_lobster_throw_executed", sawThrow)
		Spring.GiveOrderToUnit(units.jumper, Spring.Utilities.CMD.JUMP, { bx, 200, 900 }, 0)
		local q = Spring.GetUnitCommands(units.jumper, -1)
		Check("foreign_jump_rejected", not q[1] or q[1].id ~= Spring.Utilities.CMD.JUMP)
		GG.SetUnitTarget(units.tracker, units.tracked)
		Check("stored_foreign_target_rejected", not GG.GetUnitHasSetTarget(units.tracker))
		Check("scan_foreign_repeat_expiry", not pokes[units.foreign])
		Check("scan_local_repeat_expiry", (pokes[units.localUnit] or 0) >= 3, pokes[units.localUnit])
		local localGrid = Spring.GetUnitRulesParam(units.pylonA, "gridNumber")
		Check(
			"pylon_local_connected",
			localGrid
				and localGrid > 0
				and localGrid == Spring.GetUnitRulesParam(units.pylonLocal, "gridNumber")
		)
		Check("pylon_foreign_disconnected", localGrid ~= Spring.GetUnitRulesParam(units.pylonB, "gridNumber"))
		Check("shield_foreign_no_charge_transfer", Charge("shieldA") < 500, Charge("shieldA"))
		Check("shield_local_charge_transfer", Charge("shieldLocalA") > 500, Charge("shieldLocalA"))
		SetCharge("shieldA", 0)
		SetCharge("shieldB", 4000)
		local before = Charge("shieldB")
		GG.DrainShieldAndCheckProjectilePenetrate(units.shieldA, 1000, 0, nil)
		Check("shield_merge_foreign_battery_unchanged", Charge("shieldB") == before)
		local r = GG.PortalWorlds
		-- Change logical membership while positions and cached links still overlap.
		-- This exercises the same transition as arrival before periodic link updates.
		r.home[units.shieldLocalB] = 2
		SetCharge("shieldLocalA", 0)
		SetCharge("shieldLocalB", 4000)
		GG.DrainShieldAndCheckProjectilePenetrate(units.shieldLocalA, 1000, 0, nil)
		Check("shield_stale_link_no_foreign_drain", Charge("shieldLocalB") == 4000)
		r.home[units.shieldLocalB] = 1
		local beforeForeign = Spring.GetGroundHeight(bx + 100, 3000)
		Spring.SetHeightMapFunc(function()
			Spring.SetHeightMap(ax - 100, 3000, 400)
		end)
		local beforeLocal = Spring.GetGroundHeight(ax - 100, 3000)
		GG.Terraform.DoSmooth({
			smoothradius = 1200,
			gatherradius = 1200,
			detachmentradius = 1200,
			smooth = 1,
			movestructures = 1,
		}, ax, 200, 3000)
		Check("smooth_local_changed", math.abs(Spring.GetGroundHeight(ax - 100, 3000) - beforeLocal) > 1)
		Check("smooth_foreign_unchanged", Spring.GetGroundHeight(bx + 100, 3000) == beforeForeign)

		for _, id in ipairs(Spring.GetTeamUnits(1)) do
			if UnitDefs[Spring.GetUnitDefID(id)].customParams.commtype then
				Spring.DestroyUnit(id, false, false)
				break
			end
		end
	end
	if f == 600 then
		Check("carrier_creates_real_drones", #(GG.Drones_GetCarrierUnits(units.carrier) or {}) > 0)
		local docked = 0
		for _, id in ipairs(GG.Drones_GetCarrierUnits(units.carrier) or {}) do
			if select(5, Spring.GetUnitHealth(id)) < 1 then
				docked = docked + 1
			end
		end
		Check("carrier_has_docked_nanoframes_before_travel", docked > 0, docked)
		local p = GG.PortalWorlds
		local mouth = p.mouths[1] and p.mouths[1][1]
		Check("commander_loss_opened", mouth ~= nil)
		if mouth then
			local _, y = Spring.GetUnitPosition(units.carrier)
			Spring.SetUnitPosition(units.carrier, mouth.x, y, mouth.z)
			Spring.SetUnitPosition(units.bomber, mouth.x, y + 100, mouth.z)
			Spring.GiveOrderToUnit(units.bomber, Spring.Utilities.CMD.PORTAL_TRAVEL, { 1 }, 0)
			Spring.GiveOrderToUnit(units.carrier, Spring.Utilities.CMD.PORTAL_TRAVEL, { 1 }, 0)
		end
	end
	if f == 900 then
		local p = GG.PortalWorlds
		Check("bomber_travelled", p.home[units.bomber] == 2, p.home[units.bomber])
		Check(
			"bomber_old_pad_released",
			Spring.GetUnitRulesParam(units.padLocal, "unreservedPad") == 4,
			Spring.GetUnitRulesParam(units.padLocal, "unreservedPad")
		)
		Check(
			"bomber_destination_pad_search",
			GG.FindBestAirpadAt(units.bomber, bx, 2800, 3000) == units.padForeign
		)
		Check("carrier_travelled", p.home[units.carrier] == 2, p.home[units.carrier])
		local drones = GG.Drones_GetCarrierUnits(units.carrier) or {}
		Check("carrier_roster_survives", #drones > 0)
		for i, id in ipairs(drones) do
			local x, _, z = Spring.GetUnitPosition(id)
			Check("carrier_drone_home_" .. i, p.home[id] == 2)
			local queue = Spring.GetUnitCommands(id, -1)
			Check(
				"carrier_drone_guard_" .. i,
				queue[#queue] and queue[#queue].id == CMD.GUARD and queue[#queue].params[1] == units.carrier
			)
			Check("carrier_drone_position_" .. i, p.Region(x, z) == 2)
		end
		Spring.Echo("[FULL_MECHANICS] DONE checks=" .. checks .. " failures=" .. failures)
		Spring.SetGameRulesParam("portal_full_mechanics_passed", failures == 0 and 1 or 0)
		if Spring.GetModOptions().zk_duels_save == "1" then
			GG.ScanSweep.AddArea("scoutPlane", 0, bx + 500, 2000, 1200, 600)
			local m = p.mouths[1][1]
			local dx, dz = (a.x0 + a.x1) / 2 - m.x, (a.z0 + a.z1) / 2 - m.z
			local length = math.sqrt(dx * dx + dz * dz)
			Spawn("saveTraveler", "cloakraid", m.x + dx / length * 650, m.z + dz / length * 650)
			Spring.GiveOrderToUnit(
				units.saveTraveler,
				CMD.MOVE,
				{ (b.x0 + b.x1) / 2, 200, (b.z0 + b.z1) / 2 },
				0
			)
			Spring.GiveOrderToUnit(units.jumper, Spring.Utilities.CMD.JUMP, { 1800, 200, 900 }, 0)
		end
	end
	if f == 915 and Spring.GetModOptions().zk_duels_save == "1" then
		Check("save_jump_active", Spring.GetUnitRulesParam(units.jumper, "is_jumping") == 1)
		saveJumpPosition = { Spring.GetUnitPosition(units.jumper) }
		savedScanPokes = { pokes[units.localUnit] or 0, pokes[units.foreign] or 0 }
		Check("save_traveler_still_approaching", GG.PortalWorlds.home[units.saveTraveler] == 1)
		Spring.Echo("[FULL_SAVELOAD] READY checks=" .. checks .. " failures=" .. failures)
		Spring.SetGameRulesParam("portal_save_ready", failures == 0 and 1 or 0)
	end
	if f == 1020 and Spring.GetModOptions().zk_duels_save == "1" then
		local p = GG.PortalWorlds
		Check("loaded_portal_graph", p.openEdges[1] and p.mouths[1][1] and p.mouths[1][2])
		Check("loaded_carrier_membership", p.home[units.carrier] == 2)
		Check("loaded_bomber_membership", p.home[units.bomber] == 2)
		local drones = GG.Drones_GetCarrierUnits(units.carrier) or {}
		Check("loaded_carrier_roster", #drones > 0)
		for i, id in ipairs(drones) do
			Check("loaded_drone_membership_" .. i, p.home[id] == 2)
		end
		Check(
			"loaded_pylon_partition",
			Spring.GetUnitRulesParam(units.pylonA, "gridNumber")
				~= Spring.GetUnitRulesParam(units.pylonB, "gridNumber")
		)
		Check("loaded_jump_finished", Spring.GetUnitRulesParam(units.jumper, "is_jumping") ~= 1)
		local jx, jy, jz = Spring.GetUnitPosition(units.jumper)
		Check("loaded_jump_arrived", math.abs(jx - 1800) < 10 and math.abs(jz - 900) < 10)
		Check("loaded_jump_advanced", math.abs(jy - saveJumpPosition[2]) > 10)
		Check("loaded_scan_continues", (pokes[units.foreign] or 0) > savedScanPokes[2])
		Check("loaded_scan_isolated", (pokes[units.localUnit] or 0) == savedScanPokes[1])
		local foreignCharge = Charge("shieldB")
		SetCharge("shieldA", 0)
		GG.DrainShieldAndCheckProjectilePenetrate(units.shieldA, 1000, 0, nil)
		Check("loaded_shield_partition", Charge("shieldB") == foreignCharge)
		local hp = Spring.GetUnitHealth(units.foreign)
		Spring.AddUnitDamage(units.foreign, 10, 0, units.builder, WeaponDefNames.cloakraid_emg.id)
		Check("loaded_damage_partition", Spring.GetUnitHealth(units.foreign) == hp)
	end
	-- The scan expires at 1501 in its later-layered GameFrame callin.
	if f == 1502 and Spring.GetModOptions().zk_duels_save == "1" then
		expiredScanPokes = pokes[units.foreign] or 0
	end
	if f == 1560 and Spring.GetModOptions().zk_duels_save == "1" then
		Check("loaded_scan_expires", (pokes[units.foreign] or 0) == expiredScanPokes)
		Check("loaded_pending_traveler_arrives", GG.PortalWorlds.home[units.saveTraveler] == 2)
		local clean = true
		for _, cmd in ipairs(Spring.GetUnitCommands(units.saveTraveler, -1)) do
			if
				(cmd.id == CMD.MOVE or cmd.id == Spring.Utilities.CMD.RAW_MOVE)
				and world.Region(cmd.params[1], cmd.params[3]) == 1
			then
				clean = false
			end
		end
		Check("loaded_traveler_no_source_order", clean)
		Spring.Echo("[FULL_SAVELOAD] DONE checks=" .. checks .. " failures=" .. failures)
		Spring.SetGameRulesParam("portal_save_loaded_done", failures == 0 and 1 or 0)
	end
end
