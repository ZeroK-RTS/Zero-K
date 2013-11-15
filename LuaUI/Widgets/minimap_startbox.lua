--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    minimap_startbox.lua
--  brief:   shows the startboxes in the minimap
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function widget:GetInfo()
  return {
    name      = "MiniMap Start Boxes",
    desc      = "MiniMap Start Boxes",
    author    = "trepan, jK, Rafal",
    date      = "2007-2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end
-- version: 1.02
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  config options
--

-- enable simple version by default though
local drawGroundQuads = true


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

VFS.Include("LuaRules/Utilities/glVolumes.lua")

local gl = gl  --  use a local copy for faster access

local msx = Game.mapSizeX
local msz = Game.mapSizeZ

local xformList = 0
local coneList = 0

local allyStartBox    = nil
local enemyStartBoxes = {}

local allyStartBoxColor  = { 0, 1, 0, 0.3 }  -- green
local enemyStartBoxColor = { 1, 0, 0, 0.3 }  -- red

local gaiaTeamID
local gaiaAllyTeamID

local teamStartPositions = {}
local startTimer = Spring.GetTimer()

local texName = LUAUI_DIRNAME .. 'Images/highlight_strip.png'
local texScale = 512

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
  -- only show at the beginning
  if (Spring.GetGameFrame() > 1 or Game.startPosType ~= 2) then
    widgetHandler:RemoveWidget()
    return
  end

  -- get the gaia teamID and allyTeamID
  gaiaTeamID = Spring.GetGaiaTeamID()
  if (gaiaTeamID) then
    local _,_,_,_,_,atid = Spring.GetTeamInfo(gaiaTeamID)
    gaiaAllyTeamID = atid
  end

  -- flip and scale  (using x & y for gl.Rect())
  xformList = gl.CreateList(function()
    gl.LoadIdentity()
    gl.Translate(0, 1, 0)
    gl.Scale(1 / msx, -1 / msz, 1)
  end)

  -- cone list for world start positions
  coneList = gl.CreateList(function()
    local h = 100
    local r = 25
    local divs = 32
    gl.BeginEnd(GL.TRIANGLE_FAN, function()
      gl.Vertex( 0, h,  0)
      for i = 0, divs do
        local a = i * ((math.pi * 2) / divs)
        local cosval = math.cos(a)
        local sinval = math.sin(a)
        gl.Vertex(r * sinval, 0, r * cosval)
      end
    end)
  end)

  if (drawGroundQuads) then
    local myAllyID = Spring.GetMyAllyTeamID()
    local x1, z1, x2, z2 = Spring.GetAllyTeamStartBox(myAllyID)
    if (x1 and not (x1 == 0 and z1 == 0 and x2 == msx and z2 == msz)) then
      allyStartBox = { x1, z1, x2, z2 }
    end

    for _,at in ipairs(Spring.GetAllyTeamList()) do
      --if (at ~= gaiaAllyTeamID) then
      if (at ~= myAllyID) then
        local x1, z1, x2, z2 = Spring.GetAllyTeamStartBox(at)
        if (x1 and not (x1 == 0 and z1 == 0 and x2 == msx and z2 == msz)) then
          table.insert(enemyStartBoxes, { x1, z1, x2, z2 })
        end
      end
    end
  end
end


function widget:Shutdown()
  gl.DeleteList(xformList)
  gl.DeleteList(coneList)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--// The following 2 functions originally located on line 25, and supposed to function similar to 'widget:GameFrame(n)' and line 106. 
--[[
if (Game.startPosType ~= 2) then
  return false
end

if (Spring.GetGameFrame() > 1) then
  widgetHandler:RemoveWidget()
end
--]]

function widget:GameFrame(n)
	if (n > 1) then
	  widgetHandler:RemoveWidget() --// Will remove start box when game start. Widget's function is to draw start box.
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local teamColors = {}
local teamColorStrs = {}

local function GetTeamColor(teamID)
  local color = teamColors[teamID]
  if (color) then
    return color
  end
  local r,g,b = Spring.GetTeamColor(teamID)
  
  color = { r, g, b }
  teamColors[teamID] = color
  return color
end

local timer = 0
function widget:Update(s)
  timer = timer + s
  if timer > 0.5 then
    timer = 0
    for _, teamID in ipairs(Spring.GetTeamList()) do
      local r,g,b = Spring.GetTeamColor(teamID)
      if (r and g and b) then
        color = { r, g, b }
        teamColors[teamID] = color
      end
      if teamColorStrs[teamID] then
        teamColorStrs[teamID] = nil
      end
    end
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local function GetTeamColorStr(teamID)
  local colorSet = teamColorStrs[teamID]
  if (colorSet) then
    return colorSet[1], colorSet[2]
  end

  local outlineChar = ''
  local r,g,b = Spring.GetTeamColor(teamID)
  if (r and g and b) then
    local function ColorChar(x)
      local c = math.floor(x * 255)
      c = ((c <= 1) and 1) or ((c >= 255) and 255) or c
      return string.char(c)
    end
    local colorStr
    colorStr = '\255'
    colorStr = colorStr .. ColorChar(r)
    colorStr = colorStr .. ColorChar(g)
    colorStr = colorStr .. ColorChar(b)
    local i = (r * 0.299) + (g * 0.587) + (b * 0.114)
    outlineChar = ((i > 0.25) and 'o') or 'O'
    teamColorStrs[teamID] = { colorStr, outlineChar }
    return colorStr, "s",outlineChar
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function DrawStartboxes3dWithStencil()
  if (drawGroundQuads) then
    if (allyStartBox) then
      gl.Color(allyStartBoxColor)
      gl.Utilities.DrawGroundRectangle(allyStartBox)
    end

    gl.Color(enemyStartBoxColor)
    for _,startBox in ipairs(enemyStartBoxes) do
      gl.Utilities.DrawGroundRectangle(startBox)
    end
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:DrawWorld()
  gl.Fog(false)

  local time = Spring.DiffTimers(Spring.GetTimer(), startTimer)

  -- show the ally startboxes
  DrawStartboxes3dWithStencil()

  -- show the team start positions
  for _, teamID in ipairs(Spring.GetTeamList()) do
    local _,leader = Spring.GetTeamInfo(teamID)
    local _,_,spec = Spring.GetPlayerInfo(leader)
    if ((not spec) and (teamID ~= gaiaTeamID)) then
      local newx, newy, newz = Spring.GetTeamStartPosition(teamID)

      if (teamStartPositions[teamID] == nil) then
        teamStartPositions[teamID] = {newx, newy, newz}
      end

      local oldx, oldy, oldz =
        teamStartPositions[teamID][1],
        teamStartPositions[teamID][2],
        teamStartPositions[teamID][3]

      if (newx ~= oldx or newy ~= oldy or newz ~= oldz) then
        Spring.PlaySoundFile("MapPoint")
        teamStartPositions[teamID][1] = newx
        teamStartPositions[teamID][2] = newy
        teamStartPositions[teamID][3] = newz
      end

      if (newx ~= nil and newx ~= 0 and newz ~= 0 and newy > -500.0) then
        local color = GetTeamColor(teamID)
        local alpha = 0.5 + math.abs(((time * 3) % 1) - 0.5)
        gl.PushMatrix()
        gl.Translate(newx, newy, newz)
        gl.Lighting(false)
        gl.Color(color[1], color[2], color[3], alpha)
        gl.CallList(coneList)
        gl.PopMatrix()
      end
    end
  end

  gl.Fog(true)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:DrawScreenEffects()
  -- show the names over the team start positions
  gl.Fog(false)
  gl.BeginText()
  for _, teamID in ipairs(Spring.GetTeamList()) do
    local _,leader = Spring.GetTeamInfo(teamID)
    local name,_,spec = Spring.GetPlayerInfo(leader)
    if (name and (not spec) and (teamID ~= gaiaTeamID)) then
      local colorStr, outlineStr = GetTeamColorStr(teamID)
      local x, y, z = Spring.GetTeamStartPosition(teamID)
      if (x ~= nil and x > 0 and z > 0 and y > -500) then
        local sx, sy, sz = Spring.WorldToScreenCoords(x, y + 120, z)
        if (sz < 1) then
          gl.Text(colorStr .. name, sx, sy, 18, 'cs')
        end
      end
    end
  end
  gl.EndText()
  gl.Fog(true)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local mapX = Game.mapSizeX
local mapZ = Game.mapSizeZ
local mapXinv = 1/mapX
local mapZinv = 1/mapZ
local MINIMAP_DRAW_SIZE = math.max(mapX,mapZ) * 0.0145

function widget:DrawInMiniMap(sx, sz)
  -- only show at the beginning
  if (Spring.GetGameFrame() > 1) then
    widgetHandler:RemoveWidget()
  end

  gl.PushMatrix()
  gl.CallList(xformList)

  gl.LineWidth(1.49)

  local gaiaAllyTeamID
  local gaiaTeamID = Spring.GetGaiaTeamID()
  if (gaiaTeamID) then
    local _,_,_,_,_,atid = Spring.GetTeamInfo(gaiaTeamID)
    gaiaAllyTeamID = atid
  end

  -- show all start boxes
  for _,at in ipairs(Spring.GetAllyTeamList()) do
    if (at ~= gaiaAllyTeamID) then
      local xn, zn, xp, zp = Spring.GetAllyTeamStartBox(at)
      if (xn and ((xn ~= 0) or (zn ~= 0) or (xp ~= msx) or (zp ~= msz))) then
        local color
        if (at == Spring.GetMyAllyTeamID()) then
          color = { 0, 1, 0, 0.1 }  --  green
        else
          color = { 1, 0, 0, 0.1 }  --  red
        end
        gl.Color(color)
        gl.Rect(xn, zn, xp, zp)
        color[4] = 0.5  --  pump up the volume
        gl.Color(color)
        gl.PolygonMode(GL.FRONT_AND_BACK, GL.LINE)
        gl.Rect(xn, zn, xp, zp)
        gl.PolygonMode(GL.FRONT_AND_BACK, GL.FILL)
      end
    end
  end

  gl.LineWidth(3)
	gl.LoadIdentity()
	gl.Translate(0,1,0)
	gl.Scale(mapXinv , -mapZinv, 1)
	gl.Rotate(270,1,0,0)
  
  -- show the team start positions
  for _, teamID in ipairs(Spring.GetTeamList()) do
    local _,leader = Spring.GetTeamInfo(teamID)
    local _,_,spec = Spring.GetPlayerInfo(leader)
    if ((not spec) and (teamID ~= gaiaTeamID)) then
      local x, y, z = Spring.GetTeamStartPosition(teamID)
      if (x ~= nil and x > 0 and z > 0 and y > -500) then
        local color = GetTeamColor(teamID)
        local r, g, b = color[1], color[2], color[3]
        local time = Spring.DiffTimers(Spring.GetTimer(), startTimer)
        local i = 2 * math.abs(((time * 3) % 1) - 0.5)
        gl.Color(i, i, i)
        gl.DrawGroundCircle(x,0,z, MINIMAP_DRAW_SIZE*1.2,32)
        gl.Color(r, g, b)
        gl.DrawGroundCircle(x,0,z, MINIMAP_DRAW_SIZE*0.7,32)
      end
    end
  end
  gl.LineWidth(1.0)
  gl.PopMatrix()
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------