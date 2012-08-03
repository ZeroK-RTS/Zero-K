--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Modular Comm Info",
    desc      = "Helper widget that provides info on modular comms.",
    author    = "KingRaptor",
    date      = "2011",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    api       = true,
    enabled   = true,
	alwaysStart = true,
  }
end

Spring.Utilities = Spring.Utilities or {}
VFS.Include("LuaRules/Utilities/base64.lua")
VFS.Include("LuaRules/Utilities/tablefunctions.lua")

local CopyTable = Spring.Utilities.CopyTable

--------------------------------------------------------------------------------
-- load data
--------------------------------------------------------------------------------
local success, err

-- global comm data (from the modoption)
local commDataGlobal
local commDataGlobalRaw = Spring.GetModOptions().commandertypes
if not (commDataGlobalRaw and type(commDataGlobalRaw) == 'string') then
	err = "Comm data entry in modoption is empty or in invalid format"
	commDataGlobal = {}
else
	commDataGlobalRaw = string.gsub(commDataGlobalRaw, '_', '=')
	commDataGlobalRaw = Spring.Utilities.Base64Decode(commDataGlobalRaw)
	--Spring.Echo(commDataRaw)
	local commDataGlobalFunc, err = loadstring("return "..commDataGlobalRaw)
	if commDataGlobalFunc then 
		success, commDataGlobal = pcall(commDataGlobalFunc)
		if not success then
			err = commDataGlobal
			commDataGlobal = {}
		end
	end
end

if err then 
	--Spring.Echo('Modular Comm Info error: ' .. err)	-- unitdefgen will already baww about it; no need to do it here
end
WG.commDataGlobal = commDataGlobal

-- player comm data (from customkeys)
local myID = Spring.GetMyPlayerID()
local commData
local customKeys = select(10, Spring.GetPlayerInfo(myID))
local commDataRaw = customKeys and customKeys.commanders
if not (commDataRaw and type(commDataRaw) == 'string') then
	err = "Your comm data entry is empty or in invalid format"
	commData = {}
else
	commDataRaw = string.gsub(commDataRaw, '_', '=')
	commDataRaw = Spring.Utilities.Base64Decode(commDataRaw)
	--Spring.Echo(commDataRaw)
	local commDataFunc, err = loadstring("return "..commDataRaw)
	if commDataFunc then 
		success, commData = pcall(commDataFunc)
		if not success then
			err = commData
			commData = {}
		end
	end
end

if err then 
	--Spring.Echo('Modular Comm Info error: ' .. err)	-- ditto, except it's start_unit_setup that complained before
end
WG.commData = commData

VFS.Include("gamedata/modularcomms/moduledefs.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function RemoveDuplicates(base, delete)
	local count = {}
	for i=1,#delete do
		local v = delete[i]
		count[v] = (count[v] or 0) + 1
	end	
	for i=1, #base do
		local v = base[i]
		if count[v] and count[v] > 0 then
			base[i] = nil
			count[v] = count[v] - 1
		end
	end
end

-- recursive magic (likely broken)
local function MergeModuleTables(moduleTable, previous)
	local data = commDataGlobal[previous]
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

-- gets modules and costs
local function GetCommSeriesInfo(seriesName, purgeDuplicates)
	local data = {}
	local commList = commData[seriesName]
	for i=1,#commList do
		data[i] = {name = commList[i]}
	end
	for i=1,#data do
		local name = data[i].name
		if name and commDataGlobal[name] then
			local moduleTable = commDataGlobal[name].modules or {}
			data[i].modules = CopyTable(moduleTable, true)
			data[i].cost = commDataGlobal[name].cost or 0
			data[i].prev = commDataGlobal[name].prev
		end
	end
	-- remove reference to modules already in previous levels
	if purgeDuplicates then
		for i = #data, 2, -1 do
			if not data[i].prev then	-- having a previous comm specified indicates we are using per-level module tables instead of lifetime; no need to purge duplicates
				RemoveDuplicates(data[i].modules, data[i-1].modules)
				data[i].cost = data[i].cost - data[i-1].cost
			end
		end
	end
	return data
end
WG.GetCommSeriesInfo = GetCommSeriesInfo

local function GetCommUnitInfo(unitDef)
	if type(unitDef) == "number" then unitDef = UnitDefs[unitDef].name end
	if commDataGlobal[unitDef] then
		return commDataGlobal[unitDef]
	end
end
WG.GetCommUnitInfo = GetCommUnitInfo

local function GetCommUpgradeList()
	return upgrades
end
WG.GetCommUpgradeList = GetCommUpgradeList

local function GetCommModules(unitDef)
	if type(unitDef) == "number" then unitDef = UnitDefs[unitDef].name end
	if commDataGlobal[unitDef] then
		local modules = {}
		local modulesInternal = commDataGlobal[unitDef] and commDataGlobal[unitDef].modules or {}
		if commDataGlobal[unitDef].prev then
			local copy = CopyTable(modulesInternal)
			modulesInternal = MergeModuleTables(copy, commDataGlobal[unitDef].prev)
		end
		table.sort(modulesInternal,
				function(a,b)
					return (a:find("commweapon_") and not b:find("commweapon_"))
					or (a:find("conversion_") and not (b:find("commweapon_") or b:find("conversion_")) )
					or (a:find("weaponmod_") and b:find("module_")) 
				end )
		for i=1, #modulesInternal do
			local modulename = modulesInternal[i]
			modules[i] = upgrades[modulename].name
		end
		return modules
	end
end
WG.GetCommModules = GetCommModules