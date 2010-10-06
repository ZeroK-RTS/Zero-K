function widget:GetInfo()
  return {
    name      = "State Reverse Toggle",
    desc      = "Makes fire and movestates reverse toggleable",
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

function widget:CommandNotify(id, params, options)
	
	if id == CMD_FIRE_STATE then
		if options.right then
			local units = spGetSelectedUnits()
			local state = params[1] 
			if state == 0 then 
				state = 1
			elseif state == 1 then 
				state = 2
			else 
				state = 0
			end
			for v,sid in ipairs(units) do
				spGiveOrderToUnit(sid, CMD_FIRE_STATE, { state }, {})	
			end
			return true
		end
	end	
	
	if id == CMD_MOVE_STATE then
		if options.right then
			local units = spGetSelectedUnits()
			local state = params[1]
			if state == 0 then 
				state = 1
			elseif state == 1 then 
				state = 2
			else 
				state = 0
			end
			for v,sid in ipairs(units) do
				spGiveOrderToUnit(sid, CMD_MOVE_STATE, { state }, {})	
			end
			return true
		end
	end

end