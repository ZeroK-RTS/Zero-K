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


local unitsWithWeakTargetLink = {}

local function isValidType(ud)
	return ud and not (ud.isBomber or ud.isFactory)
end

local function isValidUnit(unitID)
	local unitDefID = Spring.GetUnitDefID(unitID)
	if unitDefID and Spring.ValidUnitID(unitID) then
		local ud = UnitDefs[unitDefID]
		return ud and not (ud.isBomber or ud.isFactory)
	end
	return false
end

function widget:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdTag, cmdParams, cmdOpts)
	
end

function widget:CommandNotify(id, params, options)  	
	if (options.internal) then return false end
	
	local units = Spring.GetSelectedUnits()
	for i = 1, #units do
		local unitID = units[i]			
		local qq = Spring.GetUnitCommands(unitID)
		if (#qq>0) then Spring.Echo(qq[1].tag)
		Spring.Echo()
	end
		
	if id == CMD.ATTACK then
		local units = Spring.GetSelectedUnits()
		for i = 1, #units do
			local unitID = units[i]			
			if isValidUnit(unitID) then
				if #params == 1 then					
					--Spring.GiveOrderToUnit(unitID,CMD_UNIT_SET_TARGET,params,{CMD.OPT_INTERNAL})
					--Spring.GiveOrderToUnit(UnitID,CMD.INSERT,
					--	{,CMD_UNIT_SET_TARGET, {CMD.OPT_SHIFT,CMD.OPT_INTERNAL}, params},{unitID})
					--unitsWithWeakTargetLink[unitID] = true
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