--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "ResetState",
    desc      = 'v2.00 Set hotkeys for "holdfire,stop" and "holdposition,stop" in the menu',
    author    = "CarRepairer",
    date      = "2009-01-27",
    license   = "GNU GPL, v2 or later",
    layer     = -1,
    handler   = true,
    enabled   = true,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Speedups
local spGiveOrderToUnit  		= Spring.GiveOrderToUnit
local spGiveOrderToUnitArray  	= Spring.GiveOrderToUnitArray
local spGetSelectedUnits 		= Spring.GetSelectedUnits

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
options_path = 'Game/Hotkeys/Commands'

options_order = {'resetfire', 'resetmove', 'lblspace', }

options = {
	resetfire = {
		name = 'Hold Fire & Stop',
		desc = 'Set the unit to hold fire, then stop all commands.',
		type = 'button',
		action = 'reset_firestate',
	},
	resetmove = {
		name = 'Hold Position & Stop',
		desc = 'Set the unit to hold position, then stop all commands.',
		type = 'button',
		action = 'reset_movestate',
	},
	
	lblspace = { type = 'label', name = '', },
	
	
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


-- Adding functions because of "handler=true"
local function AddAction(cmd, func, data, types)
	return widgetHandler.actionHandler:AddAction(widget, cmd, func, data, types)
end
local function RemoveAction(cmd, types)
	return widgetHandler.actionHandler:RemoveAction(widget, cmd, types)
end

function ResetFireState()
	local selUnits = spGetSelectedUnits()
	spGiveOrderToUnitArray(selUnits, CMD.FIRE_STATE, {0}, {}) 
	spGiveOrderToUnitArray(selUnits, CMD.STOP, {}, {})
	return true
end

function ResetMoveState()
	local selUnits = spGetSelectedUnits()
	spGiveOrderToUnitArray(selUnits, CMD.MOVE_STATE, { 0 }, {})
	spGiveOrderToUnitArray(selUnits, CMD.STOP, {}, {})
	return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	if Spring.GetSpectatingState() or Spring.IsReplay() then
		widgetHandler:RemoveWidget()
		return true
	end

	AddAction("reset_firestate", ResetFireState, nil, "t")
	AddAction("reset_movestate", ResetMoveState, nil, "t")
	
end

function widget:Shutdown()
	RemoveAction("reset_firestate")
	RemoveAction("reset_movestate")
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
