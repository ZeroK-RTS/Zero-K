
function widget:GetInfo()
	return {
		name      = "Chili Crude Player List",
		desc      = "An inexpensive playerlist.",
		author    = "GoogleFrog",
		date      = "8 November 2019",
		license   = "GNU GPL, v2 or later",
		layer     = 50,
		enabled   = true,
	}
end

-- A test game: http://zero-k.info/Battles/Detail/797379
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

Spring.Utilities = Spring.Utilities or {}

function Spring.Utilities.GetTruncatedString(myString, myFont, maxLength)
	if (not maxLength) then
		return myString
	end
	local length = string.len(myString)
	while myFont:GetTextWidth(myString) > maxLength do
		length = length - 1
		myString = string.sub(myString, 0, length)
		if length < 1 then
			return ""
		end
	end
	return myString
end

function Spring.Utilities.GetTruncatedStringWithDotDot(myString, myFont, maxLength)
	if (not maxLength) or (myFont:GetTextWidth(myString) <= maxLength) then
		return myString
	end
	local truncation = Spring.Utilities.GetTruncatedString(myString, myFont, maxLength)
	local dotDotWidth = myFont:GetTextWidth("..")
	truncation = Spring.Utilities.GetTruncatedString(truncation, myFont, maxLength - dotDotWidth)
	return truncation .. ".."
end

function Spring.Utilities.TruncateStringIfRequired(myString, myFont, maxLength)
	if (not maxLength) or (myFont:GetTextWidth(myString) <= maxLength) then
		return false
	end
	return Spring.Utilities.GetTruncatedString(myString, myFont, maxLength)
end

function Spring.Utilities.TruncateStringIfRequiredAndDotDot(myString, myFont, maxLength)
	if (not maxLength) or (myFont:GetTextWidth(myString) <= maxLength) then
		return false
	end
	return Spring.Utilities.GetTruncatedStringWithDotDot(myString, myFont, maxLength)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local myAllyTeamID          = Spring.GetMyAllyTeamID()
local myTeamID              = Spring.GetMyTeamID()
local myPlayerID            = Spring.GetMyPlayerID()
local mySpectating          = Spring.GetSpectatingState()
local spGetPlayerRulesParam = Spring.GetPlayerRulesParam

if mySpectating then
	myTeamID = false
	myAllyTeamID = false
end
local fallbackAllyTeamID    = Spring.GetMyAllyTeamID()

local Chili

local function GetColorChar(colorTable)
	if colorTable == nil then return string.char(255,255,255,255) end
	local col = {}
	for i = 1, 4 do
		col[i] = math.ceil(colorTable[i]*255)
	end
	return string.char(col[4],col[1],col[2],col[3])
end

local pingMult = 2/3 -- lower = higher ping needed to be red
local pingCpuColors = {
	{0, 1, 0, 1},
	{0.7, 1, 0, 1},
	{1, 1, 0, 1},
	{1, 0.6, 0, 1},
	{1, 0, 0, 1},
	{1, 1, 1, 1},
}

local ALLY_COLOR  = {0, 1, 1, 1}
local ENEMY_COLOR = {1, 0, 0, 1}

local PING_TIMEOUT = 2000 -- ms

local MAX_NAME_LENGTH = 150
local WINDOW_WIDTH = MAX_NAME_LENGTH + 130

local UPDATE_PERIOD = 1

local IMAGE_SHARE  = ":n:" .. LUAUI_DIRNAME .. "Images/playerlist/share.png"
local IMAGE_CPU    = ":n:" .. LUAUI_DIRNAME .. "Images/playerlist/cpu.png"
local IMAGE_PING   = ":n:" .. LUAUI_DIRNAME .. "Images/playerlist/ping.png"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function PingTimeOut(pingTime)
	if pingTime < 1 then
		return "Ping " .. (math.floor(pingTime*1000) ..'ms')
	elseif pingTime > 999 then
		return "Ping " .. ('' .. (math.floor(pingTime*100/60)/100)):sub(1,4) .. 'min'
	end
	--return (math.floor(pingTime*100))/100
	return "Ping " .. ('' .. (math.floor(pingTime*100)/100)):sub(1,4) .. 's' --needed due to rounding errors.
end

local function CpuUsageOut(cpuUsage)
	return "CPU usage " .. math.ceil(cpuUsage*100) .. "%"
end

local function ToGrey(v)
	if v < 0.6 then
		return 0.6 - 0.1*(0.6 - v)
	end
	return 0.6 + 0.1*(v - 0.6)
end

local function GetName(name, font, state)
	if state.isDead then
		name = "<Dead> " .. name
	elseif state.isLagging then
		name = "<Lagging> " .. name
	elseif state.isAfk then
		name = "<AFK> " .. name
	end
	
	if not font then
		return name
	end
	return Spring.Utilities.TruncateStringIfRequiredAndDotDot(name, font, MAX_NAME_LENGTH) or name
end

local function GetPlayerTeamColor(teamID, isDead)
	local r, g, b, a = Spring.GetTeamColor(teamID)
	if isDead then
		r, g, b = ToGrey(r), ToGrey(g), ToGrey(b)
	end
	return {r, g, b, a}
end

local function ShareUnits(playername, team)
	local selcnt = Spring.GetSelectedUnitsCount()
	if selcnt > 0 then
		Spring.SendCommands("say a: I gave "..selcnt.." units to "..playername..".")
		Spring.ShareResources(team, "units")
	else
		Spring.Echo('Player List: No units selected to share.')
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function UpdateEntryData(entryData, controls, pingCpuOnly, forceUpdateControls)
	local newTeamID, newAllyTeamID = entryData.teamID, entryData.allyTeamID
	local newIsLagging = entryData.isLagging
	local isSpectator = false
	
	if entryData.playerID then
		local playerName, active, spectator, teamID, allyTeamID, pingTime, cpuUsage, country, rank = Spring.GetPlayerInfo(entryData.playerID, false)
		newTeamID, newAllyTeamID = teamID, allyTeamID
		
		entryData.isMe = (entryData.playerID == myPlayerID)
		
		if spectator then
			isSpectator = true
			newTeamID, newAllyTeamID = entryData.initTeamID,  entryData.initAllyTeamID
		end
		
		local pingBucket = (active and math.max(1, math.min(5, math.ceil(math.min(pingTime, 1) * 5)))) or 6
		if forceUpdateControls or pingBucket ~= entryData.pingBucket then
			entryData.pingBucket = pingBucket
			if controls then
				controls.imPing.color = pingCpuColors[entryData.pingBucket]
				controls.imPing:Invalidate()
			end
		end
		
		local cpuBucket = (active and math.max(1, math.min(5, math.ceil(cpuUsage * 5)))) or 6
		if forceUpdateControls or cpuBucket ~= entryData.cpuBucket then
			entryData.cpuBucket = cpuBucket
			if controls then
				controls.imCpu.color = pingCpuColors[entryData.cpuBucket]
				controls.imCpu:Invalidate()
			end
		end
		
		if controls then
			controls.imCpu.tooltip = CpuUsageOut(cpuUsage)
			controls.imPing.tooltip = PingTimeOut(pingTime)
		end
		
		newIsLagging = (((not active) or (pingTime > PING_TIMEOUT)) and true) or false
		if forceUpdateControls or newIsLagging ~= entryData.isLagging then
			entryData.isLagging = newIsLagging
			if controls and not entryData.isDead then
				controls.textName:SetCaption(GetName(entryData.name, controls.textName.font, entryData))
			end
		end
		
		newIsAfk = (spGetPlayerRulesParam(entryData.playerID, "lagmonitor_lagging") and true) or false
		if forceUpdateControls or newIsAfk ~= entryData.isAfk then
			entryData.isAfk = newIsAfk
			if controls and not (entryData.isDead or entryData.isLagging) then
				controls.textName:SetCaption(GetName(entryData.name, controls.textName.font, entryData))
			end
		end
		
		if pingCpuOnly then
			return false
		end
	elseif pingCpuOnly then
		return false
	end
	
	-- Ping and CPU cannot resort
	local resortRequired = false
	
	if forceUpdateControls or newTeamID ~= entryData.teamID then
		entryData.teamID = newTeamID
		entryData.isMyTeam = (entryData.teamID == myTeamID)
		resortRequired = true
		if controls then
			controls.textName.font.color = GetPlayerTeamColor(entryData.teamID, entryData.isDead)
			controls.textName:Invalidate()
		end
	end
	
	if forceUpdateControls or newAllyTeamID ~= entryData.allyTeamID then
		entryData.allyTeamID = newAllyTeamID
		resortRequired = true
		if controls then
			controls.textAllyTeam:SetCaption(entryData.allyTeamID + 1)
		end
	end
	
	local isMyAlly = (entryData.allyTeamID == (myAllyTeamID or fallbackAllyTeamID))
	if forceUpdateControls or isMyAlly ~= entryData.isMyAlly then
		entryData.isMyAlly = isMyAlly
		entryData.allyTeamColor = (isMyAlly and ALLY_COLOR) or ENEMY_COLOR
		resortRequired = true
		if controls then
			controls.textAllyTeam.font.color = entryData.allyTeamColor
			controls.textAllyTeam:Invalidate()
			
			controls.btnShare:SetVisibility((myAllyTeamID and entryData.isMyAlly and (entryData.teamID ~= myTeamID) and true) or false)
		end
	end
	
	local newIsDead = ((isSpectator or Spring.GetTeamRulesParam(entryData.teamID, "isDead")) and true) or false
	if forceUpdateControls or newIsDead ~= entryData.isDead then
		entryData.isDead = newIsDead
		if controls then
			controls.textName:SetCaption(GetName(entryData.name, controls.textName.font, entryData))
			controls.textName.font.color = GetPlayerTeamColor(entryData.teamID, entryData.isDead)
			controls.textName:Invalidate()
		end
	end
	
	return resortRequired
end

local function GetEntryData(playerID, teamID, allyTeamID, isAiTeam, isDead)
	local entryData = {
		playerID = playerID,
		teamID = teamID,
		allyTeamID = allyTeamID,
		initTeamID = teamID,
		initAllyTeamID = allyTeamID,
		isAiTeam = isAiTeam,
		isDead = isDead,
	}
	
	if playerID then
		local playerName, active, spectator, teamID, allyTeamID, pingTime, cpuUsage, country, rank, _, customKeys = Spring.GetPlayerInfo(playerID, true)
		customKeys = customKeys or {}
		
		entryData.isMe = (entryData.playerID == myPlayerID)
		entryData.name = playerName
		entryData.country = (country and country ~= '' and ("LuaUI/Images/flags/" .. country ..".png"))
		entryData.rank = ("LuaUI/Images/LobbyRanks/" .. (customKeys.icon or "0_0") .. ".png")
		
		if customKeys.clan and customKeys.clan ~= "" then
			entryData.clan = "LuaUI/Configs/Clans/" .. customKeys.clan ..".png"
		elseif customKeys.faction and customKeys.faction ~= "" then
			entryData.clan = "LuaUI/Configs/Factions/" .. customKeys.faction .. ".png"
		end
	end
	
	if isAiTeam then
		local _, name = Spring.GetAIInfo(teamID)
		entryData.name = name
	end
	
	if not entryData.name then
		entryData.name = "noname"
	end
	
	UpdateEntryData(entryData)
	
	return entryData
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetUserControls(playerID, teamID, allyTeamID, isAiTeam, isDead, parent)
	local offset             = 0
	local offsetY            = 0
	local height             = options.text_height.value + 4
	local userControls = {}

	userControls.entryData = GetEntryData(playerID, teamID, allyTeamID, isAiTeam, isDead)

	userControls.mainControl = Chili.Control:New {
		name = playerID,
		x = 0,
		bottom = 0,
		right = 0,
		height = height,
		padding = {0, 0, 0, 0},
		parent = parent
	}

	offset = offset + 1
	if userControls.entryData.country then
		userControls.imCountry = Chili.Image:New {
			name = "imCountry",
			x = offset,
			y = offsetY,
			width = options.text_height.value + 3,
			height = options.text_height.value + 3,
			parent = userControls.mainControl,
			keepAspect = true,
			file = userControls.entryData.country,
		}
	end
	offset = offset + options.text_height.value + 3

	offset = offset + 1
	if userControls.entryData.rank then
		userControls.imRank = Chili.Image:New {
			name = "imRank",
			x = offset,
			y = offsetY,
			width = options.text_height.value + 3,
			height = options.text_height.value + 3,
			parent = userControls.mainControl,
			keepAspect = true,
			file = userControls.entryData.rank,
		}
	end
	offset = offset + options.text_height.value + 3
	
	offset = offset + 1
	if userControls.entryData.clan then
		userControls.imClan = Chili.Image:New {
			name = "imClan",
			x = offset,
			y = offsetY,
			width = options.text_height.value + 3,
			height = options.text_height.value + 3,
			parent = userControls.mainControl,
			keepAspect = true,
			file = userControls.entryData.clan,
		}
	end
	offset = offset + options.text_height.value + 3
	
	offset = offset + 15
	userControls.textAllyTeam = Chili.Label:New {
		name = "textAllyTeam",
		x = offset,
		y = offsetY + 1,
		right = 0,
		bottom = 3,
		parent = userControls.mainControl,
		caption = userControls.entryData.allyTeamID + 1,
		textColor = userControls.entryData.allyTeamColor,
		fontsize = options.text_height.value,
		fontShadow = true,
		autosize = false,
	}
	offset = offset + options.text_height.value + 3
	
	offset = offset + 2
	userControls.textName = Chili.Label:New {
		name = "textName",
		x = offset,
		y = offsetY + 1,
		right = 0,
		bottom = 3,
		align = "left",
		parent = userControls.mainControl,
		caption = GetName(userControls.entryData.name, nil, userControls.entryData),
		textColor = GetPlayerTeamColor(userControls.entryData.teamID, userControls.entryData.isDead),
		fontsize = options.text_height.value,
		fontShadow = true,
		autosize = false,
	}
	userControls.textName:SetCaption(GetName(userControls.entryData.name, userControls.textName.font, userControls.entryData))
	offset = offset + MAX_NAME_LENGTH

	offset = offset + 1
	userControls.btnShare = Chili.Button:New {
		name = "btnShare",
		x = offset + 2,
		y = offsetY + 2,
		width = options.text_height.value - 1,
		height = options.text_height.value - 1,
		parent = userControls.mainControl,
		caption = "",
		tooltip = "Double click to share the units you have selected to this player.",
		padding ={0,0,0,0},
		OnDblClick = { function(self) ShareUnits(userControls.entryData.name, playerID) end, },
	}
	Chili.Image:New {
		name = "imShare",
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		parent = userControls.btnShare,
		keepAspect = true,
		file = IMAGE_SHARE,
	}
	userControls.btnShare:SetVisibility((userControls.entryData.isMyAlly and (userControls.entryData.teamID ~= myTeamID) and true) or false)
	offset = offset + options.text_height.value + 1

	offset = offset + 1
	if userControls.entryData.cpuBucket then
		userControls.imCpu = Chili.Image:New {
			name = "imCpu",
			x = offset,
			y = offsetY,
			width = options.text_height.value + 3,
			height = options.text_height.value + 3,
			parent = userControls.mainControl,
			keepAspect = true,
			file = IMAGE_CPU,
			color = pingCpuColors[userControls.entryData.cpuBucket],
		}
		function userControls.imCpu:HitTest(x,y) return self end
	end
	offset = offset + options.text_height.value
	
	offset = offset + 1
	if userControls.entryData.pingBucket then
		userControls.imPing = Chili.Image:New {
			name = "imPing",
			x = offset,
			y = offsetY,
			width = options.text_height.value + 3,
			height = options.text_height.value + 3,
			parent = userControls.mainControl,
			keepAspect = true,
			file = IMAGE_PING,
			color = pingCpuColors[userControls.entryData.pingBucket],
		}
		function userControls.imPing:HitTest(x,y) return self end
	end
	offset = offset + options.text_height.value

	UpdateEntryData(userControls.entryData, userControls, false, true)

	return userControls
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local playerlistWindow
local listControls = {}
local playersByPlayerID = {}
local teamByTeamID = {}

local function Compare(ac, bc)
	local a, b = ac.entryData, bc.entryData
	
	if a.isMe ~= b.isMe then
		return b.isMe
	end
	
	if a.isMyTeam ~= b.isMyTeam then
		return b.isMyTeam
	end
	
	if a.isMyAlly ~= b.isMyAlly then
		return b.isMyAlly
	end
	
	if a.allyTeamID ~= b.allyTeamID then
		return a.allyTeamID > b.allyTeamID 
	end
	
	if a.isAiTeam ~= b.isAiTeam then
		return a.isAiTeam
	end
	
	if a.teamID ~= b.teamID then
		return a.teamID > b.teamID
	end
	
	if a.playerID and b.playerID and a.playerID ~= b.playerID then
		return a.playerID > b.playerID
	end
end

local function SortEntries()
	if not playerlistWindow then
		return
	end
	
	table.sort(listControls, Compare)
	
	local toTop = options.alignToTop.value
	local offset = 0
	for i = 1, #listControls do
		if toTop then
			listControls[i].mainControl._relativeBounds.top = offset
			listControls[i].mainControl._relativeBounds.bottom = nil
		else
			listControls[i].mainControl._relativeBounds.top = nil
			listControls[i].mainControl._relativeBounds.bottom = offset
		end
		listControls[i].mainControl:UpdateClientArea(false)
		
		offset = offset + options.text_height.value + 2
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function UpdateTeam(teamID)
	local controls = teamByTeamID[teamID]
	if not controls then
		return
	end
	
	local toSort = UpdateEntryData(controls.entryData, controls)
	if toSort then
		SortEntries()
	end
end

local function UpdatePlayer(playerID)
	local controls = playersByPlayerID[playerID]
	if not controls then
		return
	end
	
	local toSort = UpdateEntryData(controls.entryData, controls)
	if toSort then
		SortEntries()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function InitializePlayerlist()
	if playerlistWindow then
		playerlistWindow:Dispose()
		playerlistWindow = nil
	end
	
	if listControls then
		for i = 1, #listControls do
			listControls[i]:Dispose()
		end
		listControls = {}
		playersByPlayerID = {}
		teamByTeamID = {}
	end

	--// WINDOW
	playerlistWindow = Chili.Window:New{
		backgroundColor = {0, 0, 0, 0},
		color = {0, 0, 0, 0},
		parent = Chili.Screen0,
		dockable = true,
		name = "Player List",
		padding = {0, 0, 0, 0},
		-- right = "50%",
		x = 200,
		y = 200,
		width = WINDOW_WIDTH,
		minWidth = WINDOW_WIDTH,
		clientHeight = 600,
		minHeight = 100,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		minimizable = false,
	}
	
	local gaiaTeamID = Spring.GetGaiaTeamID
	local teamList = Spring.GetTeamList()
	for i = 1, #teamList do
		local teamID = teamList[i]
		if teamID ~= gaiaTeamID then
			local _, leaderID, isDead, isAiTeam, _, allyTeamID = Spring.GetTeamInfo(teamID, false)
			if leaderID < 0 then
				leaderID = Spring.GetTeamRulesParam(teamID, "initLeaderID") or leaderID
			end
			
			if leaderID >= 0 then
				if isAiTeam then
					leaderID = nil
				end
				
				local controls = GetUserControls(leaderID, teamID, allyTeamID, isAiTeam, isDead, playerlistWindow)
				
				listControls[#listControls + 1] = controls
				teamByTeamID[teamID] = controls
				if leaderID then
					playersByPlayerID[leaderID] = controls
				end
			end
		end
	end
	
	SortEntries()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/HUD Panels/Player List'
options_order = {'text_height', 'backgroundOpacity', 'alignToTop'}
options = {
	text_height = {
		name = 'Font Size (10-18)',
		type = 'number',
		value = 13,
		min = 10, max = 18, step = 1,
		OnChange = InitializePlayerlist,
		advanced = true
	},
	backgroundOpacity = {
		name = "Background opacity",
		type = "number",
		value = 0, min = 0, max = 1, step = 0.01,
		OnChange = function(self)
			playerlistWindow.backgroundColor = {1,1,1,self.value}
			playerlistWindow.borderColor = {1,1,1,self.value}
			playerlistWindow:Invalidate()
		end,
	},
	alignToTop = {
		name = "Align to top",
		type = 'bool',
		value = false,
		desc = "Align list entries to top (i.e. don't push to bottom)",
		OnChange = SortEntries,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local lastUpdate = 0
function widget:Update(dt)
	lastUpdate = lastUpdate + dt
	if lastUpdate < UPDATE_PERIOD then
		return
	end
	lastUpdate = 0
	
	for i = 1, #listControls do
		UpdateEntryData(listControls[i].entryData, listControls[i], true)
	end
end

function widget:PlayerChanged(playerID)
	if playerID == myPlayerID then
		local updateAll = false
		
		if mySpectating ~= Spring.GetSpectatingState() then
			updateAll = true
			mySpectating = Spring.GetSpectatingState()
		end
		if myAllyTeamID ~= (not mySpectating and Spring.GetMyAllyTeamID()) then
			updateAll = true
			myAllyTeamID = (not mySpectating and Spring.GetMyAllyTeamID())
		end
		if myTeamID ~= (not mySpectating and Spring.GetMyTeamID()) then
			updateAll = true
			myTeamID = (not mySpectating and Spring.GetMyTeamID())
		end
		
		if changedTeam then
			local toSort = false
			for i = 1, #listControls do
				toSort = UpdateEntryData(listControls[i].entryData, listControls[i], false, true) or toSort
			end
			
			if toSort then
				SortEntries()
			end
			return
		end
	end
	
	UpdatePlayer(playerID)
end

function widget:PlayerAdded(playerID)
	UpdatePlayer(playerID)
end

function widget:PlayerRemoved(playerID)
	UpdatePlayer(playerID)
end

function widget:TeamDied(teamID)
	UpdateTeam(teamID)
end

function widget:TeamChanged(teamID)
	UpdateTeam(teamID)
end

function widget:Initialize()
	Chili = WG.Chili

	if (not Chili) then
		widgetHandler:RemoveWidget()
		return
	end
	InitializePlayerlist()
end
