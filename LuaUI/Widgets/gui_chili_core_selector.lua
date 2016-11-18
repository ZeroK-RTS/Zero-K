-------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Core Selector",
    desc      = "v0.6 Manage your boi, idle cons, and factories.",
    author    = "KingRaptor",
    date      = "2011-6-2",
    license   = "GNU GPL, v2 or later",
    layer     = 1001,
    enabled   = true,
  }
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

include("Widgets/COFCTools/ExportUtilities.lua")
VFS.Include("LuaRules/Configs/customcmds.h.lua")

Spring.Utilities = Spring.Utilities or {}
VFS.Include("LuaRules/Utilities/unitDefReplacements.lua")
local GetUnitCanBuild = Spring.Utilities.GetUnitCanBuild

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
local GetUnitDefID      = Spring.GetUnitDefID
local GetUnitHealth     = Spring.GetUnitHealth
local GetUnitStates     = Spring.GetUnitStates
local DrawUnitCommands  = Spring.DrawUnitCommands
local GetSelectedUnits  = Spring.GetSelectedUnits
local GetFullBuildQueue = Spring.GetFullBuildQueue
local GetUnitIsBuilding = Spring.GetUnitIsBuilding
local GetGameSeconds	= Spring.GetGameSeconds
local GetGameFrame 	= Spring.GetGameFrame
local GetModKeyState	= Spring.GetModKeyState
local SelectUnitArray	= Spring.SelectUnitArray
local GetUnitRulesParam	= Spring.GetUnitRulesParam
local GetMouseState	= Spring.GetMouseState
local TraceScreenRay	= Spring.TraceScreenRay
local GetUnitPosition	= Spring.GetUnitPosition

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
WhiteStr   = "\255\255\255\255"
GreyStr    = "\255\210\210\210"
GreenStr   = "\255\092\255\092"

local buttonColor = {nil, nil, nil, 1}
local buttonColorFac = {0.6, 0.6, 0.6, 0.3}
local buttonColorWarning = {1, 0.2, 0.1, 1}
local buttonColorDisabled = {0.2,0.2,0.2,1}
local imageColorDisabled = {0.3, 0.3, 0.3, 1}

local stateCommands = {	-- FIXME: is there a better way of doing this?
  [CMD_WANT_CLOAK] = true,	-- this is the only one that's really needed, since it can occur without user input (when a temporarily decloaked unit recloaks)
  [CMD.FIRE_STATE] = true,
  [CMD.MOVE_STATE] = true,
  [CMD.ONOFF] = true,
  [CMD.REPEAT] = true,
  [CMD.IDLEMODE] = true,
}
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Chili
local Button
local Control
local Label
local Window
local Panel
local Image
local Progressbar
local screen0
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local window_selector, stack_main, background
local conButton = {}	-- {button, image, healthbar/label}

local echo = Spring.Echo

local windowPositionX, windowPositionY

function WG.CoreSelector_SetOptions(maxbuttons)
	options.maxbuttons.value = maxbuttons
	options.maxbuttons.OnChange(options.maxbuttons)
end

-- list and interface vars
local facsByID = {}	-- [unitID] = index of facs[]
local facs = {}	-- [ordered index] = {facID, facDefID, buildeeDefID, ["repeat"] = boolean, button, image, repeatImage, ["buildProgress"] = ProgressBar,}
local commsByID = {} -- [unitID] = index of comms[]	
local comms = {} -- [ordered index] = {commID, commDefID, warningTime, button, image, [healthbar] = ProgressBar,}
local currentComm	--unitID
local commDefID = UnitDefNames.armcom1.id
local idleCons = {}	-- [unitID] = true
local idleBuilderDefID = UnitDefNames.armrectr.id
local wantUpdateCons = false
local readyUntaskedBombers = {}	-- [unitID] = true

--local gamestart = GetGameFrame() > 1
local myTeamID = false
local commWarningTime		= 2 -- how long to flash button frame, seconds
--local commWarningTimeLeft	= -1

-------------------------------------------------------------------------------
local image_repeat = LUAUI_DIRNAME .. 'Images/repeat.png'
local buildIcon = LUAUI_DIRNAME .. 'Images/idlecon.png' --LUAUI_DIRNAME .. 'Images/commands/Bold/build.png'
local buildIcon_bw = LUAUI_DIRNAME .. 'Images/idlecon_bw.png'

local teamColors = {}
local GetTeamColor = Spring.GetTeamColor or function (teamID)
  local color = teamColors[teamID]
  if (color) then return unpack(color) end
  local _,_,_,_,_,_,r,g,b = Spring.GetTeamInfo(teamID)
  teamColors[teamID] = {r,g,b}
  return r,g,b
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
local UPDATE_FREQUENCY = 0.25

local exceptionList = {
	armasp = true,
	armcarry = true,
	reef = true,
}

local exceptionArray = {}
for name in pairs(exceptionList) do
	if UnitDefNames[name] then
		exceptionArray[UnitDefNames[name].id] = true
	end
end

local nano_name = UnitDefNames.armnanotc.humanName	-- HACK

local function RefreshConsList() end	-- redefined later
local function ClearData(reinitialize) end

local hidden = false
local function CheckHide()
	local shouldShow = (options.showCoreSelector.value == 'always') or (options.showCoreSelector.value == 'spec' and (not Spring.GetSpectatingState()))

	if shouldShow and hidden then
		hidden = false
		screen0:AddChild(window_selector)
	elseif not shouldShow and not hidden then
		hidden = true
		screen0:RemoveChild(window_selector)
	end
end

function widget:PlayerChanged()
	CheckHide()
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Widget options

local function ResetWidget()
	if window_selector then
		windowPositionX = window_selector.x
		windowPositionY = window_selector.y
	end
	ClearData(true)
	window_selector:Dispose()
	widget:Initialize()
end

options_path = 'Settings/HUD Panels/Quick Selection Bar'
options_order = {  'showCoreSelector', 'vertical', 'maxbuttons', 'background_opacity', 'monitoridlecomms','monitoridlenano', 'monitorInbuiltCons', 'leftMouseCenter', 'lblSelectionIdle', 'selectprecbomber', 'selectidlecon', 'selectidlecon_all', 'lblSelection', 'selectcomm', 'horPadding', 'vertPadding', 'buttonSpacing', 'minButtonSpaces', 'fancySkinning'}
options = { 
	showCoreSelector = {
		name = 'Selection Bar Visibility',
		type = 'radioButton',
		value = 'spec',
		items = {
			{key ='always', name='Always enabled'},
			{key ='spec',   name='Hide when spectating'},
			{key ='never',  name='Always disabled'},
		},
		OnChange = CheckHide,
		noHotkey = true,
	},
	vertical = {
		name = 'Vertical Bar',
		type = 'bool',
		value = false,
		noHotkey = true,
		OnChange = ResetWidget,	
	},
	maxbuttons = {
		name = 'Maximum number of buttons (3-16)',
		type = 'number',
		value = 6,
		min=3,max=16,step=1,
		OnChange = ResetWidget,
	},
	background_opacity = {
		name = "Opacity",
		type = "number",
		value = 0, min = 0, max = 1, step = 0.01,
	},
	monitoridlecomms = {
		name = 'Track idle comms',
		type = 'bool',
		value = true,
		noHotkey = true,
		OnChange = function() RefreshConsList() end,		
	},
	monitoridlenano = {
		name = 'Track idle nanotowers',
		type = 'bool',
		value = true,
		noHotkey = true,
		OnChange = function() RefreshConsList() end,		
	},
	monitorInbuiltCons = {
		name = 'Track constructors being built',
		type = 'bool',
		value = false,
		noHotkey = true,
		OnChange = function() RefreshConsList() end,		
	},
	leftMouseCenter = {
		name = 'Swap Camera Center Button',
		desc = 'When enabled left click a commander or factory to center the camera on it. When disabled right click centers.',
		type = 'bool',
		value = false,		
		noHotkey = true,
	},
	lblSelectionIdle = { type='label', name='Idle Units', path='Game/Selection Hotkeys', },
	selectprecbomber = { type = 'button',
		name = 'Select idle precision bomber',
		desc = 'Selects an idle, armed precision bomber. Use multiple times to select more. Deselects any units which are not idle, armed precision bombers.',
		action = 'selectprecbomber',
		path = 'Game/Selection Hotkeys',
		dontRegisterAction = true,
	},
	selectidlecon = { type = 'button',
		name = 'Select idle constructor',
		desc = 'Selects an idle constructor. Use multiple times to select more. Deselects any units which are not idle constructors.',
		action = 'selectidlecon',
		path = 'Game/Selection Hotkeys',
		dontRegisterAction = true,
	},
	selectidlecon_all = { type = 'button',
		name = 'Select all idle constructors',
		action = 'selectidlecon_all',
		path = 'Game/Selection Hotkeys',
		dontRegisterAction = true,
	},
	lblSelection = { type='label', name='Commander', path='Game/Selection Hotkeys', },
	selectcomm = { type = 'button',
		name = 'Select Commander',
		action = 'selectcomm',
		path = 'Game/Selection Hotkeys',
		dontRegisterAction = true,
	},
	horPadding = {
		name = 'Horizontal Padding',
		type = 'number',
		value = 0,
		advanced = true,
		min = 0, max = 100, step = 0.25,
		OnChange = ResetWidget,
	},
	vertPadding = {
		name = 'Vertical Padding',
		type = 'number',
		value = 0,
		advanced = true,
		min = 0, max = 100, step = 0.25,
		OnChange = ResetWidget,
	},
	buttonSpacing = {
		name = 'Button Spacing',
		type = 'number',
		value = 0,
		advanced = true,
		min = 0, max = 100, step = 0.25,
		OnChange = ResetWidget,
	},
	minButtonSpaces = {  
		name = 'Minimum Button Space',
		type = 'number',
		value = 0,
		advanced = true,
		min = 0, max = 16, step=1,
		OnChange = ResetWidget,	
	},
	fancySkinning = {
		name = 'Fancy Skinning',
		type = 'bool',
		value = false,
		advanced = true,
		noHotkey = true,
		OnChange = function (self)
			local currentSkin = Chili.theme.skin.general.skinName
			local skin = Chili.SkinHandler.GetSkin(currentSkin)
			
			local newClass = skin.panel
			if self.value and skin.bottomLeftPanel then
				newClass = skin.bottomLeftPanel
			end
			
			background.tiles = newClass.tiles
			background.TileImageFG = newClass.TileImageFG
			background.backgroundColor = newClass.backgroundColor
			background.TileImageBK = newClass.TileImageBK
			background:Invalidate()
		end
	}
}

local function SelectFactory(index)
	if not (facs[index] and facs[index].button) then
		return
	end
	
	facs[index].button.OnClick[1]()
end

local SELECT_FACTORY = "epic_chili_core_selector_select_factory_"

-- Factory hotkeys
local hotkeyPath = 'Settings/HUD Panels/Quick Selection Bar/Hotkeys'
for i = 1, 16 do
	local optionName = "select_factory_" .. i
	options_order[#options_order + 1] = optionName
	options[optionName] = {
		name = "Select Factory " .. i,
		desc = "Selects the factory in position " .. i .. " of the selection bar.",
		type = 'button',
		path = hotkeyPath,
		OnChange = function()
			SelectFactory(i)
		end
	}
end

-------------------------------------------------------------------------------
-- SCREENSIZE FUNCTIONS
-------------------------------------------------------------------------------
local vsx, vsy   = widgetHandler:GetViewSizes()

function widget:ViewResize(viewSizeX, viewSizeY)
  vsx = viewSizeX
  vsy = viewSizeY
end

-------------------------------------------------------------------------------
-- helper funcs

local function CountButtons(set)
	local count = 0
	for _,data in pairs(set) do
		if data.button then
			count = count + 1
		end
	end
	return count
end

local function GetHealthColor(fraction, returnType)
	local midpt = (fraction > .5)
	local r, g
	if midpt then 
		r = ((1-fraction)/0.5)
		g = 1
	else
		r = 1
		g = (fraction)/0.5
	end
	if returnType == "char" then
		return string.char(255,math.floor(255*r),math.floor(255*g),0)
	end
	return {r, g, 0, 1}
end

local function GetButtonPosition(index)
	if options.vertical.value then
		local y = (options.maxbuttons.value - index)*(100/options.maxbuttons.value) .. "%"
		return 0, y, "100%", (100/options.maxbuttons.value) .. "%"
	else
		local x = (index - 1)*(100/options.maxbuttons.value) .. "%"
		return x, 0, (100/options.maxbuttons.value) .. "%", "100%"
	end
end

local function UpdateBackgroundSize()
	if options.background_opacity.value == 0 or not background then
		return
	end
	
	local buttons = math.max(options.minButtonSpaces.value, CountButtons(comms) + CountButtons(facs) + 1)
	local sideSpacing = 2*((options.vertical.value and options.vertPadding.value) or options.horPadding.value)
	local buttonSpace = buttons/options.maxbuttons.value
	
	if options.vertical.value then
		buttonSpace = buttonSpace*stack_main.height
		
		local top = stack_main.height - (buttonSpace + sideSpacing)
		top = math.max(top, 0)
		
		background._relativeBounds.top = top
		background._relativeBounds.bottom = 0
		background:UpdateClientArea()
	else
		buttonSpace = buttonSpace*stack_main.width
		
		local right = buttonSpace + sideSpacing
		right = math.max(right, 0)
		
		background._relativeBounds.right = right
		background._relativeBounds.left = 0
		background:UpdateClientArea()
	end
end

function options.background_opacity.OnChange(self)
	background.backgroundColor[4] = self.value
	background:Invalidate()
	UpdateBackgroundSize()
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Core functions

local function UpdateFac(unitID, index)
	if not facs[index].button then
		return
	end
	local progress
	local buildeeDefID
	local buildeeID = GetUnitIsBuilding(unitID)
	if buildeeID then
		progress = select(5, GetUnitHealth(buildeeID))
		buildeeDefID = GetUnitDefID(buildeeID)
	end
	--Spring.Echo(progress)
	facs[index].buildProgress:SetValue(progress or 0)

	--repeat icon
	local states = GetUnitStates(unitID)
	if not states then
		return
	end
	
	local rep = states["repeat"]
	if rep and not facs[index]["repeat"] then
		facs[index].image:AddChild(facs[index].repeatImage)
		facs[index]["repeat"] = true
	elseif (not rep) and facs[index]["repeat"] then
		facs[index].image:RemoveChild(facs[index].repeatImage)
		facs[index]["repeat"] = false
	end
	
	-- write tooltip
	local queue = GetFullBuildQueue(unitID) or {}
	local count = 0
	for i=1, #queue do
		for udid, num in pairs(queue[i]) do
			count = count + num
			break
		end
	end

	local tooltip = WG.Translate("interface", "factory") .. ": ".. Spring.Utilities.GetHumanName(UnitDefs[facs[index].facDefID]) .. "\n" .. WG.Translate("interface", "x_units_in_queue", {count = count})
	if rep then
		tooltip = tooltip .. "\255\0\255\255 (" .. WG.Translate("interface", "repeating") .. ")\008"
	end
	if buildeeDefID then
		tooltip = tooltip .. "\n" .. WG.Translate("interface", "current_project") .. ": " .. Spring.Utilities.GetHumanName(UnitDefs[buildeeDefID]) .." (".. WG.Translate("interface", "x%_done", {x = math.floor(progress*100)}) .. ")"
	end
	tooltip = tooltip .. "\n\255\0\255\0" .. WG.Translate("interface", "lmb") .. ": " .. (options.leftMouseCenter.value and WG.Translate("interface", "select_and_go_to") or WG.Translate("interface", "select")) ..
										"\n" .. WG.Translate("interface", "rmb") .. ": " .. ((not options.leftMouseCenter.value) and WG.Translate("interface", "select_and_go_to") or WG.Translate("interface", "select")) ..
										"\n" .. WG.Translate("interface", "shift") .. ": " .. WG.Translate("interface", "append_to_current_selection") .. "\008"

	local tooltipOld = facs[index].button.tooltip
	if tooltipOld ~= tooltip then
		facs[index].button.tooltip = tooltip
	end
	-- change image if needed
	if buildeeDefID and (buildeeDefID~= facs[index].buildeeDefID) then
		facs[index].image.file = '#'..buildeeDefID
		facs[index].image:Invalidate()
		facs[index].buildeeDefID = buildeeDefID
	elseif (not buildeeDefID) and (facs[index].buildeeDefID) then
		facs[index].image.file = '#'..facs[index].facDefID
		facs[index].image:Invalidate()
		facs[index].buildeeDefID = nil
	end
end

-- makes fac and comm buttons
local function GenerateButton(array, i, unitID, unitDefID, hotkey)
	-- don't display surplus buttons
	local buttonCount = CountButtons(comms) + (array == facs and CountButtons(facs) or 0)
	if buttonCount > options.maxbuttons.value - 1 then
		return
	end
	
	local pos = i
	if array == facs then
		pos = pos + CountButtons(comms)
	end
	
	local bX, bY, bWidth, bHeight = GetButtonPosition(pos + 1)
	
	local hPad = ((not options.vertical.value) and options.buttonSpacing.value) or 0
	local vPad = (options.vertical.value and options.buttonSpacing.value) or 0
	
	array[i].holder = Control:New{
		parent = stack_main,
		x = bX,
		y = bY,
		width = bWidth,
		height = bHeight,
		padding = {hPad, vPad, hPad, vPad},
	}
	
	array[i].button = Button:New{
		parent = array[i].holder,
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		caption = '',
		OnClick = {	function (self, x, y, mouse)
				local _, _, meta, shift = Spring.GetModKeyState()
				if meta then
					WG.crude.OpenPath(options_path)
					WG.crude.ShowMenu()
					return true
				end

				SelectUnitArray({unitID}, shift)
				if mouse == ((options.leftMouseCenter.value and 1) or 3) then
					local x, y, z = Spring.GetUnitPosition(unitID)
					SetCameraTarget(x, y, z)
				end
			end},
		padding = {1,1,1,1},
		--keepAspect = true,
		backgroundColor = (array == facs and buttonColorFac) or buttonColor,
	}
	if (hotkey ~= nil) then 
		Label:New {
				width="100%";
				height="100%";
				autosize=false;
				x=2,
				y=3,
				align="left";
				valign="top";
				caption = '\255\0\255\0'..hotkey,
				fontSize = 11;
				fontShadow = true;
				parent = array[i].button
		}
	end 
	
	array[i].image = Image:New {
		parent = array[i].button,
		width="91%";
		height="91%";
		x="5%";
		y="5%";
		file = '#'..((array == facs and array[i].buildeeDefID) or unitDefID),
		file2 = (array == facs) and "bitmaps/icons/frame_cons.png",
		keepAspect = false,
	}
	if array == facs then
		array[i].buildProgress = Progressbar:New{
			parent = array[i].image,
			width = "85%",
			height = "85%",
			x = "8%",
			y = "8%",
			max     = 1;
			caption = "";
			color = {0.7, 0.7, 0.4, 0.6},
			backgroundColor = {1, 1, 1, 0.01},
			skin=nil,
			skinName='default',		
		}	
		array[i].repeatImage = Image:New {
			width="40%";
			height="40%";
			x="55%";
			y="10%";
			file = image_repeat,
			keepAspect = true,
		}
	elseif array == comms then
		array[i].healthbar = Progressbar:New{
			parent  = array[i].image,
			x		= 0,
			width   = "100%";
			height	= "15%",
			y = "85%",
			max     = 1;
			caption = "";
			color   = {0,0.8,0,1};
		}	
	end
	
	UpdateBackgroundSize()
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Factory Handling

--shifts facs when one of their kind is removed
local function ShiftFacRow()
	for i=1,#facs do
		if facs[i].holder then
			facs[i].holder:Dispose()
			facs[i].holder = nil
		end
	end
	for i = 1, #facs do
		GenerateButton(facs, i, facs[i].facID, facs[i].facDefID, WG.crude.GetHotkey(SELECT_FACTORY .. i) or '')
		UpdateFac(facs[i].facID, i)
	end
end

local function AddFac(unitID, unitDefID)
	local i = #facs + 1
	facs[i] = {facID = unitID, facDefID = unitDefID}
	GenerateButton(facs, i, unitID, unitDefID, WG.crude.GetHotkey(SELECT_FACTORY .. i) or '')
	facsByID[unitID] = i
	UpdateFac(unitID, i)
end

local function RemoveFac(unitID)
	local index = facsByID[unitID]
	-- move everything to the left
	local shift = false
	if facs[index].holder then
		facs[index].holder:Dispose()
		facs[index].holder = nil
	end		
	table.remove(facs, index)
	for facID,i in pairs(facsByID) do
		if i > index then
			facsByID[facID] = i - 1
			shift = true
		end
	end
	facsByID[unitID] = nil
	if shift then
		ShiftFacRow()
	end
	UpdateBackgroundSize()
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Commander handling

local function UpdateComm(unitID, index)
	if not comms[index].button then
		return
	end

	local health, maxHealth = GetUnitHealth(unitID)
	if not health then
		return
	end

	comms[index].healthbar.color = GetHealthColor(health/maxHealth)
	comms[index].healthbar:SetValue(health/maxHealth)
	
	comms[index].button.tooltip = WG.Translate("interface", "commander") .. ": " .. Spring.Utilities.GetHumanName(UnitDefs[comms[index].commDefID], unitID) ..
							"\n\255\0\255\255" .. WG.Translate("interface", "health") .. ":\008 "..GetHealthColor(health/maxHealth, "char")..math.floor(health).."/"..maxHealth.."\008"..
							"\n\255\0\255\0" .. WG.Translate("interface", "lmb") .. ": " .. (options.leftMouseCenter.value and WG.Translate("interface", "select_and_go_to") or WG.Translate("interface", "select")) ..
							"\n" .. WG.Translate("interface", "rmb") .. ": " .. ((not options.leftMouseCenter.value) and WG.Translate("interface", "select_and_go_to") or WG.Translate("interface", "select")) ..
							"\n" .. WG.Translate("interface", "shift") .. ": " .. WG.Translate("interface", "append_to_current_selection") .. "\008"
end

local function AddComm(unitID, unitDefID)
	local i = #comms + 1
	comms[i] = {commID = unitID, commDefID = unitDefID, warningTime = -1}
	GenerateButton(comms, i, unitID, unitDefID, WG.crude.GetHotkey("selectcomm") or '')
	commsByID[unitID] = i
	UpdateComm(unitID, i)
	ShiftFacRow()
end

--shifts comms when one of their kind is removed
local function ShiftCommRow()
	for i=1,#comms do
		if comms[i].holder then
			comms[i].holder:Dispose()
			comms[i].holder = nil
		end
	end
	for i=1,#comms do
		GenerateButton(comms, i, comms[i].commID, comms[i].commDefID)
		UpdateComm(comms[i].commID, i)
	end	
end

local function RemoveComm(unitID)
	local index = commsByID[unitID]
	-- move everything to the left
	if comms[index].holder then
		comms[index].holder:Dispose()
		comms[index].holder = nil
	end		
	table.remove(comms, index)
	for commID,i in pairs(commsByID) do
		if i > index then
			commsByID[commID] = i - 1
		end
	end
	commsByID[unitID] = nil
	ShiftCommRow()
	ShiftFacRow()
	
	UpdateBackgroundSize()
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Constructor Handling

local function UpdateConsButton()

	local prevTotal = idleCons.count or 0
	idleCons.count = nil
	local total = 0
	for unitID in pairs(idleCons) do
		total = total + 1
	end

	conButton.button.tooltip = WG.Translate("interface", "idle_cons", {count = total}) ..
								"\n\255\0\255\0" .. WG.Translate("interface", "lmb") .. ": " .. WG.Translate("interface", "select") ..
								"\n" .. WG.Translate("interface", "rmb") .. ": " .. WG.Translate("interface", "select_all") .. "\008"

	if ((total > 0 and prevTotal == 0) or (total == 0 and prevTotal > 0)) then
		conButton.image.file = (total > 0 and buildIcon) or buildIcon_bw
		conButton.image.color = (total == 0 and imageColorDisabled) or nil
		conButton.image:Invalidate()
		conButton.button.backgroundColor = (total == 0 and buttonColorDisabled) or buttonColor
		conButton.button:Invalidate()
	end

	if conButton.countLabel then
		conButton.countLabel:SetCaption(tostring(total))
	end
	idleCons.count = total
end

RefreshConsList = function()
	idleCons = {}
	if Spring.GetGameFrame() > 1 and myTeamID then
		local unitList = Spring.GetTeamUnits(myTeamID)
		for _,unitID in pairs(unitList) do
			local unitDefID = GetUnitDefID(unitID)
			if unitDefID then
				widget:UnitFinished(unitID, unitDefID, myTeamID)
			end
		end
		UpdateConsButton()
	end
end

local function InitializeUnits()
	if Spring.GetGameFrame() > 1 and myTeamID then
		local unitList = Spring.GetTeamUnits(myTeamID)
		for _,unitID in pairs(unitList) do
			local unitDefID = GetUnitDefID(unitID)
			--Spring.Echo(unitID, unitDefID)
			if unitDefID then
				widget:UnitCreated(unitID, unitDefID, myTeamID)
				widget:UnitFinished(unitID, unitDefID, myTeamID)
			end
		end
	end
end

ClearData = function(goingToReintializeSoDoNotBotherWithUpdate)
	while facs[1] do
		RemoveFac(facs[1].facID)
	end
	while comms[1] do
		RemoveComm(comms[1].commID)
	end
	idleCons = {}
	if not goingToReintializeSoDoNotBotherWithUpdate then
		UpdateConsButton()
	end
end

-- FIXME: donut work?
-- removes nanos from current selection
--[[
local function StripNanos()
	local units = Spring.GetSelectedUnits()
	local units2 = {}
	for i=1,#units do
		local udID = GetUnitDefID(units[i])
		if not(nanos[udID]) then
			Spring.Echo(#units2+1)
			units2[#units2 + 1] = units[i]
		end
	end
	SelectUnitArray(units2, false)
end
]]--

-- comm selection functionality
local commIndex = 1
local function SelectComm()
	local commCount = #comms
	if commCount <= 0 then 
		-- no comms, don't bother
		return 
	end
	
	-- This check deals with the case of spectators selecting
	-- teams with different numbers of commanders.
	if commCount < commIndex then
		commIndex = commCount
	end
	
	local unitID
	-- Loop long enough to check every commander.
	-- The most recently Ctrl+C selected commander is checked last.
	-- Select the first non-selected commander encountered.
	for i = 1, commCount do
		unitID = comms[commIndex].commID
		commIndex = commIndex + 1
		if commIndex > commCount then
			commIndex = 1
		end
		if not Spring.IsUnitSelected(unitID) then
			break
		end
	end
	
	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	Spring.SelectUnitArray({unitID}, shift)
	if not shift then
		local x, y, z = Spring.GetUnitPosition(unitID)
		SetCameraTarget(x, y, z)
	end
end

local mapMiddle = {Game.mapSizeX / 2, 0, Game.mapSizeZ / 2}
local function SelectPrecBomber()

	-- Check to see if anything other than a ready bomber is selected
	--	If not, then we'll increment the number of ready bombers selected
	--	If so, then we'll either:
	--		Select one ready bomber if none are selected
	--		Select only the already selected ready bombers if at least one is selected	
	
	local toBeSelected = {}
	
	local currentSelection = Spring.GetSelectedUnits()
	local isAnythingElseSelected = nil
	for i,uid in ipairs(currentSelection) do
		if not readyUntaskedBombers[uid] then
			isAnythingElseSelected = true
			break
		end
	end
	
	local mx,my = GetMouseState()
	local pos = select(2, TraceScreenRay(mx,my,true)) or mapMiddle
	local mindist = math.huge
	local muid = nil

	for uid, v in pairs(readyUntaskedBombers) do
		if (Spring.IsUnitSelected(uid)) then
			table.insert(toBeSelected,uid)
		else
			local x,_,z = GetUnitPosition(uid)
			dist = (pos[1]-x)*(pos[1]-x) + (pos[3]-z)*(pos[3]-z)
			if (dist < mindist) then
				mindist = dist
				muid = uid
			end
		end
	end
	if (muid ~= nil) and (not isAnythingElseSelected or #toBeSelected == 0) then
		table.insert(toBeSelected,muid)
	end
	Spring.SelectUnitArray(toBeSelected)
end

local function SelectIdleCon_all()
	Spring.SelectUnitMap(idleCons, select(4, Spring.GetModKeyState()))
end

local conIndex = 1
local function SelectIdleCon()
	local shift = select(4, Spring.GetModKeyState())
	if shift then
		local mx,my = GetMouseState()
		local pos = select(2, TraceScreenRay(mx,my,true)) or mapMiddle
		local mindist = math.huge
		local muid = nil

		for uid, v in pairs(idleCons) do
			if uid ~= "count" then
				if (not Spring.IsUnitSelected(uid)) then
					local x,_,z = GetUnitPosition(uid)
					dist = (pos[1]-x)*(pos[1]-x) + (pos[3]-z)*(pos[3]-z)
					if (dist < mindist) then
						mindist = dist
						muid = uid
					end
				end
			end
		end

		Spring.SelectUnitArray({muid}, true)
	else
		if idleCons.count == 0 then
			Spring.SelectUnitArray({})
		else
			conIndex = (conIndex % idleCons.count) + 1
			local i = 1
			for uid, v in pairs(idleCons) do
				if uid ~= "count" then
					if i == conIndex then
						Spring.SelectUnitArray({uid})
						SetCameraTarget(Spring.GetUnitPosition(uid))
						return
					else
						i = i + 1
					end
				end
			end
		end
	end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- engine callins

--[[
function widget:GameStart()
	gamestart = true
end
]]--

-- Check current cmdID and the queue for a double-wait
local function isDoubleWait(unitID, cmdID)
	if cmdID==CMD.WAIT then
		local cmdsLen=Spring.GetCommandQueue(unitID,0)
		if cmdsLen==1 then
			local cmds=Spring.GetCommandQueue(unitID,1)
			return cmds[1].id==CMD.WAIT
		end
	end
	return false
end

-- Check the queue for an attack command
local function isAttackQueued(unitID)
	local cmdsLen=Spring.GetCommandQueue(unitID,0)
	if cmdsLen and (cmdsLen > 0) then
		local cmds=Spring.GetCommandQueue(unitID,-1)
		for i=1,cmdsLen do
			if cmds and cmds[i] and ((cmds[i].id==CMD.ATTACK) or (cmds[i].id==CMD.AREA_ATTACK)) then
				return true
			end
		end
	end
	return false
end

-- Check to see if the bomber is ready and untasked
local function setBomberReadyStatus(unitID)
	local noAmmo = GetUnitRulesParam(unitID, "noammo")
	if (noAmmo and noAmmo ~= 0) or select(3, Spring.GetUnitIsStunned(unitID)) or isAttackQueued(unitID) then
		readyUntaskedBombers[unitID] = nil
	else
		readyUntaskedBombers[unitID] = true
	end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	if (not myTeamID or unitTeam ~= myTeamID) then
		return
	end
	local ud = UnitDefs[unitDefID]
	
	if ud.isFactory and (not exceptionArray[unitDefID]) then
		AddFac(unitID, unitDefID)
	elseif ud.customParams.level then
		AddComm(unitID, unitDefID)
	elseif options.monitorInbuiltCons.value and ((ud.buildSpeed > 0) and (not exceptionArray[unitDefID]) and (not ud.isFactory)
	and (options.monitoridlecomms.value or not ud.customParams.dynamic_comm)
	and (options.monitoridlenano.value or ud.canMove)) then
		idleCons[unitID] = true
		wantUpdateCons = true
	end
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if (not myTeamID or unitTeam ~= myTeamID) or exceptionArray[unitDefID] then
		return
	end
	local ud = UnitDefs[unitDefID]
	if GetUnitCanBuild(unitID, unitDefID) then  --- can build
		local bQueue = GetFullBuildQueue(unitID)
		if not bQueue[1] then  --- has no build queue
			local _, _, _, _, buildProg = GetUnitHealth(unitID)
			if not ud.isFactory then
				local cQueue = Spring.GetCommandQueue(unitID, 1)
				--Spring.Echo("Con "..unitID.." queue "..tostring(cQueue[1]))
				if not cQueue[1] then
					--Spring.Echo("\tCon "..unitID.." must be idle")
					widget:UnitIdle(unitID, unitDefID, myTeamID)
				end
			end
		end
	end
	local unitName = UnitDefs[unitDefID].name
	if (unitName  == "corshad") then
		setBomberReadyStatus(unitID)
	end
end

function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
  widget:UnitCreated(unitID, unitDefID, unitTeam)
  widget:UnitFinished(unitID, unitDefID, unitTeam)  
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if (not myTeamID or unitTeam ~= myTeamID) then
		return
	end
	if idleCons[unitID] then
		idleCons[unitID] = nil
		wantUpdateCons = true
	end	
	if readyUntaskedBombers[unitID] then
		readyUntaskedBombers[unitID] = nil
	end	
	if facsByID[unitID] then
		RemoveFac(unitID)
	elseif commsByID[unitID] then
		RemoveComm(unitID)
	end
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
  widget:UnitDestroyed(unitID, unitDefID, unitTeam)
end

function widget:UnitIdle(unitID, unitDefID, unitTeam)
	if (unitTeam ~= myTeamID) then
		return
	end
	local ud = UnitDefs[unitDefID]
	if (ud.buildSpeed > 0) and (not exceptionArray[unitDefID]) and (not UnitDefs[unitDefID].isFactory)
	and (options.monitoridlecomms.value or not UnitDefs[unitDefID].customParams.dynamic_comm)
	and (options.monitoridlenano.value or UnitDefs[unitDefID].canMove) then
		idleCons[unitID] = true
		wantUpdateCons = true
	end
	local unitName = UnitDefs[unitDefID].name
	if (unitName  == "corshad") then
		setBomberReadyStatus(unitID)
	end
end

function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdOpts, cmdParams)
	if (not myTeamID or unitTeam ~= myTeamID) then
		return
	end
	if cmdID and stateCommands[cmdID] then
		return
	end
	
	-- Double wait means the same as an empty queue
	-- It is just an engine hack
	if isDoubleWait(unitID,cmdID) then
		widget:UnitIdle(unitID,unitDefID,unitTeam)
		return
	end
	
	if idleCons[unitID] then
		idleCons[unitID] = nil
		wantUpdateCons = true
	end

	local unitName = UnitDefs[unitDefID].name
	if (unitName  == "corshad") then
		setBomberReadyStatus(unitID)
	end
end

local timer = 0
local warningColorPhase = false
function widget:Update(dt)
	if myTeamID ~= Spring.GetMyTeamID() then
		--Spring.Echo("<Core Selector>: Spectator mode. Widget removed.")
		--widgetHandler:RemoveWidget()
		--return false
		myTeamID = Spring.GetMyTeamID()
		ClearData(false)
		InitializeUnits()
	end
	
	if wantUpdateCons then
		UpdateConsButton()
		wantUpdateCons = false
	end

	timer = timer + dt
	if timer < UPDATE_FREQUENCY then
		return
	end

	wantUpdateCons = true

	for i=1,#facs do
		UpdateFac(facs[i].facID, i)
	end
	for i=1,#comms do
		UpdateComm(comms[i].commID, i)
	end
	warningColorPhase = not warningColorPhase
	for i=1,#comms do
		local comm = comms[i]
		if comm.button and comm.warningTime > 0 then
			comm.warningTime = comm.warningTime - timer
			if comm.warningTime > 0 then
				comms[i].button.backgroundColor = (warningColorPhase and buttonColorWarning) or buttonColor
			else
				comms[i].button.backgroundColor = buttonColor
			end
			comms[i].button:Invalidate()
		end
	end	
	timer = 0
end

-- for "under attack" achtung sign
function widget:UnitDamaged(unitID, unitDefID, unitTeam)
	if commsByID[unitID] then
		comms[commsByID[unitID]].warningTime = commWarningTime
	end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

function widget:Initialize()
	if (not WG.Chili) then
		widgetHandler:RemoveWidget(widget)
		return
	end
	
	widgetHandler:AddAction("selectcomm", SelectComm, nil, 'tp')
	widgetHandler:AddAction("selectprecbomber", SelectPrecBomber, nil, 'tp')
	widgetHandler:AddAction("selectidlecon", SelectIdleCon, nil, 'tp')
	widgetHandler:AddAction("selectidlecon_all", SelectIdleCon_all, nil, 'tp')

	-- setup Chili
	Chili = WG.Chili
	Button = Chili.Button
	Control = Chili.Control
	Label = Chili.Label
	Window = Chili.Window
	Panel = Chili.Panel
	Image = Chili.Image
	Progressbar = Chili.Progressbar
	screen0 = Chili.Screen0

	-- Set the size for the default settings.
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	local BUTTON_WIDTH = math.min(60, screenHeight/16)
	local BUTTON_HEIGHT = 55*BUTTON_WIDTH/60
	local integralWidth = math.max(350, math.min(450, screenWidth*screenHeight*0.0004))
	local integralHeight = math.min(screenHeight/4.5, 200*integralWidth/450)
	local bottom = integralHeight
	
	local hPad = options.horPadding.value
	local vPad = options.vertPadding.value
	
	stack_main = Panel:New{
		padding = {hPad, vPad, hPad, vPad},
		itemMargin = {0, 0, 0, 0},
		width= '100%',
		height = '100%',
		backgroundColor = {0, 0, 0, 0},
		OnResize = {
			UpdateBackgroundSize,
			UpdateButtonPositions
		}
	}
	background = Panel:New{
		itemMargin = {0, 0, 0, 0},
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		backgroundColor = {1, 1, 1, options.background_opacity.value},
	}
	
	local windowY = bottom - BUTTON_HEIGHT * ((options.vertical.value and options.maxbuttons.value) or 1) + 2*vPad
	
	local windowWidth, windowHeight
	if options.vertical.value then
		windowWidth  = BUTTON_WIDTH + 2*hPad
		windowHeight = (BUTTON_HEIGHT + 2*options.buttonSpacing.value) * options.maxbuttons.value + 2*vPad
	else
		windowWidth  = (BUTTON_WIDTH + 2*options.buttonSpacing.value) * options.maxbuttons.value + 2*hPad
		windowHeight = BUTTON_HEIGHT + 2*vPad
	end
	
	window_selector = Window:New{
		padding = {-1,0,0,0},
		itemMargin = {0, 0, 0, 0},
		dockable = true,
		name = "selector_window",
		x = windowPositionX or 0, 
		y = windowPositionY or windowY,
		width  = windowWidth,
		height = windowHeight,
		parent = Chili.Screen0,
		draggable = false,
		tweakDraggable = true,
		tweakResizable = true,
		resizable = false,
		dragUseGrip = false,
		minWidth = 32,
		minHeight = 32,
		color = {0,0,0,0},
		children = {
			stack_main,
			background,
		},
		OnClick={ function(self)
			local alt, ctrl, meta, shift = Spring.GetModKeyState()
			if not meta then return false end
			WG.crude.OpenPath(options_path)
			WG.crude.ShowMenu()
			return true
		end },
	}
	
	if options.fancySkinning.value then
		options.fancySkinning.OnChange(options.fancySkinning)
	end

	if WG.crude.GetHotkey("selectidlecon") and WG.crude.GetHotkey("selectidlecon_all") then
		hotkeyCaption = "\255\0\255\0" .. WG.crude.GetHotkey("selectidlecon") .. "\n" .. WG.crude.GetHotkey("selectidlecon_all")
	else
		hotkeyCaption = "\255\0\255\0" .. (WG.crude.GetHotkey("selectidlecon") or WG.crude.GetHotkey("selectidlecon_all") or '')
	end
	
	local conX, conY, conWidth, conHeight = GetButtonPosition(1)
	
	local hPadCon = ((not options.vertical.value) and options.buttonSpacing.value) or 0
	local vPadCon = (options.vertical.value and options.buttonSpacing.value) or 0
	
	conButton.holder = Control:New{
		parent = stack_main,
		x = conX,
		y = conY,
		width = conWidth,
		height = conHeight,
		padding = {hPadCon, vPadCon, hPadCon, vPadCon},
	}
	
	conButton.button = Button:New{
		parent = conButton.holder;
		caption = '',
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		OnClick = {	function (self, x, y, mouse)
				local meta = select(3, Spring.GetModKeyState())
				if meta then
					WG.crude.OpenPath(options_path)
					WG.crude.ShowMenu()
					return true
				end
				if mouse == 1 then
					SelectIdleCon()
				elseif mouse == 3 and idleCons.count > 0 then
					SelectIdleCon_all()
				end
			end},
		padding = {1,1,1,1},
		children = {
			Label:New {
				width="100%";
				height="100%";
				autosize=false;
				x=2,
				y=3,
				align="left";
				valign="top";
				caption = hotkeyCaption,
				fontSize = 11;
				fontShadow = true;
				parent = button;
			}
		}
		--keepAspect = true,
	}
	conButton.image = Image:New {
		parent = conButton.button,
		x = "2%",
		y = "6%",
		right = "2%",
		bottom = "6%",
		file = buildIcon,	--'#'..idleBuilderDefID,
		--file2 = "bitmaps/icons/frame_cons.png",
		keepAspect = false,
		color = (total == 0 and imageColorDisabled) or nil,
	}
	conButton.countLabel = Label:New {
		parent = conButton.image,
		autosize=false;
		width="100%";
		height="100%";
		align="right";
		valign="bottom";
		caption = "0";
		fontSize = 16;
		fontShadow = true;
	}
	buttonColor = conButton.button.color
	UpdateConsButton()

	myTeamID = Spring.GetMyTeamID()
	
	local viewSizeX, viewSizeY = widgetHandler:GetViewSizes()
	self:ViewResize(viewSizeX, viewSizeY)
	
	InitializeUnits()
	
	hidden = false
	CheckHide()
end

function widget:Shutdown()
	widgetHandler:RemoveAction("selectcomm")
	widgetHandler:RemoveAction("selectprecbomber")
end
