-- $Id: gui_selectioncircle.lua 3929 2009-02-08 17:12:28Z jk $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "SelectionCircle",
    desc      = "Shows a circle instead of a selection rectangle",
    author    = "trepan (tweaked by jK,Nemo)",
    date      = "Feb, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 5,
    enabled   = false  --  loaded by default?
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

function widget:Initialize()
  circleLines = gl.CreateList(function()
    gl.BeginEnd(GL.LINE_LOOP, function()
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

local function SetUnitColor(unitID)
  local teamID = GetUnitTeam(unitID)
  if (teamID == nil) then
    glColor(1.0, 0.0, 0.0, 0.45) -- red
  elseif (teamID == GetMyTeamID()) then
    glColor(0.0, 1.0, 1.0, 0.75) -- cyan
  elseif (GetUnitAllyTeam(unitID) == GetMyAllyTeamID()) then
    glColor(0.0, 1.0, 0.0, 0.45) -- green
  else
    glColor(1.0, 0.25, 0.25, 0.9) -- red
  end
end





function widget:DrawWorldPreUnit()
  local selUnits = spGetSelectedUnits()

  glLineWidth(2.5)
  if (selUnits)and(selUnits[1]) then
    --gl.DepthTest(false)
    --gl.PolygonOffset(-50, 1000)

    local lastColorSet = nil
    for i=1,#selUnits do
      local unitID = selUnits[i]
      if (IsUnitVisible(unitID)) then
        local teamID = GetUnitTeam(unitID)
        if (teamID) then
          local radius = GetUnitRadius(unitID)
          if (radius) then
            local unitDefID = GetUnitDefID(unitID)
            if (UnitDefs[unitDefID or -1].canFly) then radius = radius*0.5 end
            local colorSet  = teamColors[teamID]
            local x, y, z   = GetUnitBasePosition(unitID)
            if (x) then
              local gx, gy, gz = 0,1,0
              if (y>1) then gx, gy, gz = GetGroundNormal(x,z) end
              local degrot = acos(gy) * PI_DEG
              if (colorSet) then
                glColor(colorSet)
                glDrawListAtUnit(unitID, circleLines, false,
                                 radius, 1.0, radius,
                                 degrot, gz, 0, -gx)
              else
                local r,g,b = Spring.GetTeamColor(teamID)
                teamColors[teamID] = { r, g, b, 0.6 }
              end
            end
          end
        end
      end
    end
  end --// if (not selUnits)or(not selUnits[1]) 


  -- highlight hovered unit
  local mx, my     = GetMouseState()
  local type, data = TraceScreenRay(mx, my)

  if (type == 'unit') then
    local unitID = GetPlayerControlledUnit(GetMyPlayerID())
    if (data ~= unitID) then
      SetUnitColor(data)
      local radius = GetUnitRadius(data)
      if (radius) then
        local unitDefID = GetUnitDefID(data)
        if (UnitDefs[unitDefID or -1].canFly) then radius = radius*0.5 end
        local x, y, z = GetUnitBasePosition(data)
        if (x) then
          local gx, gy, gz = 0,1,0
          if (y>1) then gx, gy, gz = GetGroundNormal(x,z) end
          local degrot = acos(gy) * PI_DEG
          glLineWidth(3.5)
          glDrawListAtUnit(data, circleLines, false,
                                  radius, 1.0, radius,
                                  degrot, gz, 0, -gx)
          glLineWidth(1)

          -- also draw the unit's command queue
          local a,c,m,s = GetModKeyState()
          if (m)or(not selUnits[1]) then
            DrawUnitCommands(data)
          end
          glColor(1,1,1,1)
        end
      end
    end
  elseif (type == 'feature') then
    --gl.DepthTest(true)
    --gl.PolygonOffset(-20000,-500000)
    glLineWidth(2.5)

    glColor(1.0, 0.0, 1.0, 0.70)
    local radius  = GetFeatureRadius(data)
    local x, y, z = GetFeaturePosition(data)
    local gx, gy, gz = GetGroundNormal(x, z)
    local degrot = acos(gy) * PI_DEG

    glPushMatrix()
    glTranslate(x,y,z)
    glScale(radius,1,radius)
    glRotate(degrot,gz,0,-gx)
    glCallList(circleLines)
    glPopMatrix()

    glLineWidth(1)
    --gl.PolygonOffset(false)
    --gl.DepthTest(false)
    glColor(1,1,1,1)
  end

  glLineWidth(1)
  --gl.DepthTest(true)
  --gl.PolygonOffset(false)
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
