--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Factory Stop Production",
		desc      = "Adds a command to clear the factory queue",
		author    = "GoogleFrog",
		date      = "13 November 2016",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
  return false  --  no unsynced code
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetFactoryCommands = Spring.GetFactoryCommands
local spGiveOrderToUnit    = Spring.GiveOrderToUnit
local spInsertUnitCmdDesc  = Spring.InsertUnitCmdDesc

local CMD_OPT_CTRL = CMD.OPT_CTRL
local CMD_REMOVE = CMD.REMOVE

include("LuaRules/Configs/customcmds.h.lua")

local isFactory = {}
for udid = 1, #UnitDefs do
	local ud = UnitDefs[udid]
	if ud.isFactory and not ud.customParams.notreallyafactory then
		isFactory[udid] = true
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local stopProductionCmdDesc = {
	id			= CMD_STOP_PRODUCTION,
	type		= CMDTYPE.ICON,
	name		= 'Stop Production',
	action	    = 'stopproduction',
	cursor      = 'Stop', -- Probably does nothing
	tooltip     = 'Clear the unit production queue.',
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Handle the command

function gadget:AllowCommand_GetWantedCommand()
	return {[CMD_STOP_PRODUCTION] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return isFactory
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID ~= CMD_STOP_PRODUCTION) or (not isFactory[unitDefID]) then
		return
	end

	local commands = spGetFactoryCommands(unitID, -1)
	if not commands then
		return
	end
	for i = 1, #commands do
		spGiveOrderToUnit(unitID, CMD_REMOVE, commands[i].tag, CMD_OPT_CTRL)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Add the command to factories

function gadget:UnitCreated(unitID, unitDefID)
	if isFactory[unitDefID] then
		spInsertUnitCmdDesc(unitID, stopProductionCmdDesc)
	end
end

function gadget:Initialize()
	gadgetHandler:RegisterCMDID(CMD_STOP_PRODUCTION)
	for _, unitID in pairs(Spring.GetAllUnits()) do
		gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID))
	end
end
