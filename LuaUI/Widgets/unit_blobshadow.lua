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
    desc      = "shows blob shadows",
    author    = "jK",
    date      = "2007,2009",
    license   = "GNU GPL, v2 or later",
    layer     = -1000,
    enabled   = false  --  loaded by default?
  }
end

local onlyShowOnAirOption = true

local ResetWidget --forward-declared

local BLOB_TEXTURE = 'LuaUI/Images/blob2.dds' -- 'LuaUI/Images/blob.png' vr_grid.png
local SIZE_MULT = 1.3

local function OnOptionsChange()
	ResetWidget()
end

options_path = 'Settings/Graphics/Unit Visibility/BlobShadow'
options = {
  --onlyShowOnAir = {
  --  name = 'Only on air',
  --  desc = 'Only show blob shadows for flying units.  Land units will not display blob shadows',
  --  type = 'bool',
  --  value = true,
  --  advanced = false,
  --  OnChange = OnOptionsChange,
  --},
}

local shadowUnitDefID = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if (not ud.isImmobile) and ud.isGroundUnit then
		shadowUnitDefID[i] = true
	end
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
local spGetUnitViewPosition  = Spring.GetUnitViewPosition
local spIsSphereInView       = Spring.IsSphereInView
local spGetUnitDefID         = Spring.GetUnitDefID
local spGetGroundHeight      = Spring.GetGroundHeight
local spGetCameraPosition    = Spring.GetCameraPosition
local spValidUnitID          = Spring.ValidUnitID
local spGetAllUnits          = Spring.GetAllUnits

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local unitsCount = 0
local unitsList = {}
local unitMap = {}

local function AddUnit(unitID, unitDefID)
	unitDefID = unitDefID or spGetUnitDefID(unitID)
	if (not shadowUnitDefID[unitDefID]) or unitMap[unitID] then
		return
	end
	unitsCount = unitsCount + 1
	unitsList[unitsCount] = unitID
	unitMap[unitID] = unitsCount
end

local function RemoveUnit(unitID)
	if not unitMap[unitID] then
		return
	end
	
	local index = unitMap[unitID]
	unitsList[index] = unitsList[unitsCount]
	unitMap[unitsList[index]] = index
	
	unitMap[unitID] = nil
	unitsList[unitsCount] = nil
	unitsCount = unitsCount - 1
end

function widget:UnitEnteredAir(unitID)
	RemoveUnit(unitID)
end

function widget:UnitFinished(unitID, unitDefID)
	AddUnit(unitID, unitDefID)
end

function widget:UnitEnteredLos(unitID, unitDefID)
	AddUnit(unitID, unitDefID)
end

function widget:UnitLeftAir(unitID)
	AddUnit(unitID)
end


local function RemoveUnitByIndex(i)
  unitsList[i] = unitsList[unitsCount]
  unitsCount = unitsCount - 1
end

--forward-declared function
ResetWidget = function()
	unitsList = {}
	unitsCount = 0
	unitMap = {}

	local units = spGetAllUnits()
	for _, unitID in ipairs(units) do
		AddUnit(unitID)
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
	local wx, wy, wz,  dist

	-- ground heights
	local gy
	local gy_tl,gy_tr
	local gy_bl,gy_br
	local gy_t,gy_b
	local gy_l,gy_r

	local unitID
	local unitDefID
	local quadSize

	for i=1,unitsCount do
		unitID = unitsList[i]
		if spValidUnitID(unitID) then

			-- calculate quad size
			unitDefID = spGetUnitDefID(unitID)
			local xsize = UnitDefs[unitDefID].xsize
			if xsize then
				quadSize = xsize * 4
			else
				quadSize = 16
			end
			quadSize = quadSize * SIZE_MULT

			wx, wy, wz = spGetUnitViewPosition(unitID)
			if wx and wy and wz then
				gy = spGetGroundHeight(wx, wz)
				if (spIsSphereInView(wx,gy,wz,quadSize)) then

					-- get ground heights
					gy_tl,gy_tr = spGetGroundHeight(wx-quadSize,wz-quadSize),spGetGroundHeight(wx+quadSize,wz-quadSize)
					gy_bl,gy_br = spGetGroundHeight(wx-quadSize,wz+quadSize),spGetGroundHeight(wx+quadSize,wz+quadSize)
					gy_t,gy_b = spGetGroundHeight(wx,wz-quadSize),spGetGroundHeight(wx,wz+quadSize)
					gy_l,gy_r = spGetGroundHeight(wx-quadSize,wz),spGetGroundHeight(wx+quadSize,wz)

					MyDrawGroundQuad(wx,wz,quadSize,gy,gy_tl,gy_tr,gy_bl,gy_br,gy_t,gy_b,gy_l,gy_r)
				end
			end
			--end
		else
			RemoveUnit(unitID)
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
	glTexture(BLOB_TEXTURE)
	glPolygonOffset(0,-10)

	glBeginEnd(GL_QUADS, DrawShadows)

	glPolygonOffset(false)
	glTexture(false)
	glDepthTest(false)
	glColor(1,1,1,1)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
