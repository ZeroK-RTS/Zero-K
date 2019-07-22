function widget:GetInfo()
  return {
    name      = "Chili Chat Bubbles",
    desc      = "Shows Chat bubbles",
    author    = "jK",
    date      = "2009 & 2010",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false,
  }
end

include("Widgets/COFCTools/ExportUtilities.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local GetSpectatingState = Spring.GetSpectatingState
local GetTimer = Spring.GetTimer 
local DiffTimers = Spring.DiffTimers

local Chili
local color2incolor
local colorAI = {} -- color for AI team indexed by botname

local msgTypeToColor = {
  player_to_allies = {0,1,0,1},
  player_to_player_received = {0,1,1,1},
  player_to_player_sent = {0,1,1,1},
  player_to_specs = {1,1,0.5,1},
  player_to_everyone = {1,1,1,1},
  
  spec_to_specs = {1,1,0.5,1},
  spec_to_allies = {1,1,0.5,1},
  spec_to_everyone = {1,1,1,1},
  
  --shameful copy-paste -- TODO rewrite pattern matcher to remove this duplication
  replay_spec_to_specs = {1,1,0.5,1},
  replay_spec_to_allies = {1,1,0.5,1},
  replay_spec_to_everyone = {1,1,1,1},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local vsx,vsy = 0,0

local _window_id = 0

local windows = {}

--[[
local window_margin = 5
local window_width  = 400
local window_timeout = 10
--]]
--options_section = 'Interface'
options_path = 'Settings/HUD Panels/Chat/Bubbles'
options_order = {'setavatar','filterGlobalChat', 'filterAutohostMsg', 'text_height', 'window_margin', 'window_width', 'window_height', 'window_timeout', 'firstbubble_y',}
options = {
	setavatar = {
		name = 'Set An Avatar',
		desc = 'Avatar to show next to your bubble. Requires the Avatar widget',
		type = 'button',
		OnChange = function() Spring.SendCommands{"luaui enablewidget Avatars", "setavatar"} end,
		path = 'Settings/HUD Panels/Chat',
	},
	filterGlobalChat = {
		name = 'Filter Global Chat',
		desc = 'Filter out messages made in global chat',
		type = 'bool',
		value = true,
	},
	filterAutohostMsg = {
		name = 'Filter Autohost Messages',
		desc = 'Filter out messages from autohost',
		type = 'bool',
		value = true,
	},	
	text_height = {
		name = 'Font Size (10-18)',
		type = 'number',
		value = 12,
		min=10,max=18,step=1,
	},	
	window_margin = {
		name = 'Margin (0 - 10)',
		desc = 'Margin between bubbles',
		type = 'number',
		min = 0,
		max = 10,
		value = 0,
	},
	window_width  = {
		name = 'Width (200 - 600)',
		desc = '',
		type = 'number',
		min = 200,
		max = 600,
		value = 260,
	},
	window_height  = {
		name = 'Height 60-120',
		desc = '',
		type = 'number',
		min = 40,
		max = 120,
		value = 60,
	},
	
	window_timeout = {
		name = 'Timeout (5 - 50)',
		desc = '',
		type = 'number',
		min = 5,
		max = 50,
		value = 20,
	},
	firstbubble_y = {
		name = 'Screen Height of First Bubble',
		desc = 'How high up the first bubble should start on the right of the screen.',
		type = 'number',
		min = 0,
		max = 600,
		value = 120,
	},
	
}
local windows_fading = {}

-- map points
local windows_points = {}

local avatar_fallback = "LuaUI/Configs/Avatars/Crystal_personal.png"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local playerNameToIDlist = {}
local function MyPlayerNameToID(name)
	local buf = playerNameToIDlist[name]
	if (not buf) then
		local players = Spring.GetPlayerList(true)
		for i=1,#players do
			local pid = players[i]
			local pname = Spring.GetPlayerInfo(pid, false)
			playerNameToIDlist[pname] = pid
		end
		return playerNameToIDlist[name]
	else
		return buf
	end
end

local function newWindowID()
  _window_id = _window_id + 1
  return _window_id
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Update()
	local w = windows[1]
	local time_now = GetTimer()
	if (w)and(DiffTimers(time_now, w.custom_timeadded) > options.window_timeout.value) then
		table.remove(windows,1)
		windows_fading[#windows_fading+1] = w
	end

	local deleted = 0
	for i=1,#windows_fading do
		w = windows_fading[i]
		if (w.x > vsx) then
			deleted = deleted + 1
			windows_fading[i] = nil

			-- cleanup points
			local id = w.window_id
			if windows_points[id] then
				windows_points[id] = nil
			end

			w:Dispose()
		end
		w:SetPos(w.x + 10, w.y) -- this is where it moves the window off the screen
	end

	if (deleted > 0) then
		local num = #windows_fading - deleted
		local i = 1
		repeat
			w = windows_fading[i]
			if (not w) then
				table.remove(windows_fading,i)
				i = i - 1
			end
			i = i + 1
		until (i>num);
	end
end


function PushWindow(window)
	if window then
		window:Realign() --// else `window.height` wouldn't give the desired value
		windows[#windows+1] = window
	end
	local w = windows[1]
	w:SetPos(w.x, options.firstbubble_y.value)
	for i=2,#windows do
		windows[i]:SetPos(w.x, w.y + (w.height + options.window_margin.value))
		w = windows[i]
		if w.y > vsy then	-- overflow, get rid of top window
			windows[1]:Dispose()
			table.remove(windows, 1)
			PushWindow()
			return
		end
	end
end


-- last message
local last_type = nil
local last_a = nil
local last_b = nil
local last_c = nil
local last_timeadded = GetTimer()

-- returns true if current message is same as last one
-- TODO: graphical representation
function DuplicateMessage(type, a, b, c)
	local samemessage = false
	if type == last_type and a == last_a and b == last_b and c == last_c then
		if DiffTimers(GetTimer(), last_timeadded) < options.window_timeout.value then
			samemessage = true
		end
	end
	if not samemessage then
		last_type = type
		last_a = a
		last_b = b
		last_c = c
		last_timeadded = GetTimer()
	end
	return samemessage
end


function widget:AddChatMessage(msg)
	local playerID = msg.player and msg.player.id
	local type = msg.msgtype
	local text = msg.argument or ''
	
	if DuplicateMessage("chat", playerID, msg.argument, type) then 
		return
	end

	local playerName,active,isSpec,teamID
	local teamcolor
	local avatar = nil
	if type == 'autohost' then
		active = false
		playerName = "Autohost"
		isSpec = true
		teamID = 0
	else
		if msg.player and msg.player.isAI then
			teamcolor = colorAI[msg.playername]
			playerName = msg.playername
			active = true
		else
			playerName,active,isSpec,teamID,allyTeamID,pingTime,cpuUsage,country,rank, customKeys  = Spring.GetPlayerInfo(playerID)
			teamcolor = {Spring.GetTeamColor(teamID)}
			if (customKeys ~= nil) and (customKeys.avatar~=nil) then 
				avatar = "LuaUI/Configs/Avatars/" .. customKeys.avatar .. ".png"
			end
		end
	end
	
	if (not active or isSpec) then
		teamcolor = {1,1,1,0.7}
	end
	local bubbleColor = msgTypeToColor[type] or {1,1,1,1}
	local textColor = color2incolor(teamcolor)
	
	if type == 'player_to_player_received' or type == 'player_to_player_sent' then
		text = "Private: " .. text
	end

	local pp = nil
	if WG.alliedCursorsPos then 
		local cur = WG.alliedCursorsPos[playerID]
		if cur ~= nil then 
			pp = {cur[1], cur[2], cur[3], cur[4]}
		end
	end 

	
	local w = Chili.Window:New{
		parent    = Chili.Screen0;
		x         = vsx-options.window_width.value;
		y         = options.firstbubble_y.value;
		width     = options.window_width.value;
		height    = options.window_height.value;
		--minWidth  = options.window_width.value;
		--minHeight = options.window_height.value;
		autosize  = true;
		resizable = false;
		draggable = false;
		
		skinName  = "BubbleBlack";
		color     = bubbleColor;
		padding   = {12, 12, 12, 12};

		custom_timeadded = GetTimer(),
		window_id = newWindowID(),
		OnClick = {function()
			local _, _, meta, _ = Spring.GetModKeyState()
			if meta then
				WG.crude.OpenPath('Settings/HUD Panels/Chat') --click + space will shortcut to option-menu
				WG.crude.ShowMenu() --make epic Chili menu appear.
				return true
			end		
			if pp ~= nil then 
				SetCameraTarget(pp[1], 0, pp[2],1)
			end 
		end},
	}
	function w:HitTest(x,y)
		return self
	end 

	
	Chili.Image:New{
		parent = w;
		file   =   ((WG.Avatar and WG.Avatar.GetAvatar(playerName)) or avatar) or avatar_fallback; --get avatar from "api_avatar.lua" or from server, or use the default avatar
		--file2  = (type=='s') and "LuaUI/Images/tech_progressbar_empty.png";
		width  = options.window_height.value-24;
		height = options.window_height.value-24;
	}
	
	--[[
	local verb = " says:"
	if (type == 'a') then
		verb = " says to allies:"
	elseif (type == 's') then
		verb = " says to spectators:"
	elseif (type == 'p') then
		verb = " whispers to you:"
	elseif (type == 'l') then
		verb = " says:"
	end

	
	local l = Chili.Label:New{
		parent   = w;
		caption  = playerName .. verb;
		--caption  = "<" .. playerName .. ">";
		x        = options.window_height.value - 24;
		y        = 2;
		width    = w.clientWidth - (options.window_height.value - 24) - 5;
		height   = 14;
		valign   = "ascender";
		align    = "left";
		autosize = false;
		font    = {
			size   = 12;
			shadow = true;
		}
	}
	]]--

	Chili.TextBox:New{
		parent  = w;
		text    = textColor .. playerName .. ":\008 " .. color2incolor(bubbleColor) .. text .. "\008";
		x       = options.window_height.value - 24;
		y       = 2;
		width   = w.clientWidth - (options.window_height.value - 24) - 5;
		valign  = "ascender";
		align   = "left";
		font    = {
			size   = options.text_height.value;
			shadow = true;
		}
	}

	PushWindow(w)
end

function widget:AddConsoleMessage(msg)
	
	if not GetSpectatingState() then
	      if (msg.source == 'spec' or msg.source == "enemy") and options.filterGlobalChat.value then 
		      return
	      end
	end
	if msg.msgtype == 'other' then return end
	if msg.msgtype == 'autohost' and options.filterAutohostMsg.value then 
	      return
	end
	widget:AddChatMessage(msg)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local lastPoint = nil


function widget:AddMapPoint(player, caption, px, py, pz)

	if DuplicateMessage("point", player, caption) then
		-- update point for camera target
		local w = windows[#windows]
		if w then
			local index = w.window_id
			windows_points[index].x = px
			windows_points[index].y = py
			windows_points[index].z = pz
		end
		return
	end

	local playerName,active,isSpec,teamID = Spring.GetPlayerInfo(player, false)
	local teamcolor = {Spring.GetTeamColor(teamID)}
	if (not active or isSpec) then
		teamcolor = {1,0,0,1}
	end
	
	local custom_timeadded = GetTimer()
	local window_id = newWindowID()

	windows_points[window_id] = {x = px, y = py, z = pz}

	local w = Chili.Window:New{
		parent    = Chili.Screen0;
		x         = vsx-options.window_width.value;
		y    = options.firstbubble_y.value;
		width     = options.window_width.value;
		height    = options.window_height.value;
		autosize  = true;
		resizable = false;
		--draggable = false;
		skinName  = "BubbleBlack";
		color     = {1,0.2,0.2,1};
		padding   = {12, 12, 12, 12};

		custom_timeadded = custom_timeadded,
		window_id = window_id,

		draggable = false,
		-- OnMouseDown is needed for OnClick
		OnMouseDown = {function(self) return true end}, --capture click (don't allow window to pass the click). this prevent user from accidentally clicking on the ground while clicking on the window.
		OnClick = {function(self)
			local p = windows_points[window_id]
			SetCameraTarget(p.x, p.y, p.z,1)
		end},
	}
	function w:HitTest(x,y)  -- FIXME: chili hacked to allow OnClick on window
		return self
	end 

	Chili.Image:New{
		parent = w;
		file   = 'LuaUI/Images/Crystal_Clear_action_flag.png';
		width  = options.window_height.value-24;
		height = options.window_height.value-24;
	}
	local text = color2incolor(teamcolor) .. playerName .. "\008 added point" .. (caption and (": " .. caption) or '')
	
	local l = Chili.TextBox:New{
		parent   = w;
		text  = text;
		x        = options.window_height.value - 24;
		y        = 2;
		width    = w.clientWidth - (options.window_height.value - 24) - 5;
		valign   = "ascender";
		align    = "left";
		font    = {
			size   = options.text_height.value;
			shadow = true;
		}
	}
	PushWindow(w)
end

function widget:MapDrawCmd(playerID, cmdType, px, py, pz, caption)
	if (cmdType == 'point') then
		widget:AddMapPoint(playerID,caption, px,py,pz)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:AddWarning(text)

	if DuplicateMessage("warning", text) then return end

	teamcolor = {1,0.5,0,1}

	local w = Chili.Window:New{
		parent    = Chili.Screen0;
		x         = vsx-options.window_width.value;
		y         = options.firstbubble_y.value;
		width     = options.window_width.value;
		height    = options.window_height.value;
		resizable = false;
		draggable = false;
		skinName  = "BubbleBlack";
		color     = teamcolor;
		padding   = {12, 12, 12, 12};

		custom_timeadded = GetTimer(),
		window_id = newWindowID(),
	}

	Chili.Image:New{
		parent = w;
		file   = 'LuaUI/Images/Crystal_Clear_app_error.png';
		width  = options.window_height.value-24;
		height = options.window_height.value-24;
	}

	Chili.Label:New{
		parent  = w;
		caption = text;
		x       = options.window_height.value - 24;
		width   = w.clientWidth - (options.window_height.value - 24) - 5;
		height  = "90%";
		valign  = "center";
		align   = "left";
		font    = {
			color = {1, 0.5, 0, 1},
			size   = options.text_height.value;
			shadow = true;
		}
	}

	PushWindow(w)
end


function widget:TeamDied(teamID)
	local player = Spring.GetPlayerList(teamID)[1]
	-- chicken team has no players (normally)
	if player then
		local playerName = Spring.GetPlayerInfo(player, false)
		widget:AddWarning(playerName .. ' died')
	end
end

--[[
function widget:TeamChanged(teamID)
	--// ally changed
	local playerName = Spring.GetPlayerInfo(Spring.GetPlayerList(teamID)[1], false)
	widget:AddWarning(playerName .. ' allied')
end
--]]

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
				colorAI[name] = {Spring.GetTeamColor(teamID)}
			end
		end --if teamID ~= Spring.GetGaiaTeamID() 
	end --for each team		
end

function widget:PlayerChanged(playerID)
	local playerName,active,isSpec,teamID = Spring.GetPlayerInfo(playerID, false)
  local _,_,isDead = Spring.GetTeamInfo(teamID, false)
	if (isSpec) then
		if not isDead then
			widget:AddWarning(playerName .. ' resigned')
		end
	elseif (Spring.GetDrawFrame()>120) then --// skip `changed status` message flood when entering the game
		widget:AddWarning(playerName .. ' changed status')
	end
end

function widget:PlayerRemoved(playerID, reason)
	local playerName = Spring.GetPlayerInfo(playerID, false)
	if reason == 0 then
		widget:AddWarning(playerName .. ' timed out')
	elseif reason == 1 then
		widget:AddWarning(playerName .. ' quit')
	elseif reason == 2 then
		widget:AddWarning(playerName .. ' got kicked')
	else
		widget:AddWarning(playerName .. ' left (unknown reason)')
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:SetConfigData()
end

function widget:GetConfigData()
end

function widget:Shutdown()
	for i=1,#windows do
		local w = windows[i]
		w:Dispose()
	end
	for i=1,#windows_fading do
		local w = windows_fading[i]
		w:Dispose()
	end

	windows = nil
	windows_fading = nil
end

function widget:ViewResize(vsx_, vsy_)
	vsx = vsx_
	vsy = vsy_
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()

	if (not WG.Chili) then
		widgetHandler:RemoveWidget()
		return
	end

	Chili = WG.Chili
	color2incolor = Chili.color2incolor
	SetupAITeamColor()

	widget:ViewResize(Spring.GetViewGeometry())
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
