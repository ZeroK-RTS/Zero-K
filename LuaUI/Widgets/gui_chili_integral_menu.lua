-- TODO: proper tooltips for queue buttons

function widget:GetInfo()
  return {
    name      = "Chili Integral Menu",
    desc      = "v0.369 Integral Command Menu",
    author    = "Licho, KingRaptor, Google Frog",
    date      = "12.10.2010", --21.August.2013
    license   = "GNU GPL, v2 or later",
    layer     = math.huge-1,
    enabled   = true,
    handler   = true,
  }
end

include("keysym.h.lua")
--[[
for i,v in pairs(KEYSYMS) do
	Spring.Echo(i.."\t"..v)
end
--]]
--[[
HOW IT WORKS:
	Main window (invisible) is parent of a fake window.
		Tabs are buttons in main window, just above fake window.
		Currently selected tab is highlighted, when tab is changed all tabs are removed and regenerated.
		
		Two parent Panels (children of fake window), a column for normal commands and a row for state commands.
		<numRows> (or <numStateColumns>) StackPanels are nested in each of the parents, at right angles.
		When sorting commands, it splits commands into batches of <MAX_COLUMNS> and assigns them to children
			so if there are 10 commands, it puts 6 in first row and 4 in second row
			Build orders work a little differently, they have a predefined row in the config.
		Ditto for states, except it uses MAX_STATE_ROWS
		
		If unit tab is selected and third command row is free, build queue of first selected factory found in array returned by SelectionChanged is displayed.
		The queue shows up to <MAX_COLUMNS> batches of units and their exact sequence.
		
	All items resize with main window.
	
NOTE FOR OTHER GAME DEVS:
	ZK uses WG.GetBuildIconFrame to draw the unit type border around buildpics.
	If you're not using them (likely), remove all lines containing that function.
--]]

------------------------
--  CONFIG
------------------------
------------------------
options_path = 'Settings/HUD Panels/Command Panel'
options_order = { 'disablesmartselect', 'hidetabs', 'unitstabhotkey', 'unitshotkeyrequiremeta', 'unitshotkeyaltaswell', 'tab_factory', 'tab_economy', 'tab_defence', 'tab_special','old_menu_at_shutdown'}
options = {
	disablesmartselect = {
		name = 'Disable Smart Tab Select',
		type = 'bool',
		value = false,
	},
	hidetabs = {
		name = 'Hide Tab Row',
		type = 'bool',
		advanced = true,
		value = false,
	},
	unitstabhotkey = {
		name = 'Hotkey for Units tab',
		type = 'bool',
		value = true,
	},
	unitshotkeyrequiremeta = {
		name = 'Units tab hotkeys require Meta',
		type = 'bool',
		value = true,
	},
	unitshotkeyaltaswell = {
		name = 'Units tab can use Alt as Meta',
		type = 'bool',
		value = false,
	},
	tab_factory = {
		name = "Factory Tab",
		desc = "Switches to factory tab, enables grid hotkeys",
		type = 'button',
	},
	tab_economy = {
		name = "Economy Tab",
		desc = "Switches to economy tab, enables grid hotkeys",
		type = 'button',
	},
	tab_defence = {
		name = "Defence Tab",
		desc = "Switches to defence tab, enables grid hotkeys",
		type = 'button',
	},
	tab_special = {
		name = "Special Tab",
		desc = "Switches to special tab, enables grid hotkeys",
		type = 'button',
	},
	old_menu_at_shutdown = {
		name = 'Reenable Spring Menu at Shutdown',
		desc = "Upon widget shutdown (manual or upon crash) reenable Spring's original command menu.",
		type = 'bool',
		advanced = true,
		value = true,
	},
}


------------------------
--speedups
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitHealth     = Spring.GetUnitHealth
local spGetFullBuildQueue = Spring.GetFullBuildQueue
local spGetUnitIsBuilding = Spring.GetUnitIsBuilding
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetUnitWeaponState 	= Spring.GetUnitWeaponState
local spGetGameFrame 		= Spring.GetGameFrame
local spGetUnitRulesParam	= Spring.GetUnitRulesParam

local push        = table.insert

local CMD_PAGES = 60

local common_commands, states_commands, factory_commands, econ_commands, defense_commands, special_commands, globalCommands, overrides, custom_cmd_actions = include("Configs/integral_menu_commands.lua")

local function CapCase(str)
	local str = str:lower()
	str = str:gsub( '_', ' ' )
	str = str:sub(1,1):upper() .. str:sub(2)
	
	str = str:gsub( ' (.)', 
		function(x) return (' ' .. x):upper(); end
		)
	return str
end

local function AddHotkeyOptions()
	local options_order_tmp_cmd = {}
	local options_order_tmp_cmd_instant = {}
	local options_order_tmp_states = {}
	for cmdname, number in pairs(custom_cmd_actions) do 
			
		local cmdnamel = cmdname:lower()
		local cmdname_disp = CapCase(cmdname)
		options[cmdnamel] = {
			name = cmdname_disp,
			type = 'button',
			action = cmdnamel,
			path = 'Game/Command Hotkeys',
		}
		if number == 2 then
			options_order_tmp_states[#options_order_tmp_states+1] = cmdnamel
			--options[cmdnamel].isUnitStateCommand = true
		elseif number == 3 then
			options_order_tmp_cmd_instant[#options_order_tmp_cmd_instant+1] = cmdnamel
			--options[cmdnamel].isUnitInstantCommand = true
		else
			options_order_tmp_cmd[#options_order_tmp_cmd+1] = cmdnamel
			--options[cmdnamel].isUnitCommand = true
		end
	end

	options.lblcmd 		= { type='label', name='Targeted Commands', path = 'Game/Command Hotkeys',}
	options.lblcmdinstant	= { type='label', name='Instant Commands', path = 'Game/Command Hotkeys',}
	options.lblstate	= { type='label', name='State Commands', path = 'Game/Command Hotkeys',}
	
	
	table.sort(options_order_tmp_cmd)
	table.sort(options_order_tmp_cmd_instant)
	table.sort(options_order_tmp_states)

	options_order[#options_order+1] = 'lblcmd'
	for i=1, #options_order_tmp_cmd do
		options_order[#options_order+1] = options_order_tmp_cmd[i]
	end
	
	options_order[#options_order+1] = 'lblcmdinstant'
	for i=1, #options_order_tmp_cmd_instant do
		options_order[#options_order+1] = options_order_tmp_cmd_instant[i]
	end
	
	options_order[#options_order+1] = 'lblstate'
	for i=1, #options_order_tmp_states do
		options_order[#options_order+1] = options_order_tmp_states[i]
	end
end

AddHotkeyOptions()


local MAX_COLUMNS = 6
local MAX_STATE_ROWS = 5
local MIN_HEIGHT = 80
local MIN_WIDTH = 200
local COMMAND_SECTION_WIDTH = 74	-- percent
local STATE_SECTION_WIDTH = 24	-- percent

local numRows = 3
local numStateColumns = 3

local forceUpdateFrequency = 0.2	-- seconds

local selectedFac	-- unitID
local alreadyRemovedTag = {}

local hotkeyMode = false
local recentlyInitialized = false

local gridKeyMap = {
	[KEYSYMS.Q] = {1,1}, 
	[KEYSYMS.W] = {1,2},
	[KEYSYMS.E] = {1,3},
	[KEYSYMS.R] = {1,4},
	[KEYSYMS.T] = {1,5},
	[KEYSYMS.Y] = {1,6},
	[KEYSYMS.A] = {2,1}, 
	[KEYSYMS.S] = {2,2},
	[KEYSYMS.D] = {2,3},
	[KEYSYMS.F] = {2,4},
	[KEYSYMS.G] = {2,5},
	[KEYSYMS.H] = {2,6},
	[KEYSYMS.Z] = {3,1}, 
	[KEYSYMS.X] = {3,2},
	[KEYSYMS.C] = {3,3},
	[KEYSYMS.V] = {3,4},
	[KEYSYMS.B] = {3,5},
	[KEYSYMS.N] = {3,6},
}

local gridMap = {
	[1] = {
		[1] = "Q",
		[2] = "W",
		[3] = "E",
		[4] = "R",
		[5] = "T",
		[6] = "Y",
	},
	[2] = {
		[1] = "A",
		[2] = "S",
		[3] = "D",
		[4] = "F",
		[5] = "G",
		[6] = "H",
	},
	[3] = {
		[1] = "Z",
		[2] = "X",
		[3] = "C",
		[4] = "V",
		[5] = "B",
		[6] = "N",
	},
}

-- DGun button progressbar, for listening to special-weapon reload progress
--VFS.Include("LuaRules/Configs/customcmds.h.lua") --already included in "include("Configs/integral_menu_commands.lua")"
local reverseCompat = (Game.version:find('91.0') == 1) and 1 or 0
local turnOffReloadableWeaponChecks = false
local reloadableButton = {
	[CMD.MANUALFIRE] = {progress=0,status=nil},
	[CMD_ONECLICK_WEAPON] = {progress=0,status=nil},
	[CMD_JUMP] = {progress=0,status=nil},
}

-- Chili classes
local Chili
local Button
local Label
local Colorbars
local Checkbox
local Window
local Panel
local StackPanel
local TextBox
local Image
local Progressbar
local Control

-- Chili instances
local screen0
local window		--main window (invisible)
local fakewindow	--visible Panel
local menuTabRow	--parent row of tabs
local menuTabs = {}		--buttons
local commands_main	--parent column of command buttons
local sp_commands = {}	--buttons
local states_main	--parent row of state buttons
local sp_states = {}	--buttons
local buildRow	--row of build queue buttons
local buildRowButtons = {}	--contains arrays indexed by number 1 to MAX_COLUMNS, each of which contains three subobjects: button, label and image
local buildProgress	--Progressbar, child of buildRowButtons[1].image; updates every gameframe
local buildRow_dragDrop = {nil,nil,nil} --current buildqueue that is being dragged by user.

local buildRow_visible = false
local buildQueue = {}	--build order table of selectedFac
local buildQueueUnsorted = {}	--puts all units of same type into single index; thus no sequence

local gridLocation = {}

-- arrays with commands to be displayed 
local n_common = {}
local n_factories = {}
local n_econ = {}
local n_defense = {}
local n_special = {}
local n_units = {}
local n_states = {}

--shortcuts
local menuChoices = {
	[1] = { array = n_common, name = "Order", hotkeyName = "Order" },
	[2] = { array = n_factories, name = "Factory", hotkeyName = "Factory", config = factory_commands, actionName = "epic_chili_integral_menu_tab_factory" },
	[3] = { array = n_econ, name = "Econ", hotkeyName = "Econ", config = econ_commands, actionName = "epic_chili_integral_menu_tab_economy" },
	[4] = { array = n_defense, name = "Defense", hotkeyName = "Defense", config = defense_commands, actionName = "epic_chili_integral_menu_tab_defence" },
	[5] = { array = n_special, name = "Special", hotkeyName = "Special", config = special_commands, actionName = "epic_chili_integral_menu_tab_special" },
	[6] = { array = n_units, name = "Units", hotkeyName = "Units" },
}

local menuChoice = 1
local lastBuildChoice = 2

-- command id indexed field of items - each item is button, label and image 
local commandButtons = {} 
local spaceClicked = false
----------------------------------- COMMAND COLORS  - from cmdcolors.txt - default coloring
local cmdColors = {}

-- default config
local config = {
}


------------------------
--  FUNCTIONS
------------------------
-- this gets invoked when button is clicked 
local function ClickFunc(button, x, y, mouse)
	local left, right = mouse == 1, mouse == 3
	local alt,ctrl,meta,shift = Spring.GetModKeyState()
	local mb = (left and 1) or (right and 3)
	if mb then
		local index = Spring.GetCmdDescIndex(button.cmdid)
		if index then
			Spring.SetActiveCommand(index,mb,left,right,alt,ctrl,meta,shift)
		end
	end
end

------------------------
--  Generates or updates chili button - either image or text or both based - container is parent of button, cmd is command desc structure
------------------------
local function MakeButton(container, cmd, insertItem, index)
	local isState = (cmd.type == CMDTYPE.ICON_MODE and #cmd.params > 1) or states_commands[cmd.id]	--is command a state toggle command?
	local isBuild = (cmd.id < 0)
	local gridHotkeyed = not isState and menuChoice ~= 1 and menuChoice ~= 6 
	local text
	local texture
	local countText = ''
	local tooltip = cmd.tooltip

	local te = overrides[cmd.id]  -- command overrides 
	
	-- text 
	if te and te.text then 
		text = te.text 
	elseif isState then 
		text = cmd.params[cmd.params[1]+2]
	elseif isBuild then
		text = ''
	else 
		text = cmd.name 
	end
	
	local hotkey = cmd.action and WG.crude.GetHotkey(cmd.action) or ''
	
	if (options.unitstabhotkey.value and menuChoice == 6 and selectedFac and container.i_am_sp_commands) then
		if options.unitshotkeyrequiremeta.value then
			local alt,ctrl,meta,shift = Spring.GetModKeyState()
			if meta or (alt and options.unitshotkeyaltaswell.value) then
				hotkey = gridMap[container.index][index] or ''
			end
		else
			hotkey = gridMap[container.index][index] or ''
		end
	end
	if gridHotkeyed and hotkeyMode then
		hotkey = gridMap[container.index][index] or ''
	end
	
	if not isState and hotkey ~= '' then
		text = '\255\0\255\0' .. hotkey
	end
	
	--count label (for factory build options)
	if menuChoice == 6 and isBuild and buildQueueUnsorted[-cmd.id] then
		countText = tostring(buildQueueUnsorted[-cmd.id])
	end
	
	--texture 
	if te ~= nil and te.texture then 
		if (isState) then 
			texture = te.texture[cmd.params[1]+1]
		else 
			texture = te.texture
		end 
	elseif isBuild then
		texture = '#'..-cmd.id
	else
		texture = cmd.texture
	end 
	
	-- tooltip 
	if te and te.tooltip then 
		tooltip = te.tooltip
	else 
		tooltip = cmd.tooltip
	end
	if isBuild and selectedFac then
		local ud = UnitDefs[-cmd.id]
		tooltip = "Build Unit: " .. ud.humanName .. " - " .. ud.tooltip .. "\n"	-- for special options
	end
	
	if hotkey ~= '' then
		tooltip = tooltip .. ' (\255\0\255\0' .. hotkey .. '\008)'	
	end
	
	-- get cached menu item 
	local item = commandButtons[cmd.id]
	if not item then  -- no item, create one 
		if not insertItem then 
			Spring.SendMessage("CommandBar - internal error, unexpectedly adding item!")
		end 
		-- decide color 
--[[		local color = {1,1,1,1}
		if te ~= nil and te.color ~= nil then 
			color = te.color 
		elseif cmd.name ~= nil then 
			local nl = cmd.name:lower()
			if cmdColors[nl] then 
				color = cmdColors[nl]
				color[4] = color[4] + 0.2
			end 
		end]]
		
		local button = Button:New {
			parent=container;
			padding = {5, 5, 5, 5},
			margin = {0, 0, 0, 0},
			caption="";
			isDisabled = cmd.disabled;
			tooltip = tooltip;
			cmdid = cmd.id;
			OnClick = {function(self, x, y, mouse) ClickFunc(self, x, y, mouse) end}
		}
		if (isState) then 
			button.padding = {4,4,2.5,2}
--			button.backgroundColor = {0,0,0,0}
		end 
		if (isBuild) then
			button.padding = {1,1,1,1}
		end
		
		local label 
		if (not cmd.onlyTexture and text and text ~= '') or gridHotkeyed or menuChoice == 6 then 
			label = Label:New {
				width="100%";
				height="100%";
				autosize=false;
				align="left";
				valign="top";
				caption = text;
				fontSize = 11;
				fontShadow = true;
				parent = button;
			}
		end
		
		if isBuild then
			local costLabel = Label:New {
				parent = button,
				right = 0;
				y = 0;
				x = 3;
				bottom = 3;
				autosize=true; -- this (autosize=true) allow text to be truncated/cut off if button size is too small (prevent a wall-of-text on build icon if button is too small)
				align="left";
				valign="bottom";
				caption = string.format("%d m", UnitDefs[-cmd.id].metalCost);
				fontSize = 11;
				fontShadow = true;
			}		
		end
		
		local image
		if (texture and texture ~= "") then
			image= Image:New {
				width="90%";
				height= (not isBuild) and nil or "90%";
				bottom = (isBuild) and 10 or nil;
				y="5%";
				x="5%";
--				color = color;
				keepAspect = not isBuild,	--true,	--isState;
				file = texture;
				parent = button;
			}
			if isBuild then 
				image.file2 = WG.GetBuildIconFrame(UnitDefs[-cmd.id]) 
			end 
			
			if isState then 
				height = "100%"
				y = 0
			end
		else 
			if label~=nil then label.valign="center" end
		end 
		
		local countLabel
		if isBuild then
			countLabel = Label:New {
				parent = image,
				autosize=false;
				width="100%";
				height="100%";
				align="right";
				valign="bottom";
				caption = countText;
				fontSize = 16;
				fontShadow = true;
			}
		end
		

		--if button is disabled, set effect accordingly
		if button.isDisabled then 
			button.backgroundColor = {0,0,0,1};
			image.color = {0.3, 0.3, 0.3, 1}
		end
		
		item = {
			button = button,
			image = image,
			label = label,
			countLabel = countLabel,
		}
		commandButtons[cmd.id] = item
	else 
		if insertItem then 
			container:AddChild(item.button)
		end 
	end 
	
	-- update item if something changed
	if (cmd.disabled ~= item.button.isDisabled) then 
		if cmd.disabled then 
			item.button.backgroundColor = {0,0,0,1};
			item.image.color = {0.3, 0.3, 0.3, 1}
		else 
			item.button.backgroundColor = {1,1,1,0.7};
			item.image.color = {1, 1, 1, 1}
		end 
		item.button:Invalidate()
		item.image:Invalidate()
		item.button.isDisabled = cmd.disabled
	end 
	
	if (not cmd.onlyTexture and item.label and text ~= item.label.caption) then 
		item.label:SetCaption(text)
	end
	
	if (item.countLabel and countText ~= item.countLabel.caption) then
		item.countLabel:SetCaption(countText)
	end
	
	if (item.image and (texture ~= item.image.file or isState) ) then 
		item.image.file = texture
		item.image:Invalidate()
	end
	
	if (item.button.tooltip and tooltip ~= item.button.tooltip) then
		item.button.tooltip = tooltip
	end
end

--sorts commands into categories
local function ProcessCommand(cmd) 
	if not cmd.hidden and cmd.id ~= CMD_PAGES then 
		-- state icons 
		if (cmd.type == CMDTYPE.ICON_MODE and cmd.params ~= nil and #cmd.params > 1) then 
			n_states[#n_states+1] = cmd 
		elseif common_commands[cmd.id] then 
			n_common[#n_common+1] = cmd
		elseif factory_commands[cmd.id] then
			n_factories[#n_factories+1] = cmd
		elseif econ_commands[cmd.id] then
			n_econ[#n_econ+1] = cmd
		elseif defense_commands[cmd.id] then
			n_defense[#n_defense+1] = cmd
		elseif special_commands[cmd.id] then
			n_special[#n_special+1] = cmd
		elseif UnitDefs[-(cmd.id)] then
			n_units[#n_units+1] = cmd
		else
			n_common[#n_common+1] = cmd	--shove unclassified stuff in common
		end
	end
end 

local function RemoveChildren(container) 
	for i = 1, #container.children do 
		container:RemoveChild(container.children[1])
	end
end 

-- compared real chili container with new commands and update accordingly
local function UpdateContainer(container, nl, columns) 
	if not columns then columns = MAX_COLUMNS end 
	local cnt = 0 
	local needUpdate = false 
	local dif = {}
	for i =1, #container.children do  
		if container.children[i].isEmpty then 
			break 
		end 
		cnt = cnt + 1 
		dif[container.children[i].cmdid] = true 
	end 
	
	if cnt ~= #nl then  -- different counts, we update fully
		needUpdate = true 
	else  -- check if some items are different 
		for i=1, #nl do  
			dif[nl[i].id] = nil
		end 
	
		for _, _ in pairs(dif) do  -- different item found, we do full update 
			needUpdate = true 
			break
		end 
	end 
	
	if needUpdate then 
		RemoveChildren(container) 
		for i=1, #nl do 
			MakeButton(container, nl[i], true, i)
		end 
		for i = 1, columns - #container.children do 
			Control:New {
				isEmpty = true,
				parent = container
			}
		end 
	else 
		for i=1, #nl do 
			MakeButton(container, nl[i], false, i)
		end 
	end 
end 

local function BuildRowButtonFunc(num, cmdid, left, right,addInput,insertMode,customUnitID)
	local targetFactory = customUnitID or selectedFac
	buildQueue = spGetFullBuildQueue(targetFactory)
	num = num or (#buildQueue+1) -- insert build at "num" or at end of queue
	local alt,ctrl,meta,shift = Spring.GetModKeyState()
	local pos = 1
	local numInput = 1	--number of times to send the order
	
	local function BooleanMult(int, bool)
		if bool then return int
		else return 0 end
	end
	
	--CMD.OPT_META = 4
	--CMD.OPT_RIGHT = 16
	--CMD.OPT_SHIFT = 32
	--CMD.OPT_CTRL = 64
	--CMD.OPT_ALT = 128
	
	--it's not using the options, even though it's receiving them correctly
	--so we have to do it manually
	if shift then numInput = numInput * 5 end
	if ctrl then numInput = numInput * 20 end
	numInput = numInput + (addInput or 0) -- to insert specific amount without SHIFT or CTRL modifier
	
	--local options = BooleanMult(CMD.OPT_SHIFT, shift) + BooleanMult(CMD.OPT_ALT, alt) + BooleanMult(CMD.OPT_CTRL, ctrl) + BooleanMult(CMD.OPT_META, meta) + BooleanMult(CMD.OPT_RIGHT, right)
	
	--insertion position is by unit rather than batch, so we need to add up all the units in front of us to get the queue
	
	for i=1,num-1 do
		for _,unitCount in pairs(buildQueue[i]) do
			pos = pos + unitCount
		end
	end
	
	-- skip over the commands with an id of 0, left behind by removal
	local commands = Spring.GetFactoryCommands(targetFactory)
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
			Spring.GiveOrderToUnit(targetFactory, CMD.INSERT, {pos, cmdid, 0 }, {"alt", "ctrl"})
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
			Spring.GiveOrderToUnit(targetFactory, CMD.REMOVE, {commands[i+pos].tag}, {"ctrl"})
			alreadyRemovedTag[commands[i+pos].tag] = true
			j = j + 1
			i = i - 1
		end 
	end
end

local function UpdateFactoryBuildQueue() 
	buildQueue = spGetFullBuildQueue(selectedFac)
	buildQueueUnsorted = {}
	for i=1, #buildQueue do
		for udid, count in pairs(buildQueue[i]) do
			buildQueueUnsorted[udid] = (buildQueueUnsorted[udid] or 0) + count
			--Spring.Echo(udid .. "\t" .. buildQueueUnsorted[udid])
		end
	end
end

--uses its own function for more fine control
local function ManageBuildRow()
	--if (menuChoice ~= 6) or (not buildRow_visible) or (not selectedFac) then return end
	local overrun = false
	RemoveChildren(buildRow)
	if buildQueue[MAX_COLUMNS + 1] then 
		overrun = true 
	end

	for i=1, MAX_COLUMNS do
		local buttonArray = buildRowButtons[i]
		if buttonArray.button then
			RemoveChildren(buttonArray.button)
		end
		if buildQueue[i] then	--adds button for queued unit
			local udid, count, caption
			for id, num in pairs(buildQueue[i]) do
				udid = id
				count = num
				break
			end
			buildRowButtons[i].cmdid = -udid
			if overrun and i == MAX_COLUMNS then
				caption = tostring(#buildQueue - MAX_COLUMNS + 1)
			elseif count > 1 then caption = tostring(count)
			else caption = '' end
			buttonArray.button = Button:New{
				parent = buildRow;
				x = (i-1)*(100/MAX_COLUMNS).."%",
				y = 0,
				width = (100/MAX_COLUMNS).."%",
				height = "100%",
				caption = '', --remove "notext" behind button (which is visible if menu is downsized)
				OnClick = {	function (self, x, y, mouse) 
					local left, right = mouse == 1, mouse == 3
					BuildRowButtonFunc(i, buildRowButtons[i].cmdid, left, right)
					buildRow_dragDrop[1] = nil
					end},
				padding = {1,1,1,1},
				--keepAspect = true,
				
				OnMouseDown = { function(self,x,y,mouse) --for drag_drop feature
					if mouse == 1 then
						buildRow_dragDrop[1] = i; 
						buildRow_dragDrop[2] = -buildRowButtons[i].cmdid
						buildRow_dragDrop[3] = count-1;
						buildRow_dragDrop[4] = self.width/2
					end
					end},
				OnMouseUp = { function(self,x,y,mouse) -- MouseRelease event, for drag_drop feature --note: x & y is coordinate with respect to self
					local px,py = self:LocalToParent(x,y) --get coordinate with respect to parent
					if mouse == 1 and (x>self.width or x<0) and px> 0 and px< buildRow.width and py> 0 and py< buildRow.height then
						local prevIndex = buildRow_dragDrop[1]
						local currentIndex = math.ceil(px/(buildRow.width/MAX_COLUMNS)) --estimate on which button mouse was released
						if not buildQueue[currentIndex] then --drag_dropped to the end of queue
							currentIndex = #buildQueue
							if currentIndex == prevIndex then --drag_dropped from end of queue to end of queue
								return
							end
						end
						local countTransfer = buildRow_dragDrop[3]
						if buildRow_dragDrop[1] > currentIndex then --select remove & adding sequence that reduce complication from network delay
							BuildRowButtonFunc(prevIndex, buildRowButtons[prevIndex].cmdid, false, true,countTransfer) --remove queue on the right, first
							BuildRowButtonFunc(currentIndex, buildRowButtons[prevIndex].cmdid, true, false,countTransfer,true) --then, add queue to the left
						else
							BuildRowButtonFunc(currentIndex+1, buildRowButtons[prevIndex].cmdid, true, false,countTransfer,true) --add queue to the right, first
							BuildRowButtonFunc(prevIndex, buildRowButtons[prevIndex].cmdid, false, true,countTransfer) --then, remove queue on the left
						end
						buildRow_dragDrop[1] = nil
					end
					end},
			}
			if overrun and i == MAX_COLUMNS then
				buttonArray.button.caption = '...'
				buttonArray.button.OnClick = nil
			end
			buttonArray.button.backgroundColor[4] = 0.3
			
			if not (overrun and i == MAX_COLUMNS) then
				buttonArray.button.tooltip = "\255\1\255\1Hold Left mouse \255\255\255\255: drag drop to different factory or position in queue\n"..
					"\255\1\255\1Left/Right click \255\255\255\255: Add to/subtract from queue"
				buttonArray.image = Image:New {
					parent = buttonArray.button,
					width="90%";
					height="90%";
					x="5%";
					y="5%";
					file = '#'..udid,
					file2 = WG.GetBuildIconFrame(UnitDefs[udid]),
					keepAspect = false,
				}
				buttonArray.label = Label:New {
					parent = buttonArray.image,
					width="100%";
					height="100%";
					autosize=false;
					--x = "70%",
					--y = "70%",
					align="right";
					valign="bottom";
					--caption = caption;
					fontSize = 16;
					fontShadow = true;
				}
				buttonArray.label:SetCaption(caption)	-- do it here as workaround for vanishing text
			end
			
			if i == 1 then
				buttonArray.image:AddChild(buildProgress)
				--Spring.Echo("Adding build progress bar")
			end
		end
	end
end

--these two functions place the items into their rows
local function ManageStateIcons()
	local stateCols = { }
	for i=1, numStateColumns do
		stateCols[i] = {}
		for v=(MAX_STATE_ROWS * (i-1)) + 1, (MAX_STATE_ROWS*i) do
			stateCols[i][v - MAX_STATE_ROWS*(i-1)] = n_states[v]
		end
	end
	for i=1, numStateColumns do
		UpdateContainer(sp_states[i], stateCols[i], MAX_STATE_ROWS)
	end
end

local function ManageCommandIcons(useRowSort)
	local sourceArray = menuChoices[menuChoice].array
	local configArray = menuChoices[menuChoice].config
	--update factory data
	if menuChoice == 6 and selectedFac then
		UpdateFactoryBuildQueue()
	end
	local commandRows = { }
	--most commands don't use row sorting; econ, defense and special do
	if not useRowSort then
		for i=1, numRows do
			commandRows[i] = {}
			for v=(MAX_COLUMNS * (i-1)) + 1, (MAX_COLUMNS*i) do
				commandRows[i][v - MAX_COLUMNS*(i-1)] = sourceArray[v]
			end
		end
	else
		for i=1, numRows do
			commandRows[i] = {}
			for v=1,#sourceArray do
				if configArray[sourceArray[v].id].row == i then
					commandRows[i][#commandRows[i]+1] = sourceArray[v]
				end
			end
		end	
	end
	for i=1, numRows do
		UpdateContainer(sp_commands[i], commandRows[i], MAX_COLUMNS)
	end
	
	--manage factory queue if needed
	if menuChoice == 6 and selectedFac and #commandRows[numRows] == 0 then
		if not buildRow_visible then
			commands_main:AddChild(buildRow)
			buildRow_visible = true
		end
		ManageBuildRow()
	else
		commands_main:RemoveChild(buildRow)
		buildRow_visible = false
	end
end

local function Update(buttonpush) 
	local commands = widgetHandler.commands
	local customCommands = widgetHandler.customCommands
	--most commands don't use row sorting; econ, defense and special do
	local useRowSort = (menuChoice == 3 or menuChoice == 4 or menuChoice == 5)
	
	if menuChoice == 1 then
		hotkeyMode = false
	end
	
	--if (#commands + #customCommands == 0) then 
		---screen0:RemoveChild(window);
		--window_visible = false;
	--	return
	--else 
		--if not window_visible then 
			--screen0:AddChild(window);
			--window_visible = true;
		--end 
	--end 
	
	n_common = {}
	n_factories = {}
	n_econ = {}
	n_defense = {}
	n_special = {}
	n_units = {}
	n_states = {}
	
	--Spring.Echo(#commands)
	for i = 1, #commands do ProcessCommand(commands[i]) end 
	for i = 1, #customCommands do ProcessCommand(customCommands[i]) end 
	for i = 1, #globalCommands do ProcessCommand(globalCommands[i]) end
	
	menuChoices[1].array = n_common
	menuChoices[2].array = n_factories
	menuChoices[3].array = n_econ
	menuChoices[4].array = n_defense
	menuChoices[5].array = n_special
	menuChoices[6].array = n_units
	
	--[[
	local function Sort(a, b, array)
		return array[a.id] < array[b.id]
	end
	
	table.sort(n_factories, Sort(a,b, factory_commands))
	table.sort(n_econ, Sort(a,b, econ_commands))
	table.sort(n_defense, Sort(a,b, defense_commands))
	]]--
	
	--sorting isn't strictly needed, it uses the same order as listed in buildoptions
	table.sort(n_factories, function(a,b) return factory_commands[a.id].order < factory_commands[b.id].order end )
	table.sort(n_econ, function(a,b) return econ_commands[a.id].order < econ_commands[b.id].order end)
	table.sort(n_defense, function(a,b) return defense_commands[a.id].order < defense_commands[b.id].order end)
	table.sort(n_special, function(a,b) return special_commands[a.id].order < special_commands[b.id].order end)

	ManageStateIcons()
	ManageCommandIcons(useRowSort)
end 

local function MakeMenuTab(i, alpha)
	local button = Button:New{
		parent = menuTabRow;
		y = 0,
		height = "100%",
--		font = {
--			shadow = true
--		},
		
		caption = hotkeyMode and menuChoices[i].name or menuChoices[i].hotkeyName,
		OnClick = {
			function()
				menuChoice = i
				if i >= 2 and i <= 5 then lastBuildChoice = i end
				Update(true)
				ColorTabs(i)
			end
		},
	}
	button.backgroundColor[4] = alpha or 1
	return button
end

--need to recreate the tabs completely because chili is dumb
--also needs to be non-local so MakeMenuTab can call it
function ColorTabs(arg)
	arg = arg or menuChoice
	RemoveChildren(menuTabRow)
	for i=1,6 do
		if i == arg then
			menuTabs[arg] = MakeMenuTab(arg, 1)
		else
			menuTabs[i] = MakeMenuTab(i, 0.4)
		end
	end
end

local function SmartTabSelect()
	Update()
	if options.hidetabs.value then
		menuChoice = 1
		ColorTabs(1)
	elseif options.disablesmartselect.value then 
		return
	elseif #n_units > 0 and #n_econ == 0 then
		menuChoice = 6	--selected factory, jump to units
		ColorTabs(6)
	elseif #n_econ > 0 and menuChoice == 6 then
		menuChoice = lastBuildChoice	--selected non-fac and in units menu, jump to last build menu
		ColorTabs(lastBuildChoice)
	elseif #n_factories + #n_econ + #n_defense + #n_units == 0 then
		menuChoice = 1	--selected non-builder, jump to common
		ColorTabs(1)
	end
end

local function CopyTable(outtable,intable)
  for i,v in pairs(intable) do 
    if (type(v)=='table') then
      if (type(outtable[i])~='table') then outtable[i] = {} end
      CopyTable(outtable[i],v)
    else
      outtable[i] = v
    end
  end
end

-- force update every 0.2 seconds
--[[
local timer = 0
function widget:Update(dt)
	timer = timer + dt
	if timer >= forceUpdateFrequency then
		Update()
		timer = 0
	end
end
]]--
-- layout handler - its needed for custom commands to work and to delete normal spring menu
local function LayoutHandler(xIcons, yIcons, cmdCount, commands)
	widgetHandler.commands   = commands
	widgetHandler.commands.n = cmdCount
	widgetHandler:CommandsChanged()
	local reParamsCmds = {}
	local customCmds = {}
	
	local cnt = 0
	
	local AddCommand = function(command) 
		local cc = {}
		CopyTable(cc,command )
		cnt = cnt + 1
		cc.cmdDescID = cmdCount+cnt
		if (cc.params) then
			if (not cc.actions) then --// workaround for params
				local params = cc.params
				for i=1,#params+1 do
					params[i-1] = params[i]
				end
				cc.actions = params
			end
			reParamsCmds[cc.cmdDescID] = cc.params
		end
		--// remove api keys (custom keys are prohibited in the engine handler)
		cc.pos       = nil
		cc.cmdDescID = nil
		cc.params    = nil
		
		customCmds[#customCmds+1] = cc
	end 
	
	
	--// preprocess the Custom Commands
	for i=1,#widgetHandler.customCommands do
		AddCommand(widgetHandler.customCommands[i])
	end
	
	for i=1,#globalCommands do
		AddCommand(globalCommands[i])
	end

	Update()
	if (cmdCount <= 0) then
		return "", xIcons, yIcons, {}, customCmds, {}, {}, {}, {}, reParamsCmds, {} --prevent CommandChanged() from being called twice when deselecting all units  (copied from ca_layout.lua)
	end
	return "", xIcons, yIcons, {}, customCmds, {}, {}, {}, {}, reParamsCmds, {[1337]=9001}
end 

local function ScrollTabRight()
	menuChoice = menuChoice + 1
	if menuChoice > #menuChoices then menuChoice = 1 end
	if menuChoice >= 2 and menuChoice <= 5 then lastBuildChoice = menuChoice end
	Update(true)
	ColorTabs()
end

local function ScrollTabLeft()
	menuChoice = menuChoice - 1
	if menuChoice < 1 then menuChoice = #menuChoices end
	if menuChoice >= 2 and menuChoice <= 5 then lastBuildChoice = menuChoice end
	Update(true)
	ColorTabs()
end

--------------------------------------
-- Hotkey Mode

function widget:KeyPress(key, modifier, isRepeat)
	if (hotkeyMode) and not isRepeat then 
		local thingsDone = false
		local pos = gridKeyMap[key]
		if pos and sp_commands[pos[1]] and sp_commands[pos[1]].children[pos[2]] then
			local cmdid = sp_commands[pos[1]].children[pos[2]]
			if cmdid then
				cmdid = cmdid.cmdid
				if cmdid then 
					local index = Spring.GetCmdDescIndex(cmdid)
					if index then
						Spring.SetActiveCommand(index,1,true,false,false,false,false,false)
						thingsDone = true
					end
				end
			end
		end
		hotkeyMode = false
		menuChoice = 1 -- auto-return to orders to make it clear hotkey time is over
		Update(true)
		ColorTabs()
		return thingsDone 
	elseif menuChoice == 6 and options.unitstabhotkey.value and selectedFac then
		local pos = gridKeyMap[key]
		if pos and pos[1] ~= 3 and sp_commands[pos[1]] and sp_commands[pos[1]].children[pos[2]] then
			local cmdid = sp_commands[pos[1]].children[pos[2]]
			if cmdid then
				cmdid = cmdid.cmdid
				if cmdid then 
					local index = Spring.GetCmdDescIndex(cmdid)
					if index then
						local alt,ctrl,meta,shift = Spring.GetModKeyState()
						if (meta or (alt and options.unitshotkeyaltaswell.value) or not options.unitshotkeyrequiremeta.value) and not ctrl then
							local opts = 0
							if alt then
								opts = opts + CMD.OPT_ALT
							end
							if shift then
								opts = opts + CMD.OPT_SHIFT
							end
							Spring.GiveOrderToUnit(selectedFac, cmdid, {0}, opts)
							if WG.sounds_gaveOrderToUnit then
								WG.sounds_gaveOrderToUnit(selectedFac, true)
							end
							-- does not work with meta held
							--Spring.SetActiveCommand(index,1,true,false,alt,false,false,shift)
							return true
						end
					end
				end
			end
		end
	end

	if (key == KEYSYMS.SPACE or ((key == KEYSYMS.RALT or key == KEYSYMS.LALT) and options.unitshotkeyaltaswell.value)) and selectedFac and menuChoice == 6 and options.unitshotkeyrequiremeta.value  and options.unitstabhotkey.value then
		Update(true)
	end
end

function widget:KeyRelease(key, modifier, isRepeat)
	if (key == KEYSYMS.SPACE or ((key == KEYSYMS.RALT or key == KEYSYMS.LALT) and options.unitshotkeyaltaswell.value)) and selectedFac and menuChoice == 6 and options.unitshotkeyrequiremeta.value and options.unitstabhotkey.value then
		Update(true)
	end
end

	--Spring.Echo(CMD.OPT_META) = 4
	--Spring.Echo(CMD.OPT_RIGHT) = 16
	--Spring.Echo(CMD.OPT_SHIFT) = 32
	--Spring.Echo(CMD.OPT_CTRL) = 64
	--Spring.Echo(CMD.OPT_ALT) = 128

local function HotkeyTabFactory()
	menuChoice = 2
	hotkeyMode = true
	Update(true)
	ColorTabs()
end

local function HotkeyTabEconomy()
	menuChoice = 3
	hotkeyMode = true
	Update(true)
	ColorTabs()
end

local function HotkeyTabDefence()
	menuChoice = 4
	hotkeyMode = true
	Update(true)
	ColorTabs()
end

local function HotkeyTabSpecial()
	menuChoice = 5
	hotkeyMode = true
	Update(true)
	ColorTabs()
end

options.tab_factory.OnChange = HotkeyTabFactory
options.tab_economy.OnChange = HotkeyTabEconomy
options.tab_defence.OnChange = HotkeyTabDefence
options.tab_special.OnChange = HotkeyTabSpecial

local function AddAction(cmd, func, data, types)
	return widgetHandler.actionHandler:AddAction(widget, cmd, func, data, types)
end
local function RemoveAction(cmd, types)
	return widgetHandler.actionHandler:RemoveAction(widget, cmd, types)
end

--this function add hotkey text to each tab name
local function updateTabName(num, choice)
	local hotkey = WG.crude.GetHotkey(choice.actionName)
	if hotkey ~= '' then
		choice.hotkeyName = choice.name ..  '(\255\0\255\0' .. hotkey .. '\008)'	
		choice.name = choice.name ..  '(' .. hotkey .. ')'
	end
end

--get reload status for selected weapon
local function IsWeaponManualFire(unitID, weapNum)
	local unitDefID = spGetUnitDefID(unitID)
	local unitDef = UnitDefs[unitDefID]
	local weaponNoX = (unitDef and unitDef.weapons and unitDef.weapons[weapNum])
	if (weaponNoX ~= nil) and WeaponDefs[weaponNoX.weaponDef].manualFire then
		local reloadTime = WeaponDefs[weaponNoX.weaponDef].reload
		return true,reloadTime
	end
	return nil --Note: this mean unit doesn't have weapon number 'weapNum'
end

-- INITS 
function widget:Initialize()
	widgetHandler:ConfigLayoutHandler(LayoutHandler)
	Spring.ForceLayoutUpdate()
	
	recentlyInitialized = true
	
	RemoveAction("nextmenu")
	RemoveAction("prevmenu")	
	AddAction("nextmenu", ScrollTabRight, nil, "p")
	AddAction("prevmenu", ScrollTabLeft, nil, "p")
	
	--[[local f,it,isFile = nil,nil,false
	f  = io.open('cmdcolors.txt','r')
	if f then
		it = f:lines()
		isFile = true
	else
		f  = VFS.LoadFile('cmdcolors.txt')
		it = string.gmatch(f, "%a+.-\n")
	end
 
	local wp = '%s*([^%s]+)'           -- word pattern
	local cp = '^'..wp..wp..wp..wp..wp -- color pattern
	local sp = '^'..wp..wp             -- single value pattern like queuedLineWidth
 
	for line in it do
		local _, _, n, r, g, b, a = string.find(line, cp)
 
		r = tonumber(r or 1.0)
		g = tonumber(g or 1.0)
		b = tonumber(b or 1.0)
		a = tonumber(a or 1.0)
 
		if n then
			cmdColors[n]= { r, g,b,a}
		else
			_, _, n, r= string.find(line:lower(), sp)
			if n then
				cmdColors[n]= r
			end
		end
	end]]--
	
	-- setup Chili
	Chili = WG.Chili
	Button = Chili.Button
	Label = Chili.Label
	Colorbars = Chili.Colorbars
	Checkbox = Chili.Checkbox
	Window = Chili.Window
	Panel = Chili.Panel
	StackPanel = Chili.StackPanel
	TextBox = Chili.TextBox
	Image = Chili.Image
	Progressbar = Chili.Progressbar
	Control = Chili.Control
	screen0 = Chili.Screen0
	
	-- Set the size for the default settings.
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	local width = math.max(350, math.min(450, screenWidth*screenHeight*0.0004))
	local height = math.min(screenHeight/4.5, 200*width/450)
	
	--create main Chili elements
	window = Window:New{
		parent = screen0,
		name   = 'integralwindow';
		color = {0, 0, 0, 0},
		width = width,
		height = height,
		x = 0, 
		bottom = 0,
		dockable = true;
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		minWidth = MIN_WIDTH,
		minHeight = MIN_HEIGHT,
		padding = {0, 0, 0, 0},
		--itemMargin  = {0, 0, 0, 0},
	}
	
	fakewindow = Panel:New{
		parent = window,
		x = 0,
		y = '15%',
		width = "100%";
		height = "86%";
		--disableChildrenHitTest = false,
		--itemMargin  = {0, 0, 0, 0},
		dockable = false;
		draggable = false,
		resizable = false,
		padding = {0, 0, 0, 0},
		backgroundColor = {1, 1, 1, 0.8},
--		skinName  = "DarkGlass",
	}

	menuTabRow = StackPanel:New{
		parent = window,
		resizeItems = true;
		columns = 6;
		orientation   = "horizontal";
		height = "15%";
		width = "99%";
		x = '1%';
		y = 0;
		padding = {0, 0, 0, 0},
		itemMargin  = {0, 0, 0, 0},
		OnMouseDown={ function(self) 
			local _,_, meta,_ = Spring.GetModKeyState()
			if not meta then return false end --allow button to continue its function
			WG.crude.OpenPath(options_path) --// click+ space on integral-menu tab will open a integral options.
			WG.crude.ShowMenu() --make epic Chili menu appear.
			return false
		end },		
	}
	
	for i=1,6 do
		menuTabs[i] = MakeMenuTab(i, 1)
	end
	ColorTabs()
	
	commands_main = Panel:New{
		parent = fakewindow,
		backgroundColor = {0, 0, 0, 0},
		height = "100%";
		width = COMMAND_SECTION_WIDTH.."%";
		x = "0%";
		y = "0%";
		padding = {4, 4, 0, 4},
		itemMargin  = {0, 0, 0, 0},
		noSelfHitTest = true,
		NCHitTest = function(self,x,y)
			if not spaceClicked and x> self.x and y>self.y and x<self.x+self.width and y<self.y+self.height then
				if select(3,Spring.GetMouseState()) and select(3,Spring.GetModKeyState()) then -- meta and mouse down
					spaceClicked = true
					WG.crude.OpenPath('Game/Commands')  -- click+ space on panel beside command button will open command-hotkey-binder
					WG.crude.ShowMenu() --make epic Chili menu appear.
				end
			end
			if spaceClicked and not (select(3,Spring.GetMouseState()) and select(3,Spring.GetModKeyState())) then --not meta, not mouse down
				spaceClicked = false
			end
			return false
		end,	
	}
	for i=1,numRows do
		sp_commands[i] = StackPanel:New{
			parent = commands_main,
			resizeItems = true;
			orientation   = "horizontal";
			height = math.floor(100/numRows).."%";
			width = "100%";
			x = "0%";
			y = math.floor(100/numRows)*(i-1).."%";
			padding = {0, 0, 0, 0},
			itemMargin  = {0, 0, 0, 0},
			index = i,
			i_am_sp_commands = true,
		}
		--Spring.Echo("Command row "..i.." created")
	end
	
	states_main = Panel:New{
		parent = fakewindow,
		backgroundColor = {0, 0, 0, 0},
		height = "100%";
		width = (STATE_SECTION_WIDTH).."%";
		--x = tostring(100-STATE_SECTION_WIDTH).."%";
		right = 0;
		y = "0%";
		padding = {0, 4, 4, 4},
		itemMargin  = {0, 0, 0, 0},
		OnMouseDown={ function(self) --// click+ space on any unit-State button will open Unit-AI menu,
			local _,_, meta,_ = Spring.GetModKeyState()
			if not meta then return false end --allow button to continue its function
			WG.crude.OpenPath('Game/Unit AI')
			WG.crude.ShowMenu() --make epic Chili menu appear.
			return true --stop the button's function, else unit-state button will look bugged. 
		end },			
	}
	for i=1, numStateColumns do
		sp_states[i] = StackPanel:New {
			parent = states_main,
			resizeItems = true;
			orientation   = "vertical";
			height = "100%";
			width = math.floor(100/numStateColumns).."%";
			x = (100 - (math.floor(100/numStateColumns))*i).."%";
			y = "0%";
			padding = {0, 0, 0, 0},
			itemMargin  = {0, 0, 0, 0},		
		}
	end
	
	buildRow = Panel:New{
		parent = commands_main,
		orientation   = "horizontal";
		height = (math.floor(100/numRows)).."%";
		width = "100%";
		x = "0%";
		y = (math.floor(100/numRows))*(numRows-1).."%";
		padding = {0, 0, 0, 0},
		itemMargin  = {0, 0, 0, 0},
		backgroundColor = {0, 0, 0, 0}
	}

	buildProgress = Progressbar:New{
		value = 0.0,
		name    = 'prog';
		max     = 1;
		color   		= {0.7, 0.7, 0.4, 0.6},
		backgroundColor = {1, 1, 1, 0.01},
		width = "92%",
		height = "92%",
		x = "4%",
		y = "4%",
		skin=nil,
		skinName='default',
	},
	
	commands_main:RemoveChild(buildRow)
	for i=1,MAX_COLUMNS do
		buildRowButtons[i] = {}
	end
end

local lastCmd = nil  -- last active command 
local lastColor = nil  -- original color of button with last active command
local lastFocusColor = nil

-- widget:DrawScreen() is needed to highlight active command
-- also draw build icon when drag_dropping queue to another factory
function widget:DrawScreen()
	-- highlight active command
	local _,cmdid,_,cmdname = Spring.GetActiveCommand()
	if cmdid ~= lastCmd then 
		if cmdid and commandButtons[cmdid]  then 
			local but = commandButtons[cmdid].button
			lastColor = but.backgroundColor
			lastFocusColor = but.focusColor
			but.backgroundColor = {0.8, 0, 0, 1}
			but.focusColor = {0.8, 0, 0, 1}
			but:Invalidate()
		end 
		if lastCmd ~= nil and commandButtons[lastCmd] then 
			local but = commandButtons[lastCmd].button
			but.backgroundColor = lastColor
			but.focusColor = lastFocusColor
			but:Invalidate()
		end 
		lastCmd = cmdid
	end
	--draw build icon when drag_drop queue to another factory
	if buildRow_dragDrop[1] then
		local mx,my,lmb = Spring.GetMouseState()
		if not lmb then
			local pointingAt, gpos = Spring.TraceScreenRay(mx,my)
			if gpos and pointingAt=='unit' and Spring.GetUnitTeam(gpos)==Spring.GetMyTeamID() then
				local udid = spGetUnitDefID(gpos)
				local ud = UnitDefs[udid]
				for _, options in ipairs(ud.buildOptions) do --check if target unit can build this queue. Copied from unit_central_build_ai.lua
					if ( options == buildRow_dragDrop[2] ) then 
						local countTransfer = buildRow_dragDrop[3]
						BuildRowButtonFunc(nil, -buildRow_dragDrop[2], true, false,countTransfer,false,gpos) --add to new factory
						BuildRowButtonFunc(buildRow_dragDrop[1], -buildRow_dragDrop[2], false, true,countTransfer) --remove from source
						break -- only one to find.
					end	
				end
			end
			buildRow_dragDrop[1] = nil
		else
			local size = buildRow_dragDrop[4]
			local udid = buildRow_dragDrop[2]
			gl.Color(1,1,1,0.5)
			gl.Texture(WG.GetBuildIconFrame(UnitDefs[udid])) --draw build icon on screen. Copied from gui_chili_gesture_menu.lua
			gl.TexRect(mx-size*0.2, my-size, mx+size*1.8, my+size)
			gl.Texture("#"..udid)
			gl.TexRect(mx-size*0.2, my-size, mx+size*1.8, my+size)
			gl.Texture(false)
			gl.Color(1,1,1,1)
			if buildRow_dragDrop[3]>1 then
				gl.Text(buildRow_dragDrop[3]+1,mx+size*1.5, my-size*0.57,14,"")
			end
		end
	end
end

-- Make the hotkeys appear on the menu tabs
function widget:Update()
	if recentlyInitialized then
		for i = 2, 5 do
			updateTabName(i, menuChoices[i])
		end
		recentlyInitialized = false
		ColorTabs(1)
	end
end

--This function update construction progress bar and weapon reload progress bar
function widget:GameFrame(n)
	--set progress bar
	if n%6 == 0 then
		if menuChoice == 6 and selectedFac and buildRowButtons[1] and buildRowButtons[1].image then
			local progress
			local unitBuildID      = spGetUnitIsBuilding(selectedFac)
			if unitBuildID then 
				progress = select(5, spGetUnitHealth(unitBuildID))
			end
			buildProgress:SetValue(progress or 0)
		end
	end
	--update/set dgun progress bar
	if n%7==0 and not turnOffReloadableWeaponChecks then --every 1/4 second & was not sleeping
		local oneclickweapon = reloadableButton[CMD_ONECLICK_WEAPON]
		oneclickweapon.status = nil
		oneclickweapon.progress = 0
		local manualfireweapon = reloadableButton[CMD.MANUALFIRE]
		manualfireweapon.status = nil
		manualfireweapon.progress = 0
		local jump = reloadableButton[CMD_JUMP]
		jump.status = nil
		jump.progress = 0
		local selectedUnitList = spGetSelectedUnits()
		local currentFrame = n
		for i=1, #selectedUnitList do
			local unitID = selectedUnitList[i]
			if not manualfireweapon.status then
				local _,_, weaponReloadFrame, _, _ = spGetUnitWeaponState(unitID, 3-reverseCompat) --Note: weapon no.3 is by ZK convention is usually used for user controlled weapon
				local isManualFire, reloadTime = IsWeaponManualFire(unitID, 3)
				if isManualFire then
					if weaponReloadFrame > currentFrame then
						manualfireweapon.status = false
						local remainingTime = (weaponReloadFrame - currentFrame)*1/30
						local reloadFraction =1 - remainingTime/reloadTime
						if manualfireweapon.progress < reloadFraction then
							manualfireweapon.progress = reloadFraction
						end
					else
						manualfireweapon.status = true
					end
				end
			end
			if not oneclickweapon.status then
				local specialReloadFrame = spGetUnitRulesParam(unitID,"specialReloadFrame")
				local specialReloadStart = spGetUnitRulesParam(unitID,"specialReloadStart")
				if specialReloadFrame then
					if specialReloadFrame > currentFrame then
						oneclickweapon.status = false
						if specialReloadStart then
							local reloadTime = specialReloadFrame - specialReloadStart
							local remainingTime = (specialReloadFrame - currentFrame)
							local reloadFraction =1 - remainingTime/reloadTime
							if oneclickweapon.progress < reloadFraction then
								oneclickweapon.progress = reloadFraction 
							end
						end
					else
						oneclickweapon.status = true
					end
				end
			end
			if not jump.status then
				local jumpReload = spGetUnitRulesParam(unitID,"jumpReload")
				if jumpReload then
					if jumpReload < 0.95 then
						jump.status = false
						if jump.progress < jumpReload then
							jump.progress = jumpReload 
						end
					else
						jump.status = true
					end
				end
			end	
		end
		for buttonID, status_progress in pairs(reloadableButton) do
			if commandButtons[buttonID] then
				if status_progress.status == true then
					commandButtons[buttonID].image.color = {1, 1, 1, 1}
					commandButtons[buttonID].image:Invalidate()
				elseif status_progress.status == false then
					local progress = status_progress.progress*0.7
					local grey = 0.3+ progress
					commandButtons[buttonID].image.color = {grey, grey, grey, 1}
					commandButtons[buttonID].image:Invalidate()
				end
			end
		end
		
		if jump.status == nil and oneclickweapon.status==nil and manualfireweapon.status==nil then 
			turnOffReloadableWeaponChecks = true --be efficient, turn off check if no reload state detected
		end
	end
end

function widget:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdTag)
	if cmdID == CMD.MANUALFIRE or cmdID == CMD_JUMP or cmdID == CMD_ONECLICK_WEAPON then
		turnOffReloadableWeaponChecks = false --wake up reload state checking, in case some new unit activated a reload state
	end
end

function widget:SelectionChanged(newSelection)
	--reset reloadable weapon button (newly created unit doesn't have reload state, if user select this unit it need to reset to default value first)
	for buttonID, _ in pairs(reloadableButton) do
		if commandButtons[buttonID] then
			commandButtons[buttonID].image.color = {1, 1, 1, 1}
			commandButtons[buttonID].image:Invalidate()
		end
	end
	turnOffReloadableWeaponChecks = false;
	
	--get new selected fac, if any
	for i=1,#newSelection do
		local id = newSelection[i]
		local defID = spGetUnitDefID(id) --is in LOS?
		if defID and UnitDefs[defID].isFactory then
			if selectedFac ~= id then
				alreadyRemovedTag = {}
			end
			selectedFac = id
			SmartTabSelect()
			return
		end
	end
	selectedFac = nil
	SmartTabSelect()
end

function widget:Shutdown()
	widgetHandler:ConfigLayoutHandler(options.old_menu_at_shutdown.value) --true: activate Default menu, false: activate dummy (empty) menu, nil: disable menu & CommandChanged() callins. See Layout.lua
	Spring.ForceLayoutUpdate()
end

options.hidetabs.OnChange = function(self) 
	fakewindow:SetPosRelative(_, self.value and 0 or '15%', _, self.value and '100%' or '86%')
	fakewindow:SetPosRelative(_, self.value and 0 or '15%', _, self.value and '100%' or '86%')
	
	if self.value then 
		window:RemoveChild(menuTabRow)
	else
		window:AddChild(menuTabRow)
	end
	menuChoice = 1
	ColorTabs(1)
end