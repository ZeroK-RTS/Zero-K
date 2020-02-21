function widget:GetInfo()
	return {
		name      = "Gesture Menu API",
		desc      = "Common code for Gesture Menus",
		author    = "Licho, esainane",
		date      = "2009-2020",
		license   = "GNU GPL, v2 or later",
		layer     = 100000,
		enabled   = false,
		handler   = true,
	}
end

include("keysym.lua")
VFS.Include("LuaRules/Configs/customcmds.h.lua")

------ SPEEDUPS

local osclock         = os.clock

local GL_LINE_STRIP   = GL.LINE_STRIP
local glTexture       = gl.Texture
local glVertex        = gl.Vertex
local glLineWidth     = gl.LineWidth
local glColor         = gl.Color
local glBeginEnd      = gl.BeginEnd
local glRect          = gl.Rect

local spEcho          = Spring.Echo

-- consts

local ANGLE_TOLERANCE = 22.5

local MOVE_THRESHOLD_SQUARED
local IDLE_THRESHOLD

local mouselessOpen = false

-- options common to all gesture menus

local function OptionsChanged()
	MOVE_THRESHOLD_SQUARED = options.mouseMoveThreshold.value
	IDLE_THRESHOLD = options.mouseIdleThreshold.value
end

options_path = 'Settings/Interface/Gesture Menus'
options_order = { 'mouseMoveThreshold', 'mouseIdleThreshold' }
options = {

	mouseMoveThreshold = {
		name = "Mouse move threshold (10-2000)",
		type = 'number',
		value = 1000,
		min=10,max=2000,step=1,
		desc = "When you hold right button, you must move this distance(squared) to show menu",
		OnChange = OptionsChanged,
	},

	mouseIdleThreshold = {
		name = "Mouse idle threshold (0.1-3s)",
		type = 'number',
		value = 0.4,
		min=0.1,max=3,step=0.1,
		desc = "When you hold right button still, menu appears after this time(s)",
		OnChange = OptionsChanged,
	},

}

local mapWidth, mapHeight = Game.mapSizeX, Game.mapSizeZ

function WG.CreateGestureMenu(
	GetMenuDefinition,
	DrawMenuItem,
	PerformAction,
	PreDrawMenuItems,
	KeyToAngle
)

local MINDIST
local BIG_ICON_SIZE
local SMALL_ICON_SIZE
local KEYBOARD_ONLY
local KEYBOARD_OPEN_ONLY

local instance_options

local function InstanceOptionsChanged()
	MINDIST = instance_options.iconDistance.value
	SMALL_ICON_SIZE = instance_options.iconSize.value
	BIG_ICON_SIZE = instance_options.selectedIconSize.value
	KEYBOARD_ONLY = instance_options.keyboardOnly.value
	KEYBOARD_OPEN_ONLY = instance_options.onlyOpenWithKeyboard.value
end

local instance_options_order = { 'markingmenu', 'iconDistance', 'iconSize', 'selectedIconSize', 'keyboardOnly', 'onlyOpenWithKeyboard' }
instance_options = {
	markingmenu = {
		name = "Open Menu (set a hotkey ->)",
		type = 'button',
		--OnChange defined later
	},
	iconDistance = {
		name = "Icon distance (20-360)",
		type = 'number',
		value = 50,
		min=20,max=360,step=10,
		OnChange = InstanceOptionsChanged,
	},

	iconSize = {
		name = "Icon size (10-100)",
		type = 'number',
		value = 20,
		min=10,max=100,step=1,
		OnChange = InstanceOptionsChanged,
	},

	selectedIconSize = {
		name = "Selected icon size (10-100)",
		type = 'number',
		value = 32,
		min=10,max=100,step=1,
		OnChange = InstanceOptionsChanged,
	},

	keyboardOnly = {
		name = 'Keyboard only',
		type = 'bool',
		value = false,
		desc = 'Disables gesture recognition',
		OnChange = InstanceOptionsChanged,
	},

	-- TODO: This should ideally be a radio menu with a list of gesture menu instances on the top level menu
	-- (opening multiple at once with right click drag is probably not sane)
	onlyOpenWithKeyboard = {
		name = 'Only open with keyboard',
		type = 'bool',
		value = true,
		desc = 'Disables right click drag to open',
		OnChange = InstanceOptionsChanged,
	},
}

------------------------------------------------
local average_difference = 0 -- average movement speed/difference
local ignored_angle = nil -- angle to currently ignore in menu

local origin = nil
local initialWorldOrigin

local menu = nil -- nil indicates no menu is visible atm
local menu_selected = nil -- currently selected item - used in last level menus where you can select without changing origin
local menu_invisible = false  -- indicates if menu should be active but invisible (for right hold click)
local menu_start = 0 -- time when the menu was started

local menu_flash
local hold_pos


-- remember the walk through the menu, to be able to go back
local level = 0
local levels = {}

local move_digested = nil -- was move command digested (hold right click detection)

local function GetAngle(x1,y1,x2,y2)
	return 180 * math.atan2(x1-x2,y1-y2) / math.pi
end

local function GetPos(x1,y1,angle,dist)
	local a = angle * math.pi/180
	return x1 + math.sin(a) * dist, y1 + math.cos(a)*dist
end

local function GetDist(x1,y1,x2,y2)
	local dx = x2 - x1
	local dy = y2 - y1
	return math.sqrt(dx*dx+dy*dy)
end

local function AngleDifference(a1,a2)
	return math.abs((a1 + 180 - a2) % 360 - 180)
end

local lx = 0
local ly = 0


local function ProcessMove(x,y)
	if (menu == nil or KEYBOARD_ONLY or mouselessOpen) then return end
	local dx = x - lx
	local dy = y - ly
	local diff = math.sqrt(dx*dx + dy*dy)
	lx = x
	ly = y


	if diff < average_difference * 0.5 then  -- we are slowed down, this is a spot where we check stuff in detail

		local angle = GetAngle(x,y, origin[1],origin[2])
		local dist = GetDist(x,y,origin[1],origin[2])
		if (ignored_angle == nil or AngleDifference(angle,ignored_angle) > ANGLE_TOLERANCE) and dist > MINDIST then
			local item = nil
			if (menu.items) then
				for _,i in ipairs(menu.items) do
					if (AngleDifference(i.angle,angle) < ANGLE_TOLERANCE) then
						item = i
						break
					end
				end
			end
			if (item == nil) then  -- "back" in menu
				if level > 0 then
					local l_menu, l_angle = unpack(levels[level])
					if (AngleDifference(l_angle, angle)< ANGLE_TOLERANCE) then
						levels[level] = nil
						level = level - 1
						menu = l_menu
						menu_selected = menu

						if level > 0 then  --    incorrect angle is angle of previous level (to which we are going). If there is none we are in initial state and all angles are valid
							ignored_angle = levels[level][2]  + 180
						else
							ignored_angle = nil
						end
						origin = {x,y}
					end
				end
			end
			if (item ~= nil) then

				if (item.items ~= nil)  then -- item has subitems

					level = level + 1  -- save level
					levels[level] = {menu, item.angle+180}

					ignored_angle = item.angle
					menu = item
					menu_selected = item

					origin = {x,y}
				else

					if (dist > MINDIST + 2*BIG_ICON_SIZE) then
						local nx,ny = GetPos(x,y, item.angle - 180, MINDIST)
						origin = {nx,ny}
					end
					menu_selected = item
				end
			else
				-- spEcho("no item"..angle) -- FIXME?
			end
		else
			if (dist < MINDIST) then
				menu_selected = menu
			elseif diff > 0 then -- we moved and slowed a bit, so move menu to new position
				origin = {x,y}
			end
		end
	end
	average_difference = average_difference*0.8+ 0.2*diff -- geometric averaging
end

local function Update(self, t)
	if not menu or KEYBOARD_ONLY or mouselessOpen then return end
	local mx, my = Spring.GetMouseState()
	ProcessMove(mx,my)
	if hold_pos then
		local dx = mx - hold_pos[1]
		local dy = my - hold_pos[2]
		if dx*dx + dy*dy > MOVE_THRESHOLD_SQUARED or osclock() - menu_start > IDLE_THRESHOLD then
			menu_invisible = false
			hold_pos = nil
		end
	end
end

-- setups menu for selected unit
local function SetupMenu(keyboard, mouseless)
	mouselessOpen = mouseless

	-- origin might by set by mouse hold detection so we only set it if unset
	local mouse_pos = {Spring.GetMouseState()}
	local _,world_pos = Spring.TraceScreenRay(mouse_pos[1], mouse_pos[2], true)

	local menu_use = GetMenuDefinition(keyboard, mouse_pos, world_pos)
	if menu_use == nil then
		menu = nil
		menu_selected = nil
		return false
	end

	levels = {}
	level = 0
	menu_flash = nil -- erase previous flashing
	menu = menu_use
	menu_selected = menu
	menu_start = osclock()
	origin = mouse_pos
	initialWorldOrigin = world_pos
	return true
end


local function EndMenu(ok)
	if (not ok) then
		menu_selected = nil
	end

	if menu_selected~=nil then
		local data = menu_selected
		if PerformAction(data, initialWorldOrigin) then
			if (menu ~= menu_selected) then -- store last item and level to render its back path
				level = level + 1  -- save level
				levels[level] = {menu_selected, menu_selected.angle+180}
			end
			if osclock() - menu_start > level * 0.25 then  -- if speed was slower than 250ms per level, flash the gesture
				local fx,fy = origin[1], origin[2]
				if menu ~= menu_selected then
					fx,fy = GetPos(fx, fy, menu_selected.angle, MINDIST)
				end
				menu_flash = {fx, fy, osclock()}
			end
		end
	end
	origin = nil
	menu = nil
	menu_selected = nil
	ignored_angle = nil
	hold_pos = nil
	menu_invisible = false
end


local function KeyPress(self, k)
	if (menu) then
		if k == KEYSYMS.ESCAPE then  -- cancel menu
			EndMenu(false)
			return true
		end
		local angle
		if KeyToAngle then
			angle = KeyToAngle(k)
		end
		if angle == nil then return end
		menu_invisible = false -- if menu was activated with mouse but isnt visible yet,show it now
		if (menu.items) then
			local item = nil

			for _,i in ipairs(menu.items) do
				if (AngleDifference(i.angle,angle) < ANGLE_TOLERANCE) then
					item = i
					break
				end
			end

			if item ~= nil then
				if (item.items ~= nil) then -- item has subitems
					level = level + 1 -- save level
					levels[level] = {menu, item.angle+180}

					ignored_angle = item.angle
					menu = item
					menu_selected = item
				else
					menu_selected = item
					EndMenu(true)
				end
			else
				if menu.angle and (AngleDifference(menu.angle, angle) < ANGLE_TOLERANCE) then  -- we selected "same" item  - like mex = "w,w" - end selection
					menu_selected = menu
					EndMenu(true)
				elseif (level > 0) then  -- we are moving back possibly
					local l_menu, l_angle = unpack(levels[level])
					if (AngleDifference(l_angle, angle)< ANGLE_TOLERANCE) then
						levels[level] = nil
						level = level - 1
						menu = l_menu
						menu_selected = menu

						if level > 0 then  --  incorrect angle is angle of previous level (to which we are going). If there is none we are in initial state and all angles are valid
							ignored_angle = levels[level][2] + 180
						else
							ignored_angle = nil
						end
					end
				end
			end
			return true
		end
	end
end


local function MousePress(self, x, y, button)
	if menu then
		if (button == 3) then
			EndMenu(false) -- cancel after keyboard menu open
		elseif (button == 1 ) then  -- selection with lmb from keyboard menu
			EndMenu(true)
			return true
		end
	elseif (menu == nil) and not KEYBOARD_OPEN_ONLY then
		if (button == 3) then
			local map = WG.MinimapPositionSpringSpace
			if (not map) or x < map[1] or x > map[1] + map[3] or y < map[2] or y > map[2] + map[4] then
				local _, activeid = Spring.GetActiveCommand()
				local _, defid = Spring.GetDefaultCommand()
				if ((activeid == nil or activeid < 0) and (defid == CMD.MOVE or defid == CMD_RAW_MOVE or not defid)) then -- nano turrets have no CMD.MOVE active command
					if SetupMenu(false) then
						menu_invisible = true
						move_digested = true
						hold_pos = {x,y}
						return true
					end
				end
			end
		end
	end
	return false
end


local function MinimapMouseToWorld(mx, my)

	local _, posy, sizex, sizey = Spring.GetMiniMapGeometry()
	local rx, ry

	-- FIXME: This does not work and has not worked for a long time
	if dualMinimapOnLeft then
		rx, ry = (mx + sizex) / sizex, (my - posy) / sizey
	else
		rx, ry = mx / sizex, (my - posy) / sizey
	end

	if (rx >= 0) and (rx <= 1) and
		 (ry >= 0) and (ry <= 1) then

		local mapx, mapz = mapWidth * rx, mapHeight * (1 - ry)

		return {mapx, Spring.GetGroundHeight(mapx, mapz), mapz}
	else
		return nil
	end
end

local function GiveNotifyingOrder(cmdID, cmdParams, cmdOpts)
	if widgetHandler:CommandNotify(cmdID, cmdParams, cmdOpts) then
		return
	end
	if cmdParams then
		Spring.GiveOrder(cmdID, cmdParams, cmdOpts)
	end
end

local function GiveNotifyingInsertOrder(cmdID, cmdParams, cmdOpts)
	if widgetHandler:CommandNotify(cmdID, cmdParams, cmdOpts) then
		return
	end
	WG.CommandInsert(cmdID, cmdParams, cmdOpts)
end


local function MouseRelease(self,x,y,button)
	if button ~= 3 then return end
	if move_digested and (menu_invisible) then  -- we digested command, but menu not displayed, issue standard move command

		local _, activeid = Spring.GetActiveCommand()
		if (activeid ~= nil and activeid < 0) then  -- we already had unit selected and menu wasnt visible - cancel previous unit selection
			Spring.SetActiveCommand(0)
		else
			local inMinimap = Spring.IsAboveMiniMap(x, y)
			local pos

			if inMinimap then
				pos = MinimapMouseToWorld(x, y)
			else
				pos = select(2, Spring.TraceScreenRay(x, y, true))
			end
			if not pos then
				return
			end

			local alt, ctrl, meta, shift = Spring.GetModKeyState()
			local keyState = {coded = 0}
			if alt   then keyState.alt   = true; keyState.coded = keyState.coded + CMD.OPT_ALT end
			if ctrl  then keyState.ctrl  = true; keyState.coded = keyState.coded + CMD.OPT_CTRL end
			if meta  then keyState.meta  = true; keyState.coded = keyState.coded + CMD.OPT_META end
			if shift then keyState.shift = true; keyState.coded = keyState.coded + CMD.OPT_SHIFT end

			if meta and WG.CommandInsert then
				GiveNotifyingInsertOrder(CMD_RAW_MOVE, {pos[1], pos[2], pos[3]},keyState)
			else
				GiveNotifyingOrder(CMD_RAW_MOVE, {pos[1], pos[2], pos[3]}, keyState)
			end
		end
	end
	ProcessMove(Spring.GetMouseState())
	hold_pos = nil
	EndMenu(true)
end


local function IsAbove(self, x,y)
	if (menu ~= nil) then return true
	else return false end
end

local function BackPathFunc(prev, len)
	local sx,sy = unpack(prev)
	glVertex(sx,sy)
	for i=level,1,-1 do
		local _,angle = unpack(levels[i])
		sx,sy = GetPos(sx,sy, angle, len)
		glVertex(sx,sy)
	end
end

local function DrawScreen()

	if menu_flash then
		-- render back path
		glTexture(false)
		glColor(1,1,1,0.5 + 0.5 * math.sin(osclock()*30))
		glLineWidth(2)
		glBeginEnd(GL_LINE_STRIP, BackPathFunc, menu_flash, MINDIST)

		local sx,sy = unpack(menu_flash)
		for i=level,1,-1 do
			local _,angle = unpack(levels[i])
			sx,sy= GetPos(sx,sy, angle, MINDIST)
		end
		glRect(sx-5,sy-5,sx+5,sy+5)

		if (osclock() - menu_flash[3]>1) then  -- only flash for 3 seconds
			menu_flash = nil
		end
	end

	if (menu == nil or menu_invisible) then return end  -- get out if menu not visible


	local userdata
	if PreDrawMenuItems then
		userdata = PreDrawMenuItems()
	end

	-- render back path
	glTexture(false)
	glColor(0,0,0,1)
	local sx,sy = unpack(origin)
	glBeginEnd(GL_LINE_STRIP, BackPathFunc, origin, MINDIST+SMALL_ICON_SIZE)
	for i=level,1,-1 do
		local next_menu,angle = unpack(levels[i])
		sx,sy= GetPos(sx,sy, angle, MINDIST+SMALL_ICON_SIZE)
		DrawMenuItem(next_menu, sx,sy, SMALL_ICON_SIZE, 0.5, true, angle, userdata)
		glColor(0,0,0,1)
		glRect(sx-4,sy-4,sx+4,sy+4)
		glColor(1,1,1,1)
		glRect(sx-3,sy-3,sx+3,sy+3)
	end

	glColor(0,0,0,1)
	glRect(origin[1]-3,origin[2]-3,origin[1]+3, origin[2] + 3)
	glColor(1,1,1,1)
	glRect(origin[1]-2,origin[2]-2,origin[1]+2, origin[2] + 2)

	glColor(1,1,1,1)
	if (menu == menu_selected) then
		DrawMenuItem(menu, origin[1], origin[2], BIG_ICON_SIZE, 1, false, menu.angle, userdata)
	else
		DrawMenuItem(menu, origin[1], origin[2], SMALL_ICON_SIZE, 0.8, true, menu.angle, userdata)
	end


	if (menu.items) then
		for _,i in ipairs(menu.items) do
			local x,y = GetPos(origin[1], origin[2], i.angle, MINDIST + SMALL_ICON_SIZE)

			if (i == menu_selected) then
				DrawMenuItem(i, x,y, BIG_ICON_SIZE, 1, true, i.angle, userdata)
			else
				DrawMenuItem(i, x,y, SMALL_ICON_SIZE, 0.8, true, i.angle, userdata)
			end
		end
	end
	glColor(1,1,1,1)
end

function widget:Initialize()
	OptionsChanged()
end

local function ActionMenu()
	if menu == nil then
		local _ , activeid = Spring.GetActiveCommand()
		if (activeid == nil or activeid < 0) then
			return SetupMenu(true)
		end
	else
		EndMenu(false)
	end
end

instance_options.markingmenu.OnChange = ActionMenu

return instance_options, instance_options_order, Update, DrawScreen, KeyPress, MousePress, MouseRelease, IsAbove

end -- CreateGestureMenu
