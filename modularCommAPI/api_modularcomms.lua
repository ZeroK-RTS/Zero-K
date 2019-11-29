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
		alwaysStart = true,
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
local predefinedDynamicComms = VFS.Include("gamedata/modularcomms/dyncomms_predefined.lua", nil, VFSMODE)
local legacyTranslators = VFS.Include("gamedata/modularcomms/legacySiteDataTranslate.lua", nil, VFSMODE)
local success, err

local legacyToDyncommChassisMap = legacyTranslators.legacyToDyncommChassisMap

VFS.Include("gamedata/modularcomms/moduledefs.lua", nil, VFSMODE)

local NUM_COMM_LEVELS = 5

local commData = {}	-- { players = {[playerID1] = {profiles...}, [playerID2] = {profiles...}}, static = {[staticProfileID1] = {}} }
local commProfilesByProfileID = {}
local commProfileIDsByPlayerID = {}
local profileIDByBaseDefID = {}

local legacyModulesByUnitDefName = {}

local function LoadCommData()
	-- comm profile definitions
	local modOptions = (Spring and Spring.GetModOptions and Spring.GetModOptions()) or {}
	local commDataRaw = modOptions.commandertypes
	local commDataFunc
	local newCommData = {}
	local newCommProfilesByProfileID = {}
	local newCommProfileIDsByPlayerID = {}
	local newProfileIDByBaseDefID = {}
	
	if not (commDataRaw and type(commDataRaw) == 'string') then
		err = "Comm data entry in modoption is empty or in invalid format"
		newCommData = {}
	else
		commDataRaw = string.gsub(commDataRaw, '_', '=')
		if collectgarbage then
			collectgarbage("collect")
		end
		commDataRaw = Spring.Utilities.Base64Decode(commDataRaw)
		--Spring.Echo(commDataRaw)
		commDataFunc, err = loadstring("return "..commDataRaw)
		if commDataFunc then
			success, newCommProfilesByProfileID = pcall(commDataFunc)
			if not success then	-- execute Borat
				err = newCommProfilesByProfileID
				newCommProfilesByProfileID = {}
			end
		end
	end
	if err then
		Spring.Log(GetInfo().name, "warning", 'Modular Comms API warning: ' .. err)
	end
	
	newCommProfilesByProfileID = legacyTranslators.FixOverheadIcon(newCommProfilesByProfileID)
	
	-- comm player entries
	local commProfilesForPlayers = {}	-- {[playerID1] = {}, [playerID2] = {}}
	local players = Spring.GetPlayerList()
	for i = 1, #players do
		local playerID = players[i]
		local playerName, active, spectator, teamID, allyTeamID, _, _, country, rank, _, customKeys = Spring.GetPlayerInfo(playerID)
		
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
					else
						--playerCommProfileIDs = legacyTranslators.TranslatePlayerCustomkeys(playerCommProfileIDs)
					end
				end
			end
			if err then
				Spring.Log(GetInfo().name, "warning", 'Modular Comms API warning: ' .. err)
			end
			
			newCommProfileIDsByPlayerID[playerID] = playerCommProfileIDs
			local playerCommProfiles = {}
			for i = 1, #playerCommProfileIDs do
				local profileID = playerCommProfileIDs[i]
				playerCommProfiles[profileID] = newCommProfilesByProfileID[profileID]
			end
			commProfilesForPlayers[playerID] = playerCommProfiles
		end
	end
	
	-- morphable static comms (e.g. trainers)
	local morphableStaticComms = {}
	for commProfileID, commDef in pairs(predefinedDynamicComms) do
		--Spring.Echo("Modular comm API adding static comm " .. commProfileID)
		local entry = Spring.Utilities.CopyTable(commDef, true)
		for level = 1, #entry.modules do
			entry.modules[level].cost = nil
		end
		morphableStaticComms[commProfileID] = entry
		newCommProfilesByProfileID[commProfileID] = entry
	end
	newCommData.players = commProfilesForPlayers
	newCommData.static = morphableStaticComms
	
	for profileID, profile in pairs(newCommProfilesByProfileID) do
		-- MAKE SURE THIS MATCHES WHAT UNITDEFGEN SETS
		profile.baseUnitDefID = UnitDefNames[profileID .. "_base"].id
		profile.baseWreckID = FeatureDefNames[profileID .. "_base_dead"].id
		profile.baseHeapID = FeatureDefNames[profileID .. "_base_heap"].id
		newProfileIDByBaseDefID[profile.baseUnitDefID] = profileID
	end
	
	-- Convert chassis to correct names.
	for profileID, profile in pairs(newCommProfilesByProfileID) do
		profile.chassis = legacyToDyncommChassisMap[profile.chassis]
	end
	
	for i = 1, #UnitDefs do
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
			legacyModulesByUnitDefName[UnitDefs[i].name] = {raw = modulesRaw, human = modulesHuman}
		end
	end
	
	return newCommData, newCommProfilesByProfileID, newCommProfileIDsByPlayerID, newProfileIDByBaseDefID
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

local function GetProfileIDByBaseDefID(unitDefID)
	return profileIDByBaseDefID[unitDefID]
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
local function GetLegacyModuleDefs()
	return upgrades
end

local function GetLegacyModulesForComm(unitDef, raw)
	if type(unitDef) == "number" then
		unitDef = UnitDefs[unitDef].name
	end
	if legacyModulesByUnitDefName[unitDef] then
		return legacyModulesByUnitDefName[unitDef][raw and "raw" or "human"]
	end
end

local function IsStarterComm(unitID)
	local profileID = Spring.GetUnitRulesParam(unitID, "comm_profileID")
	return profileID and (not commProfilesByProfileID[profileID].notStarter)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function Initialize()
	commData, commProfilesByProfileID, commProfileIDsByPlayerID, profileIDByBaseDefID = LoadCommData()
	XG.ModularCommAPI = {
		GetPlayerCommProfiles = GetPlayerCommProfiles,
		GetProfileIDByBaseDefID = GetProfileIDByBaseDefID,
		GetLegacyModuleDefs = GetLegacyModuleDefs,
		GetLegacyModulesForComm = GetLegacyModulesForComm,
		GetCommProfileInfo = GetCommProfileInfo,
		IsStarterComm = IsStarterComm,
	}
end

local function Shutdown()
	XG.ModularCommAPI = nil
end

local this = widget or gadget

this.GetInfo    = GetInfo
this.Initialize = Initialize
this.Shutdown   = Shutdown
