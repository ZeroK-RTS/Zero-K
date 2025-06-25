
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Attributes Generic",
		desc      = "Handles UnitRulesParam attributes in a generic way.",
		author    = "GoogleFrog", -- v1 CarReparier & GoogleFrog
		date      = "2018-11-30", -- v1 2009-11-27
		license   = "GNU GPL, v2 or later",
		layer     = -1,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local UPDATE_PERIOD = 3

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local floor = math.floor

local spValidUnitID            = Spring.ValidUnitID
local spGetUnitDefID           = Spring.GetUnitDefID
local spGetGameFrame           = Spring.GetGameFrame
local spSetUnitRulesParam      = Spring.SetUnitRulesParam
local spGetUnitRulesParam      = Spring.GetUnitRulesParam

local spSetUnitBuildSpeed      = Spring.SetUnitBuildSpeed
local spSetUnitWeaponState     = Spring.SetUnitWeaponState
local spGetUnitWeaponState     = Spring.GetUnitWeaponState
local spSetUnitWeaponDamages   = Spring.SetUnitWeaponDamages

local spGetUnitMoveTypeData    = Spring.GetUnitMoveTypeData
local spMoveCtrlGetTag         = Spring.MoveCtrl.GetTag
local spSetAirMoveTypeData     = Spring.MoveCtrl.SetAirMoveTypeData
local spSetGunshipMoveTypeData = Spring.MoveCtrl.SetGunshipMoveTypeData
local spSetGroundMoveTypeData  = Spring.MoveCtrl.SetGroundMoveTypeData

local spSetUnitCOBValue = Spring.SetUnitCOBValue

local ALLY_ACCESS = {allied = true}
local INLOS_ACCESS = {inlos = true}
local WACKY_CONVERSION_FACTOR_1 = 2184.53

local getMovetype = Spring.Utilities.getMovetype
local Vector = Spring.Utilities.Vector

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")

local HALF_FRAME = 1 / (2 * Game.gameSpeed)

local workingGroundMoveType = true -- not ((Spring.GetModOptions() and (Spring.GetModOptions().pathfinder == "classic") and true) or false)

local function GetMass(health, cost)
	return (((cost/2) + (health/8))^0.6)*6.5
end

GG.att_LastChangeFrame = {}
GG.att_CostMult = {}
GG.att_HealthMult = {}
GG.att_EconomyChange = {}
GG.att_ReloadChange = {}
GG.att_MoveChange = {}
GG.att_RangeChange = {}
GG.att_JumpRangeChange = {}
GG.att_DeathExplodeMult = {}
GG.att_ProjSpeed = {}
GG.att_ProjMult = {}
GG.att_DamageMult = {}
GG.att_RegenChange = {}
GG.att_ShieldRegenChange = {}
GG.att_ShieldMaxMult = {}
GG.att_StaticBuildRateMult = {}
GG.attRaw_BuildSpeed = {} -- A build speed value rather than a multiplier

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- UnitDefs caching

local shieldWeaponDef = {}
local buildSpeedDef = {}

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.shieldWeaponDef then
		shieldWeaponDef[i] = true
	end
	if (ud.buildSpeed or 0) ~= 0 then
		buildSpeedDef[i] = ud.buildSpeed
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Sensor Handling

local origUnitSight = {}
local radarUnitDef = {}
local sonarUnitDef = {}
local jammerUnitDef = {}

local function UpdateSensorAndJamm(unitID, unitDefID, multiplier, enabled, radarOverride, sonarOverride, jammerOverride, sightOverride)
	if not origUnitSight[unitDefID] then
		local ud = UnitDefs[unitDefID]
		origUnitSight[unitDefID] = ud.sightDistance
		if ud.radarDistance > 0 then
			radarUnitDef[unitDefID] = ud.radarDistance
		end
		if ud.sonarDistance > 0 and tobool(ud.customParams.sonar_can_be_disabled) then
			sonarUnitDef[unitDefID] = ud.sonarDistance
		end
		if ud.radarDistanceJam > 0 then
			jammerUnitDef[unitDefID] = ud.radarDistanceJam
		end
	end
	local orig = origUnitSight[unitDefID]
	local abilityMult = (enabled and 1) or 0
	
	if radarUnitDef[unitDefID] or radarOverride then
		Spring.SetUnitSensorRadius(unitID, "radar", abilityMult*(radarOverride or radarUnitDef[unitDefID])*multiplier)
	end
	if sonarUnitDef[unitDefID] or sonarOverride then
		Spring.SetUnitSensorRadius(unitID, "sonar", abilityMult*(sonarOverride or sonarUnitDef[unitDefID])*multiplier)
	end
	if jammerUnitDef[unitDefID] or jammerOverride then
		Spring.SetUnitSensorRadius(unitID, "radarJammer", abilityMult*(jammerOverride or jammerUnitDef[unitDefID])*multiplier)
	end
	Spring.SetUnitSensorRadius(unitID, "los", (sightOverride or origUnitSight[unitDefID])*multiplier)
	Spring.SetUnitSensorRadius(unitID, "airLos", (sightOverride or origUnitSight[unitDefID])*multiplier)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Build Speed Handling

local REPAIR_ENERGY_COST_FACTOR = Game.repairEnergyCostFactor

local function UpdateBuildSpeed(unitID, unitDefID, speedFactor)
	local buildSpeed = (buildSpeedDef[unitDefID] or 0)
	if buildSpeed == 0 then
		return
	end
	GG.attRaw_BuildSpeed[unitID] = buildSpeed*speedFactor
	spSetUnitBuildSpeed(unitID,
		buildSpeed*speedFactor, -- build
		buildSpeed*speedFactor / REPAIR_ENERGY_COST_FACTOR, -- repair
		buildSpeed*speedFactor, -- reclaim
		0.5*buildSpeed*speedFactor) -- rezz
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Economy Handling

local function UpdateEconomy(unitID, unitDefID, factor, energyFactor)
	spSetUnitRulesParam(unitID,"metalGenerationFactor", factor, INLOS_ACCESS)
	spSetUnitRulesParam(unitID,"energyGenerationFactor", factor*energyFactor, INLOS_ACCESS)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Health Cost and Mass Handling

local origUnitHealth = {}
local origUnitCost = {}

local function UpdateHealthCostMass(unitID, unitDefID, healthAdd, healthMult, costMult, massMult)
	if not origUnitHealth[unitDefID] then
		local ud = UnitDefs[unitDefID]
		origUnitHealth[unitDefID] = ud.health
	end
	if not origUnitCost[unitDefID] then
		local ud = UnitDefs[unitDefID]
		origUnitCost[unitDefID] = ud.buildTime
	end
	local newMaxHealth = (origUnitHealth[unitDefID] + healthAdd) * healthMult
	local oldHealth, oldMaxHealth = Spring.GetUnitHealth(unitID)
	Spring.SetUnitMaxHealth(unitID, newMaxHealth)
	Spring.SetUnitHealth(unitID, oldHealth * newMaxHealth / oldMaxHealth)
	
	local origCost = origUnitCost[unitDefID]
	local cost = origCost*costMult
	Spring.SetUnitCosts(unitID, {
		metalCost = cost,
		energyCost = cost,
		buildTime = cost,
	})
	
	if massMult == 1 then
		-- Default to update mass based on new stats, if a multiplier is not set.
		local mass = GetMass(newMaxHealth, cost)
		Spring.SetUnitMass(unitID, mass)
		Spring.SetUnitRulesParam(unitID, "massOverride", mass, INLOS_ACCESS)
	else
		local mass = GetMass(origUnitHealth[unitDefID], origCost) * massMult
		Spring.SetUnitMass(unitID, mass)
		Spring.SetUnitRulesParam(unitID, "massOverride", mass, INLOS_ACCESS)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Reload Time Handling

local origUnitWeapons = {}
local unitReloadPaused = {}

local function UpdatePausedReload(unitID, unitDefID, gameFrame)
	local state = origUnitWeapons[unitDefID]
	
	for i = 1, state.weaponCount do
		local w = state.weapon[i]
		local reloadState = spGetUnitWeaponState(unitID, i , 'reloadState')
		if reloadState then
			local reloadTime  = spGetUnitWeaponState(unitID, i , 'reloadTime')
			local newReload = 100000 -- set a high reload time so healthbars don't judder. NOTE: math.huge is TOO LARGE
			if reloadState < 0 then -- unit is already reloaded, so set unit to almost reloaded
				spSetUnitWeaponState(unitID, i, {reloadTime = newReload, reloadState = gameFrame+UPDATE_PERIOD+1})
			else
				local nextReload = gameFrame+(reloadState-gameFrame)*newReload/reloadTime
				spSetUnitWeaponState(unitID, i, {reloadTime = newReload, reloadState = nextReload+UPDATE_PERIOD})
			end
		end
	end
end

local function UpdateWeapons(unitID, unitDefID, weaponMods, speedFactor, rangeFactor, projSpeedFactor, projectilesFactor, damageFactor, minSpray, gameFrame)
	if not origUnitWeapons[unitDefID] then
		local ud = UnitDefs[unitDefID]
	
		origUnitWeapons[unitDefID] = {
			weapon = {},
			weaponCount = #ud.weapons,
			maxWeaponRange = ud.maxWeaponRange,
		}
		local state = origUnitWeapons[unitDefID]
		
		for i = 1, state.weaponCount do
			local wd = WeaponDefs[ud.weapons[i].weaponDef]
			local reload = wd.reload
			state.weapon[i] = {
				reload = reload,
				burstRate = wd.salvoDelay,
				projectiles = wd.projectiles,
				oldReloadFrames = floor(reload*Game.gameSpeed),
				range = wd.range,
				sprayAngle = wd.sprayAngle,
				damages = GG.ATT_ENABLE_DAMAGE and {},
			}
			if GG.ATT_ENABLE_DAMAGE then
				local did = 0
				local data = state.weapon[i].damages
				while wd.damages[did] do
					data[did] = wd.damages[did]
					did = did + 1
				end
			end
			
			if wd.type == "LaserCannon" or wd.type == "Cannon" then
				-- Barely works for missiles, and might break their burnblow and prediction
				state.weapon[i].projectileSpeed = wd.projectilespeed
			end
			if wd.type == "BeamLaser" then
				-- beamlasers go screwy if you mess with their burst length
				state.weapon[i].burstRate = false
			end
		end
	end
	if damageFactor ~= 1 and not GG.ATT_ENABLE_DAMAGE then
		Spring.Utilities.UnitEcho(unitID, "damage attribute requires GG.ATT_ENABLE_DAMAGE")
	end
	
	local state = origUnitWeapons[unitDefID]
	local maxRangeModified = state.maxWeaponRange*rangeFactor

	for i = 1, state.weaponCount do
		local w = state.weapon[i]
		local reloadState = spGetUnitWeaponState(unitID, i , 'reloadState')
		local reloadTime  = spGetUnitWeaponState(unitID, i , 'reloadTime')
		local moddedSpeed = ((weaponMods and weaponMods[i] and weaponMods[i].reloadMult) or 1)*speedFactor
		if moddedSpeed <= 0 then
			if not unitReloadPaused[unitID] then
				local newReload = 100000 -- set a high reload time so healthbars don't judder. NOTE: math.huge is TOO LARGE
				unitReloadPaused[unitID] = unitDefID
				spSetUnitRulesParam(unitID, "reloadPaused", 1, INLOS_ACCESS)
				if reloadState < gameFrame then -- unit is already reloaded, so set unit to almost reloaded
					spSetUnitWeaponState(unitID, i, {reloadTime = newReload, reloadState = gameFrame+UPDATE_PERIOD+1})
				else
					local nextReload = gameFrame+(reloadState-gameFrame)*newReload/reloadTime
					spSetUnitWeaponState(unitID, i, {reloadTime = newReload, reloadState = nextReload+UPDATE_PERIOD})
				end
				-- add UPDATE_PERIOD so that the reload time never advances past what it is now
			end
		else
			if unitReloadPaused[unitID] then
				unitReloadPaused[unitID] = nil
				spSetUnitRulesParam(unitID, "reloadPaused", 0, INLOS_ACCESS)
			end
			local newReload = w.reload/moddedSpeed
			local nextReload = gameFrame+(reloadState-gameFrame)*newReload/reloadTime
			-- Add HALF_FRAME to round reloadTime to the closest discrete frame (multiple of 1/30), since the the engine rounds DOWN
			if w.burstRate then
				spSetUnitWeaponState(unitID, i, {reloadTime = newReload + HALF_FRAME, reloadState = nextReload + 0.5, burstRate = w.burstRate/moddedSpeed + HALF_FRAME})
			else
				spSetUnitWeaponState(unitID, i, {reloadTime = newReload + HALF_FRAME, reloadState = nextReload + 0.5})
			end
		end
		local moddedRange = w.range*((weaponMods and weaponMods[i] and weaponMods[i].rangeMult) or 1)*rangeFactor
		local moddedProjectiles = w.projectiles*((weaponMods and weaponMods[i] and weaponMods[i].projectilesMult) or 1)*projectilesFactor
		
		local sprayAngle = math.max(w.sprayAngle, minSpray)
		spSetUnitWeaponState(unitID, i, "sprayAngle", sprayAngle)
		
		if w.projectileSpeed then
			local moddedSpeed = w.projectileSpeed*((weaponMods and weaponMods[i] and weaponMods[i].projSpeedMult) or 1)*projSpeedFactor
			spSetUnitWeaponState(unitID, i, "projectileSpeed", moddedSpeed)
		end
		
		spSetUnitWeaponState(unitID, i, "projectiles", moddedProjectiles)
		spSetUnitWeaponState(unitID, i, "range", moddedRange)
		spSetUnitWeaponDamages(unitID, i, "dynDamageRange", moddedRange)
		if maxRangeModified < moddedRange then
			maxRangeModified = moddedRange
		end
		if GG.ATT_ENABLE_DAMAGE then
			local did = 0
			local data = state.weapon[i].damages
			local toSet = {}
			while data[did] do
				toSet[did] = data[did] * damageFactor
				did = did + 1
			end
			spSetUnitWeaponDamages(unitID, i, toSet)
		end
	end
	
	Spring.SetUnitMaxRange(unitID, maxRangeModified)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Movement Speed Handling

local origUnitSpeed = {}

local function UpdateMovementSpeed(unitID, unitDefID, speedFactor, turnAccelFactor, maxAccelerationFactor)
	if spMoveCtrlGetTag(unitID) ~= nil then
		return
	end
	
	if not origUnitSpeed[unitDefID] then
		local ud = UnitDefs[unitDefID]
		local moveData = spGetUnitMoveTypeData(unitID)

		origUnitSpeed[unitDefID] = {
			origSpeed = ud.speed,
			origReverseSpeed = (moveData.name == "ground") and moveData.maxReverseSpeed or ud.speed,
			origTurnRate = ud.turnRate,
			origTurnAccel = (ud.turnRate or 1) * (ud.customParams.turn_accel_factor or 1),
			origMaxRudder = ud.maxRudder,
			origMaxAcc = ud.maxAcc,
			origMaxDec = ud.maxDec,
			movetype = -1,
		}
		
		local state = origUnitSpeed[unitDefID]
		state.movetype = getMovetype(ud)
	end
	
	local state = origUnitSpeed[unitDefID]
	local decFactor = maxAccelerationFactor
	local isSlowed = (speedFactor < 1)
	if isSlowed then
		-- increase brake rate to cause units to slow down to their new max speed correctly.
		decFactor = 1000
	end
	if speedFactor <= 0 then
		speedFactor = 0
		
		-- Set the units velocity to zero if it is attached to the ground.
		local x, y, z = Spring.GetUnitPosition(unitID)
		if x then
			local h = Spring.GetGroundHeight(x, z)
			if h and h >= y then
				Spring.SetUnitVelocity(unitID, 0,0,0)
				
				-- Perhaps attributes should do this:
				--local env = Spring.UnitScript.GetScriptEnv(unitID)
				--if env and env.script.StopMoving then
				--	Spring.UnitScript.CallAsUnit(unitID,env.script.StopMoving, hx, hy, hz)
				--end
			end
		end
	end
	if turnAccelFactor <= 0 then
		turnAccelFactor = 0
	end
	local turnFactor = turnAccelFactor
	if turnFactor <= 0.001 then
		turnFactor = 0.001
	end
	if maxAccelerationFactor <= 0 then
		maxAccelerationFactor = 0.001
	end
	
	if state.movetype == 0 then
		if speedFactor > 0 then
			-- Only modify turning that goes beyond the turn factor that units get alongside
			-- speed factor. This makes sense as planes turn via speed already.
			turnFactor = turnFactor / speedFactor
		else
			turnFactor = 1
		end
		local attribute = {
			maxSpeed        = state.origSpeed       *speedFactor,
			maxAcc          = state.origMaxAcc      *maxAccelerationFactor, --(speedFactor > 0.001 and speedFactor or 0.001)
			maxRudder       = state.origMaxRudder   *turnFactor,
		}
		spSetAirMoveTypeData (unitID, attribute)
		spSetAirMoveTypeData (unitID, attribute)
	elseif state.movetype == 1 then
		local attribute =  {
			maxSpeed        = state.origSpeed       *speedFactor,
			--maxReverseSpeed = state.origReverseSpeed*speedFactor,
			turnRate        = state.origTurnRate    *turnFactor,
			accRate         = state.origMaxAcc      *maxAccelerationFactor,
			decRate         = state.origMaxDec      *maxAccelerationFactor
		}
		spSetGunshipMoveTypeData (unitID, attribute)
		GG.ForceUpdateWantedMaxSpeed(unitID, unitDefID)
	elseif state.movetype == 2 then
		if workingGroundMoveType then
			local accRate = state.origMaxAcc*maxAccelerationFactor
			if isSlowed and accRate > speedFactor then
				-- Clamp acceleration to mitigate prevent brief speedup when executing new order
				-- 1 is here as an arbitary factor, there is no nice conversion which means that 1 is a good value.
				accRate = speedFactor
			end
			local attribute =  {
				maxSpeed        = state.origSpeed       *speedFactor,
				maxReverseSpeed = (isSlowed and 0) or state.origReverseSpeed, --disallow reverse while slowed
				turnRate        = state.origTurnRate    *turnFactor,
				accRate         = accRate,
				decRate         = state.origMaxDec      *decFactor,
				turnAccel       = state.origTurnAccel    *turnAccelFactor,
			}
			spSetGroundMoveTypeData (unitID, attribute)
			GG.ForceUpdateWantedMaxSpeed(unitID, unitDefID)
		else
			--Spring.Echo(state.origSpeed*speedFactor*WACKY_CONVERSION_FACTOR_1)
			--Spring.Echo(Spring.GetUnitCOBValue(unitID, COB.MAX_SPEED))
			spSetUnitCOBValue(unitID, COB.MAX_SPEED, math.ceil(state.origSpeed*speedFactor*WACKY_CONVERSION_FACTOR_1))
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Death Explosion Handling

local explosionDefID = {}
local explosionRadius = {}
local function AddExplosions(unitID, unitDefID, teamID, expMult)
	if expMult <= 1 then -- Unsupported
		return
	end
	local extraExplosions = math.max(1, math.floor(expMult - 0.5))
	local explosionDamageMult = extraExplosions / (expMult - 1)
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
	local expLevel = 1 + math.log(expMult) / math.log(2)
	local radius = (5 + 15*expLevel)*(50 + math.pow(explosionRadius[unitDefID], 0.8))/100
	for i = 1, extraExplosions do
		local rand = Vector.RandomPointInCircle(radius)
		projectileParams.pos[1] = ux + rand[1]
		projectileParams.pos[3] = uz + rand[2]
		local proID = Spring.SpawnProjectile(explosionDefID[unitDefID], projectileParams)
		-- TODO: Handle explosionDamageMult ~= 1 with SetProjectileDamages
		if proID then
			Spring.SetProjectileCollision(proID)
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Attribute Updating

local attributesTypes = IterableMap.New()
local unitSlowed = {}
local unitHasAttributes = {}


-- Internal tracking to avoid unnecessary updates
local currentHealthAdd = {}
local currentHealthMult = {}
local currentMove = {}
local currentTurn = {}
local currentAccel = {}
local currentReload = {}
local currentRange = {}
local currentProjSpeed = {}
local currentEcon = {}
local currentMass = {}
local currentEnergy = {}
local currentBuildpower = {}
local currentCost = {}
local currentProjectiles = {}
local currentDamage = {}
local currentMinSpray = {}
local currentShieldDisabled = {}
local currentAbilityDisabled = {}

local currentSense = {}
local currentSetRadar = {}
local currentSetSonar = {}
local currentSetJammer = {}
local currentSetSight = {}

local function CleanupAttributeDataForUnit(unitID)
	unitHasAttributes[unitID] = nil
	unitReloadPaused[unitID] = nil -- defined earlier
	
	currentHealthAdd[unitID] = nil
	currentHealthMult[unitID] = nil
	currentMove[unitID] = nil
	currentTurn[unitID] = nil
	currentAccel[unitID] = nil
	currentReload[unitID] = nil
	currentRange[unitID] = nil
	currentProjSpeed[unitID] = nil
	currentEcon[unitID] = nil
	currentMass[unitID] = nil
	currentEnergy[unitID] = nil
	currentBuildpower[unitID] = nil
	currentCost[unitID] = nil
	currentProjectiles[unitID] = nil
	currentDamage[unitID] = nil
	currentMinSpray[unitID] = nil
	currentShieldDisabled[unitID] = nil
	currentAbilityDisabled[unitID] = nil
	
	currentSense[unitID] = nil
	currentSetRadar[unitID] = nil
	currentSetSonar[unitID] = nil
	currentSetJammer[unitID] = nil
	currentSetSight[unitID] = nil
	
	GG.att_LastChangeFrame[unitID] = nil
	GG.att_CostMult[unitID] = nil
	GG.att_HealthMult[unitID] = nil
	GG.att_EconomyChange[unitID] = nil
	GG.att_ReloadChange[unitID] = nil
	GG.att_MoveChange[unitID] = nil
	GG.att_RangeChange[unitID] = nil
	GG.att_JumpRangeChange[unitID] = nil
	GG.att_DeathExplodeMult[unitID] = nil
	GG.att_ProjSpeed[unitID] = nil
	GG.att_ProjMult[unitID] = nil
	GG.att_DamageMult[unitID] = nil
	GG.att_RegenChange[unitID] = nil
	GG.att_ShieldRegenChange[unitID] = nil
	GG.att_StaticBuildRateMult[unitID] = nil
	GG.attRaw_BuildSpeed[unitID] = nil
end

local function UpdateUnitAttributes(unitID, attTypeMap)
	if not spValidUnitID(unitID) then
		return true
	end
	
	local unitDefID = spGetUnitDefID(unitID)
	if not unitDefID then
		return true
	end
	
	local frame = spGetGameFrame()
	GG.att_LastChangeFrame[unitID] = frame
	
	local healthAdd = 0
	local healthMult = 1
	local moveMult = 1
	local turnMult = 1
	local accelMult = 1
	local reloadMult = 1
	local rangeMult = 1
	local jumpRangeMult = 1
	local deathExplodeMult = 1
	local projSpeedMult = 1
	local econMult = 1
	local massMult = 1
	local energyMult = 1
	local shieldRegen = 1
	local shieldMaxMult = 1
	local healthRegen = 1
	local costMult = 1
	local buildMult = 1
	local senseMult = 1
	local projectilesMult = 1
	local damageMult = 1
	local minSpray = 0
	local abilityDisabled = false
	local shieldDisabled = false
	local weaponSpecificMods = false
	local setRadar = false
	local setSonar = false
	local setJammer = false
	local setSight = false
	
	local staticBuildpowerMult = 1
	local staticMetalMult = 1
	local staticEnergyMult = 1
	local staticShieldRegen = 1
	local staticHealthRegen = 1
	local staticMoveMult = 1
	
	local hasAttributes = false
	for _, data in IterableMap.Iterator(attTypeMap) do
		if data.includedUnits[unitID] then
			hasAttributes = true
			
			healthAdd = healthAdd + (data.healthAdd and data.healthAdd[unitID] or 0)
			healthMult = healthMult*(data.healthMult and data.healthMult[unitID] or 1)
			healthRegen = healthRegen*(data.healthRegen and data.healthRegen[unitID] or 1)
			costMult = costMult*(data.cost and data.cost[unitID] or 1)
			massMult = massMult*(data.mass and data.mass[unitID] or 1)
			
			moveMult = moveMult*(data.move and data.move[unitID] or 1)
			turnMult = turnMult*(data.turn and data.turn[unitID] or (data.move and data.move[unitID]) or 1)
			accelMult = accelMult*(data.accel and data.accel[unitID] or (data.move and data.move[unitID]) or 1)
			jumpRangeMult = jumpRangeMult*(data.jumpRange and data.jumpRange[unitID] or 1)
			deathExplodeMult = deathExplodeMult*(data.deathExplode and data.deathExplode[unitID] or 1)
			
			shieldRegen = shieldRegen*(data.shieldRegen and data.shieldRegen[unitID] or 1)
			shieldMaxMult = shieldMaxMult*(data.shieldMax and data.shieldMax[unitID] or 1)
			
			energyMult = energyMult*(data.energy and data.energy[unitID] or 1)
			econMult = econMult*(data.econ and data.econ[unitID] or 1)
			buildMult = buildMult*(data.build and data.build[unitID] or 1)
			
			abilityDisabled = abilityDisabled or data.abilityDisabled and data.abilityDisabled[unitID]
			shieldDisabled = shieldDisabled or data.shieldDisabled and data.shieldDisabled[unitID]
			minSpray = math.max(minSpray, data.minSpray and data.minSpray[unitID] or 0)
			senseMult = senseMult*(data.sense and data.sense[unitID] or 1)
			setRadar = data.setRadar and data.setRadar[unitID] or setRadar
			setJammer = data.setJammer and data.setJammer[unitID] or setJammer
			setSonar = data.setSonar and data.setSonar[unitID] or setSonar
			setSight = data.setSight and data.setSight[unitID] or setSight
			
			if data.static then
				staticBuildpowerMult = staticBuildpowerMult*(data.build and data.build[unitID] or 1)
				staticMetalMult = staticMetalMult*(data.econ and data.econ[unitID] or 1)
				staticEnergyMult = staticEnergyMult*(data.econ and data.econ[unitID] or 1)*(data.energy and data.energy[unitID] or 1)
				staticShieldRegen = staticShieldRegen*(data.shieldRegen and data.shieldRegen[unitID] or 1)
				staticHealthRegen = staticHealthRegen*(data.healthRegen and data.healthRegen[unitID] or 1)
				staticMoveMult = staticMoveMult*(data.move and data.move[unitID] or 1)
			end
			
			if data.weaponNum and data.weaponNum[unitID] then
				local weaponNum = data.weaponNum[unitID]
				weaponSpecificMods = weaponSpecificMods or {}
				weaponSpecificMods[weaponNum] = weaponSpecificMods[weaponNum] or {
					reloadMult = 1,
					rangeMult = 1,
					projSpeedMult = 1,
					projectilesMult = 1,
					damageMult = 1,
				}
				local wepData = weaponSpecificMods[weaponNum]
				wepData.reloadMult = wepData.reloadMult*(data.reload and data.reload[unitID] or 1)
				wepData.rangeMult = wepData.rangeMult*(data.range and data.range[unitID] or 1)
				wepData.projSpeedMult = wepData.projSpeedMult*(data.projSpeed and data.projSpeed[unitID] or 1)
				wepData.projectilesMult = wepData.projectilesMult*(data.projectiles and data.projectiles[unitID] or 1)
				wepData.damageMult = wepData.damageMult*(data.damage and data.damage[unitID] or 1)
			else
				reloadMult = reloadMult*(data.reload and data.reload[unitID] or 1)
				rangeMult = rangeMult*(data.range and data.range[unitID] or 1)
				projSpeedMult = projSpeedMult*(data.projSpeed and data.projSpeed[unitID] or 1)
				projectilesMult = projectilesMult*(data.projectiles and data.projectiles[unitID] or 1)
				damageMult = damageMult*(data.damage and data.damage[unitID] or 1)
			end
		end
	end
	
	spSetUnitRulesParam(unitID, "totalReloadSpeedChange", reloadMult, INLOS_ACCESS)
	spSetUnitRulesParam(unitID, "totalEconomyChange", econMult, INLOS_ACCESS)
	spSetUnitRulesParam(unitID, "totalBuildPowerChange", buildMult, INLOS_ACCESS)
	spSetUnitRulesParam(unitID, "totalMoveSpeedChange", moveMult, INLOS_ACCESS)
	spSetUnitRulesParam(unitID, "costMult", costMult, INLOS_ACCESS)
	spSetUnitRulesParam(unitID, "projectilesMult", projectilesMult, INLOS_ACCESS)
	spSetUnitRulesParam(unitID, "projectileSpeedMult", projSpeedMult, INLOS_ACCESS)
	spSetUnitRulesParam(unitID, "damageMult", damageMult, INLOS_ACCESS)
	spSetUnitRulesParam(unitID, "rangeMult", rangeMult, INLOS_ACCESS)
	spSetUnitRulesParam(unitID, "senseMult", senseMult, INLOS_ACCESS)
	spSetUnitRulesParam(unitID, "jumpRangeMult", jumpRangeMult, INLOS_ACCESS)
	spSetUnitRulesParam(unitID, "deathExplodeMult", deathExplodeMult, INLOS_ACCESS)
	
	spSetUnitRulesParam(unitID, "totalStaticBuildpowerMult", staticBuildpowerMult, INLOS_ACCESS)
	spSetUnitRulesParam(unitID, "totalStaticMetalMult", staticMetalMult, INLOS_ACCESS)
	spSetUnitRulesParam(unitID, "totalStaticEnergyMult", staticEnergyMult, INLOS_ACCESS)
	spSetUnitRulesParam(unitID, "totalShieldMaxMult", shieldMaxMult, INLOS_ACCESS)
	
	spSetUnitRulesParam(unitID, "totalStaticShieldRegen", staticShieldRegen, INLOS_ACCESS)
	spSetUnitRulesParam(unitID, "totalStaticHealthRegen", staticHealthRegen, INLOS_ACCESS)
	spSetUnitRulesParam(unitID, "totalStaticMoveSpeedChange", staticMoveMult, INLOS_ACCESS)
	
	-- GG is faster (but gadget-only).
	GG.att_CostMult[unitID] = costMult
	GG.att_HealthMult[unitID] = healthMult
	GG.att_EconomyChange[unitID] = econMult
	GG.att_ReloadChange[unitID] = reloadMult
	GG.att_MoveChange[unitID] = moveMult
	GG.att_RangeChange[unitID] = rangeMult
	GG.att_JumpRangeChange[unitID] = jumpRangeMult
	GG.att_DeathExplodeMult[unitID] = deathExplodeMult
	GG.att_RegenChange[unitID] = healthRegen
	GG.att_ShieldRegenChange[unitID] = shieldRegen
	GG.att_ShieldMaxMult[unitID] = shieldMaxMult
	GG.att_StaticBuildRateMult[unitID] = staticBuildpowerMult
	GG.att_ProjSpeed[unitID] = projSpeedMult -- Ignores weapon mods
	GG.att_ProjMult[unitID] = projectilesMult
	GG.att_DamageMult[unitID] = damageMult
	
	unitSlowed[unitID] = moveMult < 1
	
	local healthChanges = (currentHealthAdd[unitID] or 0) ~= healthAdd
		or (currentHealthMult[unitID] or 1) ~= healthMult
	
	local weaponChanges = (currentReload[unitID] or 1) ~= reloadMult
		or (currentRange[unitID] or 1) ~= rangeMult
		or (currentProjectiles[unitID] or 1) ~= projectilesMult
		or (currentDamage[unitID] or 1) ~= damageMult
		or (currentMinSpray[unitID] or 0) ~= minSpray
	
	local moveChanges = (currentMove[unitID] or 1) ~= moveMult
		or (currentTurn[unitID] or 1) ~= turnMult
		or (currentAccel[unitID] or 1) ~= accelMult
	
	local senseChanges = (currentSense[unitID] ~= senseMult)
		or (abilityDisabled ~= currentAbilityDisabled[unitID])
		or (setRadar ~= (currentSetRadar[unitID] or false))
		or (setSonar ~= (currentSetSonar[unitID] or false))
		or (setJammer ~= (currentSetJammer[unitID] or false))
		or (setSight ~= (currentSetSight[unitID] or false))
	
	local actualMassMult = 1
	if healthChanges or (currentCost[unitID] or 1) ~= costMult or (currentMass[unitID] or 1) ~= massMult then
		actualMassMult = UpdateHealthCostMass(unitID, unitDefID, healthAdd, healthMult, costMult, massMult)
		currentHealthAdd[unitID] = healthAdd
		currentHealthMult[unitID] = healthMult
		currentCost[unitID] = costMult
		currentMass[unitID] = massMult
	end
	
	if moveChanges then
		UpdateMovementSpeed(unitID, unitDefID, moveMult, turnMult, accelMult)
		currentMove[unitID] = moveMult
		currentTurn[unitID] = turnMult
		currentAccel[unitID] = accelMult
	end
	
	if weaponSpecificMods or weaponChanges then
		UpdateWeapons(unitID, unitDefID, weaponSpecificMods, reloadMult, rangeMult, projSpeedMult, projectilesMult, damageMult, minSpray, frame)
		currentReload[unitID] = reloadMult
		currentRange[unitID] = rangeMult
		currentProjSpeed[unitID] = projSpeedMult
		currentProjectiles[unitID] = projectilesMult
		currentDamage[unitID] = damageMult
		currentMinSpray[unitID] = minSpray
	end
	
	if buildMult ~= currentBuildpower[unitID] then
		UpdateBuildSpeed(unitID, unitDefID, buildMult)
		currentBuildpower[unitID] = buildMult
	end
	
	if econMult ~= currentEcon[unitID] then
		UpdateEconomy(unitID, unitDefID, econMult, energyMult)
		currentEcon[unitID] = econMult
	end
	
	if abilityDisabled ~= currentAbilityDisabled[unitID] then
		spSetUnitRulesParam(unitID, "att_abilityDisabled", abilityDisabled and 1 or 0)
		currentAbilityDisabled[unitID] = abilityDisabled
	end
	
	if shieldDisabled ~= currentShieldDisabled[unitID] then
		spSetUnitRulesParam(unitID, "att_shieldDisabled", shieldDisabled and 1 or 0)
		if shieldDisabled then
			Spring.SetUnitShieldState(unitID, -1, 0)
		end
		if spGetUnitRulesParam(unitID, "comm_shield_max") ~= 0 then
			if shieldDisabled then
				Spring.SetUnitShieldState(unitID, spGetUnitRulesParam(unitID, "comm_shield_num") or -1, false)
			else
				Spring.SetUnitShieldState(unitID, spGetUnitRulesParam(unitID, "comm_shield_num") or -1, true)
			end
		end
		currentShieldDisabled[unitID] = shieldDisabled
	end
	
	if senseChanges then
		UpdateSensorAndJamm(unitID, unitDefID, senseMult, not abilityDisabled, setRadar, setSonar, setJammer, setSight)
		currentSense[unitID] = senseMult
		currentSetRadar[unitID] = setRadar
		currentSetSonar[unitID] = setSonar
		currentSetJammer[unitID] = setJammer
		currentSetSight[unitID] = setSight
	end
	
	if not hasAttributes then
		CleanupAttributeDataForUnit(unitID)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Gadgets can send these to Attributes.AddEffect
local attributeNames = {
	"healthAdd",
	"healthMult",
	"healthRegen",
	"move",
	"turn",
	"accel",
	"reload",
	"range",
	"jumpRange",
	"deathExplode",
	"projSpeed",
	"econ",
	"energy",
	"shieldMax",
	"shieldRegen",
	"cost",
	"mass",
	"build",
	"sense",
	"setRadar",
	"setSonar",
	"setJammer",
	"setSight",
	"projectiles",
	"damage", -- Enabled by setting GG.ATT_ENABLE_DAMAGE = true
	"weaponNum",
	"minSpray",
	"abilityDisabled",
	"shieldDisabled",
	
	-- Whether the attribute change is intended to ba baked into the unit, or temporary.
	-- This helps the UI display stats, and helps things like morph work correctly.
	"static",
}

local function InitAttributeType()
	local attType = {
		includedUnits = {},
	}
	return attType
end

local function AddToAttributeType(attType, unitID, effectTable, attName)
	if not effectTable[attName] and not attType[attName] then
		return false
	end
	if not attType[attName] then
		attType[attName] = {}
	end
	attType[attName][unitID] = effectTable[attName]
end

local function RemoveUnitFromAttributeType(attType, unitID)
	if not attType.includedUnits[unitID] then
		return
	end
	attType.includedUnits[unitID] = nil
	for i = 1, #attributeNames do
		if attType[attName] and attType[attName][unitID] ~= nil then
			attType[attName][unitID] = nil
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Interface

local Attributes = {}
function Attributes.RemoveUnit(unitID)
	if not unitHasAttributes[unitID] then
		return
	end
	CleanupAttributeDataForUnit(unitID)
	for _, attType in IterableMap.Iterator(attributesTypes) do
		RemoveUnitFromAttributeType(attType, unitID)
	end
end

function Attributes.AddEffect(unitID, key, effect)
	-- See attributeNames above for value effect keys
	local attType = IterableMap.Get(attributesTypes, key)
	if not attType then
		attType = InitAttributeType()
	end
	
	unitHasAttributes[unitID] = true
	attType.includedUnits[unitID] = true
	for i = 1, #attributeNames do
		AddToAttributeType(attType, unitID, effect, attributeNames[i])
	end
	
	IterableMap.Add(attributesTypes, key, attType) -- Overwrites existing key if it exists
	if UpdateUnitAttributes(unitID, attributesTypes) then
		Attributes.RemoveUnit(unitID)
	end
end

function Attributes.RemoveEffect(unitID, key)
	if not unitHasAttributes[unitID] then
		return
	end
	local attType = IterableMap.Get(attributesTypes, key)
	if attType then
		RemoveUnitFromAttributeType(attType, unitID)
	end
	if UpdateUnitAttributes(unitID, attributesTypes) then
		Attributes.RemoveUnit(unitID)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Updates and tweaks


function gadget:Initialize()
	GG.Attributes = Attributes
end

function gadget:GameFrame(f)
	if f % UPDATE_PERIOD == 1 then
		for unitID, unitDefID in pairs(unitReloadPaused) do
			UpdatePausedReload(unitID, unitDefID, f)
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	if (GG.att_DeathExplodeMult[unitID] or 1) ~= 1 then
		AddExplosions(unitID, unitDefID, teamID, GG.att_DeathExplodeMult[unitID])
	end
	Attributes.RemoveUnit(unitID)
end

function gadget:AllowCommand_GetWantedCommand()
	return true
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID == 70 and unitSlowed[unitID]) then
		return false
	else
		return true
	end
end