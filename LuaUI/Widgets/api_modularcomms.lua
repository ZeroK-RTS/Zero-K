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
		--alwaysStart = true,
	}
end

Spring.Utilities = Spring.Utilities or {}
VFS.Include("LuaRules/Utilities/base64.lua")
VFS.Include("LuaRules/Utilities/tablefunctions.lua")
local CopyTable = Spring.Utilities.CopyTable

--------------------------------------------------------------------------------
-- load data
--------------------------------------------------------------------------------
local morphableStaticCommDefs = VFS.Include("gamedata/modularcomms/staticcomms_morphable.lua")
local success, err

local NUM_COMM_LEVELS = 5

-- global comm data (from the modoption)
-- abolished - exceeeds memory usage during loading
--[[
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
]]

-- player comm data (from customkeys)
local myID = Spring.GetMyPlayerID()
local commData = {}
local commDataByID = {}
local commDataForPlayers = {}

local players = Spring.GetPlayerList()

for i=1,#players do
	local playerID = players[i]
	local playerName, active, spectator, teamID, allyTeamID, _, _, country, rank, customKeys = Spring.GetPlayerInfo(playerID)
	
	local commDataForPlayer	-- [playerID] = {[commID1] = {}, [commID2] = {}, ...}
	local commDataForPlayerRaw = customKeys and customKeys.commanders
	if not (commDataForPlayerRaw and type(commDataForPlayerRaw) == 'string') then
		err = "Comm data entry for player " .. playerName .. " is empty or in invalid format"
		commDataForPlayer = {}
	else
		commDataForPlayerRaw = string.gsub(commDataForPlayerRaw, '_', '=')
		commDataForPlayerRaw = Spring.Utilities.Base64Decode(commDataForPlayerRaw)
		local commDataForPlayerFunc, err = loadstring("return "..commDataForPlayerRaw)
		if commDataForPlayerFunc then
			success, commDataForPlayer = pcall(commDataForPlayerFunc)
			if not success then
				err = commDataForPlayer
				commDataForPlayer = {}
			end
		end
	end
	if err then 
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Modular Comm API error: " .. err)
	end
	commDataForPlayers[playerID] = commDataForPlayer
end

-- morphable static comms (e.g. trainers)
local morphableStaticComms = {}
for commID, commDef in pairs(morphableStaticCommDefs) do
	--Spring.Echo("Modular comm API adding static comm " .. commID)
	local entry = Spring.Utilities.CopyTable(commDef, true)
	entry.modules = entry.levels
	entry.levels = nil
	for level=1,#entry.modules do
		entry.modules[level].cost = nil
	end
	morphableStaticComms[commID] = entry
	commDataByID[commID] = entry
end
commData.players = commDataForPlayers
commData.static = morphableStaticComms

-- add player comms to by-name comm list
for playerID, playerComms in pairs(commData.players) do
	for commID, data in pairs(playerComms) do
		commDataByID[commID] = data
	end
end

--WG.commData = commData
--WG.commDataByID = commDataByID

VFS.Include("gamedata/modularcomms/moduledefs.lua")

local commModulesByStaticComm = {}
for i=1,#UnitDefs do
	if UnitDefs[i].customParams.modules then
		local modulesRaw = {}
		local modulesHuman = {}
		local modulesInternalFunc = loadstring("return ".. UnitDefs[i].customParams.modules)
		local modulesInternal = modulesInternalFunc()
		for i=1, #modulesInternal do
			local modulename = modulesInternal[i]
			modulesRaw[i] = modulename
			modulesHuman[i] = upgrades[modulename].name
		end
		commModulesByStaticComm[UnitDefs[i].name] = {raw = modulesRaw, human = modulesHuman}
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- TODO
local function GetModulesCost(modulesList)
	return 0
end

local function GetCommSeriesInfo(commID)
	return commDataByID[commID]
end

local function GetPlayerComms(playerID, includeTrainers)
	local comms = {}
	if commData.players[playerID] then
		comms = CopyTable(commData.players[playerID], true)
	end
	if includeTrainers then
		for commID, commDef in pairs(commData.static) do
			if (string.find(commID, "trainer")) ~= nil then
				comms[commID] = CopyTable(commDef, true)
			end
		end
	end
	return comms
end

-- returns the moduledef table
local function GetCommUpgradeList()
	return upgrades
end

local function GetCommModules(unitDef, raw)
	if type(unitDef) == "number" then
		unitDef = UnitDefs[unitDef].name
	end
	if commModulesByStaticComm[unitDef] then
		return commModulesByStaticComm[unitDef][raw and "raw" or "human"]
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:Initialize()
	WG.ModularCommAPI = {
		GetPlayerComms = GetPlayerComms,
		GetCommUpgradeList = GetCommUpgradeList,
		GetCommModules = GetCommModules,
		GetCommSeriesInfo = GetCommSeriesInfo
	}
end

function widget:Shutdown()
	WG.ModularCommAPI = nil
end