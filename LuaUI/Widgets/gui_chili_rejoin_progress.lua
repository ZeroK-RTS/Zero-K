function widget:GetInfo()
  return {
    name      = "Chili Rejoining Progress Bar",
    desc      = "v1.132 Show the progress of rejoining and temporarily turn-off Text-To-Speech while rejoining",
    author    = "msafwan (use UI from KingRaptor's Chili-Vote) ",
    date      = "Oct 10, 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,
  }
end

if Spring.IsReplay() then return end

local gameSpeed = Game.gameSpeed

local CATCH_UP_THRESHOLD = 10 * gameSpeed -- only show the window if behind this much
local UPDATE_RATE_F = 10 -- frames
local MOVING_AVG_COUNT = 30 -- update periods

local UPDATE_RATE_S = UPDATE_RATE_F / gameSpeed

local screen0, window, label_title, progress_bar

local localFrame = Spring.GetGameFrame()
local serverFrame
local previousFramesLeft
local running = (localFrame > 0)

local movingAvg = {}
for i = 1, MOVING_AVG_COUNT do
	movingAvg[i] = 0
end
local movingAvgTotal = 0
local movingAvgIndex = 1

function widget:GameProgress (n) -- happens every 300 frames
	if not serverFrame then
		previousFramesLeft = n - localFrame
	end
	serverFrame = n
end

local spGetGameSpeed = Spring.GetGameSpeed
local function EstimateServerFrame()
	local speedFactor, _, isPaused = spGetGameSpeed()
	if running and not isPaused then
		serverFrame = serverFrame + math.ceil(speedFactor * UPDATE_RATE_F)
	end
end

function widget:GameFrame (n)
	localFrame = n
end

function widget:GameStart()
	running = true
end

function widget:GameOver()
	widgetHandler:RemoveCallIn("Update")
end

local function ParseFrameTime(frames)
	local secs = math.floor(frames / gameSpeed)
	local h = math.floor(secs / 3600)
	local m = math.floor((secs % 3600) / 60)
	local s = secs % 60
	if (h > 0) then
		return string.format('%02i:%02i:%02i', h, m, s)
	else
		return string.format('%02i:%02i', m, s)
	end
end

local t = UPDATE_RATE_S
function widget:Update (dt)
	if not serverFrame then
		return
	end

	t = t - dt
	if t > 0 then
		return
	end
	t = t + UPDATE_RATE_S

	EstimateServerFrame()

	local framesLeft = serverFrame - localFrame

	if framesLeft > CATCH_UP_THRESHOLD then
		if not active then
			screen0:AddChild (window)
			if WG.TextToSpeech then
				WG.TextToSpeech.SetEnabled(false)
			end
			active = true
		end
	else
		if active then
			screen0:RemoveChild (window)
			if WG.TextToSpeech then
				WG.TextToSpeech.SetEnabled(true)
			end
			active = false
		end
		return
	end

	local currentCatchUpRate = previousFramesLeft - framesLeft
	previousFramesLeft = framesLeft
	
	movingAvgTotal = movingAvgTotal - movingAvg[movingAvgIndex] + currentCatchUpRate
	movingAvg[movingAvgIndex] = currentCatchUpRate
	movingAvgIndex = (movingAvgIndex % MOVING_AVG_COUNT) + 1

	progress_bar:SetCaption("The server is " .. ParseFrameTime(framesLeft) .. " ahead, at " .. ParseFrameTime(serverFrame))
	progress_bar:SetValue(localFrame / serverFrame)

	if movingAvgTotal > 0 then
		local avgCatchupRatePerPeriod = movingAvgTotal / MOVING_AVG_COUNT
		local avgCatchupRatePerFrame = avgCatchupRatePerPeriod / UPDATE_RATE_F
		local etaFrames = framesLeft / avgCatchupRatePerFrame
		label_title:SetCaption("Catching up, ETA: " .. ParseFrameTime(etaFrames))
	else
		label_title:SetCaption("Catching up, ETA: unknown")
	end
end

function widget:Initialize()

	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	local y = screenWidth*2/11 + 32

	screen0 = WG.Chili.Screen0

	window = WG.Chili.Window:New{
		name   = 'rejoinProgress';
		color = {0, 0, 0, 0},
		width = 280,
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
	local stack_main = WG.Chili.StackPanel:New{
		parent = window,
		resizeItems = true;
		orientation   = "vertical";
		height = "100%";
		width =  "100%";
		padding = {0, 0, 0, 0},
		itemMargin  = {0, 0, 0, 0},
	}
	label_title = WG.Chili.Label:New{
		parent = stack_main,
		autosize=false;
		align="center";
		valign="top";
		caption = '';
		height = 16,
		width = "100%";
	}

	progress_bar = WG.Chili.Progressbar:New{
		parent = stack_main,
		x		= "0%",
		y 		= '40%', --position at 40% of the window's height
		width   = "100%"; --maximum width
		height	= "100%",
		max     = 1;
		caption = "?/?";
		color   =  {0.9,0.15,0.2,1}; --Red, {0.2,0.9,0.3,1} --Green
	}

	progress_bar:SetValue(0)
	label_title:SetCaption("Catching up...")
end

