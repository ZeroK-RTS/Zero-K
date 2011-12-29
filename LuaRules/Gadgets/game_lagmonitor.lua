-- $Id: unit_noselfpwn.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Lag Monitor",
    desc      = "Gives away units of people who are lagging",
    author    = "KingRaptor",
    date      = "27/12/2011",
    license   = "Public domain",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  
if (not gadgetHandler:IsSyncedCode()) then
  return false  --  silent removal
end

  
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local lineage = {}	--[unitID] = team
local noChangeLineage = {}	-- [unitID] = bool; if true unit will not change lineage on transfer

local LAG_THRESHOLD = 25000
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	lineage[unitID] = builderID and (lineage[builderID] or Spring.GetUnitTeam(builderID)) or unitTeam
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	lineage[unitID] = nil
	noChangeLineage[unitID] = nil
end

function gadget:UnitGiven(unitID, unitDefID, teamID, oldTeamID)
	if not noChangeLineage[unitID] then
		lineage[unitID] = teamID
	end
end

function GG.GetLineage(unitID)
	return lineage[unitID]
end

function GG.AllowLineageChangeOnTransfer(unitID, bool)
	noChangeLineage[unitID] = bool
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local pauseGame = false
local mode = "debug"
local UPDATE_PERIOD = 120	-- gameframes

local function GetRecepient(allyTeam, laggers)
	local teams = Spring.GetTeamList(allyTeam)
	local highestRank = 0
	local candidatesForTake = {}
	local target
	-- look for active people to give units to
	for i=1,#teams do
		local leader = select(2, Spring.GetTeamInfo(teams[i]))
		local name, active, spectator, _, _, _, _, _, _, customKeys = Spring.GetPlayerInfo(leader)
		if active and not spectator and not laggers[leader] then	-- only consider giving to someone in position to take!
			candidatesForTake[#candidatesForTake+1] = {name = name, team = teams[i], rank = tonumber(customKeys.level)}
		end
	end

	-- pick highest rank
	for i=1,#candidatesForTake do
		local player = candidatesForTake[i]
		if (player.rank or 0) > highestRank then
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
		
		for i=1,#players do
			local name,_,_,team,allyTeam,ping = Spring.GetPlayerInfo(players[i])
			if ping >= LAG_THRESHOLD then
				local units = Spring.GetTeamUnits(team)
				laggers[players[i]] = {name = name, team = team, allyTeam = allyTeam, units = units}
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
					if mode == "debug" then
						Spring.Echo("Player " .. data.name .. " is lagging; recommend giving all units to " .. recepientByAllyTeam[allyTeam].name)		
					elseif mode == "giveall" then
						local units = data.units or {}
						if #units > 0 then
							Spring.Echo("Giving all units of "..data.name .. " to " .. recepientByAllyTeam[allyTeam].name .. " due to lag")
							for j=1,#units do
								GG.AllowLineageChangeOnTransfer(units[j], false)
								Spring.TransferUnit(units[j], recepientByAllyTeam[allyTeam].team, true)
								GG.AllowLineageChangeOnTransfer(units[j], true)
							end
						end
					end	-- if
					
					if pauseGame then
						-- TODO: allow pause if desired
					end
				end	-- if
			end	-- if
		end	-- for
	end	-- if
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
