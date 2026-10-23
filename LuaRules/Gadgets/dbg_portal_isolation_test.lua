-- This file is part of Zero-K (GPL v2 or later), see LICENSE.
function gadget:GetInfo()
	return { name = "Portal isolation and queue regression", layer = 20000, enabled = true }
end
if not gadgetHandler:IsSyncedCode() or Spring.GetModOptions().zk_duels_test ~= "isolation" then
	return false
end
local world = VFS.Include("LuaRules/Utilities/portal_worlds.lua")
local PORTAL = Spring.Utilities.CMD.PORTAL_TRAVEL
local calls, postCalls = {}, {}
local portalUsers, oldOrders = {}, {}
local waitUnit, queuedUnit, beacon, sourceFeature, carrier, cargo
local illicitSpawn, legitimateChild
local function Check(name, pass, detail)
	Spring.Echo(
		"[ISOLATION_TEST] ASSERT " .. name .. " pass=" .. tostring(not not pass) .. " " .. (detail or "")
	)
end
local function Spawn(name, region, team, x, z)
	local r = world.regions[region]
	x, z = r.x0 + (x or 2100), r.z0 + (z or 1800)
	local id = assert(Spring.CreateUnit(name, x, Spring.GetGroundHeight(x, z), z, 0, team))
	Spring.SetUnitMaxHealth(id, 100000)
	Spring.SetUnitHealth(id, 100000)
	Spring.GiveOrderToUnit(id, CMD.FIRE_STATE, { 0 }, 0)
	Spring.GiveOrderToUnit(id, CMD.MOVE_STATE, { 0 }, 0)
	return id
end
function gadget:UnitPreDamaged(id, def, team, damage)
	calls[id] = (calls[id] or 0) + 1
	return damage
end
function gadget:UnitDamaged(id)
	postCalls[id] = (postCalls[id] or 0) + 1
end
function gadget:GameFrame(f)
	if f == 1 then
		for _, id in ipairs(Spring.GetAllUnits()) do
			Spring.GiveOrderToUnit(id, CMD.FIRE_STATE, { 0 }, 0)
		end
	end
	if f == 60 then
		local names =
			{ "turretlaser", "vehcapture", "amphimpulse", "gunshipemp", "droneheavyslow", "vehraid" }
		for region = 1, #world.regions do
			for kind, name in ipairs(names) do
				local attacker = Spawn(name, region, (region - 1) * 2, 1500 + kind * 100, 1500)
				local foreign = Spawn(
					"energysolar",
					region % #world.regions + 1,
					(region % #world.regions) * 2,
					1500 + kind * 100,
					2100
				)
				local localTarget =
					Spawn("energysolar", region, (region - 1) * 2 + 1, 1500 + kind * 100, 2400)
				local weapon = UnitDefs[Spring.GetUnitDefID(attacker)].weapons[1].weaponDef
				local health = Spring.GetUnitHealth(foreign)
				Spring.AddUnitDamage(foreign, 100, 0, attacker, weapon)
				Check(
					"no_foreign_callbacks_" .. region .. "_" .. name,
					(calls[foreign] or 0) == 0 and (postCalls[foreign] or 0) == 0
				)
				Check("foreign_health_" .. region .. "_" .. name, Spring.GetUnitHealth(foreign) == health)
				Spring.AddUnitDamage(localTarget, 100, 0, attacker, weapon)
				Check("local_callbacks_" .. region .. "_" .. name, (calls[localTarget] or 0) > 0)
			end
		end
		local first = Spawn("energysolar", 1, 0, 1800, 2900)
		local second = Spawn("energysolar", 2, 2, 1800, 2900)
		local before = Spring.GetUnitHealth(first)
		local portal = GG.PortalIsolation
		portal.DamageInRegion(1, Spring.AddUnitDamage, first, 25, 0, second, -1)
		Check("persistent_source_damage_after_owner_travel", Spring.GetUnitHealth(first) == before - 25)
		before = Spring.GetUnitHealth(first)
		portal.DamageInRegion(2, Spring.AddUnitDamage, first, 25, 0, second, -1)
		Check("persistent_foreign_source_blocked", Spring.GetUnitHealth(first) == before)
		pcall(portal.DamageInRegion, 1, function()
			error("intentional scope-reset regression")
		end)
		Spring.AddUnitDamage(first, 25, 0, second, -1)
		Check("damage_scope_reset_after_error", Spring.GetUnitHealth(first) == before)
		local weapon = WeaponDefNames.staticnuke_crblmssl.id
		local x, y, z = Spring.GetUnitPosition(first)
		illicitSpawn = Spring.SpawnProjectile(
			weapon,
			{ pos = { x, y + 800, z }, speed = { 0, 1, 0 }, owner = second, ttl = 1800 }
		)
		legitimateChild = portal.DamageInRegion(
			1,
			Spring.SpawnProjectile,
			weapon,
			{ pos = { x, y + 850, z }, speed = { 0, 1, 0 }, owner = second, ttl = 1800 }
		)
		Check("parent_scope_returns_projectile_id", type(legitimateChild) == "number")
		local ground = Spring.GetGroundHeight(x, z)
		local forced = Spring.SpawnProjectile(
			weapon,
			{ pos = { x, ground + 20, z }, speed = { 0, -5, 0 }, owner = second, ttl = 100 }
		)
		Spring.SetProjectileCollision(forced)
		Check("forced_foreign_spawn_does_not_crater", Spring.GetGroundHeight(x, z) == ground)

		for _, id in ipairs(Spring.GetTeamUnits(1)) do
			if UnitDefs[Spring.GetUnitDefID(id)].customParams.commtype then
				Spring.DestroyUnit(id, false, false)
				break
			end
		end
	end
	if f == 90 then
		Check("scripted_foreign_origin_removed", not Spring.GetProjectilePosition(illicitSpawn))
		Check(
			"parent_region_child_survives_owner_travel",
			Spring.GetProjectilePosition(legitimateChild) ~= nil
		)
		Spring.DeleteProjectile(legitimateChild)
	end
	if f == 120 then
		local m = GG.PortalWorlds.mouths[1][1]
		for id, b in pairs(GG.PortalWorlds.beacons) do
			if b.edge == 1 and b.region == 1 then
				beacon = id
			end
		end
		Check("beacon_exists", beacon ~= nil)
		local before = Spring.GetUnitHealth(beacon)
		local oldX = math.max(world.regions[1].x0 + 300, math.min(world.regions[1].x1 - 300, m.x + 500))
		local oldZ = math.max(world.regions[1].z0 + 300, math.min(world.regions[1].z1 - 300, m.z - 500))
		sourceFeature = Spring.CreateFeature(
			"staticmex_dead",
			oldX,
			Spring.GetGroundHeight(oldX, oldZ),
			oldZ,
			0,
			Spring.GetGaiaTeamID()
		)
		for index, cmd in ipairs({ CMD.ATTACK, CMD.GUARD, CMD.REPAIR, CMD.RECLAIM, CMD.CAPTURE, CMD.LOAD_UNITS }) do
			local id = Spawn(
				index <= 3 and "gunshipraid" or "cloakcon",
				1,
				0,
				m.x - world.regions[1].x0 - 150,
				m.z - world.regions[1].z0 + index * 40
			)
			portalUsers[index] = id
			Spring.GiveOrderToUnit(id, cmd, { beacon }, 0)
			local queue = Spring.GetUnitCommands(id, -1)
			Check("portal_click_queued_as_travel_" .. index, queue[1] and queue[1].id == PORTAL)
			if index == 6 then
				Spring.GiveOrderToUnit(id, CMD.RECLAIM, { Game.maxUnits + sourceFeature }, CMD.OPT_SHIFT)
			end
			Spring.AddUnitDamage(
				beacon,
				100,
				0,
				id,
				UnitDefs[UnitDefNames.turretlaser.id].weapons[1].weaponDef
			)
		end
		Check(
			"beacon_has_no_damage_or_status_callbacks",
			Spring.GetUnitHealth(beacon) == before and not calls[beacon] and not postCalls[beacon]
		)
		waitUnit = Spawn("gunshipraid", 1, 0, m.x - 250, m.z)
		Spring.GiveOrderToUnit(waitUnit, CMD.WAIT, {}, 0)
		Spring.GiveOrderToUnit(waitUnit, PORTAL, { 1, 1 }, CMD.OPT_SHIFT)
		carrier = Spawn("gunshiptrans", 1, 0, m.x + 200, m.z - 300)
		cargo = Spawn("cloakraid", 1, 0, m.x + 200, m.z - 300)
		Spring.GiveOrderToUnit(cargo, CMD.MOVE, { oldX, 0, oldZ }, 0)
		Check("cargo_source_order_accepted_before_load", #Spring.GetUnitCommands(cargo, -1) > 0)
		Spring.UnitAttach(carrier, cargo, 1, true)
		Spring.GiveOrderToUnit(carrier, PORTAL, { 1, 1 }, 0)
		queuedUnit = Spawn("gunshipraid", 1, 0, m.x - 140, m.z - 100)
		local r = world.regions[2]
		Spring.GiveOrderToUnit(queuedUnit, Spring.Utilities.CMD.RAW_MOVE, { r.x0 + 1800, 0, r.z0 + 2400 }, 0)
		Spring.GiveOrderToUnit(queuedUnit, CMD.MOVE, { oldX, 0, oldZ }, CMD.OPT_SHIFT)
		Spring.GiveOrderToUnit(queuedUnit, CMD.MOVE, { r.x0 + 2300, 0, r.z0 + 2100 }, CMD.OPT_SHIFT)
		Check("source_waypoint_fixture_queued", #Spring.GetUnitCommands(queuedUnit, -1) >= 3)
	end
	if f == 240 then
		Check("shift_portal_waits_for_prior_order", GG.PortalWorlds.home[waitUnit] == 1)
		Spring.GiveOrderToUnit(waitUnit, CMD.WAIT, {}, 0)
	end
	if f == 1200 then
		for i, id in ipairs(portalUsers) do
			Check("portal_click_arrived_" .. i, GG.PortalWorlds.home[id] == 2)
		end
		Check("shift_portal_arrived", GG.PortalWorlds.home[waitUnit] == 2)
		Check("automatic_trip_arrived", GG.PortalWorlds.home[queuedUnit] == 2)
		Check("source_feature_order_removed", #Spring.GetUnitCommands(portalUsers[6], -1) == 0)
		Check("carrier_arrived", GG.PortalWorlds.home[carrier] == 2)
		Check(
			"cargo_arrived",
			GG.PortalWorlds.home[cargo] == 2 and Spring.GetUnitTransporter(cargo) == carrier
		)
		Check("cargo_source_orders_removed", #Spring.GetUnitCommands(cargo, -1) == 0)
		local old = false
		for _, cmd in ipairs(Spring.GetUnitCommands(queuedUnit, -1)) do
			if #cmd.params >= 3 and world.Region(cmd.params[1], cmd.params[3]) == 1 then
				old = true
			end
		end
		Check("source_map_waypoints_removed_after_automatic_trip", not old)
		local r = world.regions[2]
		local x, _, z = Spring.GetUnitPosition(queuedUnit)
		local orders = ""
		for _, cmd in ipairs(Spring.GetUnitCommands(queuedUnit, -1)) do
			orders = orders .. cmd.id .. ":" .. table.concat(cmd.params, ",") .. ";"
		end
		Check(
			"destination_queue_completed",
			math.abs(x - (r.x0 + 2300)) < 200 and math.abs(z - (r.z0 + 2100)) < 200,
			"x=" .. x .. " z=" .. z .. " queue=" .. orders
		)
	end
end
