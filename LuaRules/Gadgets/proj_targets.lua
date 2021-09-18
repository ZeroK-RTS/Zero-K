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

local DEBUG = true

if gadgetHandler:IsSyncedCode() then


local vector = Spring.Utilities.Vector
local spSetWatchWeapon = Script.SetWatchWeapon
local spGetProjectileDefID = Spring.GetProjectileDefID
local spGetProjectilePosition = Spring.GetProjectilePosition
local spGetProjectileVelocity = Spring.GetProjectileVelocity

local QuadTree = include("LuaRules/Utilities/quadTree.lua")
local Config = include("LuaRules/Configs/proj_targets_config.lua")
local Prediction = include("LuaRules/Utilities/projPrediction.lua")

local MAP_WIDTH = Game.mapSizeX
local MAP_HEIGHT = Game.mapSizeZ
local UPDATE_RATE = 15

local projectiles = {}
local dynamicProjs = {}
local dynamicProjCount = 0
local targetMap = QuadTree.New(0, 0, MAP_WIDTH, MAP_HEIGHT, 4, 4)

local function AddTarget(projID)
	local projDefID = spGetProjectileDefID(projID)
	if projDefID then
		local config = Config[projDefID]
		local target, targetY = Prediction.Target[config.wType](projID)
		projectiles[projID] = {
			pos = target,
			y = targetY,
			defID = projDefID,
			initPos = vector.New3(spGetProjectilePosition(projID))
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
		GG.EventDelay(0, AddTarget, {projID})
	end
end

function gadget:ProjectileDestroyed(projID)
	if projectiles[projID] then
		local pos = projectiles[projID].pos
		targetMap:Remove(pos[1], pos[2], projID)
		projectiles[projID] = nil
	end
end

function gadget:GameFrame(frame)
	if frame % UPDATE_RATE == 0 then
		local projID, data, config
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
					config = Config[data.defID]
					-- account for selfExplode projectiles
					if config.selfExplode then
						local initPos = data.initPos
						local pDir = vector.DirectionTo(initPos, data.pos)
						if vector.Mag(pDir) > config.range then
							pDir = vector.Norm(1, pDir)
							data.pos = vector.Add(initPos, vector.Mult(config.range + 50, pDir))
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
end

local external = {}

external.Query = function(x, z, radius)
	return targetMap:Query(x, z, radius)
end

external.GetData = function(projID)
	return projectiles[projID]
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

local Config = include("LuaRules/Configs/proj_targets_config.lua")

local glColor = gl.Color
local glDepthTest = gl.DepthTest
local glDrawGroundCircle = gl.DrawGroundCircle

local SYNCED = SYNCED

function gadget:DrawWorld()
	glDepthTest(true)
	glColor({1,0,0,1})
	for _, data in pairs(SYNCED.projectiles) do
		local config = Config[data.defID]
		glDrawGroundCircle(data.pos[1], data.y + 1, data.pos[2], config.aoe, 12)
	end
	glDepthTest(false)
	glColor({1,1,1,1})
end


end
