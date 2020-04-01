local versionNumber = "0.51"

function widget:GetInfo()
  return {
    name      = "Map Info",
    desc      = versionNumber .." Draws map-info on the bottom left of the map.  Toggle height with /mapinfo_floor",
    author    = "Floris",
    date      = "20 May 2014",
    license   = "GNU GPL, v2 or later",
    layer     = -10,
    enabled   = false,  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
-- Console commands
--------------------------------------------------------------------------------

--/mapinfo_floor		-- toggles placement at ground-height, or map floor

--------------------------------------------------------------------------------
-- config
--------------------------------------------------------------------------------

local scale					= 2
local offset				= 5
local backgroundOpacity		= 0.6
local textOpacity			= 0.95
local fadeMultiplier		= 0.8
local stickToFloor			= true
local thickness				= 8
local fadeStartHeight		= 2000
local fadeEndHeight			= 6000

--------------------------------------------------------------------------------
-- speed-ups
--------------------------------------------------------------------------------

local spGetCameraPosition	= Spring.GetCameraPosition
local spGetGroundHeight		= Spring.GetGroundHeight
local spIsAABBInView		= Spring.IsAABBInView
--local spGetCameraState		= Spring.GetCameraState

local glColor           = gl.Color
local glScale           = gl.Scale
local glText            = gl.Text
local glPushMatrix      = gl.PushMatrix
local glPopMatrix       = gl.PopMatrix
local glTranslate       = gl.Translate
local glBeginEnd        = gl.BeginEnd
local glVertex          = gl.Vertex
local glGetTextWidth	= gl.GetTextWidth
local glBlending		= gl.Blending

local glDepthTest       = gl.DepthTest
local glAlphaTest       = gl.AlphaTest
local glTexture         = gl.Texture
local glRotate          = gl.Rotate

local mapInfo = {}
local mapInfoWidth = 400	-- minimum width

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

function DrawMapInfo(backgroundOpacity, opacityMultiplier)
	
	glDepthTest(true)
	glBlending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	
	if stickToFloor then
		glTranslate(offset, offset, Game.mapSizeZ)
	else
		glTranslate(offset, mapInfoBoxHeight-offset, Game.mapSizeZ)
	end
	glPushMatrix()
	glScale(scale,scale,scale)
	if backgroundOpacity > 0 then
		glRotate(90,0,-1,0)
		glRotate(180,1,0,0)
		
		local length = math.max(mapInfoWidth, (glGetTextWidth(mapInfo.mapDescription)*12) + 45)
		--Spring.Echo(glGetTextWidth(mapInfo.mapDescription))
		
		local height = 90
		local thickness = -(thickness*scale)
		glBeginEnd(GL.QUADS,function()
			glColor(0.12,0.12,0.12,backgroundOpacity*opacityMultiplier*opacityMultiplier)
			glVertex( height, 0        , 0);         -- Top Right Of The Quad (Top)
			glVertex( 0     , 0        , 0);         -- Top Left Of The Quad (Top)
			glVertex( 0     , 0        , length);    -- Bottom Left Of The Quad (Top)
			glVertex( height, 0        , length);    -- Bottom Right Of The Quad (Top)
			
			glVertex( height, 0        , length);    -- Top Right Of The Quad (Front)
			glVertex( 0     , 0        , length);    -- Top Left Of The Quad (Front)
			glVertex( 0     ,-thickness, length);    -- Bottom Left Of The Quad (Front)
			glVertex( height,-thickness, length);    -- Bottom Right Of The Quad (Front)
			
			glVertex( height,-thickness, 0);         -- Top Right Of The Quad (Back)
			glVertex( 0     ,-thickness, 0);         -- Top Left Of The Quad (Back)
			glVertex( 0     , 0        , 0);         -- Bottom Left Of The Quad (Back)
			glVertex( height, 0        , 0);         -- Bottom Right Of The Quad (Back)
			
			glVertex( 0     , 0        , length);    -- Top Right Of The Quad (Left)
			glVertex( 0     , 0        , 0);         -- Top Left Of The Quad (Left)
			glVertex( 0     ,-thickness, 0);         -- Bottom Left Of The Quad (Left)
			glVertex( 0     ,-thickness, length);    -- Bottom Right Of The Quad (Left)
			
			glVertex( height, 0        , 0);         -- Top Right Of The Quad (Right)
			glVertex( height, 0        , length);    -- Top Left Of The Quad (Right)
			glVertex( height,-thickness, length);    -- Bottom Left Of The Quad (Right)
			glVertex( height,-thickness, 0);         -- Bottom Right Of The Quad (Right)
			
			
			glColor(0.05,0.05,0.05,backgroundOpacity*opacityMultiplier*opacityMultiplier)
			glVertex( height,-thickness, length);    -- Top Right Of The Quad (Bottom)
			glVertex( 0     ,-thickness, length);    -- Top Left Of The Quad (Bottom)
			glVertex( 0     ,-thickness, 0);         -- Bottom Left Of The Quad (Bottom)
			glVertex( height,-thickness, 0);         -- Bottom Right Of The Quad (Bottom)
		end)
		
		glRotate(180,1,0,0)
		glRotate(90,0,1,0)
	end
	
	glRotate(90,1,0,0)
	glTranslate(0,3,0)
	
	local textOffsetX = 11
	local textOffsetY = 16
	usedTextOffsetY = textOffsetY + (offset/2)
	local text = mapInfo.mapName
	
	glRotate(180,1,0,0)
	
	-- map name
	glColor(1,1,1,(textOpacity*1.12)*opacityMultiplier)
	glText(text, textOffsetX,-usedTextOffsetY,14,"n")
	glColor(0,0,0,textOpacity*0.12*opacityMultiplier)
	glText(text, textOffsetX+0.5,-usedTextOffsetY-0.9,14,"n")
	
	--map description
	usedTextOffsetY = usedTextOffsetY+textOffsetY
	text = mapInfo.mapDescription
	glColor(1,1,1,textOpacity*0.6*opacityMultiplier)
	glText(text, textOffsetX,-usedTextOffsetY,12,"n")
	
	if 1 == 2 then
	usedTextOffsetY = usedTextOffsetY+textOffsetY
	text = "Waterdamage: "..math.floor(mapInfo.waterDamage)
	glColor(1,1,1,textOpacity*0.6*opacityMultiplier)
	glText(text, textOffsetX,-usedTextOffsetY,12,"n")
	glColor(0,0,0,textOpacity*0.6*0.17*opacityMultiplier)
	glText(text, textOffsetX,-usedTextOffsetY-1,12,"n")
		
	textOffsetX = textOffsetX + 120
	text = "Gravity: "..math.floor(mapInfo.gravity)
	glColor(1,1,1,textOpacity*0.6*opacityMultiplier)
	glText(text, textOffsetX,-usedTextOffsetY,12,"n")
	glColor(0,0,0,textOpacity*0.6*0.17*opacityMultiplier)
	glText(text, textOffsetX,-usedTextOffsetY-1,12,"n")
	textOffsetX = textOffsetX - 120
	
	textOffsetX = textOffsetX + 210
	text = "Tidal: "..math.floor(mapInfo.tidal)
	glColor(1,1,1,textOpacity*0.6*opacityMultiplier)
	glText(text, textOffsetX,-usedTextOffsetY,12,"n")
	glColor(0,0,0,textOpacity*0.6*0.17*opacityMultiplier)
	glText(text, textOffsetX,-usedTextOffsetY-1,12,"n")
	textOffsetX = textOffsetX - 210
	
	-- game name
	usedTextOffsetY = usedTextOffsetY+textOffsetY+textOffsetY+textOffsetY
	text = mapInfo.gameName.."   "..mapInfo.gameVersion
	glColor(1,1,1,textOpacity*opacityMultiplier)
	glText(text, textOffsetX,-usedTextOffsetY,12,"n")
	glColor(0,0,0,textOpacity*0.17*opacityMultiplier)
	glText(text, textOffsetX,-usedTextOffsetY-1,12,"n")
	end
	
	glPopMatrix()
	
	if stickToFloor then
		glTranslate(-offset, -offset, -Game.mapSizeZ)
	else
		glTranslate(-offset, -mapInfoBoxHeight-offset, -Game.mapSizeZ)
	end
	glColor(1,1,1,1)
	glScale(1,1,1)
	glDepthTest(false)
end

function Init()
	mapInfo.mapName				= Game.mapName
	mapInfo.mapDescription		= Game.mapDescription
	mapInfo.waterDamage			= Game.waterDamage
	mapInfo.gravity				= Game.gravity
	mapInfo.tidal				= Game.tidal
	mapInfo.gameName			= Game.gameName
	mapInfo.gameVersion			= Game.gameVersion
	mapInfo.gameMutator			= Game.gameMutator
	
	if (glGetTextWidth(mapInfo.mapDescription) * 12) > mapInfoWidth then
		--mapInfoWidth = (glGetTextWidth(mapInfo.mapDescription) * 12) + 33
	end
	if stickToFloor then
		mapInfoBoxHeight = 0
	else
		mapInfoBoxHeight = spGetGroundHeight(0,Game.mapSizeZ)
	end
	
	-- find the lowest map height
	if not stickToFloor then
		for i=math.floor(offset*scale), math.floor((mapInfoWidth+offset)*scale) do
			if spGetGroundHeight(i,Game.mapSizeZ) < mapInfoBoxHeight then
				mapInfoBoxHeight = spGetGroundHeight(i,Game.mapSizeZ)
			end
		end
	end
end
--------------------------------------------------------------------------------
-- callins
--------------------------------------------------------------------------------

function widget:Initialize()
	Init()
end

local inView = false
local camDistance = 1000
function widget:Update()
	local camX, camY, camZ = spGetCameraPosition()
	local xDifference = camX - (mapInfoWidth/2)*scale
	local yDifference = camY - mapInfoBoxHeight
	local zDifference = camZ - Game.mapSizeZ
	camDistance = math.sqrt(xDifference*xDifference + yDifference*yDifference + zDifference*zDifference)
	inView = spIsAABBInView(offset, mapInfoBoxHeight, Game.mapSizeZ,   mapInfoWidth*scale, mapInfoBoxHeight+(thickness*scale), Game.mapSizeZ)
end

function widget:DrawWorld()
    if Spring.IsGUIHidden() then return end
	if inView then
		local opacityMultiplier = (1 - (camDistance-fadeStartHeight) / (fadeEndHeight-fadeStartHeight))*fadeMultiplier
		if opacityMultiplier > 1 then
			opacityMultiplier = 1
		end
		
		if opacityMultiplier > 0.06 then
			DrawMapInfo(backgroundOpacity, opacityMultiplier)
		end
	end
end



function widget:GetConfigData(data)
    savedTable = {}
    savedTable.stickToFloor = stickToFloor
    return savedTable
end

function widget:SetConfigData(data)
    if data.stickToFloor ~= nil 	then  stickToFloor	= data.stickToFloor end
end

function widget:TextCommand(command)
    if (string.find(command, "mapinfo_floor") == 1  and  string.len(command) == 13) then 
		stickToFloor = not stickToFloor
		Init()
	end
end
