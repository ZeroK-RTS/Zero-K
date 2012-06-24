-- TODO: make EPIC save changed options somehow!
-- TODO: add missing command icons
-- TODO: commandschanged gets called 2x for some reason, investigate
-- TODO: display which unit is currently selected
-- TODO: proper tooltips for queue buttons
-- TODO: make tab scrolling with keyboard detect actions prevmenu and nextmenu instead of KeyPress
-- TODO: Update() updates all tables - land/sea/advland/advsea/special and units - it is only needed if you select other stuff than you had before (something is missing/new).
-- TODO: make buildoptions scrollable

-- FIXME: Something limitates the buildoptions for some tabs. armwin is not in land_commands and corr is in tab_units! It is not a fault in border_menu_commands...
-- FIXME: Terraform got somehow added in the commands instead of the tabs.

function widget:GetInfo()
	-- Forked from "Chili Integral Menu v0.352" which is made by "Licho, KingRaptor, Google Frog" under "GNU GPL, v2 or later" since "2010-10-12"
	return {
		name = "Chili Border Menu",
		desc = "v0.352 Border Command Menu - beta",
		author = "NeonStorm",
		date = "2012-06-21",
		license = "GNU GPL, v2 or later",
		layer = math.huge-1,
		enabled = true,
		handler = false, -- loaded by default?
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

		Two parent StackPanels (children of fake window), a column for normal commands and a row for state commands.
		<numRows> (or <NUM_STATE_COMUMNS>) more StackPanels are nested in each of the parents, at right angles.
		When sorting commands, it splits commands into batches of <MAX_COMMAND_COLUMNS> and assigns them to children
			so if there are 10 commands, it puts 6 in first row and 4 in second row
			Build orders work a little differently, they have a predefined row in the config.
		Ditto for states, except it uses MAX_STATE_ROWS
--
		If unit tab is selected and third command row is free, build queue of first selected factory found in array returned by SelectionChanged is displayed.
		The queue shows up to <MAX_COMMAND_COLUMNS> batches of units and their exact sequence.

	All items resize with main window.

NOTE FOR OTHER GAME DEVS:
	ZK uses WG.GetBuildIconFrame to draw the unit type border around buildpics.
	If you're not using them (likely), remove all lines containing that function.
--]]

------------------------
--  CONFIG
------------------------
------------------------
options_path = 'Settings/Interface/Border Menu'
options_order = { 'invert', 'rotate', 'disablesmartselect', 'hidetabs', 'tab_units_hotkeys', 'tab_units_hotkeys_requiremeta', 'tab_units_hotkeys_altaswell', 'tab_land', 'tab_sea', 'tab_advland', 'tab_advsea', 'tab_special', 'tab_units' }
options = {
	invert = {
		name = 'Invert row order',
		description = 'Invert row order of - tabs/build/queue',
		type = 'bool',
		advanced = true,
		value = false,
	},
	rotate = {
		name = 'Rotate by 90',
		description = 'Rotate everything by 90° to get vertical rows and horizontal columns',
		type = 'bool',
		advanced = true,
		value = false,
	},
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
	tab_units_hotkeys = {
		name = 'Hotkeys for Units within Unit Tab',
		type = 'bool',
		value = true,
	},
	tab_units_hotkeys_requiremeta = {
		name = 'Units tab hotkeys require Meta',
		type = 'bool',
		value = true,
	},
	tab_units_hotkeys_altaswell = {
		name = 'Units tab can use Alt as Meta',
		type = 'bool',
		value = false,
	},
	tab_land = {
		name = "Land Tab",
		desc = "Switches to land tab, enables grid hotkeys",
		type = 'button',
		hotkey = {key='z', mod=''},
	},
	tab_sea = {
		name = "Sea Tab",
		desc = "Switches to sea tab, enables grid hotkeys",
		type = 'button',
		hotkey = {key='x', mod=''},
	},
	tab_advland = {
		name = "Adv Land Tab",
		desc = "Switches to adv land tab, enables grid hotkeys",
		type = 'button',
		hotkey = {key='c', mod=''},
	},
	tab_advsea = {
		name = "Adv Sea Tab",
		desc = "Switches to adv sea tab, enables grid hotkeys",
		type = 'button',
		hotkey = {key='v', mod=''},
	},
	tab_special = {
		name = "Special Tab",
		desc = "Switches to special tab, enables grid hotkeys",
		type = 'button',
		hotkey = {key='v', mod=''},
	},
	tab_units = {
		name = "Unit Tab",
		desc = "Switches to unit tab, enables grid hotkeys",
		type = 'button',
		hotkey = {key='v', mod=''},
	},
}


------------------------
--speedups
local spGetUnitDefID  = Spring.GetUnitDefID
local spGetUnitHealth = Spring.GetUnitHealth
local spGetFullBuildQueue = Spring.GetFullBuildQueue
local spGetUnitIsBuilding = Spring.GetUnitIsBuilding

-- local push = table.insert

local CMD_PAGES = 60

local common_commands, states_commands, land_commands, sea_commands, advland_commands, advsea_commands, special_commands, globalCommands, overrides, custom_cmd_actions = include("Configs/border_menu_commands.lua")

-- debug
	local function unpack (t, i)
		if type(t) == 'table' then
			local result = ''
			i = i or ''
			for k,v in pairs(t) do
				result = result..i..'\t'..k..': '..unpack(v,i..'\t')..'\n'
			end
			if result then
				return '\n'..i..'{\n'..result..i..'}'
			else return '{}' end
		elseif type(t) == 'string' then
			return t:gsub('\n', '\n'..i..'\t')
		else
			return tostring(t)
		end
	end
--[[
	Spring.Echo(
		'\ttables: '..unpack({
			land = land_commands,
			sea = sea_commands,
			advL = advland_commands,
			advS = advsea_commands,
			spec = special_commands,
		})
	)
]]-- end

local function CapCase(str)
	local str = str:lower()
	str = str:gsub( '_', ' ' )
	str = str:sub(1,1):upper() .. str:sub(2)

	str = str:gsub( ' (.)',
		function(x) return (' ' .. x):upper() end
		)
	return str
end

local function AddHotkeyOptions()
	local options_order_tmp_cmd = {}
	local options_order_tmp_states = {}
	for cmdname, number in pairs(custom_cmd_actions) do

		local cmdnamel = cmdname:lower()
		local cmdname_disp = CapCase(cmdname)
		options[cmdnamel] = {
			name = cmdname_disp,
			type = 'button',
			action = cmdnamel,
			path = 'Game/Commands',
		}
		if number == 2 then
			options_order_tmp_states[#options_order_tmp_states+1] = cmdnamel
		else
			options_order_tmp_cmd[#options_order_tmp_cmd+1] = cmdnamel
		end
	end

	options.lblcmd = { type='label', name='Instant Commands', path = 'Game/Commands',}
	options['lblstate'] = { type='label', name='State Commands', path = 'Game/Commands',}


	table.sort(options_order_tmp_cmd)
	table.sort(options_order_tmp_states)

	options_order[#options_order+1] = 'lblcmd'
	for i=1, #options_order_tmp_cmd do
		options_order[#options_order+1] = options_order_tmp_cmd[i]
	end

	options_order[#options_order+1] = 'lblstate'
	for i=1, #options_order_tmp_states do
		options_order[#options_order+1] = options_order_tmp_states[i]
	end
end

AddHotkeyOptions()


local MAX_COMMAND_COLUMNS = 10
local MAX_STATE_ROWS = 4
local MAX_VISIBLE_BUILDQUEUE_LENGTH = 18-- buildoptions will have the same length, but will be scrollable in the beta.

local MIN_WIDTH = 600
local MIN_HEIGHT = 120

local COMMAND_SECTION_WIDTH = 30 -- percent
local BUILD_SECTION_WIDTH = 60 -- percent
local STATE_SECTION_WIDTH = 10 -- percent

local NUM_STATE_COMUMNS = 3

-- local forceUpdateFrequency = 0.2 -- seconds

local selectedBuilder -- unitID
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

-- Widget position
local invert -- invert horizontal rows order
local rotate -- invert x/y, width/heigh, horizontal/vertical
local defaultHorizontal = "horizontal"
local defaultVertical = "vertical"

-- Chili instances
local screen0
local window		--main window (invisible)
local menuTabRow	--parent row of tabs
local menuTabs = {}	--buttons

local commands_main	--parent column of command buttons
local sp_commands = {}	--buttons
local build_main	--parent column of build buttons
local sp_build = {}	--buttons
local states_main	--parent row of state buttons
local sp_states = {}	--buttons

local buildRow		--row of build queue buttons
local buildRow_visible
local buildRowButtons = {} --contains arrays indexed by number 1 to MAX_COMMAND_COLUMNS, each of which contains three subobjects: button, label and image
local buildProgress	--Progressbar, child of buildRowButtons[1].image; updates every gameframe

local buildQueue = {}	--build order table of selectedBuilder
local buildQueueUnsorted = {}	--puts all units of same type into single index; thus no sequence

local gridLocation = {}

-- arrays with commands to be displayed
local n_common = {}
local n_land = {}
local n_sea = {}
local n_advland = {}
local n_advsea = {}
local n_special = {}
local n_units = {}
local n_states = {}

--shortcuts
local menuCommandsArray = n_common
local menuChoices = {
	[1] = { array = n_land, name = "Land", hotkeyName = "Land", config = land_commands, actionName = "epic_chili_border_menu_tab_land" },
	[2] = { array = n_sea, name = "Sea", hotkeyName = "Sea", config = sea_commands, actionName = "epic_chili_border_menu_tab_sea" },
	[3] = { array = n_advland, name = "AdvLand", hotkeyName = "AdvLand", config = advland_commands, actionName = "epic_chili_border_menu_tab_advland" },
	[4] = { array = n_advsea, name = "AdvSea", hotkeyName = "AdvSea", config = advsea_commands, actionName = "epic_chili_border_menu_tab_advsea" },
	[5] = { array = n_special, name = "Special", hotkeyName = "Special", config = special_commands, actionName = "epic_chili_border_menu_tab_special" },
	[6] = { array = n_units, name = "Units", hotkeyName = "Units", config = {}, actionName = "epic_chili_border_menu_tab_units" },
}

local menuChoice = 1
local lastBuildChoice = 2

-- command id indexed field of items - each item is button, label and image
local commandButtons = {}
----------------------------------- COMMAND COLORS  - from cmdcolors.txt - default coloring
local cmdColors = {}

-- default config
local config = {}


------------------------
--  FUNCTIONS
------------------------
-- this gets invoked when button is clicked
local function ClickFunc(button)
	local _,_,left,_,right = Spring.GetMouseState()
	local alt,ctrl,meta,shift = Spring.GetModKeyState()
	local index = Spring.GetCmdDescIndex(button.cmdid)
	if (left) then
		Spring.SetActiveCommand(index,1,left,right,alt,ctrl,meta,shift)
	end
	if (right) then
		Spring.SetActiveCommand(index,3,left,right,alt,ctrl,meta,shift)
	end
end

------------------------
--  Generates or updates chili button - either image or text or both based - container is parent of button, cmd is command desc structure
------------------------
local function MakeButton(container, cmd, index, insertItem)
	local isState = (cmd.type == CMDTYPE.ICON_MODE and #cmd.params > 1) or states_commands[cmd.id]	--is command a state toggle command?
	local isBuild = (cmd.id < 0)

	local override = overrides[cmd.id]  -- command overrides
	local gridHotkeyed = not isState and menuChoice < #menuChoices


	-- texture
	local texture
	if override and override.texture then
		if (isState) then
			texture = override.texture[cmd.params[1]+1]
		else
			texture = override.texture
		end
	elseif isBuild then
		texture = '#'..-cmd.id
	else
		texture = cmd.texture
	end

	-- hotkey
	local hotkey = cmd.action and WG.crude.GetHotkey(cmd.action) or ''
	if gridHotkeyed and hotkeyMode then
		hotkey = gridMap[container.index][index] or ''
	elseif (options.tab_units_hotkeys.value and menuChoice == #menuChoices and selectedBuilder and container.i_am_sp_build) then
		if options.tab_units_hotkeys_requiremeta.value then
			local alt,ctrl,meta,shift = Spring.GetModKeyState()
			if meta or (alt and options.tab_units_hotkeys_altaswell.value) then
				hotkey = gridMap[container.index][index] or ''
			end
		else
			hotkey = gridMap[container.index][index] or ''
		end
	end

	-- caption
	local caption
	if not isState and hotkey ~= '' then
		caption = '\255\0\255\0' .. hotkey
	elseif override and override.caption then
		caption = override.caption
	elseif isState then
		caption = cmd.params[cmd.params[1]+2] or ''
	elseif isBuild then
		caption = ''
	else
		caption = cmd.name
	end

	-- tooltip
	local tooltip = cmd.tooltip
	if override and override.tooltip then
		tooltip = override.tooltip
	else
		tooltip = cmd.tooltip
	end
	if isBuild and selectedBuilder then
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
		if override ~= nil and override.color ~= nil then
			color = override.color
		elseif cmd.name ~= nil then
			local nl = cmd.name:lower()
			if cmdColors[nl] then
				color = cmdColors[nl]
				color[4] = color[4] + 0.2
			end
		end]]

		local button = Button:New {
			parent=container,
			padding = {5, 5, 5, 5},
			margin = {0, 0, 0, 0},
			caption = "",
			isDisabled = cmd.disabled,
			tooltip = tooltip,
			cmdid = cmd.id,
			OnMouseDown = {ClickFunc} --activate the clicked command
		}
		if cmd.OnClick then
			button.OnMouseDown = cmd.OnClick
		end
		button.padding = {1,1,1,1}
--		if (isState) then
			-- button.backgroundColor = {0,0,0,0}
--		end

		local image
		if (texture and texture ~= "") then
			image= Image:New{
				parent = button,
				x = 2,
				y = isState and 0 or 12,
				right = 2,
				bottom=2,
				-- color = color,
				keepAspect = not isBuild,-- true,-- isState,
				file = texture,
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
		local label
		if (not cmd.onlyTexture and caption and caption ~= '') then
			label = Label:New {
				parent = button,
				x = 2,
				y = 1,
				right = 2,
				bottom = 2,
				autosize=false,
				align = "left",
				valign = "top",
				caption = caption,
				fontSize = 11,
				fontShadow = true,
			}
		end

		local countLabel
		if isBuild then
			if buildQueueUnsorted[-cmd.id] then
				caption = tostring(buildQueueUnsorted[-cmd.id])
			end
			countLabel = Label:New {
				parent = image,
				autosize = false,
				width = "100%",
				height = "100%",
				align = "right",
				valign = "bottom",
				caption = caption,
				fontSize = 16,
				fontShadow = true,
			}
			local costLabel = Label:New {
				parent = button,
				autosize = false,
				x = 2,
				y = 1,
				right = 2,
				height = 12,
				align = "right",
				valign = "top",
				caption = UnitDefs[-cmd.id].metalCost..'m',
				fontSize = 11,
				fontShadow = true,
			}
		end


		--if button is disabled, set effect accordingly
		if button.isDisabled then
			button.backgroundColor = {0,0,0,1}
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
			item.button.backgroundColor = {0,0,0,1}
			item.image.color = {0.3, 0.3, 0.3, 1}
		else
			item.button.backgroundColor = {1,1,1,0.7}
			item.image.color = {1, 1, 1, 1}
		end
		item.button:Invalidate()
		item.image:Invalidate()
		item.button.isDisabled = cmd.disabled
	end

	if (not cmd.onlyTexture and item.label and caption ~= item.label.caption) then
		item.label:SetCaption(caption)
	end

	if (item.countLabel and caption ~= item.countLabel.caption) then
		item.countLabel:SetCaption(caption)
	end

	if (item.image and (texture ~= item.image.file or isState) ) then
		item.image.file = texture
		item.image:Invalidate()
	end

	if (item.button.tooltip and tooltip ~= item.button.tooltip) then
		item.button.tooltip = tooltip
	end
end

local function RemoveChildren(container)
	for i = 1, #container.children do
		container:RemoveChild(container.children[1])
	end
end

-- compared real chili container with new commands and update accordingly
local function UpdateContainer(container, n_list, columns)
	local cnt = 0
	local needFullUpdate = false
	local dif = {}
	for i =1, #container.children do
		if container.children[i].isEmpty then
			--break --NOTE: removed - test it
		else
			cnt = cnt + 1
			dif[container.children[i].cmdid] = true
		end
	end

	if cnt ~= #n_list then
		needFullUpdate = true
	else  -- check if some items are different
		for i=1, #n_list do
			dif[n_list[i].id] = nil
		end

		for _, _ in pairs(dif) do
			-- if one or more entries not set to nil
			needFullUpdate = true
			break
		end
	end

	if needFullUpdate then
		RemoveChildren(container)
		for i=1, #n_list do
			MakeButton(container, n_list[i], i, true) -- insert:true
		end
		for i = 1, columns - #container.children do
			Control:New {
				isEmpty = true,
				parent = container
			}
		end
	else
		for i=1, #n_list do
			MakeButton(container, n_list[i], i, false)
		end
	end
end

local function BuildRowButtonFunc(num, buildQueue, cmdid, left, right)
	local alt,ctrl,meta,shift = Spring.GetModKeyState()

	local amount = 1 --number of times to send the order
	-- it's not using the options, even though it's receiving them correctly -- so we have to do it manually
	amount = shift and amount*5 or 0
	amount = crtl and amount*20 or 0

	-- META = 4, RIGHT = 16, SHIFT = 32, CTRL = 64, ALT = 128
	--local options = (shift and CMD.OPT_SHIFT or 0) + (alt and CMD.OPT_ALT or 0) + (crtl and CMD.OPT_CTRL or 0) + (meta and CMD.OPT_META or 0) + (right and CMD.OPT_RIGHT or 0)

	-- insertion position is by unit rather than batch, so we need to add up all the units in front of us to get the queue
	-- if you have num=3 and 20*unit1, 10*unit2, pos will be 31
	local pos = 0
	for i=1,num-1 do
		for _,units in pairs(buildQueue[i]) do
			pos = pos + units
		end
	end

	-- skip over the commands with an id of 0, left behind by removal
	-- local commands = Spring.GetFactoryCommands(selectedBuilder)
	local commands = Spring.GetUnitCommands(selectedBuilder)
	for i = 1, pos do
		if commands[i].id == 0 then
			pos = pos + 1
		end
	end

	if not right then
		for i = 1, amount do
			Spring.GiveOrderToUnit(selectedBuilder, CMD.INSERT, {pos, cmdid, 0 }, {"alt", "ctrl"})
		end
	else
		-- TODO: investigate this hacky stuff here
		-- delete from back so that the order is not canceled while under construction
		local i = 0
		while commands[i+pos] and commands[i+pos].id == cmdid and not alreadyRemovedTag[commands[i+pos].tag] do
			i = i + 1
		end
		i = i -1
		j = 0
		while commands[i+pos] and commands[i+pos].id == cmdid and j < amount do
			Spring.GiveOrderToUnit(selectedBuilder, CMD.REMOVE, {commands[i+pos].tag}, {"ctrl"})
			alreadyRemovedTag[commands[i+pos].tag] = true
			j = j + 1
			i = i - 1
		end
	end
end

--these two functions place the items into their rows
local function ManageStateIcons()
	local stateCols = {}
	for i = 1, NUM_STATE_COMUMNS do
		local stateCol = {}
		local inOtherCols = (i-1) * MAX_STATE_ROWS
		for v = 1, MAX_STATE_ROWS do
			stateCol[v] = n_states[inOtherCols+v]
		end
		stateCols[i] = stateCol
	end
	for i=1, #stateCols do
		UpdateContainer(sp_states[i], stateCols[i], MAX_STATE_ROWS)
	end
end

local function ManageCommandIcons()

	--update factory data
	if selectedBuilder then
		-- updates buildQueue / buildQueueUnsorted every time Tab[Units] get selected
		buildQueue = spGetFullBuildQueue(selectedBuilder)
		buildQueueUnsorted = {}
		for i=1, #buildQueue do
			for udid, count in pairs(buildQueue[i]) do
				buildQueueUnsorted[udid] = (buildQueueUnsorted[udid] or 0) + count
			end
		end
	end

-- NOTE: some menu choice will contain terra
	UpdateContainer(sp_build, menuChoices[menuChoice].array or {}, MAX_VISIBLE_BUILDQUEUE_LENGTH)

	for i = 1, 2 do
		local commandRow = {}
		local inOtherRows = (i-1)*MAX_COMMAND_COLUMNS
		for v = 1, MAX_COMMAND_COLUMNS do
			commandRow[v] = menuCommandsArray[inOtherRows+v]
		end
-- NOTE: some menu choice will contain terra
		UpdateContainer(sp_commands[i], commandRow, MAX_COMMAND_COLUMNS)
	end

	local overflow = false
	RemoveChildren(buildRow)-- clear the build row
	if buildQueue[#buildRowButtons + 1] then
		overflow = true
	end

	for i=1, #buildRowButtons do
		local buttonArray = buildRowButtons[i]
		if buttonArray.button then RemoveChildren(buttonArray.button) end

		if buildQueue[i] then	--adds button for queued unit
			local udid, count, caption
			for id, num in pairs(buildQueue[i]) do
				udid = id
				count = num
				break
			end
			buttonArray.cmdid = -udid

			local width = 100 / #buildRowButtons -- percent
			buttonArray.button = Button:New{
				parent = buildRow,
				x = rotate and  0  or  (i-1)*width.."%",
				y = rotate and  (i-1)*width.."%"  or  0,
				width = rotate and  "100%"  or  width.."%",
				height = rotate and  width.."%"  or  "100%",
				--caption = '',
				OnMouseDown = {function ()
					local _,_,left,_,right = Spring.GetMouseState()
					BuildRowButtonFunc( i, buildQueue, buttonArray.cmdid, left, right )
					end},
				padding = {1,1,1,1},
				--keepAspect = true,
			}

			if overflow and i == #buildRowButtons then
				buttonArray.button.caption = tostring(#buildQueue - #buildRowButtons + 1)..' more'
				buttonArray.button.OnMouseDown = nil
			else
				if count > 1 then
					caption = tostring(count)
				else
					caption = ''
				end
				buttonArray.button.tooltip = 'Add to/subtract from queued batch'
				buttonArray.image = Image:New{
					parent = buttonArray.button,
					x = 2,
					y = 2, -- invert and "50%" or 2,
					right = 2,
					bottom = 2, -- invert and 2 or "50%",
					file = '#'..udid,
					file2 = WG.GetBuildIconFrame(UnitDefs[udid]),
					keepAspect = false,
				}
				buttonArray.label = Label:New{
					parent = buttonArray.image,
					autosize=false,
					x = "0%",
					y = "0%",
					width = "100%",
					height = "100%",
					align = "right",
					valign = "bottom",
					caption = caption or '',
					fontSize = 16,
					fontShadow = true,
				}
			end

			if i == 1 then
				buttonArray.image:AddChild(buildProgress)
			end
			buttonArray.button.backgroundColor[4] = 0.3
		end
	end
end

local function Update()
	local commands = widgetHandler.commands
	local customCommands = widgetHandler.customCommands
	--most commands don't use row sorting; econ, defense and special do

	-- TODO: investigate if option-buttons work or if the command buttons should be force-fixed to meta+button.
-- 	if menuChoice == 1 then-- commands
-- 		hotkeyMode = false
-- 	end

	--if (#commands + #customCommands == 0) then
		---screen0:RemoveChild(window)
		--window_visible = false
	--	return
	--else
		--if not window_visible then
			--screen0:AddChild(window)
			--window_visible = true
		--end
	--end

	n_common = {}
	n_land = {}
	n_sea = {}
	n_advland = {}
	n_advsea = {}
	n_special = {}
	n_units = {}
	n_states = {}

	--sorts commands into categories
	local function ProcessCommand(cmd)
		if not cmd.hidden and cmd.id ~= CMD_PAGES then
			-- state icons
			if (cmd.type == CMDTYPE.ICON_MODE and cmd.params ~= nil and #cmd.params > 1) then
				n_states[#n_states+1] = cmd
			elseif common_commands[cmd.id] then
				n_common[#n_common+1] = cmd
			elseif sea_commands[cmd.id] then
				n_sea[#n_sea+1] = cmd
			elseif land_commands[cmd.id] then
				n_land[#n_land+1] = cmd
			elseif advsea_commands[cmd.id] then
				n_advsea[#n_advsea+1] = cmd
			elseif advland_commands[cmd.id] then
				n_advland[#n_advland+1] = cmd
			elseif special_commands[cmd.id] then
				n_special[#n_special+1] = cmd
			elseif UnitDefs[-(cmd.id)] then
				n_units[#n_units+1] = cmd
			else
				n_common[#n_common+1] = cmd	--shove unclassified stuff in common
			end
		end
	end
	for i = 1, #commands do ProcessCommand(commands[i]) end
	for i = 1, #customCommands do ProcessCommand(customCommands[i]) end
	for i = 1, #globalCommands do ProcessCommand(globalCommands[i]) end
	--[[ NOTE: these should fill n_XXX with something like:
		{
		type: 20
		action: buildunit_factorygunship
		id: -204
		tooltip: Build: Gunship Plant - Produces Gunships, Builds at 10 m/s
			Health 4000
			Metal cost 600
			Energy cost 600 Build time 600
		cursor: factorygunship
		showUnique: false
		name: factorygunship
		params: {}
		hidden: false
		disabled: false
		onlyTexture: false
		texture:
		}
	]]--

	menuCommandsArray = n_common
	menuChoices[1].array = n_land
	menuChoices[2].array = n_sea
	menuChoices[3].array = n_advland
	menuChoices[4].array = n_advsea
	menuChoices[5].array = n_special
	menuChoices[6].array = n_units

-- 	local function Sort(a, b, array)
-- 		return array[a.id] < array[b.id]
-- 	end

	table.sort(n_land, function(a,b) return land_commands[a.id].order < land_commands[b.id].order end )
	table.sort(n_sea, function(a,b) return sea_commands[a.id].order < sea_commands[b.id].order end)
	table.sort(n_advland, function(a,b) return advland_commands[a.id].order < advland_commands[b.id].order end)
	table.sort(n_advsea, function(a,b) return advsea_commands[a.id].order < advsea_commands[b.id].order end)
	table.sort(n_special, function(a,b) return special_commands[a.id].order < special_commands[b.id].order end)

	ManageStateIcons()
	ManageCommandIcons()
end

local function MakeMenuTab(i, alpha)
	local width = 1/ #menuChoices *100
	local button = Button:New{
		parent = menuTabRow,
		x = rotate and 0 or (width *(i-1)).."%",
		y = rotate and (width *(i-1)).."%" or 0,
		width = rotate and "100%" or width.."%",
		height = rotate and width.."%" or "100%",
--		font = {
--			shadow = true
--		},

		caption = hotkeyMode and menuChoices[i].name or menuChoices[i].hotkeyName,
		OnClick = {
			function()
				if i < #menuChoices then lastBuildChoice = i end
				SelectTab(i, true) -- Update with true
			end
		},
	}
	button.backgroundColor[4] = alpha or 1
	return button
end

--need to recreate the tabs completely because chili is dumb
--also needs to be non-local so MakeMenuTab can call it
function SelectTab(i, update)
	menuChoice = i
	if update then Update() end
	ColorTabs(i)
end
function ColorTabs(choice)
	choice = choice or menuChoice
	RemoveChildren(menuTabRow)
	for i=1,#menuChoices do
		if i ~= choice then menuTabs[i] = MakeMenuTab(i, 0.4) end
	end
	menuTabs[choice] = MakeMenuTab(choice, 1)
end

local function CopyTable(intable, outtable)
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
	widgetHandler.commands = commands
	widgetHandler.commands.n = cmdCount
	widgetHandler:CommandsChanged()
	local reParamsCmds = {}
	local customCmds = {}

	local cnt = 0

	local AddCommand = function(command)
		local cc = {}
		CopyTable(command, cc)
		cnt = cnt +1
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
		cc.pos   = nil
		cc.cmdDescID = nil
		cc.params = nil

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
	return "", xIcons, yIcons, {}, customCmds, {}, {}, {}, {}, reParamsCmds, {[1337]=9001}
end

local function ScrollTabRight()
	local menuChoice = menuChoice + 1
	if menuChoice > #menuChoices then menuChoice = 1 end
	if menuChoice < #menuChoices then lastBuildChoice = menuChoice end
	SelectTab( menuChoice, true )
end

local function ScrollTabLeft()
	local menuChoice = menuChoice - 1
	if menuChoice < 1 then menuChoice = #menuChoices end
	if menuChoice < #menuChoices then lastBuildChoice = menuChoice end
	SelectTab( menuChoice, true )
end

--------------------------------------
-- Hotkey Mode

function widget:KeyPress(key, modifier, isRepeat)
	if hotkeyMode and not isRepeat then
		hotkeyMode = false
		SelectTab( 1, true ) -- auto-return to orders to make it clear hotkey time is over
	end

	local alt,ctrl,meta,shift = Spring.GetModKeyState()
	if options.tab_units_hotkeys.value and (options.tab_units_hotkeys_requiremeta.value and (meta or (alt and options.tab_units_hotkeys_altaswell.value))) then
		local pos = gridKeyMap[key]
		if pos and sp_commands[pos[1]] and sp_commands[pos[1]].children[pos[2]] then
			local cmd = sp_commands[pos[1]].children[pos[2]]
			if cmd and cmd.cmdid and Spring.GetCmdDescIndex(cmd.cmdid) then
				if not ctrl and (meta or (alt and options.tab_units_hotkeys_altaswell.value) or not options.tab_units_hotkeys_requiremeta.value) then
					local opts = 0
					if alt then  opts = opts + CMD.OPT_ALT  end
					if shift then  opts = opts + CMD.OPT_SHIFT  end
					Spring.GiveOrderToUnit(selectedBuilder, cmd.cmdid, {0}, opts)
					if WG.sounds_gaveOrderToUnit then  WG.sounds_gaveOrderToUnit(selectedBuilder, true)   end
					--does not work with meta held
					-- Spring.SetActiveCommand(Spring.GetCmdDescIndex(cmd.cmdid),1,true,false,alt,false,false,shift)
					Update()
					return true
				end
			end
		end
	end
	return false
end

function widget:KeyRelease(key, modifier, isRepeat)
	local alt,ctrl,meta,shift = Spring.GetModKeyState()
	if options.tab_units_hotkeys.value and (options.tab_units_hotkeys_requiremeta.value and (meta or (alt and options.tab_units_hotkeys_altaswell.value))) then
		Update(true)
	end
end

	--Spring.Echo(CMD.OPT_META) = 4
	--Spring.Echo(CMD.OPT_RIGHT) = 16
	--Spring.Echo(CMD.OPT_SHIFT) = 32
	--Spring.Echo(CMD.OPT_CTRL) = 64
	--Spring.Echo(CMD.OPT_ALT) = 128

local function HotkeyTabLand()
	hotkeyMode = true
	SelectTab(1, true)
end
local function HotkeyTabSea()
	hotkeyMode = true
	SelectTab(2, true)
end
local function HotkeyTabAdvLand()
	hotkeyMode = true
	SelectTab(3, true)
end
local function HotkeyTabAdvSea()
	hotkeyMode = true
	SelectTab(4, true)
end
local function HotkeyTabSpecial()
	hotkeyMode = true
	SelectTab(5, true)
end

options.tab_land.OnChange = HotkeyTabLand
options.tab_sea.OnChange = HotkeyTabSea
options.tab_advland.OnChange = HotkeyTabAdvLand
options.tab_advsea.OnChange = HotkeyTabAdvSea
options.tab_special.OnChange = HotkeyTabSpecial

local function AddAction(cmd, func, data, types)
	return widgetHandler.actionHandler:AddAction(widget, cmd, func, data, types)
end
local function RemoveAction(cmd, types)
	return widgetHandler.actionHandler:RemoveAction(widget, cmd, types)
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
	f = io.open('cmdcolors.txt','r')
	if f then
		it = f:lines()
		isFile = true
	else
		f = VFS.LoadFile('cmdcolors.txt')
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

	--create main Chili elements
	--local screenWidth,screenHeight = Spring.GetWindowGeometry()
	--local height = tostring(math.floor(screenWidth/screenHeight*0.35*0.35*100)) .. "%"
	--local y = tostring(math.floor((1-screenWidth/screenHeight*0.35*0.35)*100)) .. "%"

	--Spring.Echo(height)
	--Spring.Echo(y)

	invert = options.invert.value or false -- TODO: if menu is docked on the top/right
	rotate = options.rotate.value or false -- TODO: if menu is docked placed left/right

	if invert then
		defaultHorizontal = "vertical"
		defaultVertical = "horizontal"
	end


	local x, y, width, height = 0,0,0,0

	if rotate then
		width = MIN_HEIGHT
		height = MIN_WIDTH
	else
		width = MIN_WIDTH
		height = MIN_HEIGHT
	end
	window = Window:New{
		parent = screen0,
		name = 'borderwindow',
		color = {0, 0, 0, 0},
		width = width,
		height = height,
		x = 0,
		bottom = 0,
		dockable = true,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		minWidth = width,
		minHeight = height,
		padding = {0, 0, 0, 0},
		--itemMargin = {0, 0, 0, 0},
		OnMouseDown={ function(self) --// click+ space on border-menu tab will open a Game-menu.
			local _,_, meta,_ = Spring.GetModKeyState()
			if not meta then return false end --allow button to continue its function
			WG.crude.OpenPath(options_path)
			WG.crude.ShowMenu() --make epic Chili menu appear.
			return false
		end },
	}
	-- window(s) users
		local window_alloc

		width = COMMAND_SECTION_WIDTH*0.97
		window_alloc = width
		if rotate then
			height = width
			width = 97
		else
			height = 97
		end
		commands_main = StackPanel:New{
			parent = window,
			resizeItems = true,
			orientation = defaultVertical,
			width = width.."%",
			height = height.."%",
			x = 0,
			y = 0,
			padding = {0, 0, 0, 0},
			itemMargin = {0, 0, 0, 0},
		}
		-- commands_main users
			for i=1,2 do
				y = ((invert and i-1 or 2-i)*50).."%"
				if rotate then
					x = y
					y = "0%"
					width = "50%"
					height = "100%"
				else
					x = "0%"
					width = "100%"
					height = "50%"
				end
				sp_commands[i] = StackPanel:New{
					parent = commands_main,
					resizeItems = true,
					orientation = defaultHorizontal,
					width = width,
					height = height,
					x = x,
					y = y,
					padding = {0, 0, 0, 0},
					itemMargin = {0, 0, 0, 0},
					index = i,
				}
			end
		-- end

		x = window_alloc +1.5
		width = BUILD_SECTION_WIDTH*0.97
		if rotate then
			y = x
			x = 1.5
			height = width
			width = 97
			window_alloc = y +height
		else
			y = 1.5
			height = 97
			window_alloc = x +width
		end
		build_main = StackPanel:New{
			parent = window,
			resizeItems = true,
			orientation = defaultVertical,
			height = height.."%",
			width = width.."%",
			x = x.."%",
			y = y.."%",
			padding = {0, 0, 0, 0},
			itemMargin = {0, 0, 0, 0},
		}
		-- build_main users

			y = invert and "85%" or "0%"
			height = "15%"
			if rotate then
				x = y
				y = 0
				width = height
				height = "100%"
			else
				x = 0
				width = "100%"
			end
			menuTabRow = StackPanel:New{
				parent = build_main,
				resizeItems = true,
				orientation = defaultHorizontal,
				height = height,
				width = width,
				x = x,
				y = y,
				padding = {0, 0, 0, 0},
				itemMargin = {0, 0, 0, 0},

				OnMouseDown={ function(self) --// click+ space on any button on the border-menu will open a Game-menu.
					local _,_, meta,_ = Spring.GetModKeyState()
					if not meta then return false end --allow button to continue its function
					WG.crude.OpenPath('Game/Commands')
					WG.crude.ShowMenu() --make epic Chili menu appear.
					return false
				end },
			}
			-- tabs in menuTabRow:
			for i=1, #menuChoices do
				menuTabs[i] = MakeMenuTab(i, 1)
			end
			ColorTabs()

			y = invert and "42.5%" or "15%"
			height = "42.5%"
			if rotate then
				x = y
				y = 0
				width = height
				height = "100%"
			else
				x = 0
				width = "100%"
			end
			sp_build = StackPanel:New{
				parent = build_main,
				resizeItems = true,
				orientation = defaultHorizontal,
				width = width,
				height = height,
				x = x,
				y = y,
				padding = {0, 0, 0, 0},
				itemMargin = {0, 0, 0, 0},
				index = i,
				i_am_sp_build = true,
			}

			-- same width/height as before
			if rotate then
				x = invert and 0 or "57.5%"
			else
				y = invert and 0 or "57.5%"
			end
			buildRow = StackPanel:New{
				parent = build_main,
				resizeItems = true,
				orientation = defaultHorizontal,
				height = height,
				width = width,
				x = x,
				y = y,
				padding = {0, 0, 0, 0},
				itemMargin = {0, 0, 0, 0},
				backgroundColor = {0.2, 0.2, 0.2, 0.6},
			}
			-- buildRow[1] users -- it will get attached to it later!
				buildProgress = Progressbar:New{
					value = 0.0,
					name = 'prog',
					max = 1,
					color = {0.7, 0.7, 0.4, 0.6},
					backgroundColor = {1, 1, 1, 0.01},
					width = "92%",
					height = "92%",
					x = "4%",
					y = "4%",
					skin=nil,
					skinName='default',
				}
			-- end
		-- end

		x = window_alloc +1.5
		width = STATE_SECTION_WIDTH*0.97
		if rotate then
			y = x
			x = 1.5
			height = width
			width = 97
		else
			y = 1.5
			height = 97
		end
		states_main = StackPanel:New{
			parent = window,
			resizeItems = true,
			orientation = defaultHorizontal,
			x = x.."%",
			y = y.."%",
			height = height.."%",
			width = width.."%",
			padding = {0, 0, 0, 0},
			itemMargin = {0, 0, 0, 0},
		}
		-- states_main users
			for i=1, NUM_STATE_COMUMNS do
				if rotate then
					width = "100"
					height = math.floor(100/NUM_STATE_COMUMNS)
					x = 0
					y = (100- width*i)
				else
					width = math.floor(100/NUM_STATE_COMUMNS)
					height = "100"
					x = (100- width*i)
					y = 0
				end
				sp_states[i] = StackPanel:New{
					parent = states_main,
					resizeItems = true,
					orientation = defaultVertical,
					x = x.."%",
					y = y.."%",
					width = width.."%",
					height = height.."%",
					padding = {0, 0, 0, 0},
					itemMargin = {0, 0, 0, 0},
					OnMouseDown={ function(self) --// click+ space on any unit-State button will open Unit-AI menu, it overrides similar function above.
						-- local forwardSlash = Spring.GetKeyState(0x02F) --reference: uikeys.txt
						-- if not forwardSlash then return false end
						local _,_, meta,_ = Spring.GetModKeyState()
						if not meta then return false end --allow button to continue its function
						WG.crude.OpenPath('Game/Unit AI')
						WG.crude.ShowMenu() --make epic Chili menu appear.
						return true --stop the button's function, else unit-state button will look bugged.
					end },
				}
			end
		-- end

	-- end

	for i=1,MAX_VISIBLE_BUILDQUEUE_LENGTH do
		buildRowButtons[i] = {}
	end
end

local lastCmd = nil  -- last active command
local lastColor = nil  -- original color of button with last active command

-- this is needed to highlight active command
function widget:DrawScreen()
	local _,cmdid,_,cmdname = Spring.GetActiveCommand()
	if cmdid ~= lastCmd then
		if cmdid and commandButtons[cmdid]  then
			local but = commandButtons[cmdid].button
			lastColor = but.backgroundColor
			but.backgroundColor = {0.8, 0, 0, 1}
			but:Invalidate()
		end
		if lastCmd ~= nil and commandButtons[lastCmd] then
			local but = commandButtons[lastCmd].button
			but.backgroundColor = lastColor
			but:Invalidate()
		end
		lastCmd = cmdid
	end
end

-- Make the hotkeys appear on the menu tabs
function widget:Update()
	if recentlyInitialized then
		for i = 1, #menuChoices do
			local choice=menuChoices[i]
			local hotkey = WG.crude.GetHotkey(choice.actionName)
			if hotkey ~= '' then
				choice.hotkeyName = choice.name ..  '(\255\0\255\0' .. hotkey .. '\008)'
				choice.name = choice.name ..  '(' .. hotkey .. ')'
			end
		end
		recentlyInitialized = false
		ColorTabs(1)
	end
end

function widget:GameFrame()
	--set progress bar
	if selectedBuilder and buildRowButtons[1] and buildRowButtons[1].image then
		local progress
		local unitBuildID  = spGetUnitIsBuilding(selectedBuilder)
		if unitBuildID then
			progress = select(5, spGetUnitHealth(unitBuildID))
		end
		buildProgress:SetValue(progress or 0)
	end
end

function widget:SelectionChanged(newSelection)
	--get new selected fac, if any
	local found = false
	for i=1,#newSelection do
		local id = newSelection[i]
		-- if UnitDefs[spGetUnitDefID(id)].isFactory then
		if UnitDefs[spGetUnitDefID(id)].builder then
			if selectedBuilder ~= id then
				alreadyRemovedTag = {}
			end
			selectedBuilder = id
			found = true
			break
		end
	end
	if not found then
		selectedBuilder = nil
		if buildRow_visible then
			build_main:RemoveChild(buildRow)
			buildRow_visible = false
		end
	elseif not buildRow_visible then
		build_main:AddChild(buildRow)
		buildRow_visible = true
	end
	Update()
	if options.hidetabs.value then
		SelectTab( 1 )
	elseif options.disablesmartselect.value then
		return
	elseif #n_units > 0 and #n_special == 0 then
		SelectTab( #menuChoices ) --selected factory, jump to units
	elseif #n_land > 0 and menuChoice == #menuChoices then
		SelectTab( lastBuildChoice ) --selected non-fac and in units menu, jump to last build menu
	end
end

function widget:Shutdown()
  widgetHandler:ConfigLayoutHandler(nil)
  Spring.ForceLayoutUpdate()
end

function options.invert:OnChange()
	invert = self.value -- TODO: if menu is docked on the top/right
	if invert then
		defaultHorizontal = "vertical"
		defaultVertical = "horizontal"
	else
		defaultHorizontal = "horizontal"
		defaultVertical = "vertical"
	end
	SelectTab(1);
end
function options.rotate:OnChange()
	rotate = self.value -- TODO: if menu is docked placed left/right
	SelectTab(1)
end

function options.hidetabs:OnChange()
	-- NOTE: fakewindow:SetPosRelative was called twice in a row with the same parameters.
	local offset = self.value and (invert and "50%" or "0%") or (invert and "42.5%" or "15%")
	if rotate then
		sp_build:SetPosRelative(offset, _, "50%", "100%")
	else
		sp_build:SetPosRelative(_, offset, "100%", "50%")
	end
	offset = invert and "0%" or self.value and "50%" or "57.5%"
	if rotate then
		buildRow:SetPosRelative(offset, _, "50%", "100%")
	else
		buildRow:SetPosRelative(_, offset, "100%", "50%")
	end

	if self.value then
		build_main:RemoveChild(menuTabRow)
	else
		build_main:AddChild(menuTabRow)
	end
	SelectTab(1)
end