function widget:GetInfo()
   return {
      name      = "UnitShapes",
      desc      = "0.5.8.zk.02 Draws blended shapes around units and buildings",
      author    = "Lelousius and aegis, modded Licho, CarRepairer",
      date      = "30.07.2010",
      license   = "GNU GPL, v2 or later",
      layer     = 2,
      enabled   = true,
	  detailsDefault = 1
   }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function SetupCommandColors(state)
  local alpha = state and 1 or 0
  local f = io.open('cmdcolors.tmp', 'w+')
  if (f) then
    f:write('unitBox  0 1 0 ' .. alpha)
    f:close()
    Spring.SendCommands({'cmdcolors cmdcolors.tmp'})
  end
  os.remove('cmdcolors.tmp')
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local math_acos				= math.acos
local math_pi				= math.pi
local math_cos				= math.cos
local math_sin				= math.sin
local math_abs				= math.abs
local rad_con				= 180 / math_pi

local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA
local GL_ONE_MINUS_DST_ALPHA = GL.ONE_MINUS_DST_ALPHA
local GL_SRC_ALPHA = GL.SRC_ALPHA
local GL_DST_ALPHA = GL.DST_ALPHA
local GL_DST_COLOR = GL.DST_COLOR
local GL_SRC_COLOR = GL.SRC_COLOR
local GL_ZERO = GL.ZERO
local GL_ONE = GL.ONE

local GL_QUADS = GL.QUADS
local GL_QUAD_STRIP = GL.QUAD_STRIP
local GL_TRIANGLE_FAN = GL.TRIANGLE_FAN
local GL_TRIANGLE_STRIP = GL.TRIANGLE_STRIP
local GL_LINE_LOOP = GL.LINE_LOOP
local GL_TRIANGLES = GL.TRIANGLES
local GL_POLYGON = GL.POLYGON

local GL_COLOR_BUFFER_BIT = GL.COLOR_BUFFER_BIT
local glPushAttrib = gl.PushAttrib
local glPopAttrib = gl.PopAttrib

local gl_DepthTest =			gl.DepthTest
local gl_BlendFunc = 			gl.BlendFunc
local gl_ColorMask =			gl.ColorMask
local gl_DrawList =				gl.CallList

local spGetUnitHeading       = Spring.GetUnitHeading
local spGetUnitDirection	 = Spring.GetUnitDirection
local spGetHeadingFromVector = Spring.GetHeadingFromVector
local spIsUnitIcon           = Spring.IsUnitIcon

local UnitDs				 = UnitDefs

-- Automatically generated local definitions

local glBeginEnd             = gl.BeginEnd
local glColor                = gl.Color
local glCreateList           = gl.CreateList
local glDeleteList           = gl.DeleteList
local glDepthTest            = gl.DepthTest
local glDrawListAtUnit       = gl.DrawListAtUnit
local glLineWidth            = gl.LineWidth
local glPolygonOffset        = gl.PolygonOffset
local glVertex               = gl.Vertex
local spDiffTimers           = Spring.DiffTimers
local spGetVisibleUnits		 = Spring.GetVisibleUnits
local spGetGroundNormal      = Spring.GetGroundNormal
local spGetSelectedUnits     = Spring.GetSelectedUnits
local spGetTeamColor         = Spring.GetTeamColor
local spGetTimer             = Spring.GetTimer
local spGetUnitBasePosition  = Spring.GetUnitBasePosition
local spGetUnitDefDimensions = Spring.GetUnitDefDimensions
local spGetUnitDefID         = Spring.GetUnitDefID
local spGetUnitRadius        = Spring.GetUnitRadius
local spGetUnitTeam          = Spring.GetUnitTeam
local spGetUnitViewPosition  = Spring.GetUnitViewPosition
local spIsUnitSelected       = Spring.IsUnitSelected
local spIsUnitVisible        = Spring.IsUnitVisible
local spSendCommands         = Spring.SendCommands

local spGetCameraPosition	 = Spring.GetCameraPosition
local spGetGameFrame		 = Spring.GetGameFrame
local spTraceScreenRay		 = Spring.TraceScreenRay
local spGetMouseState		 = Spring.GetMouseState

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local clearquad
local shapes = {}

local myTeamID = Spring.GetLocalTeamID()

local circleDivs = 32 -- how precise circle? octagon by default
local innersize = 0.9 -- circle scale compared to unit radius
local selectinner = 1.5
local outersize = 1.9 -- outer fade size compared to circle scale (1 = no outer fade)
local scalefaktor = 2.8
local rectangleFactor = 3.5
local CAlpha = 0.5

local colorout = {   1,   1,   1,   0 } -- outer color
local colorin  = {   1,   1,   1,   1 } -- inner color

local teamColors = {}
local unitConf = {}
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

local visibleAllySelUnits = {}

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
options_path = 'Settings/Interface'
options = {
	showally = {
		name = 'Show Ally Selections',
		type = 'bool',
		value = false,
		OnChange = function(self) 
			visibleAllySelUnits = {}
		end,
	},
}

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

local lastCamX, lastCamY, lastCamZ
local lastGameFrame = 0

local lastVisibleUnits, lastVisibleSelected, lastvisibleAllySelUnits
local forceUpdate = false

local function HasVisibilityChanged()
	local camX, camY, camZ = spGetCameraPosition()
	local gameFrame = spGetGameFrame()
	if (camX ~= lastCamX) or (camY ~= lastCamY) or (camZ ~= lastCamZ) or
		((gameFrame - lastGameFrame) >= 15) or (#lastVisibleSelected > 0) or
		(#spGetSelectedUnits() > 0) then
		
		lastGameFrame = gameFrame
		lastCamX, lastCamY, lastCamZ = camX, camY, camZ
		return true
	end
	return false
end

local function GetVisibleUnits()
	if (HasVisibilityChanged()) then
		
		local units = spGetVisibleUnits(-1, 30, true)
		--local visibleUnits = {}
		local visibleAllySelUnits = {}
		local visibleSelected = {}
		
		for i=1, #units do
			local unitID = units[i]
			if (spIsUnitSelected(unitID)) then
				visibleSelected[#visibleSelected+1] = unitID
			--else
				--visibleUnits[#visibleUnits+1] = unitID
			elseif options.showally.value and WG.allySelUnits[unitID] then
				visibleAllySelUnits[#visibleAllySelUnits+1] = unitID
			end
		end
		
		--lastVisibleUnits = visibleUnits
		lastvisibleAllySelUnits = visibleAllySelUnits
		lastVisibleSelected = visibleSelected
		--return visibleUnits, visibleSelected
		return visibleAllySelUnits, visibleSelected
	else
		--return lastVisibleUnits, lastVisibleSelected
		return lastvisibleAllySelUnits, lastVisibleSelected
	end
end


local function GetTeamColorSet(teamID)
  local colors = teamColors[teamID]
  if (colors) then
    return colors
  end
  local r,g,b = spGetTeamColor(teamID)
  
  colors = { r, g, b, 0 }
	-- Alpha = 0 as it is drawn with DST_ALPHA and should Clear it afterwards
  
  teamColors[teamID] = colors
  return colors
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Creating polygons:
local function CreateDisplayLists(callback)
	local displayLists = {}
	
	local zeroColor = {0, 0, 0, 0}
	local CAlphaColor = {0, 0, 0, CAlpha}
	
	displayLists.select = callback.fading(colorin, colorout, outersize, selectinner)
	displayLists.invertedSelect = callback.fading(colorout, colorin, outersize, selectinner)
	displayLists.inner = callback.solid(zeroColor, innersize)
	displayLists.large = callback.solid(nil, selectinner)
	displayLists.kill = callback.solid(nil, outersize)
	displayLists.shape = callback.fading(zeroColor, CAlphaColor, innersize, selectinner)
	
	return displayLists
end

local function CreateCircleLists()
	local callback = {}
	
	function callback.fading(colorin, colorout, innersize, outersize)
		return glCreateList(function()
			glBeginEnd(GL.QUAD_STRIP, function()
				local radstep = (2.0 * math_pi) / circleDivs
				for i = 0, circleDivs do
					local a1 = (i * radstep)
					if (colorin) then
						glColor(colorin)
					end
					glVertex(math_sin(a1)*innersize, 0, math_cos(a1)*innersize)
					if (colorout) then
						glColor(colorout)
					end
					glVertex(math_sin(a1)*outersize, 0, math_cos(a1)*outersize)
				end
			end)
		end)
	end
	
	function callback.solid(color, size)
		return glCreateList(function()
			glBeginEnd(GL.TRIANGLE_FAN, function()
				local radstep = (2.0 * math_pi) / circleDivs
				if (color) then
					glColor(color)
				end
				glVertex(0, 0, 0)
				for i = 0, circleDivs do
					local a1 = (i * radstep)
					glVertex(math_sin(a1)*size, 0, math_cos(a1)*size)
				end
			end)
		end)
	end
	
	shapes.circle = CreateDisplayLists(callback)
end

local function CreatePolygonCallback(points, immediate)
	immediate = immediate or GL_POLYGON
	local callback = {}
	
	function callback.fading(colorin, colorout, innersize, outersize)
		local diff = outersize - innersize
		local steps = {}
		
		for i=1, #points do
			local p = points[i]
			local x, z = p[1]*outersize, p[2]*outersize
			local xs, zs = (math_abs(x)/x and x or 1), (math_abs(z)/z and z or 1)
			steps[i] = {x, z, xs, zs}
		end
		
		return glCreateList(function()
			glBeginEnd(GL_TRIANGLE_STRIP, function()
				for i=1, #steps do
					local step = steps[i] or steps[i-#steps]
					local nexts = steps[i+1] or steps[i-#steps+1]
					
					glColor(colorout)
					glVertex(step[1], 0, step[2])
					
					glColor(colorin)
					glVertex(step[1] - diff*step[3], 0, step[2] - diff*step[4])
					
					glColor(colorout)
					glVertex(step[1] + (nexts[1]-step[1]), 0, step[2] + (nexts[2]-step[2]))
					
					glColor(colorin)
					glVertex(nexts[1] - diff*nexts[3], 0, nexts[2] - diff*nexts[4])
				end
			end)
		end)
	end
	
	function callback.solid(color, size)
		return glCreateList(function()
			glBeginEnd(immediate, function()
				if (color) then
					glColor(color)
				end
				for i=1, #points do
					local p = points[i]
					glVertex(size*p[1], 0, size*p[2])
				end
			end)
		end)
	end
	
	return callback
end

local function CreateSquareLists()
	local points = {
			{-1, 1},
			{1, 1},
			{1, -1},
			{-1, -1}
		}

	local callback = CreatePolygonCallback(points, GL_QUADS)
	shapes.square = CreateDisplayLists(callback)
end

local function CreateTriangleLists()
	local points = {
		{0, -1},
		{1, 1},
		{-1, 1}
	}
	
	local callback = CreatePolygonCallback(points, GL_TRIANGLES)
	shapes.triangle = CreateDisplayLists(callback)
end

local function DestroyShape(shape)
	glDeleteList(shape.select)
	glDeleteList(shape.invertedSelect)
	glDeleteList(shape.inner)
	glDeleteList(shape.large)
	glDeleteList(shape.kill)
	glDeleteList(shape.shape)
end

function widget:Initialize()
	if not WG.allySelUnits then 
		WG.allySelUnits = {} 
	end
	
	CreateCircleLists()
	CreateSquareLists()
	CreateTriangleLists()
	
	for udid, unitDef in pairs(UnitDs) do
		local xsize, zsize = unitDef.xsize, unitDef.zsize
		local scale = scalefaktor*( xsize^2 + zsize^2 )^0.5
		local shape, xscale, zscale
		
		
		if (unitDef.isBuilding or unitDef.isFactory or unitDef.speed==0) then
			shape = shapes.square
			xscale, zscale = rectangleFactor * xsize, rectangleFactor * zsize
		elseif (unitDef.canFly) then
			shape = shapes.triangle
			xscale, zscale = scale, scale
		else
			shape = shapes.circle
			xscale, zscale = scale, scale
		end

		unitConf[udid] = {shape=shape, xscale=xscale, zscale=zscale}
	end

	clearquad = glCreateList(function()
		local size = 1000
		glBeginEnd(GL.QUADS, function()
			glVertex( -size,0,  			-size)
			glVertex( Game.mapSizeX+size,0, -size)
			glVertex( Game.mapSizeX+size,0, Game.mapSizeZ+size)
			glVertex( -size,0, 				Game.mapSizeZ+size)
		end)
	end)
	SetupCommandColors(false)
end

function widget:Shutdown()
	SetupCommandColors(true)
	
	glDeleteList(clearquad)
	
	for _, shape in pairs(shapes) do
		DestroyShape(shape)
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local visibleUnits, visibleSelected = {}, {}
local degrot = {}
function widget:Update()
	-- [[
	local mx, my = spGetMouseState()
	local ct, id = spTraceScreenRay(mx, my)
	if (ct == "unit") then
		hoveredUnit = id
	else
		hoveredUnit = nil
	end
	--]]
	--visibleUnits, visibleSelected = GetVisibleUnits()
	visibleAllySelUnits, visibleSelected = GetVisibleUnits()
	heading = {}
	for i=1, #visibleUnits do
		local unitID = visibleUnits[i]
		dirx, _, dirz = spGetUnitDirection(unitID)
		if (dirz ~= nil) then
			degrot[unitID] = 180 - math_acos(dirz) * rad_con
		end
	end
	for i=1, #visibleSelected do
		local unitID = visibleSelected[i]
		dirx, _, dirz = spGetUnitDirection(unitID)
		if (dirz ~= nil) then
			if dirx < 0 then
				degrot[unitID] = 180 - math_acos(dirz) * rad_con
			else
				degrot[unitID] = 180 + math_acos(dirz) * rad_con
			end
		end
	end
end

--Funktion-vars for later use
	local teamID	= 0
	local unitID	= 0
	local udid 		= 0
	local dirx 		= 0
	local diry 		= 0
	local dirz 		= 0
	local unit
-- Drawing:


function widget:DrawWorldPreUnit()
	if Spring.IsGUIHidden() or (#visibleAllySelUnits + #visibleSelected == 0) then return end
	
	glPushAttrib(GL_COLOR_BUFFER_BIT)

	glDepthTest(false)

	if #visibleSelected > 0 then
		-- To fix Water
		gl_ColorMask(false,false,false,true)
		gl_BlendFunc(GL_ONE, GL_ONE)
		glColor(0,1,0,1)
		-- Does not need to be drawn per Unit .. it covers the whole map
		gl_DrawList(clearquad)
		
		--  Draw selection circles
		gl_BlendFunc(GL_ONE_MINUS_SRC_ALPHA, GL_SRC_ALPHA)
		for i=1, #visibleSelected do
			unitID = visibleSelected[i]
			udid = spGetUnitDefID(unitID)
			unit = unitConf[udid]
			
			if (unit) then
				glDrawListAtUnit(unitID, unit.shape.select, false, unit.xscale, 1.0, unit.zscale, degrot[unitID], 0, degrot[unitID], 0)
			end
		end

		--  Here The inner of the selected circles are removed
		gl_BlendFunc(GL_ONE, GL_ZERO)
		glColor(0,0,0,1)
		
		for i=1, #visibleSelected do
			unitID = visibleSelected[i]
			udid = spGetUnitDefID(unitID)
			unit = unitConf[udid]
			
			if (unit) then
				glDrawListAtUnit(unitID, unit.shape.large, false, unit.xscale, 1.0, unit.zscale, degrot[unitID], 0, degrot[unitID], 0)
			end
		end	

		--  Really draw the Circles now  (This could be optimised if we could say Draw as much as DST_ALPHA * SRC_ALPHA is)
		-- (without protecting form drawing them twice)
		gl_ColorMask(true,true,true,true)
		gl_BlendFunc(GL_ONE_MINUS_DST_ALPHA, GL_DST_ALPHA)
		glColor(0,1,0,1)

		-- Does not need to be drawn per Unit anymore
		gl_DrawList(clearquad)

		--  Draw Circles to AlphaBuffer
		gl_ColorMask(false, false, false, true)
		gl_BlendFunc(GL_DST_ALPHA, GL_ZERO)

		for i=1, #visibleSelected do
			unitID = visibleSelected[i]
			udid = spGetUnitDefID(unitID)
			unit = unitConf[udid]
			
			if (unit) then
				glDrawListAtUnit(unitID, unit.shape.shape, false, unit.xscale, 1.0, unit.zscale, degrot[unitID], 0, degrot[unitID], 0)
				glDrawListAtUnit(unitID, unit.shape.inner, false, unit.xscale, 1.0, unit.zscale, degrot[unitID], 0, degrot[unitID], 0)
			end
		end
		
		for i=1, #visibleSelected do
			unitID = visibleSelected[i]
			udid = spGetUnitDefID(unitID)
			unit = unitConf[udid]
			
			if (unit) then
				glColor(0,1,0,0)
				glDrawListAtUnit(unitID, unit.shape.large, false, unit.xscale, 1.0, unit.zscale, degrot[unitID], 0, degrot[unitID], 0)
			end
		end
	end --if #visibleSelected > 0
	
	--Can this massive if block be somehow merged into the above? I tried and tried.
	if #visibleAllySelUnits > 0 then
		-- To fix Water
		gl_ColorMask(false,false,false,true)
		gl_BlendFunc(GL_ONE, GL_ONE)
		glColor(1,1,0,1)
		-- Does not need to be drawn per Unit .. it covers the whole map
		gl_DrawList(clearquad)
		
		--  Draw selection circles
		gl_BlendFunc(GL_ONE_MINUS_SRC_ALPHA, GL_SRC_ALPHA)
		for i=1, #visibleAllySelUnits do
			unitID = visibleAllySelUnits[i]
			udid = spGetUnitDefID(unitID)
			unit = unitConf[udid]
			
			if (unit) then
				glDrawListAtUnit(unitID, unit.shape.select, false, unit.xscale, 1.0, unit.zscale, 0, 0, 0, 0)
			end
		end

		--  Here The inner of the selected circles are removed
		gl_BlendFunc(GL_ONE, GL_ZERO)
		glColor(0,0,0,1)
		
		for i=1, #visibleAllySelUnits do
			unitID = visibleAllySelUnits[i]
			udid = spGetUnitDefID(unitID)
			unit = unitConf[udid]
			
			if (unit) then
				glDrawListAtUnit(unitID, unit.shape.large, false, unit.xscale, 1.0, unit.zscale,  0, 0, 0, 0)	
			end
		end	

		--  Really draw the Circles now  (This could be optimised if we could say Draw as much as DST_ALPHA * SRC_ALPHA is)
		-- (without protecting form drawing them twice)
		gl_ColorMask(true,true,true,true)
		gl_BlendFunc(GL_ONE_MINUS_DST_ALPHA, GL_DST_ALPHA)
		glColor(1,1,0,1)

		-- Does not need to be drawn per Unit anymore
		gl_DrawList(clearquad)

		--  Draw Circles to AlphaBuffer
		gl_ColorMask(false, false, false, true)
		gl_BlendFunc(GL_DST_ALPHA, GL_ZERO)

		for i=1, #visibleAllySelUnits do
			unitID = visibleAllySelUnits[i]
			udid = spGetUnitDefID(unitID)
			unit = unitConf[udid]
			
			if (unit) then
				glDrawListAtUnit(unitID, unit.shape.shape, false, unit.xscale, 1.0, unit.zscale, 0, 0, 0, 0)
				glDrawListAtUnit(unitID, unit.shape.inner, false, unit.xscale, 1.0, unit.zscale, degrot[unitID], 0, degrot[unitID], 0)
			end
		end
		
		for i=1, #visibleAllySelUnits do
			unitID = visibleAllySelUnits[i]
			udid = spGetUnitDefID(unitID)
			unit = unitConf[udid]
			
			if (unit) then
				glColor(1,1,0,0)
				glDrawListAtUnit(unitID, unit.shape.large, false, unit.xscale, 1.0, unit.zscale, degrot[unitID], 0, degrot[unitID], 0)
			end
		end
	end --if #visibleAllySelUnits > 0
	
	glColor(1,1,1,1)
	glPopAttrib()
end
--allySelUnits

	


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------