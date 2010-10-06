-- $Id: draw.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    LuaRules/Deploy/draw.lua
--  brief:   deployment game mode
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

VFS.Include('LuaRules/colors.h.lua')


featureLabel = 'Deployment' -- FIXME
if (string.find(string.lower(Game.modName), 'tactics')) then
  featureLabel = 'Tactics'
end

local useLuaUI = false

local teamRangeLists = {}
local circleList = 0
local miniMapXformList = 0

local worldDivs   = 1024
local minimapDivs = 256

local toothTex = 'LuaRules/Deploy/ringTooth.png'


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Select and View
--

local function SelectViewComm()
  local teamID = Spring.GetLocalTeamID()
  local team = SYNCED.teams and SYNCED.teams[teamID] or nil
  if (not team) then
    return
  end

  Spring.SelectUnitArray({ team.comm })
  Spring.SetCameraTarget(team.x, team.y, team.z, 0.75)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Update()
--

local function LuaUITeamTable(team)
  return {
    id = team.id,

    ready = team.ready,
    
    x = team.x,
    y = team.y,
    z = team.z,
    radius = SYNCED.maxRadius,
    color  = { Spring.GetTeamColor(team.id) },

    frames = SYNCED.frames,
    units  = #team.units,
    metal  = team.metal,
    energy = team.energy,

    maxFrames = SYNCED.maxFrames,
    maxUnits  = SYNCED.maxUnits,
    maxMetal  = SYNCED.maxMetal,
    maxEnergy = SYNCED.maxEnergy,
  }
end


function Update()
  local teamID = Spring.GetLocalTeamID()

  local teams = SYNCED.teams
  if (not teams) then return end
  local team = teams and teams[teamID] or nil
  if (not team)  then return end

  local spec, fullview = Spring.GetSpectatingState()

  if (not Script.LuaUI('DeployUpdate')) then
    useLuaUI = false
  else
    useLuaUI = true
    local uiTable = {}
    local readys = {}
    for id, team in spairs(teams) do
      if (team) then
        readys[team.id] = team.ready
        if (fullview or Spring.AreTeamsAllied(teamID, team.id)) then
          uiTable[team.id] = LuaUITeamTable(team)
        end
      end
    end
    Script.LuaUI.DeployUpdate(uiTable, readys)
  end

  local units = Spring.GetSelectedUnits()
  if (not fullview) then
    if (#units <= 0) then
      SelectViewComm()
    end
  else  
    if (#units <= 0) then
      SelectViewComm()
    end
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  RecvFromSynced()
--

function RecvFromSynced(...)
  if (select(1,...) == 'NewRadius') then
    for teamID,listID in pairs(teamRangeLists) do
      gl.DeleteList(listID)
      teamRangeLists[teamID] = nil
    end
  elseif (select(1,...) == 'StartGame') then
    SelectViewComm()

    gl.DeleteTexture(toothTex)
    gl.DeleteList(circleList)
    gl.DeleteList(miniMapXformList)
    for _,listID in pairs(teamRangeLists) do
      gl.DeleteList(listID)
    end

    Update         = nil; Script.UpdateCallIn('Update')
    DrawWorld      = nil; Script.UpdateCallIn('DrawWorld')
    DrawScreen     = nil; Script.UpdateCallIn('DrawScreen')
    DrawInMiniMap  = nil; Script.UpdateCallIn('DrawInMiniMap')
    RecvFromSynced = nil; Script.UpdateCallIn('RecvFromSynced')

    VFS.Include('LuaRules/gadgets.lua')
  elseif (select(1,...) == 'urun') then
    local chunk, err = loadstring(select(2,...), 'urun', _G)
    if (chunk) then
      chunk()
    end
    return
  elseif (select(1,...) == 'uecho') then
    local chunk, err = loadstring('return ' .. select(2,...), 'uecho', _G)
    if (chunk) then
      Spring.Echo(chunk())
    end
    return
  end

  if (Script.LuaUI('DeployUpdate')) then
    Script.LuaUI.DeployUpdate(...)
  end
end

do
  if (Script.LuaUI('DeployUpdate')) then
    Script.LuaUI.DeployUpdate('NewRadius')
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Create Lists
--

local function MakeWorldRangeListXXX(px, py, pz, radius, width)
  local rads = (2 * math.pi) / worldDivs

  local points  = {}
  local lengths = {}
  local normals = {}
  for i = 0, worldDivs do
    local a = rads * i
    local x = px + (math.sin(a) * radius)
    local z = pz + (math.cos(a) * radius)
    local y = Spring.GetGroundHeight(x, z)
    points[i] = { x = x, y = y, z = z }
    local nx, ny, nz = Spring.GetGroundNormal(x, z)
    normals[i] = { x = nx, y = ny, z = nz }
    if (i > 0) then
      local dx = points[i].x - points[i - 1].x
      local dy = points[i].y - points[i - 1].y
      local dz = points[i].z - points[i - 1].z
      lengths[i] = math.sqrt((dx * dx) + (dy * dy) + (dz * dz))
    end
  end

--  local xTexStep = math.floor(4 * radius / width) / worldDivs
--[[
  gl.BeginEnd(GL.QUAD_STRIP, function()
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
--]]
end


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
      oy = Spring.GetGroundHeight(ox, oz)
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
  gl.LineWidth(1.0)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  DrawWorld()
--

local function DrawTeamWorld(team)
  if (useLuaUI) then
    return
  end

  local list = teamRangeLists[team.id]
  if (list == nil) then
    local radius = SYNCED.maxRadius
    list = gl.CreateList(MakeWorldRangeList, team.x, 0, team.z, radius, 40)
    teamRangeLists[team.id] = list
  end

  local dtime = Spring.GetGameSeconds()
  local alpha = 0.25 + 0.5 * math.abs(0.5 - ((dtime * 2) % 1))

  gl.Texture(toothTex)
  gl.MatrixMode(GL.TEXTURE)
  gl.Translate(-(dtime % 1), 0, 0)
  gl.MatrixMode(GL.MODELVIEW)

  gl.LineWidth(2)
  
  gl.DepthTest(GL.GREATER)
  gl.Color(0.5, 0.5, 0.5, 0.5)
  gl.CallList(list)

  gl.DepthTest(GL.LEQUAL)
  local r, g, b = Spring.GetTeamColor(team.id)
  gl.Color(r, g, b, 0.5)--alpha)
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


function DrawWorld()
  if (useLuaUI) then
    return
  end

  local teams = SYNCED.teams

  local spec, fullview = Spring.GetSpectatingState()
  if (not fullview) then
    local teamID = Spring.GetLocalTeamID()
    local team = teamID and teams and teams[teamID] or nil
    if (team) then
      DrawTeamWorld(team)
    end
  else
    for teamID, team in spairs(teams) do
      if (team) then
        DrawTeamWorld(team)
      end
    end
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  DrawInMiniMap()
--

local bitpat = (65536 - 775)


local function DrawTeamMiniMap(team)
  local radius = SYNCED.maxRadius

  gl.LineWidth(2.49)

  gl.DepthTest(false)

  local dtime = Spring.GetGameSeconds()
  local alpha = 0.25 + 0.5 * math.abs(0.5 - ((dtime * 2) % 1))
  local shift = math.floor((dtime * 16) % 16)

  gl.PushMatrix()
  gl.CallList(miniMapXformList)

  DrawMexRanges(team.id)

  gl.LineStipple(1, bitpat, -shift)
  local r, g, b = Spring.GetTeamColor(team.id)
  gl.Color(r, g, b, alpha)
  gl.Translate(team.x, team.y, team.z)
  gl.Scale(radius, 1, radius)
  gl.CallList(circleList)
  gl.LineStipple(false)

  gl.PopMatrix()

  gl.LineWidth(1)
end


function DrawInMiniMap(mmsx, mmsy)
  if (useLuaUI) then
    return
  end

  local teams = SYNCED.teams

  local spec, fullview = Spring.GetSpectatingState()
  if (not fullview) then
    local teamID = Spring.GetLocalTeamID()
    local team = teamID and teams and teams[teamID] or nil
    if (team) then
      DrawTeamMiniMap(team)
    end
  else
    for teamID, team in spairs(teams) do
      if (team) then
        DrawTeamMiniMap(team)
      end
    end
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  DrawScreen()
--

local function DrawReadyTeams(vsx, vsy)
  local teams = SYNCED.teams
  if (not teams) then
    return
  end

  local readys = {}
  for teamID, team in spairs(teams) do
    local id, leader, active, dead = Spring.GetTeamInfo(teamID)
    if (leader) then
      local name = Spring.GetPlayerInfo(leader)
      if (name) then
        table.insert(readys, { name, team.ready })
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


local function DrawLevelBar(name, val, max, x, y, width, height, color)
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


function DrawScreen(vsx, vsy)
  if (useLuaUI) then
    return
  end

  local teamID = Spring.GetLocalTeamID()
  local team = teamID and SYNCED.teams and SYNCED.teams[teamID] or nil
  if (team == nil) then
    return
  end

  local cx, cy = vsx * 0.5, 111 --vsy * 0.125

  local fs = (vsy / 70)
  fs = (fs > 10) and fs or 10
  fs = math.floor(fs)
  local fg = math.floor(fs * 1.8)
  local lsx = cx
  local strwidth = fs * gl.GetTextWidth('Energy Left: ')
  local nsx = lsx + strwidth
  local y = cy
  
  local width = (fs * 1.6) * gl.GetTextWidth(featureLabel)

  if (team) then
    local maxEnergy = SYNCED.maxEnergy
    if (maxEnergy < 1e9) then
      DrawLevelBar('Energy', team.energy, maxEnergy,
                   cx, y, width, fs, { 1, 1, 0, 0.5 })
      y = y + fg
    end
    local maxMetal = SYNCED.maxMetal
    if (maxMetal < 1e9) then
      DrawLevelBar('Metal', team.metal, maxMetal,
                   cx, y, width, fs, { 0, 1, 1, 0.5 })
      y = y + fg
    end
    local maxUnits = SYNCED.maxUnits
    if (maxUnits < 1e9) then
      DrawLevelBar('Units', #team.units, maxUnits,
                   cx, y, width, fs, { 0, 1, 0, 0.5 })
      y = y + fg
    end
  end

  local maxFrames = SYNCED.maxFrames
  if (maxFrames < 1e9) then
    local gs = Game.gameSpeed
    DrawLevelBar('Time', (SYNCED.frames / gs), maxFrames / gs,
                 cx, y, width, fs, { 1, 0, 0, 0.5 })
    y = y + fg
  end

  gl.Color(0, 0, 0)
  gl.Text(featureLabel, lsx, y, fs * 1.6, 'Ocn')

  DrawReadyTeams(vsx, vsy)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
