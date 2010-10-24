--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Chat",
    desc      = "v0.38 Chili Chat Console.",
    author    = "CarRepairer, Licho",
    date      = "2009-07-07",
    license   = "GNU GPL, v2 or later",
    layer     = 50,
    experimental = false,
    enabled   = false,
  }
end

include("keysym.h.lua")
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spSendCommands			= Spring.SendCommands

local abs						= math.abs

local echo = Spring.Echo

local Chili
local Button
local Window
local ScrollPanel
local StackPanel
local screen0
local color2incolor
local incolor2color
local myName -- my console name

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local stack_console = nil
local scrollpanel1 = nil
WG.enteringText = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local col_text_in
local col_ally_in
local col_othertext_in
local col_dup_in

local inputtext_inside = false

local lines = {'Loading...'}

local lines_count = 0
local MIN_HEIGHT = 150
local MIN_WIDTH = 300

local def_settings = {
	minversion = 21,
	pos_x = 450,
	pos_y = 0,
	c_width = 400,
	c_height = 200,
}
local settings = def_settings

local rightmargin = 35

local window_console, window_settings

local colorNames = {}
local colors = {}



local function option_remakeConsole()
	remakeConsole()
end


local function option_autoHideChanged() 
	screen0:RemoveChild(window_console)
	if (WG.enteringText or not options.autoHideChat.value)   then 
		screen0:AddChild(window_console)
	end 
end 

options_path = "Settings/Interface/Chat/Console"
options_order = { 'autoHideChat', 'noColorName',  'hideSpec', 'hideAlly', 'hidePoint', 'hideLabel', 'text_height', 'max_lines', 
		'col_text', 'col_ally', 'col_othertext', 'col_dup', 
		}
options = {
	
	
	autoHideChat = {
		name = "Autohide Console",
		type = 'bool',
		value = true, 
		desc = "Auto hides when not typing text",
		OnChange = option_autoHideChanged,
	},
	
	noColorName = {
		name = "Don't Color Name",
		desc = "Color only the brackets around the name with player's team color.",
		type = 'bool',
		value = false,
		OnChange = option_remakeConsole,
	},
	
	text_height = {
		name = 'Text Size',
		type = 'number',
		value = 14,
		min=8,max=30,step=1,
		OnChange = option_remakeConsole,
	},
	
	hideSpec = {
		name = "Hide Spectator Chat",
		type = 'bool',
		value = false,
		OnChange = option_remakeConsole,
		advanced = true,
	},
	hideAlly = {
		name = "Hide Ally Chat",
		type = 'bool',
		value = false,
		OnChange = option_remakeConsole,
		advanced = true,
	},
	hidePoint = {
		name = "Hide Points",
		type = 'bool',
		value = false,
		OnChange = option_remakeConsole,
		advanced = true,
	},
	hideLabel = {
		name = "Hide Labels",
		type = 'bool',
		value = false,
		OnChange = option_remakeConsole,
		advanced = true,
	},
	max_lines = {
		name = 'Maximum Lines (80-300)',
		type = 'number',
		value = 150,
		min=80,max=300,step=1, 
		OnChange = option_remakeConsole,
	},
	
	col_text = {
		name = 'Chat Text',
		type = 'colors',
		value = {1,1,1,1},
		OnChange = option_remakeConsole,
	},
	col_ally = {
		name = 'Ally Text',
		type = 'colors',
		value = {0.2,1,0.2,1},
		OnChange = option_remakeConsole,
	},
	col_othertext = {
		name = 'Other Text',
		type = 'colors',
		value = {0.6,0.6,0.7,1},
		OnChange = option_remakeConsole,
	},
	col_dup = {
		name = 'Duplicate Text',
		type = 'colors',
		value = {1,0.2,0.2,1},
		OnChange = option_remakeConsole,
	},
	
	
	
	
}



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local function setup()
	col_text_in 		= color2incolor(options.col_text.value)
	col_ally_in 		= color2incolor(options.col_ally.value)
	col_othertext_in 	= color2incolor(options.col_othertext.value)
	col_dup_in 			= color2incolor(options.col_dup.value)
	
	local myallyteamid = Spring.GetMyAllyTeamID()
	local playerroster = Spring.GetPlayerList()
	local playercount = #playerroster
	
	myName = Spring.GetPlayerInfo(Spring.GetMyPlayerID())
	
	for i=1,playercount do
		local name,_,_,teamID = Spring.GetPlayerInfo(playerroster[i])
		local inColor = color2incolor(Spring.GetTeamColor(teamID))
		colors[name]= inColor
		if options.noColorName.value then
			colorNames[name] = inColor .. '<' .. col_text_in .. name .. inColor .. '>  '.. col_text_in
		else
			colorNames[name] = inColor .. '<' ..  name .. '>  ' .. col_text_in
		end
	end
end


local function GenerateTextControl(line, remake) 
	
	if (line.mtype == "spectatormessage" and options.hideSpec.value)
		or (line.mtype == "allymessage" and options.hideAlly.value) 
		or (line.mtype == "playerpoint" and options.hidePoint.value) 
		or (line.mtype == "playerlabel" and options.hideLabel.value)
		then
		return
	end
	
	local tx = (line.dup > 1 and (col_dup_in.. line.dup ..'x '.. col_text_in) or col_text_in)..line.text
	
	if (line.dup > 1 and not remake) then
	
		local last = stack_console.children[#(stack_console.children)]
		if last then
			last:SetText(tx)
			last:UpdateClientArea()
		end
	else  
		local lab = Chili.TextBox:New{
		
			width = '100%',
			
			align="left",
			fontsize = options.text_height.value,
			valign="ascender",
			lineSpacing = 0,
			padding = {0,0,0,0},
			--text = tx.."\n",
			text = tx,
			fontOutline = true,
			--[[
			autoHeight=true,
			autoObeyLineHeight=true,
			--]]
		}
		stack_console:AddChild(lab, false)
		stack_console:UpdateClientArea()
	end 
end 


local function makeNewConsole(x, y, w, h)
	local h=h

	scrollpanel1 = ScrollPanel:New{
		x = 0,
		y = 0,
		bottom = inputtext_inside and 25 or 0,
		right= inputtext_inside and 0 or 6,
		--horizontalScrollbar = false,
		verticalSmartScroll = true,
		disableChildrenHitTest = true,
	}
	
	stack_console = StackPanel:New{
		parent = scrollpanel1,
		x = 0,
		y = 0,
		width='100%',
		height = 10,
		resizeItems=false,
		itemPadding  = {1,1,1,1},
		itemMargin  = {1,1,1,1},
		autosize = true,
		preserveChildrenOrder=true,
	}
	

	window_console = Window:New{  
		dockable = true,
		name = "chat",
		x = x,  
		y = y,
		width  = w,
		height = h,
		--parent = screen0,
		--visible = false,
		--backgroundColor = settings.col_bg,
		draggable = true,
		resizable = true,
		dragUseGrip = true,
		minimumSize = {MIN_WIDTH, MIN_HEIGHT},
		
		children = {
			scrollpanel1,
		},
	}

	for i = 1, lines_count do
		local line = lines[i]
		GenerateTextControl(line, true)
	end	
	
	option_autoHideChanged() 
end

function remakeConsole()
	setup()
		
	if window_console ~= nil then
		local x,y = window_console.x, window_console.y
		local w,h = window_console.width, window_console.height
		
		window_console:Dispose()
		window_console=nil
		stack_console:Dispose()
		stack_console=nil
		makeNewConsole(x, y, w, h)
	else 
		makeNewConsole(settings.pos_x, settings.pos_y, settings.c_width, settings.c_height)
	end 
end

local function ReshapeConsole()
	--[[ I wish these worked
	scrollpanel1.bottom = inputtext_inside and 25 or 0
	scrollpanel1.right  = inputtext_inside and 0 or 6
	
	scrollpanel1:UpdateLayout()
	scrollpanel1:UpdateClientArea()
	window_console:UpdateLayout()
	window_console:UpdateClientArea()
	--]]
	
	scrollpanel1:Dispose()
	scrollpanel1 = ScrollPanel:New{
		parent = window_console,
		x = 0,
		y = 0,
		bottom = inputtext_inside and 25 or 0,
		right= inputtext_inside and 0 or 6,
		--horizontalScrollbar = false,
		verticalSmartScroll = true,
		disableChildrenHitTest = true,
		children = {
			stack_console,
		},
	}

	
end

local function MakeInputSpace()
	inputtext_inside = true
	ReshapeConsole()	
end
local function RemoveInputSpace()
	inputtext_inside = false
	ReshapeConsole()
end


local function hideConsole() 
	if options.autoHideChat.value then 
		screen0:RemoveChild(window_console)
		return true
	end 
	return false
end 


local function addLine(msg)
	if lines_count>0 and lines[lines_count].msg == msg then
		lines[lines_count].dup = lines[lines_count].dup + 1
		GenerateTextControl(lines[lines_count])
		return
	end
	local msgtype
	local message = msg
	local playername
		
	--adapted from lolui
	if (colorNames[msg:sub(2,(msg:find("> Allies: ") or 1)-1)]) then
		msgtype = "allymessage"
		playername = msg:sub(2,msg:find("> ")-1)
		message = msg:sub(playername:len()+12)
		message = (playername and colorNames[playername] or '') .. col_ally_in .. message
		
	elseif (colorNames[msg:sub(2,(msg:find("> ") or 1)-1)]) then
		msgtype = "playermessage"
		playername = msg:sub(2,msg:find("> ")-1)
		message = msg:sub(playername:len()+4)
		message = (playername and colorNames[playername] or '') .. message
	
	elseif (colorNames[msg:sub(2,(msg:find("] ") or 1)-1)]) then
		msgtype = "spectatormessage"
		playername = msg:sub(2,msg:find("] ")-1)
		message = msg:sub(playername:len()+4)
		message = col_othertext_in..'  ['.. col_text_in .. playername .. col_othertext_in .. ']  '.. col_text_in .. message
		
	elseif (colorNames[msg:sub(2,(msg:find("(replay)") or 3)-3)]) then
		msgtype = "spectatormessage"
		playername = msg:sub(2,msg:find("(replay)")-3)
		message = msg:sub(playername:len()+13)
		message = '  (r)['.. playername ..'] '.. message
		
	elseif (colorNames[msg:sub(1,(msg:find(" added point: ") or 1)-1)]) then
		playername = msg:sub(1,msg:find(" added point: ")-1)
		message = msg:sub(string.len(playername.." added point: ")+1)
		if message == '' then
			msgtype = "playerpoint"
			message = colors[playername] .. '* '.. col_ally_in .. (playername or '') .. ' added a point.'
		else
			msgtype = "playerlabel"
			message = colors[playername] .. '*L '.. col_ally_in .. (playername or '') .. ' added a label: ' .. message
		end
	
	elseif (msg:sub(1,1) == ">") then
		msgtype = "gamemessage"
		message = msg:sub(3)
		message = col_othertext_in .. '> ' .. message
	else
		msgtype = "other"
		message = col_othertext_in ..  message
	end
	
	lines_count = lines_count + 1
	local line = { msg=msg, text=message, dup=1, mtype=msgtype, player=playername}
	lines[lines_count] = line
	GenerateTextControl(line)
	
	if lines_count >= options.max_lines.value then
		stack_console:RemoveChild(stack_console.children[1])
		
		lines_count = lines_count - 1
		
		--stack_console:UpdateLayout()
	end
	
	
	if playername == myName then
		if WG.enteringText then
			WG.enteringText = false
			RemoveInputSpace()
			hideConsole()
		end 		
	end
end



function widget:KeyPress(key, modifier, isRepeat) 
	if (key == KEYSYMS.RETURN) then
		if not WG.enteringText then 
			WG.enteringText = true
			if options.autoHideChat.value then 
				screen0:AddChild(window_console)
			end 
			MakeInputSpace()
		end
	else
		if WG.enteringText then
			WG.enteringText = false
			return hideConsole()
		end
	end 
	return false
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function widget:AddConsoleLine(line,priority)
	addLine(line)
end


function widget:Shutdown()
	if (window_settings) then
		window_settings:Dispose()
	end
	if (window_console) then
		window_console:Dispose()
	end
	spSendCommands({"console 1"})
	spSendCommands({"inputtextgeo default"}) -- not saved to spring's config file on exit
	Spring.SetConfigString("InputTextGeo", "0.26 0.73 0.02 0.028") -- spring default values
end

local timer = 0

function widget:Update(s)
	timer = timer + s
	if timer > 2 then
		timer = 0
		spSendCommands({string.format("inputtextgeo %f %f 0.02 %f", 
			--window_console.x / screen0.width + (options.inputtext_inside.value and 0.008 or 0), 
			window_console.x / screen0.width + 0.008, 
			--1 - (window_console.y + window_console.height) / screen0.height + (options.inputtext_inside.value and 0.01 or (-0.023) ), 
			1 - (window_console.y + window_console.height) / screen0.height + 0.01, 
			window_console.width / screen0.width)})
	end
end

-----------------------------------------------------------------------

function widget:Initialize()

	if (not WG.Chili) then
		widgetHandler:RemoveWidget()
		return
	end

	Chili = WG.Chili
	Button = Chili.Button
	Window = Chili.Window
	ScrollPanel = Chili.ScrollPanel
	StackPanel = Chili.StackPanel
	screen0 = Chili.Screen0
	color2incolor = Chili.color2incolor
	incolor2color = Chili.incolor2color
	
	Spring.SendCommands("bind Any+enter  chat")
	
	setup()
	remakeConsole()

	local oldLines = Spring.GetConsoleBuffer(30)
	for i=1,#oldLines do
		addLine(oldLines[i].text)
	end

	spSendCommands({"console 0"})

end
