-- $Id: gfx_outline.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    gfx_outline.lua
--  brief:   Displays a nice cartoon like outline around units
--  author:  jK
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Outline No Shader",
		desc      = "Displays a nice cartoon like outline around units.",
		author    = "jK",
		date      = "Dec 06, 2007",
		license   = "GNU GPL, v2 or later",
		layer     = -10,
		enabled   = false  --  loaded by default?
	}
end

local thickness = 1
local thicknessMult = 1
local forceLowQuality = false
local scaleWithHeight
local functionScaleWithHeight

local PI = math.pi
local SUBTLE_MIN = 500
local SUBTLE_MAX = 3000

local function OnchangeFunc()
	thickness = options.thickness.value
end

local function QualityChangeCheckFunc()
	if forceLowQuality then
		options.lowQualityOutlines.OnChange = nil
		options.lowQualityOutlines.value = true
		options.lowQualityOutlines.OnChange = QualityChangeCheckFunc
	end
end

options_path = 'Settings/Graphics/Unit Visibility/Outline (No Shader)'
options = {
	thickness = {
		name = 'Outline Thickness',
		desc = 'How thick the outline appears around objects',
		type = 'number',
		min = 0.2, max = 1, step = 0.01,
		value = 0.5,
	OnChange = OnchangeFunc,
	},
	scaleWithHeight = {
		name = 'Scale With Distance',
		desc = 'Reduces the screen space width of outlines when zoomed out.',
		type = 'bool',
		value = false,
		noHotkey = true,
		OnChange = function (self)
			scaleWithHeight = self.value
			if not scaleWithHeight then
				thicknessMult = 1
			end
		end,
	},
	functionScaleWithHeight = {
		name = 'Subtle Scale With Distance',
		desc = 'Reduces the screen space width of outlines when zoomed out, in a subtle way.',
		type = 'bool',
		value = true,
		noHotkey = true,
		OnChange = function (self)
			functionScaleWithHeight = self.value
			if not functionScaleWithHeight then
				thicknessMult = 1
			end
		end,
	},
	lowQualityOutlines = {
		name = 'Low Quality Outlines',
		desc = 'Reduces outline accuracy to improve perfomance, only recommended for low-end machines',
		type = 'bool',
		value = false,
		advanced = true,
		noHotkey = true,
		OnChange = QualityChangeCheckFunc,
	},
}

OnchangeFunc()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--//textures
local offscreentex
local depthtex
local blurtex

--//shader
local depthShader
local blurShader_h
local blurShader_v
local uniformUseEqualityTest, uniformScreenXY, uniformScreenX, uniformScreenY

--// geometric
local vsx, vsy = 0,0
local resChanged = false

--// display lists
local enter2d,leave2d

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local GL_DEPTH_BITS = 0x0D56

local GL_DEPTH_COMPONENT   = 0x1902
local GL_DEPTH_COMPONENT16 = 0x81A5
local GL_DEPTH_COMPONENT24 = 0x81A6
local GL_DEPTH_COMPONENT32 = 0x81A7

--// speed ups
local ALL_UNITS       = Spring.ALL_UNITS
local GetUnitHealth   = Spring.GetUnitHealth
local GetVisibleUnits = Spring.GetVisibleUnits

local GL_MODELVIEW  = GL.MODELVIEW
local GL_PROJECTION = GL.PROJECTION
local GL_COLOR_BUFFER_BIT = GL.COLOR_BUFFER_BIT

local glUnit            = gl.Unit
local glCopyToTexture   = gl.CopyToTexture
local glRenderToTexture = gl.RenderToTexture
local glCallList        = gl.CallList

local glUseShader  = gl.UseShader
local glUniform    = gl.Uniform
local glUniformInt = gl.UniformInt

local glClear    = gl.Clear
local glTexRect  = gl.TexRect
local glColor    = gl.Color
local glTexture  = gl.Texture

local glResetMatrices = gl.ResetMatrices
local glMatrixMode    = gl.MatrixMode
local glPushMatrix    = gl.PushMatrix
local glLoadIdentity  = gl.LoadIdentity
local glPopMatrix     = gl.PopMatrix

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--tables
local unbuiltUnits = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function widget:Initialize()
	vsx, vsy = widgetHandler:GetViewSizes()

	self:ViewResize(widgetHandler:GetViewSizes())

	if gl.CreateShader == nil then --For old Intel chips
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Outline widget: cannot create shaders. forcing shader-less fallback.")
		forceLowQuality = true
		options.lowQualityOutlines.value = true
		return true
	end

	--For cards that can use shaders
	enter2d = gl.CreateList(function()
		glUseShader(0)
		glMatrixMode(GL_PROJECTION); glPushMatrix(); glLoadIdentity()
		glMatrixMode(GL_MODELVIEW);  glPushMatrix(); glLoadIdentity()
	end)
	leave2d = gl.CreateList(function()
		glMatrixMode(GL_PROJECTION); glPopMatrix()
		glMatrixMode(GL_MODELVIEW);  glPopMatrix()
		glTexture(false)
		glUseShader(0)
	end)

	depthShader = gl.CreateShader({
		fragment = [[
			uniform sampler2D tex0;
			uniform int useEqualityTest;
			uniform vec2 screenXY;

			void main(void)
			{
				vec2 texCoord = vec2( gl_FragCoord.x/screenXY.x , gl_FragCoord.y/screenXY.y );
				float depth  = texture2D(tex0, texCoord ).z;

				if (depth < gl_FragCoord.z) {
					discard;
				}
				gl_FragColor = gl_Color;
			}
		]],
		uniformInt = {
			tex0 = 0,
			useEqualityTest = 1,
		},
			uniform = {
			screenXY = {vsx,vsy},
		},
	})

	blurShader_h = gl.CreateShader({
		fragment = [[
			uniform sampler2D tex0;
			uniform int screenX;

			const vec2 kernel = vec2(0.6,0.7);

			void main(void) {
				vec2 texCoord  = vec2(gl_TextureMatrix[0] * gl_TexCoord[0]);
				gl_FragColor = vec4(0.0);

				float pixelsize = 1.0/float(screenX);
				gl_FragColor += kernel[0] * texture2D(tex0, vec2(texCoord.s + 2.0*pixelsize,texCoord.t) );
				gl_FragColor += kernel[1] * texture2D(tex0, vec2(texCoord.s + pixelsize,texCoord.t) );

				gl_FragColor += texture2D(tex0, texCoord );

				gl_FragColor += kernel[1] * texture2D(tex0, vec2(texCoord.s + -1.0*pixelsize,texCoord.t) );
				gl_FragColor += kernel[0] * texture2D(tex0, vec2(texCoord.s + -2.0*pixelsize,texCoord.t) );
			}
		]],
		uniformInt = {
			tex0 = 0,
			screenX = vsx,
		},
	})


	blurShader_v = gl.CreateShader({
		fragment = [[
			uniform sampler2D tex0;
			uniform int screenY;

			const vec2 kernel = vec2(0.6,0.7);

			void main(void) {
				vec2 texCoord  = vec2(gl_TextureMatrix[0] * gl_TexCoord[0]);
				gl_FragColor = vec4(0.0);

				float pixelsize = 1.0/float(screenY);
				gl_FragColor += kernel[0] * texture2D(tex0, vec2(texCoord.s,texCoord.t + 2.0*pixelsize) );
				gl_FragColor += kernel[1] * texture2D(tex0, vec2(texCoord.s,texCoord.t + pixelsize) );

				gl_FragColor += texture2D(tex0, texCoord );

				gl_FragColor += kernel[1] * texture2D(tex0, vec2(texCoord.s,texCoord.t + -1.0*pixelsize) );
				gl_FragColor += kernel[0] * texture2D(tex0, vec2(texCoord.s,texCoord.t + -2.0*pixelsize) );
			}
		]],
		uniformInt = {
			tex0 = 0,
			screenY = vsy,
		},
	})

	if (depthShader == nil) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Outline widget: depthcheck shader error, forcing shader-less fallback: "..gl.GetShaderLog())
		-- widgetHandler:RemoveWidget()
		-- return false
		forceLowQuality = true
		options.lowQualityOutlines.value = true
		return true
	end
	if (blurShader_h == nil) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Outline widget: hblur shader error, forcing shader-less fallback: "..gl.GetShaderLog())
		-- widgetHandler:RemoveWidget()
		-- return false
		forceLowQuality = true
		options.lowQualityOutlines.value = true
		return true
	end
	if (blurShader_v == nil) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Outline widget: vblur shader error, forcing shader-less fallback: "..gl.GetShaderLog())
		-- widgetHandler:RemoveWidget()
		-- return false
		forceLowQuality = true
		options.lowQualityOutlines.value = true
		return true
	end

	uniformScreenXY        = gl.GetUniformLocation(depthShader,  'screenXY')
	uniformScreenX         = gl.GetUniformLocation(blurShader_h, 'screenX')
	uniformScreenY         = gl.GetUniformLocation(blurShader_v, 'screenY')
end

function widget:ViewResize(viewSizeX, viewSizeY)
	vsx = viewSizeX
	vsy = viewSizeY

	gl.DeleteTexture(depthtex or 0)
	gl.DeleteTextureFBO(offscreentex or 0)
	gl.DeleteTextureFBO(blurtex or 0)

	if not forceLowQuality then
		depthtex = gl.CreateTexture(vsx,vsy, {
			border = false,
			format = GL_DEPTH_COMPONENT24,
			min_filter = GL.NEAREST,
			mag_filter = GL.NEAREST,
		})

		offscreentex = gl.CreateTexture(vsx,vsy, {
			border = false,
			min_filter = GL.LINEAR,
			mag_filter = GL.LINEAR,
			wrap_s = GL.CLAMP,
			wrap_t = GL.CLAMP,
			fbo = true,
			fboDepth = true,
		})

		blurtex = gl.CreateTexture(vsx,vsy, {
			border = false,
			min_filter = GL.LINEAR,
			mag_filter = GL.LINEAR,
			wrap_s = GL.CLAMP,
			wrap_t = GL.CLAMP,
			fbo = true,
		})
	end

	resChanged = true
end


function widget:Shutdown()
	gl.DeleteTexture(depthtex or 0)
	if (gl.DeleteTextureFBO) then
		gl.DeleteTextureFBO(offscreentex or 0)
		gl.DeleteTextureFBO(blurtex or 0)
	end

	if (gl.DeleteShader) then
		gl.DeleteShader(depthShader or 0)
		gl.DeleteShader(blurShader_h or 0)
		gl.DeleteShader(blurShader_v or 0)
	end

	gl.DeleteList(enter2d or 0)
	gl.DeleteList(leave2d or 0)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function DrawVisibleUnits(overrideEngineDraw, perUnitStencil)
	if (Spring.GetGameFrame() % 15 == 0) then
		checknow = true
	end

	local visibleUnits = GetVisibleUnits(ALL_UNITS,nil,false)
	for i = 1, #visibleUnits do
		if checknow then
			local unitProgress = select(5, GetUnitHealth(visibleUnits[i]))
			if unitProgress == nil or unitProgress >= 1 then
				unbuiltUnits[visibleUnits[i]] = nil
			else
				unbuiltUnits[visibleUnits[i]] = true
			end
		end

		if not unbuiltUnits[visibleUnits[i]] then
			if perUnitStencil then
				gl.Clear(GL.STENCIL_BUFFER_BIT)
				gl.StencilFunc(GL.ALWAYS, 0x01, 0xFF)
				gl.StencilOp(GL.REPLACE, GL.REPLACE, GL.REPLACE)
				gl.PolygonMode(GL.FRONT_AND_BACK, GL.FILL)
				glUnit(visibleUnits[i],true)
				gl.StencilFunc(GL.NOTEQUAL, 0x01, 0xFF)
				gl.StencilOp(GL.KEEP, GL.KEEP, GL.KEEP)
				gl.PolygonMode(GL.FRONT_AND_BACK, GL.LINE)
				gl.DepthMask(true)
			end
			glUnit(visibleUnits[i],overrideEngineDraw)
			if perUnitStencil then
				gl.DepthMask(false)
				gl.StencilFunc(GL.ALWAYS, 0, 0xFF);
				gl.StencilOp(GL.REPLACE, GL.REPLACE, GL.REPLACE)
				gl.PolygonMode(GL.FRONT_AND_BACK,GL.FILL)
				gl.Unit(visibleUnits[i],true)
			end
		end
	end
end

local MyDrawVisibleUnits = function()
	glClear(GL_COLOR_BUFFER_BIT,0,0,0,0)
	glPushMatrix()
	glResetMatrices()
	glColor(0,0,0,thickness * thicknessMult)
	DrawVisibleUnits(true)
	glColor(1,1,1,1)
	glPopMatrix()
end

--This is expected to be a shader-less fallback for low-end machines, though it also works for refraction pass
local function DrawVisibleUnitsLines(underwater, frontLines)
	gl.DepthTest(GL.LESS)
	if underwater then
		gl.LineWidth(3.0 * thickness * thicknessMult)
		gl.PolygonOffset(8.0, 4.0)
	else
		if options.lowQualityOutlines.value then
			gl.LineWidth(4.0 * thickness * thicknessMult)
		end
		if frontLines then
			gl.LineWidth(3.0 * thickness * thicknessMult)
			gl.PolygonOffset(10.0, 5.0)
		end
	end
	gl.PolygonMode(GL.FRONT_AND_BACK, GL.LINE)
	gl.Culling(GL.FRONT)
	-- gl.DepthMask(false)
	glColor(0,0,0,1)

	glPushMatrix()
	glResetMatrices()
	-- gl.StencilTest(true)
	DrawVisibleUnits(true)--, true)
	-- gl.StencilTest(false)
	glPopMatrix()

	gl.LineWidth(1.0)
	glColor(1,1,1,1)
	gl.Culling(false)
	gl.PolygonMode(GL.FRONT_AND_BACK, GL.FILL)
	gl.DepthTest(false)

	if underwater then
		gl.PolygonOffset(0.0, 0.0)
	end
end

local blur_h = function()
  glClear(GL_COLOR_BUFFER_BIT,0,0,0,0)
  glUseShader(blurShader_h)
  glTexRect(-1-0.5/vsx,1+0.5/vsy,1+0.5/vsx,-1-0.5/vsy)
end

local blur_v = function()
	glClear(GL_COLOR_BUFFER_BIT,0,0,0,0)
	glUseShader(blurShader_v)
	glTexRect(-1-0.5/vsx,1+0.5/vsy,1+0.5/vsx,-1-0.5/vsy)
end

function widget:DrawWorldPreUnit()
	if (options.lowQualityOutlines.value or forceLowQuality) then
		DrawVisibleUnitsLines(false)
		gl.DepthMask(true)
		DrawVisibleUnitsLines(false, true)
		gl.DepthMask(false)
	else
		glCopyToTexture(depthtex, 0, 0, 0, 0, vsx, vsy)
		glTexture(depthtex)

		if (resChanged) then
			resChanged = false
			if (vsx==1) or (vsy==1) then
				return
			end
			glUseShader(depthShader)
			glUniform(uniformScreenXY,   vsx,vsy )
			glUseShader(blurShader_h)
			glUniformInt(uniformScreenX, vsx )
			glUseShader(blurShader_v)
			glUniformInt(uniformScreenY, vsy )
		end

		glUseShader(depthShader)
		glRenderToTexture(offscreentex,MyDrawVisibleUnits)

		glTexture(offscreentex)
		glRenderToTexture(blurtex, blur_v)
		glTexture(blurtex)
		glRenderToTexture(offscreentex, blur_h)

		glCallList(enter2d)
		glTexture(offscreentex)
		glTexRect(-1-0.5/vsx,1+0.5/vsy,1+0.5/vsx,-1-0.5/vsy)
		glCallList(leave2d)

		gl.DepthMask(true)
		DrawVisibleUnitsLines(false, true)
		gl.DepthMask(false)
		glTexture(false)
	end
end

function widget:DrawWorldRefraction()
	DrawVisibleUnitsLines(true)
end

function widget:UnitCreated(unitID)
	unbuiltUnits[unitID] = true
end

function widget:UnitDestroyed(unitID)
	unbuiltUnits[unitID] = nil
end

function widget:Update(dt)
	if functionScaleWithHeight then
		local cs = Spring.GetCameraState()
		local gy = Spring.GetGroundHeight(cs.px, cs.pz)
		local cameraHeight
		if cs.name == "ta" then
			cameraHeight = cs.height - gy
		else
			cameraHeight = cs.py - gy
		end
		if cameraHeight < SUBTLE_MIN then
			thicknessMult = 1
			return
		end
		if cameraHeight > SUBTLE_MAX then
			thicknessMult = 0.5
			return
		end
		
		thicknessMult = (((math.cos(PI*(cameraHeight - SUBTLE_MIN)/(SUBTLE_MAX - SUBTLE_MIN)) + 1)/2)^2)/2 + 0.5
		--Spring.Echo("cameraHeight", cameraHeight, "thicknessMult", thicknessMult)
		return
	end
	if not scaleWithHeight then
		return
	end
	local cs = Spring.GetCameraState()
	local gy = Spring.GetGroundHeight(cs.px, cs.pz)
	local cameraHeight
	if cs.name == "ta" then
		cameraHeight = cs.height - gy
	else
		cameraHeight = cs.py - gy
	end
	if cameraHeight < 1 then
		cameraHeight = 1
	end
	thicknessMult = 1000/cameraHeight
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
