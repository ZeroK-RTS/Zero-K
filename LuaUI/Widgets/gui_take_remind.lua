-- $Id: gui_take_remind.lua 3550 2008-12-26 04:50:47Z evil4zerggin $
local versionNumber = "v3.6"

function widget:GetInfo()
  return {
    name      = "Take Reminder",
    desc      = versionNumber .. " Reminds you to /take if a player is gone",
    author    = "Evil4Zerggin",
    date      = "31 March 2007,2008,2009,2012",
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
--	msafwan: implement take for quiting & AFK-er (not resigning) using game_lagmonitor.lua, and added some comment & code.
------------------------------------------------
------------------------------------------------
--Crude Documentation:
-- Main Logic:
-- 1) 'widget:Player Changed' --> count lagger's units + check AFK --> reset button text to "Click here..." (textPlsWait = false)  --> show button IF units ">0" else hide
-- 2) 'widget:Player Removed' --> count lagger's units + check AFK --> reset button text to "Click here..." (textPlsWait = false)  --> show button IF units ">0" else hide
-- 3) 'RecvFromSynced(...)' (thereIsChange=true) --> count lagger's units + check AFK --> reset button text to "Click here..." (textPlsWait = false) --> show button IF units ">0" else hide
-- 4) 'widget:Unit Taken' --> count lagger's units + check AFK --> reset button text to "Click here..." (textPlsWait = false) --> show button IF units ">0" else hide

-- Others:
-- 1) press the button --> count lagger's units + check AFK--> change button text to "Wait..." (textPlsWait = true) --> execute a "/take" (if droppedPlayer== false) OR execute a LUA-msg-lagmonitor (if droppedPlayer== true)
-- 2) console-message "Giving all unit.." --> count lagger's units + check AFK --> change button text to "Click here..." (textPlsWait = false) --> show button IF units ">0" else hide
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
local droppedPlayer =nil
local lagmonitorAFK = {}
local afkString_old = "" --store previous value of 'afkString' from game_lagmonitor.lua (RecvFromSynced()). Is used for making comparison.

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
	local takeAble = true --assume whole team is takeable (spec OR afk)
	local teamIsAFK = true --assume whole team is afk
	local teamIsSpec = true --assume whole team is resigned
	local _,_,_,isAI = Spring.GetTeamInfo(teamID)
	if isAI then 
		takeAble = false  -- AI teams is not takeable
		teamIsAFK = false -- AI teams cannot inactive
		teamIsSpec = false
	end
	
	local players = spGetPlayerList(teamID)--get player(s) in a team
	for i=1, #players do -- check every player in a team. If one of them is not-spec/not-afk then entire team is not takeable
		local playerID = players[i]
		local _, active, spec = spGetPlayerInfo(playerID)
		local afk = (not active) or lagmonitorAFK[playerID] --check whether player is outside-game OR reported as AFK
		if afk== false then teamIsAFK = false end --if a member is not-AFK then assume whole team NOT AFK
		if spec== false then teamIsSpec = false end --if a member is not-spec then assume whole team NOT spec
		if (not spec) and (not afk) then -- team whos player not-spectator AND not-afk is NOT takeable. In ZK resigned player goes to spectator, and exited player is afk.
			takeAble = false --if above condition is meet (a member not-spec, and not-afk) then the team is not takeable!...
			--break --if at least 1 player is not-spec/not-afk then skip checking the whole team
		end
	end
	return takeAble, teamIsAFK, teamIsSpec --isAFK indicate whether whole team was afk, and isSpec indicate whether whole team resigned
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
		local takeable, isAFK, isSpec = GetTeamIsTakeable(teamID)
		if (unitsOwned > 0 and takeable) then
			unitCount = unitCount + unitsOwned -- count lagger's unit
			droppedPlayer = (isAFK and not isSpec) or (not isSpec) --if team is whole AFK but not Spec then assume they exited/timeout (ie: isAFK and not isSpec), else: if only some member is not Spec then still assume they exited/timeout (ie: not isSpec), BUT if whole team is both AFK & spec then they all resigned. Exited/timeout means "dropped player", while resigned mean not "dropped player"; widget need to use /take command.
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
	if droppedPlayer then --alternateTake
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


function _UnitTaken()
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
	if (line:sub(1,20) == "Giving all units of ") then --is received when "game_lagmonitor.lua" finished transfer the unit. Used to re-display the "take button" (if any unit left) and to reset the take method back to "/take" instead of waiting for "game_lagmonitor.lua" (if the case)
		local allyNumLoc = line:find("#",-5,true)
		local allyNum = tonumber(line:sub(allyNumLoc+1,allyNumLoc+1))
		if allyNum == myAllyTeamID then
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
	widgetHandler:UpdateCallIn('UnitTaken')
	widgetHandler:UpdateCallIn('UnitTaken')
end


function BindCallins()
  widget.Update = _Update
  widget.MousePress = _MousePress
  widget.MouseRelease = _MouseRelease
  widget.DrawScreen = _DrawScreen
  widget.DrawWorld = _DrawWorld
  widget.AddConsoleLine = _AddConsoleLine
  widget.UnitTaken = _UnitTaken
  UpdateCallins()
end


function UnbindCallins()
  widget.Update = function() end
  widget.MousePress = function() end
  widget.MouseRelease = function() end
  widget.DrawScreen = function() end
  widget.DrawWorld = function() end --Note: originally it was assigned a "nil", but when same thing performed on AddConsoleLine() it seems to not work, so added an empty-function instead as precaution.
  widget.AddConsoleLine = function() end --Note: this is empty-function instead of "nil" because "nil" caused AddConsoleLine() on other widget to fail (eg: Chili Chat). Probably caused by cawidget.lua stopped iterating AddConsoleLine() after it found "nil" (because cawidget.lua uses ipair).
  widget.UnitTaken = function() end
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
  widgetHandler:RegisterGlobal("LagmonitorAFK", LagmonitorAFK) --part for Gadget->widget communication. Reference: http://springrts.com/phpbb/viewtopic.php?f=23&t=24781 "Gadget and Widget Cross Communication"
  colorBool = false
  vsx, vsy = widgetHandler:GetViewSizes()
  posx = vsx * 0.75
  posy = vsy * 0.75
  count = 0
  myAllyTeamID = spGetMyAllyTeamID()
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

function widget:PlayerRemoved(playerID, reason)-- check for dropped player (ally and non-spec only). Functioning with help of "game_lagmonitor.lua".
	local _,_,spec,_,allyTeamID = spGetPlayerInfo(playerID)
	if (allyTeamID == myAllyTeamID) and (not spec) then
		ProcessButton()
	end
end

function LagmonitorAFK(afkString) --check for player that is marked as AFK by "game_lagmonitor.lua", is updated at every interval. 
	if afkString ~= afkString_old then --if absolutely new content of string received: perform this:
		afkString_old = afkString
		local playerCountLoc = afkString:find("#",-3,true) --search '#' (the playerCount identifier) from the last 3 character
		local playerCount = tonumber(afkString:sub(playerCountLoc+1)) --get the max playerID value
		for i=0, playerCount do --iterate over 'lagmonitorAFK' table
			lagmonitorAFK[i] = nil --reset the whole AFK list
		end
		if playerCountLoc >=6 then --check if there's AFK information in that 'afkString'
			for i=0, playerCount do --iterate for some iteration (limited to some value)
				if '#' == afkString:sub(1,1) then break end --check if 'end-of-string' reached; if so: break
				local allyTeam = tonumber(afkString:sub(4,5)) --get allyTeamID
				if allyTeam == myAllyTeamID then --check with myAllyTeamID
					local playerID = tonumber(afkString:sub(2,3)) --get playerID
					lagmonitorAFK[playerID] = true --mark playerID as AFK in 'lagmonitorAFK'
				end
				afkString = afkString:sub(6) --discard current segment, repeat again using next segment.
			end
		end
		ProcessButton() --display button if AFK-er has unitCount > 0, then send Lua TAKE if player press the button.
	end
end