--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "ResetState",
    desc      = "You can set keybindings for holdfire,stop (luaui reset firestate) and holdposition,stop (luaui reset movestate)",
    author    = "CarRepairer",
    date      = "2009-01-27",
    license   = "GNU GPL, v2 or later",
    layer     = -1,
    enabled   = true  --  loaded by default?
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

function widget:Initialize()
  if Spring.GetSpectatingState() or Spring.IsReplay() then
    widgetHandler:RemoveWidget()
    return true
  end
end

function widget:TextCommand(command)
	if (command == "reset firestate") then
		local selUnits = spGetSelectedUnits()
		spGiveOrderToUnitArray(selUnits, CMD.FIRE_STATE, {0}, {}) 
		spGiveOrderToUnitArray(selUnits, CMD.STOP, {}, {})
		return true
	elseif (command == "reset movestate") then
		local selUnits = spGetSelectedUnits()
		spGiveOrderToUnitArray(selUnits, CMD.MOVE_STATE, { 0 }, {})
		spGiveOrderToUnitArray(selUnits, CMD.STOP, {}, {})
	end
	return false
end   


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
