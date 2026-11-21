-- This file is part of the Spring engine (GPL v2 or later), see LICENSE.html
function gadget:GetInfo()
	return { name = "Portal edge flight regression", layer = -100, enabled = true }
end
if not gadgetHandler:IsSyncedCode() or Spring.GetModOptions().zk_duels_test ~= "edges" then
	return false
end
local world = VFS.Include("LuaRules/Utilities/portal_worlds.lua")
local r, bounds = world.regions[1], world.objectBounds[1]
local aircraft, shots, outsideAircraft, outsideShots = {}, {}, 0, 0
local y, z, weapon, probe
local function Check(name, value)
	Spring.Echo("[PORTAL_EDGE] ASSERT " .. name .. " pass=" .. tostring(not not value))
end
local function Shot(x, speed)
	local id = assert(Spring.SpawnProjectile(weapon, {
		pos = { x, y + 100, z + 120 },
		speed = { speed, 0, 0 },
		owner = aircraft[1],
		team = 0,
		ttl = 600,
		gravity = 0,
	}))
	shots[id] = true
	return id
end
function gadget:GameFrame(f)
	if f == 1 then
		for _, id in ipairs(Spring.GetAllUnits()) do
			Spring.GiveOrderToUnit(id, CMD.FIRE_STATE, { 0 }, 0)
		end
	elseif f == 60 then
		assert(bounds.margin > 0, "Edge flight needs object draw bounds")
		z = (r.z0 + r.z1) / 2
		y = math.max(Spring.GetGroundHeight(r.x1 - 200, z), Spring.GetGroundHeight(r.x1, z)) + 220
		weapon = UnitDefs[UnitDefNames.veharty.id].weapons[1].weaponDef
		for i = 1, 2 do
			local id = assert(Spring.CreateUnit("gunshipskirm", r.x1 - 200, y, z - (i - 1) * 140, 0, 0))
			aircraft[i] = id
			Spring.GiveOrderToUnit(id, CMD.FIRE_STATE, { 0 }, 0)
			Spring.MoveCtrl.Enable(id)
			Spring.MoveCtrl.SetPosition(id, r.x1 + bounds.margin / 2, y, z - (i - 1) * 140)
			Spring.SetGameRulesParam("edge_aircraft_" .. i, id)
		end
		probe = Shot(r.x1 + bounds.margin / 2, 0)
	elseif f == 90 then
		local x, _, az = Spring.GetUnitPosition(aircraft[1])
		Check("aircraft_stays_in_margin", x > r.x1 and world.ContainsObject(1, x, az))
		local px, _, pz = Spring.GetProjectilePosition(probe)
		Check("projectile_survives_in_margin", px and px > r.x1 and world.ContainsObject(1, px, pz))
		Spring.MoveCtrl.SetPosition(aircraft[1], bounds.x1 + 80, y, z)
		Spring.SetProjectilePosition(probe, bounds.x1 + 80, y + 100, z + 120)
	elseif f == 110 then
		local x, _, az = Spring.GetUnitPosition(aircraft[1])
		Check("aircraft_stopped_at_outer_bound", world.ContainsObject(1, x, az))
		Check("projectile_removed_at_outer_bound", Spring.GetProjectilePosition(probe) == nil)
	end
	if f >= 150 and f <= 600 then
		-- Deterministic native-model flight, rather than an AI bombing-run test.
		-- The ordinary containment gadgets remain enabled throughout.
		for i, id in ipairs(aircraft) do
			local phase = ((f - 150 + (i - 1) * 35) % 180) / 180
			local x = r.x1 - 220 + (220 + bounds.margin * 0.7) * math.sin(math.pi * phase) ^ 2
			Spring.MoveCtrl.SetPosition(id, x, y, z - (i - 1) * 140)
			Spring.MoveCtrl.SetRotation(id, 0, phase < 0.5 and math.pi / 2 or -math.pi / 2, 0)
			if x > r.x1 then
				outsideAircraft = outsideAircraft + 1
			end
		end
		if f % 24 == 0 then
			Shot(r.x1 - 180, 4)
		end
		for id in pairs(shots) do
			local x, _, pz = Spring.GetProjectilePosition(id)
			if not x then
				shots[id] = nil
			elseif x > r.x1 and world.ContainsObject(1, x, pz) then
				outsideShots = outsideShots + 1
			end
		end
	elseif f == 620 then
		Check("aircraft_crossed_terrain_edge", outsideAircraft > 100)
		Check("projectiles_crossed_terrain_edge", outsideShots > 100)
		Spring.SetGameRulesParam("edge_test_done", 1)
	end
end
