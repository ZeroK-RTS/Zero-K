--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Chat v0.442",
    desc      = "v0.442 Chili Chat Console.",
    author    = "CarRepairer, Licho",
    date      = "2009-07-07",
    license   = "GNU GPL, v2 or later",
    layer     = 50,
    experimental = false,
    enabled   = true,
	detailsDefault = 1
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

WG.chat = WG.chat or {}

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

local visible = true
local firstEnter=true --used to activate ally-chat at game start. To run once
local noAlly=false	--used to skip the ally-chat above. eg: if 1vs1 skip ally-chat

local wasSimpleColor = nil -- variable: indicate if simple color was toggled on or off. Used to trigger refresh.

local function option_remakeConsole()
	remakeConsole()
end


options_path = "Settings/Interface/Chat/Console"
options_order = {'noColorName',  'mousewheel', 'hideSpec', 'hideAlly', 'hidePoint', 'hideLabel','defaultAllyChat', 'text_height', 'max_lines', 
		'col_back','col_text', 'col_ally', 'col_othertext', 'col_dup', 
		}
options = {
	
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
	col_back = {
		name = "Background color",
		type = "colors",
		value = {0,0,0,0},
		OnChange = function(self) 
			scrollpanel1.backgroundColor = self.value
			scrollpanel1:Invalidate() 
			inputspace.backgroundColor = self.value
			inputspace:Invalidate()
		end,
	},
	mousewheel = {
		name = "Scroll with mousewheel",
		type = 'bool',
		value = false,
		OnChange = function(self) scrollpanel1.noMouseWheel = not self.value; end,
	},
	defaultAllyChat = {
		name = "Default ally chat",
		desc = "Sets default chat mode to allies at game start",
		type = 'bool',
		value = true,
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

-- redefined in Initialize()
local function showConsole() end
local function hideConsole() end
WG.chat.hideConsole = hideConsole
WG.chat.showConsole = showConsole

local function addLine(msg)
	if msg:sub(1,3) == "[f=" then msg = msg:sub(13) end	-- truncate framenumber

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
	
	if (line.mtype=="allymessage" or line.mtype=="playerlabel") then  -- if ally message make sound
		Spring.PlaySoundFile('sounds/talk.wav', 1, 'ui')
	end 

	
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
			if noAlly then
				firstEnter= false --skip the default-ally-chat initialization if there's no ally. eg: 1vs1
			end
			if firstEnter then
				if (not (modifier.Shift or modifier.Ctrl)) and options.defaultAllyChat.value then
					spSendCommands("chatally")
				end
				firstEnter=false
			end
			WG.enteringText = true
			if window_console.hidden and not visible then 
				screen0:AddChild(window_console)
				visible = true
			end 
			MakeInputSpace()
		end
	else
		if WG.enteringText then
			WG.enteringText = false
            return hideConsole()
		end
	end 
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

local function CheckColorScheme() --//toggle between color scheme
	local currentColorScheme = wasSimpleColor 
	if WG.LocalColor then 
		currentColorScheme = WG.LocalColor.usingSimpleTeamColors	
	end
	if wasSimpleColor ~= currentColorScheme then
		option_remakeConsole()
		wasSimpleColor = currentColorScheme
	end
end

function widget:Update(s)
	timer = timer + s
	if timer > 2 then
		timer = 0
		spSendCommands({string.format("inputtextgeo %f %f 0.02 %f", 
			window_console.x / screen0.width + 0.004, 
			1 - (window_console.y + window_console.height) / screen0.height + 0.005, 
			window_console.width / screen0.width)})
		CheckColorScheme()
	end
end

function widget:PlayerAdded(playerID)
	setup()
end

-----------------------------------------------------------------------

function widget:Initialize()
	if (not WG.Chili) then
		widgetHandler:RemoveWidget()
		return
	end
	local spectating = Spring.GetSpectatingState()
	local myAllyTeamID = Spring.GetMyAllyTeamID() --get my alliance ID
	local teamList = Spring.GetTeamList(myAllyTeamID) --get list of teams in my alliance
	if #teamList == 1 and (not spectating) then --if I'm alone and playing (no ally), then no need to set default-ally-chat during gamestart . eg: 1vs1
		noAlly = true
	end

	Chili = WG.Chili
	Button = Chili.Button
	Window = Chili.Window
	ScrollPanel = Chili.ScrollPanel
	StackPanel = Chili.StackPanel
	screen0 = Chili.Screen0
	color2incolor = Chili.color2incolor
	incolor2color = Chili.incolor2color

	hideConsole = function()
		if window_console.hidden and visible then 
			screen0:RemoveChild(window_console)
			visible = false
			return true
		end 
		return false
	end

	-- only used by Crude
	showConsole = function()
		if not visible then
			screen0:AddChild(window_console)
			visible = true
		end
	end
	WG.chat.hideConsole = hideConsole
	WG.chat.showConsole = showConsole	

	Spring.SendCommands("bind Any+enter  chat")
	
	local inputsize = 33
	
	local screenWidth,screenHeight = Spring.GetWindowGeometry()
	
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
		backgroundColor = options.col_back.value,
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
		backgroundColor = options.col_back.value,
		noMouseWheel = not options.mousewheel.value,
		children = {
			stack_console,
		},
	}
	
	window_console = Window:New{  
		margin = {0,0,0,0},
		padding = {0,0,0,0},
		dockable = true,
		name = "Chat",
		y = 0,
		right = 425, -- epic/resbar width
		width  = screenWidth*0.30,
		height = screenHeight*0.20,
		--parent = screen0,
		--visible = false,
		--backgroundColor = settings.col_bg,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		minimizable = true,
        selfImplementedMinimizable = 
            function (show)
                if show then
                    showConsole()
                else
                    hideConsole()
                end
            end,
		minWidth = MIN_WIDTH,
		minHeight = MIN_HEIGHT,
		color = {0,0,0,0},
		children = {
			scrollpanel1,
			inputspace,
		},
		OnMouseDown={ function(self) --//click on scroll bar shortcut to "Settings/Interface/Chat/Console".
				local _,_, meta,_ = Spring.GetModKeyState()
				if not meta then return false end
				WG.crude.OpenPath(options_path)
				WG.crude.ShowMenu() --make epic Chili menu appear.
				return true
		end },
	}
	
	remakeConsole()

	local oldLines = Spring.GetConsoleBuffer(30)
	for i=1,#oldLines do
		addLine(oldLines[i].text)
	end
	
	spSendCommands({"console 0"})
	
	screen0:AddChild(window_console)
    visible = true
	
end
