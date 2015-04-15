--a workaround for https://springrts.com/mantis/view.php?id=4650

local osClock			= os.clock;
local spGetCameraState	= Spring.GetCameraState
local spSetCameraState	= Spring.SetCameraState
local spGetTimer		= Spring.GetTimer
local spDiffTimers		= Spring.DiffTimers
local mathPi 				= math.pi

local beginCam = {px=nil,py=0,pz=0,rx=0,ry=0,rz=0,fov=0,time=0}
local deltaEnd = {px=nil,py=0,pz=0,rx=0,ry=0,rz=0,fov=0,time=0}
local targetCam = {px=nil,py=0,pz=0,rx=0,ry=0,rz=0,dx=0,dy=0,dz=0,fov=0}

function GetTargetCameraState()
	if targetCam.px then
		-- Spring.Echo("targetCam")
		local cs = {px=0,py=0,pz=0,rx=0,ry=0,rz=0,dx=0,dy=0,dz=0,fov=0}
		cs.px = targetCam.px
		cs.py = targetCam.py
		cs.pz = targetCam.pz
		cs.rx = targetCam.rx
		cs.ry = targetCam.ry
		cs.rz = targetCam.rz
		cs.dx = targetCam.dx
		cs.dy = targetCam.dy
		cs.dz = targetCam.dz
		cs.fov = targetCam.fov
		if cs.px then
			return cs
		end
	end
	return Spring.GetCameraState()
end

function OverrideSetCameraStateInterpolate(cs,smoothness)
		Interpolate()
	beginCam.time = spGetTimer()
	deltaEnd.period = smoothness
	
	local now = Spring.GetCameraState()
	beginCam.px = now.px
	beginCam.py = now.py
	beginCam.pz = now.pz
	beginCam.rx = now.rx
	beginCam.ry = now.ry
	beginCam.rz = now.rz
	beginCam.fov = now.fov
	
	targetCam.px = cs.px
	targetCam.py = cs.py
	targetCam.pz = cs.pz
	targetCam.rx = cs.rx
	targetCam.ry = cs.ry
	targetCam.rz = cs.rz
	targetCam.dx = cs.dx
	targetCam.dy = cs.dy
	targetCam.dz = cs.dz
	targetCam.fov = cs.fov
	
	deltaEnd.px = cs.px - now.px
	deltaEnd.py = cs.py - now.py
	deltaEnd.pz = cs.pz - now.pz
	deltaEnd.rx = cs.rx - now.rx
	deltaEnd.ry = cs.ry - now.ry
	deltaEnd.rz = cs.rz - now.rz
	deltaEnd.fov = cs.fov - now.fov
	
	local fullCircle = 2*mathPi
	if deltaEnd.rx > mathPi then
		deltaEnd.rx = deltaEnd.rx - fullCircle
	elseif deltaEnd.rx < -mathPi then
		deltaEnd.rx = deltaEnd.rx + fullCircle
	end
	if deltaEnd.ry > mathPi then
		deltaEnd.ry = deltaEnd.ry - fullCircle
	elseif deltaEnd.ry < -mathPi then
		deltaEnd.ry = deltaEnd.ry + fullCircle
	end
	if deltaEnd.rz > mathPi then
		deltaEnd.rz = deltaEnd.rz - fullCircle
	elseif deltaEnd.rz < -mathPi then
		deltaEnd.rz = deltaEnd.rz + fullCircle
	end
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
	
	--Note: Spring angle is between -mathPi to +mathPi
	-- so its not from 0 to 2*mathPi
	
	local fullCircle = 2*mathPi
	if newVector.rx > mathPi then
		newVector.rx = newVector.rx - fullCircle
	elseif newVector.rx < -mathPi then
		newVector.rx = newVector.rx + fullCircle
	end
	if newVector.ry > mathPi then
		newVector.ry = newVector.ry - fullCircle
	elseif newVector.ry < -mathPi then
		newVector.ry = newVector.ry + fullCircle
	end
	if newVector.rz > mathPi then
		newVector.rz = newVector.rz - fullCircle
	elseif newVector.rz < -mathPi then
		newVector.rz = newVector.rz + fullCircle
	end

	return newVector
end

local function CopyState(cs, newState)
	cs.px = newState.px
	cs.py = newState.py
	cs.pz = newState.pz
	cs.rx = newState.rx
	cs.ry = newState.ry
	cs.rz = newState.rz
	cs.fov = newState.fov
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
	if not (targetCam.px) then
		return
	end
	local lapsedTime = spDiffTimers(spGetTimer(),beginCam.time);

	if ( lapsedTime >= deltaEnd.period) then
		local cs = spGetCameraState()
		CopyState(cs, targetCam)
		-- AddSpeed(cs,deltaEnd,0.5) 
		DisableEngineTilt(cs)
		spSetCameraState(cs,0)
		targetCam.px = nil
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