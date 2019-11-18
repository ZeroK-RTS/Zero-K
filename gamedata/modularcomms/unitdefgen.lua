--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    unitdefgen.lua
--  brief:   procedural generation of unitdefs for modular comms
--  author:  KingRaptor (L.J. Lim)
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Spring.Utilities = Spring.Utilities or {}
VFS.Include("LuaRules/Utilities/base64.lua")

Spring.Log = Spring.Log or function() end
--------------------------------------------------------------------------------
--	HOW IT WORKS:
--	First, it makes unitdefs as specified by the decoded modoption string, one for each unique comm type.
--		The unitdefs are named: <name>
--	It then modifies each unitdef based on the upgrades selected for that comm type.
--	Upgrade types are defined in gamedata/modularcomms/moduledefs.lua.
--
--	Comms are later assigned to players in start_unit_setup.lua.
--
--------------------------------------------------------------------------------
--	PROPOSED SPECS FOR TEMPLATE UNITDEFS
--	Weapon 1: fake laser
--	Weapon 2: area shield
--	Weapon 3: special weapon (uses CEG 3 and 4)
--	Weapon 4: personal shield
--	Weapon 5: main weapon (uses CEG 1 and 2)
--	Weapon 6: unused
--------------------------------------------------------------------------------

VFS.Include("gamedata/modularcomms/moduledefs.lua")

VFS.Include("gamedata/modularcomms/dyncomm_chassis_generator.lua")
VFS.Include("gamedata/modularcomms/clonedefs.lua")

local legacyTranslators = VFS.Include("gamedata/modularcomms/legacySiteDataTranslate.lua")
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- for examples see testdata.lua

local modOptions = (Spring and Spring.GetModOptions and Spring.GetModOptions()) or {}
local commData

local function DecodeBase64CommData(toDecode, useLegacyTranslator)
	local commDataTable
	local commDataFunc
	local err, success
	
	if not (toDecode and type(toDecode) == 'string') then
		err = "Attempt to decode empty or invalid comm data"
		return {}
	end
	
	toDecode = string.gsub(toDecode, '_', '=')
	toDecode = Spring.Utilities.Base64Decode(toDecode)
	--Spring.Echo(toDecode)
	commDataFunc, err = loadstring("return "..toDecode)
	if commDataFunc then
		success, commDataTable = pcall(commDataFunc)
		if not success then	-- execute Borat
			err = commDataTable
			commDataTable = {}
		elseif useLegacyTranslator then
			commDataTable = legacyTranslators.FixOverheadIcon(commDataTable)
		end
	else
		commDataTable = {}
	end
	if err then
		Spring.Log("gamedata/modularcomms/unitdefgen.lua", "warning", 'Modular Comms warning: ' .. err)
	end
	return commDataTable
end

do
	commData = DecodeBase64CommData(modOptions.commandertypes, true)
	local commDataPredefined = VFS.Include("gamedata/modularcomms/dyncomms_predefined.lua")
	commData = MergeTable(commData, commDataPredefined)
end

for commProfileID, commProfile in pairs(commData) do
	-- MAKE SURE THIS MATCHES api_modularcomms
	commProfile.baseUnitName = commProfileID .. "_base"
end

local legacyToDyncommChassisMap = legacyTranslators.legacyToDyncommChassisMap

local function GenerateLevel0DyncommsAndWrecks()
	for commProfileID, commProfile in pairs(commData) do
		Spring.Log("gamedata/modularcomms/unitdefgen.lua", "debug", "\tModularComms: Generating base dyncomm for " .. commProfile.name)
		local unitName = commProfile.baseUnitName
		
		local chassis = commProfile.chassis
		local mappedChassis = legacyToDyncommChassisMap[chassis] or "assault"
		if mappedChassis then
			chassis = mappedChassis
		end
		
		UnitDefs[unitName] = CopyTable(UnitDefs["dyn" .. chassis .. "1"], true)
		local ud = UnitDefs[unitName]
		ud.name = commProfile.name
		if commProfile.notStarter then
			ud.customparams = ud.customparams or {}
			ud.customparams.not_starter = 1
		end
		
		local features = ud.featuredefs or {}
		for featureName,array in pairs(features) do
			local mult = 0.4
			local typeName = "Wreckage"
			if featureName == "heap" then
				typeName = "Debris"
				mult = 0.2
			end
			array.description = typeName .. " - " .. commProfile.name
			array.customparams = array.customparams or {}
			array.customparams.unit = unitName
		end
		ud.featuredefs = features
	end
end

GenerateLevel0DyncommsAndWrecks()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- recursive magic (likely broken)
local function MergeModuleTables(moduleTable, previous)
	local data = commData[previous]
	if data then
		if data.prev then
			MergeModuleTables(moduleTable, data.prev)
		end
		local modules = data.modules or {}
		for i=1,#modules do
			moduleTable[#moduleTable+1] = modules[i]
		end
	end
	
	return moduleTable
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

commDefs = {}	--holds precedurally generated comm defs

local function ProcessComm(name, config)
	if config.chassis and UnitDefs[config.chassis] then
		Spring.Log("gamedata/modularcomms/unitdefgen.lua", "debug", "\tModularComms: Processing comm: " .. name)
		commDefs[name] = CopyTable(UnitDefs[config.chassis], true)
		commDefs[name].customparams = commDefs[name].customparams or {}
		local cp = commDefs[name].customparams
		
		-- set name
		commDefs[name].unitname = name
		if config.name then
			commDefs[name].name = config.name
		end
		if config.description then
			commDefs[name].description = config.description
		end
		
		-- store base values
		cp.basespeed = tostring(commDefs[name].maxvelocity)
		cp.basehp = tostring(commDefs[name].maxdamage)
		for i,v in pairs(commDefs[name].weapondefs or {}) do
			v.customparams = v.customparams or {}
			v.customparams.rangemod = 0
			v.customparams.reloadmod = 0
			v.customparams.damagemod = 0
		end

		local attributeMods = { -- add a mod for everythings that can have a negative adjustment
			health = 0,
			speed = 0,
			reload = 0,
		}
		
		-- process modules
		if config.modules then
			local modules = CopyTable(config.modules)
			local numWeapons = 0
			if config.prev then
				modules = MergeModuleTables(modules, config.prev)
			end
			-- sort: weapons first, weapon mods next, regular modules last
			-- individual modules can have different order values as defined in moduledefs.lua
			table.sort(modules,
				function(a,b)
					local order_a = (upgrades[a] and upgrades[a].order) or 4
					local order_b = (upgrades[b] and upgrades[b].order) or 4
					return order_a < order_b
				end )

			-- process all modules (including weapons)
			for _,moduleName in ipairs(modules) do
				if moduleName:find("commweapon_",1,true) then
					if weapons[moduleName] then
						--Spring.Echo("\tApplying weapon: "..moduleName)
						ApplyWeapon(commDefs[name], moduleName)
						numWeapons = numWeapons + 1
					else
						Spring.Echo("\tERROR: Weapon "..moduleName.." not found")
					end
				end
				if upgrades[moduleName] then
					--Spring.Echo("\tApplying upgrade: "..moduleName)
					if upgrades[moduleName].func then --apply upgrade function
						upgrades[moduleName].func(commDefs[name], attributeMods)
					end
					if upgrades[moduleName].useWeaponSlot then
						numWeapons = numWeapons + 1
					end
				else
					Spring.Log("gamedata/modularcomms/unitdefgen.lua", "error", "\tERROR: Upgrade "..moduleName.." not found")
				end
			end
			
			cp.modules = config.modules
		end
		
		-- apply attributemods
		if attributeMods.speed > 0 then
			commDefs[name].maxvelocity = commDefs[name].maxvelocity*(1+attributeMods.speed)
		else
			commDefs[name].maxvelocity = commDefs[name].maxvelocity*(1+attributeMods.speed)
			--commDefs[name].maxvelocity = commDefs[name].maxvelocity/(1-attributeMods.speed)
		end
		commDefs[name].maxdamage = commDefs[name].maxdamage*(1+attributeMods.health)
		
		-- set costs
		config.cost = config.cost or 0
		-- a bit less of a hack
		local commDefsCost = math.max(commDefs[name].buildcostmetal or 0, commDefs[name].buildcostenergy or 0, commDefs[name].buildtime or 0)  --one of these should be set in actual unitdef file
		commDefs[name].buildcostmetal = commDefsCost + config.cost
		commDefs[name].buildcostenergy = commDefsCost + config.cost
		commDefs[name].buildtime = commDefsCost + config.cost
		cp.cost = config.cost
		
		if config.power then
			commDefs[name].power = config.power
		end
		
		-- morph
		if config.morphto then
			cp.morphto = config.morphto
			cp.combatmorph = 1
		end
		
		-- apply decorations
		if config.decorations then
			for key,dec in pairs(config.decorations) do
				local decName = dec
				if type(dec) == "table" then
					decName = dec.name or key
				elseif type(dec) == "bool" then
					decName = key
				end
				
				if decorations[decName] then
					if decorations[decName].func then --apply upgrade function
						decorations[decName].func(commDefs[name], config)
					end
				else
					Spring.Log("gamedata/modularcomms/unitdefgen.lua", "warning", "\tDecoration "..decName.." not found")
				end
			end
		end
		
		-- apply misc. defs
		if config.miscDefs then
			commDefs[name] = MergeTable(config.miscDefs, commDefs[name], true)
		end
	end
end

--stress test: try every possible module to make sure it doesn't crash
local stressDefs = {}
local stressChassis = {
	"armcom3", "corcom3", "commrecon3", "commsupport3"
}
local stressTemplate = {
	name = "st",
	modules = {},
}
for name in pairs(upgrades) do
	stressTemplate.modules[#stressTemplate.modules+1] = name
end
for index,name in ipairs(stressChassis) do
	local def = CopyTable(stressTemplate, true)
	def.chassis = name
	def.name = def.name..name
	ProcessComm("stresstest"..index, def)
	stressDefs["stresstest"..index] = true
end

-- for easy testing; creates test commanders with specific loadouts
local testDef = VFS.Include("gamedata/modularcomms/testdata.lua")
for i = 1, testDef.count do
	ProcessComm(testDef[i].name, testDef[i])
end

-- for use by AI, in missions, etc.
local staticComms = VFS.Include("gamedata/modularcomms/staticcomms.lua")
local staticComms2 = VFS.Include("gamedata/modularcomms/staticcomms_mission.lua")
local staticComms3 = DecodeBase64CommData(modOptions.campaign_commanders)

local staticCommsMerged = MergeTable(staticComms2, staticComms, true)
staticCommsMerged = MergeTable(staticCommsMerged, staticComms3, true)

for name,data in pairs(staticCommsMerged) do
	ProcessComm(name, data)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- postprocessing
-- add cloned template comms to processing list
for name, data in pairs(UnitDefs) do
	if data.customparams.commtype then
		commDefs[name] = data
	end
end

for name, data in pairs(commDefs) do
	--Spring.Echo("\tPostprocessing commtype: ".. name)
	
	-- apply intrinsic bonuses
	local damBonus = data.customparams.damagebonus or 0
	ModifyWeaponDamage(data, damBonus, true)
	
	local rangeBonus =  data.customparams.rangebonus or 0
	ModifyWeaponRange(data, rangeBonus, true)

	if data.customparams.speedbonus then
		commDefs[name].customparams.basespeed = commDefs[name].customparams.basespeed or commDefs[name].maxvelocity
		commDefs[name].maxvelocity = commDefs[name].maxvelocity + (commDefs[name].customparams.basespeed*data.customparams.speedbonus)
	end
	
	-- calc lightning real damage based on para damage
	-- TODO: use for slow-beams
	if data.weapondefs then
		for wName, weaponData in pairs(data.weapondefs) do
			if (weaponData.customparams or {}).extra_damage_mult then
				weaponData.customparams.extra_damage = weaponData.customparams.extra_damage_mult * weaponData.damage.default
				weaponData.customparams.extra_damage_mult = nil
			end
		end
	end
	
	-- set weapon1 range	- may need exception list in future depending on what weapons we add
	if data.weapondefs and not data.customparams.dynamic_comm then
		local maxRange = 0
		local weaponRanges = {}
		local weaponNames = {}
		-- first check if the comm is actually using the weapon
		if data.weapons then
			for index, weaponData in pairs(data.weapons) do
				weaponNames[string.lower(weaponData.def)] = true
			end
		end
		for wName, weaponData in pairs(data.weapondefs) do
			if weaponNames[wName] and not (string.lower(weaponData.name):find('fake')) and not weaponData.commandfire then
				if (weaponData.range or 0) > maxRange then
					maxRange = weaponData.range
				end
				weaponRanges[wName] = weaponData.range
			end
		end
		-- lame-ass hack, because the obvious methods don't work
		for wName, weaponData in pairs(data.weapondefs) do
			if string.lower(weaponData.name):find('fake') then
				weaponData.range = maxRange
			end
		end
		for wName, range in pairs(weaponRanges) do -- only works for 2 weapons max
			if maxRange ~= range then
				data.customparams.extradrawrange = range
			end
		end
		data.sightdistance = math.max(math.min(maxRange * 1.1, 600), data.sightdistance)
	end
	
	-- set wreck values
	for featureName,array in pairs(data.featuredefs or {}) do
		local mult = 0.4
		local typeName = "Wreckage"
		if featureName == "heap" then
			typeName = "Debris"
			mult = 0.2
		end
		array.description = typeName .. " - " .. data.name
		array.metal = data.buildcostmetal * mult
		array.reclaimtime = data.buildcostmetal * mult
		array.damage = data.maxdamage
		array.customparams = {}
		array.customparams.unit = data.unitname
	end
	
	-- rez speed
	if data.canresurrect then
		data.resurrectspeed = data.workertime*0.5
	end
	
	-- make sure weapons can hit their max range
	if data.weapondefs then
		for weaponName, weaponData in pairs(data.weapondefs) do
			if weaponData.weapontype == "MissileLauncher" then
				weaponData.flighttime = math.max(weaponData.flighttime or 3, 1.2 * weaponData.range/weaponData.weaponvelocity)
			elseif weaponData.weapontype == "Cannon" then
				weaponData.weaponvelocity = math.max(weaponData.weaponvelocity, math.sqrt(weaponData.range * (weaponData.mygravity or 0.14)*1000))
			end
		end
	end

	-- set morph time
	if data.customparams.morphto then
		local morph_time = (commDefs[data.customparams.morphto].buildtime - data.buildtime) / (5 * (data.customparams.level + 2))
		data.customparams.morphtime = tostring(math.floor(morph_time))
	end
end

-- remove stress test defs
for key,_ in pairs(stressDefs) do
	commDefs[key] = nil
end

-- splice back into unitdefs
for name, data in pairs(commDefs) do
	UnitDefs[name] = data
end
