function gadget:GetInfo()
  return {
    name      = "MarketPlace",
    desc      = "Buy and Sell your units.",
    author    = "CarRepairer",
    date      = "2010-07-22",
    license   = "GNU GPL, v2 or later",
    layer     = 1,
    enabled   = false -- loaded by default?
  }
end

local TESTMODE = false

if not tobool(Spring.GetModOptions().marketandbounty) then
	return
end 

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
-------------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then 
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

local function explode(div,str)
  if (div=='') then return false end
  local pos,arr = 0,{}
  -- for each divider found
  for st,sp in function() return string.find(str,div,pos,true) end do
    table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
    pos = sp + 1 -- Jump past current divider
  end
  table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
  return arr
end

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
			Spring.TransferUnit(unitID, customer, true)
		end
		
	end
end

-------------------------------------------------------------------------------------
--Callins

function gadget:RecvLuaMsg(msg, playerID)
	local sellprefix = "$sell:"
	local sell = (msg:find(sellprefix,1,true))
	local buy = (msg:find("$buy :",1,true))
	
	
	if buy or sell then
		local _,_,spec,teamID, allianceID = spGetPlayerInfo(playerID)
		if spec then
			return
		end
		local transdata = explode( '|', msg:sub(#sellprefix+1) )
		
		if( #transdata ~= 2 ) then
			Spring.Log(gadget:GetInfo().name, LOG.WARNING, '<MarketPlace> (A) Player ' .. playerID .. ' on team ' .. teamID .. ' tried to send a nonsensical command.')
			return false
		end
		
		local unitID = transdata[1]+0
		local price = transdata[2]+0
		
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
				market[unitID].sell = price > 0 and price or nil
			end
		elseif buy then
			if not market[unitID].buy then
				market[unitID].buy  = {}
			end
			market[unitID].buy[teamID] = price > 0 and price or nil
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
	_,_,_,_,_, gaiaAlliance = spGetTeamInfo(gaiaTeam)
	
	if TESTMODE then
		local allUnits = Spring.GetAllUnits()
		for _,unitID in ipairs(allUnits) do
			market[unitID] = {}
			market[unitID].sell = 500
			market[unitID].team = Spring.GetUnitTeam(unitID)
		end
	end
	
	_G.market = market

end

--[[
function gadget:UnitCreated(unitID, unitDefID)
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
end
--]]

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
else  -- UNSYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local SendLuaRulesMsg 		= Spring.SendLuaRulesMsg
local spSendCommands		= Spring.SendCommands
local spGetSpectatingState 	= Spring.GetSpectatingState
local spGetLocalAllyTeamID	= Spring.GetLocalAllyTeamID
local spGetLocalTeamID		= Spring.GetLocalTeamID

local CallAsTeam = CallAsTeam

local glTranslate			= gl.Translate
local glColor				= gl.Color
local glDepthTest			= gl.DepthTest
local glDrawFuncAtUnit		= gl.DrawFuncAtUnit
local glBillboard			= gl.Billboard

LUAUI_DIRNAME = 'LuaUI/'
local fontHandler   = loadstring(VFS.LoadFile(LUAUI_DIRNAME.."modfonts.lua", VFS.ZIP_FIRST))()
--local bigFont			= LUAUI_DIRNAME.."Fonts/FreeSansBold_14"
--local smallFont			= LUAUI_DIRNAME.."Fonts/FreeSansBold_12"
local fhDraw    		= fontHandler.Draw
local fhDrawCentered	= fontHandler.DrawCentered
local overheadFont		= "LuaUI/Fonts/FreeSansBold_16"

local myAllyID 		= spGetLocalAllyTeamID()
local myTeamID 		= spGetLocalTeamID()

local heightOffset = 24
local xOffset = 0
local yOffset = 0
local fontSize = 6

local inColors, teamNames = {}, {}

local spec = false

local MpTextCache = {}

--gadget:ViewResize(Spring.GetViewGeometry())
--------------------------------------------------------


local function DrawPrice(unitID, text, height)
  glTranslate(0, height, 0 )
  glBillboard()
  
  fontHandler.UseFont(overheadFont)
  fontHandler.DrawCentered(text, xOffset,yOffset)
  
end

local function SetupTeamData()
	local teamList = spGetTeamList()
	for _,teamID in ipairs(teamList) do
		local _, leaderPlayerID = spGetTeamInfo(teamID)
		if leaderPlayerID and leaderPlayerID ~= -1 then
			
			teamNames[teamID] = spGetPlayerInfo(leaderPlayerID) or '?? Rob P. ??'
			local r,g,b,a = Spring.GetTeamColor(teamID)
			inColors[teamID] = '\\255\\255\\255\\255'
			if r then
				inColors[teamID] = string.char(a*255) .. string.char(r*255) ..  string.char(g*255) .. string.char(b*255)
			end
		end
	end
end

local function GetMpText(unitID, data)
	
	if MpTextCache[unitID] then
		return MpTextCache[unitID]
	end

	local sellingAt = data.sell
	local buyers = data.buy
	local team = data.team and data.team+0 or 0

	local text = ''
	if sellingAt then
		text = inColors[team] .. 'Sale $' .. sellingAt 
	end
	if buyers then
		local addedOffers = false
		
		for teamID, price in spairs(buyers) do
			if not addedOffers then
				text = text .. ' \255\255\255\255Offers: '
				addedOffers = true
			end
			text = text .. inColors[teamID] .. '$' .. price .. ' (' .. teamNames[teamID] ..') '
		end
	end
	MpTextCache[unitID] = text
	return text
end
-----------------------------------------------------------------------------
--Callins	

--function gadget:DrawScreen()	
--end

function gadget:DrawWorld()
	if not market then return end
	
	for unitID, data in spairs(market) do
	
		local visible = false
		if spec then
			visible = true
		else
			CallAsTeam({ ['read'] = myTeamID }, function()
				visible = Spring.IsUnitVisible(unitID)
			end)
		end
		if visible then
			local height = 60
			local text = GetMpText(unitID, data)
			if text ~= '' then
				glDrawFuncAtUnit(unitID, false, DrawPrice, unitID, text, height)
			end
		end
		
	end
end


function gadget:Initialize()
	SetupTeamData()
end

local cycle = 1
local cacheCycle = 1
function gadget:Update()
	
	spec = spGetSpectatingState()
	
	cycle = cycle % (32*40) + 1
	cacheCycle = cacheCycle % (32*1) + 1
	if cycle == 1 then
		SetupTeamData()
	end
	if cacheCycle == 1 then
		MpTextCache = {}
	end
	
	if SYNCED.market then
		market = SYNCED.market
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
end             