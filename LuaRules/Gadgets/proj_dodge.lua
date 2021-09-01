function gadget:GetInfo()
	return {
    name = "Projectile Dodge",
    desc = "calculates projectile dodge vector for units",
    author = "petturtle",
    date = "2021",
    layer = 0,
    enabled = true
	}
end

local DEBUG = false

if gadgetHandler:IsSyncedCode() then


local Kinematics = include("LuaRules/Utilities/kinematics.lua")
local Config = include("LuaRules/Configs/proj_targets_config.lua")

local vector = Spring.Utilities.Vector
local spIsPosInLos = Spring.IsPosInLos
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitRadius = Spring.GetUnitRadius
local spGetUnitHeight = Spring.GetUnitHeight
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitAllyTeam = Spring.GetUnitAllyTeam
local spGetProjectileDefID = Spring.GetProjectileDefID
local spGetProjectileGravity = Spring.GetProjectileGravity
local spGetProjectilePosition = Spring.GetProjectilePosition
local spGetProjectileVelocity = Spring.GetProjectileVelocity

local QUERY_RADIUS = 600
local SAFETY_DISTANCE = 30
local CANNON = "Cannon"
local AircraftBomb = "AircraftBomb"
local MISSILE = "MissileLauncher"
local StarburstLauncher = "StarburstLauncher"
local BEAMLASER = "BeamLaser"

local cos = math.cos
local max = math.max
local min = math.min
local hitDataCache = {}

local function GetHitData(projID, unitID)
	local unitDefID = spGetUnitDefID(unitID)
	local pData = GG.ProjTargets.GetData(projID)
	if hitDataCache[projID][unitDefID] and pData.config.dynamic == false then
		return hitDataCache[projID][unitDefID]
	end

	local uHeight = spGetUnitHeight(unitID)
	local pPos, pPosY = vector.New3(spGetProjectilePosition(projID))
	local pVel, pVelY = vector.New3(spGetProjectileVelocity(projID))

	local min, minY
	if pData.config.wType == CANNON or pData.config.wType == AircraftBomb then
		local pGravity = spGetProjectileGravity(projID)
		local heightDiff = pPosY - uHeight - pData.y
		local multi = -1
		if heightDiff < 0 then multi = 1 end
			local minETA = Kinematics.TimeToHeight(pVelY, pGravity, heightDiff, multi)
		if minETA ~= minETA or minETA <= 0 then
			min, minY = pData.pos, pData.y
		else
			min, minY = vector.Add(pPos, vector.Mult(minETA, pVel)), pData.y + uHeight
		end
	elseif pData.config.wType == MISSILE then
		local minETA = (pPosY - uHeight) / pVelY
		if pVelY < 0 and minETA > 0 then
			min = vector.Add(pPos, vector.Mult(minETA, pVel))
			minY = pData.y + uHeight
		elseif pData.config.dynamic then
			min, minY = pPos, pPosY
		else
			min, minY = pData.pos, pData.y
		end
	elseif pData.config.wType == StarburstLauncher then
		min, minY = pData.pos, pData.y
	elseif pData.config.wType == BEAMLASER then
		local minETA = (pPosY - uHeight) / pVelY
		if minETA > 0 then
			min = vector.Add(pPos, vector.Mult(minETA, pVel))
			minY = pData.y + uHeight
		else
			min, minY = pData.pos, pData.y
		end
	end

	local dist = vector.DirectionTo(pData.pos, min)
	local uRadius = spGetUnitRadius(unitID)
	local hitData = {
		max = pData.pos,
		maxY = pData.y,
		min = min,
		minY = minY,
		dist = dist,
		distLength = vector.Mag(dist),
		aoe = pData.config.aoe + uRadius + SAFETY_DISTANCE
	}

	hitDataCache[projID][unitDefID] = hitData
	return hitData
end

local function GetNearestPointOnLine(point, max, min)
	local line = vector.DirectionTo(max, min)
	if line[1] ~= 0 or line[2] ~= 0 then
		local t = ((point[1]-max[1])*line[1] + (point[2] - max[2])*line[2]) / (line[1]*line[1] + line[2]*line[2])
		if t < 0 then
			return vector.Clone(max)
		elseif t > 1 then
			return vector.Clone(min)
		else
			return vector.Add(max, vector.Mult(t, line))
		end
	end
	return vector.Clone(max)
end

local function FilterTarget(unitID, projID)
	local allyTeam = spGetUnitAllyTeam(unitID)
	local pPosX, pPosY, pPosZ = spGetProjectilePosition(projID)
	if not spIsPosInLos(pPosX, pPosY, pPosZ, allyTeam) then
		return false
	end

	local hitData = GetHitData(projID, unitID)
	local uPos = vector.New3(spGetUnitPosition(unitID))
	local near = GetNearestPointOnLine(uPos, hitData.max, hitData.min)
	local distance = vector.DistanceTo(near, uPos)
	if distance > hitData.aoe then
		return false
	end
	return {near, distance, hitData, projID}
end

local function GetTargetDataData(unitID, uPos)
	local tData, tDataCount = {}, 0
	local targets = GG.ProjTargets.Query(uPos[1], uPos[2], QUERY_RADIUS)
	for i = 1, #targets do
		local data = FilterTarget(unitID, targets[i])
		if data then
			tDataCount = tDataCount + 1
			tData[tDataCount] = data
		end
	end
	return tData, tDataCount
end

local function RaycastMovementToTarget(unitID, projID, dir, dirLength)
	local allyTeam = spGetUnitAllyTeam(unitID)
	local pPos, pPosY = vector.New3(spGetProjectilePosition(projID))
	if not spIsPosInLos(pPos[1], pPosY, pPos[2], allyTeam) then
		return dirLength
	end

	local hitData = GetHitData(projID, unitID)
	local uPos = vector.New3(spGetUnitPosition(unitID))
	local pVel = vector.New3(spGetProjectileVelocity(projID))
	local intersection = vector.Intersection(uPos, dir, pPos, pVel)
	if intersection == nil then
		return dirLength
	end

	local unitToInter = vector.DirectionTo(uPos, intersection)
	-- movement direction not facing intersection point
	if vector.Dot(dir, unitToInter) < 0 then
		return dirLength
	end

	local cNear = GetNearestPointOnLine(intersection, hitData.max, hitData.min)
	local cNearDistToUnit = vector.DistanceTo(cNear, uPos)
	local uNear = GetNearestPointOnLine(uPos, hitData.max, hitData.min)
	local uNearToUPos = vector.DirectionTo(uNear, uPos)
	local angle = vector.AngleTo(uNearToUPos, vector.Negative(dir))
	local aoeDist = hitData.aoe / cos(angle)
	return max(min(cNearDistToUnit - aoeDist, dirLength), 0)
end

local external = {}

external.GetDodgeVector = function(unitID)
	local uPos = vector.New3(spGetUnitPosition(unitID))
	local tData, tDataCount = GetTargetDataData(unitID, uPos)
	local dodge, maxMagnitude = {0, 0}, 0
	for i = 1, tDataCount do
		local data = tData[i]
		maxMagnitude = max(data[3].aoe - data[2], maxMagnitude)
		if uPos[1] == data[1][1] and uPos[2] == data[1][2] then
			local pVel = vector.New3(spGetProjectileVelocity(data[4]))
			dodge = vector.Add(dodge, vector.Norm(1, pVel))
		else
			local dirToUnit = vector.DirectionTo(data[1], uPos)
			dodge = vector.Add(dodge, vector.Norm(1, dirToUnit))
		end
	end
	dodge = vector.Norm(maxMagnitude, dodge)
	return dodge[1], dodge[2]
end

external.RaycastHitZones = function(unitID, x, z)
	local point = {x, z}
	local uPos = vector.New3(spGetUnitPosition(unitID))
	local unitToPoint = vector.DirectionTo(uPos, point)
	local moveDistance = vector.Mag(unitToPoint)
	local closestDist = moveDistance
	local targets = GG.ProjTargets.Query(uPos[1], uPos[2], QUERY_RADIUS)
	for i = 1, #targets do
		closestDist = min(RaycastMovementToTarget(unitID, targets[i], unitToPoint, moveDistance), closestDist)
	end
	local newPoint = vector.Add(uPos, vector.Norm(closestDist, unitToPoint))
	return newPoint[1], newPoint[2]
end

function gadget:ProjectileCreated(projID)
	local projDefID = spGetProjectileDefID(projID)
	if projDefID and Config[projDefID] then
		hitDataCache[projID] = {}
	end
end

function gadget:ProjectileDestroyed(projID)
	if hitDataCache[projID] then
		hitDataCache[projID] = nil
	end
end

function gadget:Initialize()
	GG.ProjDodge = external
	_G.hitDataCache = hitDataCache
end


elseif DEBUG then -- ----- Unsynced -----


local SYNCED = SYNCED
local PI = math.pi
local TWO_PI = math.pi * 2
local INCREMENT = PI/ 6

local cos = math.cos
local sin = math.sin
local atan2 = math.atan2
local glColor = gl.Color
local glVertex =  gl.Vertex
local glDepthTest = gl.DepthTest
local glBeginEnd = gl.BeginEnd
local glLineWidth = gl.LineWidth
local glPopMatrix = gl.PopMatrix
local glPushMatrix = gl.PushMatrix
local GL_LINE_LOOP = GL.LINE_LOOP

local function DrawHitZone(x1, y1, z1, x2, y2, z2, aoe)
	local dirX, dirZ = x1 - x2, z1 - z2
	local angle = atan2(x2*dirZ - z2*dirX, x2*dirX + z2*dirZ) - PI/4
	for theta = angle, PI + angle, INCREMENT do
		glVertex({x1 + aoe * cos(theta), y1 + 5, z1 + aoe * sin(theta)})
	end
	for theta = PI + angle, TWO_PI + angle, INCREMENT do
		glVertex({x2 + aoe * cos(theta), y2 + 5, z2 + aoe * sin(theta)})
	end
end

function gadget:DrawWorld()
	glDepthTest(true)
	glColor({0,1,0,0.25})
	glLineWidth(2)
	for _, unitDefs in pairs(SYNCED.hitDataCache) do
		for _, h in pairs(unitDefs) do
			glPushMatrix()
			glBeginEnd(GL_LINE_LOOP, DrawHitZone, h.max[1], h.maxY, h.max[2], h.min[1], h.minY, h.min[2], h.aoe)
			glPopMatrix()
		end
	end
	glLineWidth(1)
	glColor({1,1,1,1})
	glDepthTest(false)
end


end
