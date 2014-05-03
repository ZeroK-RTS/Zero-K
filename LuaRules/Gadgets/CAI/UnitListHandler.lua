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

function UnitListHandler.CreateUnitList(static, useCustomData)
	local unitMap = {}
	local unitList = {}
	local unitCount = 0
	local totalCost = 0
	
	local clusterInitialized, clusterExtracted = false,false
	local clusterFeed_UnitPos = {}
	local clusterRaw_Objects = {}
	local clusterList_UnitIDs = {}
	local clusterNoiseList_UnitIDs = {}
	local clusterCircle_Pos = {}
	
	function UpdateClustering(minimumUnitCount,maximumConnectionDistance)
		-- This function translate unit position into an ordered objects than hint a clustering information,
		-- big "maximumConnectionDistance" allow multiple cluster 'view' to be created later for wide range of connection distance with almost no cost at all,
		-- however big "maximumConnectionDistance" will increase code running time significantly because each iteration will loop over bigger number of neighbor.
		
		-- Honestly, a 600 TIGHTLY PACKED unit will cause the code to loop over every unit for each unit, test shows that it can run for 1.93 second (bad!).
		-- Its advised to not use big value for "maximumConnectionDistance" to avoid above situation. (Worse case is experimented using widget version)
		for i=1, #unitList do
			local x,z = GetUnitLocation(unitList[i])
			local y = 0
			local unitID = unitList[i].unitID
			clusterFeed_UnitPos[unitID] = {x,y,z}
		end
		minimumUnitCount = minimumUnitCount or 2
		maximumConnectionDistance = maximumConnectionDistance or 350
		clusterRaw_Objects = Spring.Utilities.Run_OPTIC(clusterFeed_UnitPos,maximumConnectionDistance,minimumUnitCount)
		clusterInitialized = true
	end
	
	function ExtractCluster(desiredConnectionDistance)
		-- This function translate OPTIC's result into clusters,
		-- this can be called multiple time for different input without needing to redo the cluster algorithm,
		-- the "desiredConnectionDistance" must be less than "maximumConnectionDistance".
		
		-- Can be used to find clusters that match weapon AOE
		if not clusterInitialized then
			UpdateClustering(2,350)
		end
		desiredConnectionDistance = desiredConnectionDistance or 300 --must be less or equal to maximumConnectionDistance
		clusterList_UnitIDs, clusterNoiseList_UnitIDs = Spring.Utilities.Extract_Cluster(clusterRaw_Objects,desiredConnectionDistance)
		clusterExtracted = true
		return clusterList_UnitIDs, clusterNoiseList_UnitIDs
	end
	
	function GetClusterCoordinates()
		--This will return a table of {x,0,z,clusterAvgRadius+100,unitCount}
		--Can be used to see where unit is concentrating.
		if not clusterExtracted then
			ExtractCluster(300)
		end
		clusterCircle_Pos = Spring.Utilities.Convert_To_Circle(clusterList_UnitIDs, clusterNoiseList_UnitIDs,clusterFeed_UnitPos)
		clusterExtracted = true
		return clusterCircle_Pos
	end
	
	function GetClusterCostCentroid()
		--This will return a table of {weightedX,0,weightedZ,totalCost,unitCount}
		if not clusterExtracted then
			ExtractCluster(300)
		end
		local costCentroids = {}
		for i=1 , #clusterList_UnitIDs do
			local sumX, sumY,sumZ, meanX, meanY, meanZ,totalCost,count= 0,0 ,0 ,0,0,0,0,0
			for j=1, #clusterList_UnitIDs[i] do
				local unitID = clusterList_UnitIDs[i][j]
				local unitIndex = unitMap[unitID]
				local x,z = GetUnitLocation(unitList[unitIndex])
				local y,cost = 0,unitList[unitIndex].cost --// get stored unit position
				sumX= sumX+x*cost; sumY = sumY+y*cost; sumZ = sumZ+z*cost
				totalCost = totalCost + cost
				count = count + 1
			end
			meanX = sumX/totalCost; meanY = sumY/totalCost; meanZ = sumZ/totalCost --//calculate center of cost
			costCentroids[#costCentroids+1] = {meanX,0,meanZ,totalCost,#clusterList_UnitIDs[i]}
		end
		
		if #clusterNoiseList_UnitIDs>0 then --//IF outlier list is not empty
			for j= 1 ,#clusterNoiseList_UnitIDs do
				local unitID = clusterNoiseList_UnitIDs[j]
				local unitIndex = unitMap[unitID]
				local x,z = GetUnitLocation(unitList[unitIndex])
				local y,cost = 0,unitList[unitIndex].cost --// get stored unit position
				costCentroids[#costCentroids+1] = {x,0,z,cost,1}
			end
		end
		return costCentroids
	end
	
	function GetNearestUnit(x,z,condition)
		local minDisSq = false
		local closeID = false
		local closeX = false
		local closeZ = false
		for i = 1, unitCount do
			local data = unitList[i]
			local ux,uz = GetUnitLocation(data)
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
			local ux,uz = GetUnitLocation(data)
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
		GetNearestUnit = GetNearestUnit,
		IsPositionNearUnit = IsPositionNearUnit,
		ModifyUnit = ModifyUnit,
		AddUnit = AddUnit,
		RemoveUnit = RemoveUnit,
		GetTotalCost = GetTotalCost,
		Iterator = Iterator,
		
		UpdateClustering = UpdateClustering,
		ExtractCluster = ExtractCluster,
		GetClusterCoordinates = GetClusterCoordinates,
		GetClusterCostCentroid = GetClusterCostCentroid,
	}
	
	return newUnitList
end
	
return UnitListHandler