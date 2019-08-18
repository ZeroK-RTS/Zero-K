function widget:GetInfo()
	return {
		name = "Local Team Colors",
		desc = "Makes neat team color scheme - you teal, allies blueish, enemies reddish",
		author = "Licho, GoogleFrog",
		date = "February, 2010",
		license = "GNU GPL v2, or later",
		layer = -10001,
		enabled = true,
	}
end

local selfName = "Local Team Colors"
local DEBUG_MODE = false

local campaignBattleID = Spring.GetModOptions().singleplayercampaignbattleid

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetColorConfig()
	if VFS.FileExists("LuaUI/Configs/LocalColors.lua") then -- user override
		Spring.Echo("Loaded local team color config.")
		return VFS.Include("LuaUI/Configs/LocalColors.lua")
	elseif VFS.FileExists("LuaUI/Configs/ZKTeamColors.lua") then
		return VFS.Include("LuaUI/Configs/ZKTeamColors.lua")
	else
		error("missing file: LuaUI/Configs/LocalColors.lua")
	end
	return {}
end

local function FixRanges(colors)
	if colors.myColor[1] <= 1 and colors.myColor[2] <= 1 and colors.myColor[3] < 1 and
			colors.gaiaColor[1] <= 1 and colors.gaiaColor[2] <= 1 and colors.gaiaColor[3] < 1 then
		return colors
	end
	colors.gaiaColor[1] = colors.gaiaColor[1]/255
	colors.gaiaColor[2] = colors.gaiaColor[2]/255
	colors.gaiaColor[3] = colors.gaiaColor[3]/255

	colors.myColor[1] = colors.myColor[1]/255
	colors.myColor[2] = colors.myColor[2]/255
	colors.myColor[3] = colors.myColor[3]/255

	for set, contents in pairs(colors.allyColors) do
		colors.allyColors[set][1] = colors.allyColors[set][1]/255
		colors.allyColors[set][2] = colors.allyColors[set][2]/255
		colors.allyColors[set][3] = colors.allyColors[set][3]/255
	end

	for set, contents in pairs(colors.enemyColors) do
		colors.enemyColors[set][1] = colors.enemyColors[set][1]/255
		colors.enemyColors[set][2] = colors.enemyColors[set][2]/255
		colors.enemyColors[set][3] = colors.enemyColors[set][3]/255
	end
	
	return colors
end

local colorConfig = VFS.Include("LuaUI/Configs/TeamColorConfig.lua")
local colorSettingsItems = {}
for key, value in pairs(colorConfig) do
	colorSettingsItems[value.order] = {
		key = key,
		name = value.name,
		desc = value.desc
	}
end

if VFS.FileExists("LuaUI/Configs/LocalColors.lua") then
	colorConfig.custom = {
		name = "Custom",
		desc = "Custom colour configration, as defined in LuaUI/Configs/LocalColors.lua.",
		colors = FixRanges(VFS.Include("LuaUI/Configs/LocalColors.lua"))
	}
	colorSettingsItems[#colorSettingsItems + 1] = {
		key = "custom",
		name = colorConfig.custom.name,
		desc = colorConfig.custom.desc
	}
end

local myColor, gaiaColor, allyColors, enemyColors, enemyByTeamColors, colorEnemiesByAllyTeam

local function UpdateColorConfig(self)
	if not colorConfig[self.value] then
		return
	end
	
	myColor = colorConfig[self.value].colors.myColor
	gaiaColor = colorConfig[self.value].colors.gaiaColor
	allyColors = colorConfig[self.value].colors.allyColors
	enemyColors = colorConfig[self.value].colors.enemyColors
	enemyByTeamColors = colorConfig[self.value].colors.enemyByTeamColors or enemyColors
	
	UpdateColor()
end

local function UpdateSimpleEnemyColor(self)
	if self.value == "auto" or self.value == "autoffa" then
		if campaignBattleID then
			colorEnemiesByAllyTeam = true
		elseif self.value == "autoffa" then
			local teamList = Spring.GetTeamList()
			local allyTeamSeen = {}
			local allyTeamCount = 0
			for i = 1, #teamList do
				local allyTeam = select(6, Spring.GetTeamInfo(teamList[i], false))
				if not allyTeamSeen[allyTeam] then
					allyTeamCount = allyTeamCount + 1
					allyTeamSeen[allyTeam] = true
				end
			end
			colorEnemiesByAllyTeam = (allyTeamCount > 3)
		else
			colorEnemiesByAllyTeam = false
		end
	else
		colorEnemiesByAllyTeam = (self.value == "enable")
	end
end

local function UpdateColorNotify()
	Spring.Echo("UpdateColorNotify")
	UpdateColor()
end

options_path = 'Settings/Interface/Team Colors'
options = {
	colorSetting = {
		name = 'Team Color Mode',
		type = 'radioButton',
		value = 'default',
		items = colorSettingsItems,
		OnChange = UpdateColorConfig
	},
	matchColors = {
		name = 'Sync Colors With Team',
		type = 'bool',
		value = false,
		OnChange = UpdateColorNotify
	},
	simpleEnemyAllyTeam = {
		name = 'Colour Enemies By Team',
		type = 'radioButton',
		value = 'auto',
		items = {
			{name = 'Always', key = 'enable', desc = "Always colour enemies by team."},
			{name = 'Missions and FFA', key = 'autoffa', desc = "Colour enemies by team in missions and FFA."},
			{name = 'Missions', key = 'auto', desc = "Colour enemies by team in missions."},
			{name = 'Never', key = 'disable', desc = "Never colour enemies by team."},
		},
		OnChange = function(self)
			UpdateSimpleEnemyColor(self)
			UpdateColor()
		end,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

WG.LocalColor = (type(WG.LocalColor) == "table" and WG.LocalColor) or {}
WG.LocalColor.listeners = WG.LocalColor.listeners or {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local is_speccing

local function SetNewTeamColors()
	local gaia = Spring.GetGaiaTeamID()
	Spring.SetTeamColor(gaia, unpack(gaiaColor))
	
	local myAlly = Spring.GetMyAllyTeamID()
	local myTeam = Spring.GetMyTeamID()
	
	local enemyColorMap = colorEnemiesByAllyTeam and {}
	
	local a, e = 0, 0
	for _, teamID in ipairs(Spring.GetTeamList()) do
		local _,_,_,_,_,allyID = Spring.GetTeamInfo(teamID, false)
		if (allyID == myAlly) then
			if is_speccing or options.matchColors.value or (myTeam ~= teamID) then
				a = (a % #allyColors) + 1
				Spring.SetTeamColor(teamID, unpack(allyColors[a]))
			end
		elseif (teamID ~= gaia) then
			if colorEnemiesByAllyTeam then
				if not enemyColorMap[allyID] then
					e = (e % #enemyByTeamColors) + 1
					enemyColorMap[allyID] = enemyByTeamColors[e]
				end
				Spring.SetTeamColor(teamID, unpack(enemyColorMap[allyID]))
			else
				e = (e % #enemyColors) + 1
				Spring.SetTeamColor(teamID, unpack(enemyColors[e]))
			end
		end
	end
	if not is_speccing then
		Spring.SetTeamColor(myTeam, unpack(myColor)) -- overrides previously defined color
	end
end

local function ResetOldTeamColors()
	for _,team in ipairs(Spring.GetTeamList()) do
		Spring.SetTeamColor(team,Spring.GetTeamOrigColor(team))
	end
end

local function NotifyColorChange()
	for name,func in pairs(WG.LocalColor.listeners) do
		if type(func) == "function" then -- because we don't trust other widget writers to not give us random junk
			func() -- yeah we wouldn't even need to do this with static typing :(
		else
			Spring.Echo("<Local Team Colors> ERROR: Listener '" .. name .. "' is not a function!" )
		end
	end
end

function WG.LocalColor.localTeamColorToggle()
	if options.colorSetting.value == "simple" then
		WG.SetWidgetOption(selfName, options_path, "colorSetting", "default")
	else
		WG.SetWidgetOption(selfName, options_path, "colorSetting", "simple")
	end
	UpdateColor()
end

function WG.LocalColor.RegisterListener(name, func)
	WG.LocalColor.listeners[name] = func
end

function WG.LocalColor.UnregisterListener(name)
	WG.LocalColor.listeners[name] = nil
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function UpdateColor(doNotNotify)
	is_speccing = Spring.GetSpectatingState()
	SetNewTeamColors()
	
	if not doNotNotify then
		NotifyColorChange()
	end
end

function widget:Initialize()
	UpdateSimpleEnemyColor(options.simpleEnemyAllyTeam)
	UpdateColorConfig(options.colorSetting)
end

local oldTeamID = Spring.GetMyTeamID()
-- This function is alright but other, poorly written widgets cause a massive spike when team colours change.
function widget:PlayerChanged()
	if Spring.GetSpectatingState() then
		return
	end
	
	local newTeamID = Spring.GetMyTeamID()
	if oldTeamID == newTeamID then
		return
	end
	oldTeamID = newTeamID
	
	UpdateColor(true)
end

function widget:Shutdown()
	-- don't restore the original colours, they're useless. This only really matters for /luaui disable
	WG.LocalColor.localTeamColorToggle = nil
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local width = 128
local height = 48

local friendlyColors

local function LoadFriendlyColors()
	friendlyColors = {myColor}
	for i=1,#allyColors do
		friendlyColors[#friendlyColors + 1] = allyColors[i]
	end
end

local function DrawRectangle(x, y)
	gl.Vertex(x, y, 0)
	gl.Vertex(x + width, y, 0)
	gl.Vertex(x + width, y + height, 0)
	gl.Vertex(x, y + height, 0)
end

function widget:DrawScreen()
	if not DEBUG_MODE then
		return
	end
	if friendlyColors == nil then
		LoadFriendlyColors()
	end
	
	local vsx, vsy = Spring.GetViewGeometry()
	local x = vsx/2 - width
	local y = vsy - 160
	
	for i = 1, #friendlyColors do
		gl.Color(friendlyColors[i])
		gl.BeginEnd(GL.QUADS, DrawRectangle, x, y)
		gl.Color(1,1,1,1)
		gl.BeginEnd(GL.LINE_LOOP, DrawRectangle, x, y)
		y = y - height
	end
	
	y = vsy - 160
	x = x + width
	for i = 1, #enemyColors do
		gl.Color(enemyColors[i])
		gl.BeginEnd(GL.QUADS, DrawRectangle, x, y)
		gl.Color(1,1,1,1)
		gl.BeginEnd(GL.LINE_LOOP, DrawRectangle, x, y)
		y = y - height
	end
end
