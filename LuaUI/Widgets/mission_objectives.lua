--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Objectives",
    desc      = "Displays mission objectives.",
    author    = "KingRaptor (L.J. Lim)",
    date      = "Dec 2011",
    license   = "GNU GPL, v2 or later",
    layer     = 1, 
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not VFS.FileExists("mission.lua") then
	return
end

local Chili
local Window
local Panel
local StackPanel
local Button
local Label
local Image
local screen0

local mainWindow
local expandButton, expandButtonImage
local minimizeButton, minimizeButtonImage
local mainPanel
local scroll
local stack

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local statusImageWidth = 24
local panelHeight = 30
local fontsize = 14

local statusImages = {
	complete = "LuaUI/Images/commands/states/fire_atwill.png",
	incomplete = "LuaUI/Images/commands/states/fire_return.png",
	failed = "LuaUI/Images/commands/states/fire_hold.png"
}
local statusColors = {
	complete = {0.5, 0.5, 0.5, 1},
	incomplete = {1, 1, 1, 1},
	failed = {0.5, 0.5, 0.5, 1}
}

local objectives = {}	-- [objID] = {panel, label, image, status}
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function Expand()
	mainWindow:AddChild(mainPanel)
	mainWindow:RemoveChild(expandButton)
end

local function Minimize()
	mainWindow:RemoveChild(mainPanel)
	mainWindow:AddChild(expandButton)
end

local function AddObjective(id, title, details, pos, status, color)
	if not id then
		Spring.Echo("<Objectives> Error: Attempt to add objective with no ID")
		return
	end
	status = string.lower(status or '')
	objectives[id] = {}
	local obj = objectives[id]
	obj.panel = Panel:New{
		parent = stack;
		height = panelHeight,
		x = 5,
		width = stack.width - 5 - 5,
		padding = {0, 0, 0, 0},
		tooltip = details,
		hitTestAllowEmpty = true,
		--backgroundColor = {1, 1, 1, 0},
		OnMouseUp = pos and {function() Spring.SetCameraTarget(pos[1], pos[2], pos[3]) end} or nil
	}
	obj.label = Label:New{
		parent = obj.panel,
		autosize = false;
		align="left";
		valign="center";
		caption = title or '',
		x = statusImageWidth + 8,
		height = panelHeight,
		width = obj.panel.width - statusImageWidth - 8,
		font = {font = panelFont, size = fontsize, color = color or statusColors[status], shadow = true, outline = true,},
	}
	obj.image = Image:New{
		parent = obj.panel,
		width = statusImageWidth,
		height = statusImageWidth,
		x = 4, 
		y = (panelHeight - statusImageWidth)/2,
		keepAspect = true,
		file = statusImages[status],
	}
	
	-- implements button mouse functionality for the panel
	function obj.panel:MouseDown(...)
		local inherited = obj.panel.inherited
		self._down = true
		self.state = 'pressed'
		inherited.MouseDown(self, ...)
		self:Invalidate()
		return self
	end

	function obj.panel:MouseUp(...)
		local inherited = obj.panel.inherited
		if (self._down) then
			self._down = false
			self.state = 'normal'
			inherited.MouseUp(self, ...)
			self:Invalidate()
			return self
		end
	end
end

local function ModifyObjective(id, title, details, pos, status, color)
	if not id then
		Spring.Echo("<Objectives> Error: Attempt to modify objective with no ID")
		return
	end
	local obj = objectives[id]
	if title and title ~= '' then
		obj.label:SetCaption(title)
	end
	if details and details ~= '' then
		obj.panel.tooltip = details
	end
	if pos then
		obj.panel.OnMouseUp = {function() Spring.SetCameraTarget(pos[1], pos[2], pos[3]) end}
	end
	if status then
		status = string.lower(status)
		if statusImages[status] then
		      obj.image.file = statusImages[status]
		      obj.image:Invalidate()
		end
	end
	if (status) or color then
		obj.label.font.color = color or statusColors[status] or obj.label.font.color
		obj.label:Invalidate()	
	end
end

local function RemoveObjective(id)
	if not id then
		Spring.Echo("<Objectives> Error: Attempt to delete objective with no ID")
		return
	end
	local obj = objectives[id]
	obj.panel:ClearChildren()
	obj.panel:Dispose()
	objectives[id] = nil
end

WG.AddObjective = AddObjective
WG.ModifyObjective = ModifyObjective
WG.RemoveObjective = RemoveObjective

local function MakeTestObjectives()
	AddObjective("testObj", "Test", "This is a test", {1000, 100, 1000}, "incomplete")
	RemoveObjective("testObj")
	AddObjective("startGame", "Start the Game", "Play some Zero-K\n(Protip: Some objectives can be clicked to set camera target)", nil, "complete", {0,1,0.2,1})
	AddObjective("killPicasso", "Kill Picasso", "The mad modder emmanuel has fled to Germany and changed his name to PicassoCT. Show him that none can hide from the might of Spring!", {5000, 100, 1000}, "incomplete")
	AddObjective("dontRead", "Don't read this", "", nil, "incomplete")
	ModifyObjective("dontRead", nil, "What did I tell you? You just lost The Game!", nil, "failed")
	AddObjective("pad1", "Padding 1", "", nil, "incomplete")
	AddObjective("pad2", "Padding 2", nil, nil, "complete")
	AddObjective("pad3", "Padding 3", "test", nil, "failed")
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:Initialize()
	if (not WG.Chili) then
		widgetHandler:RemoveWidget(widget)
		return
	end

	Chili		= WG.Chili
	Window		= Chili.Window
	Panel		= Chili.Panel
	StackPanel	= Chili.StackPanel
	ScrollPanel	= Chili.ScrollPanel
	Button		= Chili.Button
	Label		= Chili.Label
	Image		= Chili.Image
	screen0		= Chili.Screen0
	
	local vsx, vsy = gl.GetViewSizes()
	
	mainWindow = Window:New{  
		dockable = true,
		collide = false,
		name = "objectivesWindow",
		color = {0,0,0,0},
		right = 0,  
		bottom = vsy * 0.7,
		width  = 350,
		height = 150,
		padding = {0,0,0,0};
		parent = screen0,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = false,
		minimizable = false,
	}
	
	expandButton = Button:New{
		parent = mainWindow;
		right = 0,
		y = 0,
		height = 64,
		width = 64,
		caption = '',
		OnMouseUp = {	function () 
				Expand()
			end},
		padding = {8,8,8,8},
		keepAspect = true,
		tooltip = "Show objectives"
	}
	
	expandButtonImage = Image:New{
		parent = expandButton,
		width="100%";
		height="100%";
		x=0;
		y=0;
		file = "LuaUI/Images/Crystal_Clear_action_flag.png",
		keepAspect = false,
	}

	mainPanel = Panel:New{
		parent = mainWindow,
		x = 0,
		y = 0,
		width = "100%";
		height = "100%";
		padding = {2, 2, 2, 2},
	}	
	
	minimizeButton = Button:New{
		parent = mainPanel,
		right = 0,
		y = 0,
		height = 24,
		width = 24,
		caption = '',
		OnMouseUp = {	function () 
				Minimize()
			end},
		backgroundColor = {1, 1, 1, 0},
		padding = {4,4,4,4},
		keepAspect = true,
		tooltip = "Hide objectives"
	}
	
	minimizeButtonImage = Image:New{
		parent = minimizeButton,
		width=16;
		height=16;
		x=0;
		y=0;
		file = "LuaUI/Images/closex_16.png",
		keepAspect = false,
	}
	
	scroll = ScrollPanel:New{
		parent = mainPanel;
		x = 2, y = 4,
		height = mainPanel.height - 12;
		width =  mainPanel.width - 24;
		horizontalScrollbar = false,
		verticalSmartScroll = true,
		backgroundColor = {0, 0, 0, 0},
		padding = {0, 0, 0, 0},
		itemMargin  = {0, 0, 0, 0},
		scrollbarSize = 8,
	}
	
	stack = StackPanel:New{
		parent = scroll,
		autosize = true,
		resizeItems = false;
		orientation   = "vertical";
		width = "99%",
		x = 4,
		y = 0,
		padding = {0, 0, 0, 0},
		itemMargin  = {0, 0, 0, 0},
	}
	
	mainWindow:RemoveChild(mainPanel)
	
	--MakeTestObjectives()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------