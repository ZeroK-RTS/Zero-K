local versionNumber = "1.22"
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

include("Widgets/COFCTools/ExportUtilities.lua")
VFS.Include ("LuaRules/Utilities/startbox_utilities.lua")
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

local Chili
local Window
local ScrollPanel
local Grid
local Label
local screen0
local Image
local Button

local vsx, vsy = widgetHandler:GetViewSizes()
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
local optionData

local noComm = false
local gameframe = Spring.GetGameFrame()
local COMM_DROP_FRAME = 450
local WINDOW_WIDTH = 720
local WINDOW_HEIGHT = 480
local BUTTON_WIDTH = 128
local BUTTON_HEIGHT = 128

if (vsx < 1024 or vsy < 768) then 
	--shrinker
	WINDOW_WIDTH = vsx* (WINDOW_WIDTH/1024)
	WINDOW_HEIGHT = vsy* (WINDOW_HEIGHT/768)
	BUTTON_WIDTH = vsx* (BUTTON_WIDTH/1024)
	BUTTON_HEIGHT = vsy* (BUTTON_HEIGHT/768)
end

--local wantLabelUpdate = false
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- wait for next screenframe so Grid can resize its elements first	-- doesn't actually work
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
end

options_path = 'Settings/HUD Panels/Commander Selector'
options = {
	hideTrainers = {
		name = 'Hide Trainer Commanders',
		--desc = '',
		type = 'bool',
		value = false,
		noHotkey = true,
		OnChange = function(self)
			if trainerCheckbox then
				trainerCheckbox.checked = self.value
				trainerCheckbox.state.checked = self.value
				trainerCheckbox:Invalidate()
			end
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

local cameraMoved = false
function Close (permanently)

	if mainWindow then
		mainWindow:Dispose()
	end

	if not cameraMoved then
		local startboxes = GetRawBoxes()
		cameraMoved = true
		local startbox = startboxes[Spring.GetMyAllyTeamID()]
		local minX, minZ, maxX, maxZ, maxY = Game.mapSizeX, Game.mapSizeZ, 0, 0, 0
		-- Spring.Echo(startbox.boxes)
		if startbox and startbox.boxes then
			for i = 1, #startbox.boxes do
				for j = 1, #startbox.boxes[i] do
					local boxPoint = startbox.boxes[i][j]
					-- Spring.Echo("startbox["..i.."]: {"..boxPoint[1]..", "..boxPoint[2].."}, Bounds: x: "..minX.." - "..maxX..", z: "..minZ.." - "..maxZ..", maxY: "..maxY)
					minX = math.min(minX, boxPoint[1])
					minZ = math.min(minZ, boxPoint[2])
					maxX = math.max(maxX, boxPoint[1])
					maxZ = math.max(maxZ, boxPoint[2])
					maxY = math.max(maxY, Spring.GetGroundHeight(boxPoint[1], boxPoint[2]))
				end
			end
			SetCameraTargetBox(minX, minZ, maxX, maxZ, 1000, maxY, 0.67, true)
		end
	end

	if permanently then
		if not noComm then
			widgetHandler:RemoveAction(actionShow)
			noComm = true
		end

		if (Spring.GetGameFrame() <= COMM_DROP_FRAME) then
			widgetHandler:RemoveCallIn('GameFrame')
			widgetHandler:RemoveCallIn('GameProgress')
		end
	end
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
		autosize = false,
		resizeItems = true,
		x=0, right=0,
		y=0, bottom=36,
		centerItems = false,
	}
	-- add posters
	local i = 0
	for index,option in ipairs(optionData) do
		i = i + 1
		local hideButton = options.hideTrainers.value and option.trainer
		local button = Button:New {
			parent = (not hideButton) and grid or nil,
			caption = "",	--option.name,	--option.trainer and "TRAINER" or "",
			valign = "bottom",
			tooltip = option.tooltip, --added comm name under cursor on tooltip too, like for posters
			width = BUTTON_WIDTH,
			height = BUTTON_HEIGHT,
			padding = {5,5,5,5},
			OnClick = {function()
				Spring.SendLuaRulesMsg("customcomm:"..option.commProfile)
				Spring.SendCommands({'say a:I choose: '..option.name..'!'})
				Close()
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
			x = "15%",
			bottom = 4,
			caption = option.name,
			align = "center",
			font = {size = 14},
		}
		buttonLabels[i] = label
		if option.trainer then
			local trainerLabel = Label:New{
				parent = image,
				x = "25%",
				y = "50%",
				caption = "TRAINER",
				align = "center",
				font = {color = {1,0.2,0.2,1}, size=16, outline=true, outlineColor={1,1,1,0.8}},
			}
			trainerLabels[i] = trainerLabel
		end
	end
	local cbWidth = WINDOW_WIDTH*0.4
	local closeButton = Button:New{
		parent = mainWindow,
		caption = "CLOSE",
		width = cbWidth,
		x = WINDOW_WIDTH*0.5 + (WINDOW_WIDTH*0.5 - cbWidth)/2,
		height = 30,
		bottom = 2,
		OnClick = {function() Close() end}
	}
	trainerCheckbox = Chili.Checkbox:New{
		parent = mainWindow,
		x = 4,
		bottom = 2,
		width = 160,
		caption = "Hide Trainer Comms",
		checked = options.hideTrainers.value,
		OnChange = { function(self)
			-- this is called *before* the 'checked' value is swapped, hence negation everywhere
			if options.hideTrainers.epic_reference then
				options.hideTrainers.epic_reference.checked = not self.checked
				options.hideTrainers.epic_reference.state.checked = not self.checked
				options.hideTrainers.epic_reference:Invalidate()
			end
			options.hideTrainers.value = not self.checked
			ToggleTrainerButtons(self.checked)
		end },
	}
	grid:Invalidate()
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:Initialize()
	optionData = include("Configs/startup_info_selector.lua")

	if not (WG.Chili) then
		widgetHandler:RemoveWidget()
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
	if ((coop and playerID and Spring.GetGameRulesParam("commSpawnedPlayer"..playerID) == 1)
	or (not coop and Spring.GetTeamRulesParam(teamID, "commSpawned") == 1)
	or (Spring.GetSpectatingState() or Spring.IsReplay() or forcejunior))
	--and (not Spring.IsCheatingEnabled())
	then
		noComm = true	-- will prevent window from auto-appearing; can still be brought up from the button
	end

	vsx, vsy = widgetHandler:GetViewSizes()

	if (not noComm) then
		widgetHandler:AddAction(actionShow, CreateWindow, nil, "t")
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
	timer = timer + dt
	if timer >= 0.1 then
		if (spGetGameRulesParam("loadedGame") == 1) then
			Close(true)
		end
		widgetHandler:RemoveCallIn('Update')
	end
end

function widget:Shutdown()
	Close(true)
end

function widget:GameFrame(n)
	if n == COMM_DROP_FRAME then
		Close(true)
	end
end

function widget:GameProgress(n)
	if n == COMM_DROP_FRAME then
		Close(true)
	end
end

function widget:GameStart()
	screen0:RemoveChild(buttonWindow)
end

-- this a pretty retarded place to put this but:
-- Update can fire before the game is actually loaded
-- GameStart is the actual game starting (not loading finished)
-- there is probably some better way
function widget:DrawWorld()
	if (Spring.GetGameFrame() < 1) then
		PlaySound("LuaUI/Sounds/Voices/initialized_core_1", 1, 'ui')
	end
	widgetHandler:RemoveCallIn('DrawWorld')
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------