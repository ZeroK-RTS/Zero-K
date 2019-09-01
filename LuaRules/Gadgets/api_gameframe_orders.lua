----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
function gadget:GetInfo()
	return {
		name    = "Gameframe Orders",
		desc    = "Delegates unit orders to GameFrame to avoid AllowCommand recursion",
		author  = "Histidine (L.J. Lim)",
		date    = "2018.05.20",
		license = "GNU GPL, v2 or later",
		layer   = math.huge,
		enabled = true,
	}
end
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
if gadgetHandler:IsSyncedCode() then
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

local commands = {} -- [1] = {unitID = id or array, cmdID = bla, params = bla, ...}
local commandCount = 0

local gh = gadgetHandler
local ghRemoveCallIn = gh.RemoveCallIn
local ghUpdateCallIn = gh.UpdateCallIn

local function ExecuteCommand(cmd)
	if type(cmd.unitID) == "table" then
		Spring.GiveOrderToUnitArray(cmd.unitID, cmd.cmdID, cmd.params, cmd.options)
	else
		Spring.GiveOrderToUnit(cmd.unitID, cmd.cmdID, cmd.params, cmd.options)
	end
end

function gadget:GameFrame(n)
	for i = 1, commandCount do
		local cmd = commands[i]
		local success, err = pcall(ExecuteCommand, cmd)
		if not success then
			Spring.Log(gadget:GetInfo().name, LOG.ERROR, err)
		end
		commands[i] = nil
	end

	commandCount = 0
	ghRemoveCallIn(gh, 'GameFrame')
end

local function DelegateOrder(unitID, cmdID, cmdParams, cmdOptions)
	if commandCount == 0 then
		ghUpdateCallIn(gh, 'GameFrame')
	end

	commandCount = commandCount + 1
	commands[commandCount] = {unitID = unitID, cmdID = cmdID, params = cmdParams, options = cmdOptions}
end
GG.DelegateOrder = DelegateOrder

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
else --UNSYNCED--
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

end
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
