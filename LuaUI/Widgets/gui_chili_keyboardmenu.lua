--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Keyboard Menu",
    desc      = "v0.005 Chili Keyboard Menu",
    author    = "CarRepairer",
    date      = "2012-03-27",
    license   = "GNU GPL, v2 or later",
    layer     = 9991,
    enabled   = false,
    handler = true,
  }
end 


-------------------------------------------------

local echo				= Spring.Echo

------------------------------------------------

-- config
include("keysym.h.lua")
local common_commands, states_commands, factory_commands,
	econ_commands, defense_commands, special_commands,
	globalCommands, overrides, custom_cmd_actions = include("Configs/integral_menu_commands.lua")

local build_menu_use = include("Configs/marking_menu_menus.lua")

------------------------------------------------
-- Chili classes
local Chili
local Button
local Label
local Colorbars
local Checkbox
local Window
local Panel
local StackPanel
local TextBox
local Image
local Progressbar
local Control

-- Chili instances
local screen0
local window_main		
local tab_commands, tab_sels, tab_toggles
local key_buttons = {}
local key_button_images, tab_buttons

------------------------------------------------
-- keys

local keyconfig = include("Configs/marking_menu_keys.lua")
local keys = keyconfig.qwerty_d.keys
local keys_display = keyconfig.qwerty_d.keys_display


------------------------------------------------

-- globals

local curCommands = {}

local selectedUnits = {}

--radial build menu
local CMD_RADIALBUILDMENU = 10002
local advance_builder = false
local builder_types = {}
local builder_types_i = {}
local builder_ids_i = {}
local curbuilder = 1
local last_cmdid
local build_menu = nil 
local build_menu_selected = nil 
local menu_level = 0
local customKeyBind = false
local build_mode = false
local green = '\255\1\255\1'
local white = '\255\255\255\255'

local magenta_table = {0.8, 0, 0, 1}
local white_table = {1,1,1, 1}

local tabHeight = 15
local commandButtons = {}
local updateCommandsSoon = false
local lastCmd, lastColor

local curTab = 'commands'

--predeclared functions
local function UpdateButtons() end
local function UpdateMenu() end
local function StoreBuilders() end
local function SetupKeybuttons() end

------------------------------------------------
-- options


options_path = 'Game/Selections'
options_order = {
	'lbl_main',
	'select_all',
	'select_half',
	'select_one',
	
	'lbl_idle',
	'select_idleb',
	'select_idleallb',
	'select_nonidle',
	
	'lbl_same',
	'select_same',
	'select_vissame',
	
	'lbl_w',
	'select_landw',
	'selectairw',
	
	'lbl_misc',
	'uikey1',
	'uikey2',
	'uikey3',
	'uikey4',
	'uikey5',
	
	'qwertz',
}
options = {

	qwertz = {
		name = 'QWERTZ layout',
		type = 'bool',
		path = 'Settings/Interface/KB Menu',
		OnChange = function(self)
			SetupKeybuttons()
			UpdateButtons()
		end,
	},
	

	--selectkey options
	lbl_main = { type = 'label', name = 'By Total' },
	lbl_idle = { type = 'label', name = 'Idle' },
	lbl_same = { type = 'label', name = 'Same Type' },
	lbl_w = { type = 'label', name = 'Armed Units' },
	
	lbl_misc = { type = 'label', name = 'Misc ZK uikeys' },
	
	select_all = { type = 'button',
		name = 'All Units',
		desc = 'Select all units.',
		action = 'select AllMap++_ClearSelection_SelectAll+',
	},
	select_idleb = { type = 'button',
		name = 'Idle Builder',
		desc = 'Select the next idle builder.',
		action = 'select AllMap+_Builder_Not_Building_Idle+_ClearSelection_SelectOne+',
	},
	select_idleallb = { type = 'button',
		name = 'All Idle Builders',
		desc = 'Select all idle builders.',
		action = 'select AllMap+_Builder_Not_Building_Not_Transport_Idle+_ClearSelection_SelectAll+',
	},
	
	select_vissame = { type = 'button',
		name = 'Visible Same',
		desc = 'Select all visible units of the same type as current selection.',
		action = 'select Visible+_InPrevSel+_ClearSelection_SelectAll+',
	},
	select_same = { type = 'button',
		name = 'All Same',
		desc = 'Select all units of the same type as current selection.',
		action = 'select AllMap+_InPrevSel+_ClearSelection_SelectAll+',
	},
	select_half = { type = 'button',
		name = 'Deselect Half',
		desc = 'Deselect half of the selected units.',
		action = 'select PrevSelection++_ClearSelection_SelectPart_50+',
	},
	select_one = { type = 'button',
		name = 'Deselect Except One',
		desc = 'Deselect all but one of the selected units.',
		action = 'select PrevSelection++_ClearSelection_SelectOne+',
	},
	select_nonidle = { type = 'button',
		name = 'Deselect non-idle',
		desc = 'Deselect all but the idle selected units.',
		action = 'select PrevSelection+_Idle+_ClearSelection_SelectAll+',
	},
	select_landw = { type = 'button',
		name = 'Visible Armed Land',
		desc = 'Select all visible armed land units.',
		action = 'select Visible+_Not_Builder_Not_Building_Not_Aircraft_Weapons+_ClearSelection_SelectAll+',
	},
	selectairw = { type = 'button',
		name = 'Visible Armed Flying',
		desc = 'Select all visible armed flying units.',
		action = 'select Visible+_Not_Building_Not_Transport_Aircraft_Weapons+_ClearSelection_SelectAll+',
	},
	
	lowhealth = { type = 'button',
		name = '30% Health',
		desc = '',
		action = 'select PrevSelection+_Not_RelativeHealth_30+_ClearSelection_SelectAll+',
	},
	
	----
	-- the below are from uikeys, I don't know what they do
	
	uikey1 = { type = 'button',
		name = 'Unknown uikey 1 - aircraft?',
		desc = '',
		action = 'select AllMap+_Not_Builder_Not_Building_Not_Transport_Aircraft_Weapons_Not_NameContain_Vamp_Not_Radar+_ClearSelection_SelectAll+',
	},
	uikey2 = { type = 'button',
		name = 'Unknown uikey 2 - vamp?',
		desc = '',
		action = 'select AllMap+_NameContain_Vamp+_ClearSelection_SelectAll+',
	},
	uikey3 = { type = 'button',
		name = 'Unknown uikey 3 - not builder?',
		desc = '',
		action = 'select AllMap+_Not_Builder_Not_Building+_ClearSelection_SelectAll+',
	},
	uikey4 = { type = 'button',
		name = 'Unknown uikey 3 - radar?',
		desc = '',
		action = 'AllMap+_Not_Builder_Not_Building_Not_Transport_Aircraft_Radar+_ClearSelection_SelectAll+',
	},
	uikey5 = { type = 'button',
		name = 'Unknown uikey 5 - transport?',
		desc = '',
		action = 'AllMap+_Not_Builder_Not_Building_Transport_Aircraft+_ClearSelection_SelectAll+',
	},
	
	
}


local function CapCase(str)
	local str = str:lower()
	str = str:gsub( '_', ' ' )
	str = str:sub(1,1):upper() .. str:sub(2)
	
	str = str:gsub( ' (.)', 
		function(x) return (' ' .. x):upper(); end
		)
	return str
end

local function AddHotkeyOptions()
	local options_order_tmp_cmd = {}
	local options_order_tmp_states = {}
	for cmdname, number in pairs(custom_cmd_actions) do 
			
		local cmdnamel = cmdname:lower()
		local cmdname_disp = CapCase(cmdname)
		options[cmdnamel] = {
			name = cmdname_disp,
			type = 'button',
			action = cmdnamel,
			path = 'Game/Commands',
		}
		if number == 2 then
			options_order_tmp_states[#options_order_tmp_states+1] = cmdnamel
		else
			options_order_tmp_cmd[#options_order_tmp_cmd+1] = cmdnamel
		end
	end

	options.lblcmd 			= { type='label', name='Instant Commands', path = 'Game/Commands',}
	options['lblstate'] 	= { type='label', name='State Commands', path = 'Game/Commands',}
	
	
	table.sort(options_order_tmp_cmd)
	table.sort(options_order_tmp_states)

	options_order[#options_order+1] = 'lblcmd'
	for _, option in ipairs( options_order_tmp_cmd ) do
		options_order[#options_order+1] = option
	end
	
	options_order[#options_order+1] = 'lblstate'
	for _, option in ipairs( options_order_tmp_states ) do
		options_order[#options_order+1] = option
	end
end

AddHotkeyOptions()

----------------------------------------------------------------
-- Helper Functions
-- [[
local function to_string(data, indent)
    local str = ""

    if(indent == nil) then
        indent = 0
    end
	local indenter = "    "
    -- Check the type
    if(type(data) == "string") then
        str = str .. (indenter):rep(indent) .. data .. "\n"
    elseif(type(data) == "number") then
        str = str .. (indenter):rep(indent) .. data .. "\n"
    elseif(type(data) == "boolean") then
        if(data == true) then
            str = str .. "true"
        else
            str = str .. "false"
        end
    elseif(type(data) == "table") then
        local i, v
        for i, v in pairs(data) do
            -- Check for a table in a table
            if(type(v) == "table") then
                str = str .. (indenter):rep(indent) .. i .. ":\n"
                str = str .. to_string(v, indent + 2)
            else
                str = str .. (indenter):rep(indent) .. i .. ": " .. to_string(v, 0)
            end
        end
	elseif(type(data) == "function") then
		str = str .. (indenter):rep(indent) .. 'function' .. "\n"
    else
        echo(1, "Error: unknown data type: %s", type(data))
    end

    return str
end
--]]


local function CopyTable(outtable,intable)
  for i,v in pairs(intable) do 
    if (type(v)=='table') then
      if (type(outtable[i])~='table') then outtable[i] = {} end
      CopyTable(outtable[i],v)
    else
      outtable[i] = v
    end
  end
end


------------------------------------------------
--functions

-- layout handler - its needed for custom commands to work and to delete normal spring menu
local function LayoutHandler(xIcons, yIcons, cmdCount, commands)
	widgetHandler.commands   = commands
	widgetHandler.commands.n = cmdCount
	widgetHandler:CommandsChanged()
	local reParamsCmds = {}
	local customCmds = {}
	
	local cnt = 0
	
	local AddCommand = function(command) 
		local cc = {}
		CopyTable(cc,command )
		cnt = cnt + 1
		cc.cmdDescID = cmdCount+cnt
		if (cc.params) then
			if (not cc.actions) then --// workaround for params
				local params = cc.params
				for i=1,#params+1 do
					params[i-1] = params[i]
				end
				cc.actions = params
			end
			reParamsCmds[cc.cmdDescID] = cc.params
		end
		--// remove api keys (custom keys are prohibited in the engine handler)
		cc.pos       = nil
		cc.cmdDescID = nil
		cc.params    = nil
		
		customCmds[#customCmds+1] = cc
	end 
	
	
	--// preprocess the Custom Commands
	for i=1,#widgetHandler.customCommands do
		AddCommand(widgetHandler.customCommands[i])
	end
	
	for i=1,#globalCommands do
		AddCommand(globalCommands[i])
	end

	Update()
	return "", xIcons, yIcons, {}, customCmds, {}, {}, {}, {}, reParamsCmds, {[1337]=9001}
end 


local function SetButtonColor(button, color)
	button.backgroundColor = color
	button:Invalidate()
end


local function ClearKeyButtons()
	for k, v in pairs( key_buttons ) do
		key_buttons[k]:SetCaption( '' )
		key_buttons[k].OnMouseDown = {}
		key_buttons[k].OnMouseUp = {}
		key_buttons[k]:ClearChildren()
		SetButtonColor( key_buttons[k], white_table )
	end
end
	

------------------------------------------------
--build menu functions

local function AngleToKey(angle)
	angle=angle+0
	if angle < 0 then 
		angle = angle + 360 
	end
	local conv = {
		[0] 	= 'E',
		[45] 	= 'R',
		[90] 	= 'F',
		[135] 	= 'V',
		[180] 	= 'C',
		[225] 	= 'X',
		[270] 	= 'S',
		[315] 	= 'W',
	}
	return conv[angle]
end
local function KeyToAngle(index)
	local conv = {
		E = 0,
		R = 45,
		F = 90,
		V = 135,
		C = 180,
		X = 225,
		S = 270,
		W = 315,
	}
	return conv[index]
end

local function AddHotkeyLabel( key, text )
	label = Label:New {
		width="100%";
		height="100%";
		autosize=false;
		align="left";
		valign="top";
		caption = green..text;
		fontSize = 11;
		fontShadow = true;
		parent = key_buttons[key];
	}
end

local function AddBuildButton(color)
	key_buttons['D']:AddChild(
		Label:New{ caption = 'BUIL'.. green ..'D', fontSize=14, bottom='1', fontShadow = true, }
	)
	key_buttons['D']:AddChild(
		Image:New {
			file = "#".. builder_ids_i[curbuilder], 
			file2 = 'LuaUI/Images/nested_buildmenu/frame_Fac.png',
			width = '100%',
			height = '80%',
		}
	)
	key_buttons['D'].OnMouseDown = { function() MakeBuildMenu(); end }
	if color then
		SetButtonColor(key_buttons['D'], color)
	end
end


local function SetCurTab(tab)
	SetButtonColor(tab_buttons[curTab], white_table)
	curTab = tab
	SetButtonColor(tab_buttons[curTab], magenta_table)
	
	StoreBuilders(selectedUnits)
	UpdateButtons()
end

local function NextBuilder()
	if advance_builder then
		curbuilder = curbuilder % #builder_types_i + 1
	end
end


local function BuildMode(enable)
	build_mode = enable
	if enable then
		curCommands = {}
		commandButtons = {}
	end
end

local function AddButton(item, index)
	
	if not item then
		--grid_menu:AddChild(Label:New{caption=''})
		return
	end
	
	
	local ud = UnitDefNames[item.unit]
	--[[
    if not ud then 
		grid_menu:AddChild(Label:New{caption=''})
		return
	end
	--]]
    local func = function()
		if menu_level ~= 0 then 
			local cmdid = build_menu_selected.cmd
			if (cmdid == nil) then 
				local ud = UnitDefNames[item.unit]
				if (ud ~= nil) then
					cmdid = Spring.GetCmdDescIndex(-ud.id)
				end
			end 

			if (cmdid) then
				local alt, ctrl, meta, shift = Spring.GetModKeyState()
				local _, _, left, _, right = Spring.GetMouseState()

				if (build_menu ~= build_menu_selected) then -- store last item and menu_level to render its back path
					menu_level = menu_level + 1  -- save menu_level
				end 
				Spring.SetActiveCommand(cmdid, _, left, right, alt, ctrl, meta, shift)
				last_cmdid = cmdid
			end
			--BuildMode(false)
		end 
		if (item.items ~= nil)  then -- item has subitems 
			menu_level = menu_level + 1  -- save menu_level
			build_menu = item
			build_menu_selected = item
			UpdateMenu() -- fixme - check this
		end
		advance_builder = false
	end
	
	local tooltip1 = (menu_level ~= 0) and ('Build: ' ..ud.humanName .. ' - ' .. ud.tooltip) or ('Category: ' .. item.label)

	local button1 = key_buttons[index]
	--button1.OnMouseDown = { function() BuildMode(false); end }
	button1.OnMouseUp = { func }
	button1.tooltip = tooltip1
	
	if menu_level == 0 and item.label then
		button1:AddChild( Label:New{ caption = item.label, fontSize = 11, bottom=0, fontShadow = true,  } )
	end
	local label_hotkey
	if index then
		local angle = KeyToAngle(index)
		--[[
		if angle < 0 then angle = angle + 360 end 
		local idx = angle / 45
		local hotkey = keys_display[1 + idx%8]
		local label_hotkey = Label:New{ name = hotkey, caption = (build_mode and green..hotkey or ''), fontSize = 11, y = 0, right=0, fontShadow = true, }
		hotkey_labels[#hotkey_labels +1] = label_hotkey
		button1:AddChild( label_hotkey )
		--]]
	end 
	button1:AddChild( Image:New {
		file = "#"..ud.id,
		file2 = WG.GetBuildIconFrame(ud),
		keepAspect = false;
		width = '100%',
		height = '80%',
	})
	if menu_level ~= 0 then
		button1:AddChild( Label:New{ caption = ud.metalCost .. ' m', fontSize = 11, bottom=0, fontShadow = true,  } )
	end
end


UpdateMenu = function()

	ClearKeyButtons()
	
	if not build_menu then return end
	local temptree = {}

	if (build_menu.items) then
		if build_menu.angle then
			local index = AngleToKey(build_menu.angle)
			temptree[index] = build_menu
		end
		
		for _,i in ipairs(build_menu.items) do
			
			local index = AngleToKey(i.angle)
			temptree[index] = i
		end
		
		local buildKeys = 'WERSDFXCV'
		local buildKeysLen = buildKeys:len()
		for i=1,buildKeysLen do
			local key = buildKeys:sub(i,i)
			if key == 'D' then
				AddBuildButton(magenta_table)
			else
				AddButton(temptree[key], key)
			end
		end
		
	end 
end

-- setup menu depending on selected unit(s)
local function SetupBuilderMenuData()
	build_menu = nil
	build_menu_selected = nil
	
	local buildername = builder_types_i[curbuilder]
	
	if buildername then 
		menu_level = 0
		build_menu = build_menu_use[buildername]
		build_menu_selected = build_menu
	end
	
	UpdateMenu()
end

MakeBuildMenu = function()
	NextBuilder()
	advance_builder = true
	SetupBuilderMenuData()
	if build_menu then
		BuildMode(true)
	end
end

StoreBuilders = function(units)
	builder_types = {}
	builder_types_i = {}
	builder_ids_i = {}
	curbuilder = 1
	for _, unitID in ipairs(units) do 
		local ud = UnitDefs[Spring.GetUnitDefID(unitID)]
		if ud.builder and build_menu_use[ud.name] then 
			if not builder_types[ud.name] then
				builder_types[ud.name] = true
				builder_types_i[#builder_types_i + 1] = ud.name
				builder_ids_i[#builder_ids_i + 1] = ud.id
			end
		end
	end
end



---------


local function AddCustomCommands(selectedUnits)
	for _, unitID in ipairs(selectedUnits) do
		local ud = UnitDefs[Spring.GetUnitDefID(unitID)]
		if ud.builder and build_menu_use[ud.name] then
			table.insert(widgetHandler.customCommands, {
				id      = CMD_RADIALBUILDMENU,
				name	= 'Build',
				type    = CMDTYPE.ICON,
				tooltip = 'Build a structure.',
				cursor  = 'Repair',
				action  = 'radialbuildmenu',
				params  = { }, 
				--texture = 'LuaUI/Images/commands/Bold/retreat.png',
		
				pos = {CMD_MOVE_STATE,CMD_FIRE_STATE, }, 
			})
	
		end
	end
end


local function SetupTabs()
	tab_buttons = {}
	local tabs = {
		selections = 'Selections (Ctrl)',
		commands = 'Commands',
		states = 'States (Alt)',
	}
	local tabs_i = { 'selections', 'commands', 'states',}
	
	
	tabCount = 3
	
	for i, tab in ipairs(tabs_i) do
		local data = tabs[tab]
		local caption = data
		local width = (100 / tabCount)
		tab_buttons[tab] = Button:New{
			parent = window_main,
			--name = '',
			caption = caption, 
			--tooltip = '',
			backgroundColor = white_table,
			OnMouseDown = { function()
				
				local _,_, meta,_ = Spring.GetModKeyState()
				if meta then 
					WG.crude.OpenPath('Game/Commands')
					WG.crude.ShowMenu() --make epic Chili menu appear.
					return false
				end
				
				SetCurTab(tab)
				
			end }, 
			--OnMouseUp = { func }, 

			x = (width * (i-1)) .. '%',
			bottom = 0,
			width = width .. '%',
			height = tabHeight .. '%',
		}
		
	end
	SetCurTab('commands')
end

SetupKeybuttons = function()

	for _, button in pairs( key_buttons ) do
		button:Dispose()
	end

	key_buttons = {}
	key_button_images = {}
	
	--local rows = { 'QWERT', 'ASDFG', 'ZXCVB' }
	local rows = { 'QWERTY', 'ASDFGH', 'ZXCVBN' }
	
	if options.qwertz.value then
		rows = { 'QWERTZ', 'ASDFGH', 'YXCVBN' }
	end
	
	local colnum = 0
	local offset_perc = 4
	
	for _, row in ipairs(rows) do
		local row_length = row:len()
		for rownum=1,row_length do
			local key = row:sub(rownum,rownum)
			local button_width_perc = (100 - offset_perc * (#rows-1) ) / row_length
			local button_height_perc = (100 - tabHeight) / #rows
			local x = ((rownum-1) * button_width_perc + offset_perc * colnum) .. '%'
			local y = colnum * button_height_perc .. '%'
			local width = button_width_perc .. '%'
			local height = button_height_perc .. '%'
			
			-- [[
			local color = {1,1,1,1}
			if ({Y=1,H=1,N=1})[key] then
				color = {0,0,0,0.6}
			end
			--]]
			
			key_buttons[key] = Button:New{
				parent = window_main,
				caption = '-', 
				backgroundColor = color, 
				x = x, y = y,
				width = width,
				height = height,
			}
		end
		colnum = colnum + 1
	end
end


--sorts commands into categories
local function ProcessCommand(cmd) 
	if not cmd.hidden and cmd.id ~= CMD.PAGES then
		if (cmd.type == CMDTYPE.ICON_MODE and cmd.params ~= nil and #cmd.params > 1) then 
			curCommands[#curCommands+1] = cmd
			
		elseif common_commands[cmd.id] then 
			curCommands[#curCommands+1] = cmd
		
		elseif factory_commands[cmd.id] then
		
		elseif econ_commands[cmd.id] then
		
		elseif defense_commands[cmd.id] then
		
		elseif special_commands[cmd.id] then
			curCommands[#curCommands+1] = cmd
			
		elseif UnitDefs[-(cmd.id)] then
		
		else
			curCommands[#curCommands+1] = cmd
		end
	end
end 

local function CommandFunction(cmdid)
	local _,_,left,_,right = Spring.GetMouseState()
	local alt,ctrl,meta,shift = Spring.GetModKeyState()
	local index = Spring.GetCmdDescIndex(cmdid)
	if (left) then
		Spring.SetActiveCommand(index,1,left,right,alt,ctrl,meta,shift)
	end
	if (right) then
		Spring.SetActiveCommand(index,3,left,right,alt,ctrl,meta,shift)
	end
end 

local function UpdateButton( hotkey_key, hotkey, name, fcn, tooltip, texture, color )
	key_buttons[hotkey_key].OnMouseDown = { fcn }
	key_buttons[hotkey_key].tooltip = tooltip
	AddHotkeyLabel( hotkey_key, hotkey )
	if texture and texture ~= "" then
		if type(texture) == 'table' then
			texture = texture[1]
		end
		local image = Image:New {
			width="90%";
			height= "90%";
			bottom = nil;
			y="5%"; x="5%";
			keepAspect = true,
			file = texture;
			parent = key_buttons[hotkey_key];
		}
	else
		key_buttons[hotkey_key]:SetCaption( name )
	end
	
	if color then
		SetButtonColor(key_buttons[hotkey_key], color)
	end
	
end

local function BreakDownHotkey(hotkey)
	local hotkey_len = hotkey:len()
	local hotkey_key = hotkey:sub(hotkey_len, hotkey_len)
	local hotkey_mod =
		hotkey:lower():find('ctrl') and 'ctrl'
		or hotkey:lower():find('alt') and 'alt'
		or ''
	
	return hotkey_key, hotkey_mod
end

local function SetupCommands( modifier )

	AddCustomCommands(selectedUnits)
	BuildMode(false)
	
    local commands = widgetHandler.commands
    local customCommands = widgetHandler.customCommands
	
	local selections = {
		'select_all',
		'select_half',
		'select_one',
		'select_idleb',
		'select_idleallb',
		'select_nonidle',
		'select_same',
		'select_vissame',
		'select_landw',
		'selectairw',
	}
	
	curCommands = {}
	commandButtons = {}
	
	for i = 1, #commands do ProcessCommand(commands[i]) end 
	for i = 1, #customCommands do ProcessCommand(customCommands[i]) end 
	for i = 1, #globalCommands do ProcessCommand(globalCommands[i]) end 
	
	ClearKeyButtons()
	for i, cmd in ipairs( curCommands ) do
		local hotkey = cmd.action and WG.crude.GetHotkey(cmd.action) or ''
		
		local hotkey_key, hotkey_mod = BreakDownHotkey(hotkey)
		
		if modifier == '' and cmd.id == CMD_RADIALBUILDMENU then
			AddBuildButton()
		elseif hotkey_mod == modifier and key_buttons[hotkey_key] then
			local override = overrides[cmd.id]  -- command overrides
			local texture = override and override.texture or cmd.texture
			local isState = (cmd.type == CMDTYPE.ICON_MODE and #cmd.params > 1) or states_commands[cmd.id]	--is command a state toggle command?
			if isState then 
				texture = override.texture[cmd.params[1]+1]
			end
			local _,cmdid,_,cmdname = Spring.GetActiveCommand()
			
			local color = cmd.disabled and red_table
			if cmd.id == cmdid then
				color = magenta_table
			end
			--color=nil
			UpdateButton( hotkey_key, hotkey, cmd.name, function() CommandFunction( cmd.id ); end, cmd.tooltip, texture, color )
			
		end
		commandButtons[cmd.id] = key_buttons[hotkey_key]
	end
	for i, selection in ipairs(selections) do
		local option = options[selection]
		local hotkey = WG.crude.GetHotkey(option.action) or ''
		local hotkey_key, hotkey_mod = BreakDownHotkey(hotkey)
		if hotkey_mod == modifier and key_buttons[hotkey_key] then
			local override = overrides[selection]  -- command overrides
			local texture = override and override.texture
			UpdateButton( hotkey_key, hotkey, option.name:gsub(' ', '\n'), function() Spring.SendCommands(option.action) end, option.tooltip, texture )
		end
	end
	
end


UpdateButtons = function()
	
	if curTab == 'selections' then
		SetupCommands('ctrl')
	elseif curTab == 'states' then
		SetupCommands('alt')
	else
		SetupCommands('')
	end
end



------------------------------------------------
--callins

function widget:Initialize()
	widgetHandler:ConfigLayoutHandler(LayoutHandler)
	Spring.ForceLayoutUpdate()
	
	widget:SelectionChanged(Spring.GetSelectedUnits())

	-- setup Chili
	Chili = WG.Chili
	Button = Chili.Button
	Label = Chili.Label
	Colorbars = Chili.Colorbars
	Checkbox = Chili.Checkbox
	Window = Chili.Window
	Panel = Chili.Panel
	StackPanel = Chili.StackPanel
	TextBox = Chili.TextBox
	Image = Chili.Image
	Progressbar = Chili.Progressbar
	Control = Chili.Control
	screen0 = Chili.Screen0
	
	-- setup chili controls
	window_main = Window:New{  
		parent = screen0,
		dockable = true,
		name = "keyboardmenu",
		x=200,y=300,
		width  = 400,
		height = 220,
		padding  = {5,5,5,5},
		draggable = false,
		tweakDraggable = true,
		resizable = false,
		tweakResizable = true,
		dragUseGrip = false,
		fixedRatio = true,
		color = {0.4, 0.4, 0.4, 0.4}
	}
	SetupKeybuttons()
	SetupTabs()
	
	widgetHandler.AddAction = function (_, cmd, func, data, types)
		return widgetHandler.actionHandler:AddAction(widget, cmd, func, data, types)
	end
	widgetHandler.RemoveAction = function (_, cmd, types)
		return widgetHandler.actionHandler:RemoveAction(widget, cmd, types)
	end
	
	widgetHandler:AddAction("radialbuildmenu", MakeBuildMenu, nil, "t")
	if not customKeyBind then
		Spring.SendCommands("bind d radialbuildmenu")
	end
end 

function widget:Shutdown()
	widgetHandler:ConfigLayoutHandler(nil)
	Spring.ForceLayoutUpdate()
	if not customKeyBind then
		Spring.SendCommands("unbind d radialbuildmenu")
	end
	widgetHandler:RemoveAction("radialbuildmenu")
end

function widget:KeyPress(key, modifier)
	if build_mode then
		if not build_menu or key == KEYSYMS.ESCAPE then  -- cancel menu
			BuildMode(false)
			return true 
		end
		
		if modifier.shift then
			return false
		end
		
		local angle = keys[key]
		if angle == nil then return end 
		--local index = AngleToIndex(angle)
		local index = AngleToKey(angle)
		--local pressbutton = grid_menu:GetChildByName(index+0)
		
		local pressbutton = key_buttons[index]
		if pressbutton then
			if #(pressbutton.OnMouseUp) < 1 then
				echo '<KB Menu> Conflicted error with build menu.'
				return false
			end
			pressbutton.OnMouseUp[1]()
			return true
		end
	end
	
	if key == KEYSYMS.LCTRL or key == KEYSYMS.RCTRL  then
		SetCurTab('selections')
	elseif key == KEYSYMS.LALT or key == KEYSYMS.RALT then
		SetCurTab('states')
	end
end

function widget:KeyRelease(key)
	if build_mode then
		return
	end
	
	
	if key == KEYSYMS.LCTRL or key == KEYSYMS.RCTRL or key == KEYSYMS.LALT or key == KEYSYMS.LALT then
		local alt, ctrl, meta, shift = Spring.GetModKeyState()
		SetCurTab( ctrl and 'selections' or alt and 'states' or 'commands' )
	end
end

function widget:MousePress(x,y,button)
	if build_mode and button == 3 then
		UpdateButtons()
		Spring.SetActiveCommand(0)
		BuildMode(false)
		return true
	end
end

function widget:SelectionChanged(sel)
	--echo('selchanged')
	selectedUnits = sel
	-- updating here causes error because commandchanged needs to find whether unit is builder or not
end

function widget:CommandsChanged()
	--echo ('commands changed')
	-- updating here causes async error when clearing hotkey labels, two commandschanged occur at once
	updateCommandsSoon = true
end

-- this is needed to highlight active command
function widget:DrawScreen()
	local _,cmdid,_,cmdname = Spring.GetActiveCommand()
	if cmdid ~= lastCmd then 
		if cmdid and commandButtons[cmdid]  then
			local button = commandButtons[cmdid]
			lastColor = button.backgroundColor
			SetButtonColor(button, magenta_table)
		end 
		if lastCmd ~= nil and commandButtons[lastCmd] then 
			local button = commandButtons[lastCmd]
			SetButtonColor(button, lastColor)
		end 
		lastCmd = cmdid
	end
end

function widget:Update()
end

function widget:GameFrame(f)
	--updating here seems to solve the issue if the widget layer is sufficiently large
	if updateCommandsSoon then
		updateCommandsSoon = false
		StoreBuilders(selectedUnits)
		UpdateButtons()
	end
end





function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_RADIALBUILDMENU then
		MakeBuildMenu()
		return true
	elseif cmdID < 0 then
		UpdateButtons()
	end
end
