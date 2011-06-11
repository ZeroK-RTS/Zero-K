--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "ResetState",
    desc      = 'v2.01 Set hotkeys for "holdfire,stop" and "holdposition,stop" in the menu',
    author    = "CarRepairer",
    date      = "2009-01-27",
    license   = "GNU GPL, v2 or later",
    layer     = -1,
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
options_path = 'Game/Commands'

options_order = {'resetfire', 'resetmove', 'lblspace', }

options = {
	resetfire = {
		name = 'Hold Fire & Stop',
		desc = 'Set the unit to hold fire, then stop all commands.',
		type = 'button',
	},
	resetmove = {
		name = 'Hold Position & Stop',
		desc = 'Set the unit to hold position, then stop all commands.',
		type = 'button',
	},
	
	lblspace = { type = 'label', name = '', },
	
	
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options.resetfire.OnChange = function()
	local selUnits = spGetSelectedUnits()
	spGiveOrderToUnitArray(selUnits, CMD.FIRE_STATE, {0}, {}) 
	spGiveOrderToUnitArray(selUnits, CMD.STOP, {}, {})
	return true
end

options.resetmove.OnChange = function()
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
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
