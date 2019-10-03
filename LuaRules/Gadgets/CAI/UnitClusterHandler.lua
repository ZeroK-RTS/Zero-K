--[[ Determines the cluster structure of a list of units.

 
== CreateUnitList(losCheckAllyTeamID, clusterRadius)
 losCheckAllyTeamID is for the underlying UnitList.
 
 clusterRadius is how close two units need to be to be within the
 same cluster. Close units may be in different clusters depending
 on how the boundaries work out.
 
=== local functions ===
 All UnitList local functions are accessible along with two more.

 
 == UpdateUnitPositions()
 Updates the clusters based on the current unit positions.
 
 == ClusterIterator() -> averageX, averageZ, totalCost, unitCount
 Iterates over the clusters of units.
--]]

local UnitListHandler = VFS.Include("LuaRules/Gadgets/CAI/UnitListHandler.lua")

local UnitClusterHandler = {}

local function DisSQ(x1,z1,x2,z2)
	return (x1 - x2)^2 + (z1 - z2)^2
end

function UnitClusterHandler.CreateUnitCluster(losCheckAllyTeamID, clusterRadius)
	
	local unitList = UnitListHandler.CreateUnitList(losCheckAllyTeamID)
	
	local clusterRadiusSq = clusterRadius^2
	
	local clusterList = {}
	local clusterCount = 0
	
	-- Cluster Handling
	local function AddUnitToCluster(index, unitID)
		local x,_,z = unitList.GetUnitPosition(unitID)
		if not x then
			return
		end
		
		if not index then
			local cost = unitList.GetUnitCost(unitID)
			clusterCount = clusterCount + 1
			clusterList[clusterCount] = {
				x = x,
				z = z,
				averageX = x,
				averageZ = z,
				xSum = x*cost,
				zSum = z*cost,
				costSum = cost,
				unitCount = 1,
				unitMap = {[unitID] = true},
			}
			
			unitList.SetUnitDataValue(unitID, "clusterX", x)
			unitList.SetUnitDataValue(unitID, "clusterZ", z)
			
			return
		end
		
		local clusterData = clusterList[index]
		local cost = unitList.GetUnitCost(unitID)
		
		unitList.SetUnitDataValue(unitID, "clusterX", x)
		unitList.SetUnitDataValue(unitID, "clusterZ", z)

		clusterData.xSum = clusterData.xSum + x*cost
		clusterData.zSum = clusterData.zSum + z*cost
		clusterData.costSum = clusterData.costSum + cost
		
		clusterData.averageX = clusterData.xSum/clusterData.costSum
		clusterData.averageZ = clusterData.zSum/clusterData.costSum
		
		clusterData.unitMap[unitID] = true
		clusterData.unitCount = clusterData.unitCount + 1
	end
	
	local function RemoveUnitFromCluster(index, unitID)
		local clusterData = clusterList[index]
		if clusterData.unitCount == 1 then
			clusterList[index] = clusterList[clusterCount]
			clusterList[clusterCount] = nil
			clusterCount = clusterCount - 1
			return
		end
		
		local cost = unitList.GetUnitCost(unitID)
		local unitData = unitList.GetUnitData(unitID)
		local x, z = unitData.clusterX, unitData.clusterZ
		
		clusterData.xSum = clusterData.xSum - x*cost
		clusterData.zSum = clusterData.zSum - z*cost
		clusterData.costSum = clusterData.costSum - cost
		
		clusterData.averageX = clusterData.xSum/clusterData.costSum
		clusterData.averageZ = clusterData.zSum/clusterData.costSum
		
		clusterData.unitMap[unitID] = nil
		clusterData.unitCount = clusterData.unitCount - 1
	end
	
	local function HandleUnitAddition(unitID)
		local x,_,z = unitList.GetUnitPosition(unitID)
		if not x then
			return false
		end
		local minDis = false
		local minIndex = false
		for i = 1, clusterCount do
			local clusterData = clusterList[i]
			local disSq = DisSQ(x,z,clusterData.x,clusterData.z)
			if disSq < clusterRadiusSq then
				local aDisSq = DisSQ(x,z,clusterData.averageX,clusterData.averageZ)
				if (not minDis) or aDisSq < minDis then
					minDis = disSq
					minIndex = i
				end
			end
		end
		AddUnitToCluster(minIndex, unitID)
	end
	
	local function HandleUnitRemoval(unitID)
		for i = 1, clusterCount do
			local clusterData = clusterList[i]
			if clusterData.unitMap[unitID] then
				RemoveUnitFromCluster(i, unitID)
				return
			end
		end
	end
	
	-- Extra Cluster External local functions
	local function ClusterIterator() -- x, z, cost, count
		local i = 0
		return function ()
			i = i + 1
			if i <= clusterCount then
				local clusterData = clusterList[i]
				return clusterData.averageX, clusterData.averageZ, clusterData.costSum, clusterData.unitCount
			end
		end
	end
	
	local function UpdateUnitPositions(range)
		for unitID,_ in unitList.Iterator() do
			if unitList.HasUnitMoved(unitID,range) then
				HandleUnitRemoval(unitID)
				HandleUnitAddition(unitID)
			end
		end
	end
	
	-- UnitListHandler External local functions
	local function AddUnit(unitID, cost, static, newData)
		if unitList.AddUnit(unitID, cost, static, newData) then
			HandleUnitAddition(unitID)
		end
	end
	
	local function RemoveUnit(unitID)
		if unitList.ValidUnitID(unitID) then
			HandleUnitRemoval(unitID)
		end
		unitList.RemoveUnit(unitID)
	end
	
	local function SetUnitDataValue(unitID, key, value)
		if key ~= "clusterX" and key ~= "clusterZ" then
			unitList.SetUnitDataValue(unitID, key, value)
		end
	end
	
	local unitCluster = {
		ClusterIterator = ClusterIterator,
		
		UpdateUnitPositions = UpdateUnitPositions,
		
		AddUnit = AddUnit,
		RemoveUnit = RemoveUnit,
		SetUnitDataValue = SetUnitDataValue,
		
		GetUnitPosition = unitList.GetUnitPosition,
		GetNearestUnit = unitList.GetNearestUnit,
		HasUnitMoved = unitList.HasUnitMoved,
		IsPositionNearUnit = unitList.IsPositionNearUnit,
		OverwriteUnitData = unitList.OverwriteUnitData,
		GetUnitData = unitList.GetUnitData,
		GetUnitCost = unitList.GetUnitCost,
		GetTotalCost = unitList.GetTotalCost,
		ValidUnitID = unitList.ValidUnitID,
		Iterator = unitList.Iterator,
	}
	
	return unitCluster
end

return UnitClusterHandler
