function gadget:GetInfo()
	return {
		name = "Projectile Target Map",
		desc = "tracks projectiles targets",
		author = "petturtle",
		date = "2021",
		layer = 0,
		enabled = true
	}
end

local DEBUG = false

if gadgetHandler:IsSyncedCode() then


local vector = Spring.Utilities.Vector
local spSetWatchWeapon = Script.SetWatchWeapon
local spGetGroundHeight = Spring.GetGroundHeight
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitDirection = Spring.GetUnitDirection
local spGetFeaturePosition = Spring.GetFeaturePosition
local spGetProjectileDefID = Spring.GetProjectileDefID
local spGetProjectileTarget = Spring.GetProjectileTarget
local spGetProjectileGravity = Spring.GetProjectileGravity
local spGetProjectilePosition = Spring.GetProjectilePosition
local spGetProjectileVelocity = Spring.GetProjectileVelocity

local QuadTree = include("LuaRules/Utilities/quadTree.lua")
local Kinematics = include("LuaRules/Utilities/kinematics.lua")
local Config = include("LuaRules/Configs/proj_targets_config.lua")

local MAP_WIDTH = Game.mapSizeX
local MAP_HEIGHT = Game.mapSizeZ
local TTYPE_U = string.byte("u") -- unit
local TTYPE_G = string.byte("g") -- ground
local TTYPE_F = string.byte("f") -- feature
local TTYPE_P = string.byte('p') -- projectile

local projectiles = {}
local dynamicProjs = {}
local dynamicProjCount = 0
local targetMap = QuadTree.New(0, 0, MAP_WIDTH, MAP_HEIGHT, 4, 4)

local function GetProjectileRawTarget(projID)
	local tType, tArgs = spGetProjectileTarget(projID)
	if tType == TTYPE_U then
		return vector.New3(spGetUnitPosition(tArgs))
	elseif tType == TTYPE_G then
		return {tArgs[1], tArgs[3]}, tArgs[2]
	elseif tType == TTYPE_F then
		return vector.New3(spGetFeaturePosition(projID))
	else -- TTYPE_P
		return vector.New3(spGetProjectilePosition(tArgs))
	end
end

local function GetProjectileTargetIntersection(projID)
	local tType, tArgs = spGetProjectileTarget(projID)
	if tType == TTYPE_U then
		local uPos = vector.New3(spGetUnitPosition(tArgs))
		local uDir = vector.New3(spGetUnitDirection(tArgs))
		local pPos = vector.New3(spGetProjectilePosition(projID))
		local pVel = vector.New3(spGetProjectileVelocity(projID))
		local inter = vector.Intersection(uPos, uDir, pPos, pVel)
		if inter then
			return inter, spGetGroundHeight(inter[1], inter[2])
		end
		return nil
	else
		return GetProjectileRawTarget(projID)
	end
end

local function GetProjectileKinematicTarget(projID)
	local gravity = spGetProjectileGravity(projID)
	local y = select(2, GetProjectileTargetIntersection(projID))
	local pPos, py = vector.New3(spGetProjectilePosition(projID))
	local pVel, vy = vector.New3(spGetProjectileVelocity(projID))
	local timeTo = Kinematics.TimeToHeight(vy, gravity, py - y, -1)
	return vector.Add(pPos, vector.Mult(timeTo, pVel)), y
end

local GetProjectileTarget = {
	["Cannon"] = GetProjectileKinematicTarget,
	["AircraftBomb"] = GetProjectileKinematicTarget,
	["MissileLauncher"] = GetProjectileTargetIntersection,
	["StarburstLauncher"] = GetProjectileRawTarget,
	["BeamLaser"] = GetProjectileRawTarget,
}

local function TrackProjectile(projID)
	local projDefID = spGetProjectileDefID(projID)
	if projDefID == nil then
		return
	end

	local config = Config[projDefID]
	local target, targetY = GetProjectileTarget[config.wType](projID)

	if target then
		local pPos = vector.New3(spGetProjectilePosition(projID))
		projectiles[projID] = {
			pos = target, y = targetY, config = config, initPos = pPos
		}
		targetMap:Insert(target[1], target[2], projID)
		if config.dynamic then
			dynamicProjCount = dynamicProjCount + 1
			dynamicProjs[dynamicProjCount] = projID
		end
	end
end

function gadget:ProjectileCreated(projID)
	local projDefID = spGetProjectileDefID(projID)
	if projDefID and Config[projDefID] then
		-- need to delay for frame to get correct proj velocity
		GG.EventDelay(0, TrackProjectile, {projID})
	end
end

function gadget:ProjectileDestroyed(projID)
	if projectiles[projID] then
		local pos = projectiles[projID].pos
		targetMap:Remove(pos[1], pos[2], projID)
		projectiles[projID] = nil
	end
end

local external = {}

external.Query = function(x, z, radius)
	return targetMap:Query(x, z, radius)
end

external.GetData = function(projID)
	return projectiles[projID]
end

external.Update = function()
	local projID, data
	for i = dynamicProjCount, 1, -1 do
		projID = dynamicProjs[i]
		data = projectiles[projID]
		if data then
			local pPos, pPosY = vector.New3(spGetProjectilePosition(projID))
			local pVel, pVelY = vector.New3(spGetProjectileVelocity(projID))
			local timeToGround = (pPosY - data.y) / -pVelY
			if timeToGround > 0 then
				targetMap:Remove(data.pos[1], data.pos[2], projID)
				data.pos = vector.Add(pPos, vector.Mult(timeToGround, pVel))
				-- account for selfExplode projectiles
				if data.config.selfExplode then
					local initPos = data.initPos
					local pDir = vector.DirectionTo(initPos, data.pos)
					if vector.Mag(pDir) > data.config.range then
						pDir = vector.Norm(1, pDir)
						data.pos = vector.Add(initPos, vector.Mult(data.config.range + 50, pDir))
					end
				end
				targetMap:Insert(data.pos[1], data.pos[2], projID)
			end
		else
			dynamicProjs[i] = dynamicProjs[dynamicProjCount]
			dynamicProjs[dynamicProjCount] = nil
			dynamicProjCount = dynamicProjCount - 1
		end
	end
end

function gadget:Initialize()
	GG.ProjTargets = external
	_G.projectiles = projectiles
	_G.targetMap = targetMap

	for projDefID, _ in pairs(Config) do
		spSetWatchWeapon(projDefID, true)
	end
end


elseif DEBUG then -- ----- Unsynced -----


local glText = gl.Text
local glColor = gl.Color
local glVertex = gl.Vertex
local glRotate = gl.Rotate
local glBeginEnd = gl.BeginEnd
local glPopMatrix = gl.PopMatrix
local glTranslate = gl.Translate
local glDepthTest = gl.DepthTest
local glPushMatrix = gl.PushMatrix
local glDrawGroundCircle = gl.DrawGroundCircle
local spGetGroundHeight = Spring.GetGroundHeight

local SYNCED = SYNCED

local function DrawRect(rect)
	glVertex({rect.x, 0, rect.y})
	glVertex({rect.x + rect.width, 0, rect.y})
	glVertex({rect.x + rect.width, 0, rect.y + rect.height})
	glVertex({rect.x, 0, rect.y + rect.height})
end

local function DrawTargetMap(targetMap)
	if targetMap.isSubdivided then
		DrawTargetMap(targetMap.topLeft)
		DrawTargetMap(targetMap.topRight)
		DrawTargetMap(targetMap.bottomLeft)
		DrawTargetMap(targetMap.bottomRight)
	end

	local rect = targetMap.rect
	glPushMatrix()
	glBeginEnd(GL.LINE_LOOP, DrawRect, rect)
	glPopMatrix()

	local x = rect.x + rect.width * 0.5
	local z = rect.y + rect.height * 0.5
	if targetMap.dataCount ~= 0 then
		glPushMatrix()
		glTranslate(x, spGetGroundHeight(x, z) + 10, z)
		glRotate(-90, 1, 0, 0)
		glText(tostring(targetMap.dataCount), 0, 0, 128, "cv")
		glPopMatrix()
	end
end

function gadget:DrawWorld()
	glDepthTest(true)
	glColor({1,0,0,1})
	for _, data in pairs(SYNCED.projectiles) do
		glDrawGroundCircle(data.pos[1], data.y + 1, data.pos[2], data.config.aoe, 12)
	end
	glDepthTest(false)
	DrawTargetMap(SYNCED.targetMap)
	glColor({1,1,1,1})
end


end
