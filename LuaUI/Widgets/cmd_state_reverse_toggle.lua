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

local multiStates = {
  [CMD_FIRE_STATE] = 3,
  [CMD_MOVE_STATE] = 3,
  [CMD.AUTOREPAIRLEVEL] = 4,
}

function widget:CommandNotify(id, params, options)
	
	if multiStates[id] then
		if options.right then
			local units = spGetSelectedUnits()
			local state = params[1]
			
			state = state - 2	-- engine sent us one step forward instead of one step back, so we go two steps back
			if state < 0 then
			  state = multiStates[id] + state	-- wrap
			end
			for i=1, #units do
				spGiveOrderToUnit(units[i], id, { state }, {})	
			end
			return true
		end
	end	

end