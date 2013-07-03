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
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

---------------------------------------------------------------------------------
-----------C L U S T E R   D E T E C T I O N   T O O L --------------------------
---------------------------------------------------------------------------------
--Note: written by msafwan (xponen). Ask me for maintenance in case something goes wrong (and pray that I remember what to do)

local spGetUnitsInCylinder = Spring.GetUnitsInCylinder
local spGetUnitSeparation = Spring.GetUnitSeparation

--GetNeigbors--------------------------------------------------------------------
-- 1 function.
local function GetNeighbor (unitID, myTeamID, neighborhoodRadius, receivedUnitList) --//return the unitIDs of specific units around a center unit
	local x,z = receivedUnitList[unitID][1],receivedUnitList[unitID][3]
	local tempUnitList = {} 
	if x ~= nil then --//handle a case where unitID is valid but output a nil
		local neighborUnits = spGetUnitsInCylinder(x,z, neighborhoodRadius, myTeamID) --//use Spring to return the surrounding units' ID. Get neighbor. Ouput: unitID + my units
		for k = 1, #neighborUnits do --// try to filter out non-received units from receivedUnitList
			local match = false
			if receivedUnitList[neighborUnits[k]] then --and neighborUnits[k]~=unitID then --//if unit is among the received-unit-list, then accept
				match = true
			end
			if match then --//if unit is among the received-unit-list then remember it
				local unitListLenght = #tempUnitList or 0
				tempUnitList[unitListLenght+1] = neighborUnits[k]
			end
		end
	end
	return tempUnitList
end

--Pre-SORTING function----------------------------------------------------------------
--2 function
local function InsertOrderSeed (orderSeed, unitID_to_orderSeedMeta, unitID, objects) --//stack tiny values at end of table, and big values at start of table.
	local orderSeedLenght = #orderSeed or 0 --//code below can handle both: table of lenght 0 and >1
	local insertionIndex = orderSeedLenght
	for i = orderSeedLenght, 0, -1 do
		insertionIndex=i
		if i >0 then --at index 0 don't do check. Will get nil for sure.
			if orderSeed[i].content.reachability_distance > objects[unitID].reachability_distance then --//if existing value is abit bigger than to-be-inserted value: break
				break
			end
		end
	end
	insertionIndex = insertionIndex + 1 --//insert data just above that big value
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
	return orderSeed, unitID_to_orderSeedMeta
end

local function ShiftOrderSeed (orderSeed, unitID_to_orderSeedMeta, unitID, objects) --//move values to end of table, and shift big values to beginning of of table.
	local oldPosition = unitID_to_orderSeedMeta[unitID]
	local orderSeedLenght = #orderSeed
	local newPosition = orderSeedLenght
	for i = orderSeedLenght, 0, -1 do
		newPosition=i
		if i >0 and i~= oldPosition then --//at index 0 don't check. Will get nil for sure.
			if orderSeed[i].content.reachability_distance > objects[unitID].reachability_distance then --//if existing value is abit bigger than to-be-inserted value: break
				break
			end
		end
	end
	if newPosition == oldPosition then
		orderSeed[oldPosition]={unitID = unitID , content = objects[unitID]}
	else
		newPosition = newPosition + 1 --//insert data just above that big value
		if newPosition >orderSeedLenght then
			newPosition = orderSeedLenght
		end
		local buffer1 = orderSeed[newPosition] --//backup content of current index
		orderSeed[oldPosition] = nil --//delete old position
		orderSeed[newPosition] = {unitID = unitID , content = objects[unitID]} --//replace current index with new value
		unitID_to_orderSeedMeta[unitID]=newPosition --//update meta table
		if newPosition > oldPosition then
			for j = newPosition, oldPosition+1, -1 do --//shift values toward beginning of table
				local buffer2 = orderSeed[j-1] --//save content of previous index
				orderSeed[j-1] = buffer1 --//put backup value into previous index
				unitID_to_orderSeedMeta[buffer1.unitID]=j-1 --// update meta table
				buffer1 = buffer2 --//use saved content as the following backup, then repeat process
			end
		else 
			for j = newPosition, oldPosition-1, 1 do --//shift values toward end of table
				local buffer2 = orderSeed[j+1] --//save content of next index
				orderSeed[j+1] = buffer1 --//put backup value into next index
				unitID_to_orderSeedMeta[buffer1.unitID]=j+1 --// update meta table
				buffer1 = buffer2 --//use saved content as next backup, then repeat process
			end
		end
	end
	return orderSeed, unitID_to_orderSeedMeta
end

--Merge-SORTING function----------------------------------------------------------------
--2 function. Reference: http://www.algorithmist.com/index.php/Merge_sort.c
local function merge(left, right)
	local unitID_to_orderSeedMeta = {}
    local result ={} --var list result
    while #left>0 or #right>0 do --while length(left) > 0 or length(right) > 0
        if #left > 0 and #right > 0 then --if length(left) > 0 and length(right) > 0
            if left[1].content.reachability_distance >= right[1].content.reachability_distance then --if first(left) >= first(right). Stack Big value at start of table, and Tiny value at end of table
                result[(#result or 0)+1] =left[1]--append first(left) to result
				unitID_to_orderSeedMeta[left[1].unitID]=#result
				table.remove(left,1) --left = rest(left)
            else
                result[(#result or 0)+1] =right[1]--append first(right) to result
				unitID_to_orderSeedMeta[right[1].unitID]=#result
				table.remove(right,1) --right = rest(right)
			end
        elseif #left > 0 then --else if length(left) > 0
            result[(#result or 0)+1] =left[1] --append first(left) to result
			unitID_to_orderSeedMeta[left[1].unitID]=#result
            table.remove(left,1) --left = rest(left)
        elseif #right > 0 then --else if length(right) > 0
            result[(#result or 0)+1] =right[1] --append first(right) to result
			unitID_to_orderSeedMeta[right[1].unitID]=#result
            table.remove(right,1) --right = rest(right)
		end
    end --end while
    return result, unitID_to_orderSeedMeta
end

local function merge_sort(m)
    --// if list size is 1, consider it sorted and return it
    if #m <=1 then--if length(m) <= 1
        return m
	end
    --// else list size is > 1, so split the list into two sublists
    local left, right = {}, {} --var list left, right
    local middle = math.ceil(#m/2) --var integer middle = length(m) / 2
    for i= 1, middle, 1 do --for each x in m up to middle
         left[(#left or 0)+1] = m[i] --add x to left
	end
    for j= #m, middle+1, -1 do--for each x in m after or equal middle
         right[(j-middle)] = m[j]--add x to right
	end
    --// recursively call merge_sort() to further split each sublist
    --// until sublist size is 1
    left = merge_sort(left)
    right = merge_sort(right)
    --// merge the sublists returned from prior calls to merge_sort()
    --// and return the resulting merged sublist
    return merge(left, right)
end

--OPTICS function----------------------------------------------------------------
--5 function
local useMergeSorter_gbl = false --//constant: experiment with merge sorter (slower)
local function OrderSeedsUpdate(neighborsID, currentUnitID,objects, orderSeed,unitID_to_orderSeedMeta)
	local c_dist = objects[currentUnitID].core_distance
	for i=1, #neighborsID do
		objects[neighborsID[i]]=objects[neighborsID[i]] or {}
		if (objects[neighborsID[i]].processed~=true) then
			local new_r_dist = math.max(c_dist, spGetUnitSeparation(currentUnitID, neighborsID[i]))
			if objects[neighborsID[i]].reachability_distance==nil then
				objects[neighborsID[i]].reachability_distance = new_r_dist
				if useMergeSorter_gbl then
					orderSeed[(#orderSeed or 0)+1] = {unitID = neighborsID[i], content = objects[neighborsID[i]]}
					unitID_to_orderSeedMeta[neighborsID[i]] = #orderSeed
				else				
					orderSeed, unitID_to_orderSeedMeta = InsertOrderSeed (orderSeed, unitID_to_orderSeedMeta, neighborsID[i],objects)
				end
			else --// object already in OrderSeeds
				if new_r_dist< objects[neighborsID[i]].reachability_distance then
					objects[neighborsID[i]].reachability_distance = new_r_dist
					if useMergeSorter_gbl then
						local oldPosition = unitID_to_orderSeedMeta[neighborsID[i]]
						orderSeed[oldPosition] = {unitID = neighborsID[i], content = objects[neighborsID[i]]} -- update values
					else
						orderSeed, unitID_to_orderSeedMeta = ShiftOrderSeed(orderSeed, unitID_to_orderSeedMeta, neighborsID[i], objects)
					end
				end
			end
		end
	end
	if useMergeSorter_gbl then 
		orderSeed, unitID_to_orderSeedMeta = merge_sort(orderSeed) --sort based on reachability distance, and also update unitID_to_orderSeedMeta table respectively
	end
	return orderSeed, objects, unitID_to_orderSeedMeta
end

local function SetCoreDistance(neighborsID, minimumNeighbor, unitID, myTeamID)
	if (#neighborsID ~= nil) and (#neighborsID >= minimumNeighbor) then
		local neighborsDist= {} --//table to list down neighbor's distance.
		for i=1, #neighborsID do
			local distance = spGetUnitSeparation (unitID, neighborsID[i])
			neighborsDist[i]= distance --//add distance value
		end
		local count = 1
		table.sort(neighborsDist, function(a,b) return a < b end)
		return neighborsDist[minimumNeighbor] --//return the distance of the minimumNeigbor'th unit with respect to the center unit.
	else
		return nil
	end
end

local function ExtractDBSCAN_Clustering (unitID, currentClusterID, cluster, noiseIDList, objects, neighborhoodRadius_alt)
	--// Precondition: neighborhoodRadius_alt <= generating dist neighborhoodRadius for Ordered Objects
	if (objects[unitID].reachability_distance or 999) > neighborhoodRadius_alt then --// UNDEFINED > neighborhoodRadius. ie: Not reachable from outside
		if (objects[unitID].core_distance or 999) <= neighborhoodRadius_alt then --//has neighbor
			currentClusterID = (currentClusterID or 0) + 1 --//create new cluster
			cluster[currentClusterID] = cluster[currentClusterID] or {} --//initialize array
			local arrayIndex = (#cluster[currentClusterID] or 0) + 1
			cluster[currentClusterID][arrayIndex] = unitID --//add to new cluster
		else --//if has no neighbor
			local arrayIndex = (#noiseIDList or 0) +1
			noiseIDList[arrayIndex]= unitID --//add to noise list
		end
	else --// object.reachability_distance <= neighborhoodRadius_alt. ie:reachable
		local arrayIndex = (#cluster[currentClusterID] or 0) + 1
		cluster[currentClusterID][arrayIndex] = unitID--//add to current cluster
	end

	return cluster, noiseIDList, currentClusterID
end

local function ExpandClusterOrder(receivedUnitList, unitID, neighborhoodRadius, neighborhoodRadius_alt, minimumNeighbor, myTeamID,objects, currentClusterID, cluster, noiseIDList)
	local neighborsID = GetNeighbor (unitID, myTeamID, neighborhoodRadius, receivedUnitList)
	objects[unitID].processed = true
	objects[unitID].reachability_distance = nil
	objects[unitID].core_distance = SetCoreDistance(neighborsID, minimumNeighbor, unitID, myTeamID)
	cluster, noiseIDList, currentClusterID = ExtractDBSCAN_Clustering (unitID, currentClusterID, cluster, noiseIDList, objects, neighborhoodRadius_alt)
	if objects[unitID].core_distance ~= nil then --//it have neighbor
		local orderSeed ={} 
		local unitID_to_orderSeedMeta = {}
		orderSeed, objects, unitID_to_orderSeedMeta = OrderSeedsUpdate(neighborsID, unitID, objects, orderSeed,unitID_to_orderSeedMeta)
		while #orderSeed > 0 do 
			local currentUnitID = orderSeed[#orderSeed].unitID
			objects[currentUnitID] = orderSeed[#orderSeed].content
			orderSeed[#orderSeed]=nil
			local neighborsID_ne = GetNeighbor (currentUnitID, myTeamID, neighborhoodRadius, receivedUnitList)
			objects[currentUnitID].processed = true
			objects[currentUnitID].core_distance = SetCoreDistance(neighborsID_ne, minimumNeighbor, currentUnitID, myTeamID)
			cluster, noiseIDList, currentClusterID = ExtractDBSCAN_Clustering (currentUnitID, currentClusterID, cluster, noiseIDList, objects, neighborhoodRadius_alt)
			if objects[currentUnitID].core_distance~=nil then
				orderSeed, objects,unitID_to_orderSeedMeta = OrderSeedsUpdate(neighborsID_ne, currentUnitID, objects, orderSeed, unitID_to_orderSeedMeta)
			end
		end
	end
	return objects, cluster, noiseIDList, currentClusterID
end

function WG.OPTICS_cluster (receivedUnitList, neighborhoodRadius, minimumNeighbor, myTeamID, neighborhoodRadius_alt) --//OPTIC_cluster function are accessible globally
	local objects={}
	local cluster = {}
	local noiseIDList = {}
	local currentClusterID = nil
	for unitID,_ in pairs(receivedUnitList) do --//go thru the un-ordered list
		objects[unitID] = objects[unitID] or {}
		if (objects[unitID].processed ~= true) then
			objects, cluster, noiseIDList, currentClusterID = ExpandClusterOrder(receivedUnitList,unitID, neighborhoodRadius, neighborhoodRadius_alt,minimumNeighbor, myTeamID,objects, currentClusterID, cluster, noiseIDList)
		end
	end
	--local cluster, noiseIDList = ExtractDBSCAN_Clustering (orderedFile, neighborhoodRadius_alt)
	return cluster, noiseIDList
end	

--DBSCAN function----------------------------------------------------------
--1 function. BUGGY (Not yet debugged)
function WG.DBSCAN_cluster(receivedUnitList,neighborhoodRadius,minimumNeighbor,myTeamID)
	local unitID_to_clusterMeta = {}
	local visitedUnitID = {}
	local currentCluster_global=1
	local cluster = {}
	local unitIDNoise = {}

	for unitID,_ in pairs(receivedUnitList) do --//go thru the un-ordered list
	
		if visitedUnitID[unitID] ~= true then --//skip if already visited
			visitedUnitID[unitID] = true
	
			local neighborUnits = GetNeighbor (unitID, myTeamID, neighborhoodRadius, receivedUnitList)
			
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
							
							local neighborUnits_ne = GetNeighbor (unitID_ne, myTeamID, neighborhoodRadius, receivedUnitList)
							
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
--code:  Msafwan
--Reference:
--http://en.wikipedia.org/wiki/OPTICS_algorithm ;pseudocode
--http://en.wikipedia.org/wiki/DBSCAN ;pseudocode
--http://codingplayground.blogspot.com/2009/11/dbscan-clustering-algorithm.html ;C++ sourcecode
--http://www.google.com.my/search?q=optics%3A+Ordering+Points+To+Identify+the+Clustering+Structure ;article & pseudocode on OPTICS
---------------------------------------------------------------------------------
---------------------------------E N D ------------------------------------------
---------------------------------------------------------------------------------
