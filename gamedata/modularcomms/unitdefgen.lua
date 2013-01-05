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

VFS.Include("gamedata/modularcomms/clonedefs.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

VFS.Include("gamedata/modularcomms/moduledefs.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- for examples see testdata.lua

local modOptions = (Spring and Spring.GetModOptions and Spring.GetModOptions()) or {}
local err, success

local commDataRaw = modOptions.commandertypes
local commDataFunc, commData

if not (commDataRaw and type(commDataRaw) == 'string') then
	err = "Comm data entry in modoption is empty or in invalid format"
	commData = {}
else
	commDataRaw = string.gsub(commDataRaw, '_', '=')
	commDataRaw = Spring.Utilities.Base64Decode(commDataRaw)
	--Spring.Echo(commDataRaw)
	commDataFunc, err = loadstring("return "..commDataRaw)
	if commDataFunc then
		success, commData = pcall(commDataFunc)
		if not success then	-- execute Borat
			err = commData
			commData = {}
		end
	end
end
if err then 
	Spring.Log("gamedata/modularcomms/unitdefgen.lua", "warning", 'Modular Comms warning: ' .. err)
end

if not commData then commData = {} end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- generate the baseline comm
-- identical to SP strike comm except it costs 1250

local function GenerateBasicComm()
	UnitDefs.commbasic = CopyTable(UnitDefs.armcom1, true)
	local def = UnitDefs.commbasic
	def.unitname = "commbasic"
	def.name = "Commander Junior"
	def.description = "Basic Commander, Builds at 10 m/s"
	def.buildcostmetal = 1250
	def.buildcostenergy = 1250
	def.buildtime = 1250
	
	def.customparams.helptext = "The Commander Junior is a basic version of the popular Strike Commander platform, issued to new commanders. "
			            .."While lacking the glory of its customizable brethren, the Commander Jr. remains an effective tool with full base-building and combat capabilites."
	
	for featureName,array in pairs(def.featuredefs) do
		local mult = 0.4
		local typeName = "Wreckage"
		if featureName == "heap" then
			typeName = "Debris"
			mult = 0.2 
		end
		array.description = typeName .. " - Commander Junior"
		array.metal = 1250 * mult
		array.reclaimtime = 1250 * mult
	end
end

GenerateBasicComm()

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
		Spring.Echo("Processing comm: "..name)
		local name = name
		commDefs[name] = CopyTable(UnitDefs[config.chassis], true)
		commDefs[name].customparams = commDefs[name].customparams or {}
		local cp = commDefs[name].customparams
		
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
		
		RemoveWeapons(commDefs[name])
		
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
					Spring.Log("gamedata/modularcomms/unitdefgen.lua", LOG.ERROR, "\tERROR: Upgrade "..moduleName.." not found")
				end
			end
		end
		
		-- apply attributemods
		if attributeMods.speed > 0 then
			commDefs[name].maxvelocity = commDefs[name].maxvelocity*(1+attributeMods.speed)
		else
			commDefs[name].maxvelocity = commDefs[name].maxvelocity*(1+attributeMods.speed)
			--commDefs[name].maxvelocity = commDefs[name].maxvelocity/(1-attributeMods.speed)
		end
		commDefs[name].maxdamage = commDefs[name].maxdamage*(1+attributeMods.health)
		
		if config.name then
			commDefs[name].name = config.name
		end
		if config.description then
			commDefs[name].description = config.description
		end
		if config.helptext then
			commDefs[name].customparams.helptext = config.helptext
		end
		
		-- set name
		commDefs[name].unitname = name
		
		-- set costs
		config.cost = config.cost or 0
		commDefs[name].buildcostmetal = commDefs[name].buildcostmetal + config.cost
		commDefs[name].buildcostenergy = commDefs[name].buildcostenergy + config.cost
		commDefs[name].buildtime = commDefs[name].buildtime + config.cost
		
		-- apply decorations
		if config.decorations then
			for key,dec in pairs(config.decorations) do
				local decName = dec
				if type(dec) == "table" then
					decName = dec.name or key
				end
				
				if decorations[decName] then
					if decorations[decName].func then --apply upgrade function
						decorations[decName].func(commDefs[name], config) 
					end
				else
					Spring.Log("gamedata/modularcomms/unitdefgen.lua", "error", "\tERROR: Decoration "..decName.." not found")
				end
			end
		end		
	end
end

for name, config in pairs(commData) do
	ProcessComm(name, config)
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
for index,name in pairs(stressChassis) do
	local def = stressTemplate
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
for name,data in pairs(staticComms) do
	ProcessComm(name, data)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- postprocessing
for name, data in pairs(commDefs) do
	--Spring.Echo("\tPostprocessing commtype: ".. name)
	
	-- apply intrinsic bonuses
	local damBonus = data.customparams.damagebonus or 0
	ModifyWeaponDamage(data, damBonus, true)
	local rangeBonus =  data.customparams.rangebonus or 0
	ModifyWeaponRange(data, rangeBonus, true)

	if data.customparams.speedbonus then
		commDefs[name].maxvelocity = commDefs[name].maxvelocity + (commDefs[name].customparams.basespeed*data.customparams.speedbonus)
	end
	
	-- calc lightning real damage based on para damage
	-- TODO: use for slow-beams
	if data.weapondefs then
		for name, weaponData in pairs(data.weapondefs) do
			if weaponData.customparams.extra_damage_mult then
				weaponData.customparams.extra_damage = weaponData.customparams.extra_damage_mult * weaponData.damage.default
				weaponData.customparams.extra_damage_mult = nil
			end
		end
	end	
	
	-- set weapon1 range	- may need exception list in future depending on what weapons we add
	if data.weapondefs then
		local maxRange = 0
		local weaponRanges = {}
		local weaponNames = {}
		local wep1Name
		-- first check if the comm is actually using the weapon
		if data.weapons then
			for index, weaponData in pairs(data.weapons) do
				weaponNames[string.lower(weaponData.def)] = true
			end
		end
		for name, weaponData in pairs(data.weapondefs) do
			if weaponNames[name] and not (string.lower(weaponData.name):find('fake')) and not weaponData.commandfire then
				if (weaponData.range or 0) > maxRange then
					maxRange = weaponData.range 
				end
				weaponRanges[name] = weaponData.range 
			end
		end
		-- lame-ass hack, because the obvious methods don't work
		for name, weaponData in pairs(data.weapondefs) do
			if string.lower(weaponData.name):find('fake') then
				weaponData.range = maxRange
			end
		end
		for name, range in pairs(weaponRanges) do -- only works for 2 weapons max
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
	
	-- set mass
	data.mass = ((data.buildtime/2 + data.maxdamage/10)^0.55)*9
	--Spring.Echo("mass " .. (data.mass or "nil") .. " BT/HP " .. (data.buildtime or "nil") .. "  " .. (data.maxdamage or "nil"))
	
	-- rez speed
	if data.canresurrect then 
		data.resurrectspeed = data.workertime*0.8
	end
	
	-- make sure weapons can hit their max range
	if data.weapondefs then
		for name, weaponData in pairs(data.weapondefs) do
			if weaponData.weapontype == "MissileLauncher" then
				weaponData.flighttime = math.max(weaponData.flighttime or 3, 1.2 * weaponData.range/weaponData.weaponvelocity)
			elseif weaponData.weapontype == "Cannon" then
				weaponData.weaponvelocity = math.max(weaponData.weaponvelocity, math.sqrt(weaponData.range * (weaponData.mygravity or 0.14)*1000))
			end
		end
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
