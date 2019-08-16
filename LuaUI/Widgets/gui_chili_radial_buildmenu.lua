--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Radial Build Menu",
    desc      = "v0.093 Radial Build Menu",
    author    = "CarRepairer",
    date      = "2010-09-15",
    license   = "GNU GPL, v2 or later",
    layer     = 999,
    enabled   = false,
    handler = true,
  }
end

include("keysym.h.lua")

-------------------------------------------------

local echo				= Spring.Echo

------------------------------------------------
-- Chili
local Chili
local Button
local Window
local Grid
local Image
local Label

local window_menu
local grid_menu
local menu_visible = false
local orig_color = {1,1,1,0.2}
local build_color = {0.5,1,1,0.9}
local hide_color = {0,0,0,0}
local hotkey_labels = {}

------------------------------------------------
-- keys

local keyconfig = include("Configs/marking_menu_keys.lua")
local keys = keyconfig.qwerty_d.keys
local keys_display = keyconfig.qwerty_d.keys_display


------------------------------------------------
-- options

-- removed

------------------------------------------------

local selected_item = nil
local menu = nil
local menu_selected = nil
local level = 0
local customKeyBind = false
local menu_use = include("Configs/marking_menu_menus.lua")
local hotkey_mode = false
local green = '\255\1\255\1'
local white = '\255\255\255\255'

local builder_types = {}
local builder_types_i = {}
local builder_ids_i = {}
local curbuilder = 1

local last_cmdid

local function AngleToIndex(angle)
	angle=angle+0
	if angle < 0 then
		angle = angle + 360
	end
	local conv = {
		[0] 	= 2,
		[45] 	= 3,
		[90] 	= 6,
		[135] 	= 9,
		[180] 	= 8,
		[225] 	= 7,
		[270] 	= 4,
		[315] 	= 1,
	}
	return conv[angle]
end
local function IndexToAngle(index)
	local conv = {
		[2] = 0,
		[3] = 45,
		[6] = 90,
		[9] = 135,
		[8] = 180,
		[7] = 225,
		[4] = 270,
		[1] = 315,
	}
	return conv[index]
end

local UpdateMenu = function() end
local Make_KB_Menu = function() end

local advance_builder = false
local function NextBuilder()
	if advance_builder then
		curbuilder = curbuilder % #builder_types_i + 1
	end
end

local function HotKeyMode(enable)
	if enable then
		window_menu.color = build_color
		window_menu:Invalidate()
		hotkey_mode = true
		for i,v in ipairs(hotkey_labels) do
			v:SetCaption(green .. v.name)
		end
	else
		window_menu.color = menu_visible and orig_color or hide_color
		window_menu:Invalidate()
		hotkey_mode = false
		for i,v in ipairs(hotkey_labels) do
			v:SetCaption('')
		end
		hotkey_labels = {}
	end
end

local function AddBuildButton()
	local button1 = Button:New{
		name = 5,
		--caption = 'Buil'.. green ..'d',
		caption = '',
		tooltip = 'Click or press ' .. green .. 'D' .. white .. ' to activate build menu hotkeys.\n'
			.. 'Press ' .. green .. 'Space+D' .. white .. ' to build the last thing you built.' ,
		OnMouseUp = { Make_KB_Menu, },
		children = {
			Label:New{ caption = 'BUIL'.. green ..'D', fontSize=14, bottom='1', fontShadow = true, },
			Image:New {
				--file = 'LuaUI/Images/resbar/work.png', --ugly when scaled
				--file = 'LuaUI/Images/resbar/huge_m.png', --nice gear
				
				file = "#".. builder_ids_i[curbuilder],
				--file2 = WG.GetBuildIconFrame(ud),
				file2 = 'LuaUI/Images/nested_buildmenu/frame_Fac.png',
				
				width = '100%',
				height = '80%',
			},
			
		},
	}
	
	grid_menu:AddChild(button1)
end

local function AddButton(item, index)
	if not item then
		grid_menu:AddChild(Label:New{caption=''})
		return
	end
	
	local ud = UnitDefNames[item.unit]
    if not ud then
		grid_menu:AddChild(Label:New{caption=''})
		return
	end
    local func = function()
		if level ~= 0 then
			local cmdid = menu_selected.cmd
			if (cmdid == nil) then
				local ud = UnitDefNames[item.unit]
				if (ud ~= nil) then
					cmdid = Spring.GetCmdDescIndex(-ud.id)
				end
			end

			if (cmdid) then
				local alt, ctrl, meta, shift = Spring.GetModKeyState()
				local _, _, left, _, right = Spring.GetMouseState()

				if (menu ~= menu_selected) then -- store last item and level to render its back path
					level = level + 1  -- save level
				end
				Spring.SetActiveCommand(cmdid, 1, left, right, alt, ctrl, meta, shift)
				last_cmdid = cmdid
			end
			HotKeyMode(false)
		end
		if (item.items ~= nil)  then -- item has subitems
			level = level + 1  -- save level
			menu = item
			menu_selected = item
			UpdateMenu()
		end
		advance_builder = false
	end
	
	local tooltip1 = (level ~= 0) and ('Build: ' ..ud.humanName .. ' - ' .. ud.tooltip) or ('Category: ' .. item.label)
	local button1 = Button:New{
		name = index ,
		caption = '',
		tooltip = tooltip1,
		OnMouseDown = { function() HotKeyMode(false); end },
		OnMouseUp = { func },
		children = {
		},
	}
	if level == 0 and item.label then
		button1:AddChild( Label:New{ caption = item.label, fontSize = 11, bottom=0, fontShadow = true,  } )
	end
	local label_hotkey
	if index then
		local angle = IndexToAngle(index)
		if angle < 0 then angle = angle + 360 end
		local idx = angle / 45
		local hotkey = keys_display[1 + idx%8]
		local label_hotkey = Label:New{ name = hotkey, caption = (hotkey_mode and green..hotkey or ''), fontSize = 11, y = 0, right=0, fontShadow = true, }
		hotkey_labels[#hotkey_labels +1] = label_hotkey
		button1:AddChild( label_hotkey )
	end
	button1:AddChild( Image:New {
		file = "#"..ud.id,
		file2 = WG.GetBuildIconFrame(ud),
		keepAspect = false;
		width = '100%',
		height = '80%',
	})
	if level ~= 0 then
		button1:AddChild( Label:New{ caption = ud.metalCost .. ' m', fontSize = 11, bottom=0, fontShadow = true,  } )
	end
	
	grid_menu:AddChild(button1)
end
UpdateMenu = function()

	grid_menu:ClearChildren()
	if not menu then return end
	local temptree = {}

	if (menu.items) then
		if menu.angle then
			local index = AngleToIndex(menu.angle)
			--temptree[5] = menu
			temptree[index] = menu
		end
		
		for _,i in ipairs(menu.items) do
			local index = AngleToIndex(i.angle)
			temptree[index] = i
		end
		for i=1,9 do
			if i == 5 then
				AddBuildButton()
			else
				AddButton(temptree[i], i)
			end
		end
	end
end

local function MakeMenu()
	HotKeyMode(false)
	
	local units = Spring.GetSelectedUnits()
	menu = nil
	menu_selected = nil
	
	local buildername = builder_types_i[curbuilder]
	
	-- setup menu depending on selected unit
	if buildername then
		level = 0
		menu = menu_use[buildername]
		menu_selected = menu
		if not menu_visible then
			menu_visible = true
			window_menu.color = orig_color
			--screen0:AddChild(window_menu)
                        window_menu:Invalidate()
		end
	else
		if menu_visible then
			menu_visible = false
			--screen0:RemoveChild(window_menu)
			window_menu.color = hide_color
                        window_menu:Invalidate()
		end
	end
	
	UpdateMenu()
        
end

Make_KB_Menu = function()
	NextBuilder()
	advance_builder = true
	MakeMenu()
	
	if menu then
		HotKeyMode(true)
	end
end



local function StoreBuilders(units)
	builder_types = {}
	builder_types_i = {}
	builder_ids_i = {}
	curbuilder = 1
	for _, unitID in ipairs(units) do
		local ud = UnitDefs[Spring.GetUnitDefID(unitID)]
		if ud.isBuilder and menu_use[ud.name] then
			if not builder_types[ud.name] then
				builder_types[ud.name] = true
				builder_types_i[#builder_types_i + 1] = ud.name
				builder_ids_i[#builder_ids_i + 1] = ud.id
			end
		end
	end
end

local function BuildPrev()
	if last_cmdid then
		Spring.SetActiveCommand(last_cmdid)
	end
end

--------------------------------------------------------------------------------

function widget:KeyPress(k, modifier)
	if hotkey_mode then
		if not menu or k == KEYSYMS.ESCAPE then  -- cancel menu
			HotKeyMode(false)
			return true
		end
		local angle = keys[k]
		if angle == nil then return end
		local index = AngleToIndex(angle)
		local pressbutton = grid_menu:GetChildByName(index+0)
		if pressbutton then
			pressbutton.OnMouseUp[1]()
			return true
		end
	end
end

function widget:Initialize()
	Chili = WG.Chili
	Button = Chili.Button
	Window = Chili.Window
	Grid = Chili.Grid
	Image = Chili.Image
	Label = Chili.Label
	screen0 = Chili.Screen0

  -- check for custom key bind
  local hotkeys = Spring.GetActionHotKeys("radialmenu")
  if hotkeys == nil then
  else
    if #hotkeys > 0 then
      customKeyBind = true
    end
  end

  -- adding functions because of "handler=true"
  widgetHandler.AddAction    = function (_, cmd, func, data, types)
    return widgetHandler.actionHandler:AddAction(widget, cmd, func, data, types)
  end
  widgetHandler.RemoveAction = function (_, cmd, types)
    return widgetHandler.actionHandler:RemoveAction(widget, cmd, types)
  end

  widgetHandler:AddAction("radialmenu", Make_KB_Menu, nil, "t")
  if not customKeyBind then
    Spring.SendCommands("bind any+d radialmenu")
  end
  
  -- check for custom key bind
  local hotkeys = Spring.GetActionHotKeys("buildprev")
  if hotkeys == nil then
  else
    if #hotkeys > 0 then
      customKeyBind = true
    end
  end
  widgetHandler:AddAction("buildprev", BuildPrev, nil, "t")
  if not customKeyBind then
    Spring.SendCommands("bind meta+d buildprev")
  end

	grid_menu = Grid:New{
		rows = 3, columns = 3,
		width = '100%',
		height = '100%',
		resizeItems = true,
		itemPadding  = {0,0,0,0},
		itemMargin  = {0,0,0,0},
		--autosize = true,
		preserveChildrenOrder=true,
	}
	window_menu = Window:New{
		dockable = true,
		name = "chiliradialmenu",
		color = hide_color,
		x=0,y=200,
		width  = 215,
		height = 215,
		padding  = {5,5,5,5},
		parent = screen0,
		draggable = false,
		tweakDraggable = true,
		resizable = false,
		tweakResizable = true,
		dragUseGrip = false,
		fixedRatio = true,
		children = {
			grid_menu,
		},
	}
	--OptionsChanged()
	local sel = Spring.GetSelectedUnits()
	widget:SelectionChanged(sel)
end

function widget:Shutdown()
  if not customKeyBind then
    Spring.SendCommands("unbind d radialmenu")
  end
  widgetHandler:RemoveAction("radialmenu")
  
  Spring.SendCommands("unbind d radialmenu")
end


function widget:SelectionChanged(sel)
	StoreBuilders(sel)
	MakeMenu()
end
