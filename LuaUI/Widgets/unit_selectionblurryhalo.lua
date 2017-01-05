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
	'opacity',
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
    value = 14,
  },
  
  opacity = {
    name = 'Outline Opacity',
    desc = 'How bright the outlines appear',
    type = 'number',
    min = 0.05, max = 1.0, step = 0.05,
    value = 0.7,
  },
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local blurtex1
local blurtex2
local masktex

local fbo

local blurShader_h
local blurShader_v
local maskGenShader
local maskApplyShader
local invRXloc, invRYloc
local radiusXloc, radiusYloc
local haloOpacityloc

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
			visibleAllySelUnits[spGetUnitTeam(unitID)][unitID] = true
		end
		if IsUnitInSelectionBox(unitID) then
			visibleBoxed[#visibleBoxed+1] = unitID
		end
	end
	return visibleAllySelUnits, visibleSelected, visibleBoxed
end


local function DrawSelected(visibleAllySelUnits, visibleSelected, visibleBoxed)
	glClear(GL_COLOR_BUFFER_BIT,0,0,0,0)
	
	local featureHoverColor = { 1, 0, 1, 1}
	local myHoverColor 	    = { 0, 1, 1, 1 }
	local allyHoverColor 	= { 0.2, 0.2, 1, 1 }
	local enemyHoverColor   = { 1, 0, 0, 1 }
	local selectColor 	    = { 0, 1, 0, 1}

	glColor(selectColor)
	for i=1,#visibleSelected do
		local unitID = visibleSelected[i]
		glUnit(unitID,true,-1)
	end
	
	for team, data in pairs(visibleAllySelUnits) do
		local r, g, b = Spring.GetTeamColor(teamID)
		glColor(r, g, b, 1)
		for unitID, _ in pairs(data) do
			glUnit(unitID,true,-1)
		end
	end

	glColor(myHoverColor)
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
			glColor(myHoverColor)
		elseif (teamID and Spring.AreTeamsAllied(teamID, Spring.GetMyTeamID()) ) then
			glColor(allyHoverColor)
		else
			glColor(enemyHoverColor)
		end

		glUnit(data, true,-1)
	elseif (pointedType == 'feature') and ValidFeatureID(data) then
		glColor(featureHoverColor)
		glFeature(data, true)
	end
	
	glColor(1,1,1,1)
end

local function maskGen()
	glClear(GL_COLOR_BUFFER_BIT,0,0,0,0)
	glUseShader(maskGenShader)
		glTexRect(-1-0.25/vsx,1+0.25/vsy,1+0.25/vsx,-1-0.25/vsy)
	glUseShader(0)
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
	local visibleAllySelUnits, visibleSelected, visibleBoxed = GetVisibleUnits()
	glActiveFBO(fbo, DrawSelected, visibleAllySelUnits, visibleSelected, visibleBoxed)
	
	glTexture(blurtex1)
	glRenderToTexture(masktex, maskGen)
	glTexture(false)
end

function widget:DrawScreenEffects()
	if Spring.IsGUIHidden() then
		return
	end
	
	local x, y, z = spGetCameraPosition()
	y = math.max(1, y)
	local thickness = options.thickness.value * math.min(1.0, 1500/y)
	
	-- apply blur
	glBlending(false)
	glUseShader(blurShader_h)
		glUniform(invRXloc, ivsx)
		glUniform(radiusXloc, thickness)
		mglRenderToTexture(blurtex2, blurtex1, 1, -1)
	glUseShader(0)
		
	glUseShader(blurShader_v)
		glUniform(invRYloc, ivsy)
		glUniform(radiusYloc, thickness)
		mglRenderToTexture(blurtex1, blurtex2, 1, -1)
	glUseShader(0)
	
	-- apply the halos and mask to the screen
	glBlending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	glTexture(0, blurtex1)
	glTexture(1, masktex)
	glUseShader(maskApplyShader)
		glUniform(haloOpacityloc, options.opacity.value)
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
      uniform sampler2D tex0;

      void main(void) {
        vec4 color = texture2D(tex0, gl_TexCoord[0].st);
        gl_FragColor = vec4(1.0 - max(color.r, max(color.g, color.b)));
      }
    ]],
    uniformInt = {
      tex0 = 0,
    },
  })

  if (maskGenShader == nil) then
    Spring.Log(widget:GetInfo().name, LOG.ERROR, "Halo selection widget: mask generation shader error: "..gl.GetShaderLog())
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

				total_weight += weight;
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

				total_weight += weight;
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
      uniform float opacity;

      void main(void) {
		vec2 coord = gl_TexCoord[0].st;
		vec4 haloColor = texture2D(tex0, coord);
		haloColor.a = max(haloColor.r, max(haloColor.g, haloColor.b)) * opacity;
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

  invRXloc  = gl.GetUniformLocation(blurShader_h, 'inverseRX')
  invRYloc  = gl.GetUniformLocation(blurShader_v, 'inverseRY')
  radiusXloc = gl.GetUniformLocation(blurShader_h, 'fragKernelRadius')
  radiusYloc = gl.GetUniformLocation(blurShader_v, 'fragKernelRadius')
  haloOpacityloc = gl.GetUniformLocation(maskApplyShader, 'opacity')

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
	fbo.drawbuffers = GL_COLOR_ATTACHMENT0_EXT
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
		gl.DeleteShader(blurShader_h or 0)
		gl.DeleteShader(blurShader_v or 0)
		gl.DeleteShader(maskApplyShader or 0)
	end
	
	ShowSelectionSquares(true)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

