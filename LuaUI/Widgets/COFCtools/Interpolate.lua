--a workaround for https://springrts.com/mantis/view.php?id=4650

local osClock			= os.clock;
local spGetCameraState	= Spring.GetCameraState
local spSetCameraState	= Spring.SetCameraState
local spGetTimer		= Spring.GetTimer
local spDiffTimers		= Spring.DiffTimers
local mathPi 				= math.pi

local beginCam = {px=nil,py=0,pz=0,rx=0,ry=0,rz=0,fov=0,time=0}
local deltaEnd = {px=nil,py=0,pz=0,rx=0,ry=0,rz=0,fov=0,time=0}
local targetCam = {px=0,py=0,pz=0,rx=0,ry=0,rz=0,dx=0,dy=0,dz=0,fov=0,name="",active=false}

function GetTargetCameraState()
	return targetCam
end

local function CopyState(cs, newState)
	cs.px = newState.px
	cs.py = newState.py
	cs.pz = newState.pz
	cs.rx = newState.rx
	cs.ry = newState.ry
	cs.rz = newState.rz
	cs.dx = newState.dx
	cs.dy = newState.dy
	cs.dz = newState.dz
	cs.fov = newState.fov
	cs.name = newState.name
end

local function NormalizeRotation(cs)
	--Note: Spring angle is between -mathPi to +mathPi
	-- so its not from 0 to 2*mathPi

	local fullCircle = 2*mathPi
	if cs.rx > mathPi then
		cs.rx = cs.rx - fullCircle
	elseif cs.rx < -mathPi then
		cs.rx = cs.rx + fullCircle
	end
	if cs.ry > mathPi then
		cs.ry = cs.ry - fullCircle
	elseif cs.ry < -mathPi then
		cs.ry = cs.ry + fullCircle
	end
	if cs.rz > mathPi then
		cs.rz = cs.rz - fullCircle
	elseif cs.rz < -mathPi then
		cs.rz = cs.rz + fullCircle
	end
end

function OverrideSetCameraStateInterpolate(cs,smoothness)
	Interpolate()
	beginCam.time = spGetTimer()
	deltaEnd.period = smoothness
	
	local now = Spring.GetCameraState()
	CopyState(beginCam, now)

	CopyState(targetCam, cs)
	NormalizeRotation(targetCam)
	targetCam.active = true
	
	deltaEnd.px = cs.px - now.px
	deltaEnd.py = cs.py - now.py
	deltaEnd.pz = cs.pz - now.pz
	deltaEnd.rx = cs.rx - now.rx
	deltaEnd.ry = cs.ry - now.ry
	deltaEnd.rz = cs.rz - now.rz
	deltaEnd.fov = cs.fov - now.fov
	
	NormalizeRotation(deltaEnd)
end

local function Add(vector1,vector2,factor)
	local newVector = {px=0,py=0,pz=0,rx=0,ry=0,rz=0,fov=0}
	newVector.px = vector1.px + vector2.px * factor
	newVector.py = vector1.py + vector2.py * factor
	newVector.pz = vector1.pz + vector2.pz * factor
	newVector.rx = vector1.rx + vector2.rx * factor
	newVector.ry = vector1.ry + vector2.ry * factor
	newVector.rz = vector1.rz + vector2.rz * factor
	newVector.fov = vector1.fov + vector2.fov * factor

	NormalizeRotation(newVector)

	return newVector
end

local function AddSpeed(cs,delta, tweenFact)
	cs.vx = delta.px * tweenFact
	cs.vy = delta.py * tweenFact
	cs.vz = delta.pz * tweenFact
	cs.avx = delta.rx * tweenFact
	cs.avy = delta.ry * tweenFact
	cs.avz = delta.rz * tweenFact
	cs.avelTime = delta.time
	cs.velTime = delta.time
end

local function DisableEngineTilt(cs)
	--Disable engine's tilt when we press arrow key and move mouse
	cs.tiltSpeed = 0
	cs.scrollSpeed = 0
end

--All algorithm is from "Spring/rts/game/CameraHandler.cpp"
function Interpolate()
	if not (targetCam.active) then return end

	local lapsedTime = spDiffTimers(spGetTimer(),beginCam.time);

	if ( lapsedTime >= deltaEnd.period) then
		local cs = spGetCameraState()
		CopyState(cs, targetCam)
		-- AddSpeed(cs,deltaEnd,0.5) 
		DisableEngineTilt(cs)
		spSetCameraState(cs,0)
		targetCam.active = false
	else
		if (deltaEnd.period > 0) then
			local timeRatio = (deltaEnd.period - lapsedTime) / (deltaEnd.period);
			local tweenFact = 1.0 - math.pow(timeRatio, 4);

			local newState = Add(beginCam,deltaEnd,tweenFact) --add changes to camera state in gradual manner
			local cs = spGetCameraState()
			CopyState(cs, newState)
			-- AddSpeed(cs,deltaEnd,tweenFact) --possibly make it look real/have drift effect
			DisableEngineTilt(cs)
			spSetCameraState(cs,0)
		end
	end
end