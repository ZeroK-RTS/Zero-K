
-- luacheck: read globals gl GL WG
-- luacheck: read globals options commandType
-- provides: read globals RenderUpdate RenderPreUnit RenderWorld RenderCleanupUnit

-- Global Build Command/Rendering: Responsible for rendering state to screen,
-- keeping unit icons updates, checking relevant keyboard/mouse state
-- for visibility.

local Echo                = Spring.Echo
local spIsAABBInView      = Spring.IsAABBInView
local spIsSphereInView    = Spring.IsSphereInView
local spGetUnitPosition   = Spring.GetUnitPosition
local spGetModKeyState    = Spring.GetModKeyState
local spValidUnitID       = Spring.ValidUnitID

local glPushMatrix        = gl.PushMatrix
local glPopMatrix         = gl.PopMatrix
local glLoadIdentity      = gl.LoadIdentity
local glTranslate         = gl.Translate
local glBillboard         = gl.Billboard
local glColor             = gl.Color
local glTexture           = gl.Texture
local glTexRect           = gl.TexRect
local glBeginEnd          = gl.BeginEnd
local GL_LINE_STRIP       = GL.LINE_STRIP
local glDepthTest         = gl.DepthTest
local glRotate            = gl.Rotate
local glUnitShape         = gl.UnitShape
local glVertex            = gl.Vertex
local glGroundCircle      = gl.DrawGroundCircle
local glLineWidth         = gl.LineWidth

local CMD_REPAIR          = CMD.REPAIR
local CMD_RECLAIM         = CMD.RECLAIM

local abs                 = math.abs

local statusColor         = {1.0, 1.0, 1.0, 0.85}
local queueColor          = {1.0, 1.0, 1.0, 0.9}


-- Zero-K specific icons for drawing repair/reclaim/resurrect, customize if porting!
local rec_icon = "LuaUI/Images/commands/Bold/reclaim.png"
local rep_icon = "LuaUI/Images/commands/Bold/repair.png"
local res_icon = "LuaUI/Images/commands/Bold/resurrect.png"
local rec_color = {0.6, 0.0, 1.0, 1.0}
local rep_color = {0.0, 0.8, 0.4, 1.0}
local res_color = {0.4, 0.8, 1.0, 1.0}

local imgpath = "LuaUI/Images/commands/Bold/"
local no_icon = {name = 'gbcicon'}
local noidle_icon = {name = 'gbcidle'}
local idle_icon = {name = 'gbcidle', texture=imgpath .. "buildsmall.png"}
local queue_icon = {name = 'gbcicon', texture=imgpath .. "build_light.png", color=queueColor}
local drec_icon = {name = 'gbcicon', texture=imgpath .. "action.png", color=statusColor}
local move_icon = {name = 'gbcicon', texture=imgpath .. "move.png", color=statusColor}
local chicken_icon = {name = 'gbcidle', texture="LuaUI/Images/commands/states/retreat_90.png"} -- the chicken icon uses the idle icon slot because it flashes

-- drawing lists for GL
local buildList = {}
local areaList = {}
local stRepList = {}
local stRecList = {}
local stResList = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- GL Drawing Code -------------------------------------------------------------
--[[
HOW THIS WORKS:
	-- EXTERNAL API --
	RenderUpdate()
		Pre-sorts buildQueue by visibility and type for drawing.
	RenderPreUnit()
		Calls the functions for drawing building outlines and area command circles, since these need to be drawn first.
	RenderWorld()
		Draws status tags on units, calls the functions for drawing building "ghosts" for build jobs, and
		command icons for other jobs.
	-- INTERNAL FUNCTIONS --
	DrawBuildLines()
		Draws building outlines for build jobs, using DrawOutline().
	DrawAreaLines()
		Draws ground circles for area commands.
	DrawBuildingGhosts()
		Produces the gl code for drawing building ghosts for build jobs.
	DrawSTIcons()
		Draws command icons for single-target commands, takes a list as input rather than globals
		directly, since it's used to draw 3 different icon types.
]]--

-- Run pre-draw visibility checks, and sort buildQueue for drawing.
function RenderUpdate(dt, includedBuilders, allBuilders, buildQueue)
	-- update icons for builders
	if options.drawIcons.value then
		WG.icons.SetDisplay('gbcicon', true)
		WG.icons.SetDisplay('gbcidle', true)
		for unitID, data in pairs(allBuilders) do
			if data.include and includedBuilders[unitID] then
				local myCmd = includedBuilders[unitID]
				if myCmd.cmdtype == commandType.idle then
					WG.icons.SetUnitIcon(unitID, idle_icon)
					WG.icons.SetUnitIcon(unitID, no_icon) -- disable the non-idle/chicken icons
				elseif myCmd.cmdtype == commandType.ckn then
					WG.icons.SetUnitIcon(unitID, chicken_icon)
					WG.icons.SetUnitIcon(unitID, no_icon) -- disable the non-idle/chicken icons
				elseif myCmd.cmdtype == commandType.buildQueue then
					WG.icons.SetUnitIcon(unitID, queue_icon)
					WG.icons.SetUnitIcon(unitID, noidle_icon)
				elseif myCmd.cmdtype == commandType.mov then
					WG.icons.SetUnitIcon(unitID, move_icon)
					WG.icons.SetUnitIcon(unitID, noidle_icon)
				else
					WG.icons.SetUnitIcon(unitID, drec_icon)
					WG.icons.SetUnitIcon(unitID, noidle_icon)
				end
			else
				WG.icons.SetUnitIcon(unitID, no_icon)
				WG.icons.SetUnitIcon(unitID, noidle_icon)
			end
		end
	else
		WG.icons.SetDisplay('gbcicon', false)
		WG.icons.SetDisplay('gbcidle', false)
	end

	buildList = {}
	areaList = {}
	stRepList = {}
	stRecList = {}
	stResList = {}

	local alt, ctrl, meta, shift = spGetModKeyState()
	if shift or options.alwaysShow.value then
		for _, myCmd in pairs(buildQueue) do
			local cmd = myCmd.id
			if cmd < 0 then -- check visibility for building jobs
				local x, y, z, h = myCmd.x, myCmd.y, myCmd.z, myCmd.h
				if spIsAABBInView(x-1,y-1,z-1,x+1,y+1,z+1) then
					buildList[#buildList+1] = myCmd
				end
			elseif not myCmd.target then -- check visibility for area commands
				local x, y, z, r = myCmd.x, myCmd.y, myCmd.z, myCmd.r
				if spIsSphereInView(x, y, z, r+25) then
					areaList[#areaList+1] = myCmd
				end
			elseif myCmd.x -- check visibility for single-target commands
			or spValidUnitID(myCmd.target) then -- note we have to check units for validity to avoid nil errors, since the main validity checks may not have been run yet
				local x, y, z
				if myCmd.x then
					x, y, z = myCmd.x, myCmd.y, myCmd.z
				else
					x, y, z = spGetUnitPosition(myCmd.target)
				end
				local newCmd = {x=x, y=y, z=z}
				if spIsSphereInView(x, y, z, 100) then
					if cmd == CMD_REPAIR then
						stRepList[#stRepList+1] = newCmd
					elseif cmd == CMD_RECLAIM then
						stRecList[#stRecList+1] = newCmd
					else
						-- skip assigning x, y, z since res only targets features, which don't move
						stResList[#stResList+1] = newCmd
					end
				end
			end
		end
	end
end

local function DrawOutline(cmd,x,y,z,h)
	local ud = UnitDefs[cmd]
	local baseX = ud.xsize * 4 -- ud.buildingDecalSizeX
	local baseZ = ud.zsize * 4 -- ud.buildingDecalSizeY
	if (h == 1 or h==3) then
		baseX,baseZ = baseZ,baseX
	end
	glVertex(x-baseX,y,z-baseZ)
	glVertex(x-baseX,y,z+baseZ)
	glVertex(x+baseX,y,z+baseZ)
	glVertex(x+baseX,y,z-baseZ)
	glVertex(x-baseX,y,z-baseZ)
end

local function DrawBuildLines()
	for _,cmd in pairs(buildList) do -- draw outlines for building jobs
		--local cmd = buildList[i]
		local x, y, z, h = cmd.x, cmd.y, cmd.z, cmd.h
		local bcmd = abs(cmd.id)
		glBeginEnd(GL_LINE_STRIP, DrawOutline, bcmd, x, y, z, h)
	end
end

local function DrawAreaLines()
	for _,cmd in pairs(areaList) do -- draw circles for area repair/reclaim/resurrect jobs
		--local cmd = areaList[i]
		local x, y, z, r = cmd.x, cmd.y, cmd.z, cmd.r
		if cmd.id == CMD_REPAIR then
			glColor(rep_color)
		elseif cmd.id == CMD_RECLAIM then
			glColor(rec_color)
		else
			glColor(res_color)
		end
		glGroundCircle(x, y, z, r, 32)
	end
end

local function DrawBuildingGhosts(myTeamID)
	for _,myCmd in pairs(buildList) do -- draw building "ghosts"
		--local myCmd = buildList[i]
		local bcmd = abs(myCmd.id)
		local x, y, z, h = myCmd.x, myCmd.y, myCmd.z, myCmd.h
		local degrees = h * 90
		glPushMatrix()
		glLoadIdentity()
		glTranslate(x, y, z)
		glRotate(degrees, 0, 1.0, 0 )
		glUnitShape(bcmd, myTeamID, false, false, false)
		glPopMatrix()
	end
end

local function DrawAreaIcons()
	for i=1, #areaList do -- draw area command icons
		local myCmd = areaList[i]
		local x, y, z = myCmd.x, myCmd.y, myCmd.z
		glPushMatrix()
		if myCmd.id == CMD_REPAIR then
			glTexture(rep_icon)
		elseif myCmd.id == CMD_RECLAIM then
			glTexture(rec_icon)
		else
			glTexture(res_icon)
		end
		glRotate(0, 0, 1.0, 0)
		glTranslate(x-75, y, z+75)
		glBillboard()
		glTexRect(0, 0, 150, 150)
		glPopMatrix()
	end
end

local function DrawSTIcons(myList)
	for i=1, #myList do -- draw single-target command icons
		local myCmd = myList[i]
		local x, y, z = myCmd.x, myCmd.y, myCmd.z
		glPushMatrix()
		glRotate(0, 0, 1.0, 0)
		glTranslate(x-33, y, z+33)
		glBillboard()
		glTexRect(0, 0, 66, 66)
		glPopMatrix()
	end
end

-- Draw area command circles, building outlines and other ground decals
function RenderPreUnit()
	local alt, ctrl, meta, shift = spGetModKeyState()

	if shift or options.alwaysShow.value then
		glColor(1.0, 0.5, 0.1, 1) -- building outline color
		glLineWidth(1)

		DrawBuildLines() -- draw building outlines

		if shift and options.alwaysShow.value then
			glLineWidth(4)
		else
			glLineWidth(2)
		end

		DrawAreaLines() -- draw circles for area repair/reclaim/res
	end
	glColor(1, 1, 1, 1)
	glLineWidth(1)
end

function RenderWorld(myTeamID)
	local alt, ctrl, meta, shift = spGetModKeyState()

	if shift or options.alwaysShow.value then
		if shift and options.alwaysShow.value then
			glColor(1, 1, 1, 0.5) -- 0.5 alpha
		else
			glColor(1, 1, 1, 0.35) -- 0.35 alpha
		end

		glDepthTest(true)
		DrawBuildingGhosts(myTeamID) -- draw building ghosts
		glDepthTest(false)

		glTexture(true)
		if shift and options.alwaysShow.value then -- increase the opacity of command icons when shift is held
			glColor(1, 1, 1, 0.8)
		else
			glColor(1, 1, 1, 0.6)
		end

		DrawAreaIcons() -- draw icons for area commands

		if shift and options.alwaysShow.value then -- increase the opacity of command icons when shift is held
			glColor(1, 1, 1, 0.7)
		else
			glColor(1, 1, 1, 0.4)
		end

		-- draw icons for single-target commands
		if not (options.autoRepair.value and not shift) then -- don't draw repair icons if autorepair is enabled, unless shift is held
			glTexture(rep_icon)
			DrawSTIcons(stRepList)
		end

		glTexture(rec_icon)
		DrawSTIcons(stRecList)

		glTexture(res_icon)
		DrawSTIcons(stResList)
	end

	glTexture(false)
	glColor(1, 1, 1, 1)
end

function RenderCleanupUnit(unitID)
	WG.icons.SetUnitIcon(unitID, no_icon)
	WG.icons.SetUnitIcon(unitID, noidle_icon)
end
