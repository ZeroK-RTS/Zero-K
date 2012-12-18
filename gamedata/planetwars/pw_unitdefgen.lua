--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    pw_unitdefgen.lua
--  brief:   procedural generation of unitdefs for planetwars
--  author:  GoogleFrog
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Spring.Utilities = Spring.Utilities or {}
VFS.Include("LuaRules/Utilities/base64.lua")
--------------------------------------------------------------------------------
--	Produces the required planetwars structures for a given game from a generic
--  unit. The alternative is a few dozen extra unitdefs of bloat.
--------------------------------------------------------------------------------


VFS.Include("gamedata/planetwars/pw_structuredefs.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local modOptions = (Spring and Spring.GetModOptions and Spring.GetModOptions()) or {}
local pwDataRaw = modOptions.planetwarsstructures
local pwDataFunc, err, success, unitData

pwDataRaw = pwDataRaw or TEST_DEF_STRING

if not (pwDataRaw and type(pwDataRaw) == 'string') then
	err = "Planetwars data entry in modoption is empty or in invalid format"
	unitData = {}
else
	pwDataRaw = string.gsub(pwDataRaw, '_', '=')
	pwDataRaw = Spring.Utilities.Base64Decode(pwDataRaw)
	pwDataFunc, err = loadstring("return "..pwDataRaw)
	if pwDataFunc then
		success, unitData = pcall(pwDataFunc)
		if not success then	-- execute Borat
			err = pwData
			unitData = {}
		end
	end
end
if err then 
	Spring.Log("gamedata/modularcomms/unitdefgen.lua", LOG.WARNING, 'Planetwars warning: ' .. err)
end

if not unitData then 
	unitData = {}
end

--unitData = CopyTable(structureConfig, true)
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
structureDefs = {}	--holds precedurally generated structure defs
genericStructure = UnitDefs["pw_generic"]

local function makeTechStructure(def, name)
	local techName = string.sub(name,4)
	techName = UnitDefs[techName]
	if techName then
		def.name = techName.name .. " Technology Facility"
		def.description = "Gives planet owner the ability to construct " .. techName.name 
		structureConfig["generic_tech"](def)
	end
end

--for name in pairs(unitData) do
for _, info in pairs(unitData) do
	if type(info) == "table" and info.isDestroyed ~= 1 then 
		structureDefs[info.unitname] = CopyTable(genericStructure, true)
		structureDefs[info.unitname].customparams = structureDefs[info.unitname].customparams or {}
		Spring.Echo(info.unitname)
		if structureConfig[info.unitname] then
			structureConfig[info.unitname](structureDefs[info.unitname])
			structureDefs[info.unitname].unitname = info.unitname
		else
			makeTechStructure(structureDefs[info.unitname], info.unitname)
			structureDefs[info.unitname].unitname = info.unitname
		end
		structureDefs[info.unitname].name = info.name
		structureDefs[info.unitname].description = info.description
		
		structureDefs[info.unitname].buildcostmetal = structureDefs[info.unitname].maxdamage
		structureDefs[info.unitname].buildcostenergy = structureDefs[info.unitname].maxdamage
		structureDefs[info.unitname].buildtime = structureDefs[info.unitname].maxdamage
	end 
end

-- splice back into unitdefs
for name, data in pairs(structureDefs) do
	UnitDefs[name] = data
end
