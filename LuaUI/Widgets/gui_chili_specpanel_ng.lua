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
--	- Run a multi-player game and get some actual stats to plug in, for fun
--
--	- Tweak everything, esp. anything that has asymmetry
--		- Decide where I want mirroring and where I want asymmetry
--	- Rearrange bounds in this order: x,r,w,y,b,h
--	- Rewrite the bounds to be the simplest possible
--		- ... and make sure that there's explicitly exactly two in each dimension
--	- Make the unitpic frames and labels children of the pic, to make it simpler
--		- Look for other objects that can be nested that way that aren't already
--	- Rearrange all other object parameters into a consistent and pleasing order
--	- Consistentize capitalization of parameters
--	- Parameterize the colors
--		- Balance Bar colors, including writing a function to attenuate them
--	- Deal with padding in all the objects (??)
--
--	- Revise the balance bars:
--		- Make them multibars, stacked on top of each other
--		- Set the leader to 100%
--		- Set the lagger whatever percentage they are of the leader
--
--	- Logic to enable/disable when appropriate (speccing and not FFA)
--	- Hotkeyable option to enable and disable
--	- Handle widget:PlayerChanged
--	- Colourblind option
--	- Fancy skinning option? Learn about skins and fancyskins
--	- Handle interactions with (hiding) the standard econ bars
--
--	- Hook up to actual data
--		- This will be a good time to revise the panelData data structure
--		- It has a lot of redundancy that was there for mocking up the layout
--	- Get team names and other team data
--	- Add wins data
--	- Make more bg screenshots
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
local panelParams
local panelData

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

	-- Leaving out the sign to save space.
	-- For this panel, the direction is always implied
	-- and will still be colorcoded when needed.
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

local function SetupMockData()
	local mock = {}
	
	mock.playernames	= { left = "GoogleFrog", right = "Anarchid", }
	mock.playercolors	= { left = {0.5,0.5,1,1}, right = {1,0.2,0.2,1}, }
	mock.playerwins		= { left = math.random(0,4), right = math.random(0,4), }
	mock.bgfac		= { left = "cloakies", right = "hovers", }

	mock.resource_stats = {
		left = {
			{
				total = 156,
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
		},
		right = {
			{
				total = 156,
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
		},
	}
	
	mock.unit_stats = {
		left = {
			total = 5447 + 1521 + 12550,
			{ name = "Offense", value = 5447, icon = 'LuaUI/Images/commands/Bold/attack.png', icon_x = 0, },
			{ name = "Defense", value = 1521, icon = 'LuaUI/Images/commands/Bold/guard.png', icon_x = 50, },
			{ name = "Economy", value = 12550, icon = 'LuaUI/Images/energy.png', icon_x = 100, },
		},
		right = {
			total = 3386 + 872 + 10995,
			{ name = "Offense", value = 3386, icon = 'LuaUI/Images/commands/Bold/attack.png', icon_x = 0, },
			{ name = "Defense", value = 872, icon = 'LuaUI/Images/commands/Bold/guard.png', icon_x = 50, },
			{ name = "Economy", value = 10995, icon = 'LuaUI/Images/energy.png', icon_x = 100, },
		},
	}
	
	mock.balancebars = {
		{ name = "Income", value = 100 * mock.resource_stats.left[1].total / (mock.resource_stats.left[1].total + mock.resource_stats.right[1].total) },
		{ name = "Extraction", value = 100 * mock.resource_stats.left[1][1].value / (mock.resource_stats.left[1][1].value + mock.resource_stats.right[1][1].value) },
		{ name = "Military", value = 100 *
			(mock.unit_stats.left[1].value + mock.unit_stats.left[2].value) /
			(mock.unit_stats.left[1].value + mock.unit_stats.left[2].value + mock.unit_stats.right[1].value + mock.unit_stats.right[2].value)
		},
		{ name = "Attrition", value = 50 },
	}
	
	mock.unitpics = {
		left = {
			{ name = "cloakcon", value = "5" },
			{ name = "cloakraid", value = "18" },
			{ name = "cloakriot", value = "3" },
			{ name = "cloakskirm", value = "10" },
			{ name = "cloakassault", value = "7" },
		},
		right = {
			{ name = "hovercon", value = "3" },
			{ name = "hoverassault", value = "8" },
			{ name = "hoverskirm", value = "15" },
			{ name = "hoverriot", value = "6" },
			{ name = "hoverarty", value = "3" },
		},
	}
	mock.compics = {
		left = {
			-- { name = "commrecon", value = "2 more" },
			-- { name = "commstrike", value = "Lvl 4" },
			{ name = "commassault", value = "Lvl 6" },
		},
		right = {
			{ name = "commstrike", value = "Lvl 9" },
		},
	}
	
	return mock
end

local function SetupLayoutParams()
	local p = {}

	p.topcenterwidth = 200
	p.balancepanelwidth = 80
	
	p.balancelabelheight = 20
	p.balancebarheight = 10
	p.balanceheight = p.balancelabelheight + p.balancebarheight
	p.balancepanelheight = p.balanceheight * 4 + 5
	
	p.rowheight = 30
	p.topheight = p.rowheight * 1.5
	p.picsize = p.rowheight * 1.8
	
	p.unitpanelwidth = 150
	p.resourcebarwidth = 100
	p.resourcestatpanelwidth = 200
	p.resourcepanelwidth = p.resourcestatpanelwidth + p.resourcebarwidth
	
	p.screenWidth,p.screenHeight = Spring.GetWindowGeometry()
	p.screenHorizCentre = p.screenWidth / 2
	p.windowWidth = (p.resourcepanelwidth + p.unitpanelwidth) * 2 + p.balancepanelwidth + 24
	p.windowheight = p.topheight + p.balancepanelheight
	p.playerlabelwidth = (p.windowWidth - p.topcenterwidth) / 2
	
	return p
end

local function AddCenterPanels(t, p, d)
	-- 	t == table of panels; new panels will be added
	-- 	p == parameters to build layout
	-- 	d == data to populate panels
	
	t.window = Chili.Panel:New{
		classname = 'main_window',
		name = "SpecPanel",
		padding = {0,0,0,0},
		x = p.screenHorizCentre - p.windowWidth/2,
		y = 0,
		clientWidth  = p.windowWidth,
		clientHeight = p.windowheight,
	}

	t.topcenterpanel = Chili.Panel:New{
		parent = t.window,
		classname = 'main_window_small',
		padding = {5,5,5,5},
		x = (p.windowWidth - p.topcenterwidth)/2,
		width = p.topcenterwidth,
		height = p.topheight,
		dockable = false;
		draggable = false,
		resizable = false,
	}
	t.clocklabel = Chili.Label:New{
		parent = t.topcenterpanel,
		padding = {0,0,0,0},
		width = '100%',
		height = '100%',
		align = 'center',
		valign = 'center',
		fontsize = 24,
		textColor = {0.95, 1.0, 1.0, 1},
		caption = GetTimeString(),
	}
	
	t.balancepanel = Chili.Panel:New{
		parent = t.window,
		classname = 'main_window_small',
		padding = {0,0,0,0},
		x = (p.windowWidth - p.balancepanelwidth)/2,
		y = p.topheight,
		width = p.balancepanelwidth,
		height = p.balancepanelheight,
	}
	t.balancebars = {}
	for i,bar in ipairs(d.balancebars) do
		t.balancebars[i] = {}
		t.balancebars[i].label = Chili.Label:New{
			parent = t.balancepanel,
			y = p.balanceheight * (i-1) + 4,
			width = '100%',
			height = 15,
			caption = bar.name,
			align = 'center',
		}
		t.balancebars[i].bar = Chili.Progressbar:New{
			parent = t.balancepanel,
			orientation = 'horizontal',
			value = bar.value,
			x = '15%',
			y = p.balanceheight * (i-1) + p.balancelabelheight,
			width = '70%',
			height = p.balancebarheight,
			color = d.playercolors['left'],
			backgroundColor = {1,0,0,0},
		}
		t.balancebars[i].bar_bg = Chili.Progressbar:New{
			parent = t.balancepanel,
			orientation = 'horizontal',
			value = 100,
			x = '15%',
			y = p.balanceheight * (i-1) + p.balancelabelheight,
			width = '70%',
			height = p.balancebarheight,
			color = d.playercolors['right'],
		}
	end
	
end

local function AddSidePanels(t, p, d, side)
	-- 	t == table of panels; new panels will be added
	-- 	p == parameters to build layout
	-- 	d == data to populate panels

	local x, right
	if side == 'left' then
		x = "x"
		right = "right"
	elseif side == 'right' then
		x = "right"
		right = "x"
	else
		return
	end
	
	t.winslabel_top = Chili.Label:New{
		parent = t.topcenterpanel,
		padding = {0,0,0,0},
		[x] = 0,
		y = '5%',
		width = 50,
		height = '30%',
		align = 'center',
		valign = 'center',
		textColor = d.playercolors[side],
		caption = "Wins:",
	}
	t.winslabel_bottom = Chili.Label:New{
		parent = t.topcenterpanel,
		padding = {0,0,0,0},
		[x] = 0,
		y = '30%',
		width = 50,
		height = '70%',
		align = 'center',
		valign = 'center',
		fontsize = 20,
		textColor = d.playercolors[side],
		caption = d.playerwins[side],
	}

	t.playerlabel = Chili.Label:New{
		parent = t.window,
		padding = {0,0,0,0},
		[right] = (p.windowWidth + p.topcenterwidth)/2,
		width = p.playerlabelwidth,
		height = p.topheight,
		align = 'center',
		valign = 'center',
		textColor = d.playercolors[side],
		fontsize = 28,
		fontShadow = true,
		fontOutline = false,
		caption = d.playernames[side],
	}
	
	t.resource_stats = {}
	for i,resource in ipairs(d.resource_stats[side]) do
		t.resource_stats[i] = {}
		t.resource_stats[i].panel = Chili.Panel:New{
			parent = t.window,
			y = p.topheight + p.rowheight * (i-1),
			[right] = (p.windowWidth + p.balancepanelwidth)/2 + p.unitpanelwidth,
			width = p.resourcepanelwidth,
			height = p.rowheight,
			skin = nil,
			skinName = 'default',
			backgroundColor = {0,0,0,0},
			borderColor = {1,1,1,1},
			borderThickness = 1,
		}
		t.resource_stats[i].barpanel = Chili.Control:New{
			parent = t.resource_stats[i].panel,
			padding = {0,0,0,0},
			y = 0,
			right = 0,
			width = p.resourcebarwidth,
			height = '100%',
		}
		t.resource_stats[i].bar = Chili.Progressbar:New{
			parent = t.resource_stats[i].barpanel,
			padding = {0,0,0,0},
			x = '5%',
			y = '10%',
			height = '80%',
			right = '0%',
			color = resource.color,
			value = resource.bar,
		}
		t.resource_stats[i].statpanel = Chili.Control:New{
			parent = t.resource_stats[i].panel,
			padding = {0,0,0,0},
			x = 0,
			y = 0,
			width = p.resourcestatpanelwidth,
			height = '100%',
		}
		t.resource_stats[i].total = Chili.Label:New{
			parent = t.resource_stats[i].statpanel,
			x = 18,
			height = '100%',
			width = 20,
			valign = 'center',
			fontsize = 20,
			textColor = resource.color,
			caption = Format(resource.total, ""),
		}
		t.resource_stats[i].icon = Chili.Image:New{
			parent = t.resource_stats[i].statpanel,
			x = 0,
			height = 18,
			width = 18,
			file = resource.icon,
		}
		t.resource_stats[i].labels = {}
		for j,stat in ipairs(resource) do
			t.resource_stats[i].labels[j] = Chili.Label:New{
				parent = t.resource_stats[i].statpanel,
				x = resource[j].label_x,
				height = '100%',
				width = 20,
				valign = 'center',
				textColor = resource.color,
				caption = resource[j].label .. ":" .. Format(resource[j].value, ""),
			}
		end
	end
	
	t.unitpanel = Chili.Panel:New{
		parent = t.window,
		y = p.topheight,
		[right] = (p.windowWidth + p.balancepanelwidth)/2,
		height = p.rowheight * 2,
		width = p.unitpanelwidth,
		skin = nil,
		skinName = 'default',
		backgroundColor = {0,0,0,0},
		borderColor = {1,1,1,1},
		borderThickness = 1,
	}
	t.unit_stats = {}
	t.unit_stats.total = Chili.Label:New{
		parent = t.unitpanel,
		[x] = 0,
		height = '50%',
		width = '100%',
		align = 'center',
		valign = 'center',
		fontsize = 16,
		textColor = { 0.85, 0.85, 0.85, 1.0 },
		caption = "Unit Value: " .. Format(d.unit_stats[side].total, ""),
	}
	for i,stat in ipairs(d.unit_stats[side]) do
		t.unit_stats[i] = {}
		t.unit_stats[i].icon = Chili.Image:New{
			parent = t.unitpanel,
			x = stat.icon_x,
			y = '60%',
			height = 18,
			width = 18,
			file = stat.icon,
		}
		t.unit_stats[i].label = Chili.Label:New{
			parent = t.unitpanel,
			x = stat.icon_x + 18,
			y = '50%',
			height = '50%',
			width = 20,
			valign = 'center',
			textColor = { 0.7, 0.7, 0.7, 1.0 },
			caption = Format(stat.value, ""),
		}
	end
	
	t.unitpics = {}
	for i,unitpic in ipairs(d.unitpics[side]) do
		t.unitpics[i] = {}
		t.unitpics[i].text = Chili.Label:New{
			parent = t.window,
			y = p.topheight + p.rowheight * 2 + 5,
			[right] = (p.windowWidth + p.balancepanelwidth)/2 + p.picsize * (i-1) + 5,
			height = p.picsize - 10,
			width = p.picsize - 10,
			align = 'right',
			valign = 'bottom',
			fontsize = 16,
			caption = unitpic.value,
		}
		t.unitpics[i].unitpic = Chili.Image:New{
			parent = t.window,
			y = p.topheight + p.rowheight * 2,
			[right] = (p.windowWidth + p.balancepanelwidth)/2 + p.picsize * (i-1),
			height = p.picsize,
			width = p.picsize,
			file = 'unitpics/' .. unitpic.name .. '.png',
		}
		local framepic
		if i == 1 then
			framepic = 'bitmaps/icons/frame_cons.png'
		else
			framepic = 'bitmaps/icons/frame_unit.png'
		end
		t.unitpics[i].unitpicframe = Chili.Image:New{
			parent = t.window,
			y = p.topheight + p.rowheight * 2,
			[right] = (p.windowWidth + p.balancepanelwidth)/2 + p.picsize * (i-1),
			height = p.picsize,
			width = p.picsize,
			keepAspect = false,
			file = framepic,
		}
	end
	
	t.compics = {}
	for i,compic in ipairs(d.compics[side]) do
		t.compics[i] = {}
		t.compics[i].text = Chili.Label:New{
			parent = t.window,
			y = p.topheight + p.rowheight * 2 + 5,
			[right] = (p.windowWidth + p.balancepanelwidth)/2 + p.picsize * (i-1) + p.picsize * #d.unitpics[side],
			height = p.picsize - 10,
			width = p.picsize - 10,
			align = 'right',
			valign = 'bottom',
			caption = compic.value,
		}
		t.compics[i].unitpic = Chili.Image:New{
			parent = t.window,
			y = p.topheight + p.rowheight * 2,
			[right] = (p.windowWidth + p.balancepanelwidth)/2 + p.picsize * (i-1) + p.picsize * #d.unitpics[side],
			height = p.picsize,
			width = p.picsize,
			file = 'unitpics/' .. compic.name .. '.png',
		}
		local framepic = 'bitmaps/icons/frame_unit.png'
		t.compics[i].unitpicframe = Chili.Image:New{
			parent = t.window,
			y = p.topheight + p.rowheight * 2,
			[right] = (p.windowWidth + p.balancepanelwidth)/2 + p.picsize * (i-1) + p.picsize * #d.unitpics[side],
			height = p.picsize,
			width = p.picsize,
			keepAspect = false,
			file = framepic,
		}
	end
	
	t.bg_top = Chili.Panel:New{
		parent = t.window,
		[x] = 12,
		y = 0,
		width  = (p.windowWidth - 24) / 2,
		height = p.topheight,
		skin = nil,
		skinName = 'default',
		backgroundColor = {0,0,0,0.2},
		borderColor = {0,0,0,0},
	}
	t.bg_bottom = Chili.Panel:New{
		parent = t.window,
		[x] = 12,
		y = p.topheight,
		width  = (p.windowWidth - 24) / 2,
		height = p.windowheight - p.topheight,
		skin = nil,
		skinName = 'default',
		backgroundColor = {0,0,0,0.6},
		borderColor = {0,0,0,0},
	}
	t.bg_image = Chili.Image:New{
		parent = t.window,
		[x] = 12,
		y = 7,
		width  = (p.windowWidth - 24) / 2,
		height = p.windowheight - 14,
		keepAspect = false,
		file = 'LuaUI/Images/specpanel_ng/' .. d.bgfac[side] .. '_' .. side .. '.png',
	}
	
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
		specPanel = {}
		panelParams = SetupLayoutParams()
		panelData = SetupMockData()
		AddCenterPanels(specPanel, panelParams, panelData)
		AddSidePanels(specPanel, panelParams, panelData, 'left')
		AddSidePanels(specPanel, panelParams, panelData, 'right')
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
