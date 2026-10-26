-- This file is part of the Spring engine (GPL v2 or later), see LICENSE.html
function gadget:GetInfo()
	return {
		name = "Portal multiple maps verification",
		desc = "Opt-in real simulation travel and weapons checks",
		author = "Codex",
		license = "GPL v2 or later",
		layer = -100,
		enabled = true,
	}
end
if not gadgetHandler:IsSyncedCode() or Spring.GetModOptions().zk_duels_test ~= "four" then
	return false
end
local world = VFS.Include("LuaRules/Utilities/portal_worlds.lua")
local RAW_MOVE = Spring.Utilities.CMD.RAW_MOVE
local units, localUnits, tripUnits, damageUnits, deadOwner, deadMissile, nuke, localNuke, crossNuke, features =
	{}, {}, {}, {}, nil, nil, nil, nil, nil, {}
local initialHealth, initialFeature, initialGround = {}, {}, {}
local protected = {}
local edgeTrips = {}
local clickedUnit, otherSelected
local function Check(name, pass, detail)
	Spring.Echo("[FOUR_TEST] ASSERT " .. name .. " pass=" .. tostring(not not pass) .. " " .. (detail or ""))
end
local function Spawn(name, x, z, team)
	local def = UnitDefNames[name].id
	local r = world.regions[world.Region(x, z)]
	for ring = 0, 30 do
		for j = 0, 15 do
			local tx, tz =
				x + ring * 24 * math.cos(j * math.pi / 8), z + ring * 24 * math.sin(j * math.pi / 8)
			if
				world.Region(tx, tz) == world.Region(x, z)
				and Spring.GetGroundHeight(tx, tz) > 4
				and (
					UnitDefs[def].isImmobile
					or UnitDefs[def].canFly
					or Spring.TestMoveOrder(
						def,
						tx,
						Spring.GetGroundHeight(tx, tz),
						tz,
						0,
						0,
						0,
						true,
						true,
						true
					)
				)
			then
				local id = Spring.CreateUnit(name, tx, Spring.GetGroundHeight(tx, tz), tz, 0, team or 0)
				if id then
					Spring.GiveOrderToUnit(id, CMD.FIRE_STATE, { 0 }, 0)
					Spring.GiveOrderToUnit(id, CMD.MOVE_STATE, { 0 }, 0)
					return id
				end
			end
		end
	end
	error("Could not spawn fixture " .. name .. " at " .. x .. "," .. z)
end
local function Commander(team)
	for _, id in ipairs(Spring.GetTeamUnits(team)) do
		if UnitDefs[Spring.GetUnitDefID(id)].customParams.commtype then
			return id
		end
	end
end
local function KillCommander(region)
	local team = world.teams[(region - 1) * 2 + 2].team
	local id = Commander(team)
	local r = world.regions[region]
	local x, z = r.x0 + r.width * 0.75, r.z0 + r.height * 0.7
	GG.MoveMobileUnit(id, x, Spring.GetGroundHeight(x, z), z)
	Spring.SetGameRulesParam("four_death_" .. region .. "_x", x)
	Spring.SetGameRulesParam("four_death_" .. region .. "_z", z)
	Spring.DestroyUnit(id, false, false)
end
local function Mouth(edge, region)
	return GG.PortalWorlds.mouths[edge][region]
end
local function RegionOf(id)
	local x, _, z = Spring.GetUnitPosition(id)
	return world.Region(x, z)
end
function gadget:UnitPreDamaged(id, def, team, damage)
	if protected[id] then
		return 0, 0
	end
	return damage
end
function gadget:GameFrame(f)
	if f == 1 then
		for _, id in ipairs(Spring.GetAllUnits()) do
			Spring.GiveOrderToUnit(id, CMD.FIRE_STATE, { 0 }, 0)
			Spring.GiveOrderToUnit(id, CMD.MOVE_STATE, { 0 }, 0)
		end
	end
	if f == 30 then
		Check("manifest_region_count", #world.regions == 4)
		for i, r in ipairs(world.regions) do
			local count = 0
			for _, s in ipairs(GG.metalSpots) do
				if world.Region(s.x, s.z) == i then
					count = count + 1
				end
			end
			Check(
				"native_metal_spots_" .. i,
				count == r.metal_spots,
				"actual=" .. count .. " expected=" .. r.metal_spots
			)
			local id = Spawn("energysolar", r.x0 + 1000, r.z0 + 1000, (i - 1) * 2)
			damageUnits[i] = id
			initialHealth[id] = Spring.GetUnitHealth(id)
			local event = Spawn("energysolar", r.x0 + 1200, r.z0 + 1200, 0)
			protected[event] = true
			Spring.SetGameRulesParam("four_event_unit_" .. i, event)
		end
		nuke = Spawn("staticnuke", world.regions[1].x0 + 1400, world.regions[1].z0 + 1400)
		local target = world.regions[2]
		Spring.GiveOrderToUnit(nuke, CMD.ATTACK, { target.x0 + 1000, 0, target.z0 + 1000 }, 0)
		Check("cross_nuke_ground_order_rejected", #Spring.GetUnitCommands(nuke, -1) == 0)
		Spring.GiveOrderToUnit(nuke, CMD.INSERT, { 0, CMD.ATTACK, 0, damageUnits[2] }, CMD.OPT_ALT)
		Check("inserted_cross_nuke_unit_order_rejected", #Spring.GetUnitCommands(nuke, -1) == 0)
		Spring.GiveOrderToUnit(nuke, Spring.Utilities.CMD.UNIT_SET_TARGET, { damageUnits[2] }, 0)
		Check("cross_set_target_rejected", not Spring.GetUnitRulesParam(nuke, "target_id"))
		Spring.AddUnitDamage(damageUnits[2], 50, 0, damageUnits[1], -1)
		Check(
			"direct_cross_damage_rejected",
			Spring.GetUnitHealth(damageUnits[2]) == initialHealth[damageUnits[2]]
		)
		Spring.AddUnitDamage(damageUnits[1], 50, 0, nuke, -1)
		Check(
			"local_damage_still_works",
			Spring.GetUnitHealth(damageUnits[1]) < initialHealth[damageUnits[1]]
		)
	end
	if f == 60 then
		local r = world.regions[1]
		local weapon = WeaponDefNames.staticnuke_crblmssl.id
		local x, z = r.x0 + 1800, r.z0 + 1800
		crossNuke = Spring.SpawnProjectile(
			weapon,
			{ pos = { x, Spring.GetGroundHeight(x, z) + 400, z }, speed = { 0, 2, 0 }, owner = nuke, ttl = 1800, tracking = true }
		)
		Spring.SetProjectileTarget(crossNuke, damageUnits[2], string.byte("u"))
		Spring.SetGameRulesParam("four_cross_nuke", crossNuke)
		localNuke = Spring.SpawnProjectile(
			weapon,
			{ pos = { x, Spring.GetGroundHeight(x, z) + 400, z }, speed = { 0, 2, 0 }, owner = nuke, ttl = 1800, tracking = true }
		)
		Spring.SetProjectileTarget(localNuke, damageUnits[1], string.byte("u"))
		initialGround[2] = Spring.GetGroundHeight(world.regions[2].x0 + 1000, world.regions[2].z0 + 1000)
	end
	if f == 90 then
		Check("cross_target_nuke_removed", not Spring.GetProjectilePosition(crossNuke))
		Check("same_map_nuke_survives", Spring.GetProjectilePosition(localNuke) ~= nil)
		if Spring.GetProjectilePosition(localNuke) then
			Spring.DeleteProjectile(localNuke)
		end
		Check(
			"foreign_map_not_cratered",
			Spring.GetGroundHeight(world.regions[2].x0 + 1000, world.regions[2].z0 + 1000) == initialGround[2]
		)
	end
	if f == 120 then
		KillCommander(1)
	end
	if f == 180 then
		Check("first_connection_open", GG.PortalWorlds.openEdges[1] and not GG.PortalWorlds.openEdges[2])
		local m = Mouth(1, 1)
		Check(
			"mouth_at_commander_death",
			m.x == Spring.GetGameRulesParam("four_death_1_x")
				and m.z == Spring.GetGameRulesParam("four_death_1_z")
		)
		local destination = world.regions[2]
		for i, kind in ipairs({ "cloakraid", "cloakraid", "gunshipraid", "cloakraid", "cloakcon" }) do
			local id = Spawn(kind, m.x - 250, m.z + (i - 3) * 70)
			protected[id] = true
			tripUnits[i] = id
			if i == 1 then
				Spring.GiveOrderToUnit(id, RAW_MOVE, { destination.x0 + 1800, 0, destination.z0 + 2200 }, 0)
			elseif i == 2 then
				Spring.GiveOrderToUnit(id, CMD.FIGHT, { destination.x0 + 1900, 0, destination.z0 + 2100 }, 0)
			elseif i == 3 then
				Spring.GiveOrderToUnit(id, CMD.ATTACK, { damageUnits[2] }, 0)
			else
				Spring.GiveOrderToUnit(id, Spring.Utilities.CMD.PORTAL_TRAVEL, { 1 }, 0)
			end
		end
		for i, cmd in ipairs({ CMD.STOP, CMD.MOVE, CMD.FIGHT }) do
			local id = Spawn("cloakraid", m.x - 100, m.z + (i - 2) * 50)
			localUnits[i] = id
			protected[id] = true
			if cmd ~= CMD.STOP then
				Spring.GiveOrderToUnit(id, cmd, { m.x, Spring.GetGroundHeight(m.x, m.z), m.z }, 0)
			end
		end
	end
	if f == 300 then
		KillCommander(2)
	end
	if f == 400 then
		Check("second_connection_open", GG.PortalWorlds.openEdges[2] and not GG.PortalWorlds.openEdges[3])
		local m = Mouth(1, 1)
		local r = world.regions[3]
		local id = Spawn("gunshipraid", m.x - 160, m.z - 100)
		protected[id] = true
		tripUnits[6] = id
		Spring.GiveOrderToUnit(id, RAW_MOVE, { r.x0 + 2000, 0, r.z0 + 2000 }, 0)
		Spring.GiveOrderToUnit(id, CMD.MOVE, { r.x0 + 2300, 0, r.z0 + 2200 }, CMD.OPT_SHIFT)
	end
	if f == 450 then
		KillCommander(3)
	end
	if f == 600 then
		KillCommander(4)
	end
	if f == 660 then
		for i in ipairs(world.connections) do
			Check("edge_open_" .. i, GG.PortalWorlds.openEdges[i])
		end
		local r = world.regions[1]
		deadOwner = Spawn("cloakraid", r.x0 + 1300, r.z0 + 2400)
		deadMissile = Spring.SpawnProjectile(
			WeaponDefNames.staticnuke_crblmssl.id,
			{
				pos = { r.x0 + 1500, Spring.GetGroundHeight(r.x0 + 1500, r.z0 + 2400) + 700, r.z0 + 2400 },
				speed = { 0, 1, 0 },
				owner = deadOwner,
				ttl = 1800,
			}
		)
		Spring.DestroyUnit(deadOwner, false, true)
		local isolation = GG.PortalIsolation
		Check("dead_owner_projectile_provenance_guard", not isolation.DamageAllowed(2, nil, deadMissile))
		local anti = Spawn("staticantinuke", r.x0 + 1300, r.z0 + 2100)
		Check(
			"local_antinuke_can_consider_local_missile",
			isolation.projectiles[deadMissile].region == isolation.UnitRegion(anti)
		)
		local foreign = Spawn("staticantinuke", world.regions[2].x0 + 1300, world.regions[2].z0 + 2100, 2)
		Check(
			"foreign_antinuke_cannot_intercept",
			isolation.projectiles[deadMissile].region ~= isolation.UnitRegion(foreign)
		)
		Spring.SetProjectilePosition(deadMissile, world.regions[2].x0 + 1600, 900, world.regions[2].z0 + 2100)
	end
	if f == 700 then
		Check("projectile_cannot_enter_other_region", not Spring.GetProjectilePosition(deadMissile))
		local m = Mouth(1, 1)
		clickedUnit = Spawn("gunshipraid", m.x - 240, m.z - 100, 0)
		protected[clickedUnit] = true
		local to = Mouth(1, 2)
		otherSelected = Spawn("gunshipraid", to.x + 350, to.z + 200, 0)
		protected[otherSelected] = true
		Spring.SetGameRulesParam("four_click_unit", clickedUnit)
		Spring.SetGameRulesParam("four_other_selected", otherSelected)
		for id, b in pairs(GG.PortalWorlds.beacons) do
			if b.edge == 1 and b.region == 1 then
				Spring.SetGameRulesParam("four_click_beacon", id)
			end
		end
	end
	if f == 900 then
		for edge, connection in ipairs(world.connections) do
			for _, source in ipairs(connection) do
				local m = Mouth(edge, source)
				for _, kind in ipairs({ "cloakraid", "gunshipraid" }) do
					local id = Spawn(kind, m.x - 150, m.z - 180, 0)
					protected[id] = true
					edgeTrips[#edgeTrips + 1] = {
						id = id,
						destination = world.Other(connection, source),
						name = edge .. "_" .. source .. "_" .. kind,
					}
					Spring.GiveOrderToUnit(id, Spring.Utilities.CMD.PORTAL_TRAVEL, { edge, source }, 0)
				end
			end
		end
	end
	if f == 1500 then
		for _, trip in ipairs(edgeTrips) do
			Check(
				"bidirectional_edge_" .. trip.name,
				RegionOf(trip.id) == trip.destination,
				"region=" .. tostring(RegionOf(trip.id))
			)
		end
		if Spring.GetModOptions().zk_duels_headless ~= "1" then
			Check("ui_right_click_completed", RegionOf(clickedUnit) == 2)
			Check("other_map_selection_does_not_reverse", RegionOf(otherSelected) == 2)
		end
	end
	if f == 1200 then
		for i, id in ipairs(localUnits) do
			Check("proximity_never_teleports_" .. i, RegionOf(id) == 1)
		end
		for i = 1, 5 do
			Check(
				"explicit_transit_" .. i,
				RegionOf(tripUnits[i]) == 2,
				"region=" .. tostring(RegionOf(tripUnits[i]))
			)
		end
		-- Prove an ordinary nuke can still detonate and damage its own map.
		local r = world.regions[3]
		local target = Spawn("energysolar", r.x0 + 1900, r.z0 + 1800, 6)
		local shooter = Spawn("staticnuke", r.x0 + 1000, r.z0 + 2200, 4)
		units.nukeTarget = target
		units.nukeBefore = Spring.GetUnitHealth(target)
		local projectile = Spring.SpawnProjectile(
			WeaponDefNames.staticnuke_crblmssl.id,
			{
				pos = { r.x0 + 1900, Spring.GetGroundHeight(r.x0 + 1900, r.z0 + 1800) + 25, r.z0 + 1800 },
				speed = { 0, -5, 0 },
				owner = shooter,
				ttl = 90,
			}
		)
		Spring.SetProjectileTarget(projectile, target, string.byte("u"))
		units.impactProjectile = projectile
	end
	if f == 1202 then
		Spring.SetProjectileCollision(units.impactProjectile)
	end
	if f == 1800 then
		Check(
			"same_map_nuke_damages_target",
			not Spring.ValidUnitID(units.nukeTarget)
				or Spring.GetUnitIsDead(units.nukeTarget)
				or Spring.GetUnitHealth(units.nukeTarget) < units.nukeBefore
		)
		local id = tripUnits[6]
		Check("multi_hop_reaches_third_map", RegionOf(id) == 3, "region=" .. tostring(RegionOf(id)))
		local x, _, z = Spring.GetUnitPosition(id)
		local r = world.regions[3]
		Check(
			"queued_order_continues_after_multi_hop",
			x and math.abs(x - (r.x0 + 2300)) < 180 and math.abs(z - (r.z0 + 2200)) < 180,
			"pos=" .. tostring(x) .. "," .. tostring(z)
		)
	end
end
