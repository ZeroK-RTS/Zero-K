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
local GetUnitDefID      = Spring.GetUnitDefID
local GetUnitHealth     = Spring.GetUnitHealth
local GetUnitStates     = Spring.GetUnitStates
local DrawUnitCommands  = Spring.DrawUnitCommands
local GetSelectedUnits  = Spring.GetSelectedUnits
local GetFullBuildQueue = Spring.GetFullBuildQueue
local GetUnitIsBuilding = Spring.GetUnitIsBuilding
local GetGameSeconds	= Spring.GetGameSeconds
local GetGameFrame 		= Spring.GetGameFrame
local GetMouseState		= Spring.GetMouseState
local GetModKeyState	= Spring.GetModKeyState
local SelectUnitArray	= Spring.SelectUnitArray

local push        = table.insert

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
WhiteStr   = "\255\255\255\255"
GreyStr    = "\255\210\210\210"
GreenStr   = "\255\092\255\092"

local buttonColor = {1, 1, 1, 1}
local buttonColorFac = {0.6, 0.6, 0.6, 0.3}
local buttonColorWarning = {1, 0.2, 0.1, 1}
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
local conButton = {}	-- {button, image, healthbar/label}
local commButton = {}	-- unused

local echo = Spring.Echo

local BUTTON_WIDTH = 64
local BUTTON_HEIGHT = 52
local BASE_COLUMNS = 8
local NUM_FAC_COLUMNS = BASE_COLUMNS - 1	-- unused

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

local nano_name = UnitDefNames.armnanotc.humanName

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

--local gamestart = GetGameFrame() > 1
local myTeamID = false
local commWarningTime		= 2*30 -- how long to flash button frame, gameframes
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

local function RefreshConsList() end	-- redefined later

options_path = 'Settings/Interface/Core Selector'
options_order = { 'monitoridlecomms', 'monitoridlenano'}
options = {
	monitoridlecomms = {
		name = 'Track idle comms',
		type = 'bool',
		value = true,
		OnChange = function() RefreshConsList() end,		
	},
	monitoridlenano = {
		name = 'Track idle nanotowers',
		type = 'bool',
		value = true,
		OnChange = function() RefreshConsList() end,		
	},
}

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

local function SetCount(set, numOnly)
	local count = 0
	if numOnly then
		for k in ipairs(set) do
			count = count + 1
		end
	else
		for k in pairs(set) do
			count = count + 1
		end	
	end
	return count
end

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

-------------------------------------------------------------------------------
-- core functions

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

	local tooltip = "Factory: "..UnitDefs[facs[index].facDefID].humanName
	tooltip = tooltip .. "\n" .. count .. " item(s) in queue"
	if rep then
		tooltip = tooltip .. "\255\0\255\255 (repeating)\008"
	end
	if buildeeDefID then
		local buildeeDef = UnitDefs[buildeeDefID]
		tooltip = tooltip .. "\nCurrent project: "..buildeeDef.humanName.." ("..math.floor(progress*100).."% done)"
	end
	facs[index].button.tooltip = tooltip .. "\n\255\0\255\0Left-click: Select and go to"..
										"\nRight-click: Select"..
										"\nShift: Append to current selection\008"
										
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
	if CountButtons(comms) + (array == facs and CountButtons(facs) or 0) > BASE_COLUMNS - 1 then
		return
	end
	
	local pos = i
	if array == facs then
		pos = pos + CountButtons(comms)
	end
	array[i].button = Button:New{
		parent = stack_main;
		x = (pos)*(100/BASE_COLUMNS).."%",
		y = 0,
		width = (100/BASE_COLUMNS).."%",
		height = "100%",
		caption = '',
		OnMouseDown = {	function () 
				local _,_,left,_,right = GetMouseState()
				local shift = select(4, GetModKeyState())
				SelectUnitArray({unitID}, shift)
				if left then
					local x, y, z = Spring.GetUnitPosition(unitID)
					Spring.SetCameraTarget(x, y, z)
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
end

--shifts facs when one of their kind is removed
local function ShiftFacRow()
	for i in ipairs(facs) do
		if facs[i].button then
			facs[i].button:Dispose()
			facs[i].button = nil
		end
	end
	for i in ipairs(facs) do
		GenerateButton(facs, i, facs[i].facID, facs[i].facDefID)
		UpdateFac(facs[i].facID, i)
	end	
end

local function AddFac(unitID, unitDefID)
	local i = #facs + 1
	facs[i] = {facID = unitID, facDefID = unitDefID}
	GenerateButton(facs, i, unitID, unitDefID)
	facsByID[unitID] = i
	UpdateFac(unitID, i)
end

local function RemoveFac(unitID)
	local index = facsByID[unitID]
	-- move everything to the left
	local shift = false
	if facs[index].button then
		facs[index].button:Dispose()
		facs[index].button = nil
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
end

--[[	--used by old "one comm button" system
local function UpdateCommButton()
	local commDefID = currentComm and GetUnitDefID(currentComm) or commDefID
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
	if currentComm then
		commButton.image:AddChild(commButton.healthbar)
	else
		commButton.image:RemoveChild(commButton.healthbar)
	end
	commButton.button.backgroundColor = (currentComm and buttonColor) or buttonColorDisabled
	commButton.button:Invalidate()
end
]]--

local function UpdateComm(unitID, index)
	if not comms[index].button then
		return
	end
	--[[
	if not currentComm then
		if gamestart then
			commButton.button.tooltip = "Your commander is dead...sorry..."
		else
			commButton.button.tooltip = "Waiting for commander spawn..."
		end
		return
	end
	
	local health, maxHealth = GetUnitHealth(currentComm)
	commButton.healthbar:SetValue(health/maxHealth)
	commButton.healthbar.color = GetHealthColor(health/maxHealth)
	commButton.healthbar:Invalidate()
	
	local commDefID = GetUnitDefID(currentComm)
	commButton.button.tooltip = "Commander: "..UnitDefs[commDefID].humanName ..
								"\n\255\0\255\255Health:\008 "..GetHealthColor(health/maxHealth, "char")..math.floor(health).."/"..maxHealth.."\008"..
								"\n\255\0\255\0Left-click: Select and go to"..
								"\nRight-click: Cycle commander (if available)\008"
	]]--
	local health, maxHealth = GetUnitHealth(unitID)
	if not health then
		return
	end
	comms[index].healthbar:SetValue(health/maxHealth)
	comms[index].healthbar.color = GetHealthColor(health/maxHealth)
	comms[index].healthbar:Invalidate()
	
	comms[index].button.tooltip = "Commander: "..UnitDefs[comms[index].commDefID].humanName ..
								"\n\255\0\255\255Health:\008 "..GetHealthColor(health/maxHealth, "char")..math.floor(health).."/"..maxHealth.."\008"..
								"\n\255\0\255\0Left-click: Select and go to"..
								"\nRight-click: Select"..
								"\nShift: Append to current selection\008"	
end

--[[
local function UpdateCommFull()	-- regenerates image etc.
	commButton.image:Dispose()
	UpdateCommButton()
	UpdateComm()
end
]]--

local function AddComm(unitID, unitDefID)
	local i = #comms + 1
	comms[i] = {commID = unitID, commDefID = unitDefID, warningTime = -1}
	GenerateButton(comms, i, unitID, unitDefID, WG.crude.GetHotkey("selectcomm"):upper() or '')
	commsByID[unitID] = i
	UpdateComm(unitID, i)
	ShiftFacRow()
end

local function ShiftCommRow()
	for i in ipairs(comms) do
		if comms[i].button then
			comms[i].button:Dispose()
			comms[i].button = nil
		end
	end
	for i in ipairs(comms) do
		GenerateButton(comms, i, comms[i].commID, comms[i].commDefID)
		UpdateComm(comms[i].commID, i)
	end	
end

local function RemoveComm(unitID)
	local index = commsByID[unitID]
	-- move everything to the left
	if comms[index].button then
		comms[index].button:Dispose()
		comms[index].button = nil
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
end

--[[
local function CycleComm()
	if SetCount(commsByID) == 0 then
		return
	end
	local newComm
	local savedPos = 1
	local commsOrdered = {}
	
	-- ipairs breaks for some inane reason
	-- thankfully pairs preserves a constant order as long as the table remains constant, so we can use it
	for unitID in pairs(commsByID) do	
		local i = #commsOrdered+1
		commsOrdered[i] = unitID
		if unitID == currentComm then
			savedPos = i
		end
	end
	if #commsOrdered == savedPos then
		newComm = commsOrdered[1]
	else
		newComm = commsOrdered[savedPos+1]
	end
	--clear warning if needed
	if newComm ~= currentComm then
		commWarningTimeLeft = -1
	end
	
	currentComm = newComm
end
]]--

local function UpdateConsButton()
	-- get con type with highest number of idlers (as well as number of types total)
	local prevTotal = idleCons.count or 0
	idleCons.count = nil
	--local maxDefID = idleBuilderDefID
	local maxCount, total = 0, 0
	local types = {}
	for unitID in pairs(idleCons) do
		local def = GetUnitDefID(unitID)
		if def then	-- because GetUnitDefID can never be trusted to work
			types[def] = (types[def] or 0) + 1
		end
		total = total + 1
	end
	local numTypes = SetCount(types)
	
	-- this deprecated stuff is for making the button image change to reflect which con unit type has the most idlers
	--[[
	for defID, num in pairs(types) do
		if num > maxCount then
			maxDefID = defID
			maxCount = num
		end
	end
	]]--
	
	--if (idleBuilderDefID ~= maxDefID or total == 0 or prevTotal == 0) then
	if (total == 0 or prevTotal == 0) then
		--conButton.image.file = '#'..maxDefID
		conButton.image.file = (total > 0 and buildIcon) or buildIcon_bw
		conButton.image.color = (total == 0 and imageColorDisabled) or nil
		conButton.image:Invalidate()
		conButton.button.backgroundColor = (total == 0 and buttonColorDisabled) or buttonColor
		conButton.button:Invalidate()
		--idleBuilderDefID = maxDefID
	end
	conButton.button.tooltip = "You have ".. total .. " idle con(s), of "..numTypes.." different type(s)."..
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

local function ClearData()
	while facs[1] do
		RemoveFac(facs[1].facID)
	end
	while comms[1] do
		RemoveComm(comms[1].commID)
	end
	idleCons = {}
	UpdateConsButton()
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
	if #comms <= 0 then return end	-- no comms, don't bother
	local unitID = -1
	
	repeat	-- if this comm is already in selection, try the next one
		--Spring.Echo(commIndex)
		unitID = comms[commIndex].commID
		if #comms == 1 then break end	-- no other comms, just select this one
		commIndex = commIndex + 1	-- try next comm
		if commIndex > #comms then commIndex = 1 end	-- loop
	until not Spring.IsUnitSelected(unitID)
	
	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	Spring.SelectUnitArray({unitID}, shift)
	if not shift then
		local x, y, z = Spring.GetUnitPosition(unitID)
		Spring.SetCameraTarget(x, y, z)
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

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	if (not myTeamID or unitTeam ~= myTeamID) then
		return
	end

	if UnitDefs[unitDefID].isFactory and (not exceptionArray[unitDefID]) then
		AddFac(unitID, unitDefID)
	elseif UnitDefs[unitDefID].customParams.level then
		AddComm(unitID, unitDefID)
	end
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if (not myTeamID or unitTeam ~= myTeamID) or exceptionArray[unitDefID] then
		return
	end
	local ud = UnitDefs[unitDefID]
	if ud.buildSpeed > 0 then  --- can build
		local bQueue = GetFullBuildQueue(unitID)
		if not bQueue[1] then  --- has no build queue
			local _, _, _, _, buildProg = GetUnitHealth(unitID)
			if not ud.isFactory then
				local cQueue = Spring.GetCommandQueue(unitID)
				if not cQueue[1] then
					widget:UnitIdle(unitID, unitDefID, myTeamID)
				end
			end
		end
	end  
end

function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
  widget:UnitCreated(unitID, unitDefID, unitTeam)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if (not myTeamID or unitTeam ~= myTeamID) then
		return
	end
	if idleCons[unitID] then
		idleCons[unitID] = nil
		wantUpdateCons = true
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
	and (options.monitoridlecomms.value or not UnitDefs[unitDefID].customParams.level)
	and (options.monitoridlenano.value or UnitDefs[unitDefID].canMove) then
		idleCons[unitID] = true
		wantUpdateCons = true
	end
end

function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdId, cmdOpts, cmdParams)
	if (not myTeamID or unitTeam ~= myTeamID) then
		return
	end
	if idleCons[unitID] then
		idleCons[unitID] = nil
		wantUpdateCons = true
	end
end

local timer = 0
local warningColorPhase = false
function widget:Update(dt)
	if myTeamID~=Spring.GetMyTeamID() then
		--Spring.Echo("<Core Selector>: Spectator mode. Widget removed.")
		--widgetHandler:RemoveWidget()
		--return false
		myTeamID = Spring.GetMyTeamID()
		ClearData()
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
	for i=1,#facs do
		UpdateFac(facs[i].facID, i)
	end
	for i=1,#comms do
		UpdateComm(comms[i].commID, i)
	end
	warningColorPhase = not warningColorPhase
	timer = 0
end

-- for "under attack" achtung sign
function widget:UnitDamaged(unitID, unitDefID, unitTeam)
	if commsByID[unitID] then
		comms[commsByID[unitID]].warningTime = commWarningTime
	end
end
function widget:DrawScreen()
	for i=1,#comms do
		local comm = comms[i]
		if comm.button and comm.warningTime > 0 then
			comms[i].button.backgroundColor = (warningColorPhase and buttonColorWarning) or buttonColor
			comms[i].button:Invalidate()
		end
	end
end

function widget:GameFrame(n)
	if (n%10 < 0.1) then
		for i = 1, #comms do
			local comm = comms[i]
			if comm.button and comm.warningTime > 0 then
				comm.warningTime = comm.warningTime - 10
				if (comm.warningTime <= 0) then
					comms[i].button.backgroundColor = buttonColor
					comms[i].button:Invalidate()
				end
			end
		end
	end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

function widget:Initialize()
	if (not WG.Chili) then
		widgetHandler:RemoveWidget(widget)
		return
	end
	
	widgetHandler:AddAction("selectcomm", SelectComm, nil, 't')

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
		padding = {0,0,0,0},
		--itemPadding = {0, 0, 0, 0},
		itemMargin = {0, 0, 0, 0},
		width= '100%',
		height = '100%',
		resizeItems = true,
		orientation = 'horizontal',
		--autoArrangeH = true,
		centerItems = false,
	}
	window_selector = Window:New{
		padding = {0,0,0,0},
		itemMargin = {0, 0, 0, 0},
		dockable = true,
		name = "selector_window",
		x = 450,	-- integral width 
		bottom = 0,
		width  = BUTTON_WIDTH * BASE_COLUMNS,
		height = BUTTON_HEIGHT,
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

	-- for old single comm button system; deprecated
	--[[
	commButton.button = Button:New{
		parent = stack_main;
		width = (100/BASE_COLUMNS).."%",
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
	]]--

	
	
	conButton.button = Button:New{
		parent = stack_main;
		x = 0,
		caption = '',
		width = (100/BASE_COLUMNS).."%",
		OnMouseDown = {	function () 
				local _,_,left,_,right = Spring.GetMouseState()
				if left then
					if options.monitoridlecomms.value and options.monitoridlenano.value then
						Spring.SendCommands({"select AllMap+_Builder_Not_Building_Idle+_ClearSelection_SelectOne+"})
					elseif options.monitoridlenano.value then
						Spring.SendCommands({"select AllMap+_Builder_Not_Commander_Not_Building_Idle+_ClearSelection_SelectOne+"})
					elseif options.monitoridlecomms.value then
						Spring.SendCommands({"select AllMap+_Builder_Not_Building_Not_NameContain_" .. nano_name .. "_Idle+_ClearSelection_SelectOne+"})
					else
						Spring.SendCommands({"select AllMap+_Builder_Not_Commander_Not_Building_Not_NameContain_" .. nano_name .. "_Idle+_ClearSelection_SelectOne+"})
					end
				elseif right and idleCons.count > 0 then
					Spring.SelectUnitMap(idleCons, false)
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
				caption = '\255\0\255\0'..WG.crude.GetHotkey("select AllMap+_Builder_Not_Building_Idle+_ClearSelection_SelectOne+"):upper() or '',
				fontSize = 11;
				fontShadow = true;
				parent = button;
			}
		}
		--keepAspect = true,
	}
	conButton.image = Image:New {
		parent = conButton.button,
		width="91%";
		height="91%";
		x="6%";
		y="6%";
		file = buildIcon,	--'#'..idleBuilderDefID,
		--file2 = "bitmaps/icons/frame_cons.png",
		keepAspect = false,
		color = (total == 0 and imageColorDisabled) or nil,
	}
	UpdateConsButton()

	myTeamID = Spring.GetMyTeamID()


	local viewSizeX, viewSizeY = widgetHandler:GetViewSizes()
	self:ViewResize(viewSizeX, viewSizeY)
	
	InitializeUnits()
end

function widget:Shutdown()
	widgetHandler:RemoveAction("selectcomm")
end
