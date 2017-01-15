function widget:GetInfo()
	return {
		name = "Local Team Colors",
		desc = "Makes neat team color scheme - you teal, allies blueish, enemies reddish",
		author = "Licho",
		date = "February, 2010",
		license = "GNU GPL v2, or later",
		layer = -10001,
		enabled = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/Interface/Local Team Colors'
options = {
	simpleColors = {
		name = "Simple Colors",
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'All allies are green, all enemies are red.',
		OnChange = function() widget:Initialize() end
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if VFS.FileExists("LuaUI/Configs/LocalColors.lua") then -- user override
	colorCFG = VFS.Include("LuaUI/Configs/LocalColors.lua")
	Spring.Echo("Loaded local team color config.")
elseif VFS.FileExists("LuaUI/Configs/ZKTeamColors.lua") then
	colorCFG = VFS.Include("LuaUI/Configs/ZKTeamColors.lua")
else
	error("missing file: LuaUI/Configs/LocalColors.lua")
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
	if not is_speccing then
		Spring.SetTeamColor(myTeam, unpack(myColor))	-- overrides previously defined color
	end
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
	if not is_speccing then
		Spring.SetTeamColor(myTeam, unpack(myColor))	-- overrides previously defined color
	end
end

local function ResetOldTeamColors()
	for _,team in ipairs(Spring.GetTeamList()) do
		Spring.SetTeamColor(team,Spring.GetTeamOrigColor(team))
	end
end

local function NotifyColorChange()
	for name,func in pairs(WG.LocalColor.listeners) do
		if type(func) == "function" then	-- because we don't trust other widget writers to not give us random junk
			func()				-- yeah we wouldn't even need to do this with static typing :(
		else
			Spring.Echo("<Local Team Colors> ERROR: Listener '" .. name .. "' is not a function!" )
		end
	end
end

function WG.LocalColor.localTeamColorToggle()
	options.simpleColors.value = not options.simpleColors.value
	widget:Initialize()
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
	if options.simpleColors.value then
		SetNewSimpleTeamColors()
	else
		SetNewTeamColors()
	end
	
	if not doNotNotify then
		NotifyColorChange()
	end
end

function widget:Initialize()
	UpdateColor()
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
	ResetOldTeamColors()
	NotifyColorChange()
	WG.LocalColor.localTeamColorToggle = nil
end

