local moduleDefs = {
	{
		name = "nullmodule",
		humanName = "No Module",
		description = "No Module",
		image = "LuaUI/Images/dynamic_comm_menu/cross.png",
		limit = false,
		cost = 0,
		requireModules = {},
		requireLevel = 0,
		slotType = "module",
	},
	{
		name = "nullweapon",
		humanName = "No Weapon",
		description = "No Weapon",
		image = "LuaUI/Images/dynamic_comm_menu/cross.png",
		limit = false,
		cost = 0,
		requireModules = {},
		requireLevel = 0,
		slotType = "weapon",
	},
	{
		name = "lpb",
		humanName = "Light Particle Beam",
		description = "Auto Pew",
		image = "unitpics/commweapon_lparticlebeam.png",
		limit = 2,
		cost = 100,
		requireModules = {},
		requireLevel = 0,
		slotType = "weapon",
		applicationFunction = function (unitID, modules, sharedData)
			if not sharedData.weapon1 then
				sharedData.weapon1 = 2
			else
				sharedData.weapon2 = 2
			end
		end
	},
	{
		name = "hpb",
		humanName = "Heavy Particle Beam",
		description = "Manual Pew",
		image = "unitpics/conversion_hparticlebeam.png",
		limit = 1,
		cost = 100,
		requireModules = {},
		requireLevel = 0,
		slotType = "weapon",
		applicationFunction = function (unitID, modules, sharedData)
			if not sharedData.weapon1 then
				sharedData.weapon1 = 3
			else
				sharedData.weapon2 = 3
			end
		end
	},
	{
		name = "personal_shield",
		humanName = "Personal Shield",
		description = "A small, protective bubble shield.",
		image = "unitpics/module_personal_shield.png",
		limit = 1,
		cost = 100,
		requireModules = {},
		requireLevel = 0,
		slotType = "module",
		applicationFunction = function (unitID, modules, sharedData)
			sharedData.shield = 4
		end
	},
	{
		name = "area_shield",
		humanName = "Area Shield",
		description = "The Emperor protects",
		image = "unitpics/module_areashield.png",
		limit = 1,
		cost = 100,
		requireModules = {},
		requireLevel = 0,
		slotType = "module",
		applicationFunction = function (unitID, modules, sharedData)
			sharedData.shield = 5
		end
	},
	{
		name = "rocket",
		humanName = "Rocket Thingy",
		description = "Rocket Thingy",
		image = "unitpics/commweapon_rocketlauncher.png",
		limit = 2,
		cost = 75,
		requireChassis = {"support"},
		requireModules = {},
		requireLevel = 0,
		slotType = "weapon",
	},
	{
		name = "health",
		humanName = "Ablative Armour Plates",
		description = "Ablative Armour Plates, provides 600 health. Limit 8.",
		image = "unitpics/module_ablative_armor.png",
		limit = 3,
		cost = 60,
		requireChassis = {"recon", "support"},
		requireModules = {},
		requireLevel = 0,
		slotType = "module",
		applicationFunction = function (unitID, modules, sharedData)
			sharedData.healthBonus = (sharedData.healthBonus or 0) + 600
		end
	},
	{
		name = "bigHealth",
		humanName = "High Density Plating",
		description = "High Density Plating, provides 1600 health but reduces movement by 10%. Limit 7, requires Ablative Armour Plates.",
		image = "unitpics/module_heavy_armor.png",
		limit = 3,
		cost = 50,
		requireModules = {"health"},
		requireLevel = 0,
		slotType = "module",
		applicationFunction = function (unitID, modules, sharedData)
			sharedData.healthBonus = (sharedData.healthBonus or 0) + 1600
			sharedData.speedMult = (sharedData.speedMult or 1) - 0.1
		end
	},
	{
		name = "damageBooster",
		humanName = "Damage Booster",
		description = "Damage Booster, increases damage by 10%. Limit 8.",
		image = "unitpics/module_dmg_booster.png",
		limit = 8,
		cost = 40,
		requireModules = {},
		requireLevel = 0,
		slotType = "module",
	},
	{
		name = "speed",
		humanName = "High Power Servos",
		description = "High Power Servos, increases speed by 10%. Limit 8",
		image = "unitpics/module_high_power_servos.png",
		limit = 8,
		cost = 40,
		requireModules = {},
		requireLevel = 0,
		slotType = "module",
		applicationFunction = function (unitID, modules, sharedData)
			sharedData.speedMult = (sharedData.speedMult or 1) + 0.1
		end
	},
	{
		name = "econ",
		humanName = "Vanguard Economy Pack",
		description = "Vanguard Economy Pack, produces 4 Metal and 6 Energy.",
		image = "unitpics/module_energy_cell.png",
		limit = 1,
		cost = 0,
		requireModules = {},
		requireChassis = {"recon", "support"},
		requireLevel = 0,
		slotType = "module",
		applicationFunction = function (unitID, modules, sharedData)
			sharedData.metalIncome = (sharedData.metalIncome or 0) + 4
			sharedData.energyIncome = (sharedData.energyIncome or 0) + 6
		end
	},
}

local moduleDefNames = {}
for i = 1, #moduleDefs do
	moduleDefNames[moduleDefs[i].name] = i
end

local chassisDefs = {
	{
		name = "Recon",
		baseUnitDef = UnitDefNames["commrecon0"].id,
		levelDefs = {
			{
				morphBuildPower = 10,
				morphBaseCost = 20,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["commrecon1_damage_boost" .. (modulesByDefID[moduleDefNames.damageBooster] or 0)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.lpb,
						slotType = "weapon",
					},
					{
						defaultModule = moduleDefNames.bigHealth,
						slotType = "module",
					},
					{
						defaultModule = moduleDefNames.health,
						slotType = "module",
					},
				},
			},
			{
				morphBuildPower = 20,
				morphBaseCost = 30,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["commrecon2_damage_boost" .. (modulesByDefID[moduleDefNames.damageBooster] or 0)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.lpb,
						slotType = "weapon",
					},
					{
						defaultModule = moduleDefNames.bigHealth,
						slotType = "module",
					},
					{
						defaultModule = moduleDefNames.health,
						slotType = "module",
					},
				},
			},
		}
	},
	{
		name = "Support",
		baseUnitDef = UnitDefNames["commsupport0"].id,
		levelDefs = {
			{
				morphBuildPower = 10,
				morphBaseCost = 20,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["commsupport1_damage_boost" .. (modulesByDefID[moduleDefNames.damageBooster] or 0)].id
				end,
				upgradeSlots = {
					{
						defaultModule = moduleDefNames.lpb,
						slotType = "weapon",
					},
					{
						defaultModule = moduleDefNames.bigHealth,
						slotType = "module",
					},
					{
						defaultModule = moduleDefNames.health,
						slotType = "module",
					},
				},
			},
		}
	}
}


------------------------------------------------------------------------
-- Processing
------------------------------------------------------------------------

-- Find the empty modules
-- This table is both by slotType and by moduleDefID
local emptyModules = {}
for i = 1, #moduleDefs do
	if moduleDefs[i].name == "nullmodule" then
		emptyModules.module = i
		emptyModules[i] = true
	elseif moduleDefs[i].name == "nullweapon" then
		emptyModules.weapon = i
		emptyModules[i] = true
	end
end

-- Transform from human readable format into number indexed format
for i = 1, #moduleDefs do
	local data = moduleDefs[i]
	
	-- Required modules are a list of moduleDefIDs
	if data.requireModules then
		local newRequire = {}
		for j = 1, #data.requireModules do
			for k = 1, #moduleDefs do
				if moduleDefs[k].name == data.requireModules[j] then
					newRequire[#newRequire + 1] = k
					break
				end
			end
		end
		data.requireModules = newRequire
	end
	
	-- Required chassis is a map indexed by chassisDefID
	if data.requireChassis then
		local newRequire = {}
		for j = 1, #data.requireChassis do
			for k = 1, #chassisDefs do
				if chassisDefs[k].name == data.requireChassis[j] then
					newRequire[k] = true
					break
				end
			end
		end
		data.requireChassis = newRequire
	end
end

------------------------------------------------------------------------
-- Utility Functions
------------------------------------------------------------------------

local function ModuleIsValid(level, chassis, slotType, moduleDefID, alreadyOwned, alreadyOwned2)
	local data = moduleDefs[moduleDefID]
	if data.slotType ~= slotType or (data.requireLevel or 0) > level or (data.requireChassis and (not data.requireChassis[chassis])) then
		return false
	end
	
	-- Check that requirements are met
	if data.requireModules then
		for j = 1, #data.requireModules do
			-- Modules should not depend on themselves so this check is simplier than the
			-- corresponding chcek in the replacement set generator.
			local reqDefID = data.requireModules[j]
			if not (alreadyOwned[reqDefID] or (alreadyOwned2 and alreadyOwned2[reqDefID])) then
				return false
			end
		end
	end
	
	-- Check that the module limit is not reached
	if data.limit and (alreadyOwned[moduleDefID] or (alreadyOwned2 and alreadyOwned2[moduleDefID])) then
		local count = (alreadyOwned[moduleDefID] or 0) + ((alreadyOwned2 and alreadyOwned2[moduleDefID]) or 0) 
		if count > data.limit then
			return false
		end
	end
	return true
end

local function ModuleSetsAreIdentical(set1, set2)
	-- Sets should be sorted prior to this function
	if (not set1) or (not set2) or (#set1 ~= #set2) then
		return false
	end

	local validUnit = true
	for i = 1, #set1 do
		if set1[i] ~= set2[i] then
			return false
		end
	end
	return true
end

local function ModuleListToByDefID(moduleList)
	local byDefID = {}
	for i = 1, #moduleList do
		local defID = moduleList[i]
		byDefID[defID] = (byDefID[defID] or 0) + 1
	end
	return byDefID
end

local utilities = {
	ModuleIsValid = ModuleIsValid,
	ModuleSetsAreIdentical = ModuleSetsAreIdentical,
	ModuleListToByDefID = ModuleListToByDefID,
}

------------------------------------------------------------------------
-- Return Values
------------------------------------------------------------------------

return moduleDefs, emptyModules, chassisDefs, utilities