function gadget:GetInfo()
  return {
    name      = "Comander Upgrade",
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
   return false
end

local INLOS = {inlos = true}
local interallyCreatedUnit = false

local unitCreatedShield, unitCreatedShieldNum, unitCreatedCloak

local moduleDefs, emptyModules, chassisDefs, upgradeUtilities, chassisDefByBaseDef, moduleDefNames, chassisDefNames = include("LuaRules/Configs/dynamic_comm_defs.lua")
include("LuaRules/Configs/customcmds.h.lua")

-- FIXME: make this not needed
local legacyToDyncommChassisMap = {
	armcom = "assault",
	corcom = "assault",
	commrecon = "recon",
	commsupport = "support",
	benzcom = "assault",
	cremcom = "support",
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local function SetUnitRulesModule(unitID, counts, moduleDefID)
	local slotType = moduleDefs[moduleDefID].slotType
	counts[slotType] = counts[slotType] + 1
	Spring.SetUnitRulesParam(unitID, "comm_" .. slotType .. "_" .. counts[slotType], moduleDefID, INLOS)
end

local function SetUnitRulesModuleCounts(unitID, counts)
	for name, value in pairs(counts) do
		Spring.SetUnitRulesParam(unitID, "comm_" .. name .. "_count", value, INLOS)
	end
end

local function ApplyWeaponData(unitID, weapon1, weapon2, shield, rangeMult)
	local chassisDefID = Spring.GetUnitRulesParam(unitID, "comm_chassis")
	local chassisWeaponDefNames = chassisDefs[chassisDefID].weaponDefNames 
	
	weapon1 = chassisWeaponDefNames[weapon1 or "peashooter"]
	
	if weapon2 then
		weapon2 = chassisWeaponDefNames[weapon2]
	elseif Spring.GetUnitRulesParam(unitID, "comm_level") > 2 then 
		weapon2 = chassisWeaponDefNames["peashooter"]
	end
	
	shield = shield and chassisWeaponDefNames[shield]
	
	rangeMult = rangeMult or 1
	Spring.SetUnitRulesParam(unitID, "comm_range_mult", rangeMult,  INLOS)
	
	Spring.SetUnitRulesParam(unitID, "comm_weapon_id_1", (weapon1 and weapon1.weaponDefID) or 0, INLOS)
	Spring.SetUnitRulesParam(unitID, "comm_weapon_id_2", (weapon2 and weapon2.weaponDefID) or 0, INLOS)
	
	Spring.SetUnitRulesParam(unitID, "comm_weapon_num_1", (weapon1 and weapon1.num) or 0, INLOS)
	Spring.SetUnitRulesParam(unitID, "comm_weapon_num_2", (weapon2 and weapon2.num) or 0, INLOS)
	
	Spring.SetUnitRulesParam(unitID, "comm_weapon_manual_1", (weapon1 and weapon1.manualFire) or 0, INLOS)
	Spring.SetUnitRulesParam(unitID, "comm_weapon_manual_2", (weapon2 and weapon2.manualFire) or 0, INLOS)

	if shield then
		Spring.SetUnitRulesParam(unitID, "comm_shield_id", shield.weaponDefID, INLOS)
		Spring.SetUnitRulesParam(unitID, "comm_shield_num", shield.num, INLOS)
		Spring.SetUnitRulesParam(unitID, "comm_shield_max", WeaponDefs[shield.weaponDefID].shieldPower, INLOS)
	else
		Spring.SetUnitRulesParam(unitID, "comm_shield_max", 0, INLOS)
	end
	
	local env = Spring.UnitScript.GetScriptEnv(unitID)
	Spring.UnitScript.CallAsUnit(unitID, env.UpdateWeapons, weapon1, weapon2, shield, rangeMult)
end

local function ApplyModuleEffects(unitID, data)
	if data.speedMult then
		Spring.SetUnitRulesParam(unitID, "upgradesSpeedMult", data.speedMult, INLOS)
	end
	
	if data.radarRange then
		Spring.SetUnitRulesParam(unitID, "radarRangeOverride", data.radarRange, INLOS)
	end
	
	if data.radarJammingRange then
		Spring.SetUnitRulesParam(unitID, "jammingRangeOverride", data.radarJammingRange, INLOS)
	end
	
	if data.personalCloak then
		Spring.SetUnitCloak(unitID, false, data.decloakDistance)
		Spring.SetUnitRulesParam(unitID, "comm_decloak_distance", data.decloakDistance, INLOS)
		Spring.SetUnitRulesParam(unitID, "comm_personal_cloak", 1, INLOS)
	end
	
	if data.metalIncome and GG.Overdrive_AddUnitResourceGeneration then
		GG.Overdrive_AddUnitResourceGeneration(unitID, data.metalIncome, data.energyIncome)
	end
	
	if data.bonusBuildPower then
		-- All comms have 10 BP in their unitDef (even support)
		Spring.SetUnitRulesParam(unitID, "buildpower_mult", data.bonusBuildPower/10 + 1, INLOS)
	end
	
	if data.healthBonus then
		local health, maxHealth = Spring.GetUnitHealth(unitID)
		Spring.SetUnitHealth(unitID, health + data.healthBonus)
		Spring.SetUnitMaxHealth(unitID, maxHealth + data.healthBonus)
	end
	
	ApplyWeaponData(unitID, data.weapon1, data.weapon2, data.shield, data.rangeMult)
	
	-- Do this all the time as it will be needed almost always.
	GG.UpdateUnitAttributes(unitID)
end

local function Upgrades_CreateUpgradedUnit(defName, x, y, z, face, unitTeam, isBeingBuilt, upgradeDef)
	-- Calculate Module effects
	local chassisWeaponDefNames = chassisDefs[upgradeDef.chassis].weaponDefNames 
	local moduleList = upgradeDef.moduleList
	local moduleByDefID = upgradeUtilities.ModuleListToByDefID(moduleList)
	
	local moduleEffectData = {}
	for i = 1, #moduleList do
		local moduleDef = moduleDefs[moduleList[i]]
		if moduleDef.applicationFunction then
			moduleDef.applicationFunction(moduleByDefID, moduleEffectData)
		end
	end
	
	-- Create Unit
	if moduleEffectData.shield then
		unitCreatedShield = chassisWeaponDefNames[moduleEffectData.shield].weaponDefID
		unitCreatedShieldNum = chassisWeaponDefNames[moduleEffectData.shield].num
	end
	
	if moduleEffectData.personalCloak then
		unitCreatedCloak = true
	end
	
	interallyCreatedUnit = true
	
	local unitID = Spring.CreateUnit(defName, x, y, z, face, unitTeam, isBeingBuilt)
	
	-- Unset the variables which need to be present at unit creation
	interallyCreatedUnit = false
	unitCreatedShield = nil
	unitCreatedShieldNum = nil
	unitCreatedCloak = nil
	
	if not unitID then
		return false
	end
	
	-- Start setting required unitRulesParams
	local totalCost = upgradeDef.totalCost
	Spring.SetUnitRulesParam(unitID, "comm_level", upgradeDef.level, INLOS)
	Spring.SetUnitRulesParam(unitID, "comm_chassis", upgradeDef.chassis, INLOS)
	Spring.SetUnitRulesParam(unitID, "comm_name", upgradeDef.name, INLOS)
	Spring.SetUnitRulesParam(unitID, "comm_cost", totalCost, INLOS)
	Spring.SetUnitRulesParam(unitID, "comm_baseUnitDefID", upgradeDef.baseUnitDefID, INLOS)
	Spring.SetUnitRulesParam(unitID, "comm_baseWreckID", upgradeDef.baseWreckID, INLOS)
	Spring.SetUnitRulesParam(unitID, "comm_baseHeapID", upgradeDef.baseHeapID, INLOS)
	
	Spring.SetUnitCosts(unitID, {
		buildTime = totalCost,
		metalCost = totalCost,
		energyCost = totalCost
	})
	
	-- Set module unitRulesParams
	local counts = {module = 0, weapon = 0}
	for i = 1, #moduleList do
		local moduleDefID = moduleList[i]
		SetUnitRulesModule(unitID, counts, moduleDefID)
	end
	SetUnitRulesModuleCounts(unitID, counts)
	
	ApplyModuleEffects(unitID, moduleEffectData)
	return unitID
end

local function Upgrades_CreateStarterDyncomm(dyncommID, x, y, z, facing, teamID)
	Spring.Echo("Creating starter dyncomm " .. dyncommID) 
	local commProfileInfo = GG.ModularCommAPI.GetCommProfileInfo(dyncommID)
	local chassisDefID = chassisDefNames[legacyToDyncommChassisMap[commProfileInfo.chassis] or "recon"]
	if not chassisDefID then
		Spring.Echo("Incorrect dynamic comm chassis", commProfileInfo.chassis)
		return false
	end
	
	local chassisData = chassisDefs[chassisDefID]
	local baseUnitDefID = commProfileInfo.baseUnitDefID or chassisData.baseUnitDef
	
	local upgradeDef = {
		level = 0,
		chassis = chassisDefID, 
		totalCost = 1200,
		name = commProfileInfo.name,
		moduleList = {moduleDefNames.econ},
		baseUnitDefID = baseUnitDefID,
		baseWreckID = commProfileInfo.baseWreckID or chassisData.baseWreckID,
		baseHeapID = commProfileInfo.baseHeapID or chassisData.baseHeapID,
	}
	
	local unitID = Upgrades_CreateUpgradedUnit(baseUnitDefID, x, y, z, facing, teamID, false, upgradeDef)
	
	return unitID
end

local function Upgrades_CreateBrokenStarterDyncomm(dyncommID, x, y, z, facing, teamID)
	local chassisData = chassisDefs[1]
	local upgradeDef = {
		level = 0,
		chassis = 1, 
		totalCost = 1200,
		name = "Bob",
		moduleList = {moduleDefNames.econ},
		baseUnitDefID = chassisData.baseUnitDef,
		baseWreckID = chassisData.baseWreckID,
		baseHeapID = chassisData.baseHeapID,
	}
	
	local unitID = Upgrades_CreateUpgradedUnit(chassisData.baseUnitDef, x, y, z, facing, teamID, false, upgradeDef)
	
	return unitID
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if chassisDefByBaseDef[unitDefID] and not interallyCreatedUnit then
		local chassisData = chassisDefs[chassisDefByBaseDef[unitDefID]]
		
		Spring.SetUnitRulesParam(unitID, "comm_level", 0, INLOS)
		Spring.SetUnitRulesParam(unitID, "comm_chassis", chassisDefByBaseDef[unitDefID], INLOS)
		Spring.SetUnitRulesParam(unitID, "comm_cost", 1200, INLOS)
		Spring.SetUnitRulesParam(unitID, "comm_name", "Guinea Pig", INLOS)
		Spring.SetUnitRulesParam(unitID, "comm_baseUnitDefID", unitDefID, INLOS)
		Spring.SetUnitRulesParam(unitID, "comm_baseWreckID", chassisData.baseWreckID, INLOS)
		Spring.SetUnitRulesParam(unitID, "comm_baseHeapID", chassisData.baseHeapID, INLOS)
		Spring.SetUnitRulesParam(unitID, "comm_module_count", 0, INLOS)
		Spring.SetUnitRulesParam(unitID, "comm_weapon_count", 0, INLOS)
		Spring.SetUnitRulesParam(unitID, "upgradesSpeedMult", 1)
		
		ApplyWeaponData(unitID, "peashooter")
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
	
	-- Make sure level and chassis match.
	local level = Spring.GetUnitRulesParam(unitID, "comm_level")
	local chassis = Spring.GetUnitRulesParam(unitID, "comm_chassis")
	if level ~= pLevel or chassis ~= pChassis then
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
	local weaponCount = Spring.GetUnitRulesParam(unitID, "comm_weapon_count")
	for i = 1, weaponCount do
		local weapon = Spring.GetUnitRulesParam(unitID, "comm_weapon_" .. i)
		alreadyOwned[#alreadyOwned + 1] = weapon
		fullModuleList[#fullModuleList + 1] = weapon
	end
	
	local moduleCount = Spring.GetUnitRulesParam(unitID, "comm_module_count")
	for i = 1, moduleCount do
		local module = Spring.GetUnitRulesParam(unitID, "comm_module_" .. i)
		alreadyOwned[#alreadyOwned + 1] = module
		fullModuleList[#fullModuleList + 1] = module
	end
	
	-- Strictly speaking sort is not required. It is for leniency
	table.sort(alreadyOwned)
	table.sort(pAlreadyOwned)
	
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
		if not emptyModules[pNewModules[i]] then
			fullModuleList[#fullModuleList + 1] = pNewModules[i] 
		end
	end
	
	local modulesByDefID = upgradeUtilities.ModuleListToByDefID(fullModuleList)
	
	-- Determine Cost and check that the new modules are valid.
	local levelDefs = chassisDefs[chassis].levelDefs[level+1]
	local slotDefs = levelDefs.upgradeSlots
	local cost = 0
	
	for i = 1, #pNewModules do
		local moduleDefID = pNewModules[i]
		if upgradeUtilities.ModuleIsValid(level, chassis, slotDefs[i].slotType, moduleDefID, modulesByDefID) then
			cost = cost + moduleDefs[moduleDefID].cost
		else
			return false
		end
	end
	
	-- The command is now known to be valid. Construct the morphDef.
	local cost = cost + levelDefs.morphBaseCost
	local targetUnitDefID = levelDefs.morphUnitDefFunction(modulesByDefID)
	
	local morphTime = cost/levelDefs.morphBuildPower
	local increment = (1 / (30 * morphTime))
	
	local morphDef = {
		upgradeDef = {
			name = Spring.GetUnitRulesParam(unitID, "comm_name"),
			totalCost = cost + Spring.Utilities.GetUnitCost(unitID),
			level = level + 1,
			chassis = chassis,
			moduleList = fullModuleList,
			baseUnitDefID = Spring.GetUnitRulesParam(unitID, "comm_baseUnitDefID"),
			baseWreckID = Spring.GetUnitRulesParam(unitID, "comm_baseWreckID"),
			baseHeapID = Spring.GetUnitRulesParam(unitID, "comm_baseHeapID"),
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
	return unitCreatedShield or Spring.GetUnitRulesParam(unitID, "comm_shield_id"), unitCreatedShieldNum or Spring.GetUnitRulesParam(unitID, "comm_shield_num")
end

function GG.Upgrades_UnitCanCloak(unitID)
	return unitCreatedCloak or Spring.GetUnitRulesParam(unitID, "comm_personal_cloak")
end

function gadget:Initialize()
	GG.Upgrades_CreateUpgradedUnit         = Upgrades_CreateUpgradedUnit
	GG.Upgrades_CreateBrokenStarterDyncomm       = Upgrades_CreateBrokenStarterDyncomm
	GG.Upgrades_GetValidAndMorphAttributes = Upgrades_GetValidAndMorphAttributes
	
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
	
end
