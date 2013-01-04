
function widget:GetInfo()
  return {
    name      = "Decoration Handler",
    desc      = "Handles decoration drawing.",
    author    = "Google Frog (Evil4Zerggin and CarRepairer from Commander Nametags)",
    date      = "Jan 3, 2013",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true --  loaded by default?
  }
end

local spGetAllUnits = Spring.GetAllUnits
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitTeam = Spring.GetUnitTeam
local spGetUnitPieceMap = Spring.GetUnitPieceMap

local glColor             = gl.Color
local glPushMatrix        = gl.PushMatrix
local glPopMatrix         = gl.PopMatrix
local glTranslate         = gl.Translate

local glDepthTest      = gl.DepthTest
local glAlphaTest      = gl.AlphaTest
local glTexture        = gl.Texture
local glTexRect        = gl.TexRect
local glRotate         = gl.Rotate
local GL_GREATER       = GL.GREATER
local glUnitMultMatrix = gl.UnitMultMatrix
local glUnitPieceMultMatrix = gl.UnitPieceMultMatrix
local glScale          = gl.Scale

local commtypeTable = include("Configs/decoration_handler_defs.lua")
local textures = {} 
local unitAlreadyAdded = {}

local imagePath = 'LuaUI/Configs/Decorations/'
local imageFormat = '.png'

-------------------
-- Unit Handling

local function AddUnitTexture(unitID, attributes, tex)
	if (not VFS.FileExists(tex)) then
		return
	end
	
	local pieceMap = spGetUnitPieceMap(unitID)
	if not textures[tex] then
		textures[tex] = {units = {}, count = 0}
	end
	if not textures[tex].units[unitID] then
		textures[tex].count = textures[tex].count + 1
	end
	if not textures[tex].units[unitID] then
		textures[tex].units[unitID] = {data = {}, count = 0}
	end
	textures[tex].units[unitID].count = textures[tex].units[unitID].count + 1
	textures[tex].units[unitID].data[textures[tex].units[unitID].count] = {
		piece = pieceMap[attributes.piece],
		width = attributes.width,
		height = attributes.height,
		rotation = attributes.rotation,
		rotVector = attributes.rotVector,

		offset = attributes.offset,
		alpha = attributes.alpha,
	}
end

local function RemoveUnit(unitID, attributes, tex)
	textures[tex].units[unitID] = nil
	textures[tex].count = textures[tex].count - 1
	if textures[tex].count == 0 then
		textures[tex] = nil
	end
end

local function SetupPossibleCommander(unitID,  unitDefID)
	if unitDefID and not unitAlreadyAdded[unitID] then
		unitAlreadyAdded[unitID] = true
		local ud = UnitDefs[unitDefID]
		if ud.customParams and ud.customParams.commtype and ud.customParams.level then
			local commtype = ud.customParams.commtype
			local level = ud.customParams.level
			if commtypeTable[commtype] and commtypeTable[commtype][level] then
				local points = commtypeTable[commtype][level]
				for i = 1, #points do
					if ud.customParams["decoration_" .. i] then
						local image = imagePath .. ud.customParams["decoration_" .. i] .. imageFormat
						AddUnitTexture(unitID, points[i],  image)
					end
				end
			end
		end
	end
end

local function RemovePossibleCommander(unitID,  unitDefID)
	if unitDefID then
		unitAlreadyAdded[unitID] = nil
		local ud = UnitDefs[unitDefID]
		if ud.customParams and ud.customParams.commtype and ud.customParams.level then
			local commtype = ud.customParams.commtype
			local level = ud.customParams.level
			if commtypeTable[commtype] and commtypeTable[commtype][level] then
				local points = commtypeTable[commtype][level]
				for i = 1, #points do
					if ud.customParams["decoration_" .. i] then
						local image = imagePath .. ud.customParams["decoration_" .. i] .. imageFormat
						RemoveUnit(unitID, points[i],  image)
					end
				end
			end
		end
	end
end

function widget:UnitEnteredLos(unitID, unitTeam)
	local unitDefID = spGetUnitDefID(unitID)
	SetupPossibleCommander(unitID,  unitDefID)
end

function widget:UnitCreated( unitID,  unitDefID,  unitTeam)
	SetupPossibleCommander(unitID,  unitDefID)
end

function widget:UnitDestroyed( unitID,  unitDefID,  unitTeam)
	RemovePossibleCommander(unitID,  unitDefID)
end

function widget:Initialize()
	local allUnits = spGetAllUnits()
	for i = 1, #allUnits do
		local unitID = allUnits[i]
		local unitDefID = spGetUnitDefID(unitID)
		local teamID = spGetUnitTeam(unitID)
		widget:UnitCreated(unitID, unitDefID, teamID)
	end
end

-------------------
-- Drawing

function widget:DrawWorld()
	glDepthTest(true)
	glAlphaTest(GL_GREATER, 0)
	
	for textureName, texData in pairs(textures) do
		glTexture(textureName)
		for unitID, unitData in pairs(texData.units) do
			local unit = texData.units
			for i = 1, unitData.count do
				local attributes = unitData.data[i]
				glPushMatrix()
				glUnitMultMatrix(unitID)
				glUnitPieceMultMatrix(unitID, attributes.piece)
				glTranslate(attributes.offset[1],attributes.offset[2],attributes.offset[3])
				glRotate(attributes.rotation,attributes.rotVector[1],attributes.rotVector[2],attributes.rotVector[3])
				glColor(1,1,1,attributes.alpha)
				glTexRect(-attributes.width, -attributes.height, attributes.width, attributes.height)
				glPopMatrix()
			end
		end
	end
	
	glAlphaTest(false)
	glColor(1,1,1,1)
	glTexture(false)
	glDepthTest(false)
end