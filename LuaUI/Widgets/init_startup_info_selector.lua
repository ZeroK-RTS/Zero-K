local versionNumber = "1.21"
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GetInfo()
	return {
	name	= "Startup Info and Selector",
	desc	= "[v" .. string.format("%s", versionNumber ) .. "] Shows important information and options on startup.",
	author	= "SirMaverick",
	date	= "2009,2010",
	license	= "GNU GPL, v2 or later",
	layer	= 0,
	enabled	= true
	}
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--[[
-- Features:
_ Show a windows at game start with pictures to choose commander type.
]]--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spGetGameRulesParam = Spring.GetGameRulesParam
-- FIXME use tobool instead of this string comparison silliness
local coop = (Spring.GetModOptions().coop == "1") or false
local forcejunior = (Spring.GetModOptions().forcejunior == "1") or false
local dotaMode = Spring.GetModOptions().zkmode == "dota"
local ctfMode = Spring.GetModOptions().zkmode == "ctf"

local Chili
local Window
local ScrollPanel
local Grid
local Label
local screen0
local Image
local Button

local vsx, vsy
local modoptions = Spring.GetModOptions() --used in LuaUI\Configs\startup_info_selector.lua for planetwars
local selectorShown = false
local mainWindow
local scroll
local grid
local trainerCheckbox
local buttons = {}
local buttonLabels = {}
local trainerLabels = {}
local actionShow = "showstartupinfoselector"
local optionData = include("Configs/startup_info_selector.lua")

local noComm = false
local gameframe = Spring.GetGameFrame()

local WINDOW_WIDTH = 720
local WINDOW_HEIGHT = 480
local BUTTON_WIDTH = 128
local BUTTON_HEIGHT = 128

local wantLabelUpdate = false
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- wait for next screenframe so Grid can resize its elements first	-- doesn't actually work
local function UpdateLabelPositions()
	for index, label in pairs(buttonLabels) do
		label.x = (buttons[index].width - label.width)*0.3
		label.align = "center"
		label:UpdateLayout()
		label:Invalidate()
	end
	for index, label in pairs(trainerLabels) do
		label.x = (buttons[index].width - label.width)*0.5
		label.align = "center"
		label:UpdateLayout()
		label:Invalidate()
	end	
end

local function ToggleTrainerButtons(bool)
	for i=1,#buttons do
		if buttons[i].trainer then
			if bool then
				grid:AddChild(buttons[i])
			else
				grid:RemoveChild(buttons[i])
			end
		end
	end
	wantLabelUpdate = true
end

options_path = 'Settings/HUD Panels/Commander Selector'
options = {
	hideTrainers = {
		name = 'Hide Trainer Commanders',
		--desc = '',
		type = 'bool',
		value = false,
		OnChange = function(self)
			--if trainerCheckbox then
			--	trainerCheckbox:Toggle()
			--end
			ToggleTrainerButtons(not self.value)
		end
	},
}
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local function PlaySound(filename, ...)
	local path = filename..".WAV"
	if (VFS.FileExists(path)) then
		Spring.PlaySoundFile(path, ...)
	else
	--Spring.Echo(filename)
		Spring.Echo("<Startup Info Selector>: Error - file "..path.." doesn't exist.")
	end
end

function widget:ViewResize(viewSizeX, viewSizeY)
  vsx = viewSizeX
  vsy = viewSizeY
end


function Close(commPicked)
	if not commPicked then
		--Spring.Echo("Requesting baseline comm")
		--Spring.SendLuaRulesMsg("faction:commbasic")
	end
	--Spring_SendCommands("say: a:I chose " .. option.button})
	if mainWindow then mainWindow:Dispose() end
end

local function CreateWindow()
	if mainWindow then
		mainWindow:Dispose()
	end
	
	local numColumns = math.floor(WINDOW_WIDTH/BUTTON_WIDTH)
	local numRows = math.ceil(#optionData/numColumns)

	mainWindow = Window:New{
		resizable = false,
		draggable = false,
		clientWidth  = WINDOW_WIDTH,
		clientHeight = WINDOW_HEIGHT,
		x = (vsx - WINDOW_WIDTH)/2,
		y = ((vsy - WINDOW_HEIGHT)/2),
		parent = screen0,
		caption = "COMMANDER SELECTOR",
		}
	--scroll = ScrollPanel:New{
	--	parent = mainWindow,
	--	horizontalScrollbar = false,
	--	bottom = 36,
	--	x = 2,
	--	y = 12,
	--	right = 2,
	--}
	grid = Grid:New{
		parent = mainWindow,
		autosize = true,
		resizeItems = true,
		x=0, right=0,
		y=0, bottom=36,
		centerItems = false,
	}
	-- add posters
	local i = 0
	for index,option in ipairs(optionData) do
		i = i + 1
		local button = Button:New {
			parent = grid,
			caption = "",	--option.name,	--option.trainer and "TRAINER" or "",
			valign = "bottom",
			tooltip = option.tooltip, --added comm name under cursor on tooltip too, like for posters
			width = BUTTON_WIDTH,
			height = BUTTON_HEIGHT,
			padding = {5,5,5,5},
			OnClick = {function()
				local prefix = option.trainer and "faction:" or "customcomm:"
				Spring.SendLuaRulesMsg(prefix..option.name)
				Spring.SendCommands({'say a:I choose: '..option.name..'!'})
				Close(true)
			end},
			trainer = option.trainer,
		}
		buttons[i] = button
		
		local image = Image:New{
			parent = button,
			file = option.image,--lookup Configs/startup_info_selector.lua to get optiondata
			tooltip = option.tooltip,
			x = 2,
			y = 2,
			right = 2,
			bottom = 12,
		}
		local label = Label:New{
			parent = button,
			x = 64,
			bottom = 4,
			caption = option.name,
			align = "center",
			font = {size = 14},
		}
		buttonLabels[i] = label
		if option.trainer then
			local trainerLabel = Label:New{
				parent = image,
				x = 42,
				y = BUTTON_HEIGHT * 0.45,
				caption = "TRAINER",
				align = "center",
				font = {color = {1,0.2,0.2,1}, size=16, outline=true, outlineColor={1,1,1,0.8}},
			}
			trainerLabels[i] = trainerLabel
		end
	end
	local cbWidth = WINDOW_WIDTH*0.75
	local closeButton = Button:New{
		parent = mainWindow,
		caption = "CLOSE",
		width = cbWidth,
		x = (WINDOW_WIDTH - cbWidth)/2,
		height = 30,
		bottom = 2,
		OnClick = {function() Close(false) end}
	}
	--[[	-- FIXME: EPIC doesn't remember the setting if you change it with this checkbox
	trainerCheckbox = Chili.Checkbox:New{
		parent = mainWindow,
		x = 4,
		bottom = 2,
		width = 160,
		caption = "Hide Trainer Comms",
		checked = options.hideTrainers.value,
		OnChange = { function(self)
			options.hideTrainers.value = self.checked
			ToggleTrainerButtons(self.checked)
		end },
	}
	]]
	wantLabelUpdate = true
	grid:Invalidate()
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:Initialize()
	if not (WG.Chili) then
		widgetHandler:RemoveWidget()
	end
	 if (Spring.GetSpectatingState() or Spring.IsReplay() or forcejunior) and (not Spring.IsCheatingEnabled()) then
		Spring.Echo("<Startup Info and Selector> Spectator mode, Junior forced, or replay. Widget removed.")
		widgetHandler:RemoveWidget()
		return
	end
	-- chili setup
	Chili = WG.Chili
	Window = Chili.Window
	ScrollPanel = Chili.ScrollPanel
	Grid = Chili.Grid
	Label = Chili.Label
	screen0 = Chili.Screen0
	Image = Chili.Image
	Button = Chili.Button
	
	-- FIXME: because this code runs before gadget:GameLoad(), the selector window pops up
	-- even if comm is already selected
	-- nothing serious, just annoying
	local playerID = Spring.GetMyPlayerID()
	local teamID = Spring.GetMyTeamID()
	if (coop and playerID and Spring.GetGameRulesParam("commSpawnedPlayer"..playerID) == 1)
	or (not coop and Spring.GetTeamRulesParam(teamID, "commSpawned") == 1)	then 
		noComm = true	-- will prevent window from auto-appearing; can still be brought up from the button
	end
	PlaySound("LuaUI/Sounds/Voices/initialized_core_1", 1, 'ui')


	vsx, vsy = widgetHandler:GetViewSizes()

	widgetHandler:AddAction(actionShow, CreateWindow, nil, "t")
	if (not noComm) or dotaMode then
		buttonWindow = Window:New{
			resizable = false,
			draggable = false,
			width = 64,
			height = 64,
			right = 0,
			y = 160,
			tweakDraggable = true,
			color = {0, 0, 0, 0},
			padding = {0, 0, 0, 0},
			itemMargin = {0, 0, 0, 0}
		}
		if Spring.GetGameSeconds() <= 0 then
			screen0:AddChild(buttonWindow)
		end
		
		button = Button:New{
			parent = buttonWindow,
			caption = '',
			tooltip = "Open comm selection screen",
			width = "100%",
			height = "100%",
			x = 0,
			y = 0,
			OnClick = {function() Spring.SendCommands({"luaui "..actionShow}) end}
		}
		
		buttonImage = Image:New{
			parent = button,
			width="100%";
			height="100%";
			x=0;
			y=0;
			file = "LuaUI/Images/startup_info_selector/selecticon.png",
			keepAspect = false,
		}	
		CreateWindow()
	end
end

-- hide window if game was loaded
local timer = 0
function widget:Update(dt)
	if gameframe < 1 then
		timer = timer + dt
		if timer >= 0.1 then
			if (spGetGameRulesParam("loadedGame") == 1) and mainWindow then
				mainWindow:Dispose()
			end
		end
	end
	if wantLabelUpdate then
		UpdateLabelPositions()
		wantLabelUpdate = false
	end
end

function widget:Shutdown()
  --if mainWindow then
	--mainWindow:Dispose()
  --end
  widgetHandler:RemoveAction(actionShow)
end

function widget:Gameframe(n)
	gameframe = n
end

function widget:GameStart()
	if (not dotaMode) and (not ctfMode) then
		screen0:RemoveChild(buttonWindow)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------