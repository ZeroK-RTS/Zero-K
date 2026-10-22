-- This file is part of the Spring engine (GPL v2 or later), see LICENSE.html
function gadget:GetInfo()
	return {
		name = "Portal worlds",
		desc = "Map region isolation for composed multi-region maps",
		author = "Codex",
		license = "GPL v2 or later",
		layer = -1000,
		enabled = true,
	}
end

if not gadgetHandler:IsSyncedCode() then
	return false
end

local world = VFS.Include("LuaRules/Utilities/portal_worlds.lua")
if not world then
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

local regions = world.regions
local Region = world.Region
local home, projectiles = {}, {}

local function Valid(id)
	return id and Spring.ValidUnitID(id) and not Spring.GetUnitIsDead(id)
end

local function UnitRegion(id)
	if home[id] then
		return home[id]
	end
	local x, _, z = Spring.GetUnitPosition(id)
	return Region(x, z)
end

local function SetUnitRegion(id, region)
	home[id] = region
	Spring.SetUnitRulesParam(id, "portal_region", region, { public = true })
	for _, cargo in ipairs(Spring.GetUnitIsTransporting(id) or {}) do
		SetUnitRegion(cargo, region)
	end
end

-- Wrap Spring.SetUnitTarget before unit_* gadgets cache it so Lua target
-- setters (e.g. unit_target_on_the_move, unit_timeslow) cannot target across regions.
local rawSetUnitTarget = Spring.SetUnitTarget
Spring.SetUnitTarget = function(unitID, arg1, arg2, arg3, ...)
	if arg1 ~= nil and arg1 ~= 0 and unitID then
		local source = UnitRegion(unitID)
		if type(arg3) == "number" then
			if not source or Region(arg1, arg3) ~= source then
				return false
			end
		elseif type(arg1) == "number" and arg1 > 0 then
			if not source or UnitRegion(arg1) ~= source then
				return false
			end
		end
	end
	return rawSetUnitTarget(unitID, arg1, arg2, arg3, ...)
end

local stateCommands = VFS.Include("LuaRules/Configs/state_commands.lua") or {}
local SUC = Spring.Utilities.CMD

-- Commands whose parameters are neither world positions nor unit/feature IDs,
-- or that pack a unit ID at params[1] alongside extra parameters.
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
for cmd in pairs(stateCommands) do
	if cmd ~= SUC.UNIT_SET_TARGET and cmd ~= SUC.UNIT_SET_TARGET_CIRCLE then
		nonSpatialCommands[cmd] = true
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

local function IsNonSpatialCommand(id, cmd)
	if cmd >= 0 and nonSpatialCommands[cmd] then
		return true
	end
	if id and cmd >= 0 then
		local cmdDescID = Spring.FindUnitCmdDesc(id, cmd)
		if cmdDescID then
			local cmdDesc = Spring.GetUnitCmdDescs(id, cmdDescID, cmdDescID)
			local cmdType = cmdDesc and cmdDesc[1] and cmdDesc[1].type
			if cmdType and nonSpatialCmdTypes[cmdType] then
				return true
			end
		end
	end
	return false
end

local function CommandRegion(id, cmd, params)
	if IsNonSpatialCommand(id, cmd) then
		return nil, false
	end
	if unitFirstParamCommands[cmd] then
		return Valid(params[1]) and UnitRegion(params[1]) or nil, true
	end
	local count = #params
	if count == 3 or count == 4 then
		return Region(params[1], params[3]), true
	end
	if count == 6 then
		local r1, r2 = Region(params[1], params[3]), Region(params[4], params[6])
		return (r1 == r2 and r1) or nil, true
	end
	if count == 1 then
		local targetID = params[1]
		if targetID >= Game.maxUnits then
			local featureID = targetID - Game.maxUnits
			if Spring.ValidFeatureID(featureID) then
				local x, _, z = Spring.GetFeaturePosition(featureID)
				return Region(x, z), true
			end
		elseif Valid(targetID) then
			return UnitRegion(targetID), true
		end
	end
	return nil, false
end

local function DeleteProjectile(id)
	local p = projectiles[id]
	if p and not p.deleted then
		p.deleted = true
		Spring.SetProjectilePosition(id, -world.size[1] - world.minimumGap, 100000, -world.size[2] - world.minimumGap)
		Spring.SetProjectileVelocity(id, 0, 0, 0)
		Spring.DeleteProjectile(id)
	end
end

local function TargetRegion(id)
	local kind, target = Spring.GetProjectileTarget(id)
	if kind == string.byte("g") and type(target) == "table" then
		if target[1] ~= 0 or target[3] ~= 0 then
			return Region(target[1], target[3])
		end
	elseif kind == string.byte("u") then
		return UnitRegion(target)
	elseif kind == string.byte("f") then
		local x, _, z = Spring.GetFeaturePosition(target)
		return Region(x, z)
	end
end

local function DamageAllowed(targetRegion, attacker, projectile)
	local p = projectile and projectiles[projectile]
	local source = (p and p.region) or (attacker and UnitRegion(attacker))
	if source and targetRegion and source ~= targetRegion then
		return false
	end
	return true
end

function gadget:Initialize()
	assert(
		Game.mapSizeX == world.size[1] and Game.mapSizeZ == world.size[2],
		"Portal manifest and physical map disagree"
	)
	local sensorRegions = {}
	for i, r in ipairs(regions) do
		sensorRegions[i] = { r.x0, r.z0, r.x1, r.z1 }
	end
	assert(
		Spring.SetSensorRegions(sensorRegions),
		"Portal sensor regions must align to the engine sensor grid and be configured before simulation starts"
	)
	assert(
		Spring.SetMapDamageRegions(sensorRegions),
		"Portal crater regions must be configured before simulation starts"
	)

	Spring.SetGameRulesParam("portal_regions", #regions)
	for i, r in ipairs(regions) do
		for _, k in ipairs({ "x0", "z0", "x1", "z1" }) do
			Spring.SetGameRulesParam("portal_r" .. i .. "_" .. k, r[k])
		end
	end

	-- Cubicle barriers: impassable terrain and build masks between authored regions.
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

	for id in pairs(WeaponDefs) do
		Script.SetWatchProjectile(id, true)
		Script.SetWatchAllowTarget(id, true)
	end

	GG.PortalWorlds = {
		world = world,
		home = home,
		Region = Region,
		UnitRegion = UnitRegion,
		SetUnitRegion = SetUnitRegion,
		DamageAllowed = DamageAllowed,
		UnitDamageAllowed = function(id, attacker, projectile)
			return DamageAllowed(UnitRegion(id), attacker, projectile)
		end,
	}
end

function gadget:UnitCreated(id, def, team, builder)
	local x, _, z = Spring.GetUnitPosition(id)
	SetUnitRegion(id, (builder and home[builder]) or Region(x, z))
end

function gadget:UnitDestroyed(id)
	home[id] = nil
end

function gadget:AllowUnitCreation(unitDefID, builderID, builderTeam, x, y, z, facing)
	if not builderID then
		return true
	end
	local builderRegion = UnitRegion(builderID)
	if x == nil or z == nil then
		local builderDef = UnitDefs[Spring.GetUnitDefID(builderID)]
		return (builderDef and builderDef.isFactory and builderRegion ~= nil) or false
	end
	local ud = UnitDefs[unitDefID]
	local hx, hz = ud.xsize * 4, ud.zsize * 4
	if facing and facing % 2 == 1 then
		hx, hz = hz, hx
	end
	local r = regions[builderRegion]
	if not r or Region(x, z) ~= builderRegion
		or x - hx < r.x0 or x + hx > r.x1 or z - hz < r.z0 or z + hz > r.z1 then
		return false
	end
	return true
end

function gadget:AllowCommand(id, def, team, cmd, params, opts)
	local actual, p = cmd, params
	if cmd == CMD.INSERT then
		if #params < 3 then
			return false
		end
		actual = params[2]
		p = {}
		for i = 4, #params do
			p[#p + 1] = params[i]
		end
	end
	local destination, isSpatial = CommandRegion(id, actual, p)
	if isSpatial and (not destination or (home[id] and destination ~= home[id])) then
		return false
	end
	return true
end

function gadget:AllowWeaponTarget(attacker, target, weaponNum, weaponDef, priority)
	local source, destination = UnitRegion(attacker), UnitRegion(target)
	return source ~= nil and source == destination, priority
end

function gadget:AllowWeaponInterceptTarget(id, weapon, projectile)
	local p = projectiles[projectile]
	return p and p.region == UnitRegion(id) or false
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam, projectileID)
	if not DamageAllowed(UnitRegion(unitID), attackerID, projectileID) then
		return 0, 0
	end
	return damage, 1
end

function gadget:FeaturePreDamaged(featureID, featureDefID, featureTeam, damage, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
	local fx, _, fz = Spring.GetFeaturePosition(featureID)
	if not DamageAllowed(Region(fx, fz), attackerID, projectileID) then
		return 0, 0
	end
	return damage, 1
end

function gadget:ShieldPreDamaged(proID, proOwnerID, shieldEmitterWeaponNum, shieldCarrierUnitID, bounceProjectile, beamEmitterWeaponNum, beamEmitterUnitID)
	local attacker = (beamEmitterUnitID and beamEmitterUnitID >= 0 and beamEmitterUnitID) or proOwnerID
	if not DamageAllowed(UnitRegion(shieldCarrierUnitID), attacker, proID) then
		return true
	end
	return false
end

function gadget:ProjectileCreated(id, owner, weapon)
	local x, _, z = Spring.GetProjectilePosition(id)
	local region = (owner and UnitRegion(owner)) or Region(x, z)
	projectiles[id] = { region = region }
	if not world.ContainsObject(region, x, z) then
		DeleteProjectile(id)
	end
end

function gadget:ProjectileDestroyed(id)
	local p = projectiles[id]
	if p then
		p.expires = Spring.GetGameFrame() + 900
	end
end

function gadget:GameFrame(f)
	for id, p in pairs(projectiles) do
		if p.expires then
			if f >= p.expires then
				projectiles[id] = nil
			end
		elseif not p.deleted then
			local x, _, z = Spring.GetProjectilePosition(id)
			if not x or not world.ContainsObject(p.region, x, z) then
				DeleteProjectile(id)
			else
				local vx, _, vz = Spring.GetProjectileVelocity(id)
				if vx and not world.ContainsObject(p.region, x + vx, z + vz) then
					DeleteProjectile(id)
				else
					local target = TargetRegion(id)
					if target and target ~= p.region then
						DeleteProjectile(id)
					end
				end
			end
		end
	end

	if f % 5 == 0 then
		for id, region in pairs(home) do
			if Valid(id) and not Spring.GetUnitTransporter(id) then
				local x, y, z = Spring.GetUnitPosition(id)
				local aircraft = UnitDefs[Spring.GetUnitDefID(id)].canFly
				local r = aircraft and world.objectBounds[region] or regions[region]
				if (aircraft and not world.ContainsObject(region, x, z)) or (not aircraft and Region(x, z) ~= region) then
					local tx = math.max(r.x0 + 24, math.min(r.x1 - 24, x))
					local tz = math.max(r.z0 + 24, math.min(r.z1 - 24, z))
					if aircraft then
						Spring.SetUnitPosition(id, tx, y, tz)
					else
						GG.MoveMobileUnit(id, tx, y, tz)
					end
					Spring.SetUnitVelocity(id, 0, 0, 0)
				end
			end
		end
	end

	if f % 30 == 0 then
		for id, region in pairs(home) do
			local r = regions[region]
			if r.surface and r.surface.damage and Valid(id) then
				local _, y, _ = Spring.GetUnitPosition(id)
				if y < r.surface.height + 2 and not Spring.GetUnitTransporter(id) then
					Spring.AddUnitDamage(id, r.surface.damage)
				end
			end
		end
	end
end

function gadget:Shutdown()
	Spring.SetUnitTarget = rawSetUnitTarget
	GG.PortalWorlds = nil
end
