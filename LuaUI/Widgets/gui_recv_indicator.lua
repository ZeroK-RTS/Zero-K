local versionName = "v1.03"
--------------------------------------------------------------------------------
--
--  file:   gui_recv_indicator.lua
--  brief:   a clustering algorithm
--  algorithm: Ordering Points To Identify the Clustering Structure (OPTICS) by Mihael Ankerst, Markus M. Breunig, Hans-Peter Kriegel and Jörg Sander
--	algorithm: density-based spatial clustering of applications with noise (DBSCAN) by Martin Ester, Hans-Peter Kriegel, Jörg Sander and Xiaowei Xu
--	code:  Msafwan
--
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
function widget:GetInfo()
  return {
    name      = "Receive Units Indicator",
    desc      = versionName .. " Notify users of received units from unit transfer",
    author    = "msafwan",
    date      = "Jan 17, 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 20,
    enabled   = true  --  loaded by default?
  }
end

local myTeamID_gbl = -1 --//variable: myTeamID
local receivedUnitList = {} --//variable: store received unitID
local givenByTeamID_gbl = -1 --//variable: store sender's ID

local minimumNeighbor_gbl = 3 --//constant: minimum neighboring (units) before considered a cluster
local neighborhoodRadius_gbl = 600 --//constant: neighborhood radius. Distance from each unit where neighborhoodList are generated. 
local radiusThreshold_gbl = 400 --//constant: density threshold where border is detected. Huge value means 2 cluster are combined, small value mean all unit disassociated

---------------------------------------------------------------------------------
--Add Marker---------------------------------------------------------------------
-- 1 function. 
local function AddMarker (cluster, unitIDNoise)
	local givenByTeamID = givenByTeamID_gbl
	------
	--// extract cluster information and add mapMarker.
	local currentIndex=0
	local playerName = Spring.GetPlayerInfo(givenByTeamID)
	for index=1 , #cluster do
		local sumX, sumY,sumZ, unitCount,meanX, meanY, meanZ = 0,0 ,0 ,0 ,0,0,0
		for unitIndex=1, #cluster[index] do
			local x,y,z=Spring.GetUnitPosition(cluster[index][unitIndex])
			sumX= sumX+x
			sumY = sumY+y
			sumZ = sumZ+z
			unitCount=unitCount+1
		end
		meanX = sumX/unitCount --//calculate center of cluster
		meanY = sumY/unitCount
		meanZ = sumZ/unitCount
		Spring.MarkerAddPoint(meanX,meanY,meanZ, unitCount .. " units received from ".. playerName)
		currentIndex = index
	end
	currentIndex=currentIndex+1
	
	if currentIndex == 1 and unitIDNoise ~= nil then --//if there's no discernable cluster then add individual marker.
		for j= 1 ,#unitIDNoise do
			local x,y,z=Spring.GetUnitPosition(unitIDNoise[j])
			Spring.MarkerAddPoint(x,y,z, "Unit received from ".. playerName)
			currentIndex=currentIndex+1
		end
	end
	------
	givenByTeamID_gbl = -1 --//reset value
end

---------------------------------------------------------------------------------
--Spring Call-Ins----------------------------------------------------------------
--3 functions
local waitDuration = 10 --//variable: ...
local elapsedTime = 0 --//variable: ...
function widget:Update(n)
	elapsedTime= elapsedTime + n
	if elapsedTime < waitDuration then
		return
	end
	elapsedTime = 0
	if receivedUnitList~=nil then --// if 'receivedUnitList' is not empty: assume ALL unitID was received, calculate the cluster, and add marker.
		local myTeamID = myTeamID_gbl
		local minimumNeighbor = minimumNeighbor_gbl
		local neighborhoodRadius = neighborhoodRadius_gbl
		local cluster={}
		local unitIDNoise ={}
		------
		--cluster, unitIDNoise = DBSCAN_cluster (myTeamID, minimumNeighbor, neighborhoodRadius, cluster, receivedUnitList, unitIDNoise) --//method 1
		cluster, unitIDNoise = OPTICS_cluster (receivedUnitList, neighborhoodRadius, minimumNeighbor, myTeamID, neighborhoodRadius-200) --//method 2. Better
		AddMarker(cluster, unitIDNoise)
		------
		waitDuration = 10 --// disable widget:Update() by setting update to huge value. eg: 10 second
		receivedUnitList = {} --//reset 'receivedUnitList' content
	end
end

local timelapse = 0
function widget:UnitGiven(unitID, unitDefID, unitTeamID, oldTeamID) --//will be executed repeatedly if there's more than 1 unit transfer
	if unitTeamID == myTeamID_gbl then
		receivedUnitList[(#receivedUnitList or 0) +1]=unitID
		givenByTeamID_gbl = oldTeamID
		waitDuration = 0.1 --// tell widget:Update() to wait 0.1 more second before start adding mapMarker
		elapsedTime = 0 --// tell widget:Update() to reset timer
	end
end

function widget:Initialize()
	myTeamID_gbl = Spring.GetMyTeamID()
end
---------------------------------------------------------------------------------
--GetNeigbors--------------------------------------------------------------------
-- 1 function.
local function GetNeighbor (unitID, myTeamID, neighborhoodRadius, receivedUnitList) --//return the unitIDs of specific units around a center unit
	local x,_,z = Spring.GetUnitPosition(unitID)
	-- local unitDefID= Spring.GetUnitDefID(unitID)
	-- local unitDef= UnitDefs[unitDefID]
	-- local losRadius= unitDef.losRadius*32 --for some reason it was times 32
	local neighborUnits = Spring.GetUnitsInCylinder(x,z, neighborhoodRadius, myTeamID) --//use Spring to return the surrounding units' ID. Get neighbor. Ouput: unitID + my units
	local tempUnitList = {} --// try to filter out non-received units from neighbor receivedUnitList
	local isEmpty = true
	for k = 1, #neighborUnits do
		local match = false
		for j= 1, #receivedUnitList do
			if neighborUnits[k] ==receivedUnitList[j] then --and neighborUnits[k]~=unitID then --//if unit is among the received-unit-list, then accept
				match = true
				break
			end
		end
		if match then --//if unit is among the received-unit-list then remember it
			local unitListLenght = #tempUnitList or 0
			tempUnitList[unitListLenght+1] = neighborUnits[k]
		end
	end
	neighborUnits = tempUnitList
	return neighborUnits
end

---------------------------------------------------------------------------------
--OPTICS function----------------------------------------------------------------
--6 function
local function InsertOrderSeed (orderSeed, unitID_to_orderSeedMeta, unitID, objects) --//stack tiny values at end of table, and big values at start of table.
	local orderSeedLenght = #orderSeed or 0 --//code below can handle both: table of lenght 0 and >1
	local insertionIndex = orderSeedLenght
	for i = orderSeedLenght, 0, -1 do
		insertionIndex=i
		if i >0 then --//at index 0 don't check. Will get nil for sure.
			if orderSeed[i].content.reachability_distance > objects[unitID].reachability_distance then --//if existing value is abit bigger than to-be-inserted value: break
				break
			end
		end
	end
	insertionIndex = insertionIndex + 1 --//insert data just above that big value
	local buffer1 = orderSeed[insertionIndex] --//backup content of current index
	orderSeed[insertionIndex] = {unitID = unitID , content = objects[unitID]} --//replace current index with new value
	unitID_to_orderSeedMeta[unitID]=insertionIndex --//update meta table
	for j = insertionIndex, orderSeedLenght, 1 do --//shift content for content less-or-equal-to table lenght
		local buffer2 = orderSeed[j+1] --//save content of next index
		orderSeed[j+1] = buffer1 --//put backup value into next index
		unitID_to_orderSeedMeta[buffer1.unitID]=j+1 --// update meta table
		buffer1 = buffer2 --//use saved content as next backup, then repeat process
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

-- OrderSeeds::update(neighbors, CenterObject);
-- c_dist := CenterObject.core_distance;
-- FORALL Object FROM neighbors DO
-- IF NOT Object.Processed THEN
-- new_r_dist:=max(c_dist,CenterObject.dist(Object));
-- IF Object.reachability_distance=UNDEFINED THEN
-- Object.reachability_distance := new_r_dist;
-- insert(Object, new_r_dist);
-- ELSE // Object already in OrderSeeds
-- IF new_r_dist<Object.reachability_distance THEN
-- Object.reachability_distance := new_r_dist;
-- decrease(Object, new_r_dist);
-- END; // OrderSeeds::update

local function OrderSeedsUpdate(neighborsID, currentUnitID,objects, orderSeed,unitID_to_orderSeedMeta)
	local c_dist = objects[currentUnitID].core_distance
	for i=1, #neighborsID do
		objects[neighborsID[i]]=objects[neighborsID[i]] or {}
		if (objects[neighborsID[i]].processed~=true) then
			local new_r_dist = math.ceil(c_dist, Spring.GetUnitSeparation(currentUnitID, neighborsID[i]))
			if objects[neighborsID[i]].reachability_distance==nil then
				objects[neighborsID[i]].reachability_distance = new_r_dist
				orderSeed, unitID_to_orderSeedMeta = InsertOrderSeed (orderSeed, unitID_to_orderSeedMeta, neighborsID[i],objects)
			else --// object already in OrderSeeds
				if new_r_dist< objects[neighborsID[i]].reachability_distance then
					objects[neighborsID[i]].reachability_distance = new_r_dist
					orderSeed, unitID_to_orderSeedMeta = ShiftOrderSeed(orderSeed, unitID_to_orderSeedMeta, neighborsID[i], objects)
				end
			end
		end
	end
	--table.sort(orderSeed, function(a,b) return a.content.reachability_distance > b.content.reachability_distance end)
	return orderSeed, objects, unitID_to_orderSeedMeta
end

local function SetCoreDistance(neighborsID, minimumNeighbor, unitID, myTeamID)
	if #neighborsID ~= nil and #neighborsID >= minimumNeighbor then
		local neighborsDist= {}
		for i=1, #neighborsID do
			local _2ndUnitID =neighborsID[i]
			-- Spring.Echo("---")
			-- Spring.Echo(unitID)
			-- Spring.Echo(_2ndUnitID)
			local distance = Spring.GetUnitSeparation (unitID, _2ndUnitID)
			neighborsDist[i]= distance --//replace with distance value
		end
		table.sort(neighborsDist, function(a,b) return a < b end)
		return neighborsDist[minimumNeighbor] --//return the shortest distance to the minimumNeigbor'th unit.
	else
		return nil
	end
end

-- ExpandClusterOrder(SetOfObjects, Object, e, MinPts, OrderedFile);
-- neighbors := SetOfObjects.neighbors(Object, e);
-- Object.Processed := TRUE;
-- Object.reachability_distance := UNDEFINED;
-- Object.setCoreDistance(neighbors, e, MinPts);
-- OrderedFile.write(Object);
-- IF Object.core_distance <> UNDEFINED THEN
-- OrderSeeds.update(neighbors, Object);
-- WHILE NOT OrderSeeds.empty() DO
-- currentObject := OrderSeeds.next();
-- neighbors:=SetOfObjects.neighbors(currentObject, e);
-- currentObject.Processed := TRUE;
-- currentObject.setCoreDistance(neighbors, e, MinPts);
-- OrderedFile.write(currentObject);
-- IF currentObject.core_distance<>UNDEFINED THEN
-- OrderSeeds.update(neighbors, currentObject);
-- END; // ExpandClusterOrder

local function ExpandClusterOrder(receivedUnitList, unitID, neighborhoodRadius, minimumNeighbor,orderedFile, myTeamID,objects)
	local neighborsID = GetNeighbor (unitID, myTeamID, neighborhoodRadius, receivedUnitList)
	objects[unitID].processed = true
	objects[unitID].reachability_distance = nil
	objects[unitID].core_distance = SetCoreDistance(neighborsID, minimumNeighbor, unitID, myTeamID)
	orderedFile[(#orderedFile or 0) +1]= {unitID=unitID, content = objects[unitID]}
	if objects[unitID].core_distance ~= nil then
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
			orderedFile[(#orderedFile or 0) +1]= {unitID=currentUnitID, content = objects[currentUnitID]}
			if objects[currentUnitID].core_distance~=nil then
				orderSeed, objects,unitID_to_orderSeedMeta = OrderSeedsUpdate(neighborsID_ne, currentUnitID, objects, orderSeed, unitID_to_orderSeedMeta)
			end
		end
	end
	return orderedFile, objects
end

-- ExtractDBSCAN-Clustering (ClusterOrderedObjs,e, MinPts)
-- // Precondition: e' £ generating dist e for ClusterOrderedObjs
-- ClusterId := NOISE;
-- FOR i FROM 1 TO ClusterOrderedObjs.size DO
-- Object := ClusterOrderedObjs.get(i);
-- IF Object.reachability_distance > e THEN
-- // UNDEFINED > e
-- IF Object.core_distance £ e THEN
-- ClusterId := nextId(ClusterId);
-- Object.clusterId := ClusterId;
-- ELSE
-- Object.clusterId := NOISE;
-- ELSE // Object.reachability_distance £ e
-- Object.clusterId := ClusterId;
-- END; // ExtractDBSCAN-Clustering

local function ExtractDBSCAN_Clustering (clusterOrderedObjs, neighborhoodRadius_alt)
	--// Precondition: neighborhoodRadius_alt <= generating dist neighborhoodRadius for clusterOrderedObjs
	local clusterID = nil
	for i=1, #clusterOrderedObjs do
		--Spring.Echo(clusterOrderedObjs[i].unitID)
		local object = clusterOrderedObjs[i].content
		if (object.reachability_distance or 999) > neighborhoodRadius_alt then
			--// UNDEFINED > neighborhoodRadius
			if (object.core_distance or 999) <= neighborhoodRadius_alt then
				clusterID = (clusterID or 0) + 1
				object.clusterID = clusterID
			else
				object.clusterID = nil
			end
		else --// object.reachability_distance <= neighborhoodRadius_alt
			object.clusterID = clusterID
		end
		clusterOrderedObjs[i].content=object
	end
	
	local cluster = {}
	local noiseIDList = {}
	for i=1, #clusterOrderedObjs do
		local object = clusterOrderedObjs[i].content
		if (object.clusterID ~= nil) then 
			if cluster[object.clusterID] == nil then
				cluster[object.clusterID] = {}
			end
			local listLenght = (#cluster[object.clusterID] or 0) + 1
			cluster[object.clusterID][listLenght]= clusterOrderedObjs[i].unitID
		else 
			noiseIDList[(#noiseIDList or 0) +1]=clusterOrderedObjs[i].unitID
		end
	end
	return cluster, noiseIDList
end

-- Algorithm OPTICS
-- OPTICS (SetOfObjects, e, MinPts, OrderedFile)
-- OrderedFile.open();
-- FOR i FROM 1 TO SetOfObjects.size DO
-- Object := SetOfObjects.get(i);
-- IF NOT Object.Processed THEN
-- ExpandClusterOrder(SetOfObjects, Object, e,
-- MinPts, OrderedFile)
-- OrderedFile.close();
-- END; // OPTICS

function OPTICS_cluster (receivedUnitList, neighborhoodRadius, minimumNeighbor, myTeamID, neighborhoodRadius_alt)
	local orderedFile = {}
	local objects={}
	for i=1, #receivedUnitList do
		local unitID =receivedUnitList[i]
		objects[unitID] = objects[unitID] or {}
		if (objects[unitID].processed ~= true) then
			orderedFile,objects = ExpandClusterOrder(receivedUnitList,unitID, neighborhoodRadius,minimumNeighbor, orderedFile, myTeamID,objects)
		end
	end
	local cluster, unitIDNoise = ExtractDBSCAN_Clustering (orderedFile, neighborhoodRadius_alt)
	return cluster, unitIDNoise
end
	
---------------------------------------------------------------------------
--DBSCAN function----------------------------------------------------------
--1 function. Not yet debugged
function DBSCAN_cluster(myTeamID, minimumNeighbor, neighborhoodRadius, cluster, receivedUnitList, unitIDNoise)
	local unitID_to_clusterMeta = {}
	local visitedUnitID = {}
	local currentCluster_global=1

	for i=1, #receivedUnitList do
		local unitID = receivedUnitList[i]
		
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
------------------------------------------------------------------------
--OPTIC pseudocode 2----------------------------------------------------------------------
--[[ --Not yet debugged
local function update_optics(N, p, Seeds, eps, Minpts)
	local coredist = p.core_distance
	local unitID_to_Seeds={}
	for j=1, #N do
		local o = {unitID = N[1], reachability_distance= nil, processed=false}
		if (o.processed==false) then
		local new-reach-dist = math.ceil(coredist, Spring.GetUnitSeparation(p.unitID, o.unitID))
		if (o.reachability-distance == nil) --// o is not in Seeds
			  o.reachability-distance = new-reach-dist
			  Seeds[(#Seeds or 0) + 1) = o
		else               --// o in Seeds, check for improvement
			if (new-reach-dist < o.reachability-distance)
				o.reachability-distance = new-reach-dist
				Seeds, unitID_to_Seeds = ShiftOrderSeedUpward(Seeds, unitID_to_Seeds, o.unitID)
			end
		end
	end
	table.sort(Seeds, function(a,b) return a.reachability_distance > b.reachability_distance end)
	return Seeds
end

function OPTICS_second(DB, eps, MinPts, myTeamID)
	local orderedList={}
	for i=1, #DB do 
		local p = {unitID= DB[i], reachability_distance=nil, processed=false}
		if (p.processed==false) then
			local N = GetNeighbor(q.unitID, myTeamID, eps, DB)
			p.processed=true
			orderedList[(#orderedList or 0)+1]=p
			local Seeds = {}
			p.core_distance = SetCoreDistance(N, MinPts, p.unitID, myTeamID)
			if (p.core_distance ~= nil)
				Seeds = update_optics(N, p, Seeds, eps, Minpts)
				while #Seeds~=nil do 
					local q = Seeds[#Seeds]
					Seeds[#Seeds]=nil
					local N' = GetNeighbor (q.unitID, myTeamID, eps, DB)
					q.processed = true
					orderedList[(#orderedList or 0)+1]=q
					q.core_distance = SetCoreDistance(N', MinPts, q.unitID, myTeamID)
					if (q.core_distance ~= nil)
						Seeds = update_optics(N', p, Seeds, eps, Minpts)
					end
				end
			end
		end
	end	
end
--]]
------------------------------------------------------------------------
------------------------------------------------------------------------
--Reference:
--http://en.wikipedia.org/wiki/OPTICS_algorithm ;pseudocode
--http://en.wikipedia.org/wiki/DBSCAN ;pseudocode
--http://codingplayground.blogspot.com/2009/11/dbscan-clustering-algorithm.html ;C++ sourcecode
--http://www.google.com.my/search?q=optics%3A+Ordering+Points+To+Identify+the+Clustering+Structure ;article & pseudocode on OPTICS