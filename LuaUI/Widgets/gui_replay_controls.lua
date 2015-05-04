function widget:GetInfo()
  return {
    name      = "Replay control buttons",
    desc      = "Graphical buttons for controlling replay speed, " .. 
    "pausing and skipping pregame chatter",
    author    = "knorke",
    date      = "August 2012", --updated on 5 May 2015
    license   = "stackable",
    layer     = 1, 
    enabled   = true  --  loaded by my horse?
  }
end
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

local speeds = {0.5, 1, 2, 3, 4, 5,10}

local isPaused = false
-- local wantedSpeed = nil
local skipped = false
local fastForwardTo = -1
local demoStarted = false

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
		OnMouseDown = {function(self, x, y, mouse) 
				--clickable bar, reference: "Chili Economy Panel Default"'s Reserve bar
				if x>progress_target.x
				and y>progress_target.y
				and x<progress_target.x + progress_target.width
				and  y<progress_target.y+ progress_target.height
				then
					local target = (x-progress_target.x) / (progress_target.width)
					progress_target:SetValue(target)
					snapButton(#speeds)
					setReplaySpeed (speeds[#speeds], #speeds)
					fastForwardTo = modf(target*progress_speed.max)
				end
				return 
			end},
		OnMouseMove = {function(self, x, y, mouse) 
				--clickable bar, reference: "Chili Economy Panel Default"'s Reserve bar
				if x>progress_target.x
				and y>progress_target.y
				and x<progress_target.x + progress_target.width
				and  y<progress_target.y+ progress_target.height
				then
					local target = (x-progress_target.x) / (progress_target.width)
					local hoverOver = modf(target*progress_speed.max/30)
					local minute, second = modf(hoverOver/60)--second divide by 60sec-per-minute, then saperate result from its remainder
					second = 60*second --multiply remainder with 60sec-per-minute to get second back.
					label_hoverTime:SetCaption(format ("%d:%02d" , minute, second))
				else
					label_hoverTime:SetCaption(" ")
				end
				return 
			end},
	}
	
	for i = 1, #speeds do
		button_setspeed[i] = Button:New {
		width = 40,
		height = 20,
		y = 36,
		x = 10+(i-1)*40,
		parent=window;
		padding = {0, 0, 0,0},
		margin = {0, 0, 0, 0},
		backgroundColor = (i==2 and {0, 0, 1, 1}) or {1, 1, 0, 1}, -- 1x selected by default
		caption=speeds[i] .."x",
		tooltip = "play at " .. speeds[i] .. "x speed";
		OnClick = {function()
			snapButton(i)
			progress_target:SetValue(0)
			setReplaySpeed (speeds[i], i)
		end}
	}
	end
	
	if (Spring.GetGameFrame() == 0) then 
		button_skipPreGame = Button:New {
			width = 180,
			height = 20,
			y = 58,
			x = 100,
			parent=window;
			padding = {0, 0, 0,0},
			margin = {0, 0, 0, 0},
			caption="skip pregame chatter",
			tooltip = "Skip the pregame chat and startposition chosing, directly to the action!";
			OnClick = {function()
				skipPreGameChatter ()
				end}
		}
	else 
		--in case reloading luaui mid demo
		widgetHandler:RemoveCallIn("AddConsoleMessage")
		widgetHandler:RemoveCallIn("Update")
	end
	
	label_hoverTime = Label:New {
		width = 20,
		height = 15,
		y = 58,
		x = 133,
		parent=window;
		caption=" ",
	}
	
	button_startStop = Button:New {
		width = 80,
		height = 20,
		y = 58,
		x = 10,
		parent=window;
		padding = {0, 0, 0,0},
		margin = {0, 0, 0, 0},
		caption="pause", --pause/continue
		tooltip = "pause or continue playback";
		OnClick = {function()
			if (isPaused) then
				unpause ()
			else
				pause ()
			end
			end}
	}
	
	progress_target = Progressbar:New{
			parent = window,
			y =  8,
			x		= 10,
			width   = 280,
			height	= 20, 
			max     = 1;
			color   = {0.75,0.75,0.75,0.75};
			value = 0,
		}

	local replayLen = (Spring.GetReplayLength and Spring.GetReplayLength() or 1)* 30 -- in frame
	progress_speed = Progressbar:New{
			parent = window,
			y =  8,
			x		= 10,
			width   = 280,
			height	= 20, 
			max     = replayLen;
			caption = "0%",
			color   = {0.9,0.15,0.2,0.75}; --red, --{0.2,0.9,0.3,1}; --green
			value = replayLen,
			isWorking = (replayLen>30),
			currSpeed = 2,
		}
	
	screen0:AddChild(window)

end

function snapButton(pushButton)
	button_setspeed[progress_speed.currSpeed].backgroundColor = {1, 1, 0, 1}
	button_setspeed[progress_speed.currSpeed]:Invalidate()
	button_setspeed[pushButton].backgroundColor = {0, 0, 1, 1}
	button_setspeed[pushButton]:Invalidate()
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
	progress_speed.currSpeed = i
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
end

function widget:GameFrame (f)
	if (fastForwardTo>0) then
		if f==fastForwardTo then
			pause ()
			progress_target:SetValue(0)
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
		widgetHandler:RemoveCallIn("Update")
	elseif progress_speed.isWorking and (f%2 ==0)  then
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