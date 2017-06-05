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
--	- Skin the panels, including background image
--	- Put a nice frame around the unitpics, like the selections widget uses
--	- Deal with padding in all the objects
--	- Consistentize capitalization of parameters
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

local col_metal = {136/255,214/255,251/255,1}
local col_energy = {.93,.93,0,1}

-- hardcoding these for now, will add colourblind options later
local positiveColourStr = GreenStr
local negativeColourStr = RedStr

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Options Functions

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Options

options_path = 'Settings/HUD Panels/Spectator Panels'


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function Format(input, override)

	-- Leaving out the sign to save space
	-- For this panel, the direction is always implied
	-- and will still be colorcoded when needed
	--
	-- local leadingString = positiveColourStr .. "+"
	local leadingString = positiveColourStr
	if input < 0 then
		-- leadingString = negativeColourStr .. "-"
		leadingString = negativeColourStr
	end
	leadingString = override or leadingString
	input = math.abs(input)
	
	if input < 0.05 then
		if override then
			return override .. "0.0"
		end
		return WhiteStr .. "0"
	elseif input < 10 - 0.05 then
		return leadingString .. ("%.1f"):format(input) .. WhiteStr
	elseif input < 10^3 - 0.5 then
		return leadingString .. ("%.0f"):format(input) .. WhiteStr
	elseif input < 10^4 then
		return leadingString .. ("%.1f"):format(input/1000) .. "k" .. WhiteStr
	elseif input < 10^5 then
		return leadingString .. ("%.0f"):format(input/1000) .. "k" .. WhiteStr
	else
		return leadingString .. ("%.0f"):format(input/1000) .. "k" .. WhiteStr
	end
end

local function GetTimeString()
  local secs = math.floor(Spring.GetGameSeconds())
  if (timeSecs ~= secs) then
    timeSecs = secs
    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    local s = math.floor(secs % 60)
    if (h > 0) then
      timeString = string.format('%02i:%02i:%02i', h, m, s)
    else
      timeString = string.format('%02i:%02i', m, s)
    end
  end
  return timeString
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Update Panel Data

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Create Panels

local function CreateSpecPanel()
	local data = {}
	
	local topcenterwidth = 200
	local balancepanelwidth = 80

	local balancelabelheight = 20
	local balancebarheight = 10
	local balanceheight = balancelabelheight + balancebarheight
	local balancepanelheight = balanceheight * 4 + 5

	local rowheight = 30
	local topheight = rowheight * 1.5
	local picsize = rowheight * 1.8

	local unitpanelwidth = 150
	local resourcebarwidth = 100
	local resourcestatpanelwidth = 200
	local resourcepanelwidth = resourcestatpanelwidth + resourcebarwidth
	local compics = 1
	local unitpics = 5
	
	local screenWidth,screenHeight = Spring.GetWindowGeometry()
	local screenHorizCentre = screenWidth / 2
	local windowWidth = (resourcepanelwidth + unitpanelwidth) * 2 + balancepanelwidth + 24
	local windowheight = topheight + balancepanelheight
	local playerlabelwidth = (windowWidth - topcenterwidth) / 2
	
	
	data.window = Chili.Panel:New{
		classname = 'main_window',
		parent = data.superwindow,
		name = "SpecPanel",
		padding = {0,0,0,0},
		x = screenHorizCentre - windowWidth/2,
		y = 0,
		clientWidth  = windowWidth,
		clientHeight = windowheight,
	}
	
	data.topcenterpanel = Chili.Panel:New{
		parent = data.window,
		classname = 'main_window_small',
		padding = {5,5,5,5},
		x = (windowWidth - topcenterwidth)/2,
		width = topcenterwidth,
		height = topheight,
		dockable = false;
		draggable = false,
		resizable = false,
	}
	data.clocklabel = Chili.Label:New{
		parent = data.topcenterpanel,
		padding = {0,0,0,0},
		width = '100%',
		height = '100%',
		align = 'center',
		valign = 'center',
		fontsize = 24,
		textColor = {0.95, 1.0, 1.0, 1},
		caption = GetTimeString(),
	}
	data.winslabel_top = Chili.Label:New{
		parent = data.topcenterpanel,
		padding = {0,0,0,0},
		y = '5%',
		width = 50,
		height = '30%',
		align = 'center',
		valign = 'center',
		caption = "Wins:",
	}
	data.winslabel_bottom = Chili.Label:New{
		parent = data.topcenterpanel,
		padding = {0,0,0,0},
		x = 0,
		y = '30%',
		width = 50,
		height = '70%',
		align = 'center',
		valign = 'center',
		fontsize = 20,
		textColor = {0.5,0.5,1,1},
		caption = "2",
	}

	data.balancepanel = Chili.Panel:New{
		parent = data.window,
		classname = 'main_window_small',
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
			color = {0.5,0.5,1,1},
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
		textColor = {0.5,0.5,1,1},
		fontsize = 28,
		fontShadow = true,
		fontOutline = false,
		caption = "West",
	}
	
	local resource_stats = {
		{
			total = 155,
			bar = 25,
			icon = 'LuaUI/Images/ibeam.png',
			color = col_metal,
			{ name = "Extraction", value = 100, label = "E", label_x = 65, },
			{ name = "Reclaim", value = 15, label = "R", label_x = 110, },
			{ name = "Overdrive", value = 20, label = "O", label_x = 150, },
		},
		{
			total = 1955,
			bar = 66,
			icon = 'LuaUI/Images/energy.png',
			color = col_energy,
			{ name = "Generation", value = 1234, label = "G", label_x = 65, },
			{ name = "Reclaim", value = 133, label = "R", label_x = 110, },
			{ name = "Overdrive", value = 543, label = "O", label_x = 150, },
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
			skin = nil,
			skinName = 'default',
			backgroundColor = {0,0,0,0},
			borderColor = {1,1,1,1},
			borderThickness = 1,
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
			color = resource_stats[i].color,
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
		data.resource_stats[i].total = Chili.Label:New{
			parent = data.resource_stats[i].statpanel,
			x = 18,
			height = '100%',
			width = 20,
			valign = 'center',
			fontsize = 20,
			textColor = resource_stats[i].color,
			caption = Format(resource_stats[i].total, ""),
		}
		data.resource_stats[i].icon = Chili.Image:New{
			parent = data.resource_stats[i].statpanel,
			x = 0,
			height = 18,
			width = 18,
			file = resource_stats[i].icon,
		}
		data.resource_stats[i].labels = {}
		for j,stat in ipairs(resource_stats[i]) do
			data.resource_stats[i].labels[j] = Chili.Label:New{
				parent = data.resource_stats[i].statpanel,
				x = resource_stats[i][j].label_x,
				height = '100%',
				width = 20,
				valign = 'center',
				textColor = resource_stats[i].color,
				caption = resource_stats[i][j].label .. ":" .. Format(resource_stats[i][j].value, ""),
			}
		end
	end
	
	data.unitpanel = Chili.Panel:New{
		parent = data.window,
		y = topheight,
		right = (windowWidth + balancepanelwidth)/2,
		height = rowheight * 2,
		width = unitpanelwidth,
		skin = nil,
		skinName = 'default',
		backgroundColor = {0,0,0,0},
		borderColor = {1,1,1,1},
		borderThickness = 1,
	}
	local unit_stats = {
		total = 25379,
		{ name = "Offense", value = 1500, icon = 'LuaUI/Images/commands/Bold/attack.png', icon_x = 0, },
		{ name = "Defense", value = 5000, icon = 'LuaUI/Images/commands/Bold/guard.png', icon_x = 50, },
		{ name = "Economy", value = 12550, icon = 'LuaUI/Images/energy.png', icon_x = 100, },
	}
	data.unit_stats = {}
	data.unit_stats.total = Chili.Label:New{
		parent = data.unitpanel,
		x = 0,
		height = '50%',
		width = '100%',
		align = 'center',
		valign = 'center',
		fontsize = 16,
		textColor = { 0.85, 0.85, 0.85, 1.0 },
		caption = "Unit Value: " .. Format(unit_stats.total, ""),
	}
	for i,stat in ipairs(unit_stats) do
		data.unit_stats[i] = {}
		data.unit_stats[i].icon = Chili.Image:New{
			parent = data.unitpanel,
			x = unit_stats[i].icon_x,
			y = '60%',
			height = 18,
			width = 18,
			file = unit_stats[i].icon,
		}
		data.unit_stats[i].label = Chili.Label:New{
			parent = data.unitpanel,
			x = unit_stats[i].icon_x + 18,
			y = '50%',
			height = '50%',
			width = 20,
			valign = 'center',
			textColor = { 0.7, 0.7, 0.7, 1.0 },
			caption = Format(unit_stats[i].value, ""),
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
			y = topheight + rowheight * 2 + 5,
			right = (windowWidth + balancepanelwidth)/2 + picsize * (i-1) + 5,
			height = picsize - 10,
			width = picsize - 10,
			align = 'right',
			valign = 'bottom',
			fontsize = 16,
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
		local framepic
		if i == 1 then
			framepic = 'bitmaps/icons/frame_cons.png'
		else
			framepic = 'bitmaps/icons/frame_unit.png'
		end
		data.unitpics[i].unitpicframe = Chili.Image:New{
			parent = data.window,
			y = topheight + rowheight * 2,
			right = (windowWidth + balancepanelwidth)/2 + picsize * (i-1),
			height = picsize,
			width = picsize,
			keepAspect = false,
			file = framepic,
		}
	end
	
	local compics_mock = {
		{ name = "commassault", value = "Lvl 6" },
		{ name = "commstrike", value = "Lvl 4" },
		{ name = "commrecon", value = "2 more" },
	}
	data.compics = {}
	for i = 1,compics do
		data.compics[i] = {}
		data.compics[i].text = Chili.Label:New{
			parent = data.window,
			y = topheight + rowheight * 2 + 5,
			right = (windowWidth + balancepanelwidth)/2 + picsize * (compics - i) + picsize * unitpics +5,
			height = picsize - 10,
			width = picsize - 10,
			align = 'right',
			valign = 'bottom',
			caption = compics_mock[i].value,
		}
		data.compics[i].unitpic = Chili.Image:New{
			parent = data.window,
			y = topheight + rowheight * 2,
			right = (windowWidth + balancepanelwidth)/2 + picsize * (compics - i) + picsize * unitpics,
			height = picsize,
			width = picsize,
			file = 'unitpics/' .. compics_mock[i].name .. '.png',
		}
		local framepic = 'bitmaps/icons/frame_unit.png'
		data.compics[i].unitpicframe = Chili.Image:New{
			parent = data.window,
			y = topheight + rowheight * 2,
			right = (windowWidth + balancepanelwidth)/2 + picsize * (compics - i) + picsize * unitpics,
			height = picsize,
			width = picsize,
			keepAspect = false,
			file = framepic,
		}
	end
	
	data.bg_top = Chili.Panel:New{
		parent = data.window,
		x = 12,
		y = 0,
		width  = (windowWidth - 24) / 2,
		height = topheight,
		skin = nil,
		skinName = 'default',
		backgroundColor = {0,0,0,0.3},
		borderColor = {0,0,0,0},
	}
	data.bg_bottom = Chili.Panel:New{
		parent = data.window,
		x = 12,
		y = topheight,
		width  = (windowWidth - 24) / 2,
		height = windowheight - topheight,
		skin = nil,
		skinName = 'default',
		backgroundColor = {0,0,0,0.5},
		borderColor = {0,0,0,0},
	}
	data.bg_image = Chili.Image:New{
		parent = data.window,
		x = 12,
		y = 7,
		width  = (windowWidth - 24) / 2,
		height = windowheight - 14,
		keepAspect = false,
		file = 'LuaUI/Images/specpanel_ng/bg_mock3.png',
	}
	data.bg_image_right_temp = Chili.Image:New{
		parent = data.window,
		right = 12,
		y = 7,
		width  = (windowWidth - 24) / 2,
		height = windowheight - 14,
		keepAspect = false,
		file = 'LuaUI/Images/specpanel_ng/bg_mock2.png',
	}

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
