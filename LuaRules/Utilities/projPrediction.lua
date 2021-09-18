local vector = Spring.Utilities.Vector
local spGetGroundHeight = Spring.GetGroundHeight
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitDirection = Spring.GetUnitDirection
local spGetFeaturePosition = Spring.GetFeaturePosition
local spGetProjectileTarget = Spring.GetProjectileTarget
local spGetProjectileGravity = Spring.GetProjectileGravity
local spGetProjectilePosition = Spring.GetProjectilePosition
local spGetProjectileVelocity = Spring.GetProjectileVelocity

local sqrt = math.sqrt
local TTYPE_U = string.byte("u") -- unit
local TTYPE_G = string.byte("g") -- ground
local TTYPE_F = string.byte("f") -- feature
local TTYPE_P = string.byte('p') -- projectile

local function GetProjectileGroundTarget(tArgs)
	return tArgs[1], tArgs[2], tArgs[3]
end

local ProjTTypeToPos = {
	[TTYPE_U] = spGetUnitPosition,
	[TTYPE_G] = GetProjectileGroundTarget,
	[TTYPE_F] = spGetFeaturePosition,
	[TTYPE_P] = spGetProjectilePosition,
}

local function GetProjectileTargetPos(tType, tArgs)
	return vector.New3(ProjTTypeToPos[tType](tArgs))
end

local function GetKinematicProjTimeTo(pPosY, pVelY, pGravity, height)
	local deltaY = pPosY - height
	local root = sqrt((pVelY * pVelY) - (2 * pGravity * deltaY))
	local multi = -1
	if deltaY < 0 then multi = 1 end
	return (-pVelY + (root * multi)) / pGravity
end

local function GetRawTarget(projID)
	local tType, tArgs = spGetProjectileTarget(projID)
	return GetProjectileTargetPos(tType, tArgs)
end

local function GetIntersectionTarget(projID)
	local tType, tArgs = spGetProjectileTarget(projID)
	local target, targetY = GetProjectileTargetPos(tType, tArgs)
	if tType == TTYPE_U then
		local uDir = vector.New3(spGetUnitDirection(tArgs))
		local pPos = vector.New3(spGetProjectilePosition(projID))
		local pVel = vector.New3(spGetProjectileVelocity(projID))
		local inter = vector.Intersection(target, uDir, pPos, pVel)
		if inter then
			return inter, spGetGroundHeight(inter[1], inter[2])
		end
	end
	return target, targetY
end

local function GetKinematicTarget(projID)
	local pGravity = spGetProjectileGravity(projID)
	local height = select(2, GetIntersectionTarget(projID))
	local pPos, pPosY = vector.New3(spGetProjectilePosition(projID))
	local pVel, pVelY = vector.New3(spGetProjectileVelocity(projID))
	local timeTo = GetKinematicProjTimeTo(pPosY, pVelY, pGravity, height)
	local target = vector.Add(pPos, vector.Mult(timeTo, pVel))
	return target, spGetGroundHeight(target[1], target[2])
end

local target = {
	["Cannon"] = GetKinematicTarget,
	["AircraftBomb"] = GetKinematicTarget,
	["MissileLauncher"] = GetIntersectionTarget,
	["StarburstLauncher"] = GetRawTarget,
	["BeamLaser"] = GetRawTarget,
}

local function GetKinematicAtHeight(projID, target, targetY, height)
	local pGravity = spGetProjectileGravity(projID)
	local pPos, pPosY = vector.New3(spGetProjectilePosition(projID))
	local pVel, pVelY = vector.New3(spGetProjectileVelocity(projID))
	local minETA = GetKinematicProjTimeTo(pPosY, pVelY, pGravity, height)
	if minETA ~= minETA or minETA <= 0 then
		return target, targetY
	end
	return vector.Add(pPos, vector.Mult(minETA, pVel)), height
end

local function GetLinearAtHeight(projID, target, targetY, height, dynamic)
	local pPos, pPosY = vector.New3(spGetProjectilePosition(projID))
	if dynamic then
		return pPos, pPosY
	end

	local pVel, pVelY = vector.New3(spGetProjectileVelocity(projID))
	local minETA = (pPosY - height) / pVelY
	if minETA > 0 then
		return vector.Add(pPos, vector.Mult(minETA, pVel)), targetY
	end
	return target, targetY
end

local function GetTargetAtHeight(projID, target, targetY)
	return target, targetY
end

local atHeight = {
	["Cannon"] = GetKinematicAtHeight,
	["AircraftBomb"] = GetKinematicAtHeight,
	["MissileLauncher"] = GetLinearAtHeight,
	["StarburstLauncher"] = GetTargetAtHeight,
	["BeamLaser"] = GetLinearAtHeight,
}

local projectilePrediction = {
	Target = target,
	AtHeight = atHeight,
}
return projectilePrediction
