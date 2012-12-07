local versionName = "v1.292"
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
    date      = "Jan 30, 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 20,
    enabled   = true  --  loaded by default?
  }
end
---------------------------------------------------------------------------------
--Imports------------------------------------------------------------------------
local osClock = os.clock
local spMarkerErasePosition = Spring.MarkerErasePosition
local spMarkerAddPoint = Spring.MarkerAddPoint
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitsInCylinder = Spring.GetUnitsInCylinder
local spAreTeamsAllied = Spring.AreTeamsAllied
local spValidUnitID = Spring.ValidUnitID
local spIsAABBInView = Spring.IsAABBInView
local spGetGameFrame  = Spring.GetGameFrame 

--Copied From gui_point_tracker.lua----------------------------------------------
local glLineWidth = gl.LineWidth
local glColor = gl.Color
local glDrawGroundCircle = gl.DrawGroundCircle
local glPopMatrix = gl.PopMatrix
local glPushMatrix = gl.PushMatrix
local spWorldToScreenCoords = Spring.WorldToScreenCoords
local abs = math.abs
local strSub = string.sub
local GL_FRONT_AND_BACK = GL.FRONT_AND_BACK
local GL_FILL = GL.FILL
local glShape = gl.Shape
local GL_TRIANGLES = GL.TRIANGLES
local glPolygonMode = gl.PolygonMode
local glText = gl.Text
--end----------------------------------------------------------------------------
---------------------------------------------------------------------------------
local myTeamID_gbl = -1 --//variable: myTeamID
local receivedUnitList_gbl = {} --//variable: store unitID and its corresponding unitPosition
local givenByTeamID_gbl = -1 --//variable: store sender's ID
local gameID_to_playerName_gbl = {}
local knownMarkerPosition_gbl  = {}
local knownCirclePosition_gbl = {}
local notifyCapture_gbl = {}
local knownMarkerPositionEMPTY_gbl = true --//variable: a flag. Used because those table did not start filling at index 1, thus unable to check them (with #) if it is truely empty or not.
local knownCirclePositionEMPTY_gbl = true --//variable: a flag
local receivedUnitListEMPTY_gbl = true --//variable: a flag

local minimumNeighbor_gbl = 3 --//constant: minimum neighboring (units) before considered a cluster
local neighborhoodRadius_gbl = 600 --//constant: neighborhood radius. Distance from each unit where neighborhoodList are generated. 
local radiusThreshold_gbl = 300 --//constant: density threshold where border is detected. Huge value means 2 cluster are combined, small value mean all unit disassociated
local waitConstant_gbl = 1 --//constant: default interval (in second) for 'widget:Update()' to be executed
local waitDuration_gbl = waitConstant_gbl --//variable: determine how frequently 'widget:Update()' is executed
local markerLife_gbl = 4 --//constant: wait (in second) before marker expired (to prevent clutter)
local circleLife_gbl = 6
local maximumLife_gbl = 20 --//constant: wait (in second) before marker & circle forcefully expired (to prevent clutter)
local useMergeSorter_gbl = false --//constant: experiment with merge sorter (slower)

local iNotLagging = true --//variable: indicate if player(me) is lagging in current game. If I'm lagging then do not count any received units (because I might be in state of rejoining and those units I saw are probably just a replay).

--Copied From gui_point_tracker.lua & minimap_event.lua--------------------------
local circleList_gbl =nil
local circleDivs =16
local lineWidth = 2  -- set to 0 to remove outlines
local vsX, vsY, sMidX,sMidY = 0,0,0,0 --//variable: screen size
local myColor_gbl = {0,0,0}
local edgeMarkerSize = 16
local on = true
local blinkPeriod = 0.25
local maxAlpha = 1
local ttl = 15
local timePart = 0
local fontSize = 16
local maxLabelLength = 16
--end----------------------------------------------------------------------------
WG.recvIndicator ={} --//allow global access
---------------------------------------------------------------------------------
--Add Marker---------------------------------------------------------------------
-- 1 function. 
local function AddMarker (cluster, unitIDNoise, receivedUnitList)
	local givenByTeamID = givenByTeamID_gbl
	local gameID_to_playerName = gameID_to_playerName_gbl
	local knownMarkerPosition = knownMarkerPosition_gbl
	local knownCirclePosition = knownCirclePosition_gbl
	local knownCirclePositionEMPTY = knownCirclePositionEMPTY_gbl
	------
	--// extract cluster information and add mapMarker.
	local currentIndex=0
	local playerName = gameID_to_playerName[givenByTeamID+1]
	local now = osClock()
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
		local label = unitCount .. " units received from ".. playerName
		spMarkerAddPoint(meanX,meanY,meanZ, label)
		knownMarkerPosition[(#knownMarkerPosition or 0)+1] = {meanX, meanY, meanZ, birth = now, age=0}
		knownMarkerPositionEMPTY = false
		
		radiiX = ((maxX - meanX)+ (meanX - minX))/2
		radiiZ = ((maxZ - meanZ)+ (meanZ - minZ))/2
		avgRadii = (radiiX + radiiZ) /2
		knownCirclePosition[(#knownCirclePosition or 0)+1] = {meanX, 0, meanZ, true, avgRadii+100, strSub(label, 1, maxLabelLength), birth = now, age=0, false} --//add circle
		knownCirclePositionEMPTY = false
		currentIndex = index
	end
	currentIndex=currentIndex+1
	
	if #unitIDNoise>0 then --//IF outlier list is not empty
		local addMarker = true
		local notIgnore = true
		local label = "Unit received from ".. playerName
		if #unitIDNoise >= 6 and currentIndex > 1 then --//IF the outlier list is greater than 5, and there already discernable cluster, then no need to add individual marker.
			addMarker = false
		end
		for j= 1 ,#unitIDNoise do
			local x,y,z=spGetUnitPosition(unitIDNoise[j])
			if x~=nil then --// exclude 'nil'. Unit under construction usually return 'nil'.
				if j>= 6 and currentIndex > 1 then --//IF current index is greater than 5, and there already discernable cluster, then no need to hi-light individual units.
					notIgnore=false
				end
				if addMarker then 
					spMarkerAddPoint(x,y,z, label)
					knownMarkerPosition[(#knownMarkerPosition or 0)+1] = {x, y, z,  birth = now, age = 0}
				end --// add marker
				knownCirclePosition[(#knownCirclePosition or 0)+1] = {x, 0, z, notIgnore, 100, strSub(label, 1, maxLabelLength), birth = now, age = 0}
				knownCirclePositionEMPTY = false
				currentIndex=currentIndex+1
			end
		end
	end
	------
	givenByTeamID_gbl = -1 --//reset value
	knownMarkerPosition_gbl = knownMarkerPosition
	knownCirclePosition_gbl = knownCirclePosition
	knownCirclePositionEMPTY_gbl = knownCirclePositionEMPTY
end

---------------------------------------------------------------------------------
--Periodic Function----------------------------------------------------------------
--3 functions
local elapsedTime = 0 --//variable: ...
function widget:Update(n)
	elapsedTime= elapsedTime + n
	timePart = timePart + n
	if (timePart > blinkPeriod and blinkPeriod > 0) then
		timePart = timePart - blinkPeriod
		on = not on
	end
	if elapsedTime < waitDuration_gbl then
		return
	end
	elapsedTime = 0
	local viewSizeX, viewSizeY = widgetHandler:GetViewSizes()
	widget:ViewResize(viewSizeX, viewSizeY)
	
	if (receivedUnitListEMPTY_gbl == false) then --// if 'receivedUnitList' is not empty: assume ALL unitID was received, calculate the cluster, and add marker.
		local receivedUnitList = receivedUnitList_gbl
		local myTeamID = myTeamID_gbl
		local minimumNeighbor = minimumNeighbor_gbl
		local neighborhoodRadius = neighborhoodRadius_gbl
		local radiusThreshold = radiusThreshold_gbl
		local cluster={}
		local unitIDNoise ={}
		------
		--cluster, unitIDNoise = DBSCAN_cluster (myTeamID, minimumNeighbor, neighborhoodRadius, cluster, receivedUnitList, unitIDNoise) --//method 1
		cluster, unitIDNoise = WG.recvIndicator.OPTICS_cluster (receivedUnitList, neighborhoodRadius, minimumNeighbor, myTeamID, radiusThreshold) --//method 2. Better
		AddMarker(cluster, unitIDNoise, receivedUnitList)
		------
		receivedUnitListEMPTY_gbl = true --//flag the table as empty
		waitDuration_gbl = waitConstant_gbl --// reset 'widget:Update()' update interval
		receivedUnitList_gbl = {} --//reset 'receivedUnitList' content
	end
	
	if (knownMarkerPositionEMPTY_gbl==false) then --//Function: delete marker when it expired
		local knownMarkerPosition = knownMarkerPosition_gbl
		local now = osClock()
		local markerLife = markerLife_gbl
		local maximumLife = maximumLife_gbl
		local waitDuration = waitDuration_gbl
		local knownMarkerPositionEMPTY = knownMarkerPositionEMPTY_gbl
		-----
		knownMarkerPositionEMPTY = true
		for i,_ in pairs(knownMarkerPosition) do
			if knownMarkerPosition[i] ~= nil then
				local x, y ,z = knownMarkerPosition[i][1], knownMarkerPosition[i][2], knownMarkerPosition[i][3]
				local inView = spIsAABBInView(x,y,z, x,y,z )
				if inView then --//if inView then calculate marker age and/or erase it
					local markerAge = knownMarkerPosition[i].age
					if markerAge >= markerLife then --//if marker age exceed marker life then delete it
						spMarkerErasePosition (x,y,z)
						knownMarkerPosition[i] = nil --//set to nil here so that next content (inserted using # will put it here, filling the space)
					else --//if marker age not yet exceed marker life then add age
						knownMarkerPosition[i].age = knownMarkerPosition[i].age +waitDuration
					end
				else --//if not in view: check for marker actual age
					local markerAge = now - knownMarkerPosition[i].birth
					if markerAge >= maximumLife then
						knownMarkerPosition[i] = nil
					end
				end
			end
			knownMarkerPositionEMPTY = false
		end
		-----
		knownMarkerPosition_gbl = knownMarkerPosition
		knownMarkerPositionEMPTY_gbl = knownMarkerPositionEMPTY
	end
	
	if (knownCirclePositionEMPTY_gbl== false) then --//Function: remove circle when it expired
		local knownCirclePosition = knownCirclePosition_gbl
		local now = osClock()
		local circleLife = circleLife_gbl
		local maximumLife = maximumLife_gbl
		local waitDuration = waitDuration_gbl
		local knownCirclePositionEMPTY = knownCirclePositionEMPTY_gbl
		-----
		knownCirclePositionEMPTY = true
		for i,_ in pairs(knownCirclePosition) do
			if knownCirclePosition[i] ~= nil then
				local x, y ,z = knownCirclePosition[i][1], knownCirclePosition[i][2], knownCirclePosition[i][3]
				local inView = spIsAABBInView(x,y,z, x,y,z )
				if inView then --//if inView then calculate circle age and/or erase it
					local circleAge = knownCirclePosition[i].age
					if circleAge >= circleLife then --//if circle age exceed circle life then delete it
						spMarkerErasePosition (x,y,z)
						knownCirclePosition[i] = nil --//set to nil here so that next content (inserted using # will put it here, filling the space)
					else --//if circle age not yet exceed circle life then add age
						knownCirclePosition[i].age = knownCirclePosition[i].age +waitDuration
					end
				else --//if not in view: check for circle actual age
					local circleAge = now - knownCirclePosition[i].birth
					if circleAge >= maximumLife then
						knownCirclePosition[i] = nil
					end
				end
			end
			knownCirclePositionEMPTY = false
		end
		-----
		knownCirclePosition_gbl = knownCirclePosition
		knownCirclePositionEMPTY_gbl = knownCirclePositionEMPTY
	end
end


function widget:UnitGiven(unitID, unitDefID, unitTeamID, oldTeamID) --//will be executed repeatedly if there's more than 1 unit transfer
	if iNotLagging then
		if spValidUnitID(unitID) and unitTeamID == myTeamID_gbl then --if my unit
			if spAreTeamsAllied(unitTeamID, oldTeamID) or notifyCapture_gbl[oldTeamID] then --if from my ally, or from a captured enemy unit
				--myTeamID_gbl = unitTeamID --//uncomment this and comment 'unitTeamID == myTeamID_gbl' (above) when testing
				notifyCapture_gbl[oldTeamID] = false
				local x,y,z = spGetUnitPosition(unitID)
				receivedUnitList_gbl[unitID]={x,y,z}
				receivedUnitListEMPTY_gbl = false --//flag the table as not empty
				givenByTeamID_gbl = oldTeamID
				waitDuration_gbl = 0.2 -- tell widget:Update() to wait 0.2 more second before start adding mapMarker
				elapsedTime = 0 -- tell widget:Update() to reset timer
			end
		end
	end
end

function widget:Initialize()
	local myPlayerID=Spring.GetMyPlayerID()
	local _, _, spec = Spring.GetPlayerInfo(myPlayerID)
	if spec then widgetHandler:RemoveWidget() return false end --//widget will not load if we are a spectator.
	
	----- localize global variable:
	local gameID_to_playerName = gameID_to_playerName_gbl
	local myTeamID = myTeamID_gbl
	local notifyCapture = notifyCapture_gbl
	local myColor = myColor_gbl
	-----
	-- local playerList = Spring.GetPlayerRoster() --//check playerIDList for players
	-- for i = 1, #playerList do
		-- local teamID = playerList[i][3]
		-- local playerName = playerList[i][1]
		-- gameID_to_playerName[teamID+1] = playerName
	-- end
	myTeamID = Spring.GetMyTeamID() --//get my teamID. Used to filter receivedUnitList from our own unit.
	local teamList = Spring.GetTeamList() --//check teamIDlist for AI
	for j= 1, #teamList do
		local teamID = teamList[j]
		notifyCapture[teamID] = true
		local _,playerID, _, isAI = Spring.GetTeamInfo(teamID)
		if isAI then
			local _, aiName = Spring.GetAIInfo(teamID)
			gameID_to_playerName[teamID+1] = aiName
		elseif not isAI then
			local playerName = Spring.GetPlayerInfo(playerID)
			gameID_to_playerName[teamID+1] = playerName
		end
	end
	
	--circleList_gbl = gl.CreateList(function() --Reference: minimap_events.lua (Dave Rodgers). Create circle
		-- gl.BeginEnd(GL.TRIANGLE_FAN, function() --//fill circle with opaque color
		  -- for i = 0, circleDivs - 1 do
			-- local r = 2.0 * math.pi * (i / circleDivs)
			-- local cosv = math.cos(r)
			-- local sinv = math.sin(r)
			-- gl.TexCoord(cosv, sinv)
			-- gl.Vertex(cosv, 0, sinv)
		  -- end
		-- end)
		-- if (lineWidth > 0) then --//outline circle
		  -- gl.BeginEnd(GL.LINE_LOOP, function()
			-- for i = 0, circleDivs - 1 do
			  -- local r = 2.0 * math.pi * (i / circleDivs)
			  -- local cosv = math.cos(r)
			  -- local sinv = math.sin(r)
			  -- gl.TexCoord(cosv, sinv)
			  -- gl.Vertex(cosv, 0, sinv)
			-- end
		  -- end)
		-- end
	  -- end)
	  local myPlayerID = Spring.GetMyTeamID()
	  local r, g, b = Spring.GetTeamColor(myPlayerID)
	  myColor = {r,g,b}
	-----
	gameID_to_playerName_gbl = gameID_to_playerName
	myTeamID_gbl = myTeamID
	notifyCapture_gbl = notifyCapture
	myColor_gbl = myColor
end

---------------------------------------------------------------------------------
--Widget's Turn-Off/On switch-----------------------------------------------------
--2 functions
function widget:PlayerChanged(playerID)
	if Spring.GetSpectatingState() then widgetHandler:RemoveWidget() end --//widget will unload when we become spectator.
end

function widget:GameProgress(serverFrameNum) --//see if me are lagging behind the server in the current game. If me is lagging then trigger a switch, (this switch will tell the widget to stop counting received units).
	local myFrameNum = spGetGameFrame()
	local frameNumDiff = serverFrameNum - myFrameNum
	if frameNumDiff > 120 then --// 120 frame means: a 4 second lag. Consider me is lagging if my frame differ from server by more than 4 second.
		iNotLagging = false
	else  --// consider me not lagging if my frame differ from server's frame for less than 4 second.
		iNotLagging = true
	end
end
---------------------------------------------------------------------------------
--Visual FX----------------------------------------------------------------
--3 functions
function widget:DrawScreen() --Reference: gui_point_tracker.lua (Evil4Zerggin)
	if #knownCirclePosition_gbl~= nil then
		for i,_ in pairs(knownCirclePosition_gbl) do
			local sX,sY,sZ = spWorldToScreenCoords(knownCirclePosition_gbl[i][1], knownCirclePosition_gbl[i][2], knownCirclePosition_gbl[i][3])
			if (sX >= 0 and sY >= 0 and sX <= vsX and sY <= vsY) then --if within view then: draw circle on screen
				-- glPushMatrix()
				-- glLineWidth(2)
				-- gl.Rotate(270, 1, 0, 0)
				-- glColor(myColor_gbl[1],myColor_gbl[2],myColor_gbl[3], 0.3)
				-- gl.Translate(sX, 0, sY)
				-- gl.Scale(knownCirclePosition_gbl[i][4], 1, knownCirclePosition_gbl[i][4])
				-- gl.CallList(circleList_gbl)
				-- glColor(1,1,1,1)
				-- glLineWidth(1)
				-- glPopMatrix()
			else --//if outside view then: draw arrow on edge of the screen
				glPushMatrix()
				glLineWidth(1)
				if (on) and (knownCirclePosition_gbl[i][4]) then
					local alpha = 1
					--alpha = maxAlpha * (os.clock() - knownCirclePosition_gbl[i][4]) / ttl
					glColor(myColor_gbl[1],myColor_gbl[2],myColor_gbl[3], alpha)
					--out of screen
					glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
					--flip if behind screen
					if (sZ > 1) then
						sX = sMidX - sX
						sY = sMidY - sY
					end
					local xRatio = sMidX / abs(sX - sMidX)
					local yRatio = sMidY / abs(sY - sMidY)
					local edgeDist, vertices, textX, textY, textOptions
					if (xRatio < yRatio) then
						edgeDist = (sY - sMidY) * xRatio + sMidY
						if (sX > 0) then
							vertices = {
								{v = {vsX, edgeDist, 0}},
								{v = {vsX - edgeMarkerSize, edgeDist + edgeMarkerSize, 0}},
								{v = {vsX - edgeMarkerSize, edgeDist - edgeMarkerSize, 0}},
							}
							textX = vsX - edgeMarkerSize
							textY = edgeDist - fontSize * 0.5
							textOptions = "rn"
						else
							vertices = {
								{v = {0, edgeDist, 0}},
								{v = {edgeMarkerSize, edgeDist - edgeMarkerSize, 0}},
								{v = {edgeMarkerSize, edgeDist + edgeMarkerSize, 0}},
							}
							textX = edgeMarkerSize
							textY = edgeDist - fontSize * 0.5
							textOptions = "n"
						end
					else
						edgeDist = (sX - sMidX) * yRatio + sMidX
						if (sY > 0) then
							vertices = {
								{v = {edgeDist, vsY, 0}},
								{v = {edgeDist - edgeMarkerSize, vsY - edgeMarkerSize, 0}},
								{v = {edgeDist + edgeMarkerSize, vsY - edgeMarkerSize, 0}},
							}
							textX = edgeDist
							textY = vsY - edgeMarkerSize - fontSize
							textOptions = "cn"
						else
							vertices = {
								{v = {edgeDist, 0, 0}},
								{v = {edgeDist + edgeMarkerSize, edgeMarkerSize, 0}},
								{v = {edgeDist - edgeMarkerSize, edgeMarkerSize, 0}},
							}
							textX = edgeDist
							textY = edgeMarkerSize
							textOptions = "cn"
						end
					end
					glShape(GL_TRIANGLES, vertices)
					glColor(1, 1, 1, alpha)
					glText(knownCirclePosition_gbl[i][6], textX, textY, fontSize, textOptions)
				end
				glColor(1,1,1,1)
				glLineWidth(1)
				glPopMatrix()
			end			
		end
	end
end

function widget:DrawWorld() --Reference: minimap_events.lua (Dave Rodgers), gfx_stereo3d.lua (Carrepairer, jK)
	if #knownCirclePosition_gbl~= nil then
		for i,_ in pairs(knownCirclePosition_gbl) do --// draw circle on the ground
			local x,y,z,r = knownCirclePosition_gbl[i][1], knownCirclePosition_gbl[i][2], knownCirclePosition_gbl[i][3], knownCirclePosition_gbl[i][5]
			local inView = spIsAABBInView(x-r,y-r,z-r, x+r,y+r,z+r )
			if inView and (on) then 
				glPushMatrix()
				glLineWidth(2)
				glColor(myColor_gbl[1],myColor_gbl[2],myColor_gbl[3], 0.3)
				glDrawGroundCircle(x,y,z, r, 32)
				glLineWidth(1)
				glColor(1,1,1,1)
				glPopMatrix()
			end
		end
	end
end

function widget:ViewResize(viewSizeX, viewSizeY)
	vsX = viewSizeX
	vsY = viewSizeY
	sMidX = viewSizeX * 0.5
	sMidY = viewSizeY * 0.5
end

function widget:Shutdown()
  gl.DeleteList(circleList_gbl)
end
---------------------------------------------------------------------------------
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

---------------------------------------------------------------------------------
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
---------------------------------------------------------------------------------
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
---------------------------------------------------------------------------------
--OPTICS function----------------------------------------------------------------
--5 function
local function OrderSeedsUpdate(neighborsID, currentUnitID,objects, orderSeed,unitID_to_orderSeedMeta)
	local c_dist = objects[currentUnitID].core_distance
	for i=1, #neighborsID do
		objects[neighborsID[i]]=objects[neighborsID[i]] or {}
		if (objects[neighborsID[i]].processed~=true) then
			local new_r_dist = math.ceil(c_dist, Spring.GetUnitSeparation(currentUnitID, neighborsID[i]))
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
			local distance = Spring.GetUnitSeparation (unitID, neighborsID[i])
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

function WG.recvIndicator.OPTICS_cluster (receivedUnitList, neighborhoodRadius, minimumNeighbor, myTeamID, neighborhoodRadius_alt) --//OPTIC_cluster function are accessible globally
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
---------------------------------------------------------------------------
--DBSCAN function----------------------------------------------------------
--1 function. Not yet debugged
function DBSCAN_cluster(myTeamID, minimumNeighbor, neighborhoodRadius, cluster, receivedUnitList, unitIDNoise)
	local unitID_to_clusterMeta = {}
	local visitedUnitID = {}
	local currentCluster_global=1

	for i=1, #receivedUnitList do --//go thru the ordered list
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
------------------------------------------------------------------------
--Reference:
--http://en.wikipedia.org/wiki/OPTICS_algorithm ;pseudocode
--http://en.wikipedia.org/wiki/DBSCAN ;pseudocode
--http://codingplayground.blogspot.com/2009/11/dbscan-clustering-algorithm.html ;C++ sourcecode
--http://www.google.com.my/search?q=optics%3A+Ordering+Points+To+Identify+the+Clustering+Structure ;article & pseudocode on OPTICS