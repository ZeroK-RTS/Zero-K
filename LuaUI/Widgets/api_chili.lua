--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name        = "Chili Framework",
		desc        = "Hot GUI Framework",
		author      = "jK",
		date        = "WIP",
		license     = "GPLv2",
		version     = "2.1",
		layer       = 1000,
		enabled     = true,  --  loaded by default?
		handler     = true,
		api	        = true,
		alwaysStart = true,
	}
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Use old chili if unable to use RTT
local USE_OLD_CHILI = (Spring.GetConfigInt("ZKUseNewChiliRTT") ~= 1) or not ((gl.CreateFBO and gl.BlendFuncSeparate) ~= nil)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- UI Scaling

local UI_SCALE_MESSAGE = "SetInterfaceScale "

local function SetUiScale(scaleFactor)
	-- Scale such that width is an integer, because the UI aligns along the bottom of the screen.
	local realWidth = gl.GetViewSizes()
	WG.uiScale = realWidth/math.floor(realWidth/scaleFactor)
end
SetUiScale((Spring.GetConfigInt("interfaceScale", 100) or 100)/100)

function widget:RecvLuaMsg(msg)
	if string.find(msg, UI_SCALE_MESSAGE) == 1 then
		local value = tostring(string.sub(msg, 19))
		if value then
			SetUiScale(value/100)
			local vsx, vsy = Spring.Orig.GetViewSizes()
			local widgets = widgetHandler.widgets
			for i = 1, #widgets do
				local w = widgets[i]
				if w.ViewResize then
					w:ViewResize(vsx, vsy)
				end
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if not USE_OLD_CHILI then

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
		gl.Scale(WG.uiScale,WG.uiScale,1)
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
		gl.Scale(WG.uiScale,WG.uiScale,1)
		screen0:TweakDraw()
		gl.PopMatrix()
	end
end

function widget:DrawGenesis()
	gl.Color(1,1,1,1)
	tf.Update()
	th.Update()
	tk.Update()
	gl.Color(1,1,1,1)
end


function widget:IsAbove()
	local x, y, lmb, mmb, rmb, outsideSpring = Spring.ScaledGetMouseState()
	return (not outsideSpring) and (not screen0:IsEmpty()) and screen0:IsAbove(x,y)
end


local mods = {}
function widget:MousePress(x,y,button)
	if WG.uiScale and WG.uiScale ~= 1 then
		x, y = x/WG.uiScale, y/WG.uiScale
	end
	if Spring.IsGUIHidden() then return false end
	
	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	mods.alt=alt; mods.ctrl=ctrl; mods.meta=meta; mods.shift=shift;
	return screen0:MouseDown(x,y,button,mods)
end


function widget:MouseRelease(x,y,button)
	if WG.uiScale and WG.uiScale ~= 1 then
		x, y = x/WG.uiScale, y/WG.uiScale
	end
	if Spring.IsGUIHidden() then return false end
	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	mods.alt=alt; mods.ctrl=ctrl; mods.meta=meta; mods.shift=shift;

	return screen0:MouseUp(x,y,button,mods)
end


function widget:MouseMove(x,y,dx,dy,button)
	if WG.uiScale and WG.uiScale ~= 1 then
		x, y, dx, dy = x/WG.uiScale, y/WG.uiScale, dx/WG.uiScale, dy/WG.uiScale
	end
	if Spring.IsGUIHidden() then return false end
	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	mods.alt=alt; mods.ctrl=ctrl; mods.meta=meta; mods.shift=shift;

	return screen0:MouseMove(x,y,dx,dy,button,mods)
end


function widget:MouseWheel(up,value)
	local x,y = Spring.ScaledGetMouseState()
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


function widget:TextInput(utf8, ...)
	if Spring.IsGUIHidden() then return false end

	return screen0:TextInput(utf8, ...)
end


function widget:ViewResize(vsx, vsy)
	screen0:Resize(vsx/(WG.uiScale or 1), vsy/(WG.uiScale or 1))
end

widget.TweakIsAbove	  = widget.IsAbove
widget.TweakMousePress   = widget.MousePress
widget.TweakMouseRelease = widget.MouseRelease
widget.TweakMouseMove	= widget.MouseMove
widget.TweakMouseWheel   = widget.MouseWheel

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
else -- Old Chili
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

assert(debug)
local source = debug and debug.getinfo(1).source
local DIR = GetDirectory(source) or ((LUA_DIRNAME or LUAUI_DIRNAME) .."Widgets/")
CHILI_DIRNAME = DIR .. "chili_old/"

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
	gl.Color(1,1,1,1)
	if (not screen0:IsEmpty()) then
		gl.PushMatrix()
			local vsx,vsy = gl.GetViewSizes()
			gl.Translate(0,vsy,0)
			gl.Scale(1,-1,1)
			gl.Scale(WG.uiScale,WG.uiScale,1)
			screen0:Draw()
		gl.PopMatrix()
	end
	gl.Color(1,1,1,1)
end


function widget:DrawLoadScreen()
	gl.Color(1,1,1,1)
	if (not screen0:IsEmpty()) then
		gl.PushMatrix()
			local vsx,vsy = gl.GetViewSizes()
			gl.Scale(1/vsx,1/vsy,1)
			gl.Translate(0,vsy,0)
			gl.Scale(1,-1,1)
			screen0:Draw()
		gl.PopMatrix()
	end
	gl.Color(1,1,1,1)
end


function widget:TweakDrawScreen()
	gl.Color(1,1,1,1)
	if (not screen0:IsEmpty()) then
		gl.PushMatrix()
			local vsx,vsy = gl.GetViewSizes()
			gl.Translate(0,vsy,0)
			gl.Scale(1,-1,1)
			gl.Scale(WG.uiScale,WG.uiScale,1)
			screen0:TweakDraw()
		gl.PopMatrix()
	end
	gl.Color(1,1,1,1)
end


function widget:DrawGenesis()
	gl.Color(1,1,1,1)
	tf.Update()
	th.Update()
	tk.Update()
	gl.Color(1,1,1,1)
end


function widget:IsAbove(x,y)
	if WG.uiScale and WG.uiScale ~= 1 then
		x, y = x/WG.uiScale, y/WG.uiScale
	end
	if Spring.IsGUIHidden() then
		return false
	end
	local x, y, lmb, mmb, rmb, outsideSpring = Spring.ScaledGetMouseState()
	if outsideSpring then
		return false
	end

	return screen0:IsAbove(x,y)
end


local mods = {}
function widget:MousePress(x,y,button)
	if WG.uiScale and WG.uiScale ~= 1 then
		x, y = x/WG.uiScale, y/WG.uiScale
	end
	if Spring.IsGUIHidden() then return false end

	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	mods.alt=alt; mods.ctrl=ctrl; mods.meta=meta; mods.shift=shift;
	return screen0:MouseDown(x,y,button,mods)
end


function widget:MouseRelease(x,y,button)
	if WG.uiScale and WG.uiScale ~= 1 then
		x, y = x/WG.uiScale, y/WG.uiScale
	end
	if Spring.IsGUIHidden() then return false end

	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	mods.alt=alt; mods.ctrl=ctrl; mods.meta=meta; mods.shift=shift;
	return screen0:MouseUp(x,y,button,mods)
end


function widget:MouseMove(x,y,dx,dy,button)
	if WG.uiScale and WG.uiScale ~= 1 then
		x, y, dx, dy = x/WG.uiScale, y/WG.uiScale, dx/WG.uiScale, dy/WG.uiScale
	end
	if Spring.IsGUIHidden() then return false end

	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	mods.alt=alt; mods.ctrl=ctrl; mods.meta=meta; mods.shift=shift;
	return screen0:MouseMove(x,y,dx,dy,button,mods)
end


function widget:MouseWheel(up,value)
	if Spring.IsGUIHidden() then return false end

	local x,y = Spring.ScaledGetMouseState()
	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	mods.alt=alt; mods.ctrl=ctrl; mods.meta=meta; mods.shift=shift;
	return screen0:MouseWheel(x,y,up,value,mods)
end


local keyPressed = true
function widget:KeyPress(key, mods, isRepeat, label, unicode)
	if Spring.IsGUIHidden() then return false end

	keyPressed = screen0:KeyPress(key, mods, isRepeat, label, unicode)
	return keyPressed
end


function widget:KeyRelease()
	if Spring.IsGUIHidden() then return false end

	local _keyPressed = keyPressed
	keyPressed = false
	return _keyPressed -- block engine actions when we processed it
end

function widget:TextInput(utf8, ...)
	if Spring.IsGUIHidden() then return false end

	return screen0:TextInput(utf8, ...)
end


function widget:ViewResize(vsx, vsy)
	screen0:Resize(vsx/(WG.uiScale or 1), vsy/(WG.uiScale or 1))
end

widget.TweakIsAbove	  = widget.IsAbove
widget.TweakMousePress   = widget.MousePress
widget.TweakMouseRelease = widget.MouseRelease
widget.TweakMouseMove	= widget.MouseMove
widget.TweakMouseWheel   = widget.MouseWheel

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

end
