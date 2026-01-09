--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Rogue-K Rewards",
    desc      = "Select Rogue-K upgrades and prepare for the next battle.",
    author    = "GoogleFrog",
    date      = "9 January 2026",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Chili
local screen0

local modOptions = Spring.GetModOptions() or {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function MakePostgamePanel()
	WG.SetMinimapVisibility(false)
	local black = Chili.Window:New{
		parent = screen0,
		classname = "window_black",
		name = "RogueRewards",
		caption = "",
		color = {0, 0, 0, 0.7}, -- Transparent for debug
		x = 0,
		y = 0,
		right  = 0,
		bottom = 0,
		draggable = false,
		resizable = false,
	}
	local window = Chili.Window:New{
		parent = black,
		classname = "main_window_opaque",
		name = "RogueRewards",
		caption = "",
		x = '16%',
		y = '10%',
		right  = '16%',
		bottom = '10%',
		minWidth  = 500,
		minHeight = 400,
		draggable = false,
		resizable = false,
	}
	
	local topPanel = Chili.Control:New{
		parent = window,
		x = 0,
		y = 0,
		right  = 0,
		bottom = '34%',
	}
	local bottomPanel = Chili.Control:New{
		parent = window,
		x = 0,
		y = '66%',
		right  = 0,
		bottom = 0,
	}
	
	local rewardListPanel = Chili.ScrollPanel:New {
		parent = Chili.Control:New{
			parent = topPanel,
			x = 0,
			y = 0,
			right = '72%',
			bottom = 0,
			padding = {10, 10, 10, 10},
		},
		x = 0,
		right = 0,
		y = 0,
		bottom = 0,
	}
	local mainDisplay = Chili.ScrollPanel:New {
		parent = Chili.Control:New{
			parent = topPanel,
			x = '28%',
			y = 0,
			right = 0,
			bottom = 0,
			padding = {10, 10, 10, 10},
		},
		x = 0,
		right = 0,
		y = 0,
		bottom = 0,
	}
	local loadoutPanel = Chili.ScrollPanel:New {
		parent = Chili.Control:New{
			parent = bottomPanel,
			x = 0,
			y = 0,
			right = 0,
			bottom = 0,
			padding = {10, 0, 10, 10},
		},
		x = 0,
		right = 0,
		y = 0,
		bottom = 0,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	if tonumber(modOptions.rk_enabled or 0) ~= 1 then
		widgetHandler:RemoveWidget()
		return
	end
	Chili = WG.Chili
	screen0 = Chili.Screen0
	if (not Chili) then
		widgetHandler:RemoveWidget()
		return
	end
	
	if tonumber(modOptions.rk_post_game_only or 0) == 1 then
		MakePostgamePanel()
	end
end
