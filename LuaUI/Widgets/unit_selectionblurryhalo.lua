--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Selection BlurryHalo",
    desc      = "Shows a halo for selected, hovered ally-selected units.",
    author    = "CarRepairer, from jK's gfx_halo, modified by Shadowfury333 and aeonios",
    date      = "Jan, 2017",
    version   = "1.0",
    license   = "GNU GPL, v2 or later",
    layer     = -11,
    enabled   = false  --  loaded by default?
  }
end


local SafeWGCall = function(fnName, param1) if fnName then return fnName(param1) else return nil end end
local GetUnitUnderCursor = function(onlySelectable) return SafeWGCall(WG.PreSelection_GetUnitUnderCursor, onlySelectable) end
local IsSelectionBoxActive = function() return SafeWGCall(WG.PreSelection_IsSelectionBoxActive) end
local GetUnitsInSelectionBox = function() return SafeWGCall(WG.PreSelection_GetUnitsInSelectionBox) end
local IsUnitInSelectionBox = function(unitID) return SafeWGCall(WG.PreSelection_IsUnitInSelectionBox, unitID) end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/Interface/Selection/Blurry Halo Selections'

options_order = {
	'showAlly',
	'thickness',
	'blur',
}

options = {
	showAlly = {
		name = 'Show Ally Selections',
		type = 'bool',
		desc = 'Highlight the units your allies currently have selected.',
		value = true,
	},
	
	thickness = {
		name = 'Outline Thickness',
		desc = 'How thick the outline appears around objects',
		type = 'number',
		min = 1, max = 16, step = 1,
		value = 10,
    },
  
	blur = {
		name = 'Outline Blurriness',
		desc = 'How smooth the outlines appear',
		type = 'number',
		min = 2, max = 16, step = 1,
		value = 16,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local blurtex1
local blurtex2
local masktex

local fbo

local featherShader_h
local featherShader_v
local blurShader_h
local blurShader_v
local maskGenShader
local maskApplyShader
local invRXloc, invRYloc, screenXloc, screenYloc
local radiusXloc, radiusYloc, thkXloc, thkYloc
local haloColorloc

local vsx, vsy = 1,1
local ivsx, ivsy = 1,1

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--// speed ups

local ALL_UNITS       = Spring.ALL_UNITS

local spGetMyTeamID     = Spring.GetMyTeamID
local spGetUnitTeam     = Spring.GetUnitTeam
local spValidUnitID		= Spring.ValidUnitID
local ValidFeatureID	= Spring.ValidFeatureID
local spIsUnitAllied	= Spring.IsUnitAllied
local spIsUnitSelected	= Spring.IsUnitSelected
local spGetMouseState	= Spring.GetMouseState
local spTraceScreenRay	= Spring.TraceScreenRay
local spGetCameraPosition = Spring.GetCameraPosition
local spGetGroundHeight = Spring.GetGroundHeight
local spGetPlayerControlledUnit		= Spring.GetPlayerControlledUnit
local spGetVisibleUnits			= Spring.GetVisibleUnits
local spIsUnitIcon = Spring.IsUnitIcon

local GL_FRONT = GL.FRONT
local GL_BACK  = GL.BACK
local GL_MODELVIEW  = GL.MODELVIEW
local GL_PROJECTION = GL.PROJECTION
local GL_COLOR_BUFFER_BIT = GL.COLOR_BUFFER_BIT
local GL_DEPTH_BUFFER_BIT = GL.DEPTH_BUFFER_BIT
local GL_COLOR_ATTACHMENT0_EXT = 0x8CE0
local GL_COLOR_ATTACHMENT1_EXT = 0x8CE1

local glCreateTexture = gl.CreateTexture
local glDeleteTexture = gl.DeleteTexture

local glUnit            = gl.Unit
local glFeature         = gl.Feature
local glRenderToTexture = gl.RenderToTexture
local glActiveFBO		= gl.ActiveFBO

local glUseShader  = gl.UseShader
local glUniform    = gl.Uniform
local glUniformInt = gl.UniformInt

local glClear     = gl.Clear
local glTexRect   = gl.TexRect
local glColor     = gl.Color
local glTexture   = gl.Texture
local glDepthTest = gl.DepthTest
local glBlending  = gl.Blending

local echo = Spring.Echo

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetVisibleUnits()
	local units = spGetVisibleUnits(-1, 30, false)
	local boxedUnits = GetUnitsInSelectionBox();

	local visibleAllySelUnits = {}
	local visibleSelected = {}
	local visibleBoxed = {}
	
	
	for i=1, #units do
		local unitID = units[i]
		if (spIsUnitSelected(unitID)) then
			visibleSelected[#visibleSelected+1] = unitID
		elseif options.showAlly.value and WG.allySelUnits and WG.allySelUnits[unitID] then
			local team = spGetUnitTeam(unitID)
			if team then
				if not visibleAllySelUnits[team] then
					visibleAllySelUnits[team] = {}
				end
				visibleAllySelUnits[team][unitID] = true
			end
		end
		if IsUnitInSelectionBox(unitID) then
			visibleBoxed[#visibleBoxed+1] = unitID
		end
	end
	
	return visibleAllySelUnits, visibleSelected, visibleBoxed
end


local function DrawSelected(visibleAllySelUnits, visibleSelected, visibleBoxed)
	local featureHoverColor = { 1, 0, 1, 1}
	local myHoverColor 	    = { 0, 1, 1, 1 }
	local enemyHoverColor   = { 1, 0, 0, 1 }
	local selectColor 	    = { 0, 1, 0, 1}

	glUniform(haloColorloc, selectColor[1], selectColor[2], selectColor[3], selectColor[4])
	for i=1,#visibleSelected do
		local unitID = visibleSelected[i]
		glUnit(unitID,true,-1)
	end
	
	for teamID, data in pairs(visibleAllySelUnits) do
		local r, g, b = Spring.GetTeamColor(teamID)
		glUniform(haloColorloc, r, g, b, 1)
		for unitID, _ in pairs(data) do
			glUnit(unitID,true,-1)
		end
	end

	glUniform(haloColorloc, myHoverColor[1], myHoverColor[2], myHoverColor[3], myHoverColor[4])
	for i=1, #visibleBoxed do
		local unitID = visibleBoxed[i]
		glUnit(unitID,true,-1)
	end

	local mx, my = spGetMouseState()
	local pointedType, data = spTraceScreenRay(mx, my, false, true)
	if pointedType == 'unit' then
		data = GetUnitUnderCursor(false) --Does minimap check and handles selection box as well
	end

	if pointedType == 'unit' and data and spValidUnitID(data) then
		local teamID = spGetUnitTeam(data)
		if teamID == spGetMyTeamID() then
			glUniform(haloColorloc, myHoverColor[1], myHoverColor[2], myHoverColor[3], myHoverColor[4])
		elseif (teamID and Spring.AreTeamsAllied(teamID, Spring.GetMyTeamID()) ) then
			glUniform(haloColorloc, myHoverColor[1], myHoverColor[2], myHoverColor[3], myHoverColor[4])
		else
			glUniform(haloColorloc, enemyHoverColor[1], enemyHoverColor[2], enemyHoverColor[3], enemyHoverColor[4])
		end

		glUnit(data, true,-1)
	elseif (pointedType == 'feature') and ValidFeatureID(data) then
		glUniform(haloColorloc, featureHoverColor[1], featureHoverColor[2], featureHoverColor[3], featureHoverColor[4])
		glFeature(data, true)
	end
end

local function renderToTextureFunc(tex, s, t)
	glTexture(tex)
	glTexRect(-1 * s, -1 * t,  1 * s, 1 * t)
	glTexture(false)
end

local function mglRenderToTexture(FBOTex, tex, s, t)
	glRenderToTexture(FBOTex, renderToTextureFunc, tex, s, t)
end

function widget:DrawWorldPreUnit()
	if Spring.IsGUIHidden() then
		return
	end

	glBlending(false)
	glDepthTest(false)
	glRenderToTexture(blurtex1, glClear, GL_COLOR_BUFFER_BIT,0,0,0,0)
	glRenderToTexture(masktex, glClear, GL_COLOR_BUFFER_BIT,1,1,1,1)
	local visibleAllySelUnits, visibleSelected, visibleBoxed = GetVisibleUnits()
	glUseShader(maskGenShader)
		glActiveFBO(fbo, DrawSelected, visibleAllySelUnits, visibleSelected, visibleBoxed)
	glUseShader(0)
end

function widget:DrawScreenEffects()
	if Spring.IsGUIHidden() then
		return
	end
	
	local x, y, z = spGetCameraPosition()
	local _, coords = spTraceScreenRay(vsx/2, vsy/2, true)
	if (coords) then
		y = y - coords[2]
	else
		local iy = spGetGroundHeight(x, z)
		if iy then
			y = y - iy
		end
	end
	y = math.max(1, y)
	
	glBlending(false)
	
	-- apply feathering
	local thickness = options.thickness.value * math.min(2.0, math.max(750/y, 0.2))
	thickness = math.max(thickness, 1)
	glUseShader(featherShader_h)
		glUniform(screenXloc, ivsx)
		glUniform(thkXloc, thickness)
		mglRenderToTexture(blurtex2, blurtex1, 1, -1)
	glUseShader(0)
	
	glUseShader(featherShader_v)
		glUniform(screenYloc, ivsy)
		glUniform(thkYloc, thickness)
		mglRenderToTexture(blurtex1, blurtex2, 1, -1)
	glUseShader(0)
	
	-- apply blur over two iterations to approximate a gaussian
	local blur = options.blur.value * math.min(2.0, math.max(750/y, 0.2))
	blur = math.max(1, blur)
	glUseShader(blurShader_h)
		glUniform(invRXloc, ivsx)
		glUniform(radiusXloc, blur)
		mglRenderToTexture(blurtex2, blurtex1, 1, -1)
	glUseShader(0)
		
	glUseShader(blurShader_v)
		glUniform(invRYloc, ivsy)
		glUniform(radiusYloc, blur)
		mglRenderToTexture(blurtex1, blurtex2, 1, -1)
	glUseShader(0)
	
	-- apply the halos and mask to the screen
	glBlending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	glTexture(0, blurtex1)
	glTexture(1, masktex)
	glUseShader(maskApplyShader)
		glTexRect(0, 0, vsx, vsy, false, true)
	glUseShader(0)
	glTexture(0, false)
	glTexture(1, false)
	glBlending(false)
end


local function ShowSelectionSquares(state)
  local alpha = state and 1 or 0
  local f = io.open('cmdcolors.tmp', 'w+')
  if (f) then
    f:write('unitBox  0 1 0 ' .. alpha)
    f:close()
    Spring.SendCommands({'cmdcolors cmdcolors.tmp'})
  end
  os.remove('cmdcolors.tmp')
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- initializers

function widget:Initialize()
	if not gl.CreateShader or not gl.CreateFBO then
		Spring.Echo("Blurry Halo Selections: your card does not support shaders!")
		widgetHandler:RemoveWidget()
		return
	end
	
	fbo = gl.CreateFBO()
	self:ViewResize()

	maskGenShader = gl.CreateShader({
    fragment = [[
      uniform vec4 color;

      void main(void) {
        gl_FragData[0] = color;
        gl_FragData[1] = vec4(0.0, 0.0, 0.0, 0.0);
      }
    ]],
  })

  if (maskGenShader == nil) then
    Spring.Log(widget:GetInfo().name, LOG.ERROR, "Halo selection widget: mask generation shader error: "..gl.GetShaderLog())
    widgetHandler:RemoveWidget()
    return false
  end
  
  featherShader_h = gl.CreateShader({
    fragment = [[
      uniform sampler2D tex0;
      uniform float screenX;
      uniform float thickness;
	  
      void main(void) {
        vec2 texCoord  = gl_TexCoord[0].st;
        vec4 color = texture2D(tex0, texCoord);
        
        for (int i = 1; i <= thickness; i++){
			vec4 tmpcolor1 = texture2D(tex0, vec2(texCoord.s + i * screenX,texCoord.t));
			vec4 tmpcolor2 = texture2D(tex0, vec2(texCoord.s - i * screenX,texCoord.t));
			
			color.r = max(color.r, max(tmpcolor1.r, tmpcolor2.r));
			color.g = max(color.g, max(tmpcolor1.g, tmpcolor2.g));
			color.b = max(color.b, max(tmpcolor1.b, tmpcolor2.b));
			color.a = max(color.a, max(tmpcolor1.a, tmpcolor2.a));
        }

        gl_FragColor = color;
      }
    ]],
    uniformInt = {
      tex0 = 0,
    },
  })


  if (featherShader_h == nil) then
    Spring.Log(widget:GetInfo().name, LOG.ERROR, "Halo selection widget: hfeather shader error: "..gl.GetShaderLog())
    widgetHandler:RemoveWidget()
    return false
  end

	featherShader_v = gl.CreateShader({
    fragment = [[
		uniform sampler2D tex0;
      uniform float screenY;
      uniform float thickness;

      void main(void) {
        vec2 texCoord  = gl_TexCoord[0].st;
        vec4 color = texture2D(tex0, texCoord);
        
        for (int i = 1; i <= thickness; i++){
			vec4 tmpcolor1 = texture2D(tex0, vec2(texCoord.s,texCoord.t + i * screenY));
			vec4 tmpcolor2 = texture2D(tex0, vec2(texCoord.s,texCoord.t - i * screenY));
			
			color.r = max(color.r, max(tmpcolor1.r, tmpcolor2.r));
			color.g = max(color.g, max(tmpcolor1.g, tmpcolor2.g));
			color.b = max(color.b, max(tmpcolor1.b, tmpcolor2.b));
			color.a = max(color.a, max(tmpcolor1.a, tmpcolor2.a));
        }
        
        gl_FragColor = color;
      }
    ]],
    uniformInt = {
      tex0 = 0,
    },
  })

  if (featherShader_v == nil) then
    Spring.Log(widget:GetInfo().name, LOG.ERROR, "Halo selection widget: vfeather shader error: "..gl.GetShaderLog())
    widgetHandler:RemoveWidget()
    return false
  end

  blurShader_h = gl.CreateShader({
    fragment = [[
		uniform sampler2D texture0;
		uniform float inverseRX;
		uniform float fragKernelRadius;
		float bloomSigma = fragKernelRadius / 2.0;

		void main(void) {
			vec2 C0 = vec2(gl_TexCoord[0]);

			vec4 S = texture2D(texture0, C0);
			float weight = 1.0 / (2.50663 * bloomSigma);
			float total_weight = weight;
			S *= weight;
			for (float r = 1.5; r < fragKernelRadius; r += 2.0)
			{
				weight = exp(-((r*r)/(2.0 * bloomSigma * bloomSigma)))/(2.50663 * bloomSigma);
				S += texture2D(texture0, C0 - vec2(r * inverseRX, 0.0)) * weight;
				S += texture2D(texture0, C0 + vec2(r * inverseRX, 0.0)) * weight;

				total_weight += 2.0 * weight;
			}

			gl_FragColor = S/total_weight;
		}
    ]],
    uniformInt = {
      texture0 = 0,
    },
  })


  if (blurShader_h == nil) then
    Spring.Log(widget:GetInfo().name, LOG.ERROR, "Halo selection widget: hblur shader error: "..gl.GetShaderLog())
    widgetHandler:RemoveWidget()
    return false
  end

  blurShader_v = gl.CreateShader({
    fragment = [[
		uniform sampler2D texture0;
		uniform float inverseRY;
		uniform float fragKernelRadius;
		float bloomSigma = fragKernelRadius / 2.0;

		void main(void) {
			vec2 C0 = vec2(gl_TexCoord[0]);

			vec4 S = texture2D(texture0, C0);
			float weight = 1.0 / (2.50663 * bloomSigma);
			float total_weight = weight;
			S *= weight;
			for (float r = 1.5; r < fragKernelRadius; r += 2.0)
			{
				weight = exp(-((r*r)/(2.0 * bloomSigma * bloomSigma)))/(2.50663 * bloomSigma);
				S += texture2D(texture0, C0 - vec2(0.0, r * inverseRY)) * weight;
				S += texture2D(texture0, C0 + vec2(0.0, r * inverseRY)) * weight;

				total_weight += 2.0 * weight;
			}

			gl_FragColor = S/total_weight;
		}
    ]],
    uniformInt = {
      texture0 = 0,
    },
  })

  if (blurShader_v == nil) then
    Spring.Log(widget:GetInfo().name, LOG.ERROR, "Halo selection widget: vblur shader error: "..gl.GetShaderLog())
    widgetHandler:RemoveWidget()
    return false
  end

  maskApplyShader = gl.CreateShader({
    fragment = [[
      uniform sampler2D tex0;
      uniform sampler2D tex1;

      void main(void) {
		vec2 coord = gl_TexCoord[0].st;
		vec4 haloColor = texture2D(tex0, coord);
		haloColor.a *= texture2D(tex1, coord).a;
        gl_FragColor = haloColor;
      }
    ]],
    uniformInt = {
      tex0 = 0,
      tex1 = 1,
    },
  })

  if (maskApplyShader == nil) then
    Spring.Log(widget:GetInfo().name, LOG.ERROR, "Blurry Halo Selections: mask application shader error: "..gl.GetShaderLog())
    widgetHandler:RemoveWidget()
    return false
  end

  screenXloc  = gl.GetUniformLocation(featherShader_h, 'screenX')
  screenYloc  = gl.GetUniformLocation(featherShader_v, 'screenY')
  thkXloc  = gl.GetUniformLocation(featherShader_h, 'thickness')
  thkYloc  = gl.GetUniformLocation(featherShader_v, 'thickness')
  invRXloc  = gl.GetUniformLocation(blurShader_h, 'inverseRX')
  invRYloc  = gl.GetUniformLocation(blurShader_v, 'inverseRY')
  radiusXloc = gl.GetUniformLocation(blurShader_h, 'fragKernelRadius')
  radiusYloc = gl.GetUniformLocation(blurShader_v, 'fragKernelRadius')
  haloColorloc = gl.GetUniformLocation(maskGenShader, 'color')

  ShowSelectionSquares(false)
end

function widget:ViewResize()
	vsx, vsy = gl.GetViewSizes()
	ivsx = 1/vsx
	ivsy = 1/vsy

	fbo.color0 = nil

	gl.DeleteTextureFBO(blurtex1 or "")
	gl.DeleteTextureFBO(blurtex2 or "")
	gl.DeleteTextureFBO(masktex or "")

	blurtex1 = gl.CreateTexture(vsx,vsy, {
		border = false,
		min_filter = GL.LINEAR,
		mag_filter = GL.LINEAR,
		wrap_s = GL.CLAMP,
		wrap_t = GL.CLAMP,
		fbo = true,
	})

	blurtex2 = gl.CreateTexture(vsx,vsy, {
		border = false,
		min_filter = GL.LINEAR,
		mag_filter = GL.LINEAR,
		wrap_s = GL.CLAMP,
		wrap_t = GL.CLAMP,
		fbo = true,
	})

	masktex = gl.CreateTexture(vsx, vsy, {
		border = false,
		min_filter = GL.LINEAR,
		mag_filter = GL.LINEAR,
		wrap_s = GL.CLAMP,
		wrap_t = GL.CLAMP,
		fbo = true,
	})
  
	if not blurtex1 or not blurtex2 or not masktex then
		Spring.Echo("Blurry Halo Selections: Failed to create offscreen textures!")
		widgetHandler:RemoveWidget()
		return
	end
	
	fbo.color0 = blurtex1
	fbo.color1 = masktex
	fbo.drawbuffers = {GL_COLOR_ATTACHMENT0_EXT, GL_COLOR_ATTACHMENT1_EXT}
end


function widget:Shutdown()
	if (gl.DeleteTextureFBO) then
		gl.DeleteTextureFBO(blurtex1 or "")
		gl.DeleteTextureFBO(blurtex2 or "")
		gl.DeleteTextureFBO(masktex or "")
	end
	
	if (gl.DeleteFBO) then
		gl.DeleteFBO(fbo)
	end

	if (gl.DeleteShader) then
		gl.DeleteShader(maskGenShader or 0)
		gl.DeleteShader(featherShader_h or 0)
		gl.DeleteShader(featherShader_v or 0)
		gl.DeleteShader(blurShader_h or 0)
		gl.DeleteShader(blurShader_v or 0)
		gl.DeleteShader(maskApplyShader or 0)
	end
	
	ShowSelectionSquares(true)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

