function widget:GetInfo()
	return {
		name = "Local Team Colors",
		desc = "Makes neat team color scheme - you teal, allies blueish, enemies reddish",
		author = "Licho",
		date = "February, 2010",
		license = "GPL v3",
		layer = -10001,
		enabled = true,
	}
end

options_path = 'Settings/Interface/Local Team Colors'
options = {
	simpleColors = {
		name = "Simple Colors",
		type = 'bool',
		value = false,
		desc = 'All allies are green, all enemies are red.',
		OnChange = function() widget:Initialize() end
	},
}

if VFS.FileExists("Luaui/Configs/LocalColors.lua") then -- user override
	colorCFG = VFS.Include("Luaui/Configs/LocalColors.lua")
	Spring.Echo("Loaded local team color config.")
elseif VFS.FileExists("Luaui/Configs/ZKTeamColors.lua") then
	colorCFG = VFS.Include("Luaui/Configs/ZKTeamColors.lua")
else
	error("missing file: Luaui/Configs/LocalColors.lua")
end

colorCFG.gaiaColor[1] = colorCFG.gaiaColor[1]/255 
colorCFG.gaiaColor[2] = colorCFG.gaiaColor[2]/255
colorCFG.gaiaColor[3] = colorCFG.gaiaColor[3]/255

colorCFG.myColor[1] = colorCFG.myColor[1]/255 
colorCFG.myColor[2] = colorCFG.myColor[2]/255
colorCFG.myColor[3] = colorCFG.myColor[3]/255

for set, contents in pairs(colorCFG.allyColors) do
	colorCFG.allyColors[set][1] = colorCFG.allyColors[set][1]/255 
	colorCFG.allyColors[set][2] = colorCFG.allyColors[set][2]/255
	colorCFG.allyColors[set][3] = colorCFG.allyColors[set][3]/255
end

for set, contents in pairs(colorCFG.enemyColors) do
	colorCFG.enemyColors[set][1] = colorCFG.enemyColors[set][1]/255 
	colorCFG.enemyColors[set][2] = colorCFG.enemyColors[set][2]/255
	colorCFG.enemyColors[set][3] = colorCFG.enemyColors[set][3]/255
end

local myColor = colorCFG.myColor
local gaiaColor = colorCFG.gaiaColor
local allyColors = colorCFG.allyColors
local enemyColors = colorCFG.enemyColors

WG.LocalColor = {}

local function RecreatePlayerList()
	if WG.PlayerList.RecreateList then
		WG.PlayerList.RecreateList()
	end
end

local function SetNewTeamColors() 
	local gaia = Spring.GetGaiaTeamID()
	Spring.SetTeamColor(gaia, unpack(gaiaColor))
	
	local myAlly = Spring.GetMyAllyTeamID()
	local myTeam = Spring.GetMyTeamID()

	local a, e = 0, 0
	for _, teamID in ipairs(Spring.GetTeamList()) do
		local _,_,_,_,_,allyID = Spring.GetTeamInfo(teamID)
		if (allyID == myAlly) then
			a = (a % #allyColors) + 1
			Spring.SetTeamColor(teamID, unpack(allyColors[a]))
		elseif (teamID ~= gaia) then
			e = (e % #enemyColors) + 1
			Spring.SetTeamColor(teamID, unpack(enemyColors[e]))
		end
	end
	Spring.SetTeamColor(myTeam, unpack(myColor))	-- overrides previously defined color
	
	RecreatePlayerList()
end

local function SetNewSimpleTeamColors() 
	local gaia = Spring.GetGaiaTeamID()
	Spring.SetTeamColor(gaia, unpack(gaiaColor))
	
	local myAlly = Spring.GetMyAllyTeamID()
	local myTeam = Spring.GetMyTeamID()

	for _, teamID in ipairs(Spring.GetTeamList()) do
		local _,_,_,_,_,allyID = Spring.GetTeamInfo(teamID)
		if (allyID == myAlly) then
			Spring.SetTeamColor(teamID, unpack(allyColors[1]))
		elseif (teamID ~= gaia) then
			Spring.SetTeamColor(teamID, unpack(enemyColors[1]))
		end
	end
	Spring.SetTeamColor(myTeam, unpack(myColor))	-- overrides previously defined color
	
	RecreatePlayerList()
end


local function ResetOldTeamColors()
	for _,team in ipairs(Spring.GetTeamList()) do
		Spring.SetTeamColor(team,Spring.GetTeamOrigColor(team))
	end
	
	RecreatePlayerList()
end

function WG.LocalColor.localTeamColorToggle()
	options.simpleColors.value = not options.simpleColors.value
	widget:Initialize()
end

function widget:Initialize()
	if options.simpleColors.value then
		SetNewSimpleTeamColors()
	else
		SetNewTeamColors()
	end
end

function widget:Shutdown()
	ResetOldTeamColors()
end

