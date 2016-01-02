--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetInfo()
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

local XG      = (widget and WG) or (GG)
local VFSMODE = (widget and VFS.RAW_FIRST) or (VFS.ZIP_ONLY)

Spring.Utilities = Spring.Utilities or {}
VFS.Include("LuaRules/Utilities/base64.lua", nil, VFSMODE)
VFS.Include("LuaRules/Utilities/tablefunctions.lua", nil, VFSMODE)
local CopyTable = Spring.Utilities.CopyTable

--------------------------------------------------------------------------------
-- load data
--------------------------------------------------------------------------------
local morphableStaticCommDefs = VFS.Include("gamedata/modularcomms/staticcomms_morphable.lua", nil, VFSMODE)
local success, err

VFS.Include("gamedata/modularcomms/moduledefs.lua", nil, VFSMODE)

local NUM_COMM_LEVELS = 5

local commData = {}
local commDataByProfileID = {}
local commDataForPlayers = {}

local players = Spring.GetPlayerList()

for i=1,#players do
	local playerID = players[i]
	local playerName, active, spectator, teamID, allyTeamID, _, _, country, rank, customKeys = Spring.GetPlayerInfo(playerID)
	
	local commDataForPlayer	-- [playerID] = {[commProfileID1] = {}, [commProfileID2] = {}, ...}
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
for commProfileID, commDef in pairs(morphableStaticCommDefs) do
	--Spring.Echo("Modular comm API adding static comm " .. commProfileID)
	local entry = Spring.Utilities.CopyTable(commDef, true)
	entry.modules = entry.levels
	entry.levels = nil
	for level=1,#entry.modules do
		entry.modules[level].cost = nil
	end
	morphableStaticComms[commProfileID] = entry
	commDataByProfileID[commProfileID] = entry
end
commData.players = commDataForPlayers
commData.static = morphableStaticComms

-- add player comms to by-name comm list
for playerID, playerComms in pairs(commData.players) do
	for commProfileID, data in pairs(playerComms) do
		commDataByProfileID[commProfileID] = data
	end
end

--XG.commData = commData
--XG.commDataByProfileID = commDataByProfileID

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

local function GetCommProfileInfo(commProfileID)
	return commDataByProfileID[commProfileID]
end

local function GetPlayerComms(playerID, includeTrainers)
	local comms = {}
	if commData.players[playerID] then
		comms = CopyTable(commData.players[playerID], true)
	end
	if includeTrainers then
		for commProfileID, commDef in pairs(commData.static) do
			if (string.find(commProfileID, "trainer")) ~= nil then
				comms[commProfileID] = CopyTable(commDef, true)
			end
		end
	end
	return comms
end

-- TODO: use dynamic comm def data instead of the old stuff in gamedata
-- returns the moduledef table
local function GetCommUpgradeList()
	return upgrades
end

--[[
local function GetCommModules(unitDef, raw)
	if type(unitDef) == "number" then
		unitDef = UnitDefs[unitDef].name
	end
	if commModulesByStaticComm[unitDef] then
		return commModulesByStaticComm[unitDef][raw and "raw" or "human"]
	end
end
]]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function Initialize()
	XG.ModularCommAPI = {
		GetPlayerComms = GetPlayerComms,
		GetCommUpgradeList = GetCommUpgradeList,
		--GetCommModules = GetCommModules,
		GetCommProfileInfo = GetCommProfileInfo
	}
end

local function Shutdown()
	XG.ModularCommAPI = nil
end

local this = widget or gadget

this.GetInfo    = GetInfo
this.Initialize = Initialize
this.Shutdown   = Shutdown