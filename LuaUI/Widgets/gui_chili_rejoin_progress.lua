function widget:GetInfo()
  return {
    name      = "Chili Rejoining Progress Bar",
    desc      = "v1.132 Show the progress of rejoining and temporarily turn-off Text-To-Speech while rejoining",
    author    = "msafwan (use UI from KingRaptor's Chili-Vote) ",
    date      = "Oct 10, 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    experimental = false,
    enabled   = true, --  loaded by default?
	--handler = true, -- allow this widget to use 'widgetHandler:FindWidget()'
  }
end
--------------------------------------------------------------------------------
--Crude Documentation-----------------------------------------------------------
--How it meant to work:
--1) GameProgress return serverFrame --> IF I-am-behind THEN activate chili UI ELSE de-activate chili UI --> Update the estimated-time-of-completion every second.
--2) LuaRecvMsg return timeDifference --> IF I-am-behind THEN activate chili UI ELSE nothing ---> Update the estimated-time-of-completion every second.
--3) at GameStart send LuaMsg containing GameStart's UTC.

--Others: some tricks to increase efficiency, bug fix, ect
--------------------------------------------------------------------------------
--Localize Spring function------------------------------------------------------
local spGetSpectatingState = Spring.GetSpectatingState
--------------------------------------------------------------------------------
--Chili Variable----------------------------------------------------------------- ref: gui_chili_vote.lua by KingRaptor
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
local window, stack_main, label_title
local stack_vote, label_vote, button_vote, progress_vote

local voteCount, voteMax
--------------------------------------------------------------------------------
--Calculator Variable------------------------------------------------------------
local serverFrameRate_G = 30 --//constant: assume server run at x1.0 gamespeed. 
local serverFrameNum1_G = nil --//variable: get the latest server's gameFrame from GameProgress() and do work with it.  
local oneSecondElapsed_G = 0 --//variable: a timer for 1 second, used in Update(). Update UI every 1 second.
local myGameFrame_G = 0 --//variable: get latest my gameFrame from GameFrame() and do work with it.
local myLastFrameNum_G = 0 --//variable: used to calculate local game-frame rate.
local ui_active_G = false --//variable:indicate whether UI is shown or hidden.
local averageLocalSpeed_G = {sumOfSpeed= 0, sumCounter= 0} --//variable: store the local-gameFrame speeds so that an average can be calculated. 
local defaultAverage_G = 30 --//constant: Initial/Default average is set at 30gfps (x1.0 gameSpeed)
local simpleMovingAverageLocalSpeed_G = {storage={},index = 1, runningAverage=defaultAverage_G} --//variable: for calculating rolling average. Initial/Default average is set at 30gfps (x1.0 gameSpeed)
--------------------------------------------------------------------------------
--Variable for fixing GameProgress delay at rejoin------------------------------
local myTimestamp_G = 0 --//variable: store my own timestamp at GameStart
local serverFrameNum2_G = nil --//variable: the expected server-frame of current running game
local submittedTimestamp_G = {} --//variable: store all timestamp at GameStart submitted by original players (assuming we are rejoining)
local functionContainer_G = function(x) end --//variable object: store a function 
local myPlayerID_G = 0
local gameProgressActive_G = false --//variable: signal whether GameProgress has been updated.
local iAmReplay_G = false
--------------------------------------------------------------------------------
--For testing GUI---------------------------------------------------------------
local forceDisplay = nil
--------------------------------------------------------------------------------
--[[
if VFS.FileExists("Luaui/Config/ZK_data.lua") then
	local configFile =  VFS.Include("Luaui/Config/ZK_data.lua")
	ttsControlEnabled_G = configFile["EPIC Menu"].config.epic_Text_To_Speech_Control_enable
	if ttsControlEnabled_G == nil then
		ttsControlEnabled_G = true
	end
end --]]


local function ActivateGUI_n_TTS (frameDistanceToFinish, ui_active, ttsControlEnabled, altThreshold)
	if frameDistanceToFinish >= (altThreshold or 120) then
		if not ui_active then
			screen0:AddChild(window)
			ui_active = true
			if ttsControlEnabled then
				Spring.Echo(Spring.GetPlayerInfo(myPlayerID_G) .. " DISABLE TTS") --eg: output "<playerName> DISABLE TTS"
			end
		end
	elseif frameDistanceToFinish < (altThreshold or 120) then
		if ui_active then
			screen0:RemoveChild(window)
			ui_active = false
			if ttsControlEnabled then
				Spring.Echo(Spring.GetPlayerInfo(myPlayerID_G) .. " ENABLE TTS")
			end		
		end
	end
	return ui_active
end

function widget:GameProgress(serverFrameNum) --this function run 3rd. It read the official serverFrameNumber
	local myGameFrame = myGameFrame_G
	local ui_active = ui_active_G
	-----localize--

	local ttsControlEnabled = CheckTTSwidget()
	local serverFrameNum1 = serverFrameNum
	local frameDistanceToFinish = serverFrameNum1-myGameFrame
	ui_active = ActivateGUI_n_TTS (frameDistanceToFinish, ui_active, ttsControlEnabled)
	
	-----return--
	serverFrameNum1_G = serverFrameNum1
	ui_active_G = ui_active
	gameProgressActive_G = true
end

function widget:Update(dt) --this function run 4th. It update the progressBar
	if ui_active_G then
		oneSecondElapsed_G = oneSecondElapsed_G + dt
		if oneSecondElapsed_G >= 1 then --wait for 1 second period
			-----var localize-----
			local serverFrameNum1 = serverFrameNum1_G
			local serverFrameNum2 = serverFrameNum2_G
			local oneSecondElapsed = oneSecondElapsed_G
			local myLastFrameNum = myLastFrameNum_G
			local serverFrameRate = serverFrameRate_G
			local myGameFrame = myGameFrame_G		
			local simpleMovingAverageLocalSpeed = simpleMovingAverageLocalSpeed_G
			-----localize
			
			local serverFrameNum = serverFrameNum1 or serverFrameNum2 --use FrameNum from GameProgress if available, else use FrameNum derived from LUA_msg.
			serverFrameNum = serverFrameNum + serverFrameRate*oneSecondElapsed -- estimate Server's frame number after each widget:Update() while waiting for GameProgress() to refresh with actual value.
			local frameDistanceToFinish = serverFrameNum-myGameFrame

			local myGameFrameRate = (myGameFrame - myLastFrameNum) / oneSecondElapsed
			--Method1: simple average
			--[[
			averageLocalSpeed_G.sumOfSpeed = averageLocalSpeed_G.sumOfSpeed + myGameFrameRate -- try to calculate the average of local gameFrame speed.
			averageLocalSpeed_G.sumCounter = averageLocalSpeed_G.sumCounter + 1
			myGameFrameRate = averageLocalSpeed_G.sumOfSpeed/averageLocalSpeed_G.sumCounter -- using the average to calculate the estimate for time of completion.
			--]]
			--Method2: simple moving average
			myGameFrameRate = SimpleMovingAverage(myGameFrameRate, simpleMovingAverageLocalSpeed) -- get our average frameRate
			
			local timeToComplete = frameDistanceToFinish/myGameFrameRate -- estimate the time to completion.
			local timeToComplete_string = "?/?"
			
			local minute, second = math.modf(timeToComplete/60) --second divide by 60sec-per-minute, then saperate result from its remainder
			second = 60*second --multiply remainder with 60sec-per-minute to get second back.
			timeToComplete_string = string.format ("Time Remaining: %d:%02d" , minute, second)
		
			progress_vote:SetCaption(timeToComplete_string)
			progress_vote:SetValue(myGameFrame/serverFrameNum)
			
			oneSecondElapsed = 0
			myLastFrameNum = myGameFrame
			
			if serverFrameNum1 then serverFrameNum1 = serverFrameNum --update serverFrameNum1 if value from GameProgress() is used,
			else serverFrameNum2 = serverFrameNum end --update serverFrameNum2 if value from LuaRecvMsg() is used.
			-----return
			serverFrameNum1_G = serverFrameNum1
			serverFrameNum2_G = serverFrameNum2
			oneSecondElapsed_G = oneSecondElapsed
			myLastFrameNum_G = myLastFrameNum
			simpleMovingAverageLocalSpeed_G = simpleMovingAverageLocalSpeed
		end
	end
end

local function RemoveLUARecvMsg(n)
	if n > 150 then
		iAmReplay_G = nil
		spGetSpectatingState = nil --de-reference the function so that garbage collector can clean it up.
		widgetHandler:RemoveCallIn("RecvLuaMsg") --remove unused method for increase efficiency after frame> timestampLimit (150frame or 5 second).
		functionContainer_G = function(x) end --replace this function with an empty function/method
	end 
end

function widget:GameFrame(n)  --this function run at all time. It update current gameFrame
	myGameFrame_G = n
	functionContainer_G(n) --function that are able to remove itself. Reference: gui_take_reminder.lua (widget by EvilZerggin, modified by jK)
end

--//thanks to Rafal[0K] for pointing to the rolling average idea.
function SimpleMovingAverage(myGameFrameRate, simpleMovingAverageLocalSpeed)
	--//remember current frameRate, and advance table index by 1
	local index = (simpleMovingAverageLocalSpeed.index) --retrieve current index.
	simpleMovingAverageLocalSpeed.storage[index] = myGameFrameRate --remember current frameRate at current index.
	simpleMovingAverageLocalSpeed.index = simpleMovingAverageLocalSpeed.index +1 --advance index by 1.
	--//wrap table index around. Create a circle
	local poolingSize = 10 --//number of sample. note: simpleMovingAverage() is executed every second, so the value represent an average spanning 10 second.
	if (simpleMovingAverageLocalSpeed.index == (poolingSize + 2)) then --when table out-of-bound:
		simpleMovingAverageLocalSpeed.index = 1 --wrap the table index around (create a circle of 150 + 1 (ie: poolingSize plus 1 space) entry).
	end
	--//update averages
	index = (simpleMovingAverageLocalSpeed.index) --retrieve an index advanced by 1.
	local oldAverage = (simpleMovingAverageLocalSpeed.storage[index] or defaultAverage_G) --retrieve old average or use initial/default average as old average.
	simpleMovingAverageLocalSpeed.runningAverage = simpleMovingAverageLocalSpeed.runningAverage + myGameFrameRate/poolingSize - oldAverage/poolingSize --calculate average: add new value, remove old value. Ref: http://en.wikipedia.org/wiki/Moving_average#Simple_moving_average
	local avgGameFrameRate = simpleMovingAverageLocalSpeed.runningAverage -- replace myGameFrameRate with its average value.

	return avgGameFrameRate, simpleMovingAverageLocalSpeed
end

function CheckTTSwidget()
	local ttsValue
	--[[
	local widget = widgetHandler:FindWidget("Text To Speech Control") --find widget. Reference: gui_epicmenu.lua by Carrepairer/Wagonrepairer
	if widget then --get all variable from TTS control widget.
		ttsValue = widget.options.enable.value --get the value
	else --If widget is not found, then 'Rejoin Progress widget' will not try to disable/enable TTS. It became neutral.
		ttsValue = false --disable TTS control
	end
	--]]
	if WG.textToSpeechCtrl then
		ttsValue = WG.textToSpeechCtrl.ttsEnable --retrieve Text-To-Speech widget settings from global table.
	else
		ttsValue = false
	end
	return ttsValue
end

----------------------------------------------------------
--Chili--------------------------------------------------
function widget:Initialize()
	functionContainer_G = RemoveLUARecvMsg
	myPlayerID_G = Spring.GetMyPlayerID()
	iAmReplay_G = Spring.IsReplay()

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
	-- local height = tostring(math.floor(screenWidth/screenHeight*0.35*0.35*100)) .. "%"
	-- local y = tostring(math.floor((1-screenWidth/screenHeight*0.35*0.35)*100)) .. "%"
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	local y = screenWidth*2/11 + 32
	-- local labelHeight = 24
	-- local fontSize = 16

	window = Window:New{
		--parent = screen0,
		name   = 'rejoinProgress';
		color = {0, 0, 0, 0},
		width = 260,
		height = 60,
		left = 2, --dock left?
		y = y, --halfway on screen?
		dockable = true,
		draggable = false, --disallow drag to avoid capturing mouse click
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		minWidth = MIN_WIDTH, 
		minHeight = MIN_HEIGHT,
		padding = {0, 0, 0, 0},
		savespace = true, --probably could save space?
		--itemMargin  = {0, 0, 0, 0},
	}
	stack_main = StackPanel:New{
		parent = window,
		resizeItems = true;
		orientation   = "vertical";
		height = "100%";
		width =  "100%";
		padding = {0, 0, 0, 0},
		itemMargin  = {0, 0, 0, 0},
	}
	label_title = Label:New{
		parent = stack_main,
		autosize=false;
		align="center";
		valign="top";
		caption = '';
		height = 16,
		width = "100%";
	}
	--[[
	stack_vote = StackPanel:New{
		parent = stack_main,
		resizeItems = true;
		orientation   = "horizontal";
		y = (40*(1-1))+15 ..'%',
		height = "40%";
		width =  "100%";
		padding = {0, 0, 0, 0},
		itemMargin  = {0, 0, 0, 0},
	}
	--]]
	progress_vote = Progressbar:New{
		parent = stack_main,
		x		= "0%",
		y 		= '40%', --position at 40% of the window's height
		width   = "100%"; --maximum width
		height	= "100%",
		max     = 1;
		caption = "?/?";
		color   =  {0.9,0.15,0.2,1}; --Red, {0.2,0.9,0.3,1} --Green
	}
	progress_vote:SetValue(0)
	voteCount = 0
	voteMax = 1	-- protection against div0
	label_title:SetCaption("Catching up.. Please Wait")
	
	if forceDisplay then
		ActivateGUI_n_TTS (1, false, false, 0) --force GUI to display for testing
		return
	end	
end

----------------------------------------------------------
--fix for Game Progress delay-----------------------------
function widget:RecvLuaMsg(bigMsg, playerID) --this function run 2nd. It read the LUA timestamp
	if forceDisplay then
		ActivateGUI_n_TTS (1, false, false, 0) --force GUI to display for testing
		return
	end
	
	if gameProgressActive_G or iAmReplay_G then --skip LUA message if gameProgress is already active OR game is a replay
		return false 
	end

	local iAmSpec = spGetSpectatingState()
	local myMsg = (playerID == myPlayerID_G)
	if (myMsg or iAmSpec) then
		if bigMsg:sub(1,9) == "rejnProg " then --check for identifier
			-----var localize-----
			local ui_active = ui_active_G
			local submittedTimestamp = submittedTimestamp_G
			local myTimestamp = myTimestamp_G
			-----localize
			
			local timeMsg = bigMsg:sub(10) --saperate time-message from the identifier
			local systemSecond = tonumber(timeMsg)
			--Spring.Echo(systemSecond ..  " B")
			submittedTimestamp[#submittedTimestamp +1] = systemSecond --store all submitted timestamp from each players
			local sumSecond= 0
			for i=1, #submittedTimestamp,1 do
				sumSecond = sumSecond + submittedTimestamp[i]
			end
			--Spring.Echo(sumSecond ..  " C")
			local avgSecond = sumSecond/#submittedTimestamp
			--Spring.Echo(avgSecond ..  " D")
			local secondDiff = myTimestamp - avgSecond
			--Spring.Echo(secondDiff ..  " E")
			local frameDiff = secondDiff*30
			
			local serverFrameNum2 = frameDiff --this value represent the estimate difference in frame when everyone was submitting their timestamp at game start. Therefore the difference in frame will represent how much frame current player are ahead of us.
			local ttsControlEnabled = CheckTTSwidget()
			ui_active = ActivateGUI_n_TTS (frameDiff, ui_active, ttsControlEnabled, 1800)
			
			-----return
			ui_active_G = ui_active
			serverFrameNum2_G = serverFrameNum2
			submittedTimestamp_G = submittedTimestamp
		end
	end
end

function widget:GameStart() --this function run 1st, before any other function. It send LUA timestamp
	--local format = "%H:%M" 
	local currentTime = os.date("!*t") --ie: clock on "gui_epicmenu.lua" (widget by CarRepairer), UTC & format: http://lua-users.org/wiki/OsLibraryTutorial
	local systemSecond = currentTime.hour*3600 + currentTime.min*60 + currentTime.sec
	local myTimestamp = systemSecond
	--Spring.Echo(systemSecond ..  " A")
	local timestampMsg = "rejnProg " .. systemSecond --currentTime --create a timestamp message
	Spring.SendLuaUIMsg(timestampMsg) --this message will remain in server's cache as a LUA message which rejoiner can intercept. Thus allowing the game to leave a clue at game start for latecomer.  The latecomer will compare the previous timestamp with present and deduce the catch-up time.

	------return
	myTimestamp_G = myTimestamp
end
