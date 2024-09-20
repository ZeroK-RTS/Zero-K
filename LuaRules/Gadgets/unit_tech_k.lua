--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local modoption = Spring.GetModOptions().techk
function gadget:GetInfo()
	return {
		name      = "Tech-K",
		desc      = "Implements Tech-K",
		author    = "GoogleFrog",
		date      = "16 September 2024",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = (modoption == "1") or (modoption == 1),
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local explosionDefID = {}
local explosionRadius = {}
local deathCloneDefID = {}
local Vector = Spring.Utilities.Vector

if not gadgetHandler:IsSyncedCode() then
	return
end

local INLOS_ACCESS = {inlos = true}

local function SetUnitTechLevel(unitID, level)
	local unitDefID = Spring.GetUnitDefID(unitID)
	--Spring.Utilities.UnitEcho(unitID, level)
	
	local sizeScale = math.pow(1.6, math.pow(level, 0.4) - 1)
	local projectiles = math.pow(2, level - 1)
	local speed = math.pow(0.8, level - 1)
	local range = math.pow(1.1, level - 1)
	
	local redTint = math.pow(0.82, level - 1)
	local otherTint = math.pow(0.7, level - 1)
	local simpleDoubling = math.pow(2, level - 1)
	local energy = math.pow(1.5, level - 1) -- Multiplier for energy on top of the base econ multiplier
	local healthMult = math.pow(2, level - 1)
	
	GG.Attributes.AddEffect(unitID, "tech", {
		projectiles = projectiles,
		speed = speed,
		range = range,
		cost = simpleDoubling,
		econ = simpleDoubling,
		energy = energy,
		shieldRegen = simpleDoubling,
		healthRegen = simpleDoubling,
		build = simpleDoubling,
		healthMult = healthMult,
		projSpeed = math.sqrt(range), -- Maintains Cannon range.
		minSprayAngle = (math.pow(level, 0.25) - 1) * 0.04
	})
	GG.SetColvolScales(unitID, {1 + (sizeScale - 1)*0.2, sizeScale, 1 + (sizeScale - 1)*0.2})
	GG.UnitModelRescale(unitID, sizeScale)
	GG.TintUnit(unitID, redTint, otherTint, otherTint)
	Spring.SetUnitRulesParam(unitID, "tech_level", level, INLOS_ACCESS)
end

local function AddExplosions(unitID, unitDefID, teamID, level)
	local extraExplosions = math.pow(2, level - 1) - 1
	if not explosionDefID[unitDefID] then
		local wd = WeaponDefNames[UnitDefs[unitDefID].deathExplosion]
		explosionDefID[unitDefID] = wd.id
		explosionRadius[unitDefID] = wd.damageAreaOfEffect or 0
	end
	local _, _, _, ux, uy, uz = Spring.GetUnitPosition(unitID, true)
	local projectileParams = {
		pos = {ux, uy, uz},
		["end"] = {ux, uy - 1, uz},
		owner = unitID,
		team = teamID,
		ttl = 0,
	}
	local radius = (5 + 15*level)*(50 + math.pow(explosionRadius[unitDefID], 0.8))/100
	for i = 1, extraExplosions do
		local rand = Vector.RandomPointInCircle(radius)
		projectileParams.pos[1] = ux + rand[1]
		projectileParams.pos[3] = uz + rand[2]
		local proID = Spring.SpawnProjectile(explosionDefID[unitDefID], projectileParams)
		if proID then
			Spring.SetProjectileCollision(proID)
		end
	end
end

local function AddFeature(unitID, unitDefID, teamID, level)
	local _,_,inBuild = Spring.GetUnitIsStunned(unitID)
	if inBuild then
		return
	end
	local extraFeatures = math.pow(2, level - 1) - 1
	if not deathCloneDefID[unitDefID] then
		local wreckName = UnitDefs[unitDefID].wreckName
		deathCloneDefID[unitDefID] = (wreckName and FeatureDefNames[wreckName] and FeatureDefNames[wreckName].id) or -1
	end
	if deathCloneDefID[unitDefID] == -1 then
		return
	end
	local _, _, _, ux, uy, uz = Spring.GetUnitPosition(unitID, true)
	local vx, vy, vz = Spring.GetUnitVelocity(unitID, true)
	local allyTeamID = Spring.GetUnitAllyTeam(unitID)
	local maxMag = 1 + 3*level
	for i = 1, extraFeatures do
		local rand, randMag = Vector.RandomPointInCircle(maxMag)
		local featureID = Spring.CreateFeature(deathCloneDefID[unitDefID], ux + rand[1]*0.4, uy, uz + rand[2]*0.4, math.random()*2^16, allyTeamID)
		if featureID then
			local ySpeed = 1.2*maxMag - randMag
			Spring.SetFeatureVelocity(featureID, rand[1]*0.1 + vx, ySpeed*0.1 + vy, rand[2]*0.1 + vz)
		end
	end
end

function gadget:UnitCreated(unitID, unitDefID)
	SetUnitTechLevel(unitID, math.floor(math.random()*8) + 1)
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	if GG.wasMorphedTo[unitID] then
		-- TODO, set level of new unit
		return
	end
	local level = Spring.GetUnitRulesParam(unitID, "tech_level") or 1
	if level <= 1 then
		return
	end
	AddExplosions(unitID, unitDefID, teamID, level)
	AddFeature(unitID, unitDefID, teamID, level)
end
