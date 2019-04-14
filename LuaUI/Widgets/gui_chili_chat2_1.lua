--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- TODO : extract code that can be shared between widgets (parsing) and maybe move it to cawidget and add new callin
-- TODO (maybe) : extract code that can be shared between similar chat widgets (message formatting, hidden+highlight detection) so only chili/ScrollPanel+TextBoxen stuff remain in there
-- TODO : test replay message formats (and change pattern matcher/parseCommand() to remove duplication in message definitions)
-- TODO : check that private (whisper) messages work as expected
-- TODO FIXME : reformat all messages when simpleColors is toggled or when colors are changed
-- TODO FIXME : when some messages are hidden... make sure we dont destroy too many stack_console control children
-- TODO : add message highlight options (never, only ally, all messages) + highlight format (currently surrounds message with #### in highlight color)
-- FIXME : fix (probable) bug while shrinking max_lines option

function widget:GetInfo()
  return {
    name      = "Chili Chat 2.2",
    desc      = "v0.925 Chili Chat Console.",
    author    = "CarRepairer, Licho, Shaun",
    date      = "2012-06-12",
    license   = "GNU GPL, v2 or later",
    layer     = 50,
    enabled   = false,
  }
end

include("keysym.h.lua")
include("Widgets/COFCTools/ExportUtilities.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- message rules - widget stuff
--[[
each message definition can have:
	- either 1 format
	- either name + output, output containing pairs of { name = '', format = '' }
all the names are used when displaying the options

format syntax:
- #x : switch to color 'x' where 'x' can be:
	- a : ally (option)
	- e : everyone (option)
	- o : other (option)
	- s : spec (option)
	- h : highlight (option)
	- p : color of the player who sent message (dynamic)
- $var : gets replaced by msg['var'] ; interesting vars:
	- playername
	- argument	for messages, this is only the message part; for labels, this is the caption
	- msgtype	type of message as identified by parseMessage()
	- priority	as received by widget:AddConsoleLine()
	- text		full message, as received by widget:AddConsoleLine()

--]]
local MESSAGE_RULES = {
	player_to_allies = {
		name = "Player to allies message",
		output = {
			{
				name = "Only bracket in player's color, message in 'ally' color",
				format = '#p<#e$playername#p> #a$argument'
			},
			{
				name = "Playername in his color, message in 'ally' color",
				format = '#p<$playername> #a$argument',
				default = true
			},
			{
				name = "Playername and message in player's color",
				format = '#p<$playername> $argument'
			},
		}
	},
	player_to_player_received = { format = '#p*$playername* $argument' },
	player_to_player_sent = { format = '#p -> *$playername* $argument' }, -- NOTE: #p will be color of destination player!
	player_to_specs = { format = '#p<$playername> #s$argument' },
	player_to_everyone = { format = '#p<$playername> #e$argument' },

	spec_to_specs = { format = '#s[$playername] $argument' },
	spec_to_allies = { format = '#s[$playername] $argument' }, -- TODO is there a reason to differentiate spec_to_specs and spec_to_allies??
	spec_to_everyone = { format = '#s[$playername] #e$argument' },

	-- shameful copy-paste -- TODO remove this duplication
	replay_spec_to_specs = { format = '#s[$playername (replay)] $argument' },
	replay_spec_to_allies = { format = '#s[$playername (replay)] $argument' }, -- TODO is there a reason to differentiate spec_to_specs and spec_to_allies??
	replay_spec_to_everyone = { format = '#s[$playername (replay)] #e$argument' },

	label = { format = '#p *** $playername added label \'$argument\'' },
	point = { format = '#p *** $playername added point' },
	autohost = { format = '#o> $argument', noplayername = true },
	other = { format = '#o$text' }, -- no pattern... will match anything else
	game_message = { format = '#o$text' } -- no pattern...
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local SOUNDS = {
	ally = "sounds/talk.wav",
	label = "sounds/talk.wav",
	highlight = "LuaUI/Sounds/communism/cash-register-01.wav" -- TODO find a better sound :)
}

local function PlaySound(id, condition)
	if condition ~= nil and not condition then
		return
	end
	local file = SOUNDS[id]
	if file then
		Spring.PlaySoundFile(file, 1, 'ui')
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local HIGHLIGHT_SURROUND_SEQUENCE_1 = ' >>> '
local HIGHLIGHT_SURROUND_SEQUENCE_2 = ' <<<'
local DEDUPE_SUFFIX = 'x '

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local screen0
local myName -- my console name
local myAllyTeamId

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local MIN_HEIGHT = 150
local MIN_WIDTH = 300
local MAX_STORED_MESSAGES = 300

local stack_console
local window_console
local scrollpanel1
local inputspace
local color2incolor
WG.enteringText = false
WG.chat = WG.chat or {}

local echo = Spring.Echo

-- redefined in Initialize()
local function showConsole() end
local function hideConsole() end
WG.chat.hideConsole = hideConsole
WG.chat.showConsole = showConsole

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local incolor_dup
local incolor_highlight
local incolors = {} -- incolors indexed by playername + special #a/#e/#o/#s/#h colors based on config

local messages = {} -- message buffer
local highlightPattern -- currently based on player name -- TODO add configurable list of highlight patterns

local visible = false
local firstEnter = true --used to activate ally-chat at game start. To run once
local noAlly = false	--used to skip the ally-chat above. eg: if 1vs1 skip ally-chat

local wasSimpleColor = nil -- variable: indicate if simple color was toggled on or off. Used to trigger refresh.

local time_opened = nil

local GetTimer = Spring.GetTimer 
local DiffTimers = Spring.DiffTimers

----

options_path = "Settings/HUD Panels/Chat/Console"
options_order = {
	'lblError',
	'error_opengl_source',	
	
	'lblGeneral',
	'mousewheel', 
	'defaultAllyChat',
	'text_height', 'max_lines',
	'color_background', 'color_chat', 'color_ally', 'color_other', 'color_spec',
	
	
	'lblFilter',
	'hideSpec', 'hideAlly', 'hidePoint', 'hideLabel', 'hideLog',
	
	'lblPointButtons',
	'clickable_points','pointButtonOpacity',
	
	'lblAutohide',
	'autohide', 'autohide_time',
	
	
	'lblHilite',
	'highlight_all_private', 'highlight_filter_allies', 'highlight_filter_enemies', 'highlight_filter_specs', 'highlight_filter_other',
	'highlight_surround', 'highlight_sound', 'color_highlight','highlighted_text_height', 
	
	'lblDedupe',
	'dedupe_messages', 'dedupe_points','color_dup',
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function onOptionsChanged()
	RemakeConsole()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options = {
	
	lblError = {name='Error Filter', type='label', advanced = true},
	lblFilter = {name='Filtering', type='label', advanced = false},
	lblPointButtons = {name='Point Buttons', type='label', advanced = true},
	lblAutohide = {name='Auto Hiding', type='label'},
	lblHilite = {name='Highlighting', type='label'},
	lblDedupe = {name='De-Duplication', type='label'},
	lblGeneral = {name='General Settings', type='label'},
	
	error_opengl_source = {
		name = "Filter out \'Error: OpenGL: source\' error",
		type = 'bool',
		value = true,
		desc = "This filter out \'Error: OpenGL: source\' error message from ingame chat, which happen specifically in Spring 91 with Intel Mesa driver."
		.."\nTips: the spam will be written in infolog.txt, if the file get unmanageably large try set it to Read-Only to prevent write.",
		advanced = true,
	},
	
	text_height = {
		name = 'Text Size',
		type = 'number',
		value = 14,
		min = 8, max = 30, step = 1,
		OnChange = onOptionsChanged,
	},
	highlighted_text_height = {
		name = 'Highlighted Text Size',
		type = 'number',
		value = 16,
		min = 8, max = 30, step = 1,
		OnChange = onOptionsChanged,
	},
	clickable_points = {
		name = "Clickable points and labels",
		type = 'bool',
		value = true,
		noHotkey = true,
		OnChange = onOptionsChanged,
		advanced = true,
	},
	pointButtonOpacity = {
		name = "Point button opacity",
		type = 'number',
		value = 0.25,
		min = 0, max = 1, step = 0.05,
		advanced = true,
	},
	
	-- TODO work in progress
	dedupe_messages = {
		name = "Dedupe messages",
		type = 'bool',
		value = true,
		noHotkey = true,
		OnChange = onOptionsChanged,
		advanced = true,
	},
	dedupe_points = {
		name = "Dedupe points and labels",
		type = 'bool',
		value = true,
		noHotkey = true,
		OnChange = onOptionsChanged,
		advanced = true,
	},
	highlight_all_private = {
		name = "Highlight all private messages",
		type = 'bool',
		value = true,
		noHotkey = true,
		advanced = true,
	},
	highlight_filter_allies = {
		name = "Check allies messages for highlight",
		type = 'bool',
		value = true,
		noHotkey = true,
		advanced = true,
	},
	highlight_filter_enemies = {
		name = "Check enemy messages for highlight",
		type = 'bool',
		value = true,
		noHotkey = true,
		advanced = true,
	},
	highlight_filter_specs = {
		name = "Check spec messages for highlight",
		type = 'bool',
		value = true,
		noHotkey = true,
		advanced = true,
	},
	highlight_filter_other = {
		name = "Check other messages for highlight",
		type = 'bool',
		value = false,
		noHotkey = true,
		advanced = true,
	},
--[[
	highlight_filter = {
		name = 'Highlight filter',
		type = 'list',
		OnChange = onOptionsChanged, -- NO NEED
		value = 'allies',
		items = {
			{ key = 'disabled', name = "Disabled" },
			{ key = 'allies', name = "Highlight only allies messages" },
			{ key = 'all', name = "Highlight all messages" },
		},
		advanced = true,
	},
--]]
	
	highlight_surround = {
		name = "Surround highlighted messages",
		type = 'bool',
		value = true,
		noHotkey = true,
		OnChange = onOptionsChanged,
		advanced = true,
	},
	highlight_sound = {
		name = "Sound for highlighted messages",
		type = 'bool',
		value = false,
		noHotkey = true,
		OnChange = onOptionsChanged,
		advanced = true,
	},
	hideSpec = {
		name = "Hide Spectator Chat",
		type = 'bool',
		value = false,
		OnChange = onOptionsChanged,
		advanced = false,
	},
	hideAlly = {
		name = "Hide Ally Chat",
		type = 'bool',
		value = false,
		OnChange = onOptionsChanged,
		advanced = false,
	},
	hidePoint = {
		name = "Hide Points",
		type = 'bool',
		value = false,
		OnChange = onOptionsChanged,
		advanced = true,
	},
	hideLabel = {
		name = "Hide Labels",
		type = 'bool',
		value = false,
		OnChange = onOptionsChanged,
		advanced = true,
	},
	hideLog = {
		name = "Hide Engine Logging Messages",
		type = 'bool',
		value = true,
		OnChange = onOptionsChanged,
		advanced = true,
	},
	max_lines = {
		name = 'Maximum Lines (20-100)',
		type = 'number',
		value = 60,
		min = 20, max = 100, step = 1, 
		OnChange = onOptionsChanged,
	},
	
	color_chat = {
		name = 'Everyone chat text',
		type = 'colors',
		value = { 1, 1, 1, 1 },
		OnChange = onOptionsChanged,
	},
	color_ally = {
		name = 'Ally text',
		type = 'colors',
		value = { 0.2, 1, 0.2, 1 },
		OnChange = onOptionsChanged,
	},
	color_other = {
		name = 'Other text',
		type = 'colors',
		value = { 0.6, 0.6, 0.6, 1 },
		OnChange = onOptionsChanged,
	},
	color_spec = {
		name = 'Spectator text',
		type = 'colors',
		value = { 0.8, 0.8, 0.8, 1 },
		OnChange = onOptionsChanged,
	},
	color_dup = {
		name = 'Duplicate message mark',
		type = 'colors',
		value = { 1, 0.2, 0.2, 1 },
		OnChange = onOptionsChanged,
	},
	color_highlight = {
		name = 'Highlight mark',
		type = 'colors',
		value = { 1, 1, 0.2, 1 },
		OnChange = onOptionsChanged,
	},
	color_background = {
		name = "Background color",
		type = "colors",
		value = { 0, 0, 0, 0},
		OnChange = function(self) 
			scrollpanel1.backgroundColor = self.value
			scrollpanel1.borderColor = self.value
			scrollpanel1:Invalidate()
			inputspace.backgroundColor = self.value
			inputspace.borderColor = self.value
			inputspace:Invalidate()
		end,
	},
	mousewheel = {
		name = "Scroll with mousewheel",
		type = 'bool',
		value = false,
		noHotkey = true,
		OnChange = function(self) scrollpanel1.ignoreMouseWheel = not self.value; end,
	},
	defaultAllyChat = {
		name = "Default ally chat",
		desc = "Sets default chat mode to allies at game start",
		type = 'bool',
		value = true,
		noHotkey = true,
	},	
	autohide = {
		name = "Autohide chat",
		desc = "Hides the chat when not in use",
		type = 'bool',
		value = false,
		noHotkey = true,
		OnChange = onOptionsChanged,
	},
	autohide_time = {
		name = "Autohide time",
		type = 'number',
		value = 8,
		min = 1, max = 30, step = 1, 
		OnChange = onOptionsChanged,
	},
	
}
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- TODO : should these pattern/escape functions be moved to some shared file/library?

local function nocase(s)
  return string.gsub(s, "%a", function (c)
		return string.format("[%s%s]", string.lower(c), string.upper(c))
	  end
  )
end

local function escapePatternMatchChars(s)
  return string.gsub(s, "(%W)", "%%%1")
end

local function caseInsensitivePattern(s)
  return nocase(escapePatternMatchChars(s))
end

-- local widget only
function getMessageRuleOptionName(msgtype, suboption)
  return msgtype .. "_" .. suboption
end

for msgtype,rule in pairs(MESSAGE_RULES) do
	if rule.output and rule.name then -- if definition has multiple output formats, make associated config option
		local option_name = getMessageRuleOptionName(msgtype, "output_format")
		options_order[#options_order + 1] = option_name
		local o = {
			name = "Format for " .. rule.name,
			type = 'list',
			OnChange = function (self)
				Spring.Echo('Selected: ' .. self.value)
				onOptionsChanged()
			end,
			value = '1', -- may be overriden
			items = {},
			advanced = true,
		}
		
		for i, output in ipairs(rule.output) do
			o.items[i] = { key = i, name = output.name }
			if output.default then
				o.value = i
			end
		end
		options[option_name] = o
    end
end

local function getOutputFormat(msgtype)
  local rule = MESSAGE_RULES[msgtype]
  if not rule then
	Spring.Echo("UNKNOWN MESSAGE TYPE: " .. msgtype or "NiL")
	return
  elseif rule.output then -- rule has multiple user-selectable output formats
    local option_name = getMessageRuleOptionName(msgtype, "output_format")
    local value = options[option_name].value
    return rule.output[value].format
  else -- rule has only 1 format defined
	return rule.format
  end
end

local function getSource(spec, allyTeamId)
	return (spec and 'spec')
		or ((Spring.GetMyTeamID() == allyTeamId) and 'ally')
		or 'enemy'
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function detectHighlight(msg)
	-- must handle case where we are spec and message comes from player

	if msg.msgtype == 'player_to_player_received' and options.highlight_all_private.value then
		msg.highlight = true
		return
	end
	
--	Spring.Echo("msg.source = " .. (msg.source or 'NiL'))
	
	if msg.source == 'ally' and not options.highlight_filter_allies.value
	or msg.source == 'enemy' and not options.highlight_filter_enemies.value
	or msg.source == 'spec' and not options.highlight_filter_specs.value
	or msg.source == 'other' and not options.highlight_filter_other.value then
		return
	end

	if (msg.argument and msg.argument:find(highlightPattern)) then
		msg.highlight = true
	end
end

local function formatMessage(msg)
	local format = getOutputFormat(msg.msgtype) or getOutputFormat("other")
	
	-- insert/sandwich colour string into text
	local formatted, _ = format:gsub('([#%$]%w+)', function(parameter) -- FIXME pattern too broad for 1-char color specifiers
			if parameter:sub(1,1) == '$' then
				return msg[parameter:sub(2,parameter:len())]
			elseif parameter == '#p' then
				if msg.playername and incolors[msg.playername] then
					return incolors[msg.playername]
				else
					return incolors['#o'] -- player still at lobby, use grey text
				end
			else
				return incolors[parameter]
			end
		end)
	msg.formatted = formatted
end

local function MessageIsChatInfo(msg)
	return string.find(msg.argument,'Speed set to') or
	string.find(msg.argument,'following') or
	string.find(msg.argument,'Connection attempted') or
	string.find(msg.argument,'exited') or 
	string.find(msg.argument,'is no more') or 
	string.find(msg.argument,'paused the game') or
	string.find(msg.argument,'Sync error for') or
	string.find(msg.argument,'Cheating is') or
	string.find(msg.argument,'resigned') or
	(string.find(msg.argument,'left the game') and string.find(msg.argument,'Player'))
	--string.find(msg.argument,'Team') --endgame comedic message. Engine message, loaded from gamedata/messages.lua (hopefully 'Team' with capital 'T' is not used anywhere else)
end

local function hideMessage(msg)
	return (msg.msgtype == "spec_to_everyone" and options.hideSpec.value) -- can only hide spec when playing
		or (msg.msgtype == "player_to_allies" and options.hideAlly.value)
		or (msg.msgtype == "point" and options.hidePoint.value)
		or (msg.msgtype == "label" and options.hideLabel.value)
		or (msg.msgtype == 'other' and options.hideLog.value and not MessageIsChatInfo(msg))
end

local function displayMessage(msg, remake)
	if hideMessage(msg)	or (not WG.Chili) then
		return
	end
	
	-- TODO betterify this / make configurable
	local highlight_sequence1 = (msg.highlight and options.highlight_surround.value and (incolor_highlight .. HIGHLIGHT_SURROUND_SEQUENCE_1) or '')
	local highlight_sequence2 = (msg.highlight and options.highlight_surround.value and (incolor_highlight .. HIGHLIGHT_SURROUND_SEQUENCE_2) or '')
	local text = (msg.dup > 1 and (incolor_dup .. msg.dup .. DEDUPE_SUFFIX) or '') .. highlight_sequence1 .. msg.formatted .. highlight_sequence2

	if (msg.dup > 1 and not remake) then
		local last = stack_console.children[#(stack_console.children)]
		if last then
			if last.SetText then
				last:SetText(text)
				-- UpdateClientArea() is not enough - last message keeps disappearing until new message is added
				last:Invalidate()
			end
		end
	else
		local textbox = WG.Chili.TextBox:New{
			width = '100%',
			align = "left",
			fontsize = (msg.highlight and options.highlighted_text_height.value or options.text_height.value),
			valign = "ascender",
			lineSpacing = 0,
			padding = { 0, 0, 0, 0 },
			text = text,
			--fontShadow = true,
			--[[
			autoHeight=true,
			autoObeyLineHeight=true,
			--]]

			font = {
				outlineWidth = 3,
				outlineWeight = 10,
				outline = true
			}
		}
		
		if options.clickable_points.value then
			local button = textbox
			if msg.point then --message is a marker, make obvious looking button
				textbox:SetPos( nil, 3, stack_console.width - 6 )
				textbox:Update()
				local tbheight = textbox.height -- not perfect
				tbheight = math.max( tbheight, 15 ) --hack
				--echo('tbheight', tbheight)
				button = WG.Chili.Button:New{
					width = '100%',
					height = tbheight + 8,
					padding = { 3,3,3,3 },
					backgroundColor = {1,1,1,options.pointButtonOpacity.value},
					caption = '',
					children = { textbox, },
					OnClick = {function(self, x, y, mouse)
						local alt,ctrl, meta,shift = Spring.GetModKeyState()
						if (shift or ctrl or meta or alt) or ( mouse ~= 1 ) then return false end --skip modifier key since they meant player are using click to issue command.Try to not steal click
						SetCameraTarget(msg.point.x, msg.point.y, msg.point.z, 1)
					end}
				}
				
			elseif WG.alliedCursorsPos and msg.player and msg.player.id then --message is regular chat, make hidden button
				local cur = WG.alliedCursorsPos[msg.player.id]
				if cur then
					textbox.OnMouseDown = {function(self, x, y, mouse)
							local alt,ctrl, meta,shift = Spring.GetModKeyState()
							if ( shift or ctrl or meta or alt ) then return false end --skip all modifier key
							local click_on_text = x <= textbox.font:GetTextWidth(self.text); -- use self.text instead of text to include dedupe message prefix
							if (mouse == 1 and click_on_text) then
								SetCameraTarget(cur[1], 0,cur[2], 1) --go to where player is pointing at. NOTE: "cur" is table referenced to "WG.alliedCursorsPos" so its always updated with latest value
							end
					end}
					function textbox:HitTest(x, y)  -- copied this hack from chili bubbles
						return self
					end
				end
			end
			stack_console:AddChild(button, false)
		else
			stack_console:AddChild(textbox, false)	
		end

		stack_console:UpdateClientArea()
		
	end 

	showConsole()
end 


local function setupColors()
	incolor_dup			= color2incolor(options.color_dup.value)
	incolor_highlight	= color2incolor(options.color_highlight.value)
	incolors['#h']		= incolor_highlight
	incolors['#a'] 		= color2incolor(options.color_ally.value)
	incolors['#e'] 		= color2incolor(options.color_chat.value)
	incolors['#o'] 		= color2incolor(options.color_other.value)
	incolors['#s'] 		= color2incolor(options.color_spec.value)
end

local function setupPlayers(playerID)
	if playerID then
		local name, active, spec, teamId, allyTeamId = Spring.GetPlayerInfo(playerID, false)
		--lobby: grey chat, spec: white chat, player: color chat
		incolors[name] = (spec and incolors['#s']) or color2incolor(Spring.GetTeamColor(teamId))
	else
		local playerroster = Spring.GetPlayerList()
		for i, id in ipairs(playerroster) do
			local name,active, spec, teamId, allyTeamId = Spring.GetPlayerInfo(id, false)
			--lobby: grey chat, spec: white chat, player: color chat
			incolors[name] = (spec and incolors['#s']) or color2incolor(Spring.GetTeamColor(teamId))
		end
	end
end

local function SetupAITeamColor() --Copied from gui_chili_chat2_1.lua
	-- register any AIs
	-- Copied from gui_chili_crudeplayerlist.lua
	local teamsSorted = Spring.GetTeamList()
	for i=1,#teamsSorted do
		local teamID = teamsSorted[i]
		if teamID ~= Spring.GetGaiaTeamID() then
			local isAI = select(4,Spring.GetTeamInfo(teamID, false))
			if isAI then
				local name = select(2,Spring.GetAIInfo(teamID))
				incolors[name] = color2incolor(Spring.GetTeamColor(teamID))
			end
		end --if teamID ~= Spring.GetGaiaTeamID() 
	end --for each team	
end

local function setupMyself()
	myName, _, _, _, myAllyTeamId = Spring.GetPlayerInfo(Spring.GetMyPlayerID(), false) -- or do it in the loop?
	highlightPattern = caseInsensitivePattern(myName)
end

local function setup()
	setupMyself()
	setupColors()
	setupPlayers()
	SetupAITeamColor()
end

local function removeToMaxLines()
	while #stack_console.children > options.max_lines.value do
		-- stack_console:RemoveChild(stack_console.children[1]) --disconnect children
		if stack_console.children[1] then
			stack_console.children[1]:Dispose() --dispose/disconnect children (safer)
		end
		--stack_console:UpdateLayout()
	end
end

function RemakeConsole()
	setup()
	-- stack_console:ClearChildren() --disconnect from all children
	for i=1, #stack_console.children do
		stack_console.children[1]:Dispose() --dispose/disconnect all children (safer)
	end
	for i = 1, #messages do -- FIXME : messages collection changing while iterating (if max_lines option has been shrinked)
		local msg = messages[i]
		displayMessage(msg, true)	
	end	
	
	removeToMaxLines()
	
	-- set initial state for the chat, hide the dock for autohide
	if (options.autohide.value) then
		hideConsole()
	else
		showConsole()
	end 
end


-----------------------------------------------------------------------

function widget:KeyPress(key, modifier, isRepeat)
	if (key == KEYSYMS.RETURN) then

		if noAlly then
			firstEnter = false --skip the default-ally-chat initialization if there's no ally. eg: 1vs1
		end
		if firstEnter then
			if (not (modifier.Shift or modifier.Ctrl)) and options.defaultAllyChat.value then
				Spring.SendCommands("chatally")
			end
			firstEnter = false
		end
		WG.enteringText = true
		showConsole()
	else
		WG.enteringText = false		
	end 
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:MapDrawCmd(playerId, cmdType, px, py, pz, caption)
--	Spring.Echo("########### MapDrawCmd " .. playerId .. " " .. cmdType .. " coo="..px..","..py..","..pz .. (caption and (" caption " .. caption) or ''))
	if (cmdType == 'point') then
		widget:AddMapPoint(playerId, px, py, pz, caption) -- caption may be an empty string
		-- FIXME return true or false?
	end
end

function widget:AddMapPoint(playerId, px, py, pz, caption)
	local playerName, active, spec, teamId, allyTeamId = Spring.GetPlayerInfo(playerId, false)

	widget:AddConsoleMessage({
		msgtype = ((caption:len() > 0) and 'label' or 'point'),
		playername = playerName,
		source = getSource(spec, allyTeamId),
		text = 'MapDrawCmd ' .. caption,
		argument = caption,
		priority = 0, -- just in case ... probably useless
		point = { x = px, y = py, z = pz }
	})
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- new callin! will remain in widget
function widget:AddConsoleMessage(msg)
	if options.error_opengl_source.value and msg.msgtype == 'other' and (msg.argument):find('Error: OpenGL: source') then return end
	if msg.msgtype == 'other' and (msg.argument):find('added point') then return end
	
	if ((msg.msgtype == "point" or msg.msgtype == "label") and options.dedupe_points.value or options.dedupe_messages.value)
	and #messages > 0 and messages[#messages].text == msg.text then
		-- update MapPoint position with most recent, as it is probably more relevant
		messages[#messages].point = msg.point
		messages[#messages].dup = messages[#messages].dup + 1
		displayMessage(messages[#messages])
		return
	end
	
	msg.dup = 1
	
	detectHighlight(msg)
	formatMessage(msg) -- does not handle dedupe or highlight
	
	messages[#messages + 1] = msg
	displayMessage(msg)
	
	if msg.highlight and options.highlight_sound.value then
		PlaySound("highlight")
	elseif (msg.msgtype == "player_to_allies") then -- FIXME not for sent messages
		PlaySound("ally")
	elseif msg.msgtype == "label" then
		PlaySound("label")
	end

	if #messages > MAX_STORED_MESSAGES then
		table.remove(messages, 1)
	end
	
	removeToMaxLines()

	-- if playername == myName then
		if WG.enteringText then
			WG.enteringText = false
			-- hideConsole()
		end 		
	-- end
end

-----------------------------------------------------------------------

local timer = 0

-- FIXME wtf is this obsessive function?
function widget:Update(s)

	if options.autohide.value and time_opened and (DiffTimers(GetTimer(), time_opened) > options.autohide_time.value) then
		-- echo(inputspace.state.enabled)
		-- if not inputspace.visible then --TODO find some way to guarantee this doesn't go off when, and only when, text is being entered
			hideConsole() 
		-- end
	end

	timer = timer + s
	if timer > 2 then
		timer = 0
		Spring.SendCommands({string.format("inputtextgeo %f %f 0.02 %f", 
			window_console.x / screen0.width + 0.004, 
			1 - (window_console.y + window_console.height) / screen0.height + 0.005, 
			window_console.width / screen0.width)})
--		CheckColorScheme()
	end
end

-----------------------------------------------------------------------

-- function widget:PlayerAdded(playerID)
	-- setup()
-- end
function widget:PlayerChanged(playerID)
	setupPlayers(playerID)
end

-----------------------------------------------------------------------
function widget:LocalColorRegister()
	if WG.LocalColor and WG.LocalColor.RegisterListener then
		WG.LocalColor.RegisterListener(widget:GetInfo().name, onOptionsChanged)
	end
end

function widget:LocalColorUnregister()
	if WG.LocalColor and WG.LocalColor.UnregisterListener then
		WG.LocalColor.UnregisterListener(widget:GetInfo().name)
	end
end

-----------------------------------------------------------------------

function widget:Initialize()
	if (not WG.Chili) then
		widgetHandler:RemoveWidget()
		return
	end
	local spectating = Spring.GetSpectatingState()
	local myAllyTeamID = Spring.GetMyAllyTeamID() -- get my alliance ID
	local teams = Spring.GetTeamList(myAllyTeamID) -- get list of teams in my alliance
	if #teams == 1 and (not spectating) then -- if I'm alone and playing (no ally), then no need to set default-ally-chat during gamestart . eg: 1vs1
		noAlly = true
	end

	screen0 = WG.Chili.Screen0
	color2incolor = WG.Chili.color2incolor
	
	hideConsole = function()
		if visible then
			screen0:RemoveChild(window_console)
			visible = false
			time_opened = nil
		end
	end

	showConsole = function()
		if not visible then
			screen0:AddChild(window_console)
			visible = true
		end
		time_opened = GetTimer()
	end
	WG.chat.hideConsole = hideConsole
	WG.chat.showConsole = showConsole

	Spring.SendCommands("bind Any+enter  chat")
	
	local inputsize = 33
	
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	
	stack_console = WG.Chili.StackPanel:New{
		name = "stack_console",
		margin = { 0, 0, 0, 0 },
		padding = { 0, 0, 0, 0 },
		x = 0,
		y = 0,
		width = '100%',
		height = 10,
		resizeItems = false,
		itemPadding  = { 1, 1, 1, 1 },
		itemMargin  = { 1, 1, 1, 1 },
		autosize = true,
		preserveChildrenOrder = true,
	}
	inputspace = WG.Chili.ScrollPanel:New{
		x = 0,
		bottom = 0,
		right = 5,
		height = inputsize,
		backgroundColor = options.color_background.value,
		borderColor = options.color_background.value,
		--backgroundColor = {1,1,1,1},
	}
	
	scrollpanel1 = WG.Chili.ScrollPanel:New{
		--margin = {5,5,5,5},
		padding = { 5, 5, 5, 5 },
		x = 0,
		y = 0,
		width = '100%',
		bottom = inputsize + 2, -- This line is temporary until chili is fixed so that ReshapeConsole() works both times! -- TODO is it still required??
		verticalSmartScroll = true,
		horizontalScrollbar = false,
-- DISABLED FOR CLICKABLE TextBox		disableChildrenHitTest = true,
		backgroundColor = options.color_background.value,
		borderColor = options.color_background.value,
		ignoreMouseWheel = not options.mousewheel.value,
		children = {
			stack_console,
		},
	}
	
	function scrollpanel1:IsAboveVScrollbars(x, y)  -- this override default Scrollpanel's HitTest.
		--It aim to: exclude any modifier key (shift,alt,ctrl, except spacebar which is used for Space+click shortcut), and only allow left-click to reposition the vertical scrollbar, because it have a chance of stealing click when giving order (highest when in Low resolution and when ChiliChat2 is positioned to left of screen).
		local alt,ctrl, meta,shift = Spring.GetModKeyState()
		if (x< self.width - self.scrollbarSize) or (shift or ctrl or alt) or (not select(3,Spring.GetMouseState())) then 
			return false 
		end --skip modifier key since they meant player are using click to issue command. Try to not steal click
		return self
	end
	
	window_console = WG.Chili.Window:New{  
		margin = { 0, 0, 0, 0 },
		padding = { 0, 0, 0, 0 },
		dockable = true,
		name = "Chat",
		y = 0,
		right = 425, -- epic/resbar width
		width  = screenWidth * 0.30,
		height = screenHeight * 0.20,
		--parent = screen0,
		--visible = false,
		--backgroundColor = settings.col_bg,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		minimizable = true,
		parentWidgetName = widget:GetInfo().name, --for gui_chili_docking.lua (minimize function)
		selfImplementedMinimizable = 
			function (show)
				if show then
					options.autohide.value = false
					showConsole()
				else
					options.autohide.value = true
					hideConsole()
				end
			end,
		minWidth = MIN_WIDTH,
		minHeight = MIN_HEIGHT,
		color = { 0, 0, 0, 0 },
		children = {
			scrollpanel1,
			inputspace,
		},
		OnMouseDown = {
			function(self) --//click on scroll bar shortcut to "Settings/HUD Panels/Chat/Console".
				local _,_, meta,_ = Spring.GetModKeyState()
				if not meta then return false end
				WG.crude.OpenPath(options_path)
				WG.crude.ShowMenu() --make epic Chili menu appear.
				return true
			end
		},
	}
	
	RemakeConsole()
	local buffer = widget:ProcessConsoleBuffer(nil, options.max_lines.value)
	for i=1,#buffer do
	  widget:AddConsoleMessage(buffer[i])
	end
	
	Spring.SendCommands({"console 0"})
 	
	self:LocalColorRegister()
end

function widget:GameStart()
	setupPlayers() --re-check teamColor at gameStart for Singleplayer (special case. widget Initialized before player join).
end

-----------------------------------------------------------------------

function widget:Shutdown()
	if (window_console) then
		window_console:Dispose()
	end
	Spring.SendCommands({"console 1", "inputtextgeo default"}) -- not saved to spring's config file on exit
	Spring.SetConfigString("InputTextGeo", "0.26 0.73 0.02 0.028") -- spring default values
	
	self:LocalColorUnregister()
end
