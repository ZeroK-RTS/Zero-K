if (not gadgetHandler:IsSyncedCode()) then
	return
end

function gadget:GetInfo()
	return {
		name      = "Typemap Options",
		desc      = "Edit's the map's typemap at the start of the game.",
		author    = "Google Frog",
		date      = "Feb, 2010",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

local terrainNameToIndex = {}
local oldTerrain = {}

local IMPASSIBLE_TERRAIN = 137 -- Hope that this does not conflict with any maps
local NANOFRAMES_BLOCK = false -- Allows for LOS hax.

local retainImpassException, retainRoadException = VFS.Include("LuaRules/Configs/typemap_options_maps.lua")
local RETAIN_MAP_IMPASSIBLE = not retainImpassException[Game.mapName]
local RETAIN_MAP_ROAD = not retainRoadException[Game.mapName]

local function Round(x)
	return math.floor((x + 4)/8)*8
end

local function SetImpassibleTerrain(x1, z1, x2, z2)
	x1, z1, x2, z2 = Round(x1), Round(z1), Round(x2), Round(z2)
	
	-- Save old terrain
	for i = x1, x2, 8 do
		oldTerrain[i] = oldTerrain[i] or {}
		for j = z1, z2, 8 do
			if not oldTerrain[i][j] then
				local terrainType = Spring.GetGroundInfo(i, j)
				if terrainNameToIndex[terrainType] then
					oldTerrain[i][j] = terrainNameToIndex[terrainType]
				end
			end
		end
	end
	
	-- Override terrain
	for i = x1, x2, 8 do
		for j = z1, z2, 8 do
			Spring.SetMapSquareTerrainType(i, j, IMPASSIBLE_TERRAIN)
		end
	end
end

local function ResetTerrain(x1, z1, x2, z2)
	x1, z1, x2, z2 = Round(x1), Round(z1), Round(x2), Round(z2)

	for i = x1, x2, 8 do
		for j = z1, z2, 8 do
			Spring.SetMapSquareTerrainType(i, j, (oldTerrain[i] and oldTerrain[i][j]) or 0)
		end
	end
end

local function GetUnitBounds(unitID, unitDefID)
	local ud = UnitDefs[unitDefID]
	local ux,_,uz = Spring.GetUnitPosition(unitID, true)
	local xsize = ud.xsize*4
	local zsize = ud.zsize*4

	local minx = ux - xsize
	local minz = uz - zsize
	local maxx = ux + xsize - 8
	local maxz = uz + zsize - 8
	return minx, minz, maxx, maxz
end

local function CreateImpassibleFootprint(unitID, unitDefID)
	local minx, minz, maxx, maxz = GetUnitBounds(unitID, unitDefID)
	SetImpassibleTerrain(minx, minz, maxx, maxz)
end

local function DestroyImpassibleFootprint(unitID, unitDefID)
	local minx, minz, maxx, maxz = GetUnitBounds(unitID, unitDefID)
	ResetTerrain(minx, minz, maxx, maxz)
end

function gadget:UnitCreated(unitID, unitDefID)
	if NANOFRAMES_BLOCK and (Spring.Utilities.getMovetype(UnitDefs[unitDefID]) == 2) then
		local _, _, inBuild = Spring.GetUnitIsStunned(unitID)
		if inBuild then
			CreateImpassibleFootprint(unitID, unitDefID)
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID)
	if NANOFRAMES_BLOCK and (Spring.Utilities.getMovetype(UnitDefs[unitDefID]) == 2) then
		DestroyImpassibleFootprint(unitID, unitDefID)
	end
end

function gadget:UnitFinished(unitID, unitDefID)
	if NANOFRAMES_BLOCK and (Spring.Utilities.getMovetype(UnitDefs[unitDefID]) == 2) then
		DestroyImpassibleFootprint(unitID, unitDefID)
	end
end

local function CheckNotImpassible(t, k, h, s)
	if (not RETAIN_MAP_IMPASSIBLE) then
		return true
	end
	return t > 0 or k > 0 or h > 0 or s > 0
end

function gadget:Initialize()
	Spring.SetTerrainTypeData(IMPASSIBLE_TERRAIN, 0, 0, 0, 0)
	if (Spring.GetModOptions().typemapsetting == "1") or (not RETAIN_MAP_ROAD) then
		for i = 0, 255 do
			if i ~= IMPASSIBLE_TERRAIN then
				local name, _, t, k, h, s = Spring.GetTerrainTypeData(i)
				if CheckNotImpassible(t, k, h, s) then
					Spring.SetTerrainTypeData(i, 1, 1, 1, 1)
				end
			end
		end
	else
		for i = 0, 255 do
			if i ~= IMPASSIBLE_TERRAIN then
				local name, _, t, k, h, s = Spring.GetTerrainTypeData(i)
				if name and not terrainNameToIndex[name] then
					terrainNameToIndex[name] = i
				end
				if CheckNotImpassible(t, k, h, s) and not (t == k and k == h and h == s and t ~= 0) then
					Spring.SetTerrainTypeData(i, 1,1,1,1)
				end
			end
		end
	end
end
