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
-- yeah, yeah, n^2
local function RemoveDuplicates(base, delete)
	for i1,v1 in ipairs(base) do
		for i2,v2 in ipairs(delete) do
			if v1 == v2 then
				base[i1] = nil
				break
			end
		end
	end
end

-- gets modules and costs
local function GetCommSeriesInfo(seriesName, purgeDuplicates)
	local data = {}
	local commList = commData[seriesName]
	for i=1,#commList do
		data[i] = {name = commList[i]}
	end
	for i=1,#data do
		data[i].modules = commDataGlobal[data[i].name] and commDataGlobal[data[i].name].modules or {}
		data[i].cost = commDataGlobal[data[i].name] and commDataGlobal[data[i].name].cost or 0
	end
	-- remove reference to modules already in previous levels
	if purgeDuplicates then
		for i = #data, 2, -1 do
			RemoveDuplicates(data[i].modules, data[i-1].modules)
			data[i].cost = data[i].cost - data[i-1].cost
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
		for i,v in ipairs(commDataGlobal[unitDef] and commDataGlobal[unitDef].modules) do
			local modulename = v
			modules[i] = upgrades[modulename].name
		end
		return modules
	end
end
WG.GetCommModules = GetCommModules