local version = "v1.121"

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

VFS.Include("LuaRules/Configs/customcmds.h.lua")

local defaultCommands = {
	[CMD.ATTACK] = true,
	[CMD.AREA_ATTACK] = true,
	[CMD.FIGHT] = true,
	[CMD.PATROL] = true,
	[CMD.GUARD] = true,
	[CMD.MANUALFIRE] = true,
	[CMD_REARM] = true,
	[CMD_FIND_PAD] = true,
	[CMD.MOVE] = true,
	[CMD_UNIT_SET_TARGET] = true,
	[CMD_UNIT_SET_TARGET_CIRCLE] = true,
	-- [CMD.REMOVE] = true,
	-- [CMD.INSERT] = true,
}

local unitsSplitAttackQueue = {nil} --just in case user press SHIFT after doing split attack, we need to remove these queue
local handledCount = 0

function widget:CommandNotify(id, params, options) --ref: gui_tacticalCalculator.lua by msafwan, and central_build_AI.lua by Troy H. Creek
	if not defaultCommands[id] or options.internal then --only process user's command
		return false
	end
	if Spring.GetSelectedUnitsCount() == 0 then --skip whole thing if no selection
		return false
	end
	local units
	if handledCount > 0 then
		 --This remove all but 1st attack order from CTRL+Area_attack if user choose to append new order to unit (eg: SHIFT+move),
		 --this is to be consistent with bomber_command (rearm-able bombers), which only shoot 1st target and move on to next order.
		 
		 --Known limitation: not able to remove order if user queued faster than network delay (it need to see unit's current command queue)
		units = Spring.GetSelectedUnits()
		local unitID,attackList
		for i=1,#units do
			unitID = units[i]
			attackList = GetAndRemoveHandledHistory(unitID)
			if attackList and options.shift then
				RevertAllButOneAttackQueue(unitID,attackList)
			end
		end
	end
	
	if (id == CMD.ATTACK or id == CMD_UNIT_SET_TARGET or id == CMD_UNIT_SET_TARGET_CIRCLE) then
		local cx, cy, cz, cr = params[1], params[2], params[3], params[4]
		if (cr == nil) then --not area command
			return false 
		end
		if (cx == nil or cy == nil or cz == nil) then --outside of map
			return false 
		end
		--The following code filter out ground unit from dedicated AA, and
		--split target among selected unit if user press CTRL+Area_attack
		local cx2, cy2, cz2 = params[4], params[5], params[6]
		units = units or Spring.GetSelectedUnits()
		local targetUnits
		if cz2 then
			targetUnits = Spring.GetUnitsInRectangle(math.min(cx,cx2), math.min(cz,cz2), math.max(cx,cx2), math.max(cz,cz2))
		else
			targetUnits = Spring.GetUnitsInCylinder(cx, cz, cr)
		end
		local antiAirUnits,normalUnits = GetAAUnitList(units)
		local airTargets, allTargets = ReturnAllAirTarget(targetUnits, Spring.GetUnitAllyTeam(units[1]),(#antiAirUnits>1)) -- get all air target for selected area-command
		if #allTargets>0 then --skip if no target
			return ReIssueCommandsToUnits(antiAirUnits,airTargets,normalUnits,allTargets,id,options)
		end
	end
	return false
end

function widget:UnitGiven(unitID)
	GetAndRemoveHandledHistory(unitID)
end

function widget:UnitDestroyed(unitID)
	GetAndRemoveHandledHistory(unitID)
end
--------------------------------------------------------------------------------
function GetAndRemoveHandledHistory(unitID)
	if unitsSplitAttackQueue[unitID] then
		local attackList = unitsSplitAttackQueue[unitID]
		unitsSplitAttackQueue[unitID] = nil
		handledCount = handledCount - 1
		return attackList
	end
	return nil
end

function RevertAllButOneAttackQueue(unitID,attackList)
	local queue = Spring.GetUnitCommands(unitID, -1)
	if queue then
		local toRemoveCount = 0
		local queueToRemove = {}
		for j=1,#queue do
			command = queue[j]
			if command.id == CMD.ATTACK and  attackList[command.params[1] ] then
				if toRemoveCount > 0 then --skip first queue
					queueToRemove[toRemoveCount] = command.tag
				end
				toRemoveCount = toRemoveCount + 1
			end
		end
		Spring.GiveOrderToUnit (unitID,CMD.REMOVE, queueToRemove,{})
	end
end

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

function GetAAUnitList(units)
	local antiAirUnits = {nil}
	local normalUnits = {nil}
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
	return antiAirUnits, normalUnits
end

function ReIssueCommandsToUnits(antiAirUnits,airTargets,normalUnits,allTargets,cmdID,options)
	local isHandled = false
	if options.ctrl then -- split attacks between units
		--split between AA and ground,
		IssueSplitedCommand(antiAirUnits,airTargets,cmdID,options)
		IssueSplitedCommand(normalUnits,allTargets,cmdID,options)
		isHandled = true
	else -- normal queue
		if #antiAirUnits>1 then
			--split between AA and ground,
			IssueCommand(antiAirUnits,airTargets,cmdID,options)
			IssueCommand(normalUnits,allTargets,cmdID,options)
			isHandled = true
		else 
			isHandled = false --nothing need to be done, let spring handle
		end
	end
	return isHandled
end
--------------------------------------------------------------------------------
function IssueCommand(selectedUnits,allTargets,cmdID,options)
	if #allTargets>=1 then
		local attackCommandListAll = PrepareCommandArray(allTargets, cmdID, options,1) -- prepare a normal queue (like regular SHIFT)
		Spring.GiveOrderArrayToUnitArray (selectedUnits, attackCommandListAll)
	end
end

function IssueSplitedCommand(selectedUnits,allTargets,cmdID,options)
	if #allTargets>=1 then
		local targetsUnordered = {}
		if cmdID==CMD.ATTACK then --and not CMD_UNIT_SET_TARGET. Note: only CMD.ATTACK support split attack queue, and in such case we also need to remember the queue so we can revert later if user decided to do SHIFT+Move
			for i=1,#allTargets do
				targetsUnordered[allTargets[i] ] = true
			end
			for i=1, #selectedUnits do
				unitsSplitAttackQueue[selectedUnits[i] ] = targetsUnordered --note: all units in this loop was refer to same table to avoid duplication
				handledCount = handledCount + 1
			end
		end
		for i=1, #selectedUnits do
			-- local noAttackQueue = queueException[Spring.GetUnitDefID(selectedUnits[i])]
			local attackCommandListAll = PrepareCommandArray(allTargets, cmdID, options,i,true,noAttackQueue) --prepare a shuffled queue for target splitting
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

function PrepareCommandArray (targetUnits, cmdID, options,indx,shuffle)
	indx = LoopAroundIndex(indx, #targetUnits)
	local stepSkip = 1
	if shuffle then
		stepSkip = (#targetUnits%(2))*-1 +3
		--stepSkip is 3 if #targetUnits is EVEN number (eg: 4,6,8), or 2 if  #targetUnits is ODD (eg: 3,5,7)
		--this will shuffle the target sequence appropriately
	end
	local attackCommandList = {}
	local j = 1
	attackCommandList[j] = {cmdID,{targetUnits[indx],},{((options.shift and "shift") or nil),}}
	if cmdID == CMD.ATTACK then
		for i=1, #targetUnits-1, 1 do
			j= j + 1
			indx = indx + stepSkip --stepSkip>1 will shuffle the queue
			indx = LoopAroundIndex(indx, #targetUnits)
			attackCommandList[j] = {cmdID,{targetUnits[indx],},{"shift",}} --every unit get to attack every target
		end
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