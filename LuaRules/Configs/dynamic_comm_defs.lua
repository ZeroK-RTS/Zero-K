-- mission editor compatibility
Spring.GetModOptions = Spring.GetModOptions or function() return {} end
local ModularCommDefsShared_={}
ModularCommDefsShared=ModularCommDefsShared_
ModularCommDefsShared=nil
local skinDefs
local SKIN_FILE = "LuaRules/Configs/dynamic_comm_skins.lua"
if VFS.FileExists(SKIN_FILE) then
	skinDefs = VFS.Include(SKIN_FILE)
else
	skinDefs = {}
end
---@type integer?
local LEVEL_BOUND = math.floor(tonumber(Spring.GetModOptions().max_com_level or 0)--[[@as integer]])
if LEVEL_BOUND <= 0 then
	LEVEL_BOUND = nil -- unlimited
else
	LEVEL_BOUND = LEVEL_BOUND - 1 -- UI counts from 1 but internals count from 0
end

local COST_MULT = 1
local HP_MULT = 1
local ECHO_MODULES_FOR_CIRCUIT = false

if (Spring.GetModOptions) then
	local modOptions = Spring.GetModOptions()
	if modOptions then
		if modOptions.hpmult and modOptions.hpmult ~= 1 then
			HP_MULT = tonumber(modOptions.hpmult)--[[@as number]]
		end
	end
end

ModularCommDefsShared_.HP_MULT=HP_MULT
ModularCommDefsShared_.COST_MULT=COST_MULT
local moduleImagePath = "unitpics/"
ModularCommDefsShared_.moduleImagePath=moduleImagePath
local disableResurrect = (Spring.GetModOptions().disableresurrect == 1) or (Spring.GetModOptions().disableresurrect == "1")
ModularCommDefsShared_.disableResurrect=disableResurrect
------------------------------------------------------------------------
-- Module Definitions
------------------------------------------------------------------------

-- For autogenerating expensive advanced versions
--[=[
local basicWeapons = {
	["commweapon_beamlaser"] = true,
	["commweapon_flamethrower"] = true,
	["commweapon_heatray"] = true,
	["commweapon_heavymachinegun"] = true,
	["commweapon_lightninggun"] = true,
	["commweapon_lparticlebeam"] = true,
	["commweapon_missilelauncher"] = true,
	["commweapon_riotcannon"] = true,
	["commweapon_rocketlauncher"] = true,
	["commweapon_shotgun"] = true,
}
ModularCommDefsShared_.basicWeapons=basicWeapons
]=]

local forAllChassisModules={
	"nullmodule","nullbasicweapon","nulladvweapon","nulldualbasicweapon"
}
local moduleDefNames = {}
ModularCommDefsShared_.moduleDefNames=moduleDefNames
local moduleDefNamesToIDs = {}
ModularCommDefsShared_.moduleDefNamesToIDs=moduleDefNamesToIDs


ModularCommDefsShared_.applicationFunctionApplyWeapon=function (GetWeaponName)
	return function (modules, sharedData)
		if sharedData.noMoreWeapons then
			return
		end
		if not sharedData.weapon1 then
			sharedData.weapon1 = GetWeaponName(modules,sharedData)
		else
			sharedData.weapon2 = GetWeaponName(modules,sharedData)
		end
	end
end

ModularCommDefsShared_.applicationFunctionApplyNoMoreWeapon=function (GetWeaponName)
	return function (modules, sharedData)
		if sharedData.noMoreWeapons then
			return
		end
		local weaponName = GetWeaponName(modules,sharedData)
		sharedData.weapon1 = weaponName
		sharedData.weapon2 = nil
		sharedData.noMoreWeapons = true
	end
end
ModularCommDefsShared_.UnitDefNames=UnitDefNames
ModularCommDefsShared_.GenAdvWeaponModule=function (def)
	
	local newDef = Spring.Utilities.CopyTable(def, true)
	newDef.name = newDef.name .. "_adv"
	newDef.slotType = "dual_basic_weapon"
	newDef.cost = 350 * COST_MULT
	return newDef
end
local moduleDefs = {}
local SharedEnv={ModularCommDefsShared=ModularCommDefsShared_,UnitDefNames=UnitDefNames}

setmetatable(SharedEnv,{__index=getfenv()})

local modulesalldefs=VFS.Include("gamedata/modularcomms/modules_all_defs.lua")
--local moduleFiles=VFS.DirList("gamedata/modularcomms/modules", "*.lua") or {}

for i = 1, #modulesalldefs do
	local new_moduleDefs = modulesalldefs[i].dynamic_comm_def(ModularCommDefsShared_)
	for key, moduleDef in pairs(new_moduleDefs) do
		moduleDefs[#moduleDefs+1]=moduleDef
		local def=moduleDef
		if def.isBasicWeapon then
			local newDef = Spring.Utilities.CopyTable(def, true)
			newDef.name = newDef.name .. "_adv"
			newDef.slotType = "dual_basic_weapon"
			newDef.cost = 350 * COST_MULT
			moduleDefs[#moduleDefs + 1] = newDef
		end
	end
end

do
	local i=1
	while(i<=#moduleDefs)do
		local md=moduleDefs[i]
		if(md.hardcodedID and i~=md.hardcodedID) then
			local b=md.hardcodedID
			local mdb=moduleDefs[b]
			if mdb.hardcodedID and mdb.hardcodedID==b then
				error("Both " .. md.name .. " and " .. mdb.name .. " has same hardcodedID " .. b)
			end
			moduleDefs[i],moduleDefs[b]=moduleDefs[b],md
		else
			i=i+1
		end
	end
end

-- Add second versions of basic weapons


--[[ Stochastic check for module IDs,
     not perfect but should do its job.
     See the error message below. ]]
if moduleDefs[ 1].name ~= "nullmodule"
or moduleDefs[ 4].name ~= "nulldualbasicweapon"
or moduleDefs[10].name ~= "commweapon_lparticlebeam"
or moduleDefs[25].name ~= "commweapon_personal_shield"
or moduleDefs[42].name ~= "module_ablative_armor"
or moduleDefs[61].name ~= "commweapon_shotgun_adv" then
	Spring.Echo("MODULE IDs NEED TO STAY CONSTANT BECAUSE AI HARDCODES THEM.\n"
	         .. "SEE https://github.com/ZeroK-RTS/Zero-K/issues/4796 \n"
	         .. "REMEMBER TO CHANGE CircuitAI CONFIG IF MODIFYING THE LIST!")
	Script.Kill()
end

for name, data in pairs(skinDefs) do
	moduleDefs[#moduleDefs + 1] = {
		name = "skin_" .. name,
		humanName = data.humanName,
		description = data.humanName,
		image = moduleImagePath .. "module_ablative_armor.png",
		limit = 1,
		cost = 0,
		requireChassis = {data.chassis},
		requireLevel = 0,
		slotType = "decoration",
		applicationFunction = function (modules, sharedData)
			sharedData.skinOverride = name
		end
	}
end

for i = 1, #moduleDefs do
	local data = moduleDefNamesToIDs[moduleDefs[i].name] or {}
	data[#data + 1] = i
	moduleDefNamesToIDs[moduleDefs[i].name] = data
end

local chassisAllDefs=VFS.Include("gamedata/modularcomms/chassises_all_defs.lua")

local chassisList={}
for _,v in pairs(chassisAllDefs) do
	local k=v.dynamic_comm_defs_name
	moduleDefNames[k] = {}
	chassisList[#chassisList+1]=k
end



for _, moudleName in pairs(forAllChassisModules) do
	moduleDefs[moduleDefNamesToIDs[moudleName][1]].requireChassis=chassisList
end

local function FindModule(moduleName,requireChassis)
	local ids=moduleDefNamesToIDs[moduleName]
	if not ids then
		Spring.Echo("Warning: module " ..moduleName .. " not found")
		return nil
	end
	for _, moduleID in pairs(ids) do
		local moduleDef=moduleDefs[moduleID]
		if not requireChassis then
			return moduleDef
		else
			local foundAll=true
			for _, requireChassisNeeded in pairs(requireChassis) do
				local found=false
				for _, requireChassisHas in pairs(moduleDef.requireChassis) do
					if requireChassisHas==requireChassisNeeded then
						found=true
						break
					end
				end
				if not found then
					foundAll=false
					break
				end
			end
			if foundAll then
				return moduleDef
			end
		end
	end
	return nil
end

ModularCommDefsShared_.FindModule=FindModule

for _,v in pairs(chassisAllDefs) do
	local moduleIdentities=v.dynamic_comm_defs_modules
	if moduleIdentities then
		for _, moduleIdentity in pairs(moduleIdentities) do
			local moduleDef=FindModule(moduleIdentity.name,moduleIdentity.requireChassis)
			if moduleDef then
				moduleDef.requireChassis[#moduleDef.requireChassis+1] = v.dynamic_comm_defs_name
			else
				Spring.Echo("Warning: module " ..moduleIdentity.name .. " not found")
			end
		end
	end
end

for i = 1, #moduleDefs do
	local data = moduleDefs[i]
	local allowedChassis = moduleDefs[i].requireChassis or chassisList
	for j = 1, #allowedChassis do
		local chassisName=allowedChassis[j]
		local mdn_=moduleDefNames[chassisName]
		if not mdn_ then
			Spring.Echo("Error: dynamic_comm_defs.lua: missing chassis " .. tostring(chassisName) .. " for module " .. tostring(data.name))
			
		else
			mdn_[data.name] = i
		end
		
	end
end

------------------------------------------------------------------------
-- Chassis Definitions
------------------------------------------------------------------------

-- it'd help if there was a name -> chassisDef map you know

--------------------------------------------------------------------------------------
-- Must match staticomms.lua around line 250 (MakeCommanderChassisClones)
--------------------------------------------------------------------------------------
-- A note on personal shield and area shield:
-- The personal shield weapon is replaced by the area shield weapon in moduledefs.lua.
-- Therefore the clonedef with an area shield and no personal shield does not actually
-- have an area shield. This means that the below functions return the correct values,
-- if a commander has a an area shield and a personal shield it should return the
-- clone which was given those modules.





local morphCosts = {
	50,
	100,
	150,
	200,
	250,
}
ModularCommDefsShared_.morphCosts=morphCosts
local morphBuildPower = {
	5,
	7.5,
	10,
	12.5,
	15
}
ModularCommDefsShared_.morphBuildPower=morphBuildPower
local function extraLevelCostFunction(level)
	return level * 50 * COST_MULT
end
ModularCommDefsShared_.extraLevelCostFunction=extraLevelCostFunction

ModularCommDefsShared_.GetCloneModuleString=function (chassis,listOfCloneModules)
	return function (modulesByDefID)
		local res=""
		for key, value in pairs(listOfCloneModules) do
			res=res .. (modulesByDefID[moduleDefNames[chassis][value]] or 0)
		end
		return res
	end
end

do
	
	ModularCommDefsShared_.morphUnitDefFunction=function (name,GetCloneModuleString)
		return function (lv)
			return function (modulesByDefID)
				
				return UnitDefNames[name .. lv .. "_" .. GetCloneModuleString(modulesByDefID)].id
			end
		end
	end
end

local chassisDefs = {
}


for i = 1, #chassisAllDefs do
	local chassisDef = chassisAllDefs[i].dynamic_comm_defs(ModularCommDefsShared_)
	chassisDefs[#chassisDefs+1]=chassisDef
end

local chassisDefByBaseDef = {}
if UnitDefNames then
	for i = 1, #chassisDefs do
		chassisDefByBaseDef[chassisDefs[i].baseUnitDef] = i
	end
end

local chassisDefNames = {}
for i = 1, #chassisDefs do
	chassisDefNames[chassisDefs[i].name] = i
end

------------------------------------------------------------------------
-- Processing
------------------------------------------------------------------------

-- Set cost in module tooltip
for i = 1, #moduleDefs do
	local data = moduleDefs[i]
	if not data.emptyModule then
		if data.cost > 0 then
			data.description = data.description .. "\nCost: " .. data.cost
		else
			data.description = data.description .. "\nCost: Free"
		end
	end
end

-- Transform from human readable format into number indexed format
for i = 1, #moduleDefs do
	local data = moduleDefs[i]
	
	-- Required modules are a list of moduleDefIDs
	if data.requireOneOf then
		local newRequire = {}
		for j = 1, #data.requireOneOf do
			local reqModuleIDs = moduleDefNamesToIDs[data.requireOneOf[j]]
			if reqModuleIDs then
				for i = 1, #reqModuleIDs do
					newRequire[#newRequire + 1] = reqModuleIDs[i]
				end
			end
		end
		data.requireOneOf = newRequire
	end
	
	-- Prohibiting modules are a list of moduleDefIDs too
	if data.prohibitingModules then
		local newProhibit = {}
		for j = 1, #data.prohibitingModules do
			local reqModuleIDs = moduleDefNamesToIDs[data.prohibitingModules[j]]
			if reqModuleIDs then
				for i = 1, #reqModuleIDs do
					newProhibit[#newProhibit + 1] = reqModuleIDs[i]
				end
			end
		end
		data.prohibitingModules = newProhibit
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

-- Find empty modules so slots can find their appropriate empty module
local emptyModules = {}
for i = 1, #moduleDefs do
	if moduleDefs[i].emptyModule then
		emptyModules[moduleDefs[i].slotType] = i
	end
end

-- Process slotAllows into a table of keys
for i = 1, #chassisDefs do
	for j = 0, #chassisDefs[i].levelDefs do
		local levelData = chassisDefs[i].levelDefs[j]
		for k = 1, #levelData.upgradeSlots do
			local slotData = levelData.upgradeSlots[k]
			if type(slotData.slotAllows) == "string" then
				slotData.empty = emptyModules[slotData.slotAllows]
				slotData.slotAllows = {[slotData.slotAllows] = true}
			else
				local newSlotAllows = {}
				slotData.empty = emptyModules[slotData.slotAllows[1]]
				for m = 1, #slotData.slotAllows do
					newSlotAllows[slotData.slotAllows[m]] = true
				end
				slotData.slotAllows = newSlotAllows
			end
		end
	end
end

-- Add baseWreckID and baseHeapID
if UnitDefNames then
	for i = 1, #chassisDefs do
		local data = chassisDefs[i]
		local wreckData = FeatureDefNames[UnitDefs[data.baseUnitDef].corpse]

		data.baseWreckID = wreckData.id
		data.baseHeapID = wreckData.deathFeatureID
	end
end

------------------------------------------------------------------------
-- Utility Functions
------------------------------------------------------------------------

local function ModuleIsValid(level, chassis, slotAllows, moduleDefID, alreadyOwned, alreadyOwned2)
	local data = moduleDefs[moduleDefID]
	if (not slotAllows[data.slotType]) or (data.requireLevel or 0) > level or
			(data.requireChassis and (not data.requireChassis[chassis])) or data.unequipable then
		return false
	end
	
	-- Check that requirements are met
	if data.requireOneOf then
		local foundRequirement = false
		for j = 1, #data.requireOneOf do
			-- Modules should not depend on themselves so this check is simplier than the
			-- corresponding chcek in the replacement set generator.
			local reqDefID = data.requireOneOf[j]
			if (alreadyOwned[reqDefID] or (alreadyOwned2 and alreadyOwned2[reqDefID])) then
				foundRequirement = true
				break
			end
		end
		if not foundRequirement then
			return false
		end
	end
	
	-- Check that nothing prohibits this module
	if data.prohibitingModules then
		for j = 1, #data.prohibitingModules do
			-- Modules cannot prohibit themselves otherwise this check makes no sense.
			local probihitDefID = data.prohibitingModules[j]
			if (alreadyOwned[probihitDefID] or (alreadyOwned2 and alreadyOwned2[probihitDefID])) then
				return false
			end
		end
	
	end

	-- cheapass hack to prevent cremcom dual wielding same weapon (not supported atm)
	-- proper solution: make the second instance of a weapon apply projectiles x2 or reloadtime x0.5 and get cremcoms unit script to work with that
	local limit = data.limit
	if chassis == 5 and data.slotType == "basic_weapon" and limit == 2 then
		limit = 1
	end

	-- Check that the module limit is not reached
	if limit and (alreadyOwned[moduleDefID] or (alreadyOwned2 and alreadyOwned2[moduleDefID])) then
		local count = (alreadyOwned[moduleDefID] or 0) + ((alreadyOwned2 and alreadyOwned2[moduleDefID]) or 0)
		if count > limit then
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

local function GetUnitDefShield(unitDefNameOrID, shieldName)
	local unitDefID = (type(unitDefNameOrID) == "string" and UnitDefNames[unitDefNameOrID].id) or unitDefNameOrID
	local wepTable = UnitDefs[unitDefID].weapons
	for num = 1, #wepTable do
		local wd = WeaponDefs[wepTable[num].weaponDef]
		if wd.type == "Shield" then
			local weaponName = string.sub(wd.name, (string.find(wd.name,"commweapon") or 0), 100)
			if weaponName == shieldName then
				return wd.id, num
			end
		end
	end
end

local utilities = {
	ModuleIsValid          = ModuleIsValid,
	ModuleSetsAreIdentical = ModuleSetsAreIdentical,
	ModuleListToByDefID    = ModuleListToByDefID,
	GetUnitDefShield       = GetUnitDefShield
}

------------------------------------------------------------------------
-- Circuit need static module IDs
------------------------------------------------------------------------

if ECHO_MODULES_FOR_CIRCUIT then
	local function SortFunc(a, b)
		return a[2] < b[2]
	end

	for chassis, chassisModules in pairs(moduleDefNames) do
		Spring.Echo("==============================================================")
		Spring.Echo("Modules for", chassis)
		local printList = {}
		for name, chassisDefID in pairs(chassisModules) do
			printList[#printList + 1] = {chassisDefID, name}
		end
		table.sort(printList, SortFunc)
		for i = 1, #printList do
			Spring.Echo(printList[i][1], printList[i][2])
		end
	end
	Spring.Echo("==============================================================")
end

------------------------------------------------------------------------
-- Return Values
------------------------------------------------------------------------

return moduleDefs, chassisDefs, utilities, LEVEL_BOUND, chassisDefByBaseDef, moduleDefNames, chassisDefNames
