function widget:GetInfo()
	return {
		name      = "State Reverse Toggle",
		desc      = "Makes multinary states reverse toggleable",
		author    = "Google Frog",
		date      = "Oct 2, 2009",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

local spGetSelectedUnits = Spring.GetSelectedUnits
local spGiveOrderToUnit = Spring.GiveOrderToUnit

local CMD_FIRE_STATE = CMD.FIRE_STATE
local CMD_MOVE_STATE = CMD.MOVE_STATE

local removableStates = {
	[CMD_FIRE_STATE] = 1,
	[CMD_MOVE_STATE] = 2,
}

local multiStates = {
	[CMD_FIRE_STATE] = 3,
	[CMD_MOVE_STATE] = 3,
	[CMD.AUTOREPAIRLEVEL] = 4,
}

local function ReverseToggle(cmdID, state)
	local units = spGetSelectedUnits()
	
	state = state - 2 -- engine sent us one step forward instead of one step back, so we go two steps back
	if state < 0 then
		state = multiStates[cmdID] + state -- wrap
	end
	local paramTable = { state }
	for i = 1, #units do
		spGiveOrderToUnit(units[i], cmdID, paramTable, 0)
	end
end

function widget:CommandNotify(cmdID, params, options)
	if (WG.RemoveReturnFireState and cmdID == CMD_FIRE_STATE) or (WG.RemoveRoamState and cmdID == CMD_MOVE_STATE) then
		local state = params[1]
		if state == removableStates[cmdID] then
			ReverseToggle(cmdID, state)
			return true
		end
		return false
	end
	if multiStates[cmdID] then
		if options.right then
			ReverseToggle(cmdID, params[1])
			return true
		end
	end
end
