-- $Id: gui_selectionhalo.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "SelectionHalo",
    desc      = "Shows a halo around selected and hovered units/features.",
    author    = "jK",
    date      = "2009",
    license   = "GNU GPL, v2 or later",
    layer     = 5,
    handler   = true,
    enabled   = false, --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function SetupCommandColors(state)
  local alpha = state and 1 or 0
  local f = io.open('cmdcolors.tmp', 'w+')
  if (f) then
    f:write('unitBox  0 1 0 ' .. alpha)
    f:close()
    Spring.SendCommands({'cmdcolors cmdcolors.tmp'})
  end
  os.remove('cmdcolors.tmp')
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local teamColors = {}

local circleLines  = 0

local circleDivs   = 32
local circleOffset = 0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local GL_ZERO      = GL.ZERO
local GL_KEEP      = 0x1E00
local GL_REPLACE   = 0x1E01  
local GL_INCR      = 0x1E02  
local GL_DECR      = 0x1E03
local GL_INCR_WRAP = 0x8507
local GL_DECR_WRAP = 0x8508
local GL_STENCIL_BITS = 0x0D57

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
  local stencilBits = gl.GetNumber(GL_STENCIL_BITS)

  if (stencilBits < 1) then
    Spring.Echo('Hardware support not available, quitting')
    widgetHandler:RemoveWidget(widget)
    return
  end

  circleLines = gl.CreateList(function()
    gl.BeginEnd(GL.LINE_LOOP, function()
      local radstep = (2.0 * math.pi) / circleDivs
      for i = 1, circleDivs do
        local a = (i * radstep)
        gl.Vertex(math.sin(a), circleOffset, math.cos(a))
      end
    end)
    gl.BeginEnd(GL.POINTS, function()
      local radstep = (2.0 * math.pi) / circleDivs
      for i = 1, circleDivs do
        local a = (i * radstep)
        gl.Vertex(math.sin(a), circleOffset, math.cos(a))
      end
    end)
  end)

  SetupCommandColors(false)
end


function widget:Shutdown()
  gl.DeleteList(circleLines)

  SetupCommandColors(true)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Speed-ups
--

local GetUnitTeam         = Spring.GetUnitTeam
local GetUnitDefID        = Spring.GetUnitDefID
local GetUnitRadius       = Spring.GetUnitRadius
local GetUnitViewPosition = Spring.GetUnitViewPosition
local GetUnitBasePosition = Spring.GetUnitBasePosition
local GetUnitAllyTeam     = Spring.GetUnitAllyTeam
local spGetSelectedUnits  = Spring.GetSelectedUnits
local IsUnitVisible       = Spring.IsUnitVisible
local IsUnitSelected      = Spring.IsUnitSelected
local GetGroundNormal     = Spring.GetGroundNormal
local GetMouseState       = Spring.GetMouseState
local TraceScreenRay      = Spring.TraceScreenRay
local GetMyPlayerID       = Spring.GetMyPlayerID
local GetMyTeamID         = Spring.GetMyTeamID
local GetMyAllyTeamID     = Spring.GetMyAllyTeamID
local GetUnitRadius       = Spring.GetUnitRadius
local GetModKeyState      = Spring.GetModKeyState
local DrawUnitCommands    = Spring.DrawUnitCommands
local GetPlayerControlledUnit = Spring.GetPlayerControlledUnit
local GetFeatureRadius   = Spring.GetFeatureRadius
local GetFeaturePosition = Spring.GetFeaturePosition

local acos   = math.acos
local PI_DEG = 180 / math.pi

local glPushMatrix = gl.PushMatrix
local glTranslate  = gl.Translate
local glScale      = gl.Scale
local glRotate     = gl.Rotate
local glCallList   = gl.CallList
local glPopMatrix  = gl.PopMatrix
local glLineWidth  = gl.LineWidth
local glColor          = gl.Color
local glDrawListAtUnit = gl.DrawListAtUnit
local glUnit = gl.Unit

local function SetUnitColor(unitID)
  local teamID = GetUnitTeam(unitID)
  if (teamID == nil) then
    glColor(1.0, 0.0, 0.0, 1) -- red
  elseif (teamID == GetMyTeamID()) then
    glColor(0.0, 1.0, 1.0, 1) -- cyan
  elseif (GetUnitAllyTeam(unitID) == GetMyAllyTeamID()) then
    glColor(0.0, 1.0, 0.0, 1) -- green
  else
    glColor(1.0, 0.3, 0.3, 1) -- red
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Main
--

local selUnits = {}
local visUnit = {}
local visUnitNum = 0
local hoveredType = "ground"
local hoveredData = 0
local sec = 0


function widget:SelectionChanged(newSelection)
  selUnits = newSelection
end


function widget:Update(dt)
  sec = sec+dt
  if (sec < 1/30) then
    return
  end
  sec=0

  visUnit = {}
  visUnitNum = 0
  for i=1,#selUnits do
    local unitID = selUnits[i]
    if (IsUnitVisible(unitID,nil,true)) then
      visUnitNum = visUnitNum+1
      visUnit[visUnitNum] = unitID
    end
  end

  local mx, my = GetMouseState()
  if (widgetHandler:IsAbove(mx, my)) then
    hoveredType="ground"
    return
  end

  hoveredType, hoveredData = TraceScreenRay(mx, my)
  if (hoveredType=="unit") then
    local unitID = GetPlayerControlledUnit(GetMyPlayerID())
    if (hoveredData==unitID) then
      hoveredType="ground"
    end
  end
end


function widget:DrawWorld()
  if (visUnitNum==0)and(hoveredType=="ground") then
    return;
  end

  glLineWidth(3)
  gl.PointSize(3)
  gl.Blending(false)
  gl.Smoothing(true,true)
  gl.DepthTest(true)
  gl.PolygonOffset(0,-95)
  gl.StencilTest(true)
  gl.StencilMask(1)

  if (visUnitNum>0) then
    gl.ColorMask(false)
    gl.StencilFunc(GL.ALWAYS, 1, 1)
    gl.StencilOp(GL_KEEP, GL_KEEP, GL_REPLACE)
    gl.PolygonMode(GL.FRONT_AND_BACK,GL.FILL)
    for i=1,visUnitNum do
      glUnit(visUnit[i],true,-1)
    end

    gl.ColorMask(true)
    glColor(0.25,1,0.25,1)
    gl.StencilFunc(GL.NOTEQUAL, 1, 1)
    gl.StencilOp(GL_KEEP, GL_KEEP, GL_KEEP)
    gl.PolygonMode(GL.FRONT_AND_BACK,GL.LINE)
    for i=1,visUnitNum do
      glUnit(visUnit[i],true,-1)
    end
    gl.PolygonMode(GL.FRONT_AND_BACK,GL.POINT)
    for i=1,visUnitNum do
      glUnit(visUnit[i],true,-1)
    end

    gl.ColorMask(false)
    gl.StencilFunc(GL.ALWAYS, 0, 1)
    gl.StencilOp(GL_ZERO, GL_ZERO, GL_ZERO)
    gl.PolygonMode(GL.FRONT_AND_BACK,GL.FILL)
    if (visUnitNum<10) then
      for i=1,visUnitNum do
        glUnit(visUnit[i],true,-1)
      end
    else
      gl.PushMatrix()
      gl.LoadIdentity()
      gl.MatrixMode(GL.PROJECTION)
        gl.PushMatrix()
        gl.LoadIdentity()

      gl.Rect(-1,-1,1,1)

        gl.PopMatrix()
      gl.MatrixMode(GL.MODELVIEW)
      gl.PopMatrix()
    end
  end --// if (not selUnits)or(not selUnits[1])


  -- highlight hovered unit
  glLineWidth(4)
  gl.PointSize(4)

  if (hoveredType == 'unit') then
    gl.ColorMask(false)
    gl.StencilFunc(GL.ALWAYS, 1, 1);
    gl.StencilOp(GL_KEEP, GL_KEEP, GL_REPLACE)
    gl.PolygonMode(GL.FRONT_AND_BACK,GL.FILL)
    gl.Unit(hoveredData,true,-1)

    gl.ColorMask(true)
    gl.StencilFunc(GL.NOTEQUAL, 1, 1)
    gl.StencilOp(GL_KEEP, GL_KEEP, GL_KEEP)

    SetUnitColor(hoveredData)
    gl.PolygonMode(GL.FRONT_AND_BACK,GL.LINE)
    gl.Unit(hoveredData,true,-1)
    gl.PolygonMode(GL.FRONT_AND_BACK,GL.POINT)
    gl.Unit(hoveredData,true,-1)

    gl.ColorMask(false)
    gl.StencilFunc(GL.ALWAYS, 0, 1);
    gl.StencilOp(GL_REPLACE, GL_REPLACE, GL_REPLACE)
    gl.PolygonMode(GL.FRONT_AND_BACK,GL.FILL)
    gl.Unit(hoveredData,true,-1)

    -- also draw the unit's command queue
    local a,c,m,s = GetModKeyState()
    if (m)or(not selUnits[1]) then
      DrawUnitCommands(hoveredData)
    end
  elseif (hoveredType == 'feature') then
    glColor(1, 0, 1, 1)

    local fd = FeatureDefs[Spring.GetFeatureDefID(hoveredData)]

    if (fd)and(not fd.noSelect) then
      if (fd.drawTypeString == 'tree') then
        local radius  = GetFeatureRadius(hoveredData)
        local x, y, z = GetFeaturePosition(hoveredData)
        local gx, gy, gz = GetGroundNormal(x, z)
        local degrot = acos(gy) * PI_DEG

        glLineWidth(5)
        gl.PointSize(5)
        gl.ColorMask(true)

        gl.StencilTest(false)

        glPushMatrix()
        glTranslate(x,y+1,z)
        glScale(radius,1,radius)
        glRotate(degrot,gz,0,-gx)
        glCallList(circleLines)
        glPopMatrix()
      else
        gl.ColorMask(false)
        gl.StencilFunc(GL.ALWAYS, 1, 1)
        gl.StencilOp(GL_KEEP, GL_KEEP, GL_REPLACE)
        gl.PolygonMode(GL.FRONT_AND_BACK,GL.FILL)
        gl.Feature(hoveredData)

        gl.ColorMask(true)
        gl.StencilFunc(GL.NOTEQUAL, 1, 1)
        gl.StencilOp(GL_KEEP, GL_KEEP, GL_KEEP)
        gl.PolygonMode(GL.FRONT_AND_BACK,GL.LINE)
        gl.Feature(hoveredData)
        gl.PolygonMode(GL.FRONT_AND_BACK,GL.POINT)
        gl.Feature(hoveredData)

        gl.ColorMask(false)
        gl.StencilFunc(GL.ALWAYS, 0, 1)
        gl.StencilOp(GL_REPLACE, GL_REPLACE, GL_REPLACE)
        gl.PolygonMode(GL.FRONT_AND_BACK,GL.FILL)
        gl.Feature(hoveredData)
      end
    end
  end

  gl.ColorMask(true)
  gl.StencilTest(false)
  glColor(1,1,1,1)
  glLineWidth(1)
  gl.PointSize(1)
  gl.PolygonMode(GL.FRONT_AND_BACK,GL.FILL)
  gl.Blending(true)
  --gl.Smoothing(true,true)
  gl.DepthTest(false)
  gl.DepthMask(false)
  gl.PolygonOffset(false)
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

