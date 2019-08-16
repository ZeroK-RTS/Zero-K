-- $Id: minimap_events.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    minimap_events.lua
--  brief:   display ally events and battle damages in the minimap
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "MinimapEvents",
    desc      = "Display ally events and battle damages in the minimap",
    author    = "trepan",
    date      = "Jul 16, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local GL_LINE_LOOP           = GL.LINE_LOOP
local GL_ONE                 = GL.ONE
local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA
local GL_POINTS              = GL.POINTS
local GL_QUADS               = GL.QUADS
local GL_SRC_ALPHA           = GL.SRC_ALPHA
local GL_TRIANGLE_FAN        = GL.TRIANGLE_FAN
local glBeginEnd             = gl.BeginEnd
local glBlending             = gl.Blending
local glCallList             = gl.CallList
local glColor                = gl.Color
local glCreateList           = gl.CreateList
local glDeleteList           = gl.DeleteList
local glLineWidth            = gl.LineWidth
local glLoadIdentity         = gl.LoadIdentity
local glPopMatrix            = gl.PopMatrix
local glPushMatrix           = gl.PushMatrix
local glRotate               = gl.Rotate
local glScale                = gl.Scale
local glSmoothing            = gl.Smoothing
local glTexCoord             = gl.TexCoord
local glTranslate            = gl.Translate
local glVertex               = gl.Vertex
local glTexture        		 = gl.Texture
local spGetFrameTimeOffset   = Spring.GetFrameTimeOffset
local spGetGameSeconds       = Spring.GetGameSeconds
local spGetUnitPosition      = Spring.GetUnitPosition
local spGetUnitViewPosition  = Spring.GetUnitViewPosition
local spIsUnitAllied         = Spring.IsUnitAllied


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- TODO:
--  - texture atlas for different event types (animated?)
--  - better clamping and default scales
--  - remove unneeded lists (circle, point, rect)
--  - varied alpha?
--  - option for local team only (no allied events)
--  - speed-ups ...

--
--  event = {
--    u = unitID
--    v = pixels value
--    x = x position
--    z = z position
--    c = color
--  }
--
--  damage = {
--    u = unitID
--    v = damage value    (pixels)
--    p = paralyze value  (pixels)
--  }
--

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local stockpileExceptions = {
	[UnitDefNames["turretaaheavy"].id] = true,
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local lineWidth = 2  -- set to 0 to remove outlines

local eventScale = 0.02

local doDamages = true

local fracScale = 50
local healthScale = 0 -- 0.001

local paraFracScale = fracScale * 0.25
local paraHealthScale = healthScale * 0

local alpha = 0.3
local deathColor     = { 1.0, 0.2, 0.2, alpha }
local takenColor     = { 1.0, 0.0, 1.0, alpha }
local createColor    = { 0.0, 1.0, 0.0, alpha }
local stockpileColor = { 1.0, 1.0, 1.0, alpha }
local damageColor    = { 1.0, 1.0, 0.0, alpha }
local paralyzeColor  = { 0.0, 0.0, 1.0, alpha }

local limit = 0.1

local minAlpha = 0.4
local minPixels = 5.0


--------------------------------------------------------------------------------

local gl = gl

local gameSecs = 0
local gamestart = false

local xMapSize = Game.mapX * 512
local yMapSize = Game.mapY * 512
local pxScale = 1  -- (xMapSize / minimap xPixels)
local pyScale = 1  -- (yMapSize / minimap yPixels)

local rectList = 0

local pointList = 0

local circleDivs = 16
local circleList = 0


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local eventMap  = {}

local damageMap = {}


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetGameSecs()
  return spGetGameSeconds() + spGetFrameTimeOffset()
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GameStart()
  gamestart = true
end

local function CreateLists()
  circleList = glCreateList(function()
    glBeginEnd(GL_TRIANGLE_FAN, function()
      for i = 0, circleDivs - 1 do
        local r = 2.0 * math.pi * (i / circleDivs)
        local cosv = math.cos(r)
        local sinv = math.sin(r)
        --glTexCoord(cosv, sinv)
        glVertex(cosv, sinv, 0)
      end
    end)
    if (lineWidth > 0) then
      glBeginEnd(GL_LINE_LOOP, function()
        for i = 0, circleDivs - 1 do
          local r = 2.0 * math.pi * (i / circleDivs)
          local cosv = math.cos(r)
          local sinv = math.sin(r)
          --glTexCoord(cosv, sinv)
          glVertex(cosv, sinv, 0)
        end
      end)
    end
  end)
  --pointList = glCreateList(function()
  --  glBeginEnd(GL_POINTS, function()
  --    glVertex(0, 0, 0)
  --  end)
  --end)
  --rectList = glCreateList(function()
  --  glBeginEnd(GL_QUADS, function()
  --    --glTexCoord(0, 0);
  --    glVertex(-1, -1, 0)
  --    --glTexCoord(1, 0);
  --    glVertex( 1, -1, 0)
  --    --glTexCoord(1, 1);
  --    glVertex( 1,  1, 0)
  --    --glTexCoord(0, 1);
  --    glVertex(-1,  1, 0)
  --  end)
  --end)
end

function widget:Initialize()

  gameSecs = GetGameSecs()
  gamestart = gameSecs > 0

  
end


function widget:Shutdown()
  --glDeleteList(rectList)
  --glDeleteList(pointList)
  glDeleteList(circleList)
end


--------------------------------------------------------------------------------

function widget:Update(dt)

  local gs = GetGameSecs()
  if (gs == gameSecs) then
    return
  end
--  dt = gs - gameSecs
  gameSecs = gs

  local scale = (1 - (4 * dt))

  for unitID, d in pairs(eventMap) do
    local v = d.v
    v = v * scale
    if (v < limit) then
      eventMap[unitID] = nil
    else
      d.v = v
    end
  end

  for unitID, d in pairs(damageMap) do
      local v = d.v * scale
      local p = d.p * scale

      if (v > limit) then
        d.v = v
      else
        if (p > limit) then
          d.v = 0
        else
          damageMap[unitID] = nil
        end
      end

      if (p > 1) then
        d.p = p
      else
        if (v > 1) then
          d.p = 0
        else
          damageMap[unitID] = nil
        end
      end
  end
end


--------------------------------------------------------------------------------
local terraunitDefID = UnitDefNames["terraunit"].id

local function AddEvent(unitID, unitDefID, color, cost)
  if (not spIsUnitAllied(unitID)) then
    return
  end
  local ud = UnitDefs[unitDefID]
  if ((ud == nil) or ud.isFeature or unitDefID == terraunitDefID) then
    return
  end
  local px, py, pz = spGetUnitPosition(unitID)
  if (px and pz) then
    eventMap[unitID] = {
      x = px,
      z = pz,
      v = cost or (ud.metalCost * eventScale),
      u = unitID,
      c = color,
--      t = GetGameSeconds()
    }
  end
end


function widget:UnitFinished(unitID, unitDefID, unitTeam)
  if not gamestart then return end
  AddEvent(unitID, unitDefID, createColor)
end


function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
  damageMap[unitID] = nil
  AddEvent(unitID, unitDefID, deathColor)
end


function widget:UnitTaken(unitID, unitDefID)
  damageMap[unitID] = nil
  AddEvent(unitID, unitDefID, takenColor)
end


function widget:StockpileChanged(unitID, unitDefID, unitTeam,
                                 weaponNum, oldCount, newCount)
  if (newCount > oldCount) and not stockpileExceptions[unitDefID] then
    AddEvent(unitID, unitDefID, stockpileColor, 100)
  end
end


--------------------------------------------------------------------------------

function widget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer)
  if (not doDamages) then
    return
  end
  if (not spIsUnitAllied(unitID)) then
    return
  end
  if (damage <= 0) then
    return
  end

  local ud = UnitDefs[unitDefID]
  if (ud == nil) then
    return
  end

  -- clamp the damage
  damage = math.min(ud.health, damage)

  -- scale the damage value
  if (paralyzer) then
    damage = (paraHealthScale * damage) +
             (paraFracScale   * (damage / ud.health))
  else
    damage = (healthScale * damage) +
             (fracScale   * (damage / ud.health))
  end


  local d = damageMap[unitID]
  if (d ~= nil) then
    if (paralyzer) then
      d.p = d.p + damage
    else
      d.v = d.v + damage
    end
  else
    d = {}
    d.u = unitID
--    d.t = GetGameSeconds()
    if (paralyzer) then
      d.v = 0
      d.p = math.max(1, damage)
    else
      d.v = math.max(1, damage)
      d.p = 0
    end
    damageMap[unitID] = d
  end
  if d.v > 0 and d.v < minPixels then d.v = minPixels end
  if d.p >0 and d.p  < minPixels then d.p = minPixels end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function DrawEvent(event)
  local pixels = event.v

  local color = event.c
  color[4] = alpha

  local scale = minPixels + pixels
  
  glPushMatrix()
  glTranslate(event.x, event.z, 0)
  glScale(scale * pxScale, scale * pyScale, 1)
  glColor(color)
  glCallList(circleList)
  glPopMatrix()
end


local function DrawDamage(damage)

  local px, py, pz = spGetUnitViewPosition(damage.u)
  if (px == nil) then
    return
  end


  local pixels = damage.v
  
  if (pixels > 0) then
    
	local scale = minPixels + pixels
	
    glPushMatrix()
    glTranslate(px, pz, 0)
    glScale(scale * pxScale, scale * pyScale, 1)
    glColor(damageColor)
	glCallList(circleList)
    glPopMatrix()
  end

  pixels = damage.p
  if (pixels > 0) then

    local scale = minPixels + pixels

    glPushMatrix()
    glTranslate(px, pz, 0)
    glScale(scale * pxScale, scale * pyScale, 1)
	glColor(paralyzeColor)
    glCallList(circleList)
    glPopMatrix()
  end

end


--------------------------------------------------------------------------------

function widget:DrawInMiniMap(xSize, ySize)
  if ((next(eventMap)  == nil) and
      (next(damageMap) == nil)) then
    return
  end
  
  if circleList == 0 then
	CreateLists()
  end
  
  if glSmoothing then
    glSmoothing(false, false, false)
  end
  glBlending(GL_SRC_ALPHA, GL_ONE)
  glLineWidth(lineWidth)
  glTexture(false)
  gl.Lighting(false)

  -- setup the pixel scales
  pxScale = xMapSize / xSize
  pyScale = yMapSize / ySize

  glPushMatrix()

  glLoadIdentity()
  glTranslate(0, 1, 0)
  glScale(1 / xMapSize, -1 / yMapSize,1)
  
  -- draw damages before events
  for _,damage in pairs(damageMap) do
    DrawDamage(damage)
  end

  for _,event in pairs(eventMap) do
    DrawEvent(event)
  end

  glPopMatrix()

  glLineWidth(1)
  glColor(1,1,1,1)
  --gl.Lighting(true)
  glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
  if glSmoothing then
    glSmoothing(true, true, false)
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
