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
--	- Finalize the layout
--	- Consistentize capitalization of parameters
--	- Skin the panels, including background image
--	- Put a nice frame around the unitpics, like the selections widget uses
--	- Deal with padding in all the objects
--	- Parameterize the colors
--		- Balance Bar colors, including writing a function to attenuate them
--	- Mirror the player panels
--		- Write functions to draw panels forwards or backwards
--		- .. which requires parameterizing all the panels for direction
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
--	- Consider making small / medium / large versions
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
	
	local topcenterwidth = 200
	local balancepanelwidth = 100

	local balancelabelheight = 20
	local balancebarheight = 10
	local balanceheight = balancelabelheight + balancebarheight
	local balancepanelheight = balanceheight * 4 + 5

	local rowheight = 30
	local topheight = rowheight * 1.5
	local picsize = rowheight * 1.8

	local playerlabelwidth = 300
	local unitpanelwidth = 150
	local resourcebarwidth = 100
	local resourcestatpanelwidth = 200
	local resourcepanelwidth = resourcestatpanelwidth + resourcebarwidth
	local compics = 3
	local unitpics = 5
	
	local screenWidth,screenHeight = Spring.GetWindowGeometry()
	local screenHorizCentre = screenWidth / 2
	local windowWidth = (resourcepanelwidth + unitpanelwidth) * 2 + balancepanelwidth
	local windowheight = topheight + balancepanelheight

	data.window = Chili.Panel:New{
		backgroundColor = {0.2, 0.2, 0.2, 0.2},
		color = {0.7, 0.7, 0, 0},
		name = "SpecPanel",
		padding = {0,0,0,0},
		x = screenHorizCentre - windowWidth/2,
		y = 0,
		clientWidth  = windowWidth,
		clientHeight = windowheight,
		draggable = false,
		resizable = false,
		minimizable = false,
	}
	
	data.topcenterpanel = Chili.Panel:New{
		parent = data.window,
		padding = {0,0,0,0},
		x = (windowWidth - topcenterwidth)/2,
		width = topcenterwidth,
		height = topheight,
	}
	data.clocklabel = Chili.Label:New{
		parent = data.topcenterpanel,
		padding = {0,0,0,0},
		width = '100%',
		height = '100%',
		align = 'center',
		valign = 'center',
		caption = "12:34",
	}
	data.winslabel_top = Chili.Label:New{
		parent = data.topcenterpanel,
		padding = {0,0,0,0},
		x = 0,
		width = 100,
		height = '40%',
		align = 'center',
		valign = 'center',
		caption = "Wins:",
	}
	data.winslabel_bottom = Chili.Label:New{
		parent = data.topcenterpanel,
		padding = {0,0,0,0},
		x = 0,
		y = '40%',
		width = 100,
		height = '60%',
		align = 'center',
		valign = 'center',
		caption = "2",
	}

	data.balancepanel = Chili.Panel:New{
		parent = data.window,
		padding = {0,0,0,0},
		x = (windowWidth - balancepanelwidth)/2,
		y = topheight,
		width = balancepanelwidth,
		height = balancepanelheight,
	}
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
			y = balanceheight * (i-1) + 4,
			width = '100%',
			height = 15,
			caption = bar.name,
			align = 'center',
		}
		data.balancebars[i].bar = Chili.Progressbar:New{
			parent = data.balancepanel,
			orientation = 'horizontal',
			value = bar.value,
			x = '20%',
			y = balanceheight * (i-1) + balancelabelheight,
			width = '60%',
			height = balancebarheight,
			color = {0,0,1,1},
			backgroundColor = {1,0,0,0},
		}
		data.balancebars[i].bar_bg = Chili.Progressbar:New{
			parent = data.balancepanel,
			orientation = 'horizontal',
			value = 100,
			x = '20%',
			y = balanceheight * (i-1) + balancelabelheight,
			width = '60%',
			height = balancebarheight,
			color = {1,0,0,1},
		}
	end

	
	data.playerlabel = Chili.Label:New{
		parent = data.window,
		padding = {0,0,0,0},
		right = (windowWidth + topcenterwidth)/2,
		width = playerlabelwidth,
		height = topheight,
		align = 'center',
		valign = 'center',
		caption = "West - 2 Players",
	}

--[[
	data.resourcepanel = Chili.Panel:New{
		parent = data.window,
		padding = {0,0,0,0},
		y = topheight,
		right = (windowWidth + balancepanelwidth)/2 + unitpanelwidth,
		width = resourcepanelwidth,
		height = rowheight * 2,
	}
	data.metalbar = Chili.Progressbar:New{
		parent = data.resourcepanel,
		x = '10%',
		y = '10%',
		height = '35%',
		right = '10%',
		value = 25,
	}
	data.energybar = Chili.Progressbar:New{
		parent = data.resourcepanel,
		x = '10%',
		y = '55%',
		height = '35%',
		right = '10%',
		value = 55,
	}
--]]
	
	local resource_stats = {
		{
			total = 155,
			bar = 25,
			{ name = "Mex", value = 100 },
			{ name = "Re", value = 15 },
			{ name = "OD", value = 20 },
		},
		{
			total = 195,
			bar = 66,
			{ name = "Gen", value = 123 },
			{ name = "Re", value = 33 },
			{ name = "OD", value = 43 },
		},
	}
	data.resource_stats = {}
	for i,resource in ipairs(resource_stats) do
		data.resource_stats[i] = {}
		data.resource_stats[i].panel = Chili.Panel:New{
			parent = data.window,
			y = topheight + rowheight * (i-1),
			right = (windowWidth + balancepanelwidth)/2 + unitpanelwidth,
			width = resourcepanelwidth,
			height = rowheight,
		}
		data.resource_stats[i].barpanel = Chili.Control:New{
			parent = data.resource_stats[i].panel,
			padding = {0,0,0,0},
			y = 0,
			right = 0,
			width = resourcebarwidth,
			height = '100%',
		}
		data.resource_stats[i].bar = Chili.Progressbar:New{
			parent = data.resource_stats[i].barpanel,
			padding = {0,0,0,0},
			x = '5%',
			y = '10%',
			height = '80%',
			right = '0%',
			value = resource_stats[i].bar,
		}
		data.resource_stats[i].statpanel = Chili.Control:New{
			parent = data.resource_stats[i].panel,
			padding = {0,0,0,0},
			x = 0,
			y = 0,
			width = resourcestatpanelwidth,
			height = '100%',
		}
		data.resource_stats[i].labels = {}
		data.resource_stats[i].labels.total = Chili.Label:New{
			parent = data.resource_stats[i].statpanel,
			x = 0,
			height = '100%',
			width = 20,
			valign = 'center',
			caption = resource_stats[i].total,
		}
		for j,stat in ipairs(resource_stats[i]) do
			data.resource_stats[i].labels[j] = Chili.Label:New{
				parent = data.resource_stats[i].statpanel,
				x = (25 * j) .. '%',
				height = '100%',
				width = 20,
				valign = 'center',
				caption = resource_stats[i][j].name .. ": " .. resource_stats[i][j].value,
			}
		end
	end
	
	data.unitpanel = Chili.Panel:New{
		parent = data.window,
		y = topheight,
		right = (windowWidth + balancepanelwidth)/2,
		height = rowheight * 2,
		width = unitpanelwidth,
	}
	local unit_stats = {
		total = 2500,
		{ name = "O", value = 1500 },
		{ name = "D", value = 500 },
		{ name = "E", value = 250 },
	}
	data.unit_stats = {}
	data.unit_stats.total = Chili.Label:New{
		parent = data.unitpanel,
		x = 0,
		height = '50%',
		width = '100%',
		align = 'center',
		valign = 'center',
		caption = "Unit Value: " .. unit_stats.total,
	}
	for i,stat in ipairs(unit_stats) do
		data.unit_stats[i] = Chili.Label:New{
			parent = data.unitpanel,
			x = (33 * (i-1)) .. '%',
			y = '50%',
			height = '50%',
			width = 20,
			valign = 'center',
			caption = unit_stats[i].name .. ": " .. unit_stats[i].value,
		}
	end
	
	local unitpics_mock = {
		{ name = "cloakcon", value = "2" },
		{ name = "cloakraid", value = "18" },
		{ name = "cloakriot", value = "3" },
		{ name = "cloakskirm", value = "10" },
		{ name = "cloakassault", value = "7" },
	}
	data.unitpics = {}
	for i = 1,unitpics do
		data.unitpics[i] = {}
		data.unitpics[i].text = Chili.Label:New{
			parent = data.window,
			y = topheight + rowheight * 2,
			right = (windowWidth + balancepanelwidth)/2 + picsize * (i-1),
			height = picsize,
			width = picsize,
			align = 'right',
			valign = 'bottom',
			caption = unitpics_mock[i].value,
		}
		data.unitpics[i].unitpic = Chili.Image:New{
			parent = data.window,
			y = topheight + rowheight * 2,
			right = (windowWidth + balancepanelwidth)/2 + picsize * (i-1),
			height = picsize,
			width = picsize,
			file = 'unitpics/' .. unitpics_mock[i].name .. '.png',
		}
	end
	
	local compics_mock = {
		{ name = "commassault", value = "Lvl 6" },
		{ name = "commstrike", value = "Lvl 4" },
		{ name = "commrecon", value = "+2 more" },
	}
	data.compics = {}
	for i = 1,compics do
		data.compics[i] = {}
		data.compics[i].text = Chili.Label:New{
			parent = data.window,
			y = topheight + rowheight * 2,
			right = (windowWidth + balancepanelwidth)/2 + picsize * (i-1) + picsize * unitpics,
			height = picsize,
			width = picsize,
			align = 'right',
			valign = 'bottom',
			caption = compics_mock[i].value,
		}
		data.compics[i].unitpic = Chili.Image:New{
			parent = data.window,
			y = topheight + rowheight * 2,
			right = (windowWidth + balancepanelwidth)/2 + picsize * (i-1) + picsize * unitpics,
			height = picsize,
			width = picsize,
			file = 'unitpics/' .. compics_mock[i].name .. '.png',
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
