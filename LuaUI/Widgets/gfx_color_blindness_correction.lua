function widget:GetInfo()
	return {
		name      = "Color Blindness Correction",
		version   = 1.0,
		desc      = "Corrects a screen colors for color-blinded people",
		author    = "ivand",
		date      = "2017",
		license   = "GPL",
		layer     = math.huge, --wanna draw last
		enabled   = true
	}
end

options_path = "Settings/Accessibility"
options_order = { "cbcType", "cbcMethod", "cbcOnlySim" }

options = {
	cbcType = {
		name = "Color Blindness Type",
		type = "radioButton",
		value = "none",
		items = {
			{key = "none", name = "None"},
			{key = "protanopia", name="Protanopia - missing RED"},
			{key = "deuteranopia", name="Deuteranopia - missing GREEN"},
			{key = "tritanopia", name="Tritanopia - missing BLUE"},
		},
		simpleMode = true,
		everyMode = true,
	},
	cbcMethod = {
		name = "Color Blindness Correction Method",
		type = "number",
		value = 2,
		min = 1, max = 2, step = 1,
		simpleMode = true,
		everyMode = true,
	},
	cbcOnlySim = {
		name = 'Only simulate color blindness',
		type = 'bool',
		value = false,
		advanced = true,
	},
}

---------------------------------------------------------------------------
local cbcShader = nil
local fragment_body = nil
local vsx, vsy = nil
local screenTex = nil
---------------------------------------------------------------------------

local function CleanShader()
	if (gl.DeleteShader and cbcShader) then
		gl.DeleteShader(cbcShader)
	end
	cbcShader = nil
end

local function CreateShader()
	local fragment_complete =
		"#define "..string.upper(options.cbcType.value).."\n" ..
		"#define METHOD"..tostring(options.cbcMethod.value).."\n" ..
		((options.cbcOnlySim.value and "#define CORRECT") or "").."\n" ..
		fragment_body
		
	cbcShader = gl.CreateShader({
		fragment = fragment_complete,
		uniformInt = {screenTex = 0}
	})
		
	if cbcShader == nil then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "cbcShader: shader error: "..gl.GetShaderLog())
	end
end

local function SetupCBCOptions()
	CleanShader()
	if options.cbcType.value ~= "none" then
		CreateShader()
	end
end

---------------------------------------------------------------------------

function widget:Initialize()
	if (gl.CreateShader == nil) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "removing widget, no shader support")
		widgetHandler:RemoveWidget()
		return
	end
	
	fragment_body = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\cbc.fs", VFS.ZIP)
	if (fragment_body == nil) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "removing widget, no shader code found")
		widgetHandler:RemoveWidget()
		return
	end

	options.cbcType.OnChange    = SetupCBCOptions
	options.cbcMethod.OnChange  = SetupCBCOptions
	options.cbcOnlySim.OnChange = SetupCBCOptions

	if (widgetHandler.DrawScreenPost ~= nil) then
		widgetHandler:RemoveCallIn("DrawScreenEffects")
	end

	SetupCBCOptions()
	widget:ViewResize()
end

local function CleanTextures()
	if screenTex then
		gl.DeleteTexture(screenTex)
		screenTex = nil
	end
end

local function CreateTextures()
	screenTex = gl.CreateTexture(vsx, vsy, {
		--TODO figure out what it means
		fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
	})
	if screenTex == nil then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "screenTex texture error")
	end
end

function widget:ViewResize()
	vsx, vsy = gl.GetViewSizes()
	CleanTextures()
	CreateTextures()
end

local function PerformDraw()
	if cbcShader then
		gl.CopyToTexture(screenTex, 0, 0, 0, 0, vsx, vsy)
		gl.Texture(0, screenTex)
		gl.UseShader(cbcShader)
		gl.TexRect(0,vsy,vsx,0)
		gl.Texture(0, false)
		gl.UseShader(0)
	end
end

-- Adds partial compatibility with spring versions, which don't support "DrawScreenPost", remove this later.
-- This call is removed in widget:Initialize() if DrawScreenPost is present
function widget:DrawScreenEffects(vsx, vsy)
	PerformDraw()
end

function widget:DrawScreenPost(vsx, vsy)
	PerformDraw()
end

function widget:Shutdown()
	CleanShader()
	CleanTextures()
	fragment_body = nil
end
