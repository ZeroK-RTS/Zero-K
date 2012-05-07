function widget:GetInfo()
  return {
    name      = "Chili Rejoining Progress Bar",
    desc      = "v0.9 Show the progress of rejoining and temporarily turn-off Text-To-Speech while rejoining",
    author    = "msafwan (use UI from KingRaptor's Chili-Vote) ",
    date      = "May 7, 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    experimental = false,
    enabled   = true, --  loaded by default?
  }
end

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
local serverFrameNum_G = 0 --//variable: get the latest server's gameFrame from GameProgress() and do work with it.  
local oneSecondElapsed_G = 0 --//variable: a timer for 1 second, used in Update(). Update UI every 1 second.
local localGameFrame_G = 0 --//variable: get latest my gameFrame from GameFrame() and do work with it.
local timeToComplete_G = 0 --//variable: store the estimated time for catching up during rejoining.
local localLastFrameNum_G = 0 --//variable: used to calculate local game-frame rate.
local ui_active_G = false --//variable:indicate whether UI is shown or hidden.
local textToSpeechEnabled = true --//variable: used to properly disable/re-enable TTS when rejoining
--------------------------------------------------------------------------------

if VFS.FileExists("Luaui/Config/ZK_data.lua") then
	local configFile =  VFS.Include("Luaui/Config/ZK_data.lua")
	textToSpeechEnabled = configFile["EPIC Menu"].config.epic_Text_To_Speech_Control_enable
	if textToSpeechEnabled == nil then
		textToSpeechEnabled = true
	end
end

function widget:GameProgress(serverFrameNum) 
	serverFrameNum_G = serverFrameNum
	local frameDistanceToFinish = serverFrameNum_G-localGameFrame_G
	if frameDistanceToFinish >= 120 then
		if not ui_active_G then
			screen0:AddChild(window)
			ui_active_G = true
			if textToSpeechEnabled then
				Spring.Echo(Spring.GetPlayerInfo(Spring.GetMyPlayerID()) .. " DISABLE TTS")
			end
		end
	elseif frameDistanceToFinish < 120 then
		if ui_active_G then
			screen0:RemoveChild(window)
			ui_active_G = false
			if textToSpeechEnabled then
				Spring.Echo(Spring.GetPlayerInfo(Spring.GetMyPlayerID()) .. " ENABLE TTS")
			end		
		end
	end
end

function widget:Update(dt)
	if ui_active_G then
		oneSecondElapsed_G = oneSecondElapsed_G + dt
		if oneSecondElapsed_G >= 1 then
			local localGameFrameRate = localGameFrame_G - localLastFrameNum_G
			serverFrameNum_G = serverFrameRate_G*oneSecondElapsed_G + serverFrameNum_G -- estimate current Server's frame number while waiting for GameProgress() to update.
			local frameDistanceToFinish = serverFrameNum_G-localGameFrame_G
			timeToComplete_G = frameDistanceToFinish/localGameFrameRate -- estimate the time to completion.
			
			voteCount = localGameFrame_G
			voteMax = serverFrameNum_G
			local timeToComplete_string = string.format ("%.1f",timeToComplete_G) .." second left."
			progress_vote:SetCaption(timeToComplete_string)
			progress_vote:SetValue(voteCount/voteMax)
			
			oneSecondElapsed_G = 0
		end
	end
end

function widget:GameFrame(n)
	localGameFrame_G	= n
end
----------------------------------------------------------
--Chili--------------------------------------------------
function widget:Initialize()
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
		name   = 'votes';
		color = {0, 0, 0, 0},
		width = 300;
		height = 120;
		right = 2; 
		y = "45%";
		dockable = false;
		draggable = true,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		minWidth = MIN_WIDTH, 
		minHeight = MIN_HEIGHT,
		padding = {0, 0, 0, 0},
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
	progress_vote = Progressbar:New{
		parent = stack_vote,
		x		= "0%",
		width   = "80%";
		height	= "100%",
		max     = 1;
		caption = "?/?";
		color   = (i == 1 and {0.2,0.9,0.3,1}) or {0.9,0.15,0.2,1};
	}
	progress_vote:SetValue(0)
	voteCount = 0
	voteMax = 1	-- protection against div0
	label_title:SetCaption("Catching up.. Please Wait")
end