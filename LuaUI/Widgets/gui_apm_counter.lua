--[[
v0.1 - develobstered for Zero-K v1.7.3.1
                             ,.---._
                   ,,,,     /       `,
                    \\\\   /    '\_  ;
                     |||| /\/``-.__\;'
                     ::::/\/_
     {{`-.__.-'(`(^^(^^^(^ 9 `.========='
    {{{{{{ { ( ( (  (   (-----:=
     {{.-'~~'-.(,(,,(,,,(__6_.'=========.
                     ::::\/\
                     |||| \/\  ,-'/,
                    ////   \ `` _/ ;
                   ''''     \  `  .'
                             `---'
--]]
function widget:GetInfo()
  return {
    name      = "APM Counter Simple",
    desc      = "counts actions per minute",
    author    = "snoke",
    date      = "2019",
    license   = "GNU GPL v2", -- should be compatible with Spring
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end
--speedups
local GetPlayerStatistics = Spring.GetPlayerStatistics;
local GetGameSeconds = Spring.GetGameSeconds;
local GetSpectatingState = Spring.GetSpectatingState;
local GetLocalPlayerID = Spring.GetLocalPlayerID;
--const
local POS_X = 0;
local POS_Y = 50;
local FONT_SIZE = 15;
local FONT_COLOR = {1, 1, 1, 0.8}
--vars
local actions=0;
local playerId;
local apm=0;
local window;
--loblob
function widget:GameFrame()
	_,_,_,actions,_ = GetPlayerStatistics(playerId);
	apm = actions / (GetGameSeconds()/60) 
	window.children[1]:SetCaption(apm);
end
function widget:Initialize()
	SetSpectatingState();
	window = WG.Chili.Window:New{
		name = "Apm",
		x = POS_X,
		y = POS_Y,
		savespace = true,
		resizable = false,
		draggable = true,
		autosize  = true,
		color     = {0, 0, 0, 0},
		parent = WG.Chili.Screen0,
		children = {
			WG.Chili.Label:New{
				x= FONT_SIZE,
				y = FONT_SIZE,
				align = "center",
				font = {size = FONT_SIZE, outline = true, color = FONT_COLOR},
				caption = "APM:" .. apm,
				fontSize = FONT_SIZE
			}
		}
	};
end
function widget:PlayerChanged ()
	SetSpectatingState();
end

function SetSpectatingState()
	if GetSpectatingState() then
		widgetHandler:RemoveWidget();
	else
		playerId = GetLocalPlayerID();
	end
end
