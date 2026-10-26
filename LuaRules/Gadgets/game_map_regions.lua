-- This file is part of the Spring engine (GPL v2 or later), see LICENSE.html
function gadget:GetInfo()
	return {
		name = "Map regions",
		desc = "Map region isolation for multi-region maps",
		author = "Codex",
		license = "GPL v2 or later",
		layer = -1000,
		enabled = true,
	}
end

if not gadgetHandler:IsSyncedCode() then
	return false
end

local mapRegions = VFS.Include("LuaRules/Utilities/map_regions.lua")
if not mapRegions then
	return false
end

if
	not (
		Engine.FeatureSupport
		and Engine.FeatureSupport.mapRegionViews
		and Engine.FeatureSupport.sensorRegions
		and Engine.FeatureSupport.mapDamageRegions
	)
then
	function gadget:GameFrame(f)
		if f == 1 then
			Spring.Echo("Map regions require engine mapRegionViews, sensorRegions, and mapDamageRegions support.")
			Spring.GameOver({})
		end
	end
	return
end

local regions = mapRegions.regions
local Region = mapRegions.Region
local unitRegion = {}

local function ValidUnit(unitID)
	return unitID and Spring.ValidUnitID(unitID) and not Spring.GetUnitIsDead(unitID)
end

local function GetUnitRegion(unitID)
	if unitRegion[unitID] then
		return unitRegion[unitID]
	end
	local x, _, z = Spring.GetUnitPosition(unitID)
	return Region(x, z)
end

local function SetUnitRegion(unitID, regionID)
	unitRegion[unitID] = regionID
	Spring.SetUnitRulesParam(unitID, "map_region", regionID, { public = true })
	for _, cargoID in ipairs(Spring.GetUnitIsTransporting(unitID) or {}) do
		SetUnitRegion(cargoID, regionID)
	end
end

local stateCommands = VFS.Include("LuaRules/Configs/state_commands.lua") or {}
local SUC = Spring.Utilities.CMD

-- Commands whose parameters are neither world positions nor unit/feature IDs,
-- or that pack a unit ID at cmdParams[1] alongside extra parameters.
local nonSpatialCommands = {
	[CMD.REMOVE] = true,
	[CMD.TIMEWAIT] = true,
	[CMD.SQUADWAIT] = true,
	[CMD.GATHERWAIT] = true,
	[CMD.AUTOREPAIRLEVEL] = true,
	[SUC.WANTED_SPEED] = true,
	[SUC.TRANSFER_UNIT] = true,
	[SUC.FORMATION_RANK] = true,
	[SUC.FIELD_FAC_UNIT_TYPE] = true,
	[SUC.FIELD_FAC_QUEUELESS] = true,
	[SUC.TERRAFORM_INTERNAL] = true,
}
for cmdID in pairs(stateCommands) do
	if cmdID ~= SUC.UNIT_SET_TARGET and cmdID ~= SUC.UNIT_SET_TARGET_CIRCLE then
		nonSpatialCommands[cmdID] = true
	end
end

local unitFirstParamCommands = {
	[SUC.ORBIT] = true,
	[SUC.ORBIT_DRAW] = true,
}

local nonSpatialCmdTypes = {
	[CMDTYPE.ICON] = true,
	[CMDTYPE.ICON_MODE] = true,
	[CMDTYPE.NUMBER] = true,
}

local function IsNonSpatialCommand(unitID, cmdID)
	if cmdID >= 0 and nonSpatialCommands[cmdID] then
		return true
	end
	if unitID and cmdID >= 0 then
		local cmdDescID = Spring.FindUnitCmdDesc(unitID, cmdID)
		if cmdDescID then
			local cmdDesc = Spring.GetUnitCmdDescs(unitID, cmdDescID, cmdDescID)
			local cmdType = cmdDesc and cmdDesc[1] and cmdDesc[1].type
			if cmdType and nonSpatialCmdTypes[cmdType] then
				return true
			end
		end
	end
	return false
end

local function GetCommandRegion(unitID, cmdID, cmdParams)
	if IsNonSpatialCommand(unitID, cmdID) then
		return nil, false
	end
	if unitFirstParamCommands[cmdID] then
		return ValidUnit(cmdParams[1]) and GetUnitRegion(cmdParams[1]) or nil, true
	end
	local count = #cmdParams
	if count == 3 or count == 4 then
		return Region(cmdParams[1], cmdParams[3]), true
	end
	if count == 6 then
		local r1, r2 = Region(cmdParams[1], cmdParams[3]), Region(cmdParams[4], cmdParams[6])
		return (r1 == r2 and r1) or nil, true
	end
	if count == 1 then
		local targetID = cmdParams[1]
		if targetID >= Game.maxUnits then
			local featureID = targetID - Game.maxUnits
			if Spring.ValidFeatureID(featureID) then
				local x, _, z = Spring.GetFeaturePosition(featureID)
				return Region(x, z), true
			end
		elseif ValidUnit(targetID) then
			return GetUnitRegion(targetID), true
		end
	end
	return nil, false
end

local function DamageAllowed(targetRegion, attackerID)
	local sourceRegion = attackerID and GetUnitRegion(attackerID)
	if sourceRegion and targetRegion and sourceRegion ~= targetRegion then
		return false
	end
	return true
end

function gadget:Initialize()
	assert(
		Game.mapSizeX == mapRegions.size[1] and Game.mapSizeZ == mapRegions.size[2],
		"Map region manifest and physical map disagree"
	)
	local sensorRegions = {}
	for i, r in ipairs(regions) do
		sensorRegions[i] = { r.x0, r.z0, r.x1, r.z1 }
	end
	assert(
		Spring.SetSensorRegions(sensorRegions),
		"Sensor regions must align to the engine sensor grid and be configured before simulation starts"
	)
	assert(
		Spring.SetMapDamageRegions(sensorRegions),
		"Crater regions must be configured before simulation starts"
	)

	Spring.SetGameRulesParam("map_regions", #regions)
	for i, r in ipairs(regions) do
		for _, k in ipairs({ "x0", "z0", "x1", "z1" }) do
			Spring.SetGameRulesParam("map_region_" .. i .. "_" .. k, r[k])
		end
	end

	-- Impassable terrain and build masks between authored regions.
	for x = 0, Game.mapSizeX - 8, 8 do
		for z = 0, Game.mapSizeZ - 8, 8 do
			if not Region(x + 4, z + 4) then
				Spring.SetMapSquareTerrainType(x, z, GG.IMPASSIBLE_TERRAIN)
				if x % 16 == 0 and z % 16 == 0 then
					Spring.SetSquareBuildingMask(x / 16, z / 16, 0)
				end
			end
		end
	end

	GG.MapRegions = {
		mapRegions = mapRegions,
		unitRegion = unitRegion,
		Region = Region,
		UnitRegion = GetUnitRegion,
		SetUnitRegion = SetUnitRegion,
		DamageAllowed = DamageAllowed,
	}
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	local x, _, z = Spring.GetUnitPosition(unitID)
	SetUnitRegion(unitID, Region(x, z))
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	local actualCmdID, actualParams = cmdID, cmdParams
	if cmdID == CMD.INSERT then
		if #cmdParams < 3 then
			return false
		end
		actualCmdID = cmdParams[2]
		actualParams = {}
		for i = 4, #cmdParams do
			actualParams[#actualParams + 1] = cmdParams[i]
		end
	end
	local destination, isSpatial = GetCommandRegion(unitID, actualCmdID, actualParams)
	if isSpatial and (not destination or (unitRegion[unitID] and destination ~= unitRegion[unitID])) then
		return false
	end
	return true
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam, projectileID)
	if not DamageAllowed(GetUnitRegion(unitID), attackerID) then
		return 0, 0
	end
	return damage, 1
end

function gadget:FeaturePreDamaged(featureID, featureDefID, featureTeam, damage, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
	local fx, _, fz = Spring.GetFeaturePosition(featureID)
	if not DamageAllowed(Region(fx, fz), attackerID) then
		return 0, 0
	end
	return damage, 1
end

function gadget:ShieldPreDamaged(proID, proOwnerID, shieldEmitterWeaponNum, shieldCarrierUnitID, bounceProjectile, beamEmitterWeaponNum, beamEmitterUnitID)
	local attackerID = (beamEmitterUnitID and beamEmitterUnitID >= 0 and beamEmitterUnitID) or proOwnerID
	if not DamageAllowed(GetUnitRegion(shieldCarrierUnitID), attackerID) then
		return true
	end
	return false
end

function gadget:GameFrame(f)
	if f % 15 == 0 then
		for unitID, regionID in pairs(unitRegion) do
			if ValidUnit(unitID) and not Spring.GetUnitTransporter(unitID) then
				local x, y, z = Spring.GetUnitPosition(unitID)
				local unitDefID = Spring.GetUnitDefID(unitID)
				local isAir = unitDefID and UnitDefs[unitDefID] and UnitDefs[unitDefID].canFly
				local r = isAir and mapRegions.objectBounds[regionID] or regions[regionID]
				if (isAir and not mapRegions.ContainsObject(regionID, x, z)) or (not isAir and Region(x, z) ~= regionID) then
					local tx = math.max(r.x0 + 24, math.min(r.x1 - 24, x))
					local tz = math.max(r.z0 + 24, math.min(r.z1 - 24, z))
					if isAir then
						Spring.SetUnitPosition(unitID, tx, y, tz)
					else
						GG.MoveMobileUnit(unitID, tx, y, tz)
					end
					Spring.SetUnitVelocity(unitID, 0, 0, 0)
				end
			end
		end
	end

	if f % 30 == 0 then
		for unitID, regionID in pairs(unitRegion) do
			local r = regions[regionID]
			if r.surface and r.surface.damage and ValidUnit(unitID) then
				local _, y, _ = Spring.GetUnitPosition(unitID)
				if y < r.surface.height + 2 and not Spring.GetUnitTransporter(unitID) then
					Spring.AddUnitDamage(unitID, r.surface.damage)
				end
			end
		end
	end
end

function gadget:Shutdown()
	GG.MapRegions = nil
end
