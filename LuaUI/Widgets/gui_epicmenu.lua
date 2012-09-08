function widget:GetInfo()
  return {
    name      = "EPIC Menu",
    desc      = "v1.302 Extremely Powerful Ingame Chili Menu.",
    author    = "CarRepairer",
    date      = "2009-06-02",
    license   = "GNU GPL, v2 or later",
    layer     = -100001,
    handler   = true,
    experimental = false,	
    enabled   = true,
	alwaysStart = true,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetConfigInt    		= Spring.GetConfigInt
local spSendCommands			= Spring.SendCommands

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
local pathorders = {}

WG.GetWidgetOption = function(wname, path, key)  -- still fails if path and key are un-concatenatable
	return (pathoptions and path and key and wname and pathoptions[path] and pathoptions[path][wname..key]) or {}
end 

local exitWindowVisible = false

--------------------------------------------------------------------------------
-- Key bindings
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
local kb_option
local kb_path

local transkey = {
	leftbracket 	= '[',
	rightbracket 	= ']',
	--delete 			= 'del',
	comma 			= ',',
	period 			= '.',
	slash 			= '/',
	backslash 			= '\\',
	
	kp_multiply		= 'numpad*',
	kp_divide		= 'numpad/',
	kp_add			= 'numpad+',
	kp_subract		= 'numpad-',
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
local settings = {
	versionmin = 50,
	lang = 'en',
	widgets = {},
	show_crudemenu = true,
	music_volume = 0.5,
}

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

----------------------------------------------------------------
-- Helper Functions
--[[
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
--[[
local function MergeTable(table1,table2)
  local ret = {}
  CopyTable(ret,table2)
  CopyTable(ret,table1)
  return ret
end
--]]

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



local function HotkeyFromUikey(uikey_hotkey)
	local uikey_table = explode('+', uikey_hotkey)
	local alt, ctrl, meta, shift

	for i=1, #uikey_table do
		local str2 = uikey_table[i]:lower()
		if str2 == 'alt' 		then alt = true
		elseif str2 == 'ctrl' 	then ctrl = true
		elseif str2 == 'shift' 	then shift = true
		elseif str2 == 'meta' 	then meta = true
		end
	end
	
	local modstring = '' ..
		(alt and 'A+' or '') ..
		(ctrl and 'C+' or '') ..
		(meta and 'M+' or '') ..
		(shift and 'S+' or '')
	return {
		key = uikey_table[#uikey_table],
		mod = modstring,
	}
end

local function GetReadableHotkeyMod(mod)
	return (mod:lower():find('a+') and 'Alt+' or '') ..
		(mod:lower():find('c+') and 'Ctrl+' or '') ..
		(mod:lower():find('m+') and 'Meta+' or '') ..
		(mod:lower():find('s+') and 'Shift+' or '') ..
		''		
end


-- Assign a keybinding to settings and other tables that keep track of related info
--local function AssignKeyBind(hotkey, menukey, itemindex, item, verbose)
local function AssignKeyBind(hotkey, path, option, verbose) -- param4 = verbose

	if not (hotkey.key and hotkey.mod) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, '<EPIC Menu> Wacky assign keybind error #1')
		return
	end
	
	local kbfunc = option.OnChange
	
	if option.type == 'bool' then
		kbfunc = function()
			local wname = option.wname
			newval = not pathoptions[path][option.wname..option.key].value	
			pathoptions[path][option.wname..option.key].value	= newval
			
			option.OnChange({checked=newval})
			
			if path == curPath then
				MakeSubWindow(path)
			end
		end
	end
	
	local actionName = GetActionName(path, option)
	
	if verbose then
		local actions = Spring.GetKeyBindings(hotkey.mod .. hotkey.key)
		if (actions and #actions > 0) then
			echo( 'Warning: There are other actions bound to this hotkey combo (' .. GetReadableHotkeyMod(hotkey.mod) .. hotkey.key .. '):' )
			for i=1, #actions do
				for actionCmd, actionExtra in pairs(actions[i]) do
					echo ('  - ' .. actionCmd .. ' ' .. actionExtra)
				end
			end
		end
		echo( 'Hotkey (' .. GetReadableHotkeyMod(hotkey.mod) .. hotkey.key .. ') bound to action: ' .. actionName )
	end
	
	--actionName = actionName:lower()
	settings.keybounditems[actionName] = hotkey
	AddAction(actionName, kbfunc, nil, "t")
	Spring.SendCommands("bind " .. hotkey.mod .. hotkey.key .. " " .. actionName)
end

local function GetUikeyHotkeyStr(action)
	local uikey_hotkey_strs = Spring.GetActionHotKeys(action)
	if uikey_hotkey_strs and uikey_hotkey_strs[1] then
		return (uikey_hotkey_strs[1])
	end
	return false
end

-- Unsssign a keybinding from settings and other tables that keep track of related info
local function UnassignKeyBind(path, option)
	
	local actionName = GetActionName(path, option)
	
	if option.action then
		local uikey_hotkey_str = GetUikeyHotkeyStr(actionName)
		if uikey_hotkey_str then
			-- unbindaction doesn't work on a command+params, must be command only!
			local actionName_split = explode(' ', actionName)
			local actionName_cmd = actionName_split[1]
			--echo('unassign', "unbind " .. uikey_hotkey_str .. ' ' .. actionName_cmd)
			Spring.SendCommands("unbind " .. uikey_hotkey_str .. ' ' .. actionName_cmd) 
		end
	else 
		--echo('unassign', "unbindaction " .. actionName)
		Spring.SendCommands("unbindaction " .. actionName:lower()) -- this only works if lowercased, even if /keyprint says otherwise!
	end
	
	
	settings.keybounditems[actionName] = 'none'
end


local function AddOption(path, option, wname )
--echo(path, wname, option)

	if not wname then
		wname = path
	end

	local path2 = path
	if not option then
		if not pathoptions[path] then
			pathoptions[path] = {}
			pathorders[path] = {}
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
		--load option from widget settings
		if settings.config[fullkey] ~= nil then --nil check as it can be false
			newval = settings.config[fullkey]
		end
	end
	
	if option.default == nil then
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
				if option.action then
					Spring.SendCommands{option.action} 
				end
			end
	elseif option.type == 'bool' then
		
		controlfunc = 
			function(self)
				if self then
					option.value = self.checked
				end
				if option.springsetting then
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
						
		controlfunc = 
			function(self) 
				if self then
					if option.valuelist then
						option.value = option.valuelist[self.value]
					else
						option.value = self.value
					end
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
	
	end
	option.OnChange = function(self)
		controlfunc(self)
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
		
		local uikey_hotkey_str = GetUikeyHotkeyStr(actionName)
		local uikey_hotkey = uikey_hotkey_str and HotkeyFromUikey(uikey_hotkey_str)
		
		if option.hotkey then
		  local orig_hotkey = {}
		  CopyTable(orig_hotkey, option.hotkey)
		  option.orig_hotkey = orig_hotkey
		  echo(option.key, option.orig_hotkey.key)
		end
		
		local hotkey = settings.keybounditems[actionName] or option.hotkey or uikey_hotkey
		if hotkey and hotkey ~= 'none' then
			if uikey_hotkey then
				UnassignKeyBind(path, option)
			end
			AssignKeyBind(hotkey, path, option, false)
		end 
	end
	
	pathoptions[path][wname..option.key] = option
	alloptions[path..wname..option.key] = option
	local temp = #(pathorders[path])
	pathorders[path][temp+1] = wname..option.key
	
	
end

local function RemOption(path, option, wname )
	if not pathorders[path] then
		--this occurs when a widget unloads itself inside :init
		--echo ('<epic menu> error #333 ', wname, path)
		--echo ('<epic menu> ...error #333 ', (option and option.key) )
		return
	end
	for i=1, #pathorders[path] do
		if pathorders[path][i] == (wname..option.key) then
			table.remove(pathorders[path], i)
		end
	end
	pathoptions[path][wname..option.key] = nil
	alloptions[path..wname..option.key] = nil
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
				if(
					not wname:find('Chili Chat')
					) then
					--echo ('get val', wname, k, key, t.priv_value)
				end
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
	if hotkey then
		UnassignKeyBind(path, option)
	end
	
	local window_height = 80
	local window_width = 300
	
	get_key = true
	kb_mkey = menukey
	kb_mindex = i
	kb_item = item
	
	kb_option = option
	kb_path = path
		
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

WG.crude.GetHotkey = function(actionName)
	local hotkey = settings.keybounditems[actionName]
	if not hotkey or hotkey == 'none' then
	  return ''
	end
	return GetReadableHotkeyMod(hotkey.mod) .. CapCase(hotkey.key)
end


--[[
-- is this an improvement?
WG.crude.GetHotkey = function(actionName)
	local hotkey = settings.keybounditems[actionName]
	if not hotkey then
		local fallback = Spring.GetActionHotKeys(actionName)
		if fallback and fallback[1] then
			return CapCase(fallback[1])
		else
			return ''
		end
	end
	return GetReadableHotkeyMod(hotkey.mod) .. CapCase(hotkey.key)
end
--]]


--Get hotkey action and readable hotkey string
local function GetHotkeyData(path, option)
	local actionName = GetActionName(path, option)
	local hotkey = settings.keybounditems[actionName]
	if hotkey and hotkey ~= 'none' then
		return hotkey, GetReadableHotkeyMod(hotkey.mod) .. CapCase(hotkey.key)
	end
	
	return nil, 'None'
end



--Make a stack with control and its hotkey button
local function MakeHotkeyedControl(control, path, option)

	local hotkey, hotkeystring = GetHotkeyData(path, option)
	local kbfunc = function() 
			if not get_key then
				MakeKeybindWindow( path, option, hotkey ) 
			end
		end

	local hklength = math.max( hotkeystring:len() * 10, 20)
	local control2 = control
	control.x = 0
	control.right = hklength+2
	control:DetectRelativeBounds()
	
	local hkbutton = Button:New{
		minHeight = 30,
		right=0,
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
		itemPadding = {2,0,0,0},
		padding = {0,0,0,0},
		children={
			control2,
			hkbutton
		},
	}
end

local function ResetWinSettings(path)
	for _,optionkey in ipairs(pathorders[path]) do
		local option = pathoptions[path][optionkey]
		if option.default ~= nil then --fixme : need default
			if option.type == 'bool' or option.type == 'number' then
				option.value = option.valuelist and GetIndex(option.valuelist, option.default) or option.default
				option.checked = option.value
				option.OnChange(option)
			elseif option.type == 'list' then
				option.value = option.default
				option.OnChange(option.default)
			elseif option.type == 'colors' then
				option.color = option.default
				option.OnChange(option)
			end
		else
			Spring.Log(widget:GetInfo().name, LOG.ERROR, '<EPIC Menu> Error #627', option.name)
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
	
	local settings_height = #(pathorders[path]) * B_HEIGHT
	local settings_width = 270
	
	local tree_children = {}
	local hotkeybuttons = {}
	
	for _,optionkey in ipairs(pathorders[path]) do
		local option = pathoptions[path][optionkey]
		
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
				if pathorders[menupath] and #(pathorders[menupath]) == 0 then
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
					tooltip=option.desc 
				}
			
			
		elseif option.type == 'list' then	
			tree_children[#tree_children+1] = Label:New{ caption = option.name, textColor = color.sub_header, }
			for i=1, #option.items do
				local item = option.items[i]
				settings_height = settings_height + B_HEIGHT 
				tree_children[#tree_children+1] = 
					Button:New{
						width = "100%",
						caption = item.name, 
						OnMouseUp = { function(self) option.OnChange(item.key) end },
						backgroundColor = color.sub_button_bg,
						textColor = color.sub_button_fg, 
						tooltip=item.desc,
					}
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
	WG.crude.visible = settings.show_crudemenu -- HACK set it to wg to signal to player list 
	if settings.show_crudemenu then
		if window_crude then
			screen0:AddChild(window_crude)
			--WG.chat.showConsole()
			window_crude:UpdateClientArea()
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
		
	local crude_width = 425
	local crude_height = B_HEIGHT+10
	

	lbl_fps = Label:New{ name='lbl_fps', caption = 'FPS:', textColor = color.sub_header,  }
	lbl_gtime = Label:New{ name='lbl_gtime', caption = 'Time:', textColor = color.sub_header, align="center" }
	lbl_clock = Label:New{ name='lbl_clock', caption = 'Clock:', width = 35, height=5, textColor = color.main_fg, autosize=false, }
	img_flag = Image:New{ tooltip='Choose Your Location', file=":cn:".. LUAUI_DIRNAME .. "Images/flags/".. settings.country ..'.png', width = 16,height = 11, OnClick = { MakeFlags }, margin={4,4,4,4}  }
	
	local screenWidth,screenHeight = Spring.GetWindowGeometry()
	
	window_exit = Window:New{
		name='exitwindow',
		x = screenWidth*0.5-50,  
		y = screenHeight*0.5-70,  
		dockable = false,
		clientWidth = 120,
		clientHeight = 150,
		draggable = false,
		tweakDraggable = true,
		resizable = false,
		minimizable = false,
		backgroundColor = color.main_bg,
		color = {1,1,1,0.5},
		margin = {0,0,0,0},
		padding = {0,0,0,0},
		
		children = {
				
			Label:New{ 
				caption = 'Leave Battle?', 
				x = 0,
				y = 15,
				width = 120, 
				align="center",
				textColor = color.main_fg },
				
			Button:New{
				caption = "Exit", OnMouseUp = { function() spSendCommands{"quit","quitforce"} end, }, 
				x = 20,  
				y = 46, 
				height=25, 
				width=80,
			},
			
			
			Button:New{
				caption = "Resign", OnMouseUp = { function() spSendCommands{"spectator"} end, }, 
				x = 20,  
				y = 78, 
				height=25, 
				width=80,
			},
			
			Button:New{
				caption = "Cancel", 
				OnMouseUp = { function() 
						screen0:RemoveChild(window_exit) 
						exitWindowVisible = false
					end, }, 
				x = 20,  
				y = 110, 
				height=25, 
				width=80,
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
		color = {1,1,1,0.5},
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
								OnChange = { function(self)	Spring.SendCommands{"set snd_volmaster " .. self.value} end	},
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
						width = 120,
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
								width = 60,
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

function WG.crude.OpenPath(path)
	MakeSubWindow(path)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:ViewResize(vsx, vsy)
	scrW = vsx
	scrH = vsy
end


function widget:Initialize()
	
	Spring.SendCommands("unbindaction quitmenu") -- http://springrts.com/mantis/view.php?id=2944
	
	if (not WG.Chili) then
		widgetHandler:RemoveWidget(widget)
		return
	end
	init = true
	
	
	Spring.SendCommands("unbindaction hotbind")
	Spring.SendCommands("unbindaction hotunbind")
	

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
	if not settings.keybounditems then
		settings.keybounditems = {}
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
	AddOption('Settings/Camera')
	AddOption('Settings/Graphics')	
	AddOption('Settings/Interface')
	AddOption('Settings/Interface/Mouse Cursor')
	AddOption('Settings/Misc')

	
	local options_temp ={}
	CopyTable(options_temp , epic_options);
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
	
	WG.crude.ResetKeys = function()
		for actionName,_ in pairs(settings.keybounditems) do
			--local actionNameL = actionName:lower()
			local actionNameL = actionName
			Spring.SendCommands({"unbindaction " .. actionNameL})
		end
		
		settings.keybounditems = {}
		
		for _,option in pairs(alloptions) do
		    if option.orig_hotkey then
			  AssignKeyBind(option.orig_hotkey, option.path, option, false)
		    end
		end
		
		echo 'Reset all hotkeys to default.'
	end
	
	-- Add actions for keybinds
	AddAction("crudemenu", ActionMenu, nil, "t")
	AddAction("exitwindow", ActionExitWindow, nil, "t")
	-- replace default key binds
	Spring.SendCommands({
		"unbind esc quitmessage",
		"unbind esc quitmenu", --Upgrading to 0.82 doesn't change existing uikeys so pre-0.82 keybinds still apply.
	})
	Spring.SendCommands("bind esc crudemenu")
	Spring.SendCommands("bind shift+esc exitwindow")

	MakeMenuBar()
	
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
  Spring.SendCommands({
    "bind esc quitmessage",
    "bind esc quitmenu", -- FIXME made for licho, removed after 0.82 release
  })
  --]]
  Spring.SendCommands("unbind esc crudemenu")
end

function widget:GetConfigData()
	return settings
end

function widget:SetConfigData(data)
	if (data and type(data) == 'table') then
		if data.versionmin and data.versionmin >= 50 then
			settings = data
		end
	end
	WG.music_volume = settings.music_volume or 0.5
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
		local hotkey = { key = translatedkey, mod = modstring, }		
		
		if key ~= KEYSYMS.ESCAPE then		
			AssignKeyBind(hotkey, kb_path, kb_option, true) -- param4 = verbose
		else
			local actionName = GetActionName(kb_path, kb_option)
			echo( 'Unbound hotkeys from action: ' .. actionName )
		end
		
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