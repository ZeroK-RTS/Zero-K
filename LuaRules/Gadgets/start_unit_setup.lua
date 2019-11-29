function gadget:GetInfo()
	return {
		name      = "StartSetup",
		desc      = "Implements initial setup: start units, resources, and plop for construction",
		author    = "Licho, CarRepairer, Google Frog, SirMaverick",
		date      = "2008-2010",
		license   = "GNU GPL, v2 or later",
		layer     = -1, -- Before terraforming gadget (for facplop terraforming)
		enabled   = true  --  loaded by default?
	}
end

-- partially based on Spring's unit spawn gadget
include("LuaRules/Configs/start_setup.lua")
include("LuaRules/Configs/constants.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spGetTeamInfo         = Spring.GetTeamInfo
local spGetPlayerInfo       = Spring.GetPlayerInfo
local spGetSpectatingState  = Spring.GetSpectatingState
local spGetPlayerList       = Spring.GetPlayerList

local modOptions = Spring.GetModOptions()

local DELAYED_AFK_SPAWN = false
local COOP_MODE = false
local playerChickens = Spring.Utilities.tobool(Spring.GetModOption("playerchickens", false, false))
local campaignBattleID = modOptions.singleplayercampaignbattleid
local setAiStartPos = (modOptions.setaispawns == "1")

local CAMPAIGN_SPAWN_DEBUG = (Spring.GetModOptions().campaign_spawn_debug == "1")

local gaiateam = Spring.GetGaiaTeamID()
local gaiaally = select(6, spGetTeamInfo(gaiateam, false))

local SAVE_FILE = "Gadgets/start_unit_setup.lua"

local fixedStartPos = (modOptions.fixedstartpos == "1")
local ordersToRemove

local storageUnits = {
	{
		unitDefID = UnitDefNames["staticstorage"].id,
		storeAmount = UnitDefNames["staticstorage"].metalStorage
	}
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (gadgetHandler:IsSyncedCode()) then

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Functions shared between missions and non-missions

local function CheckOrderRemoval() -- FIXME: maybe we can remove polling every frame and just remove the orders directly
	if not ordersToRemove then
		return
	end
	for unitID, factoryDefID in pairs(ordersToRemove) do
		local cmdID, _, cmdTag = Spring.GetUnitCurrentCommand(unitID)
		if cmdID == -factoryDefID then
			Spring.GiveOrderToUnit(unitID, CMD.REMOVE, {cmdTag}, CMD.OPT_ALT)
		end
	end
	ordersToRemove = nil
end

local function CheckFacplopUse(unitID, unitDefID, teamID, builderID)
	if ploppableDefs[unitDefID] and (select(5, Spring.GetUnitHealth(unitID)) < 0.1) and (builderID and Spring.GetUnitRulesParam(builderID, "facplop") == 1) then
		-- (select(5, Spring.GetUnitHealth(unitID)) < 0.1) to prevent ressurect from spending facplop.
		Spring.SetUnitRulesParam(builderID,"facplop",0, {inlos = true})
		Spring.SetUnitRulesParam(unitID,"ploppee",1, {private = true})
		
		ordersToRemove = ordersToRemove or {}
		ordersToRemove[builderID] = unitDefID
		
		-- Instantly complete factory
		local maxHealth = select(2,Spring.GetUnitHealth(unitID))
		Spring.SetUnitHealth(unitID, {health = maxHealth, build = 1})
		local x,y,z = Spring.GetUnitPosition(unitID)
		Spring.SpawnCEG("gate", x, y, z)

		-- Stats collection (acuelly not, see below)
		if GG.mod_stats_AddFactoryPlop then
			GG.mod_stats_AddFactoryPlop(teamID, unitDefID)
		end

		-- FIXME: temporary hack because I'm in a hurry
		-- proper way: get rid of all the useless shit in modstats, reenable and collect plop stats that way (see above)
		local str = "SPRINGIE:facplop," .. UnitDefs[unitDefID].name .. "," .. teamID .. "," .. select(6, Spring.GetTeamInfo(teamID, false)) .. ","
		local _, playerID, _, isAI = Spring.GetTeamInfo(teamID, false)
		if isAI then
			str = str .. "Nightwatch" -- existing account just in case infra explodes otherwise
		else
			str = str .. (Spring.GetPlayerInfo(playerID, false) or "ChanServ") -- ditto, different acc to differentiate
		end
		str = str .. ",END_PLOP"
		Spring.SendCommands("wbynum 255 " .. str)

		-- Spring.PlaySoundFile("sounds/misc/teleport2.wav", 10, x, y, z) -- FIXME: performance loss, possibly preload?
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Mission Handling

if VFS.FileExists("mission.lua") then -- this is a mission, we just want to set starting storage (and enable facplopping)
	function gadget:Initialize()
		for _, teamID in ipairs(Spring.GetTeamList()) do
			Spring.SetTeamResource(teamID, "es", START_STORAGE + HIDDEN_STORAGE)
			Spring.SetTeamResource(teamID, "ms", START_STORAGE + HIDDEN_STORAGE)
		end
	end

	function GG.SetStartLocation()
	end

	function gadget:GameFrame(n)
		CheckOrderRemoval()
	end
	
	function GG.GiveFacplop(unitID) -- deprecated, use rulesparam directly
		Spring.SetUnitRulesParam(unitID, "facplop", 1, {inlos = true})
	end

	function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
		CheckFacplopUse(unitID, unitDefID, teamID, builderID)
	end

	return
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local gamestart = false
--local createBeforeGameStart = {}	-- no longer used
local scheduledSpawn = {}
local luaSetStartPositions = {}
local playerSides = {} -- sides selected ingame from widget  - per players
local teamSides = {} -- sides selected ingame from widgets - per teams

local playerIDsByName = {}
local commChoice = {}

--local prespawnedCommIDs = {}	-- [teamID] = unitID

GG.startUnits = {}	-- WARNING: this is liable to break with new dyncomms (entries will likely not be an actual unitDefID)
GG.CommanderSpawnLocation = {}

local waitingForComm = {}
GG.waitingForComm = waitingForComm

-- overlaps with the rulesparam
local commSpawnedTeam = {}
local commSpawnedPlayer = {}

-- allow gadget:Save (unsynced) to reach them
local function UpdateSaveReferences()
	_G.waitingForComm = waitingForComm
	_G.scheduledSpawn = scheduledSpawn
	_G.playerSides = playerSides
	_G.teamSides = teamSides
	_G.commSpawnedTeam = commSpawnedTeam
	_G.commSpawnedPlayer = commSpawnedPlayer
end
UpdateSaveReferences()

local loadGame = false	-- was this loaded from a savegame?

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
	CheckFacplopUse(unitID, unitDefID, teamID, builderID)
end

local function InitUnsafe()
	
end

function gadget:Initialize()
	-- needed if you reload luarules
	local frame = Spring.GetGameFrame()
	if frame and frame > 0 then
		gamestart = true
	end

	InitUnsafe()
	local allUnits = Spring.GetAllUnits()
	for _, unitID in pairs(allUnits) do
		local udid = Spring.GetUnitDefID(unitID)
		if udid then
			gadget:UnitCreated(unitID, udid, Spring.GetUnitTeam(unitID))
		end
	end
end

local function GetStartUnit(teamID, playerID, isAI)

	local teamInfo = teamID and select(8, Spring.GetTeamInfo(teamID, true))
	if teamInfo and teamInfo.staticcomm then
		local commanderName = teamInfo.staticcomm
		local commanderLevel = teamInfo.staticcomm_level or 1
		local commanderProfile = GG.ModularCommAPI.GetCommProfileInfo(commanderName)
		return commanderProfile.baseUnitDefID
	end

	local startUnit
	local commProfileID = nil

	if isAI then -- AI that didn't pick comm type gets default comm
		return UnitDefNames[Spring.GetTeamRulesParam(teamID, "start_unit") or "dyntrainer_assault_base"].id
	end

	if (teamID and teamSides[teamID]) then
		startUnit = DEFAULT_UNIT
	end

	if (playerID and playerSides[playerID]) then
		startUnit = DEFAULT_UNIT
	end

	-- if a player-selected comm is available, use it
	playerID = playerID or (teamID and select(2, spGetTeamInfo(teamID, false)) )
	if (playerID and commChoice[playerID]) then
		--Spring.Echo("Attempting to load alternate comm")
		local playerCommProfiles = GG.ModularCommAPI.GetPlayerCommProfiles(playerID, true)
		local altComm = playerCommProfiles[commChoice[playerID]]
		if altComm then
			startUnit = playerCommProfiles[commChoice[playerID]].baseUnitDefID
			commProfileID = commChoice[playerID]
		end
	end

	if (not startUnit) and (not DELAYED_AFK_SPAWN) then
		startUnit = DEFAULT_UNIT
	end
	
	-- hack workaround for chicken
	--local luaAI = Spring.GetTeamLuaAI(teamID)
	--if luaAI and string.find(string.lower(luaAI), "chicken") then startUnit = nil end

	--if didn't pick a comm, wait for user to pick
	return (startUnit or nil)
end


local function GetFacingDirection(x, z, teamID)
	return (math.abs(Game.mapSizeX/2 - x) > math.abs(Game.mapSizeZ/2 - z))
			and ((x>Game.mapSizeX/2) and "west" or "east")
			or ((z>Game.mapSizeZ/2) and "north" or "south")
end

local function getMiddleOfStartBox(teamID)
	local x = Game.mapSizeX / 2
	local z = Game.mapSizeZ / 2

	local boxID = Spring.GetTeamRulesParam(teamID, "start_box_id")
	if boxID then
		local startposList = GG.startBoxConfig[boxID] and GG.startBoxConfig[boxID].startpoints
		if startposList then
			local startpos = startposList[1] -- todo: distribute afkers over them all instead of always using the 1st
			x = startpos[1]
			z = startpos[2]
		end
	end

	return x, Spring.GetGroundHeight(x,z), z
end

local function GetStartPos(teamID, teamInfo, isAI)
	if luaSetStartPositions[teamID] then
		return luaSetStartPositions[teamID].x, luaSetStartPositions[teamID].y, luaSetStartPositions[teamID].z
	end
	
	if fixedStartPos then
		local x, y, z
		if teamInfo then
			x, z = tonumber(teamInfo.start_x), tonumber(teamInfo.start_z)
		end
		if x then
			y = Spring.GetGroundHeight(x, z)
		else
			x, y, z = Spring.GetTeamStartPosition(teamID)
		end
		return x, y, z
	end
	
	if not (Spring.GetTeamRulesParam(teamID, "valid_startpos") or isAI) then
		local x, y, z = getMiddleOfStartBox(teamID)
		return x, y, z
	end
	
	local x, y, z = Spring.GetTeamStartPosition(teamID)
	-- clamp invalid positions
	-- AIs can place them -- remove this once AIs are able to be filtered through AllowStartPosition
	local boxID = isAI and Spring.GetTeamRulesParam(teamID, "start_box_id")
	if boxID and not GG.CheckStartbox(boxID, x, z) then
		x,y,z = getMiddleOfStartBox(teamID)
	end
	return x, y, z
end

local function SpawnStartUnit(teamID, playerID, isAI, bonusSpawn, notAtTheStartOfTheGame)
	if not teamID then
		return
	end
	local _,_,_,_,_,allyTeamID,_,teamInfo = Spring.GetTeamInfo(teamID, true)
	if teamInfo and teamInfo.nocommander then
		waitingForComm[teamID] = nil
		return
	end
	
	local luaAI = Spring.GetTeamLuaAI(teamID)
	if luaAI and string.find(string.lower(luaAI), "chicken") then
		return false
	elseif playerChickens then
		-- allied to latest chicken team? no com for you
		local chickenTeamID = -1
		for _,t in pairs(Spring.GetTeamList()) do
			local teamLuaAI = Spring.GetTeamLuaAI(t)
			if teamLuaAI and string.find(string.lower(teamLuaAI), "chicken") then
				chickenTeamID = t
			end
		end
		if (chickenTeamID > -1) and (Spring.AreTeamsAllied(teamID,chickenTeamID)) then
			--Spring.Echo("chicken_control detected no com for "..playerID)
			return false
		end
	end
	
	-- get start unit
	local startUnit = GetStartUnit(teamID, playerID, isAI)

	if ((COOP_MODE and playerID and commSpawnedPlayer[playerID]) or (not COOP_MODE and commSpawnedTeam[teamID])) and not bonusSpawn then
		return false
	end

	if startUnit then
		-- replace with shuffled position
		local x,y,z = GetStartPos(teamID, teamInfo, isAI)
		
		-- get facing direction
		local facing = GetFacingDirection(x, z, teamID)

		if CAMPAIGN_SPAWN_DEBUG then
			local _, aiName = Spring.GetAIInfo(teamID)
			Spring.MarkerAddPoint(x, y, z, "Commander " .. (aiName or "Player"))
			return -- Do not spawn commander
		end
		GG.startUnits[teamID] = startUnit
		GG.CommanderSpawnLocation[teamID] = {x = x, y = y, z = z, facing = facing}

		if GG.GalaxyCampaignHandler then
			facing = GG.GalaxyCampaignHandler.OverrideCommFacing(teamID) or facing
		end
		
		-- CREATE UNIT
		local unitID = GG.DropUnit(startUnit, x, y, z, facing, teamID, _, _, _, _, _, GG.ModularCommAPI.GetProfileIDByBaseDefID(startUnit), teamInfo and tonumber(teamInfo.static_level), true)
		
		if not unitID then
			return
		end
		
		if GG.GalaxyCampaignHandler then
			GG.GalaxyCampaignHandler.DeployRetinue(unitID, x, z, facing, teamID)
		end
		
		if Spring.GetGameFrame() <= 1 then
			Spring.SpawnCEG("gate", x, y, z)
			-- Spring.PlaySoundFile("sounds/misc/teleport2.wav", 10, x, y, z) -- performance loss
		end

		if not bonusSpawn then
			Spring.SetTeamRulesParam(teamID, "commSpawned", 1, {allied = true})
			commSpawnedTeam[teamID] = true
			if playerID then
				Spring.SetGameRulesParam("commSpawnedPlayer"..playerID, 1, {allied = true})
				commSpawnedPlayer[playerID] = true
			end
			waitingForComm[teamID] = nil
		end

		-- add facplop
		local teamLuaAI = Spring.GetTeamLuaAI(teamID)
		local udef = UnitDefs[Spring.GetUnitDefID(unitID)]

		local metal, metalStore = Spring.GetTeamResources(teamID, "metal")
		local energy, energyStore = Spring.GetTeamResources(teamID, "energy")

		Spring.SetTeamResource(teamID, "energy", teamInfo.start_energy or (START_ENERGY + energy))
		Spring.SetTeamResource(teamID, "metal", teamInfo.start_metal or (START_METAL + metal))

		if GG.Overdrive then
			GG.Overdrive.AddInnateIncome(allyTeamID, INNATE_INC_METAL, INNATE_INC_ENERGY)
		end

		if (udef.customParams.level and udef.name ~= "chickenbroodqueen") and
			((not campaignBattleID) or GG.GalaxyCampaignHandler.HasFactoryPlop(teamID)) then
			Spring.SetUnitRulesParam(unitID, "facplop", 1, {inlos = true})
		end
		
		local name = "noname" -- Backup for when player does not choose a commander and then resigns.
		if isAI then
			name = select(2, Spring.GetAIInfo(teamID))
		else
			name = Spring.GetPlayerInfo(playerID, false)
		end
		Spring.SetUnitRulesParam(unitID, "commander_owner", name, {inlos = true})
		return true
	end
	return false
end

local function StartUnitPicked(playerID, name)
	local _,_,spec,teamID = spGetPlayerInfo(playerID, false)
	if spec then
		return
	end
	teamSides[teamID] = name
	local startUnit = GetStartUnit(teamID, playerID)
	if startUnit then
		SendToUnsynced("CommSelection",playerID, startUnit) --activate an event called "CommSelection" that can be detected in unsynced part
		if UnitDefNames[startUnit] then
			Spring.SetTeamRulesParam(teamID, "commChoice", UnitDefNames[startUnit].id)
		else
			Spring.SetTeamRulesParam(teamID, "commChoice", startUnit)
		end
	end
	if gamestart then
		-- picked commander after game start, prep for orbital drop
		-- can't do it directly because that's an unsafe change
		local frame = Spring.GetGameFrame() + 3
		if not scheduledSpawn[frame] then scheduledSpawn[frame] = {} end
		scheduledSpawn[frame][#scheduledSpawn[frame] + 1] = {teamID, playerID}
	else
		--[[
		if startPosition[teamID] then
			local oldCommID = prespawnedCommIDs[teamID]
			local pos = startPosition[teamID]
			local startUnit = GetStartUnit(teamID, playerID, isAI)
			if startUnit then
				local newCommID = Spring.CreateUnit(startUnit, pos.x, pos.y, pos.z , "s", 0)
				if oldCommID then
					local cmds = Spring.GetCommandQueue(oldCommID, -1)
					--//transfer command queue
					for i = 1, #cmds do
						local cmd = cmds[i]
						Spring.GiveOrderToUnit(newUnit, cmd.id, cmd.params, cmd.options.coded)
					end
					Spring.DestroyUnit(oldCommID, false, true)
				end
				prespawnedCommIDs[teamID] = newCommID
			end
		end
		]]
	end
	GG.startUnits[teamID] = GetStartUnit(teamID) -- ctf compatibility
end

local function workAroundSpecsInTeamZero(playerlist, team)
	if team == 0 then
		local players = #playerlist
		local specs = 0
		-- count specs
		for i=1,#playerlist do
			local _,_,spec = spGetPlayerInfo(playerlist[i], false)
			if spec then
				specs = specs + 1
			end
			end
		if players == specs then
			return nil
		end
	end
	return playerlist
end

--[[
   This function return true if everyone in the team resigned.
   This function is alternative to "isDead" from: "_,_,isDead,isAI = spGetTeamInfo(team, false)"
   because "isDead" failed to return true when human team resigned before GameStart() event.
--]]
local function IsTeamResigned(team)
	local playersInTeam = spGetPlayerList(team)
	for j=1,#playersInTeam do
		local spec = select(3,spGetPlayerInfo(playersInTeam[j], false))
		if not spec then
			return false
		end
	end
	return true
end

local function GetPregameUnitStorage(teamID)
	local storage = 0
	for i = 1, #storageUnits do
		storage = storage + Spring.GetTeamUnitDefCount(teamID, storageUnits[i].unitDefID) * storageUnits[i].storeAmount
	end
	return storage
end

function gadget:GameStart()
	if Spring.Utilities.tobool(Spring.GetGameRulesParam("loadedGame")) then
		return
	end
	gamestart = true

	-- spawn units
	for teamNum,team in ipairs(Spring.GetTeamList()) do
		
		-- clear resources
		-- actual resources are set depending on spawned unit and setup
		if not loadGame then
			local pregameUnitStorage = (campaignBattleID and GetPregameUnitStorage(team)) or 0
			Spring.SetTeamResource(team, "es", pregameUnitStorage + HIDDEN_STORAGE)
			Spring.SetTeamResource(team, "ms", pregameUnitStorage + HIDDEN_STORAGE)
			Spring.SetTeamResource(team, "energy", 0)
			Spring.SetTeamResource(team, "metal", 0)
		end

		--check if player resigned before game started
		local _,playerID,_,isAI = spGetTeamInfo(team, false)
		local deadPlayer = (not isAI) and IsTeamResigned(team)

		if team ~= gaiateam and not deadPlayer then
			local luaAI = Spring.GetTeamLuaAI(team)
			if DELAYED_AFK_SPAWN then
				if not (luaAI and string.find(string.lower(luaAI), "chicken")) then
					waitingForComm[team] = true
				end
			end
			if COOP_MODE then
				-- 1 start unit per player
				local playerlist = Spring.GetPlayerList(team, true)
				playerlist = workAroundSpecsInTeamZero(playerlist, team)
				if playerlist and (#playerlist > 0) then
					for i=1,#playerlist do
						local _,_,spec = spGetPlayerInfo(playerlist[i], false)
						if (not spec) then
							SpawnStartUnit(team, playerlist[i])
						end
					end
				else
					-- AI etc.
					SpawnStartUnit(team, nil, true)
				end
			else -- no COOP_MODE
				if (playerID) then
					local _,_,spec,teamID = spGetPlayerInfo(playerID, false)
					if (teamID == team and not spec) then
						isAI = false
					else
						playerID = nil
					end
				end

				SpawnStartUnit(team, playerID, isAI)
			end

			-- extra comms
			local playerlist = Spring.GetPlayerList(team, true)
			playerlist = workAroundSpecsInTeamZero(playerlist, team)
			if playerlist then
				for i = 1, #playerlist do
					local customKeys = select(11, Spring.GetPlayerInfo(playerlist[i]))
					if customKeys and customKeys.extracomm then
						for j = 1, tonumber(customKeys.extracomm) do
							Spring.Echo("Spawing a commander")
							SpawnStartUnit(team, playerlist[i], false, true)
						end
					end
				end
			end
		end
	end
end

function gadget:RecvSkirmishAIMessage(aiTeam, dataStr)
	-- perhaps this should be a global relay mode somewhere instead
	local command = "ai_commander:";
	if dataStr:find(command,1,true) then
		local name = dataStr:sub(command:len()+1);
		CallAsTeam(aiTeam, function()
			Spring.SendLuaRulesMsg(command..aiTeam..":"..name);
		end)
	end
end

local function SetStartLocation(teamID, x, z)
    luaSetStartPositions[teamID] = {x = x, y = Spring.GetGroundHeight(x,z), z = z}
end
GG.SetStartLocation = SetStartLocation

function gadget:RecvLuaMsg(msg, playerID)
	if msg:find("faction:",1,true) then
		local side = msg:sub(9)
		playerSides[playerID] = side
		commChoice[playerID] = nil	-- unselect existing custom comm, if any
		StartUnitPicked(playerID, side)
	elseif msg:find("customcomm:",1,true) then
		local name = msg:sub(12)
		commChoice[playerID] = name
		StartUnitPicked(playerID, name)
	elseif msg:find("ai_commander:",1,true) then
		local command = "ai_commander:";
		local offset = msg:find(":",command:len()+1,true);
		local teamID = msg:sub(command:len()+1,offset-1);
		local name = msg:sub(offset+1);
		
		teamID = tonumber(teamID);
		
		local _,_,_,isAI = Spring.GetTeamInfo(teamID, false)
		if(isAI) then -- this is actually an AI
			local aiid, ainame, aihost = Spring.GetAIInfo(teamID)
			if (aihost == playerID) then -- it's actually controlled by the local host
				local unitDef = UnitDefNames[name];
				if unitDef then -- the requested unit actually exists
					if aiCommanders[unitDef.id] then
						Spring.SetTeamRulesParam(teamID, "start_unit", name);
					end
				end
			end
		end
	elseif (msg:find("ai_start_pos:",1,true) and setAiStartPos) then
		local msg_table = Spring.Utilities.ExplodeString(':', msg)
		if msg_table then
			local teamID, x, z = tonumber(msg_table[2]), tonumber(msg_table[3]), tonumber(msg_table[4])
			if teamID then
				local _,_,_,isAI = Spring.GetTeamInfo(teamID, false)
				if isAI and x and z then
					SetStartLocation(teamID, x, z)
					Spring.MarkerAddPoint(x, 0, z, "AI " .. teamID .. " start")
				end
			end
		end
	end
end

function gadget:GameFrame(n)
	CheckOrderRemoval()
	if n == (COMM_SELECT_TIMEOUT) then
		for team in pairs(waitingForComm) do
			local _,playerID = spGetTeamInfo(team, false)
			teamSides[team] = DEFAULT_UNIT_NAME
			--playerSides[playerID] = "basiccomm"
			scheduledSpawn[n] = scheduledSpawn[n] or {}
			scheduledSpawn[n][#scheduledSpawn[n] + 1] = {team, playerID} -- playerID is needed here so the player can't spawn coms 2 times in COOP_MODE mode
		end
	end
	if scheduledSpawn[n] then
		for _, spawnData in pairs(scheduledSpawn[n]) do
			local teamID, playerID = spawnData[1], spawnData[2]
			local canSpawn = SpawnStartUnit(teamID, playerID, false, false, true)

			if (canSpawn) then
				-- extra comms
				local customKeys = select(10, playerID)
				if playerID and customKeys and customKeys.extracomm then
					for j=1, tonumber(customKeys.extracomm) do
						SpawnStartUnit(teamID, playerID, false, true, true)
					end
				end
			end
		end
		scheduledSpawn[n] = nil
	end
end

function gadget:Shutdown()
	--Spring.Echo("<Start Unit Setup> Going to sleep...")
end

function gadget:Load(zip)
	if not (GG.SaveLoad and GG.SaveLoad.ReadFile) then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Start Unit Setup failed to access save/load API")
		return
	end
	loadGame = true
	local data = GG.SaveLoad.ReadFile(zip, "Start Unit Setup", SAVE_FILE) or {}

	-- load data wholesale
	waitingForComm = data.waitingForComm or {}
	scheduledSpawn = data.scheduledSpawn or {}
	playerSides = data.playerSides or {}
	teamSides = data.teamSides or {}
	commSpawnedPlayer = data.commSpawnedPlayer or {}
	commSpawnedTeam = data.commSpawnedTeam or {}
	
	UpdateSaveReferences()
end

--------------------------------------------------------------------
-- unsynced code
--------------------------------------------------------------------
else

local teamID 			= Spring.GetLocalTeamID()
local spGetUnitDefID 	= Spring.GetUnitDefID
local spValidUnitID 	= Spring.ValidUnitID
local spAreTeamsAllied 	= Spring.AreTeamsAllied
local spGetUnitTeam 	= Spring.GetUnitTeam


function gadget:Initialize()
  gadgetHandler:AddSyncAction('CommSelection',CommSelection) --Associate "CommSelected" event to "WrapToLuaUI". Reference: http://springrts.com/phpbb/viewtopic.php?f=23&t=24781 "Gadget and Widget Cross Communication"

end
  
function CommSelection(_,playerID, startUnit)
	if (Script.LuaUI('CommSelection')) then --if there is widgets subscribing to "CommSelection" function then:
		local isSpec = Spring.GetSpectatingState() --receiver player is spectator?
		local myAllyID = Spring.GetMyAllyTeamID() --receiver player's alliance?
		local _,_,_,_, eventAllyID = Spring.GetPlayerInfo(playerID, false) --source alliance?
		if isSpec or myAllyID == eventAllyID then
			Script.LuaUI.CommSelection(playerID, startUnit) --send to widgets as event
		end
	end
end

local MakeRealTable = Spring.Utilities.MakeRealTable

function gadget:Save(zip)
	if VFS.FileExists("mission.lua") then -- nothing to do
		return
	end
	if not GG.SaveLoad then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Start Unit Setup failed to access save/load API")
		return
	end
	local toSave = {
		waitingForComm = MakeRealTable(SYNCED.waitingForComm, "Start setup (waitingForComm)"),
		scheduledSpawn = MakeRealTable(SYNCED.scheduledSpawn, "Start setup (scheduledSpawn)"),
		playerSides = MakeRealTable(SYNCED.playerSides, "Start setup (playerSides)"),
		teamSides = MakeRealTable(SYNCED.teamSides, "Start setup (teamSides)"),
		commSpawnedPlayer = MakeRealTable(SYNCED.commSpawnedPlayer, "Start setup (commSpawnedPlayer)"),
		commSpawnedTeam = MakeRealTable(SYNCED.commSpawnedTeam, "Start setup (commSpawnedTeam)"),
	}
	GG.SaveLoad.WriteSaveData(zip, SAVE_FILE, toSave)
end

end
