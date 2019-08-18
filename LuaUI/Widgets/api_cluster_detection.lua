--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GetInfo()
  return {
    name      = "Cluster Detection",
    desc      = "Unit cluster detection API",
    author    = "msafwan",
    date      = "2011.10.22",
    license   = "GNU GPL, v2 or later",
    layer     = -math.huge,
    enabled   = true,
	api = true,
	alwaysStart = true,
  }
end

local echoOutCalculationTime = false
---------------------------------------------------------------------------------
-----------C L U S T E R   D E T E C T I O N   T O O L --------------------------
---------------------------------------------------------------------------------
--Note: maintained by msafwan (xponen)
--Positional Functions------------------------------------------------------------
-- 3 function.
local searchCount = 0
local function BinarySearchNaturalOrder(position, orderedList)
	local prevCount = os.clock()
	local startPos = 1
	local endPos = #orderedList
	local span = endPos - startPos
	local midPos = math.modf((span/2) + startPos + 0.5) --round to nearest integer
	local found = false
	while (span > 1) do
		local difference = position - orderedList[midPos][2]
 
		if difference < 0 then
			endPos = midPos
		elseif difference > 0 then
			startPos = midPos
		else
			found=true
			break;
		end
		
		span = endPos - startPos
		midPos = math.modf((span/2) + startPos + 0.5) --round to nearest integer
	end
	if not found then
		if(math.abs(position - orderedList[startPos][2]) < math.abs(position - orderedList[endPos][2])) then
			midPos = startPos
		else
			midPos = endPos
		end
	end
	searchCount = searchCount + (os.clock() - prevCount)
	return midPos
end

local distCount = 0
local function GetDistanceSQ(unitID1, unitID2,receivedUnitList)
	local prevClock = os.clock()
	local x1,x2 = receivedUnitList[unitID1][1],receivedUnitList[unitID2][1]
	local z1,z2 = receivedUnitList[unitID1][3],receivedUnitList[unitID2][3]
	local distanceSQ = ((x1-x2)^2 + (z1-z2)^2)
	distCount = distCount + (os.clock() - prevClock)
	return distanceSQ
end

local intersectionCount = 0
local function GetUnitsInSquare(x,z,distance,posListX)
	local unitIndX = BinarySearchNaturalOrder(x, posListX)
	local unitsX = {}
	for i = unitIndX, 1, -1 do --go left
		if x - posListX[i][2] > distance then
			break
		end
		unitsX[#unitsX+1]=posListX[i]
	end
	for i = unitIndX+1, #posListX, 1 do --go right
		if posListX[i][2]-x > distance then
			break
		end
		unitsX[#unitsX+1]=posListX[i]
	end
	if #unitsX == 0 then
		return unitsX
	end
	local prevClock = os.clock()
	local unitsInBox = {}
	for i=1, #unitsX, 1 do
		if (math.abs(unitsX[i][3]-z) <= distance) then
			unitsInBox[#unitsInBox+1] = unitsX[i][1]
		end
	end
	intersectionCount = intersectionCount + (os.clock()-prevClock)
	return unitsInBox
end

--GetNeigbors--------------------------------------------------------------------
-- 1 function.
local getunitCount = 0
local function GetNeighbor (unitID, myTeamID, neighborhoodRadius, receivedUnitList,posListX) --//return the unitIDs of specific units around a center unit
	local prevCount = os.clock()
	local x,z = receivedUnitList[unitID][1],receivedUnitList[unitID][3]
	local tempList = GetUnitsInSquare(x,z,neighborhoodRadius,posListX) --Get neighbor. Ouput: unitID + my units
	getunitCount = getunitCount + (os.clock() - prevCount)
	return tempList
end

--Pre-SORTING function----------------------------------------------------------------
--3 function
local function InsertAtOrder(posList, newObject,compareFunction) --//stack big values at end of table, and tiny values at start of table.
	local insertionIndex = #posList + 1 --//insert data just below that big value
	for i = #posList, 1, -1 do
		if compareFunction(posList[i],newObject) then-- posList[i] < newObject will sort in ascending order, while  posList[i] > newObject will sort in descending order
			break
		end
		insertionIndex=i
	end
	
	--//shift table content
	local buffer1 = posList[insertionIndex] --backup content of current index
	posList[insertionIndex] = newObject --replace current index with new value. eg: {unitID = objects.unitID , x = objects.x, z = objects.z }
	for j = insertionIndex, #posList, 1 do --shift content for content less-or-equal-to table lenght
		local buffer2 = posList[j+1] --save content of next index
		posList[j+1] = buffer1 --put backup value into next index
		buffer1 = buffer2 --use saved content as next backup, then repeat process
	end
	return posList
end

local insertCount = 0
local function InsertOrderSeed (orderSeed, unitID_to_orderSeedMeta, unitID, objects) --//stack tiny values at end of table, and big values at start of table.
	local prevClock = os.clock()
	local orderSeedLenght = #orderSeed or 0 --//code below can handle both: table of lenght 0 and >1
	local insertionIndex = orderSeedLenght + 1 --//insert data just above that big value
	for i = orderSeedLenght, 1, -1 do
		if orderSeed[i].content.reachability_distance >= objects[unitID].reachability_distance then --//if existing value is abit bigger than to-be-inserted value: break
			break
		end
		insertionIndex=i
	end

	--//shift table content
	local buffer1 = orderSeed[insertionIndex] --backup content of current index
	orderSeed[insertionIndex] = {unitID = unitID , content = objects[unitID]} --replace current index with new value
	unitID_to_orderSeedMeta[unitID]=insertionIndex --update meta table
	for j = insertionIndex, orderSeedLenght, 1 do --shift content for content less-or-equal-to table lenght
		local buffer2 = orderSeed[j+1] --save content of next index
		orderSeed[j+1] = buffer1 --put backup value into next index
		unitID_to_orderSeedMeta[buffer1.unitID]=j+1 -- update meta table
		buffer1 = buffer2 --use saved content as next backup, then repeat process
	end
	insertCount = insertCount + (os.clock() - prevClock)
	return orderSeed, unitID_to_orderSeedMeta
end

local shiftCount = 0
local function ShiftOrderSeed (orderSeed, unitID_to_orderSeedMeta, unitID, objects) --//move values to end of table, and shift big values to beginning of of table.
	local prevClock = os.clock()
	local oldPosition = unitID_to_orderSeedMeta[unitID]
	local newPosition = oldPosition
	for i = oldPosition+1, #orderSeed, 1 do
		if orderSeed[i].content.reachability_distance < objects[unitID].reachability_distance then --//if existing value is abit lower than to-be-inserted value: add behind it and break
			break
		end
		newPosition = i
	end
	if newPosition == oldPosition then
		orderSeed[oldPosition]={unitID = unitID , content = objects[unitID]}
	else
		local buffer1 = orderSeed[newPosition] --//backup content of current index
		orderSeed[newPosition] = {unitID = unitID , content = objects[unitID]} --//replace current index with new value
		unitID_to_orderSeedMeta[unitID]=newPosition --//update meta table
		orderSeed[oldPosition] = nil --//delete old position
		for j = newPosition-1, oldPosition, -1 do --//shift values toward beginning of table
			local buffer2 = orderSeed[j] --//save content of current index
			orderSeed[j] = buffer1 --//put backup value into previous index
			unitID_to_orderSeedMeta[buffer1.unitID]=j --// update meta table
			buffer1 = buffer2 --//use saved content as the following backup, then repeat process
		end
	end
	shiftCount = shiftCount + (os.clock() - prevClock)
	return orderSeed, unitID_to_orderSeedMeta
end

--Merge-SORTING function----------------------------------------------------------------
--2 function. Reference: http://www.algorithmist.com/index.php/Merge_sort.c
local function merge(left, right, CompareFunction)
    local result ={} --var list result
	local leftProgress, rightProgress = 1,1
    while leftProgress <= #left or rightProgress <= #right do --while length(left) > 0 or length(right) > 0
		local leftNotFinish = leftProgress <= #left
		local rightNotFinish = rightProgress <= #right
        if leftNotFinish and rightNotFinish then --if length(left) > 0 and length(right) > 0
            if CompareFunction(left[leftProgress],right[rightProgress]) then --if first(left) < first(right), sort ascending. if first(left) > first(right), sort descending.
                result[#result+1] =left[leftProgress]--append first(left) to result
				leftProgress = leftProgress + 1 --left = rest(left)
            else
                result[#result+1] =right[rightProgress]--append first(right) to result
				rightProgress = rightProgress + 1 --right = rest(right)
			end
        elseif leftNotFinish then --else if length(left) > 0
            result[#result+1] =left[leftProgress] --append first(left) to result
			leftProgress = leftProgress + 1  --left = rest(left)
        elseif rightNotFinish then --else if length(right) > 0
            result[#result+1] =right[rightProgress] --append first(right) to result
			rightProgress = rightProgress + 1  --right = rest(right)
		end
    end --end while
    return result
end

local function merge_sort(m,CompareFunction)
    --// if list size is 1, consider it sorted and return it
    if #m <=1 then--if length(m) <= 1
        return m
	end
    --// else list size is > 1, so split the list into two sublists
    local left, right = {}, {} --var list left, right
    local middle = math.modf((#m/2)+0.5) --var integer middle = length(m) / 2
    for i= 1, middle, 1 do --for each x in m up to middle
         left[#left+1] = m[i] --add x to left
	end
    for j= #m, middle+1, -1 do--for each x in m after or equal middle
         right[(j-middle)] = m[j]--add x to right
	end
    --// recursively call merge_sort() to further split each sublist
    --// until sublist size is 1
    left = merge_sort(left,CompareFunction)
    right = merge_sort(right,CompareFunction)
    --// merge the sublists returned from prior calls to merge_sort()
    --// and return the resulting merged sublist
	return merge(left, right,CompareFunction)
end

--OPTICS function----------------------------------------------------------------
--5 function
local useMergeSorter_gbl = true --//constant: experiment with merge sorter (slower)
local orderseedCount = 0
local function OrderSeedsUpdate(neighborsID, currentUnitID,objects, orderSeed,unitID_to_orderSeedMeta,receivedUnitList)
	local prevCount = os.clock()
	local c_dist = objects[currentUnitID].core_distance
	for i=1, #neighborsID do
		local neighborUnitID = neighborsID[i]
		objects[neighborUnitID]=objects[neighborUnitID] or {unitID=neighborUnitID,}
		if (objects[neighborUnitID].processed~=true) then
			local new_r_dist = math.max(c_dist, GetDistanceSQ(currentUnitID, neighborUnitID,receivedUnitList))
			if objects[neighborUnitID].reachability_distance==nil then
				objects[neighborUnitID].reachability_distance = new_r_dist
				if useMergeSorter_gbl then
					orderSeed[#orderSeed+1] = {unitID = neighborUnitID, content = objects[neighborUnitID]}
					unitID_to_orderSeedMeta[neighborUnitID] = #orderSeed
				else
					orderSeed, unitID_to_orderSeedMeta = InsertOrderSeed (orderSeed, unitID_to_orderSeedMeta, neighborUnitID,objects)
				end
			else --// object already in OrderSeeds
				if new_r_dist< objects[neighborUnitID].reachability_distance then
					objects[neighborUnitID].reachability_distance = new_r_dist
					if useMergeSorter_gbl then
						local oldPosition = unitID_to_orderSeedMeta[neighborUnitID]
						orderSeed[oldPosition] = {unitID = neighborUnitID, content = objects[neighborUnitID]} -- update values
					else
						orderSeed, unitID_to_orderSeedMeta = ShiftOrderSeed(orderSeed, unitID_to_orderSeedMeta, neighborUnitID, objects)
					end
				end
			end
		end
	end
	if useMergeSorter_gbl then
		-- orderSeed = merge_sort(orderSeed, function(a,b) return a.content.reachability_distance > b.content.reachability_distance end ) --really slow
		table.sort(orderSeed, function(a,b) return a.content.reachability_distance > b.content.reachability_distance end) --abit slow
		for i= 1, #orderSeed do
			unitID_to_orderSeedMeta[orderSeed[i].unitID] = i
		end
	end
	orderseedCount = orderseedCount + (os.clock() - prevCount)
	return orderSeed, objects, unitID_to_orderSeedMeta
end

local setcoreCount =0
local function SetCoreDistance(neighborsID, minimumNeighbor, unitID,receivedUnitList)
	if (#neighborsID >= minimumNeighbor) then
		local neighborsDist= {} --//table to list down neighbor's distance.
		for i=1, #neighborsID do
			-- local distance = spGetUnitSeparation (unitID, neighborsID[i])
			local distanceSQ = GetDistanceSQ(unitID,neighborsID[i],receivedUnitList)
			neighborsDist[i]= distanceSQ --//add distance value
		end
		local prevCount = os.clock()
		table.sort(neighborsDist, function(a,b) return a < b end)
		-- neighborsDist = merge_sort(neighborsDist, true)
		setcoreCount = setcoreCount + (os.clock()-prevCount)
		return neighborsDist[minimumNeighbor] --//return the distance of the minimumNeigbor'th unit with respect to the center unit.
	else
		return nil
	end
end

local function ExtractDBSCAN_Clustering (unitID, currentClusterID, cluster, noiseIDList, object, neighborhoodRadius_alt)
	local reachabilityDist = (object.reachability_distance and math.sqrt(object.reachability_distance)) or 9999
	--// Precondition: neighborhoodRadius_alt <= generating dist neighborhoodRadius for Ordered Objects
	if reachabilityDist > neighborhoodRadius_alt then --// UNDEFINED > neighborhoodRadius. ie: Not reachable from outside
		local coreDistance = (object.core_distance and math.sqrt(object.core_distance)) or 9999
		if coreDistance <= neighborhoodRadius_alt then --//has neighbor
			currentClusterID = currentClusterID + 1 --//create new cluster
			cluster[currentClusterID] = cluster[currentClusterID] or {} --//initialize array
			local arrayIndex = #cluster[currentClusterID] + 1
			cluster[currentClusterID][arrayIndex] = unitID --//add to new cluster
			-- Spring.Echo("CREATE CLUSTER")
		else --//if has no neighbor
			local arrayIndex = #noiseIDList +1
			noiseIDList[arrayIndex]= unitID --//add to noise list
		end
	else --// object.reachability_distance <= neighborhoodRadius_alt. ie:reachable
		local arrayIndex = #cluster[currentClusterID] + 1
		cluster[currentClusterID][arrayIndex] = unitID--//add to current cluster
	end

	return cluster, noiseIDList, currentClusterID
end

local function ExpandClusterOrder(orderedObjects,receivedUnitList, unitID, neighborhoodRadius, minimumNeighbor, objects,posListX)
	local neighborsID = GetNeighbor (unitID, myTeamID, neighborhoodRadius, receivedUnitList,posListX)
	objects[unitID].processed = true
	objects[unitID].reachability_distance = nil
	objects[unitID].core_distance = SetCoreDistance(neighborsID, minimumNeighbor, unitID,receivedUnitList)
	orderedObjects[#orderedObjects+1]=objects[unitID]
	if objects[unitID].core_distance ~= nil then --//it have neighbor
		local orderSeed ={}
		local unitID_to_orderSeedMeta = {}
		orderSeed, objects, unitID_to_orderSeedMeta = OrderSeedsUpdate(neighborsID, unitID, objects, orderSeed,unitID_to_orderSeedMeta,receivedUnitList)
		while #orderSeed > 0 do
			local currentUnitID = orderSeed[#orderSeed].unitID
			objects[currentUnitID] = orderSeed[#orderSeed].content
			orderSeed[#orderSeed]=nil
			local neighborsID_ne = GetNeighbor (currentUnitID, myTeamID, neighborhoodRadius, receivedUnitList,posListX)
			objects[currentUnitID].processed = true
			objects[currentUnitID].core_distance = SetCoreDistance(neighborsID_ne, minimumNeighbor, currentUnitID,receivedUnitList)
			orderedObjects[#orderedObjects+1]=objects[currentUnitID]
			if objects[currentUnitID].core_distance~=nil then
				orderSeed, objects,unitID_to_orderSeedMeta = OrderSeedsUpdate(neighborsID_ne, currentUnitID, objects, orderSeed, unitID_to_orderSeedMeta,receivedUnitList)
			end
		end
	end
	return orderedObjects,objects
end

function WG.OPTICS_cluster (receivedUnitList, neighborhoodRadius, minimumNeighbor, _, neighborhoodRadius_alt) --//OPTIC_cluster function are accessible globally
	local objects={}
	local orderedObjects = {}
	local cluster = {}
	local noiseIDList = {}
	local currentClusterID = 0
	local posListX= {}
	local osClock1 = os.clock()
	--//SORTING unit list by X axis for easier searching, for getting unit in a box thru GetUnitInSquare()
	neighborhoodRadius = math.max(neighborhoodRadius_alt,neighborhoodRadius)
	for unitID,pos in pairs(receivedUnitList) do
		posListX[#posListX+1] = {unitID,pos[1],pos[3]}
		-- posListX = InsertAtOrder(posListX, {unitID,pos[1],pos[3]},function(a,b) return a[2]<b[2] end) --abit slow
	end
	table.sort(posListX, function(a,b) return a[2]<b[2] end) --//stack ascending
	if echoOutCalculationTime then
		distCount,shiftCount,insertCount = 0,0,0
		setcoreCount,getunitCount,searchCount = 0,0,0
		orderseedCount,intersectionCount = 0,0
		Spring.Echo("SPEED")
		Spring.Echo("Initial sorting: ".. os.clock() - osClock1)
		osClock1 = os.clock()
	end
	--//SORTING unit list by connections, for extracting cluster information later using ExtractDBSCAN_Clustering()
	for unitID,_ in pairs(receivedUnitList) do --//go thru the un-ordered list
		objects[unitID] = objects[unitID] or {unitID=unitID,}
		if (objects[unitID].processed ~= true) then
			orderedObjects, objects = ExpandClusterOrder(orderedObjects,receivedUnitList,unitID, neighborhoodRadius,minimumNeighbor,objects,posListX)
		end
	end
	if echoOutCalculationTime then
		Spring.Echo("OPTICs: ".. os.clock() - osClock1)
		Spring.Echo("  Distance calculation: ".. distCount)
		Spring.Echo("  OrderSeed calc: " .. orderseedCount)
		Spring.Echo("    Insert calculation: " .. insertCount)
		Spring.Echo("    Shift calculation: " .. shiftCount)
		Spring.Echo("  SetCore sort calc: " .. setcoreCount)
		Spring.Echo("  GetUnitBox calc: " .. getunitCount)
		Spring.Echo("    BinarySearch: " .. searchCount)
		Spring.Echo("    Intersection: " .. intersectionCount)
		osClock1 = os.clock()
	end
	--//CREATE cluster based on desired density (density == neighborhoodRadius_alt).
	--//Note: changing cluster view to different density is really cheap when using this function as long as the initial neighborhoodRadius is greater than the new density.
	--//if new density (neighborhoodRadius_alt) is greater than initial neighborhoodRadius, then you must recalculate the connections using bigger neighborhoodRadius which incur greater cost.
	for i=1, #orderedObjects do
		local unitID = orderedObjects[i].unitID
		cluster, noiseIDList, currentClusterID = ExtractDBSCAN_Clustering (unitID, currentClusterID, cluster, noiseIDList, orderedObjects[i], neighborhoodRadius_alt)
	end
	if echoOutCalculationTime then
		Spring.Echo("Extract Cluster: ".. os.clock() - osClock1)
	end
	return cluster, noiseIDList
end

function WG.Run_OPTIC(receivedUnitList, neighborhoodRadius, minimumNeighbor) --//OPTIC_cluster function are accessible globally
	local objects={}
	local orderedObjects = {}
	local posListX= {}
	--//SORTING unit list by X axis for easier searching, for getting unit in a box thru GetUnitInSquare()
	for unitID,pos in pairs(receivedUnitList) do
		posListX[#posListX+1] = {unitID,pos[1],pos[3]}
		-- posListX = InsertAtOrder(posListX, {unitID,pos[1],pos[3]},function(a,b) return a[2]<b[2] end) --abit slow
	end
	table.sort(posListX, function(a,b) return a[2]<b[2] end) --//stack ascending
	--//SORTING unit list by connections, for extracting cluster information later using ExtractDBSCAN_Clustering()
	for unitID,_ in pairs(receivedUnitList) do --//go thru the un-ordered list
		objects[unitID] = objects[unitID] or {unitID=unitID,}
		if (objects[unitID].processed ~= true) then
			orderedObjects, objects = ExpandClusterOrder(orderedObjects,receivedUnitList,unitID, neighborhoodRadius,minimumNeighbor,objects,posListX)
		end
	end
	return orderedObjects
end

function WG.Extract_Cluster (orderedObjects,neighborhoodRadius_alt )
	local cluster = {}
	local noiseIDList = {}
	local currentClusterID = 0
	--//CREATE cluster based on desired density (density == neighborhoodRadius_alt).
	--//Note: changing cluster view to different density is really cheap when using this function as long as the initial neighborhoodRadius is greater than the new density.
	--//if new density (neighborhoodRadius_alt) is greater than initial neighborhoodRadius, then you must recalculate the connections using bigger neighborhoodRadius which incur greater cost.
	for i=1, #orderedObjects do
		local unitID = orderedObjects[i].unitID
		cluster, noiseIDList, currentClusterID = ExtractDBSCAN_Clustering (unitID, currentClusterID, cluster, noiseIDList, orderedObjects[i], neighborhoodRadius_alt)
	end
	return cluster, noiseIDList
end

function WG.Convert_To_Circle (cluster, noiseIDList,receivedUnitList)
	--// extract cluster information and add mapMarker.
	local circlePosition = {}
	for index=1 , #cluster do
		local sumX, sumY,sumZ, unitCount,meanX, meanY, meanZ = 0,0 ,0 ,0 ,0,0,0
		local maxX, minX, maxZ, minZ, radiiX, radiiZ, avgRadii = 0,99999,0,99999, 0,0,0
		for unitIndex=1, #cluster[index] do
			local unitID = cluster[index][unitIndex]
			local x,y,z= receivedUnitList[unitID][1],receivedUnitList[unitID][2],receivedUnitList[unitID][3] --// get stored unit position
			sumX= sumX+x
			sumY = sumY+y
			sumZ = sumZ+z
			if x> maxX then
				maxX= x
			end
			if x<minX then
				minX=x
			end
			if z> maxZ then
				maxZ= z
			end
			if z<minZ then
				minZ=z
			end
			unitCount=unitCount+1
		end
		meanX = sumX/unitCount --//calculate center of cluster
		meanY = sumY/unitCount
		meanZ = sumZ/unitCount
		
		radiiX = ((maxX - meanX)+ (meanX - minX))/2
		radiiZ = ((maxZ - meanZ)+ (meanZ - minZ))/2
		avgRadii = (radiiX + radiiZ) /2
		circlePosition[#circlePosition+1] = {meanX,0,meanZ,avgRadii+100,#cluster[index]}
	end
	
	if #noiseIDList>0 then --//IF outlier list is not empty
		for j= 1 ,#noiseIDList do
			local unitID = noiseIDList[j]
			local x,y,z= receivedUnitList[unitID][1],receivedUnitList[unitID][2],receivedUnitList[unitID][3] --// get stored unit position
			circlePosition[#circlePosition+1] = {x,0,z,100,1}
		end
	end
	return circlePosition
end

--DBSCAN function----------------------------------------------------------
--1 function. BUGGY (Not yet debugged)
function WG.DBSCAN_cluster(receivedUnitList,neighborhoodRadius,minimumNeighbor)
	local unitID_to_clusterMeta = {}
	local visitedUnitID = {}
	local currentCluster_global=1
	local cluster = {}
	local unitIDNoise = {}

	local posListX = {}
	for unitID,pos in pairs(receivedUnitList) do
		posListX[#posListX+1] = {unitID,pos[1],pos[3]}
		-- posListX = InsertAtOrder(posListX, {unitID,pos[1],pos[3]},function(a,b) return a[2]<b[2] end) --abit slow

	end
	table.sort(posListX, function(a,b) return a[2]<b[2] end) --//stack ascending
	for unitID,_ in pairs(receivedUnitList) do --//go thru the un-ordered list
	
		if visitedUnitID[unitID] ~= true then --//skip if already visited
			visitedUnitID[unitID] = true
	
			local neighborUnits = GetNeighbor (unitID, myTeamID, neighborhoodRadius, receivedUnitList,posListX)
			
			if #neighborUnits ~= nil then
				if #neighborUnits <= minimumNeighbor then --//if surrounding units is less-or-just-equal to minimum neighbor then mark current unit as noise or 'outliers'
					local noiseIDLenght = #unitIDNoise or 0 --// if table is empty then make sure return table-lenght as 0 (zero) instead of 'nil'
					unitIDNoise[noiseIDLenght +1] = unitID
				else
					--local clusterIndex = #cluster+1 --//lenght of previous cluster table plus 1 new cluster
					cluster[currentCluster_global]={} --//initialize new cluster with an empty table for unitID
					local unitClusterLenght = #cluster[currentCluster_global] or 0 --// if table is empty then make sure return table-lenght as 0 (zero) instead of 'nil'
					cluster[currentCluster_global][unitClusterLenght +1] = unitID --//lenght of the table-in-table containing unit list plus 1 new unit
					unitID_to_clusterMeta[unitID] = currentCluster_global
					
					for l=1, #neighborUnits do
						local unitID_ne = neighborUnits[l]
						if visitedUnitID[unitID_ne] ~= true then --//skip if already visited
							visitedUnitID[unitID_ne] = true
							
							local neighborUnits_ne = GetNeighbor (unitID_ne, myTeamID, neighborhoodRadius, receivedUnitList,posListX)
							
							if #neighborUnits_ne ~= nil then
								if #neighborUnits_ne > minimumNeighbor then
									for m=1, #neighborUnits_ne do
										local duplicate = false
										for n=1, #neighborUnits do
											if neighborUnits[n] == neighborUnits_ne[m] then
												duplicate = true
												break
											end
										end
										if duplicate== false then
											neighborUnits[#neighborUnits +1]=neighborUnits_ne[m]
										end
									end --//for m=1, m<= #neighborUnits_ne, 1
								end --// if #neighborUnits_ne > minimumNeighbor
							end --//if #neighborUnits_ne ~= nil
							
							if unitID_to_clusterMeta[unitID_ne] ~= currentCluster_global then
								local unitIndex_ne = #cluster[currentCluster_global] +1 --//lenght of the table-in-table containing unit list plus 1 new unit
								cluster[currentCluster_global][unitIndex_ne] = unitID_ne
								
								unitID_to_clusterMeta[unitID_ne] = currentCluster_global
							end
							
						end --//if visitedUnitID[unitID_ne] ~= true
					end --//for l=1, l <= #neighborUnits, 1
					currentCluster_global= currentCluster_global + 1
				end --//if #neighborUnits <= minimumNeighbor, else
			end --//if #neighborUnits ~= nil
		end --//if visitedUnitID[unitID] ~= true
	end --//for i=1, i <= #receivedUnitList,1
	return cluster, unitIDNoise
end
--brief:   a clustering algorithm
--algorithm source: Ordering Points To Identify the Clustering Structure (OPTICS) by Mihael Ankerst, Markus M. Breunig, Hans-Peter Kriegel and Jörg Sander
--algorithm source: density-based spatial clustering of applications with noise (DBSCAN) by Martin Ester, Hans-Peter Kriegel, Jörg Sander and Xiaowei Xu
--Reference:
--http://en.wikipedia.org/wiki/OPTICS_algorithm ;pseudocode
--http://en.wikipedia.org/wiki/DBSCAN ;pseudocode
--http://codingplayground.blogspot.com/2009/11/dbscan-clustering-algorithm.html ;C++ sourcecode
--http://www.google.com.my/search?q=optics%3A+Ordering+Points+To+Identify+the+Clustering+Structure ;article & pseudocode on OPTICS
---------------------------------------------------------------------------------
---------------------------------E N D ------------------------------------------
---------------------------------------------------------------------------------
