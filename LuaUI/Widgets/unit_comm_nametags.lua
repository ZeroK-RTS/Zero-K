-- $Id: unit_comm_nametags.lua 3240 2008-11-17 10:48:13Z carrepairer $
local versionNumber = "1.72"

function widget:GetInfo()
  return {
    name      = "Commander Name Tags ",
    desc      = versionNumber .." Displays a name tag above each commander.",
    author    = "Evil4Zerggin and CarRepairer",
    date      = "18 April 2008",
    license   = "GNU GPL, v2 or later",
    layer     = -9,
    enabled   = false  --  loaded by default?
  }
end

--[[
Changelog: 
1.2   CarRepairer: Added an actual HelloMyNameIs nametag that is pinned to the Commander's chest!!!

1.7   CarRepairer: Using Fonthandler, nametag text now works properly. Added speedups.
1.71   CarRepairer: Forgot to remove old text.

--]]


--------------------------------------------------------------------------------
-- config
--------------------------------------------------------------------------------

local showStickyTags --comms literally wear name tags
local heightOffset = 24
local xOffset = 0
local yOffset = 0
local fontSize = 6

options_path = 'Settings/Interface/Commander Nametags'
options_order = {"stickyTags"}
options = {
	stickyTags = {
		name = "Show Sticky Tags",
		type = 'bool',
		value = true,
		desc = 'Commanders literally wear name tags',
		OnChange = function(self)
			showStickyTags = self.value
		end,
	},
}

showStickyTags = options.stickyTags.value

--------------------------------------------------------------------------------
-- speed-ups
--------------------------------------------------------------------------------

local GetUnitTeam         = Spring.GetUnitTeam
local GetTeamInfo         = Spring.GetTeamInfo
local GetPlayerInfo       = Spring.GetPlayerInfo
local GetTeamColor        = Spring.GetTeamColor
local GetUnitViewPosition = Spring.GetUnitViewPosition
local GetVisibleUnits     = Spring.GetVisibleUnits
local GetUnitDefID        = Spring.GetUnitDefID
local GetAllUnits         = Spring.GetAllUnits
local GetUnitHeading      = Spring.GetUnitHeading
local IsUnitIcon 		  = Spring.IsUnitIcon 

local iconsize   = 10
local iconhsize  = iconsize * 0.5


local glColor             = gl.Color
--local glText              = gl.Text
local glPushMatrix        = gl.PushMatrix
local glPopMatrix         = gl.PopMatrix
local glTranslate         = gl.Translate
local glBillboard         = gl.Billboard
local glDrawFuncAtUnit    = gl.DrawFuncAtUnit

local glDepthTest      = gl.DepthTest
local glAlphaTest      = gl.AlphaTest
local glTexture        = gl.Texture
local glTexRect        = gl.TexRect
local glRotate         = gl.Rotate
local GL_GREATER       = GL.GREATER
local glUnitMultMatrix = gl.UnitMultMatrix
local glUnitPieceMultMatrix = gl.UnitPieceMultMatrix
local glScale          = gl.Scale


local overheadFont	= "LuaUI/Fonts/FreeSansBold_16"
local stickyFont	= "LuaUI/Fonts/Skrawl_40"
--local stickyFont	= "LuaUI/Fonts/KOMTXT___5"
local fhDraw		= fontHandler.Draw
--------------------------------------------------------------------------------
-- local variables
--------------------------------------------------------------------------------

--key: unitID
--value: attributes = {name, color, height, currentAttributes, torsoPieceID}
--currentAttributes = {name, color, height}
local comms = {}

--------------------------------------------------------------------------------
-- helper functions
--------------------------------------------------------------------------------

--gets the name, color, and height of the commander
local function GetCommAttributes(unitID, unitDefID)
  local team = GetUnitTeam(unitID)
  local _, player = GetTeamInfo(team, false)
  local name = GetPlayerInfo(player, false) or 'Robert Paulson'
  local r, g, b, a = GetTeamColor(team)
  local height = Spring.Utilities.GetUnitHeight(UnitDefs[unitDefID]) + heightOffset
  local pm = spGetUnitPieceMap(unitID)
  local pmt = pm["torso"]
  if (pmt == nil) then 
    pmt = pm["chest"]
  end    
  return {name, {r, g, b, a}, height, pmt }
end

local function DrawCommName(unitID, attributes)
  glTranslate(0, attributes[3], 0 )
  glBillboard()
  
  glColor(attributes[2])
  --glText(attributes[1], xOffset, yOffset, fontSize, "cn")
  fontHandler.UseFont(overheadFont)
  fontHandler.DrawCentered(attributes[1], xOffset,yOffset)
  glColor(1,1,1,1)
end

local function DrawNameTag(rotation)
  glRotate(rotation,0,1,0)
  glTranslate(8, 35, 7)
  
  glColor(1,1,1,1)
  glTexRect(-iconhsize, 0, iconhsize, iconsize)
end

local function DrawCommName2(unitID, attributes, rotation)
  glRotate(rotation,0,1,0)
  glTranslate(8, 40, 7)

  glColor(attributes[2])
  --glText(attributes[1], xOffset, yOffset, 1, "cn")

  glColor(1,1,1,1)
end

--------------------------------------------------------------------------------
-- callins
--------------------------------------------------------------------------------

function widget:Initialize()
  local allUnits = GetAllUnits()
  for _, unitID in pairs(allUnits) do
    local unitDefID = GetUnitDefID(unitID)
    if (unitDefID and UnitDefs[unitDefID].customParams.level) then
      comms[unitID] = GetCommAttributes(unitID, unitDefID)
    end
  end
end


function spGetUnitPieceMap(unitID,piecename)
  local pieceMap = {}
  for piecenum,piecename in pairs(Spring.GetUnitPieceList(unitID)) do
    pieceMap[piecename] = piecenum
  end
  return pieceMap
end

local function DrawWorldFunc()
		if not Spring.IsGUIHidden() then
		glDepthTest(true)
		glTexture('LuaUI/Images/hellomynameis.png')
		glAlphaTest(GL_GREATER, 0)
		if (showStickyTags) then
			--draw HelloMyName icon is on chest
			for unitID, attributes in pairs(comms) do
				if (attributes[4]) and (not IsUnitIcon(unitID)) then 
					glPushMatrix()
					glUnitMultMatrix(unitID)
					glUnitPieceMultMatrix(unitID, attributes[4])
					glRotate(0,0,1,0)
					glTranslate(8, 0, 7)
					glColor(1,1,1,1)
					glTexRect(-iconhsize, 0, iconhsize, iconsize)
					glPopMatrix()
				end
			end
			 --draw player name on HelloMyName icon
			for unitID, attributes in pairs(comms) do
				if (attributes[4]) and (not IsUnitIcon(unitID)) then
					glPushMatrix()
					glUnitMultMatrix(unitID)
					glUnitPieceMultMatrix(unitID, attributes[4])
					glRotate(0,0,1,0)
					glTranslate(8, 0, 7)
					glColor(attributes[2])
					
					glPushMatrix()
					glScale(0.03, 0.03, 0.03)
					glTranslate (0,120,5)
					fontHandler.UseFont(stickyFont)
					fontHandler.DrawCentered(attributes[1], 0,0)
					glPopMatrix()
					
					glPopMatrix()
				end
			end
		end
	--draw hovering text that mention player's name.
	for unitID, attributes in pairs(comms) do
		local heading = GetUnitHeading(unitID)
		if (not heading) then
			return
		end
		local rot = (heading / 32768) * 180
		glDrawFuncAtUnit(unitID, false, DrawCommName, unitID, attributes)
		if (showStickyTags) then
			glDrawFuncAtUnit(unitID, false, DrawCommName2, unitID, attributes, rot)
		end
	end
	

	glAlphaTest(false)
	glColor(1,1,1,1)
	glTexture(false)
	glDepthTest(false)
	end
end

function widget:DrawWorld()
	DrawWorldFunc()
end

function widget:DrawWorldRefraction()
	DrawWorldFunc()
end

function widget:UnitCreated( unitID,  unitDefID,  unitTeam)
  if (unitDefID and UnitDefs[unitDefID] and UnitDefs[unitDefID].customParams.level) then
    comms[unitID] = GetCommAttributes(unitID, unitDefID)
  end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
  comms[unitID] = nil
end

function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
  widget:UnitCreated( unitID,  unitDefID,  unitTeam)
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
  widget:UnitCreated( unitID,  unitDefID,  unitTeam)
end

function widget:UnitEnteredLos(unitID, unitTeam)
  local unitDefID = Spring.GetUnitDefID(unitID)
  widget:UnitCreated( unitID,  unitDefID,  unitTeam)
end
