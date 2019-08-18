function widget:GetInfo()
	return {
		name      = "Chili AI Set Start",
		desc      = "UI for setting AI start position.",
		author    = "GoogleFrog",
		date      = "1 July 2017",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		handler   = true,
		enabled   = true,
	}
end

VFS.Include("LuaRules/Configs/customcmds.h.lua")

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local BUTTON_HEIGHT = 48

local setAiPosCommand = {
	id      = CMD_SET_AI_START,
	type    = CMDTYPE.ICON_MAP,
	tooltip = 'Set AI start position.',
	cursor  = 'Attack',
	action  = 'setaistart',
	params  = {},
	texture = 'LuaUI/Images/commands/Bold/attack.png',
	pos = {124},
}

-- Chili
local Chili
local screen0

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Variables

local activePlacementTeamID
local aiPositionWindow

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function SelectAiPlacement(teamID)
	activePlacementTeamID = teamID
	local index = Spring.GetCmdDescIndex(CMD_SET_AI_START)
	Spring.SetActiveCommand(index, 1)
end

local function AddAiButton(parent, offset, teamData)
	local tooltip = "Set start position for AI " .. teamData.teamID ..
		".\nName: " .. teamData.name ..
		"\nOwner: " .. teamData.playerName ..
		"\nAlly: " .. teamData.allyTeamID
	
	local newButton = Chili.Button:New{
		caption = "",
		x = 0,
		y = offset,
		right = 0,
		height = BUTTON_HEIGHT,
		padding = {0, 0, 0, 0},
		OnClick = {
			function(self)
				SelectAiPlacement(teamData.teamID)
			end
		},
		tooltip = tooltip,
		parent = parent,
	}
	
	local r, g, b = Spring.GetTeamColor(teamData.teamID)
	
	local textBox = Chili.TextBox:New{
		x      = 10,
		y      = 12,
		right  = 10,
		bottom = 10,
		valign = "left",
		text   = teamData.name .. "\nAI: " .. teamData.teamID .. ", Ally: " .. teamData.allyTeamID,
		font   = {size = 14, outline = true, color = {r, g, b}, outlineWidth = 2, outlineWeight = 2},
		parent = newButton,
	}
end

local function InitializeControls(aiTeams)
	local mainWindow = Chili.Window:New{
		classname = "main_window_small_tall",
		name      = 'AiStartPosWindow',
		x         = 50,
		y         = 150,
		width     = 250,
		height    = 250,
		minWidth  = 250,
		minHeight = 150,
		dockable  = true,
		dockableSavePositionOnly = true,
		draggable = true,
		resizable = true,
		tweakDraggable = true,
		tweakResizable = true,
		parent = screen0,
	}
	
	local topLabel = Chili.Label:New{
		x      = 0,
		right  = 0,
		y      = 0,
		height = 35,
		valign = "center",
		align  = "center",
		caption = "Set AI Start Positions",
		autosize = false,
		font   = {size = 20, outline = true, color = {.8,.8,.8,.9}, outlineWidth = 2, outlineWeight = 2},
		parent = mainWindow,
	}
	
	local scrollPanel = Chili.ScrollPanel:New{
  		x = 8,
		y = 36,
		bottom = 8,
		right = 8,
		horizontalScrollbar = false,
		parent = mainWindow
	}
	
	local offset = 0
	for i = 1, #aiTeams do
		AddAiButton(scrollPanel, offset, aiTeams[i])
		offset = offset + BUTTON_HEIGHT + 3
	end
	
	return mainWindow
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Command Handling

function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_SET_AI_START and activePlacementTeamID then
		local x, y, z = cmdParams[1], cmdParams[2], cmdParams[3]
		Spring.SendLuaRulesMsg('ai_start_pos:' .. activePlacementTeamID.. ':' .. x .. ':' .. z)
		return true
	end
end

function widget:CommandsChanged()
	local customCommands = widgetHandler.customCommands
	table.insert(customCommands, setAiPosCommand)
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Initialization and removal

function widget:GameFrame()
	if aiPositionWindow then
		aiPositionWindow:Dispose()
	end
	widgetHandler:RemoveWidget(widget)
end

local function SpawnDisabled()
	local setSpawns = Spring.GetModOptions().setaispawns
	return (not setSpawns) or (setSpawns == 0) or (setSpawns == "0")
end

function widget:Initialize()
	if SpawnDisabled() or (Spring.GetGameFrame() > 0) then
		widgetHandler:RemoveWidget(widget)
		return
	end
	
	Chili = WG.Chili
	screen0 = Chili.Screen0
	
	local aiTeams = {}
	local teamList = Spring.GetTeamList()
	for i = 1, #teamList do
		local teamID = teamList[i]
		local _,_,_,isAI,_,allyTeamID = Spring.GetTeamInfo(teamID, false)
		if isAI then
			local skirmishAIID, name, hostingPlayerID, shortName, version, options = Spring.GetAIInfo(teamID)
			local playerName = Spring.GetPlayerInfo(hostingPlayerID, false)
			aiTeams[#aiTeams + 1] = {
				teamID = teamID,
				allyTeamID = allyTeamID,
				name = name or "unknown",
				playerName = playerName or "unknown",
			}
		end
	end
	
	if #aiTeams > 0 then
		aiPositionWindow = InitializeControls(aiTeams)
	else
		widgetHandler:RemoveWidget(widget)
	end
end
