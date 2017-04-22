--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
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

--Other logics:
--1) If Owner's builder (constructor) created a unit --> Owner inherit the ownership to that unit
--2) If Taker finished an Owner's unit --> the unit belong to Taker
--3) wait 3 strike (3 time AFK & Ping) before --> mark player as AFK/Lagging

--Everything else: anti-bug, syntax, methods, ect
local playerLineageUnits = {} --keep track of unit ownership: Is populated when gadget give away units, and when units is created. Depopulated when units is destroyed, or is finished construction, or when gadget return units to owner.
local teamResourceShare = {}
local allyTeamResourceShares = {}
local unitAlreadyFinished = {}
local factories = {}
local transferredFactories = {} -- unitDef and health states of the unit that was being produced be the transferred factory

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

local LAG_THRESHOLD = 25000
local AFK_THRESHOLD = 30 -- In seconds
local FACTORY_UPDATE_PERIOD = 15 -- gameframes

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function GetTeamName(teamID)
	local _, leaderID, _, isAiTeam = Spring.GetTeamInfo(teamID)
	if isAiTeam then
		return select(2, Spring.GetAIInfo()) or "Unknown AI on team " .. (teamID or "???")
	end
	return select(1, Spring.GetPlayerInfo(leaderID)) or ("Unknown Player on team " .. (teamID or "???"))
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

local function ApplyProductionCancelRefund(data, factoryTeam)  -- return invested metal if produced unit wasn't recreated
	local ud = UnitDefs[data.producedDefID]
	local returnedMetal = data.build * (ud and ud.metalCost or 0)
	spAddTeamResource(factoryTeam, "metal", returnedMetal)
end

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

	if transferredFactories[unitID] then --the dying unit is the factory we transfered to other team but it haven't continued previous build queue yet. 
		ApplyProductionCancelRefund(transferredFactories[unitID], unitTeam)  -- refund metal for partial build
		transferredFactories[unitID] = nil
	end
	factories[unitID] = nil
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if not builderID then
		return
	end
	
	local builderDefID = spGetUnitDefID(builderID)
	local ud = (builderDefID and UnitDefs[builderDefID])
	if ud and (not ud.isFactory) then 
		--(set ownership to original owner for all units except units from factory so that receipient player didn't lose his investment creating that unit)
		local originalPlayerIDs = playerLineageUnits[builderID]
		if originalPlayerIDs ~= nil and #originalPlayerIDs > 0 then
			-- playerLineageUnits of the new unit will be the same as its builder
			playerLineageUnits[unitID] = {unpack(originalPlayerIDs)} --NOTE!: this copy value to new table instead of copying table-reference (to avoid bug)
		end
	elseif transferredFactories[builderID] then --this unit was created inside a recently transfered factory
		local data = transferredFactories[builderID]

		if (data.producedDefID == unitDefID) then --this factory has continued its previous build queue
			data.producedDefID   = nil
			data.expirationFrame = nil
			spSetUnitHealth(unitID, data) --set health of current build to pre-transfer level
		else
			ApplyProductionCancelRefund(data, unitTeam)  -- different unitDef was created after factory transfer, refund
		end

		transferredFactories[builderID] = nil
	end
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	--player who finished a unit will own that unit; its playerLineageUnits will be deleted and the unit will never be returned to the lagging team.
	if unitDefID and UnitDefs[unitDefID] and UnitDefs[unitDefID].isFactory then
		factories[unitID] = {}
	else
		if playerLineageUnits[unitID] and (not unitAlreadyFinished[unitID]) then 
		--(relinguish ownership for all unit except factories so the returning player has something to do)
			playerLineageUnits[unitID] = {} --relinguish the original ownership of the unit
		end
	end
	unitAlreadyFinished[unitID] = true --for reverse build
end

local mouseActivityTime = {}

function gadget:RecvLuaMsg(msg, playerID)
	if msg:find("AFK",1,true) then
		mouseActivityTime[playerID] = tonumber(msg:sub(4))
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit Transfer, handles factories

local function TransferUnitAndKeepProduction(unitID, newTeamID)
	if (factories[unitID]) then --is a factory
		local producedUnitID = spGetUnitIsBuilding(unitID)
		if (producedUnitID) then
			local producedDefID = spGetUnitDefID(producedUnitID)
			if (producedDefID) then
				local data = factories[unitID]
				data.producedDefID   = producedDefID
				data.expirationFrame = Spring.GetGameFrame() + 31

				local health, _, paralyzeDamage, captureProgress, buildProgress = spGetUnitHealth(producedUnitID)
				-- following 4 members are compatible with params required by Spring.SetUnitHealth
				data.health   = health
				data.paralyze = paralyzeDamage
				data.capture  = captureProgress
				data.build    = buildProgress

				transferredFactories[unitID] = data

				spSetUnitHealth(producedUnitID, {build = 0})  -- reset buildProgress to 0 before transfer factory, so no resources are given to AFK team when cancelling current build queue
			end
		end
	end
	GG.allowTransfer = true
	spTransferUnit(unitID, newTeamID, true)
	GG.allowTransfer = false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Activity updates

local function GetPlayerActivity(playerID)
	local name, active, spec, team, allyTeam, ping, _, _, _, customKeys = spGetPlayerInfo(playerID)
	
	if spec or not (active and ping <= 2000) then
		return false
	end
	
	local lastActionTime = spGetGameSeconds() - (mouseActivityTime[playerID] or 0)
	
	if lastActionTime >= AFK_THRESHOLD then
		return
	end
	
	return customKeys.elo or 0
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
						TransferUnitAndKeepProduction(unitID, teamID)
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
		
		if unitsRecieved then
			spEcho("game_message: Player " .. playerName .. " is no longer lagging or AFK; returning all their units.")
		end
	end
	
	-- Note that AIs do not have a rank so a team with just an AI will have teamRank = false
	return resourceShare, teamRank
end

local function UpdateAllyTeamActivity(allyTeamID)
	local teamList = Spring.GetTeamList(allyTeamID)
	
	local totalResourceShares = 0
	local giveAwayTeams = {}
	local recieveRank = false
	local recieveTeamID = false
	
	for i = 1, #teamList do
		local teamID = teamList[i]
		local resourceShare, teamRank = UpdateTeamActivity(teamID)
		totalResourceShares = totalResourceShares + resourceShare
		if resourceShare == 0 then
			if teamResourceShare[teamID] ~= 0 then
				-- The team is newly afk.
				giveAwayTeams[#giveAwayTeams + 1] = teamID
			end
		elseif teamRank and ((not recieveRank) or (teamRank > recieveRank)) then
			recieveRank = teamRank
			recieveTeamID = teamID
		end
		teamResourceShare[teamID] = resourceShare
	end
	allyTeamResourceShares[allyTeamID] = totalResourceShares
	
	if not recieveTeamID then
		-- Nobody can recieve units so there is not much more to do
		for i = 1, #giveAwayTeams do
			local giveTeamID = giveAwayTeams[i]
			local giveResigned = select(3, Spring.GetTeamInfo(giveTeamID))
			if giveResigned then
				spEcho("game_message: " .. GetTeamName(giveTeamID) .. " resigned")
			end
		end
		return
	end
	
	for i = 1, #giveAwayTeams do
		local giveTeamID = giveAwayTeams[i]
		local givePlayerID = TeamIDToPlayerID(giveTeamID)
		
		-- Energy share is not set because the storage needs to be full for full overdrive.
		-- Also energy income is mostly private and a large energy influx to the rest of the 
		-- team is likely to be wasted or overdriven inefficently.
		
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
					TransferUnitAndKeepProduction(unitID, recieveTeamID)
				end
			end
			GG.allowTransfer = false
		end
		
		local recieveName = GetTeamName(recieveTeamID)
		local giveName = GetTeamName(giveTeamID)
		local giveResigned = select(3, Spring.GetTeamInfo(giveTeamID))
		
		-- Send message
		if giveResigned then
			spEcho("game_message: " .. giveName .. " resigned, giving all units to " .. recieveName)
		elseif #units > 0 then
			spEcho("game_message: Giving all units of ".. giveName .. " to " .. recieveName .. " due to lag/AFK")
		end
	end
end

function gadget:GameFrame(n)
	if n % FACTORY_UPDATE_PERIOD == 0 then  -- check factories that haven't recreated the produced unit after transfer
		for factoryID, data in pairs(transferredFactories) do
			if (data.expirationFrame <= n) then
				ApplyProductionCancelRefund(data, spGetUnitTeam(factoryID)) --refund metal to current team
				transferredFactories[factoryID] = nil
			end
		end
	end

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
	end

	GG.Lagmonitor = externalFunctions
end
