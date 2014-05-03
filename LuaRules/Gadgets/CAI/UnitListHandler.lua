--[[ Handles Lists of Units
 * Create as a list of unit with some functions.
 * Can get total unit cost, a random unit, units in area etc..
 * Elements can have custom data.
--]]

local spGetUnitPosition = Spring.GetUnitPosition

local UnitListHandler = {}

local function DisSQ(x1,z1,x2,z2)
	return (x1 - x2)^2 + (z1 - z2)^2
end


function InternalGetUnitPosition(data)
	if static then
		if data.x then
			return data.x, data.z
		else
			local x,y,z = spGetUnitPosition(data.unitID)
			data.x = x
			data.y = y
			data.z = z
			return x, y, z
		end
	end
	local x,y,z = spGetUnitPosition(data.unitID)
	return x, y, z
end

function UnitListHandler.CreateUnitList(static, useCustomData)
	local unitMap = {}
	local unitList = {}
	local unitCount = 0
	local totalCost = 0
	
	function GetUnitPosition(unitID)
		if unitMap[unitID] then
			local index = unitMap[unitID]
			return InternalGetUnitPosition(unitList[index])
		end
	end
	
	function GetNearestUnit(x,z,condition)
		local minDisSq = false
		local closeID = false
		local closeX = false
		local closeZ = false
		for i = 1, unitCount do
			local data = unitList[i]
			local ux,_,uz = InternalGetUnitPosition(data)
			if condition and condition(data.unitID, ux, uz, data.customData, data.cost) then
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
	
	function IsPositionNearUnit(x, z, radius, condition)
		local radiusSq = radius^2
		for i = 1, unitCount do
			local data = unitList[i]
			local ux,_,uz = InternalGetUnitPosition(data)
			if condition and condition(data.unitID, ux, uz, data.customData, data.cost) then
				local thisDisSq = DisSQ(x,z,ux,uz)
				if thisDisSq < radiusSq then
					return true
				end
			end
		end
		return false
	end
	
	function ModifyUnit(unitID, newData) -- Cost can not be changed.
		if unitMap[unitID] then
			local index = unitMap[unitID]
			unitList[index].customData = newData
		end
	end
	
	function AddUnit(unitID, newData, cost)
		if unitMap[unitID] then
			if useCustomData then
				ModifyUnit(unitID, newData, cost)
			else
				return
			end
		end
		
		cost = cost or 0
		
		-- Add unit to list
		unitCount = unitCount + 1
		unitList[unitCount] = {
			unitID = unitID,
			cost = cost,
			customData = newData,
		}
		unitMap[unitID] = unitCount
		totalCost = totalCost + cost
	end
	
	function RemoveUnit(unitID)
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
		end
	end
	
	function GetTotalCost()
		return totalCost
	end
	
	function Iterator()
		local i = 0
		return function ()
			i = i + 1
			if i <= unitCount then 
				return unitList[i].unitID, unitList[i].customData 
			end
		end
	end
	
	local newUnitList = {
		GetUnitPosition = GetUnitPosition,
		GetNearestUnit = GetNearestUnit,
		IsPositionNearUnit = IsPositionNearUnit,
		ModifyUnit = ModifyUnit,
		AddUnit = AddUnit,
		RemoveUnit = RemoveUnit,
		GetTotalCost = GetTotalCost,
		Iterator = Iterator,
	}
	
	return newUnitList
end
	
return UnitListHandler