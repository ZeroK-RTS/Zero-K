local version = "v0.9"

function widget:GetInfo()
  return {
    name      = "AA Command Helper",
    desc      = version .. " Filter out ground target from area attack when using AA unit",
    author    = "msafwan",
    date      = "May 22, 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true -- loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:CommandNotify(id, params, options)	--ref: gui_tacticalCalculator.lua by msafwan, and central_build_AI.lua by Troy H. Creek
	if (id == CMD.ATTACK) then
		local cx, cy, cz, cr = params[1], params[2], params[3], params[4]
		if (cr == nil) then return false end --skip the whole thing if player use a single-click (widget only accept area-attack)
		if (cx == nil or cy == nil or cz == nil) then return false end --skip whole thing if coordinate was nil (eg: issue command outside of map)
		local cx2, cy2, cz2 = params[4], params[5], params[6]
		local units	= Spring.GetSelectedUnits()
		local antiAirUnits = {}
		local normalUnits = {}
		if(units ~= nil) then
			for i=1, #units,1 do  --catalog AA and non-AA
				-- Note: unitID = units[i]
				local unitDefID = Spring.GetUnitDefID(units[i])
				local unitDef_primaryWeapon = UnitDefs[unitDefID].weapons[1]
				if (unitDef_primaryWeapon~= nil) then
					local primaryWeapon_target = UnitDefs[unitDefID].weapons[1].onlyTargets
					local exclusiveAA = (primaryWeapon_target["fixedwing"] and primaryWeapon_target["gunship"]) and 
										not (primaryWeapon_target["sink"] or primaryWeapon_target["land"] or primaryWeapon_target["sub"])
					--[[
					Spring.Echo(UnitDefs[unitDefID].weapons[1].onlyTargets)
					for name,content in pairs(UnitDefs[unitDefID].weapons[1].onlyTargets) do
						Spring.Echo(name)
						Spring.Echo(content)
					end
					--]]
					if (exclusiveAA) then 
						antiAirUnits[#antiAirUnits +1]= units[i] 
					else
						normalUnits[#normalUnits +1]= units[i] 
					end
				else
					normalUnits[#normalUnits +1]= units[i]
				end
			end
			if #antiAirUnits == 0 then return false end --skip whole thing if no AA unit was selected (because player dont need widget to do normal attack command).
			local selectedTeam =  Spring.GetUnitTeam(units[1]) --remember the ID for own team
			local selectedAlly = Spring.GetUnitAllyTeam(units[1]) -- remember the ID for own ally
			local targetUnits
			if cz2 then
				targetUnits = Spring.GetUnitsInRectangle(math.min(cx,cx2), math.min(cz,cz2), math.max(cx,cx2), math.max(cz,cz2))
			else
				targetUnits = Spring.GetUnitsInCylinder(cx, cz, cr)
			end
			local airTargets, allTargets = ReturnAllAirTarget(targetUnits, selectedTeam, selectedAlly) -- get all air target for selected area-command
			IssueReplacementCommand (antiAirUnits, airTargets, options, normalUnits,allTargets)
			return true --return true after widget issued a replacement command.
		end
	end
	return false
end
--------------------------------------------------------------------------------
function ReturnAllAirTarget(targetUnits, selectedTeam, selectedAlly)

	local filteredTargets = {}
	local nonFilteredTargets = {}
	for i=1, #targetUnits,1 do  --see if targets can fly and if they are enemy or ally.
		--note: unitID == targetUnits[i]
		local enemyTeamID = Spring.GetUnitTeam(targetUnits[i])
		local enemyAllyID = Spring.GetUnitAllyTeam(targetUnits[i])
		if (enemyTeamID~=selectedTeam) and (selectedAlly ~= enemyAllyID) then --differenciate between selected unit, targeted units, and enemyteam. Filter out ally and owned units
			local unitDefID = Spring.GetUnitDefID(targetUnits[i]) 
			local unitDef = UnitDefs[unitDefID]
			if not unitDef then
				if GetDotsFloating(targetUnits[i]) then --check & remember floating radar dots in new table.
					filteredTargets[#filteredTargets +1] = targetUnits[i]
				end
			else
				if unitDef["canFly"] then --check & remember flying units in new table
					filteredTargets[#filteredTargets +1] = targetUnits[i]
				end
			end
			nonFilteredTargets[#nonFilteredTargets +1] = targetUnits[i] --also copy all target to a non-filtered table
		end
	end	
	return filteredTargets, nonFilteredTargets
end

function IssueReplacementCommand (antiAirUnits, airTargets, options, normalUnits,allTargets)
	if #antiAirUnits>=1 and #airTargets>=1 then
		local attackCommandListAir = PrepareCommandArray(airTargets, options)
		Spring.GiveOrderArrayToUnitArray (antiAirUnits, attackCommandListAir)
	end
	if #normalUnits>=1 and #allTargets>=1 then
		local attackCommandListAll = PrepareCommandArray(allTargets, options)
		Spring.GiveOrderArrayToUnitArray (normalUnits, attackCommandListAll)
	end
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
	attackCommandList[1] = {CMD.ATTACK,{targetUnits[1],},{((options.shift and "shift") or nil),}}
	local j = 2
	for i=2, #targetUnits, 1 do
		attackCommandList[j] = {CMD.ATTACK,{targetUnits[i],},{"shift",}}
		j= j + 1
	end
	return attackCommandList
end