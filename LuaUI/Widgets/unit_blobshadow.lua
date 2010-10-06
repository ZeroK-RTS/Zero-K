-- $Id: unit_blobshadow.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  author:  jK
--
--  Copyright (C) 2007,2009.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "BlobShadow",
    desc      = "shows an blob shadows for aircraft",
    author    = "jK",
    date      = "2007,2009",
    license   = "GNU GPL, v2 or later",
    layer     = -1000,
    enabled   = false  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local gameFrame = 0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- speed-ups

local GL_QUADS        = GL.QUADS
local glVertex        = gl.Vertex
local glTexCoord      = gl.TexCoord
local glBeginEnd      = gl.BeginEnd
local glTranslate     = gl.Translate
local glColor         = gl.Color
local glDepthTest     = gl.DepthTest
local glTexture       = gl.Texture
local glPushMatrix    = gl.PushMatrix
local glPopMatrix     = gl.PopMatrix
local glPolygonOffset = gl.PolygonOffset
local insert          = table.insert
local GetTeamList          = Spring.GetTeamList
local GetTeamUnits         = Spring.GetTeamUnits
local GetUnitViewPosition  = Spring.GetUnitViewPosition
local IsSphereInView       = Spring.IsSphereInView
local GetGameFrame         = Spring.GetGameFrame
local GetUnitDefID         = Spring.GetUnitDefID
local GetGroundHeight      = Spring.GetGroundHeight
local GetCameraPosition    = Spring.GetCameraPosition
local ValidUnitID          = Spring.ValidUnitID

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local flyingUnitsCount = 0
local flyingUnitsList = {}


local function AddFlyingUnit(_unitID,unitID)
  flyingUnitsCount = flyingUnitsCount + 1
  flyingUnitsList[flyingUnitsCount] = (unitID or _unitID)
end


local function AddFlyingUnitCheck(_,unitID,unitDefID)
  local udef = UnitDefs[unitDefID]
  if (udef and udef.canFly) then
    flyingUnitsCount = flyingUnitsCount + 1
    flyingUnitsList[flyingUnitsCount] = (unitID or _unitID)
  end
end


local function RemoveFlyingUnit(_unitID,unitID)
  local uid = (unitID or _unitID)
  for i=1,flyingUnitsCount do
    if (flyingUnitsList[i] == uid) then
      flyingUnitsList[i] = flyingUnitsList[flyingUnitsCount]
      flyingUnitsCount = flyingUnitsCount - 1
      return
    end
  end
end


local function RemoveFlyingUnitByIndex(i)
  flyingUnitsList[i] = flyingUnitsList[flyingUnitsCount]
  flyingUnitsCount = flyingUnitsCount - 1
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local function MyDrawGroundQuad(wx,wz,gy,gy_tl,gy_tr,gy_bl,gy_br,gy_t,gy_b,gy_l,gy_r)
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

local function DrawShadows()
  -- object position
  local wx, wy, wz,  dist;
  --local cx, cy, cz = GetCameraPosition()

  -- ground heights
  local gy;
  local gy_tl,gy_tr;
  local gy_bl,gy_br;
  local gy_t,gy_b;
  local gy_l,gy_r;

  local uid;
  for i=1,flyingUnitsCount do
    uid = flyingUnitsList[i]
    if ValidUnitID(uid) then
      wx, wy, wz = GetUnitViewPosition(uid)
      --dist = (wx - cx)^2 + (wy - cy)^2 + (wz - cz)^2
      --if (dist<9000000) then
        gy = GetGroundHeight(wx, wz)
        if (IsSphereInView(wx,gy,wz,16)) then

          -- get ground heights
          gy_tl,gy_tr = GetGroundHeight(wx-16,wz-16),GetGroundHeight(wx+16,wz-16)
          gy_bl,gy_br = GetGroundHeight(wx-16,wz+16),GetGroundHeight(wx+16,wz+16)
          gy_t,gy_b = GetGroundHeight(wx,wz-16),GetGroundHeight(wx,wz+16)
          gy_l,gy_r = GetGroundHeight(wx-16,wz),GetGroundHeight(wx+16,wz)

          MyDrawGroundQuad(wx,wz,gy,gy_tl,gy_tr,gy_bl,gy_br,gy_t,gy_b,gy_l,gy_r)

        end
      --end
    else
      RemoveFlyingUnitByIndex(i)
    end
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

widget.UnitEnteredAir = AddFlyingUnit
widget.UnitLeftAir = RemoveFlyingUnit
widget.UnitEnteredLos = AddFlyingUnitCheck

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:DrawWorld()
  glColor(1,1,1,0.4)
  glDepthTest(true)
  glTexture('LuaUI/Images/blob.png')
  glPolygonOffset(-7,-10)

  glBeginEnd(GL_QUADS,DrawShadows)

  glPolygonOffset(false)
  glTexture(false)
  glDepthTest(false)
  glColor(1,1,1,1)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------