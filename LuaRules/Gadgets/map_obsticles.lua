function gadget:GetInfo()
	return {
		name = "Map Obsticles",
		desc = "tracks map obsticles",
		author = "petturtle",
		date = "2021",
		layer = 0,
		enabled = true
	}
end

local DEBUG = false
local MAP_WIDTH = Game.mapSizeX
local MAP_HEIGHT = Game.mapSizeZ

if gadgetHandler:IsSyncedCode() then

local TTYPE_U = string.byte("u") -- unit
local TTYPE_G = string.byte("g") -- ground
local TTYPE_F = string.byte("f") -- feature
local TTYPE_P = string.byte('p') -- projectile

local QuadTree = VFS.Include("LuaRules/Utilities/quad_tree.lua")
local Config = VFS.Include("LuaRules/Configs/projectile_dodge_defs.lua")

local spSetWatchWeapon = Script.SetWatchWeapon
local spGetUnitPosition = Spring.GetUnitPosition
local spGetFeaturePosition = Spring.GetFeaturePosition
local spGetProjectileDefID = Spring.GetProjectileDefID
local spGetProjectileTarget = Spring.GetProjectileTarget
local spGetProjectilePosition = Spring.GetProjectilePosition

local function GetProjectileGroundTarget(tArgs)
	return tArgs[1], tArgs[2], tArgs[3]
end

local ProjTTypeToPos = {
	[TTYPE_U] = spGetUnitPosition,
	[TTYPE_G] = GetProjectileGroundTarget,
	[TTYPE_F] = spGetFeaturePosition,
	[TTYPE_P] = spGetProjectilePosition,
}

local layers = {
    projectiles = {
        color = {1, 0, 0, 1},
        obsticles = {},
        quad_tree = QuadTree.New(0, 0, MAP_WIDTH, MAP_HEIGHT, 4, 4),
    },
}

function gadget:ProjectileCreated(projID)
	local projDefID = spGetProjectileDefID(projID)
	if projDefID and Config[projDefID] then
		local tType, tArgs = spGetProjectileTarget(projID)
        local x, y, z = ProjTTypeToPos[tType](tArgs)
        layers.projectiles.obsticles[projID] = {{x, z}, y, projID, projDefID}
        layers.projectiles.quad_tree:Insert(x, z, projID)
	end
end

function gadget:ProjectileDestroyed(projID)
    if layers.projectiles.obsticles[projID] then
        local target = layers.projectiles.obsticles[projID][1]
        layers.projectiles.quad_tree:Remove(target[1], target[2], projID)
        layers.projectiles.obsticles[projID] = nil
    end
end

-- obsticle
-- [1] = target
-- [2] = target y
-- [3] = projID
-- [4] = projDefID

local function Query(x, z, radius, layer_names)
    local results = {}
    local layer, layer_results
    for _, layer_name in pairs(layer_names) do
        layer = layers[layer_name]
        layer_results = layer.quad_tree:Query(x, z, radius)
        for _, obsticle_id in pairs(layer_results) do
            results[#results+1] = layer.obsticles[obsticle_id]
        end
    end
    return results
end

function gadget:Initialize()
	for projDefID, _ in pairs(Config) do
		spSetWatchWeapon(projDefID, true)
	end

    _G.layers = layers
    GG.MapObsticles = Query
end

elseif DEBUG then -- ----- Unsynced Debug -----
    local SYNCED = SYNCED
    local glColor = gl.Color
    local glDepthTest = gl.DepthTest
    local glDrawGroundCircle = gl.DrawGroundCircle

    function gadget:DrawWorld()
        glDepthTest(true)
        for _, layer in pairs(SYNCED.layers) do
            glColor(layer.color)
            for _, obsticle in pairs(layer.obsticles) do
                glDrawGroundCircle(obsticle[1][1], obsticle[2], obsticle[1][2], 32, 12)
            end
        end
        glDepthTest(false)
        glColor({1,1,1,1})
    end
end