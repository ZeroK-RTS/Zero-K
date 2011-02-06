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

for name, config in pairs(commData) do
	if config.chassis and UnitDefs[config.chassis] then
		Spring.Echo("Processing comm: "..name)
		local name = name
		commDefs[name] = CopyTable(UnitDefs[config.chassis])
		if config.modules then
			for _,upgradeName in pairs(config.modules) do
				upgrades[upgradeName].func(commDefs[name])	--apply upgrade function
				Spring.Echo("\tApplying upgrade: "..upgradeName)
			end
		end
		if config.name then
			commDefs[name].name = config.name
		end		
	end
end

--set weapon1 range	- may need exception list in future depending on what weapons we add
--[[
for name, data in pairs(commDefs) do
	Spring.Echo("\tPostprocessing commtype: ".. name)
	if data.weapondefs then
		local minRange = 999999
		for name, weaponData in pairs(data.weapondefs) do
			if weaponData.range < minRange then minRange = weaponData.range end
		end
		if data.weapons and data.weapondefs then
			local wepName = data.weapondefs[1].def
			wepName = string.lower(wepName)
			data.weapondefs[wepName].range = minRange
		end
	end
end
--]]

-- splice back into unitdefs
for name, data in pairs(commDefs) do
	UnitDefs[name] = data
end
