function gadget:GetInfo()
  return {
    name      = "Commander Upgrade",
    desc      = "",
    author    = "Google Frog",
    date      = "30 December 2015",
    license   = "GNU GPL, v2 or later",
    layer     = 1,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--SYNCED
if (not gadgetHandler:IsSyncedCode()) then
   return
end

include("LuaRules/Configs/constants.lua")

local INLOS = {inlos = true}
local interallyCreatedUnit = false
local internalCreationUpgradeDef
local internalCreationModuleEffectData

local unitCreatedShield, unitCreatedShieldNum, unitCreatedCloak, unitCreatedJammingRange, unitCreatedCloakShield, unitCreatedWeaponNums

local moduleDefs, chassisDefs, upgradeUtilities, LEVEL_BOUND, chassisDefByBaseDef, moduleDefNames, chassisDefNames =  include("LuaRules/Configs/dynamic_comm_defs.lua")
	
include("LuaRules/Configs/customcmds.h.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Various module configs

local commanderCloakShieldDef = {
	draw = true,
	init = true,
	level = 2,
	delay = 30,
	energy = 15,
	minrad = 64,
	maxrad = 350,
	
	growRate = 512,
	shrinkRate = 2048,
	selfCloak = true,
	decloakDistance = 75,
	isTransport = false,
	
	radiusException = {}
}

local COMMANDER_JAMMING_COST = 1.5

for _, eud in pairs (UnitDefs) do
	if eud.decloakDistance < commanderCloakShieldDef.decloakDistance then
		commanderCloakShieldDef.radiusException[eud.id] = true
	end
end

local commAreaShield = WeaponDefNames["shieldshield_cor_shield_small"]

local commAreaShieldDefID = {
	maxCharge = commAreaShield.shieldPower,
	perUpdateCost = 2*tonumber(commAreaShield.customParams.shield_drain)/TEAM_SLOWUPDATE_RATE,
	chargePerUpdate = 2*tonumber(commAreaShield.customParams.shield_rate)/TEAM_SLOWUPDATE_RATE,
	perSecondCost = tonumber(commAreaShield.customParams.shield_drain)
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local moduleSlotTypeMap = {
	decoration = "decoration",
	module = "module",
	basic_weapon = "module",
	adv_weapon = "module",
}

local function SetUnitRulesModule(unitID, counts, moduleDefID)
	local slotType = moduleSlotTypeMap[moduleDefs[moduleDefID].slotType]
	counts[slotType] = counts[slotType] + 1
	Spring.SetUnitRulesParam(unitID, "comm_" .. slotType .. "_" .. counts[slotType], moduleDefID, INLOS)
end

local function SetUnitRulesModuleCounts(unitID, counts)
	for name, value in pairs(counts) do
		Spring.SetUnitRulesParam(unitID, "comm_" .. name .. "_count", value, INLOS)
	end
end

local function ApplyWeaponData(unitID, weapon1, weapon2, shield, rangeMult, damageMult)
	if (not weapon2) and weapon1 then
		local unitDefID = Spring.GetUnitDefID(unitID)
		local weaponName = "0_" .. weapon1
		local wd = WeaponDefNames[weaponName]
		if wd and wd.customParams and wd.customParams.manualfire then
			weapon2 = weapon1
			weapon1 = "commweapon_beamlaser"
		end
	end
	
	weapon1 = weapon1 or "commweapon_beamlaser"
	local chassis = Spring.GetUnitRulesParam(unitID, "comm_chassis")
	
	if chassis and chassisDefs[chassis] and chassisDefs[chassis].secondPeashooter and (not weapon2) and Spring.GetUnitRulesParam(unitID, "comm_level") > 2 then 
		weapon2 = "commweapon_beamlaser"
	end
	
	rangeMult = rangeMult or Spring.GetUnitRulesParam(unitID, "comm_range_mult") or 1
	Spring.SetUnitRulesParam(unitID, "comm_range_mult", rangeMult,  INLOS)
	damageMult = damageMult or Spring.GetUnitRulesParam(unitID, "comm_damage_mult") or 1
	Spring.SetUnitRulesParam(unitID, "comm_damage_mult", damageMult,  INLOS)
	
	local env = Spring.UnitScript.GetScriptEnv(unitID)
	Spring.UnitScript.CallAsUnit(unitID, env.dyncomm.UpdateWeapons, weapon1, weapon2, shield, rangeMult, damageMult)
end

local function ApplyModuleEffects(unitID, data, totalCost, images)
	-- Update ApplyModuleEffectsFromUnitRulesParams if any non-unitRulesParams changes are made.
	if data.speedMult then
		Spring.SetUnitRulesParam(unitID, "upgradesSpeedMult", data.speedMult, INLOS)
	end
	
	if data.radarRange then
		Spring.SetUnitRulesParam(unitID, "radarRangeOverride", data.radarRange, INLOS)
	end
	
	if data.radarJammingRange then
		Spring.SetUnitRulesParam(unitID, "jammingRangeOverride", data.radarJammingRange, INLOS)
		Spring.SetUnitRulesParam(unitID, "comm_jamming_cost", COMMANDER_JAMMING_COST, INLOS)
	else
		local onOffCmd = Spring.FindUnitCmdDesc(unitID, CMD.ONOFF)
		if onOffCmd then
			Spring.RemoveUnitCmdDesc(unitID, onOffCmd)
		end
	end
	
	if data.decloakDistance then
		Spring.SetUnitCloak(unitID, false, data.decloakDistance)
		Spring.SetUnitRulesParam(unitID, "comm_decloak_distance", data.decloakDistance, INLOS)
	end
	
	if data.personalCloak then
		Spring.SetUnitRulesParam(unitID, "comm_personal_cloak", 1, INLOS)
	end
	
	if data.areaCloak then
		Spring.SetUnitRulesParam(unitID, "comm_area_cloak", 1, INLOS)
		Spring.SetUnitRulesParam(unitID, "comm_area_cloak_upkeep", data.cloakFieldUpkeep, INLOS)
		Spring.SetUnitRulesParam(unitID, "comm_area_cloak_radius", data.cloakFieldRange, INLOS)
	end
	
	-- All comms have 10 BP in their unitDef (even support)
	local buildPower = (10 + (data.bonusBuildPower or 0)) * (data.buildPowerMult or 1)
	data.metalIncome = (data.metalIncome or 0)
	data.energyIncome = (data.energyIncome or 0)
	Spring.SetUnitRulesParam(unitID, "buildpower_mult", buildPower/10, INLOS)
	
	if data.metalIncome and GG.Overdrive then
		Spring.SetUnitRulesParam(unitID, "comm_income_metal", data.metalIncome, INLOS)
		Spring.SetUnitRulesParam(unitID, "comm_income_energy", data.energyIncome, INLOS)
		GG.Overdrive.AddUnitResourceGeneration(unitID, data.metalIncome, data.energyIncome, true)
	end
	
	if data.healthBonus then
		local health, maxHealth = Spring.GetUnitHealth(unitID)
		local newHealth = math.max(health + data.healthBonus, 1)
		local newMaxHealth = math.max(maxHealth + data.healthBonus, 1)
		Spring.SetUnitHealth(unitID, newHealth)
		Spring.SetUnitMaxHealth(unitID, newMaxHealth)
	end
	
	if data.skinOverride then
		Spring.SetUnitRulesParam(unitID, "comm_texture", data.skinOverride, INLOS)
	end
	
	if data.bannerOverhead then
		Spring.SetUnitRulesParam(unitID, "comm_banner_overhead", images.overhead or "fakeunit", INLOS)
	end
	
	if data.drones or data.droneheavyslows then
		if data.drones then
			Spring.SetUnitRulesParam(unitID, "carrier_count_drone", data.drones, INLOS)
		end
		if data.droneheavyslows then
			Spring.SetUnitRulesParam(unitID, "carrier_count_droneheavyslow", data.droneheavyslows, INLOS)
		end
		if GG.Drones_InitializeDynamicCarrier then
			GG.Drones_InitializeDynamicCarrier(unitID)
		end
	end
	
	if data.autorepairRate then
		Spring.SetUnitRulesParam(unitID, "comm_autorepair_rate", data.autorepairRate, INLOS)
		if GG.SetUnitIdleRegen then
			GG.SetUnitIdleRegen(unitID, 0, data.autorepairRate / 2)
		end
	end
	
	local _, maxHealth = Spring.GetUnitHealth(unitID)
	local effectiveMass = (((totalCost/2) + (maxHealth/8))^0.6)*6.5
	Spring.SetUnitRulesParam(unitID, "massOverride", effectiveMass, INLOS)
	
	ApplyWeaponData(unitID, data.weapon1, data.weapon2, data.shield, data.rangeMult, data.damageMult)
	
	-- Do this all the time as it will be needed almost always.
	GG.UpdateUnitAttributes(unitID)
end

local function ApplyModuleEffectsFromUnitRulesParams(unitID)
	if not Spring.GetUnitRulesParam(unitID, "jammingRangeOverride") then
		local onOffCmd = Spring.FindUnitCmdDesc(unitID, CMD.ONOFF)
		if onOffCmd then
			Spring.RemoveUnitCmdDesc(unitID, onOffCmd)
		end
	end
	
	local decloakDist = Spring.GetUnitRulesParam(unitID, "comm_decloak_distance")
	if decloakDist then
		Spring.SetUnitCloak(unitID, false, decloakDist)
	end
	
	if GG.Overdrive then
		local mInc = Spring.GetUnitRulesParam(unitID, "comm_income_metal")
		local eInc = Spring.GetUnitRulesParam(unitID, "comm_income_energy")
		GG.Overdrive.AddUnitResourceGeneration(unitID, mInc or 0, eInc or 0, true, true)
	end
	
	if Spring.GetUnitRulesParam(unitID, "carrier_count_drone") or Spring.GetUnitRulesParam(unitID, "carrier_count_droneheavyslow") then
		if GG.Drones_InitializeDynamicCarrier then
			GG.Drones_InitializeDynamicCarrier(unitID)
		end
	end
	
	local autoRegen = Spring.GetUnitRulesParam(unitID, "comm_autorepair_rate")
	if autoRegen and GG.SetUnitIdleRegen then
		GG.SetUnitIdleRegen(unitID, 0, autoRegen / 2)
	end
	
	ApplyWeaponData(unitID, Spring.GetUnitRulesParam(unitID, "comm_weapon_name_1"), 
		Spring.GetUnitRulesParam(unitID, "comm_weapon_name_2"),
		Spring.GetUnitRulesParam(unitID, "comm_shield_name"))
	
	-- Do this all the time as it will be needed almost always.
	GG.UpdateUnitAttributes(unitID)
end

local function GetModuleEffectsData(moduleList, level, chassis)
	local moduleByDefID = upgradeUtilities.ModuleListToByDefID(moduleList)
	
	local moduleEffectData = {}
	for i = 1, #moduleList do
		local moduleDef = moduleDefs[moduleList[i]]
		if moduleDef.applicationFunction then
			moduleDef.applicationFunction(moduleByDefID, moduleEffectData)
		end
	end
	
	local levelFunction = chassisDefs[chassis or 1].levelDefs[math.min(chassisDefs[chassis or 1].maxNormalLevel, level or 1)].chassisApplicationFunction
	if levelFunction then
		levelFunction(moduleByDefID, moduleEffectData)
	end
	
	return moduleEffectData
end

local function InitializeDynamicCommander(unitID, level, chassis, totalCost, name, baseUnitDefID, baseWreckID, baseHeapID, moduleList, moduleEffectData, images, profileID, staticLevel)
	-- This function sets the UnitRulesParams and updates the unit attributes after
	-- a commander has been created. This can either happen internally due to a request
	-- to spawn a commander or with rezz/construction/spawning.
	if not moduleEffectData then
		moduleEffectData = GetModuleEffectsData(moduleList, level, chassis)
	end
	
	-- Start setting required unitRulesParams
	Spring.SetUnitRulesParam(unitID, "comm_level",         level, INLOS)
	Spring.SetUnitRulesParam(unitID, "comm_chassis",       chassis, INLOS)
	Spring.SetUnitRulesParam(unitID, "comm_name",          name, INLOS)
	Spring.SetUnitRulesParam(unitID, "comm_cost",          totalCost, INLOS)
	Spring.SetUnitRulesParam(unitID, "comm_baseUnitDefID", baseUnitDefID, INLOS)
	Spring.SetUnitRulesParam(unitID, "comm_baseWreckID",   baseWreckID, INLOS)
	Spring.SetUnitRulesParam(unitID, "comm_baseHeapID",    baseHeapID, INLOS)
	
	if profileID then
		Spring.SetUnitRulesParam(unitID, "comm_profileID",     profileID, INLOS)
	end
	
	if staticLevel then -- unmorphable
		Spring.SetUnitRulesParam(unitID, "comm_staticLevel",   staticLevel, INLOS)
	end
	
	Spring.SetUnitCosts(unitID, {
		buildTime = totalCost,
		metalCost = totalCost,
		energyCost = totalCost
	})
	
	-- Set module unitRulesParams
	-- Decorations are kept seperate from other module types.
	-- basic_weapon, adv_weapon and module all count as modules.
	local counts = {module = 0, decoration = 0}
	for i = 1, #moduleList do
		local moduleDefID = moduleList[i]
		SetUnitRulesModule(unitID, counts, moduleDefID)
	end
	SetUnitRulesModuleCounts(unitID, counts)
	
	ApplyModuleEffects(unitID, moduleEffectData, totalCost, images or {})
	
	if staticLevel then
		-- Newly created commander, set to full health
		local _, maxHealth = Spring.GetUnitHealth(unitID)
		Spring.SetUnitHealth(unitID, maxHealth)
	end
end

local function Upgrades_CreateUpgradedUnit(defName, x, y, z, face, unitTeam, isBeingBuilt, upgradeDef)
	-- Calculate Module effects
	local moduleEffectData = GetModuleEffectsData(upgradeDef.moduleList, upgradeDef.level, upgradeDef.chassis)
	
	-- Create Unit, set appropriate global data first
	-- These variables are set such that other gadgets can notice the effect
	-- within UnitCreated.
	if moduleEffectData.shield then
		unitCreatedShield, unitCreatedShieldNum = upgradeUtilities.GetUnitDefShield(defName, moduleEffectData.shield)
	end
	
	if moduleEffectData.personalCloak then
		unitCreatedCloak = true
	end
	
	if moduleEffectData.radarJammingRange then
		unitCreatedJammingRange = COMMANDER_JAMMING_COST
	end
	
	if moduleEffectData.areaCloak then
		unitCreatedCloakShield = true
	end
	
	unitCreatedWeaponNums = {}
	if moduleEffectData.weapon1 then
		unitCreatedWeaponNums[moduleEffectData.weapon1] = 1
	end
	if moduleEffectData.weapon2 then
		unitCreatedWeaponNums[moduleEffectData.weapon2] = 2
	end
	if moduleEffectData.shield then
		unitCreatedWeaponNums[moduleEffectData.shield] = 3
	end
	
	interallyCreatedUnit = true
	
	internalCreationUpgradeDef = upgradeDef
	internalCreationModuleEffectData = moduleEffectData
	
	local unitID = Spring.CreateUnit(defName, x, y, z, face, unitTeam, isBeingBuilt)
	
	-- Unset the variables which need to be present at unit creation
	interallyCreatedUnit = false
	internalCreationUpgradeDef = nil
	internalCreationModuleEffectData = nil
	
	unitCreatedShield = nil
	unitCreatedShieldNum = nil
	unitCreatedShield = nil
	unitCreatedCloak = nil
	unitCreatedJammingRange = nil
	unitCreatedCloakShield = nil
	unitCreatedWeaponNums = nil
	unitCreatedCarrierDef = nil
	
	if not unitID then
		return false
	end
	
	return unitID
end

local function CreateStaticCommander(dyncommID, commProfileInfo, moduleList, moduleCost, x, y, z, facing, teamID, targetLevel)
	for i = 0, targetLevel do
		local levelModules = commProfileInfo.modules[i]
		if levelModules then
			for j = 1, #levelModules do
				local moduleID = moduleDefNames[levelModules[j]]
				if moduleID and moduleDefs[moduleID] then
					moduleList[#moduleList + 1] = moduleID
					moduleCost = moduleCost + moduleDefs[moduleID].cost
				end
			end
		end
	end
	
	local moduleByDefID = upgradeUtilities.ModuleListToByDefID(moduleList)
	
	local chassisDefID = chassisDefNames[commProfileInfo.chassis]
	local chassisData = chassisDefs[chassisDefID]
	local chassisLevel = math.min(chassisData.maxNormalLevel, targetLevel)
	local unitDefID = chassisData.levelDefs[chassisLevel].morphUnitDefFunction(moduleByDefID)
	
	local upgradeDef = {
		level = targetLevel,
		staticLevel = targetLevel,
		chassis = chassisDefID, 
		totalCost = UnitDefs[chassisDefID].metalCost + moduleCost,
		name = commProfileInfo.name,
		moduleList = moduleList,
		baseUnitDefID = unitDefID,
		baseWreckID = commProfileInfo.baseWreckID or chassisData.baseWreckID,
		baseHeapID = commProfileInfo.baseHeapID or chassisData.baseHeapID,
		images = commProfileInfo.images,
		profileID = dyncommID,
	}
	
	local unitID = Upgrades_CreateUpgradedUnit(unitDefID, x, y, z, facing, teamID, false, upgradeDef)
	
	return unitID
end

local function Upgrades_CreateStarterDyncomm(dyncommID, x, y, z, facing, teamID, staticLevel)
	--Spring.Echo("Creating starter dyncomm " .. dyncommID)
	local commProfileInfo = GG.ModularCommAPI.GetCommProfileInfo(dyncommID)
	local chassisDefID = chassisDefNames[commProfileInfo.chassis]
	if not chassisDefID then
		Spring.Echo("Incorrect dynamic comm chassis", commProfileInfo.chassis)
		return false
	end
	
	local chassisData = chassisDefs[chassisDefID]
	if chassisData.notSelectable and not staticLevel then
		Spring.Echo("Chassis not selectable", commProfileInfo.chassis)
		return false
	end
	
	local baseUnitDefID = commProfileInfo.baseUnitDefID or chassisData.baseUnitDef
	
	local moduleList = {moduleDefNames.econ}
	local moduleCost = moduleDefs[moduleDefNames.econ].cost
	
	if commProfileInfo.decorations then
		for i = 1, #commProfileInfo.decorations do
			local decName = commProfileInfo.decorations[i]
			if moduleDefNames[decName] then
				moduleList[#moduleList + 1] = moduleDefNames[decName]
			end
		end
	end
	
	if staticLevel then
		return CreateStaticCommander(dyncommID, commProfileInfo, moduleList, moduleCost, x, y, z, facing, teamID, staticLevel)
	end
	
	local upgradeDef = {
		level = 0,
		chassis = chassisDefID, 
		totalCost = UnitDefs[baseUnitDefID].metalCost + moduleCost,
		name = commProfileInfo.name,
		moduleList = moduleList,
		baseUnitDefID = baseUnitDefID,
		baseWreckID = commProfileInfo.baseWreckID or chassisData.baseWreckID,
		baseHeapID = commProfileInfo.baseHeapID or chassisData.baseHeapID,
		images = commProfileInfo.images,
		profileID = dyncommID
	}
	
	local unitID = Upgrades_CreateUpgradedUnit(baseUnitDefID, x, y, z, facing, teamID, false, upgradeDef)
	
	return unitID
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if Spring.GetUnitRulesParam(unitID, "comm_level") then
		return
	end
	
	if interallyCreatedUnit then
		InitializeDynamicCommander(
			unitID,
			internalCreationUpgradeDef.level, 
			internalCreationUpgradeDef.chassis, 
			internalCreationUpgradeDef.totalCost, 
			internalCreationUpgradeDef.name, 
			internalCreationUpgradeDef.baseUnitDefID, 
			internalCreationUpgradeDef.baseWreckID, 
			internalCreationUpgradeDef.baseHeapID, 
			internalCreationUpgradeDef.moduleList, 
			internalCreationModuleEffectData,
			internalCreationUpgradeDef.images,
			internalCreationUpgradeDef.profileID,
			internalCreationUpgradeDef.staticLevel
		)
		return
	end
	
	local profileID = GG.ModularCommAPI.GetProfileIDByBaseDefID(unitDefID)
	if profileID then
		local commProfileInfo = GG.ModularCommAPI.GetCommProfileInfo(profileID)
		
		-- Add decorations
		local moduleList = {}
		if commProfileInfo.decorations then
			for i = 1, #commProfileInfo.decorations do
				local decName = commProfileInfo.decorations[i]
				if moduleDefNames[decName] then
					moduleList[#moduleList + 1] = moduleDefNames[decName]
				end
			end
		end
		
		InitializeDynamicCommander(
			unitID,
			0, 
			chassisDefNames[commProfileInfo.chassis], 
			UnitDefs[unitDefID].metalCost, 
			commProfileInfo.name, 
			unitDefID, 
			commProfileInfo.baseWreckID, 
			commProfileInfo.baseHeapID, 
			moduleList,
			false,
			commProfileInfo.images,
			profileID
		)
		return
	end
	
	if chassisDefByBaseDef[unitDefID] then
		local chassisData = chassisDefs[chassisDefByBaseDef[unitDefID]]
		
		InitializeDynamicCommander(
			unitID,
			0, 
			chassisDefByBaseDef[unitDefID], 
			UnitDefs[unitDefID].metalCost, 
			"Guinea Pig", 
			unitDefID, 
			chassisData.baseWreckID, 
			chassisData.baseHeapID, 
			{},
			{}
		)
		return
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function Upgrades_GetValidAndMorphAttributes(unitID, params)
	-- Initial data and easy sanity tests
	if #params <= 4 then
		return false
	end
	
	local pLevel = params[1]
	local pChassis = params[2]
	local pAlreadyCount = params[3]
	local pNewCount = params[4]
	
	if #params ~= 4 + pAlreadyCount + pNewCount then
		return false
	end
	
	if Spring.GetUnitRulesParam(unitID, "comm_staticLevel") then
		return false
	end
	
	-- Make sure level and chassis match.
	local level = Spring.GetUnitRulesParam(unitID, "comm_level")
	local chassis = Spring.GetUnitRulesParam(unitID, "comm_chassis")
	if level ~= pLevel or chassis ~= pChassis then
		return false
	end
	
	local newLevel = level + 1
	local newLevelBounded = math.min(chassisDefs[chassis].maxNormalLevel, level + 1)
	
	-- If unbounded level is disallowed then the comm might be invalid
	if LEVEL_BOUND and newLevel > LEVEL_BOUND then
		return false
	end

	-- Determine what the command thinks the unit already owns
	local index = 5
	local pAlreadyOwned = {}
	for i = 1, pAlreadyCount do
		pAlreadyOwned[i] = params[index] 
		index = index + 1
	end
	
	-- Find the modules which are already owned
	local alreadyOwned = {}
	local fullModuleList = {}
	
	local moduleCount = Spring.GetUnitRulesParam(unitID, "comm_module_count")
	for i = 1, moduleCount do
		local module = Spring.GetUnitRulesParam(unitID, "comm_module_" .. i)
		alreadyOwned[#alreadyOwned + 1] = module
		fullModuleList[#fullModuleList + 1] = module
	end
	
	-- Strictly speaking sort is not required. It is for leniency
	table.sort(alreadyOwned)
	table.sort(pAlreadyOwned)
	
	-- alreadyOwned does not contain decoration modules so pAlreadyOwned
	-- should not contain decoration modules. The check fails if pAlreadyOwned
	-- contains decorations.
	if not upgradeUtilities.ModuleSetsAreIdentical(alreadyOwned, pAlreadyOwned) then
		return false
	end
	
	-- Check the validity of the new module set
	local pNewModules = {}
	for i = 1, pNewCount do
		pNewModules[#pNewModules + 1] = params[index] 
		index = index + 1
	end
	
	-- Finish the full modules list
	-- Empty module slots do not make it into this list
	for i = 1, #pNewModules  do
		if not moduleDefs[pNewModules[i]].emptyModule then
			fullModuleList[#fullModuleList + 1] = pNewModules[i] 
		end
	end
	
	local modulesByDefID = upgradeUtilities.ModuleListToByDefID(fullModuleList)
	
	-- Determine Cost and check that the new modules are valid.
	local levelDefs = chassisDefs[chassis].levelDefs[newLevelBounded]
	local slotDefs = levelDefs.upgradeSlots
	local cost = 0
	
	for i = 1, #pNewModules do
		local moduleDefID = pNewModules[i]
		if upgradeUtilities.ModuleIsValid(newLevelBounded, chassis, slotDefs[i].slotAllows, moduleDefID, modulesByDefID) then
			cost = cost + moduleDefs[moduleDefID].cost
		else
			return false
		end
	end
	
	-- Add Decorations, they are modules but not part of the previous checks.
	-- Assumed to be valid here because they cannot be added by this function.
	local decCount = Spring.GetUnitRulesParam(unitID, "comm_decoration_count")
	for i = 1, decCount do
		local decoration = Spring.GetUnitRulesParam(unitID, "comm_decoration_" .. i)
		fullModuleList[#fullModuleList + 1] = decoration
	end
	
	local images = {}
	local bannerOverhead = Spring.GetUnitRulesParam(unitID, "comm_banner_overhead")
	if bannerOverhead then
		images.overhead = bannerOverhead
	end
	
	-- The command is now known to be valid. Construct the morphDef.
	
	if newLevel ~= newLevelBounded then
		cost = cost + chassisDefs[chassis].extraLevelCostFunction(newLevel)
	else
		cost = cost + levelDefs.morphBaseCost
	end
	local targetUnitDefID = levelDefs.morphUnitDefFunction(modulesByDefID)
	
	local morphTime = cost/levelDefs.morphBuildPower
	local increment = (1 / (30 * morphTime))
	
	local morphDef = {
		upgradeDef = {
			name = Spring.GetUnitRulesParam(unitID, "comm_name"),
			totalCost = cost + Spring.Utilities.GetUnitCost(unitID),
			level = newLevel,
			chassis = chassis,
			moduleList = fullModuleList,
			baseUnitDefID = Spring.GetUnitRulesParam(unitID, "comm_baseUnitDefID"),
			baseWreckID = Spring.GetUnitRulesParam(unitID, "comm_baseWreckID"),
			baseHeapID = Spring.GetUnitRulesParam(unitID, "comm_baseHeapID"),
			images = images,
			profileID = Spring.GetUnitRulesParam(unitID, "comm_profileID"),
		},
		combatMorph = true,
		metal = cost,
		time = morphTime,
		into = targetUnitDefID,
		increment = increment,
		stopCmd = CMD_UPGRADE_STOP,
		resTable = {
			m = (increment * cost),
			e = (increment * cost)
		},
		cmd = nil, -- for completeness
		facing = nil,
	}
	
	return true, targetUnitDefID, morphDef
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function GG.Upgrades_UnitShieldDef(unitID)
	local shieldDefID = (unitCreatedShield or Spring.GetUnitRulesParam(unitID, "comm_shield_id")) or false
	local shieldNum = (unitCreatedShieldNum or Spring.GetUnitRulesParam(unitID, "comm_shield_num")) or false
	local shieldDef = false
	if shieldDefID and WeaponDefs[shieldDefID].shieldRadius > 200 then
		shieldDef = commAreaShieldDefID
	end

	return shieldDefID, shieldNum, shieldDef
end

function GG.Upgrades_UnitCanCloak(unitID)
	return unitCreatedCloak or Spring.GetUnitRulesParam(unitID, "comm_personal_cloak")
end

function GG.Upgrades_UnitJammerEnergyDrain(unitID)
	return unitCreatedJammingRange or Spring.GetUnitRulesParam(unitID, "comm_jamming_cost")
end

function GG.Upgrades_UnitCloakShieldDef(unitID)
	return (unitCreatedCloakShield or Spring.GetUnitRulesParam(unitID, "comm_area_cloak")) and commanderCloakShieldDef
end

function GG.Upgrades_WeaponNumMap(num)
	if unitCreatedWeaponNums then
		return unitCreatedWeaponNums[num]
	end
	return false
end

-- GG.Upgrades_GetUnitCustomShader is up in unsynced

function gadget:Initialize()
	GG.Upgrades_CreateUpgradedUnit         = Upgrades_CreateUpgradedUnit
	GG.Upgrades_CreateStarterDyncomm       = Upgrades_CreateStarterDyncomm
	GG.Upgrades_GetValidAndMorphAttributes = Upgrades_GetValidAndMorphAttributes
	
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
	
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Save/Load

function gadget:Load(zip)
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		if Spring.GetUnitRulesParam(unitID, "comm_level") then
			ApplyModuleEffectsFromUnitRulesParams(unitID)
		end
	end
end
