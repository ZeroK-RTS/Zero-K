-- TODO: make EPIC save changed options somehow!
-- TODO: state switches need icons 
-- TODO: commandschanged gets called 2x for some reason, investigate

function widget:GetInfo()
  return {
    name      = "Chili Integral Menu ",
    desc      = "v0.1 Integral Command Menu",
    author    = "Licho, KingRaptor",
    date      = "6.9.2010",
    license   = "GNU GPL, v2 or later",
    layer     = 50,
    enabled   = false,
	handler   = true,
  }
end

--[[
HOW IT WORKS:
	Two parent StackPanels, a column for normal commands and a row for state commands.
	Three (currently this is a hardcoded figure) more StackPanels are nested in each of the parents, at right angles.
	When sorting commands, it splits state commands into batches of (MAX_COLUMNS) and assigns them to children
		so if there are 12 commands, it puts 10 in first row and 2 in second row
	Ditto for states, except it uses MAX_STATE_ROWS
	Both parents and children resize with main window.
--]]

local CMD_PAGES = 60

local common_commands, states_commands, factory_commands, econaux_commands, defense_commands, overrides = include("Configs/integral_menu_commands.lua")

local MAX_COLUMNS = 10
local MAX_STATE_ROWS = 5
local MIN_HEIGHT = 180
local MIN_WIDTH = 400

-- Global commands defined here - they have cmdDesc format + 
local globalCommands = {
--[[	{
		name = "crap",
		texture= 'LuaUi/Images/move_hold.png',
		id = math.huge,
		OnClick = {function() 
			Spring.SendMessage("crap")
		end }
	}
	{
		id      = CMD_RETREAT_ZONE
		type    = CMDTYPE.ICON_MAP,
		tooltip = 'Place a retreat zone. Units will retreat there. Constructors placed in it will repair units.',
		cursor  = 'Repair',
		action  = 'sethaven',
		params  = { }, 
		texture = 'LuaUI/Images/ambulance.png',
	}]]--
}

-- Chili classes
local Chili
local Button
local Label
local Colorbars
local Checkbox
local Window
local ScrollPanel
local StackPanel
local LayoutPanel
local Grid
local Trackbar
local TextBox
local Image
local Progressbar
local Control

-- Chili instances
local screen0
local window
local sp_commands = {}
local sp_states = {}

local btn_special
local btn_common
local btn_build
local menuButtons = {}

local window_visible = true

-- command id indexed field of items - each item is button, label and image 
local commandButtons = {} 
----------------------------------- COMMAND COLORS  - from cmdcolors.txt - default coloring
local cmdColors = {}

-- default config
local config = {

}


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
-----------------------
local function MakeButton(container, cmd, insertItem) 
	local isState = (cmd.type == CMDTYPE.ICON_MODE and #cmd.params > 1) or states_commands[cmd.id]	--is command a state toggle command?
	local isBuild = (cmd.id < 0)
	local text
	local texture
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
	
	--texture 
	if te ~= nil and te.texture then 
		if (isState) then 
			texture = te.texture[cmd.params[1]+1]
		else 
			texture = te.texture
		end 
	elseif isBuild then
		texture = '#' .. -cmd.id		
	else
		texture = cmd.texture 
	end 
	
	-- tooltip 
	if te and te.tooltip then 
		tooltip = te.tooltip
	else 
		tooltip = cmd.tooltip
	end
	
	-- get cached menu item 
	local item = commandButtons[cmd.id]
	if not item then  -- no item, create one 
		if not insertItem then 
			Spring.SendMessage("CommandBar - internal error, unexpectedly adding item!")
		end 
		-- decide color 
		local color = {1,1,1,1}
		if te ~= nil and te.color ~= nil then 
			color = te.color 
		elseif cmd.name ~= nil then 
			local nl = cmd.name:lower()
			if cmdColors[nl] then 
				color = cmdColors[nl]
				color[4] = color[4] + 0.2
			end 
		end

		
		local button = Button:New {
			parent=container;
			padding = {5, 5, 5, 5},
			margin = {0, 0, 0, 0},
			caption="";
			isDisabled = cmd.disabled;
			tooltip = tooltip;
			cmdid = cmd.id;
			OnMouseDown = {ClickFunc}
		}
		if cmd.OnClick then 
			button.OnMouseDown = cmd.OnClick
		end 
		
		if (isState) then 
			button.padding = {0,0,0,0}
			--button.backgroundColor = {0,0,0,0}
			--button.height = '20%'
			--button.width = button.height
		end 
		if (isBuild) then
			button.padding = {0,0,0,0}
			--button.margin = {0,0,0,0}
		end
		
		local label 
		if (not cmd.onlyTexture and text and text ~= '') then 
			label = Label:New {
				width="100%";
				height="100%";
				autosize=false;
				align="center";
				valign="top";
				caption = text;
				fontSize = 11;
				fontShadow = true;
				parent = button;
			}
		end 
		
		local image
		if (texture and texture ~= "") then
			image= Image:New {
				width="100%";
				height="90%";
				y="8%";
				color = color;
				keepAspect = isState;
				file = texture;
				parent = button;
			}
			if isBuild then image.file2 = WG.GetBuildIconFrame(UnitDefs[-cmd.id]) end
		else 
			if label~=nil then label.valign="center" end
		end 
		item = {
			button = button,
			image = image,
			label = label 
		}
		commandButtons[cmd.id] = item
	else 
		if insertItem then 
			container:AddChild(item.button)
		end 
	end 
	
	-- update item if something changed
	if (cmd.disabled ~= item.button.isDisabled) then 
		if cmd.isDisabled then 
			item.button.backgroundColor = {0,0,0,1};
			if item.image then item.image.color[4] = 0.3 end
		else 
			item.button.backgroundColor = {1,1,1,0.7};
			if item.image then item.image.color[4] = 1 end 
		end 
		item.button:Invalidate()
		item.button.isDisabled = cmd.disabled
	end 
	
	
	if (not cmd.onlyTexture and item.label and text ~= item.label.caption) then 
		item.label:SetCaption(text)
	end 
	
	if (item.image and texture ~= item.image.file) then 
		item.image.file = texture
		item.image:Invalidate()
	end 
end 

-- arrays with commands to be displayed 
local n_common = {}
local n_factories = {}
local n_econaux = {}
local n_defense = {}
local n_units = {}
local n_states = {}

local menuChoices = {
	[1] = { array = n_common, name = "General" },
	[2] = { array = n_factories, name = "Factories" },
	[3] = { array = n_econaux, name = "Econ/Aux" },
	[4] = { array = n_defense, name = "Defense" },
	[5] = { array = n_units, name = "Units" },
}
local menuChoice = 1

local function ProcessCommand(cmd) 
	if not cmd.hidden and cmd.id ~= CMD_PAGES then 
		--- state icons 
		if (cmd.type == CMDTYPE.ICON_MODE and cmd.params ~= nil and #cmd.params > 1) then 
			--if states_commands[cmd.id] then 
				--if btn_states.level >= states_commands[cmd.id] then 
					n_states[#n_states+1] = cmd 
				--end 
			--elseif btn_states.level >= 1 then 
				--n_states[#n_states+1] = cmd
			--end 
		--this stuff is broken
		elseif common_commands[cmd.id] then 
			--if btn_common.level >= common_commands[cmd.id] then 
				n_common[#n_common+1] = cmd
			--end 
		elseif factory_commands[cmd.id] then
			n_factories[#n_factories+1] = cmd
		elseif econaux_commands[cmd.id] then
			n_econaux[#n_econaux+1] = cmd
		elseif defense_commands[cmd.id] then
			n_defense[#n_defense+1] = cmd
		elseif UnitDefs[-(cmd.id)] then
			n_units[#n_units+1] = cmd
		else
			n_common[#n_common+1] = cmd
			--n_common[#n_common+1] = cmd		--shove unclassified stuff in common
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
		for _, cmd in ipairs(nl) do  
			dif[cmd.id] = nil
		end 
	
		for _, _ in pairs(dif) do  -- different item found, we do full update 
			needUpdate = true 
			break
		end 
	end 
	
	
	if needUpdate then 
		RemoveChildren(container) 
		for _, cmd in ipairs(nl) do 
			MakeButton(container, cmd, true)
		end 
		for i = 1, columns - #container.children do 
			Control:New {
				isEmpty = true,
				parent = container
			}
		end 
	else 
		for _, cmd in ipairs(nl) do  -- update buttons only 
			MakeButton(container, cmd, false)
		end 
	end 
end 

--these two functions place the items into their rows
local function ManageStateIcons()
	local stateCols = { {}, {}, {} }
	for i=1, MAX_STATE_ROWS do
		stateCols[1][i] = n_states[i]
	end
	for i=MAX_STATE_ROWS+1, MAX_STATE_ROWS*2 do
		stateCols[2][i-MAX_STATE_ROWS] = n_states[i]
	end	
	for i=(2*MAX_STATE_ROWS)+1, MAX_STATE_ROWS*3 do
		stateCols[3][i-(2*MAX_STATE_ROWS)] = n_states[i]
	end
	for i=1, 3 do
		UpdateContainer(sp_states[i], stateCols[i], MAX_STATE_ROWS)
	end
end

local function ManageCommandIcons(sourceArray)
	local commandRows = { {}, {}, {} }
	for i=1, MAX_COLUMNS do
		commandRows[1][i] = sourceArray[i]
	end
	for i=MAX_COLUMNS+1, MAX_COLUMNS*2 do
		commandRows[2][i-MAX_COLUMNS] = sourceArray[i]
	end	
	for i=(2*MAX_COLUMNS)+1, MAX_COLUMNS*3 do
		commandRows[3][i-(2*MAX_COLUMNS)] = sourceArray[i]
	end
	for i=1, 3 do
		UpdateContainer(sp_commands[i], commandRows[i], MAX_COLUMNS)
	end
end

local function Update() 
    local commands = widgetHandler.commands
    local customCommands = widgetHandler.customCommands
	
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
	n_econaux = {}
	n_defense = {}
	n_units = {}
	n_states = {}
	
	--Spring.Echo(#commands)
	for i = 1, #commands do ProcessCommand(commands[i]) end 
	for i = 1, #customCommands do ProcessCommand(customCommands[i]) end 
	for i = 1, #globalCommands do ProcessCommand(globalCommands[i]) end 
	--for i,v in pairs(buildOptions) do ProcessCommand(i) end 

	menuChoices[1].array = n_common
	menuChoices[2].array = n_factories
	menuChoices[3].array = n_econaux
	menuChoices[4].array = n_defense
	menuChoices[5].array = n_units

	--[[
	local function Sort(a, b, array)
		return array[a.id] < array[b.id]
	end
	
	table.sort(n_factories, Sort(a,b, factory_commands))
	table.sort(n_econaux, Sort(a,b, econaux_commands))
	table.sort(n_defense, Sort(a,b, defense_commands))
	]]--
	table.sort(n_factories, function(a,b) return factory_commands[a.id] < factory_commands[b.id] end )
	table.sort(n_econaux, function(a,b) return econaux_commands[a.id] < econaux_commands[b.id] end)
	table.sort(n_defense, function(a,b) return defense_commands[a.id] < defense_commands[b.id] end)

	ManageStateIcons()
	ManageCommandIcons(menuChoices[menuChoice].array)
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
	return "", xIcons, yIcons, {}, customCmds, {}, {}, {}, {}, reParamsCmds, {[1337]=9001}
end 

-- INITS 
function widget:Initialize()
	widgetHandler:ConfigLayoutHandler(LayoutHandler)
	Spring.ForceLayoutUpdate()


	local f,it,isFile = nil,nil,false
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
	end
	
	-- setup Chili
	Chili = WG.Chili
	Button = Chili.Button
	Label = Chili.Label
	Colorbars = Chili.Colorbars
	Checkbox = Chili.Checkbox
	Window = Chili.Window
	ScrollPanel = Chili.ScrollPanel
	StackPanel = Chili.StackPanel
	LayoutPanel = Chili.LayoutPanel
	Grid = Chili.Grid
	Trackbar = Chili.Trackbar
	TextBox = Chili.TextBox
	Image = Chili.Image
	Progressbar = Chili.Progressbar
	Control = Chili.Control
	screen0 = Chili.Screen0
	
	local viewWidth,viewHeight = Spring.GetWindowGeometry()
	local width = (viewWidth-480)
	--local height = (viewHeight)
	--if height > 300 then
	--	height = 300
	--end
	
	
	window = Window:New{
		name   = 'integralwindow';
		--padding = {0, 0, 0, 0},
		--color = {0, 0, 0, 1},
		width = "54%";
		height = "25%";
		--temporary position fudges so it looks right on my screen w/o docking
		x = '23%';
		y = '76%';
		dockable = true;
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		minimumSize = {MIN_WIDTH, MIN_HEIGHT},
		parent = screen0,
		anchors = {bottom=true},
	}

	buttonRow = StackPanel:New{
		parent = window,
		resizeItems = true;
		orientation   = "horizontal";
		height = "15%";
		width = "80%";
		x = "0%";
		y = "0%";
		padding = {0, 0, 0, 0},
		itemMargin  = {0, 0, 0, 0},
	}
	
	for i=1,5 do
		menuButtons[i] = Button:New{
			parent = buttonRow;
			x = tostring((20*i)-20).."%",
			y = 0,
			width = "20%",
			height = "100%",
			caption = menuChoices[i].name,
			anchors = {top=true},
			OnClick = {
				function()
					menuChoice = i
					Update()
				end
			},
		}
	end
	
	commands_main = StackPanel:New{
		parent = window,
		resizeItems = true;
		orientation   = "vertical";
		height = "88%";
		width = "80%";
		x = "0%";
		y = "12%";
		padding = {0, 0, 0, 0},
		itemMargin  = {0, 0, 0, 0},
	}
	sp_commands[1] = StackPanel:New{
		parent = commands_main,
		resizeItems = true;
		orientation   = "horizontal";
		height = "33%";
		width = "100%";
		x = "0%";
		y = "0%";
		padding = {0, 0, 0, 0},
		itemMargin  = {0, 0, 0, 0},
	}
	sp_commands[2] = StackPanel:New{
		parent = commands_main,
		resizeItems = true;
		orientation   = "horizontal";
		height = "33%";
		width = "100%";
		x = "0%";
		y = "33%";
		padding = {0, 0, 0, 0},
		itemMargin  = {0, 0, 0, 0},
	}
	sp_commands[3] = StackPanel:New{
		parent = commands_main,
		resizeItems = true;
		orientation   = "horizontal";
		height = "33%";
		width = "100%";
		x = "0%";
		y = "66%";
		padding = {0, 0, 0, 0},
		itemMargin  = {0, 0, 0, 0},
	}

	states_main = StackPanel:New{
		parent = window,
		resizeItems = true;
		orientation   = "horizontal";
		height = "100%";
		width = "20%";
		x = "80%";
		y = "0%";
		padding = {0, 0, 0, 0},
		itemMargin  = {0, 0, 0, 0},
	}
	sp_states[1] = StackPanel:New {
		parent = states_main,
		resizeItems = true;
		orientation   = "vertical";
		height = "98%";
		width = "33%";
		x = "66%";
		y = "0%";
		padding = {0, 0, 0, 0},
		itemMargin  = {0, 0, 0, 0},
	}
	sp_states[2] = StackPanel:New {
		parent = states_main,
		resizeItems = true;
		orientation   = "vertical";
		height = "98%";
		width = "33%";
		x = '33%';
		y = "0%";
		padding = {0, 0, 0, 0},
		itemMargin  = {0, 0, 0, 0},
	}
	sp_states[3] = StackPanel:New {
		parent = states_main,
		resizeItems = true;
		orientation   = "vertical";
		height = "98%";
		width = "33%";
		x = "0%";
		y = "0%";
		padding = {0, 0, 0, 0},
		itemMargin  = {0, 0, 0, 0},
	}
	
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
			but.backgroundColor = {0.8, 0, 0, 1};
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


function widget:GetConfigData()
	if btn_common then 
		local ret = 
		{

		}
	  return ret
	else return nil end 
end

function widget:SetConfigData(data)
	if (data and type(data) == 'table') then

	end 
end 


function widget:Shutdown()
  widgetHandler:ConfigLayoutHandler(nil)
  Spring.ForceLayoutUpdate()
end

