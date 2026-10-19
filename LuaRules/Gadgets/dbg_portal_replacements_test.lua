-- This file is part of Zero-K (GPL v2 or later), see LICENSE.
function gadget:GetInfo()
	return { name = "Portal morph and upgrade regression", layer = -100, enabled = true }
end
if not gadgetHandler:IsSyncedCode() or Spring.GetModOptions().zk_duels_test ~= "replacements" then
	return false
end
local world = VFS.Include("LuaRules/Utilities/portal_worlds.lua")
local commanderTeam = world.teams[2].team
local sourceRegion = world.teams[2].region
local destinationRegion = sourceRegion == 1 and 2 or 1
local oldCommander, oldMorph, newCommander, newMorph, oldLevel
local checks, failures = 0, 0
local function Check(name, value)
	checks = checks + 1
	if not value then
		failures = failures + 1
	end
	Spring.Echo("[REPLACEMENTS_TEST] ASSERT " .. name .. " pass=" .. tostring(not not value))
end
local function UpgradeParams(id)
	local params = {
		Spring.GetUnitRulesParam(id, "comm_level"),
		Spring.GetUnitRulesParam(id, "comm_chassis"),
		Spring.GetUnitRulesParam(id, "comm_module_count"),
		1,
	}
	for i = 1, params[3] do
		params[#params + 1] = Spring.GetUnitRulesParam(id, "comm_module_" .. i)
	end
	local modules = VFS.Include("LuaRules/Configs/dynamic_comm_defs.lua")
	for module = 1, #modules do
		params[5 + params[3]] = module
		if GG.Upgrades_GetValidAndMorphAttributes(id, params) then
			return params
		end
	end
	error("No ordinary commander upgrade available")
end
function gadget:GameFrame(frame)
	if frame == 1 then
		for _, r in ipairs(world.regions) do
			Spring.LevelHeightMap(r.x0, r.z0, r.x1, r.z1, 200)
		end
		for _, id in ipairs(Spring.GetAllUnits()) do
			Spring.GiveOrderToUnit(id, CMD.FIRE_STATE, { 0 }, 0)
		end
	end
	if frame == 60 then
		for _, id in ipairs(Spring.GetTeamUnits(commanderTeam)) do
			if UnitDefs[Spring.GetUnitDefID(id)].customParams.commtype then
				oldCommander = id
				break
			end
		end
		assert(oldCommander, "No commander for upgrade fixture")
		local r = world.regions[destinationRegion]
		oldMorph = assert(Spring.CreateUnit("amphcon", r.x0 + 1200, 200, r.z0 + 1200, 0, world.teams[1].team))
		Spring.GiveOrderToUnit(oldMorph, CMD.FIRE_STATE, { 0 }, 0)
		Check("morph_source_is_away_from_team_home", GG.PortalWorlds.home[oldMorph] == destinationRegion)
		oldLevel = Spring.GetUnitRulesParam(oldCommander, "comm_level")
		local params = UpgradeParams(oldCommander)
		Check("upgrade_command_valid", GG.Upgrades_GetValidAndMorphAttributes(oldCommander, params))
		-- Accelerate progress only; use the normal command validation, resource
		-- bookkeeping, replacement creation and old-unit destruction paths.
		GG.SetFreeMorph(true)
		Spring.GiveOrderToUnit(oldCommander, Spring.Utilities.CMD.MORPH_UPGRADE_INTERNAL, params, 0)
		Spring.GiveOrderToUnit(
			oldMorph,
			GG.MorphInfo[UnitDefNames.amphcon.id][UnitDefNames.amphtele.id],
			{},
			0
		)
	end
	if frame == 150 then
		GG.SetFreeMorph(false)
		newCommander, newMorph = GG.wasMorphedTo[oldCommander], GG.wasMorphedTo[oldMorph]
		Check(
			"commander_replaced",
			newCommander and Spring.ValidUnitID(newCommander) and not Spring.ValidUnitID(oldCommander)
		)
		Check(
			"mobile_morph_replaced",
			newMorph and Spring.ValidUnitID(newMorph) and not Spring.ValidUnitID(oldMorph)
		)
		Check(
			"upgrade_level_increased",
			newCommander and Spring.GetUnitRulesParam(newCommander, "comm_level") == oldLevel + 1
		)
		Check("upgrade_keeps_region", newCommander and GG.PortalWorlds.home[newCommander] == sourceRegion)
		Check("morph_uses_physical_region", newMorph and GG.PortalWorlds.home[newMorph] == destinationRegion)
		Check("morph_keeps_owner", newMorph and Spring.GetUnitTeam(newMorph) == world.teams[1].team)
		Check("upgrade_does_not_open_portal", not next(GG.PortalWorlds.openEdges))
	end
	if frame == 180 then
		assert(newCommander, "Upgrade did not complete")
		Spring.DestroyUnit(newCommander, false, false)
	end
	if frame == 240 then
		local edge
		for i, connection in ipairs(world.connections) do
			if connection[1] == sourceRegion then
				edge = i
				break
			end
		end
		Check("real_upgraded_commander_loss_opens_portal", edge and GG.PortalWorlds.openEdges[edge])
		local unrelatedOpen = false
		for i, connection in ipairs(world.connections) do
			if connection[1] == destinationRegion and GG.PortalWorlds.openEdges[i] then
				unrelatedOpen = true
			end
		end
		Check("unrelated_morph_region_stays_closed", not unrelatedOpen)
		Spring.Echo("[REPLACEMENTS_TEST] DONE checks=" .. checks .. " failures=" .. failures)
	end
end
