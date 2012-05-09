-- $Id: unit_noselfpwn.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Lag Monitor",
    desc      = "Gives away units of people who are lagging",
    author    = "KingRaptor",
    date      = "9/5/2012",
    license   = "Public domain",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end
--Revision Million-th
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  
if (not gadgetHandler:IsSyncedCode()) then
  return false  --  silent removal
end

  
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local lineage = {}
local afkTeams = {}
local tickTockCounter = {}
local unitAlreadyFinished = {}

GG.Lagmonitor_activeTeams = {}

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
	lineage[unitID] = nil
	unitAlreadyFinished[unitID] = nil
end

-- Only lineage for factories so the returning player has something to do.
function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	--lineage[unitID] = builderID and (lineage[builderID] or Spring.GetUnitTeam(builderID)) or unitTeam
	if builderID ~= nil then
		local originalTeamID = lineage[builderID]
		if originalTeamID ~= nil then
			lineage[unitID] = originalTeamID
		end
	end
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	if lineage[unitID] and (not unitAlreadyFinished[unitID]) and not (unitDefID and UnitDefs[unitDefID] and UnitDefs[unitDefID].isFactory) then
		lineage[unitID] = nil
	end
	unitAlreadyFinished[unitID] = true -- reverse build
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
local UPDATE_PERIOD = 50	-- gameframes


local function GetRecepient(allyTeam, laggers)
	local teams = Spring.GetTeamList(allyTeam)
	local highestRank = 0
	local candidatesForTake = {}
	local target
	-- look for active people to give units to, including AIs
	for i=1,#teams do
		local leader = select(2, Spring.GetTeamInfo(teams[i]))
		local name, active, spectator, _, _, _, _, _, _, customKeys = Spring.GetPlayerInfo(leader)
		if active and not spectator and not laggers[leader] then	-- only consider giving to someone in position to take!
			candidatesForTake[#candidatesForTake+1] = {name = name, team = teams[i], rank = tonumber(customKeys.elo)}
		end
	end

	-- pick highest rank
	for i=1,#candidatesForTake do
		local player = candidatesForTake[i]
		if (player.rank or 0) > highestRank then
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
	if n%UPDATE_PERIOD == 0 then
		local laggers = {}
		local players = Spring.GetPlayerList()
		local recepientByAllyTeam = {}
		local gameSecond = Spring.GetGameSeconds()
		
		for i=1,#players do
			local name,active,spec,team,allyTeam,ping = Spring.GetPlayerInfo(players[i])
			local afk = Spring.GetGameSeconds() - (pActivity[players[i]] or 0)
			local _,_,_,isAI,_,_ = Spring.GetTeamInfo(team)
			if not spec  and not isAI then 
				if (afkTeams[team] == true) then  -- team was AFK 
					if active and ping <= 2000 and afk < AFK_THRESHOLD then -- team no longer AFK, return his or her units
						tickTockCounter[players[i]] = nil -- empty tick-tock clock.
						Spring.Echo("Player " .. name .. " is no longer lagging or AFK; returning all his or her units")
						GG.allowTransfer = true
						for unitID, uteam in pairs(lineage) do
							if (uteam == team) then
								Spring.TransferUnit(unitID, team, true)
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
					tickTockCounter[players[i]] = (tickTockCounter[players[i]] or 0) + 1 --tick tock clock ++
					if tickTockCounter[players[i]] >= 2 then --allow team to be tagged as AFK after 3 passes (3x50frame = 5 second).
						local units = Spring.GetTeamUnits(team)
						if units ~= nil and #units > 0 then 
							laggers[players[i]] = {name = name, team = team, allyTeam = allyTeam, units = units}
						end
					end
				else --if not at all AFK or lagging: then...
					tickTockCounter[players[i]] = nil -- empty tick-tock clock. We don't want the counter to always show 2 if player/team return.
				end
			end
		end
		
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
						--REASON for WHY THE ABOVE^ CHECK was ADDED: if someone sent units to this AFK-er then (typically) var:"laggers[players[i]]" will be filled twice for the same player (line 161) & normally unit will be sent (redirected) to the non-AFK-er (line 198), but (unfortunately) equation:"GG.Lagmonitor_activeTeams[allyTeam].count = GG.Lagmonitor_activeTeams[allyTeam].count - 1" will also run twice for the AFK ally (line 193) and it will effect 'unit_mex_overdrive.lua on line 999'. 			
						GG.Lagmonitor_activeTeams[allyTeam].count = GG.Lagmonitor_activeTeams[allyTeam].count - 1
						GG.Lagmonitor_activeTeams[allyTeam][team] = false
					end
					afkTeams[team] = true --mark team as AFK
					local units = data.units or {}
					if #units > 0 then -- transfer units when number of units in AFK team is > 0
						Spring.Echo("Giving all units of "..data.name .. " to " .. recepientByAllyTeam[allyTeam].name .. " due to lag/AFK")
						GG.allowTransfer = true
						for j=1,#units do
							lineage[units[j]] = team
							Spring.TransferUnit(units[j], recepientByAllyTeam[allyTeam].team, true)
						end
					
						GG.allowTransfer = false
					end
				end	-- if
			end	-- if
		end	-- for
	end	-- if
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
