-- $Id: unit_noselfpwn.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Lag Monitor",
    desc      = "Gives away units of people who are lagging",
    author    = "KingRaptor",
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
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then -- SYNCED ---
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local lineage = {} --keep track of unit ownership: Is populated when gadget give away units, and when units is created. Depopulated when units is destroyed, or is finished construction, or when gadget return units to owner.
local afkTeams = {}
local tickTockCounter = {} --remember how many second a player is in AFK mode. To add a delay before unit transfer commence.
local unitAlreadyFinished = {}
local oldTeam = {} -- team which player was on last frame
local oldAllyTeam = {} -- allyTeam which player was on last frame
local factories = {}
local transferredFactories = {} -- unitDef and health states of the unit that was being produced be the transferred factory

GG.Lagmonitor_activeTeams = {}

local spAddTeamResource   = Spring.AddTeamResource
local spEcho              = Spring.Echo
local spGetGameSeconds    = Spring.GetGameSeconds
local spGetPlayerInfo     = Spring.GetPlayerInfo
local spGetTeamInfo       = Spring.GetTeamInfo
local spGetTeamList       = Spring.GetTeamList
local spGetTeamResources  = Spring.GetTeamResources
local spGetTeamRulesParam = Spring.GetTeamRulesParam
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

local gameFrame = -1

local allyTeamList = Spring.GetAllyTeamList()
for i=1,#allyTeamList do
	local allyTeamID = allyTeamList[i]
	local teamList = Spring.GetTeamList(allyTeamID)
	GG.Lagmonitor_activeTeams[allyTeamID] = {count = #teamList}
	for j=1,#teamList do
		local teamID = teamList[j]
		GG.Lagmonitor_activeTeams[allyTeamID][teamID] = true
	end
end

local LAG_THRESHOLD = 25000
local AFK_THRESHOLD = 30
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function ProductionCancelled(data, factoryTeam)  -- return invested metal if produced unit wasn't recreated
	local ud = UnitDefs[data.producedDefID]
	local returnedMetal = data.build * (ud and ud.metalCost or 0)
	spAddTeamResource(factoryTeam, "metal", returnedMetal)
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if GG.wasMorphedTo and GG.wasMorphedTo[unitID] then --copy lineage for unit Morph
		local newUnitID = GG.wasMorphedTo[unitID]
		local originalTeamIDs = lineage[unitID]
		if originalTeamIDs ~= nil and #originalTeamIDs > 0 then
			-- lineage of the morphed unit will be the same as its pre-morph
			lineage[newUnitID] = {unpack(originalTeamIDs)} --NOTE!: this copy value to new table instead of copying table-reference (to avoid bug)
		end
		unitAlreadyFinished[newUnitID] = true --for reverse build -- what is reverse build?
	end

	lineage[unitID] = nil --to delete any units that do not need returning.
	unitAlreadyFinished[unitID] = nil

	if transferredFactories[unitID] then --the dying unit is the factory we transfered to other team but it haven't continued previous build queue yet. 
		ProductionCancelled(transferredFactories[unitID], unitTeam)  -- refund metal for partial build
		transferredFactories[unitID] = nil
	end
	factories[unitID] = nil
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	--lineage[unitID] = builderID and (lineage[builderID] or spGetUnitTeam(builderID)) or unitTeam
	if builderID ~= nil then
		local builderDefID = spGetUnitDefID(builderID)
		local ud = (builderDefID and UnitDefs[builderDefID])
		if ud and (not ud.isFactory) then --(set ownership to original owner for all units except units from factory so that receipient player didn't lose his investment creating that unit)
			local originalTeamIDs = lineage[builderID]
			if originalTeamIDs ~= nil and #originalTeamIDs > 0 then
				-- lineage of the new unit will be the same as its builder
				lineage[unitID] = {unpack(originalTeamIDs)} --NOTE!: this copy value to new table instead of copying table-reference (to avoid bug)
			end
		elseif transferredFactories[builderID] then --this unit was created inside a recently transfered factory
			local data = transferredFactories[builderID]

			if (data.producedDefID == unitDefID) then --this factory has continued its previous build queue
				data.producedDefID   = nil
				data.expirationFrame = nil
				spSetUnitHealth(unitID, data) --set health of current build to pre-transfer level
			else
				ProductionCancelled(data, unitTeam)  -- different unitDef was created after factory transfer, refund
			end

			transferredFactories[builderID] = nil
		end
	end
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam) --player who finished a unit will own that unit; its lineage will be deleted and the unit will never be returned to the lagging team.
	if unitDefID and UnitDefs[unitDefID] and UnitDefs[unitDefID].isFactory then
		factories[unitID] = {}
	else
		if lineage[unitID] and (not unitAlreadyFinished[unitID]) then --(relinguish ownership for all unit except factories so the returning player has something to do)
			lineage[unitID] = {} --relinguish the original ownership of the unit
		end
	end
	unitAlreadyFinished[unitID] = true --for reverse build
end

GG.allowTransfer = false
--FIXME block transfers for /take but allow manual H/crude list gives
--[[
function gadget:AllowUnitTransfer(unitID, unitDefID, oldTeam, newTeam, capture)
	if capture then return true end
	return GG.allowTransfer
end
]]--

local pActivity = {}

function gadget:RecvLuaMsg(msg, playerID)
	if msg:find("AFK",1,true) then
		pActivity[playerID] = tonumber(msg:sub(4))
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local UPDATE_PERIOD = 50	-- gameframes, 1.67 second

local function GetRecepient(allyTeam, laggers)
	local teams = spGetTeamList(allyTeam)
	local highestRank = 0
	local candidatesForTake = {}
	local target
	-- look for active people to give units to, including AIs
	for i=1,#teams do
		local leader = select(2, spGetTeamInfo(teams[i]))
		local name, active, spectator, _, _, _, _, _, _, customKeys = spGetPlayerInfo(leader)
		if active and not spectator and not laggers[leader] and not spGetTeamRulesParam(teams[i], "WasKilled") then -- only consider giving to someone in position to take!
			candidatesForTake[#candidatesForTake+1] = {name = name, team = teams[i], rank = ((tonumber(customKeys.elo) or 0))}
		end
	end

	-- pick highest rank
	for i=1,#candidatesForTake do
		local player = candidatesForTake[i]
		if player.rank > highestRank then
			highestRank = player.rank
			target = player
		end
	end

	-- no rank info? pick at random
	if not target and #candidatesForTake > 0 then
		target = candidatesForTake[math.random(1,#candidatesForTake)]
	end

	return target
end

local function TransferUnitAndKeepProduction(unitID, newTeamID, given)
	if (factories[unitID]) then --is a factory
		local producedUnitID = spGetUnitIsBuilding(unitID)
		if (producedUnitID) then
			local producedDefID = spGetUnitDefID(producedUnitID)
			if (producedDefID) then
				local data = factories[unitID]
				data.producedDefID   = producedDefID
				data.expirationFrame = gameFrame + 31

				local health, _, paralyzeDamage, captureProgress, buildProgress = spGetUnitHealth(producedUnitID)
				-- following 4 members are compatible with params required by Spring.SetUnitHealth
				data.health   = health
				data.paralyze = paralyzeDamage
				data.capture  = captureProgress
				data.build    = buildProgress

				transferredFactories[unitID] = data

				spSetUnitHealth(producedUnitID, { build = 0 })  -- reset buildProgress to 0 before transfer factory, so no resources are given to AFK team when cancelling current build queue
			end
		end
	end
	spTransferUnit(unitID, newTeamID, given)
end

function gadget:GameFrame(n)
	gameFrame = n;

	if n % 15 == 0 then  -- check factories that haven't recreated the produced unit after transfer
		for factoryID, data in pairs(transferredFactories) do
			if (data.expirationFrame <= gameFrame) then
				ProductionCancelled(data, spGetUnitTeam(factoryID)) --refund metal to current team
				transferredFactories[factoryID] = nil
			end
		end
	end

	if n%UPDATE_PERIOD == 0 then --check every UPDATE_PERIOD-th frame
		local laggers = {}
		local specList = {}
		local players = spGetPlayerList()
		local recepientByAllyTeam = {}
		local gameSecond = spGetGameSeconds()
		local afkPlayers = "" -- remember which player is AFK/Lagg. Information will be sent to 'gui_take_remind.lua' as string

		for i=1,#players do
			local playerID = players[i]
			local name,active,spec,team,allyTeam,ping = spGetPlayerInfo(playerID)

			local justResigned = false
			if oldTeam[playerID] then
				if spec then
					active = false
					spec = false
					team = oldTeam[playerID]
					allyTeam = oldAllyTeam[playerID]
					oldTeam[playerID] = nil
					oldAllyTeam[playerID] = nil
					justResigned = true
				end
			elseif team and not spec then
				oldTeam[playerID] = team
				oldAllyTeam[playerID] = allyTeam
			end

			local afk = gameSecond - (pActivity[playerID] or 0) --mouse activity
			local _,_,_,isAI,_,_ = spGetTeamInfo(team)
			if not (spec or isAI) then
				if (afkTeams[team] == true) then  -- team was AFK
					if active and ping <= 2000 and afk < AFK_THRESHOLD then -- team no longer AFK, return his or her units
						spEcho("Player " .. name .. " is no longer lagging or AFK; returning all his or her units")
						GG.allowTransfer = true
						
						for unitID, teamList in pairs(lineage) do --Return unit to the oldest inheritor (or to original owner if possible)
							local delete = false;
							for i=1,#teamList do
								local uteam = teamList[i];
								if (uteam == team) then
									if allyTeam == spGetUnitAllyTeam(unitID) then
										TransferUnitAndKeepProduction(unitID, team, true)
										delete = true
									end
								end
								-- remove all teams after the previous owner (inclusive)
								if (delete) then
									lineage[unitID][i] = nil;
								end
							end
						end
						GG.allowTransfer = false
						afkTeams[team] = nil
						GG.Lagmonitor_activeTeams[allyTeam].count = GG.Lagmonitor_activeTeams[allyTeam].count + 1
						GG.Lagmonitor_activeTeams[allyTeam][team] = true
					end
				end
				if (not active or ping >= LAG_THRESHOLD or afk > AFK_THRESHOLD) then -- player afk: mark him, except AIs
					afkPlayers = afkPlayers .. (10000 + playerID*100 + allyTeam) --compose a string of number that contain playerID & allyTeam information
					tickTockCounter[playerID] = (tickTockCounter[playerID] or 0) + 1 --tick tock counter ++. count-up 1
					if tickTockCounter[playerID] >= 2 or justResigned then --team is to be tagged as lagg-er/AFK-er after 3 passes (3 times 50frame = 5 second).
						local units = spGetTeamUnits(team)
						if units~=nil and #units > 0 then
							laggers[playerID] = {name = name, team = team, allyTeam = allyTeam, units = units, resigned = justResigned}
						end
					end
				else --if not at all AFK or lagging: then...
					tickTockCounter[playerID] = nil -- empty tick-tock clock. We want to reset the counter when the player return.
				end
			elseif (spec and not isAI) then
				specList[playerID] = true --record spectator list in non-AI team
			end
		end
		afkPlayers = afkPlayers .. "#".. players[#players] --cap the string with the largest playerID information. ie: (string)1010219899#98 can be read like this-> (1=dummy) id:01 ally:02, (1=dummy) id:98 ally:99, (#=dummy) highestID:98
		SendToUnsynced("LagmonitorAFK",afkPlayers) --tell widget about AFK list (widget need to deserialize this string)

		for playerID, lagger in pairs(laggers) do
			-- FIRST! check if everyone else on the team is also lagging
			local team = lagger.team
			local allyTeam = lagger.allyTeam
			local playersInTeam = spGetPlayerList(team, true) --return only active player
			local discontinue = false
			for j=1,#playersInTeam do
				local playerID = playersInTeam[j]
				if not (laggers[playerID] or specList[playerID]) then --Note: we need the extra specList check because Spectators is sharing same teamID as team 0
					discontinue = true	-- someone on same team is not lagging & not spec, don't move units around!
					break
				end
			end

			-- no-one on team not lagging (the likely situation in absence of commshare), continue working
			if not discontinue then
				recepientByAllyTeam[allyTeam] = recepientByAllyTeam[allyTeam] or GetRecepient(allyTeam, laggers)

				-- okay, we have someone to give to, prep transfer
				if recepientByAllyTeam[allyTeam] then
					if (afkTeams[team] == nil) then -- if team was not an AFK-er (but now is an AFK-er) then process the following... else do nothing for the same AFK-er.
						--REASON for WHY THE ABOVE^ CHECK was ADDED: if someone sent units to this AFK-er then (typically) var:"laggers[playerID]" will be filled twice for the same player (line 161) & normally unit will be sent (redirected) to the non-AFK-er (line 198), but (unfortunately) equation:"GG.Lagmonitor_activeTeams[allyTeam].count = GG.Lagmonitor_activeTeams[allyTeam].count - 1" will also run twice for the AFK ally (line 193) and it will effect 'unit_mex_overdrive.lua on line 999'.
						GG.Lagmonitor_activeTeams[allyTeam].count = GG.Lagmonitor_activeTeams[allyTeam].count - 1
						GG.Lagmonitor_activeTeams[allyTeam][team] = false
					end
					afkTeams[team] = true --mark team as AFK
					local units = lagger.units or {}
					if #units > 0 then -- transfer units when number of units in AFK team is > 0
						-- Transfer Units
						GG.allowTransfer = true
						for j=1,#units do
							local unit = units[j]
							if allyTeam == spGetUnitAllyTeam(unit) then
								-- add this team to the lineage list, then send the unit away
								if lineage[unit] == nil then
									lineage[unit] = { team }
								else
									-- this unit belonged to someone else before me, add me to the end of the list
									lineage[unit][#lineage[unit]+1] = team
								end
								TransferUnitAndKeepProduction(unit, recepientByAllyTeam[allyTeam].team, true)
							end
						end
						GG.allowTransfer = false

						-- Transfer metal to reviever, engine handles excess going to allies if it occurs.
						local spareMetal = spGetTeamResources(team,"metal") or 0
						spUseTeamResource(team,"metal",spareMetal)
						spAddTeamResource(recepientByAllyTeam[allyTeam].team,"metal",spareMetal)

						-- Send message
						if lagger.resigned then
							spEcho(lagger.name .. " resigned, giving all units to ".. recepientByAllyTeam[allyTeam].name .. " (ally #".. allyTeam ..")")
						else
							spEcho("Giving all units of "..lagger.name .. " to " .. recepientByAllyTeam[allyTeam].name .. " due to lag/AFK (ally #".. allyTeam ..")")
						end
					end
				end	-- if
			end	-- if
		end	-- for
	end	-- if
end

function gadget:GameOver()
	gadgetHandler:RemoveGadget() --shutdown after game over, so that at end of a REPLAY Lagmonitor doesn't bounce unit among player
end

else -- UNSYNCED ---

	function WrapToLuaUI(_,afkPlayer)
		if (Script.LuaUI('LagmonitorAFK')) then
			Script.LuaUI.LagmonitorAFK(afkPlayer)
		end
	end

	function gadget:Initialize() --Reference: http://springrts.com/phpbb/viewtopic.php?f=23&t=24781 "Gadget and Widget Cross Communication"
		gadgetHandler:AddSyncAction('LagmonitorAFK',WrapToLuaUI)
	end

end