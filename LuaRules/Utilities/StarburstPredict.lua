
--[[
	Starburst Projectile Tracker:
	This attempts to perfectly recreate the engine's simulation of a starburst
	projectile.
	This is only truly accurate if you can see the projectile before it starts
	to turn, and if fired at a unit or feature, only while the unit or feature
	stays at its initial location.
	This only works with projectiles that do not track and have no acceleration.
	Caveat Emptor: Probably doesn't work for non-Trinity projectiles.

	USAGE:
	Call StarburstPredictPrecache(weaponDefID) prior to any use of a weaponDefID.
	Call StarburstPredict(projectileID, weaponDefID, curFrame) to receive
	  {impactX,impactY,impactZ,impactFrame}
--]]

--[[
	Starburst phases:
	1. Go up for `uptime` frames.
	2. Turn to hit target.
	  Turning applies until the dot product between where it's aiming and the ideal vector to the target exceeds 0.99f
	  Each frame, turn at a "turnrate" value, specified as wd.turnrate or the default of 0.06.
	  That is, take the current vector, add the ideal vector times the turnrate to it, then normalize the result.
	3. Hit target
	  Turning continues to apply if the dot product between the current vector and the ideal vector exceeds "maxGoodDif",
	  which is based on the tracking parameter maxGoodDif = cos(tracking). That is, when tracking is 0, maxGoodDif = 1.
	  Correction is based on the tracking parameter: no tracking value means no correction.
	  This means while solving this phase looks hard from the code, it's a simple linear function here.
--]]

local Echo = Spring.Echo
local GetProjectilePosition = Spring.GetProjectilePosition
local GetProjectileVelocity = Spring.GetProjectileVelocity
local GetProjectileTimeToLive = Spring.GetProjectileTimeToLive
local GetProjectileTarget = Spring.GetProjectileTarget
local GetUnitPosition = Spring.GetUnitPosition
local GetFeaturePosition = Spring.GetFeaturePosition

local g_CHAR = string.byte('g')
local u_CHAR = string.byte('u')
local f_CHAR = string.byte('f')

local UPDATES_PER_SECOND = 30

local initialFlightTime = {}
local uptime = {}
local turnRate = {}

local sqrt = math.sqrt

function StarburstPredictPrecache(weaponDefID)
	local weaponDef = WeaponDefs[weaponDefID]
	initialFlightTime[weaponDefID] = weaponDef.flightTime
	uptime[weaponDefID] = weaponDef.uptime * UPDATES_PER_SECOND - 1
	local myTurnRate = weaponDef.turnRate
	if not myTurnRate or myTurnRate == 0 then
		myTurnRate = 0.06
	end
	turnRate[weaponDefID] = myTurnRate
end

local function GetProjectileParameters(projectileID, weaponDefID,curFrame)
	local x,y,z = GetProjectilePosition(projectileID)
	local dx,dy,dz = GetProjectileVelocity(projectileID)
	local ttl = GetProjectileTimeToLive(projectileID)
	local ift = initialFlightTime[weaponDefID]
	local age = ift - ttl
	return x,y,z,dx,dy,dz,age
end

-- Vector helpers

local nrm_eps = 1e-12

local function SafeNormalize(dx,dy,dz,dist)
	if not dist then dist = sqrt(dx*dx+dy*dy+dz*dz) end
	if dist > nrm_eps then
		return dx/dist,dy/dist,dz/dist,dist
	end
	return dx,dy,dz,dist
end
local function Normalize(dx,dy,dz,dist)
	if not dist then dist = sqrt(dx*dx+dy*dy+dz*dz) end
	return dx/dist,dy/dist,dz/dist,dist
end

function StarburstPredict(projectileID, weaponDefID, curFrame, targetPosition)
	-- Initial projectile values
	local ix,iy,iz,idx,idy,idz,age = GetProjectileParameters(projectileID, weaponDefID, curFrame)
	local x,y,z,dx,dy,dz = ix,iy,iz,idx,idy,idz
	-- Target location
	local tx,ty,tz
	if targetPosition then
		tx,ty,tz = unpack(targetPosition)
	else
		local t, tpos = GetProjectileTarget(projectileID)
		-- Should always be 'g', but just to be robust about it
		if t == g_CHAR then
			tx,ty,tz = unpack(tpos)
		elseif t == u_CHAR then
			tx,ty,tz = GetUnitPosition(tpos)
		elseif t == f_CHAR then
			tx,ty,tz = GetFeaturePosition(tpos)
		else
			return nil
		end
	end
	-- Speed is constant
	local ndx,ndy,ndz,speed = Normalize(dx,dy,dz)

	--
	-- Stage 1: Shoot vertically upwards
	--
	local s1FramesRemaining = uptime[weaponDefID] - age
	y = y + s1FramesRemaining * dy

	--
	-- Stage 2: Rotate around with a fixed velocity to face the target
	--
	-- It's going to take some number of frames to turn.
	-- There is possibly a way to express multiple frames mathematically,
	-- but this isn't a calculation we need to do often.
	--
	local turnrate = turnRate[weaponDefID]

	-- check the optimal vector against our actual vector
	-- equiv: float3 targetErrorVec = (targetPos - pos).Normalize();
	local odx, ody, odz = Normalize(tx-x, ty-y, tz-z)
	-- We should never hit this, but just in case...
	local itersUntilGiveup = UPDATES_PER_SECOND * 10
	local s2FramesRemaining = 0
	repeat
		-- get a normalized vector of our direction
		-- equiv: dir	(always normalized before saving)
		-- get the wanted difference between our ideal vector and our current vector
		-- equiv: targetErrorVec = targetErrorVec - dir;
		local wddx, wddy, wddz = odx-ndx, ody-ndy, odz-ndz
		-- normalize this across how much we're pointing that way
		-- equiv: targetErrorVec = (targetErrorVec - (dir * (targetErrorVec.dot(dir)))).SafeNormalize()
		local dot = ndx*wddx + ndy*wddy + ndz*wddz
		wddx,wddy,wddz = wddx - ndx * dot, wddy - ndy * dot, wddz - ndz * dot
		-- ...and normalize that, too
		wddx,wddy,wddz = SafeNormalize(wddx, wddy, wddz)
		-- lets see how much we turn this frame. Add the two directions together, in proportion to our turnrate.
		-- equiv: dir = (dir + (targetErrorVec * weaponDef->turnrate)).Normalize()
		ndx,ndy,ndz = Normalize(ndx+wddx*turnrate,ndy+wddy*turnrate,ndz+wddz*turnrate)
		dx,dy,dz = ndx*speed, ndy*speed, ndz*speed

		-- Position is updated after trajectory is updated
		-- Equiv: CWorldObject::SetVelocity(dir * speed.w);
		--				SetPosition(pos + speed);
		x,y,z = x+dx,y+dy,z+dz
		s2FramesRemaining = s2FramesRemaining + 1
		itersUntilGiveup = itersUntilGiveup - 1

		-- done, recheck the start of the next "frame" to see whether we continue in stage 2 or not
		odx, ody, odz = Normalize(tx-x, ty-y, tz-z)
		dot = odx*ndx + ody*ndy + odz*ndz
	until dot > 0.99 or itersUntilGiveup < 0

	-- Stage 2 does one final frame where it sets the direction to the exact desired vector
	dx,dy,dz = odx*speed,ody*speed,odz*speed
	x,y,z = x+dx,y+dy,z+dz
	s2FramesRemaining = s2FramesRemaining + 1

	--
	-- Stage 3 - Go downwards in a straight line to the target
	--
	local distX, distY, distZ = tx-x, ty-y, tz-z
	local dist = sqrt(distX*distX + distY*distY + distZ*distZ)
	local s3FramesRemaining = dist / speed

	-- END OF PREDICTION

	local estimatedImpactFrame = curFrame + s1FramesRemaining + s2FramesRemaining + s3FramesRemaining

	-- Spring.Echo('Result', tx,ty,tz, curFrame, s1FramesRemaining, s2FramesRemaining, s3FramesRemaining, estimatedImpactFrame)

	return tx,ty,tz,estimatedImpactFrame
end
