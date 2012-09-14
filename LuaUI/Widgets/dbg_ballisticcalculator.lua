function widget:GetInfo()
  return {
    name      = "Ballistic Calculator",
    desc      = "Simulate & plot weapon's ballistic range & trajectory based on gravity setting (ie: myGravity) and velocity (ie:weaponVelocity). For weapon setting testing. \n\nInstruction: select any unit, press attack, hover mouse over ground (trajectory will be drawn), press I & O to decrease & increase myGravity respectively, press K & L to decrease & increase weaponVelocity respectively , M to activate high-trajectory.",
    author    = "msafwan", --using component from "gui_jumpjets.lua" by quantum,
    date      = "Sept 14 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 10000,
    enabled   = false,
  }
end

local customMyGravity = 130
local customWeaponVelocity = 232
local flightTime =0
local highTrajectory = false
local maximumRange = 0

local spGetActiveCommand = Spring.GetActiveCommand
local spGetMouseState = Spring.GetMouseState
local spTraceScreenRay = Spring.TraceScreenRay
local spGetModKeyState = Spring.GetModKeyState
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetCommandQueue = Spring.GetCommandQueue
function widget:DrawWorld()
	local _, activeCommand = spGetActiveCommand()
	if (activeCommand == CMD.ATTACK) then
		local mouseX, mouseY   = spGetMouseState()
		local category, arg    = spTraceScreenRay(mouseX, mouseY)
		local _, _, _, shift   = spGetModKeyState()
		local units = spGetSelectedUnits()
		for i=1,#units do
			DrawMouseArc(units[i], shift, category == 'ground' and arg)
		end
	end
end

local spGetUnitPosition = Spring.GetUnitPosition
function DrawMouseArc(unitID, shift, groundPos)
	if (not groundPos) then
		return
	end
	local queue = spGetCommandQueue(unitID)
	local deltaV = customWeaponVelocity
	if (not queue or #queue == 0 or not shift) then
		local unitPos = {spGetUnitPosition(unitID)}
		local dist = GetDist2D(unitPos, groundPos)
		local maxRange,_ = CalculateBallisticConstant(deltaV,customMyGravity)
		DrawArc(unitID, unitPos, groundPos, maxRange,dist, deltaV, customMyGravity)
		maximumRange = maxRange
	end
end

function GetDist2D(a, b)
  return ((a[1] - b[1])^2 + (a[3] - b[3])^2)^0.5
end

function CalculateBallisticConstant(deltaV,myGravity)
	local angle  = 0.707 --use test range of 45 degree for optimal launch
	--determine maximum range & time
	local xVel = math.cos(0.707)*deltaV --horizontal portion
	local yVel = math.sin(0.707)*deltaV --vertical portion
	local t = nil
	local yDist = 0 -- set vertical height of 0 (a round trip from 0 height to 0 height)
	local a = myGravity
	-- 0 = yVel*t - a*t*t/2
	-- 0 = (yVel)*t - (a/2)*t*t 
	local t1 = (-yVel + (yVel^2 - 4*(-a/2)*(-0))^0.5)/(2*(-a/2)) ---formula for finding root for quadratic equation. Ref: http://www.sosmath.com/algebra/quadraticeq/quadraformula/summary/summary.html
	local t2 = (-yVel - (yVel^2 - 4*(-a/2)*(-0))^0.5)/(2*(-a/2))
	xDist1 = xVel*t1 --distance travelled horizontally in "t" amount of time
	xDist2 = xVel*t2
	local maxRange = nil
	if xDist1>= xDist2 then
		maxRange=xDist1 --maximum range
		t=t1 --flight time
	else
		maxRange=xDist2 
		t=t2
	end
	--
	--Non-changing value so far: maxRange. This depends on: mapGravity and deltaV.
	--
	return maxRange, t --return maximum range and flight time.
end

local glVertex = gl.Vertex
local glColor = gl.Color
local glDrawGroundCircle = gl.DrawGroundCircle
local spGetGroundHeight = Spring.GetGroundHeight
local glBeginEnd = gl.BeginEnd
local glLineStipple = gl.LineStipple
local GL_LINE_STRIP = GL.LINE_STRIP
local yellow   = {  1,   1, 0.5,   1}
local green    = {0.5,   1, 0.5,   1}
local cachedResult = {nil,nil,nil}
local calculateNow= false
function DrawArc(unitID, start, finish, range, dist, deltaV, myGravity)
	--TODO: cache the correct trajectory, don't calculate it every DrawWorld frame. Is CPU intensive.
	
	--x, y, z direction to target
	local vector = {}
	for i=1, 3 do
		vector[i] = finish[i] - start[i]
	end
	--draw max range
	local col = yellow
	glColor(col[1], col[2], col[3], col[4])
	glDrawGroundCircle(start[1], start[2], start[3], range, 100)

	--calculate correct trajectory
	local correctAngle= cachedResult[1] or 0
	local yVelocity = cachedResult[2] or 0
	local horizontalSpeed = cachedResult[3] or 0	
	if calculateNow then --let GameFrame() control when to calculate this rather than letting it to DrawWorld()
		local goodValue = {deviation= 999}
		local searchPattern = {startAngle = 0.0, endAngle = 0.707, stepAngle = 0.005}
		if highTrajectory then 
			searchPattern= {startAngle = 0.707, endAngle = 1.57, stepAngle = 0.005}
		end
		for i= searchPattern.startAngle ,searchPattern.endAngle, searchPattern.stepAngle do
			local angle  = i
			local xVel = math.cos(angle)*deltaV
			local yVel = math.sin(angle)*deltaV
			local yDist = spGetGroundHeight(finish[1],finish[3]) - spGetGroundHeight(start[1],start[3])
			local a = myGravity
			local t1 = nil
			local t2 = nil
			-- yDist = yVel*t - a*t*t/2
			-- 0 = -yDist + (yVel)*t - (a/2)*t*t 
			t1 = (-yVel + (yVel^2 - 4*(-a/2)*(-yDist))^0.5)/(2*(-a/2))
			t2 = (-yVel - (yVel^2 - 4*(-a/2)*(-yDist))^0.5)/(2*(-a/2))
			local xDist1 = xVel*t1
			local xDist2 = xVel*t2
			if math.abs(xDist1 - dist) <= goodValue.deviation and t1>=0 then 
				goodValue[2] = angle
				goodValue[3] = xVel
				goodValue[4] = yVel
				goodValue[5]= t1
				goodValue.deviation = math.abs(xDist1 - dist)
			elseif math.abs(xDist2 - dist) <= goodValue.deviation and t2>=0 then 
				goodValue[2] = angle
				goodValue[3] = xVel
				goodValue[4] = yVel
				goodValue[5]= t2
				goodValue.deviation = math.abs(xDist2 - dist)
			end
		end
		correctAngle = goodValue[2]
		horizontalSpeed = goodValue[3]
		yVelocity = goodValue[4]
		flightTime= goodValue[5] or 0
		cachedResult[1] = correctAngle --update cache
		cachedResult[2] = yVelocity
		cachedResult[3] = horizontalSpeed
		calculateNow= false --wait for GameFrame()
	end
	if flightTime == 0 then
		Spring.Echo("Ballistic plot error: No solution found")
		return
	end
	
	--draw real time trajectory
	gl.DepthTest (true)
	glLineStipple('')
	glBeginEnd(GL_LINE_STRIP, DrawLoop, start, vector, green, dist, flightTime, yVelocity, horizontalSpeed, myGravity)
	glLineStipple(false)
	gl.DepthTest(false)

end

local lineProgress = 0
function DrawLoop(start, vector, color,dist, flightTime, yVelocity, horizontalSpeed, myGravity)
	glColor(color[1], color[2], color[3], color[4])
	local currentProjectilePosition = lineProgress
	--breakdown horizontal speed into x and z component.
	local directionxz_radian = math.atan2(vector[3]/dist, vector[1]/dist)
	local xVelocity = math.cos(directionxz_radian)*horizontalSpeed
	local zVelocity = math.sin(directionxz_radian)*horizontalSpeed
	local simStep = 0.017 --set resolution of the plot
	for i=0, currentProjectilePosition,simStep do

		local x = start[1] + xVelocity*i
		local y = start[2] + (yVelocity)*i - (myGravity/2)*i*i 
		local z = start[3] + zVelocity*i

		glVertex(x, y, z)
	end
	--lineProgress = lineProgress + 1sec, update at GameFrame()
	if lineProgress >= flightTime then
		lineProgress = 0
	end
end

local lastUpdate=0
function widget:GameFrame(n)
	lineProgress = lineProgress + (1/30)
	calculateNow =true
	if n- lastUpdate >= 30 then
		Spring.Echo("myGravity: ".. customMyGravity.. ", weaponVelocity: ".. customWeaponVelocity .. ", flightTime: " .. flightTime .. " ,maximumRange: ".. maximumRange)
		lastUpdate = n
	end
end

---using code from central_build_AI.lua by Troy H. Cheek
local incGravity = string.byte( "o" ) --"i" "o", "k" "l", "m"
local decGravity = string.byte( "i" )
local incVelocity = string.byte( "l" )
local decVelocity = string.byte( "k" )
local trajectory =  string.byte( "m" )
function widget:KeyPress(key, mods, isRepeat)
	if ( key == incGravity ) then 
		customMyGravity = customMyGravity + ((isRepeat and 1) or 0.01)
		return true
	elseif ( key == decGravity ) then
		customMyGravity = customMyGravity - ((isRepeat and 1) or 0.01)
		return true
	elseif ( key == incVelocity ) then
		customWeaponVelocity = customWeaponVelocity + ((isRepeat and 10) or 1)
		return true
	elseif ( key == decVelocity ) then
		customWeaponVelocity = customWeaponVelocity - ((isRepeat and 10) or 1)
		return true
	elseif ( key == trajectory ) then
		highTrajectory = not highTrajectory
		return true
	end
end