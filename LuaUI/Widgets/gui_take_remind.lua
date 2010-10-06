-- $Id: gui_take_remind.lua 3550 2008-12-26 04:50:47Z evil4zerggin $
local versionNumber = "v3.3"

function widget:GetInfo()
  return {
    name      = "Take Reminder",
    desc      = versionNumber .. " Reminds you to /take if a player is gone",
    author    = "Evil4Zerggin",
    date      = "31 March 2007,2008,2009",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

------------------------------------------------
-- modified by:
------------------------------------------------
--  jK: only get mouse owner in MousePress() if there are teams to take
--      and some smaller speed ups
--  SirMaverick: works now when someone uses "/spectator"
--  jK: now even faster
------------------------------------------------

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
local lastActivePlayers = 0
local gameStarted = false

------------------------------------------------
-- speedups
------------------------------------------------
local GetTeamList = Spring.GetTeamList
local GetMyAllyTeamID  = Spring.GetMyAllyTeamID
local GetTeamUnitCount = Spring.GetTeamUnitCount
local GetPlayerList  = Spring.GetPlayerList
local GetPlayerInfo  = Spring.GetPlayerInfo
local GetGameSeconds = Spring.GetGameSeconds
local GetSpectatingState = Spring.GetSpectatingState
local GetUnitPosition = Spring.GetUnitPosition
local GetVisibleUnits = Spring.GetVisibleUnits
local GetUnitTeam = Spring.GetUnitTeam
local AreTeamsAllied = Spring.AreTeamsAllied
local GetMyTeamID = Spring.GetMyTeamID
local glBillboard         = gl.Billboard
local glPushMatrix        = gl.PushMatrix
local glPopMatrix         = gl.PopMatrix
local glText = gl.Text
local glTranslate         = gl.Translate
local glColor = gl.Color

------------------------------------------------
-- helper functions
------------------------------------------------

local function GetTeamIsTakeable(team)
  local _,_,_,isAI = Spring.GetTeamInfo(team)
  -- don't take AI teams
  if isAI then
    return false
  end

  local players = GetPlayerList(team,true)
  for _, player in ipairs(players) do
    local _, _, spec = GetPlayerInfo(player)
    if (not spec) then
      return false
    end
  end
  return true
end


local takeableTeamsCached = {}
local function GetTeamIsTakeableCached(team)
  local takeable = takeableTeamsCached[team]
  if (takeable ~= nil) then
    takeable = GetTeamIsTakeable(team)
    takeableTeamsCached[team] = takeable
  end
  return takeable
end


local function UpdateUnitsToTake()
  local teamList = GetTeamList(myAllyTeamID)
  count = 0
  for _, team in ipairs(teamList) do
    local unitsOwned = GetTeamUnitCount(team)
    if (unitsOwned > 0 and GetTeamIsTakeable(team)) then
      count = count + unitsOwned
    end
  end
end


local function SomeoneDropped(playerid)
  local activePlayers = GetPlayerList(true)
  if (#activePlayers ~= lastActivePlayers) then
    lastActivePlayers = #activePlayers

    local _, _, _, teamID, allyTeamID = GetPlayerInfo(playerid)
    if allyTeamID == myAllyTeamID then
      local playersInTeam  = GetPlayerList(teamID, true)
      -- check if team has at least 1 active player
      -- (e.g. team 0 has all the specs)
      if playersInTeam then
        for i,p in ipairs(playersInTeam) do
          local _, active, spec = GetPlayerInfo(playerid)
          if not spec and active then
            return false
          end
        end
        return true
      else
        -- no player in team
        return true
      end
    end

  end
end


local function IsOnButton(x, y)
  return x >= posx - buttonX and x <= posx + buttonX
     and y >= posy           and y <= posy + buttonY
end


function Take()
  Spring.SendCommands("take")
  return
end

------------------------------------------------
-- dynamic bound call-ins
------------------------------------------------

function _Update(_,dt)
  blinkTimer = blinkTimer + dt
  if (blinkTimer>1) then blinkTimer = 0 end
  colorBool = (blinkTimer > 0.5)

  if (recheck) then
    UpdateUnitsToTake()
    if (count == 0) then
      UnbindCallins()
    end
    recheck = false
  end
end


function widget:UnitTaken()
  recheck = true
end


function _MousePress(_,x, y, button)
  return (IsOnButton(x, y))
end


function _MouseRelease(_,x, y, button)
  if (IsOnButton(x, y)) then
    UpdateUnitsToTake()
    if (count > 0) then
      Take()
    else
      UnbindCallins()
    end
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
  gl.Text(colorStr .. "Click here to take " .. count .. " unit(s)!", posx, posy + buttonY * 0.5, 24, "ovc")
end


function _DrawWorld()
  if colorBool then
    myTeamID = GetMyTeamID()
    glColor(1,1,1,1)
    local visibleUnits = GetVisibleUnits(Spring.ALLY_UNITS,nil,true) 
    for i=1,#visibleUnits do 
      local currUnit = visibleUnits[i]
      local currTeam = GetUnitTeam(currUnit)
      if currTeam and (AreTeamsAllied(myTeamID, currTeam) and GetTeamIsTakeableCached(currTeam)) then
        glPushMatrix()
        local ux, uy, uz = GetUnitPosition(currUnit)
        glTranslate(ux, uy, uz)
        glBillboard()
        glText("\255\255\255\1T", 0, -24, 48, "c")
        glPopMatrix()
      end
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
end


function BindCallins()
  widget.Update = _Update
  widget.MousePress = _MousePress
  widget.MouseRelease = _MouseRelease
  widget.DrawScreen = _DrawScreen
  widget.DrawWorld = _DrawWorld
  UpdateCallins()
end


function UnbindCallins()
  widget.Update = nil
  widget.MousePress = nil
  widget.MouseRelease = nil
  widget.DrawScreen = nil
  widget.DrawWorld = nil
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
  myAllyTeamID = GetMyAllyTeamID()
  lastActivePlayers = #(GetPlayerList(true) or {})
end


function widget:ViewResize(viewSizeX, viewSizeY)
  vsx = viewSizeX
  vsy = viewSizeY
  posx = vsx * 0.75
  posy = vsy * 0.75
end


function widget:PlayerChanged()
  if not GetSpectatingState() then
    takeableTeamsCached = {}
    myAllyTeamID = GetMyAllyTeamID()
    UpdateUnitsToTake()
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

-- don't check for dropped players before the game starts, they might reconnect
function widget:PlayerRemoved(player, reason)
  if gameStarted then
    if (SomeoneDropped(player)) then
      widget:PlayerChanged()
    end
  end
end

-- check on game start for players who dropped or didn't connect at all
function widget:GameStart()
  gameStarted = true

  widget:PlayerChanged()
end

