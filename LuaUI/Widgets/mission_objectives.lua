--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Objectives",
    desc      = "Displays mission objectives.",
    author    = "KingRaptor (L.J. Lim)",
    date      = "Dec 2011",
    license   = "GNU GPL, v2 or later",
    layer     = -1, -- make sure it draws before point tracker
    enabled   = true  --  loaded by default?
  }
end
include("Widgets/COFCTools/ExportUtilities.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local debugMode = false
if not (VFS.FileExists("mission.lua") or debugMode) then
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

local mainWindow, buttonWindow
local expandButton, expandButtonImage
local minimizeButton, minimizeButtonImage
local mainPanel
local scroll
local stack

local colorGrey = {0.4, 0.4, 0.4, 1}
local colorWhite = {1,1,1,1}
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local statusImageWidth = 30
local panelHeight = 36
local fontsize = 16

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

local objectives = {}	-- [objID] = {panel, label, image, status, unitsOrPositions = {}, uolIndex = 0}
local unitsWithObjectives = {}
local unread = false
local open = false
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function Expand()
	--mainWindow.x = buttonWindow.x - (mainWindow.width - buttonWindow.width)
	--mainWindow.y = buttonWindow.y
	--mainWindow:AddChild(mainPanel)
	--mainWindow:RemoveChild(expandButton)
	screen0:AddChild(mainWindow)
	if unread then
		expandButton.backgroundColor = colorGrey
		expandButtonImage.color = colorGrey
		expandButtonImage:Invalidate()
		expandButton:Invalidate()
		unread = false
	end
	open = true
end

local function Minimize()
	--mainWindow:RemoveChild(mainPanel)
	--mainWindow:AddChild(expandButton)
	screen0:RemoveChild(mainWindow)
	open = false
end


local function CyclePointsOrUnits(objID)
	local obj = objectives[objID]
	if not obj then
		Spring.Echo("Objective " .. objID .. "not found")
		return
	end
	local maxTries = #obj.unitsOrPositions
	for i=1, maxTries, 1 do
		obj.index = obj.index + 1
		if (obj.index > #obj.unitsOrPositions) then
			obj.index = 1
		end
		local target = obj.unitsOrPositions[obj.index]
		if type(target) == "table" then	-- is a point
			local y = Spring.GetGroundHeight(target[1], target[2])
			SetCameraTarget(target[1], y, target[2])
			return
		else	-- is a unit
			local x,y,z = Spring.GetUnitPosition(target)
			if (x and y and z) then
				SetCameraTarget(x, y, z)
				return
			end
		end
	end
end

local function ModifyObjective(id, title, description, pos, status, color)
	if not id then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Attempt to modify objective with no ID")
		return
	end
	local obj = objectives[id]
	if not obj then
		Spring.Log(widget:GetInfo().name, LOG.WARNING, "Attempt to modify missing objective "..id)
		return
	end
	
	if title and title ~= '' then
		obj.label:SetCaption(title)
	end
	if description and description ~= '' then
		obj.panel.tooltip = description
	end
	
	-- pos is deprecated, use the point/unit tables instead
	--if pos then
	--	obj.panel.OnClick = {function() SetCameraTarget(pos[1], pos[2], pos[3]) end}
	--end
	if status then
		status = string.lower(status)
		if statusImages[status] then
			obj.image.file = statusImages[status]
			obj.image:Invalidate()
		end
		obj.status = status
	end
	if (status) or color then
		obj.label.font.color = color or statusColors[status] or obj.label.font.color
		obj.label:Invalidate()
	end
	
	Spring.PlaySoundFile("sounds/message_private.wav", 1, "ui")
end

local function AddUnitOrPosToObjective(id, toAdd)
	if not id then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Attempt to add unit or position to objective with no ID")
		return
	end
	local obj = objectives[id]
	if not obj then
		Spring.Log(widget:GetInfo().name, LOG.WARNING, "Attempt to modify missing objective "..id)
		return
	end
	obj.unitsOrPositions[#obj.unitsOrPositions + 1] = toAdd
	if type(toAdd) == "number" then
		unitsWithObjectives[toAdd] = true
	end
end

local function AddObjective(id, title, description, pos, status, color)
	if not id then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Attempt to add objective with no ID")
		return
	end
	status = string.lower(status or '')
	if objectives[id] then	-- duplicate objective
		ModifyObjective(id, title, description, pos, status, color)
	else
		objectives[id] = {
			status = status,
			unitsOrPositions = {},
			index = 0,
		}
		local obj = objectives[id]
		
		-- pos is deprecated, use the point/unit tables instead
		if (pos) then
			obj.unitsOrPositions[#obj.unitsOrPositions + 1] = pos
		end
		
		obj.panel = Button:New{
			parent = stack;
			height = panelHeight,
			x = 5,
			width = stack.width - 5 - 5,
			padding = {0, 0, 0, 0},
			tooltip = description,
			caption = "",
			hitTestAllowEmpty = true,	-- for old ZK chili
			noSelfHitTest = false,
			--backgroundColor = {1, 1, 1, 0},
			OnClick = {function() CyclePointsOrUnits(id) end}
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
			self.state.pressed = true
			inherited.MouseDown(self, ...)
			self:Invalidate()
			return self
		end
	
		function obj.panel:MouseUp(...)
			local inherited = obj.panel.inherited
			if (self._down) then
				self._down = false
				self.state.pressed = false
				inherited.MouseUp(self, ...)
				self:Invalidate()
				return self
			end
		end
		
		Spring.PlaySoundFile("sounds/message_private.wav", 1, "ui")
		if not unread then
			expandButtonImage.backgroundColor = colorWhite
			expandButtonImage.color = colorWhite
			expandButtonImage:Invalidate()
			expandButton:Invalidate()
			unread = true
		end
	end
end

local function RemoveObjective(id)
	if not id then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Attempt to remove objective with no ID")
		return
	end
	local obj = objectives[id]
	obj.panel:ClearChildren()
	obj.panel:Dispose()
	objectives[id] = nil
end

local function MakeTestObjectives()
	AddObjective("testObj", "Test", "This is a test", {1000, 1000}, "incomplete")
	RemoveObjective("testObj")
	AddObjective("startGame", "Start the Game", "Play some Zero-K\n(Protip: Some objectives can be clicked to set camera target)", nil, "complete", {0,1,0.2,1})
	AddObjective("killPicasso", "Kill Picasso", "The mad modder emmanuel has fled to Germany and changed his name to PicassoCT. Show him that none can hide from the might of Spring!", {5000, 1000}, "incomplete")
	AddObjective("dontRead", "Don't read this", "", nil, "incomplete")
	AddUnitOrPosToObjective("dontRead", {5000, 1500})
	ModifyObjective("dontRead", nil, "What did I tell you? You just lost The Game!", nil, "failed")
	AddObjective("pad1", "Padding 1", "", nil, "incomplete")
	AddObjective("pad2", "Padding 2", nil, nil, "complete")
	AddObjective("pad3", "Padding 3", "test", nil, "incomplete")
	AddObjective("pad3", "Padding 3.1", nil, nil, "failed")
end

function ReceiveMissionObjectives(newObjectives)
	-- first remove all existing objectives
	for id in pairs(objectives) do
		RemoveObjective(id)
	end
	for index, obj in pairs(newObjectives) do
		AddObjective(obj.id, obj.title, obj.description, obj.pos, obj.status, obj.color)
		for i=1, #obj.unitsOrPositions do
			AddUnitOrPosToObjective(obj.id, obj.unitsOrPositions[i])
		end
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- remove unit from objective if necessary
function widget:UnitDestroyed(unitID)
	if unitsWithObjectives[unitID] then
		for objID, obj in pairs(objectives) do
			for i=#obj.unitsOrPositions, -1 do
				unitOrPos = obj.unitsOrPositions[i]
				if unitOrPos == unitID then
					table.remove(obj.unitsOrPositions[i])
				end
			end
		end
		unitsWithObjectives[unitID] = nil
	end
end

function widget:Initialize()
	if (not WG.Chili) then
		widgetHandler:RemoveWidget(widget)
		return
	end

	Chili       = WG.Chili
	Window      = Chili.Window
	Panel       = Chili.Panel
	StackPanel  = Chili.StackPanel
	ScrollPanel = Chili.ScrollPanel
	Button      = Chili.Button
	Label       = Chili.Label
	Image       = Chili.Image
	screen0     = Chili.Screen0
	
	local vsx, vsy = Spring.GetWindowGeometry()
	local width, height = 480, 240
	local y = vsy * 0.20 + 50	-- put it under proconsole
	
	mainWindow = Window:New{
		name = "objectivesWindow",
		dockable = false,
		x = (vsx - width)/2,
		y = (vsy - height)/2,
		width  = width,
		height = height,
		padding = {0,0,0,0};
		draggable = true,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = false,
	}
	
	buttonWindow = Window:New{
		name = "objectivesButtonWindow",
		parent = screen0,
		dockable = true,
		color = {0,0,0,0},
		right = 0,
		y = y,
		width  = 64,
		height = 64,
		padding = {0,0,0,0};
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = false,
		minimizable = false,
	}
	
	expandButton = Button:New{
		parent = buttonWindow;
		right = 0,
		y = 0,
		height = 64,
		width = 64,
		caption = '',
		OnClick = {	function ()
				if open then Minimize(); else Expand(); end
			end},
		padding = {8,8,8,8},
		keepAspect = true,
		tooltip = "Show objectives",
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
		right = 2,
		y = 2,
		height = 26,
		width = 26,
		caption = '',
		OnClick = {	function ()
				Minimize()
			end},
		backgroundColor = {1, 1, 1, 0},
		padding = {2,2,2,2},
		keepAspect = true,
		tooltip = "Hide objectives"
	}
	
	minimizeButtonImage = Image:New{
		parent = minimizeButton,
		width="100%";
		height="100%";
		x=0;
		y=0;
		file = "LuaUI/Images/closex_16.png",
		keepAspect = false,
	}
	
	scroll = ScrollPanel:New{
		parent = mainPanel;
		x = 2, y = 4,
		height = mainPanel.height - 12;
		right = 28,
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
		padding = {1, 3, 3, 3},
		itemMargin  = {0, 1, 1, 1},
	}
	
	WG.AddObjective = AddObjective
	WG.ModifyObjective = ModifyObjective
	WG.AddUnitOrPosToObjective = AddUnitOrPosToObjective
	WG.RemoveObjective = RemoveObjective
	
	widgetHandler:RegisterGlobal("MissionObjectivesFromSynced", ReceiveMissionObjectives)
	
	if debugMode then
		MakeTestObjectives()
	end
	
	-- fetch objectives from gadget
	-- doesn't catch the case if widget is toggled before game start but meh
	Spring.SendLuaRulesMsg("sendMissionObjectives")
end

function widget:Shutdown()
	WG.AddObjective = nil
	WG.ModifyObjective = nil
	WG.RemoveObjective = nil
	widgetHandler:DeregisterGlobal("MissionObjectivesFromSynced")
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
