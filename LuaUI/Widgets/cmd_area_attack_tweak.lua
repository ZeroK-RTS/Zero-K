local version = "v1.1"

function widget:GetInfo()
  return {
    name      = "Area Attack Tweak",
    desc      = version .. " Tweak to area attack command:"..
				"\n• automatically filter out ground target for AA units."..
				"\n• CTRL+Attack split targets among units.",
    author    = "msafwan",
    date      = "May 22, 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true -- loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local reverseCompatibility = Game.version:find('91.') or (Game.version:find('94') and not Game.version:find('94.1.1'))

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
				local unitID = units[i]
				local unitDefID = Spring.GetUnitDefID(unitID)
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
						antiAirUnits[#antiAirUnits +1]= unitID 
					else
						normalUnits[#normalUnits +1]= unitID 
					end
				else
					normalUnits[#normalUnits +1]= unitID
				end
			end
			if #units >= 1 then --skip whole thing if no AA unit was selected (because player dont need widget to do normal attack command).
				local selectedAlly = Spring.GetUnitAllyTeam(units[1]) -- remember the ID for own ally
				local targetUnits
				if cz2 then
					targetUnits = Spring.GetUnitsInRectangle(math.min(cx,cx2), math.min(cz,cz2), math.max(cx,cx2), math.max(cz,cz2))
				else
					targetUnits = Spring.GetUnitsInCylinder(cx, cz, cr)
				end
				local airTargets, allTargets = ReturnAllAirTarget(targetUnits, selectedAlly,(#antiAirUnits>1)) -- get all air target for selected area-command
				if #allTargets>1 then
					if options.ctrl then
						--split between AA and ground, and split target between units
						IssueSplitedCommand(antiAirUnits,airTargets,options)
						IssueSplitedCommand(normalUnits,allTargets,options)
						return true --return true after widget issued a replacement command.
					else
						if #antiAirUnits>1 then
							--split between AA and ground
							IssueCommand(antiAirUnits,airTargets,options)
							IssueCommand(normalUnits,allTargets,options)
							return true
						else 
							-- See http://springrts.com/mantis/view.php?id=4351
							if reverseCompatibility then
								--let Spring handle
								return false
							else
								IssueCommand(normalUnits,allTargets,options)
								return true
							end
						end
					end
				end
			end
		end
	end
	return false
end
--------------------------------------------------------------------------------
function ReturnAllAirTarget(targetUnits, selectedAlly,checkAir)
	local filteredTargets = {}
	local nonFilteredTargets = {}
	for i=1, #targetUnits,1 do  --see if targets can fly and if they are enemy or ally.
		local unitID = targetUnits[i]
		local enemyAllyID = Spring.GetUnitAllyTeam(unitID)
		if (selectedAlly ~= enemyAllyID) then --differentiate between selected unit, targeted units, and enemyteam. Filter out ally and owned units
			if checkAir then
				local unitDefID = Spring.GetUnitDefID(unitID) 
				local unitDef = UnitDefs[unitDefID]
				if not unitDef then
					if GetDotsFloating(unitID) then --check & remember floating radar dots in new table.
						filteredTargets[#filteredTargets +1] = unitID
					end
				else
					if unitDef["canFly"] then --check & remember flying units in new table
						filteredTargets[#filteredTargets +1] = unitID
					end
				end
			end
			nonFilteredTargets[#nonFilteredTargets +1] = unitID --also copy all target to a non-filtered table
		end
	end	
	return filteredTargets, nonFilteredTargets
end

function IssueCommand(selectedUnits,allTargets,options)
	if #selectedUnits>=1 and #allTargets>=1 then
		local attackCommandListAll = PrepareCommandArray(allTargets, options,1)
		Spring.GiveOrderArrayToUnitArray (selectedUnits, attackCommandListAll)
	end
end

function IssueSplitedCommand(selectedUnits,allTargets,options)
	if #selectedUnits>=1 and #allTargets>=1 then
		for i=1, #selectedUnits do
			local attackCommandListAll = PrepareCommandArray(allTargets, options,i,true)
			Spring.GiveOrderArrayToUnitArray ({selectedUnits[i]}, attackCommandListAll)
		end
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

function PrepareCommandArray (targetUnits, options,indx,shuffle)
	indx = LoopAroundIndex(indx, #targetUnits)
	local stepSkip = 1
	if shuffle then
		stepSkip = (#targetUnits%(2))*-1 +3
		--stepSkip is 3 if #targetUnits is EVEN number (eg: 4,6,8), or 2 if  #targetUnits is ODD (eg: 3,5,7)
		--this will shuffle the target sequence appropriately
	end
	local attackCommandList = {}
	local j = 1
	attackCommandList[j] = {CMD.ATTACK,{targetUnits[indx],},{((options.shift and "shift") or nil),}}
	for i=1, #targetUnits-1, 1 do
		j= j + 1
		indx = indx + stepSkip --stepSkip>1 will shuffle the queue
		indx = LoopAroundIndex(indx, #targetUnits)
		attackCommandList[j] = {CMD.ATTACK,{targetUnits[indx],},{"shift",}}
	end
	return attackCommandList
end
--------------------------------------------------------------------------------
function LoopAroundIndex(indx, maxIndex)
	----
	-- Example:
	-- if maxIndex is 3 and input indx is 1,2,3,4,5,6
	-- the following 3 line of code will convert indx into: 1,2,3,1,2,3 (which will avoid "index out-of-bound" case)
	indx = indx - 1
	indx = indx%(maxIndex)
	indx = indx + 1
	-- also: if indx is (maxIndex + extraValue), then it would convert into: (1 + extraValue).
	return indx
end