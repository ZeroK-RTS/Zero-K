--a workaround for https://springrts.com/mantis/view.php?id=4650

local spGetCameraState	= Spring.GetCameraState
local spSetCameraState	= Spring.SetCameraState
local spGetTimer		= Spring.GetTimer
local spDiffTimers		= Spring.DiffTimers
local mathPi 				= math.pi
local pow = math.pow

lockMode = {
	xy = 1,
	free = 2,
	xycenter = 3,
}

local beginCam = {px=nil,py=0,pz=0,rx=0,ry=0,rz=0,fov=0,time=0}
local deltaEnd = {px=nil,py=0,pz=0,rx=0,ry=0,rz=0,fov=0,time=0}
local targetCam = {px=0,py=0,pz=0,rx=0,ry=0,rz=0,dx=0,dy=0,dz=0,fov=0,name="",active=false}
local lockTarget = nil

MWIDTH, MHEIGHT = Game.mapSizeX, Game.mapSizeZ
mcx, mcz 	= MWIDTH / 2, MHEIGHT / 2
mcy 		= Spring.GetGroundHeight(mcx, mcz)
maxDistY = math.max(MHEIGHT, MWIDTH) * 2
mapEdgeBuffer = 1000

-----------------------------------------
--COFC correction functions
-----------------------------------------

function GetCenterBounds(cs)
	-- local currentFOVhalf_rad = (csnew.fov/2) * RADperDEGREE
	local maxDc = math.max((maxDistY - cs.py), 0)/(maxDistY - mapEdgeBuffer)-- * math.tan(currentFOVhalf_rad) * 1.5)
	-- Spring.Echo("MaxDC: "..maxDc)
	local minX, minZ, maxX, maxZ = math.max(mcx - MWIDTH/2 * maxDc, 0), math.max(mcz - MHEIGHT/2 * maxDc, 0), math.min(mcx + MWIDTH/2 * maxDc, MWIDTH), math.min(mcz + MHEIGHT/2 * maxDc, MHEIGHT)
	return minX, minZ, maxX, maxZ
end

local function CorrectLockpointCentering(cs, lockPoint) --For COFC's zoom out to center setting
	local vsx, vsy = widgetHandler:GetViewSizes()
	local cx,cy = vsx * 0.5,vsy * 0.5
	local dirx, diry, dirz = Spring.GetPixelDir(cx, cy)
	local distanceFactor = 0
	if diry ~= 0 then
		distanceFactor = (lockPoint.world.y - cs.py) / diry
	end
	dirx = dirx * distanceFactor
	diry = diry * distanceFactor
	dirz = dirz * distanceFactor
	lockPoint.worldCenter = {x = cs.px + dirx, y = cs.py + diry, z = cs.pz + dirz}
	-- lockPoint.worldCenter = {x = cg[1], y = cg[2], z = cg[3]}

	local minX, minZ, maxX, maxZ = GetCenterBounds(cs)
	local cdx, cdz = 0, 0
	-- local corrected = false
	if lockPoint.worldCenter.x < minX then cdx = minX - lockPoint.worldCenter.x ; lockPoint.worldCenter.x = minX end
	if lockPoint.worldCenter.x > maxX then cdx = maxX - lockPoint.worldCenter.x ; lockPoint.worldCenter.x = maxX end
	if lockPoint.worldCenter.z < minZ then cdz = minZ - lockPoint.worldCenter.z ; lockPoint.worldCenter.z = minZ end
	if lockPoint.worldCenter.z > maxZ then cdz = maxZ - lockPoint.worldCenter.z ; lockPoint.worldCenter.z = maxZ end
	-- if corrected then
		-- lockPoint.world.x = lockPoint.worldCenter.x
		-- lockPoint.world.z = lockPoint.worldCenter.z
	-- end
	-- Spring.Echo("lockPoint.world: {"..lockPoint.world.x..", "..lockPoint.world.z.."}")
	-- Spring.Echo("Bounds: x: "..minX.." - "..maxX..", z: "..minZ.." - "..maxZ..", lockPoint.worldCenter: {"..lockPoint.worldCenter.x..", "..lockPoint.worldCenter.z.."}")
	return cdx, cdz
end

local function InterpLockScreenWorldPoints(lockPoint, tweenFact)
	if not lockPoint.screen and lockPoint.screenBegin then lockPoint.screen = {x = lockPoint.screenBegin.x, y = lockPoint.screenBegin.y} end
	if lockPoint.screenBegin and lockPoint.screenEnd and tweenFact then
		if not lockPoint.screenDelta then
			lockPoint.screenDelta = {x = lockPoint.screenEnd.x - lockPoint.screenBegin.x, y = lockPoint.screenEnd.y - lockPoint.screenBegin.y}
		end
		lockPoint.screen.x = lockPoint.screenBegin.x + lockPoint.screenDelta.x * tweenFact
		lockPoint.screen.y = lockPoint.screenBegin.y + lockPoint.screenDelta.y * tweenFact
	end

	if not lockPoint.world and lockPoint.worldBegin then lockPoint.world = {x = lockPoint.worldBegin.x, y = lockPoint.worldBegin.y, z = lockPoint.worldBegin.z} end
	if lockPoint.worldBegin and lockPoint.worldEnd and tweenFact then
		if not lockPoint.worldDelta then
			lockPoint.worldDelta = {x = lockPoint.worldEnd.x - lockPoint.worldBegin.x, y = lockPoint.worldEnd.y - lockPoint.worldBegin.y, z = lockPoint.worldEnd.z - lockPoint.worldBegin.z}
		end
		lockPoint.world.x = lockPoint.worldBegin.x + lockPoint.worldDelta.x * tweenFact
		lockPoint.world.y = lockPoint.worldBegin.y + lockPoint.worldDelta.y * tweenFact
		lockPoint.world.z = lockPoint.worldBegin.z + lockPoint.worldDelta.z * tweenFact
	end
end

function GetLockpointCorrectionDelta(cs, lockPoint, tweenFact)
	local dx, dy, dz
	if lockPoint then
		-- Spring.Echo("lockPoint.screen: {"..lockPoint.screen.x..", "..lockPoint.screen.y.."}")
		InterpLockScreenWorldPoints(lockPoint, tweenFact)

		if lockPoint.worldCenter and lockPoint.mode == lockMode.xycenter then --This seems to be necessary to stop jittering with Zoomout from center
		 	CorrectLockpointCentering(cs, lockPoint)
		 	lockPoint.world.x = lockPoint.worldCenter.x
			lockPoint.world.z = lockPoint.worldCenter.z
		end

		if lockPoint.mode == lockMode.xy or lockPoint.mode == lockMode.xycenter then
			local dirx, diry, dirz = Spring.GetPixelDir(lockPoint.screen.x, lockPoint.screen.y)
			local distanceFactor = 0
			if diry ~= 0 then
				distanceFactor = (lockPoint.world.y - cs.py) / diry
			end
			dirx = dirx * distanceFactor
			diry = diry * distanceFactor
			dirz = dirz * distanceFactor
			local screenTargetInWorld = {x = cs.px + dirx, y = cs.py + diry, z = cs.pz + dirz}
			-- Spring.Echo("lockPoint.world: {"..lockPoint.world.x..", "..lockPoint.world.z.."}, screenTargetInWorld: {"..screenTargetInWorld.x..", "..screenTargetInWorld.z.."}")

			dx, dz = lockPoint.world.x - screenTargetInWorld.x, lockPoint.world.z - screenTargetInWorld.z
			-- Spring.Echo("lockPoint.screen: {"..lockPoint.screen.x..", "..lockPoint.screen.y.."}")
			-- Spring.Echo("d: {"..dx..", "..dz.."}")
		end
		if lockPoint.mode == lockMode.free then
			--When someone needs this, this is where to put in the correction mode that works on xyz
			--should be useful for orbiting/rotating around a point, but not necessary for tiltzoom
		end
	end
	return dx, dy, dz
end

local function CorrectLockpointCamera(cs, dx, dy, dz)
	cs.px = cs.px + dx
	if dy then cs.py = cs.py + dy end
	cs.pz = cs.pz + dz
	beginCam.px = beginCam.px + dx
	if dy then beginCam.py = beginCam.py + dy end
	beginCam.pz = beginCam.pz + dz
	targetCam.px = targetCam.px + dx
	if dy then targetCam.py = targetCam.py + dy end
	targetCam.pz = targetCam.pz + dz
	spSetCameraState(cs, 0)
end

local function CorrectToLockpoint(cs, tweenFact)
	if lockTarget and lockTarget.mode then
		local dx, dy, dz = GetLockpointCorrectionDelta(cs, lockTarget, tweenFact)
		CorrectLockpointCamera(cs, dx, dy, dz)

		--Theoretically this should handle zoom out to center for fromCursor and fromCenter, but it's
		--not the most numerically stable, so it's only enabled for fromCursor,
		--since fromCenter has another possible method that's less bouncy.
		if lockTarget.worldCenter and lockTarget.mode ~= lockMode.xycenter then
			dx, dz = CorrectLockpointCentering(cs, lockTarget)
			CorrectLockpointCamera(cs, dx, dy, dz)
		end
	end
end

-----------------------------------------
--External functions
-----------------------------------------

function GetTargetCameraState()
	--//Double-check no outside SetCameraTarget happened//--
	if not targetCam.active then
		local curr_px, curr_py, curr_pz = Spring.GetCameraPosition()
		targetCam.px = curr_px
		targetCam.py = curr_py
		targetCam.pz = curr_pz
	end

	return targetCam
end

function CopyState(cs, newState)
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

-----------------------------------------
--Internal helper functions
-----------------------------------------

local function NormalizeRotation(cs)
	--Note: Spring angle is between -mathPi to +mathPi
	-- so its not from 0 to 2*mathPi

	--failure?
	-- Spring.Echo('Failure - NormalizeRotation')
	if not cs.rx then Spring.Echo('Failure - OverrideSetCameraStateInterpolate'); return end

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

function OverrideSetCameraStateInterpolate(cs,smoothness, lockPoint)
	-- lockWorldTarget = worldTarget
	-- lockScreenTarget = screenTarget
	

	lockTarget = nil
	Interpolate()
	beginCam.time = spGetTimer()
	deltaEnd.period = smoothness
	
	local now = Spring.GetCameraState()
	CopyState(beginCam, now)
	
	--failure?
	if not cs.rx or not now.rx then Spring.Echo('Failure - OverrideSetCameraStateInterpolate'); return end

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

	if lockPoint then
		lockTarget = {}
		lockTarget.world = lockPoint.world
		lockTarget.worldCenter = lockPoint.worldCenter
		lockTarget.worldBegin = lockPoint.worldBegin
		lockTarget.worldEnd = lockPoint.worldEnd
		lockTarget.screen = lockPoint.screen
		lockTarget.screenBegin = lockPoint.screenBegin
		lockTarget.screenEnd = lockPoint.screenEnd
		lockTarget.mode = lockPoint.mode
	end
	
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
		CorrectToLockpoint(cs, tweenFact)
		targetCam.active = false
	else
		if (deltaEnd.period > 0) then
			local timeRatio = (deltaEnd.period - lapsedTime) / (deltaEnd.period);
			local tweenFact = 1.0 - pow(timeRatio, 4);

			local newState = Add(beginCam,deltaEnd,tweenFact) --add changes to camera state in gradual manner
			local cs = spGetCameraState()
			CopyState(cs, newState)
			-- AddSpeed(cs,deltaEnd,tweenFact) --possibly make it look real/have drift effect
			DisableEngineTilt(cs)
			spSetCameraState(cs,0)
			CorrectToLockpoint(cs, tweenFact)
		end
	end
end
