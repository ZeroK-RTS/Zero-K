local versionNumber = "1.2"

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

--[[
-- Features:
_ Show a windows at game start with pictures to choose commander type.

-- To do:
_ Make a small (2-3 frames) animation when cursor hover comms' posters (like the unit highlight widget)and an highlight of the buttons hovered on. Can chili do that yet ?
_ Make each player broadcast their choice to their team in a way it can be used by chili_chatbubbles, I had issues with that, left it for later. Use Spring.SendCommands( ?

---- CHANGELOG -----
-- versus666, 		v1.2	(30oct2010)	:	Placed CreateWindow() @ _DrawScreen() to avoid showing commander selection after game start when DEBUG is FALSE and doing /luiaui reload.
--											Thanks to [LCC]Quantum[0K] for spotting the little mistake which was blocking me for 1 complete day.
-- versus666,		v1.1	(28oct2010)	:	Corrected typos, cosmetic changes and added comments & infos about comm choices.
-- SirMaverick,		v1.0				:	Creation.
--]]
----------------------------------------------
local debug	= false --generates debug message
local Echo	= Spring.Echo
local spGetSpectatingState	= Spring.GetSpectatingState()
local spIsReplay			= Spring.IsReplay()

local Chili
local Window
local screen0
local Image
local Button

local vsx, vsy
local modoptions = Spring.GetModOptions() --used in LuaUI\Configs\startup_info_selector.lua for planetwars
local selectorShown = false
local mainWindow
local actionShow = "showstartupinfoselector"
local optionData = include("Configs/startup_info_selector.lua")
---------------------------------------------
function widget:ViewResize(viewSizeX, viewSizeY)
  vsx = viewSizeX
  vsy = viewSizeY
end

function printDebug( value )
	if ( debug ) then Echo( value )
	end
end

--local gameDate = os.date(t)
--if (gameDate.month == 4) and (gameDate.day == 1) then optionData.communism.sound = "LuaUI/Sounds/communism/tetris.wav" end

-- set poster size (3/4 ratio)
local function posterSize(num)
	if num < 2 then
		local a,b = 450, 600
	-- for those who play with 800x600; but consider card upgrade!
			if b > 0.8*vsy then
				local scale = 0.8*vsy/b
				a = scale * a
				b = scale * b
			end
			return a, b, 60
	else
	-- scale to 80% of screen width
		local spacex = vsx * 0.8 / num
		if spacex < 300 then
			return spacex, spacex*4/3, 60
		else
		return 300, 400, 60
		end
	end
end

function widget:Initialize()
	if ((not WG.Chili) and IsSpec()) then
		printDebug("<gui_startup_info_selector DEBUG >: Or not using Chili, exiting.")
		widgetHandler:RemoveWidget()
	end

	-- chili setup
	Chili = WG.Chili
	Window = Chili.Window
	screen0 = Chili.Screen0
	Image = Chili.Image
	Button = Chili.Button

	vsx, vsy = widgetHandler:GetViewSizes()

	BindCallins()

	widgetHandler:AddAction(actionShow, CreateWindow, nil, "t")

	-- create the window if debug = true and not already shown, shortcut _DrawScreen
	if debug and not selectorShown then
		Echo( "<gui_startup_info_selector DEBUG >: Selector shown due to debug.")
		CreateWindow()
	end
end

function IsSpec()
	if spGetSpectatingState() or spIsReplay() then
		printDebug("<gui_startup_info_selector DEBUG >: You're spec or playing demo.")
		return true
	end
end

function CreateWindow()
	selectorShown = true
	printDebug("<gui_startup_info_selector DEBUG >: create window.")
	-- count options
	local actived = 0
	for name,option in pairs(optionData) do
		if option:enabled() then
			actived = actived + 1
		end
	end

	local posterx, postery, buttonspace = posterSize(actived)

	-- create window if necessary
	if actived > 0 then

	mainWindow = Window:New{
		resizable = false,
		draggable = false,
		clientWidth  = posterx*actived,
		clientHeight = postery + buttonspace +12 ,--there is a title (caption below), height is not just poster+buttons
		x = (vsx - posterx*actived)/2,
		y = ((vsy - postery - buttonspace)/2),
		parent = screen0,
		caption = "STARTUP SELECTOR",
		}

	-- add posters
	local i = 0
	for name,option in pairs(optionData) do
		if option:enabled() then
			local image = Image:New{
				parent = mainWindow,
				file = option.poster,--lookup Configs/startup_info_selector.lua to get optiondata
				tooltip = option.tooltip,
				caption = option.selector,
				width = posterx,
				height = postery,
				x = (i*posterx),
				padding = {1,1,1,1},
				OnClick = {option.button},
				--OnMouseUp = {option.button},
				y = 9 
				}
			local buttonWidth = posterx*2/3
				if (option.button ~= nil) then 
					local button = Button:New {
						parent = mainWindow,
						x = i*posterx + (posterx - buttonWidth)/2, --placement of comms names' buttons @ the middle of each poster
						y = postery+12,
						caption = option.selector,
						tooltip = option.tooltip, --added comm name under cursor on tooltip too, like for posters
						width = buttonWidth,
						height = 30,
						padding={1,1,1,1},
					--OnMouseUp = {option.button},
						OnClick = {option.button},-- used onclick in case people change their mind, mouseup register the option you were when pressed on, even if you moved somewhere else while still hold mouse button. onclick register it only if you're still on it (even if you moved to another part of the comm button).
						}
				end 
			i = i + 1
      end
    end

    local cbWidth = posterx*actived*0.75-- calculate width of close button depending of number or posters
    local closeButton = Button:New{
      parent = mainWindow,
      caption = "CLOSE  (defaults to Strike Commander)",
	  tooltip = "CLOSE\nNo commander selection made, will use Strike Commander",
      width = cbWidth,
      height = 30,
      x = (posterx*actived - cbWidth)/2,
      y = postery + (buttonspace)/2+14,
      --OnMouseUp = {Close}
	  OnClick = {function() Close(false) end}
	}

  end
end

function Close(commPicked)
	printDebug("<gui_startup_info_selector DEBUG >: closing")
	if not commPicked then Spring.SendLuaRulesMsg("faction:nova") end
	--Spring_SendCommands("say: a:I chose " .. option.button})
	mainWindow:Dispose()
end
 
 
function widget:Shutdown()

  if mainWindow then
    mainWindow:Dispose()
  end

  widgetHandler:RemoveAction(actionShow)

end

-- keep the window open, we want to be able to pick later
function widget:GameStart()
  if mainWindow then
    --mainWindow:Dispose()
  end
end

function UpdateCallins()
  --why is this called twice?
  widgetHandler:UpdateCallIn('DrawScreen')
  widgetHandler:UpdateCallIn('DrawScreen')
end

function BindCallins()
  widget.DrawScreen = _DrawScreen
  UpdateCallins()
end

function UnbindCallins()
  widget.DrawScreen = nil
  UpdateCallins()
end

-- use to play communism (always enabled) sound only at game start
function _DrawScreen()
  if (((Spring.GetGameSeconds() < 0.1) or Spring.IsCheatingEnabled())) then --create window in pregame and if not already shown
    if (Spring.GetModOption('communism',true,true)) then Spring.PlaySoundFile("LuaUI/Sounds/communism/sovnat1.wav", 1) 
	else Spring.PlaySoundFile("LuaUI/Sounds/communism/cash-register-01.wav", 1) end 
	printDebug("<gui_startup_info_selector DEBUG >: it's _DrawScreen")
  end
  if not (selectorShown) then CreateWindow() end
  UnbindCallins()
end

-----
-----