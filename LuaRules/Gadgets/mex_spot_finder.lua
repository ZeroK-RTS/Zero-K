
function gadget:GetInfo()
	return {
		name      = "Metalspot Finder Gadget",
		desc      = "Finds metal spots",
		author    = "Niobium, modified by Google Frog",
		version   = "v1.1",
		date      = "November 2010",
		license   = "GNU GPL, v2 or later",
		layer     = -999999, -- after start_boxes (NB: can't apply arithmetic to math.huge), but before everything else
		enabled   = true
	}
end

--------------------------------------------------------------------------------
-- SYNCED
--------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then

------------------------------------------------------------
-- Config
------------------------------------------------------------
local MAPSIDE_METALMAP = "mapconfig/map_metal_layout.lua"
local ALT_MAPSIDE_METALMAP = "mapconfig/map_resource_spot_layout.lua"
local GAMESIDE_METALMAP = "LuaRules/Configs/MetalSpots/" .. (Game.mapName or "") .. ".lua"

local DEFAULT_MEX_INCOME = 2
local MINIMUM_MEX_INCOME = 0.2

local gridSize = Game.metalMapSquareSize -- Resolution of metal map
local buildGridSize = Game.squareSize -- Resolution of build positions

local MEX_RADIUS = Game.extractorRadius
local MAP_SIZE_X = Game.mapSizeX
local MAP_SIZE_X_SCALED = MAP_SIZE_X / gridSize
local MAP_SIZE_Z = Game.mapSizeZ
local MAP_SIZE_Z_SCALED = MAP_SIZE_Z / gridSize

------------------------------------------------------------
-- Speedups
------------------------------------------------------------
local min, max = math.min, math.max
local floor, ceil = math.floor, math.ceil
local sqrt = math.sqrt
local huge = math.huge

local spGetGroundInfo       = Spring.GetGroundInfo
local spGetGroundOrigHeight = Spring.GetGroundOrigHeight
local spSetGameRulesParam   = Spring.SetGameRulesParam

local extractorRadius    = Game.extractorRadius
local extractorRadiusSqr = extractorRadius * extractorRadius
 
local buildmapSizeX  = Game.mapSizeX - buildGridSize
local buildmapSizeZ  = Game.mapSizeZ - buildGridSize
local buildmapStartX = buildGridSize
local buildmapStartZ = buildGridSize

local metalmapSizeX  = Game.mapSizeX - 1.5 * gridSize
local metalmapSizeZ  = Game.mapSizeZ - 1.5 * gridSize
local metalmapStartX = 1.5 * gridSize
local metalmapStartZ = 1.5 * gridSize

------------------------------------------------------------
-- Variables
------------------------------------------------------------

local mexUnitDef = UnitDefNames["staticmex"]

local mexDefInfo = {
	extraction = 0.001,
	oddX = (mexUnitDef.xsize % 4 == 2),
	oddZ = (mexUnitDef.zsize % 4 == 2),
}

local modOptions
if (Spring.GetModOptions) then
	modOptions = Spring.GetModOptions()
end

------------------------------------------------------------
-- Speedup
------------------------------------------------------------
local function GetSpotsByPos(spots)
	local spotPos = {}
	for i = 1, #spots do
		local spot = spots[i]
		local x = spot.x
		local z = spot.z
		--Spring.MarkerAddPoint(x,0,z,x .. ", " .. z)
		spotPos[x] = spotPos[x] or {}
		spotPos[x][z] = i
	end
	return spotPos
end

------------------------------------------------------------
-- Set Game Rules so widgets can read metal spots
------------------------------------------------------------

local function SetMexGameRulesParams(metalSpots, needMexDrawing)
	if not metalSpots then -- Mexes can be built anywhere
		spSetGameRulesParam("mex_count", -1)
		return
	end
	
	local mexCount = #metalSpots
	spSetGameRulesParam("mex_count", mexCount)
	
	for i = 1, mexCount do
		local mex = metalSpots[i]
		spSetGameRulesParam("mex_x" .. i, mex.x)
		spSetGameRulesParam("mex_y" .. i, mex.y)
		spSetGameRulesParam("mex_z" .. i, mex.z)
		spSetGameRulesParam("mex_metal" .. i, mex.metal)
	end
end

local function SetMexHelperAttributes(metalSpots, needMexDrawing)
	if not metalSpots then -- Mexes can be built anywhere
		return
	end

	if needMexDrawing then
		spSetGameRulesParam("mex_need_drawing", 1)
	end
	local mexCount = #metalSpots
	
	local minHeight, maxHeight, minX, maxX, minZ, maxZ
	for i = 1, mexCount do
		local mex = metalSpots[i]
		if (not minHeight) or (mex.y < minHeight) then
			minHeight = mex.y
		end
		if (not maxHeight) or (mex.y > maxHeight) then
			maxHeight = mex.y
		end
		if (not minX) or (mex.x < minX) then
			minX = mex.x
		end
		if (not maxX) or (mex.x > maxX) then
			maxX = mex.x
		end
		if (not minZ) or (mex.z < minZ) then
			minZ = mex.z
		end
		if (not maxZ) or (mex.z > maxZ) then
			maxZ = mex.z
		end
	end
	
	if minHeight then
		spSetGameRulesParam("mex_min_height", minHeight)
		spSetGameRulesParam("mex_max_height", maxHeight)
		spSetGameRulesParam("mex_min_x", minX)
		spSetGameRulesParam("mex_max_x", maxX)
		spSetGameRulesParam("mex_min_z", minZ)
		spSetGameRulesParam("mex_max_z", maxZ)
		spSetGameRulesParam("mex_min_x_prop", minX / Game.mapSizeX)
		spSetGameRulesParam("mex_max_x_prop", maxX / Game.mapSizeX)
		spSetGameRulesParam("mex_min_z_prop", minZ / Game.mapSizeZ)
		spSetGameRulesParam("mex_max_z_prop", maxZ / Game.mapSizeZ)
	end
end

------------------------------------------------------------
-- Extractor Processing
------------------------------------------------------------

local function AdjustCoordinates(x, z)
	local centerX, centerZ
	if (mexDefInfo.oddX) then
		centerX = (floor( x / gridSize) + 0.5) * gridSize
	else
		centerX = floor( x / gridSize + 0.5) * gridSize
	end
	
	if (mexDefInfo.oddZ) then
		centerZ = (floor( z / gridSize) + 0.5) * gridSize
	else
		centerZ = floor( z / gridSize + 0.5) * gridSize
	end
	
	return centerX, centerZ
end

local function IntegrateMetalFromAdjusted(centerX, centerZ, radius)
	radius = radius or MEX_RADIUS
	
	local startX = floor((centerX - radius) / gridSize)
	local startZ = floor((centerZ - radius) / gridSize)
	local endX = floor((centerX + radius) / gridSize)
	local endZ = floor((centerZ + radius) / gridSize)
	startX, startZ = max(startX, 0), max(startZ, 0)
	endX, endZ = min(endX, MAP_SIZE_X_SCALED - 1), min(endZ, MAP_SIZE_Z_SCALED - 1)
	
	local mult = mexDefInfo.extraction
	local result = 0

	for i = startX, endX do
		for j = startZ, endZ do
			local cx, cz = (i + 0.5) * gridSize, (j + 0.5) * gridSize
			local dx, dz = cx - centerX, cz - centerZ
			local dist = sqrt(dx * dx + dz * dz)

			if (dist < radius) then
				local _, metal = spGetGroundInfo(cx, cz)
				result = result + (metal or 0)
			end
		end
	end
	
	return result * mult
end

local function IntegrateMetal(x, z, radius)
	local centerX, centerZ = AdjustCoordinates(x, z)
	local metal = IntegrateMetalFromAdjusted(centerX, centerZ, radius)
	return metal, centerX, centerZ
end


------------------------------------------------------------
-- Mex finding
------------------------------------------------------------

local function SanitiseSpots(spots, metalOverride, overrideDefinedMexes)
	local metalOverrideFunc
	if type(metalOverride) == "number" then
		metalOverrideFunc = function() return metalOverride end
	elseif type(metalOverride) == "function" then
		metalOverrideFunc = metalOverride
	end

	local retSpots = {}
	for i = 1, #spots do
		local spot = spots[i]
		if spot and spot.x and spot.z then
			if metalOverrideFunc and (overrideDefinedMexes or not spot.metal) then
				local m, x, z = metalOverrideFunc(spot.metal, spot.x, spot.z)
				spot.metal = m or spot.metal
				spot.x     = x or spot.x
				spot.z     = z or spot.z
			end

			spot.x, spot.z = AdjustCoordinates(spot.x, spot.z)
			spot.y = spGetGroundOrigHeight(spot.x, spot.z)

			if not spot.metal then
				local metal = IntegrateMetalFromAdjusted(spot.x, spot.z)
				spot.metal = (metal > 0 and metal) or DEFAULT_MEX_INCOME
			end
			
			if spot.metal > MINIMUM_MEX_INCOME then
				spot.metal = spot.metal
				retSpots[#retSpots + 1] = spot
			end
		end
	end
	
	return retSpots
end

local function MakeString(group)
	if group then
		local ret = ""
		for i, v in pairs(group.left) do
			ret = ret .. i .. v
		end
		ret = ret .. " "
		for i, v in pairs(group.right) do
			ret = ret .. i .. v
		end
		ret = ret .. " " .. group.minZ .. " " .. group.maxZ .. " " .. group.worth
		return ret
	else
		return ""
	end
end

local function SearchForSpots()
	local spots = {}
	
	Spring.Log(gadget:GetInfo().name, LOG.INFO, "Detecting mex config from metalmap")

	-- Main group collection
	local uniqueGroups = {}
	
	-- Strip info
	local nStrips = 0
	local stripLeft = {}
	local stripRight = {}
	local stripGroup = {}
	
	-- Indexes
	local aboveIdx
	local workingIdx
	
	-- Strip processing function (To avoid some code duplication)
	local function DoStrip(x1, x2, z, worth)
		local assignedTo
		
		for i = aboveIdx, workingIdx - 1 do
			if stripLeft[i] > x2 + gridSize then
				break
			elseif stripRight[i] + gridSize >= x1 then
				local matchGroup = stripGroup[i]
				if assignedTo then
					if matchGroup ~= assignedTo then
						for iz = matchGroup.minZ, assignedTo.minZ - gridSize, gridSize do
							assignedTo.left[iz] = matchGroup.left[iz]
						end
						for iz = matchGroup.minZ, matchGroup.maxZ, gridSize do
							assignedTo.right[iz] = matchGroup.right[iz]
						end
						if matchGroup.minZ < assignedTo.minZ then
							assignedTo.minZ = matchGroup.minZ
						end
						assignedTo.maxZ = z
						assignedTo.worth = assignedTo.worth + matchGroup.worth
						uniqueGroups[MakeString(matchGroup)] = nil
					end
				else
					assignedTo = matchGroup
					assignedTo.left[z] = assignedTo.left[z] or x1 -- Only accept the first
					assignedTo.right[z] = x2 -- Repeated overwrite gives us result we want
					assignedTo.maxZ = z -- Repeated overwrite gives us result we want
					assignedTo.worth = assignedTo.worth + worth
				end
			else
				aboveIdx = aboveIdx + 1
			end
		end
		
		nStrips = nStrips + 1
		stripLeft[nStrips] = x1
		stripRight[nStrips] = x2
		
		if assignedTo then
			stripGroup[nStrips] = assignedTo
		else
			local newGroup = {
					left = {[z] = x1},
					right = {[z] = x2},
					minZ = z,
					maxZ = z,
					worth = worth
				}
			stripGroup[nStrips] = newGroup
			uniqueGroups[MakeString(newGroup)] = newGroup
		end
	end
	
	-- Strip finding
	workingIdx = huge
	for mz = metalmapStartX, metalmapSizeZ, gridSize do
		
		aboveIdx = workingIdx
		workingIdx = nStrips + 1
		
		local stripStart = nil
		local stripWorth = 0
		
		for mx = metalmapStartZ, metalmapSizeX, gridSize do
			local _, groundMetal = spGetGroundInfo(mx, mz)
			if groundMetal > 0 then
				stripStart = stripStart or mx
				stripWorth = stripWorth + groundMetal
			elseif stripStart then
				DoStrip(stripStart, mx - gridSize, mz, stripWorth)
				stripStart = nil
				stripWorth = 0
			end
		end
		
		if stripStart then
			DoStrip(stripStart, metalmapSizeX, mz, stripWorth)
		end
	end
	
	-- Final processing
	for _, g in pairs(uniqueGroups) do
		local d = {}
		
		local gMinX, gMaxX = huge, -1
		local gLeft, gRight = g.left, g.right
		for iz = g.minZ, g.maxZ, gridSize do
			if gLeft[iz] < gMinX then gMinX = gLeft[iz] end
			if gRight[iz] > gMaxX then gMaxX = gRight[iz] end
		end
		local x = (gMinX + gMaxX) * 0.5
		local z = (g.minZ + g.maxZ) * 0.5
		
		d.metal, d.x, d.z = IntegrateMetal(x,z)
		
		d.y = spGetGroundOrigHeight(d.x, d.z)
		
		local merged = false
		
		for i = 1, #spots do
			local spot = spots[i]
			local dis = (d.x - spot.x)^2 + (d.z - spot.z)^2
			if dis < extractorRadiusSqr*4 then
				local metal, mx, mz = IntegrateMetal((d.x + spot.x) * 0.5, (d.z + spot.z) * 0.5)
				
				if dis < extractorRadiusSqr*1.7 or metal > (d.metal + spot.metal)*0.95 then
					spot.x = mx
					spot.y = spGetGroundOrigHeight(mx, mx)
					spot.z = mz
					merged = true
					break
				end
			end
		end
		
		if not merged then
			spots[#spots + 1] = d
		end
	end

	return spots
end

local function DoMetalMult(spots)
	local metalMult = (modOptions and modOptions.metalmult) or 1
	for i = 1, #spots do
		local spot = spots[i]
		spot.metal = spot.metal * metalMult
	end
	return spots
end

local function GetSpots(gameConfig, mapConfig)
	local spotValueOverride = false
	
	-- Check configs
	if gameConfig then
		Spring.Log(gadget:GetInfo().name, LOG.INFO, "Loading gameside mex config")
		if gameConfig.spots then
			local spots = SanitiseSpots(gameConfig.spots, gameConfig.metalValueOverride, true)
			return DoMetalMult(spots), false
		elseif gameConfig.metalValueOverride then
			spotValueOverride = gameConfig.metalValueOverride
		end
	end
	
	if mapConfig then
		Spring.Log(gadget:GetInfo().name, LOG.INFO, "Loading mapside mex config")
		if mapConfig.spots then
			local spots = SanitiseSpots(mapConfig.spots, spotValueOverride or mapConfig.metalValueOverride, spotValueOverride or false)
			return DoMetalMult(spots), false
		elseif mapConfig.metalValueOverride and not gameConfig.metalValueOverride then
			spotValueOverride = mapConfig.metalValueOverride
		end
	end

	local spots = SanitiseSpots(SearchForSpots(), spotValueOverride, true)
	return DoMetalMult(spots), true
end

------------------------------------------------------------
-- Callins
------------------------------------------------------------

function gadget:Initialize()
	Spring.Log(gadget:GetInfo().name, LOG.INFO, "Mex Spot Finder Initialising")
	local gameConfig = VFS.FileExists(GAMESIDE_METALMAP) and VFS.Include(GAMESIDE_METALMAP) or false
	local mapConfig = VFS.FileExists(MAPSIDE_METALMAP) and VFS.Include(MAPSIDE_METALMAP) or false
	if not mapConfig then
		mapConfig = VFS.FileExists(ALT_MAPSIDE_METALMAP) and VFS.Include(ALT_MAPSIDE_METALMAP) or false
	end
	local metalSpots, fromEngineMetalmap = GetSpots(gameConfig, mapConfig)
	local metalSpotsByPos = false
	
	if fromEngineMetalmap and #metalSpots < 6 then
		Spring.Log(gadget:GetInfo().name, LOG.INFO, "Indiscrete metal map detected")
		metalSpots = false
	end
	
	local metalValueOverride = gameConfig and gameConfig.metalValueOverride
	
	if metalSpots then
		metalSpotsByPos = GetSpotsByPos(metalSpots)
	end
	
	local needMexDrawing = (gameConfig and gameConfig.needMexDrawing) or (mapConfig and mapConfig.needMexDrawing)
	SetMexGameRulesParams(metalSpots)
	SetMexHelperAttributes(metalSpots, needMexDrawing)

	GG.metalSpots = metalSpots
	GG.metalSpotsByPos = metalSpotsByPos
	
	GG.IntegrateMetal = IntegrateMetal
	
	Spring.Log(gadget:GetInfo().name, LOG.INFO, "Metal Spots found and GGed")
end

--------------------------------------------------------------------------------
else  -- UNSYNCED
--------------------------------------------------------------------------------

function gadget:GameStart()
	Spring.Utilities = Spring.Utilities or {}
	VFS.Include("LuaRules/Utilities/json.lua");

	local teamlist = Spring.GetTeamList();
	local localPlayer = Spring.GetLocalPlayerID();
	local mexes = "";
	local encoded = false;
	
	for _, teamID in pairs(teamlist) do
		local _,_,_,isAI = Spring.GetTeamInfo(teamID, false)
		if isAI then
			local aiid, ainame, aihost = Spring.GetAIInfo(teamID);
			if (aihost == localPlayer) then
				if not encoded then
					local metalSpots = GetMexSpotsFromGameRules();
					mexes = 'METAL_SPOTS:'..Spring.Utilities.json.encode(metalSpots);
					encoded = true;
				end
				Spring.SendSkirmishAIMessage(teamID, mexes);
			end
		end
	end
end

function GetMexSpotsFromGameRules()
	local spGetGameRulesParam = Spring.GetGameRulesParam
	local mexCount = spGetGameRulesParam("mex_count")
	if (not mexCount) or mexCount == -1 then
		return {}
	end
	
	local metalSpots = {}
	for i = 1, mexCount do
		metalSpots[i] = {
			x = spGetGameRulesParam("mex_x" .. i),
			y = spGetGameRulesParam("mex_y" .. i),
			z = spGetGameRulesParam("mex_z" .. i),
			metal = spGetGameRulesParam("mex_metal" .. i),
		}
	end
	
	return metalSpots
end

end
