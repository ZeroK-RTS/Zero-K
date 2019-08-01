
function gadget:GetInfo()
	return {
		name    = "Block Ally and Neutral Attack",
		desc    = "Blocks attack command from being issued on allies and neutrals.",
		author  = "GoogleFrog",
		date    = "29 July 2017",
		license = "GNU GPL, v2 or later",
		layer   = 0,
		enabled = true,
	}
end

include("LuaRules/Configs/customcmds.h.lua")
local allyTeamByTeam = {}
local teamList = Spring.GetTeamList()
for i = 1, #teamList do
	local allyTeamID = select(6, Spring.GetTeamInfo(teamList[i], false))
	allyTeamByTeam[teamList[i]] = allyTeamID
end

local CMD_ATTACK = CMD.ATTACK
local CMD_INSERT = CMD.INSERT

local allyTargetUnits = {
	[UnitDefNames["jumpsumo"].id] = true,
	[UnitDefNames["turretimpulse"].id] = true,
	[UnitDefNames["jumpblackhole"].id] = true,
	[UnitDefNames["amphlaunch"].id] = true,
}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
if gadgetHandler:IsSyncedCode() then -- SYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if allyTargetUnits[unitDefID] then
		return true
	end
	
	local targetID
	if cmdID == CMD_INSERT and cmdParams[2] == CMD_ATTACK and #cmdParams == 4 then
		targetID = cmdParams[4]
	end
	
	if cmdID == CMD_ATTACK and #cmdParams == 1 then
		targetID = cmdParams[1]
	end
	
	if not targetID then
		return true
	end
	
	if Spring.GetUnitNeutral(targetID) then
		if Spring.GetUnitRulesParam(targetID, "avoidAttackingNeutral") == 1 then
			return false
		end
		return true
	end
	
	local allyTeamID = Spring.GetUnitAllyTeam(targetID)
	if allyTeamID and allyTeamID == allyTeamByTeam[teamID] then
		return false
	end
	
	return true
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
else -- UNSYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:DefaultCommand(targetType, targetID)
	if (targetType == 'unit') and targetID and Spring.GetUnitNeutral(targetID) then
		if (Spring.GetUnitRulesParam(targetID, "avoidAttackingNeutral") == 1) or (Spring.GetUnitRulesParam(targetID, "avoidRightClickAttack") == 1) then
			return CMD_RAW_MOVE
		end
	end
end

end