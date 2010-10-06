function widget:GetInfo()
  return {
    name      = "Chili Command Menu Wrapper",
    desc      = "v0.03 Chili Command Menu Wrapper",
    author    = "CarRepairer (adapted from IceUI)",
    date      = "2010-07-27",
    license   = "GNU GPL, v2 or later",
    layer     = 50,
    enabled   = false,
  }
end


local window_cmenu
local Chili
local cmenu_visible = false
local request_update = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Config

local ctrlpanel = include("ctrlpanel.h.lua") or {}
local vsx,vsy = Spring.GetViewGeometry()


local function booldef(v1,def)
  if (v1==nil) then
    return def
  else
    return (v1==true)or(v1==1)or(v1=="1")
  end
end


options_path = 'Settings/Interface/Command Menu'
options_order = {
    'buildiconsfirst',
    'outlinefont',
    'dropshadows',
    'useoptionleds',
    'selectgaps',
    'newattackmode',
    'attackrect',
    'invcolorselect',
    'frontbyends',
    'iconsize',
    'texturealpha',
    'textborder',
    'iconborder',
    'aspect',		
    'xselectionpos',
    'yselectionpos',
  }
options = {
  
  buildiconsfirst = {
    name  = 'Display build icons first',
    desc  = 'Do you want build icons or commands at the top of the panel?',
    type  = 'bool',
    value = Spring.GetConfigInt('BuildIconsFirst') == 1,

    OnChange = function(self)
      local oldbuildiconsfirst = (Spring.GetConfigInt('BuildIconsFirst') == 1)
      if (oldbuildiconsfirst ~= options.buildiconsfirst.value) then
        Spring.SetConfigInt('BuildIconsFirst', options.buildiconsfirst.value and 1 or 0)
        Spring.SendCommands("buildiconsfirst")
      end
      Spring.ForceLayoutUpdate()
    end,
  },
  outlinefont = {
    name  = 'Outline font',
    desc  = 'Should the font on the control panel be outlined?',
    type  = 'bool',
    value = booldef(ctrlpanel.outlinefont, true),
  },
  dropshadows = {
    name  = 'Dropshadows',
    desc  = 'Should the font on the control have a dropshadow?',
    type  = 'bool',
    value = booldef(ctrlpanel.dropshadows, true),
  },
  useoptionleds = {
    name  = 'Use option LEDs',
    desc  = 'Display LEDs underneath buttons that have several states (like On/Off, Hold/Maneuver/Roam).',
    type  = 'bool',
    value = booldef(ctrlpanel.useoptionleds, true),
  },
  selectgaps = {
    name  = 'Select through icon margin',
    desc  = 'Should the margin between icons let mouse clicks through or should they belong to the icon?',
    type  = 'bool',
    value = booldef(ctrlpanel.selectgaps, false),
  },
--[[
  selectthrough = {
    name  = 'Select through',
    desc  = 'Do you want to be able to give orders and select units if you click on unoccupied space of the control panel?',
    type  = 'bool',
    value = booldef(ctrlpanel.selectthrough, true),
  },
--]]
  newattackmode = {
    name  = 'Area attack',
    desc  = 'If selected, you can drag a circle or rectangle to attack all enemies in the area in turn.\n'..
            'Listed because it\'s also configured through ctrlpanel.txt.',
    type  = 'bool',
    value = booldef(ctrlpanel.newattackmode, true),
    path  = 'Settings/Interface',
  },
  attackrect = {
    name  = 'Rectangular area attack',
    desc  = 'Use a rectangle instead of a circle for an area attack order.\n'..
            'Listed because it\'s also configured through ctrlpanel.txt.',
    type  = 'bool',
    value = booldef(ctrlpanel.attackrect, false),
    path  = 'Settings/Interface',
	advanced = true,
  },
  invcolorselect = {
    name  = 'Rectangular area attack - inverted color',
    desc  = 'When using rectangular area attack, this inverts the colors of the highlighted terrain.\n'..
            'Listed because it\'s also configured through ctrlpanel.txt.',
    type  = 'bool',
    value = booldef(ctrlpanel.invcolorselect, true),
    path  = 'Settings/Interface',
	advanced = true,
  },
  frontbyends = {
    name  = 'Line move - end to end',
    desc  = 'When ordering units to move into a line, this lets you select the end points instead of the middle and one end point.\n'..
            'Listed because it\'s also configured through ctrlpanel.txt. Has no effect if you use the custom formation widget.',
    type  = 'bool',
    value = booldef(ctrlpanel.frontbyends, true),
    path  = 'Settings/Interface',
	advanced = true,
  },
  texturealpha = {
    name  = 'Buildpic and texture transparency',
    desc  = 'How much of the battlefield do you want to see through the buildpics and textures?',
    type  = 'number', min = 0, max = 1, step = 0.01,
    value = ctrlpanel.texturealpha or 0.9,
  },
  textborder = {
    name  = 'Text margin',
    desc  = 'How much space should be between the text of the orders and their border?',
    type  = 'number', min = 0, max = 20, step = 1,
    value = (ctrlpanel.textborder and vsx and ctrlpanel.textborder * vsx) or 0,
  },
  iconborder = {
    name  = 'Icon margin',
    desc  = 'How much space should be between the individual items?',
    type  = 'number', min = 0, max = 20, step = 1,
    value = (ctrlpanel.iconborder and vsx and ctrlpanel.iconborder * vsx) or 0,
  },
  --[[
  frameborder = {
    name  = 'Frame margin',
    desc  = 'How much space should be between the buttons and the window frame?',
    type  = 'number', min = 0, max = 20, step = 1,
    value = (ctrlpanel.frameborder and vsx and ctrlpanel.frameborder * vsx) or 0,
  },
  --]]
  aspect = {
    name  = 'Buildpics aspect ratio',
    desc  = 'Most mods use square buildpics but some adapted to the 4:3 ratio used by Springs default control panel.',
    type  = 'list',
    items = {
      { 
        key  = 1,
        name = '1:1',
        desc = '1:1',
      },
      {
        key  = 4/3,
        name = '4:3',
        desc = '4:3',
      },
      {
        key  = 'preset',
        name = 'Preset',
        desc = 'Read the correct aspect ratio from an internal list.\n'..
               'Please tell MelTraX and/or CarRepairer if it\'s wrong for any mod.',
      },
    },
    value = 'preset'
  },
  iconsize = {
    name  = 'Icon Size',
    desc  = 'Set the size of the Icon.',
    type  = 'number', min = 20, max = 100, step = 2,
    value = (ctrlpanel.xiconsize and vsx and ctrlpanel.xiconsize * vsx or 50),
  },
  xselectionpos = {
    name  = 'SelectionCount Info Position X',
    desc  = 'Set the x position of the \'Selected Units\' info box.',
    type  = 'number', min = -0.1, max = 1, step = 0.0001,
    value = ctrlpanel.xselectionpos or -0.1,
	advanced = true,
  },
  yselectionpos = {
    name  = 'SelectionCount Info Position Y',
    desc  = 'Set the y position of the \'Selected Units\' info box.',
    type  = 'number', min = -0.1, max = 1, step = 0.0001,
    value = ctrlpanel.yselectionpos or -0.1,
	advanced = true,
  },
}


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- ctrlpanel.txt writter

local function getAspectRatio(selectedRatio)
  local nonSquare = {
    ca = 4/3
  }

  if type(selectedRatio) == 'number' then
    return selectedRatio
  elseif selectedRatio == 'preset' then
    return nonSquare[Game.modShortName] or 1
  else
    return 1
  end
end


local function ConfigureCMenu()
	local file = io.open('Chili_ctrlpanel.txt', 'w')
	
	vsx,vsy = Spring.GetViewGeometry()
	local aspect = getAspectRatio(options.aspect.value)

	local x,y,w,h = Chili.unpack4(window_cmenu.clientArea)
	x,y = window_cmenu:LocalToScreen(x,y)
	y = vsy - y - h

	local iconSizeAndBorder = options.iconsize.value + options.iconborder.value * 2

	local iconSize_sw  = options.iconsize.value / vsx
	local iconSize_sh  = options.iconsize.value / (vsy * aspect)
	local cols           = math.floor( w / iconSizeAndBorder  )
	local rows           = math.floor( h / iconSizeAndBorder * aspect )

	if file then
		file:write('outlinefont    ' .. (options.outlinefont.value and 1 or 0) .. '\n')
		file:write('dropshadows    ' .. (options.dropshadows.value and 1 or 0) .. '\n')
		file:write('useOptionLEDs  ' .. (options.useoptionleds.value and 1 or 0) .. '\n')
		file:write('textureAlpha   ' .. options.texturealpha.value .. '\n')
		file:write('selectGaps     ' .. (options.selectgaps.value and 1 or 0) .. '\n')
		--file:write('selectThrough  ' .. (options.selectthrough.value and 1 or 0) .. '\n')

		file:write('newAttackMode  ' .. (options.newattackmode.value and 1 or 0) .. '\n')
		file:write('attackRect     ' .. (options.attackrect.value and 1 or 0) .. '\n')
		file:write('invColorSelect ' .. (options.invcolorselect.value and 1 or 0) .. '\n')
		file:write('frontByEnds    ' .. (options.frontbyends.value and 1 or 0) .. '\n')

		file:write('prevPageSlot   auto\n')
		file:write('deadIconSlot   none\n')
		file:write('nextPageSlot   auto\n')

		file:write('xSelectionPos  ' .. (options.xselectionpos.value) .. '\n')
		file:write('ySelectionPos  ' .. (options.yselectionpos.value) .. '\n')

		file:write( ('frameAlpha      0\n') )
		file:write( ('xIcons         %i\n'):format(cols) )
		file:write( ('yIcons         %i\n'):format(rows) )

		file:write( ('xIconSize      %f\n'):format(iconSize_sw) )
		file:write( ('yIconSize      %f\n'):format(iconSize_sh) )

		file:write( ('textBorder     %f\n'):format(options.textborder.value / vsx) )
		file:write( ('iconBorder     %f\n'):format(options.iconborder.value / vsx) )
		file:write( ('frameBorder     0\n') )
		file:write( ('selectThrough   1\n') )

		file:write( ('xPos           %f\n'):format(x / vsx) )
		file:write( ('yPos           %f\n'):format(y / vsy) )

		file:close()
		Spring.SendCommands('ctrlpanel Chili_ctrlpanel.txt')
		os.remove('Chili_ctrlpanel.txt')
	end
end


for _,option in pairs(options) do
  if type(option.OnChange) ~= 'function' then
    --option.OnChange = ConfigureCMenu
    option.OnChange = function() request_update = true end
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialize & Shutdown

function widget:Initialize()
	if (not WG.Chili) then
		widgetHandler:RemoveWidget()
		return
	end

	Chili = WG.Chili

	window_cmenu = Chili.Window:New{  
		color = {1,1,1,0.1},
		dockable = true,
		name = "commandmenu",
		x = 0,  
		y = "25%",
		width  = "20%",
		height = "50%",
		--parent = Chili.Screen0,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		minimumSize = {50,50},
	}

	widget:SelectionChanged(Spring.GetSelectedUnits())
end


function widget:Shutdown()
	if (window_cmenu) then
		window_cmenu:Dispose()
	end
	Spring.SendCommands('ctrlpanel LuaUI/ctrlpanel.txt')
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Callins

local lastUpdate = 0
local curTime = 0
local lx, ly, lw, lh

function widget:Update(dt)
	curTime = curTime + dt
	if (curTime > lastUpdate + 0.5) and
	   (request_update or lw ~= window_cmenu.width or lh ~= window_cmenu.height or lx ~= window_cmenu.x or ly ~= window_cmenu.y)
	then
		--// window size changed -> update ctrlpanel.txt
		local cx,cy,cw,ch = Chili.unpack4(window_cmenu.clientArea)
		cx,cy = window_cmenu:LocalToScreen(cx,cy)
		local vsx,vsy = gl.GetViewSizes()
		
		ConfigureCMenu()
		
		lx = window_cmenu.x
		ly = window_cmenu.y
		lh = window_cmenu.height
		lw = window_cmenu.width

		lastUpdate = curTime
		request_update = false
	end
end 


function widget:SelectionChanged(sel)
	if sel[1] then
		if not cmenu_visible then
			Chili.Screen0:AddChild(window_cmenu)
		end
		cmenu_visible = true
	else
		if cmenu_visible then
			Chili.Screen0:RemoveChild(window_cmenu)
		end
		cmenu_visible = false
	end
end
