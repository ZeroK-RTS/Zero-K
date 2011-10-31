--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Chat Bubbles",
    desc      = "Shows Chat bubbles",
    author    = "jK",
    date      = "2009 & 2010",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,
	detailsDefault = Spring.GetConfigInt("widgetDetailLevel", 3) > 0,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local GetTimer = Spring.GetTimer 
local DiffTimers = Spring.DiffTimers

local Chili

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
options_path = 'Settings/Interface/Chat/Bubbles'
options_order = {'lblblank', 'setavatar', 'window_margin', 'window_width', 'window_height', 'window_timeout', 'firstbubble_y',}
options = {
	
	lblblank = {type='label', name=''},
	setavatar = {
		name = 'Set An Avatar',
		desc = 'Avatar to show next to your bubble. Requires the Avatar widget',
		type = 'button',
		OnChange = function() Spring.SendCommands{"luaui enablewidget Avatars", "setavatar"} end,
		path = 'Settings/Interface/Chat',
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
		min = 60,
		max = 120,
		value = 80,
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
			local pname = Spring.GetPlayerInfo(pid)
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
		w:SetPos(w.x + 10, w.y)
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
	window:Realign() --// else `window.height` wouldn't give the desired value
	windows[#windows+1] = window
	local w = windows[1]
	w:SetPos(w.x, options.firstbubble_y.value)
	for i=2,#windows do
		windows[i]:SetPos(w.x, w.y + (w.height + options.window_margin.value))
		w = windows[i]
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
function NewMessage(type, a, b, c)
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


function widget:AddChatMessage(player, msg, type)

	if NewMessage("chat", player, msg, type) then return end

	local playerName,active,isSpec,teamID
	local teamcolor
	local avatar = nil
	if player < 0 then
		active = false
		playerName = "Autohost"
		isSpec = true
		teamID = 0
	else
		playerName,active,isSpec,teamID,allyTeamID,pingTime,cpuUsage,country,rank, customKeys  = Spring.GetPlayerInfo(player)
		teamcolor = {Spring.GetTeamColor(teamID)}
		if (customKeys ~= nil and customKeys.avatar~=nil) then 
			avatar = "LuaUI/Configs/Avatars/" .. customKeys.avatar .. ".png"
		end 
	end
	if (not active or isSpec) then
		teamcolor = {1,1,1,0.7}
	end

	local pp = nil
	if WG.alliedCursorsPos then 
		pp = WG.alliedCursorsPos[player]
	end 

	
	local w = Chili.Window:New{
		parent    = Chili.Screen0;
		x         = vsx-options.window_width.value;
		y    = options.firstbubble_y.value;
		width     = options.window_width.value;
		height    = options.window_height.value;
		minWidth  = options.window_width.value;
		minHeight = options.window_height.value;
		autosize  = true;
		resizable = false;
		draggable = false;
		
		skinName  = "DarkGlass";
		color     = teamcolor;
		padding   = {16, 16, 16, 16};

		custom_timeadded = GetTimer(),
    window_id = newWindowID(),
		OnMouseDown = {function() 
			if pp ~= nil then 
				Spring.SetCameraTarget(pp[1], 0, pp[2],1)
			end 
		end},
	}
	function w:HitTest(x,y)
		return self
	end 

	
	Chili.Image:New{
		parent = w;
		file   =   (WG.Avatar) and (WG.Avatar.GetAvatar(playerName)) or avatar_fallback;
		--file2  = (type=='s') and "LuaUI/Images/tech_progressbar_empty.png";
		width  = options.window_height.value-36;
		height = options.window_height.value-36;
	}

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
		x        = options.window_height.value - 36;
		y        = 2;
		width    = w.clientWidth - (options.window_height.value - 36) - 5;
		height   = 14;
		valign   = "ascender";
		align    = "left";
		autosize = false;
		font    = {
			size   = 12;
			shadow = true;
		}
	}

	Chili.TextBox:New{
		parent  = w;
		text    = msg;
		x       = options.window_height.value - 32;
		y       = l.y + l.height + 2;
		width   = w.clientWidth - (options.window_height.value - 32) - 10;
		valign  = "ascender";
		align   = "left";
		font    = {
			size   = 14;
			shadow = true;
		}
	}

	PushWindow(w)
end


local function ExtractMsgType(str)
	local ally      =            select(2, str:find("^(Allies: )"))
	local private   = ally or    select(2, str:find("^(Private: )"))
	local spectator = private or select(2, str:find("^(Spectators: )"))

	local type     = ''
	local msgstart = ally or private or spectator
	if (msgstart) then
		str = str:sub(msgstart + 1)
		type = (ally and 'a') or (private and 'p') or (spectator and 's')
	end

	return type, str
end


function widget:AddConsoleLine(msg)
	if Game.version == "0.82.7.0 (0.82.7)" then msg = msg:sub(13) end	-- truncate framenumber (workaround for 0.82.7.0)
	
	local firstChar = msg:sub(1,1)

	local nickend
	local autohost
	if (firstChar == "<") then
		--// message comes from a player
		nickend = msg:find("> ", 1, true)
	elseif (firstChar == "[") then
		--// message comes from a spectator
		nickend = msg:find("] ", 1, true)
	elseif (firstChar == ">") then
		--// dedicated autohost relay message
		if (msg:sub(1,2) == "> ") then
			autohost = true

			-- autohost interface is ambiguous 
			-- [[CLAN]bob]hello! - normal chat
			-- [CLAN]bob has left lobby - leaving message
			-- [alice]bob has left lobby -- chat mesage from alice

			--local i = 1
			--while (i) do i = msg:find(']',i+1,true); if (i) then nickend = i end end
		end
	end

	if not (nickend or autohost) then
		return
	end
	local playerID = -1
	local type,mesg
	if nickend and not autohost then -- ingame
		local playerName = msg:sub(2, nickend-1)
		playerID = MyPlayerNameToID(playerName)
		if (not playerID) then
			return
		end
		msg = msg:sub(nickend+2)
		type,mesg = ExtractMsgType(msg)
		
	else -- autohost
		mesg = msg:sub(3)
		type = 'l'
	end
	if (type == 'a' or type=='p') then 
		widget:AddChatMessage(playerID,mesg,type)
	end 
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local lastPoint = nil


function widget:AddMapPoint(player, caption, px, py, pz)

	if NewMessage("point", player, caption) then
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

	local playerName,active,isSpec,teamID = Spring.GetPlayerInfo(player)
	local teamcolor = {1,0,0,1}
	if (not active or isSpec) then
		teamcolor = {1,0,0,0.7}
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
		skinName  = "DarkGlass";
		color     = teamcolor;
		padding   = {16, 16, 16, 16};

		custom_timeadded = custom_timeadded,
    window_id = window_id,

		draggable = false,
		OnMouseDown = {function()
			local p = windows_points[window_id]
			Spring.SetCameraTarget(p.x, p.y, p.z,1)
		end},
	}
	function w:HitTest(x,y)  -- FIXME: chili hacked to allow OnMouseDown on window
		return self
	end 

	Chili.Image:New{
		parent = w;
		file   = 'LuaUI/Images/Crystal_Clear_action_flag.png';
		width  = options.window_height.value-36;
		height = options.window_height.value-36;
		

	}

	if (caption)and(caption ~= "") then
		local l = Chili.Label:New{
			parent   = w;
			caption  = playerName .. " added point:";
			x        = options.window_height.value - 36;
			y        = 2;
			width    = w.clientWidth - (options.window_height.value - 36) - 5;
			valign   = "ascender";
			align    = "left";
			autosize = false;
			font    = {
				size   = 12;
				shadow = true;
			}
		}

		Chili.TextBox:New{
			parent  = w;
			text    = caption;
			x       = options.window_height.value - 32;
			y       = l.y + l.height - 5;
			width   = w.clientWidth - (options.window_height.value - 32) - 10;
			valign  = "ascender";
			align   = "left";
			font    = {
				size   = 14;
				shadow = true;
			}
		}
	else
		Chili.Label:New{
			parent   = w;
			caption  = playerName .. " added point";
			x        = options.window_height.value - 32;
			width    = w.clientWidth - (options.window_height.value - 32) - 10;
			height   = "90%";
			valign   = "center";
			align    = "left";
			autosize = false;
			font    = {
				size   = 14;
				shadow = true;
			},
		}
	end

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

	if NewMessage("warning", text) then return end

	teamcolor = {1,1,0,1}

	local w = Chili.Window:New{
		parent    = Chili.Screen0;
		x         = vsx-options.window_width.value;
		y   = options.firstbubble_y.value;
		width     = options.window_width.value;
		height    = options.window_height.value;
		resizable = false;
		draggable = false;
		skinName  = "DarkGlass";
		color     = teamcolor;
		padding   = {16, 16, 16, 16};

		custom_timeadded = GetTimer(),
    window_id = newWindowID(),
	}

	Chili.Image:New{
		parent = w;
		file   = 'LuaUI/Images/Crystal_Clear_app_error.png';
		width  = options.window_height.value-36;
		height = options.window_height.value-36;
	}

	Chili.Label:New{
		parent  = w;
		caption = text;
		x       = options.window_height.value - 36;
		width   = w.clientWidth - (options.window_height.value - 36) - 5;
		height  = "90%";
		valign  = "center";
		align   = "left";
		font    = {
			size   = 14;
			shadow = true;
		}
	}

	PushWindow(w)
end


function widget:TeamDied(teamID)
	local player = Spring.GetPlayerList(teamID)[1]
	-- chicken team has no players (normally)
	if player then
		local playerName = Spring.GetPlayerInfo(player)
		widget:AddWarning(playerName .. ' died')
	end
end

--[[
function widget:TeamChanged(teamID)
	--// ally changed
	local playerName = Spring.GetPlayerInfo(Spring.GetPlayerList(teamID)[1])
	widget:AddWarning(playerName .. ' allied')
end
--]]

function widget:PlayerChanged(playerID)
	local playerName,active,isSpec,teamID = Spring.GetPlayerInfo(playerID)
  local _,_,isDead = Spring.GetTeamInfo(teamID)
	if (isSpec) then
		if not isDead then
			widget:AddWarning(playerName .. ' resigned')
		end
	elseif (Spring.GetDrawFrame()>120) then --// skip `changed status` message flood when entering the game
		widget:AddWarning(playerName .. ' changed status')
	end
end

function widget:PlayerRemoved(playerID, reason)
	local playerName = Spring.GetPlayerInfo(playerID)
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

	widget:ViewResize(Spring.GetViewGeometry())
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
