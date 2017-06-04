--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili SpecPanel - Next Gen",
    desc      = "Displays team information while spectating.",
    author    = "GoogleFrog, CrazyEddie",
    date      = "3 June 2017",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false
  }
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- TODO:
--
--	- Logic to enable/disable when appropriate (speccing and not FFA)
--	- Hotkeyable option to enable and disable
--	- Handle widget:PlayerChanged
--	- Colourblind option
--	- Fancy skinning option? Learn about skins and fancyskins
--	- Handle interactions with (hiding) the standard econ bars
--
--	- Hook up to actual data
--	- Get team names and other team data
--	- Add wins data
--	- Add tooltips to everything.
--		"What do you mean, everything?"
--		"EEEEEVVVERYTHIIIING!!!!!!"
--	- Add context menu / ShowOptions on meta-click
--	- Make it tweakable and dockable? Nah, design decision.
--		It's top center and you can't change that.
--		Don't like it? Don't use it!
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("colors.h.lua")
VFS.Include("LuaRules/Configs/constants.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local echo = Spring.Echo
local Chili
local screen0

local specPanel

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Options Functions

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Options

options_path = 'Settings/HUD Panels/Spectator Panels'

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Update Panel Data

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Create Panels

local function CreateSpecPanel()
	local data = {}
	
	local screenWidth,screenHeight = Spring.GetWindowGeometry()
	local screenHorizCentre = screenWidth / 2
	local windowWidth = 1000

	data.window = Chili.Window:New{
		backgroundColor = {0.2, 0.2, 0.2, 0.2},
		color = {0.7, 0.7, 0, 0},
		name = "SpecPanel",
		padding = {0,0,0,0},
		x = screenHorizCentre - windowWidth/2,
		y = 0,
		clientWidth  = windowWidth,
		clientHeight = 500,
		draggable = false,
		resizable = false,
		minimizable = false,
	}
	
	data.clockpanel = Chili.Panel:New{
		parent = data.window,
		x = 450,
		width = 100,
		height = 50,
	}
	data.clocklabel = Chili.Label:New{
		parent = data.clockpanel,
		caption = "12:34",
		width = '100%',
		height = '100%',
		align = 'center',
		valign = 'center',
	}

	data.balancepanel = Chili.Panel:New{
		parent = data.window,
		padding = {0,0,0,0},
		x = 400,
		y = 50,
		width = 200,
		height = 250,
	}
	
	local balanceheight = 30
	local balancelabelheight = 15
	
	local balancebars = {
		{ name = "Income", value = 22 },
		{ name = "Extraction", value = 44 },
		{ name = "Military", value = 55 },
		{ name = "Attrition", value = 77 },
	}
	data.balancebars = {}
	for i,bar in ipairs(balancebars) do
		data.balancebars[i] = {}
		data.balancebars[i].label = Chili.Label:New{
			parent = data.balancepanel,
			y = balanceheight * (i-1),
			width = '100%',
			height = 15,
			caption = bar.name,
			align = 'center',
		}
		data.balancebars[i].bar = Chili.Progressbar:New{
			parent = data.balancepanel,
			orientation = 'horizontal',
			value = bar.value,
			x = 50,
			y = balanceheight * (i-1) + balancelabelheight,
			width = 100,
			height = 15,
			color = {0,0,1,1},
			backgroundColor = {1,0,0,0},
		}
		data.balancebars[i].bar_bg = Chili.Progressbar:New{
			parent = data.balancepanel,
			orientation = 'horizontal',
			value = 100,
			x = 50,
			y = balanceheight * (i-1) + balancelabelheight,
			width = 100,
			height = 15,
			color = {1,0,0,1},
		}
	end


	return data
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Call-ins

function widget:Shutdown()
end

function widget:Initialize()
	Chili = WG.Chili
	screen0 = Chili.Screen0
	
	if (not Chili) then
		widgetHandler:RemoveWidget()
		return
	end
	
	-- if we should show the panel then
		specPanel = CreateSpecPanel()
		if specPanel and specPanel.window then
			screen0:AddChild(specPanel.window)
		end
	-- end
end

local timer = 0
function widget:Update(dt)
	timer = timer + dt
	-- Update the resource bar flashing status and graphics
	if timer >= 1 then
		-- Update the time
		-- Update the wins counters
		timer = 0
	end
end

function widget:GameFrame(n)
	if n%TEAM_SLOWUPDATE_RATE == 0 then
		-- Update the resources
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
