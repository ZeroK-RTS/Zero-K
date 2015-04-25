function widget:GetInfo()
   return {
      name      = "UnitShapes",
      desc      = "0.5.8.zk.02 Draws blended shapes around units and buildings",
      author    = "Lelousius and aegis, modded Licho, CarRepairer, jK",
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
	Spring.LoadCmdColorsConfig('unitBox  0 1 0 ' .. alpha)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local math_acos				= math.acos
local math_pi				= math.pi
local math_cos				= math.cos
local math_sin				= math.sin
local math_abs				= math.abs
local rad_con				= 180 / math_pi

local GL_KEEP      = 0x1E00
local GL_REPLACE   = 0x1E01

local spGetUnitDirection     = Spring.GetUnitDirection

local spGetVisibleUnits      = Spring.GetVisibleUnits
local spGetSelectedUnits     = Spring.GetSelectedUnits
local spGetUnitDefID         = Spring.GetUnitDefID
local spIsUnitSelected       = Spring.IsUnitSelected

local spGetCameraPosition	 = Spring.GetCameraPosition
local spGetGameFrame		 = Spring.GetGameFrame
local spTraceScreenRay		 = Spring.TraceScreenRay
local spGetMouseState		 = Spring.GetMouseState

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local clearquad
local shapes = {}

local myTeamID = Spring.GetLocalTeamID()
--local r,g,b = Spring.GetTeamColor(myTeamID)
local r,g,b = 0, 1, 0
local rgba = {r,g,b,1}
local yellow = {1,1,0,1}

local circleDivs = 32 -- how precise circle? octagon by default
local innersize = 0.9 -- circle scale compared to unit radius
local selectinner = 1.5
local outersize = 1.8 -- outer fade size compared to circle scale (1 = no outer fade)
local scalefaktor = 2.8
local rectangleFactor = 3.5
local CAlpha = 0.2

local colorout = {   1,   1,   1,   0 } -- outer color
local colorin  = {   r,   g,   b,   1 } -- inner color

local teamColors = {}
local unitConf = {}
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

local visibleAllySelUnits = {}

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
options_path = 'Settings/Interface/Selection/Selection Shapes'
options_order = {'showally'} 
options = {
	showally = {
		name = 'Show Ally Selections',
		desc = 'Highlight the units your allies currently have selected.', 
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
		return gl.CreateList(function()
			gl.BeginEnd(GL.QUAD_STRIP, function()
				local radstep = (2.0 * math_pi) / circleDivs
				for i = 0, circleDivs do
					local a1 = (i * radstep)
					if (colorin) then
						gl.Color(colorin)
					end
					gl.Vertex(math_sin(a1)*innersize, 0, math_cos(a1)*innersize)
					if (colorout) then
						gl.Color(colorout)
					end
					gl.Vertex(math_sin(a1)*outersize, 0, math_cos(a1)*outersize)
				end
			end)
		end)
	end
	
	function callback.solid(color, size)
		return gl.CreateList(function()
			gl.BeginEnd(GL.TRIANGLE_FAN, function()
				local radstep = (2.0 * math_pi) / circleDivs
				if (color) then
					gl.Color(color)
				end
				gl.Vertex(0, 0, 0)
				for i = 0, circleDivs do
					local a1 = (i * radstep)
					gl.Vertex(math_sin(a1)*size, 0, math_cos(a1)*size)
				end
			end)
		end)
	end
	
	shapes.circle = CreateDisplayLists(callback)
end

local function CreatePolygonCallback(points, immediate)
	immediate = immediate or GL.POLYGON
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
		
		return gl.CreateList(function()
			gl.BeginEnd(GL.TRIANGLE_STRIP, function()
				for i=1, #steps do
					local step = steps[i] or steps[i-#steps]
					local nexts = steps[i+1] or steps[i-#steps+1]
					
					gl.Color(colorout)
					gl.Vertex(step[1], 0, step[2])
					
					gl.Color(colorin)
					gl.Vertex(step[1] - diff*step[3], 0, step[2] - diff*step[4])
					
					gl.Color(colorout)
					gl.Vertex(step[1] + (nexts[1]-step[1]), 0, step[2] + (nexts[2]-step[2]))
					
					gl.Color(colorin)
					gl.Vertex(nexts[1] - diff*nexts[3], 0, nexts[2] - diff*nexts[4])
				end
			end)
		end)
	end
	
	function callback.solid(color, size)
		return gl.CreateList(function()
			gl.BeginEnd(immediate, function()
				if (color) then
					gl.Color(color)
				end
				for i=1, #points do
					local p = points[i]
					gl.Vertex(size*p[1], 0, size*p[2])
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

	local callback = CreatePolygonCallback(points, GL.QUADS)
	shapes.square = CreateDisplayLists(callback)
end

local function CreateTriangleLists()
	local points = {
		{0, -1},
		{1, 1},
		{-1, 1}
	}
	
	local callback = CreatePolygonCallback(points, GL.TRIANGLES)
	shapes.triangle = CreateDisplayLists(callback)
end

local function DestroyShape(shape)
	gl.DeleteList(shape.select)
	gl.DeleteList(shape.invertedSelect)
	gl.DeleteList(shape.inner)
	gl.DeleteList(shape.large)
	gl.DeleteList(shape.kill)
	gl.DeleteList(shape.shape)
end

function widget:Initialize()
	if not WG.allySelUnits then
		WG.allySelUnits = {}
	end
	
	CreateCircleLists()
	CreateSquareLists()
	CreateTriangleLists()
	
	for udid, unitDef in pairs(UnitDefs) do
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

	clearquad = gl.CreateList(function()
		local size = 1000
		gl.BeginEnd(GL.QUADS, function()
			gl.Vertex( -size,0,              -size)
			gl.Vertex( Game.mapSizeX+size,0, -size)
			gl.Vertex( Game.mapSizeX+size,0, Game.mapSizeZ+size)
			gl.Vertex( -size,0,              Game.mapSizeZ+size)
		end)
	end)
	SetupCommandColors(false)
end

function widget:Shutdown()
	SetupCommandColors(true)
	
	gl.DeleteList(clearquad)
	
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
	for i=1, #visibleUnits do
		local unitID = visibleUnits[i]
		local dirx, _, dirz = spGetUnitDirection(unitID)
		if (dirz ~= nil) then
			degrot[unitID] = 180 - math_acos(dirz) * rad_con
		end
	end
	for i=1, #visibleSelected do
		local unitID = visibleSelected[i]
		local dirx, _, dirz = spGetUnitDirection(unitID)
		if (dirz ~= nil) then
			if dirx < 0 then
				degrot[unitID] = 180 - math_acos(dirz) * rad_con
			else
				degrot[unitID] = 180 + math_acos(dirz) * rad_con
			end
		end
	end
end


function DrawUnitShapes(unitList, color)
	if not unitList[1] then
		return
	end

	-- To fix Water
	gl.ColorMask(false,false,false,true)
	gl.BlendFunc(GL.ONE, GL.ONE)
	gl.Color(0,0,0,1)
	-- Does not need to be drawn per Unit .. it covers the whole map
	gl.CallList(clearquad)

	--  Draw selection circles
	gl.Color(1,1,1,1)
	gl.Blending(true)
	gl.BlendFunc(GL.ONE_MINUS_SRC_ALPHA, GL.SRC_ALPHA)
	gl.ColorMask(false,false,false,true)
	gl.StencilFunc(GL.ALWAYS, 0x01, 0xFF)
	gl.StencilOp(GL_KEEP, GL_KEEP, GL_REPLACE)
	for i=1, #unitList do
		local unitID = unitList[i]
		local udid = spGetUnitDefID(unitID)
		local unit = unitConf[udid]

		if (unit) then
			gl.DrawListAtUnit(unitID, unit.shape.select, false, unit.xscale, 1.0, unit.zscale, degrot[unitID], 0, degrot[unitID], 0)
		end
	end

	--  Here The inner of the selected circles are removed
	gl.Blending(false)
	gl.ColorMask(false,false,false,false)
	gl.StencilFunc(GL.ALWAYS, 0x0, 0xFF)
	gl.StencilOp(GL_KEEP, GL_KEEP, GL_REPLACE)
	for i=1, #unitList do
		local unitID = unitList[i]
		local udid = spGetUnitDefID(unitID)
		local unit = unitConf[udid]

		if (unit) then
			gl.DrawListAtUnit(unitID, unit.shape.large, false, unit.xscale, 1.0, unit.zscale, degrot[unitID], 0, degrot[unitID], 0)
			gl.Unit(unitID, true)
		end
	end

	--  Really draw the Circles now
	gl.Color(color)
	gl.ColorMask(true,true,true,true)
	gl.Blending(true)
	gl.BlendFuncSeparate(GL.ONE_MINUS_DST_ALPHA, GL.DST_ALPHA, GL.ONE, GL.ONE)
	gl.StencilFunc(GL.EQUAL, 0x01, 0xFF)
	gl.StencilOp(GL_KEEP, GL_KEEP, GL.ZERO)
	gl.CallList(clearquad)
end

function widget:DrawWorldPreUnit()
		--if Spring.IsGUIHidden() then return end
	if (#visibleAllySelUnits + #visibleSelected == 0) then return end
	
	gl.PushAttrib(GL_COLOR_BUFFER_BIT)
		gl.DepthTest(false)
		gl.StencilTest(true)

			DrawUnitShapes(visibleSelected, rgba)
			DrawUnitShapes(visibleAllySelUnits, yellow)

		gl.StencilFunc(GL.ALWAYS, 0x0, 0xFF)
		gl.StencilOp(GL_KEEP, GL_KEEP, GL_KEEP)
		gl.Blending("reset")
		gl.Color(1,1,1,1)
	gl.PopAttrib()
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
