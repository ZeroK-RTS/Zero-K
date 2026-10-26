-- This file is part of the Spring engine (GPL v2 or later), see LICENSE.html
function gadget:GetInfo()
	return { name = "Portal combat rendering fixture", layer = -100, enabled = true }
end
if not gadgetHandler:IsSyncedCode() or Spring.GetModOptions().zk_duels_test ~= "combat" then
	return false
end
local world = VFS.Include("LuaRules/Utilities/portal_worlds.lua")
local targets, hits = {}, {}
local setups = {
	{ "vehraid", 0.27, 0.27, 130 },
	{ "striderdante", 0.7, 0.27, 260 },
	{ "turretlaser", 0.27, 0.7, 300 },
	{ "gunshipskirm", 0.7, 0.7, 300 },
}
local function Spawn(name, x, z, team)
	local id = Spring.CreateUnit(name, x, Spring.GetGroundHeight(x, z), z, 0, team)
	assert(id, "Missing combat fixture " .. name)
	Spring.GiveOrderToUnit(id, CMD.FIRE_STATE, { 0 }, 0)
	Spring.GiveOrderToUnit(id, CMD.MOVE_STATE, { 0 }, 0)
	return id
end
function gadget:UnitPreDamaged(id, def, team, damage)
	local info = targets[id]
	if info then
		hits[info] = (hits[info] or 0) + 1
		return 0, 0
	end
	return damage
end
function gadget:GameFrame(f)
	if f == 1 then
		-- Rendering fixture: reveal opponents in every region to the capture player.
		for _, ally in ipairs(Spring.GetAllyTeamList()) do
			Spring.SetGlobalLos(ally, true)
		end
		for _, id in ipairs(Spring.GetAllUnits()) do
			Spring.GiveOrderToUnit(id, CMD.FIRE_STATE, { 0 }, 0)
			Spring.GiveOrderToUnit(id, CMD.MOVE_STATE, { 0 }, 0)
		end
	end
	if f == 30 then
		for region in ipairs(world.regions) do
			local team = world.teams[region * 2].team
			for _, id in ipairs(Spring.GetTeamUnits(team)) do
				if UnitDefs[Spring.GetUnitDefID(id)].customParams.commtype then
					Spring.DestroyUnit(id, false, false)
					break
				end
			end
		end
	end
	if f == 120 then
		for region, r in ipairs(world.regions) do
			for kind, setup in ipairs(setups) do
				local x, z = r.x0 + r.width * setup[2], r.z0 + r.height * setup[3]
				local y = math.max(40, Spring.GetGroundHeight(x, z))
				-- Give each weapon a clear test lane. These small flat pads exist
				-- only in this opt-in fixture, never in ordinary matches.
				Spring.SetHeightMapFunc(function()
					for sx = math.floor((x - 100) / 8) * 8, math.ceil((x + setup[4] + 100) / 8) * 8, 8 do
						for sz = math.floor((z - 100) / 8) * 8, math.ceil((z + 100) / 8) * 8, 8 do
							Spring.SetHeightMap(sx, sz, y)
						end
					end
				end)
				local source = Spawn(setup[1], x, z, (region - 1) * 2)
				local target = Spawn("energysolar", x + setup[4], z, (region % #world.regions) * 2)
				targets[target] = region .. "_" .. kind
				Spring.SetUnitHealth(target, 100000)
				Spring.GiveOrderToUnit(source, CMD.FIRE_STATE, { 2 }, 0)
				Spring.GiveOrderToUnit(source, CMD.ATTACK, { target }, 0)
			end
		end
	end
	if f == 900 then
		for region in ipairs(world.regions) do
			for kind in ipairs(setups) do
				local key = region .. "_" .. kind
				Spring.Echo(
					"[COMBAT_TEST] ASSERT hits_"
						.. key
						.. " pass="
						.. tostring((hits[key] or 0) > 0)
						.. " hits="
						.. (hits[key] or 0)
				)
			end
		end
	end
end
