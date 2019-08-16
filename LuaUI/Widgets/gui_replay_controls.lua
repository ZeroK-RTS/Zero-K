function widget:GetInfo()
  return {
    name      = "Replay control buttons",
    desc      = "Graphical buttons for controlling replay speed, " ..
    "pausing and skipping pregame chatter",
    author    = "knorke",
    date      = "August 2012", --updated on 20 May 2015
    license   = "stackable",
    layer     = 1,
    enabled   = true  --  loaded by my horse?
  }
end

-- 5 May 2015 added progress bar, by xponen

--Speedup
local widgetName = widget:GetInfo().name
local modf = math.modf
local format = string.format

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
local progress_speed
local progress_target
local label_hoverTime

---------------------------------
-- Globals
---------------------------------
local speeds = {0.5, 1, 2, 3, 4, 5,10}
local isPaused = false
-- local wantedSpeed = nil
local skipped = false
local fastForwardTo = -1
local currentFrameTime = 0
local demoStarted = false
local showProgress = true

local SELECT_BUTTON_COLOR = {0.98, 0.48, 0.26, 0.85}
local SELECT_BUTTON_FOCUS_COLOR = {0.98, 0.48, 0.26, 0.85}

-- Defined upon learning the appropriate colors
local BUTTON_COLOR
local BUTTON_FOCUS_COLOR
local BUTTON_BORDER_COLOR

---------------------------------
-- Epic Menu
---------------------------------
options_path = 'Settings/HUD Panels/Replay Controls'
options_order = { 'visibleprogress'}
options = {
	visibleprogress = {
		name = 'Progress Bar',
		desc = 'Enables a clickable progress bar for the replay.',
		type = 'bool',
		value = true,
		noHotkey = true,
		OnChange = function(self)
			if (not Spring.IsReplay()) then
				return
			end
			local replayLen = Spring.GetReplayLength and Spring.GetReplayLength()
			if replayLen == 0 then --replay info broken
				replayLen = false
				self.value = false
			end
			local frame = Spring.GetGameFrame()
			
			if self.value then
				progress_speed:SetValue(frame)
				progress_speed:SetCaption(math.modf(frame/progress_speed.max*100) .. "%")
			else
				progress_speed:SetValue(0)
				progress_speed:SetCaption("")
			end
			showProgress = self.value
		end,
	},
}

---------------------------------
---------------------------------

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
	Window = Chili.Window
	StackPanel = Chili.StackPanel
	Image = Chili.Image
	Progressbar = Chili.Progressbar
	Control = Chili.Control
	screen0 = Chili.Screen0

	CreateTheUI()
end

function CreateTheUI()
	--create main Chili elements
	local screenWidth,screenHeight = Spring.GetWindowGeometry()
	local height = tostring(math.floor(screenWidth/screenHeight*0.35*0.35*100)) .. "%"
	local windowY = math.floor(screenWidth*2/11 + 32)
	
	local labelHeight = 24
	local fontSize = 16
	
	local currSpeed = 2 --default button setting
	if window then
		currSpeed = window.currSpeed
		screen0:RemoveChild(window)
		window:Dispose()
	end

	local replayLen = Spring.GetReplayLength and Spring.GetReplayLength()
	if replayLen == 0 then --replay info broken
		replayLen = false
		showProgress = false
	end
	local frame = Spring.GetGameFrame()
	
	window = Window:New{
		--parent = screen0,
		name   = 'replaycontroller3';
		width = 310;
		height = 86;
		right = 10;
		y = windowY;
		classname = "main_window_small_flat",
		dockable = false;
		draggable = true,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = false,
		--informational tag:
		currSpeed = currSpeed,
		lastClick = Spring.GetTimer(),
		--end info tag
		--itemMargin  = {0, 0, 0, 0},
		--caption = "replay control"
		OnMouseDown = {function(self, x, y, mouse)
				--clickable bar, reference: "Chili Economy Panel Default"'s Reserve bar
				if not showProgress then
					return
				end
				if x>progress_speed.x and y>progress_speed.y and x<progress_speed.x2 and  y<progress_speed.y2 then
					local target = (x-progress_speed.x) / (progress_speed.width)
					if target > progress_speed.value/progress_speed.max then
						progress_target:SetValue(target)
						snapButton(#speeds)
						setReplaySpeed (speeds[#speeds], #speeds)
						fastForwardTo = modf(target*progress_speed.max)
						label_hoverTime:SetCaption("> >")
					else
						snapButton(2)
						progress_target:SetValue(0)
						setReplaySpeed (speeds[2],2)
					end
				end
				return
			end},
		OnMouseMove = {function(self, x, y, mouse)
				--clickable bar, reference: "Chili Economy Panel Default"'s Reserve bar
				if not showProgress then
					return
				end

				if x>progress_speed.x and y>progress_speed.y and x<progress_speed.x2 and  y<progress_speed.y2 then
					local target = (x-progress_speed.x) / (progress_speed.width)
					local hoverOver = modf(target*progress_speed.max/30)
					local minute, second = modf(hoverOver/60)--second divide by 60sec-per-minute, then saperate result from its remainder
					second = 60*second --multiply remainder with 60sec-per-minute to get second back.
					label_hoverTime:SetCaption(format ("%d:%02d" , minute, second))
				else
					if label_hoverTime.caption ~= " " then
						label_hoverTime:SetCaption(" ")
					end
				end
				return
			end},
	}
	
	for i = 1, #speeds do
		local button = Button:New {
			width = 40,
			height = 20,
			y = 28,
			x = 5+(i-1)*40,
			classname = "button_tiny",
			parent=window;
			padding = {0, 0, 0,0},
			margin = {0, 0, 0, 0},
			caption=speeds[i] .."x",
			tooltip = "play at " .. speeds[i] .. "x speed";
			OnClick = {
				function()
					snapButton(i)
					progress_target:SetValue(0)
					setReplaySpeed (speeds[i], i)
				end
			}
		}
		if not BUTTON_COLOR then
			BUTTON_COLOR = button.backgroundColor
		end
		if not BUTTON_FOCUS_COLOR then
			BUTTON_FOCUS_COLOR = button.focusColor
		end
		if not BUTTON_BORDER_COLOR then
			BUTTON_BORDER_COLOR = button.borderColor
		end
		if i == currSpeed then
			button.backgroundColor = SELECT_BUTTON_COLOR
			button.focusColor = SELECT_BUTTON_FOCUS_COLOR
			button:Invalidate()
		end
		button_setspeed[i] = button
	end
	
	if (frame == 0) then
		button_skipPreGame = Button:New {
			width = 180,
			height = 20,
			y = 50,
			x = 95,
			classname = "button_tiny",
			parent=window;
			padding = {0, 0, 0,0},
			margin = {0, 0, 0, 0},
			caption="skip pregame chatter",
			tooltip = "Skip the pregame chat and startposition choosing, go directly to the action!";
			OnClick = {function()
				skipPreGameChatter ()
				end}
		}
	else
		--in case reloading luaui mid demo
		widgetHandler:RemoveCallIn("AddConsoleMessage")
	end
	
	label_hoverTime = Label:New {
		width = 20,
		height = 15,
		y = 54,
		x = 125,
		parent=window;
		caption=" ",
	}
	
	button_startStop = Button:New {
		width = 80,
		height = 20,
		y = 50,
		x = 5,
			classname = "button_tiny",
		parent=window;
		padding = {0, 0, 0,0},
		margin = {0, 0, 0, 0},
		caption="pause", --pause/continue
		tooltip = "pause or continue playback";
		OnClick = {function()
			currentFrameTime = -3
			if (isPaused) then
				unpause()
			else
				pause()
			end
		end}
	}
	
	progress_target = Progressbar:New{
			parent = window,
			y =  5,
			x		= 5,
			right = 5,
			height	= 20,
			max     = 1;
			color   = {0.75,0.75,0.75,0.5} ;
			backgroundColor = {0,0,0,0} ,
			value = 0,
		}

	local replayLen = (replayLen and replayLen* 30) or 100-- in frame
	progress_speed = Progressbar:New{
			parent = window,
			y =  5,
			x		= 5,
			right = 5,
			height	= 20,
			max     = replayLen;
			caption = showProgress and (frame/replayLen*100 .. "%") or " ",
			color   = showProgress and {0.9,0.15,0.2,0.75} or  {1,1,1,0.0} ; --red, --{0.2,0.9,0.3,1}; --green
			backgroundColor = {1,1,1,0.8} ,
			value = frame,
			flash = false,
		}
	progress_speed.x2 =  progress_speed.x + progress_speed.width
	progress_speed.y2 =  progress_speed.y + progress_speed.height

	screen0:AddChild(window)
end

function snapButton(pushButton)
	button_setspeed[window.currSpeed].backgroundColor = BUTTON_COLOR
	button_setspeed[window.currSpeed].focusColor = BUTTON_FOCUS_COLOR
	button_setspeed[window.currSpeed]:Invalidate()
	button_setspeed[pushButton].backgroundColor = SELECT_BUTTON_COLOR
	button_setspeed[pushButton].focusColor = SELECT_BUTTON_FOCUS_COLOR
	button_setspeed[pushButton]:Invalidate()
end

function pause(supressCommand)
	Spring.Echo ("Playback paused")
	if not supressCommand then
		Spring.SendCommands ("pause 1")
	end
	isPaused = true
	button_startStop:SetCaption ("play")
	--window:SetColor ({1,0,0, 1})
	--window:SetCaption ("trololo")--button stays pressed down and game lags	ANY INVALID CODE MAKES IT LAG, REASON WHY COM MORPH LAGS?
end

function unpause(supressCommand)
	Spring.Echo ("Playback continued")
	if not supressCommand then
		Spring.SendCommands ("pause 0")
	end
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
		-- wantedSpeed = speed
		--[[
		--does not work:
		Spring.SendCommands ("slowdown")
		Spring.SendCommands ("slowdown")
		Spring.SendCommands ("slowdown")
		Spring.SendCommands ("slowdown")
		Spring.SendCommands ("slowdown")
		]]--
		--does not work:
		-- local i = 0
		-- while (Spring.GetGameSpeed() > speed and i < 50) do
			-- Spring.SendCommands ("setminspeed " ..0.1)
			Spring.SendCommands ("setmaxspeed " .. speed)
			Spring.SendCommands ("setmaxspeed " .. 10.0)
			-- Spring.SendCommands ("slowdown")
			-- i=i+1
		-- end
	end
	--Spring.SendCommands ("setmaxpeed " .. speed)
	window.currSpeed = i
end

local lastSkippedTime = 0
function widget:Update(dt)
	-- if (wantedSpeed) then
	-- 	if (Spring.GetGameSpeed() > wantedSpeed) then
	-- 		Spring.SendCommands ("slowdown")
	-- 	else
	-- 		wantedSpeed = nil
	-- 	end
	-- end
	if skipped and demoStarted then --do not do "skip 1" at or before demoStart because,it Hung Spring/broke the command respectively.
		if lastSkippedTime > 1.5 then
			Spring.SendCommands("skip 1")
			lastSkippedTime = 0
		else
			lastSkippedTime = lastSkippedTime + dt
		end
	end
	currentFrameTime = currentFrameTime + dt
	if currentFrameTime > 0 then
		if (currentFrameTime > 1) ~= isPaused then
			if not isPaused then
				pause(true)
			else
				unpause(true)
			end
		end
	end
end

function widget:GameFrame (f)
	if currentFrameTime > 0 then
		currentFrameTime = 0
	end
	if (fastForwardTo>0) then
		if f==fastForwardTo then
			pause ()
			snapButton(2)
			progress_target:SetValue(0)
			setReplaySpeed (speeds[2],2)
			fastForwardTo = -1
		elseif f>fastForwardTo then
			progress_target:SetValue(0)
			fastForwardTo = -1
		end
	end
	if (f==1) then
		window:RemoveChild(button_skipPreGame)
		skipped = nil
		lastSkippedTime = nil
		widgetHandler:RemoveCallIn("AddConsoleMessage")
	elseif showProgress and (f%2 ==0)  then
		progress_speed:SetValue(f)
		progress_speed:SetCaption(math.modf(f/progress_speed.max*100) .. "%")
	end
end

function widget:AddConsoleMessage(msg)
	if msg.text == "Beginning demo playback" then
		demoStarted = true
		widgetHandler:RemoveCallIn("AddConsoleMessage")
	end
end

function skipPreGameChatter ()
	Spring.Echo("Skipping pregame chatter")
	if (demoStarted) then
		Spring.SendCommands("skip 1")
	end
	skipped = true
	-- window:RemoveChild(button_skipPreGame)
end
