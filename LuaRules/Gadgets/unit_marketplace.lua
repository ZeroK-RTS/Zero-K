--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:GetInfo()
  return {
    name      = "MarketPlace",
    desc      = "Buy and Sell your units.",
    author    = "CarRepairer",
    date      = "2010-07-22",
    license   = "GNU GPL, v2 or later",
    layer     = 1,
    enabled   = false,
  }
end

local TESTMODE = false

local echo 				= Spring.Echo
local spGetPlayerInfo	= Spring.GetPlayerInfo
local spGetTeamInfo		= Spring.GetTeamInfo
local spGetTeamList		= Spring.GetTeamList
local spAreTeamsAllied	= Spring.AreTeamsAllied
local spGetAllUnits     = Spring.GetAllUnits
local spGetUnitDefID    = Spring.GetUnitDefID

local market = {}

if not GG.shareunits then
	GG.shareunits = {}
end


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local spGetUnitAllyTeam		= Spring.GetUnitAllyTeam
local spGetUnitPosition		= Spring.GetUnitPosition
local spGetUnitNearestEnemy = Spring.GetUnitNearestEnemy
local spGetUnitIsActive     = Spring.GetUnitIsActive
local spGiveOrderToUnit     = Spring.GiveOrderToUnit
local spEditUnitCmdDesc     = Spring.EditUnitCmdDesc
local spFindUnitCmdDesc     = Spring.FindUnitCmdDesc
local spGetTeamUnitCount	= Spring.GetTeamUnitCount
local spInsertUnitCmdDesc	= Spring.InsertUnitCmdDesc
local spGetAllyTeamList		= Spring.GetAllyTeamList

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function CheckOffer(data)
	local saleprice = data.sell
	local buyers = data.buy
	if buyers and saleprice then
		for teamID, buyprice in pairs(buyers) do
			if saleprice+0 <= buyprice+0 then
				return teamID, saleprice
			end
		end
	end
	return false, false
end

local function CheckOffers()
	for unitID, data in pairs(market) do
		local customer, saleprice = CheckOffer(data)
		if customer then
			local teamID = market[unitID].team
			market[unitID] = nil
			GG.AddDebt(customer, teamID, saleprice)
			GG.shareunits[unitID] = true
			GG.allowTransfer = true
			Spring.TransferUnit(unitID, customer, true)
			GG.allowTransfer = false
			Spring.SetUnitRulesParam( unitID, 'buy'..teamID, 0, {allied=true} )
			Spring.SetUnitRulesParam( unitID, 'sell'..teamID, 0, {allied=true} )
		end
		
	end
end

-------------------------------------------------------------------------------------
--Callins

function gadget:RecvLuaMsg(msg, playerID)
	local msgTable = Spring.Utilities.ExplodeString( '|', msg )
	local command = msgTable[1]
	local sell = command == '$sell'
	local buy = command == '$buy'
	
	if buy or sell then
		local _,_,spec,teamID, allianceID = spGetPlayerInfo(playerID, false)
		if spec then
			return
		end
		
		if( #msgTable ~= 3 ) then
			Spring.Log(gadget:GetInfo().name, LOG.WARNING, '<MarketPlace> (A) Player ' .. playerID .. ' on team ' .. teamID .. ' tried to send a nonsensical command.')
			return false
		end
		
		local unitID = msgTable[2]+0
		local price = msgTable[3]+0
		
		if( type(unitID) ~= 'number' or type(price) ~= 'number' ) then
			Spring.Log(gadget:GetInfo().name, LOG.WARNING, '<MarketPlace> (B) Player ' .. playerID .. ' on team ' .. teamID .. ' tried to send a nonsensical command.')
			return false
		end
		
		local unitTeamID = Spring.GetUnitTeam(unitID)
		
		if not market[unitID] then
			market[unitID] = {}
		end
		market[unitID].team = unitTeamID
		
		if sell then
			if unitTeamID ~= teamID then
				echo ('<MarketPlace> You cannot sell a unit that\'s not yours, Player ' .. playerID .. ' on team ' .. teamID)
				return
			else
				--echo 'put for sale'
				market[unitID].sell = price > 0 and price or nil
				Spring.SetUnitRulesParam( unitID, 'sell'..teamID, price, {allied=true} )
			end
		elseif buy then
			if not market[unitID].buy then
				market[unitID].buy  = {}
			end
			market[unitID].buy[teamID] = price > 0 and price or nil
			echo( unitID, 'buy'..teamID, price )
			Spring.SetUnitRulesParam( unitID, 'buy'..teamID, price, {allied=true} )
		end
	end
	

end

function gadget:GameFrame(f)
	if (f%32) < 0.1 then
		CheckOffers()
	end
end


function gadget:Initialize()
	gaiaTeam = Spring.GetGaiaTeamID()
	_,_,_,_,_, gaiaAlliance = spGetTeamInfo(gaiaTeam, false)
	
	if TESTMODE then
		local allUnits = Spring.GetAllUnits()
		for _,unitID in ipairs(allUnits) do
			local teamID = Spring.GetUnitTeam(unitID)
			market[unitID] = {}
			market[unitID].sell = 500
			market[unitID].team = teamID
			Spring.SetUnitRulesParam( unitID, 'sell'..teamID, 500, {allied=true} )
		end
	end
end

--[[
function gadget:UnitCreated(unitID, unitDefID)
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
end
--]]         