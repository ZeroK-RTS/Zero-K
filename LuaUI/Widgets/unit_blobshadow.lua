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

local onlyShowOnAirOption = true

local ResetWidget --forward-declared

local function OnOptionsChange()
  ResetWidget()
end

options_path = 'Settings/Graphics/Unit Visibility/BlobShadow'
options = {
  onlyShowOnAir = {
    name = 'Only on air',
    desc = 'Only show blob shadows for flying units.  Land units will not display blob shadows',
    type = 'bool',
    value = true,
    advanced = false,
    OnChange = OnOptionsChange,
  },
}

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
local GetUnitDefID         = Spring.GetUnitDefID
local GetGroundHeight      = Spring.GetGroundHeight
local GetCameraPosition    = Spring.GetCameraPosition
local ValidUnitID          = Spring.ValidUnitID
local GetAllUnits          = Spring.GetAllUnits

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local unitsCount = 0
local unitsList = {}


local function AddUnit(unitID,unitDefID)
  
  local udef = UnitDefs[unitDefID]
  if not onlyShowOnAirOption or (udef and udef.canFly) then
    unitsCount = unitsCount + 1
    unitsList[unitsCount] = (unitID)
  end
end

function widget:UnitEnteredAir(unitID)
  if onlyShowOnAirOption then
    unitsCount = unitsCount + 1
    unitsList[unitsCount] = (unitID)
  end
end

function widget:UnitFinished(unitID, unitDefID)
  if not onlyShowOnAirOption then
    AddUnit(unitID,unitDefID)
  end
end

function widget:UnitEnteredLos(unitID, unitDefID)
  AddUnit(unitID, unitDefID)
end

function widget:UnitLeftAir(unitID)
  if onlyShowOnAirOption then
    uid = (unitID or _unitID)
	  for i=1,unitsCount do
      if unitsList[i] == uid then
        unitsList[i] = unitsList[unitsCount]
        unitsCount = unitsCount - 1
        return
      end
	  end
  end
end


local function RemoveUnitByIndex(i)
  unitsList[i] = unitsList[unitsCount]
  unitsCount = unitsCount - 1
end

--forward-declared function
ResetWidget = function()
  onlyShowOnAirOption = options.onlyShowOnAir.value
  unitsList = {}
  unitsCount = 0
  
  local units = GetAllUnits() 
  for _, uid in ipairs(units) do
    AddUnit(uid, GetUnitDefID(uid))
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function MyDrawGroundQuad(wx,wz,quadSize,gy,gy_tl,gy_tr,gy_bl,gy_br,gy_t,gy_b,gy_l,gy_r)
  --topleft
  glTexCoord(0,0)
  glVertex(wx-quadSize,gy_bl,wz-quadSize)
  glTexCoord(0,0.5)
  glVertex(wx-quadSize,gy_l,wz)
  glTexCoord(0.5,0.5)
  glVertex(wx,gy,wz)
  glTexCoord(0.5,0)
  glVertex(wx,gy_t,wz-quadSize)

  --topright
  glTexCoord(0.5,0)
  glVertex(wx,gy_t,wz-quadSize)
  glTexCoord(0.5,0.5)
  glVertex(wx,gy,wz)
  glTexCoord(1,0.5)
  glVertex(wx+quadSize,gy_r,wz)
  glTexCoord(1,0)
  glVertex(wx+quadSize,gy_tr,wz-quadSize)

  --bottomright
  glTexCoord(0.5,0.5)
  glVertex(wx,gy,wz)
  glTexCoord(0.5,1)
  glVertex(wx,gy_b,wz+quadSize)
  glTexCoord(1,1)
  glVertex(wx+quadSize,gy_br,wz+quadSize)
  glTexCoord(1,0.5)
  glVertex(wx+quadSize,gy_r,wz)

  --bottomleft
  glTexCoord(0.5,0)
  glVertex(wx-quadSize,gy_l,wz)
  glTexCoord(1,0)
  glVertex(wx-quadSize,gy_bl,wz+quadSize)
  glTexCoord(1,0.5)
  glVertex(wx,gy_b,wz+quadSize)
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
  local unitDefID;
  local quadSize;
  
  for i=1,unitsCount do
    uid = unitsList[i]
    if ValidUnitID(uid) then
    
      -- calculate quad size
      unitDefID = GetUnitDefID(uid)
      local xsize = UnitDefs[unitDefID].xsize 
      if xsize then
        quadSize = xsize * 4
      else
        quadSize = 16
      end
      
      wx, wy, wz = GetUnitViewPosition(uid)
      --dist = (wx - cx)^2 + (wy - cy)^2 + (wz - cz)^2
      --if (dist<9000000) then
        gy = GetGroundHeight(wx, wz)
        if (IsSphereInView(wx,gy,wz,quadSize)) then

          -- get ground heights
          gy_tl,gy_tr = GetGroundHeight(wx-quadSize,wz-quadSize),GetGroundHeight(wx+quadSize,wz-quadSize)
          gy_bl,gy_br = GetGroundHeight(wx-quadSize,wz+quadSize),GetGroundHeight(wx+quadSize,wz+quadSize)
          gy_t,gy_b = GetGroundHeight(wx,wz-quadSize),GetGroundHeight(wx,wz+quadSize)
          gy_l,gy_r = GetGroundHeight(wx-quadSize,wz),GetGroundHeight(wx+quadSize,wz)

          MyDrawGroundQuad(wx,wz,quadSize,gy,gy_tl,gy_tr,gy_bl,gy_br,gy_t,gy_b,gy_l,gy_r)

        end
      --end
    else
      RemoveUnitByIndex(i)
    end
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
  ResetWidget()
end

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