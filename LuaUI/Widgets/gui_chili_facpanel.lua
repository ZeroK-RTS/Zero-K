-------------------------------------------------------------------------------

local version = "v0.019"

function widget:GetInfo()
  return {
    name      = "Chili FactoryPanel",
    desc      = version .. " - Chili buildmenu for factories.",
    author    = "CarRepairer",
    date      = "2013-07-06",
    license   = "GNU GPL, v2 or later",
    layer     = 1001,
    enabled   = false,
  }
end

include("Widgets/COFCTools/ExportUtilities.lua")
VFS.Include("LuaRules/Configs/customcmds.h.lua")

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local WhiteStr   = "\255\255\255\255"
local GreyStr    = "\255\210\210\210"
local GreenStr   = "\255\092\255\092"
local magenta_table = {0.8, 0, 0, 1}

local buttonColor = {0,0,0,0.4}
--local queueColor = {0.0,0.4,0.4,0.9}
local queueColor = {1,1,1,1}
local progColor = {1,0.9,0,0.6}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--chili

local Chili
local Button
local Label
local Window
local StackPanel
local Grid
local Image
local Progressbar
local Panel
local ScrollPanel
local screen0

local window_facbar, stack_main, stack_build, window_icondrag, scrollpanel
local echo = Spring.Echo

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--options

local function RecreateFacbar() end
local function UpdateFactoryList () end

options_path = 'Settings/HUD Panels/FactoryPanel'
options = {
	
	buttonsize = {
		type = 'number',
		name = 'Button Size',
		min = 40, max = 100, step=5,
		value = 50,
		OnChange = function() RecreateFacbar() end,
	},
	
	backgroundOpacity = {
		name = "Background opacity",
		type = "number",
		value = 1, min = 0, max = 1, step = 0.01,
		OnChange = function(self)
			window_facbar.color = {1,1,1,self.value}
			window_facbar.caption = self.value == 0 and '' or WG.Translate("interface", "factories")
			window_facbar:Invalidate()
		end,
	},
	showAllPlayers = {
		name = "Show All Players",
		type = 'bool',
		desc = 'When spectating, show the factory queues of all players. When disabled, only shows the factory queue of the currently spectated player.',
		value = false,
		OnChange = function() UpdateFactoryList() end,
	},
	
	showETA = {
		name = "Show ETA",
		type = 'bool',
		desc = 'Show ETA for the unit currently being built.',
		value = true,
		OnChange = function() RecreateFacbar() end,
	},

	showBuildPanel = {
		name = "Show Selected Factory's Units Panel",
		type = 'radioButton',
		value = 'always',
		items = {
			{key = 'always', 		name = 'Always'},
			{key = 'playerOnly', name = 'Only when not spectating'},
			{key = 'never', 			name = 'Never'},
		},
		OnChange = function() widget:SelectionChanged(Spring.GetSelectedUnits()) end,
		noHotkey = true,
	},
}

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- list and interface vars

local facs = {}
local facsByUnitId = {}
--local unfinished_facs = {}
local pressedFac  = -1
local waypointFac = -1
local waypointMode = 0   -- 0 = off; 1=lazy; 2=greedy (greedy means: you have to left click once before leaving waypoint mode and you can have units selected)

local alreadyRemovedTag = {}

local myTeamID = 0
local inTweak  = false
local leftTweak, enteredTweak = false, false
local lmx,lmy=-1,-1
local showAllPlayers

local EMPTY_TABLE = {}

-------------------------------------------------------------------------------
-- SOUNDS
-------------------------------------------------------------------------------

local sound_waypoint  = LUAUI_DIRNAME .. 'Sounds/buildbar_waypoint.wav'
local sound_click     = LUAUI_DIRNAME .. 'Sounds/buildbar_click.WAV'
local sound_queue_add = LUAUI_DIRNAME .. 'Sounds/buildbar_add.wav'
local sound_queue_rem = LUAUI_DIRNAME .. 'Sounds/buildbar_rem.wav'
local sound_queue_clear = LUAUI_DIRNAME .. 'Sounds/buildbar_hover.wav'

-------------------------------------------------------------------------------

local image_repeat    = LUAUI_DIRNAME .. 'Images/repeat.png'

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
local spGetMouseState	= Spring.GetMouseState

local spGetFullBuildQueue = Spring.GetFullBuildQueue

local tts 	= function (data)
	 local str = ""

    if(indent == nil) then
        indent = 0
    end
	local indenter = "    "
    -- Check the type
    if(type(data) == "string") then
        str = str .. (indenter):rep(indent) .. data .. "\n"
    elseif(type(data) == "number") then
        str = str .. (indenter):rep(indent) .. data .. "\n"
    elseif(type(data) == "boolean") then
        if(data == true) then
            str = str .. "true"
        else
            str = str .. "false"
        end
    elseif(type(data) == "table") then
        local i, v
        for i, v in pairs(data) do
            -- Check for a table in a table
            if(type(v) == "table") then
                str = str .. (indenter):rep(indent) .. i .. ":\n"
                str = str .. Spring.Utilities.TableToString(v, indent + 2)
            else
                str = str .. (indenter):rep(indent) .. i .. ": " .. Spring.Utilities.TableToString(v, 0)
            end
        end
	elseif(type(data) == "function") then
		str = str .. (indenter):rep(indent) .. 'function' .. "\n"
    else
        echo(1, "Error: unknown data type: %s", type(data))
    end

    return str
end

local push  = table.insert


-------------------------------------------------------------------------------

--temporary function until "#" is restored.
--[[
local function GetUnitPic(unitDefID)
	return 'unitpics/' .. UnitDefs[unitDefID].name .. '.png'
end
--]]

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


local function RemoveChildren(container) 
	for i = 1, #container.children do 
		container:RemoveChild(container.children[1])
	end
end 


local function UpdateFac(i, facInfo)
	--local unitDefID = facInfo.unitDefID
	
	--[[
	local unitBuildDefID = -1
	local unitBuildID    = -1

	-- building?
	local progress = 0
	unitBuildID      = GetUnitIsBuilding(facInfo.unitID)
	if unitBuildID then
		unitBuildDefID = GetUnitDefID(unitBuildID)
		_, _, _, _, progress = GetUnitHealth(unitBuildID)
		--unitDefID      = unitBuildDefID
		
	elseif (unfinished_facs[facInfo.unitID]) then
		_, _, _, _, progress = GetUnitHealth(facInfo.unitID)
		if (progress>=1) then 
			progress = -1
			unfinished_facs[facInfo.unitID] = nil
		end
		
	end
	--]]

	--echo 'UpdateFac'
	local buildList   = facInfo.buildList
	local buildQueue  = GetBuildQueue(facInfo.unitID)
	for j,unitDefIDb in ipairs(buildList) do
		local unitDefIDb = unitDefIDb
		
		if not facs[i].boStack then
		  echo('<Chili Facpanel> Strange error #1' )
		else
		  local boButton = facs[i].boStack.childrenByName[unitDefIDb]
		  local boBar = boButton:GetChildByName('bp'):GetChildByName('prog')
		  local amount = buildQueue[unitDefIDb] or 0
		  local boCount = boButton:GetChildByName('count')
		  boBar:SetValue(0)
		  if amount > 0 then
			  boButton.backgroundColor = queueColor
		  else
			  boButton.backgroundColor = buttonColor
		  end
		  boButton:Invalidate()
		  
		  boCount:SetCaption(amount > 0 and amount or '')
		  
		end
	end
end


local function AddFacButton(unitID, unitDefID, tocontrol, stackname)
	
	local facButton = Button:New{
		width = options.buttonsize.value*1.2,
		height = options.buttonsize.value*1.0,
		tooltip = 			WG.Translate("interface", "lmb") .. ' - ' .. GreenStr .. WG.Translate("interface", "select") .. '\n' 					
			.. WhiteStr .. 	WG.Translate("interface", "mmb") .. ' - ' .. GreenStr .. WG.Translate("interface", "go_to") .. '\n'
			.. WhiteStr .. 	WG.Translate("interface", "rmb") .. ' - ' .. GreenStr .. WG.Translate("interface", "quick_rallypoint_mode")
			,
		--backgroundColor = buttonColor,
		backgroundColor = {1,1,1,1},
		
		OnClick = {
			unitID ~= 0 and
				function(_,_,_,button)
					if button == 2 then
						local x,y,z = Spring.GetUnitPosition(unitID)
						SetCameraTarget(x,y,z)
					elseif button == 3 then
						Spring.Echo("FactoryPanel: Entered Quick Rallypoint mode")
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
		caption= unitID == 0 and WG.Translate("interface", "button") or '',
		padding={3, 3, 3, 3},
		--margin={0, 0, 0, 0},
		children = {
			unitID ~= 0 and
				Image:New {
					name='facIcon';
					file = "#"..unitDefID, -- do not remove this line
					--file = GetUnitPic(unitDefID),
					file2 = WG.GetBuildIconFrame(UnitDefs[unitDefID]),
					keepAspect = false;
					x = '5%',
					y = '5%',
					width = '90%',
					height = '90%',
					children = {
						Label:New {
							name='etaLabel',
							caption='';
							autosize=false;
							width="100%";
							height="100%";
							align="right";
							valign="bottom";
							
							fontSize = 16;
							fontShadow = true;
						},
					};
				}
			or nil,
		},
	}
	
	--tocontrol:AddChild(facButton)

	local boStack = StackPanel:New{
		name = stackname .. '_bo',
		itemMargin={0,0,0,0},
		itemPadding={0,0,0,0},
		padding={0,0,0,0},
		--margin={0, 0, 0, 0},
		
		x=0,y=0,
		--width=700,
		right=0,
		bottom=0,
		
		--height = options.buttonsize.value,
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
		width=800,
		height = options.buttonsize.value,
		resizeItems = false,
		orientation = 'horizontal',
		centerItems = false,
	}
	local qStore = {}
	
	
	local fullFacStack = StackPanel:New{
		name = stackname,
		itemMargin={0,0,0,0},
		itemPadding={0,0,0,0},
		padding={0,0,0,0},
		width=900,
		height = options.buttonsize.value*1.0,
		resizeItems = false,
		centerItems = false,
		children = {
			facButton,
			qStack,
		},
		orientation = 'horizontal',
	}
	
	
	tocontrol:AddChild( fullFacStack )
	
	return facButton, boStack, qStack, qStore
end


local function BuildRowButtonFunc(num, cmdid, left, right,addInput,insertMode,customUnitID)
	local targetFactory = customUnitID or selectedFac
	local buildQueue = spGetFullBuildQueue(targetFactory)
	num = num or (#buildQueue+1) -- insert build at "num" or at end of queue
	local alt,ctrl,meta,shift = Spring.GetModKeyState()
	local pos = 1
	local numInput = 1	--number of times to send the order
	
	--it's not using the options, even though it's receiving them correctly
	--so we have to do it manually
	if shift then numInput = numInput * 5 end
	if ctrl then numInput = numInput * 20 end
	numInput = numInput + (addInput or 0) -- to insert specific amount without SHIFT or CTRL modifier
	
	--insertion position is by unit rather than batch, so we need to add up all the units in front of us to get the queue
	
	for i=1,num-1 do
		if buildQueue[i] then
			for _,unitCount in pairs(buildQueue[i]) do
				pos = pos + unitCount
			end
		end
	end
	
	-- skip over the commands with an id of 0, left behind by removal
	local commands = Spring.GetFactoryCommands(targetFactory, -1)
	local i = 1
	while i <= pos do
		if not commands[i] then --end of queue reached
			break
		end
		if commands[i].id == 0 then 
			pos = pos + 1
		end
		i = i + 1
	end
	
	pos = pos- (insertMode and 1 or 0) -- to insert before this index (possibly replace active nanoframe) or after this index (default)
	--Spring.Echo(cmdid)
	if not right then
		for i = 1, numInput do
			Spring.GiveOrderToUnit(targetFactory, CMD.INSERT, {pos, cmdid, 0 }, CMD.OPT_ALT + CMD.OPT_CTRL)
		end
	else
		-- delete from back so that the order is not canceled while under construction
		local i = 0
		while commands[i+pos] and commands[i+pos].id == cmdid and not alreadyRemovedTag[commands[i+pos].tag] do
			i = i + 1
		end
		i = i - 1
		j = 0
		while commands[i+pos] and commands[i+pos].id == cmdid and j < numInput do
			Spring.GiveOrderToUnit(targetFactory, CMD.REMOVE, {commands[i+pos].tag}, CMD.OPT_CTRL)
			alreadyRemovedTag[commands[i+pos].tag] = true
			j = j + 1
			i = i - 1
		end 
	end
end

local buildRow_dragDrop = {}
local function MakeButton(unitDefID, facID, buttonId, facIndex, bqPos)

	local ud = UnitDefs[unitDefID]
	local tooltip = "Build Unit: " .. ud.humanName .. " - " .. ud.tooltip .. "\n"
  
	local cmdid = -(unitDefID)
	return
		Button:New{
			name = buttonId,
			tooltip=tooltip,
			x=0,
			caption='',
			width = options.buttonsize.value,
			height = options.buttonsize.value,
			padding = {4, 4, 4, 4},
			--padding = {0,0,0,0},
			--margin={0, 0, 0, 0},
			backgroundColor = queueColor,
			cmdid = cmdid;
			OnClick = { function (self, x, y, button)
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

				if bqPos and not alt then
					BuildRowButtonFunc(bqPos, cmdid, lb, rb, nil, nil, facID)
				else
					Spring.GiveOrderToUnit(facID, cmdid, EMPTY_TABLE, opt)
				end
				
				if rb then
					Spring.PlaySoundFile(sound_queue_rem, 0.97, 'ui')
				else
					Spring.PlaySoundFile(sound_queue_add, 0.95, 'ui')
				end
				
				buildRow_dragDrop[1] = nil
				
				--UpdateFac(facIndex, facs[facIndex])
			end},
			OnMouseDown = { function(self,x,y,mouse) --for drag_drop feature
				
				if not bqPos then return end
				
				if mouse == 1 then
					buildRow_dragDrop[1] = bqPos; 
					--buildRow_dragDrop[2] = -buildRowButtons[i].cmdid
					buildRow_dragDrop[2] = cmdid
					buildRow_dragDrop[3] = count-1;
					buildRow_dragDrop[4] = self.width/2
					
					screen0:AddChild(window_icondrag)
					local dragImg = window_icondrag:GetChildByName('icon')
					dragImg.file = "#"..unitDefID -- do not remove this line
					dragImg.file2 = WG.GetBuildIconFrame(ud)
					dragImg:Invalidate()
					lmx,lmy = spGetMouseState()
				end
			end},
			OnMouseUp = { function(self,x,y,mouse) -- MouseRelease event, for drag_drop feature --note: x & y is coordinate with respect to self
				
				if not bqPos then return end
				
				screen0:RemoveChild(window_icondrag)
				
				local i = facIndex
				local buildRow = facs[i].qStack
				local MAX_COLUMNS = 5
				
				local px,py = self:LocalToParent(x,y) --get coordinate with respect to parent
				if mouse == 1 and (x>self.width or x<0) and px> 0 and px< buildRow.width and py> 0 and py< buildRow.height then
					
					local prevIndex = buildRow_dragDrop[1]
					--local currentIndex = math.ceil(px/(buildRow.width/MAX_COLUMNS)) --estimate on which button mouse was released
					local currentIndex = math.ceil(px/options.buttonsize.value) --estimate on which button mouse was released
					
					--[[
					if not buildQueue[currentIndex] then --drag_dropped to the end of queue
						currentIndex = #buildQueue
						if currentIndex == prevIndex then --drag_dropped from end of queue to end of queue
							return
						end
					end
					--]]
					
					local countTransfer = buildRow_dragDrop[3]
					if buildRow_dragDrop[1] > currentIndex then --select remove & adding sequence that reduce complication from network delay
						BuildRowButtonFunc(prevIndex, facs[i].qStack.children[prevIndex].cmdid, false, true,countTransfer, nil,facID) --remove queue on the right, first
						BuildRowButtonFunc(currentIndex, facs[i].qStack.children[prevIndex].cmdid, true, false,countTransfer,true, facID) --then, add queue to the left
					else
						BuildRowButtonFunc(currentIndex+1, facs[i].qStack.children[prevIndex].cmdid, true, false,countTransfer,true, facID) --add queue to the right, first
						BuildRowButtonFunc(prevIndex, facs[i].qStack.children[prevIndex].cmdid, false, true,countTransfer, nil,facID) --then, remove queue on the left
					end
					buildRow_dragDrop[1] = nil
				end
			end},
			
			children = {
				Label:New {
					name='count',
					autosize=false;
					width="100%";
					height="100%";
					align="right";
					valign="top";
					caption = '';
					fontSize = 16;
					fontShadow = true;
				},

				
				Label:New{ caption = ud.metalCost .. ' m', fontSize = 11, x=2, bottom=2, fontShadow = true, },
				Image:New {
					name = 'bp',
					file = "#"..unitDefID, -- do not remove this line
					--file = GetUnitPic(unitDefID),
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
	local buildQueue  = Spring.GetFullBuildQueue(facInfo.unitID, 10)
	RemoveChildren(facs[i].qStack)
	
	if not buildQueue  then return end
	--echo'updating facq'
	
	for j,v in ipairs(buildQueue) do
		local unitDefIDb, count = next(v)

		local qButton = MakeButton(unitDefIDb, facInfo.unitID, j..'-'..unitDefIDb, i, j )
		local qCount = qButton.childrenByName['count']
		
		local altCheck = ''
		local count2 = 0
		if j==1 then
			local commands = Spring.GetFactoryCommands(facInfo.unitID, count)
			for k, command in ipairs(commands) do
				if command.options.alt then
					count2 = count2 + 1
					count = count - 1
				end
			end
		end
		if count2 > 0 then
			altCheck = altCheck .. '\255\255\150\0' .. (count > 1 and '|' or '') .. count2
		end
		
		qCount:SetCaption(count > 1 and count .. altCheck or altCheck)
		facs[i].qStack:AddChild(qButton)
	end
end

local function UpdateFacProg(i, facInfo)
	local etaLabel = facInfo.facButton:GetChildByName('facIcon'):GetChildByName('etaLabel')

	local unitBuildID = GetUnitIsBuilding(facInfo.unitID)
	if not unitBuildID then
		etaLabel:SetCaption("")
		return
	end

	if options.showETA.value then
		local timeLeft = WG.etaTable and WG.etaTable[unitBuildID] and WG.etaTable[unitBuildID].timeLeft
		local etaStr = ''
		if timeLeft then
			local color = WG.etaTable[unitBuildID].negative and '\255\255\1\1' or '\255\1\255\1'
			etaLabel:SetCaption(string.format('%s%d:%02d', color, timeLeft / 60, timeLeft % 60))
		else
			etaLabel:SetCaption("\255\255\255\0?:??")
		end
	else
		etaLabel:SetCaption("")
	end

	local firstButton = facs[i].qStack and facs[i].qStack.children[1]
	if not firstButton then return end

	local qBar = firstButton.childrenByName['bp'].childrenByName['prog']
	local boButton = facs[i].boStack:GetChildByName(GetUnitDefID(unitBuildID))
	local boBar = boButton:GetChildByName('bp'):GetChildByName('prog')

	local progress = select(5, GetUnitHealth(unitBuildID))
	qBar:SetValue(progress)
	boBar:SetValue(progress)
end



-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local function WaypointHandler(x,y,button)
  if (button==1)or(button>3) then
    Spring.Echo("FactoryPanel: Exited Quick Rallypoint mode")
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

local function MakeClearButton(unitID, i)
	return Button:New{
		name = 'clearfac-' .. unitID,
		tooltip= WG.Translate("interface", "clear_factory_queue"),
		x=0,
		caption='',
		width = options.buttonsize.value,
		height = options.buttonsize.value,
		padding = {4, 4, 4, 4},
		backgroundColor = queueColor,
		OnClick = {
			function(_,_,_,button)
				local buildQueue = Spring.GetFactoryCommands (unitID, -1)
				for _, buildCommand in ipairs( buildQueue) do
					Spring.GiveOrderToUnit( unitID, CMD.REMOVE, { buildCommand.tag } , CMD.OPT_CTRL )
				end
				Spring.PlaySoundFile(sound_queue_clear, 0.97, 'ui')
			end
		},
		children = {
			Label:New{ caption = WG.Translate("interface", "clear"), fontSize = 11, x=2, bottom=2, fontShadow = true, },
			Image:New{
				file='LuaUI/images/drawingcursors/eraser.png',
				width="80%";
				height="80%";
				x="10%";
				y="0%";
			}
		},
		
	}
	
end

function AddPlayerName(teamID)
	local _, player,_,isAI = Spring.GetTeamInfo(teamID, false)
	local playerName
	if isAI then
		local _, aiName, _, shortName = Spring.GetAIInfo(teamID)
		playerName = aiName ..' ('.. shortName .. ')'
	else
		playerName = player and Spring.GetPlayerInfo(player, false) or 'noname'
	end
	local teamColor		= {Spring.GetTeamColor(teamID)}
	stack_main:AddChild( Label:New{ caption = playerName, font = {outline = true; color = teamColor; } } )
end

RecreateFacbar = function()
	enteredTweak = false
	if inTweak then return end
	
	table.sort(facs, function(t1,t2)
		if t1.allyTeamID ~= t2.allyTeamID then return t1.allyTeamID < t2.allyTeamID end
		if t1.teamID ~= t2.teamID then return t1.teamID < t2.teamID end
		return t1.unitID < t2.unitID
	end)
	
	stack_main:ClearChildren()
	local curTeam = -1
	for i,facInfo in ipairs(facs) do
		local unitDefID = facInfo.unitDefID
		
		--[[
		local unitBuildDefID = -1
		local unitBuildID    = -1
		local progress

		-- building?
		--unitBuildID      = GetUnitIsBuilding(facInfo.unitID)
		
		if unitBuildID then
			unitBuildDefID = GetUnitDefID(unitBuildID)
			_, _, _, _, progress = GetUnitHealth(unitBuildID)
		elseif (unfinished_facs[facInfo.unitID]) then
			_, _, _, _, progress = GetUnitHealth(facInfo.unitID)
			if (progress>=1) then 
				progress = -1
				unfinished_facs[facInfo.unitID] = nil
			end
		end
		--]]
		if showAllPlayers and facInfo.teamID ~= curTeam then
			curTeam = facInfo.teamID 
			AddPlayerName(curTeam)
		end
		local facButton,boStack, qStack, qStore = AddFacButton(facInfo.unitID, unitDefID, stack_main, i)
		facs[i].facButton 	= facButton
		--facs[i].facStack 	= facStack
		facs[i].boStack 	= boStack
		facs[i].qStack 		= qStack
		facs[i].qStore 		= qStore
		
		facsByUnitId[facInfo.unitID] = i
		
		local buildList   = facInfo.buildList
		local buildQueue  = GetBuildQueue(facInfo.unitID)
		for j,unitDefIDb in ipairs(buildList) do
			local unitDefIDb = unitDefIDb
			boStack:AddChild( MakeButton(unitDefIDb, facInfo.unitID, unitDefIDb, i) )
		end
		boStack:AddChild( MakeClearButton( facInfo.unitID, i ) )

	end
	
	stack_build.x = options.buttonsize.value*1.2

	stack_main:Invalidate()
	stack_main:UpdateLayout()
	
	widget:SelectionChanged(Spring.GetSelectedUnits())
	
end


UpdateFactoryList = function()

	facs = {}
	showAllPlayers = options.showAllPlayers.value and Spring.GetSpectatingState()
	
	--facsByUnitId = {}
  
	local teamUnits = showAllPlayers and Spring.GetAllUnits() or Spring.GetTeamUnits(myTeamID)
	local totalUnits = #teamUnits
  
	for num = 1, totalUnits do
		local unitID = teamUnits[num]
		local unitDefID = GetUnitDefID(unitID)
		if UnitDefs[unitDefID] and UnitDefs[unitDefID].isFactory then --failsafe in case using specfullview 0 and unitDefID becomes unavailable
			local bo =  UnitDefs[unitDefID] and UnitDefs[unitDefID].buildOptions
			if bo and #bo > 0 then
				local teamID = Spring.GetUnitTeam(unitID)
				local allyTeamID = Spring.GetUnitAllyTeam(unitID)
				push(facs,{ unitID=unitID, unitDefID=unitDefID, buildList=UnitDefs[unitDefID].buildOptions, teamID=teamID, allyTeamID=allyTeamID })
				--[[
				local _, _, _, _, buildProgress = GetUnitHealth(unitID)
				if (buildProgress)and(buildProgress<1) then
					unfinished_facs[unitID] = true
				end
				--]]
			end
		end
	end
	
	  
	RecreateFacbar()
end

local function CheckRemoveFacStack()
	if facs[pressedFac] then
		local qStack = facs[pressedFac].qStack
		stack_build:ClearChildren()
		stack_build.backgroundColor = {0,0,0,0}
		--facs[pressedFac].facStack:AddChild(qStack)
		
		facs[pressedFac].facButton.backgroundColor = {1,1,1,1}
		facs[pressedFac].facButton:Invalidate()
	end
end

------------------------------------------------------
------------------------------------------------------
--callins

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

function widget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if (unitTeam ~= myTeamID) and not showAllPlayers then
		return
	end

	if UnitDefs[unitDefID].isFactory then
		local bo =  UnitDefs[unitDefID] and UnitDefs[unitDefID].buildOptions
		if bo and #bo > 0 then
			local allyTeamID = Spring.GetUnitAllyTeam(unitID)
			push(facs,{ unitID=unitID, unitDefID=unitDefID, buildList=UnitDefs[unitDefID].buildOptions, teamID=unitTeam, allyTeamID=allyTeamID })
			--UpdateFactoryList()
			RecreateFacbar()
		end
		--unfinished_facs[unitID] = true
	end
	
	
	local bdid = builderID and Spring.GetUnitDefID(builderID)
    if UnitDefs[bdid] and UnitDefs[bdid].isFactory then
		local i = facsByUnitId[builderID]
	end
end

function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
  widget:UnitCreated(unitID, unitDefID, unitTeam)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
  if (unitTeam ~= myTeamID) and not showAllPlayers then
    return
  end
  if UnitDefs[unitDefID].isFactory then
    for i,facInfo in ipairs(facs) do
      if unitID==facInfo.unitID then
        
		CheckRemoveFacStack()
		
		table.remove(facs,i)
        --unfinished_facs[unitID] = nil
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

local updateT = -1
function widget:Update(dt)
	updateT = updateT - dt
	if myTeamID~=Spring.GetMyTeamID() then
		myTeamID = Spring.GetMyTeamID()
		UpdateFactoryList()
		widget:SelectionChanged(Spring.GetSelectedUnits())
	end
	inTweak = widgetHandler:InTweakMode()
  
	if updateT < 0 then
		updateT = 0.25
		for i = 1, #facs do
			UpdateFac(i, facs[i])
			UpdateFacQ(i, facs[i])
		end
	end

	for i,facInfo in ipairs(facs) do
		UpdateFacProg(i, facInfo)
	end

	if inTweak and not enteredTweak then
		enteredTweak = true
		stack_main:ClearChildren()
		for i = 1,5 do
			local facButton, boStack, qStack, qStore = AddFacButton(0, 0, stack_main, i)
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
	
	if buildRow_dragDrop[1] then
		local buttonSizeHalf = window_icondrag.width/2
		local mx,my = spGetMouseState()
		
		window_icondrag:SetPos(mx-buttonSizeHalf ,vsy-my-buttonSizeHalf )
		
		if mx ~= lmx or my ~= lmy then
			window_icondrag:BringToFront()
		end
		lmx,lmy = mx,my
		
	end
end

function widget:SelectionChanged(selectedUnits)
	CheckRemoveFacStack()
	
	pressedFac = -1

	local showBuildPanel = options.showBuildPanel.value == 'always' or 
	(options.showBuildPanel.value == 'playerOnly' and not Spring.GetSpectatingState())
	
	if (#selectedUnits == 1) then 
		for cnt, f in ipairs(facs) do 
			if f.unitID == selectedUnits[1] then 
				pressedFac = cnt
				if showBuildPanel then
				--local qStack = facs[pressedFac].qStack
					local boStack = facs[pressedFac].boStack
				--facs[pressedFac].facStack:RemoveChild(qStack)
					stack_build:AddChild(boStack)
					stack_build.backgroundColor = {1,1,1,1}
				end
				facs[pressedFac].facButton.backgroundColor = magenta_table
				facs[pressedFac].facButton:Invalidate()
				
				alreadyRemovedTag = {}
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
		Spring.Echo("FactoryPanel: Exited Quick Rallypoint mode")
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
	Image = Chili.Image
	Progressbar = Chili.Progressbar
	Panel = Chili.Panel
	ScrollPanel = Chili.ScrollPanel
	screen0 = Chili.Screen0

	stack_main = StackPanel:New{
		y=0,
		padding = {0,0,0,0},
		itemPadding = {0, 0, 0, 0},
		itemMargin = {0, 0, 0, 0},
		width=800,
		--height = '100%',
		height=20;
		resizeItems = false,
		orientation = 'vertical',
		centerItems = false,
		columns=2,
		
		autosize=true,
	}
	
	stack_build = Panel:New{
		y=0,
		x=options.buttonsize.value*1.2 + 0, 
		right=0,
		--bottom=0,
		height='100%';
		
		padding = {4, 4, 4, 4},
		backgroundColor = {0,0,0,0},
		
		resizeItems = false,
		orientation = 'horizontal',
		centerItems = false,
	}
	
	window_icondrag = Window:New{
		padding = {0,0,0,0},
		name = "buildicon drag",
		width  = 65,
		height = 45,
		--parent = Chili.Screen0,
		--draggable = false,
		--tweakDraggable = true,
		--tweakResizable = true,
		resizable = false,
		
		--color = {0,0,0,1},
		--caption='Factories',
		children = {
			
			Image:New {
				name="icon";
				--file = "#"..unitDefID, -- do not remove this line
				--file2 = WG.GetBuildIconFrame(UnitDefs[unitDefID]),
				
				keepAspect = false;
				x = '5%',
				y = '5%',
				width = '90%',
				height = '90%',
			}
			
		},
	}
	
	scrollpanel = ScrollPanel:New{
		x=0;y=0;
		width="100%";
		height="100%";
		horizontalScrollbar=false;
		--color = {0,0,0,0},
		backgroundColor = {0,0,0,0},
		borderColor = {0,0,0,0},
		children = {
			--stack_build, --must be first so it's always above of the others (like frontmost layer)
			--Label:New{ caption='Factories', fontShadow = true, },
			stack_main,
		},
		
	}
					
	window_facbar = Window:New{
		padding = {3,3,3,3,},
		dockable = true,
		name = "facpanel",
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
--		color = {0,0,0,1},
		caption= WG.Translate("interface", "factories"),
		children = {
			stack_build,
			scrollpanel
			--[[
			stack_build, --must be first so it's always above of the others (like frontmost layer)
			--Label:New{ caption='Factories', fontShadow = true, },
			stack_main,
			--]]
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
