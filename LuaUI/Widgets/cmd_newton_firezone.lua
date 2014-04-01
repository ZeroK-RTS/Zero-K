local versionNum = '0.308'

function widget:GetInfo()
	return {
		name		= "Newton Firezone",
		desc 		= "v".. (versionNum) .."Adds the Firezone command for Newtons. Allies in an area are targeted.",
		author		= "wolas, xponen, Google Frog", --xponen (add crash location estimator)
		date		= "2013",
		license		= "GNU GPL, v2 or later",
		layer		= 20,
		handler		= true, --for adding customCommand into UI
		enabled		= true  --loaded by default?
	}
end

-- Based on Improved Newtons by wolas. ZK official version has less usage of pairs and a well integrated command instead of the hotkeys.
--------------
--CONSTANTS---
--------------
VFS.Include("LuaRules/Configs/customcmds.h.lua")

local checkRate = 2 -- how fast Newton retarget. Default every 2 frame. Basically you control responsives and accuracy. On big setups checkRate = 1 is not recomended + count your ping in
local newtonUnitDefID = UnitDefNames["corgrav"].id
local newtonUnitDefRange = UnitDefNames["corgrav"].maxWeaponRange
local calculateSimpleBallistic = Game.version:find('91.')
local mapGravity = Game.gravity/30/30
local goneBallisticThresholdSQ = 8^2 --square of speed (in elmo per frame) before ballistic calculator predict unit trajectory

local GL_LINE_STRIP = GL.LINE_STRIP
local glLineWidth = gl.LineWidth
local glColor = gl.Color
local glBeginEnd = gl.BeginEnd
local glVertex = gl.Vertex
local circleList 

local spTraceScreenRay = Spring.TraceScreenRay
local spGetGroundHeight = Spring.GetGroundHeight
local spGetMouseState = Spring.GetMouseState
local spGetUnitsInRectangle = Spring.GetUnitsInRectangle
local spGetUnitDefID = Spring.GetUnitDefID
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGiveOrderToUnitArray = Spring.GiveOrderToUnitArray
local spGetCommandQueue = Spring.GetCommandQueue
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitVelocity = Spring.GetUnitVelocity
--local ech = Spring.Echo

local floor = math.floor

local CMD_NEWTON_FIREZONE = 10283
local CMD_STOP_NEWTON_FIREZONE = 10284

local cmdFirezone = {
	id      = CMD_NEWTON_FIREZONE,
	type    = CMDTYPE.ICON_UNIT_OR_RECTANGLE,
	tooltip = 'Set a Newton firezone. Newtons will fire at all units in the area (including allies).',
	cursor  = 'Attack',
	action  = 'setfirezone',
	params  = { }, 
	texture = 'LuaUI/Images/commands/Bold/capture.png',
	params  = {CMD_ONOFF,CMD_REPEAT,CMD_MOVE_STATE,CMD_FIRE_STATE, CMD_RETREAT},  
}

local cmdStopFirezone = {
	id      = CMD_STOP_NEWTON_FIREZONE,
	type    = CMDTYPE.ICON ,
	tooltip = 'Disasociate Newton from current firezone.',
	cursor  = 'Stop',
	action  = 'cancelfirezone',
	params  = { }, 
	texture = 'LuaUI/Images/commands/Bold/stop.png',
	params  = {CMD_ONOFF,CMD_REPEAT,CMD_MOVE_STATE,CMD_FIRE_STATE, CMD_RETREAT},  
}
--------------
--VARIABLE----
--------------
local springPoints = {}			--[newtonGroupID] -> {points}
springPoints[100] = {y = 100}
springPoints[100] = nil
local tempPoints = {}

local groups = {count = 0, data = {}}

local newtonIDs = {} 		--[unitID] -> newtonGroupid
local newtonTrianglePoints = {}	--[unitID] -> { newtonTriangle Points}
local selectedNewtons = nil		--temprorary {newtons}

local intensivity = 255
local colorIndex = 0

local victim = {}
local groupTarget = {}
local victimStillBeingAttacked = {}
local victimLandingLocation = {}

local queueTrajectoryEstimate = {targetFrame=-1,unitList={}} --for use in scheduling the time to calculate unit trajectory

--local cmdRate = 0
--local cmdRateS = 0
local softEnabled = false	--if zero newtons has orders, uses less
local currentFrame = Spring.GetGameFrame()
--------------
--METHODS-----
--------------
local function LimitRectangleSize(rect,units)  --limit rectangle size to Newton's range
	local maxX = 0
	local minX = math.huge
	local maxZ = 0
	local minZ = math.huge
	for i = 1, #units do 
		local unitID = units[i]
		if spGetUnitDefID(unitID) == newtonUnitDefID then
			local x,_,z = spGetUnitPosition(unitID)
			if x + newtonUnitDefRange > maxX then
				maxX = x + newtonUnitDefRange
			end
			if z + newtonUnitDefRange > maxZ then
				maxZ = z + newtonUnitDefRange
			end
			if x - newtonUnitDefRange < minX then
				minX = x - newtonUnitDefRange
			end
			if z - newtonUnitDefRange < minZ then
				minZ = z - newtonUnitDefRange
			end
		end
	end
	rect.x = math.min(maxX,rect.x)
	rect.z = math.min(maxZ,rect.z)
	rect.x2 = math.min(maxX + 252,rect.x2)
	rect.z2 = math.min(maxZ + 252,rect.z2)
	rect.x = math.max(minX - 252,rect.x)
	rect.z = math.max(minZ - 252,rect.z)
	rect.x2 = math.max(minX,rect.x2)
	rect.z2 = math.max(minZ,rect.z2)
	return rect
end

local function FixRectangle(rect)
	rect.x = floor((rect.x+8)/16)*16
	rect.z = floor((rect.z+8)/16)*16
	rect.x2= floor((rect.x2+8)/16)*16
	rect.z2= floor((rect.z2+8)/16)*16

	rect.y_xy= spGetGroundHeight(rect.x, rect.z)
	rect.y_x2y2= spGetGroundHeight(rect.x2, rect.z2)
	rect.y_xy2= spGetGroundHeight(rect.x, rect.z2)
	rect.y_x2y= spGetGroundHeight(rect.x2, rect.z)

	if (rect.x2 < rect.x) then
		tmp = rect.x
		rect.x = rect.x2
		rect.x2 = tmp
		--Spring.Echo("fixed X")
	end
	if (rect.z2 < rect.z) then
		tmp = rect.z
		rect.z = rect.z2
		rect.z2 = tmp
		--Spring.Echo("fixed y")
	end
	return rect

end

local function PickColor()
	local color = {}
	ind = colorIndex % 6
	if colorIndex > 5 and ind == 0 then
		intensivity = floor(intensivity / 2)
	end

	if (ind == 0 ) then
		color[1] = intensivity
		color[2] = 0
		color[3] = 0
	elseif (ind == 1) then
		color[1] = 0
		color[2] = intensivity
		color[3] = 0
	elseif (ind == 2) then
		color[1] = 0
		color[2] = 0
		color[3] = intensivity
	elseif (ind == 3) then
		color[1] = intensivity
		color[2] = intensivity
		color[3] = 0
	elseif (ind == 4) then
		color[1] = intensivity
		color[2] = 0
		color[3] = intensivity
	elseif (ind == 5) then
		color[1] = 0
		color[2] = intensivity
		color[3] = intensivity
	end

	colorIndex = colorIndex + 1
	if colorIndex > 30 then
		colorIndex = 0
	end
	return color
end

local function RemoveDeadGroups(units)
	for i = 1, #units do 
		local unitID = units[i]
		if newtonIDs[unitID] then
			local groupID, index = newtonIDs[unitID].groupID, newtonIDs[unitID].index
			local groupData = groups.data[groupID]
			local newtons = groupData.newtons
			
			newtons.data[index] = newtons.data[newtons.count]
			newtonIDs[newtons.data[newtons.count]].index = index
			newtons.data[newtons.count] = nil
			newtons.count = newtons.count - 1
			
			newtonIDs[unitID] = nil
			newtonTrianglePoints[unitID] = nil
			
			if newtons.count == 0 then
				
				local egNewtons = groups.data[groups.count].newtons -- end group
				for j = 1, egNewtons.count do
					newtonIDs[egNewtons.data[j]].groupID = groupID
				end
				
				--displace/re-occupy dead group with another group
				victimStillBeingAttacked[groupID] = victimStillBeingAttacked[groups.count]
				victimStillBeingAttacked[groups.count] = nil
				groupTarget[groupID] = groupTarget[groups.count]
				groupTarget[groups.count] = nil
				
				groups.data[groupID] = groups.data[groups.count]
				groups.data[groups.count] = nil
				groups.count = groups.count - 1
				
				if groups.count == 0 then
					softEnabled = false
				end
			end
		end
	end
end

local function NewGroup(points)
	
	groups.count = groups.count + 1
	groups.data[groups.count] = {
		newtons = {count = #selectedNewtons, data = {}},
		points = points,
		color = PickColor(),
	}
	local newtons = groups.data[groups.count].newtons.data

	for i = 1, #selectedNewtons do
		local unitID = selectedNewtons[i]
		newtons[i] = unitID
		newtonIDs[unitID] = {groupID = groups.count, index = i}
		local x, y, z = spGetUnitPosition (unitID)
		newtonTrianglePoints[unitID] = {y,
			x - 15, z - 15,
			x, z + 15,
			x +15, z -15}
	end
end

-------------------------------------------------------------------
-------------------------------------------------------------------
--- COMMAND HANDLING

function widget:CommandNotify(cmdID, params, options)
	if selectedNewtons ~= nil then
		if (cmdID == CMD_NEWTON_FIREZONE) and #params > 3 and params[4] ~= 0 then
			local points = {}
			if #params > 4 then
				points.x = params[1]
				points.z = params[3]
				points.x2 = params[4]
				points.z2 = params[6]
			else
				local radius = params[4]
				points.x = params[1]
				points.z = params[3]
				local mx, my = spGetMouseState()
				local _, pos = spTraceScreenRay(mx,my, true)
				points.x2 = pos[1]
				points.z2 = pos[3]
			end
			points = LimitRectangleSize(points,selectedNewtons)
			points = FixRectangle(points)

			RemoveDeadGroups(selectedNewtons)
			NewGroup(points)
			
			softEnabled = true
		elseif (cmdID == CMD_STOP_NEWTON_FIREZONE) then
			RemoveDeadGroups(selectedNewtons)
		end
	end
end

function widget:SelectionChanged(selectedUnits)
	selectedNewtons = filterNewtons(selectedUnits)
end

function filterNewtons(units)
	local filtered = {}
	local n = 0
	for i = 1, #units do
		local unitID = units[i]
		if (newtonUnitDefID == spGetUnitDefID(unitID)) then
			n = n + 1
			filtered[n] = unitID
		end
	end
	if n == 0 then
		return nil
	else
		return filtered
	end
end

function widget:CommandsChanged()
	if selectedNewtons then
		local customCommands = widgetHandler.customCommands
		customCommands[#customCommands+1] = cmdFirezone
		customCommands[#customCommands+1] = cmdStopFirezone
	end
end
-------------------------------------------------------------------
-------------------------------------------------------------------
--- SPECTATOR CHECK
local function IsSpectatorAndExit()
	local _, _, spec = Spring.GetPlayerInfo(Spring.GetMyPlayerID())
	if spec then 
		Spring.Echo("Newton Firezone disabled for spectator.")
		widgetHandler:RemoveWidget(widget)
	end
end

function widget:PlayerChanged()
	if Spring.GetSpectatingState() and (not Spring.IsCheatingEnabled()) then 
		Spring.Echo("Newton Firezone disabled for spectator.")
		widgetHandler:RemoveWidget(widget) --input self (widget) because we are using handler=true,
	end
end
-------------------------------------------------------------------
-------------------------------------------------------------------
--- UNIT HANDLING

local function SquareDistance (points, target)
	local xCenter = (points.x2 + points.x)/2
	local zCenter = (points.z2 + points.z)/2
	local x,_,z = spGetUnitPosition(target)
	local diffX = xCenter - x
	local diffZ = zCenter - z
	return (diffX*diffX + diffZ*diffZ)
end

function widget:UnitDestroyed(unitID)
	if newtonIDs[unitID] ~= nil then
		RemoveDeadGroups({unitID})
	end
	if victimLandingLocation[unitID] then
		victimLandingLocation[unitID]= nil
	end
end

function widget:UnitDamaged(unitID, unitDefID, unitTeam,damage, paralyzer)
	if victim[unitID] then --is current victim of any Newton group?
		victim[unitID] = currentFrame + 90 --delete 3 second later (if nobody attack it afterward)
		
		--notify group that target is still being attacked
		for group=1, groups.count do
			if groupTarget[group] == unitID then
				victimStillBeingAttacked[group] = unitID --signal a "wait, this group is attacking this unit!"
			end
		end
		--ech("still being attacked")
		
		--estimate trajectory of any unit hit by weapon
		if currentFrame >= queueTrajectoryEstimate["targetFrame"] then
			queueTrajectoryEstimate["targetFrame"] = (currentFrame-(currentFrame % 15)) + 15 --"(frame-(frame % 15))" group continous integer into steps of 15. eg [1 ... 30] into [1,15,30]
		end
		queueTrajectoryEstimate["unitList"][unitID] = true
	end
end

function widget:GameFrame(n)
	currentFrame = n
	--if n % 30 == 0 then
	--	ech("cmdRate A=".. cmdRate .. " cmdRate S="  .. cmdRateS .. "   SUM=" .. cmdRate + cmdRateS)
	--	cmdRate = 0
	--	cmdRateS= 0
	--end

	-- estimate for recently launched units
	if queueTrajectoryEstimate["targetFrame"] == n then
		for unitID,_ in pairs(queueTrajectoryEstimate["unitList"]) do
			EstimateCrashLocation(unitID)
			queueTrajectoryEstimate["unitList"][unitID]=nil
		end
	end
	
	--empty whitelist to widget:UnitDamaged() monitoring
	for unitID, frame in pairs(victim) do
		if frame<=n then
			victim[unitID] = nil
		end
	end
	
	if softEnabled then --is disabled if group is empty
		-- update attack orders
		if n % checkRate == 0 then
			for g = 1, groups.count do
				local points = groups.data[g].points
				local newtons = groups.data[g].newtons.data
				if points ~= nil then
					local units = spGetUnitsInRectangle(points.x, points.z, points.x2, points.z2)
					local stop = true
					local unitToAttack = nil
					local shortestDistance = 999999
					for i = 1, #units do
						local unitID = units[i]
						local targetDefID = spGetUnitDefID(unitID)
						if (not targetDefID) or UnitDefs[targetDefID].speed > 0 then
							stop = false
							if victimStillBeingAttacked[g] == unitID then --wait signal from UnitDamaged() that a unit is still being pushed
								victimStillBeingAttacked[g] = nil--clear wait signal
								unitToAttack = nil
								break --wait for next frame until UnitDamaged() stop signalling wait. 
								--NOTE: there is periodic pause when Newton reload in UnitDamaged() (every 0.2 second), this allowed the wait signal to be empty and prompted Newton-groups to retarget.
							end
							--if (#cmdQueue>0) then
							--ech("attack " .. CMD.ATTACK)
							--ech("options " .. cmdQueue[1].options["coded"])
							--ech("params ")
							--ech( cmdQueue[1].params)
							--if cmdQueue[1].id == 10 then
							--	--ech"breaking"
							--	break
							--end
							--end
							-- spGiveOrderToUnitArray(newtons, CMD.ATTACK, {unitID}, {} )
							-- groupTarget[g] = unitID
							-- victim[unitID] = n + 90 --empty whitelist 3 second later
							--cmdRate = cmdRate +1
							--break
							
							local distToBoxCenter = SquareDistance (points, unitID)
							if distToBoxCenter < shortestDistance then --get smallest distance to box's center
								shortestDistance = distToBoxCenter --shortest square distance
								unitToAttack = unitID --shoot this unit at end of this loop
							end
						end
					end
					if unitToAttack and (groupTarget[g]~=unitToAttack) then --there are target, and target is different than previous target (prevent command spam)? 
						spGiveOrderToUnitArray(newtons, CMD.ATTACK, {unitToAttack}, {} ) --shoot unit
						groupTarget[g] = unitToAttack --flag this group as having a target!
						victimStillBeingAttacked[g] = nil --clear wait signal
						victim[unitToAttack] = n + 90 --add UnitDamaged() whitelist, and expire after 3 second later
					end
					if stop and groupTarget[g] then --no unit in the box, and still have target?
						local orders = spGetCommandQueue(newtons[1],1)[1]
						if orders and orders.id ==CMD.ATTACK and orders.params[1]==groupTarget[g] then --is currently attacking old target??
							spGiveOrderToUnitArray(newtons,CMD.STOP, {}, {}) --cancel attacking any out-of-box unit
							--cmdRateS = cmdRateS +1
							--ech("stop")
						end
						groupTarget[g] = nil --no target
						victimStillBeingAttacked[g] = nil --clear wait signal
					end
				end
			end
		end
	end
	
	if n % 150 == 0 then --recheck crash estimated location every 5 second
		for victimID, _ in pairs (victimLandingLocation) do
			local x,y,z = spGetUnitPosition(victimID)
			if x then
				local grndHeight = spGetGroundHeight(x,z) +30
				if y<= grndHeight then
					victimLandingLocation[victimID]=nil
				end
			else
				victimLandingLocation[victimID]=nil
			end
		end
	end
end

-------------------------------------------------------------------
-------------------------------------------------------------------
--- DRAWING

local function DrawRectangleLine(rect)
	glVertex(rect.x,rect.y_xy, rect.z)
	glVertex(rect.x2,rect.y_x2y, rect.z)
	glVertex(rect.x2,rect.y_x2y2, rect.z2)
	glVertex(rect.x,rect.y_xy2, rect.z2)
	glVertex(rect.x,rect.y_xy, rect.z)
end

local function DrawTriangle(triangle)
	glVertex(triangle[2], triangle[1], triangle[3])
	glVertex(triangle[4], triangle[1], triangle[5])
	glVertex(triangle[6], triangle[1], triangle[7])
	glVertex(triangle[2], triangle[1], triangle[3])
end

function widget:DrawWorld()
	if Spring.IsGUIHidden() then
		return
	end
	glLineWidth(2.0)
	glColor(1, 1, 0)
	if selectedNewtons then
		for g = 1, groups.count do
			local data = groups.data[g]
			local points = data.points
			local color = data.color
			local newtons = data.newtons
			glColor(color[1],color[2],color[3]) -- for some odd reason I see only 6 colors..
			glBeginEnd(GL_LINE_STRIP, DrawRectangleLine, points)
			for i = 1, newtons.count do
				glBeginEnd(GL_LINE_STRIP,DrawTriangle, newtonTrianglePoints[newtons.data[i]])
			end
		end
	end
	--for unitID, triangle in pairs ( newtonTrianglePoints) do
	--	glBeginEnd(GL_LINE_STRIP, DrawTriangle, triangle)
	--end
	
	------Crash location estimator---
	for victimID, position in pairs (victimLandingLocation) do
		local numAoECircles = 9
		local aoe = 100
		local alpha = 0.75
		for i=1,numAoECircles do   --Reference: draw a AOE rings , gui_attack_aoe.lua by Evil4Zerggin
			local proportion = (i/(numAoECircles + 1))
			local radius = aoe * proportion
			local alphamult = alpha*(1-proportion)
			glColor(1, 0, 0,alphamult)
			gl.PushMatrix()
				gl.Translate(position[1],position[2],position[3])
				gl.Scale(radius, radius, radius)
				gl.CallList(circleList)
			gl.PopMatrix()
		end
	end	
end

------Crash location estimator---
function EstimateCrashLocation(victimID)
	if not Spring.ValidUnitID(victimID) then
		return
	end
	local defID = spGetUnitDefID(victimID)
	if not UnitDefs[defID] or UnitDefs[defID].canFly then --if speccing with limited LOS or the unit can fly, then skip predicting trajectory.
		return
	end
	local xVel,yVel,zVel, compositeVelocity= spGetUnitVelocity(victimID)
	local currentVelocitySQ = (compositeVelocity and compositeVelocity^2 or (xVel^2+yVel^2+zVel^2)) --elmo per second square
	local gravity = mapGravity
	if currentVelocitySQ < goneBallisticThresholdSQ then --speed insignificant compared to unit speed
		victimLandingLocation[victimID]=nil
		return
	end
	local x,y,z = spGetUnitPosition(victimID)
	local future_locationX, future_locationZ, future_height
	if calculateSimpleBallistic then
		--Simple simulation:
		future_locationX, future_height,future_locationZ = SimulateWithoutDrag(xVel,yVel,zVel, x,y,z, gravity)
	else
		--HARDCORE simulation!:
		local radius = Spring.GetUnitRadius(victimID)
		local mass = UnitDefs[defID].mass
		local airDensity = 1.2/4 --see Spring/rts/Map/Mapinfo.cpp
		future_locationX, future_height,future_locationZ = SimulateWithDrag(xVel,yVel,zVel, x,y,z, gravity ,mass,radius, airDensity)
	end
	if future_locationX then
		victimLandingLocation[victimID]={future_locationX,future_height, future_locationZ}
	end
end

function widget:Initialize()
	IsSpectatorAndExit()
	
	local circleVertex = function() 
			local circleDivs, PI = 64 , math.pi
			for i = 1, circleDivs do
				local theta = 2 * PI * i / circleDivs
				glVertex(math.cos(theta), 0, math.sin(theta))
			end
		end
	local circleDraw = 	function() glBeginEnd(GL.LINE_LOOP, circleVertex ) end --Reference: draw a circle , gui_attack_aoe.lua by Evil4Zerggin
	circleList = gl.CreateList(circleDraw)
end

function widget:Shutdown()
	if circleList then
		gl.DeleteList(circleList)
	end
end
---------------------------------
---------------------------------
-- SIMULATION / Prediction
--a) simple balistic
function SimulateWithoutDrag(xVel,yVel,zVel, x,y,z,gravity)
	local hitGround=false
	local reachApex = false
	local iterationSoFar=1
	local step =5 --how much gameframe to skip (set how much gameframe does 1 iteration will represent)
	local maximumIteration = 360 --1 iteration crudely simulate 5 frame (skip 4 frame), therefore 360 iteration is roughly 2 minute simulation into future
	local future_locationX, future_locationZ, future_height= 0,0,0
	while (not hitGround and iterationSoFar < maximumIteration) do --not hit ground yet?
		local future_time = iterationSoFar*step
		future_locationX =xVel*future_time
		future_locationZ =zVel*future_time
		future_height =(yVel)*future_time - (gravity/2)*future_time*future_time 
		local groundHeight =spGetGroundHeight(future_locationX+x,future_locationZ+z)
		if gravity*future_time >= yVel then --is falling down phase?
			reachApex = true
		end
		if future_height+y <= groundHeight and reachApex then --reach ground & is falling down?
			hitGround = true
		end
		iterationSoFar = iterationSoFar +1
	end
	return future_locationX+x,future_height+y,future_locationZ+z
end
--b) complex balistic with airdrag
--SOURCE CODE copied from: 
--1) http://www2.hawaii.edu/~kjbeamer/
--2) http://www.codeproject.com/Articles/19107/Flight-of-a-projectile
--Some Theory from: 
--1) Kamalu J. Beamer ,"Projectile Motion Using Runge-Kutta Methods" PDF, 13 April 2013
--2) Vit Buchta, "Flight of Projectile" CodeProject article, 8 Jun 2007
--(No copyright licence was stated)

local function Vec2dot(X,Y) --a function that takes dot products of two specific vectors X and Y
  local tmp={hrzn=0,vert=0};
  tmp.hrzn = X.hrzn * Y.hrzn;
  tmp.vert = X.vert * Y.vert;
  return(tmp.hrzn+ tmp.vert);
end

local function Vec2sum(X,Y) --a function that adds two specific vectors X and Y
  local tmp={hrzn=0,vert=0};
  tmp.hrzn = X.hrzn + Y.hrzn;
  tmp.vert = X.vert + Y.vert;
  return(tmp);
end

local function Vec2sum4(W,X,Y,Z) --a function that sums four 3-vectors W,X,Y,Z
  local tmp={hrzn=0,vert=0};
  tmp.hrzn = W.hrzn + X.hrzn + Y.hrzn + Z.hrzn;
  tmp.vert = W.vert + X.vert + Y.vert + Z.vert;
  return(tmp);
end

local function Scalar_vec2mult(X,Y) --a function that multiplies vector Y by double X
  local tmp = {hrzn=0,vert=0};
  tmp.hrzn = X * Y.hrzn;
  tmp.vert = X * Y.vert;
  return(tmp);
end

local function f_x(t,x,v) --gives the formal definition of v = dx/dt
	return(v)
end

local function f_v(t,xold,vold,mass,area,gravity,airDensity) -- a function that returns acceleration as a function of x, v and all other variables; all based on force law
  local tmp = {hrzn=0,vert=0};
  local rho=1
  local b=(1.0/2.0)*airDensity*area*rho;
  local horizontalSign = -1*math.abs(vold.hrzn)/vold.hrzn
  local verticalSign = -1*math.abs(vold.vert)/vold.vert
  --MethodA: current spring implementation--
  tmp.hrzn = (b/mass)*(vold.hrzn^2)*horizontalSign;--horizontal is back-and-forth movement
  tmp.vert = -gravity+(b/mass)*(vold.vert^2)*verticalSign; --is vertical movement
  --MethodB: ideal implementation (more accurate to real airdrag, not implemented in spring)--
  -- local totalVelocity = math.sqrt(vold.hrzn^2+vold.vert^2)
  -- tmp.hrzn = (b/mass)*(totalVelocity^2)*(vold.hrzn/totalVelocity)*horizontalSign;
  -- tmp.vert = -g+(b/mass)*(totalVelocity^2)*(vold.vert/totalVelocity)*verticalSign; 
  return(tmp);
end

--4th order Runge-Kutta algorithm--
--Numerical method for differential equation--
--Algorithm:
--[[
for n=0,1,2....,N-1 do
	k1=stepSize * derivativeOfEquation(currentX,currentV)
	k2=stepSize * derivativeOfEquation(currentX+stepSize/2, currentV+k1/2)
	k3=stepSize * derivativeOfEquation(currentX+stepSize/2, currentV+k2/2)
	k4=stepSize * derivativeOfEquation(currentX+stepSize, currentV+k3)
	nextX = currentX + stepSize
	nextV = currentV + (k1+2*k2+2*k3+k4)/6
end
--]]
--For projectile simulation:
--The derivative of X is V (velocity), and the derivative of V is A (acceleration)
--the equation for A is given as the Drag equation while X and V is not available due to complexity
local function VecFRK4xv(ytype,t,xold, vold,dt,mass,area,gravity,airDensity)
	local k1x = Scalar_vec2mult(dt,f_x(t,xold,vold));
	local k1v = Scalar_vec2mult(dt,f_v(t,xold,vold,mass,area,gravity,airDensity));
	local k2x = Scalar_vec2mult(dt,f_x(t+dt/2.0,Vec2sum(xold,Scalar_vec2mult(0.5,k1x)),Vec2sum(vold,Scalar_vec2mult(0.5,k1v))));
	local k2v = Scalar_vec2mult(dt,f_v(t+dt/2.0,Vec2sum(xold,Scalar_vec2mult(0.5,k1x)),Vec2sum(vold,Scalar_vec2mult(0.5,k1v)),mass,area,gravity,airDensity));  
	local k3x = Scalar_vec2mult(dt,f_x(t+dt/2.0,Vec2sum(xold,Scalar_vec2mult(0.5,k2x)),Vec2sum(vold,Scalar_vec2mult(0.5,k2v))));
	local k3v = Scalar_vec2mult(dt,f_v(t+dt/2.0,Vec2sum(xold,Scalar_vec2mult(0.5,k2x)),Vec2sum(vold,Scalar_vec2mult(0.5,k2v)),mass,area,gravity,airDensity));
	local k4x = Scalar_vec2mult(dt,f_x(t+dt,Vec2sum(xold,k3x),Vec2sum(vold,k3v)));
	local k4v = Scalar_vec2mult(dt,f_v(t+dt,Vec2sum(xold,k3x),Vec2sum(vold,k3v),mass,area,gravity,airDensity));
	local k2x2 = Scalar_vec2mult(2.0,k2x);
	local k2v2 = Scalar_vec2mult(2.0,k2v);
	local k3x2 = Scalar_vec2mult(2.0,k3x);
	local k3v2 = Scalar_vec2mult(2.0,k3v);

	if (ytype==0) then
		return(Scalar_vec2mult((1.0/6.0),Vec2sum4(k1x,k2x2,k3x2,k4x)));
	else
		return(Scalar_vec2mult((1.0/6.0),Vec2sum4(k1v,k2v2,k3v2,k4v)));
	end
end

function SimulateWithDrag(velX,velY,velZ, x,y,z, gravity,mass,radius, airDensity)
	radius = radius *0.01 --in centi-elmo (centimeter, or 10^-2) instead of elmo. See Spring/rts/Sim/Objects/SolidObject.cpp  
	local horizontalVelocity = math.sqrt(velX^2+velZ^2)
	local horizontalAngle = math.atan2 (velX/horizontalVelocity, velZ/horizontalVelocity)
	local hrznAngleCos = math.cos(horizontalAngle)
	local hrznAngleSin = math.sin(horizontalAngle)

	local area=(radius*radius)*math.pi;

	local xold={hrzn=0,vert=0}; --position
	local vold={hrzn=0,vert=0}; --velocity
	local currPosition = {x=0,y=0,z=0}

	vold.hrzn = horizontalVelocity --initial horizontal component of velocity
	vold.vert = velY --initial vertical component of velocity

	xold.hrzn = 0.0; --initial at the origin
	xold.vert = 0.0;

	--PRINT OUT A TABLE OF TRAJECTORY:
	-- Spring.Echo("Time    dist-Pos    dist-Vel    vert-Pos    vert-Vel");
	-- Spring.Echo(t0.. " " .. xold.hrzn .. " " .. vold.hrzn .. " " .. xold.vert .. " " .. vold.vert);
	
	local t0 = 0; --initial frame
	local dt = 15; --frame increment
	local Tmax = 1800 --max 2 minute
	for t=t0,Tmax,dt do
		local xt = Vec2sum(xold,VecFRK4xv(0,t,xold,vold,dt,mass,area,gravity,airDensity));
		local vt = Vec2sum(vold,VecFRK4xv(1,t,xold,vold,dt,mass,area,gravity,airDensity));
		xold = xt;
		vold = vt;
		currPosition.x = xt.hrzn*hrznAngleSin + x --break down xt.hrzn (distance) into components. Note: math.sin for X and math.cos for Z due to orientation of x & z axis in Spring.
		currPosition.z = xt.hrzn*hrznAngleCos + z
		currPosition.y = xt.vert + y
		local groundHeight =spGetGroundHeight(currPosition.x,currPosition.z)
		if currPosition.y < groundHeight then --if the unit hits the ground, stop calculating...
			break;
		end
		-- Spring.Echo(t.. " " .. xold.hrzn .. " " .. vold.hrzn .. " " .. xold.vert .. " " .. vold.vert);
	end
	if xold.hrzn then
		return currPosition.x,currPosition.y ,currPosition.z
	end
	return
end