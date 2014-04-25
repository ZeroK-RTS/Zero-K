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

local function GetUnitLocation(data)
	if static then
		if data.x then
			return data.x, data.z
		else
			local x,_,z = spGetUnitPosition(data.unitID)
			data.x = x
			data.z = z
			return x, z
		end
	end
	local x,_,z = spGetUnitPosition(data.unitID)
	return x, z
end

function UnitListHandler.CreateUnitList(static)
	local unitMap = {}
	local unitList = {}
	local unitCount = 0
	
	function GetNearestUnit(x,z,condition)
		local minDisSq = false
		local closeID = false
		local closeX = false
		local closeZ = false
		for i = 1, unitCount do
			local data = unitList[i]
			local ux,uz = GetUnitLocation(data)
			if condition and condition(data.unitID, ux, uz, data.customData) then
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
			local ux,uz = GetUnitLocation(data)
			if condition and condition(data.unitID, ux, uz, data.customData) then
				local thisDisSq = DisSQ(x,z,ux,uz)
				if thisDisSq < radiusSq then
					return true
				end
			end
		end
		return false
	end
	
	function ModifyUnit(unitID, newData)
		if unitMap[unitID] then
			unitList[index].customData = newData
		end
	end
	
	function AddUnit(unitID, newData)
		if unitMap[unitID] then
			ModifyUnit(unitID, cost, newData)
		end
		
		-- Add unit to list
		unitCount = unitCount + 1
		unitList[unitCount] = {
			unitID = unitID,
			customData = newData,
		}
		unitMap[unitID] = unitCount
	end
	
	function RemoveUnit(unitID)
		if unitMap[unitID] then
			local index = unitMap[unitID]

			-- Copy the end of the list to this index
			unitList[index] = unitList[unitCount]
			unitMap[unitList[index].unitID] = index
			
			-- Remove the end of the list
			unitList[unitCount] = nil
			unitCount = unitCount - 1
			unitMap[unitID] = nil
		end
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
		GetNearestUnit = GetNearestUnit,
		IsPositionNearUnit = IsPositionNearUnit,
		ModifyUnit = ModifyUnit,
		AddUnit = AddUnit,
		RemoveUnit = RemoveUnit,
		Iterator = Iterator,
	}
	
	return newUnitList
end
	
return UnitListHandler