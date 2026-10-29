--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Factory Copy Queue",
		desc      = "Adds a command for factories and plates to copy the build queue of another of the same type.",
		author    = "QrowZK",
		date      = "29 October 2026",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if not gadgetHandler:IsSyncedCode() then
	return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetFactoryCommands = Spring.GetFactoryCommands
local spGetUnitDefID       = Spring.GetUnitDefID
local spGetUnitStates      = Spring.GetUnitStates
local spGetUnitTeam        = Spring.GetUnitTeam
local spGiveOrderToUnit    = Spring.GiveOrderToUnit
local spInsertUnitCmdDesc  = Spring.InsertUnitCmdDesc
local spValidUnitID        = Spring.ValidUnitID

local CMD_REPEAT          = CMD.REPEAT
local CMD_COPY_QUEUE      = Spring.Utilities.CMD.COPY_QUEUE
local CMD_STOP_PRODUCTION = Spring.Utilities.CMD.STOP_PRODUCTION

-- Factories and plates that build the same units share a production line, keyed by the factory unitDefID.
local productionLine = {}
for i = 1, #UnitDefs do
	local cp = UnitDefs[i].customParams
	if cp.parent_of_plate then
		productionLine[i] = i
	elseif cp.child_of_factory then
		productionLine[i] = UnitDefNames[cp.child_of_factory].id
	end
end

local copyQueueCmdDesc = {
	id      = CMD_COPY_QUEUE,
	type    = CMDTYPE.ICON_UNIT,
	name    = 'Copy Queue',
	cursor  = 'facselect',
	action  = 'copyqueue',
	tooltip = 'Copy Factory Queue: Copy the build queue and repeat state of one of your factories or plates of the same type.',
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function CopyQueue(unitID, targetID, append)
	local commands = spGetFactoryCommands(targetID, -1)
	if not commands then
		return
	end

	if not append then
		spGiveOrderToUnit(unitID, CMD_STOP_PRODUCTION, 0, 0)
	end
	for i = 1, #commands do
		local cmdID = commands[i].id
		if cmdID < 0 then
			spGiveOrderToUnit(unitID, cmdID, 0, 0)
		end
	end

	local states = spGetUnitStates(targetID)
	if states then
		spGiveOrderToUnit(unitID, CMD_REPEAT, (states["repeat"] and 1) or 0, 0)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Handle the command

function gadget:AllowCommand_GetWantedCommand()
	return {[CMD_COPY_QUEUE] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return productionLine
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if cmdID ~= CMD_COPY_QUEUE or not productionLine[unitDefID] then
		return true
	end
	local targetID = cmdParams[1]
	if not targetID or targetID == unitID or not spValidUnitID(targetID) then
		return false
	end
	-- Only copy from your own factories, never an ally's.
	if spGetUnitTeam(targetID) ~= teamID or productionLine[spGetUnitDefID(targetID)] ~= productionLine[unitDefID] then
		return false
	end

	CopyQueue(unitID, targetID, cmdOptions.shift)
	return false -- Instant command, never queued.
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Add the command to factories and plates

function gadget:UnitCreated(unitID, unitDefID)
	if productionLine[unitDefID] then
		spInsertUnitCmdDesc(unitID, copyQueueCmdDesc)
	end
end

function gadget:Initialize()
	gadgetHandler:RegisterCMDID(CMD_COPY_QUEUE)
	Spring.SetCustomCommandDrawData(CMD_COPY_QUEUE, "FactorySelect", {0.2, 0.7, 1.0, 0.7})
	for _, unitID in pairs(Spring.GetAllUnits()) do
		gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID))
	end
end
