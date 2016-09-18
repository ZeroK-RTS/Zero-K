
if addon.InGetInfo then return {
	name    = "Proper Loadscreen",
	desc    = "Proper loadscreen",
	author  = "Sprung",
	date    = "2016",
	license = "PD",
	layer   = 0,
	enabled = true,
} end

-- there is no GetMy*ID, we need to make our own
local myPlayerID = 0
local myTeamID = 0
local myAllyTeamID = 0
local mySpecStatus = true
local myName = Spring.GetConfigString("name") or "" -- apparently this sometimes isn't the real name? To investigate.
local players = Spring.GetPlayerList()
for i = 1, #players do
	local name, _, spec, teamID, allyteamID = Spring.GetPlayerInfo(players[i])
	if (name == myName) then
		myPlayerID = players[i]
		myTeamID = teamID
		myAllyTeamID = allyteamID
		mySpecStatus = spec
		break
	end
end

local font = gl.LoadFont("FreeSansBold.otf", 50, 5, 2)
local textSize = font:GetTextWidth(Game.mapName)*0.06

local borderTex = "bitmaps/map_loading_border.png"

local vsx, vsz = gl.GetViewSizes()
local ratio = vsz / vsx

local maxX = 0.75 * ratio
local maxZ = 0.75

local startX = 0
local startZ = 0

--local mapRatio = Game.mapSizeX / Game.mapSizeZ
local mapRatio = 1 -- engine does not expose map size to LuaIntro for some reason. Very elongated maps are generally shitty anyway so not a huge problem

if mapRatio > 1 then
	mapRatio = 1 / mapRatio
	startZ = maxZ * ((1 - mapRatio) / 2)
	maxZ = maxZ * mapRatio
else
	startX = maxX * ((1 - mapRatio) / 2)
	maxX = maxX * mapRatio
end

startZ = startZ + 0.125

maxX = maxX+startX
maxZ = maxZ+startZ

-- apply teamcolors manually
local colorCFG
if VFS.FileExists("LuaUI/Configs/LocalColors.lua") then
	colorCFG = VFS.Include("LuaUI/Configs/LocalColors.lua")
	Spring.Echo("Loaded local team color config.")
elseif VFS.FileExists("LuaUI/Configs/ZKTeamColors.lua") then
	colorCFG = VFS.Include("LuaUI/Configs/ZKTeamColors.lua")
else
	error("missing file: LuaUI/Configs/LocalColors.lua")
end
local teamlist = Spring.GetTeamList()
local colors = {}
local a, e = 0, 0
for i = 1, #teamlist do
	local allyID = select(6, Spring.GetTeamInfo(teamlist[i]))
	if (allyID == myAllyTeamID) then
		a = (a % #colorCFG.allyColors) + 1
		colors[teamlist[i]] = colorCFG.allyColors[a]
	elseif (teamlist[i] ~= Spring.GetGaiaTeamID()) then
		e = (e % #colorCFG.enemyColors) + 1
		colors[teamlist[i]] = colorCFG.enemyColors[e]
	end
end
if not mySpecStatus then
	colors[myTeamID] = colorCFG.myColor
end

local allyteams = Spring.GetAllyTeamList()
local actualAllyteams = {}
for i = 1, #allyteams do
	if (allyteams[i] ~= select(6, Spring.GetTeamInfo(Spring.GetGaiaTeamID()))) and (#Spring.GetTeamList(allyteams[i]) > 0) then
		actualAllyteams[#actualAllyteams+1] = allyteams[i]
	end
end

local labels = {}
if #actualAllyteams == 2 then
	sizeX = maxX - startX
	startX = 0.5 - sizeX/2
	maxX = 0.5 + sizeX/2

	local team = Spring.GetTeamList(actualAllyteams[1])
	for i = 1, #team do
		local teamID = team[i]
		local _, playerID, _, isAI = Spring.GetTeamInfo(teamID)
		local name
		if isAI then
			name = select(2, Spring.GetAIInfo(teamID))
		else
			name = Spring.GetPlayerInfo(playerID)
		end
		r,g,b = unpack(colors[teamID])
		labels[#labels+1] = {
			name = name,
			r = r, g = g, b = b,
			x = startX/2,
			y = (maxZ * vsz) - 100 - (25 * i)
		}
	end

	team = Spring.GetTeamList(actualAllyteams[2])
	for i = 1, #team do
		local teamID = team[i]
		local _, playerID, _, isAI = Spring.GetTeamInfo(teamID)
		local name
		if isAI then
			name = select(2, Spring.GetAIInfo(teamID))
		else
			name = Spring.GetPlayerInfo(playerID)
		end
		r,g,b = unpack(colors[teamID])
		labels[#labels+1] = {
			name = name,
			r = r, g = g, b = b,
			x = maxX + (1-maxX)/2,
			y = (maxZ * vsz) - 100 - (25 * i)
		}
	end
else
	local currentX
	local isCrowded = (#actualAllyteams > 5 or (#actualAllyteams > 2 and #Spring.GetTeamList() > 11))
	if isCrowded then
		currentX = maxX + (1-maxX)/4
	else
		currentX = maxX + (1-maxX)/2
	end
	local secondRow = false
	local currentY = 0
	for j = 1, #actualAllyteams do
		if (isCrowded and not secondRow and j > #actualAllyteams/2) then
			secondRow = true
			currentX = currentX + (1-maxX)/2
			currentY = 0
		elseif (#labels > 0) then
			labels[#labels+1] = { -- spacer
				name = "",
				r = 1, g = 1, b = 1,
				x = currentX,
				y = currentY,
			}
			currentY = currentY + 1
		end
		local team = Spring.GetTeamList(actualAllyteams[j])
		for i = 1, #team do
			local teamID = team[i]
			local _, playerID, _, isAI = Spring.GetTeamInfo(teamID)
			local name
			if isAI then
				name = select(2, Spring.GetAIInfo(teamID))
			else
				name = Spring.GetPlayerInfo(playerID)
			end
			r,g,b = unpack(colors[teamID])
			labels[#labels+1] = {
				name = name,
				r = r, g = g, b = b,
				x = currentX, -- maxX + (1-maxX)/2,
				y = (maxZ * vsz) - 100 - (25 * currentY)
			}
			currentY = currentY + 1
		end
	end
end

function addon.DrawLoadScreen()
	gl.Color(1,1,1,1)
	gl.Texture(0, "$minimap")
	gl.TexRect(startX,startZ,maxX,maxZ)
	gl.Texture(0, borderTex)
	gl.TexRect(startX,startZ,maxX,maxZ)
	gl.Texture(false)

	gl.PushMatrix()
		gl.Scale(1/vsx, 1/vsz, 1)
		font:Print(Game.mapName, vsx/2, vsz-50, 50, "oc")

		for i = 1, #labels do
			local label = labels[i]
			font:Print("\255"..string.char(label.r)..string.char(label.g)..string.char(label.b) .. label.name, label.x * vsx, label.y, 20, "oc")
		end
	gl.PopMatrix()
	gl.Color(1,1,1,1)
end

function addon.Shutdown()
	gl.DeleteTexture(borderTex)
end