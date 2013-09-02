local versionNum = '0.300'

function widget:GetInfo()
	return {
		name		= "Newton Firezone",
		desc 		= "v".. (versionNum) .."Adds the Firezone command for Newtons. Allies in an area are targeted.",
		author		= "wolas, xponen, Google Frog", --xponen (add crash location estimator)
		date		= "2013",
		license		= "GNU GPL, v2 or later",
		layer		= 20,
		handler		= true,
		enabled		= true  --loaded by default?
	}
end

-- Based on Improved Newtons by wolas. ZK official version has less usage of pairs and a well integrated command instead of the hotkeys.

VFS.Include("LuaRules/Configs/customcmds.h.lua")

local checkRate = 2 -- spring has 30 frames per second, basically you
-- control responsives and accuracy.
-- On big setups checkRate = 1 is not recomended
-- + count your ping in
local newtonUnitDefID = UnitDefNames["corgrav"].id

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
local spGetUnitCommands = Spring.GetUnitCommands
local spGetUnitPosition = Spring.GetUnitPosition
--local ech = Spring.Echo

local CMD_NEWTON_FIREZONE = 10283

local floor = math.floor

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

local victim = nil
local victimStillBeingAttacked = false
local victimLandingLocation = {}

local estimateInFuture = {}

--local cmdRate = 0
--local cmdRateS = 0
local softEnabled = false	--if zero newtons has orders, uses less 

local cmdFirezone = {
	id      = CMD_NEWTON_FIREZONE,
	type    = CMDTYPE.ICON_UNIT_OR_RECTANGLE,
	tooltip = 'Set a Newton firezone. Newtons will fire at all units in the area (including allied).',
	cursor  = 'Attack',
	action  = 'setfirezone',
	params  = { }, 
	texture = 'LuaUI/Images/commands/Bold/capture.png',
	params  = {CMD_CLOAK,CMD_ONOFF,CMD_REPEAT,CMD_MOVE_STATE,CMD_FIRE_STATE, CMD_RETREAT},  
}

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

			points = FixRectangle(points)

			RemoveDeadGroups(selectedNewtons)
			NewGroup(points)
			
			softEnabled = true
		elseif cmdID == CMD.STOP or cmdID == CMD.ATTACK then
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
	end
end

-------------------------------------------------------------------
-------------------------------------------------------------------
--- UNIT HANDLING

function widget:UnitDestroyed(unitID)
	if newtonIDs[unitID] ~= nil then
		RemoveDeadGroups({unitID})
	end
	if victimLandingLocation[unitID] then
		victimLandingLocation[unitID]= nil
	end
end

function widget:UnitDamaged(unitID, unitDefID, unitTeam,damage, paralyzer
, weaponDefID, attackerID, attackerDefID, attackerTeam )
	if victim == unitID then
		victimStillBeingAttacked = true
		EstimateCrashLocation(unitID)
		local frame = Spring.GetGameFrame() + 10
		estimateInFuture[frame] = estimateInFuture[frame] or {}
		estimateInFuture[frame][unitID] = true
		--ech("still being attacked")
	end
end

function widget:GameFrame(n)
	--if n % 30 == 0 then
	--	ech("cmdRate A=".. cmdRate .. " cmdRate S="  .. cmdRateS .. "   SUM=" .. cmdRate + cmdRateS)
	--	cmdRate = 0
	--	cmdRateS= 0
	--end

	-- estimate for recently launched units
	if estimateInFuture[n] then
		for unitID,_ in pairs(estimateInFuture[n]) do
			EstimateCrashLocation(unitID)
		end
		estimateInFuture[n] = nil
	end
	
	if softEnabled then
		-- update attack orders
		if n % checkRate == 0 then
			for g = 1, groups.count do
				local points = groups.data[g].points
				local newtons = groups.data[g].newtons.data
				if points ~= nil then
					units = spGetUnitsInRectangle(points.x, points.z, points.x2, points.z2)
					stop = true
					for i = 1, #units do
						local unitID = units[i]
						if UnitDefs[spGetUnitDefID(unitID)].speed > 0 then
							stop = false
							if victimStillBeingAttacked then
								victimStillBeingAttacked = false
								break
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
							spGiveOrderToUnitArray(newtons, CMD.ATTACK, {unitID}, {} )
							victim = unitID
							--cmdRate = cmdRate +1

							break
						end
					end
					if stop and spGetUnitCommands(newtons[1],1)[1] ~= nil then
						spGiveOrderToUnitArray(newtons,CMD.STOP, {}, {})
						victim = nil
						--cmdRateS = cmdRateS +1
						--ech("stop")
					end
				end
			end
		end
	end
	
	if n % 150 == 0 then --recheck crash estimated location after 5 second
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
	if UnitDefs[defID].canFly then
		return
	end
	local xVel,yVel,zVel = Spring.GetUnitVelocity(victimID)
	local x,y,z = spGetUnitPosition(victimID)
	local gravity = Game.gravity/30/30
	if math.abs(yVel) < gravity*10 then --speed insignificant compared to gravity?
		victimLandingLocation[victimID]=nil
		return
	end
	local future_locationX, future_locationZ, future_height= 0,0,0
	local hitGround=false
	local reachApex = false
	local iterationSoFar=1
	local step =5 --how much gameframe to skip (set how much gameframe does 1 iteration will represent)
	local maximumIteration = 360 --1 iteration crudely simulate 5 frame (skip 4 frame), therefore 360 iteration is roughly 2 minute simulation into future
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
	victimLandingLocation[victimID]={future_locationX+x,future_height+y, future_locationZ+z}
end

function widget:Initialize()
	local circleVertex = 
		function() 
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
	gl.DeleteList(circleList)
end