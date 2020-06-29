-- $Id: camain.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    main.lua
--  brief:   the entry point from gui.lua, relays call-ins to the widget manager
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local vfsInclude = VFS.Include
local vfsGame = VFS.GAME
local spSendCommands = Spring.SendCommands

spSendCommands("ctrlpanel LuaUI/ctrlpanel.txt")

vfsInclude("LuaUI/utils.lua"    , nil, vfsGame)
vfsInclude("LuaUI/setupdefs.lua", nil, vfsGame)
vfsInclude("LuaUI/savetable.lua", nil, vfsGame)
vfsInclude("LuaUI/debug.lua"    , nil, vfsGame)
vfsInclude("LuaUI/modfonts.lua" , nil, vfsGame)
vfsInclude("LuaUI/layout.lua"   , nil, vfsGame)   -- contains a simple LayoutButtons()
vfsInclude("LuaUI/cawidgets.lua", nil, vfsGame)  -- the widget handler

spSendCommands("echo " .. LUAUI_VERSION)

local gl = Spring.Draw  --  easier to use

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
--  A few helper functions
--

function Say(msg)
	spSendCommands('say ' .. msg)
end


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
--  Update()  --  called every frame
--

activePage = 0

forceLayout = true


function Update()
  local currentPage = Spring.GetActivePage()
  if (forceLayout or (currentPage ~= activePage)) then
    Spring.ForceLayoutUpdate()  --  for the page number indicator
    forceLayout = false
  end
  activePage = currentPage

  fontHandler.Update()

  widgetHandler:Update()

  return
end


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
--  WidgetHandler fixed calls
--

function Shutdown()
  return widgetHandler:Shutdown()
end

function ConfigureLayout(command)
  return widgetHandler:ConfigureLayout(command)
end

function CommandNotify(id, params, options)
  return widgetHandler:CommandNotify(id, params, options)
end

function UnitCommandNotify(unitID, id, params, options)
  return widgetHandler:UnitCommandNotify(unitID, id, params, options)
end

function DrawScreen(vsx, vsy)
  return widgetHandler:DrawScreen()
end

function KeyPress(key, mods, isRepeat)
  return widgetHandler:KeyPress(key, mods, isRepeat)
end

function KeyRelease(key, mods)
  return widgetHandler:KeyRelease(key, mods)
end

function TextInput(utf8, ...)
  return widgetHandler:TextInput(utf8, ...)
end

function MouseMove(x, y, dx, dy, button)
  return widgetHandler:MouseMove(x, y, dx, dy, button)
end

function MousePress(x, y, button)
  return widgetHandler:MousePress(x, y, button)
end

function MouseRelease(x, y, button)
  return widgetHandler:MouseRelease(x, y, button)
end

function IsAbove(x, y)
  return widgetHandler:IsAbove(x, y)
end

function GetTooltip(x, y)
  return widgetHandler:GetTooltip(x, y)
end

function AddConsoleLine(msg, priority)
  return widgetHandler:AddConsoleLine(msg, priority)
end

function GroupChanged(groupID)
  return widgetHandler:GroupChanged(groupID)
end

local allModOptions = Spring.GetModOptions()
function Spring.GetModOption(s,bool,default)
  if (bool) then
    local modOption = allModOptions[s]
    if (modOption==nil) then modOption = (default and "1") end
    return (modOption=="1")
  else
    local modOption = allModOptions[s]
    if (modOption==nil) then modOption = default end
    return modOption
  end
end

--
-- The unit (and some of the Draw) call-ins are handled
-- differently (see LuaUI/widgets.lua / UpdateCallIns())
--


--------------------------------------------------------------------------------

