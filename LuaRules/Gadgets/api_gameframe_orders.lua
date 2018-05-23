----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
function gadget:GetInfo()
	return {
		name 	= "Gameframe Orders",
		desc	= "Delegates unit orders to GameFrame to avoid AllowCommand recursion",
		author	= "Histidine (L.J. Lim)",
		date	= "2018.05.20",
		license	= "GNU GPL, v2 or later",
		layer	= math.huge,
		enabled = true,
	}
end
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
if gadgetHandler:IsSyncedCode() then
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

local commands = {}	-- [1] = {unitID = id or array, cmdID = bla, params = bla, ...}

local function ExecuteCommand(cmd)
	if type(cmd.unitID) == "table" then
		Spring.GiveOrderToUnitArray(cmd.unitID, cmd.cmdID, cmd.params, cmd.options)
	else
		Spring.GiveOrderToUnit(cmd.unitID, cmd.cmdID, cmd.params, cmd.options)
	end
end

function gadget:GameFrame(n)
	for i=1,#commands do
		local cmd = commands[i]
		local success, err = pcall(ExecuteCommand, cmd)
		if not success then
			Spring.Log(gadget:GetInfo().name, LOG.ERROR, err)
		end
		commands[i] = nil
	end
end

local function DelegateOrder(unitID, cmdID, cmdParams, cmdOptions)
	commands[#commands + 1] = {unitID = unitID, cmdID = cmdID, params = cmdParams, options = cmdOptions}
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