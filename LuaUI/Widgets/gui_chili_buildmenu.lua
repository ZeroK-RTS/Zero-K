-- TODO: make EPIC save changed options somehow!
-- TODO: state switches need icons 
-- TODO: commandschanged gets called 2x for some reason, investigate

function widget:GetInfo()
  return {
    name      = "Chili Build Menu ",
    desc      = "Forked from Chili Command Menu v0.5",
    author    = "Licho, changed to build by GoogleFrog",
    date      = "6.9.2010",
    license   = "GNU GPL, v2 or later",
    layer     = 50,
    enabled   = true,
	handler   = true,
  }
end


-- command configuration - command = level, categories can cycle detail levels which show only commands  below current detail level
-- level 0 - always visible, 1 - visible on  default settins, 2 - visible on advanced settings, >2 - invisible
-- default command level is 1,, default command category is special unless its state switch,

--common_commands
--build_commands
--special_commands

local economy_commands, turret_commands, other_turret_commands, factory_commands, support_commands, MAX_COLUMNS = include("Configs/build_menu.lua")

-- Command overrides. State commands by default expect array of textures, one for each state. States are drawn without button borders and keep aspect ratio. 
-- You can specify texture, text,tooltip, color

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
local build_window
local sp_economy
local sp_turret
local sp_other_turret
local sp_factory
local sp_support

local btn_economy
local btn_turret
local btn_other_turret
local btn_factory
local btn_support


local window_visible = false

-- command id indexed field of items - each item is button, label and image 
local commandButtons = {} 
----------------------------------- COMMAND COLORS  - from cmdcolors.txt - default coloring
local cmdColors = {}

-- default config
local config = {
	economy_level = 1,
	turret_level = 1,
	other_turret_level = 1,
	factory_level = 1,
	support_level = 0,
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
	local text = ""
	local texture  = '#' .. -cmd.id
	local tooltip = cmd.tooltip

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
local n_economy = {}
local n_turret = {}
local n_other_turret = {}
local n_factory = {}
local n_support = {}

local function ProcessCommand(cmd) 
	if cmd.id <= 0 and not cmd.hidden and cmd.id ~= CMD_PAGES then 
		if economy_commands[cmd.id] then 
			if btn_economy.level >= economy_commands[cmd.id].level then 
				n_economy[#n_economy+1] = cmd
			end 
		elseif turret_commands[cmd.id] then 
			if btn_turret.level >= turret_commands[cmd.id].level then 
				n_turret[#n_turret+1] = cmd
			end 
		elseif  other_turret_commands[cmd.id] then 
			if btn_other_turret.level >= other_turret_commands[cmd.id].level then 
				n_other_turret[#n_other_turret+1] = cmd
			end 
		elseif factory_commands[cmd.id] then 
			if btn_factory.level >= factory_commands[cmd.id].level then 
				n_factory[#n_factory+1] = cmd
			end 
		elseif support_commands[cmd.id] then 
			if btn_support.level >= support_commands[cmd.id].level then 
				n_support[#n_support+1] = cmd
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
	
	if (#commands == 0) then 
		screen0:RemoveChild(build_window);
		window_visible = false;
		return
	else 
		if not window_visible then 
			screen0:AddChild(build_window);
			window_visible = true;
		end 
	end 
	
	n_economy = {}
	n_turret = {}
	n_other_turret = {}
	n_factory = {}
	n_support = {}
	for i = 1, #commands do ProcessCommand(commands[i]) end 

	table.sort(n_economy, function(a,b) return economy_commands[a.id].order < economy_commands[b.id].order  end)
	table.sort(n_turret, function(a,b) return turret_commands[a.id].order < turret_commands[b.id].order end)
	table.sort(n_other_turret, function(a,b) return other_turret_commands[a.id].order < other_turret_commands[b.id].order end)
	table.sort(n_factory, function(a,b) return factory_commands[a.id].order < factory_commands[b.id].order end)
	table.sort(n_support, function(a,b) return support_commands[a.id].order < support_commands[b.id].order end)
	
	UpdateContainer(sp_economy, n_economy)
	UpdateContainer(sp_turret, n_turret)
	UpdateContainer(sp_other_turret, n_other_turret)
	UpdateContainer(sp_factory, n_factory)
	UpdateContainer(sp_support, n_support)
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

function widget:CommandsChanged()
	Update()		
end 

-- INITS 
function widget:Initialize()
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
	
 	build_window= Window:New{
		name   = 'orderbuildmenu6';
		padding = {0, 0, 0, 0},
		color = {0,0,0,0},
		x      = 0;
		width = 400;
		height = height; -- half space left over by minimap and selctions
		y = 270;
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
			parent = build_window;
			level = level;
			OnMouseDown = {function(self) 
				local _,_,left,_,right = Spring.GetMouseState()
				if right then
					self.level = ((self.level or 0) - 1) % 4
				else
					self.level = ((self.level or 0) + 1) % 4
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

	
	sp_economy = StackPanel:New {
		resizeItems = true;
		orientation   = "horizontal";
		parent = build_window;
		x = "5%";
		height = "20%";
		width="95%";
		padding = {0, 0, 0, 0},
		itemMargin  = {1, 1, 1, 1},
	}

	sp_turret = StackPanel:New {
		resizeItems = true;
		orientation   = "horizontal";
		x = "5%";
		width = "95%";
		y= "20%";
		height = "20%";
		parent = build_window;
		padding = {0, 0, 0, 0},
		itemMargin  = {1, 1, 1, 1},
	}
	
	sp_other_turret = StackPanel:New {
		resizeItems = true;
		orientation   = "horizontal";
		x = "5%";
		width = "95%";
		y= "40%";
		height = "20%";
		parent = build_window;
		padding = {0, 0, 0, 0},
		itemMargin  = {1, 1, 1, 1},
	}
	
	sp_factory = StackPanel:New {
		resizeItems = true;
		orientation   = "horizontal";
		x = "5%";
		width = "95%";
		y= "60%";
		height = "20%";
		parent = build_window;
		padding = {0, 0, 0, 0},
		itemMargin  = {1, 1, 1, 1},
	}
	
	sp_support = StackPanel:New {
		resizeItems = true;
		orientation   = "horizontal";
		parent = build_window;
		height = "20%";
		width = "95%";
		x = "5%";
		y = "80%";
		padding = {0, 0, 0, 0},
		itemMargin  = {1, 1, 1, 1},
	}
	
	
	btn_economy = MakeLevelButton(0,0,"5%", "20%", config.economy_level)
	btn_turret = MakeLevelButton(0, "20%", "5%", "20%", config.turret_level)
	btn_other_turret = MakeLevelButton(0, "40%", "5%", "20%", config.other_turret_level)
	btn_factory = MakeLevelButton(0,"60%", "5%", "20%", config.factory_level)
	btn_support = MakeLevelButton(0,"80%", "5%", "20%", config.support_level)

	
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
	if btn_economy then 
		local ret = 
		{
			economy_level = btn_economy.level,
			turret_level = btn_turret.level,
			other_turret_level = btn_other_turret.level,
			factory_level = btn_factory.level,
			support_level = btn_support.level,
		}
	  return ret
	else return nil end 
end

function widget:SetConfigData(data)
	if (data and type(data) == 'table') then
		config.economy_level = data.economy_level
		config.turret_level = data.turret_level
		config.other_turret_level = data.other_turret_level
		config.factory_level = data.factory_level
		config.support_level = data.support_level
	end 
end 


function widget:Shutdown()
  widgetHandler:ConfigLayoutHandler(nil)
  Spring.ForceLayoutUpdate()
end

