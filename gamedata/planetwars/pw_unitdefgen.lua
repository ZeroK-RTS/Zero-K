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


local structureConfig = VFS.Include("gamedata/planetwars/pw_structuredefs.lua")

local ALLOW_SERVER_OVERRIDE_UNIT_TEXT = false
local LOAD_ALL_STRUCTURES = true

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local modOptions = (Spring and Spring.GetModOptions and Spring.GetModOptions()) or {}
local pwDataRaw = modOptions.planetwarsstructures
local pwDataFunc, err, success, unitData

if not (pwDataRaw and type(pwDataRaw) == 'string') then
	unitData = {}
else
	pwDataRaw = string.gsub(pwDataRaw, '_', '=')
	pwDataRaw = Spring.Utilities.Base64Decode(pwDataRaw)
	pwDataRaw = pwDataRaw:gsub("True", "true")
	pwDataRaw = pwDataRaw:gsub("False", "false")
	pwDataFunc, err = loadstring("return "..pwDataRaw)
	if pwDataFunc then
		success, unitData = pcall(pwDataFunc)
		if not success then	-- execute Borat
			err = unitData
			unitData = {}
		end
	end
end
if err then
	Spring.Log("gamedata/modularcomms/unitdefgen.lua", "warning", 'Planetwars warning: ' .. err)
end

if not unitData then
	unitData = {}
end

--unitData = CopyTable(structureConfig, true)
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local structureDefs = {} --holds precedurally generated structure defs
local genericStructure = UnitDefs["pw_generic"]

local function makeTechStructure(def, name)
	local techName = string.sub(name,4)
	techName = UnitDefs[techName]
	if techName then
		def.name = techName.name .. " Technology Facility"
		def.description = "Gives planet owner the ability to construct " .. techName.name
	end
	structureConfig["generic_tech"](def)
end

local function commonDefs(def)
	local fd = def.featuredefs.dead
	fd.collisionvolumetype = fd.collisionvolumetype or def.collisionvolumetype
	fd.collisionvolumescales = fd.collisionvolumescales or def.collisionvolumescales
	def.customparams.planetwars = 1
end

--for name in pairs(unitData) do
for _, info in pairs(unitData) do
	if type(info) == "table" and info.isDestroyed ~= 1 then
		structureDefs[info.unitname] = CopyTable(genericStructure, true)
		structureDefs[info.unitname].customparams = structureDefs[info.unitname].customparams or {}
		if structureConfig[info.unitname] then
			structureConfig[info.unitname](structureDefs[info.unitname])
			structureDefs[info.unitname].unitname = info.unitname
		else
			makeTechStructure(structureDefs[info.unitname], info.unitname)
			structureDefs[info.unitname].unitname = info.unitname
		end
		if ALLOW_SERVER_OVERRIDE_UNIT_TEXT then
			structureDefs[info.unitname].name = info.name
			structureDefs[info.unitname].description = info.description
		end
		structureDefs[info.unitname].customparams.canbeevacuated = info.canBeEvacuated
	end
end

if LOAD_ALL_STRUCTURES then
	for name, structureFunction in pairs(structureConfig) do
		if not structureDefs[name] then
			structureDefs[name] = CopyTable(genericStructure, true)
			structureFunction(structureDefs[name]) -- Yay side effects! >:-/
		end
	end
end

for name, data in pairs(structureDefs) do
	commonDefs(data)
end

-- splice back into unitdefs
for name, data in pairs(structureDefs) do
	UnitDefs[name] = data
end
