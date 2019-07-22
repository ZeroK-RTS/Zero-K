-------------------------------------------------------------------------------

local version = "v0.053"

function widget:GetInfo()
  return {
    name      = "Chili FactoryBar",
    desc      = version .. " - Chili buildmenu for factories.",
    author    = "CarRepairer (converted from jK's Buildbar)",
    date      = "2010-11-10",
    license   = "GNU GPL, v2 or later",
    layer     = 1001,
    enabled   = false,
  }
end

include("Widgets/COFCTools/ExportUtilities.lua")
VFS.Include("LuaRules/Configs/customcmds.h.lua")

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

WhiteStr   = "\255\255\255\255"
GreyStr    = "\255\210\210\210"
GreenStr   = "\255\092\255\092"

local buttonColor = {0,0,0,0.5}
local queueColor = {0.0,0.4,0.4,0.9}
local progColor = {1,0.7,0,0.6}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Chili
local Button
local Label
local Window
local StackPanel
local Grid
local TextBox
local Image
local Progressbar
local screen0
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local window_facbar, stack_main
local echo = Spring.Echo

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local function RecreateFacbar() end

options_path = 'Settings/HUD Panels/FactoryBar'
options = {
	maxVisibleBuilds = {
		type = 'number',
		name = 'Visible Units in Que',
		desc = "The maximum units to show in the factory's queue",
		min = 2, max = 14,
		value = 5,
	},	
	
	buttonsize = {
		type = 'number',
		name = 'Button Size',
		min = 40, max = 100, step=5,
		value = 50,
		OnChange = function() RecreateFacbar() end,
	},
}

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local EMPTY_TABLE = {}

-- list and interface vars
local facs = {}
local unfinished_facs = {}
local pressedFac  = -1
local waypointFac = -1
local waypointMode = 0   -- 0 = off; 1=lazy; 2=greedy (greedy means: you have to left click once before leaving waypoint mode and you can have units selected)

local myTeamID = 0
local inTweak  = false
local leftTweak, enteredTweak = false, false
local cycle_half_s = 1
local cycle_2_s = 1

-------------------------------------------------------------------------------
-- SOUNDS
-------------------------------------------------------------------------------

local sound_waypoint  = LUAUI_DIRNAME .. 'Sounds/buildbar_waypoint.wav'
local sound_click     = LUAUI_DIRNAME .. 'Sounds/buildbar_click.WAV'
local sound_queue_add = LUAUI_DIRNAME .. 'Sounds/buildbar_add.wav'
local sound_queue_rem = LUAUI_DIRNAME .. 'Sounds/buildbar_rem.wav'

-------------------------------------------------------------------------------

local image_repeat    = LUAUI_DIRNAME .. 'Images/repeat.png'

local GetTeamColor = Spring.GetTeamColor

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
local DrawUnitCommands  = Spring.DrawUnitCommands
local GetSelectedUnits  = Spring.GetSelectedUnits
local GetFullBuildQueue = Spring.GetFullBuildQueue
local GetUnitIsBuilding = Spring.GetUnitIsBuilding

local push        = table.insert


-------------------------------------------------------------------------------

local function GetBuildQueue(unitID)
  local result = {}
  local queue = GetFullBuildQueue(unitID)
  if (queue ~= nil) then
    for _,buildPair in ipairs(queue) do
      local udef, count = next(buildPair, nil)
      if result[udef]~=nil then
        result[udef] = result[udef] + count
      else
        result[udef] = count
      end
    end
  end
  return result
end



local function UpdateFac(i, facInfo)
	--local unitDefID = facInfo.unitDefID
	
	local unitBuildDefID = -1
	local unitBuildID    = -1

	-- building?
	local progress = 0
	unitBuildID      = GetUnitIsBuilding(facInfo.unitID)
	if unitBuildID then
		unitBuildDefID = GetUnitDefID(unitBuildID)
		_, _, _, _, progress = GetUnitHealth(unitBuildID)
		--unitDefID      = unitBuildDefID
		--[[
	elseif (unfinished_facs[facInfo.unitID]) then
		_, _, _, _, progress = GetUnitHealth(facInfo.unitID)
		if (progress>=1) then 
			progress = -1
			unfinished_facs[facInfo.unitID] = nil
		end
		--]]
	end

	local buildList   = facInfo.buildList
	local buildQueue  = GetBuildQueue(facInfo.unitID)
	for j,unitDefIDb in ipairs(buildList) do
		local unitDefIDb = unitDefIDb
		
		if not facs[i].boStack then
		  echo('<Chili Facbar> Strange error #1' )
		else
		  local boButton = facs[i].boStack.childrenByName[unitDefIDb]
		  local qButton = facs[i].qStore[i .. '|' .. unitDefIDb]
		  
		  local boBar = boButton.childrenByName['bp'].childrenByName['prog']
		  local qBar = qButton.childrenByName['bp'].childrenByName['prog']
		  
		  local amount = buildQueue[unitDefIDb] or 0
		  local boCount = boButton.childrenByName['count']
		  local qCount = qButton.childrenByName['count']			
		  
		  facs[i].qStack:RemoveChild(qButton)
		  
		  boBar:SetValue(0)
		  qBar:SetValue(0)
		  if unitDefIDb == unitBuildDefID then
			  boBar:SetValue(progress)
			  qBar:SetValue(progress)
		  end
		  
		  if amount > 0 then
			  boButton.backgroundColor = queueColor
		  else
			  boButton.backgroundColor = buttonColor
		  end
		  boButton:Invalidate()
		  
		  boCount:SetCaption(amount > 0 and amount or '')
		  qCount:SetCaption(amount > 0 and amount or '')
		end
	end
end
local function UpdateFacQ(i, facInfo)
	local unitBuildDefID = -1
	local unitBuildID    = -1

	-- building?
	local progress = 0
	unitBuildID      = GetUnitIsBuilding(facInfo.unitID)
	if unitBuildID then
		unitBuildDefID = GetUnitDefID(unitBuildID)
		_, _, _, _, progress = GetUnitHealth(unitBuildID)
	end
	local buildQueue  = Spring.GetFullBuildQueue(facInfo.unitID, options.maxVisibleBuilds.value +1)
				
	if (buildQueue ~= nil) then
		
		local n,j = 1,options.maxVisibleBuilds.value
		
		while (buildQueue[n]) do
			local unitDefIDb, count = next(buildQueue[n], nil)
			
			local qButton = facs[i].qStore[i .. '|' .. unitDefIDb]
			
			if not facs[i].qStack:GetChildByName(qButton.name) then
				facs[i].qStack:AddChild(qButton)
			end
		
			j = j-1
			if j==0 then break end
			n = n+1
		end
	end
end				



local function AddFacButton(unitID, unitDefID, tocontrol, stackname)
	tocontrol:AddChild(
		Button:New{
			width = options.buttonsize.value*1.2,
			height = options.buttonsize.value*1.0,
			tooltip = 			WG.Translate("interface", "lmb") .. ' - ' .. GreenStr .. WG.Translate("interface", "select") .. '\n' 					
				.. WhiteStr .. 	WG.Translate("interface", "mmb") .. ' - ' .. GreenStr .. WG.Translate("interface", "go_to") .. '\n'
				.. WhiteStr .. 	WG.Translate("interface", "rmb") .. ' - ' .. GreenStr .. WG.Translate("interface", "quick_rallypoint_mode")
				,
			backgroundColor = buttonColor,
			
			OnClick = {
				unitID ~= 0 and
					function(_,_,_,button)
						if button == 2 then
							local x,y,z = Spring.GetUnitPosition(unitID)
							SetCameraTarget(x,y,z)
						elseif button == 3 then
							Spring.Echo("FactoryBar: Entered easy waypoint mode")
							Spring.PlaySoundFile(sound_waypoint, 1, 'ui')
							waypointMode = 2 -- greedy mode
							waypointFac  = stackname
						else
							Spring.PlaySoundFile(sound_click, 1, 'ui')
							Spring.SelectUnitArray({unitID})
						end
					end
					or nil
			},
			padding={3, 3, 3, 3},
			--margin={0, 0, 0, 0},
			children = {
				unitID ~= 0 and
					Image:New {
						file = "#"..unitDefID,
						file2 = WG.GetBuildIconFrame(UnitDefs[unitDefID]),
						keepAspect = false;
						width = '100%',
						height = '100%',
					}
				or nil,
			},
		}
	)

	local boStack = StackPanel:New{
		name = stackname .. '_bo',
		itemMargin={0,0,0,0},
		itemPadding={0,0,0,0},
		padding={0,0,0,0},
		--margin={0, 0, 0, 0},
		x=0,
		width=700,
		height = options.buttonsize.value,
		resizeItems = false,
		orientation = 'horizontal',
		centerItems = false,
	}
	local qStack = StackPanel:New{
		name = stackname .. '_q',
		itemMargin={0,0,0,0},
		itemPadding={0,0,0,0},
		padding={0,0,0,0},
		--margin={0, 0, 0, 0},
		x=0,
		width=700,
		height = options.buttonsize.value,
		resizeItems = false,
		orientation = 'horizontal',
		centerItems = false,
	}
	local qStore = {}
	
	local facStack = StackPanel:New{
		name = stackname,
		itemMargin={0,0,0,0},
		itemPadding={0,0,0,0},
		padding={0,0,0,0},
		--margin={0, 0, 0, 0},
		width=800,
		height = options.buttonsize.value*1.0,
		resizeItems = false,
		centerItems = false,
	}
	
	facStack:AddChild( qStack )
	tocontrol:AddChild( facStack )
	return facStack, boStack, qStack, qStore
end

local function MakeButton(unitDefID, facID, facIndex)

	local ud = UnitDefs[unitDefID]
	local tooltip = "Build Unit: " .. ud.humanName .. " - " .. ud.tooltip .. "\n"
  
	return
		Button:New{
			name = unitDefID,
			tooltip=tooltip,
			x=0,
			caption='',
			width = options.buttonsize.value,
			height = options.buttonsize.value,
			padding = {4, 4, 4, 4},
			--padding = {0,0,0,0},
			--margin={0, 0, 0, 0},
			backgroundColor = queueColor,
			OnClick = {
				function(_,_,_,button)
					local alt, ctrl, meta, shift = Spring.GetModKeyState()
					local rb = button == 3
					local lb = button == 1
					if not (lb or rb) then return end
					
					local opt = 0
					if alt   then opt = opt + CMD.OPT_ALT   end
					if ctrl  then opt = opt + CMD.OPT_CTRL  end
					if meta  then opt = opt + CMD.OPT_META  end
					if shift then opt = opt + CMD.OPT_SHIFT end
					if rb    then opt = opt + CMD.OPT_RIGHT end
					
					Spring.GiveOrderToUnit(facID, -(unitDefID), EMPTY_TABLE, opt)
					
					if rb then
						Spring.PlaySoundFile(sound_queue_rem, 0.97, 'ui')
					else
						Spring.PlaySoundFile(sound_queue_add, 0.95, 'ui')
					end
					
					--UpdateFac(facIndex, facs[facIndex])
					
				end
			},
			children = {
				Label:New {
					name='count',
					autosize=false;
					width="100%";
					height="100%";
					align="right";
					valign="top";
					caption = '';
					fontSize = 14;
					fontShadow = true;
				},

				
				Label:New{ caption = ud.metalCost .. ' m', fontSize = 11, x=2, bottom=2, fontShadow = true, },
				Image:New {
					name = 'bp',
					file = "#"..unitDefID,
					file2 = WG.GetBuildIconFrame(ud),
					keepAspect = false;
					width = '100%',height = '80%',
					children = {
						Progressbar:New{
							value = 0.0,
							name    = 'prog';
							max     = 1;
							color   		= progColor,
							backgroundColor = {1,1,1,  0.01},
							x=4,y=4, bottom=4,right=4,
							skin=nil,
							skinName='default',
						},
					},
				},
			},
		}
	
end


-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local function WaypointHandler(x,y,button)
  if (button==1)or(button>3) then
    Spring.Echo("FactoryBar: Exited easy waypoint mode")
    Spring.PlaySoundFile(sound_waypoint, 1, 'ui')
    waypointFac  = -1
    waypointMode = 0
    return
  end

  local alt, ctrl, meta, shift = Spring.GetModKeyState()
  local opt = CMD.OPT_RIGHT
  if alt   then opt = opt + CMD.OPT_ALT   end
  if ctrl  then opt = opt + CMD.OPT_CTRL  end
  if meta  then opt = opt + CMD.OPT_META  end
  if shift then opt = opt + CMD.OPT_SHIFT end

  local type,param = Spring.TraceScreenRay(x,y)
  if type=='ground' then
    Spring.GiveOrderToUnit(facs[waypointFac].unitID, CMD_RAW_MOVE,param,opt) 
  elseif type=='unit' then
    Spring.GiveOrderToUnit(facs[waypointFac].unitID, CMD.GUARD,{param},opt)     
  else --feature
    type,param = Spring.TraceScreenRay(x,y,true)
    Spring.GiveOrderToUnit(facs[waypointFac].unitID, CMD_RAW_MOVE,param,opt)
  end

  --if not shift then waypointMode = 0; return true end
end

RecreateFacbar = function()
	enteredTweak = false
	if inTweak then return end
	
	stack_main:ClearChildren()
	for i,facInfo in ipairs(facs) do
		local unitDefID = facInfo.unitDefID
		
		local unitBuildDefID = -1
		local unitBuildID    = -1
		local progress

		-- building?
		unitBuildID      = GetUnitIsBuilding(facInfo.unitID)
		if unitBuildID then
			unitBuildDefID = GetUnitDefID(unitBuildID)
			_, _, _, _, progress = GetUnitHealth(unitBuildID)
			unitDefID      = unitBuildDefID
		elseif (unfinished_facs[facInfo.unitID]) then
			_, _, _, _, progress = GetUnitHealth(facInfo.unitID)
			if (progress>=1) then 
				progress = -1
				unfinished_facs[facInfo.unitID] = nil
			end
		end

		local facStack, boStack, qStack, qStore = AddFacButton(facInfo.unitID, unitDefID, stack_main, i)
		facs[i].facStack 	= facStack
		facs[i].boStack 	= boStack
		facs[i].qStack 		= qStack
		facs[i].qStore 		= qStore
		
		local buildList   = facInfo.buildList
		local buildQueue  = GetBuildQueue(facInfo.unitID)
		for j,unitDefIDb in ipairs(buildList) do
			local unitDefIDb = unitDefIDb
			boStack:AddChild( MakeButton(unitDefIDb, facInfo.unitID, i) )
			qStore[i .. '|' .. unitDefIDb] = MakeButton(unitDefIDb, facInfo.unitID, i)
		end
		
	end

	stack_main:Invalidate()
	stack_main:UpdateLayout()
end

local function UpdateFactoryList()

  facs = {}

  local teamUnits = Spring.GetTeamUnits(myTeamID)
  local totalUnits = #teamUnits

  for num = 1, totalUnits do
    local unitID = teamUnits[num]
    local unitDefID = GetUnitDefID(unitID)
    if UnitDefs[unitDefID].isFactory then
		local bo =  UnitDefs[unitDefID] and UnitDefs[unitDefID].buildOptions
		if bo and #bo > 0 then	
		  push(facs,{ unitID=unitID, unitDefID=unitDefID, buildList=UnitDefs[unitDefID].buildOptions })
		  local _, _, _, _, buildProgress = GetUnitHealth(unitID)
		  if (buildProgress)and(buildProgress<1) then
			unfinished_facs[unitID] = true
		  end
		end
    end
  end
  
	
	RecreateFacbar()
end

------------------------------------------------------

function widget:DrawWorld()
	-- Draw factories command lines
	if waypointMode>1 then
		local unitID
		if waypointMode>1 then 
			unitID = facs[waypointFac].unitID
		end
		DrawUnitCommands(unitID)
	end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
  if (unitTeam ~= myTeamID) then
    return
  end

  if UnitDefs[unitDefID].isFactory then
	local bo =  UnitDefs[unitDefID] and UnitDefs[unitDefID].buildOptions
	if bo and #bo > 0 then
		push(facs,{ unitID=unitID, unitDefID=unitDefID, buildList=UnitDefs[unitDefID].buildOptions })
		--UpdateFactoryList()
		RecreateFacbar()
	end
  end
  unfinished_facs[unitID] = true
end

function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
  widget:UnitCreated(unitID, unitDefID, unitTeam)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
  if (unitTeam ~= myTeamID) then
    return
  end
  if UnitDefs[unitDefID].isFactory then
    for i,facInfo in ipairs(facs) do
      if unitID==facInfo.unitID then
        
        table.remove(facs,i)
        unfinished_facs[unitID] = nil
		--UpdateFactoryList()
		RecreateFacbar()
        return
      end
    end
  end
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
  widget:UnitDestroyed(unitID, unitDefID, unitTeam)
end

function widget:Update()
	if myTeamID~=Spring.GetMyTeamID() then
		myTeamID = Spring.GetMyTeamID()
		UpdateFactoryList()
	end
	inTweak = widgetHandler:InTweakMode()
  
	cycle_half_s = (cycle_half_s % 16) + 1
	cycle_2_s = (cycle_2_s % (32*2)) + 1
	
	
	if cycle_half_s == 1 then 
		for i,facInfo in ipairs(facs) do
			if Spring.ValidUnitID( facInfo.unitID ) then
				if cycle_2_s == 1 then
					UpdateFac(i, facInfo)
				end
				UpdateFacQ(i, facInfo)
			end
		end
	end
	
	
	if inTweak and not enteredTweak then
		enteredTweak = true
		stack_main:ClearChildren()
		for i = 1,5 do
			local facStack, boStack, qStack, qStore = AddFacButton(0, 0, stack_main, i)
		end
		stack_main:Invalidate()
		stack_main:UpdateLayout()
		leftTweak = true
	end
	
	if not inTweak and leftTweak then
		enteredTweak = false
		leftTweak = false
		RecreateFacbar()
	end
end



-------------------------------------------------------------------------------
-------------------------------------------------------------------------------


function widget:SelectionChanged(selectedUnits)
	if facs[pressedFac] then
		local qStack = facs[pressedFac].qStack
		local boStack = facs[pressedFac].boStack
		facs[pressedFac].facStack:RemoveChild(boStack)
		facs[pressedFac].facStack:AddChild(qStack)
	end

	pressedFac = -1
	
	if (#selectedUnits == 1) then 
		for cnt, f in ipairs(facs) do 
			if f.unitID == selectedUnits[1] then 
				pressedFac = cnt
				
				local qStack = facs[pressedFac].qStack
				local boStack = facs[pressedFac].boStack
				facs[pressedFac].facStack:RemoveChild(qStack)
				facs[pressedFac].facStack:AddChild(boStack)
			end
		end
	end
end


function widget:MouseRelease(x, y, button)
	if (waypointMode>0)and(not inTweak) and (waypointMode>0)and(waypointFac>0) then
		WaypointHandler(x,y,button)	
	end
	return -1
end

function widget:MousePress(x, y, button)
	if waypointMode>1 then
		-- greedy waypointMode
		return (button~=2) -- we allow middle click scrolling in greedy waypoint mode
	end
	if waypointMode>1 then
		Spring.Echo("FactoryBar: Exited easy waypoint mode")
		Spring.PlaySoundFile(sound_waypoint, 1, 'ui')
	end
	waypointFac  = -1
	waypointMode = 0
	return false
end

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
	Grid = Chili.Grid
	TextBox = Chili.TextBox
	Image = Chili.Image
	Progressbar = Chili.Progressbar
	screen0 = Chili.Screen0

	stack_main = Grid:New{
		y=20,
		padding = {0,0,0,0},
		itemPadding = {0, 0, 0, 0},
		itemMargin = {0, 0, 0, 0},
		width='100%',
		height = '100%',
		resizeItems = false,
		orientation = 'horizontal',
		centerItems = false,
		columns=2,
	}
	window_facbar = Window:New{
		padding = {3,3,3,3,},
		dockable = true,
		name = "facbar",
		x = 0, y = "30%",
		width  = 600,
		height = 200,
		parent = Chili.Screen0,
		draggable = false,
		tweakDraggable = true,
		tweakResizable = true,
		resizable = false,
		dragUseGrip = false,
		minWidth = 56,
		minHeight = 56,
		color = {0,0,0,0},
		children = {
			Label:New{ caption = WG.Translate("interface", "factories"), fontShadow = true, },
			stack_main,
		},
		OnMouseDown={ function(self)
			local alt, ctrl, meta, shift = Spring.GetModKeyState()
			if not meta then return false end
			WG.crude.OpenPath(options_path)
			WG.crude.ShowMenu()
			return true
		end },
	}
	myTeamID = Spring.GetMyTeamID()

	UpdateFactoryList()

	local viewSizeX, viewSizeY = widgetHandler:GetViewSizes()
	self:ViewResize(viewSizeX, viewSizeY)
end
