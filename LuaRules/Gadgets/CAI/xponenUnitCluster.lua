
local UnitListHandler = VFS.Include("LuaRules/Gadgets/CAI/UnitListHandler.lua")

local xponenUnitCluster = {}

function xponenUnitCluster.CreateUnitCluster(static)
	
	local unitList = UnitListHandler.CreateUnitList(static)
	
	local clusterInitialized, clusterExtracted = false,false
	local clusterFeed_UnitPos = {}
	local clusterRaw_Objects = {}
	local clusterList_UnitIDs = {}
	local clusterNoiseList_UnitIDs = {}
	local clusterCircle_Pos = {}
	
	local function UpdateClustering(minimumUnitCount,maximumConnectionDistance)
		-- This local function translate unit position into an ordered objects than hint a clustering information,
		-- big "maximumConnectionDistance" allow multiple cluster 'view' to be created later for wide range of connection distance with almost no cost at all,
		-- however big "maximumConnectionDistance" will increase code running time significantly because each iteration will loop over bigger number of neighbor.
		
		-- Honestly, a 600 TIGHTLY PACKED unit will cause the code to loop over every unit for each unit, test shows that it can run for 1.93 second (bad!).
		-- Its advised to not use big value for "maximumConnectionDistance" to avoid above situation. (Worse case is experimented using widget version)
		for unitID,_ in unitList.Iterator() do
			local x,_,z = unitList.GetUnitPosition(unitID)
			local y = 0
			clusterFeed_UnitPos[unitID] = {x,y,z}
		end
		minimumUnitCount = minimumUnitCount or 2
		maximumConnectionDistance = maximumConnectionDistance or 350
		clusterRaw_Objects = Spring.Utilities.Run_OPTIC(clusterFeed_UnitPos,maximumConnectionDistance,minimumUnitCount)
		clusterInitialized = true
	end
	
	local function ExtractCluster(desiredConnectionDistance)
		-- This local function translate OPTIC's result into clusters,
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
	
	local function GetClusterCoordinates()
		--This will return a table of {x,0,z,clusterAvgRadius+100,unitCount}
		--Can be used to see where unit is concentrating.
		if not clusterExtracted then
			ExtractCluster(300)
		end
		clusterCircle_Pos = Spring.Utilities.Convert_To_Circle(clusterList_UnitIDs, clusterNoiseList_UnitIDs,clusterFeed_UnitPos)
		clusterExtracted = true
		return clusterCircle_Pos
	end
	
	local function GetClusterCostCentroid()
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
		
	unitList.UpdateClustering = UpdateClustering
	unitList.ExtractCluster = ExtractCluster
	unitList.GetClusterCoordinates = GetClusterCoordinates
	unitList.GetClusterCostCentroid = GetClusterCostCentroid
	
	return unitList
end

return xponenUnitCluster
