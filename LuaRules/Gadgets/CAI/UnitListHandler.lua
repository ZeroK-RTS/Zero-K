--[[ Handles Lists of Units
 * Create as a list of unit with some local functions.
 * Can get total unit cost, a random unit, units in area etc..
 * Elements can have custom data.
 
== CreateUnitList(losCheckAllyTeamID)
 losCheckAllyTeamID is the point of view that the return functions should take
 regarding LOS. A non-cheating AI would always create a unit list with its
 allyTeamID to ensure that the UnitList does not cheat.
 
=== local functions ===

 == GetUnitPosition(unitID) -> {x, y, z} or false
 Returns the position of the unitID obeying LOS and radar.
 
 == GetNearestUnit(x, z, condition) -> unitID
 Returns the nearest unit in the list which satisfies the condition.
 The condition is a local function of the form
	condition(unitID, x, z, customData, cost).
 
 == HasUnitMoved(unitID, range) -> boolean
 Returns true if the unit is range away from where it was when HasUnitMoved
 was last called.
 
 == IsPositionNearUnit(x, z, radius, condition) -> boolean
 Returns true if there is a unit from the list satisfying the conditions
 within the radius around the point. The condition is the same as in
 GetNearestUnit.
 
 == OverwriteUnitData(unitID, newData)
 == GetUnitData(unitID) -> table
 == SetUnitDataValue(unitID, key, value)
 local functions which get and set the custom data attachable to units in the list.
 
 
 == AddUnit(unitID, static, cost, newData)
 Adds a unit to the list.
 - static tells the list whether the unit can move.
 - cost is just treated as a number.
 - newData is a table of information to attach to the unit.
 
 == RemoveUnit(unitID) -> boolean
 Remove a unit from the list

 == GetUnitCost(unitID) -> cost
 == GetTotalCost() -> cost

 == ValidUnitID(unitID) -> boolean
 Returns true if the unit is in the list.

 == Iterator() -> unitID, cost, customData
 Provides a way to iterate over units in the list. It is not safe to remove units
 while iterating over them. To use do this:
 
 for unitID, cost, customData in unitList.Iterator() do
	...
 end
--]]

local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitLosState = Spring.GetUnitLosState

local UnitListHandler = {}

local function DisSQ(x1,z1,x2,z2)
	return (x1 - x2)^2 + (z1 - z2)^2
end

local function InternalGetUnitPosition(data, losCheckAllyTeamID)
	if data.static then
		if data.x then
			return data.x, data.y, data.z
		else
			local x,y,z = spGetUnitPosition(data.unitID)
			data.x = x
			data.y = y
			data.z = z
			return x, y, z
		end
	end
	if losCheckAllyTeamID then
		local los = spGetUnitLosState(data.unitID, losCheckAllyTeamID, false)
		if los and (los.los or los.radar) and los.typed then
			local x,y,z = spGetUnitPosition(data.unitID)
			return x, y, z
		end
	else
		local x,y,z = spGetUnitPosition(data.unitID)
		return x, y, z
	end
	return false
end

function UnitListHandler.CreateUnitList(losCheckAllyTeamID)
	local unitMap = {}
	local unitList = {}
	local unitCount = 0
	local totalCost = 0
	
	-- Indiviual Unit Position local functions
	local function GetUnitPosition(unitID)
		if unitMap[unitID] then
			local index = unitMap[unitID]
			return InternalGetUnitPosition(unitList[index], losCheckAllyTeamID)
		end
	end
	
	local function HasUnitMoved(unitID, range)
		if not unitMap[unitID] then
			return false
		end
		local index = unitMap[unitID]
		local data = unitList[index]
		if data.static then
			return false
		end
		local x,_,z = InternalGetUnitPosition(data, losCheckAllyTeamID)
		if x then
			if not data.oldX then
				data.oldX = x
				data.oldZ = z
				return true
			end
			if DisSQ(x,z,data.oldX,data.oldZ) > range^2 then
				data.oldX = x
				data.oldZ = z
				return true
			end
			return false
		end
		return true
	end
	
	-- Position checks over all units in the list
	local function GetNearestUnit(x,z,condition)
		local minDisSq = false
		local closeID = false
		local closeX = false
		local closeZ = false
		for i = 1, unitCount do
			local data = unitList[i]
			local ux,_,uz = InternalGetUnitPosition(data, losCheckAllyTeamID)
			if ux and condition and condition(data.unitID, ux, uz, data.customData, data.cost) then
				local thisDisSq = DisSQ(x,z,ux,uz)
				if not minDisSq or minDisSq > thisDisSq then
					minDisSq = thisDisSq
					closeID = data.unitID
					closeX = x
					closeZ = z
				end
			end
		end
		return closeID, closeX, closeZ
	end
	
	local function IsPositionNearUnit(x, z, radius, condition)
		local radiusSq = radius^2
		for i = 1, unitCount do
			local data = unitList[i]
			local ux,_,uz = InternalGetUnitPosition(data, losCheckAllyTeamID)
			if ux and condition and condition(data.unitID, ux, uz, data.customData, data.cost) then
				local thisDisSq = DisSQ(x,z,ux,uz)
				if thisDisSq < radiusSq then
					return true
				end
			end
		end
		return false
	end
	
	-- Unit cust data handling
	local function OverwriteUnitData(unitID, newData)
		if unitMap[unitID] then
			local index = unitMap[unitID]
			unitList[index].customData = newData
		end
	end
	
	local function GetUnitData(unitID)
		-- returns a table but don't edit it!
		if unitMap[unitID] then
			local index = unitMap[unitID]
			return unitList[index].customData or {}
		end
	end
	
	local function SetUnitDataValue(unitID, key, value)
		if unitMap[unitID] then
			local index = unitMap[unitID]
			if not unitList[index].customData then
				unitList[index].customData = {}
			end
			unitList[index].customData[key] = value
		end
	end
	
	-- Unit addition and removal handling
	local function AddUnit(unitID, static, cost, newData)
		if unitMap[unitID] then
			if newData then
				OverwriteUnitData(unitID, newData)
			end
			return false
		end
		
		cost = cost or 0
		
		-- Add unit to list
		unitCount = unitCount + 1
		unitList[unitCount] = {
			unitID = unitID,
			static = static,
			cost = cost,
			customData = newData,
		}
		unitMap[unitID] = unitCount
		totalCost = totalCost + cost
		return true
	end
	
	local function RemoveUnit(unitID)
		if unitMap[unitID] then
			local index = unitMap[unitID]
			
			totalCost = totalCost - unitList[index].cost

			-- Copy the end of the list to this index
			unitList[index] = unitList[unitCount]
			unitMap[unitList[index].unitID] = index
			
			-- Remove the end of the list
			unitList[unitCount] = nil
			unitCount = unitCount - 1
			unitMap[unitID] = nil
			return true
		end
		return false
	end
	
	local function ValidUnitID(unitID)
		return (unitMap[unitID] and true) or false
	end
	
	-- Cost Handling
	local function GetUnitCost(unitID)
		if unitMap[unitID] then
			local index = unitMap[unitID]
			return unitList[index].cost
		end
	end
	
	local function GetTotalCost()
		return totalCost
	end
	
	-- To use Iterator, write "for unitID, data in unitList.Iterator() do"
	local function Iterator()
		local i = 0
		return function ()
			i = i + 1
			if i <= unitCount then
				return unitList[i].unitID, unitList[i].cost, unitList[i].customData
			end
		end
	end
	
	local newUnitList = {
		GetUnitPosition = GetUnitPosition,
		GetNearestUnit = GetNearestUnit,
		HasUnitMoved = HasUnitMoved,
		IsPositionNearUnit = IsPositionNearUnit,
		OverwriteUnitData = OverwriteUnitData,
		GetUnitData = GetUnitData,
		SetUnitDataValue = SetUnitDataValue,
		AddUnit = AddUnit,
		RemoveUnit = RemoveUnit,
		GetUnitCost = GetUnitCost,
		GetTotalCost = GetTotalCost,
		ValidUnitID = ValidUnitID,
		Iterator = Iterator,
	}
	
	return newUnitList
end
	
return UnitListHandler
