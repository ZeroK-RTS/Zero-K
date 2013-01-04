-- $Id: unit_noselfpwn.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Lag Monitor",
    desc      = "Gives away units of people who are lagging",
    author    = "KingRaptor",
    date      = "11/5/2012",
    license   = "Public domain",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end
--Revision 29-th?
--------------------------------------------------------------------------------
--List of stuff in this gadget (to help us remember stuff for future debugging/improvement):

--Main logic:
--1) Periodic(CheckAFK & Ping) ---> mark player as AFK/Lagging --->  Check if player has Shared Command --> Check for Candidate with highest ELO -- > Loop(send unit away to candidate & remember unit Ownership).
--2) Periodic(CheckAFK & Ping) ---> IF AFK/Lagger is no longer lagging --> Return all units & delete unit Ownership.

--Other logics:
--1) If Owner's builder (constructor) created a unit --> Owner inherit the ownership to that unit
--2) If Taker finished an Owner's unit --> the unit belong to Taker
--3) wait 3 strike (3 time AFK & Ping) before --> mark player as AFK/Lagging
--4) being AFK/Lag --> deduct the perceived ELO by 250 each
--5) request "TAKE" --> temporary increase the perceived ELO by 250

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

GG.Lagmonitor_activeTeams = {}

local spGetUnitDefID = Spring.GetUnitDefID

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

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	lineage[unitID] = nil --to delete any units that do not need returning.
	unitAlreadyFinished[unitID] = nil
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	--lineage[unitID] = builderID and (lineage[builderID] or Spring.GetUnitTeam(builderID)) or unitTeam
	if builderID ~= nil then
		local builderDefID = spGetUnitDefID(builderID)
		local ud = (builderDefID and UnitDefs[builderDefID])
		if ud and (not ud.isFactory) then --(set ownership to original owner for all units except units from factory so that receipient player didn't loose his investment creating that unit)
			local originalTeamID = lineage[builderID]
			if originalTeamID ~= nil then
				lineage[unitID] = originalTeamID --to return newly created unit to the owner of the constructor.
			end
		end
	end
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam) --player who finished a unit will own that unit; its lineage will be deleted and the unit will never be returned to the lagging team.
	if lineage[unitID] and (not unitAlreadyFinished[unitID]) and not (unitDefID and UnitDefs[unitDefID] and UnitDefs[unitDefID].isFactory) then --(religuish ownership for all unit except factories so the returning player has something to do)
		lineage[unitID] = nil --relinguish the original ownership of the unit
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
	local teams = Spring.GetTeamList(allyTeam)
	local highestRank = 0
	local candidatesForTake = {}
	local target
	-- look for active people to give units to, including AIs
	for i=1,#teams do
		local leader = select(2, Spring.GetTeamInfo(teams[i]))
		local name, active, spectator, _, _, _, _, _, _, customKeys = Spring.GetPlayerInfo(leader)
		if active and not spectator and not laggers[leader] and not Spring.GetTeamRulesParam(teams[i], "WasKilled") then -- only consider giving to someone in position to take!
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

function gadget:GameFrame(n)
 
	if n%UPDATE_PERIOD == 0 then --check every UPDATE_PERIOD-th frame
		local laggers = {}
		local players = Spring.GetPlayerList()
		local recepientByAllyTeam = {}
		local gameSecond = Spring.GetGameSeconds()
		local afkPlayer = "" -- remember which player is AFK/Lagg. Information will be sent to 'gui_take_remind.lua' as string
		
		for i=1,#players do
			local playerID = players[i]
			local name,active,spec,team,allyTeam,ping = Spring.GetPlayerInfo(playerID)
			
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
			
			local afk = Spring.GetGameSeconds() - (pActivity[playerID] or 0)
			local _,_,_,isAI,_,_ = Spring.GetTeamInfo(team)
			if not spec and not isAI then 
				if (afkTeams[team] == true) then  -- team was AFK 
					if active and ping <= 2000 and afk < AFK_THRESHOLD then -- team no longer AFK, return his or her units
						Spring.Echo("Player " .. name .. " is no longer lagging or AFK; returning all his or her units")
						GG.allowTransfer = true
						local spTransferUnit = Spring.TransferUnit
						for unitID, uteam in pairs(lineage) do
							if (uteam == team) then
								spTransferUnit(unitID, team, true)
								lineage[unitID] = nil
							end
						end
						GG.allowTransfer = false
						afkTeams[team] = nil
						GG.Lagmonitor_activeTeams[allyTeam].count = GG.Lagmonitor_activeTeams[allyTeam].count + 1
						GG.Lagmonitor_activeTeams[allyTeam][team] = true
					end 
				end
				if (not active or ping >= LAG_THRESHOLD or afk > AFK_THRESHOLD) then -- player afk: mark him, except AIs
					afkPlayer = afkPlayer .. (10000 + playerID*100 + allyTeam) --compose a string of number that contain playerID & allyTeam information
					tickTockCounter[playerID] = (tickTockCounter[playerID] or 0) + 1 --tick tock counter ++. count-up 1
					if tickTockCounter[playerID] >= 2 or justResigned then --team is to be tagged as lagg-er/AFK-er after 3 passes (3 times 50frame = 5 second).
						local units = Spring.GetTeamUnits(team)
						if units ~= nil and #units > 0 then 
							laggers[playerID] = {name = name, team = team, allyTeam = allyTeam, units = units, resigned = justResigned}
						end
					end
				else --if not at all AFK or lagging: then...
					tickTockCounter[playerID] = nil -- empty tick-tock clock. We want to reset the counter when the player return.
				end
			end
		end
		afkPlayer = afkPlayer .. "#".. players[#players] --cap the string with the largest playerID information. ie: (string)1010219899#98 can be read like this-> id:01 ally:02, id:98 ally:99, highestID:98  
		SendToUnsynced("LagmonitorAFK",afkPlayer) --tell widget about AFK list
		
		for playerID, data in pairs(laggers) do
			-- FIRST! check if everyone else on the team is also lagging
			local team = data.team
			local allyTeam = data.allyTeam
			local playersInTeam = Spring.GetPlayerList(team, true)
			local discontinue = false
			for j=1,#playersInTeam do
				if not laggers[playersInTeam[j]] then
					discontinue = true	-- someone on same team is not lagging, don't move units around!
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
					local units = data.units or {}
					if #units > 0 then -- transfer units when number of units in AFK team is > 0
						-- Transfer Units
						GG.allowTransfer = true
						local spTransferUnit = Spring.TransferUnit
						for j=1,#units do
							lineage[units[j]] = (lineage[units[j]] or team) --set the lineage to the original owner, but if owner is "nil" then use the current (lagging team) as the original owner & then send the unit away...
							spTransferUnit(units[j], recepientByAllyTeam[allyTeam].team, true)
						end
						GG.allowTransfer = false
						
						-- Transfer metal to reviever, engine handles excess going to allies if it occurs.
						local spareMetal = select(1,Spring.GetTeamResources(team,"m"))
						Spring.UseTeamResource(team,"m",-spareMetal)
						Spring.AddTeamResource(recepientByAllyTeam[allyTeam].team,"m",spareMetal)
						
						-- Send message
						if data.resigned then
							Spring.Echo(data.name .. " resigned, giving all units to ".. recepientByAllyTeam[allyTeam].name .. " (ally #".. allyTeam ..")")
						else
							Spring.Echo("Giving all units of "..data.name .. " to " .. recepientByAllyTeam[allyTeam].name .. " due to lag/AFK (ally #".. allyTeam ..")")
						end
					end
				end	-- if
			end	-- if
		end	-- for
	end	-- if
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
else-- UNSYNCED ---
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
	function WrapToLuaUI(_,afkPlayer)
		if (Script.LuaUI('LagmonitorAFK')) then
			Script.LuaUI.LagmonitorAFK(afkPlayer)
		end
	end

	function gadget:Initialize() --Reference: http://springrts.com/phpbb/viewtopic.php?f=23&t=24781 "Gadget and Widget Cross Communication"
		gadgetHandler:AddSyncAction('LagmonitorAFK',WrapToLuaUI)
	end

end