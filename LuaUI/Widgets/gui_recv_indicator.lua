local versionName = "v1.294"
function widget:GetInfo()
  return {
    name      = "Receive Units Indicator",
    desc      = versionName .. " Notify users of received units from unit transfer",
    author    = "msafwan",
    date      = "Jan 30, 2012", --minor clean up: June 25, 2013
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
		cluster, unitIDNoise = WG.OPTICS_cluster (receivedUnitList, neighborhoodRadius, minimumNeighbor, myTeamID, radiusThreshold) --//method 2. Better (WG.OPTICS_cluster is located in api_shared_functions.lua)
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
	local _, _, spec = Spring.GetPlayerInfo(myPlayerID, false)
	if spec or Spring.GetModOptions().campaign_disable_share_marker then
		widgetHandler:RemoveWidget()
		return false
	end
	
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
		local _,playerID, _, isAI = Spring.GetTeamInfo(teamID, false)
		if isAI then
			local _, aiName = Spring.GetAIInfo(teamID)
			gameID_to_playerName[teamID+1] = aiName
		elseif not isAI then
			local playerName = Spring.GetPlayerInfo(playerID, false)
			gameID_to_playerName[teamID+1] = playerName or "Gaia"
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
