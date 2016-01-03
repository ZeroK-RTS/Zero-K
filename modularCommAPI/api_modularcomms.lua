--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetInfo()
	return {
		name      = "Modular Comm Info",
		desc      = "Helper widget/gadget that provides info on modular comms.",
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

local commData = {}	-- {players = {[playerID1] = {}, [playerID2] = {}}, static = {}}
local commProfilesByProfileID = {}
local commProfileIDsByPlayerID = {}

local function LoadCommData()
	-- comm profile definitions
	local modOptions = (Spring and Spring.GetModOptions and Spring.GetModOptions()) or {}
	local commDataRaw = modOptions.commanders
	local commDataFunc
	if not (commDataRaw and type(commDataRaw) == 'string') then
		err = "Comm data entry in modoption is empty or in invalid format"
		commData = {}
	else
		commDataRaw = string.gsub(commDataRaw, '_', '=')
		commDataRaw = Spring.Utilities.Base64Decode(commDataRaw)
		--Spring.Echo(commDataRaw)
		commDataFunc, err = loadstring("return "..commDataRaw)
		if commDataFunc then
			success, commProfilesByProfileID = pcall(commDataFunc)
			if not success then	-- execute Borat
				err = commProfilesByProfileID
				commProfilesByProfileID = {}
			end
		end
	end
	if err then 
		Spring.Log(GetInfo().name, "warning", 'Modular Comms API warning: ' .. err)
	else
		for profileID, profile in pairs(commProfilesByProfileID) do
			-- MAKE SURE THIS MATCHES WHAT UNITDEFGEN SETS
			profile.baseUnitDefID = UnitDefNames[profileID .. "_base"].id
			profile.baseWreckID = FeatureDefNames[profileID .. "_base_dead"].id
			profile.baseHeapID = FeatureDefNames[profileID .. "_base_heap"].id
		end
	end
	
	-- comm player entries
	local commProfilesForPlayers = {}	-- {[playerID1] = {}, [playerID2] = {}}
	local players = Spring.GetPlayerList()
	for i=1,#players do
		local playerID = players[i]
		local playerName, active, spectator, teamID, allyTeamID, _, _, country, rank, customKeys = Spring.GetPlayerInfo(playerID)
		
		if (not spectator) then
			local playerCommProfileIDs	-- [playerID] = {[commProfileID1] = {}, [commProfileID2] = {}, ...}
			local playerCommProfileIDsRaw = customKeys and customKeys.commanders
			if not (playerCommProfileIDsRaw and type(playerCommProfileIDsRaw) == 'string') then
				err = "Comm data entry for player " .. playerName .. " is empty or in invalid format"
				playerCommProfileIDs = {}
			else
				playerCommProfileIDsRaw = string.gsub(playerCommProfileIDsRaw, '_', '=')
				playerCommProfileIDsRaw = Spring.Utilities.Base64Decode(playerCommProfileIDsRaw)
				local playerCommProfileIDsFunc, err = loadstring("return "..playerCommProfileIDsRaw)
				if playerCommProfileIDsFunc then
					success, playerCommProfileIDs = pcall(playerCommProfileIDsFunc)
					if not success then
						err = playerCommProfileIDs
						playerCommProfileIDs = {}
					end
				end
			end
			if err then 
				Spring.Log(GetInfo().name, "warning", 'Modular Comms API warning: ' .. err)
			end
			
			commProfileIDsByPlayerID[playerID] = playerCommProfileIDs
			local playerCommProfiles = {} 
			for i=1,#playerCommProfileIDs do
				local profileID = playerCommProfileIDs[i]
				playerCommProfiles[profileID] = commProfilesByProfileID[profileID]
			end
			commProfilesForPlayers[playerID] = playerCommProfiles
		end
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
		commProfilesByProfileID[commProfileID] = entry
	end
	commData.players = commProfilesForPlayers
	commData.static = morphableStaticComms
	
	--XG.commData = commData
	--XG.commProfilesByProfileID = commProfilesByProfileID
	
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
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- TODO
local function GetModulesCost(modulesList)
	return 0
end

local function GetCommProfileInfo(commProfileID)
	return commProfilesByProfileID[commProfileID]
end

local function GetPlayerCommProfiles(playerID, includeTrainers)
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
	LoadCommData()
	XG.ModularCommAPI = {
		GetPlayerCommProfiles = GetPlayerCommProfiles,
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