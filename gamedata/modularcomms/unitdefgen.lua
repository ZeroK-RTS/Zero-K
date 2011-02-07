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
--	TODO:
--		Figure out how modstats should handle procedurally generated comms
--			* Teach gadget to treat them as baseline comms
--------------------------------------------------------------------------------
VFS.Include("gamedata/modularcomms/moduledefs.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local commDataRaw = Spring.GetModOptions().commandertypes
local commDataFunc, err, success, commData
if not (commDataRaw and type(commDataRaw) == 'string') then
	err = "Comm data entry in modoption is empty"
	commData = {}
else
	commDataRaw = string.gsub(commDataRaw, '_', '=')
	commDataRaw = Spring.Utilities.Base64Decode(commDataRaw)
	Spring.Echo(commDataRaw)
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
	Spring.Echo('Modular Comms error: ' .. err)
end

if not commData then commData = {} end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
commDefs = {}	--holds precedurally generated comm defs

local function ApplyWeapon(unitDef, weapon)
	local wcp = weapons[weapon].customparams
	local slot = tonumber(wcp and wcp.slot) or 1
	unitDef.weapons[slot] = {
		def = weapon,
		badtargetcategory = wcp.badtargetcategory,
		onlytargetcategory = wcp.onlytargetcategory,
	}
	unitDef.weapondefs[weapon] = CopyTable(weapons[weapon], true)
end

local function ProcessComm(name, config)
	if config.chassis and UnitDefs[config.chassis] then
		Spring.Echo("Processing comm: "..name)
		local name = name
		commDefs[name] = CopyTable(UnitDefs[config.chassis], true)
		local cp = commDefs[name].customparams
		cp.morphCost = cp.morphCost or "0"
		cp.morphTime = cp.moprhTime or "0"
		if config.modules then
			-- process weapons first
			for _,moduleName in pairs(config.modules) do
				if moduleName:find("commweapon_",1,true) then
					if weapons[moduleName] then
						ApplyWeapon(commDefs[name], moduleName)
						Spring.Echo("\tApplying weapon: "..moduleName)
					else
						Spring.Echo("\tERROR: Weapon "..moduleName.." not found")
					end
				end
			end
			-- process other modules
			for _,moduleName in pairs(config.modules) do
				if upgrades[moduleName] then
					upgrades[moduleName].func(commDefs[name])	--apply upgrade function
					Spring.Echo("\tApplying upgrade: "..moduleName)
				else
					Spring.Echo("\tERROR: Upgrade "..moduleName.." not found")
				end
			end
		end
		if config.name then
			commDefs[name].name = config.name
		end		
	end
end

for name, config in pairs(commData) do
	ProcessComm(name, config)
end


--stress test: try every possible module to make sure it doesn't crash
local stressTestDef = {
	chassis = "armcom",
	name = "Quality Assurance",
	modules = {},
}
for name in pairs(upgrades) do
	stressTestDef.modules[#stressTestDef.modules+1] = name
end
ProcessComm("testDef", stressTestDef)
commDefs.testDef = nil


--set weapon1 range	- may need exception list in future depending on what weapons we add
for name, data in pairs(commDefs) do
	Spring.Echo("\tPostprocessing commtype: ".. name)
	if data.weapondefs then
		local minRange = 999999
		for name, weaponData in pairs(data.weapondefs) do
			if weaponData.range < minRange then minRange = weaponData.range end
		end
		if data.weapons and data.weapondefs then
			local wepName = data.weapondefs[1] and data.weapondefs[1].def
			if wepName then
				wepName = string.lower(wepName)
				data.weapondefs[wepName].range = minRange
			end
		end
	end
end



-- splice back into unitdefs
for name, data in pairs(commDefs) do
	UnitDefs[name] = data
end
