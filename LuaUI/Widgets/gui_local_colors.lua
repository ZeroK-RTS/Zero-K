function widget:GetInfo()
	return {
		name = "Local Team Colors",
		desc = "Makes neat team color scheme - you teal, allies blueish, enemies reddish",
		author = "Licho",
		date = "February, 2010",
		license = "GPL v3",
		layer = -10000,
		enabled = true,
	}
end



if VFS.FileExists("Luaui/Configs/ZKTeamColors.lua") then
	colorCFG = VFS.Include("Luaui/Configs/ZKTeamColors.lua")
elseif VFS.FileExists("Luaui/Configs/LocalColors.lua") then -- allow for user over ride
	colorCFG = VFS.Include("Luaui/Configs/LocalColors.lua")
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
end


local function ResetOldTeamColors()
	for _,team in ipairs(Spring.GetTeamList()) do
		Spring.SetTeamColor(team,Spring.GetTeamOrigColor(team))
	end
end


function widget:Initialize()
	SetNewTeamColors()
end

function widget:Shutdown()
	ResetOldTeamColors()
end

