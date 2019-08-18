--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "AllyCursors",
    desc      = "Shows the mouse pos of allied players",
    author    = "jK",
    date      = "May,2008",
    license   = "GNU GPL, v2 or later",
    layer     = 5,
    enabled   = true
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- configs

local sendPacketEvery = 0.8
local numMousePos     = 2 --//num mouse pos in 1 packet

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- locals

local pairs = pairs

local GetMouseState   = Spring.GetMouseState
local TraceScreenRay  = Spring.TraceScreenRay
local SendLuaUIMsg    = Spring.SendLuaUIMsg
local GetGroundHeight = Spring.GetGroundHeight
local GetPlayerInfo   = Spring.GetPlayerInfo
local GetTeamColor    = Spring.GetTeamColor
local IsSphereInView  = Spring.IsSphereInView
local GetSpectatingState = Spring.GetSpectatingState

local glTexCoord      = gl.TexCoord
local glVertex        = gl.Vertex
local glPolygonOffset = gl.PolygonOffset
local glDepthTest     = gl.DepthTest
local glTexture       = gl.Texture
local glColor         = gl.Color
local glBeginEnd      = gl.BeginEnd

local floor = math.floor
local tanh  = math.tanh
local GL_QUADS = GL.QUADS

local clock = os.clock

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function CubicInterpolate2(x0,x1,mix)
  local mix2 = mix*mix;
  local mix3 = mix2*mix;

  return x0*(2*mix3-3*mix2+1) + x1*(3*mix2-2*mix3);
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

WG.alliedCursorsPos = {}

--local alliedCursorsPos = WG.alliedCursorsPos

local newPos = {}
function widget:RecvLuaMsg(msg, playerID)
  if (msg:sub(1,1)=="%")
  then
    if (playerID==Spring.GetMyPlayerID()) then return true; end
    local xz = msg:sub(3)

    local l = xz:len()*0.25
    if (l==numMousePos) then
      for i=0,numMousePos-1 do
        local x = VFS.UnpackU16(xz:sub(i*4+1,i*4+2))
        local z = VFS.UnpackU16(xz:sub(i*4+3,i*4+4))
        newPos[i*2+1]   = x
        newPos[i*2+2] = z
      end

      if (WG.alliedCursorsPos[playerID]) then
        local acp = WG.alliedCursorsPos[playerID]

        acp[(numMousePos)*2+1]   = acp[1]
        acp[(numMousePos)*2+2]   = acp[2]

        for i=0,numMousePos-1 do
          acp[i*2+1] = newPos[i*2+1]
          acp[i*2+2] = newPos[i*2+2]
        end

        acp[(numMousePos+1)*2+1] = clock()
        acp[(numMousePos+1)*2+2] = (msg:sub(2,2)=="1")
      else
        local acp = {}
        WG.alliedCursorsPos[playerID] = acp

        for i=0,numMousePos-1 do
          acp[i*2+1] = newPos[i*2+1]
          acp[i*2+2] = newPos[i*2+2]
        end

        acp[(numMousePos)*2+1]   = newPos[(numMousePos-2)*2+1]
        acp[(numMousePos)*2+2]   = newPos[(numMousePos-2)*2+2]

        acp[(numMousePos+1)*2+1] = clock()
        acp[(numMousePos+1)*2+2] = (msg:sub(2,2)=="1")
        _,_,_,acp[(numMousePos+1)*2+3] = GetPlayerInfo(playerID, false)
      end
    end
    return true
  end
end

--------------------------------------------------------------------------------

local updateTimer = 0
local poshistory = {}

local saveEach = sendPacketEvery/numMousePos

local n = 0

function widget:Update(t)
  updateTimer = updateTimer + t

  if (updateTimer%saveEach<0.2) then
    local mx,my = GetMouseState()
    local _,pos = TraceScreenRay(mx,my,true)

    if (pos~=nil) then
      poshistory[n*2]   = VFS.PackU16(floor(pos[1]))
      poshistory[n*2+1] = VFS.PackU16(floor(pos[3]))
    end

    n = n + 1
  end

  if (updateTimer>sendPacketEvery)and(n>=numMousePos) then
    updateTimer = 0
    n=0

    local posStr = "0"
    local _,_,l,m,r = Spring.GetMouseState()
    if (l or r) then posStr = "1" end
    for i=numMousePos,1,-1 do
      local xStr = poshistory[i*2]
      local zStr = poshistory[i*2+1]
      if (xStr and zStr) then posStr = posStr .. xStr .. zStr end
    end

    SendLuaUIMsg("%" .. posStr,"allies")
  end

  if (GetSpectatingState()) then
    widgetHandler:RemoveCallIn("Update")
    return
  end
end

local function DrawGroundquad(wx,gy,wz)
  -- get ground heights
  local gy_tl,gy_tr = GetGroundHeight(wx-16,wz-16),GetGroundHeight(wx+16,wz-16)
  local gy_bl,gy_br = GetGroundHeight(wx-16,wz+16),GetGroundHeight(wx+16,wz+16)
  local gy_t,gy_b = GetGroundHeight(wx,wz-16),GetGroundHeight(wx,wz+16)
  local gy_l,gy_r = GetGroundHeight(wx-16,wz),GetGroundHeight(wx+16,wz)

  --topleft
  glTexCoord(0,0)
  glVertex(wx-16,gy_bl,wz-16)
  glTexCoord(0,0.5)
  glVertex(wx-16,gy_l,wz)
  glTexCoord(0.5,0.5)
  glVertex(wx,gy,wz)
  glTexCoord(0.5,0)
  glVertex(wx,gy_t,wz-16)

  --topright
  glTexCoord(0.5,0)
  glVertex(wx,gy_t,wz-16)
  glTexCoord(0.5,0.5)
  glVertex(wx,gy,wz)
  glTexCoord(1,0.5)
  glVertex(wx+16,gy_r,wz)
  glTexCoord(1,0)
  glVertex(wx+16,gy_tr,wz-16)

  --bottomright
  glTexCoord(0.5,0.5)
  glVertex(wx,gy,wz)
  glTexCoord(0.5,1)
  glVertex(wx,gy_b,wz+16)
  glTexCoord(1,1)
  glVertex(wx+16,gy_br,wz+16)
  glTexCoord(1,0.5)
  glVertex(wx+16,gy_r,wz)

  --bottomleft
  glTexCoord(0.5,0)
  glVertex(wx-16,gy_l,wz)
  glTexCoord(1,0)
  glVertex(wx-16,gy_bl,wz+16)
  glTexCoord(1,0.5)
  glVertex(wx,gy_b,wz+16)
  glTexCoord(0.5,0.5)
  glVertex(wx,gy,wz)
end


local teamColors = {}
local function SetTeamColor(teamID,a)
  local color = teamColors[teamID]
  if (color) then
    color[4]=a
    glColor(color)
    return
  end
  local r, g, b = Spring.GetTeamColor(teamID)
  if (r and g and b) then
    color = { r, g, b }
    teamColors[teamID] = color
    glColor(color)
    return
  end
end


function widget:DrawWorldPreUnit()
  if Spring.IsGUIHidden() then return end
  glDepthTest(true)
  glTexture('LuaUI/Images/AlliedCursors.png')
  glPolygonOffset(-7,-10)
  local time = clock()

  for playerID,data in pairs(WG.alliedCursorsPos) do
    local teamID = data[#data]
    for n=0,5 do
      local wx,wz = data[1],data[2]
      local lastUpdatedDiff = time-data[#data-2] + n*0.025

      if (lastUpdatedDiff<sendPacketEvery) then
        local scale  = (1-(lastUpdatedDiff/sendPacketEvery))*numMousePos
        local iscale = math.min(floor(scale),numMousePos-1)
        local fscale = scale-iscale

        wx = CubicInterpolate2(data[iscale*2+1],data[(iscale+1)*2+1],fscale)
        wz = CubicInterpolate2(data[iscale*2+2],data[(iscale+1)*2+2],fscale)
      end

      local gy = GetGroundHeight(wx,wz)
      if (IsSphereInView(wx,gy,wz,16)) then
        local r,g,b = GetTeamColor(teamID)
        if (data[#data-1]) then --mouse pressed?
          glColor(1,0,0,n*0.2)
        else
          SetTeamColor(teamID,n*0.2)
        end
        glBeginEnd(GL_QUADS,DrawGroundquad,wx,gy,wz)
      end
    end
  end

  glPolygonOffset(false)
  glTexture(false)
  glDepthTest(false)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
