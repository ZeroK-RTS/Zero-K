function widget:GetInfo()
   return {
      name      = "UnitShapes",
      desc      = "0.5.8.zk.02 Draws blended shapes around units and buildings",
      author    = "Lelousius and aegis, modded Licho, CarRepairer, jK, Shadowfury333",
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

local spGetUnitIsDead        = Spring.GetUnitIsDead
local spGetUnitHeading       = Spring.GetUnitHeading

local spGetVisibleUnits      = Spring.GetVisibleUnits
local spGetSelectedUnits     = Spring.GetSelectedUnits
local spGetUnitDefID         = Spring.GetUnitDefID
local spIsUnitSelected       = Spring.IsUnitSelected

local spGetCameraPosition	 = Spring.GetCameraPosition
local spGetGameFrame		 = Spring.GetGameFrame
local spTraceScreenRay		 = Spring.TraceScreenRay
local spGetMouseState		 = Spring.GetMouseState

local SafeWGCall = function(fnName, param1) if fnName then return fnName(param1) else return nil end end
local GetUnitUnderCursor = function(onlySelectable) return SafeWGCall(WG.PreSelection_GetUnitUnderCursor, onlySelectable) end
local IsSelectionBoxActive = function() return SafeWGCall(WG.PreSelection_IsSelectionBoxActive) end
local GetUnitsInSelectionBox = function() return SafeWGCall(WG.PreSelection_GetUnitsInSelectionBox) end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local clearquad
local shapes = {}

local myTeamID = Spring.GetLocalTeamID()
--local r,g,b = Spring.GetTeamColor(myTeamID)
local r,g,b = 0.1, 1, 0.2
local rgba = {r,g,b,1}
local yellow = {1,1,0.1,1}
local teal = {0.1,1,1,1}
local red = {1,0.2,0.1,1}
local hoverColor = teal


local circleDivs = 32 -- how precise circle? octagon by default
local innersize = 0.9 -- circle scale compared to unit radius
local selectinner = 1.5
local outersize = 1.8 -- outer fade size compared to circle scale (1 = no outer fade)
local scalefaktor = 2.8
local rectangleFactor = 2.7
local CAlpha = 0.2


local hoverScaleDuration = 0.05
local hoverScaleStart = 0.95
local hoverScaleEnd = 1.0

local hoverRestedTime = 0.05 --Time in ms below which the player is assumed to be rapidly hovering over different units
local hoverBufferDisplayTime = 0.05 --Time in ms to keep showing hover when starting box selection
local hoverBufferScaleSuppressTime = 0.1 --Time in ms to stop box select from doing scale effect on a hovered unit

local boxedScaleDuration = 0.05
local boxedScaleStart = 0.9
local boxedScaleEnd = 1.0


local colorout = {   1,   1,   1,   0 } -- outer color
local colorin  = {   r,   g,   b,   1 } -- inner color

local teamColors = {}
local unitConf = {}
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

local lastBoxedUnits = {}
local lastBoxedUnitsIDs = {}

local selectedUnits = {}

local visibleBoxed = {}
local visibleAllySelUnits = {}
local hoveredUnit = {}

local hasVisibleAllySelections = false
local forceUpdate = false
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
options_path = 'Settings/Interface/Selection/Selection Shapes'
options_order = {'allyselectionlevel', 'showallyplayercolours', 'showhover', 'showinselectionbox', 'animatehover', 'animateselectionbox'}
options = {
	allyselectionlevel = {
		name = 'Show Ally Selections',
		type = 'radioButton',
		items = {
			{name = 'Enabled',key='enabled', desc="Show selected unit of allies."},
			{name = 'Commshare Only',key='commshare', desc="Show when sharing unit control."},
			{name = 'Disabled',key='disabled', desc="Do not show any allied selection."},
		},
		value = 'commshare',
		OnChange = function(self)
			forceUpdate = true
			visibleAllySelUnits = {}
		end,
	},
	showallyplayercolours = {
		name = 'Use Player Colors when Spectating',
		desc = 'Highlight allies\' selected units with their color.',
		type = 'bool',
		value = false,
		OnChange = function(self)
			forceUpdate = true
		end,
		noHotkey = true,
	},
	showhover = {
		name = 'Highlight Hovered Unit',
		desc = 'Highlight the unit under your cursor.',
		type = 'bool',
		value = true,
		OnChange = function(self)
			hoveredUnit = {}
		end,
		noHotkey = true,
	},
	showinselectionbox = {
		name = 'Highlight Units in Selection Box',
		desc = 'Highlight the units in the selection box.',
		type = 'bool',
		value = true,
		noHotkey = true,
	},
	animatehover = {
		name = 'Animate Hover Shape',
		desc = '',
		type = 'bool',
		value = true,
		advanced = true,
		noHotkey = true,
	},
	animateselectionbox = {
		name = 'Animate Shapes in Selection Box',
		desc = '',
		type = 'bool',
		value = true,
		advanced = true,
		noHotkey = true,
	}
}

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

local lastCamX, lastCamY, lastCamZ
local lastGameFrame = 0

local lastVisibleUnits, lastVisibleSelected, lastvisibleAllySelUnits
-- local lastDrawtoolSetting = WG.drawtoolKeyPressed

local hoverBuffer = 0
local hoverTime = 0 --how long we've been hovering
local cursorIsOn = "self"

local function GetBoxedUnits() --Mostly a helper function for the animation system
	local allBoxedUnits = GetUnitsInSelectionBox()
	local boxedUnits = {}
	local boxedUnitsIDs = {}
	if allBoxedUnits then
		for i=1, #allBoxedUnits do
			if #hoveredUnit > 0 and hoveredUnit[1].unitID == allBoxedUnits[i] then --Transfer hovered unit here to avoid flickering
				boxedUnits[#boxedUnits+1] = hoveredUnit[1]
				hoveredUnit = {}
				boxedUnitsIDs[allBoxedUnits[i]] = #boxedUnits
			elseif hoverBuffer > 0 or spIsUnitSelected(allBoxedUnits[i]) or not options.animateselectionbox.value then --don't scale if it just stopped being hovered over, reduces flicker effect
				boxedUnitsIDs[allBoxedUnits[i]] = #boxedUnits+1
				boxedUnits[#boxedUnits+1] = {unitID = allBoxedUnits[i], scale = boxedScaleEnd}
			elseif not lastBoxedUnitsIDs[allBoxedUnits[i]] then
				boxedUnitsIDs[allBoxedUnits[i]] = #boxedUnits+1
				boxedUnits[#boxedUnits+1] = {unitID = allBoxedUnits[i], startTime = Spring.GetTimer(), duration = boxedScaleDuration, startScale = boxedScaleStart, endScale = boxedScaleEnd}
			else
				boxedUnits[#boxedUnits+1] = lastBoxedUnits[lastBoxedUnitsIDs[allBoxedUnits[i]]]
				boxedUnitsIDs[allBoxedUnits[i]] = #boxedUnits
			end
		end
	end
	return boxedUnits, boxedUnitsIDs
end

local function HasVisibilityChanged()
	local camX, camY, camZ = spGetCameraPosition()
	local gameFrame = spGetGameFrame()
	if forceUpdate or (camX ~= lastCamX) or (camY ~= lastCamY) or (camZ ~= lastCamZ) or
		((gameFrame - lastGameFrame) >= 15) or (#lastVisibleSelected > 0) or
		(#spGetSelectedUnits() > 0) then
		
		lastGameFrame = gameFrame
		lastCamX, lastCamY, lastCamZ = camX, camY, camZ
		return true
	end

	-- if WG.drawtoolKeyPressed ~= lastDrawtoolSetting then
	-- 	lastDrawtoolSetting = WG.drawtoolKeyPressed
	-- 	return true
	-- end
	return false
end

local function ShowAllySelection(unitID, myTeamID)
	if options.allyselectionlevel.value == "disabled" or (not WG.allySelUnits[unitID]) then
		return false
	end
	if options.allyselectionlevel.value == "enabled" then
		return true
	end
	local teamID = Spring.GetUnitTeam(unitID)
	return teamID == myTeamID
end

local function GetVisibleUnits()
	local visibleBoxed = {}
	if options.showinselectionbox.value then
		local boxedUnits, boxedUnitsIDs = GetBoxedUnits()

		if IsSelectionBoxActive() then --It's not worth rebuilding visible selected lists for selection box, but selection box needs to be updated per-frame
			local units = spGetVisibleUnits(-1, 30, true)
			for i=1, #units do
				local unitID = units[i]
				if boxedUnitsIDs[units[i]] and not WG.drawtoolKeyPressed then
					visibleBoxed[#visibleBoxed+1] = boxedUnits[boxedUnitsIDs[unitID]]
				end
			end
		end

		lastBoxedUnits = boxedUnits
		lastBoxedUnitsIDs = boxedUnitsIDs
	end

	if (HasVisibilityChanged()) then
		local units = spGetVisibleUnits(-1, 30, true)
		--local visibleUnits = {}
		local visibleAllySelUnits = {}
		local visibleSelected = {}
		local myTeamID = Spring.GetMyTeamID()
		
		for i = 1, #units do
			local unitID = units[i]
			if (spIsUnitSelected(unitID)) then
				visibleSelected[#visibleSelected+1] = {unitID = unitID}
			end
			
			if ShowAllySelection(unitID, myTeamID) then
				local teamIDIndex = Spring.GetUnitTeam(unitID)
				if teamIDIndex then --Possible nil check failure if unit is destroyed while selected
					teamIDIndex = teamIDIndex+1
					if Spring.GetSpectatingState() and not options.showallyplayercolours.value then
						teamIDIndex = 1
					end
					if not visibleAllySelUnits[teamIDIndex] then
						visibleAllySelUnits[teamIDIndex] = {}
					end
					visibleAllySelUnits[teamIDIndex][#visibleAllySelUnits[teamIDIndex]+1] = {unitID = unitID, scale = 0.92}
					hasVisibleAllySelections = true
				end
			end
		end

		lastvisibleAllySelUnits = visibleAllySelUnits
		lastVisibleSelected = visibleSelected
		return visibleAllySelUnits, visibleSelected, visibleBoxed
	else
		return lastvisibleAllySelUnits, lastVisibleSelected, visibleBoxed
	end
end

local function GetHoveredUnit(dt) --Mostly a convenience function for the animation system
	local unitID = GetUnitUnderCursor(false)
	local hoveredUnit = hoveredUnit
	local cursorIsOn = cursorIsOn
	if unitID and not spIsUnitSelected(unitID) then
		if #hoveredUnit == 0 or unitID ~= hoveredUnit[#hoveredUnit].unitID then
			if hoverTime < hoverRestedTime or not options.animatehover.value then --Only animate hover effect if player is not rapidly changing hovered unit
				hoveredUnit[1] = {unitID = unitID, scale = hoverScaleEnd}
			else
				hoveredUnit[1] = {unitID = unitID, startTime = Spring.GetTimer(), duration = hoverScaleDuration, startScale = hoverScaleStart, endScale = hoverScaleEnd}
			end

			local teamID = Spring.GetUnitTeam(unitID)
			local myTeamID = Spring.GetMyTeamID()
			if teamID then
				if teamID == myTeamID then
					cursorIsOn = "self"
				elseif teamID and Spring.AreTeamsAllied(teamID, myTeamID) then
					cursorIsOn = "ally"
				else
					cursorIsOn = "enemy"
				end
			end
			hoverTime = 0
		else
			hoverTime = math.min(hoverTime + dt, hoverRestedTime)
		end

		hoverBuffer = hoverBufferDisplayTime + hoverBufferScaleSuppressTime
	elseif hoverBuffer > 0 then
		hoverBuffer = math.max(hoverBuffer - dt, 0)

		if hoverBuffer <= hoverBufferScaleSuppressTime then --stop showing hover shape here, but if box selected within a short time don't do scale effect
			hoveredUnit = {}
		end

		if hoverBuffer < hoverBufferScaleSuppressTime then
			cursorIsOn = "self" --Don't change colour at the last second when over enemy
		end
	end
	return hoveredUnit, cursorIsOn
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
		{0, -1.3},
		{1, 0.7},
		{-1, 0.7}
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
		
		if unitDef.customParams and unitDef.customParams.selection_scale then
			local factor = (tonumber(unitDef.customParams.selection_scale) or 1)
			scale = scale*factor
			xsize = xsize*factor
			zsize = zsize*factor
		end
		
		
		if unitDef.isImmobile then
			shape = shapes.square
			xscale, zscale = rectangleFactor * xsize, rectangleFactor * zsize
		elseif (unitDef.canFly) then
			shape = shapes.triangle
			xscale, zscale = scale, scale
		else
			shape = shapes.circle
			xscale, zscale = scale, scale
		end

		unitConf[udid] = {
			shape = shape,
			xscale = xscale,
			zscale = zscale,
			noRotate = (unitDef.customParams.select_no_rotate and true) or false
		}
		
		if unitDef.customParams and unitDef.customParams.selection_velocity_heading then
			unitConf[udid].velocityHeading = true
		end
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
local visibleSelected = {}
local degrot = {}

local HEADING_TO_RAD = 1/32768*math.pi
local RADIANS_PER_COBANGLE = math.pi / 32768

local function UpdateUnitListScale(unitList)
	if not unitList then
		return
	end
	local now = Spring.GetTimer()
	for i=1, #unitList do
		local startScale = unitList[i].startScale
		local endScale = unitList[i].endScale
		local scaleDuration = unitList[i].duration
		if scaleDuration and scaleDuration > 0 then
			unitList[i].scale = startScale + math.min(Spring.DiffTimers(now, unitList[i].startTime) / scaleDuration, 1.0) * (endScale - startScale)
		elseif startScale then
			unitList[i].scale = startScale
		elseif not unitList[i].scale then --implicitly allows explicit scale to be set on unitList entry creation
			unitList[i].scale = 1.0
		end
	end
end

local function UpdateUnitListRotation(unitList)
	if not unitList then
		return
	end
	for i = 1, #unitList do
		local unitID = unitList[i].unitID
		local udid = spGetUnitDefID(unitID)
		if udid and unitConf[udid].noRotate then
			degrot[unitID] = 0
		elseif udid and unitConf[udid].velocityHeading then
			local vx,_,vz = Spring.GetUnitVelocity(unitID)
			if vx then
				local speed = vx*vx + vz*vz
				if speed > 0.25 then
					local velHeading = Spring.GetHeadingFromVector(vx, vz)*HEADING_TO_RAD
					degrot[unitID] = 180 + velHeading * rad_con
				end
			end
		else
			local heading = (not (spGetUnitIsDead(unitID)) and spGetUnitHeading(unitID) or 0) * RADIANS_PER_COBANGLE
			degrot[unitID] = 180 + heading * rad_con
		end
	end
end

function widget:Update(dt)
	if options.showhover.value then
		hoveredUnit, cursorIsOn = GetHoveredUnit(dt)
	end

	visibleAllySelUnits, visibleSelected, visibleBoxed = GetVisibleUnits()

	if #visibleBoxed > 0 then
		cursorIsOn = "self"
	end
	
	UpdateUnitListRotation(visibleSelected)
	local teams = Spring.GetTeamList()
	if Spring.GetSpectatingState() and options.showallyplayercolours.value then
		for i=1, #teams do
			if visibleAllySelUnits[teams[i]+1] then
				UpdateUnitListRotation(visibleAllySelUnits[teams[i]+1])
				UpdateUnitListScale(visibleAllySelUnits[teams[i]+1])
			end
		end
	elseif hasVisibleAllySelections then
		UpdateUnitListRotation(visibleAllySelUnits[1])
		UpdateUnitListScale(visibleAllySelUnits[1])
	end
	UpdateUnitListRotation(hoveredUnit)
	UpdateUnitListRotation(visibleBoxed)
	
	UpdateUnitListScale(visibleSelected)
	UpdateUnitListScale(hoveredUnit)
	UpdateUnitListScale(visibleBoxed)
end

function SetupUnitShapes()
	-- To fix Water
	gl.ColorMask(false,false,false,true)
	gl.BlendFunc(GL.ONE, GL.ONE)
	gl.Color(0,0,0,1)

	gl.DepthMask(false)
	--To fix other stencil effects leaving stencil data in
	gl.ColorMask(false,false,false,true)
	gl.StencilFunc(GL.ALWAYS, 0x00, 0xFF)
	gl.StencilOp(GL_REPLACE, GL_REPLACE, GL_REPLACE)
	-- Does not need to be drawn per Unit .. it covers the whole map
	gl.CallList(clearquad)
end

function DrawUnitShapes(unitList, color, underWorld)
	if not unitList[1] then
		return
	end

	-- Setup unit mask for later depth test against only units (don't test against map)
	-- gl.ColorMask(false,false,false,false)
	-- gl.DepthTest(GL.LEQUAL)
	-- gl.PolygonOffset(-1.0,-1.0)
	-- gl.StencilFunc(GL.ALWAYS, 0x01, 0xFF)
	-- gl.StencilOp(GL_KEEP, GL_KEEP, GL_REPLACE)
	-- local visibleUnits = spGetVisibleUnits(-1, 30, true)
	-- for i=1, #visibleUnits do
	-- 	gl.Unit(visibleUnits[i], true)
	-- end
	-- gl.DepthTest(false)

	--  Draw selection circles
	gl.Color(1,1,1,1)
	gl.Blending(true)
	gl.BlendFunc(GL.ONE_MINUS_SRC_ALPHA, GL.SRC_ALPHA)
	gl.ColorMask(false,false,false,true)
	if underWorld then
		gl.DepthTest(GL.GREATER)
	else
		gl.DepthTest(GL.LEQUAL)
	end
	gl.PolygonOffset(-1.0,-1.0)
	-- gl.StencilMask(0x01)
	gl.StencilFunc(GL.ALWAYS, 0x01, 0xFF)
	gl.StencilOp(GL_KEEP, GL_KEEP, GL_REPLACE)
	for i=1, #unitList do
		local unitID = unitList[i].unitID
		local udid = spGetUnitDefID(unitID)
		local unit = unitConf[udid]
		local scale = unitList[i].scale or 1

		if (unit) then
			gl.DrawListAtUnit(unitID, unit.shape.select, false, unit.xscale * scale, 1.0, unit.zscale * scale, degrot[unitID], 0, degrot[unitID], 0)
		end
	end
	gl.DepthTest(false)

	--  Here The inner of the selected circles are removed
	gl.Blending(false)
	gl.ColorMask(false,false,false,false)
	gl.StencilFunc(GL.ALWAYS, 0x0, 0xFF)
	gl.StencilOp(GL_KEEP, GL_KEEP, GL_REPLACE)
	for i=1, #unitList do
		local unitID = unitList[i].unitID
		local udid = spGetUnitDefID(unitID)
		local unit = unitConf[udid]
		local scale = unitList[i].scale or 1

		if (unit) then
			gl.DrawListAtUnit(unitID, unit.shape.large, false, unit.xscale * scale, 1.0, unit.zscale * scale, degrot[unitID], 0, degrot[unitID], 0)
		end
	end
	-- gl.DepthTest(GL.LEQUAL)
	-- gl.PolygonOffset(-1.0,-1.0)
	for i=1, #unitList do --Correct underwater
		local unitID = unitList[i].unitID
		local _, y, _ = Spring.GetUnitViewPosition(unitID)
		if y and (y < 0) then
			gl.Unit(unitID, true)
		end
	end
	-- gl.PolygonOffset(0.0,0.0)
	-- gl.DepthTest(GL.LESS)
	-- for i=1, #visibleUnits do
	-- 	gl.Unit(visibleUnits[i], true)
	-- end
	-- gl.DepthTest(false)

	--  Really draw the Circles now
	gl.Color(color)
	gl.ColorMask(true,true,true,true)
	gl.Blending(true)
	gl.BlendFuncSeparate(GL.ONE_MINUS_DST_ALPHA, GL.DST_ALPHA, GL.ONE, GL.ONE)
	gl.StencilFunc(GL.EQUAL, 0x01, 0xFF)
	gl.StencilOp(GL_KEEP, GL.ZERO, GL.ZERO)
	gl.CallList(clearquad)
		gl.PolygonOffset(0.0,0.0)
	-- gl.StencilMask(0xFF)
end

local function DrawCircles(underWorld)
	if Spring.IsGUIHidden() then return end
	if (#visibleSelected + #hoveredUnit + #visibleBoxed == 0) and not hasVisibleAllySelections then return end
	
	gl.PushAttrib(GL_COLOR_BUFFER_BIT)
		gl.DepthTest(false)
		gl.StencilTest(true)
			hoverColor = cursorIsOn == "enemy" and red or (cursorIsOn == "ally" and yellow or teal)

			SetupUnitShapes()

			DrawUnitShapes(visibleSelected, rgba, underWorld)
			if not Spring.IsGUIHidden() then
				local spec, _, fullselect = Spring.GetSpectatingState()
				if spec and options.showallyplayercolours.value then
					if fullselect then hoverColor = teal end
					
					local teams = Spring.GetTeamList()
					for i=1, #teams do
						if visibleAllySelUnits[teams[i]+1] then
							local r,g,b = Spring.GetTeamColor(teams[i])
						  DrawUnitShapes(visibleAllySelUnits[teams[i]+1], {r,g,b,1}, underWorld)
						end
					end
				elseif visibleAllySelUnits[1] then
					DrawUnitShapes(visibleAllySelUnits[1], yellow, underWorld)
				end
				DrawUnitShapes(hoveredUnit, hoverColor, underWorld)
				DrawUnitShapes(visibleBoxed, hoverColor, underWorld)
			end

		gl.StencilFunc(GL.ALWAYS, 0x0, 0xFF)
		gl.StencilOp(GL_KEEP, GL_KEEP, GL_KEEP)
		gl.StencilTest(false)
		gl.Blending("reset")
		gl.Color(1,1,1,1)
	gl.PopAttrib()
end

function widget:DrawWorldPreUnit()
	DrawCircles(true)
end

function widget:DrawWorld()
	DrawCircles(false)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
