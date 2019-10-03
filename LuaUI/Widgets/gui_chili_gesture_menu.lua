--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--[[ This widget is actually independent of chilli. Chilli is not needed for it's use. All you need to use this are of course this file, and the config files named "marking_" in luaui/config -Forboding Angel]]--

function widget:GetInfo()
  return {
    name      = "Chili Gesture Menu",
    desc      = "Hold right mouse + move or press B to use",
    author    = "Licho",
    date      = "2009-not as hot as before",
    license   = "GNU GPL, v2 or later",
    layer     = 100000,
    enabled   = false,
    handler   = true,
  }
end

include("keysym.h.lua")
VFS.Include("LuaRules/Configs/customcmds.h.lua")
-------------------------------------------------
------ SPEEDUPS
-------------------------------------------------
local osclock	= os.clock

local GL_LINE_STRIP		= GL.LINE_STRIP
local glVertex			= gl.Vertex
local glLineStipple 	= gl.LineStipple
local glLineWidth   	= gl.LineWidth
local glColor       	= gl.Color
local glBeginEnd    	= gl.BeginEnd
local glPushMatrix		= gl.PushMatrix
local glPopMatrix		= gl.PopMatrix
local glScale			= gl.Scale
local glTranslate		= gl.Translate
local glRect = gl.Rect
local glLoadIdentity	= gl.LoadIdentity
local tinsert = table.insert

local spEcho				= Spring.Echo

------------------------------------------------
-- constst


local CMD_BUILD_STRUCTURE = 10010
local ANGLE_TOLERANCE = 22.5

local MINDIST
local BIG_ICON_SIZE
local MOVE_THRESHOLD_SQUARED
local IDLE_THRESHOLD
local SMALL_ICON_SIZE
local KEYBOARD_ONLY
local KEYBOARD_OPEN_ONLY
local ALLOW_MULTIPLE

local mouselessOpen = false

local keyconfig = include("Configs/marking_menu_keys.lua")
local keys = keyconfig.qwerty.keys
local keys_display = keyconfig.qwerty.keys_display

local function OptionsChanged()
	MINDIST = options.iconDistance.value
	SMALL_ICON_SIZE = options.iconSize.value
	BIG_ICON_SIZE = options.selectedIconSize.value
	MOVE_THRESHOLD_SQUARED = options.mouseMoveThreshold.value
	IDLE_THRESHOLD = options.mouseIdleThreshold.value
	KEYBOARD_ONLY = options.keyboardOnly.value
	KEYBOARD_OPEN_ONLY = options.onlyOpenWithKeyboard.value
	ALLOW_MULTIPLE = options.allowMultiple.value
	
	if options.alternateconfig.value then
		keys = keyconfig.qwerty_d.keys
		keys_display = keyconfig.qwerty_d.keys_display
	elseif options.qwertz.value then
		keys = keyconfig.qwertz.keys
		keys_display = keyconfig.qwertz.keys_display
	else
		keys = keyconfig.qwerty.keys
		keys_display = keyconfig.qwerty.keys_display
	end
end

options_path = 'Settings/Interface/Gesture Menu'
options_order = { 'markingmenu', 'iconDistance', 'iconSize', 'selectedIconSize', 'mouseMoveThreshold', 'mouseIdleThreshold', 'keyboardOnly', 'onlyOpenWithKeyboard', "qwertz", 'alternateconfig', 'allowMultiple'}
options = {
	markingmenu = {
		name = "Open Menu (set a hotkey ->)",
		type = 'button',
		--OnChange defined later
	},
	
	iconDistance = {
		name = "Icon distance (20-150)",
		type = 'number',
		value = 50,
		min=20,max=150,step=1,
		OnChange = OptionsChanged,
	},
	
	iconSize = {
		name = "Icon size (10-100)",
		type = 'number',
		value = 20,
		min=10,max=100,step=1,
		OnChange = OptionsChanged,
	},
	
	selectedIconSize = {
		name = "Selected icon size (10-100)",
		type = 'number',
		value = 32,
		min=10,max=100,step=1,
		OnChange = OptionsChanged,
	},
	
	mouseMoveThreshold = {
		name = "Mouse move threshold (10-2000)",
		type = 'number',
		value = 900,
		min=10,max=1000,step=1,
		desc = "When you hold right button, you must move this distance(squared) to show menu",
		OnChange = OptionsChanged,
	},
	
	mouseIdleThreshold = {
		name = "Mouse idle threshold (0.1-3s)",
		type = 'number',
		value = 1,
		min=0.1,max=3,step=0.1,
		desc = "When you hold right button still, menu appears after this time(s)",
		OnChange = OptionsChanged,
	},
	
	keyboardOnly = {
		name = 'Keyboard only',
		type = 'bool',
		value = false,
		desc = 'Disables gesture recognition',
		OnChange = OptionsChanged,
	},
	
	onlyOpenWithKeyboard = {
		name = 'Only open with keyboard',
		type = 'bool',
		value = false,
		desc = 'Disables right click drag to open',
		OnChange = OptionsChanged,
	},

	qwertz = {
		name = "qwertz keyboard",
		type = "bool",
		value = false,
		desc = "keys for qwertz keyboard",
		OnChange = OptionsChanged,
	},
	
	alternateconfig = {
		name = "Alternate Keyboard Layout",
		type = "bool",
		value = false,
		desc = "Centre hotkeys around D instead of S.",
		OnChange = OptionsChanged,
	},
	
	allowMultiple = {
		name = "Allow for multiple selected units",
		type = "bool",
		value = true,
		desc = "Allows gestures even for multiple units selected",
		OnChange = OptionsChanged,
	},
	
}

local mapWidth, mapHeight = Game.mapSizeX, Game.mapSizeZ

------------------------------------------------
local average_difference = 0 -- average movement speed/difference
local ignored_angle = nil -- angle to currently ignore in menu

local origin = nil
local selected_item = nil

local menu = nil -- nil indicates no menu is visible atm
local menu_selected = nil -- currently selected item - used in last level menus where you can select without changing origin
local menu_invisible = false  -- indicates if menu should be active but invisible (for right hold click)
local menu_start = 0 -- time when the menu was started

local menu_keymode = false -- was menu opened using keyboard


-- remember the walk through the menu, to be able to go back
local level = 0
local levels = {}

local move_digested = nil -- was move command digested (hold right click detection)

local customKeyBind = false

local menu_use = include("Configs/marking_menu_menus.lua")

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

local function CanInitialQueue()
  return WG.InitialQueue~=nil and not (Spring.GetGameFrame() > 0)
end


function widget:Update(t)
  if not menu or KEYBOARD_ONLY or mouselessOpen then return end
  local mx, my = Spring.GetMouseState()
  ProcessMove(mx,my)
  if hold_pos then
    local dx = mx - hold_pos[1]
    local dy = my - hold_pos[2]
    if dx*dx + dy*dy > MOVE_THRESHOLD_SQUARED  or os.clock() - menu_start > IDLE_THRESHOLD then
      menu_invisible = false
      hold_pos = nil
    end
  end
end

local lx = 0
local ly = 0


function ProcessMove(x,y)
  if (menu == nil or KEYBOARD_ONLY or mouselessOpen) then return end
  local dx = x - lx
  local dy = y - ly
  diff =  math.sqrt(dx*dx + dy*dy)
  lx = x
  ly = y

  
  if diff < average_difference * 0.5 then  -- we are slowed down, this is a spot where we check stuff in detail
    
    local angle = GetAngle(x,y, origin[1],origin[2])
    local dist = GetDist(x,y,origin[1],origin[2])
    if (ignored_angle == nil or AngleDifference(angle,ignored_angle) > ANGLE_TOLERANCE) and  dist > MINDIST then
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
            
            if level > 0 then  --  incorrect angle is angle of previous level (to which we are going). If there is none we are in initial state and all angles are valid
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
            origin  = {nx,ny}
          end
          menu_selected = item
        end
      else
        -- spEcho("no item"..angle) FIXME?
      end
    else
      if (dist < MINDIST) then
        menu_selected = menu
      elseif diff > 0 then -- we moved and slowed a bit, so move menu to new position
        origin = {x,y}
      end
    end
  end
  average_difference = average_difference*0.8+  0.2*diff -- geometric averaging
end



-- setups menu for selected unit
function SetupMenu(keyboard, mouseless)
  menu_keymode = keyboard
  mouselessOpen = mouseless

  local units = Spring.GetSelectedUnits()
  local initialQueue = CanInitialQueue()
  local allow = (units and (#units == 1 or (#units > 0 and (ALLOW_MULTIPLE or keyboard))) ) or initialQueue

  -- only show menu if a unit is selected
  if allow then
    origin = {Spring.GetMouseState()} -- origin might by set by mouse hold detection so we only set it if unset
    
    local found = false
    for _, unitID in ipairs(units) do
      local ud = UnitDefs[Spring.GetUnitDefID(unitID)]
      if ud then
	    if ud.isBuilder and menu_use[ud.name] then
		  found = ud
	    elseif ud.canMove and not keyboard then
		  menu = nil
          menu_selected=  nil
          return false
        end
	  else
		return false
	  end
    end

    -- setup menu depending on selected unit
    if found or initialQueue then
      levels = {}
      level =0
      menu_flash = nil -- erase previous flashing
      menu = found and menu_use[found.name] or menu_use["armcom1"]
      menu_selected = menu
      menu_start = os.clock()
    else
      menu = nil
      menu_selected=  nil
      return false
    end

    return true

  end
end


function EndMenu(ok)
  if (not ok) then
		menu_selected = nil
   end
  local initialQueue = CanInitialQueue()
 
  if menu_selected~=nil and menu_selected.unit ~= nil then
    local cmdid = menu_selected.cmd
    if (cmdid == nil) then
      local ud = UnitDefNames[menu_selected.unit]
      if (ud ~= nil) then
        cmdid = Spring.GetCmdDescIndex(-ud.id)
      end
    end
    if (cmdid) then
      local alt, ctrl, meta, shift = Spring.GetModKeyState()
      local _, _, left, _, right = Spring.GetMouseState()
        
      if (menu ~= menu_selected) then -- store last item and level to render its back path
        level = level + 1  -- save level
        levels[level] = {menu_selected, menu_selected.angle+180}
      end
      if os.clock() - menu_start > level * 0.25 then  -- if speed was slower than 250ms per level, flash the gesture
        menu_flash = {origin[1], origin[2], os.clock()}
      end
      Spring.SetActiveCommand(cmdid, 1, left, right, alt, ctrl, meta, shift)  -- FIXME set only when you close menu
    end
  end
  origin = nil
  menu = nil
  menu_selected = nil
  ignored_angle = nil
  hold_pos = nil
  menu_invisible = false
  menu_keymode = false
end

-- note we dont want menu to show on command thats why we return

function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
  if cmdID ~= CMD_BUILD_STRUCTURE then
    return
  end
  if menu == nil then
	local x,y = Spring.GetWindowGeometry()
	Spring.WarpMouse(x/2, y/2)
    return SetupMenu(true)
  else
    EndMenu(false)
    return true
  end
end


function widget:KeyPress(k)
	if (menu) then
		if k == KEYSYMS.ESCAPE then  -- cancel menu
			EndMenu(false)
			return true
		end
		local angle = keys[k]
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
				if (item.items ~= nil)  then -- item has subitems
					level = level + 1  -- save level
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
							ignored_angle = levels[level][2]  + 180
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


function widget:MousePress(x, y, button)
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
				local activeCmdIndex, activeid = Spring.GetActiveCommand()
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


function widget:MouseRelease(x,y,button)
	if button ~= 3 then return end
	if move_digested and (menu_invisible) then  -- we digested command, but menu not displayed, issue standard move command
	
		local activeCmdIndex, activeid = Spring.GetActiveCommand()
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
			if alt   then keyState.alt   = true; keyState.coded = keyState.coded + CMD.OPT_ALT   end
			if ctrl  then keyState.ctrl  = true; keyState.coded = keyState.coded + CMD.OPT_CTRL  end
			if meta  then keyState.meta  = true; keyState.coded = keyState.coded + CMD.OPT_META  end
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


function widget:IsAbove(x,y)
  if (menu ~= nil) then return true
  else return false end
end


function widget:GetTooltip(x, y)
  if menu_selected ~= nil and menu_selected.unit ~= nil then
    local ud = UnitDefNames[menu_selected.unit]
    if (ud) then
      return 'Build: ' ..ud.humanName .. ' - ' .. ud.tooltip
    end
  end
end

local function BackPathFunc(origin, len)
  local sx,sy = unpack(origin)
  glVertex(sx,sy)
  for i=level,1,-1 do
    local menu,angle = unpack(levels[i])
    sx,sy= GetPos(sx,sy, angle, len)
    glVertex(sx,sy)
  end
end


local function DrawMenuItem(item, x,y, size, alpha, displayLabel, angle, cmdDesc)
  if not alpha then alpha = 1 end
  if displayLabel == nil then displayLabel = true end
  if item then
    local ud = UnitDefNames[item.unit]
	if (ud)  then
      if (displayLabel and item.label) then
        glColor(1,1,1,alpha)
        local wid = gl.GetTextWidth(item.label)*12
        gl.Text(item.label,x-wid*0.5, y+size,12,"")
      end

	  local isEnabled = CanInitialQueue()
	  if not isEnabled then
		  for _, desc in ipairs(cmdDesc) do
			if desc.id == -ud.id and not desc.disabled then
				isEnabled = true
				break
			end
		  end
	  end
	  
	  if isEnabled then
		glColor(1*alpha,1*alpha,1,alpha)
	  else glColor(0.3,0.3,0.3,alpha) end
      gl.Texture(WG.GetBuildIconFrame(ud))
      gl.TexRect(x-size, y-size, x+size, y+size)
      gl.Texture("#"..ud.id)
      gl.TexRect(x-size, y-size, x+size, y+size)
      gl.Texture(false)

	  if (ud.metalCost) then
		--gl.Color(1,1,1,alpha)
		gl.Text(ud.metalCost .. " m",x-size+4,y-size + 4,10,"")
	  end

	  if angle then
		if angle < 0 then angle = angle + 360 end
		local idx = angle / 45
		gl.Color(0,1,0,1)
		gl.Text(keys_display[1 + idx%8],x-size+4,y+size-10,10,"")
	  end
    end
  end
  
end



function widget:DrawScreen()

  if menu_flash then
    -- render back path
    gl.Texture(false)
    glColor(1,1,1,0.5 + 0.5 * math.sin(os.clock()*30))
    gl.LineWidth(2)
    gl.BeginEnd(GL_LINE_STRIP, BackPathFunc, menu_flash, MINDIST*3)
    
    local sx,sy = unpack(menu_flash)
    for i=level,1,-1 do
      local menu,angle = unpack(levels[i])
      sx,sy= GetPos(sx,sy, angle, MINDIST*3)
    end
    gl.Rect(sx-5,sy-5,sx+5,sy+5)

    if (os.clock() - menu_flash[3]>1) then  -- only flash for 3 seconds
      menu_flash = nil
    end
  end

  if (menu == nil or menu_invisible) then return end  -- get out if menu not visible

  
  cmdDesc = Spring.GetActiveCmdDescs()
  
  -- render back path
  gl.Texture(false)
  glColor(0,0,0,1)
  local sx,sy = unpack(origin)
  gl.BeginEnd(GL_LINE_STRIP, BackPathFunc, origin, MINDIST+SMALL_ICON_SIZE)
  for i=level,1,-1 do
    local menu,angle = unpack(levels[i])
    sx,sy= GetPos(sx,sy, angle, MINDIST+SMALL_ICON_SIZE)
    DrawMenuItem(menu, sx,sy, SMALL_ICON_SIZE, 0.5, true, angle, cmdDesc)
    glColor(0,0,0,1)
    gl.Rect(sx-4,sy-4,sx+4,sy+4)
    glColor(1,1,1,1)
    gl.Rect(sx-3,sy-3,sx+3,sy+3)
  end

  glColor(0,0,0,1)
  glRect(origin[1]-3,origin[2]-3,origin[1]+3, origin[2] + 3)
  glColor(1,1,1,1)
  glRect(origin[1]-2,origin[2]-2,origin[1]+2, origin[2] + 2)

  glColor(1,1,1,1)
  if (menu == menu_selected) then
    DrawMenuItem(menu, origin[1], origin[2], BIG_ICON_SIZE, 1, false, menu.angle, cmdDesc)
  else
    DrawMenuItem(menu, origin[1], origin[2], SMALL_ICON_SIZE, 0.8, true, menu.angle, cmdDesc)
  end
  

  if (menu.items) then
    for _,i in ipairs(menu.items) do
      local x,y = GetPos(origin[1], origin[2], i.angle, MINDIST + SMALL_ICON_SIZE)
      
      if (i == menu_selected) then
        DrawMenuItem(i, x,y, BIG_ICON_SIZE, 1, true, i.angle, cmdDesc)
      else
        DrawMenuItem(i, x,y, SMALL_ICON_SIZE, 0.8, true, i.angle, cmdDesc)
      end
    end
  end
  glColor(1,1,1,1)
end

function widget:Initialize()

	OptionsChanged()

  -- adding functions because of "handler=true"
  widgetHandler.AddAction    = function (_, cmd, func, data, types)
    return widgetHandler.actionHandler:AddAction(widget, cmd, func, data, types)
  end
  widgetHandler.RemoveAction = function (_, cmd, types)
    return widgetHandler.actionHandler:RemoveAction(widget, cmd, types)
  end

  widgetHandler:AddAction("keyboardmarkingmenu", MouselessActionMenu, nil, "t")

end

function widget:Shutdown()
  widgetHandler:RemoveAction("keyboardmarkingmenu")
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

options.markingmenu.OnChange = ActionMenu

function MouselessActionMenu()
  if menu == nil then
    SetupMenu(true, true)
  else
    EndMenu(false)
  end
end

function widget:CommandsChanged()
--[[ COMMANDS DISABLED

	local selectedUnits = Spring.GetSelectedUnits()
	local customCommands = widgetHandler.customCommands
	local foundBuilder = false
    
  for _, unitID in ipairs(selectedUnits) do
		local unitDefID = Spring.GetUnitDefID(unitID)
			
    if UnitDefs[unitDefID].isBuilder then
      foundBuilder = true
      break
    end
  end

  if foundBuilder then
    table.insert(customCommands, {
      id      = CMD_BUILD_STRUCTURE,
      type    = CMDTYPE.ICON,
      tooltip = 'Hold \255\10\240\240right mouse button + move \255\255\255\255 mouse, or hit \255\10\240\240B',
      name = "Build",
      cursor  = 'Build',
      action  = '',
      params  = { },
      pos = {CMD_ONOFF,CMD_REPEAT,CMD_MOVE_STATE,CMD_FIRE_STATE},
    })
  end
]]--
end
