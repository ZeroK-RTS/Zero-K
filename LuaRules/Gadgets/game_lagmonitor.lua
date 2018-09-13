--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if gadgetHandler:IsSyncedCode() then
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Lag Monitor",
    desc      = "Gives away units of people who are lagging",
    author    = "KingRaptor, GoogleFrog rewrite",
    date      = "11/5/2012", --6/11/2013
    license   = "Public domain",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end
--------------------------------------------------------------------------------
--List of stuff in this gadget (to help us remember stuff for future debugging/improvement):

--Main logic:
--1) Periodic(CheckAFK & Ping) ---> mark player as AFK/Lagging --->  Check if player has Shared Command --> Check for Candidate with highest ELO -- > Loop(send unit away to candidate & remember unit Ownership).
--2) Periodic(CheckAFK & Ping) ---> IF AFK/Lagger is no longer lagging --> Return all units & delete unit Ownership.

--Everything else: anti-bug, syntax, methods, ect
local playerLineageUnits = {} --keep track of unit ownership: Is populated when gadget give away units, and when units is created. Depopulated when units is destroyed, or is finished construction, or when gadget return units to owner.
local teamResourceShare = {}
local allyTeamResourceShares = {}
local unitAlreadyFinished = {}

local spAddTeamResource   = Spring.AddTeamResource
local spEcho              = Spring.Echo
local spGetGameSeconds    = Spring.GetGameSeconds
local spGetPlayerInfo     = Spring.GetPlayerInfo
local spGetTeamInfo       = Spring.GetTeamInfo
local spGetTeamList       = Spring.GetTeamList
local spGetTeamResources  = Spring.GetTeamResources
local spGetTeamUnits      = Spring.GetTeamUnits
local spGetUnitAllyTeam   = Spring.GetUnitAllyTeam
local spGetUnitDefID      = Spring.GetUnitDefID
local spGetUnitTeam       = Spring.GetUnitTeam
local spGetPlayerList     = Spring.GetPlayerList
local spTransferUnit      = Spring.TransferUnit
local spUseTeamResource   = Spring.UseTeamResource
local spGetUnitIsBuilding = Spring.GetUnitIsBuilding
local spGetUnitHealth     = Spring.GetUnitHealth
local spSetUnitHealth     = Spring.SetUnitHealth

include("LuaRules/Configs/constants.lua")

-- in seconds. The delay considered is (ping + time spent afk)
local TO_AFK_THRESHOLD = 30 -- going above this marks you AFK
local FROM_AFK_THRESHOLD = 5 -- going below this marks you non-AFK

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local teamNames = {}
local function GetTeamName(teamID)
	return teamNames[teamID] or ("Unknown Player on team " .. (teamID or "???"))
end

local function PlayerIDToTeamID(playerID)
	local _, _, spectator, teamID = spGetPlayerInfo(playerID)
	if spectator then
		return false
	end
	return teamID
end

local function TeamIDToPlayerID(teamID)
	return select(2, spGetTeamInfo(teamID))
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Factory and Lineage

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if GG.wasMorphedTo and GG.wasMorphedTo[unitID] then --copy playerLineageUnits for unit Morph
		local newUnitID = GG.wasMorphedTo[unitID]
		local originalPlayerIDs = playerLineageUnits[unitID]
		if originalPlayerIDs ~= nil and #originalPlayerIDs > 0 then
			-- playerLineageUnits of the morphed unit will be the same as its pre-morph
			playerLineageUnits[newUnitID] = {unpack(originalPlayerIDs)} --NOTE!: this copy value to new table instead of copying table-reference (to avoid bug)
		end
		unitAlreadyFinished[newUnitID] = true --for reverse build -- what is reverse build?
	end

	playerLineageUnits[unitID] = nil --to delete any units that do not need returning.
	unitAlreadyFinished[unitID] = nil
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	if unitAlreadyFinished[unitID] or not playerLineageUnits[unitID] then
		return
	end

	if Spring.GetUnitRulesParam(unitID, "ploppee") then
		return
	end

	unitAlreadyFinished[unitID] = true
	playerLineageUnits[unitID] = {}
end

local mouseActivityTime = {}

local function CheckMouseActivity(msg, playerID)
	if msg:find("AFK",1,true) then
		mouseActivityTime[playerID] = tonumber(msg:sub(4))
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit Transfer, handles factories

local function TransferUnit(unitID, newTeamID)
	GG.allowTransfer = true
	spTransferUnit(unitID, newTeamID, true)
	GG.allowTransfer = false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Activity updates

local playerIsAfk = {}
local function GetPlayerActivity(playerID)
	local name, active, spec, team, allyTeam, ping, _, _, _, customKeys = spGetPlayerInfo(playerID)
	
	if spec or not (active and ping <= 2000) then
		return false
	end
	
	local lastActionTime = spGetGameSeconds() - (mouseActivityTime[playerID] or 0)
	
	if lastActionTime >= TO_AFK_THRESHOLD
	or lastActionTime >= FROM_AFK_THRESHOLD and playerIsAfk[playerID] then
		playerIsAfk[playerID] = true
		return false
	end

	playerIsAfk[playerID] = false
	return customKeys.elo and tonumber(customKeys.elo) or 0
end

local function UpdateTeamActivity(teamID)
	local resourceShare = 0
	local teamRank = false
	local players = spGetPlayerList(teamID)
	for i = 1, #players do
		local activeRank = GetPlayerActivity(players[i])
		if activeRank then
			resourceShare = resourceShare + 1
			if (not teamRank) or (activeRank > teamRank) then
				teamRank = activeRank
			end
		end
	end
	
	local _, leaderID, _, isAiTeam, _, allyTeamID = spGetTeamInfo(teamID)
	if isAiTeam then
		-- Treat the AI as an active player.
		resourceShare = resourceShare + 1
	end
	
	if resourceShare > 0 and teamResourceShare[teamID] == 0 then
		local playerName = Spring.GetPlayerInfo(leaderID)
		local unitsRecieved = false
		
		for unitID, playerList in pairs(playerLineageUnits) do --Return unit to the oldest inheritor (or to original owner if possible)
			local delete = false
			local unitAllyTeamID = spGetUnitAllyTeam(unitID)
			if unitAllyTeamID == allyTeamID then
				for i = 1, #playerList do
					local otherPlayerID = playerList[i]
					local otherTeamID = PlayerIDToTeamID(otherPlayerID)
					if (otherTeamID == teamID) then
						TransferUnit(unitID, teamID)
						unitsRecieved = true
						delete = true
					end
					-- remove all teams after the previous owner (inclusive)
					if delete then
						playerLineageUnits[unitID][i] = nil
					end
				end
			end
		end
		
		SendToUnsynced("TeamUnafked", teamID)
		spEcho("TeamUnafked", teamID)
		if unitsRecieved then
			spEcho("game_message: Player " .. playerName .. " is no longer lagging or AFK; returning all their units.")
		end
	end
	
	-- Note that AIs do not have a rank so a team with just an AI will have teamRank = false
	return resourceShare, teamRank
end

local function GetRawTeamShare(teamID)
	local _, _, isDead, isAiTeam = spGetTeamInfo(teamID)
	if isDead then
		return 0
	end

	local shares = 0
	if isAiTeam then
		shares = shares + 1
	end

	local players = spGetPlayerList(teamID)
	for i = 1, #players do
		local playerID = players[i]
		local _, active, spec = spGetPlayerInfo(playerID)
		if active and not spec then
			shares = shares + 1
		end
	end

	return shares
end

local function GiveAwayTeam(giveTeamID, receiveTeamID)
	local givePlayerID = TeamIDToPlayerID(giveTeamID)

	local units = spGetTeamUnits(giveTeamID) or {}
	if #units > 0 then -- transfer units when number of units in AFK team is > 0
		-- Transfer Units
		GG.allowTransfer = true
		for j = 1, #units do
			local unitID = units[j]
			if allyTeamID == spGetUnitAllyTeam(unitID) then
				if givePlayerID then
					-- add this team to the playerLineageUnits list, then send the unit away
					if playerLineageUnits[unitID] == nil then
						playerLineageUnits[unitID] = {givePlayerID}
					else
						-- this unit belonged to someone else before me, add me to the end of the list
						playerLineageUnits[unitID][#playerLineageUnits[unitID]+1] = givePlayerID
					end
				end
				TransferUnit(unitID, receiveTeamID)
			end
		end
		GG.allowTransfer = false
	end

	local receiveName = GetTeamName(receiveTeamID)
	local giveName = GetTeamName(giveTeamID)
	local giveResigned = select(3, Spring.GetTeamInfo(giveTeamID))

	SendToUnsynced("TeamTaken", giveTeamID, receiveTeamID)
	spEcho("TeamTaken", giveTeamID, receiveTeamID)
	if giveResigned then
		spEcho("game_message: " .. giveName .. " resigned, giving all units to " .. receiveName)
	elseif #units > 0 then
		spEcho("game_message: Giving all units of ".. giveName .. " to " .. receiveName .. " due to lag/AFK")
	end
end

local function CheckTake(msg, playerID)
	local _, _, isSpec, teamID, allyTeamID = Spring.GetPlayerInfo(playerID)
	if msg ~= "afk_take" or isSpec then
		return
	end

	local teamList = Spring.GetTeamList(allyTeamID)

	spEcho("CheckTake p/t", playerID, teamID)
	for i = 1, #teamList do
		local giveTeamID = teamList[i]
		if teamResourceShare[giveTeamID] == 0 and giveTeamID ~= teamID then
			GiveAwayTeam(giveTeamID, teamID)
		end
	end
end

function gadget:RecvLuaMsg(msg, playerID)
	CheckMouseActivity(msg, playerID)
	CheckTake(msg, playerID)
end

local function UpdateAllyTeamActivity(allyTeamID)
	local teamList = Spring.GetTeamList(allyTeamID)
	
	local totalResourceShares = 0
	local giveAwayTeams = {}
	local onlyBotsLeft = true
	
	for i = 1, #teamList do
		local teamID = teamList[i]
		local resourceShare, teamRank = UpdateTeamActivity(teamID)
		totalResourceShares = totalResourceShares + resourceShare
		if resourceShare == 0 then
			if teamResourceShare[teamID] ~= 0 then
				-- The team is newly afk.
				giveAwayTeams[#giveAwayTeams + 1] = teamID
			end
		elseif teamRank then
			onlyBotsLeft = false
		end
		teamResourceShare[teamID] = resourceShare
	end
	allyTeamResourceShares[allyTeamID] = totalResourceShares

	for i = 1, #giveAwayTeams do
		local giveTeamID = giveAwayTeams[i]
		if select(3, Spring.GetTeamInfo(giveTeamID)) then
			-- TODO chat is horrible ui, better make a gui popup (-> PlayerChanged should suffice?)
			spEcho("game_message: " .. GetTeamName(giveTeamID) .. " resigned")
		else
			SendToUnsynced("TeamAfked", giveTeamID)
			spEcho("TeamAfked", giveTeamID)
		end
	end

	-- a human can have bot teammates; they are not eligible to receive his units but would still drain his income
	-- in that case, the human gets to keep his income (some people like to queue up a lot of expensive stuff)
	-- TODO: if there's [1 human afker, 1 human playing, and 1 bot] the playing human should prolly get 2 shares and bot 1
	if onlyBotsLeft and totalResourceShares > 0 and #giveAwayTeams > 0 then
		totalResourceShares = 0
		for i = 1, #teamList do
			local teamID = teamList[i]
			local rawShare = GetRawTeamShare(teamID)
			totalResourceShares = totalResourceShares + rawShare
			teamResourceShare[teamID] = rawShare
		end
		allyTeamResourceShares[allyTeamID] = totalResourceShares
	end
end

function gadget:GameFrame(n)
	if n % TEAM_SLOWUPDATE_RATE == 0 then -- Just before overdrive
		local allyTeamList = Spring.GetAllyTeamList()
		for i = 1, #allyTeamList do
			UpdateAllyTeamActivity(allyTeamList[i])
		end
	end 
end

function gadget:GameOver()
	gadgetHandler:RemoveGadget() --shutdown after game over, so that at end of a REPLAY Lagmonitor doesn't bounce unit among player
end

----------------------------------------------------------------------------------------
-- External Functions
----------------------------------------------------------------------------------------
local externalFunctions = {}
function externalFunctions.GetResourceShares()
	return allyTeamResourceShares, teamResourceShare
end

function gadget:Initialize()
	local teamList = Spring.GetTeamList()
	for i = 1, #teamList do
		local teamID = teamList[i]
		local allyTeamID = select(6, spGetTeamInfo(teamID))
		teamResourceShare[teamID] = 1
		allyTeamResourceShares[allyTeamID] = (allyTeamResourceShares[allyTeamID] or 0) + 1

		local _, playerID, _, isAI = Spring.GetTeamInfo(teamID)
		if isAI then
			teamNames[teamID] = select(2, Spring.GetAIInfo(teamID))
		else
			teamNames[teamID] = Spring.GetPlayerInfo(playerID)
		end
	end

	GG.Lagmonitor = externalFunctions
end

else -- unsynced
	local function WrapToLuaUI(cmd, arg1, arg2)
		if not Script.LuaUI(cmd) then
			return
		end
		Script.LuaUI[cmd](arg1, arg2)
	end

	function gadget:Initialize()
		gadgetHandler:AddSyncAction("TeamAfked",   WrapToLuaUI)
		gadgetHandler:AddSyncAction("TeamTaken",   WrapToLuaUI)
		gadgetHandler:AddSyncAction("TeamUnafked", WrapToLuaUI)
	end

	function gadget:Shutdown()
		gadgetHandler:RemoveSyncAction("TeamAfked")
		gadgetHandler:RemoveSyncAction("TeamTaken")
		gadgetHandler:RemoveSyncAction("TeamUnafked")
	end
end
