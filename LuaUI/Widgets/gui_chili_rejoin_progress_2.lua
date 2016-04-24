function widget:GetInfo()
  return {
    name      = "Chili Rejoining Progress Bar 2",
    desc      = "v1.132 Show the progress of rejoining and temporarily turn-off Text-To-Speech while rejoining",
    author    = "msafwan (use UI from KingRaptor's Chili-Vote) ",
    date      = "Oct 10, 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    experimental = false,
    enabled   = false,
  }
end

if Spring.IsReplay() then return end

local screen0

local window, label_title, progress_bar

local localFrame = 0
local serverFrame = 1
local avgFrameRate = 100
local previousFramesLeft = 0
local running = false

function widget:GameProgress (n) -- happens every 10s
	serverFrame = n
end
function widget:GameFrame (n)
	localFrame = n
end

function widget:GameStart()
	running = true
end

local t = 0
function widget:Update (dt)
	t = t + dt
	if t < 1 then return end
	t = t - 1

	if running then
		serverFrame = serverFrame + 30
	end

	local framesLeft = serverFrame - localFrame

	if (framesLeft > 150) then
		if not active then
			screen0:AddChild (window)
			active = true
		end
	else
		if active then
			screen0:RemoveChild (window)
			active = false
		end
	end

	local frameRate = previousFramesLeft - framesLeft
	if (frameRate > -100) then
		avgFrameRate = avgFrameRate * 0.7 + frameRate * 0.3
	end

	previousFramesLeft = framesLeft
	if (framesLeft < 150) then return end

	local minute, second = math.modf(serverFrame / (30*60))
	progress_bar:SetCaption(string.format ("Server time: %d:%02d", minute, second*60))
	progress_bar:SetValue(localFrame / serverFrame)

	if (avgFrameRate < 0) then
		label_title:SetCaption("Performance too low, will never catch up")
	else
		local eta = framesLeft / avgFrameRate
		minute, second = math.modf(eta / 60)
		label_title:SetCaption(string.format ("Catching up, ETA: %d:%02d", minute, second*60))
	end
end

function widget:Initialize()

	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	local y = screenWidth*2/11 + 32

	screen0 = WG.Chili.Screen0

	window = WG.Chili.Window:New{
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

