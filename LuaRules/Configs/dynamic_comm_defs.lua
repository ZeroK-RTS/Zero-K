local moduleDefs = {
	{
		name = "nullmodule",
		humanName = "No Module",
		description = "No Module",
		image = "LuaUI/Images/commands/Bold/cancel.png",
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
		image = "LuaUI/Images/commands/Bold/cancel.png",
		limit = false,
		cost = 0,
		requireModules = {},
		requireLevel = 0,
		slotType = "weapon",
	},
	{
		name = "gun",
		humanName = "Gun Thingy",
		description = "Gun Thingy",
		image = "unitpics/commweapon_beamlaser.png",
		limit = 2,
		cost = 100,
		requireModules = {},
		requireLevel = 0,
		slotType = "weapon",
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
		humanName = "Health Thingy",
		description = "Health Thingy",
		image = "unitpics/module_ablative_armor.png",
		limit = 3,
		cost = 60,
		requireChassis = {"recon", "support"},
		requireModules = {},
		requireLevel = 0,
		slotType = "module",
	},
	{
		name = "bigHealth",
		humanName = "Health Thingy",
		description = "Big Health Thingy - Requires Health Thingy",
		image = "unitpics/module_heavy_armor.png",
		limit = 3,
		cost = 50,
		requireModules = {"health"},
		requireLevel = 0,
		slotType = "module",
	},
	{
		name = "skull",
		humanName = "Skull Thingy",
		description = "Skull Thingy - Limit 3",
		image = "unitpics/module_dmg_booster.png",
		limit = 3,
		cost = 40,
		requireModules = {},
		requireLevel = 0,
		slotType = "module",
	},
}

local moduleDefNames = {}
for i = 1, #moduleDefs do
	moduleDefNames[moduleDefs[i].name] = i
end

local chassisDefs = {
	{
		name = "recon",
		baseUnitDef = UnitDefNames["commrecon0"].id,
		levelDefs = {
			{
				morphBuildPower = 10,
				morphBaseCost = 200,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["commrecon1_damage_boost" .. (modulesByDefID[moduleDefNames[skull]] or 0)].id
				end,
				upgradeSlots = {
					{
						defaultModule = 3,
						slotType = "weapon",
					},
					{
						defaultModule = 5,
						slotType = "module",
					},
					{
						defaultModule = 7,
						slotType = "module",
					},
				},
			},
			{
				morphBuildPower = 20,
				morphBaseCost = 300,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["commrecon2_damage_boost" .. (modulesByDefID[moduleDefNames[skull]] or 0)].id
				end,
				upgradeSlots = {
					{
						defaultModule = 5,
						slotType = "module",
					},
					{
						defaultModule = 7,
						slotType = "module",
					},
				},
			},
		}
	},
	{
		name = "support",
		baseUnitDef = UnitDefNames["commsupport0"].id,
		levelDefs = {
			{
				morphBuildPower = 10,
				morphBaseCost = 200,
				morphUnitDefFunction = function(modulesByDefID)
					return UnitDefNames["commsupport1_damage_boost" .. (modulesByDefID[moduleDefNames[skull]] or 0)].id
				end,
				upgradeSlots = {
					{
						defaultModule = 3,
						slotType = "weapon",
					},
					{
						defaultModule = 5,
						slotType = "module",
					},
					{
						defaultModule = 7,
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