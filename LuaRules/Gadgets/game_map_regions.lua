function gadget:GetInfo()
	return {
		name      = "Map Regions",
		desc      = "Keeps units, commands and damage inside the regions of a multi-region map",
		author    = "gajop",
		date      = "2026-11",
		license   = "GNU GPL, v2 or later",
		layer     = -1000,
		enabled   = true,
	}
end

if not gadgetHandler:IsSyncedCode() then
	return false
end

local mapRegions = VFS.Include("LuaRules/Gadgets/Include/map_regions.lua")
if not mapRegions then
	return false
end

local function EndGameAtStart(message)
	function gadget:GameFrame(n)
		if n == 1 then
			Spring.Echo(message)
			Spring.GameOver({})
		end
	end
end

if not (Engine.FeatureSupport and Engine.FeatureSupport.mapRegionViews
		and Engine.FeatureSupport.sensorRegions and Engine.FeatureSupport.mapDamageRegions) then
	EndGameAtStart("Map regions require engine mapRegionViews, sensorRegions, and mapDamageRegions support.")
	return
end

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")

local regions = mapRegions.regions
local Region = mapRegions.Region

local CONTAIN_UPDATE_FREQ = 15
local SURFACE_DAMAGE_FREQ = 30
local PRIVATE = {private = true}

-- Region of every unit that has existed this session. Entries outlive the unit:
-- ShieldPreDamaged reports the raw owner ID of projectiles whose owner has died.
-- Unit/FeaturePreDamaged receive a nil attacker for dead owners, so damage from
-- such projectiles is not filtered there. Live units also store their region in
-- the "map_region" unit rules param, so LuaRules reload restores it exactly;
-- dead owners are forgotten at that point.
local unitRegion = {}
-- Live units checked every CONTAIN_UPDATE_FREQ frames, keyed by unitID with the
-- unitDefID as value: all mobile units, plus structures in regions with surface damage.
local checkedUnits = IterableMap.New()

local flyingDefs = {}
local mobileDefs = {}
for unitDefID = 1, #UnitDefs do
	local moveType = Spring.Utilities.getMovetype(UnitDefs[unitDefID])
	if moveType then
		mobileDefs[unitDefID] = true
		flyingDefs[unitDefID] = (moveType ~= 2)
	end
end

-- Optional per-region surface damage: units below surface.height + 2 take
-- surface.damage every SURFACE_DAMAGE_FREQ frames. Nil when no region has one.
local surfaceDamage
for i, r in ipairs(regions) do
	if r.surface and r.surface.damage then
		surfaceDamage = surfaceDamage or {}
		surfaceDamage[i] = r.surface
	end
end

local function SpawnRegion(x, z)
	local regionID = Region(x, z)
	if regionID then
		return regionID
	end
	-- Units created in a separating strip still need a region for commands,
	-- damage and containment. Ties follow manifest order.
	local best, bestDistance
	for i, r in ipairs(regions) do
		local dx = x - math.max(r.x0 + 1, math.min(x, r.x1 - 1))
		local dz = z - math.max(r.z0 + 1, math.min(z, r.z1 - 1))
		local distance = dx * dx + dz * dz
		if not bestDistance or distance < bestDistance then
			best, bestDistance = i, distance
		end
	end
	return best
end

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

-- Mobile units are always checked; structures only while their region has
-- surface damage, so a region change can add or drop them.
local function UpdateCheckedUnit(unitID, unitDefID, regionID)
	if mobileDefs[unitDefID] or (surfaceDamage and surfaceDamage[regionID]) then
		IterableMap.Add(checkedUnits, unitID, unitDefID)
	else
		IterableMap.Remove(checkedUnits, unitID)
	end
end

local function SetUnitRegion(unitID, regionID)
	unitRegion[unitID] = regionID
	Spring.SetUnitRulesParam(unitID, "map_region", regionID, PRIVATE)
	local unitDefID = Spring.GetUnitDefID(unitID)
	if unitDefID then
		UpdateCheckedUnit(unitID, unitDefID, regionID)
	end
	for _, cargoID in ipairs(Spring.GetUnitIsTransporting(unitID) or {}) do
		SetUnitRegion(cargoID, regionID)
	end
end

--------------------------------------------------------------------------------
-- Commands

local stateCommands = VFS.Include("LuaRules/Configs/state_commands.lua") or {}
local SUC = Spring.Utilities.CMD

-- Whether a command's parameters are neither world positions nor unit/feature IDs.
-- Filled lazily from command descriptions, keyed by cmdID.
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

-- Whether a command's single parameter is a unit or feature ID. Filled lazily
-- from command descriptions, keyed by cmdID, like nonSpatialCommands.
local entityTargetCommands = {
	[CMD.ATTACK] = true,
	[CMD.GUARD] = true,
	[CMD.REPAIR] = true,
	[CMD.RECLAIM] = true,
	[CMD.RESURRECT] = true,
	[CMD.CAPTURE] = true,
	[CMD.LOAD_UNITS] = true,
	[CMD.LOAD_ONTO] = true,
	[CMD.MANUALFIRE] = true,
}

local entityTargetCmdTypes = {
	[CMDTYPE.ICON_UNIT] = true,
	[CMDTYPE.ICON_UNIT_OR_MAP] = true,
	[CMDTYPE.ICON_UNIT_OR_AREA] = true,
	[CMDTYPE.ICON_UNIT_FEATURE_OR_AREA] = true,
	[CMDTYPE.ICON_UNIT_OR_RECTANGLE] = true,
}

-- Returns whether the parameters are neither positions nor unit/feature IDs,
-- and whether a single parameter is a unit or feature ID.
local function ClassifyCommand(unitID, cmdID)
	local nonSpatial = nonSpatialCommands[cmdID]
	if nonSpatial ~= nil then
		return nonSpatial, entityTargetCommands[cmdID] == true
	end
	local cmdDescID = Spring.FindUnitCmdDesc(unitID, cmdID)
	local cmdDesc = cmdDescID and Spring.GetUnitCmdDescs(unitID, cmdDescID, cmdDescID)[1]
	if not (cmdDesc and cmdDesc.type) then
		-- Not cached: another unit may have the description. Positions are still
		-- checked, a single parameter is only a target for known target commands.
		return false, entityTargetCommands[cmdID] == true
	end
	nonSpatial = nonSpatialCmdTypes[cmdDesc.type] or false
	nonSpatialCommands[cmdID] = nonSpatial
	entityTargetCommands[cmdID] = entityTargetCommands[cmdID] or entityTargetCmdTypes[cmdDesc.type] or false
	return nonSpatial, entityTargetCommands[cmdID]
end

local function GetCommandRegion(unitID, cmdID, cmdParams)
	local nonSpatial, targetsEntity = ClassifyCommand(unitID, cmdID)
	if nonSpatial then
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
	if count == 1 and targetsEntity then
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

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if cmdID == CMD.INSERT then
		if #cmdParams < 3 then
			return false
		end
		local insertedParams = {}
		for i = 4, #cmdParams do
			insertedParams[#insertedParams + 1] = cmdParams[i]
		end
		cmdID, cmdParams = cmdParams[2], insertedParams
	end
	local destination, isSpatial = GetCommandRegion(unitID, cmdID, cmdParams)
	if isSpatial and (not destination or (unitRegion[unitID] and destination ~= unitRegion[unitID])) then
		return false
	end
	return true
end

--------------------------------------------------------------------------------
-- Damage

local function DamageAllowed(targetRegion, attackerID)
	local sourceRegion = attackerID and GetUnitRegion(attackerID)
	return not (sourceRegion and targetRegion and sourceRegion ~= targetRegion)
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam, projectileID)
	if not DamageAllowed(GetUnitRegion(unitID), attackerID) then
		return 0, 0
	end
	return damage, 1
end

function gadget:FeaturePreDamaged(featureID, featureDefID, featureTeam, damage, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
	local x, _, z = Spring.GetFeaturePosition(featureID)
	if not DamageAllowed(Region(x, z), attackerID) then
		return 0, 0
	end
	return damage, 1
end

function gadget:ShieldPreDamaged(proID, proOwnerID, shieldEmitterWeaponNum, shieldCarrierUnitID, bounceProjectile, beamEmitterWeaponNum, beamEmitterUnitID)
	local attackerID = (beamEmitterUnitID and beamEmitterUnitID >= 0 and beamEmitterUnitID) or proOwnerID
	return not DamageAllowed(GetUnitRegion(shieldCarrierUnitID), attackerID)
end

--------------------------------------------------------------------------------
-- Containment

local function ContainUnit(unitID, regionID, isFlying, x, y, z)
	if isFlying then
		if mapRegions.ContainsObject(regionID, x, z) then
			return
		end
	elseif Region(x, z) == regionID then
		return
	end
	local r = isFlying and mapRegions.objectBounds[regionID] or regions[regionID]
	local tx = math.max(r.x0 + 24, math.min(r.x1 - 24, x))
	local tz = math.max(r.z0 + 24, math.min(r.z1 - 24, z))
	if isFlying then
		Spring.SetUnitPosition(unitID, tx, y, tz)
	else
		GG.MoveMobileUnit(unitID, tx, y, tz)
	end
	Spring.SetUnitVelocity(unitID, 0, 0, 0)
end

local function CheckUnit(unitID, unitDefID, index, surfaceTick)
	if Spring.GetUnitTransporter(unitID) then
		return
	end
	local regionID = unitRegion[unitID]
	local x, y, z = Spring.GetUnitPosition(unitID)
	if mobileDefs[unitDefID] then
		ContainUnit(unitID, regionID, flyingDefs[unitDefID], x, y, z)
	end
	if surfaceTick then
		local surface = surfaceDamage[regionID]
		if surface and y < surface.height + 2 then
			Spring.AddUnitDamage(unitID, surface.damage)
		end
	end
end

function gadget:GameFrame(n)
	-- Each unit is visited once per CONTAIN_UPDATE_FREQ frames; surface damage
	-- applies on every other visit.
	local surfaceTick = surfaceDamage and (n % SURFACE_DAMAGE_FREQ < CONTAIN_UPDATE_FREQ)
	IterableMap.ApplyFraction(checkedUnits, CONTAIN_UPDATE_FREQ, n % CONTAIN_UPDATE_FREQ, CheckUnit, surfaceTick)
end

--------------------------------------------------------------------------------
-- Unit tracking

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	local x, _, z = Spring.GetUnitPosition(unitID)
	local regionID = SpawnRegion(x, z)
	SetUnitRegion(unitID, regionID)
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	-- unitRegion keeps the entry, see above.
	IterableMap.Remove(checkedUnits, unitID)
end

--------------------------------------------------------------------------------
-- Initialization

local function ConfigureEngine()
	local rectangles = {}
	for i, r in ipairs(regions) do
		rectangles[i] = {r.x0, r.z0, r.x1, r.z1}
	end
	if not Spring.SetSensorRegions(rectangles) then
		return "sensor"
	end
	if not Spring.SetMapDamageRegions(rectangles) then
		return "crater"
	end

	Spring.SetGameRulesParam("map_regions", #regions)
	for i, r in ipairs(regions) do
		for _, k in ipairs({"x0", "z0", "x1", "z1"}) do
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
end

function gadget:Initialize()
	assert(Game.mapSizeX == mapRegions.size[1] and Game.mapSizeZ == mapRegions.size[2],
		"Map region manifest and physical map disagree")

	-- Sensor and crater regions, rules params and the typemap are engine state:
	-- they persist across LuaRules reload and are saved with the game, and the
	-- engine may refuse region changes once simulation has started.
	if Spring.GetGameFrame() <= 0 then
		local rejected = ConfigureEngine()
		if rejected then
			EndGameAtStart("Map regions: the engine rejected the map's " .. rejected .. " regions, so the map cannot be played.")
			return
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

	-- After a LuaRules reload, units keep the region recorded in their rules param,
	-- which also covers units inside transports or standing in the separating strip.
	-- Units without one fall back to their position.
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local regionID = Spring.GetUnitRulesParam(unitID, "map_region")
		if not regions[regionID] then
			local x, _, z = Spring.GetUnitPosition(unitID)
			regionID = SpawnRegion(x, z)
			Spring.SetUnitRulesParam(unitID, "map_region", regionID, PRIVATE)
		end
		unitRegion[unitID] = regionID
		UpdateCheckedUnit(unitID, Spring.GetUnitDefID(unitID), regionID)
	end
end

function gadget:Shutdown()
	GG.MapRegions = nil
end
