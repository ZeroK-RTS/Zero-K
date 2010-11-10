function gadget:GetInfo()
  return {
    name      = "Bounties",
    desc      = "Place bounties on units.",
    author    = "CarRepairer",
    date      = "2010-07-25",
    license   = "GNU GPL, v2 or later",
    layer     = 1,
    enabled   = true -- loaded by default?
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


-------------------------------------------------------------------------------------
--Callins

function gadget:RecvLuaMsg(msg, playerID)
	local bounty_prefix = "$bounty:"
	local bounty_msg = (msg:find(bounty_prefix,1,true))
	
	if bounty_msg then
		local _,_, spec, teamID, allianceID = spGetPlayerInfo(playerID)
		if spec then
			return
		end
		--echo (msg)
		local transdata = explode( '|', msg:sub(#bounty_prefix+1) )
		
		if( #transdata ~= 2 ) then
			echo ('<Bounty> (A) Player ' .. playerID .. ' on team ' .. teamID .. ' tried to send a nonsensical command.')
			return false
		end
		
		local unitID = transdata[1]+0
		local price = transdata[2]+0
		
		if( type(unitID) ~= 'number' or type(price) ~= 'number' ) then
			echo ('<Bounty> (B) Player ' .. playerID .. ' on team ' .. teamID .. ' tried to send a nonsensical command.')
			return false
		end
		
		--local unitTeamID = Spring.GetUnitTeam(unitID)
		local unitAlliance = Spring.GetUnitAllyTeam(unitID)
		
		if unitAlliance == allianceID then
			echo ('<Bounty> You cannot place a bounty on an allied unit, Player ' .. playerID .. ' on team ' .. teamID)
			return false
		end
		
		if not bounty[unitID] then
			bounty[unitID] = {}
			bounty[unitID][teamID] = 0
		end
		
		bounty[unitID][teamID] = math.max( price, bounty[unitID][teamID] )
		
	end

end


function gadget:Initialize()
	gaiaTeam = Spring.GetGaiaTeamID()
	_,_,_,_,_, gaiaAlliance = spGetTeamInfo(gaiaTeam)
	
	if TESTMODE then
		local allUnits = Spring.GetAllUnits()
		for _,unitID in ipairs(allUnits) do
			bounty[unitID] = {
				[0] = 500,
				[1] = 100,
				[2] = 200,
			}
			
		end
	end
	
	_G.bounty = bounty

end


function gadget:UnitDestroyed(unitID,unitDefID,unitTeam,attackerID, attackerDefID, attackerTeam)
	local ubounty = bounty[unitID]
	if ubounty then
		for teamID, amount in pairs(ubounty) do
			GG.AddDebt(teamID, attackerTeam, amount)
		end
		bounty[unitID] = nil
	end
end


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
else  -- UNSYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

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

local BountyTextCache = {}

local spec = false

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

local function GetBountyText(unitID, ubounty)

	if BountyTextCache[unitID] then
		return BountyTextCache[unitID]
	end

	local text = '\255\255\255\255Bounty: '
	for team, amount in spairs(ubounty) do
		text = text .. inColors[team] .. '$' .. amount .. ' '
	end
	BountyTextCache[unitID] = text
	return text
end

-----------------------------------------------------------------------------
--Callins	

--function gadget:DrawScreen()	
--end

function gadget:DrawWorld()
	if not bounty then return end
	
	for unitID, ubounty in spairs(bounty) do
	
		local visible = false
		if spec then
			visible = true
		else
			CallAsTeam({ ['read'] = myTeamID }, function()
				visible = Spring.IsUnitVisible(unitID)
			end)
		end
		local height = 80
		if visible then
			local text = GetBountyText(unitID, ubounty)
			glDrawFuncAtUnit(unitID, false, DrawPrice, unitID, text, height)
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
		BountyTextCache = {}
	end
	
	if SYNCED.bounty then
		bounty = SYNCED.bounty
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
end