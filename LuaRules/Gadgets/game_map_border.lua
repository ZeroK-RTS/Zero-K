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

local impulseMultipliers = {
	[0] = 4, -- Fixedwing
	[1] = 1, -- Gunship
	[2] = 1.2, -- Ground/Sea
}

-- Configurable with originX, originZ, radius in GG.map_CircularMapBorder as a table.
local circularMapX = MAP_WIDTH/2
local circularMapZ = MAP_HEIGHT/2
local circularMapRadius = math.min(MAP_WIDTH/2, MAP_HEIGHT/2)
local circularMapRadiusSq, circularMapNearRadiusSq = 0, 0 -- Set later

local mobileUnits = IterableMap.New()
local outOfBoundsUnits = IterableMap.New()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function IsOutsideBorder(x, z)
	return vecDistSq(x, z, circularMapX, circularMapZ) > circularMapRadiusSq
end

local function IsInBorder(x, z)
	return not IsOutsideBorder(x, z)
end

local function IsNearBorder(x, z)
	return vecDistSq(x, z, circularMapX, circularMapZ) > circularMapNearRadiusSq
end

local function LoadMapBorder()
	local gameConfig = VFS.FileExists(GAMESIDE_BORDER_FILE) and VFS.Include(GAMESIDE_BORDER_FILE) or false
	local mapConfig = VFS.FileExists(MAPSIDE_BORDER_FILE) and VFS.Include(MAPSIDE_BORDER_FILE) or false
	local config = gameConfig or mapConfig or false
	if not config then
		return false
	end
	
	circularMapX = config.originX or circularMapX
	circularMapZ = config.originZ or circularMapZ
	circularMapRadius = config.radius or circularMapRadius
	circularMapRadiusSq = circularMapRadius^2
	circularMapNearRadiusSq = (circularMapRadius > NEAR_DIST and (circularMapRadius - NEAR_DIST)^2) or 0
	
	return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function SetupTypemapAndMask()
	for x = 0, MAP_WIDTH - 8, 8 do
		for z = 0, MAP_HEIGHT - 8, 8 do
			if IsOutsideBorder(x, z) then
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
	if (moveType == 2 and IsOutsideBorder(x, z)) or (moveType~= 2 and IsNearBorder(x, z)) then
		IterableMap.Add(outOfBoundsUnits, unitID, moveType)
		return true -- remove from mobileUnits
	end
end

local function HandleOutOFBoundsUnit(unitID, moveType)
	local x, _, z = spGetUnitPosition(unitID)
	if not IsOutsideBorder(x, z) then
		if moveType ~= 2 and IsNearBorder(x, z) then
			return -- Keep track of aircraft near border.
		end
		IterableMap.Add(mobileUnits, unitID, moveType)
		return true -- Remove from outOfBoundsUnits
	end
	
	local vx = circularMapX - x
	local vz = circularMapZ - z
	local norm = math.sqrt(vx*vx + vz*vz)
	
	local mag = (impulseMultipliers[moveType] or 1)
	if norm < RAMP_DIST + circularMapRadius then
		if moveType == 2 then
			-- Ground units only go down to half magnitude, to help with unsticking.
			mag = mag * (0.5 + 0.5 * (norm - circularMapRadius) / RAMP_DIST)
		else
			mag = mag * (norm - circularMapRadius) / RAMP_DIST
		end
	end
	
	vx, vz = vx / norm, vz / norm
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
		gadgetHandler:RemoveGadget()
		return
	end
	
	SetupTypemapAndMask()
	
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
	
	GG.map_AllowPositionTerraform = IsInBorder
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
