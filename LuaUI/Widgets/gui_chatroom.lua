function widget:GetInfo()
  return {
    name      = "Chatroom",
    desc      = "Chatroom GUI.",
    author    = "CarRepairer",
    date      = "2010-12-18",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("keysym.h.lua")

local spSendLuaRulesMsg			= Spring.SendLuaRulesMsg
local spGetCurrentTooltip		= Spring.GetCurrentTooltip
local spGetUnitDefID			= Spring.GetUnitDefID
local spGetUnitAllyTeam			= Spring.GetUnitAllyTeam
local spGetUnitTeam				= Spring.GetUnitTeam
local spTraceScreenRay			= Spring.TraceScreenRay
local spGetTeamInfo				= Spring.GetTeamInfo
local spGetPlayerInfo			= Spring.GetPlayerInfo
local spGetTeamColor			= Spring.GetTeamColor

local echo = Spring.Echo

local VFSMODE      = VFS.RAW_FIRST
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Chili
local Button
local Label
local Window
local ScrollPanel
local StackPanel
local Grid
local TextBox
local Image
local screen0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local B_HEIGHT 		= 30
local icon_size 	= 18

local scrH, scrW 		= 0,0
local myAlliance 		= Spring.GetLocalAllyTeamID()
local myTeamID 			= Spring.GetLocalTeamID()

local window_avatar
local window_bubbles = {}


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function CloseButtonFunc(self)
	self.parent.parent:Dispose()
end
local function CloseButtonFunc2(self)
	self.parent.parent.parent:Dispose()
end

local function CloseButton(width)
	return Button:New{ 
		caption = 'Close',
		bottom=0,
		OnMouseUp = { CloseButtonFunc }, 
		width=width, 
		height = B_HEIGHT,
	}
end

local function AvatarWindow(unitID, action)
	local window_width = 250
	
	local command = '^'
	
	local children = {}
	children[#children+1] = Label:New{ caption = 'Choose your 3D Avatar (20s delay)', width=window_width, height=B_HEIGHT }
	
	local grid_children = {}
	
	local UnitDefs2 = {}
	for udid, ud in ipairs(UnitDefs) do
		if ud.speed > 0.1 then
			UnitDefs2[#UnitDefs2+1] = {udid, ud}
		end
	end
	table.sort(UnitDefs2, function(a,b) return a[2].humanName < b[2].humanName; end )
	
	for _, data in ipairs(UnitDefs2) do
		local udid, ud = data[1], data[2]
		grid_children[#grid_children+1] = Image:New{
			file = "#" .. ud.id,
			file2 = (WG.GetBuildIconFrame)and(WG.GetBuildIconFrame(ud)),
			keepAspect = false,
			height  = 55*(4/5),
			width   = 55,
		}
		local func = function() spSendLuaRulesMsg(  command .. udid ) end
		grid_children[#grid_children+1] = Button:New{ 
			caption = ud.humanName, 
			--OnMouseUp = { func, CloseButtonFunc2, },
			OnMouseUp = { func, },
			width=window_width,
			height = 55*(4/5),
		}
	end
	
	local grid_height = (55*(4/5) + 4 )* #grid_children/2
	local ava_grid = Grid:New{
		--rows = 3,
		columns = 2,
		resizeItems=false,
		width = '100%',
		height = grid_height,
		padding = {0,0,0,0},
		itemPadding = {2,2,2,2},
		itemMargin = {0,0,0,0},
		
		children = grid_children,
	}
	-- [[
	local ava_scroll = ScrollPanel:New{
		horizontalScrollbar = false,
		x=0,y=B_HEIGHT,
		width='100%',
		bottom = B_HEIGHT*2,
		padding = {2,2,2,2},
		children = { ava_grid },
	}
	--]]
	children[#children+1] = ava_scroll
	
	children[#children+1] = Label:New{ caption = '', bottom=B_HEIGHT, width='100%', height=B_HEIGHT, autosize=false,}

	children[#children+1] =  CloseButton(window_width)
	
	local window_height = (B_HEIGHT) * (#children-1) + grid_height

	local window = Window:New{  
		x = scrW/2,  
		y = scrH/2,
		width='20%',
		height = '60%',
		resizable = true,
		parent = screen0,
		children = children,
	}
	return window
end

local function GetUnitAttributes(unitID, unitDefID)
	--[[
	local team = GetUnitTeam(unitID)
	local _, player = GetTeamInfo(team)
	local name = GetPlayerInfo(player) or 'Robert Paulson'
	local r, g, b, a = GetTeamColor(team)
	local height = UnitDefs[unitDefID].height + heightOffset
	local pm = spGetUnitPieceMap(unitID)
	local pmt = pm["torso"]
	if (pmt == nil) then 
		pmt = pm["chest"]
	end    
	return {name, {r, g, b, a}, height, pmt }
	--]]
end

local _window_id = 1
local avatar_fallback = "LuaUI/Configs/Avatars/Crystal_personal.png"

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
local function newWindowID()
  _window_id = _window_id + 1
  return _window_id
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:AddConsoleLine(msg)
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
	widget:AddChatMessage(playerID,mesg,type)
end

function widget:AddChatMessage(playerID, msg, type)

	--if NewMessage("chat", playerID, msg, type) then return end

	local wheight = 80
	
	local playerName,active,isSpec,teamID
	local teamcolor
	if playerID < 0 then
		active = false
		playerName = "Autohost"
		isSpec = true
		teamID = 0
	else
		playerName,active,isSpec,teamID = Spring.GetPlayerInfo(playerID)
		teamcolor = {Spring.GetTeamColor(teamID)}
	end
	if (not active or isSpec) then
		teamcolor = {1,1,1,0.7}
	end

	local w = Chili.Window:New{
		--parent    = Chili.Screen0;
		width     = 200;
		height    = wheight;
		minWidth  = 20;
		minHeight = 20;
		autosize  = true;
		resizable = false;
		draggable = false;
		skinName  = "DarkGlass";
		color     = teamcolor;
		padding   = {16, 16, 16, 16};

		--custom_timeadded = GetTimer(),
		window_id = newWindowID(),
	}
	function w:HitTest(x,y)
		return self
	end 

	Chili.Image:New{
		parent = w;
		file   = (WG.Avatar) and (WG.Avatar.GetAvatar(playerName)) or avatar_fallback;
		--file2  = (type=='s') and "LuaUI/Images/tech_progressbar_empty.png";
		width  = wheight;
		height = '100%';
	}

	Chili.TextBox:New{
		parent  = w;
		text    = msg;
		x       = wheight+2;
		y       = 2;
		width = 200,
		valign  = "ascender";
		align   = "left";
		font    = {
			size   = 14;
			shadow = true;
		}
	}
	if window_bubbles[playerID] then
		window_bubbles[playerID]:Dispose()
	end
	window_bubbles[playerID] = w

end

function widget:ViewResize(vsx, vsy)
	scrW = vsx
	scrH = vsy
end

function widget:UnitCreated(unitID, unitDefID, teamID)
	
end

function widget:Initialize()
	if 
		(Spring.GetGameRulesParam("chatroom") ~= 1)
		or (not WG.Chili)
		then
		
		widgetHandler:RemoveWidget(widget)
		return
	end

	-- setup Chili
	 Chili = WG.Chili
	 Button = Chili.Button
	 Label = Chili.Label
	 Window = Chili.Window
	 ScrollPanel = Chili.ScrollPanel
	 StackPanel = Chili.StackPanel
	 Grid = Chili.Grid
	 TextBox = Chili.TextBox
	 Image = Chili.Image
	 screen0 = Chili.Screen0

	widget:ViewResize(Spring.GetViewGeometry())
	
	window_avatar = AvatarWindow()
end

function widget:Shutdown()
end

function widget:DrawScreen()
	local extra = 20
	local visibleUnits = Spring.GetVisibleUnits(-1,nil,false)
	for _,unitID in ipairs(visibleUnits) do
		local teamID = Spring.GetUnitTeam(unitID)
		if teamID then
			local _, playerID = Spring.GetTeamInfo(teamID)
			local bubblewindow = window_bubbles[playerID]
			if bubblewindow then
				if not bubblewindow:IsDescendantOf(screen0) then
					screen0:AddChild(bubblewindow)
				end
				local ux,uy,uz = Spring.GetUnitPosition(unitID)
				local sx,sy,sz = Spring.WorldToScreenCoords(ux,uy,uz)
				--echo('setting window pos', sx, sy, sz)
				bubblewindow:SetPos(sx+extra,scrH-(sy+extra+bubblewindow.height))
			end
		end
	end
end
