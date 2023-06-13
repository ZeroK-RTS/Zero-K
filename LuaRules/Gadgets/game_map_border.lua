--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Map Border",
		desc      = "Implements a circular map border.",
		author    = "GoogleFrog",
		date      = "5 June 2021",
		license   = "GNU GPL, v2 or later",
		layer     = 100,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local MAPSIDE_BORDER_FILE = "mapconfig/map_border_config.lua"
local GAMESIDE_BORDER_FILE = "LuaRules/Configs/MapBorder/" .. (Game.mapName or "") .. ".lua"

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")

local spSetMapSquareTerrainType = Spring.SetMapSquareTerrainType
local spSetSquareBuildingMask = Spring.SetSquareBuildingMask
local spGetUnitPosition = Spring.GetUnitPosition
local vecDistSq = Spring.Utilities.Vector.DistSq

local MAP_WIDTH = Game.mapSizeX
local MAP_HEIGHT = Game.mapSizeZ
local MASK_SCALE = 1 / (2 * Game.squareSize)

local MOBILE_UPDATE_FREQ = 2 * 30
local OUT_OF_BOUNDS_UPDATE_FREQ = 3

local UP_IMPULSE = 0.25
local SIDE_IMPULSE = 1.5
local RAMP_DIST = 180
local NEAR_DIST = 500
local DEFAULT_EDGE_BORDER = 800
local DEFAULT_EDGE_NEAR = DEFAULT_EDGE_BORDER - NEAR_DIST

local impulseMultipliers = {
	[0] = 4, -- Fixedwing
	[1] = 1, -- Gunship
	[2] = 1.2, -- Ground/Sea
}

local defaultConfig = {
	airBorderOnly = true,
	forceMult = 0.15,
	SpeedLimitFunc = function (distance)
		return 3 + distance * 0.015
	end,
	IsInBounds = function (x, z)
		return not ((x < -DEFAULT_EDGE_BORDER) or (z < -DEFAULT_EDGE_BORDER) or (x > MAP_WIDTH + DEFAULT_EDGE_BORDER) or (z > MAP_HEIGHT + DEFAULT_EDGE_BORDER))
	end,
	IsNearBorderOrOutOfBounds = function (x, z)
		return (x < -DEFAULT_EDGE_NEAR) or (z < -DEFAULT_EDGE_NEAR) or (x > MAP_WIDTH + DEFAULT_EDGE_NEAR) or (z > MAP_HEIGHT + DEFAULT_EDGE_NEAR)
	end,
	GetClosestBorderPoint = function (x, z)
		if z < 0 and z < x and z < (MAP_WIDTH - x) then
			--Spring.Echo("Top Edge", math.random())
			return x, -DEFAULT_EDGE_BORDER
		elseif z > MAP_HEIGHT and (MAP_HEIGHT - z) < x and (MAP_HEIGHT - z) < (MAP_WIDTH - x) then
			--Spring.Echo("Bottom Edge", math.random())
			return x, MAP_HEIGHT + DEFAULT_EDGE_BORDER
		elseif x < 0 then
			--Spring.Echo("Left Edge", math.random())
			return -DEFAULT_EDGE_BORDER, z
		else
			--Spring.Echo("Right Edge", math.random())
			return MAP_WIDTH + DEFAULT_EDGE_BORDER, z
		end
	end,
}

-- Configurable with originX, originZ, radius in GG.map_CircularMapBorder as a table.
local circularMapX = MAP_WIDTH/2
local circularMapZ = MAP_HEIGHT/2
local airBorderOnly = false
local circularMapRadius = math.min(MAP_WIDTH/2, MAP_HEIGHT/2)
local circularMapRadiusSq, circularMapNearRadiusSq = 0, 0 -- Set later
local forceMult = 1
local speedLimit = 20

local mobileUnits = IterableMap.New()
local outOfBoundsUnits = IterableMap.New()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function IsInBounds(x, z)
	-- returns whether (x,z) is inside the playable area.
	return vecDistSq(x, z, circularMapX, circularMapZ) <= circularMapRadiusSq
end

local function IsNearBorderOrOutOfBounds(x, z)
	-- returns whether (x,z) is within NEAR_DIST (500) of a border.
	return vecDistSq(x, z, circularMapX, circularMapZ) > circularMapNearRadiusSq
end

local function GetClosestBorderPoint(x, z)
	-- returns position on border closest to (x,z)
	local vx = x - circularMapX
	local vz = z - circularMapZ
	local norm = math.sqrt(vx*vx + vz*vz)
	vx, vz = vx / norm, vz / norm
	return circularMapX + circularMapRadius*vx, circularMapZ + circularMapRadius*vz
end

local function LoadMapBorder()
	local gameConfig = VFS.FileExists(GAMESIDE_BORDER_FILE) and VFS.Include(GAMESIDE_BORDER_FILE) or false
	local mapConfig  = VFS.FileExists(MAPSIDE_BORDER_FILE) and VFS.Include(MAPSIDE_BORDER_FILE) or false
	local config     = gameConfig or mapConfig or defaultConfig
	
	IsInBounds                = config.IsInBounds or IsInBounds
	IsNearBorderOrOutOfBounds = config.IsNearBorderOrOutOfBounds or IsNearBorderOrOutOfBounds
	GetClosestBorderPoint     = config.GetClosestBorderPoint or GetClosestBorderPoint
	SpeedLimitFunc            = config.SpeedLimitFunc
	
	circularMapX            = config.originX or circularMapX
	circularMapZ            = config.originZ or circularMapZ
	circularMapRadius       = config.radius or circularMapRadius
	circularMapRadiusSq     = circularMapRadius^2
	circularMapNearRadiusSq = (circularMapRadius > NEAR_DIST and (circularMapRadius - NEAR_DIST)^2) or 0
	
	airBorderOnly = config.airBorderOnly or airBorderOnly
	forceMult     = config.forceMult or forceMult
	speedLimit    = config.speedLimit or speedLimit
	
	return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function SetupTypemapAndMask()
	for x = 0, MAP_WIDTH - 8, 8 do
		for z = 0, MAP_HEIGHT - 8, 8 do
			if not IsInBounds(x, z) then
				spSetMapSquareTerrainType(x, z, GG.IMPASSIBLE_TERRAIN)
				if x%16 == 0 and z%16 == 0 then
					spSetSquareBuildingMask(x * MASK_SCALE, z * MASK_SCALE, 0)
				end
			end
		end
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Unit Handling

local function CheckMobileUnit(unitID, moveType)
	local x, _, z = spGetUnitPosition(unitID)
	if not x then
		return true
	end
	if (moveType == 2 and not IsInBounds(x, z)) or (moveType~= 2 and IsNearBorderOrOutOfBounds(x, z)) then
		IterableMap.Add(outOfBoundsUnits, unitID, moveType)
		return true -- remove from mobileUnits
	end
end

local function HandleOutOFBoundsUnit(unitID, moveType)
	local ux, _, uz = spGetUnitPosition(unitID)
	if not ux then
		return true
	end
	if IsInBounds(ux, uz) then
		if moveType ~= 2 and IsNearBorderOrOutOfBounds(ux, uz) then
			return -- Keep track of aircraft near border.
		end
		IterableMap.Add(mobileUnits, unitID, moveType)
		return true -- Remove from outOfBoundsUnits
	end
	
	local bx, bz = GetClosestBorderPoint(ux, uz)
	local vx = bx - ux
	local vz = bz - uz
	local norm = math.sqrt(vx*vx + vz*vz)
	vx, vz = vx / norm, vz / norm
	
	if speedLimit or SpeedLimitFunc then
		local curVx, curVy, curVz, curSpeed = Spring.GetUnitVelocity(unitID)
		local dot = curVx * vx + curVz * vz
		--Spring.Echo("dot", dot)
		if SpeedLimitFunc and (dot > SpeedLimitFunc(norm)) then
			return
		end
		if speedLimit and (dot > speedLimit) then
			return
		end
	end
	
	local mag = (impulseMultipliers[moveType] or 1)
	if norm < RAMP_DIST then
		if moveType == 2 then
			-- Ground units only go down to half magnitude, to help with unsticking.
			mag = mag * (0.5 + 0.5 * norm / RAMP_DIST)
		else
			mag = mag * norm / RAMP_DIST
		end
	end
	
	GG.AddGadgetImpulseRaw(unitID, vx*mag*SIDE_IMPULSE, UP_IMPULSE, vz*mag*SIDE_IMPULSE, true, true)
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Gagdet API

function gadget:GameFrame(n)
	IterableMap.ApplyFraction(mobileUnits, MOBILE_UPDATE_FREQ, n%MOBILE_UPDATE_FREQ, CheckMobileUnit)
	IterableMap.ApplyFraction(outOfBoundsUnits, OUT_OF_BOUNDS_UPDATE_FREQ, n%OUT_OF_BOUNDS_UPDATE_FREQ, HandleOutOFBoundsUnit)
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
	local moveType = Spring.Utilities.getMovetypeByID(unitDefID)
	if not moveType then
		-- Don't handle static structures.
		return
	end
	if airBorderOnly and moveType == 2 then
		-- Don't handle land or sea
		return
	end
	IterableMap.Add(mobileUnits, unitID, moveType)
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	if not Spring.Utilities.getMovetypeByID(unitDefID) then
		-- Don't handle static structures.
		return
	end
	IterableMap.Remove(mobileUnits, unitID)
	IterableMap.Remove(outOfBoundsUnits, unitID)
end

function gadget:Initialize()
	if not LoadMapBorder() then
		GG.map_AllowPositionTerraform = function() return true end
		gadgetHandler:RemoveGadget()
		return
	end
	
	SetupTypemapAndMask()
	
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
	
	GG.map_AllowPositionTerraform = IsInBounds
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
