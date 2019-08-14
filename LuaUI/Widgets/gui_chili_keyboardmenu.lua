--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Keyboard Menu",
    desc      = "v0.035 Chili Keyboard Menu",
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
local factory_commands,econ_commands, defense_commands, special_commands, _, overrides = include("Configs/integral_menu_commands.lua")
	
local build_menu_use = include("Configs/marking_menu_menus.lua")
local custom_cmd_actions = include("Configs/customCmdTypes.lua")

local initialBuilder = 'armcom1'

------------------------------------------------
-- Chili classes
local Chili
local Button
local Label
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
local red 	= '\255\255\001\001'

local magenta_table = {0.8, 0, 0, 1}
local white_table = {1,1,1, 1}
local black_table = {0,0,0,1}

local tabHeight = 15
local commandButtons = {}
local updateCommandsSoon = false
local lastCmd, lastColor

local curTab = 'none'
local keyRows = {}
local unboundKeyList = {}


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
	'lowhealth',
	
	'uikey1',
	'uikey2',
	'uikey3',
	'uikey4',
	'uikey5',
	'uikey6',
	
}

--predeclared functions
local function UpdateButtons() end
local function UpdateBuildMenu() end
local function StoreBuilders() end
local function SetupKeybuttons() end

------------------------------------------------
-- options


options_path = 'Settings/HUD Panels/KB Menu'
options_order = {
	'layout',
	'sevenperrow',
	'showGlobalCommands',
	'goToCommands',
	'goToSelections',
	'opacity',
	'old_menu_at_shutdown'
}
options = {

	layout = {
		name = 'Keyboard Layout',
		type = 'radioButton',
		OnChange = function(self)
			SetupKeybuttons()
			UpdateButtons()
		end,
		value = 'qwerty',
		items={
			{key='qwerty', name='QWERTY', },
			{key='qwertz', name='QWERTZ', },
			{key='azerty', name='AZERTY', },
			
		},
	},
	sevenperrow = {
		name = 'Rows of 7 keys',
		type = 'bool',
		desc = 'Each row has 7 keys instead of the 6 default.',
		OnChange = function(self)
			SetupKeybuttons()
			UpdateButtons()
		end,
		value = false,
	},
	
	showGlobalCommands = {
		name = 'Show Global Commands',
		type = 'bool',
		value = false,
		advanced = true,
	},
	goToCommands = {
		name = 'Commands...',
		type = 'button',
		OnChange = function(self)
			WG.crude.OpenPath('Hotkeys/Commands')
		end
	},
	goToSelections = {
		name = 'Selections...',
		type = 'button',
		OnChange = function(self)
			WG.crude.OpenPath('Hotkeys/Selection')
		end
	},
	opacity = {
		name = "Opacity",
		type = "number",
		value = 0.4, min = 0, max = 1, step = 0.01,
		OnChange = function(self) window_main.color = {1,1,1,self.value}; window_main:Invalidate() end,
	},
	old_menu_at_shutdown = {
		name = 'Reenable Spring Menu at Shutdown',
		desc = "Upon widget shutdown (manual or upon crash) reenable Spring's original command menu.",
		type = 'bool',
		advanced = true,
		value = true,
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
	local options_order_tmp_cmd_instant = {}
	local options_order_tmp_states = {}
	for cmdname, cmdData in pairs(custom_cmd_actions) do
		local number = cmdData.cmdType
		
		local cmdnamel = cmdname:lower()
		local cmdname_disp = CapCase(cmdname)
		options[cmdnamel] = {
			name = cmdname_disp,
			type = 'button',
			action = cmdData.name or cmdnamel,
			path = 'Hotkeys/Commands',
		}
		if number == 2 then
			options_order_tmp_states[#options_order_tmp_states+1] = cmdnamel
			--options[cmdnamel].isUnitStateCommand = true
		elseif number == 3 then
			options_order_tmp_cmd_instant[#options_order_tmp_cmd_instant+1] = cmdnamel
			--options[cmdnamel].isUnitInstantCommand = true
		else
			options_order_tmp_cmd[#options_order_tmp_cmd+1] = cmdnamel
			--options[cmdnamel].isUnitCommand = true
		end
	end

	options.lblcmd 		= { type='label', name='Targeted Commands', path = 'Hotkeys/Commands',}
	options.lblcmdinstant	= { type='label', name='Instant Commands', path = 'Hotkeys/Commands',}
	options.lblstate	= { type='label', name='State Commands', path = 'Hotkeys/Commands',}
	
	
	table.sort(options_order_tmp_cmd)
	table.sort(options_order_tmp_cmd_instant)
	table.sort(options_order_tmp_states)

	options_order[#options_order+1] = 'lblcmd'
	for i=1, #options_order_tmp_cmd do
		options_order[#options_order+1] = options_order_tmp_cmd[i]
	end
	
	options_order[#options_order+1] = 'lblcmdinstant'
	for i=1, #options_order_tmp_cmd_instant do
		options_order[#options_order+1] = options_order_tmp_cmd_instant[i]
	end
	
	options_order[#options_order+1] = 'lblstate'
	for i=1, #options_order_tmp_states do
		options_order[#options_order+1] = options_order_tmp_states[i]
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

local function explode(div,str)
	if (div=='') then
		--return false
		local ret = {}
		local len = str:len()
		for i=1,len do
			local char = str:sub(i,i)
			ret[#ret+1] = char
		end
		return ret
	end
	local pos,arr = 0,{}
	-- for each divider found
	for st,sp in function() return string.find(str,div,pos,true) end do
	  table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
	  pos = sp + 1 -- Jump past current divider
	end
	table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
	return arr
end

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


local function BuildPrev()
	if last_cmdid then
		Spring.SetActiveCommand(last_cmdid)
	end
end

local function SetButtonColor(button, color)
	button.backgroundColor = color
	button:Invalidate()
end


local function ClearKeyButtons()
	for k, v in pairs( key_buttons ) do
		key_buttons[k]:SetCaption( '' )
		key_buttons[k].OnClick = {}
		--key_buttons[k].OnMouseUp = {}
		key_buttons[k]:ClearChildren()
		key_buttons[k].tooltip = nil
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

local function CanInitialQueue()
	return WG.InitialQueue~=nil and not (Spring.GetGameFrame() > 0)
end

local function AddBuildButton(color)
	key_buttons['D']:AddChild(
		Label:New{ caption = 'BUIL'.. green ..'D', fontSize=14, bottom='1', fontShadow = true, }
	)
	key_buttons['D']:AddChild(
		Image:New {
			file = builder_ids_i[curbuilder] and "#".. builder_ids_i[curbuilder],
			file2 = 'LuaUI/Images/nested_buildmenu/frame_Fac.png',
			width = '100%',
			height = '80%',
		}
	)
	key_buttons['D'].OnClick = { function() MakeBuildMenu(); end }
	if color then
		SetButtonColor(key_buttons['D'], color)
	end
end


local function SetCurTab(tab)
	if curTab == tab then
		return
	end
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


local function CommandFunction(cmdid, left,right)
	--local _,_,left,_,right = Spring.GetMouseState()
	local alt,ctrl,meta,shift = Spring.GetModKeyState()
	local index = Spring.GetCmdDescIndex(cmdid)
	if (left) then
		Spring.SetActiveCommand(index,1,left,right,alt,ctrl,meta,shift)
	end
	if (right) then
		Spring.SetActiveCommand(index,3,left,right,alt,ctrl,meta,shift)
	end
end


local function AddBuildStructureButtonBasic(unitName, hotkey_key, index )
	local button1 = key_buttons[hotkey_key]
	
	local ud = UnitDefNames[unitName]
	button1.tooltip = 'Build: ' ..ud.humanName .. ' - ' .. ud.tooltip
	
	local label_hotkey
	if index then
		--local angle = KeyToAngle(index)
		AddHotkeyLabel( index, index )
	end
	button1:AddChild( Image:New {
		file = "#"..ud.id,
		file2 = WG.GetBuildIconFrame(ud),
		keepAspect = false;
		width = '100%',
		height = '80%',
	})
	
	button1:AddChild( Label:New{ caption = ud.metalCost .. ' m', height='20%', fontSize = 11, bottom=0, fontShadow = true,  } )
	
	
	button1.OnClick = { function (self, x, y, mouse)
		local left, right = mouse == 1, mouse == 3
		CommandFunction( -(ud.id), left, right );
	end }
end

local function AddBuildStructureButton(item, index)
	
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
    local func = function (self, x, y, mouse)
		--if menu_level ~= 0 then
		if menu_level ~= 0 or not item.items then  --account for first level items without subitems
			local cmdid = build_menu_selected.cmd

			if (cmdid == nil) then
				local ud = UnitDefNames[item.unit]
				if (ud ~= nil) then
					cmdid = Spring.GetCmdDescIndex(-ud.id)
				end
				
			end

			if (cmdid) then
				local alt, ctrl, meta, shift = Spring.GetModKeyState()
				--local _, _, left, _, right = Spring.GetMouseState()
				local left, right = mouse == 1, mouse == 3

				if (build_menu ~= build_menu_selected) then -- store last item and menu_level to render its back path
					menu_level = menu_level + 1  -- save menu_level
				end
				Spring.SetActiveCommand(cmdid, 1, left, right, alt, ctrl, meta, shift)
				last_cmdid = cmdid
			end
			--BuildMode(false)
		end
		if (item.items ~= nil) then -- item has subitems
			menu_level = menu_level + 1  -- save menu_level
			build_menu = item
			build_menu_selected = item
			UpdateBuildMenu() -- fixme - check this
		end
		advance_builder = false
	end
	
	local tooltip1 = (menu_level ~= 0) and ('Build: ' ..ud.humanName .. ' - ' .. ud.tooltip) or ('Category: ' .. item.label)

	local button1 = key_buttons[index]
	--button1.OnMouseDown = { function() BuildMode(false); end }
	button1.OnClick = { func }
	button1.tooltip = tooltip1
	
	if menu_level == 0 and item.label then
		button1:AddChild( Label:New{ caption = item.label, fontSize = 11, bottom=0, fontShadow = true,  } )
	end
	
	
	
	local label_hotkey
	if index then
		--local angle = KeyToAngle(index)
		AddHotkeyLabel( index, index )
	end
	button1:AddChild( Image:New {
		file = "#"..ud.id,
		file2 = WG.GetBuildIconFrame(ud),
		keepAspect = false;
		width = '100%',
		height = '80%',
	})
	if menu_level ~= 0 then
		button1:AddChild( Label:New{ caption = ud.metalCost .. ' m', height='20%', fontSize = 11, bottom=0, fontShadow = true,  } )
	end
end


UpdateBuildMenu = function()

	ClearKeyButtons()
	
	if not build_menu then return end
	local temptree = {}

	if (build_menu.items) then
	--if true then
		--local items = build_menu.items or {}
		local items = build_menu.items
		
		if build_menu.angle then
			local index = AngleToKey(build_menu.angle)
			temptree[index] = build_menu
		end
		
		for _,i in ipairs(items) do
			
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
				AddBuildStructureButton(temptree[key], key)
			end
		end
		
	end
end

-- setup menu depending on selected unit(s)
local function SetupBuilderMenuData()
	build_menu = nil
	build_menu_selected = nil
	
	local buildername = builder_types_i[curbuilder]
	
	if CanInitialQueue() then
		buildername = initialBuilder
	end
	
	if buildername then
		menu_level = 0
		build_menu = build_menu_use[buildername]
		build_menu_selected = build_menu
	end
	
	UpdateBuildMenu()
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
		if ud and ud.isBuilder and build_menu_use[ud.name] then
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
	if CanInitialQueue() then
		selectedUnits = {'a'}
	end
	for _, unitID in ipairs(selectedUnits) do
		local ud
		if CanInitialQueue() then
			ud = UnitDefNames[initialBuilder]
		else
			ud = UnitDefs[Spring.GetUnitDefID(unitID)]
		end
		if ud and ud.isBuilder and build_menu_use[ud.name] then
			table.insert(widgetHandler.customCommands, {
				id      = CMD_RADIALBUILDMENU,
				name	= 'Build',
				type    = CMDTYPE.ICON,
				tooltip = 'Build a structure.',
				cursor  = 'Repair',
				action  = 'radialbuildmenu',
				params  = { },
				--texture = 'LuaUI/Images/commands/Bold/retreat.png',
		
				pos = {CMD.MOVE_STATE,CMD.FIRE_STATE, },
			})
			table.insert(widgetHandler.customCommands, {
				id      = CMD_BUILDPREV,
				name	= 'Build Previous',
				type    = CMDTYPE.ICON,
				tooltip = 'Build the previous structure.',
				cursor  = 'Repair',
				action  = 'buildprev',
				params  = { },
				pos = {CMD.MOVE_STATE,CMD.FIRE_STATE, },
			})
		end
	end
end



local function SetupTabs()
	tab_buttons = {}
	local tabs = {
		none = 'Commands',
		ctrl = 'Selection '..green..'(Ctrl)',
		alt = 'States ' ..green..'(Alt)',
		meta = green..'(Spacebar)',
		unbound = 'Other',
	}
	local tabs_i = { 'none', 'ctrl', 'alt', 'meta', 'unbound' }
	
	
	tabCount = #tabs_i
	
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
			
			OnClick = { function()
				SetCurTab(tab)
				BuildMode(false)
			end },
			

			x = (width * (i-1)) .. '%',
			bottom = 0,
			width = width .. '%',
			height = tabHeight .. '%',
		}
		
	end
	SetCurTab('none')
end

SetupKeybuttons = function()

	for _, button in pairs( key_buttons ) do
		button:Dispose()
	end

	key_buttons = {}
	key_button_images = {}
	
	if options.layout.value == 'qwertz' then
		keyRows = options.sevenperrow.value
			and	{ 'QWERTZU', 'ASDFGHJ', 'YXCVBNM' }
			or 	{ 'QWERTZ', 'ASDFGH', 'YXCVBN' }
	elseif options.layout.value == 'azerty' then
		keyRows = options.sevenperrow.value
			and	{ 'AZERTYU', 'QSDFGHJ', 'WXCVBN,' }
			or 	{ 'AZERTY', 'QSDFGH', 'WXCVBN' }
	else
		keyRows = options.sevenperrow.value
			and	{ 'QWERTYU', 'ASDFGHJ', 'ZXCVBNM' }
			or 	{ 'QWERTY', 'ASDFGH', 'ZXCVBN' }
	end
	
	local width, height
	height = window_main.height
	
	local ratio = (keyRows[1]:len() + 0.8) / (3 + 0.5)
	width = ratio * height
	
	window_main:Resize(width, height)
	
	local rows = keyRows
	
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
	
	local unboundKeys = table.concat( keyRows )
	unboundKeyList = explode( '', unboundKeys )
end


--sorts commands into categories
local function ProcessCommand(cmd)
	if not cmd.hidden and cmd.id ~= CMD.PAGES then
		if (cmd.type == CMDTYPE.ICON_MODE and cmd.params ~= nil and #cmd.params > 1) then
			curCommands[#curCommands+1] = cmd
		elseif special_commands[cmd.id] then --curently terraform
			curCommands[#curCommands+1] = cmd
			
		elseif UnitDefs[-(cmd.id)] then
			curCommands[#curCommands+1] = cmd
		else
			curCommands[#curCommands+1] = cmd
		end
	end
end

local function UpdateButton( hotkey_key, hotkey, name, fcn, tooltip, texture, color )

	key_buttons[hotkey_key].OnClick = { fcn }
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
		--key_buttons[hotkey_key]:SetCaption( name:gsub(' ', '\n') )
	end
	key_buttons[hotkey_key]:SetCaption( name and name:gsub(' ', '\n') or '' )
	
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
		or hotkey:lower():find('meta') and 'meta'
		or ''
	
	return hotkey_key, hotkey_mod
end

local function SetupCommands( modifier )

	--AddCustomCommands(Spring.GetSelectedUnits())
	BuildMode(false)
	
    local commands = widgetHandler.commands
    local customCommands = widgetHandler.customCommands
	
	curCommands = {}
	commandButtons = {}
	-- [=[
	for i = 1, #commands do ProcessCommand(commands[i]) end
	for i = 1, #customCommands do ProcessCommand(customCommands[i]) end
	--]=]
	
	
	ClearKeyButtons()
	
	if modifier == 'none' then
		modifier = '';
	end
	
	--moved to SetupKeybuttons
	--local unboundKeys = table.concat( keyRows )
	--local unboundKeyList = explode( '', unboundKeys )
	local unboundKeyIndex = 1
	
	local ignore = {}
	
	-- [=[
	if options.showGlobalCommands.value then
		for letterInd=1,26 do
			local letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
			local letter = letters:sub(letterInd, letterInd)
			local hotkey_key = letter
			local actions
			local modifiers = {'', 'ctrl', 'alt', 'meta'}
			for j=1,#modifiers do
				local modifier2 = modifiers[j]
				local modifierKb = (modifier2 ~= '') and (modifier2 .. '+') or ''
				actions = Spring.GetKeyBindings(modifierKb .. hotkey_key)
				
				--if not ignore[hotkey_key] and actions and #actions > 0 then
				if actions and #actions > 0 then
						
					for i=1,#actions do
						local actionData = actions[i]
						local actionCmd,actionExtra = actionData.command, actionData.extra
						if not(actionCmd) then actionCmd,actionExtra = next(actionData) end
						assert(actionCmd)
						
						local buildCommand = actionCmd:find('buildunit_')
						
						if not custom_cmd_actions[ actionCmd ] and actionCmd ~= 'radialbuildmenu' and not buildCommand then
						
							local actionOption = WG.crude.GetActionOption(actionCmd)
							local actionName = actionOption and actionOption.name
							local actionDesc = actionOption and actionOption.desc
							
							local label = actionName or actionCmd
							local tooltip = actionDesc or (label  .. ' ' .. actionExtra)
							local action = actionExtra and actionExtra ~= '' and actionCmd .. ' ' .. actionExtra or actionCmd
							
							if label == 'luaui' then
								label = actionExtra
							end
							
							--create fake command and add it to list
							curCommands[#curCommands+1] = {
								type = '',
								id = 99999,
								name = label,
								tooltip = tooltip,
								action = action,
							}
						end
							
							
					end
				end
				
			end
			
		end --for letterInd=1,26
	end --if options.showGlobalCommands.value
	--]=]
	
	-- [=[
	--for i, cmd in ipairs( curCommands ) do
	for i = 1, #curCommands do
		local cmd = curCommands[i]
		local hotkey = cmd.action and WG.crude.GetHotkey(cmd.action) or ''
		
		local hotkey_key, hotkey_mod = BreakDownHotkey(hotkey)
		--echo(CMD[cmd.id], cmd.name, hotkey_key, hotkey_mod)
		
		if not ignore[hotkey_key] then
			if ( (modifier == 'unbound' and hotkey_key == '') or not key_buttons[hotkey_key] )
				and cmd.type ~= CMDTYPE.NEXT and cmd.type ~= CMDTYPE.PREV
				and cmd.id >= 0
				and cmd.id ~= CMD_RADIALBUILDMENU
				then
				if unboundKeyList[unboundKeyIndex] then
					hotkey_key = unboundKeyList[unboundKeyIndex]
					hotkey_mod = 'unbound'
					unboundKeyIndex = unboundKeyIndex + 1
				end
			end
			
			if modifier == '' and cmd.id == CMD_RADIALBUILDMENU then
				AddBuildButton()
				ignore['D'] = true
			elseif hotkey_mod == modifier and key_buttons[hotkey_key] then
				local override = overrides[cmd.id]  -- command overrides
				local texture = override and override.texture or cmd.texture
				local isState = (cmd.type == CMDTYPE.ICON_MODE and #cmd.params > 1)	--is command a state toggle command?
				if isState and override then
					texture = override.texture[cmd.params[1]+1]
				end
				local _,cmdid,_,cmdname = Spring.GetActiveCommand()
				
				local color = cmd.disabled and black_table
				if cmd.id == cmdid then
					color = magenta_table
				end
				
				local label = cmd.name
				if texture and texture ~= '' then
					label = ''
				end
				
				if cmd.name == 'Morph' or cmd.name == red  .. 'Stop' then
					hotkey = cmd.name
				end
				
				if cmd.id < 0 then
					AddBuildStructureButtonBasic( cmd.name, hotkey_key, hotkey )
				else
					if cmd.id == 99999 then
						UpdateButton( hotkey_key, hotkey, label, function() Spring.SendCommands( cmd.action ); end, cmd.tooltip, texture, color )
					else
						UpdateButton( hotkey_key, hotkey, label, function (self, x, y, mouse)
							local left, right = mouse == 1, mouse == 3
							CommandFunction( cmd.id, left, right );
						end, cmd.tooltip, texture, color )
					end
				end
				
				
				ignore[hotkey_key] = true
			end
			
			commandButtons[cmd.id] = key_buttons[hotkey_key]
			
		end --if not ignore[hotkey_key] then
	end --for i = 1, #curCommands do
	--]=]
	
	-- [=[
	--for i, selection in ipairs(selections) do
	for i = 1, #selections do
		local selection = selections[i]
		--local option = options[selection]
		local option = WG.GetWidgetOption( 'Select Keys','Hotkeys/Selection', selection ) --returns empty table if problem
		if option.action then
			local hotkey = WG.crude.GetHotkey(option.action) or ''
			local hotkey_key, hotkey_mod = BreakDownHotkey(hotkey)
			--echo(option.action, hotkey_key, hotkey_mod)
			if hotkey_mod == modifier and key_buttons[hotkey_key] then
				local override = overrides[selection]  -- command overrides
				local texture = override and override.texture
				UpdateButton( hotkey_key, hotkey, option.name, function() Spring.SendCommands(option.action) end, option.tooltip, texture )
				ignore[hotkey_key] = true
			end
		end
	end
	--]=]
end --SetupCommands


UpdateButtons = function()
	SetupCommands( curTab )
end



------------------------------------------------
--callins

function widget:Initialize()
	widget:SelectionChanged(Spring.GetSelectedUnits())

	-- setup Chili
	Chili = WG.Chili
	Button = Chili.Button
	Label = Chili.Label
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
		color = {1,1,1,options.opacity.value},
	}
	local configButton = Button:New{
		parent = window_main,
		caption = '',
		tooltip = 'Configure Hotkeys',
		backgroundColor = white_table,
		OnClick = { function()
			WG.crude.OpenPath('Settings/HUD Panels/KB Menu')
			WG.crude.ShowMenu() --make epic Chili menu appear.
		end },
		bottom = tabHeight .. '%',
		x = 0,
		width = (tabHeight/2) .. '%',
		height = tabHeight.. '%',
	}
	local image = Image:New {
		width="100%",
		height= "100%",
		--bottom = nil,
		--y="5%"; x="5%",
		keepAspect = true,
		file = 'LuaUI/Images/epicmenu/settings.png',
		parent = configButton,
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
	
	widgetHandler:AddAction("buildprev", BuildPrev, nil, "t")
	if not customKeyBind then
		--Spring.SendCommands("bind d buildprev")
	end
	
	
end

function widget:Shutdown()
	if not customKeyBind then
		Spring.SendCommands("unbind d radialbuildmenu")
	end
	widgetHandler:RemoveAction("radialbuildmenu")
	
	if not customKeyBind then
		--Spring.SendCommands("unbind d buildprev")
	end
	widgetHandler:RemoveAction("buildprev")
	
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
			if #(pressbutton.OnClick) > 0 then
				pressbutton.OnClick[1]()
			end
			return true
		end
	end
	
	if key == KEYSYMS.LCTRL or key == KEYSYMS.RCTRL  then
		SetCurTab('ctrl')
	elseif key == KEYSYMS.LALT or key == KEYSYMS.RALT then
		SetCurTab('alt')
	elseif key == KEYSYMS.LMETA or key == KEYSYMS.RMETA or key == KEYSYMS.SPACE then
		SetCurTab('meta')
	end
end

function widget:KeyRelease(key)
	if build_mode then
		return
	end
	
	if
		key == KEYSYMS.LCTRL or key == KEYSYMS.RCTRL
		or key == KEYSYMS.LALT or key == KEYSYMS.LALT
		or key == KEYSYMS.LMETA or key == KEYSYMS.RMETA or key == KEYSYMS.SPACE
		then
		local alt, ctrl, meta, shift = Spring.GetModKeyState()
		SetCurTab( ctrl and 'ctrl'
			or alt and 'alt'
			or meta and 'meta'
			or 'none'
			)
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

--local selectionHasChanged
function widget:SelectionChanged(sel)
	--echo('selchanged')
	selectedUnits = sel
	--selectionHasChanged = true
	-- updating here causes error because commandchanged needs to find whether unit is builder or not
end

function widget:CommandsChanged()
	--echo ('commands changed')
	-- updating here causes async error when clearing hotkey labels, two commandschanged occur at once
	AddCustomCommands(selectedUnits)
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

local timer = 0

function widget:Update() --no param, see below
	local s = Spring.GetLastUpdateSeconds() -- needed because of Update() call in this function
	timer = timer + s
	if timer > 0.5 then
		timer = 0
		
		--updating here seems to solve the issue if the widget layer is sufficiently large
		if updateCommandsSoon then
			updateCommandsSoon = false
			StoreBuilders(selectedUnits)
			if not( build_mode and #builder_ids_i > 0 ) then
				UpdateButtons()
			end
			--selectionHasChanged = false
		end
	end
end

function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_RADIALBUILDMENU then
		MakeBuildMenu()
		return true
	elseif cmdID == CMD_BUILDPREV then
		BuildPrev()
		return true
	elseif cmdID < 0 then
		UpdateButtons()
	end
end
