local version = "v0.5"

function widget:GetInfo()
  return {
    name      = "Attack Command Helper",
    desc      = version .. " Filter out ground target from area attack when using Vamp (Vamp can only attack air)",
    author    = "msafwan",
    date      = "May 13, 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true -- loaded by default?
  }
end

--------------------------------------------------------------------------------
--Functions:
local CMD_ATTACK        	 = CMD.ATTACK

local vampName_gbl = "Vamp"

function widget:CommandNotify(id, params, options)	--ref: gui_tacticalCalculator.lua by xponen, and central_build_AI.lua by Troy H. Creek
	if (id == CMD_ATTACK) then
		local cx, cy, cz, cr = params[1], params[2], params[3], params[4]
		if (cr == nil) then return false end --skip the whole thing if player use a single-click (widget only accept area-attack)
		if (cx == nil or cy == nil or cz == nil) then return false end --skip whole thing if coordinate is nil (eg: issue command outside of map)
		--[[
		local xmin = cx-cr
		local xmax = cx+cr
		local zmin = cz-cr
		local zmax = cz+cr
		--]]
					
		local units	= Spring.GetSelectedUnits()
		if(units ~= nil) then
			for i=1, #units,1 do  --see if player select Vamp.
				local unitID = units[i]
				local unitDefID = Spring.GetUnitDefID(unitID)
				local unitDef = UnitDefs[unitDefID]
				if unitDef["humanName"] ~= vampName_gbl then return false end --skip whole thing if player didn't select Vamp exclusively (widget only active when player only select Vamp)
			end
			local selectedTeam =  Spring.GetUnitTeam(units[1]) --remember the ID for own team
			local selectedAlly = Spring.GetUnitAllyTeam(units[1]) -- remember the ID for own ally
			local targetUnits = ReturnAllAirUnits(cx, cz, cr, selectedTeam, selectedAlly)
			local success = IssueReplacementCommand (units, targetUnits, options)
			return success
		end
	end
	return false
end

function ReturnAllAirUnits(cx, cz, cr, selectedTeam, selectedAlly)
	local targetUnits = Spring.GetUnitsInCylinder(cx, cz, cr)
	local filteredTargets = {}
	for i=1, #targetUnits,1 do  --see if targets can fly and if they are enemy or ally.
		--local unitID = targetUnits[i]
		local enemyTeamID = Spring.GetUnitTeam(targetUnits[i])
		local enemyAllyID = Spring.GetUnitAllyTeam(targetUnits[i])
		if (enemyTeamID~=selectedTeam) and (selectedAlly ~= enemyAllyID) then --differenciate between selected unit, targeted units, and enemyteam. Filter out ally and owned units
			local unitDefID = Spring.GetUnitDefID(targetUnits[i]) 
			local unitDef = UnitDefs[unitDefID]
			if not unitDef then
				if GetDotsFloating(targetUnits[i]) then --check & remember floating radar dots in new table
					filteredTargets[(#filteredTargets or 0)+1] = targetUnits[i]
				end
			else
				if unitDef["canFly"] then --check & remember flying units in new table
					filteredTargets[(#filteredTargets or 0)+1] = targetUnits[i]
				end
			end
		end
	end	
	return filteredTargets
end

function IssueReplacementCommand (units, targetUnits, options)
	local replaceCommand= false
	if #targetUnits >= 1 then
		local attackCommandList = {}
		attackCommandList[1] = {CMD_ATTACK,{targetUnits[1],},{(options.shift and "shift"),}}
		local j = 2
		for i=2, #targetUnits, 1 do
			attackCommandList[j] = {CMD_ATTACK,{targetUnits[i],},{"shift",}}
			j= j + 1
		end
		Spring.GiveOrderArrayToUnitArray (units, attackCommandList)
		replaceCommand = true
	end
	return replaceCommand
end

function GetDotsFloating (unitID) --ref: gui_vertLineAid.lua by msafwan
	local x, y, z = Spring.GetUnitPosition(unitID)
	if x == nil then 
		return false
	end
	local isFloating = false
	local groundY = Spring.GetGroundHeight(x,z)
	local surfaceY = math.max (groundY, 0) --//select water, or select terrain height depending on which is higher. 
	if (y-surfaceY) >=200 then  --//mark unit as flying if it far above surface
		isFloating = true
	end
	return isFloating
end