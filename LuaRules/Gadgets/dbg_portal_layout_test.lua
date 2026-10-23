-- This file is part of the Spring engine (GPL v2 or later), see LICENSE.html
function gadget:GetInfo()
	return { name = "Portal arbitrary layout verification", layer = -100, enabled = true }
end
if not gadgetHandler:IsSyncedCode() or Spring.GetModOptions().zk_duels_test ~= "layout" then
	return false
end
local world = VFS.Include("LuaRules/Utilities/portal_worlds.lua")
local function Check(name, pass)
	Spring.Echo("[LAYOUT_TEST] ASSERT " .. name .. " pass=" .. tostring(not not pass))
end
function gadget:GameFrame(f)
	if f == 30 then
		Check("physical_size_matches", Game.mapSizeX == world.size[1] and Game.mapSizeZ == world.size[2])
		Check("region_count_matches", Spring.GetGameRulesParam("zkduels_regions") == #world.regions)
		for _, entry in ipairs(world.teams) do
			for _, id in ipairs(Spring.GetTeamUnits(entry.team)) do
				local x, _, z = Spring.GetUnitPosition(id)
				Check("team_home_" .. entry.team, world.Region(x, z) == entry.region)
			end
		end
		for i in ipairs(world.regions) do
			local last
			for _, entry in ipairs(world.teams) do
				if entry.region == i then
					last = entry.team
				end
			end
			for _, id in ipairs(Spring.GetTeamUnits(last)) do
				if UnitDefs[Spring.GetUnitDefID(id)].customParams.commtype then
					Spring.DestroyUnit(id, false, false)
					break
				end
			end
		end
	end
	if f == 120 then
		for i in ipairs(world.connections) do
			Check("open_edge_" .. i, GG.PortalWorlds.openEdges[i])
		end
		for a in ipairs(world.regions) do
			for b in ipairs(world.regions) do
				if a ~= b then
					Check("route_" .. a .. "_" .. b, world.Route(a, b, function(e)
						return GG.PortalWorlds.openEdges[e]
					end) ~= nil)
				end
			end
		end
	end
end
