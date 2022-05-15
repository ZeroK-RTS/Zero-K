local vector = Spring.Utilities.Vector
local spGetGroundHeight = Spring.GetGroundHeight
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitDirection = Spring.GetUnitDirection
local spGetFeaturePosition = Spring.GetFeaturePosition
local spGetProjectileTarget = Spring.GetProjectileTarget
local spGetProjectileGravity = Spring.GetProjectileGravity
local spGetProjectilePosition = Spring.GetProjectilePosition
local spGetProjectileVelocity = Spring.GetProjectileVelocity

local abs = math.abs
local sqrt = math.sqrt

local function GetKinematicProjTimeTo(velocity, acceleration, distance, multi)
	local root = (velocity * velocity) + (2 * acceleration * distance) * multi
	if root <= 0 then
		return 1
	end
	return (-velocity - sqrt(root)) / acceleration
end

local function GetKinematicETA(velocity, acceleration, distance)
	local eta = 1
	if distance >= 0 then
		eta = GetKinematicProjTimeTo(velocity, acceleration, distance, 1)
	elseif distance < 0 then
		distance = -distance
		eta = GetKinematicProjTimeTo(velocity, acceleration, distance, -1)
	end
	return eta
end

local function GetKinematic(projID, target, targetY, height, config)
	local pGravity = spGetProjectileGravity(projID)
	local pPos, pPosY = vector.New3(spGetProjectilePosition(projID))
	local pVel, pVelY = vector.New3(spGetProjectileVelocity(projID))
	local heightETA = GetKinematicETA(pVelY, pGravity, height - pPosY)
	local a = vector.Add(pPos, vector.Mult(heightETA, pVel))
	local targetETA = GetKinematicETA(pVelY, pGravity, targetY - pPosY)
	local b = vector.Add(pPos, vector.Mult(targetETA, pVel))
	return {a, height, b, targetY}, heightETA
end

local function GetLinear(projID, target, targetY, height, config)
	local pPos, pPosY = vector.New3(spGetProjectilePosition(projID))
	local pVel, pVelY = vector.New3(spGetProjectileVelocity(projID))
	local eta = 40
	local b = vector.Add(pPos, vector.Mult(eta, pVel))
	return {pPos, pPosY, b, targetY}, eta
end

local function GetTarget(projID, target, targetY, height, config)
	local _, pPosY = spGetProjectilePosition(projID)
	local _, pVelY = spGetProjectileVelocity(projID)
	local eta = -1
	if pVelY < 0 then
		eta = (pPosY - height) / -pVelY
	end
	local offset_target = {target[1] + 1, target[2] + 1}
	return {offset_target, targetY, target, targetY}, eta
end

local atHeight = {
	["Cannon"] = GetKinematic,
	["AircraftBomb"] = GetKinematic,
	["MissileLauncher"] = GetLinear,
	["StarburstLauncher"] = GetTarget,
	["BeamLaser"] = GetLinear,
}

local function ProjectileTargets(config, projID, target, targetY, height)
	return atHeight[config.wType](projID, target, targetY, height, config)
end

return ProjectileTargets