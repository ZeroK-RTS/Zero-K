function widget:GetInfo()
	return {
		name      = "Persistent Build Spacing",
		desc      = "-Maintains build spacing between matches\n-Add Mousewheel+Shift to control it\n-Add previsualization of future placements",
		author    = "Helwor",
		date      = "August 2020",
		license   = "GNU GPL, v2 or later",
		layer     = 1,
		enabled   = true,  --  loaded by default?
	}
end

-- Config
local defaultSpacing = 4 -- Big makes for more navigable bases for new players.

-- Speedups
local spGetActiveCommand    = Spring.GetActiveCommand
local spGetBuildSpacing     = Spring.GetBuildSpacing
local spSetBuildSpacing     = Spring.SetBuildSpacing
local spGetBuildFacing      = Spring.GetBuildFacing
local spGetMouseState       = Spring.GetMouseState
local spTraceScreenRay      = Spring.TraceScreenRay
local spGetGroundHeight     = Spring.GetGroundHeight
local spGetGameSeconds      = Spring.GetGameSeconds
local spGetModKeyState      = Spring.GetModKeyState
local spuGetMoveType        = Spring.Utilities.getMovetype
local spTestBuildOrder      = Spring.TestBuildOrder

local floor, round, huge, max = math.floor, math.round, math.huge, math.max

local GL_LINE_STRIP = GL.LINE_STRIP
local glLineWidth   = gl.LineWidth
local glColor       = gl.Color
local glBeginEnd    = gl.BeginEnd
local glVertex      = gl.Vertex
local glLineStipple = gl.LineStipple
local glPushMatrix  = gl.PushMatrix
local glPopMatrix   = gl.PopMatrix
local glTranslate   = gl.Translate
local glBillboard   = gl.Billboard
local glText        = gl.Text


---- Shared variables
local cmdID, lastCmdID
local buildStarted
local buildSpacing = {}
local identified = false
local placement
local placementCache = {}
local placementCacheOff = {}
local preGame
local spacing, newspacing, facing
local spacedRects = {}
local x, y, z
local dwOn, draw, drawValue, drawRects
local drawTime = 0
local colors = {  -- red, yellow, green
	[0] = {  1 , 0.5, 0.5, 1 },
	[1] = {  1 ,  1 , 0.5, 1 },
	[2] = { 0.5,  1 , 0.5, 1 }
}
-- related to options
local grdots = "\255\155\155\155" .. " .." .. "\255\255\255\255"
local wheelSpacing, wheelValue = false, 1
local showSpacingRects, only2Rects, followGround, stickToWrongGrid, showRectsOnChange
	=      true,          true,        true,          false,             true
local withBadColor = followGround
local showSpacingValue, showValueOnChange = false, false

local showRectsTime = 0.7
local showValueTime = 1
local spacingIncrease
local spacingDecrease


------- OPTIONS -------
-- Identify the hotkeys
include("keysym.lua")
local _, ToKeysyms  = include("Configs/integral_menu_special_keys.lua")
local function UpdateKeys()
	local key = WG.crude.GetHotkeyRaw("buildspacing inc")
	spacingIncrease = ToKeysyms(key and key[1])
	key = WG.crude.GetHotkeyRaw("buildspacing dec")
	spacingDecrease = ToKeysyms(key and key[1])
end

local hotkeys_path = 'Hotkeys/Construction'
options_path = 'Settings/Interface/Building Placement'
options_order = {
	'text_hotkey',
	'hotkey_inc', 'hotkey_dec', 'hotkey_facing_inc', 'hotkey_facing_dec',
	'spacing_label',
	'wheel_spacing', 'reverse_wheel',
	'show_spacing_rects', 'show_only_2_rects', 'show_rects_only_on_change', 'rects_follow_ground', 'stick_to_wrong_grid', 'rects_bad_color', 'show_time_rects',
	'show_spacing_value', 'show_value_only_on_change', 'show_time_value',
	
}
options = {
	-- hotkeys
	text_hotkey = {
		name            = 'Structure Placement Modifiers',
		type            = 'label',
		path            = hotkeys_path
	},
	hotkey_inc = {
		name            = 'Increase Build Spacing',
		type            = 'button',
		desc            = 'Increase the spacing between structures queued in a line or rectangle. Hold Shift to queue a line of structures. Add Alt to queue a rectangle. Add Ctrl to queue a hollow rectangle.',
		action          = "buildspacing inc",
		bindWithAny     = true,
		path            = hotkeys_path,
		OnHotkeyChange  = UpdateKeys,
	},
	hotkey_dec = {
		name            = 'Decrease Build Spacing',
		type            = 'button',
		desc            = 'Decrease the spacing between structures queued in a line or rectangle. Hold Shift to queue a line of structures. Add Alt to queue a rectangle. Add Ctrl to queue a hollow rectangle.',
		action          = "buildspacing dec",
		bindWithAny     = true,
		path            = hotkeys_path,
		OnHotkeyChange  = UpdateKeys,
		
	},
	hotkey_facing_inc = {
		name            = 'Rotate Counterclockwise',
		type            = 'button',
		desc            = 'Rotate the structure placement blueprint counterclockwise.',
		action          = "buildfacing inc",
		bindWithAny     = true,
		path            = hotkeys_path,
	},
	hotkey_facing_dec = {
		name            = 'Rotate Clockwise',
		type            = 'button',
		desc            = 'Rotate the structure placement blueprint clockwise.',
		action          = "buildfacing dec",
		bindWithAny     = true,
		path            = hotkeys_path,
	},
	----- wheel and visualization implementation
	spacing_label = {
		name            = 'Build Spacing',
		type            = 'label',
	},
	-- wheel
	wheel_spacing = {
		name            = 'Change with Shift + MouseWheel',
		type            = 'bool',
		desc            = 'Change the spacing Shift down and the MouseWheel',
		value           = wheelSpacing,
		noHotkey        = true,
		OnChange        = function(self)
			wheelSpacing = self.value
			widgetHandler[(wheelSpacing and 'Update' or 'Remove')..'CallIn'](widget,"MouseWheel")
		end,
		children        = {'reverse_wheel'}
	},
	reverse_wheel = {
		name            = '..reversed.',
		type            = 'bool',
		value           = wheelValue == -1,
		noHotkey        = true,
		OnChange        = function(self)
			wheelValue = self.value and -1 or 1
		end,
		parents         = {'wheel_spacing'}
	},
	-- rectangle showing options
	show_spacing_rects = {
		name            = 'Visualise spacing',
		type            = 'bool',
		desc            = "Briefly show spaced rectangles in all directions around the cursor",
		value           = showSpacingRects,
		noHotkey        = true,
		OnChange        = function(self)
			showSpacingRects = self.value
			spacedRects = {}
		end,
		children        = {'show_only_2_rects', 'rects_follow_ground', 'show_rects_only_on_change', 'show_time_rects'}
	},
	
	show_only_2_rects = {
		name            = '..of only two rectangles, ',
		type            = 'bool',
		desc            = "If 8 rectangles bug you too much, only show 2 horizontal rectangles",
		value           = only2Rects,
		noHotkey        = true,
		OnChange        = function(self)
			spacedRects = {}
			only2Rects = self.value
		end,
		parents         = {'show_spacing_rects'}
	},
	show_rects_only_on_change = {
		name            = '..only on spacing change, ',
		type            = 'bool',
		desc            = "If you don't want to see those rectangles until you change the current spacing",
		value           = showRectsOnChange,
		noHotkey        = true,
		OnChange        = function(self)
			showRectsOnChange = self.value
		end,
		parents         = {'show_spacing_rects'}
	},
	rects_follow_ground = {
		name            = '..following the ground height,',
		type            = 'bool',
		desc            = "..unless, of course, if it should float !",
		noHotkey        = true,
		value           = followGround,
		OnChange        = function(self)
			followGround = self.value
		end,
		parents         = {'show_spacing_rects'}
	},
	stick_to_wrong_grid = {
		name            = '..according to the placement grid,',
		type            = 'bool',
		desc            = "In case of building moving units, the placement grid is misleading, uncheck this is you want to see the rectangles following where the placements will really occur.",
		noHotkey        = true,
		value           = stickToWrongGrid,
		OnChange        = function(self)
			stickToWrongGrid = self.value
		end,
		parents         = {'show_spacing_rects'}
	},
	rects_bad_color = {
		name            = '..with bad colors for bad placements,',
		type            = 'bool',
		desc            = "Reddish color if it cannot be placed",
		noHotkey        = true,
		value           = withBadColor,
		OnChange        = function(self)
			withBadColor = self.value
		end,
		parents         = {'show_spacing_rects'}
	},
	show_time_rects = {
		name            = '... for this many seconds.',
		type            = 'number',
		min             = 0.1,
		max             = 10.1,
		step            = 0.1,
		value           = math.min(showRectsTime, 10.1),
		tooltipFunction = function(self)
			return self.value < 10.1 and round(self.value, 1).." seconds" or "forever"
		end,
		OnChange        = function(self)
			showRectsTime = self.value < 10.1 and self.value or huge
		end,
		parents        = {'show_spacing_rects'}
	},
	-- value showing options
	show_spacing_value = {
		name            = 'Show spacing value',
		type            = 'bool',
		desc            = "Briefly show separation value",
		value           = showSpacingValue,
		noHotkey        = true,
		OnChange        = function(self)
			showSpacingValue = self.value
		end,
		children        = {'show_value_only_on_change', 'show_time_value'}
	},
	
	show_value_only_on_change = {
		name            = '..only on spacing change, ',
		type            = 'bool',
		desc            = "If you don't want to see the above helper until you change the current spacing",
		value           = showValueOnChange,
		noHotkey        = true,
		OnChange        = function(self)
			showValueOnChange = self.value
		end,
		parents         = {'show_spacing_value'}
	},
	
	show_time_value = {
		name            = '... for this many seconds.',
		type            = 'number',
		min             = 0.1,
		max             = 10.1,
		step            = 0.1,
		value           = math.min(showValueTime, 10.1),
		tooltipFunction    = function(self)
			return self.value < 10.1 and round(self.value, 1).." seconds" or "forever"
		end,
		OnChange        = function(self)
			showValueTime = self.value < 10.1 and self.value or huge
		end,
		parents         = {'show_spacing_value'},
	},
}

------- DRAWING FUNCTIONS -------
local function IdentifyPlacement(unitDefID, facing)
	local offFacing = (facing == 1 or facing == 3)
	local placeTable = (offFacing and placementCacheOff) or placementCache
	if not placeTable[unitDefID] then
		local ud = UnitDefs[unitDefID]
		local sx = ud.xsize*8
		local sz = ud.zsize*8
		if offFacing then
			sx, sz = sz, sx
		end
		local oddx, oddz = (sx/2)%16, (sz/2)%16
		--[[
			Note:
			-floatOnWater is only correct for buildings (at the notable exception of turretgauss) and flying units
			-canMove and isBuilding are unreliable:
			   staticjammer, staticshield, staticradar, factories... have 'canMove'
			   staticcon, striderhub doesn't have... 'isBuilding'
			-isGroundUnit is reliable
			-spuGetMoveType is better as it discern also between flying (1) and building (false)
			-ud.maxWaterDepth is only correct for telling us if a non floating building can be a valid build undersea
			-ud.moveDef.depth is always correct about units except for hover
			-ud.moveDef.depthMod is 100% reliable for telling if non flying unit can be built under sea, on float or only on shallow water:
			   no depthMod = flying or building,
			   0 = walking unit undersea,
			   0.1 = sub, ship or hover,
			   0.02 = walking unit only on shallow water
		--]]
		local isUnit = spuGetMoveType(ud) -- 1 == flying, 2 == on ground/water false = building
		local depthMod = isUnit and ud.moveDef.depthMod

		local floatOnWater = ud.floatOnWater
		local gridAboveWater = floatOnWater or isUnit -- that's what the engine relate to, with a position based on trace screen ray that has floatOnWater only, which offset the grid for units
		local underSea = depthMod == 0 or not (isUnit or floatOnWater or ud.maxWaterDepth == 0)
		local reallyFloat = isUnit == 2 and depthMod == 0.1 or floatOnWater and ud.name ~= 'turretgauss'
		local cantPlaceOnWater = not (underSea or reallyFloat)

		placeTable[unitDefID] = {
			oddx = oddx,
			oddz = oddz,
			sx = sx,
			sz = sz,
			underSea = underSea,
			reallyFloat = reallyFloat,
			cantPlaceOnWater = cantPlaceOnWater,
			gridAboveWater = gridAboveWater, -- following the wrong engine grid 
			floatOnWater = floatOnWater,
		}
	end
	return placeTable[unitDefID]
end

local function ToValidPlacement(x,z,oddx,oddz)
	return  floor((x + 8 - oddx)/16)*16 + oddx,
		floor((z + 8 - oddz)/16)*16 + oddz
end

local function MakeRect(x, y, z, sx, sz, color)
	return {
			{x-sx, y, z-sz},
			{x-sx, y, z+sz},
			{x+sx, y, z+sz},
			{x+sx, y, z-sz}
	}
end

local function DrawRect(corners)
	glColor(corners.color)
	for i = 1, 5 do
		glVertex(unpack(corners[i] or corners[1]))
	end
end


------- CALLINS -------
function widget:KeyPress(key)
	if not cmdID then
		return
	end
	local change = (key == spacingIncrease and 1) or (key == spacingDecrease and -1)
	if not change then
		return
	end
	spacing = max(spacing + change, 0)
	newspacing = true
	if preGame then
		spSetBuildSpacing(spacing)-- action is recognized but still doesnt work, so we do change spacing directly
		return true -- make it override construction tab hotkey in pregame as it would do in game
	end
end

function widget:MouseWheel(_, value)
	if not (cmdID and select(4,spGetModKeyState())) then
		return
	end
	spacing = max(spacing + wheelValue*value,0)
	spSetBuildSpacing(spacing)
	newspacing = true
	return true -- blocking the zoom
end


function widget:GameFrame(frame) -- more elegant way and less checking to set preGame
	preGame=false
	widgetHandler:RemoveCallIn('GameFrame',self)
end


function widget:Update(dt)
	cmdID = select(2, spGetActiveCommand())
	cmdID = cmdID and cmdID < 0 and -cmdID
	if not cmdID then
		draw = false
		buildStarted = nil
		return
	end
	if cmdID ~= lastCmdID then
		spacing = buildSpacing[cmdID] or tonumber(UnitDefs[cmdID].customParams.default_spacing) or defaultSpacing
		spSetBuildSpacing(spacing)
		lastCmdID = cmdID
		identified = false
		buildStarted = nil
	else
		spacing = spGetBuildSpacing() -- changed mind, if another widget wants to change the spacing, we have to know it
		buildSpacing[cmdID] = spacing
	end
	local mx, my, leftClick, _, rightClick = spGetMouseState()

	-- all pre-conditions variables set here
	if leftClick or rightClick then
		draw = false
		newspacing = false
		buildStarted = false
		drawTime=false
		return
	elseif newspacing then
		buildStarted = false
		drawTime = 0
		newspacing = false
	elseif buildStarted == nil then
		buildStarted = true
		drawTime = 0
	elseif not drawTime then
		return
	else
		drawTime = drawTime + dt
	end
	----

	-- Drawing set up
	draw, drawRects, drawValue = true, true, true
	if not showSpacingRects
	   or drawTime > showRectsTime
	   or showRectsOnChange and buildStarted
	   then
		drawRects = false
	end

	if not showSpacingValue
	   or drawTime > showValueTime
	   or showValueOnChange and buildStarted
	   then
		drawValue = false
	end
	
	if not (drawValue or drawRects) then
		draw = false
		return
	end
	
	
	local f = spGetBuildFacing()
	if not identified or facing%2 ~= f%2 then
		facing = f
		placement = IdentifyPlacement(cmdID, facing)
		identified = true
	end

	if not placement then --Can happen when rotation changes rapidly
		draw = false
		return
	end

	local pos = select(2, spTraceScreenRay(mx, my, true, false, false, not placement.floatOnWater))
	if not pos then
		draw = false
		return
	end

	local nx, nz = ToValidPlacement(pos[1], pos[3], placement.oddx, placement.oddz)
	if x == nx and z == nz and drawTime~=0 then-- only recalculate when needed
		return
	end

	
	x, y, z = nx, pos[2], nz
	local fix
	-- we set a different y ref for rectangle draw, y for showValue will always stay above engine grid for the sake of visibility
	local rY = y

	if y<0 and placement.gridAboveWater then 
		-- we're undersea, floatOnWater is false but grid is above water, therefore it's a non flying unit
		-- the engine up the grid to floatline no matter what
		-- when user will click, it will be placed actually undersea if the unit can sub
		
		-- if user wants to get the real placement and a fix is needed... fixing even impossible placement for the sake of coherence                                             
		fix = not stickToWrongGrid and (placement.underSea or placement.cantPlaceOnWater)
		y=0 -- the y is moving up following the engine placement grid
		if not fix then
			rY = y -- nothing to fix, rY stands corrected
		end
	end

	if drawRects then
		local count = 0
		local sx, sz = placement.sx, placement.sz
		local realspacing = spacing*16
		for offx = -1, 1 do
			for offz = -1, 1 do
				if (not only2Rects or offz == 0) and (offx ~= 0 or offz ~= 0 or fix) then -- will add the center rect if we fix
					count = count + 1
					local ix,iz = x + offx*(realspacing + sx), z + offz*(realspacing + sz)
					local iy = not followGround and rY or spGetGroundHeight(ix,iz)
					-- we follow the grid if it's correct or user don't want to fix it
					if iy < 0 and not fix and placement.gridAboveWater then 
						iy = 0
					end
					-- prepare corners directly here instead of recalculating them in DrawWorld, prepare different colors if the user want to
					spacedRects[count] = MakeRect(ix, iy, iz, sx/2, sz/2)
					spacedRects[count].color = colors[withBadColor and spTestBuildOrder(cmdID, ix, 0, iz, facing) or 2]

				end
			end
		end
		if not fix then 
			-- erasing an extra rect that might still be present from a previous 'fix'
			spacedRects[only2Rects and 3 or 9] = nil
		end
	end
	if not dwOn then
		widgetHandler:UpdateCallIn("DrawWorld")
	end
end

-- Drawing
function widget:DrawWorld()
	if not draw then
		dwOn = false
		spacedRects = {}
		widgetHandler:RemoveCallIn("DrawWorld")
		return
	end
	dwOn = true
	if drawRects then
		local alpha
		-- keep at 0.6 until the last second
		if showRectsTime - drawTime > 1 then
			alpha = 0.6
		else
			local ftime = drawTime - (showRectsTime - 1) -- make the last second 0... to 1
			alpha = 0.6 / (ftime + 1) ^ ftime -- fading out in that last second, augmenting the divisor exponentially as time run
		end
		glLineWidth(1.5)
		glLineStipple(true)
		for _, rect in ipairs(spacedRects) do
			rect.color[4] = alpha
			glBeginEnd(GL_LINE_STRIP, DrawRect, rect)
		end
		glLineWidth(1)
		glLineStipple(false)
	end
	if drawValue then
		glPushMatrix()
		glTranslate(x, y, z)
		glBillboard()
		glColor(1, 1, 1, 0.4)
		glText(spacing, placement.sx/2, placement.sz/2, 30, 'h')
		glPopMatrix()
	end
	glColor(1, 1, 1, 1)
end

------------
-- Save/Load spacing values
function widget:GetConfigData()
	local spacingByName = {}
	for unitDefID, spacing in pairs(buildSpacing) do
		local name = UnitDefs[unitDefID] and UnitDefs[unitDefID].name
		if name then
			spacingByName[name] = spacing
		end
	end
	return { buildSpacing = spacingByName }
end

function widget:SetConfigData(data)
	local spacingByName = data.buildSpacing or {}
	for name, spacing in pairs(spacingByName) do
		local unitDefID = UnitDefNames[name] and UnitDefNames[name].id
		if unitDefID then
			buildSpacing[unitDefID] = spacing
		end
	end
end
-- Init
function widget:Initialize()-- fixing the missing hotkey recognition in pre-game
	preGame = Spring.GetGameFrame()<1
	UpdateKeys()
	if not wheelSpacing then -- now MouseWheel callin is updated/removed when option change
		widgetHandler:RemoveCallIn('MouseWheel')
	end
end
