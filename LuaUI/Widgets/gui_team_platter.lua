-- see http://springrts.com/phpbb/viewtopic.php?f=23&t=21244&start=60 for opt
-- http://code.google.com/p/zero-k/source/browse/trunk/mods/zk/LuaUI/Widgets/unit_shapes.lua?spec=svn647&r=647

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    gui_team_platter.lua
--  brief:   team colored platter for all visible units
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "TeamPlatter",
    desc      = "Shows a team color platter above all visible units",
    author    = "trepan, tweaked by Sphiloth",
    date      = "Apr 16, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 5,
    enabled   = false,  --  loaded by default?
  }
end

local widgetName = widget:GetInfo().name


local SafeWGCall = function(fnName, param1) if fnName then return fnName(param1) else return nil end end
local GetUnitUnderCursor = function(onlySelectable) return SafeWGCall(WG.PreSelection_GetUnitUnderCursor, onlySelectable) end
local IsSelectionBoxActive = function() return SafeWGCall(WG.PreSelection_IsSelectionBoxActive) end
local GetUnitsInSelectionBox = function() return SafeWGCall(WG.PreSelection_GetUnitsInSelectionBox) end
local IsUnitInSelectionBox = function(unitID) return SafeWGCall(WG.PreSelection_IsUnitInSelectionBox, unitID) end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


-- Automatically generated local definitions

local GL_LINE_LOOP           = GL.LINE_LOOP
local GL_TRIANGLE_FAN        = GL.TRIANGLE_FAN
local glBeginEnd             = gl.BeginEnd
local glColor                = gl.Color
local glCreateList           = gl.CreateList
local glDeleteList           = gl.DeleteList
local glDepthTest            = gl.DepthTest
local glDrawListAtUnit       = gl.DrawListAtUnit
local glLineWidth            = gl.LineWidth
local glPolygonOffset        = gl.PolygonOffset
local glVertex               = gl.Vertex
local spDiffTimers           = Spring.DiffTimers
local spGetAllUnits          = Spring.GetAllUnits
local spGetGroundNormal      = Spring.GetGroundNormal
local spGetSelectedUnits     = Spring.GetSelectedUnits
local spGetTeamColor         = Spring.GetTeamColor
local spGetTimer             = Spring.GetTimer
local spGetUnitPosition      = Spring.GetUnitPosition
local spGetUnitDefDimensions = Spring.GetUnitDefDimensions
local spGetUnitDefID         = Spring.GetUnitDefID
--local spGetUnitRadius        = Spring.GetUnitRadius --not used
local spGetUnitTeam          = Spring.GetUnitTeam
local spGetUnitViewPosition  = Spring.GetUnitViewPosition
local spGetUnitNoDraw        = Spring.GetUnitNoDraw
local spIsUnitSelected       = Spring.IsUnitSelected
local spIsUnitVisible        = Spring.IsUnitVisible
local spSendCommands         = Spring.SendCommands
local spGetVisibleUnits      = Spring.GetVisibleUnits


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Manual optimizations

local spIsGUIHidden = Spring.IsGUIHidden
local abs = math.abs
local acos = math.acos
local cos = math.cos
local sin = math.sin
local pi = math.pi
local radInDeg = 180/pi

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Memoization tables

local realRadii = {}

local teamColors = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function SetupCommandColors(state)
  local alpha = state and 1 or 0
  local f = io.open('cmdcolors.tmp', 'w+')
  if (f) then
    f:write('unitBox  0 1 0 ' .. alpha)
    f:close()
    spSendCommands({'cmdcolors cmdcolors.tmp'})
  end
  os.remove('cmdcolors.tmp')
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/Interface/Selection/Team Platters'
options = {
  outlineOpacity = {
      name = "Outline opacity (0 boosts performance)",
      type = 'number',
      value = 0, min = 0, max = 1, step = 0.05,
      --desc = "How much can be seen through the circle outline. The outline can removed completely by " ..
      --"setting this to 1, significantly enhancing performance",
  },
  fillOpacity = {
      name = "Fill opacity",
      type = 'number',
      value = 0.4, min = 0, max = 1, step = 0.05,
      --desc = "How much can be seen through the circle fill",
  },
  extraRadius = {
      name = "Platter size",
      type = 'number',
      value = 6, min = 0, max = 10, step = 0.5,
      --desc = "How much additional padding should be added to the circle radius in pixels",
  },
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local teamColors = {}

local trackSlope = true

local circleLines  = 0
local circlePolys  = 0
local circleDivs   = 32
local circleOffset = 0
local lineWidth = 3
local noOutlineMakeUp = lineWidth/2

local startTimer = spGetTimer()


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function ClearColorMemoization()
  teamColors = {}
end



function widget:Initialize()

  circleLines = glCreateList(function()
    glBeginEnd(GL_LINE_LOOP, function()
      local radstep = (2.0 * pi) / circleDivs
      for i = 1, circleDivs do
        local a = (i * radstep)
        glVertex(sin(a), circleOffset, cos(a))
      end
    end)
  end)

  circlePolys = glCreateList(function()
    glBeginEnd(GL_TRIANGLE_FAN, function()
      local radstep = (2.0 * pi) / circleDivs
      for i = 1, circleDivs do
        local a = (i * radstep)
        glVertex(sin(a), circleOffset, cos(a))
      end
    end)
  end)

  SetupCommandColors(false)

  self:LocalColorRegister()
end


function widget:Shutdown()
  glDeleteList(circleLines)
  glDeleteList(circlePolys)

  SetupCommandColors(true)

  self:LocalColorUnregister()
end

function widget:LocalColorRegister()
  if WG.LocalColor and WG.LocalColor.RegisterListener then
    WG.LocalColor.RegisterListener(widgetName, ClearColorMemoization)
  end
end

function widget:LocalColorUnregister()
  if WG.LocalColor and WG.LocalColor.UnregisterListener then
    WG.LocalColor.UnregisterListener(widgetName)
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------




local function GetUnitDefRealRadius(udid)
  local radius = realRadii[udid]
  if (radius) then
    return radius
  end

  local ud = UnitDefs[udid]
  if (ud == nil) then return nil end

  local dims = spGetUnitDefDimensions(udid)
  if (dims == nil) then return nil end

  local scale = ud.hitSphereScale -- missing in 0.76b1+
  scale = ((scale == nil) or (scale == 0.0)) and 1.0 or scale
  radius = dims.radius / scale
  realRadii[udid] = radius
  return radius
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------




local function GetTeamColorSet(teamID)
  local colors = teamColors[teamID]
  if (colors) then
    return colors
  end
  local r,g,b = spGetTeamColor(teamID)
  
  colors = { r, g, b }
  teamColors[teamID] = colors
  return colors
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:DrawWorldPreUnit()
if not spIsGUIHidden() then
  local extraRadius = options.extraRadius.value
  local fillOpacity = options.fillOpacity.value
  local outlineOpacity = options.outlineOpacity.value
  local showOutline = (outlineOpacity > 0)
  local noOutlineExtraRadius = extraRadius + noOutlineMakeUp
  
  glLineWidth(lineWidth)

  glDepthTest(false)
  
  glPolygonOffset(-50, -2)

  --local lastColorSet = nil
  local visUnits = spGetVisibleUnits(-1, nil, false)

  --for _,unitID in ipairs(spGetAllUnits()) do
  if visUnits then
    for i = 1, #visUnits do
      --if (spIsUnitVisible(visUnits[i])) then
      if (not spGetUnitNoDraw(visUnits[i])) then
        local teamID = spGetUnitTeam(visUnits[i])
        if (teamID) then
          local udid = spGetUnitDefID(visUnits[i])
          local radius = GetUnitDefRealRadius(udid)
          if (radius) then
            if showOutline then
              radius = radius + extraRadius
            else
              radius = radius + noOutlineExtraRadius
            end
            local colorSet  = GetTeamColorSet(teamID)
            if (trackSlope and (not UnitDefs[udid].canFly)) then
              local x, y, z = spGetUnitPosition(visUnits[i])
              local gx, gy, gz = spGetGroundNormal(x, z)
              local degrot = acos(gy) * radInDeg
              colorSet[4] = fillOpacity
              glColor(colorSet)
              glDrawListAtUnit(visUnits[i], circlePolys, false,
                               radius, 1.0, radius,
                               degrot, gz, 0, -gx)
              if showOutline then
                colorSet[4] = outlineOpacity
                glColor(colorSet)
                glDrawListAtUnit(visUnits[i], circleLines, false,
                                 radius, 1.0, radius,
                                 degrot, gz, 0, -gx)
              end
            else
              colorSet[4] = fillOpacity
              glColor(colorSet)
              glDrawListAtUnit(visUnits[i], circlePolys, false,
                               radius, 1.0, radius)
              if showOutline then
                colorSet[4] = outlineOpacity
                glColor(colorSet)
                glDrawListAtUnit(visUnits[i], circleLines, false,
                                 radius, 1.0, radius)
              end
            end
          end
        end
      end
    end
  end

  glPolygonOffset(false)

  --
  -- Blink the selected units
  --

  --glDepthTest(false)

  local diffTime = spDiffTimers(spGetTimer(), startTimer)
  local alpha = 1.8 * abs(0.5 - (diffTime * 3.0 % 1.0))
  glColor(1, 1, 1, alpha)

  -- for _,unitID in ipairs(spGetSelectedUnits()) do
  local units = spGetVisibleUnits(-1, 30, true)
  for i=1, #units do
    local unitID = units[i]
    if IsUnitInSelectionBox(unitID) or (GetUnitUnderCursor() == unitID and not spIsUnitSelected(unitID)) then
      glColor(1, 1, 1, 0.5)
    else
      glColor(1, 1, 1, alpha)
    end
    
    if (spIsUnitSelected(unitID) or IsUnitInSelectionBox(unitID) or GetUnitUnderCursor(false) == unitID) and not spGetUnitNoDraw(unitID) then
      local udid = spGetUnitDefID(unitID)
      local radius = GetUnitDefRealRadius(udid)
      if (radius) then
        radius = radius + extraRadius
        if (trackSlope and (not UnitDefs[udid].canFly)) then
          local x, y, z = spGetUnitPosition(unitID)
          local gx, gy, gz = spGetGroundNormal(x, z)
          local degrot = acos(gy) * radInDeg
          glDrawListAtUnit(unitID, circleLines, false,
                           radius, 1.0, radius,
                           degrot, gz, 0, -gx)
        else
          glDrawListAtUnit(unitID, circleLines, false,
                           radius, 1.0, radius)
        end
      end
    end
  end
  glColor(1, 1, 1,1)
  glLineWidth(1.0)
end
end
              

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
