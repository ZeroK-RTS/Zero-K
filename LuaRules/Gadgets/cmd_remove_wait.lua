if not gadgetHandler:IsSyncedCode() then
	return
end

function gadget:GetInfo()
	  return {
		name    = "Remove Wait",
		desc    = "Removes wait from structures that don't need the command and makes factory wait removal consistent with other units.",
		author  = "GoogleFrog",
		date    = "3 April 2015",
		license = "GNU GPL, v2 or later",
		layer   = 0,
		enabled = true,
	}
end

local spRemoveUnitCmdDesc  = Spring.RemoveUnitCmdDesc
local spFindUnitCmdDesc    = Spring.FindUnitCmdDesc
local spGetFactoryCommands = Spring.GetFactoryCommands
local CMD_WAIT = CMD.WAIT

local removeCommands = {
	CMD.WAIT,
	CMD.REPEAT,
}

local waitRemoveDefs = {}
local factoryDefs = {}
local handleDefs = {}
local stopRemoveDefs = {}
local antiRecursionWaitDo = false

for unitDefID = 1, #UnitDefs do
	local ud = UnitDefs[unitDefID]
	if ud.customParams and ud.customParams.removewait then
		waitRemoveDefs[unitDefID] = true
		handleDefs[unitDefID] = true
	end
	if ud.customParams and ud.customParams.removestop then
		stopRemoveDefs[unitDefID] = true
	end
	if ud.isFactory then
		factoryDefs[unitDefID] = true
		handleDefs[unitDefID] = true
	end
end

local function GetFactoryHasWait(unitID, unitDefID)
	local cQueue = spGetFactoryCommands(unitID, 1)
	return cQueue and cQueue[1] and (cQueue[1].id == CMD_WAIT)
end

function gadget:AllowCommand_GetWantedCommand()
	return true
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return handleDefs
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID == CMD_WAIT and waitRemoveDefs[unitDefID]) then
		return false
	end
	if cmdID >= 0 and cmdID ~= CMD_WAIT and factoryDefs[unitDefID] and not (cmdOptions.shift or cmdOptions.alt) then
		local hasWait = GetFactoryHasWait(unitID)
		if hasWait and not (antiRecursionWaitDo and antiRecursionWaitDo[unitID]) then
			antiRecursionWaitDo = antiRecursionWaitDo or {}
			antiRecursionWaitDo[unitID] = true
		end
	end
	return true
end

function gadget:GameFrame()
	if not antiRecursionWaitDo then
		return
	end

	for unitID, _ in pairs(antiRecursionWaitDo) do
		Spring.GiveOrderToUnit(unitID, CMD.WAIT, {}, {})
	end
	antiRecursionWaitDo = false
end

function gadget:UnitCreated(unitID, unitDefID)
	if waitRemoveDefs[unitDefID] then
		for i = 1, #removeCommands do
			local cmdDesc = spFindUnitCmdDesc(unitID, removeCommands[i])
			if cmdDesc then
				spRemoveUnitCmdDesc(unitID, cmdDesc)
			end
		end
	end
	if stopRemoveDefs[unitDefID] then
		local cmdDesc = spFindUnitCmdDesc(unitID, CMD.STOP)
		if cmdDesc then
			spRemoveUnitCmdDesc(unitID, cmdDesc)
		end
	end
end

function gadget:Initialize()
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID)
	end
end
