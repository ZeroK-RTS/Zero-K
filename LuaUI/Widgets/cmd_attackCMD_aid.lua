local version = "v0.7"

function widget:GetInfo()
  return {
    name      = "AA Command Helper",
    desc      = version .. " Filter out ground target from area attack when using AA unit",
    author    = "msafwan",
    date      = "May 16, 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true -- loaded by default?
  }
end

--------------------------------------------------------------------------------
--Functions:
local CMD_ATTACK        	 = CMD.ATTACK

--local vampName_gbl = "Vamp"
--------------------------------------------------------------------------------
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
		local antiAirUnits = {}
		local normalUnits = {}
		if(units ~= nil) then
			for i=1, #units,1 do  --see if player select Vamp.
				local unitID = units[i]
				local unitDefID = Spring.GetUnitDefID(unitID)
				local unitDef_primaryWeapon_target = UnitDefs[unitDefID].weapons[1].onlyTargets
				local exclusiveAA = (unitDef_primaryWeapon_target["fixedwing"] and unitDef_primaryWeapon_target["gunship"]) and 
									not (unitDef_primaryWeapon_target["sink"] or unitDef_primaryWeapon_target["land"] or unitDef_primaryWeapon_target["sub"])
				--if unitDef["humanName"] ~= vampName_gbl then return false end --skip whole thing if player didn't select Vamp exclusively (widget only active when player only select Vamp)

				--[[
				Spring.Echo(UnitDefs[unitDefID].weapons[1].onlyTargets)
				for name,content in pairs(UnitDefs[unitDefID].weapons[1].onlyTargets) do
					Spring.Echo(name)
					Spring.Echo(content)
				end
				--]]
				if (exclusiveAA) then 
					antiAirUnits[(#antiAirUnits or 0) +1]= unitID 
				else
					normalUnits[(#normalUnits or 0) +1]= unitID 
				end
			end
			if #antiAirUnits == 0 then return false end --skip whole thing if no AA unit was selected (because player dont need widget to do normal attack command).
			local selectedTeam =  Spring.GetUnitTeam(units[1]) --remember the ID for own team
			local selectedAlly = Spring.GetUnitAllyTeam(units[1]) -- remember the ID for own ally
			local airTargets, allTargets = ReturnAllAirTarget(cx, cz, cr, selectedTeam, selectedAlly) -- get all air target for selected area-command
			local success = IssueReplacementCommand (antiAirUnits, airTargets, options, normalUnits,allTargets)
			return success --return true if widget issued a replacement command.
		end
	end
	return false
end
--------------------------------------------------------------------------------
function ReturnAllAirTarget(cx, cz, cr, selectedTeam, selectedAlly)
	local targetUnits = Spring.GetUnitsInCylinder(cx, cz, cr)
	local filteredTargets = {}
	local nonFilteredTargets = {}
	for i=1, #targetUnits,1 do  --see if targets can fly and if they are enemy or ally.
		--local unitID = targetUnits[i]
		local enemyTeamID = Spring.GetUnitTeam(targetUnits[i])
		local enemyAllyID = Spring.GetUnitAllyTeam(targetUnits[i])
		if (enemyTeamID~=selectedTeam) and (selectedAlly ~= enemyAllyID) then --differenciate between selected unit, targeted units, and enemyteam. Filter out ally and owned units
			local unitDefID = Spring.GetUnitDefID(targetUnits[i]) 
			local unitDef = UnitDefs[unitDefID]
			if not unitDef then
				if GetDotsFloating(targetUnits[i]) then --check & remember floating radar dots in new table.
					filteredTargets[(#filteredTargets or 0)+1] = targetUnits[i]
				end
			else
				if unitDef["canFly"] then --check & remember flying units in new table
					filteredTargets[(#filteredTargets or 0)+1] = targetUnits[i]
				end
			end
			nonFilteredTargets[(#nonFilteredTargets or 0)+1] = targetUnits[i] --also copy all target to a non-filtered table
		end
	end	
	return filteredTargets, nonFilteredTargets
end

function IssueReplacementCommand (antiAirUnits, airTargets, options, normalUnits,allTargets)
	local replaceCommand= false
	if #airTargets >= 1 then
		local attackCommandList = PrepareCommandArray(airTargets, options)
		Spring.GiveOrderArrayToUnitArray (antiAirUnits, attackCommandList)
		replaceCommand = true
	end
	if #allTargets >= 1 then
		local attackCommandList = PrepareCommandArray(allTargets, options)
		Spring.GiveOrderArrayToUnitArray (normalUnits, attackCommandList)
		replaceCommand = true
	end
	return replaceCommand
end
--------------------------------------------------------------------------------
function GetDotsFloating (unitID) --ref: gui_vertLineAid.lua by msafwan
	local x, y, z = Spring.GetUnitPosition(unitID)
	if x == nil then 
		return false
	end
	local isFloating = false
	local groundY = Spring.GetGroundHeight(x,z)
	local surfaceY = math.max (groundY, 0) --//select water, or select terrain height depending on which is higher. 
	if (y-surfaceY) >= 100 then  --//mark unit as flying if it appears to float far above surface, if this fail then player can force attack it with single-(non-area)-attack or scout its ID first.
		isFloating = true
	end
	return isFloating
end

function PrepareCommandArray (targetUnits, options)
	local attackCommandList = {}
	attackCommandList[1] = {CMD_ATTACK,{targetUnits[1],},{(options.shift and "shift"),}}
	local j = 2
	for i=2, #targetUnits, 1 do
		attackCommandList[j] = {CMD_ATTACK,{targetUnits[i],},{"shift",}}
		j= j + 1
	end
	return attackCommandList
end