function widget:GetInfo()
  return {
    name      = "Replay control buttons",
    desc      = "Graphical buttons for controlling replay speed, " .. 
    "pausing and skipping pregame chatter",
    author    = "knorke",
    date      = "August 2012",
    license   = "stackable",
    layer     = 1, 
    enabled   = true  --  loaded by my horse?
  }
end

local widgetName = widget:GetInfo().name

local Chili
local Button
local Label
local Window
local Panel
local TextBox
local Image
local Progressbar
local Control
local Font

-- elements
local window
local button_setspeed = {}
local button_skipPreGame
local button_startStop

local speeds = {0.5, 1, 2, 3, 4, 5,10}

local isPaused = false
local wantedSpeed = nil


function widget:Initialize()
	if (not Spring.IsReplay()) then
		Spring.Echo ("<" .. widgetName .. "> Live mode. Widget removed.")
		widgetHandler:RemoveWidget(self)
		return
	end
	-- setup Chili
	Chili = WG.Chili
	Button = Chili.Button
	Label = Chili.Label
	Colorbars = Chili.Colorbars
	Window = Chili.Window
	StackPanel = Chili.StackPanel
	Image = Chili.Image
	Progressbar = Chili.Progressbar
	Control = Chili.Control
	screen0 = Chili.Screen0
	
	--create main Chili elements
	local screenWidth,screenHeight = Spring.GetWindowGeometry()
	local height = tostring(math.floor(screenWidth/screenHeight*0.35*0.35*100)) .. "%"
	local y = tostring(math.floor((1-screenWidth/screenHeight*0.35*0.35)*100)) .. "%"
	
	local labelHeight = 24
	local fontSize = 16

	window = Window:New{
		--parent = screen0,
		name   = 'replaycontroller';
		color = {255, 255, 255, 255},
		width = 300;
		height = 85;
		right = 10; 
		y = "20%";
		dockable = false;
		draggable = true,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = false,
		minWidth = MIN_WIDTH, 
		minHeight = MIN_HEIGHT,
		padding = {0, 0, 0, 0},
		--itemMargin  = {0, 0, 0, 0},
		--caption = "replay control"
	}
	
	for i = 1, #speeds do
		button_setspeed[i] = Button:New {
		width = 40,
		height = 20,
		y = 30,
		x = 10+(i-1)*40,
		parent=window;
		padding = {0, 0, 0,0},
		margin = {0, 0, 0, 0},
		backgroundColor = {1, 1, 0, 255},		
		caption=speeds[i] .."x",
		tooltip = "play at " .. speeds[i] .. "x speed";
		OnMouseDown = {function()
			setReplaySpeed (speeds[i], i)
			button_setspeed.backgroundColor = {0, 0, 1, 1}
			end}
	}
	end
	
	button_skipPreGame = Button:New {
		width = 180,
		height = 20,
		y = 55,
		x = 100,
		parent=window;
		padding = {0, 0, 0,0},
		margin = {0, 0, 0, 0},
		backgroundColor = {1, 1, 1, 1},		
		caption="skip pregame chatter",
		tooltip = "Skip the pregame chat and startposition chosing, directly to the action!";
		OnMouseDown = {function()
			skipPreGameChatter ()
			end}
	}
	
	button_startStop = Button:New {
		width = 80,
		height = 20,
		y = 55,
		x = 10,
		parent=window;
		padding = {0, 0, 0,0},
		margin = {0, 0, 0, 0},
		backgroundColor = {1, 1, 1, 1},		
		caption="pause", --pause/continue
		tooltip = "pause or continue playback";
		OnMouseDown = {function()
			if (isPaused) then
				unpause ()
			else
				pause ()
			end
			end}
	}
	
	progress_speed = Progressbar:New{
			parent = window,
			y = 8,
			x		= 10,
			width   = 280,
			height	= 20,
			max     = #speeds;
			caption = "replay speed";
			color   = (i == 1 and {0.2,0.9,0.3,1}) or {0.9,0.15,0.2,1};
			value = 1 +1,
		}
	
	screen0:AddChild(window)

end

function pause ()
	Spring.Echo ("Playback paused")
	Spring.SendCommands ("pause 1")
	isPaused = true
	button_startStop:SetCaption ("play")
	--window:SetColor ({1,0,0, 1})
	--window:SetCaption ("trololo")--button stays pressed down and game lags	ANY INVALID CODE MAKES IT LAG, REASON WHY COM MORPH LAGS?	
end

function unpause ()
	Spring.Echo ("Playback continued")
	Spring.SendCommands ("pause 0")
	isPaused = false
	button_startStop:SetCaption ("pause")
end


function setReplaySpeed (speed, i)
	--put something invalid in these button function like:
	--doesNotExist[3] = 5
	--and there will be no error message. However, the game will stutter for a second
	
	local s = Spring.GetGameSpeed()	
	--Spring.Echo ("setting speed to: " .. speed .. " current is " .. s)
	if (speed > s) then	--speedup
		Spring.SendCommands ("setminspeed " .. speed)
		Spring.SendCommands ("setminspeed " ..0.1)
	else	--slowdown
		wantedSpeed = speed
		--[[
		--does not work:
		Spring.SendCommands ("slowdown")
		Spring.SendCommands ("slowdown")
		Spring.SendCommands ("slowdown")
		Spring.SendCommands ("slowdown")
		Spring.SendCommands ("slowdown")
		--does not work:
		local i = 0
		while (Spring.GetGameSpeed() > speed and i < 50) do
			--Spring.SendCommands ("setminspeed " ..0.4)
			--Spring.SendCommands ("setmaxpeed " .. speed)
			Spring.SendCommands ("slowdown")
			i=i+1
		end
		--]]		
	end	
	--Spring.SendCommands ("setmaxpeed " .. speed)
	progress_speed:SetValue(i)
end

function widget:Update()
	if (wantedSpeed) then
		if (Spring.GetGameSpeed() > wantedSpeed) then
			Spring.SendCommands ("slowdown")
		else
			wantedSpeed = nil
		end
	end
end

function widget:GameFrame (f)
	if (f==1) then
		window:RemoveChild(button_skipPreGame)
	end
end

function skipPreGameChatter ()
	Spring.Echo ("Skipping pregame chatter")
	Spring.SendCommands ("skip 1")
	window:RemoveChild(button_skipPreGame)
end