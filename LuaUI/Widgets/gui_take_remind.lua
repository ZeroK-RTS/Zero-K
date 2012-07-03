-- $Id: gui_take_remind.lua 3550 2008-12-26 04:50:47Z evil4zerggin $
local versionNumber = "v3.54"

function widget:GetInfo()
  return {
    name      = "Take Reminder",
    desc      = versionNumber .. " Reminds you to /take if a player is gone",
    author    = "Evil4Zerggin",
    date      = "31 March 2007,2008,2009",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false --  loaded by default?
  }
end

------------------------------------------------
-- modified by:
------------------------------------------------
--  jK: only get mouse owner in MousePress() if there are teams to take
--      and some smaller speed ups
--  SirMaverick: works now when someone uses "/spectator"
--  jK: now even faster
--	msafwan: implement take quiting player using game_lagmonitor.lua, and rearrange stuff.
------------------------------------------------
------------------------------------------------
--Crude Documentation:
-- Main Logic:
-- 1) 'widget:Player Changed' or 'widget:Player Removed' --> count lagger's units --> reset button text to "Click here..." (textPlsWait = false)  --> show button IF units ">0"
-- 2) press the button --> count lagger's units --> change button text to "Wait..." (textPlsWait = true) --> [execute a "/take" when alternateTake== false OR execute a LUA-msg-lagmonitor when alternateTake== true] IF units ">0"
-- 3) 'widget:Unit Taken' --> count lagger's units --> reset button text to "Click here..." (textPlsWait = false) --> hide button IF units "=0"

-- Others:
-- 1) console-message "Giving all unit.." --> alternateTake= false --> count lagger's units --> change button text to "Click here..." (textPlsWait = false) --> hide button IF units "=0"
------------------------------------------------
-- config
------------------------------------------------
local autoTake = false

------------------------------------------------
-- local variables
------------------------------------------------
local blinkTimer = 0
local vsx, vsy, posx, posy
local count
local myAllyTeamID
local myTeamID
local colorBool
local trueColor = "\255\255\255\1"
local falseColor = "\255\127\127\1"
local buttonX = 240
local buttonY = 36
local recheck = false
--local lastActivePlayers = 0
local textPlsWait = false
local alternateTake = false

------------------------------------------------
-- speedups
------------------------------------------------
local spGetTeamList = Spring.GetTeamList
local spGetMyAllyTeamID  = Spring.GetMyAllyTeamID
local spGetTeamUnitCount = Spring.GetTeamUnitCount
local spGetPlayerList  = Spring.GetPlayerList
local spGetPlayerInfo  = Spring.GetPlayerInfo
local spGetGameSeconds = Spring.GetGameSeconds
local spGetSpectatingState = Spring.GetSpectatingState
local spGetUnitPosition = Spring.GetUnitPosition
local spGetVisibleUnits = Spring.GetVisibleUnits
local spGetUnitTeam = Spring.GetUnitTeam
local spAreTeamsAllied = Spring.AreTeamsAllied
local spGetMyTeamID = Spring.GetMyTeamID
local glBillboard         = gl.Billboard
local glPushMatrix        = gl.PushMatrix
local glPopMatrix         = gl.PopMatrix
local glText = gl.Text
local glTranslate         = gl.Translate
local glColor = gl.Color

------------------------------------------------
-- helper functions
------------------------------------------------

local function GetTeamIsTakeable(teamID)
	local takeAble = false --assume team is not takeable
	local players = spGetPlayerList(teamID)--get player(s) in a team
	for i=1, #players do -- check every player in a team
		local playerID = players[i]
		local _, active, spec = spGetPlayerInfo(playerID)
		if (spec) -- team who crossed to the spectator realm is takeable. Ie: in ZK only resigned player goes to spectator.
			or not active then -- team who crossed to reality realm is takeable. Ie: exited/quited player is not active player, but they are not spec
			takeAble = true --if above condition is meet (spec, or outside) then this team is indeed takeable! take it...
		end
	end

	local _,_,_,isAI = Spring.GetTeamInfo(teamID)
	if isAI then 
		takeAble = false  -- AI teams is not takeable
	end
	return takeAble
end


local takeableTeamsCached = {}
local function GetTeamIsTakeableCached(team)
  local takeable = takeableTeamsCached[team]
  if (takeable == nil) then
    takeable = GetTeamIsTakeable(team)
    takeableTeamsCached[team] = takeable
  end
  return takeable
end


local function UpdateUnitsToTake()
	local unitCount = 0 -- the number of units to take
	local teamList = spGetTeamList(myAllyTeamID)
	for i= 1, #teamList do
		local teamID = teamList[i]
		local unitsOwned = spGetTeamUnitCount(teamID)
		local takeable = GetTeamIsTakeable(teamID)
		if (unitsOwned > 0 and takeable) then
			unitCount = unitCount + unitsOwned -- count lagger's unit
		end
	end
	return unitCount
end

--[[
local function SomeoneDropped(playerid)
	local activePlayers = spGetPlayerList(true)
	if (#activePlayers ~= lastActivePlayers) then
		lastActivePlayers = #activePlayers

		local _, _, _, teamID, allyTeamID = spGetPlayerInfo(playerid)
		if allyTeamID == myAllyTeamID then
			local playersInTeam  = spGetPlayerList(teamID, true)
			-- check if team has at least 1 active player
			-- (e.g. team 0 has all the specs)
			if #playersInTeam > 0 then
				for i,p in ipairs(playersInTeam) do
					local _, active, spec = spGetPlayerInfo(playerid)
					if not spec and active then
						return false
					end
				end
				return true
			else -- no player in team
				return true
			end
		end
	end
end
-]]

local function ProcessButton()
	if not spGetSpectatingState() then
		takeableTeamsCached = {}
		myAllyTeamID = spGetMyAllyTeamID()
		textPlsWait = false -- cancel show "Wait.."
		count = UpdateUnitsToTake()
		if (count > 0) then
			if (autoTake) then
				Take()
			else
				BindCallins()
			end
		else
			UnbindCallins()
		end
	else
		UnbindCallins()
	end
end

local function IsOnButton(x, y)
  return x >= posx - buttonX and x <= posx + buttonX
     and y >= posy           and y <= posy + buttonY
end


function Take()
	if alternateTake then
		Spring.SendLuaUIMsg("TAKE")
		Spring.Echo("sending TAKE msg")
	else
		Spring.SendCommands("take")
		Spring.Echo("executing /TAKE cmd")
	end
end

------------------------------------------------
-- dynamic bound call-ins
------------------------------------------------

function _Update(_,dt)
	blinkTimer = blinkTimer + dt
	if (blinkTimer>1) then blinkTimer = 0 end
	colorBool = (blinkTimer > 0.5)

	if (recheck) then
		count = UpdateUnitsToTake()
		if (count == 0) then
			UnbindCallins()
		end
		recheck = false
	end
end


function widget:UnitTaken()
	recheck = true
    count = UpdateUnitsToTake()
    if (count == 0) then
		UnbindCallins()
    end
end


function _MousePress(_,x, y, button)
  return (IsOnButton(x, y))
end


function _MouseRelease(_,x, y, button)
  if (IsOnButton(x, y)) then
    count = UpdateUnitsToTake()
    if (count > 0) then
      Take()
    else
      UnbindCallins()
    end
	textPlsWait = true -- show "Wait.."
    return -1
  end
  return false
end


function _DrawScreen()
  gl.Color(1, 1, 0, 1)
  gl.Shape(GL.LINE_LOOP, {{ v = { posx + buttonX, posy} }, 
                          { v = { posx + buttonX, posy + buttonY } }, 
                          { v = { posx - buttonX, posy + buttonY } }, 
                          { v = { posx - buttonX, posy} }  })
  gl.Color(1, 1, 0, 0.15)
  gl.Shape(GL.QUADS, {{ v = { posx + buttonX, posy} }, 
                          { v = { posx + buttonX, posy + buttonY } }, 
                          { v = { posx - buttonX, posy + buttonY } }, 
                          { v = { posx - buttonX, posy} }  })
  local colorStr
  if (colorBool) then
    colorStr = trueColor
  else
    colorStr = falseColor
  end
  local displayText = (textPlsWait and (trueColor .. "Wait...")) or (colorStr .. "Click here to take " .. count .. " unit(s)!")
  gl.Text(displayText, posx, posy + buttonY * 0.5, 24, "ovc")
end


function _DrawWorld()
  if colorBool then
    myTeamID = spGetMyTeamID()
    glColor(1,1,1,1)
    local visibleUnits = spGetVisibleUnits(Spring.ALLY_UNITS,nil,true) 
    for i=1,#visibleUnits do 
      local currUnit = visibleUnits[i]
      local currTeam = spGetUnitTeam(currUnit)
      if currTeam and (spAreTeamsAllied(myTeamID, currTeam) and GetTeamIsTakeableCached(currTeam)) then
        glPushMatrix()
        local ux, uy, uz = spGetUnitPosition(currUnit)
        glTranslate(ux, uy, uz)
        glBillboard()
        glText("\255\255\255\1T", 0, -24, 48, "c")
        glPopMatrix()
      end
    end
  end
end

function _AddConsoleLine(_,line,priority)
	if (line:sub(1,20) == "Giving all units of ") then --to know when "game_lagmonitor.lua" finished transfer the unit. Used to re-display the "take button" (if any unit left) and to reset the take method back to "/take" instead of waiting for "game_lagmonitor.lua" (if the case)
		local allyNumLoc = line:find("#",-5,true)
		local allyNum = tonumber(line:sub(allyNumLoc+1,allyNumLoc+1))
		if allyNum == myAllyTeamID then 
			alternateTake =false
			ProcessButton()
		end
	end
end

local function UpdateCallins()
	widgetHandler:UpdateCallIn('Update')
	widgetHandler:UpdateCallIn('Update')
	widgetHandler:UpdateCallIn('MousePress')
	widgetHandler:UpdateCallIn('MousePress')
	widgetHandler:UpdateCallIn('DrawScreen')
	widgetHandler:UpdateCallIn('DrawScreen')
	widgetHandler:UpdateCallIn('DrawWorld')
	widgetHandler:UpdateCallIn('DrawWorld')
	widgetHandler:UpdateCallIn('AddConsoleLine')
	widgetHandler:UpdateCallIn('AddConsoleLine')
end


function BindCallins()
  widget.Update = _Update
  widget.MousePress = _MousePress
  widget.MouseRelease = _MouseRelease
  widget.DrawScreen = _DrawScreen
  widget.DrawWorld = _DrawWorld
  widget.AddConsoleLine = _AddConsoleLine
  UpdateCallins()
end


function UnbindCallins()
  widget.Update = function() end
  widget.MousePress = function() end
  widget.MouseRelease = function() end
  widget.DrawScreen = function() end
  widget.DrawWorld = function() end --Note: originally it was assigned a "nil", but when performed on AddConsoleLine() it seems to not work, so added an empty-function instead as precaution.
  widget.AddConsoleLine = function() end --Note: this is empty-function instead of "nil" because "nil" caused AddConsoleLine() on other widget to fail (eg: Chili Chat). Probably caused by cawidget.lua stopped iterating AddConsoleLine() after it found "nil" (because cawidget.lua uses ipair).
  UpdateCallins()
end

------------------------------------------------
-- call-ins
------------------------------------------------

function widget:Initialize()
  if Spring.IsReplay() then
    widgetHandler:RemoveWidget()
    return true
  end
  colorBool = false
  vsx, vsy = widgetHandler:GetViewSizes()
  posx = vsx * 0.75
  posy = vsy * 0.75
  count = 0
  myAllyTeamID = spGetMyAllyTeamID()
  --lastActivePlayers = #(spGetPlayerList(true) or {})
end


function widget:ViewResize(viewSizeX, viewSizeY)
  vsx = viewSizeX
  vsy = viewSizeY
  posx = vsx * 0.75
  posy = vsy * 0.75
end

function widget:GameStart() -- check at game start for players who dropped or didn't connect at all
	ProcessButton()
end

function widget:PlayerChanged(playerID) --check for player who became spec or un-spec
	local _,_,_,_,allyTeamID = spGetPlayerInfo(playerID)
	if (allyTeamID == myAllyTeamID) then
		ProcessButton()
	end
end

function widget:PlayerRemoved(playerID, reason)-- check for dropped player (ally and non-spec only). To functioning with help of "game_lagmonitor.lua".
	local _,_,spec,_,allyTeamID = spGetPlayerInfo(playerID)
	if (allyTeamID == myAllyTeamID) and (not spec) then
		alternateTake = true
		ProcessButton()
	end
end