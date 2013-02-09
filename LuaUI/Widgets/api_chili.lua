--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Framework",
    desc      = "Hot GUI Framework",
    author    = "jK",
    date      = "WIP",
    license   = "GPLv2",
    version   = "2.0",
    layer     = 1000,
    enabled   = true,  --  loaded by default?
    handler   = true,
    api       = true,
    alwaysStart    = true,
  }
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Chili
local screen0
local th
local tk
local tf

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Chili's location

local function GetDirectory(filepath) 
    return filepath and filepath:gsub("(.*/)(.*)", "%1") 
end 

local source = debug and debug.getinfo(1).source
local DIR = GetDirectory(source) or (LUAUI_DIRNAME.."Widgets/")
CHILI_DIRNAME = DIR .. "chili/"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
  Chili = VFS.Include(CHILI_DIRNAME .. "core.lua", nil, VFS.RAW_FIRST)

  screen0 = Chili.Screen:New{}
  th = Chili.TextureHandler
  tk = Chili.TaskHandler
  tf = Chili.FontHandler

  --// Export Widget Globals
  WG.Chili = Chili
  WG.Chili.Screen0 = screen0

  --// do this after the export to the WG table!
  --// because other widgets use it with `parent=Chili.Screen0`,
  --// but chili itself doesn't handle wrapped tables correctly (yet)
  screen0 = Chili.DebugHandler.SafeWrap(screen0)
end

function widget:Shutdown()
  --table.clear(Chili) the Chili table also is the global of the widget so it contains a lot more than chili's controls (pairs,select,...)
  WG.Chili = nil
end

function widget:Dispose()
  screen0:Dispose()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:DrawScreen()
  if (not screen0:IsEmpty()) then
    gl.PushMatrix()
    local vsx,vsy = gl.GetViewSizes()
    gl.Translate(0,vsy,0)
    gl.Scale(1,-1,1)
    screen0:Draw()
    gl.PopMatrix()
  end
end


function widget:TweakDrawScreen()
  if (not screen0:IsEmpty()) then
    gl.PushMatrix()
    local vsx,vsy = gl.GetViewSizes()
    gl.Translate(0,vsy,0)
    gl.Scale(1,-1,1)
    screen0:TweakDraw()
    gl.PopMatrix()
  end
end


function widget:Update()
  tk.Update()
  tf.Update()
end


function widget:DrawGenesis()
  th.Update()
end


function widget:IsAbove(x,y)
  return (not screen0:IsEmpty()) and screen0:IsAbove(x,y)
end


local mods = {}
function widget:MousePress(x,y,button)
  local alt, ctrl, meta, shift = Spring.GetModKeyState()
  mods.alt=alt; mods.ctrl=ctrl; mods.meta=meta; mods.shift=shift;

  return screen0:MouseDown(x,y,button,mods)
end


function widget:MouseRelease(x,y,button)
  local alt, ctrl, meta, shift = Spring.GetModKeyState()
  mods.alt=alt; mods.ctrl=ctrl; mods.meta=meta; mods.shift=shift;

  return screen0:MouseUp(x,y,button,mods)
end


function widget:MouseMove(x,y,dx,dy,button)
  local alt, ctrl, meta, shift = Spring.GetModKeyState()
  mods.alt=alt; mods.ctrl=ctrl; mods.meta=meta; mods.shift=shift;

  return screen0:MouseMove(x,y,dx,dy,button,mods)
end


function widget:MouseWheel(up,value)
  local x,y = Spring.GetMouseState()
  local alt, ctrl, meta, shift = Spring.GetModKeyState()
  mods.alt=alt; mods.ctrl=ctrl; mods.meta=meta; mods.shift=shift;

  return screen0:MouseWheel(x,y,up,value,mods)
end


local keyPressed = true
function widget:KeyPress(key, mods, isRepeat, label, unicode)
  keyPressed = screen0:KeyPress(key, mods, isRepeat, label, unicode)
  return keyPressed
end


function widget:KeyRelease()
  local _keyPressed = keyPressed
  keyPressed = false
  return _keyPressed -- block engine actions when we processed it
end


function widget:ViewResize(vsx, vsy) 
	screen0:Resize(vsx, vsy)
end 

widget.TweakIsAbove      = widget.IsAbove
widget.TweakMousePress   = widget.MousePress
widget.TweakMouseRelease = widget.MouseRelease
widget.TweakMouseMove    = widget.MouseMove
widget.TweakMouseWheel   = widget.MouseWheel

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
