function widget:GetInfo()
  return {
    name      = "Keep Target",
    desc      = "Simple and slowest usage of target on the move",
    author    = "Google Frog, Klon",
    date      = "3 Jul 2015",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

local CMD_UNIT_SET_TARGET = 34923
local CMD_UNIT_CANCEL_TARGET = 34924

local unitsWithWeakTargetLink = {}

local function isValidType(ud)
	return ud and not (ud.isBomber or ud.isFactory)
end

function widget:CommandNotify(id, params, options)  
	if id == CMD.SET_WANTED_MAX_SPEED then
        return false -- FUCK CMD.SET_WANTED_MAX_SPEED what?
    end
	if id == CMD.ATTACK then
		local units = Spring.GetSelectedUnits()
		for i = 1, #units do
			local unitID = units[i]
			local unitDefID = Spring.GetUnitDefID(unitID)
			local ud = UnitDefs[unitDefID]
			if isValidType(ud) and Spring.ValidUnitID(unitID) then
				if #params == 1 and not options.internal then
					Spring.GiveOrderToUnit(unitID,CMD_UNIT_SET_TARGET,params,{})
					unitsWithWeakTargetLink[unitID] = true
				end
			end
		end
	elseif id == CMD.STOP or id == CMD.FIGHT then
		local units = Spring.GetSelectedUnits()
        for i = 1, #units do
            local unitID = units[i]
			if (unitsWithWeakTargetLink[unitID]) then 
				local unitDefID = Spring.GetUnitDefID(unitID)
				local ud = UnitDefs[unitDefID]
				if isValidType(ud) and Spring.ValidUnitID(unitID) then				
					Spring.GiveOrderToUnit(unitID,CMD_UNIT_CANCEL_TARGET,params,{})
					unitsWithWeakTargetLink[unitID] = nil
				end
			end
		end
	elseif id == CMD_UNIT_SET_TARGET or id == CMD_UNIT_CANCEL_TARGET then    
		local units = Spring.GetSelectedUnits()
        for i = 1, #units do
            local unitID = units[i]
			if (unitsWithWeakTargetLink[unitID]) then 
				local unitDefID = Spring.GetUnitDefID(unitID)
				local ud = UnitDefs[unitDefID]
				if isValidType(ud) and Spring.ValidUnitID(unitID) then					
					unitsWithWeakTargetLink[unitID] = nil
				end
			end
		end	
	end	
    return false
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
	if (unitsWithWeakTargetLink[unitID]) then unitsWithWeakTargetLink[unitID] = nil end
end