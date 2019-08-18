function gadget:GetInfo()
  return {
    name      = "Bounties",
    desc      = "Place bounties on units.",
    author    = "CarRepairer",
    date      = "2010-07-25",
    license   = "GNU GPL, v2 or later",
    layer     = 2,
    enabled   = false,
  }
end

include("LuaRules/Configs/constants.lua")

local TESTMODE = false
local BOUNTYTIME = 60*5

local echo 				= Spring.Echo
local spGetPlayerInfo	= Spring.GetPlayerInfo
local spGetTeamInfo		= Spring.GetTeamInfo
local spGetTeamList		= Spring.GetTeamList
local spAreTeamsAllied	= Spring.AreTeamsAllied
local spGetAllUnits     = Spring.GetAllUnits
local spGetUnitDefID    = Spring.GetUnitDefID

local bounty = {}

-------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local spGetUnitAllyTeam		= Spring.GetUnitAllyTeam
local spGetUnitPosition		= Spring.GetUnitPosition
local spGetUnitNearestEnemy = Spring.GetUnitNearestEnemy
local spGetUnitIsActive     = Spring.GetUnitIsActive
local spEditUnitCmdDesc     = Spring.EditUnitCmdDesc
local spFindUnitCmdDesc     = Spring.FindUnitCmdDesc
local spGetTeamUnitCount	= Spring.GetTeamUnitCount
local spInsertUnitCmdDesc	= Spring.InsertUnitCmdDesc
local spGetAllyTeamList		= Spring.GetAllyTeamList

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function AddBounty( unitID, teamID, price, timer )
	if not bounty[unitID] then
		bounty[unitID] = {}
	end
	if not bounty[unitID][teamID] then
		bounty[unitID][teamID] = {price = 0}
	end
	
	local newprice = math.max( price, bounty[unitID][teamID].price )
	bounty[unitID][teamID] = {price = newprice, timer = timer,}
	
	Spring.SetUnitRulesParam( unitID, 'bounty'..teamID, newprice, {public=true} )
	Spring.SetUnitRulesParam( unitID, 'bountyTimer'..teamID, timer, {public=true} )
end


local function RemoveBounty( unitID, teamID )
	if not bounty[unitID] then
		return
	end
	Spring.SetUnitRulesParam( unitID, 'bounty'..teamID, 0, {public=true} )
	Spring.SetUnitRulesParam( unitID, 'bountyTimer'..teamID, 0, {public=true} )
	bounty[unitID][teamID] = nil
end

-------------------------------------------------------------------------------------
--Callins

function gadget:RecvLuaMsg(msg, playerID)
	local msgTable = Spring.Utilities.ExplodeString( '|', msg )
	local command = msgTable[1]
	
	local bounty_prefix = "$bounty"
	
	if command == '$bounty' then
		local _,_, spec, teamID, allianceID = spGetPlayerInfo(playerID, false)
		if spec then
			return
		end
		
		if( #msgTable ~= 3 ) then
			Spring.Log(gadget:GetInfo().name, LOG.WARNING, '<Bounty> (A) Player ' .. playerID .. ' on team ' .. teamID .. ' tried to send a nonsensical command.')
			return false
		end
		
		local unitID = msgTable[2]+0
		local price = msgTable[3]+0
		
		if( type(unitID) ~= 'number' or type(price) ~= 'number' ) then
			Spring.Log(gadget:GetInfo().name, LOG.WARNING, '<Bounty> (B) Player ' .. playerID .. ' on team ' .. teamID .. ' tried to send a nonsensical command.')
			return false
		end
		
		--local unitTeamID = Spring.GetUnitTeam(unitID)
		local unitAlliance = Spring.GetUnitAllyTeam(unitID)
		
		if unitAlliance == allianceID then
			echo ('<Bounty> You cannot place a bounty on an allied unit, Player ' .. playerID .. ' on team ' .. teamID)
			return false
		end
		
		AddBounty( unitID, teamID, price, BOUNTYTIME )
		
	end

end


function gadget:Initialize()
	gaiaTeam = Spring.GetGaiaTeamID()
	_,_,_,_,_, gaiaAlliance = spGetTeamInfo(gaiaTeam, false)
	
	if TESTMODE then
		local allUnits = Spring.GetAllUnits()
		for _,unitID in ipairs(allUnits) do
			AddBounty( unitID, 0, 50, 20 )
			--AddBounty( unitID, 1, 100, 20 )
			AddBounty( unitID, 2, 100, 40 )
			--AddBounty( unitID, 3, 50, 500 )
			
		end
	end
end

local timerPeriod = 5

function gadget:GameFrame(f)
	
	if f % (TEAM_SLOWUPDATE_RATE*timerPeriod) == 0 then
		for unitID, teamData in pairs(bounty) do
			local bountiesLeft = false
			for teamID, bData in pairs(teamData) do
				if bData.timer <= timerPeriod then
					--bounty[unitID][teamID] = nil
					RemoveBounty(unitID, teamID)
				else
					bountiesLeft = true
					bounty[unitID][teamID].timer = bData.timer - timerPeriod
				end
			end
			if not bountiesLeft then
				bounty[unitID] = nil
			end
		end
	end
end


function gadget:UnitDestroyed(unitID,unitDefID,unitTeam,attackerID, attackerDefID, attackerTeam)
	local ubounty = bounty[unitID]
	if ubounty then
		for teamID, amount in pairs(ubounty) do
			if attackerTeam then
				GG.AddDebt(teamID, attackerTeam, amount)
			end
			RemoveBounty(unitID, teamID)
		end
		bounty[unitID] = nil
	end
end


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
else  -- UNSYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
end
