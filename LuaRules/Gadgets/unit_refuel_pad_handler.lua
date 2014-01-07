function gadget:GetInfo()
	return {
		name    = "Refuel Pad Handler",
		desc    = "Replaces the engine implementation of the refuel pad.",
		author  = "Google Frog",
		date    = "5 Jan 2014",
		license = "GNU GPL, v2 or later",
		layer   = 0,
		enabled = true, -- loaded by default?
	}
end

if (not gadgetHandler:IsSyncedCode()) then
	return false -- no unsynced code
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetUnitBasePosition = Spring.GetUnitBasePosition
local spGetUnitHeading		= Spring.GetUnitHeading
local spGetUnitDefID 		= Spring.GetUnitDefID
local spSetUnitVelocity		= Spring.SetUnitVelocity
local spSetUnitLeaveTracks 	= Spring.SetUnitLeaveTracks 
local spGetUnitVelocity		= Spring.GetUnitVelocity
local spGetUnitRotation		= Spring.GetUnitRotation 

local mcSetRotationVelocity = Spring.MoveCtrl.SetRotationVelocity
local mcSetPosition	        = Spring.MoveCtrl.SetPosition
local mcSetRotation         = Spring.MoveCtrl.SetRotation
local mcDisable	            = Spring.MoveCtrl.Disable
local mcEnable	            = Spring.MoveCtrl.Enable

local coroutine = coroutine
local Sleep	    = coroutine.yield
local assert    = assert

-- South is 0 radians and increases counter-clockwise
local HEADING_TO_RAD = (math.pi*2/2^16)
local RAD_TO_HEADING = 1/HEADING_TO_RAD
local PI = math.pi
local cos = math.cos
local sin = math.sin
local acos = math.acos
local floor = math.floor
local sqrt = math.sqrt
local exp = math.exp

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local coroutines = {}

local function StartScript(fn)
	local co = coroutine.create(fn)
	coroutines[#coroutines + 1] = co
end

local function Circle(unitID, goal)
	local start = {spGetUnitBasePosition(unitID)}
	
	local unitDefID	= spGetUnitDefID(unitID)
	local ud = UnitDefs[unitDefID]
	
	local turnCircleRadius = 180
	local turnCircleRadiusSq = turnCircleRadius^2
	
	local _,_,_,maxSpeed = spGetUnitVelocity(unitID)
	local targetSpeed = ud.speed/30
	
	local heading = spGetUnitHeading(unitID)*HEADING_TO_RAD
	
	-- Find position of focus points for left or right turning circles 
	local leftFocus = {
		[1] = start[1] + turnCircleRadius*sin(heading + PI/2),
		[3] = start[3] + turnCircleRadius*cos(heading + PI/2)
	}
	
	local rightFocus = {
		[1] = start[1] + turnCircleRadius*sin(heading - PI/2),
		[3] = start[3] + turnCircleRadius*cos(heading - PI/2)
	}
	
	-- Decide upon direction to turn
	local leftDistSq = (goal[1] - leftFocus[1])^2 + (goal[3] - leftFocus[3])^2 
	local rightDistSq = (goal[1] - rightFocus[1])^2 + (goal[3] - rightFocus[3])^2 
	
	--Spring.MarkerAddPoint(leftFocus[1],0,leftFocus[3],sqrt(leftDistSq))
	--Spring.MarkerAddPoint(rightFocus[1],0,rightFocus[3],sqrt(rightDistSq))
	
	local turnDir -- 1 is left, -1 is right.
	local focus
	if rightDistSq < turnCircleRadiusSq then
		turnDir = 1
		focus = leftFocus
	elseif leftDistSq < turnCircleRadiusSq then
		turnDir = -1
		focus = rightFocus
	elseif leftDistSq < rightDistSq then
		turnDir = 1
		focus = leftFocus
	else
		turnDir = -1
		focus = rightFocus
	end
	
	-- Determine the equations of the two lines tangent to the circle passing through the goal.
	local fx,fz,gx,gz,r = focus[1], focus[3], goal[1], goal[3], turnCircleRadius
	
	local denom = (fx^2 - 2*fx*gx + gx^2 - r^2)
	if denom == 0 then
		denom = 0.0001
	end
	local determinateSqrt = sqrt(fx^2*r^2 + fz^2*r^2 - 2*fx*gx*r^2 + gx^2*r^2 - 2*fz*gz*r^2 + gz^2*r^2 - r^4)
	local otherBit = fx*fz - fz*gx - fx*gz + gx*gz
	
	local grad1 = (otherBit - determinateSqrt)/denom
	local grad2 = (otherBit + determinateSqrt)/denom
	
	-- Choose a line
	local gradToFocus = (fz - gz)/(fx == gx and 0.0001 or fx - gx)
	
	local grad
	if (grad1 < gradToFocus and gradToFocus < grad2) or (grad2 < gradToFocus and gradToFocus < grad1) then
		if grad1*turnDir < grad2*turnDir then
			grad = grad1
		else
			grad = grad2
		end
	else
		if grad1*turnDir < grad2*turnDir then
			grad = grad2
		else
			grad = grad1
		end
	end
	
	-- Find the intersection of the line and circle.
	local ix = (fx + fz*grad - gz*grad + gx*grad^2)/(1 + grad^2)
	local iz = grad*(ix-gx)+gz
	
	-- Find the angle to the intersection and the distance to it along the circle.
	local sAngle = (heading - turnDir*PI/2)
	local iAngle = acos((iz-fz)/turnCircleRadius) or PI/2
	if ix < fx then
		iAngle = -iAngle
	end
	iAngle = iAngle%(2*PI)
	
	local angularDist = turnDir*(iAngle - sAngle)%(2*PI)
	local circleDist = angularDist*turnCircleRadius

	-- Calculate linear distance after turning and vector to follow
	local lineDist = sqrt((gx - ix)^2 + (gz - iz)^2)
	local lineVectorX = (gx - ix)/lineDist
	local lineVectorZ = (gz - iz)/lineDist
	
	local totalDist = circleDist + lineDist
	
	-- Functions which determine position and direction based on distance travelled
	local function DistanceToPosition(distance)
		if distance < circleDist then
			return fx + turnCircleRadius*sin(sAngle + turnDir*distance/turnCircleRadius), fz + turnCircleRadius*cos(sAngle + turnDir*distance/turnCircleRadius)
		else
			return ix + (distance - circleDist)*lineVectorX, iz + (distance - circleDist)*lineVectorZ
		end
	end
	
	local linearDirection = acos(lineVectorZ)
	if lineVectorX < 0 then
		linearDirection = -linearDirection
	end
	
	local function DistanceToDirection(distance)
		if distance < circleDist then
			return heading + turnDir*distance/turnCircleRadius
		else
			return linearDirection
		end
	end
	
	-- Calculate speeds and acceleration
	local currentSpeed = maxSpeed
	local currentTime = 0
	
	local estimatedTime = (2*totalDist)/(maxSpeed+targetSpeed)
	local acceleration = (targetSpeed^2 - maxSpeed^2)/(2*totalDist)
	
	local function TimeToVerticalPositon(t)
		return start[2] + (goal[2] - start[2])*(1/(1 + exp(6*(-2*t/estimatedTime +1))))
	end
	
	--[[
	for i = 0, totalDist, maxSpeed do
		local px, pz = DistanceToPosition(i)
		Spring.MarkerAddPoint(px,0,pz,"")
	end
		
	Spring.MarkerAddLine(gx,0,gz,ix,0,iz)
	Spring.Echo(sqrt(lineVectorX^2 + lineVectorZ^2))
	--]]
	
	-- Roll Animation
	local _,_,roll = spGetUnitRotation(unitID)
	roll = -roll
	
	local rollStopFudgeDistance = maxSpeed*25
	local rollSpeed = 0.02
	local maxRoll = 1
	
	-- Move control stuff
	mcEnable(unitID)
	spSetUnitVelocity(unitID,0,0,0)
	mcSetRotation(unitID,0,heading,roll+currentTime/50)
	spSetUnitLeaveTracks(unitID, false)
		
	local currentDistance = 0

	local function LandLoop()
		
		local prevX, prevY, prevZ = start[1], start[2], start[3]
		
		while currentDistance < totalDist do
			local px, pz = DistanceToPosition(currentDistance)
			local py = TimeToVerticalPositon(currentTime)
			
			local direction = DistanceToDirection(currentDistance)
			
			mcSetRotation(unitID,0,direction,roll)
			mcSetPosition(unitID, px, py, pz)
			
			spSetUnitVelocity(unitID, px - prevX, py - prevY, pz - prevZ)
			
			currentDistance = currentDistance + currentSpeed
			currentSpeed = currentSpeed + acceleration
			currentTime = currentTime + 1
			
			if currentDistance < circleDist - rollStopFudgeDistance then
				if -roll*turnDir < maxRoll then
					roll = roll - turnDir*rollSpeed
				end
			else
				if -roll*turnDir > 0 then
					roll = roll + turnDir*rollSpeed
				elseif -roll*turnDir < -0.03 then
					roll = roll - turnDir*rollSpeed
				end
			end
			
			prevX, prevY, prevZ = px, py, pz
			Sleep()
		end
		
		local px, pz = DistanceToPosition(totalDist)
		mcSetPosition(unitID, px, goal[2], pz)
		
		spSetUnitLeaveTracks(unitID, true)
		spSetUnitVelocity(unitID, 0, 0, 0)
		mcDisable(unitID)
	end
	
	StartScript(LandLoop)
	
end

function gadget:AllowCommand_GetWantedCommand()
	return true
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return true
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if cmdID == CMD.ATTACK then
		Circle(unitID, {1000,113,1128})
		return false
	end
	return true
end

-- a bit convoluted for this but might be					 
-- useful for lua unit scripts
local function UpdateCoroutines() 
	local newCoroutines = {} 
	for i=1, #coroutines do 
		local co = coroutines[i] 
		if (coroutine.status(co) ~= "dead") then 
			newCoroutines[#newCoroutines + 1] = co 
		end 
	end 
	coroutines = newCoroutines 
	for i=1, #coroutines do 
		assert(coroutine.resume(coroutines[i]))
	end
end

function gadget:GameFrame(f)
	UpdateCoroutines()
end