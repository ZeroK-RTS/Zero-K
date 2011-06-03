-------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Core Selector",
    desc      = "v0.1 Manage your boi, idle cons, and factories.",
    author    = "KingRaptor",
    date      = "2011-6-2",
    license   = "GNU GPL, v2 or later",
    layer     = 1001,
    enabled   = false,
  }
end


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

WhiteStr   = "\255\255\255\255"
GreyStr    = "\255\210\210\210"
GreenStr   = "\255\092\255\092"

local buttonColor = {1,1,1,0.7}
local buttonColorDisabled = {0.2,0.2,0.2,1}
local imageColor = {1,1,1,1}
local imageColorDisabled = {0.3, 0.3, 0.3, 1}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Chili
local Button
local Label
local Window
local StackPanel
local Image
local Progressbar
local screen0
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local window_selector, stack_main
local commButton, conButton = {}, {}

local echo = Spring.Echo

local BUTTON_WIDTH = 64
local BUTTON_HEIGHT = 64
local MAX_COLUMNS = 8

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

--options_path = 'Settings/Interface/ConManager'
--options = {}

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
local UPDATE_FREQUENCY = 0.1

local exceptionList = {
	armasp = true,
	armcarry = true,
}

local exceptionArray = {}
for name in pairs(exceptionList) do
	if UnitDefNames[name] then
		exceptionArray[UnitDefNames[name].id] = true
	end
end


-- list and interface vars
local facs = {}
local facButtons = {}
local comms = {}
local currentComm
local defaultCommDefID = UnitDefNames.armcom1.id
local idleCons = {}
local idleBuilderDefID = UnitDefNames.armrectr.id

local myTeamID = 0
--local inTweak  = false
--local leftTweak, enteredTweak = false, false
--local cycle_half_s = 1
--local cycle_2_s = 1

-------------------------------------------------------------------------------
local image_repeat    = LUAUI_DIRNAME .. 'Images/repeat.png'

local teamColors = {}
local GetTeamColor = Spring.GetTeamColor or function (teamID)
  local color = teamColors[teamID]
  if (color) then return unpack(color) end
  local _,_,_,_,_,_,r,g,b = Spring.GetTeamInfo(teamID)
  teamColors[teamID] = {r,g,b}
  return r,g,b
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

local GetUnitDefID      = Spring.GetUnitDefID
local GetUnitHealth     = Spring.GetUnitHealth
local GetUnitStates     = Spring.GetUnitStates
local DrawUnitCommands  = Spring.DrawUnitCommands
local GetSelectedUnits  = Spring.GetSelectedUnits
local GetFullBuildQueue = Spring.GetFullBuildQueue
local GetUnitIsBuilding = Spring.GetUnitIsBuilding

local push        = table.insert


-------------------------------------------------------------------------------

local function GetBuildQueueFirstItem(unitID)
  local queue = GetFullBuildQueue(unitID)
  if (queue ~= nil) then
    for udid, count in ipairs(queue) do
		return udid
	end
  end
end

local function SetCount(set)
  local count = 0
  for k in pairs(set) do
    count = count + 1
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
	return {r, g*0.8, 0, 1}
end

-------------------------------------------------------------------------------
local function UpdateCommButton()
	local commDefID = currentComm and GetUnitDefID(currentComm) or defaultCommDefID
	commButton.image = Image:New {
		parent = commButton.button,
		width="90%";
		height="90%";
		x="5%";
		y="5%";
		file = '#'..commDefID,
		keepAspect = false,
		color = (not currentComm and imageColorDisabled) or nil,
	}
	commButton.button.backgroundColor = (currentComm and buttonColor) or buttonColorDisabled
	commButton.button:Invalidate()
	if currentComm then
		commButton.image:AddChild(commButton.healthbar)
	else
		commButton.image:RemoveChild(commButton.healthbar)
	end
end

local function UpdateFac(unitID)
end

local function AddFac(unitID)
	
end

local function RemoveFac(unitID)
end

local function UpdateComm()	-- just health
	if not currentComm then return end
	local health, maxHealth = GetUnitHealth(currentComm)
	commButton.healthbar:SetValue(health/maxHealth)
	commButton.healthbar.color = GetHealthColor(health/maxHealth)
	commButton.healthbar:Invalidate()
	
	if not currentComm then
		commButton.button.tooltip = "Your commander is dead...sorry..."
	else
		local commDefID = GetUnitDefID(currentComm)
		commButton.button.tooltip = "Commander: "..UnitDefs[commDefID].humanName ..
									"\n\255\0\255\255Health:\008 "..GetHealthColor(health/maxHealth, "char")..math.floor(health).."/"..maxHealth.."\008"..
									"\n\255\0\255\0Left-click: Select and go to"..
									"\nRight-click: Cycle commander (if available)\008"
	end	
end

local function UpdateCommFull()	-- regenerates image etc.
	commButton.image:Dispose()
	UpdateCommButton()
	UpdateComm()
end

local function AddComm(unitID)
	comms[unitID] = true
	if not currentComm then
		currentComm = unitID
		defaultCommDefID = GetUnitDefID(unitID)
		UpdateCommFull()
	end
end

local function CycleComm()
	if SetCount(comms) == 0 then
		return
	end
	local savedPos = 1
	local commsOrdered = {}
	
	-- ipairs breaks for some inane reason
	-- thankfully pairs preserves a constant order as long as the table remains constant, so we can use it
	for unitID in pairs(comms) do	
		local i = #commsOrdered+1
		commsOrdered[i] = unitID
		if unitID == currentComm then
			savedPos = i
		end
	end
	if #commsOrdered == savedPos then
		currentComm = commsOrdered[1]
	else
		currentComm = commsOrdered[savedPos+1]
	end
end

local function UpdateCons()
	-- get con type with highest number of idlers (as well as number of types total)
	local prevTotal = idleCons.count
	idleCons.count = nil
	local maxDefID = idleBuilderDefID
	local maxCount, total = 0, 0
	local types = {}
	for unitID in pairs(idleCons) do
		local def = GetUnitDefID(unitID)
		types[def] = (types[def] or 0) + 1
		total = total + 1
	end
	local numTypes = SetCount(types)
	for defID, num in pairs(types) do
		if num > maxCount then
			maxDefID = defID
			maxCount = num
		end
	end
	
	if (idleBuilderDefID ~= maxDefID or total == 0 or prevTotal == 0) then
		conButton.image:Dispose()
		conButton.image = Image:New {
			parent = conButton.button,
			width="90%";
			height="90%";
			x="5%";
			y="5%";
			file = '#'..maxDefID,
			keepAspect = false,
			color = (total == 0 and imageColorDisabled) or nil,
		}
		idleBuilderDefID = maxDefID
	end
	conButton.button.tooltip = "You have ".. total .. " idle cons, of "..numTypes.." different types."..
								"\n\255\0\255\0Left-click: Select one and go to"..
								"\nRight-click: Select all\008"
	idleCons.count = total
	total = (total > 0 and tostring(total)) or ''
	if conButton.countLabel then
		conButton.countLabel:Dispose()
	end
	conButton.countLabel = Label:New {
		parent = conButton.image,
		autosize=false;
		width="100%";
		height="100%";
		align="right";
		valign="bottom";
		caption = total;
		fontSize = 16;
		fontShadow = true;
	}
end

local function InitializeUnits()
	if Spring.GetGameFrame() > 1 then
		local unitList = Spring.GetTeamUnits(myTeamID)
		for _,unitID in pairs(unitList) do
			local unitDefID = GetUnitDefID(unitID)
			--Spring.Echo(unitID, unitDefID)
			if unitDefID then
				widget:UnitCreated(unitID, unitDefID, myTeamID)
				local ud = UnitDefs[unitDefID]
				if ud.buildSpeed > 0 then  --- can build
					local bQueue = GetFullBuildQueue(unitID)
					if not bQueue[1] then  --- has no build queue
						local _, _, _, _, buildProg = GetUnitHealth(unitID)
						if buildProg == 1 then  --- isnt under construction
							if not ud.isFactory then
								local cQueue = Spring.GetCommandQueue(unitID)
								if not cQueue[1] then
									widget:UnitIdle(unitID, unitDefID, myTeamID)
								end
							end
						end
					end
				end
			end
		end
	end
end

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-- engine funcs

function widget:UnitCreated(unitID, unitDefID, unitTeam)
  if (unitTeam ~= myTeamID) then
    return
  end

  if UnitDefs[unitDefID].isFactory then
  
  elseif UnitDefs[unitDefID].isCommander then
	AddComm(unitID)
  end
end

function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
  widget:UnitCreated(unitID, unitDefID, unitTeam)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if (unitTeam ~= myTeamID) then
		return
	end
	idleCons[unitID] = nil  
	if UnitDefs[unitDefID].isFactory then
	
	elseif comms[unitID] then
		comms[unitID] = nil
		if unitID == currentComm then
			commButton.healthbar:SetValue(0)
			currentComm = nil
			CycleComm()
			UpdateCommFull()
		end
	end
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
  widget:UnitDestroyed(unitID, unitDefID, unitTeam)
end


local timer = 0
function widget:Update(dt)
	if myTeamID~=Spring.GetMyTeamID() then
		myTeamID = Spring.GetMyTeamID()
	end
	timer = timer + dt
	if timer < UPDATE_FREQUENCY then
		return
	end	
	UpdateComm()
	timer = 0
end

function widget:UnitIdle(unitID, unitDefID, unitTeam)
	local ud = UnitDefs[unitDefID]
	if (ud.buildSpeed > 0) and (not exceptionArray[unitDefID]) and (not UnitDefs[unitDefID].isFactory) then
		idleCons[unitID] = true
		UpdateCons()
	end
end

function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdId, cmdOpts, cmdParams)
	if idleCons[unitID] then
		idleCons[unitID] = nil
		UpdateCons()
	end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

function widget:Initialize()
	if (not WG.Chili) then
		widgetHandler:RemoveWidget(widget)
		return
	end

	-- setup Chili
	Chili = WG.Chili
	Button = Chili.Button
	Label = Chili.Label
	Window = Chili.Window
	StackPanel = Chili.StackPanel
	Image = Chili.Image
	Progressbar = Chili.Progressbar
	screen0 = Chili.Screen0

	stack_main = StackPanel:New{
		x = 0,
		y = 0,
		padding = {0,0,0,0},
		itemPadding = {0, 0, 0, 0},
		itemMargin = {0, 0, 0, 0},
		width= '100%',
		height = '100%',
		resizeItems = true,
		orientation = 'horizontal',
	}
	window_selector = Window:New{
		padding = {0,0,0,0},
		itemPadding = {0, 0, 0, 0},
		dockable = true,
		name = "selector_window",
		x = 0, 
		y = "30%",
		width  = 512,
		height = 64,
		parent = Chili.Screen0,
		draggable = false,
		tweakDraggable = true,
		tweakResizable = true,
		resizable = false,
		dragUseGrip = false,
		--minimumSize = {300,64},
		color = {0,0,0,0},
		children = {
			stack_main,
		},
	}
	commButton.button = Button:New{
		parent = stack_main;
		y = 0,
		width = tostring(100/MAX_COLUMNS).."%",
		height = "100%",
		caption = '',
		OnMouseDown = {	function () 
				local _,_,left,_,right = Spring.GetMouseState()
				if left and currentComm then
					Spring.SelectUnitArray({currentComm}, false)
					local x, y, z = Spring.GetUnitPosition(currentComm)
					Spring.SetCameraTarget(x, y, z)
				elseif right then
					CycleComm()
					UpdateCommFull()
				end
			end},
		padding = {1,1,1,1},
		disabled = true,
		keepAspect = true,
		backgroundColor = (not currentComm and buttonColorDisabled) or nil,
	}
	commButton.healthbar = Progressbar:New{
		name	= "commhealthbar",
		x		= 0,
		width   = "100%";
		height	= "15%",
		y = "85%",
		max     = 1;
		caption = "";
		color   = {0,0.8,0,1};
	}	
	UpdateCommButton()

	
	conButton.button = Button:New{
		parent = stack_main;
		x = tostring(100/MAX_COLUMNS).."%",
		y = 0,
		width = tostring(100/MAX_COLUMNS).."%",
		height = "100%",
		caption = '',
		OnMouseDown = {	function () 
				local _,_,left,_,right = Spring.GetMouseState()
				if left then
					Spring.SendCommands({"select AllMap+_Builder_Not_Building_Idle+_ClearSelection_SelectOne+"})
				elseif right and idleCons.count > 0 then
					Spring.SelectUnitMap(idleCons, false)
				end
			end},
		padding = {1,1,1,1},
		disabled = true,
		keepAspect = true,
	}
	conButton.image = Image:New {
		parent = conButton.button,
		width="90%";
		height="90%";
		x="5%";
		y="5%";
		file = '#'..idleBuilderDefID,
		keepAspect = false,
	}
	UpdateCons()
	
	myTeamID = Spring.GetMyTeamID()

	--UpdateFactoryList()

	local viewSizeX, viewSizeY = widgetHandler:GetViewSizes()
	self:ViewResize(viewSizeX, viewSizeY)
	
	InitializeUnits()
end
