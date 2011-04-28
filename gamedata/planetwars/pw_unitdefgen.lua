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
local pwDataRaw = modOptions.pwstructures
local pwDataFunc, err, success, unitData

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
	Spring.Echo('Planetwars error: ' .. err)
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
		def.description = "Gives the owner the ability to construct " .. techName.name 
		structureConfig["generic_tech"](def)
	end
end

--for name in pairs(unitData) do
for _, name in pairs(unitData) do
	structureDefs[name] = CopyTable(genericStructure, true)
	structureDefs[name].customparams = structureDefs[name].customparams or {}
	Spring.Echo(name)
	if structureConfig[name] then
		structureConfig[name](structureDefs[name])
		structureDefs[name].unitname = name
	else
		makeTechStructure(structureDefs[name], name)
		structureDefs[name].unitname = name
	end
	
	structureDefs[name].buildcostmetal = structureDefs[name].maxdamage
	structureDefs[name].buildcostenergy = structureDefs[name].maxdamage
	structureDefs[name].buildtime = structureDefs[name].maxdamage
end

-- splice back into unitdefs
for name, data in pairs(structureDefs) do
	UnitDefs[name] = data
end
