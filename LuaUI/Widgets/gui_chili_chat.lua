--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Chat",
    desc      = "v0.41 Chili Chat Console.",
    author    = "CarRepairer, Licho",
    date      = "2009-07-07",
    license   = "GNU GPL, v2 or later",
    layer     = 50,
    experimental = false,
    enabled   = true,
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

local stack_console
local scrollpanel1
local inputspace
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

local window_console

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
options_order = { 'autoHideChat', 'noColorName',  'mousewheel', 'hideSpec', 'hideAlly', 'hidePoint', 'hideLabel', 'text_height', 'max_lines', 
		'backgroundOpacity', 'col_text', 'col_ally', 'col_othertext', 'col_dup', 
		}
options = {
	
	
	autoHideChat = {
		name = "Autohide Console",
		type = 'bool',
		value = false, 
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
	backgroundOpacity = {
		name = "Background opacity",
		type = "number",
		value = 0, min = 0, max = 1, step = 0.01,
		OnChange = function(self) 
			scrollpanel1.backgroundColor = {1,1,1,self.value}
			scrollpanel1:Invalidate() 
			inputspace.backgroundColor = {1,1,1,self.value}
			inputspace:Invalidate()
		end,
	},
	mousewheel = {
		name = "Scroll with mousewheel",
		type = 'bool',
		value = false,
		OnChange = function(self) scrollpanel1.noMouseWheel = not self.value; end,
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
			--fontShadow = true,
			--[[
			autoHeight=true,
			autoObeyLineHeight=true,
			--]]
			font = {
				outlineWidth=3,
				outlineWeight = 10,
				outline=true
			}
		}
		stack_console:AddChild(lab, false)
		stack_console:UpdateClientArea()
	end 
end 


local function UpdateConsole()


	stack_console:ClearChildren()
	for i = 1, lines_count do
		local line = lines[i]
		GenerateTextControl(line, true)
	end	
	
	option_autoHideChanged() 
end

function remakeConsole()
	setup()	
	UpdateConsole()
end

local function ReshapeConsole()
	--scrollpanel1.bottom = inputtext_inside and 35 or 0
	
	-- Testing with temporary change to Control:SetPosRelative() 
	--   with signature Control:SetPosRelative(x, y, right, bottom, w, h, ...). Only works sometimes.
	--scrollpanel1:SetPosRelative(_, _, inputtext_inside and 0 or 1, inputtext_inside and 35 or 0 ) 
	
end

local function MakeInputSpace()
	inputtext_inside = true
	ReshapeConsole() -- ****** THIS ONE DOESN'T WORK!
end
local function RemoveInputSpace()
	inputtext_inside = false
	ReshapeConsole() -- ****** THIS ONE WORKS!
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
			window_console.x / screen0.width + 0.004, 
			1 - (window_console.y + window_console.height) / screen0.height + 0.005, 
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
	
	local inputsize = 33
	
	stack_console = StackPanel:New{
		margin = {0,0,0,0},
		padding = {0,0,0,0},
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
	inputspace = ScrollPanel:New{
		x = 0,
		bottom = 0,
		right=5,
		height = inputsize,
		backgroundColor = {1,1,1,options.backgroundOpacity.value},
		--backgroundColor = {1,1,1,1},
	}
	
	scrollpanel1 = ScrollPanel:New{
		--margin = {5,5,5,5},
		padding = {5,5,5,5},
		x = 0,
		y = 0,
		width = '100%',
		--height = '100%',
		bottom = inputsize+2, -- This line is temporary until chili is fixed so that ReshapeConsole() works both times!
		verticalSmartScroll = true,
		disableChildrenHitTest = true,
		--skinName="EmptyScrollbar",
		--color = {0,0,0,0},
		backgroundColor = {1,1,1,options.backgroundOpacity.value},
		noMouseWheel = not options.mousewheel.value,
		children = {
			stack_console,
		},
	}
	
	window_console = Window:New{  
		margin = {0,0,0,0},
		padding = {0,0,0,0},
		dockable = true,
		name = "chat",
		x = 300,  
		y = 0,
		width  = 350,
		height = 250,
		--parent = screen0,
		--visible = false,
		--backgroundColor = settings.col_bg,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		minimumSize = {MIN_WIDTH, MIN_HEIGHT},
		color = {0,0,0,0},
		children = {
			scrollpanel1,
			inputspace,
		},
	}
	
	remakeConsole()

	local oldLines = Spring.GetConsoleBuffer(30)
	for i=1,#oldLines do
		addLine(oldLines[i].text)
	end
	
	spSendCommands({"console 0"})
end
