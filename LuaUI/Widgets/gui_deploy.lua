-- $Id: gui_deploy.lua 4534 2009-05-04 23:35:06Z licho $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    gui_deploy.lua
--  brief:   custom deploy gui
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (Spring.GetModOptions().zkmode~="deploy") then
  return false --//remove widget quietly
end

function widget:GetInfo()
  return {
    name      = "Deploy",
    desc      = "custom deploy gui",
    author    = "trepan",
    date      = "May 02, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include('colors.h.lua')


local featureLabel = 'Deployment'
if (string.find(string.lower(Game.modName), 'tactics')) then
  featureLabel = 'Tactics'
end

local active = 0

local teams = {}
local teamReadys = {}

local invertValues = false

local teamRangeLists = {}
local circleList = 0
local miniMapXformList = 0

local worldDivs   = 1024
local minimapDivs = 256

local vsx, vsy = widgetHandler:GetViewSizes()
local cx,  cy  = vsx*0.5, 111

function widget:ViewResize(viewSizeX, viewSizeY)
  vsx = viewSizeX
  vsy = viewSizeY

  if (cx<0) then --this centers the dialog you first start this widget
    cx, cy = vsx/2, 111
    widget:MouseMove(cx, cy, 0, 0, 1)
  else
    local dx, dy = vsx - cx, vsy - cy
    vsx = viewSizeX
    vsy = viewSizeY
    cx, cy = vsx - dx, vsy - dy
    widget:MouseMove(cx, cy, 0, 0, 1)
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Update()
  active = active - 1
  active = (active < 0) and 0 or active
end


function widget:IsAbove(x, y)
  if (active <= 0) then
    return false
  end
  if ((x > (cx - 75)) and (x < (cx + 75)) and
      (y > (cy - 10)) and (y < (cy + 100))) then
    return true
  end
  return false
end


function widget:GetTooltip(x, y)
  local noteColor  = '\255\128\255\128'
  local tipColor1  = '\255\255\128\64'
  local tipColor2  = '\255\255\255\128'
  local tipColor3  = '\255\160\160\160'
  local ready = RedStr .. 'Ready' .. noteColor
  local tt = ''
  if (invertValues) then
    tt = 'Deployment Remaining\n'
  else
    tt = 'Deployment Expended\n'
  end
  tt = tt .. noteColor .. 'Select the commander and press ' .. ready
  tt = tt              .. ' when you are done\n'
  tt = tt .. tipColor1 .. 'Tip: '
  tt = tt .. tipColor2 .. 'use ALT + RIGHT-CLICK to delete units\n'
  tt = tt .. tipColor3 .. '       (with comm selected)'
  return tt
end


function widget:MousePress(x, y, b)
  if (not widget:IsAbove(x, y)) then
    return false
  end
  if (b == 3) then
    invertValues = not invertValues
    return false
  end
  return (b == 1)
end


function widget:MouseMove(x, y, dx, dy, b)
  cx = cx + dx
  cy = cy + dy
  if vsx>10 then
    local xn, xp = 100, (vsx - 100)
    local yn, yp =  10, (vsy - 100)
    cx = ((cx < xn) and xn) or ((cx > xp) and xp) or cx
    cy = ((cy < yn) and yn) or ((cy > yp) and yp) or cy
  end
end


function widget:MouseRelease(x, y, b)
  return -1
end

function widget:GetConfigData()
  return {
    posx = cx,
    posy = cy,
  }
end

function widget:SetConfigData(data)
  cx = data.posx or -1
  cy = data.posy or 111

  widget:MouseMove(cx, cy, 0, 0, 1)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
  widgetHandler:RegisterGlobal('DeployUpdate', DeployUpdate)
end


function widget:Shutdown()
  widgetHandler:DeregisterGlobal('DeployUpdate')
  for teamID, listID in pairs(teamRangeLists) do
    gl.DeleteList(listID)
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function DeployUpdate(...)
  local argType = type(select(1,...))
  if (argType == 'table') then
    teams      = select(1,...)
    teamReadys = select(2,...)
  elseif (argType == 'string') then
    if (select(1,...) == 'NewRadius') then
      for teamID, listID in pairs(teamRangeLists) do
        gl.DeleteList(listID)
      end
      teamRangeLists = {}
    elseif (select(1,...) == 'StartGame') then
      teams      = {}
      teamReadys = {}
      widgetHandler:RemoveWidget()
    end
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Create Lists
--

local function MakeWorldRangeList(px, py, pz, radius, width)
  local rads = (2 * math.pi) / worldDivs
  local xTexStep = math.floor(4 * radius / width) / worldDivs
  gl.BeginEnd(GL.QUAD_STRIP, function()
    for i = 0, worldDivs do
      local a = rads * i
      local ix = px + (math.sin(a) * radius)
      local iz = pz + (math.cos(a) * radius)
      local iy = Spring.GetGroundHeight(ix, iz)
      local ox = px + (math.sin(a) * (radius + width))
      local oz = pz + (math.cos(a) * (radius + width))
      local oy = Spring.GetGroundHeight(ox, oz)

      local isx, isy, isz = Spring.GetGroundNormal(ix, iz)
      local osx, osy, osz = Spring.GetGroundNormal(ox, oz)
      local f = 5
      ix, iy, iz = (ix + (isx * f)), (iy + (isy * f)), (iz + (isz * f))
      ox, oy, oz = (ox + (osx * f)), (oy + (osy * f)), (oz + (osz * f))
      local dx, dy, dz = (ox - ix), (oy - iy), (oz - iz)
      local len = math.sqrt((dx * dx) + (dy * dy) + (dz * dz))
      local lf = width / len
      ox, oy, oz = (ix + (dx * lf)), (iy + (dy * lf)), (iz + (dz * lf))
--      gl.Color(1, 0, 0, 0.5)
      gl.TexCoord(i * xTexStep, 1.0)
      gl.Vertex(ix, iy, iz)
--      gl.Color(1, 0, 0, 0.0)
      gl.TexCoord(i * xTexStep, 0.125)
      gl.Vertex(ox, oy, oz)
    end
  end)
end


circleList = gl.CreateList(function()
  local rads = (2 * math.pi) / minimapDivs
  gl.BeginEnd(GL.LINE_LOOP, function()
    for i = 0, minimapDivs-1 do
      local a = rads * i
      gl.Vertex(math.sin(a), 0, math.cos(a))
    end
  end)
end)


miniMapXformList = gl.CreateList(function()
  local mapX = Game.mapX * 512
  local mapY = Game.mapY * 512
  -- this will probably be a common display
  -- list for widgets that use DrawInMiniMap()
  gl.LoadIdentity()
  gl.Translate(0, 1, 0)
  gl.Scale(1 / mapX, 1 / mapY, 1)
  gl.Rotate(90, 1, 0, 0)
end)


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  DrawMexRanges()
--

local function DrawMexRanges(teamID)
  if (Spring.GetMapDrawMode() ~= 'metal') then
    return
  end
  gl.Color(1, 0, 0, 0.5)
  gl.LineWidth(1.49)
  local units = Spring.GetTeamUnits(teamID)
  for _,unitID in ipairs(units) do
    local udid = Spring.GetUnitDefID(unitID)
    local ud = udid and UnitDefs[udid] or nil
    if (ud and (ud.extractsMetal > 0)) then
      local x, y, z = Spring.GetUnitBasePosition(unitID)
      if (x) then
        gl.DrawGroundCircle(x, y, z, ud.extractRange, 64)
      end
    end
  end
  gl.LineWidth(1)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  DrawWorld()
--

function DrawTeamWorld(team)
  if (team == nil) then
    return
  end

  local list = teamRangeLists[team.id]
  if (list == nil) then
    list = gl.CreateList(MakeWorldRangeList, team.x, 0, team.z, team.radius, 40)
    teamRangeLists[team.id] = list
  end

  local dtime = Spring.GetGameSeconds()

  gl.Texture('LuaRules/Deploy/ringTooth.png')
  gl.MatrixMode(GL.TEXTURE)
  gl.Translate(-(dtime % 1), 0, 0)
  gl.MatrixMode(GL.MODELVIEW)

  gl.LineWidth(2)
  
  gl.DepthTest(GL.GREATER)
  gl.Color(0.5, 0.5, 0.5, 0.5)
  gl.CallList(list)

  gl.DepthTest(GL.LEQUAL)
  gl.Color(team.color[1], team.color[2], team.color[3], 0.5)
  gl.CallList(list)

  gl.DepthTest(GL.LEQUAL)
  gl.DepthTest(false)

  gl.LineWidth(1)

  gl.Texture(false)
  gl.MatrixMode(GL.TEXTURE)
  gl.LoadIdentity()
  gl.MatrixMode(GL.MODELVIEW)

  DrawMexRanges(team.id)
end


function DrawWorld(team)
  for id, team in pairs(teams) do
    DrawTeamWorld(team)
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  DrawInMiniMap()
--

local bitpat = (65536 - 775)


function DrawTeamMiniMap(team)

  active = 2

  gl.LineWidth(2.49)

  gl.DepthTest(false)

  local dtime = Spring.GetGameSeconds()
  local alpha = 0.25 + 0.5 * math.abs(0.5 - ((dtime * 2) % 1))
  local shift = math.floor((dtime * 16) % 16)

  gl.PushMatrix()
  gl.CallList(miniMapXformList)

  DrawMexRanges(team.id)

  gl.LineStipple(1, bitpat, -shift)
  gl.Color(team.color[1], team.color[2], team.color[3], alpha)
  gl.Translate(team.x, team.y, team.z)
  gl.Scale(team.radius, 1, team.radius)
  gl.CallList(circleList)
  gl.LineStipple(false)

  gl.PopMatrix()

  gl.LineWidth(1.0)
end


function DrawInMiniMap()
  for id, team in pairs(teams) do
    DrawTeamMiniMap(team)
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  DrawScreen()
--

local function DrawReadyTeams()
  if (not teams) then
    return
  end

  local readys = {}
  for teamID, ready in pairs(teamReadys) do
    local id, leader, active, dead = Spring.GetTeamInfo(teamID)
    if (leader) then
      local name = Spring.GetPlayerInfo(leader)
      if (name) then
        table.insert(readys, { name, ready })
      end
    end
  end

  table.sort(readys, function(a, b)
    if (a[2] ~= b[2]) then
      return b[2]
    end
    return (a[1] > b[1])
  end)

  local fs = 12
  local fg = fs * 1.5
  local x = vsx - (fs * 0.5)

  local count = #readys
  local y = 0.5 * (vsy - (fg * count))
  for i = 1, count do
    local ready = readys[i]
    local color = ready[2] and '\255\64\255\64' or '\255\255\64\64'
    gl.Text(color .. ready[1], x, y, fs, 'or')
    y = y + fg
  end
  gl.Text('\255\255\255\1' .. 'READY', x, y, fs * 1.25, 'or')
end


local function DrawLevelBar(name, val, max, x, y,
                            width, height, color, highlight)

  active = 2

  if (invertValues) then
    val = (max - val)
  end

  local hw = math.floor(width * 0.5)
  local x0, x1 = x - hw, x + hw
  local y0, y1 = y - 1, y + height + 2

  local xm = x0 + (width * (val / max))
  gl.Color(color[1], color[2], color[3], 0.5)
  gl.Rect(x0, y0, xm, y1)
  gl.Color(0, 0, 0, 0.5)
  gl.Rect(xm, y0, x1, y1)

  val = math.floor(val)
  max = math.floor(max)
  local preStr  = val .. ':' .. name
  local postStr = name .. ':' .. max

  local g = math.floor(height / 2)
  gl.Color(1, 1, 1, 0.75)
  gl.Text(name, x, y0, height, 'ocn')

  gl.LineWidth(1)
  gl.PolygonMode(GL.FRONT_AND_BACK, GL.LINE)
  gl.Color(1, 1, 1, 0.75)
  gl.Rect(x0 - 0.5, y0 - 0.5, x1 + 0.5, y1 + 0.5)
  gl.Color(0, 0, 0, 0.75)
  gl.Rect(x0 - 1.5, y0 - 1.5, x1 + 1.5, y1 + 1.5)
  gl.PolygonMode(GL.FRONT_AND_BACK, GL.FILL)

  gl.Text(val, x0 - g, y0, height, 'or')
  gl.Text(max, x1 + g, y0, height, 'o')
end


function DrawScreen(teamID,  f, mf,  u, mu,  m, mm,  e, me)

  active = 2

  team = teams[Spring.GetMyTeamID()]
  if (team == nil) then
    return
  end

  local highlight = widgetHandler:IsMouseOwner() or
                    widget:IsAbove(Spring.GetMouseState())

  local fs = (vsy / 70)
  fs = (fs > 10) and fs or 10
  fs = math.floor(fs)
  local fg = math.floor(fs * 1.8)
  local lsx = cx
  local strwidth = fs * gl.GetTextWidth('Energy Left: ')
  local nsx = lsx + strwidth
  local y = cy
  
  local width = (fs * 1.6) * gl.GetTextWidth(featureLabel)

  if (teamID) then
    if (team.maxEnergy < 1e9) then
      DrawLevelBar('Energy', team.energy, team.maxEnergy,
                   cx, y, width, fs, { 1, 1, 0, 0.5 }, highlight)
      y = y + fg
    end
    if (team.maxMetal < 1e9) then
      DrawLevelBar('Metal', team.metal, team.maxMetal,
                   cx, y, width, fs, { 0, 1, 1, 0.5 }, highlight)
      y = y + fg
    end
    if (team.maxUnits < 1e9) then
      DrawLevelBar('Units', team.units, team.maxUnits,
                   cx, y, width, fs, { 0, 1, 0, 0.5 }, highlight)
      y = y + fg
    end
  end

  if (team.maxFrames < 1e9) then
    local gs = Game.gameSpeed
    DrawLevelBar('Time', (team.frames / gs), team.maxFrames / gs,
                 cx, y, width, fs, { 1, 0, 0, 0.5 }, highlight)
    y = y + fg
  end

  if (highlight) then
    gl.Color(1, 1, 1)
    gl.Text(featureLabel, lsx, y, fs * 1.6, 'ocn')
  else
    gl.Color(0, 0, 0)
    gl.Text(featureLabel, lsx, y, fs * 1.6, 'Ocn')
  end

  DrawReadyTeams()
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
