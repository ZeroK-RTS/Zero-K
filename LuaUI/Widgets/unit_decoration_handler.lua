
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

local imagePaths = {	-- tested in order
  'LuaUI/Configs/Decorations/',
  'LuaUI/Configs/Avatars/',
  'LuaUI/Configs/Factions/',
  'LuaUI/Configs/Clans/',
}
local imageFormat = '.png'

local function GetImageDir(imageName)
  for i=1,#imagePaths do
    local dir = imagePaths[i] .. imageName .. imageFormat
    if VFS.FileExists(dir) then
      return dir
    end
  end
end

-------------------
-- Unit Handling

local function AddUnitTexture(unitID, attributes, tex)
	if not (tex and VFS.FileExists(tex)) then
		return
	end

	local pieceMap = spGetUnitPieceMap(unitID)
	if not textures[tex] then
		textures[tex] = {units = {}, count = 0}
	end
	if not textures[tex].units[unitID] then
		textures[tex].count = textures[tex].count + 1
		textures[tex].units[unitID] = {data = {}, count = 0}
	end
		
	for i = 1,#attributes do
		textures[tex].units[unitID].count = textures[tex].units[unitID].count + 1
		textures[tex].units[unitID].data[textures[tex].units[unitID].count] = {
			piece = pieceMap[attributes[i].piece],
			width = attributes[i].width,
			height = attributes[i].height,
			rotation = attributes[i].rotation,
			rotVector = attributes[i].rotVector,
	
			offset = attributes[i].offset,
			alpha = attributes[i].alpha,
		}
	end
end

local function RemoveUnit(unitID, tex)
	textures[tex].units[unitID] = nil
	textures[tex].count = textures[tex].count - 1
	if textures[tex].count == 0 then
		textures[tex] = nil
	end
end

local function SetupPossibleCommander(unitID,  unitDefID, teamID)
	if unitDefID and not unitAlreadyAdded[unitID] then
		unitAlreadyAdded[unitID] = true
		local ud = UnitDefs[unitDefID]
		if (ud.customParams and ud.customParams.commtype and ud.customParams.level) or Spring.GetUnitRulesParam(unitID, "comm_level") then
			local commtype = Spring.GetUnitRulesParam(unitID, "comm_chassis") or ud.customParams.commtype
			local level = Spring.GetUnitRulesParam(unitID, "comm_level") or ud.customParams.level
			if commtypeTable[commtype] and commtypeTable[commtype][level] then
				local points = commtypeTable[commtype][level]
				if Spring.GetUnitRulesParam(unitID, "comm_level") then
					for pointName, data in pairs(points) do
						local imageName = Spring.GetUnitRulesParam(unitID, "comm_banner_" .. pointName)
						if imageName then
							local image = GetImageDir(imageName)
							AddUnitTexture(unitID, data,  image)
						end
					end
				else
					local decIconFunc, err = loadstring("return" .. (ud.customParams.decorationicons or ""))
					local decIcons = decIconFunc() or {}
					for pointName, data in pairs(points) do
						local imageName = decIcons[pointName]
						if imageName then
							local image = GetImageDir(imageName)
							AddUnitTexture(unitID, data,  image)
						end
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
		if (ud.customParams and ud.customParams.commtype and ud.customParams.level) or Spring.GetUnitRulesParam(unitID, "comm_level") then
			local commtype = Spring.GetUnitRulesParam(unitID, "comm_chassis") or ud.customParams.commtype
			local level = Spring.GetUnitRulesParam(unitID, "comm_level") or ud.customParams.level
			if commtypeTable[commtype] and commtypeTable[commtype][level] then
				local points = commtypeTable[commtype][level]
				if Spring.GetUnitRulesParam(unitID, "comm_level") then
					for pointName, data in pairs(points) do
						local imageName = Spring.GetUnitRulesParam(unitID, "comm_banner_" .. pointName)
						if imageName then
							local image = GetImageDir(imageName)
							AddUnitTexture(unitID, data,  image)
						end
					end
				else
					for pointName, data in pairs(points) do
						local imageName = (ud.customParams.decorationicons or {}).pointName
						if imageName then
							local image = GetImageDir(imageName)
							AddUnitTexture(unitID, data,  image)
						end
					end
				end
			end
		end
	end
end

function widget:UnitEnteredLos(unitID, unitTeam)
	local unitDefID = spGetUnitDefID(unitID)
	SetupPossibleCommander(unitID,  unitDefID, unitTeam)
end

function widget:UnitCreated( unitID,  unitDefID,  unitTeam)
	SetupPossibleCommander(unitID,  unitDefID, unitTeam)
end

function widget:UnitDestroyed( unitID,  unitDefID,  unitTeam)
	if not Spring.IsUnitAllied(unitID) then
		return
	end
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

local function DrawWorldFunc()
	glDepthTest(true)
	glAlphaTest(GL_GREATER, 0)
	
	for textureName, texData in pairs(textures) do
		glTexture(textureName)
		for unitID, unitData in pairs(texData.units) do
			local unitDefID = Spring.GetUnitDefID(unitID)
			if unitDefID and UnitDefs[unitDefID].customParams.commtype then
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
			else
				-- Requires more work
				--RemoveUnit(unitID, textureName)
			end
		end
	end
	
	glAlphaTest(false)
	glColor(1,1,1,1)
	glTexture(false)
	glDepthTest(false)
end

function widget:DrawWorld()
	DrawWorldFunc()
end
function widget:DrawWorldRefraction()
	DrawWorldFunc()
end
