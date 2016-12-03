function widget:GetInfo()
	return {
		name      = "Depth of Field Shader",
		version	  = 1.0,
		desc      = "Blurs far away objects.",
		author    = "aeonios",
		date      = "Nov. 2016",
		license   = "GPL",
		layer     = -1,
		enabled   = true
	}
end

options_path = 'Settings/Graphics/Effects/Depth of Field'

options_order = {'useDoF'}

options = {
	useDoF = { type='bool', name='Apply Depth of Field Effect', value=false, noHotkey = true, advanced = false}
}

local function onChangeFunc()
	if options.useDoF.value then
		widget:Initialize()
	else
		if glDeleteTexture then
			glDeleteTexture(blurTex or "")
			glDeleteTexture(screenTex or "")
			blurTex, screenTex = nil, nil
		end
	end
end

options.useDoF.OnChange = onChangeFunc

-----------------------------------------------------------------
-- Engine Functions
-----------------------------------------------------------------

local spGetCameraPosition    = Spring.GetCameraPosition

local glCopyToTexture        = gl.CopyToTexture
local glCreateShader         = gl.CreateShader
local glCreateTexture        = gl.CreateTexture
local glDeleteShader         = gl.DeleteShader
local glDeleteTexture        = gl.DeleteTexture
local glGetShaderLog         = gl.GetShaderLog
local glTexture              = gl.Texture
local glTexRect              = gl.TexRect
local glRenderToTexture		 = gl.RenderToTexture
local glUseShader            = gl.UseShader
local glGetUniformLocation   = gl.GetUniformLocation
local glUniform				 = gl.Uniform
local glUniformMatrix		 = gl.UniformMatrix

-----------------------------------------------------------------


-----------------------------------------------------------------
-- Global Vars
-----------------------------------------------------------------

local vsx = nil	-- current viewport width
local vsy = nil	-- current viewport height
local dofShader = nil
local screenTex = nil
local blurTex = nil

-- shader uniform handles
local eyePosLoc = nil
local viewProjectionInvLoc = nil

-----------------------------------------------------------------

function widget:ViewResize(x, y)
	vsx, vsy = gl.GetViewSizes()
	glDeleteTexture(blurTex or "")
	glDeleteTexture (screenTex or "")
	blurTex, screenTex = nil, nil
	
	screenTex = glCreateTexture(vsx, vsy, {
		fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
	})
	
	blurTex = glCreateTexture(vsx/2, vsy/2, {
		fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
	})
	
	if not blurTex or not screenTex then
		Spring.Echo("Depth of Field: Failed to create textures!")
		widgetHandler:RemoveWidget()
		return
	end
end

function widget:Initialize()
	if (glCreateShader == nil) then
		Spring.Echo("[Depth of Field::Initialize] removing widget, no shader support")
		widgetHandler:RemoveWidget()
		return
	end
	
	if not options.useDoF.value then
		return
	end
	
	dofShader = dofShader or glCreateShader({
		fragment = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\dof.fs", VFS.ZIP),
		
		uniformInt = {origTex = 0, blurTex = 1, mapdepths = 2},
	})
	
	if not dofShader then
		Spring.Echo("Depth of Field: Failed to create shader!")
		Spring.Echo(gl.GetShaderLog())
		widgetHandler:RemoveWidget()
		return
	end
	
	eyePosLoc = gl.GetUniformLocation(dofShader, "eyePos")
	viewProjectionInvLoc = gl.GetUniformLocation(dofShader, "viewProjectionInv")
	
	widget:ViewResize()
end

function widget:Shutdown()
	if (glDeleteShader and dofShader) then
		glDeleteShader(dofShader)
	end
	
	if glDeleteTexture then
		glDeleteTexture(blurTex or "")
		glDeleteTexture(screenTex or "")
	end
	dofShader, blurTex, screenTex = nil, nil, nil
end

function widget:DrawScreenEffects()
	if not options.useDoF.value then
		return -- if the option is disabled don't draw anything.
	end

	gl.Blending(false)
	glCopyToTexture(screenTex, 0, 0, 0, 0, vsx, vsy) -- the original screen image
	
	glTexture(screenTex)
	glRenderToTexture(blurTex, glTexRect, -1, 1, 1, -1)
	glTexture(false)
	
	local cpx, cpy, cpz = spGetCameraPosition()
	local gmin, gmax = Spring.GetGroundExtremes()
	local effectiveHeight = cpy - math.max(0, gmin)
	cpy = 3.5 * math.sqrt(effectiveHeight) * math.log(effectiveHeight)
	glUseShader(dofShader)
		glUniform(eyePosLoc, cpx, cpy, cpz)
		glUniformMatrix(viewProjectionInvLoc, "viewprojectioninverse")
		glTexture(0, screenTex)
		glTexture(1, blurTex)
		glTexture(2, "$map_gbuffer_zvaltex")
		
		glTexRect(0, 0, vsx, vsy, false, true)
		
		glTexture(0, false)
		glTexture(1, false)
		glTexture(2, false)
	glUseShader(0)
end
