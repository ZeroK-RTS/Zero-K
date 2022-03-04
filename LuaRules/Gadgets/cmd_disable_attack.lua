
function gadget:GetInfo()
	return {
		name      = "Disable attack command",
		desc      = "Implements disable attack command",
		author    = "Google Frog",
		date      = "12 Janurary 2018",
		license   = "GNU GPL, v2 or later",
		layer     = -1,
		enabled   = true  --  loaded by default?
	}
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local attackDisabableUnitTypes = {}

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.customParams.can_disable_attack then
		attackDisabableUnitTypes[i] = true
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- SYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

include("LuaRules/Configs/customcmds.h.lua")
local spFindUnitCmdDesc     = Spring.FindUnitCmdDesc
local spEditUnitCmdDesc     = Spring.EditUnitCmdDesc
local spInsertUnitCmdDesc   = Spring.InsertUnitCmdDesc

local unitBlockAttackCmd = {
	id      = CMD_DISABLE_ATTACK,
	type    = CMDTYPE.ICON_MODE,
	name    = 'Disable Attack',
	action  = 'disableattack',
	tooltip = 'Allow attack commands',
	params  = {0, 'Allowed','Blocked'}
}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local attackDisabledUnits = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Command Handling

local function SetIsAttackDisabled(unitID, cmdParams)
	if attackDisabledUnits[unitID] then
		local state = cmdParams[1]
		local cmdDescID = spFindUnitCmdDesc(unitID, CMD_DISABLE_ATTACK)
		
		if (cmdDescID) then
			unitBlockAttackCmd.params[1] = state
			spEditUnitCmdDesc(unitID, cmdDescID, { params = unitBlockAttackCmd.params})
		end
		attackDisabledUnits[unitID] = state
	end
end

function gadget:AllowCommand_GetWantedCommand()
	return {
		[CMD_DISABLE_ATTACK] = true,
	}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	local wanted = {}
	for unitID, _ in pairs(attackDisabableUnitTypes) do
		wanted[unitID] = true
	end
	return wanted
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID ~= CMD_DISABLE_ATTACK) then
		return true  -- command was not used
	end
	SetIsAttackDisabled(unitID, cmdParams)
	return false  -- command was used
end

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Unit Handler

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if attackDisabableUnitTypes[unitDefID] then
		unitBlockAttackCmd.params[1] = 0
		spInsertUnitCmdDesc(unitID, unitBlockAttackCmd)
		attackDisabledUnits[unitID] = 0
	end
end

function gadget:UnitDestroyed(unitID, unitDefID)
	attackDisabledUnits[unitID] = false
end

local externalFunc = {}
function externalFunc.IsAttackDisabled(unitID)
	return unitID and attackDisabledUnits[unitID] == 1
end

function gadget:Initialize()
	-- register command
	gadgetHandler:RegisterCMDID(CMD_DISABLE_ATTACK)
	
	for _, unitID in pairs(Spring.GetAllUnits()) do
		gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID), Spring.GetUnitTeam(unitID))
	end

	GG.DisableAttack = externalFunc
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
end
