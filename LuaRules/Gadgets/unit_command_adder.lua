--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Command Adder",
		desc      = "Adds engine commands to some units.",
		author    = "GoogleFrog",
		date      = "26 May 2019",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = false
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--SYNCED
if (not gadgetHandler:IsSyncedCode()) then
	return false
end
---------------------------------

include("LuaRules/Configs/customcmds.h.lua")

local fightCmdDesc = {
	id        = CMD.FIGHT,
	type      = CMDTYPE.ICON_FRONT,
	name      = 'Fight',
	action    = 'fight',
	tooltip   = "Fight: Order the unit to take action while moving to a position",
}

local patrolCmdDesc = {
	id        = CMD.PATROL,
	type      = CMDTYPE.ICON_MAP,
	name      = 'Patrol',
	action    = 'patrol',
	tooltip   = "Patrol: Order the unit to patrol to one or more waypoints",
}

local spInsertUnitCmdDesc = Spring.InsertUnitCmdDesc

local addUnitDefs = {}
local addedUnits = {}

local CMD_FIGHT = CMD.FIGHT
local CMD_PATROL = CMD.PATROL

for id, data in pairs(UnitDefs) do
	if data.customParams and (data.customParams.addfight or data.customParams.addpatrol) then
		addUnitDefs[id] = {
			addFight = data.customParams.addfight,
			addPatrol = data.customParams.addpatrol,
		}
	end
end

function gadget:CommandFallback(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if addedUnits[unitID] and (cmdID == CMD_FIGHT or cmdID == CMD_PATROL) then
		return true, false
	end
	return false
end

function gadget:Initialize()
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if addUnitDefs[unitDefID] then
		if addUnitDefs[unitDefID].addFight then
			spInsertUnitCmdDesc(unitID, fightCmdDesc)
		end
		if addUnitDefs[unitDefID].addPatrol then
			spInsertUnitCmdDesc(unitID, patrolCmdDesc)
		end
		addedUnits[unitID] = true
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	addedUnits[unitID] = nil
end
