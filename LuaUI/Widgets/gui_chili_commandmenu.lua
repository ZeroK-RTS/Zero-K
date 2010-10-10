-- TODO: make EPIC save changed options somehow!
-- TODO: state switches need icons 
-- TODO: commandschanged gets called 2x for some reason, investigate

function widget:GetInfo()
  return {
    name      = "Chili Command Menu ",
    desc      = "v0.5 Chili Command Menu",
    author    = "Licho",
    date      = "6.9.2010",
    license   = "GNU GPL, v2 or later",
    layer     = 50,
    enabled   = true,
	handler   = true,
  }
end


local CMD_BUILD = 10010
local CMD_RAMP = 39734
local CMD_LEVEL = 39736
local CMD_RAISE = 39737
local CMD_SMOOTH = 39738
local CMD_RESTORE = 39739
local CMD_EMBARK = 31800
local CMD_DISEMBARK = 31801
local CMD_RETREAT_ZONE = 10001
local CMD_RETREAT =	10000
local CMD_PAGES = 60
local CMD_PRIORITY=34220
local CMD_STEALTH = 32100
local CMD_UNIT_AI = 36214
local CMD_AREA_MEX = 10100
local CMD_CLOAK_SHIELD = 32101

-- command configuration - command = level, categories can cycle detail levels which show only commands  below current detail level
-- level 0 - always visible, 1 - visible on  default settins, 2 - visible on advanced settings, >2 - invisible
-- default command level is 1,, default command category is special unless its state switch,

local common_commands = {
	[CMD.STOP]=1, [CMD.GUARD]=1, [CMD.ATTACK]=1, [CMD.FIGHT]=1,
	[CMD.WAIT]=2, [CMD.PATROL]=2, [CMD.MOVE]=2, 
}

local build_commands = {
	[CMD.REPAIR]=1,   [CMD.RECLAIM]=1, [CMD_BUILD] = 1, [CMD.CAPTURE] = 1, [CMD.RESURRECT] = 1, [CMD_LEVEL] =1,  [CMD_RAMP]= 1, 
	[CMD_RAISE] = 2, [CMD_SMOOTH] =2,  [CMD_RESTORE] =2 ,
}

local special_commands = {
	[CMD.SELFD]=1, [CMD.AUTOREPAIRLEVEL]=1,[CMD.DGUN]=1,
	[CMD_RETREAT_ZONE] = 2,
	[CMD_AREA_MEX] = 1,
}

local states_commands = {
	[CMD_CLOAK_SHIELD] = 1,
	[CMD_RETREAT] = 2, [CMD.MOVE_STATE] = 2, [CMD.FIRE_STATE] = 2, [CMD_UNIT_AI] = 2,
	[CMD_STEALTH] = 2,
	[CMD.AISELECT] = 3, 
	
}

local MAX_COLUMNS = 10
local MAX_STATE_COLUMNS = 16


-- Command overrides. State commands by default expect array of textures, one for each state. States are drawn without button borders and keep aspect ratio. 
-- You can specify texture, text,tooltip, color
local overrides = {
	[CMD.ATTACK] = { texture = 'LuaUi/Images/commands/attack.png',  text= '\255\0\255\0A\008ttack'},
	[CMD.STOP] = { texture = 'LuaUi/Images/commands/cancel.png', color={1,0,0,1.2}, text= '\255\0\255\0S\008top'},
	[CMD.FIGHT] = { texture = 'LuaUi/Images/commands/fight.png',text= '\255\0\255\0F\008ight'},
	[CMD.GUARD] = { texture = 'LuaUi/Images/commands/guard.png', text= '\255\0\255\0G\008uard'},
	[CMD.MOVE] = { texture = 'LuaUi/Images/commands/move.png', text= '\255\0\255\0M\008ove'},
	[CMD.PATROL] = { texture = 'LuaUi/Images/commands/patrol.png', text= '\255\0\255\0P\008atrol'},
	[CMD.WAIT] = { texture = 'LuaUi/Images/commands/wait.png', text= '\255\0\255\0W\008ait'},
	
	
	[CMD.REPAIR] = {text= '\255\0\255\0R\008epair', texture = 'LuaUi/Images/commands/repair.png'},
	[CMD.RECLAIM] = {text= 'R\255\0\255\0e\008claim', texture = 'LuaUi/Images/commands/reclaim.png'},
	[CMD.RESURRECT] = {text= 'Resurrec\255\0\255\0t\008', texture = 'LuaUi/Images/commands/resurrect.png'},
	[CMD_BUILD] = {text = '\255\0\255\0B\008uild'},
	
	[CMD_RAMP] = {text = 'Ramp', texture = 'LuaUi/Images/commands/ramp.png'},
	[CMD_LEVEL] = {text = 'Level', texture = 'LuaUi/Images/commands/level.png'},
	[CMD_RAISE] = {text = 'Raise', texture = 'LuaUi/Images/commands/raise.png'},
	[CMD_SMOOTH] = {text = 'Smooth', texture = 'LuaUi/Images/commands/smooth.png'},
	[CMD_RESTORE] = {text = 'Restore', texture = 'LuaUi/Images/commands/restore.png'},
	
	[CMD_AREA_MEX] = {text = 'Mex', texture = 'LuaUi/Images/ibeam.png'},
	
	[CMD.ONOFF] = { texture = {'LuaUi/Images/commands/states/off.png', 'LuaUi/Images/commands/states/on.png'}, text=''},
	[CMD_UNIT_AI] = { texture = {'LuaUi/Images/commands/states/bulb_off.png', 'LuaUi/Images/commands/states/bulb_on.png'}, text=''},
	[CMD.REPEAT] = { texture = {'LuaUi/Images/commands/states/repeat_off.png', 'LuaUi/Images/commands/states/repeat_on.png'}, text=''},
	[CMD.CLOAK] = { texture = {'LuaUi/Images/commands/states/cloak_off.png', 'LuaUI/Images/commands/states/cloak_on.png'}, text ='', tooltip =  'Unit cloaking state - press \255\0\255\0K\008 to toggle'},
	[CMD_CLOAK_SHIELD] = { texture = {'LuaUi/Images/commands/states/areacloak_off.png', 'LuaUI/Images/commands/states/areacloak_on.png'}, text ='', tooltip = 'Area Cloaker State'},
	[CMD_STEALTH] = { texture = {'LuaUi/Images/commands/states/stealth_off.png', 'LuaUI/Images/commands/states/stealth_on.png'}, text ='', },
	[CMD_PRIORITY] = { texture = {'LuaUi/Images/commands/states/wrench_low.png', 'LuaUi/Images/commands/states/wrench_med.png', 'LuaUi/Images/commands/states/wrench_high.png'}, text=''},
	[CMD.MOVE_STATE] = { texture = {'LuaUi/Images/commands/states/move_hold.png', 'LuaUi/Images/commands/states/move_engage.png', 'LuaUi/Images/commands/states/move_roam.png'}, text=''},
	[CMD.FIRE_STATE] = { texture = {'LuaUi/Images/commands/states/fire_hold.png', 'LuaUi/Images/commands/states/fire_return.png', 'LuaUi/Images/commands/states/fire_atwill.png'}, text=''},
	[CMD_RETREAT] = { texture = {'LuaUi/Images/commands/states/retreat_off.png', 'LuaUi/Images/commands/states/retreat_30.png', 'LuaUi/Images/commands/states/retreat_60.png', 'LuaUi/Images/commands/states/retreat_90.png'}, text=''},
}

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


--- 
local detailLevelButtonImages = {
	--/"LuaUi/Images/commands/leftarrow.png","LuaUi/Images/commands/plus.png","LuaUi/Images/commands/pluses.png",
	"LuaUi/Images/commands/minus.png","LuaUi/Images/commands/plus.png","LuaUi/Images/commands/pluses.png",
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
local sp_common
local sp_build 
local sp_special 
local sp_states

local btn_special
local btn_common
local btn_build


local window_visible = false

-- command id indexed field of items - each item is button, label and image 
local commandButtons = {} 
----------------------------------- COMMAND COLORS  - from cmdcolors.txt - default coloring
local cmdColors = {}

-- default config
local config = {
	common_level = 1,
	build_level = 1,
	special_level = 1,
	states_level = 1,
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
	local isState = cmd.type == CMDTYPE.ICON_MODE and #cmd.params > 1
	local text
	local texture
	local tooltip = cmd.tooltip

	local te = overrides[cmd.id]  -- command overrides 
	
	-- text 
	if te and te.text then 
		text = te.text 
	elseif isState then 
		text = cmd.params[cmd.params[1]+2]
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
			padding = {5, 5,5, 5},
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
			button.backgroundColor = {0,0,0,0}
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
				height="85%";
				y="15%";
				color = color;
				keepAspect = isState;
				file = texture;
				parent = button;
			}
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
local n_build = {}
local n_special = {}
local n_states = {}

local function ProcessCommand(cmd) 
	if cmd.id >= 0 and not cmd.hidden and cmd.id ~= CMD_PAGES then 
		--- state icons 
		if (cmd.type == CMDTYPE.ICON_MODE and cmd.params ~= nil and #cmd.params > 1) then 
			if states_commands[cmd.id] then 
				if btn_states.level >= states_commands[cmd.id] then 
					n_states[#n_states+1] = cmd 
				end 
			elseif btn_states.level >= 1 then 
				n_states[#n_states+1] = cmd
			end 
		elseif common_commands[cmd.id] then 
			if btn_common.level >= common_commands[cmd.id] then 
				n_common[#n_common+1] = cmd
			end 
		elseif build_commands[cmd.id] then 
			if btn_build.level >= build_commands[cmd.id] then 
				n_build[#n_build+1] = cmd
			end 
		else 
			if special_commands[cmd.id] then 
				if  btn_special.level >= special_commands[cmd.id] then 
					n_special[#n_special+1] = cmd 
				end
			elseif btn_special.level >= 1 then 
				n_special[#n_special+1] = cmd
			end 
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

local function Update() 
    local commands = widgetHandler.commands
    local customCommands = widgetHandler.customCommands
	
	if (#commands + #customCommands == 0) then 
		screen0:RemoveChild(window);
		window_visible = false;
		return
	else 
		if not window_visible then 
			screen0:AddChild(window);
			window_visible = true;
		end 
	end 
	
	n_common = {}
	n_build = {}
	n_special = {}
	n_states = {}
	for i = 1, #commands do ProcessCommand(commands[i]) end 
	for i = 1, #customCommands do ProcessCommand(customCommands[i]) end 
	for i = 1, #globalCommands do ProcessCommand(globalCommands[i]) end 

	UpdateContainer(sp_common, n_common)
	UpdateContainer(sp_build, n_build)
	UpdateContainer(sp_special, n_special)
	UpdateContainer(sp_states, n_states, MAX_STATE_COLUMNS)
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
	
	local _,viewHeight = Spring.GetWindowGeometry()
	local height = (viewHeight-390)/2
	if height > 300 then
		height = 300
	end
	
	window = Window:New{
		name   = 'ordercommandmenu6';
		padding = {0, 0, 0, 0},
		color = {0,0,0,0},
		x      = 0;
		width = 400;
		height = height; -- half space left over by minimap and selctions
		y = viewHeight-160-height;
		dockable = true;
		autosize = false,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
	}
	
	local function MakeLevelButton(x,y,width,height,level) 
		level = level or 0
		return Button:New{
			x = x;
			y = y;
			width = width;
			height = height;
			caption  = '',
			color = {0,0,0,0};
			backgroundColor = {0,0,0,0};
			padding = {0,0,0,0};
			tooltip = "Expand/Hide";
			parent = window;
			level = level;
			OnMouseDown = {function(self) 
				local _,_,left,_,right = Spring.GetMouseState()
				if right then
					self.level = ((self.level or 0) - 1) % 3
				else
					self.level = ((self.level or 0) + 1) % 3
				end
				self.children[1].file = detailLevelButtonImages[self.level+1]
				self.children[1]:Invalidate()
				Update()
			end};
				
			children = {
				Image:New {
					width = "100%";
					height = "100%";
					file = detailLevelButtonImages[level+1];
					keepAspect = true;
				}
			}
		}
	end 

	
	sp_common = StackPanel:New {
		resizeItems = true;
		orientation   = "horizontal";
		parent = window;
		x = "5%";
		height = "27%";
		width="95%";
		padding = {0, 0, 0, 0},
		itemMargin  = {1, 1, 1, 1},
	}

	sp_build = StackPanel:New {
		resizeItems = true;
		orientation   = "horizontal";
		x = "5%";
		width = "95%";
		y= "27%";
		height = "27%";
		parent = window;
		padding = {0, 0, 0, 0},
		itemMargin  = {1, 1, 1, 1},
	}
	
	sp_special = StackPanel:New {
		resizeItems = true;
		orientation   = "horizontal";
		x = "5%";
		width = "95%";
		y= "54%";
		height = "27%";
		parent = window;
		padding = {0, 0, 0, 0},
		itemMargin  = {1, 1, 1, 1},
	}
	
	sp_states = StackPanel:New {
		resizeItems = true;
		orientation   = "horizontal";
		parent = window;
		height = "18%";
		width = "95%";
		x = "5%";
		y = "81%";
		padding = {0, 0, 0, 0},
		itemMargin  = {1, 1, 1, 1},
	}
	
	
	btn_common = MakeLevelButton(0,0,"5%", "29%", config.common_level)
	btn_build = MakeLevelButton(0, "29%", "5%", "29%", config.build_level)
	btn_special = MakeLevelButton(0,"58%", "5%", "29%", config.special_level)
	btn_states = MakeLevelButton(0,"87%", "5%", "13%", config.states_level)

	
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
			common_level = btn_common.level,
			special_level = btn_special.level,
			build_level = btn_build.level,
			states_level = btn_states.level,
		}
	  return ret
	else return nil end 
end

function widget:SetConfigData(data)
	if (data and type(data) == 'table') then
		config.common_level = data.common_level
		config.build_level = data.build_level
		config.special_level = data.special_level
		config.states_level = data.states_level
	end 
end 


function widget:Shutdown()
  widgetHandler:ConfigLayoutHandler(nil)
  Spring.ForceLayoutUpdate()
end

