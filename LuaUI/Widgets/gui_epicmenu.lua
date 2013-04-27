function widget:GetInfo()
  return {
    name      = "EPIC Menu",
    desc      = "v1.314 Extremely Powerful Ingame Chili Menu.",
    author    = "CarRepairer",
    date      = "2009-06-02", --2013-04-10
    license   = "GNU GPL, v2 or later",
    layer     = -100001,
    handler   = true,
    experimental = false,	
    enabled   = true,
	alwaysStart = true,
  }
end

--CRUDE EXPLAINATION (third party comment) on how things work: (by Msafwan)
--1) first... a container called "OPTION" is shipped into epicMenuFactory from various sources (from widgets or epicmenu_conf.lua)
--Note: "OPTION" contain a smaller container called "OnChange" (which is the most important content). 
--2) "OPTION" is then brought into epicMenuFactory\AddOption() which then attach a tracker which calls "SETTINGS" whenever "OnChange" is called.
--Note: "SETTINGS" is container which come and go from epicMenuFactory. Its destination is at CAWidgetFactory which save into "Zk_data.lua".
--4) "OPTION" are then brought into epicMenuFactory\MakeSubWindow() which then wrap the content(s) into regular buttons/checkboxes. This include the modified "OnChange"
--5) then Hotkey buttons is created in epicMenuFactory\MakeHotkeyedControl() and attached to regular buttons horizontally (thru 'StackPanel') which then sent back to  epicMenuFactory\MakeSubWindow()
--6) then epicMenuFactory\MakeSubWindow() attaches all created button(s) to main "Windows" and finished the job. (now waiting for ChiliFactory to render them all).
--Note: hotkey button press is handled by Spring, but its registration & attachment with "OnChange" is handled by epicMenuFactory
--Note: all button rendering & clicking is handled by ChiliFactory (which receive button settings & call "OnChange" if button is pressed)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetConfigInt    		= Spring.GetConfigInt
local spSendCommands			= Spring.SendCommands
local min = math.min
local max = math.max

local echo = Spring.Echo

--------------------------------------------------------------------------------

-- Config file data
local VFSMODE      = VFS.RAW_FIRST
local file = LUAUI_DIRNAME .. "Configs/epicmenu_conf.lua"
local confdata = VFS.Include(file, nil, VFSMODE)
local epic_options = confdata.eopt
local color = confdata.color
local title_text = confdata.title
local title_image = confdata.title_image
local keybind_file = confdata.keybind_file or title_text .. '_keys.lua'
local file_return = VFS.Include(keybind_file, nil, VFS.ZIP)
local defaultkeybinds, defaultkeybind_date = file_return.keybinds, file_return.date
local useUiKeys = false
--file_return = nil

local _, _, _, _, _, _, _, _, custom_cmd_actions = include("Configs/integral_menu_commands.lua")

--------------------------------------------------------------------------------

-- Chili control classes
local Chili
local Button
local Label
local Colorbars
local Checkbox
local Window
local ScrollPanel
local StackPanel
local LayoutPanel
local Grid
local Trackbar
local TextBox
local Image
local Progressbar
local Colorbars
local screen0

--------------------------------------------------------------------------------
-- Global chili controls
local window_crude 
local window_exit
local window_flags
local window_help
local window_getkey
local lbl_gtime, lbl_fps, lbl_clock, img_flag
local cmsettings_index = -1
local window_sub_cur

--------------------------------------------------------------------------------
-- Misc
local B_HEIGHT = 26
local C_HEIGHT = 16

local scrH, scrW = 0,0
local cycle = 1
local curSubKey = ''
local curPath = ''

local init = false
local myCountry = 'wut'

local pathoptions = {}	
local alloptions = {}	

local exitWindowVisible = false

--------------------------------------------------------------------------------
-- Key bindings
-- KEY BINDINGS AND YOU:
-- First, Epic Menu checks for a keybind bound to the action in LuaUI/Configs/zk_keys.lua.
-- 	If the local copy has a lower date value than the one in the mod,
-- 	it overwrites ALL conflicting keybinds in the local config.
--	Else it just adds any action-key pairs that are missing from the local config.
--	zk_keys.lua is written to at the end of loading LuaUI and on LuaUI shutdown.
-- Next, if it's a widget command, it checks if the widget specified a default keybind.
--	If so, it uses that command.
-- Lastly, it checks uikeys.txt (read-only).

include("keysym.h.lua")
local keysyms = {}
for k,v in pairs(KEYSYMS) do
	keysyms['' .. v] = k	
end
--[[
for k,v in pairs(KEYSYMS) do
	keysyms['' .. k] = v
end
--]]
local get_key = false
local kb_path
local kb_action

local transkey = {
	backquote 		= '`',
	
	leftbracket 	= '[',
	rightbracket 	= ']',
	--delete 			= 'del',
	comma 			= ',',
	period 			= '.',
	slash 			= '/',
	backslash 			= '\\',
	equals 			= '=',
	
	quote 			= "'",
	
	kp_multiply		= 'numpad*',
	kp_divide		= 'numpad/',
	kp_plus			= 'numpad+',
	kp_minus		= 'numpad-',
	kp_period		= 'numpad.',
	
	kp0				= 'numpad0',
	kp1				= 'numpad1',
	kp2				= 'numpad2',
	kp3				= 'numpad3',
	kp4				= 'numpad4',
	kp5				= 'numpad5',
	kp6				= 'numpad6',
	kp7				= 'numpad7',
	kp8				= 'numpad8',
	kp9				= 'numpad9',
}



--------------------------------------------------------------------------------
-- Widget globals
WG.crude = {}
if not WG.Layout then
	WG.Layout = {}
end

--------------------------------------------------------------------------------
-- Luaui config settings
local keybounditems = {}
local keybind_date = 0

local settings = {
	versionmin = 50,
	lang = 'en',
	widgets = {},
	show_crudemenu = true,
	music_volume = 0.5,
}



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
                str = str .. (indenter):rep(indent) .. i .. ": " ..
to_string(v, 0)
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

local function CapCase(str)
	local str = str:lower()
	str = str:gsub( '_', ' ' )
	str = str:sub(1,1):upper() .. str:sub(2)
	
	str = str:gsub( ' (.)', 
		function(x) return (' ' .. x):upper(); end
		)
	return str
end


local function explode(div,str)
  if (div=='') then return false end
  local pos,arr = 0,{}
  -- for each divider found
  for st,sp in function() return string.find(str,div,pos,true) end do
    table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
    pos = sp + 1 -- Jump past current divider
  end
  table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
  return arr
end


local function GetIndex(t,v) local idx = 1; while (t[idx]<v)and(t[idx+1]) do idx=idx+1; end return idx end

local function CopyTable(tableToCopy, deep)
  local copy = {}
  for key, value in pairs(tableToCopy) do
    if (deep and type(value) == "table") then
      copy[key] = Spring.Utilities.CopyTable(value, true)
    else
      copy[key] = value
    end
  end
  return copy
end

--[[
local function tableMerge(t1, t2, appendIndex)
	for k,v in pairs(t2) do
		if type(v) == "table" then
			if type(t1[k] or false) == "table" then
				tableMerge(t1[k] or {}, t2[k] or {}, appendIndex)
			else
				if type(k) == 'number' and appendIndex then
					t1[#t1+1] = v
				else
					t1[k] = v
				end
			end
		else
			if type(k) == 'number' and appendIndex then
				t1[#t1+1] = v
			else
				t1[k] = v
			end
		end
	end
	return t1
end
--]]

local function tableremove(table1, item)
	local table2 = {}
	for i=1, #table1 do
		local v = table1[i]
		if v ~= item then
			table2[#table2+1] = v
		end
	end
	return table2
end

-- function GetTimeString() taken from trepan's clock widget
local function GetTimeString()
  local secs = math.floor(Spring.GetGameSeconds())
  if (timeSecs ~= secs) then
    timeSecs = secs
    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    local s = math.floor(secs % 60)
    if (h > 0) then
      timeString = string.format('%02i:%02i:%02i', h, m, s)
    else
      timeString = string.format('%02i:%02i', m, s)
    end
  end
  return timeString
end

local function BoolToInt(bool)
	return bool and 1 or 0
end
local function IntToBool(int)
	return int ~= 0
end

-- cool new framework for ordered table that has keys
local function otget(t,key)
	for i=1,#t do
		if not t[i] then
			return
		end
		if t[i][1] == key then --key stored in index 1, while value at index 2
			return t[i][2]
		end
	end
	return nil
end
local function otset(t, key, val)
	for i=1,#t do
		if t[i][1] == key then --key stored in index 1, while value at index 2
			if val == nil then
				table.remove( t, i )
			else
				t[i][2] = val
			end
			return
		end
	end
	if val ~= nil then
		t[#t+1] = {key, val}
	end
end
local function otvalidate(t)
	for i=1,#t do
		if not t[i] then
			return false
		end
	end
	return true
end
--end cool new framework

--------------------------------------------------------------------------------

WG.crude.SetSkin = function(Skin)
  if Chili then
    Chili.theme.skin.general.skinName = Skin
  end
end

--Reset custom widget settings, defined in Initialize
WG.crude.ResetSettings 	= function() end

--Reset hotkeys, defined in Initialized
WG.crude.ResetKeys 		= function() end

--Get hotkey by actionname, defined in Initialize()
WG.crude.GetHotkey = function() end

--Set hotkey by actionname, defined in Initialize(). Is defined in Initialize() because trying to iterate pathoptions table here (at least if running epicmenu.lua in local copy) will return empty pathoptions table.
WG.crude.SetHotkey =  function() end 

--Callin often used for space+click shortcut, defined in Initialize(). Is defined in Initialize() because it help with testing epicmenu.lua in local copy
WG.crude.OpenPath = function() end

--Allow other widget to toggle-up/show Epic-Menu remotely, defined in Initialize()
WG.crude.ShowMenu = function() end --// allow other widget to toggle-up Epic-Menu which allow access to game settings' Menu via click on other GUI elements.


--[[
-- is this an improvement?
WG.crude.GetHotkey = function(actionName)
	local hotkey = keybounditems[actionName]
	if not hotkey then
		local fallback = Spring.GetActionHotKeys(actionName)
		if fallback and fallback[1] then
			return CapCase(fallback[1])
		else
			return ''
		end
	end
	return GetReadableHotkey(hotkey) 
end
--]]

WG.GetWidgetOption = function(wname, path, key)  -- still fails if path and key are un-concatenatable
	--return (pathoptions and path and key and wname and pathoptions[path] and pathoptions[path][wname..key]) or {}
	return (pathoptions and path and key and wname and pathoptions[path] and otget( pathoptions[path], wname..key ) ) or {}
end 
WG.SetWidgetOption = function(wname, path, key, value)  
	if (pathoptions and path and key and wname and pathoptions[path] and otget( pathoptions[path], wname..key ) ) then
		local option = alloptions[path..wname .. key]
		option.OnChange(value)
	end
end 


local function SaveKeybinds()
	local keybindfile_table = { keybinds = keybounditems, date=keybind_date } 
	--table.save( keybindfile_table, keybind_file )
	
	local file = io.open (keybind_file, "w")
	if (file== nil) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Could not open keybind file " .. keybind_file .. " for writing")
		return
	end
	
	file:write ("return " .. WG.WriteTable(keybindfile_table, 0, true, true, true))
	file:flush()
	file:close()
	
end

local function LoadKeybinds()
	local loaded = false
	if VFS.FileExists(keybind_file, VFS.RAW) then
		local file_return = VFS.Include(keybind_file, nil, VFS.RAW)
		if file_return then
			keybounditems, keybind_date = file_return.keybinds, file_return.date
			if keybounditems and keybind_date then
				
				if not otvalidate(keybounditems) then
					keybounditems = {}
				end
				
				loaded = true
				keybind_date = keybind_date or defaultkeybind_date	-- reverse compat
				
				--echo ('============OVERRIDE??', keybind_date, defaultkeybind_date)
				
				if not keybind_date or keybind_date == 0 or (keybind_date+0) < defaultkeybind_date then
					keybind_date = defaultkeybind_date
					for _,elem in ipairs(defaultkeybinds) do
						local action = elem[1]
						local keybind = elem[2]
						otset( keybounditems, action, keybind)-- forcibly override any user changes to default binds
					end
				else
					for _, elem in ipairs(defaultkeybinds) do
						local action = elem[1]
						local keybind = elem[2]
						otset( keybounditems, action, otget( keybounditems, action ) or keybind )
					end
				end
			end
		end
	end
	
	if not loaded then
		keybounditems = CopyTable(defaultkeybinds, true)
		keybind_date = defaultkeybind_date
	end
	
	if not otvalidate(keybounditems) then
		keybounditems = {}
	end
	
end

--[[
local function ReadUserUiKeys()
	local fileName = 'Configs/uikeys.txt'
	local file = io.open (fileName, "r")
	while true do
		local line = file:read()
		if not line then 
			break
		end
		if line:find()
	end
end
--]]
----------------------------------------------------------------
--May not be needed with new chili functionality
local function AdjustWindow(window)
	local nx
	if (0 > window.x) then
		nx = 0
	elseif (window.x + window.width > screen0.width) then
		nx = screen0.width - window.width
	end

	local ny
	if (0 > window.y) then
		ny = 0
	elseif (window.y + window.height > screen0.height) then
		ny = screen0.height - window.height
	end

	if (nx or ny) then
		window:SetPos(nx,ny)
	end
end


-- Adding functions because of "handler=true"
local function AddAction(cmd, func, data, types)
	return widgetHandler.actionHandler:AddAction(widget, cmd, func, data, types)
end
local function RemoveAction(cmd, types)
	return widgetHandler.actionHandler:RemoveAction(widget, cmd, types)
end


local function GetFullKey(path, option)
	--local curkey = path .. '_' .. option.key
	local fullkey = ('epic_'.. option.wname .. '_' .. option.key)
	fullkey = fullkey:gsub(' ', '_')
	return fullkey
end

local function GetActionName(path, option)
	local fullkey = GetFullKey(path, option):lower()
	return option.action or fullkey
end

WG.crude.GetActionName = GetActionName

WG.crude.GetOptionHotkey = function(path, option)
	return WG.crude.GetHotkey(GetActionName(path,option))
end


-- returns whether widget is enabled
local function WidgetEnabled(wname)
	local order = widgetHandler.orderList[wname]
	return order and (order > 0)
end
			

-- Kill submenu window
local function KillSubWindow()
	if window_sub_cur then
		if window_sub_cur then
			settings.sub_pos_x = window_sub_cur.x
			settings.sub_pos_y = window_sub_cur.y
		end
		window_sub_cur:Dispose()
		window_sub_cur = nil
		curPath = ''
		
	end
end

-- Update colors for labels of widget checkboxes in widgetlist window
local function checkWidget(widget)
	if WG.cws_checkWidget then
		WG.cws_checkWidget(widget)
	end
end


local function SetCountry(self) 
	echo('Setting country: "' .. self.country .. '" ') 
	
	WG.country = self.country
	settings.country = self.country
	
	WG.lang = self.countryLang 
	settings.lang = self.countryLang
	
	if img_flag then
		img_flag.file = ":cn:".. LUAUI_DIRNAME .. "Images/flags/".. settings.country ..'.png'
		img_flag:Invalidate()
	end
end 

--Make country chooser window
local function MakeFlags()

	if window_flags then return end

	local countries = {}
	local flagdir = 'LuaUI/Images/flags/'
	local files = VFS.DirList(flagdir)
	for i=1,#files do
		local file = files[i]
		local country = file:sub( #flagdir+1, -5 )
		countries[#countries+1] = country
	end
		
	local country_langs = {
		br='bp',
		de='de',
		es='es',
		fi='fi', 
		fr='fr',
		it='it',
		my='my', 
		pl='pl',
		pt='pt',
		pr='es',
	}

	local flagChildren = {}
	
	flagChildren[#flagChildren + 1] = Label:New{ caption='Flag', align='center' }
	flagChildren[#flagChildren + 1] = Button:New{ 
		caption = 'Auto', 
		country = myCountry, 
		countryLang = country_langs[myCountry] or 'en',
		width='50%',
		textColor = color.sub_button_fg,
		backgroundColor = color.sub_button_bg, 
		OnMouseUp = { SetCountry }  
	}
	

	local flagCount = 0
	for i=1, #countries do
		local country = countries[i]
		local countryLang = country_langs[country] or 'en'
		flagCount = flagCount + 1
		flagChildren[#flagChildren + 1] = Image:New{ file=":cn:".. LUAUI_DIRNAME .. "Images/flags/".. country ..'.png', }
		flagChildren[#flagChildren + 1] = Button:New{ caption = country:upper(), 
			width='50%',
			textColor = color.sub_button_fg,
			backgroundColor = color.sub_button_bg,
			country = country,
			countryLang = countryLang,
			OnMouseUp = { SetCountry } 
		}
	end
	local window_height = 300
	local window_width = 170
	window_flags = Window:New{
		caption = 'Choose Your Location...',
		x = settings.sub_pos_x,  
		y = settings.sub_pos_y,  
		clientWidth  = window_width,
		clientHeight = window_height,
		parent = screen0,
		backgroundColor = color.sub_bg,
		children = {
			ScrollPanel:New{
				x=0,y=15,
				right=5,bottom=0+B_HEIGHT,
				
				children = {
					Grid:New{
						columns=2,
						x=0,y=0,
						width='100%',
						height=#flagChildren/2*B_HEIGHT*1,
						children = flagChildren,
					}
				}
			},
			--close button
			Button:New{ caption = 'Close',  x=10, y=0-B_HEIGHT, bottom=5, right=5, 
				OnMouseUp = { function(self) window_flags:Dispose(); window_flags = nil; end },  
				width=window_width-20, backgroundColor = color.sub_close_bg, textColor = color.sub_close_fg,
				},
		}
	}
end

--Make help text window
local function MakeHelp(caption, text)
	local window_height = 400
	local window_width = 400
	
	window_help = Window:New{
		caption = caption or 'Help?',
		x = settings.sub_pos_x,  
		y = settings.sub_pos_y,  
		clientWidth  = window_width,
		clientHeight = window_height,
		parent = screen0,
		backgroundColor = color.sub_bg,
		children = {
			ScrollPanel:New{
				x=0,y=15,
				right=5,
				bottom=B_HEIGHT,
				height = window_height - B_HEIGHT*3 ,
				children = {
					TextBox:New{ x=0,y=10, text = text, textColor = color.sub_fg, width  = window_width - 40, }
				}
			},
			--Close button
			Button:New{ caption = 'Close', OnMouseUp = { function(self) self.parent:Dispose() end }, x=10, bottom=1, right=50, height=B_HEIGHT, backgroundColor = color.sub_close_bg, textColor = color.sub_close_fg, },
		}
	}
end


local function MakeSubWindow(key)
end

local function GetReadableHotkeyMod(mod)
	local modlowercase = mod:lower()
	return (modlowercase:find('a%+') and 'Alt+' or '') ..
		(modlowercase:find('c%+') and 'Ctrl+' or '') ..
		(modlowercase:find('m%+') and 'Meta+' or '') ..
		(modlowercase:find('s%+') and 'Shift+' or '') ..
		''		
end

local function HotKeyBreakdown(hotkey) --convert hotkey string into a standardized hotkey string
	hotkey = hotkey:gsub('numpad%+', 'numpadplus')
	local hotkey_table = explode('+', hotkey)
	local alt, ctrl, meta, shift

	for i=1, #hotkey_table-1 do
		local str2 = hotkey_table[i]:lower()
		if str2 == 'a' or str2 == 'alt' 		then 	alt = true
		elseif str2 == 'c' or str2 == 'ctrl' 	then ctrl = true
		elseif str2 == 's' or str2 == 'shift' 	then shift = true
		elseif str2 == 'm' or str2 == 'meta' 	then meta = true
		end
	end
	
	local mod = '' ..
		(alt and 'A+' or '') ..
		(ctrl and 'C+' or '') ..
		(meta and 'M+' or '') ..
		(shift and 'S+' or '')
	
	local key = hotkey_table[#hotkey_table]
	key = key:gsub( 'numpadplus', 'numpad+')
	
	return mod, key
end
local function GetReadableHotkey(hotkey)
	local mod, key = HotKeyBreakdown(hotkey)
	return GetReadableHotkeyMod(mod) .. CapCase(key)
end

local function GetActionHotkeys(action)
	return Spring.GetActionHotKeys(action)
end

local function GetActionHotkey(action)
	local actionHotkeys = Spring.GetActionHotKeys(action)
	if actionHotkeys and actionHotkeys[1] then
		return (actionHotkeys[1])
	end
	return nil
end

local function AssignKeyBindAction(hotkey, actionName, verbose)
	if verbose then
		--local actions = Spring.GetKeyBindings(hotkey.mod .. hotkey.key)
		local actions = Spring.GetKeyBindings(hotkey)
		if (actions and #actions > 0) then
			echo( 'Warning: There are other actions bound to this hotkey combo (' .. GetReadableHotkey(hotkey) .. '):' )
			for i=1, #actions do
				for actionCmd, actionExtra in pairs(actions[i]) do
					echo ('  - ' .. actionCmd .. ' ' .. actionExtra)
				end
			end
		end
		echo( 'Hotkey (' .. GetReadableHotkey(hotkey) .. ') bound to action: ' .. actionName )
	end
	
	--actionName = actionName:lower()
	if type(hotkey) == 'string' then
		--otset( keybounditems, actionName, hotkey )
		
		--echo("bind " .. hotkey .. " " .. actionName)
		spSendCommands("bind " .. hotkey .. " " .. actionName)
		
		local buildCommand = actionName:find('buildunit_')
		local isUnitCommand
		local isUnitStateCommand
		local isUnitInstantCommand
		
		if custom_cmd_actions[actionName] then
			local number = custom_cmd_actions[actionName]
			isUnitCommand = number == 1
			isUnitStateCommand = number == 2
			isUnitInstantCommand = number == 3
		end
			
		if custom_cmd_actions[actionName] or buildCommand then
			-- bind shift+hotkey as well if needed for unit commands
			local alreadyShift = hotkey:lower():find("s%+") or hotkey:lower():find("shift%+") 
			if not alreadyShift then
				if isUnitCommand or buildCommand then
					spSendCommands("bind S+" .. hotkey .. " " .. actionName)
				elseif isUnitStateCommand or isUnitInstantCommand then
					spSendCommands("bind S+" .. hotkey .. " " .. actionName .. " queued")
				end
			end
		end
			
	end
end

--create spring action for this option. Note: this is used by AddOption()
local function CreateOptionAction(path, option)

	local kbfunc = option.OnChange
	
	if option.type == 'bool' then
		kbfunc = function()
		
			local wname = option.wname
			-- [[ Note: following code between -- [[ and  --]] is just to catch an exception. Is not part of code's logic.
			if not pathoptions[path] or not otget( pathoptions[path], wname..option.key ) then
				Spring.Echo("Warning, detected keybind mishap. Please report this info and help us fix it:")
				Spring.Echo("Option path is "..path)
				Spring.Echo("Option name is "..option.wname..option.key)
				if pathoptions[path] then --pathoptions[path] table still intact, but option table missing
					Spring.Echo("case: option table was missing")
					--pathoptions[path][option.wname..option.key] = option --re-add option table
					otset( pathoptions[path], option.wname..option.key, option ) --re-add option table
				else --both option table & pathoptions[path] was missing, probably was never initialized
					Spring.Echo("case: whole path was never initialized")
					pathoptions[path] = {}
					--pathoptions[path][option.wname..option.key] = option
					otset( pathoptions[path], option.wname..option.key, option )
				end
				-- [f=0088425] Error: LuaUI::RunCallIn: error = 2, ConfigureLayout, [string "LuaUI/Widgets/gui_epicmenu.lua"]:583: attempt to index field '?' (a nil value)
			end
			--]]
			local pathoption = otget( pathoptions[path], wname..option.key )
			newval = not pathoption.value
			pathoption.value = newval
			otset( pathoptions[path], wname..option.key, pathoption )
						
			option.OnChange({checked=newval})
			
			if path == curPath then
				MakeSubWindow(path)
			end
		end
	end
	local actionName = GetActionName(path, option)
	AddAction(actionName, kbfunc, nil, "t")
	
	if option.hotkey then
		local existingRegister = otget( keybounditems, actionName) --check whether existing actionname is already bound with a custom hotkey in zkkey
		if existingRegister == nil then
			Spring.Echo("Epicmenu: " .. option.hotkey .. " (" .. option.key .. ", " .. option.wname..")") --tell user (in infolog.txt) that a widget is adding hotkey
			otset(keybounditems, actionName, option.hotkey ) --save new hotkey if no existing key found (not yet applied. Will be applied in IntegrateWidget())
		end
	end
end

--remove spring action for this option
local function RemoveOptionAction(path, option)
	local actionName = GetActionName(path, option)
	RemoveAction(actionName)
end


-- Unsssign a keybinding from settings and other tables that keep track of related info
local function UnassignKeyBind(actionName, verbose)
	local actionHotkeys = GetActionHotkeys(actionName)
	if actionHotkeys then
		for _,actionHotkey in ipairs(actionHotkeys) do
				
			--[[
				unbind and unbindaction don't work on a command+params, only on the command itself
			--]]
			
			local actionName_split = explode(' ', actionName)
			local actionName_cmd = actionName_split[1]
			
			--echo("unbind " .. actionHotkey .. ' ' .. actionName_cmd:lower()) 
			spSendCommands("unbind " .. actionHotkey .. ' ' .. actionName_cmd:lower()) -- must be lowercase when calling unbind
			--spSendCommands("unbindaction " .. actionName ) --don't do this, unbinding one select would unbind all.
			
			if verbose then
				echo( 'Unbound hotkeys from action: ' .. actionName )
			end
		end
	end
	--otset( keybounditems, actionName, nil )
end

--unassign and reassign keybinds
local function ReApplyKeybinds()
	--[[
	To migrate from uikeys:
	Find/Replace:
	bind\s*(\S*)\s*(.*)
	{ "\2", "\1" },
	]]
	--echo 'ReApplyKeybinds'
	
	if useUiKeys then
		return
	end
	
	for _,elem in ipairs(keybounditems) do
		local actionName = elem[1]
		local hotkey = elem[2]
		--actionName = actionName:lower()
		UnassignKeyBind(actionName, false)
		
		local hotkeyTable = type(hotkey) == 'table' and hotkey or {hotkey}
		
		for _,hotkey2 in ipairs(hotkeyTable) do
			if hotkey2 ~= 'None' then
				AssignKeyBindAction(hotkey2, actionName, false)
			end
		end
		
		--echo("unbindaction(1) ", actionName)
		--echo("bind(1) ", hotkey, actionName)
	end
end

local function AddOption(path, option, wname ) --Note: this is used when loading widgets and in Initialize()
	--echo(path, wname, option)
	if not wname then
		wname = path
	end

	local path2 = path
	if not option then
		if not pathoptions[path] then
			pathoptions[path] = {}
		end
		local pathexploded = explode('/',path)
		local pathend = pathexploded[#pathexploded]
		pathexploded[#pathexploded] = nil
		path = table.concat(pathexploded, '/')
		
		option = {
			type='button',
			name=pathend .. '...',
			OnChange = function(self)
				MakeSubWindow(path2)
			end,
			desc=path2,
		}
	end
	
	if not pathoptions[path] then
		AddOption( path )
	end
	
	if not option.key then
		option.key = option.name
	end
	option.wname = wname
	
	local curkey = path .. '_' .. option.key
	--local fullkey = ('epic_'.. curkey)
	local fullkey = GetFullKey(path, option)
	fullkey = fullkey:gsub(' ', '_')
	
	--get spring config setting
	local valuechanged = false
	local newval
	if option.springsetting ~= nil then --nil check as it can be false but maybe not if springconfig only assumes numbers
		newval = Spring.GetConfigInt( option.springsetting, 0 )
		if option.type == 'bool' then
			newval = IntToBool(newval)
		end
	else
		--load option from widget settings (LuaUI/Config/ZK_data.lua).
		--Read/write is handled by widgethandler; see widget:SetConfigData and widget:GetConfigData
		if settings.config[fullkey] ~= nil then --nil check as it can be false
			newval = settings.config[fullkey]
		end
	end
	
	if option.type ~= 'button' and option.type ~= 'label' and option.default == nil then
		if option.value ~= nil then
			option.default = option.value
		else
			option.default = newval
		end	
	end
	
	
	if newval ~= nil and option.value ~= newval then --must nilcheck newval
		valuechanged = true
		option.value = newval
	end
	
	
	
	local origOnChange = option.OnChange or function() end
	
	local controlfunc
	if option.type == 'button' then
		controlfunc = 
			function(self)
				if option.action then --if keybindings supplied by widgets
					spSendCommands{option.action} 
				end
			end
	elseif option.type == 'bool' then
		
		controlfunc = 
			function(self)
				if self then
					option.value = self.checked
				end
				if option.springsetting then --if widget supplies option for springsettings
					Spring.SetConfigInt( option.springsetting, BoolToInt(option.value) )
				end
				settings.config[fullkey] = option.value
			end

	elseif option.type == 'number' then
		if option.valuelist then
			option.min 	= 1
			option.max 	= #(option.valuelist)
			option.step	= 1
		end
		--option.desc_orig = option.desc or ''	
		controlfunc =
			function(self) 
				if self then
					if option.valuelist then
						option.value = option.valuelist[self.value]
					else
						option.value = self.value
					end
					--self.tooltip = option.desc_orig .. ' - Current: ' .. option.value
				end
				
				if option.springsetting then
					if not option.value then
						echo ('<EPIC Menu> Error #444', fullkey)
					else
						Spring.SetConfigInt( option.springsetting, option.value )
					end
				end
				settings.config[fullkey] = option.value
			end
	
	elseif option.type == 'colors' then
		controlfunc = 
			function(self) 
				if self then
					option.value = self.color
				end
				settings.config[fullkey] = option.value
			end
	
	elseif option.type == 'list' then
		controlfunc = 
			function(key)
				option.value = key
				settings.config[fullkey] = option.value
			end
	elseif option.type == 'radioButton' then
		controlfunc = 
			function(key)
				option.value = key
				settings.config[fullkey] = option.value
				
				if path == curPath then
					MakeSubWindow(path) --remake button/checkbox
				end
			end			
	end
	option.OnChange = function(self) 
		controlfunc(self) --note: 'self' in this context will be refer to the button/checkbox/slider state provided by Chili UI
		origOnChange(option)
	end
	
	--call onchange once
	if valuechanged and option.type ~= 'button' and (origOnChange ~= nil) 
		--and not option.springsetting --need a different solution
		then 
		origOnChange(option)
	end
	
	--Keybindings
	if option.type == 'button' or option.type == 'bool' then
		local actionName = GetActionName(path, option)
		
		--migrate from old logic, make sure this is done before setting orig_key
		if option.hotkey and type(option.hotkey) == 'table' then
			option.hotkey = option.hotkey.mod .. option.hotkey.key --change hotkey table into string
		end
		
		if option.hotkey then
		  local orig_hotkey = ''
		  orig_hotkey = option.hotkey
		  option.orig_hotkey = orig_hotkey
		end
		
		CreateOptionAction(path, option)
		
	--Keybinds for radiobuttons
	elseif option.type == 'radioButton' then --if its a list of checkboxes:
		for i=1, #option.items do --prepare keybinds for each of radioButton's checkbox
			local item = {} 
			item.wname = wname.."radioButton" -- wname is needed by Hotkey to 'AddAction'
			item.key = option.items[i].key
			item.hotkey = option.items[i].hotkey
			item.OnChange = function() option.OnChange(item.key) end --encapsulate OnChange() with a fixed input (item's key). Is needed for Hotkey
			local actionName = GetActionName(path, item)
			if item.hotkey then
			  local orig_hotkey = ''
			  orig_hotkey = item.hotkey
			  item.orig_hotkey = orig_hotkey
			end
			
			CreateOptionAction(path,item)
			
			alloptions[path..wname..item.key] = item --is used to store options but will not be used to make button. Is for random stuff now.
		end			
	end
	
	otset( pathoptions[path], wname..option.key, option )--is used for remake epicMenu's button(s)
	alloptions[path..wname..option.key] = option --is used for random stuff now.
	
end

local function RemOption(path, option, wname )
	if not pathoptions[path] then
		--this occurs when a widget unloads itself inside :init
		--echo ('<epic menu> error #333 ', wname, path)
		--echo ('<epic menu> ...error #333 ', (option and option.key) )
		return
	end
	RemoveOptionAction(path, option)	
	otset( pathoptions[path], wname..option.key, nil )
	alloptions[path..wname..option.key] = nil
	if option.type == 'radioButton' then
		for i=1, #option.items do
			local itemsKey = option.items[i].key
			alloptions[path..wname..itemsKey] = nil
		end
	end
end


-- sets key and wname for each option so that GetOptionHotkey can work before widget initialization completes
local function PreIntegrateWidget(w)
	
	local options = w.options
	if type(options) ~= 'table' then
		return
	end
	
	local wname = w.whInfo.name
	local defaultpath = w.options_path or ('Settings/Misc/' .. wname)
	
	if w.options.order then
		echo ("<EPIC Menu> " .. wname ..  ", don't index an option with the word 'order' please, it's too soon and I'm not ready.")
		w.options.order = nil
	end
	
	--Generate order table if it doesn't exist
	if not w.options_order then
		w.options_order = {}
		for k,v in pairs(options) do
			w.options_order[#(w.options_order) + 1] = k
		end
	end
	

	for i=1, #w.options_order do
		local k = w.options_order[i]
		local option = options[k]
		if not option then
			Spring.Log(widget:GetInfo().name, LOG.ERROR,  '<EPIC Menu> Error in loading custom widget settings in ' .. wname .. ', order table incorrect.' )
			return
		end
		
		option.key = k
		option.wname = wname
	end
end


--(Un)Store custom widget settings for a widget
local function IntegrateWidget(w, addoptions, index)
	
	local options = w.options
	if type(options) ~= 'table' then
		return
	end
	
	local wname = w.whInfo.name
	local defaultpath = w.options_path or ('Settings/Misc/' .. wname)
	
	
	--[[
	--If a widget disables itself in widget:Initialize it will run the removewidget before the insertwidget is complete. this fix doesn't work
	if not WidgetEnabled(wname) then
		return
	end
	--]]
	
	if w.options.order then
		echo ("<EPIC Menu> " .. wname ..  ", don't index an option with the word 'order' please, it's too soon and I'm not ready.")
		w.options.order = nil
	end
	
	--Generate order table if it doesn't exist
	if not w.options_order then
		w.options_order = {}
		for k,v in pairs(options) do
			w.options_order[#(w.options_order) + 1] = k
		end
	end
	
	
	for i=1, #w.options_order do
		local k = w.options_order[i]
		local option = options[k]
		if not option then
			Spring.Log(widget:GetInfo().name, LOG.ERROR,  '<EPIC Menu> Error in loading custom widget settings in ' .. wname .. ', order table incorrect.' )
			return
		end
		
		--Add empty onchange function if doesn't exist
		if not option.OnChange or type(option.OnChange) ~= 'function' then
			w.options[k].OnChange = function(self) end
		end
		
		--store default
		w.options[k].default = w.options[k].value
		
		
		option.key = k
		option.wname = wname
		
		local origOnChange = w.options[k].OnChange
		
		if option.type ~= 'button' then
			option.OnChange = 
				function(self)
					if self then
						w.options[k].value = self.value
					end
					origOnChange(self)
				end
		else
			option.OnChange = 
				function(self)
					origOnChange(self)
				end
		end
		
		local path = option.path or defaultpath
		
		
		-- [[
		local value = w.options[k].value
		w.options[k].value = nil
		w.options[k].priv_value = value
		
		--setmetatable( w.options[k], temp )
		--local temp = w.options[k]
		--w.options[k] = {}
		w.options[k].__index = function(t, key)
			if key == 'value' then
				--[[
				if( not wname:find('Chili Chat') ) then
					echo ('get val', wname, k, key, t.priv_value)
				end
				--]]
				--return t.priv_value
				return t.priv_value
			end
		end
		
		w.options[k].__newindex = function(t, key, val)
			-- For some reason this is called twice per click with the same parameters for most options
			-- a few rare options have val = nil for their second call which resets the option.
			
			if key == 'value' then
				if val ~= nil then -- maybe this isn't needed
				  --echo ('set val', wname, k, key, val)
				  t.priv_value = val
				  
				  local fullkey = GetFullKey(path, option)
				  fullkey = fullkey:gsub(' ', '_')
				  settings.config[fullkey] = option.value
				end
			else
			  rawset(t,key,val)
			end
			
		end
		
		setmetatable( w.options[k], w.options[k] )
		--]]
		if addoptions then
			AddOption(path, option, wname )
		else
			RemOption(path, option, wname )
		end
		
	end
	
	MakeSubWindow(curPath)
	
	
	ReApplyKeybinds() --reapply keybinds when widget load/removed (incase widget alter keybinds)
	
end

--Store custom widget settings for all active widgets
local function AddAllCustSettings()
	local cust_tree = {}
	for i=1,#widgetHandler.widgets do
		IntegrateWidget(widgetHandler.widgets[i], true, i)
	end
end

local function RemakeEpicMenu()
end


-- Spring's widget list
local function ShowWidgetList(self)
	spSendCommands{"luaui selector"} 
end

-- Crudemenu's widget list
WG.crude.ShowWidgetList2 = function(self)
	MakeWidgetList()
end

WG.crude.ShowFlags = function()
	MakeFlags()
end

--Make little window to indicate user needs to hit a keycombo to save a keybinding
local function MakeKeybindWindow( path, option, hotkey ) 
	local window_height = 80
	local window_width = 300
	
	get_key = true
	kb_path = path
	kb_action = GetActionName(path, option)
	
	UnassignKeyBind(kb_action, true) -- 2nd param = verbose
	--otset( keybounditems, kb_action, nil )
	otset( keybounditems, kb_action, 'None' )
		
	window_getkey = Window:New{
		caption = 'Set a HotKey',
		x = (scrW-window_width)/2,  
		y = (scrH-window_height)/2,  
		clientWidth  = window_width,
		clientHeight = window_height,
		parent = screen0,
		backgroundColor = color.sub_bg,
		resizable=false,
		draggable=false,
		children = {
			Label:New{ y=10, caption = 'Press a key combo', textColor = color.sub_fg, },
			Label:New{ y=30, caption = '(Hit "Escape" to clear keybinding)', textColor = color.sub_fg, },
		}
	}
end

--Get hotkey action and readable hotkey string. Note: this is used in MakeHotkeyedControl() which make hotkey handled by Chili.
local function GetHotkeyData(path, option)
	local actionName = GetActionName(path, option)
	--local hotkey = keybounditems[actionName]
	local hotkey = otget( keybounditems, actionName )
	if type(hotkey) == 'table' then
		hotkey = hotkey[1]
	end
	if hotkey and hotkey ~= 'none' then --if ZKkey contain definitive hotkey: return zkkey's hotkey
		if hotkey:find('%+%+') then
			hotkey = hotkey:gsub( '%+%+', '+plus' )
		end
		
		return GetReadableHotkey(hotkey) 
	end
	if (not hotkey ) and option.hotkey then  --if widget supplied default hotkey: return widget's hotkey (this only effect hotkey on Chili menu)
		return option.hotkey
	end
	
	return 'None' --show "none" on epicmenu's menu
end

--Make a stack with control and its hotkey button
local function MakeHotkeyedControl(control, path, option)

	local hotkeystring = GetHotkeyData(path, option)
	local kbfunc = function() 
			if not get_key then
				--MakeKeybindWindow( path, option, hotkey ) 
				MakeKeybindWindow( path, option ) 
			end
		end

	local hklength = math.max( hotkeystring:len() * 10, 20)
	local control2 = control
	control.x = 0
	control.right = hklength+2 --room for hotkey button on right side?
	control:DetectRelativeBounds()
	
	local hkbutton = Button:New{
		minHeight = 30,
		--right=0, --Note: uncommenting this entry cause hotkey-button's position to overlap with control-button's position. It happen after Chili merge/update (???)
		width = hklength,
		--x=-30,
		caption = hotkeystring, 
		OnMouseUp = { kbfunc },
		backgroundColor = color.sub_button_bg,
		textColor = color.sub_button_fg, 
		tooltip = 'Hotkey: ' .. hotkeystring,
	}
	
	return StackPanel:New{
		width = "100%",
		orientation='horizontal',
		resizeItems = false,
		centerItems = false,
		autosize = true,
		itemMargin = {0,0,0,0},
		margin = {0,0,0,0},
		itemPadding = {2,0,-hklength-2,0}, --{left,top,right,bottom}. Note: removing -hklength-2 padding causes wide empty space to appear between control-buttons and hotkey-buttons. This happen after Chili update/merge (???)
		padding = {0,0,0,0},
		children={
			control2,
			hkbutton
		},
	}
end

local function ResetWinSettings(path)
	for _,elem in ipairs(pathoptions[path]) do
		local option = elem[2]
		
		if not ({button=1, label=1, menu=1})[option.type] then
			if option.default ~= nil then --fixme : need default
				if option.type == 'bool' or option.type == 'number' then
					option.value = option.valuelist and GetIndex(option.valuelist, option.default) or option.default
					option.checked = option.value
					option.OnChange(option)
				elseif option.type == 'list' or option.type == 'radioButton' then
					option.value = option.default
					option.OnChange(option.default)
				elseif option.type == 'colors' then
					option.color = option.default
					option.OnChange(option)
				end
			else
				Spring.Log(widget:GetInfo().name, LOG.ERROR, '<EPIC Menu> Error #627', option.name, option.type)
			end
		end
	end
end

--[[ WIP
WG.crude.MakeHotkey = function(path, optionkey)
	local option = pathoptions[path][optionkey]
	local hotkey, hotkeystring = GetHotkeyData(path, option)
	if not get_key then
		MakeKeybindWindow( path, option, hotkey ) 
	end
	
end
--]]

-- Make submenu window based on index from flat window list
--local function MakeSubWindow(key)
MakeSubWindow = function(path)
	
	if not pathoptions[path] then return end
	
	local explodedpath = explode('/', path)
	explodedpath[#explodedpath] = nil
	local parent_path = table.concat(explodedpath,'/')
	
	local settings_height = #(pathoptions[path]) * B_HEIGHT
	local settings_width = 270
	
	local tree_children = {}
	local hotkeybuttons = {}
	
	for _,elem in ipairs(pathoptions[path]) do
		local option = elem[2]

		local optionkey = option.key
		
		--fixme: shouldn't be needed
		if not option.OnChange then
			option.OnChange = function(self) end
		end
		if not option.desc then
			option.desc = ''
		end
		
		
		if option.advanced and not settings.config['epic_Settings_Show_Advanced_Settings'] then
			--do nothing
		elseif option.type == 'button' then
			local hide = false
			
			if option.wname == 'epic' then --menu
				local menupath = option.desc
				if pathoptions[menupath] and #(pathoptions[menupath]) == 0 then
					hide = true
					settings_height = settings_height - B_HEIGHT
				end
			end
			
			if not hide then
				local button = Button:New{
					x=0,
					--right = 30,
					minHeight = 30,
					caption = option.name, 
					OnMouseUp = {option.OnChange},
					backgroundColor = color.sub_button_bg,
					textColor = color.sub_button_fg, 
					tooltip = option.desc
				}
				tree_children[#tree_children+1] = MakeHotkeyedControl(button, path, option)
			end
			
		elseif option.type == 'label' then	
			tree_children[#tree_children+1] = Label:New{ caption = option.value or option.name, textColor = color.sub_header, }
			
		elseif option.type == 'text' then	
			tree_children[#tree_children+1] = 
				Button:New{
					width = "100%",
					minHeight = 30,
					caption = option.name, 
					OnMouseUp = { function() MakeHelp(option.name, option.value) end },
					backgroundColor = color.sub_button_bg,
					textColor = color.sub_button_fg, 
					tooltip=option.desc
				}
			
		elseif option.type == 'bool' then				
			local chbox = Checkbox:New{ 
				x=0,
				right = 35,
				caption = option.name, 
				checked = option.value or false, 
				
				OnMouseUp = { option.OnChange, }, 
				textColor = color.sub_fg, 
				tooltip   = option.desc,
			}
			tree_children[#tree_children+1] = MakeHotkeyedControl(chbox,  path, option)
			
		elseif option.type == 'number' then	
			settings_height = settings_height + B_HEIGHT
			tree_children[#tree_children+1] = Label:New{ caption = option.name, textColor = color.sub_fg, }
			if option.valuelist then
				option.value = GetIndex(option.valuelist, option.value)
			end
			tree_children[#tree_children+1] = 
				Trackbar:New{ 
					width = "100%",
					caption = option.name, 
					value = option.value, 
					trackColor = color.sub_fg, 
					min=option.min or 0, 
					max=option.max or 100, 
					step=option.step or 1, 
					OnMouseUp = { option.OnChange }, 
					tooltip=option.desc,
					--useValueTooltip=true,
				}
			
		elseif option.type == 'list' then	
			tree_children[#tree_children+1] = Label:New{ caption = option.name, textColor = color.sub_header, }
			local items = {};
			for i=1, #option.items do
				local item = option.items[i]
				settings_height = settings_height + B_HEIGHT
				tree_children[#tree_children+1] = Button:New{
						width = "100%",
						caption = item.name, 
						OnMouseUp = { function(self) option.OnChange(item.key) end },
						backgroundColor = color.sub_button_bg,
						textColor = color.sub_button_fg, 
						tooltip=item.desc,
					}
			end
			--[[
			tree_children[#tree_children+1] = ComboBox:New {
				items = items;
			}
			]]--
		elseif option.type == 'radioButton' then	
			tree_children[#tree_children+1] = Label:New{ caption = option.name, textColor = color.sub_header, }
			for i=1, #option.items do
				local item = {} 
				item.wname = option.wname.."radioButton"	-- wname is needed by Hotkey to 'AddAction'
				item.name = option.items[i].name --is needed by checkbox caption
				item.key = option.items[i].key --is needed to set checkbox status
				item.desc = option.items[i].desc --is needed for checkbox tooltip
				item.OnChange = function() option.OnChange(item.key) end --encapsulate OnChange() with a fixed input (item.key). Is needed for Hotkey
				settings_height = settings_height + B_HEIGHT
				tree_children[#tree_children+1] = MakeHotkeyedControl(
					Checkbox:New{
						x=0,
						right = 35,
						caption = item.name, 
						checked = (option.value == item.key), 
						OnMouseUp = {function(self) option.OnChange(item.key) end},
						textColor = color.sub_fg,
						tooltip=item.desc,
					}, path, item)
			end			
		elseif option.type == 'colors' then
			settings_height = settings_height + B_HEIGHT*2.5
			tree_children[#tree_children+1] = Label:New{ caption = option.name, textColor = color.sub_fg, }
			tree_children[#tree_children+1] = 
				Colorbars:New{
					width = "100%",
					height = B_HEIGHT*2,
					tooltip=option.desc,
					color = option.value or {1,1,1,1},
					OnMouseUp = { option.OnChange, },
				}
				
		end
	end
	
	local window_height = 400
	if settings_height < window_height then
		window_height = settings_height+10
	end
	local window_width = 300
	
		
	local window_children = {}
	window_children[#window_children+1] =
		ScrollPanel:New{
			x=0,y=15,
			bottom=B_HEIGHT+20,
			width = '100%',
			children = {
				StackPanel:New{
					x=0,
					y=0,
					right=0,
					orientation = "vertical",
					--width  = "100%",
					height = "100%",
					backgroundColor = color.sub_bg,
					children = tree_children,
					itemMargin = {2,2,2,2},
					resizeItems = false,
					centerItems = false,
					autosize = true,
				},
				
			}
		}
	
	window_height = window_height + B_HEIGHT
	local backButton 
	--back button
	if parent_path then
		window_children[#window_children+1] = Button:New{ caption = 'Back', OnMouseUp = { KillSubWindow, function() MakeSubWindow(parent_path) end,  }, 
			backgroundColor = color.sub_back_bg,textColor = color.sub_back_fg, x=0, bottom=1, width='33%', height=B_HEIGHT, }
	end
	
	
	--reset button
	window_children[#window_children+1] = Button:New{ caption = 'Reset', OnMouseUp = { function() ResetWinSettings(path); RemakeEpicMenu(); end }, 
		textColor = color.sub_close_fg, backgroundColor = color.sub_close_bg, width='33%', x='33%', right='33%', bottom=1, height=B_HEIGHT, }
	
	
	--close button
	window_children[#window_children+1] = Button:New{ caption = 'Close', OnMouseUp = { KillSubWindow }, 
		textColor = color.sub_close_fg, backgroundColor = color.sub_close_bg, width='33%', x='66%', right=1, bottom=1, height=B_HEIGHT, }
	
	
	
	KillSubWindow()
	curPath = path -- must be done after KillSubWindow
	window_sub_cur = Window:New{  
		caption=path,
		x = settings.sub_pos_x,  
		y = settings.sub_pos_y, 
		clientWidth = window_width,
		clientHeight = window_height+B_HEIGHT*4,
		minWidth = 250,
		minHeight = 350,		
		--resizable = false,
		parent = settings.show_crudemenu and screen0 or nil,
		backgroundColor = color.sub_bg,
		children = window_children,
	}
	AdjustWindow(window_sub_cur)
end

-- Show or hide menubar
local function ShowHideCrudeMenu()
	--WG.crude.visible = settings.show_crudemenu -- HACK set it to wg to signal to player list 
	if settings.show_crudemenu then
		if window_crude then
			screen0:AddChild(window_crude)
			--WG.chat.showConsole()
			--window_crude:UpdateClientArea()
		end
		if window_sub_cur then
			screen0:AddChild(window_sub_cur)
		end
	else
		if window_crude then
			screen0:RemoveChild(window_crude)
			--WG.chat.hideConsole()
		end
		if window_sub_cur then
			screen0:RemoveChild(window_sub_cur)
		end
	end
	if window_sub_cur then
		AdjustWindow(window_sub_cur)
	end
end

local function MakeMenuBar()
	local btn_padding = {4,3,2,2}
	local btn_margin = {0,0,0,0}
    local exit_menu_width = 210
    local exit_menu_height = 280
    local exit_menu_btn_width = 7*exit_menu_width/8
    local exit_menu_btn_height = max(exit_menu_height/8, 30)
    local exit_menu_cancel_width = exit_menu_btn_width/2
    local exit_menu_cancel_height = 2*exit_menu_btn_height/3

	local crude_width = 445
	local crude_height = B_HEIGHT+10
	

	lbl_fps = Label:New{ name='lbl_fps', caption = 'FPS:', textColor = color.sub_header,  }
	lbl_gtime = Label:New{ name='lbl_gtime', caption = 'Time:', width = 45, height=5, textColor = color.sub_header,  }
	lbl_clock = Label:New{ name='lbl_clock', caption = 'Clock:', width = 45, height=5, textColor = color.main_fg, } -- autosize=false, }
	img_flag = Image:New{ tooltip='Choose Your Location', file=":cn:".. LUAUI_DIRNAME .. "Images/flags/".. settings.country ..'.png', width = 16,height = 11, OnClick = { MakeFlags }, margin={4,4,4,4}  }
	
	local screen_width,screen_height = Spring.GetWindowGeometry()
	
	window_exit = Window:New{
		name='exitwindow',
		x = screen_width/2 - exit_menu_width/2,  
		y = screen_height/2 - exit_menu_height/2,  
		dockable = false,
		clientWidth = exit_menu_width,
		clientHeight = exit_menu_height,
		draggable = false,
		tweakDraggable = true,
		resizable = false,
		minimizable = false,
		backgroundColor = color.main_bg,
		color = {nil,nil,nil,0.5},
		margin = {0,0,0,0},
		padding = {0,0,0,0},
		
		children = {
				
			Label:New{ 
				caption = 'Would you like to quit?', 
				width = exit_menu_width,
                x = 0,
                y = 2*exit_menu_height/64,
				align="center",
				textColor = color.main_fg },
			
			Button:New{
                caption = "Vote Resign",
                OnMouseUp = { function()
						spSendCommands("say !voteresign") --after this gui_chili_vote.lua will handle vote GUI
						screen0:RemoveChild(window_exit)
						exitWindowVisible = false
					end, },
				tooltip = "Ask teammate to resign",
				height=exit_menu_btn_height, 
				width=exit_menu_btn_width,
                x = exit_menu_width/2 - exit_menu_btn_width/2, 
                y = 20*exit_menu_height/64 - exit_menu_btn_height/2, 
			},
			
			Button:New{
                caption = "Resign and Spectate",
                OnMouseUp = { function()
						spSendCommands{"spectator"}
						screen0:RemoveChild(window_exit)
						exitWindowVisible = false
					end, },
				tooltip = "Abandon team and be spectator",
				height=exit_menu_btn_height, 
				width=exit_menu_btn_width,
                x = exit_menu_width/2 - exit_menu_btn_width/2, 
                y = 30*exit_menu_height/64 - exit_menu_btn_height/2, 
			},
			
			
			Button:New{
				caption = "Exit game", OnMouseUp = { function() spSendCommands{"quit","quitforce"} end, },
				tooltip = "Leave game completely.",
				height=exit_menu_btn_height, 
				width=exit_menu_btn_width,
                x = exit_menu_width/2 - exit_menu_btn_width/2,  
                y = 40*exit_menu_height/64 - exit_menu_btn_height/2,
			},
			
			Button:New{
				caption = "Cancel", 
				OnMouseUp = { function() 
						screen0:RemoveChild(window_exit) 
						exitWindowVisible = false
					end, }, 
			
				height=exit_menu_cancel_height, 
				width=exit_menu_cancel_width,
                x = 4*exit_menu_width/8, -- exit_menu_cancel_width,
                y = 58*exit_menu_height/64 - exit_menu_cancel_height/2,
			},
		},
	}
	
	screen0:RemoveChild(window_exit)
		
	window_crude = Window:New{
		name='epicmenubar',
		right = 0,  
		y = 50, -- resbar height
		dockable = true,
		clientWidth = crude_width,
		clientHeight = crude_height,
		draggable = false,
		tweakDraggable = true,
		resizable = false,
		minimizable = false,
		backgroundColor = color.main_bg,
		color = {nil,nil,nil,0.5},
		margin = {0,0,0,0},
		padding = {0,0,0,0},
		
		children = {
			StackPanel:New{
				name='stack_main',
				orientation = 'horizontal',
				width = '100%',
				height = '100%',
				resizeItems = false,
				padding = {0,0,0,0},
				itemPadding = {1,1,1,1},
				itemMargin = {1,1,1,1},
				autoArrangeV = false,
				autoArrangeH = false,
						
				children = {
					--GAME LOGO GOES HERE
					Image:New{ tooltip = title_text, file = title_image, height=B_HEIGHT, width=B_HEIGHT, },
					
					-- odd-number button width keeps image centered
					Button:New{
						caption = "", OnMouseUp = { function() MakeSubWindow('Game') end, }, textColor=color.game_fg, height=B_HEIGHT+4, width=B_HEIGHT+5,
						padding = btn_padding, margin = btn_margin,	tooltip = 'Game Actions and Settings...',
						children = {
							Image:New{file=LUAUI_DIRNAME .. 'Images/epicmenu/game.png', height=B_HEIGHT-2,width=B_HEIGHT-2},
						},
					},
					Button:New{
						caption = "", OnMouseUp = { function() MakeSubWindow('Settings') end, }, textColor=color.menu_fg, height=B_HEIGHT+4, width=B_HEIGHT+5,
						padding = btn_padding, margin = btn_margin,	tooltip = 'General Settings...', 
						children = {
							Image:New{ tooltip = 'Settings', file=LUAUI_DIRNAME .. 'Images/epicmenu/settings.png', height=B_HEIGHT-2,width=B_HEIGHT-2, },
						},
					},
					Button:New{
						caption = "", OnMouseUp = { function() spSendCommands{"luaui tweakgui"} end, }, textColor=color.menu_fg, height=B_HEIGHT+4, width=B_HEIGHT+5, 
						padding = btn_padding, margin = btn_margin, tooltip = "Move and resize parts of the user interface (\255\0\255\0Ctrl+F11\008) (Hit ESC to exit)",
						children = {
							Image:New{ file=LUAUI_DIRNAME .. 'Images/epicmenu/move.png', height=B_HEIGHT-2,width=B_HEIGHT-2, },
						},
					},
					
					Grid:New{
						height = '100%',
						width = 100,
						columns = 2,
						rows = 2,
						resizeItems = false,
						margin = {0,0,0,0},
						padding = {0,0,0,0},
						itemPadding = {1,1,1,1},
						itemMargin = {1,1,1,1},
						
						
						children = {
							--Label:New{ caption = 'Vol', width = 20, textColor = color.main_fg },
							Image:New{ tooltip = 'Volume', file=LUAUI_DIRNAME .. 'Images/epicmenu/vol.png', width= 18,height= 18, },
							Trackbar:New{
								tooltip = 'Volume',
								height=15,
								width=70,
								trackColor = color.main_fg,
								value = spGetConfigInt("snd_volmaster", 50),
								OnChange = { function(self)	spSendCommands{"set snd_volmaster " .. self.value} end	},
							},
							
							Image:New{ tooltip = 'Music', file=LUAUI_DIRNAME .. 'Images/epicmenu/vol_music.png', width= 18,height= 18, },
							Trackbar:New{
								tooltip = 'Music',
								height=15,
								width=70,
								min = 0,
								max = 1,
								step = 0.01,
								trackColor = color.main_fg,
								value = settings.music_volume or 0.5,
								prevValue = settings.music_volume or 0.5,
								OnChange = { 
									function(self)	
										if (WG.music_start_volume or 0 > 0) then 
											Spring.SetSoundStreamVolume(self.value / WG.music_start_volume) 
										else 
											Spring.SetSoundStreamVolume(self.value) 
										end 
										settings.music_volume = self.value
										WG.music_volume = self.value
										if (self.prevValue > 0 and self.value <=0) then widgetHandler:DisableWidget("Music Player") end 
										if (self.prevValue <=0 and self.value > 0) then widgetHandler:EnableWidget("Music Player") end 
										self.prevValue = self.value
									end	
								},
							},
						},
					
					},

					
					Grid:New{
						orientation = 'horizontal',
						columns = 2,
						rows = 2,
						width = 140,
						height = '100%',
						--height = 40,
						resizeItems = true,
						autoArrangeV = true,
						autoArrangeH = true,
						padding = {0,0,0,0},
						itemPadding = {0,0,0,0},
						itemMargin = {0,0,0,0},
						
						children = {
							
							lbl_fps,
							StackPanel:New{
								orientation = 'horizontal',
								width = 60,
								height = '100%',
								resizeItems = false,
								autoArrangeV = false,
								autoArrangeH = false,
								padding = {0,0,0,0},
								itemMargin = {2,0,0,0},
								children = {
									Image:New{ file= LUAUI_DIRNAME .. 'Images/epicmenu/game.png', width = 20,height = 20,  },
									lbl_gtime,
								},
							},
							
							
							img_flag,
							StackPanel:New{
								orientation = 'horizontal',
								width = 90,
								height = '100%',
								resizeItems = false,
								autoArrangeV = false,
								autoArrangeH = false,
								padding = {0,0,0,0},
								itemMargin = {2,0,0,0},
								children = {
									Image:New{ file= LUAUI_DIRNAME .. 'Images/clock.png', width = 20,height = 20,  },
									lbl_clock,
								},
							},
							
						},
					},
					
					Button:New{
						caption = "", OnMouseUp = { function() MakeSubWindow('Help') end, }, textColor=color.menu_fg, height=B_HEIGHT+4, width=B_HEIGHT+5,
						padding = btn_padding, margin = btn_margin, tooltip = 'Help...', 
						children = {
							Image:New{ file=LUAUI_DIRNAME .. 'Images/epicmenu/questionmark.png', height=B_HEIGHT-2,width=B_HEIGHT-2,  },
						},
					},
					Button:New{
						caption = "", OnMouseUp = { function() 
								if not exitWindowVisible then
									screen0:AddChild(window_exit) 
									exitWindowVisible = true
								end
							end, }, 
						textColor=color.menu_fg, height=B_HEIGHT+4, width=B_HEIGHT+5,
						padding = btn_padding, margin = btn_margin, tooltip = 'Exit or Resign...',
						children = {
							Image:New{file=LUAUI_DIRNAME .. 'Images/epicmenu/quit.png', height=B_HEIGHT-2,width=B_HEIGHT-2,  }, 
						},
					},	
				}
			}
		}
	}
	ShowHideCrudeMenu()
end

--Remakes crudemenu and remembers last submenu open
RemakeEpicMenu = function()
	local lastPath = curPath
	KillSubWindow()
	if lastPath ~= '' then	
		MakeSubWindow(lastPath)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:ViewResize(vsx, vsy)
	scrW = vsx
	scrH = vsy
end


function widget:Initialize()
	
	if (not WG.Chili) then
		widgetHandler:RemoveWidget(widget)
		return
	end
	init = true
	
	
	spSendCommands("unbindaction hotbind")
	spSendCommands("unbindaction hotunbind")
	

	-- setup Chili
	Chili = WG.Chili
	Button = Chili.Button
	Label = Chili.Label
	Colorbars = Chili.Colorbars
	Checkbox = Chili.Checkbox
	Window = Chili.Window
	ScrollPanel = Chili.ScrollPanel
	StackPanel = Chili.StackPanel
	LayoutPanel = Chili.LayoutPanel
	Grid = Chili.Grid
	Trackbar = Chili.Trackbar
	TextBox = Chili.TextBox
	Image = Chili.Image
	Progressbar = Chili.Progressbar
	Colorbars = Chili.Colorbars
	screen0 = Chili.Screen0

	
	
	widget:ViewResize(Spring.GetViewGeometry())
	
	-- Set default positions of windows on first run
	if not settings.sub_pos_x then
		settings.sub_pos_x = scrW/2
		settings.sub_pos_y = scrH/2
	end
	if not settings.wl_x then -- widget list
		settings.wl_h = 0.7*scrH
		settings.wl_w = 300
		
		settings.wl_x = (scrW - settings.wl_w)/2
		settings.wl_y = (scrH - settings.wl_h)/2
	end
	if not keybounditems then
		keybounditems = {}
	end
	if not settings.config then
		settings.config = {}
	end
	
	if not settings.country or settings.country == 'wut' then
		myCountry = select(8, Spring.GetPlayerInfo( Spring.GetLocalPlayerID() ) ) 
		if not myCountry or myCountry == '' then
			myCountry = 'wut'
		end
		settings.country = myCountry
	end
	
	WG.country = settings.country	
	WG.lang = settings.lang
	
		-- add custom widget settings to crudemenu
	AddAllCustSettings()
	

	--this is done to establish order the correct button order
	AddOption('Settings/Reset Settings')
	AddOption('Settings/Audio')
	AddOption('Settings/Camera')
	AddOption('Settings/Graphics')	
	AddOption('Settings/HUD Panels')
	AddOption('Settings/Interface')
	AddOption('Settings/Misc')
	

	-- Add pre-configured button/options found in epicmenu config file
	local options_temp = CopyTable(epic_options, true)
	for i=1, #options_temp do
		local option = options_temp[i]
		AddOption(option.path, option)
	end
	
	-- Clears all saved settings of custom widgets stored in crudemenu's config
	WG.crude.ResetSettings = function()
		for path, _ in pairs(pathoptions) do
			ResetWinSettings(path)
		end
		RemakeEpicMenu()
		echo 'Cleared all settings.'
	end
	
	-- clear all keybindings
	WG.crude.ResetKeys = function()
		keybounditems = {}
		keybounditems = CopyTable(defaultkeybinds, true) --restore with mods zkkey's default value
		
		--restore with widget's default value:
		for path, subtable in pairs ( pathoptions) do
			for _,element in ipairs(subtable) do
				local option = element[2]
				local defaultHotkey = option.orig_hotkey
				if defaultHotkey then
					option.hotkey = defaultHotkey --make chili menu display the default hotkey
					local actionName = GetActionName(path, option)
					otset( keybounditems, actionName, defaultHotkey) --save default hotkey to zkkey
				end
			end
		end
		
		ReApplyKeybinds() --unbind all hotkey and re-attach with stuff in keybounditems table 
		echo 'Reset all hotkeys to default.'
	end
	
	-- get hotkey
	WG.crude.GetHotkey = function(actionName) --Note: declared here because keybounditems must not be empty
		local actionHotkey = GetActionHotkey(actionName)
		--local hotkey = keybounditems[actionName] or actionHotkey
		local hotkey = otget( keybounditems, actionName ) or actionHotkey
		if not hotkey or hotkey == 'none' then
			return ''
		end
		if type(hotkey) == 'table' then
			hotkey = hotkey[1]
		end
		return GetReadableHotkey(hotkey) 
	end
	
	-- set hotkey
	WG.crude.SetHotkey =  function(actionName, hotkey, func) --Note: declared here because pathoptions must not be empty
		if hotkey then
			hotkey = GetReadableHotkey(hotkey) --standardize hotkey (just in case stuff happen)
		end
		if hotkey == '' then 
			hotkey = nil --convert '' into NIL.
		end
		if func then
			if hotkey then
				AddAction(actionName, func, nil, "t") --attach function to action
			else
				RemoveAction(actionName) --detach function from action
			end
		end
		if hotkey then
			AssignKeyBindAction(hotkey, actionName, false) --attach action to keybinds
		else
			UnassignKeyBind(actionName,false) --detach action from keybinds
		end
		otset(keybounditems, actionName, hotkey) --update epicmenu's hotkey table
		for path, subtable in pairs (pathoptions) do 
			for _,element in ipairs(subtable) do
				local option = element[2]
				local indirectActionName = GetActionName(path, option)
				local directActionName = option.action
				if indirectActionName==actionName or directActionName == actionName then
					option.hotkey = hotkey or "None" --update pathoption hotkey for Chili menu display & prevent conflict with hotkey registerd by Chili . Note: LUA is referencing table, so we don't need to change same table elsewhere.
				end
			end
		end
	end
	
	-- Add custom actions for the following keybinds
	AddAction("crudemenu", ActionMenu, nil, "t")
	AddAction("exitwindow", ActionExitWindow, nil, "t")
	
	MakeMenuBar()
	
	useUiKeys = settings.config['epic_Settings/Misc_Use_uikeys.txt']
	
	if not useUiKeys then
		spSendCommands("unbindall")
	else
		echo('You have opted to use the engine\'s uikeys.txt. The menu keybind system will not be used.')
	end
	
	LoadKeybinds()
	ReApplyKeybinds()
	
	-- Override widgethandler functions for the purposes of alerting crudemenu 
	-- when widgets are loaded, unloaded or toggled
	widgetHandler.OriginalInsertWidget = widgetHandler.InsertWidget
	widgetHandler.InsertWidget = function(self, widget)
		PreIntegrateWidget(widget)
		
		local ret = self:OriginalInsertWidget(widget)
		
		if type(widget) == 'table' and type(widget.options) == 'table' then
			IntegrateWidget(widget, true)
			if not (init) then
				RemakeEpicMenu()
			end
		end
		
		
		checkWidget(widget)
		return ret
	end
	
	widgetHandler.OriginalRemoveWidget = widgetHandler.RemoveWidget
	widgetHandler.RemoveWidget = function(self, widget)
		local ret = self:OriginalRemoveWidget(widget)
		if type(widget) == 'table' and type(widget.options) == 'table' then
			IntegrateWidget(widget, false)
			if not (init) then
				RemakeEpicMenu()
			end
		end
		
		checkWidget(widget)
		return ret
	end
	
	widgetHandler.OriginalToggleWidget = widgetHandler.ToggleWidget
	widgetHandler.ToggleWidget = function(self, name)
		local ret = self:OriginalToggleWidget(name)
		
		local w = widgetHandler:FindWidget(name)
		if w then
			checkWidget(w)
		else
			checkWidget(name)
		end
		return ret
	end
	init = false
	
	--intialize remote menu trigger
	WG.crude.OpenPath = function(path) --Note: declared here so that it work in local copy
		MakeSubWindow(path)
	end
	
	--intialize remote menu trigger 2
	WG.crude.ShowMenu = function()  --Note: declared here so that it work in local copy
		if not settings.show_crudemenu then 
			settings.show_crudemenu = true
			ShowHideCrudeMenu()
		end
	end
end

function widget:Shutdown()
	-- Restore widgethandler functions to original states
	if widgetHandler.OriginalRemoveWidget then
		widgetHandler.InsertWidget = widgetHandler.OriginalInsertWidget
		widgetHandler.OriginalInsertWidget = nil

		widgetHandler.RemoveWidget = widgetHandler.OriginalRemoveWidget
		widgetHandler.OriginalRemoveWidget = nil
		
		widgetHandler.ToggleWidget = widgetHandler.OriginalToggleWidget
		widgetHandler.OriginalToggleWidget = nil
	end
	

  if window_crude then
    screen0:RemoveChild(window_crude)
  end
  if window_sub_cur then
    screen0:RemoveChild(window_sub_cur)
  end

  RemoveAction("crudemenu")
 
  -- restore key binds
  --[[
  spSendCommands({
    "bind esc quitmessage",
    "bind esc quitmenu", -- FIXME made for licho, removed after 0.82 release
  })
  --]]
  spSendCommands("unbind esc crudemenu")
end


function widget:GetConfigData()
	SaveKeybinds()
	return settings
end

function widget:SetConfigData(data)
	if (data and type(data) == 'table') then
		if data.versionmin and data.versionmin >= 50 then
			settings = data
		end
	end
	WG.music_volume = settings.music_volume or 0.5
	LoadKeybinds()
end

function widget:Update()
	cycle = cycle%32+1
	if cycle == 1 then
		--Update clock, game timer and fps meter that show on menubar
		if lbl_fps then
			lbl_fps:SetCaption( 'FPS: ' .. Spring.GetFPS() )
		end
		if lbl_gtime then
			lbl_gtime:SetCaption( GetTimeString() )
		end
		if lbl_clock then
			--local displaySeconds = true
			--local format = displaySeconds and "%H:%M:%S" or "%H:%M"
			local format = "%H:%M" --fixme: running game for over an hour pushes time label down
			--lbl_clock:SetCaption( 'Clock\n ' .. os.date(format) )
			lbl_clock:SetCaption( os.date(format) )
		end
	end
end


function widget:KeyPress(key, modifier, isRepeat)
	if key == KEYSYMS.LCTRL 
		or key == KEYSYMS.RCTRL 
		or key == KEYSYMS.LALT
		or key == KEYSYMS.RALT
		or key == KEYSYMS.LSHIFT
		or key == KEYSYMS.RSHIFT
		or key == KEYSYMS.LMETA
		or key == KEYSYMS.RMETA
		or key == KEYSYMS.SPACE
		then
		
		return
	end
	
	local modstring = 
		(modifier.alt and 'A+' or '') ..
		(modifier.ctrl and 'C+' or '') ..
		(modifier.meta and 'M+' or '') ..
		(modifier.shift and 'S+' or '')
	
	--Set a keybinding 
	if get_key then
		get_key = false
		window_getkey:Dispose()
		translatedkey = transkey[ keysyms[''..key]:lower() ] or keysyms[''..key]:lower()
		--local hotkey = { key = translatedkey, mod = modstring, }		
		local hotkey = modstring .. translatedkey	
		
		if key ~= KEYSYMS.ESCAPE then
			--otset( keybounditems, kb_action, hotkey )
			AssignKeyBindAction(hotkey, kb_action, true) -- param4 = verbose
			otset( keybounditems, kb_action, hotkey )
	
		end
		ReApplyKeybinds()
		
		if kb_path == curPath then
			MakeSubWindow(kb_path)
		end
		
		return true
	end
	
end

function ActionExitWindow()
	if exitWindowVisible then
		screen0:RemoveChild(window_exit) 
		exitWindowVisible = false
	else
		screen0:AddChild(window_exit) 
		exitWindowVisible = true
	end						
end

function ActionMenu()
	settings.show_crudemenu = not settings.show_crudemenu
	ShowHideCrudeMenu()
end

function WG.crude.ShowMenu() --// allow other widget to toggle-up Epic-Menu. This'll enable access to game settings' Menu via click on other GUI elements.
	if not settings.show_crudemenu then 
		settings.show_crudemenu = true
		ShowHideCrudeMenu()
	end
end

--// [[ see comments in epicmenu conf (about "radioButton" camera option). UPDATE: propose re-enable "radioButton" camera option
do --Set our prefered camera mode when first screen frame is drawn. The engine always go to default TA at first screen frame, so we need to re-apply our camera settings.
	if Spring.GetGameFrame() == 0 then  --we check if this code is run at midgame (due to /reload). In that case we don't need to re-apply settings (the camera mode is already set at gui_epicmenu.lua\AddOption()).
		local screenFrame = 0
		function widget:DrawScreen() --game event: Draw Screen
			if screenFrame >= 1 then --detect frame no.2
				local option = alloptions["Settings/CameraSettings/CameraCamera Type"] --get camera option we saved earlier in gui_epicmenu.lua\AddOption()
				option.OnChange(option.value) --re-apply our settings 
				Spring.Echo("Epicmenu: Switching to " .. option.value .. " camera mode") --notify in log what happen.
				widgetHandler:RemoveWidgetCallIn("DrawScreen", self) --stop updating "widget:DrawScreen()" event. Note: this is a special "widgetHandler:RemoveCallin" for widget that use "handler=true".
			end
			screenFrame = screenFrame+1
		end
	end
end
--]]