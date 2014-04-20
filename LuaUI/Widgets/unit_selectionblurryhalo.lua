--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Selection BlurryHalo",
    desc      = "Shows a halo for selected, hovered ally-selected units. (Doesn't work on ati cards!)",
    author    = "CarRepairer, from jK's gfx_halo",
    date      = "Jan, 2008",
    version   = "0.004",
    license   = "GNU GPL, v2 or later",
    layer     = -11,
    enabled   = false  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local showAlly = false
local visibleAllySelUnits = {}
local visibleSelected = {}
local thickness = 1.0

local function UpdateHaloColors(self) end

options_path = 'Settings/Interface/Selection/Blurry Halo Selections'

options_order = {
	'showally',
	'useteamcolors',
	'thickness',

	
	'lblPresetColors',
	'selectColor',
	'allySelectColor',
	'myHoverColor',
	'allyHoverColor',
	'enemyHoverColor',
	'featureHoverColor',
	
	
}

options = {
	showally = {
		name = 'Show Ally Selections',
		type = 'bool',
		desc = 'Highlight the units your allies currently have selected.',
		value = true,
		OnChange = function(self) 
			visibleAllySelUnits = {}
			showAlly = self.value
		end,
	},
	useteamcolors = {
		name = 'Use Team Colors',
		type = 'bool',
		desc = 'Highlight your allies\' selections with their team colors instead of the preset colors.',
		value = false,
	},

	thickness = {
    name = 'Outline Thickness',
    desc = 'How thick the outline appears around objects',
    type = 'number',
    min = 0.4, max = 2, step = 0.01,
    value = 0.8,
    OnChange = function(self) UpdateHaloColors(); end
  },
	-----
	
	lblPresetColors = {type='label', name = 'Preset Colors' },
	selectColor = {
		name = 'Selected Units Color',
		type = 'colors',
		value = { 0.1, 1, 0.25, 1 },
		OnChange = function(self) UpdateHaloColors(); end
	},
	
	allySelectColor = {
		name = 'Ally Selected Units Color',
		type = 'colors',
		value = { 1, 1, 0.25, 1 },
		OnChange = function(self) UpdateHaloColors(); end
	}, 
	
	myHoverColor = {
		name = 'My Unit Hover Color',
		type = 'colors',
		value = { 0.3, 1, 1, 1 },
		OnChange = function(self) UpdateHaloColors(); end
	},
	
	allyHoverColor = {
		name = 'Ally Unit Hover Color',
		type = 'colors',
		value = { 0.2, 0.2, 1, 1 },
		OnChange = function(self) UpdateHaloColors(); end
	}, 
	
	enemyHoverColor = {
		name = 'Enemy Unit Hover Color',
		type = 'colors',
		value = { 1, 0.3, 0.2, 1 },
		OnChange = function(self) UpdateHaloColors(); end
	}, 
	
	
	featureHoverColor = {
		name = 'Feature Hover Color',
		type = 'colors',
		value = { 1, 0.25, 1, 1 },
		OnChange = function(self) UpdateHaloColors(); end
	}, 
	
	
	
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--// user var

local gAlpha = 0.8

--// app var

local offscreentex
local outlinemasktex
local depthtex
local blurtex
local fbo

local blurShader_h
local blurShader_v
local maskGenShader
local maskApplyShader
local uniformScreenX, uniformScreenY
local uniformThicknessX, uniformThicknessY

local vsx, vsy = 0,0
local resChanged = false


--more
local featureHoverColor = { 1, 0, 1, 1}
local myHoverColor 	    = { 0, 1, 1, 1 }
local allyHoverColor 	= { 0.2, 0.2, 1, 1 }
local enemyHoverColor   = { 1, 0, 0, 1 }
local selectColor 	    = { 0, 1, 0, 1 }
local allySelectColor 	= { 1, 1, 0, 1 }

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--// gl const

local GL_DEPTH_BITS = 0x0D56

local GL_DEPTH_COMPONENT   = 0x1902
local GL_DEPTH_COMPONENT16 = 0x81A5
local GL_DEPTH_COMPONENT24 = 0x81A6
local GL_DEPTH_COMPONENT32 = 0x81A7

local GL_COLOR_ATTACHMENT0_EXT = 0x8CE0
local GL_COLOR_ATTACHMENT1_EXT = 0x8CE1
local GL_COLOR_ATTACHMENT2_EXT = 0x8CE2
local GL_COLOR_ATTACHMENT3_EXT = 0x8CE3

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
local spGetPlayerControlledUnit		= Spring.GetPlayerControlledUnit
local spGetVisibleUnits			= Spring.GetVisibleUnits
local spIsUnitIcon = Spring.IsUnitIcon

--local myPlayerID = Spring.GetMyPlayerID()

local GL_FRONT = GL.FRONT
local GL_BACK  = GL.BACK
local GL_MODELVIEW  = GL.MODELVIEW
local GL_PROJECTION = GL.PROJECTION
local GL_COLOR_BUFFER_BIT = GL.COLOR_BUFFER_BIT
local GL_DEPTH_BUFFER_BIT = GL.DEPTH_BUFFER_BIT

local glUnit            = gl.Unit
local glFeature         = gl.Feature
local glCopyToTexture   = gl.CopyToTexture
local glRenderToTexture = gl.RenderToTexture
local glCallList        = gl.CallList
local glActiveFBO       = gl.ActiveFBO

local glUseShader  = gl.UseShader
local glUniform    = gl.Uniform
local glUniformInt = gl.UniformInt

local glClear     = gl.Clear
local glTexRect   = gl.TexRect
local glColor     = gl.Color
local glTexture   = gl.Texture
local glCulling   = gl.Culling
local glDepthTest = gl.DepthTest

local glResetMatrices = gl.ResetMatrices
local glMatrixMode    = gl.MatrixMode
local glPushMatrix    = gl.PushMatrix
local glLoadIdentity  = gl.LoadIdentity
local glPopMatrix     = gl.PopMatrix
local glBlending      = gl.Blending

local echo = Spring.Echo

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--functions

UpdateHaloColors = function(self)
	selectColor = options.selectColor.value
	allySelectColor = options.allySelectColor.value
	myHoverColor = options.myHoverColor.value
	
	allyHoverColor = options.allyHoverColor.value
	enemyHoverColor = options.enemyHoverColor.value
	featureHoverColor = options.featureHoverColor.value

  thickness = options.thickness.value
end

local function GetVisibleUnits()
  local units = spGetVisibleUnits(-1, 30, false)
    
	local visibleAllySelUnits = {}
    local visibleSelected = {}
    
    for i=1, #units do
	    local unitID = units[i]
	    if (spIsUnitSelected(unitID)) then
		    visibleSelected[#visibleSelected+1] = unitID
	    elseif showAlly and WG.allySelUnits and WG.allySelUnits[unitID] then
		    visibleAllySelUnits[#visibleAllySelUnits+1] = unitID
	    end
    end
    
    return visibleAllySelUnits, visibleSelected

end


local function DrawHaloFunc()
	visibleAllySelUnits, visibleSelected = GetVisibleUnits()

	glColor(selectColor)
	for i=1,#visibleSelected do
		local unitID = visibleSelected[i]
		glUnit(unitID,true)
	end
    
	if not options.useteamcolors.value then glColor(allySelectColor) end
	for i=1,#visibleAllySelUnits do
		local unitID = visibleAllySelUnits[i]
		if options.useteamcolors.value then
			local teamID = spGetUnitTeam(unitID)
			if teamID then
        local r, g, b = Spring.GetTeamColor(teamID);
				glColor(r, g, b, allySelectColor[4])
			else
				glColor(allySelectColor)
			end
		end
		glUnit(unitID,true)
	end
    
	local mx, my = spGetMouseState()
    local pointedType, data = spTraceScreenRay(mx, my)
	if pointedType == 'unit' and spValidUnitID(data) then -- and not spIsUnitIcon(data) then
		local teamID = spGetUnitTeam(data)
		if teamID == spGetMyTeamID() then
			glColor(myHoverColor)
		elseif (teamID and Spring.AreTeamsAllied(teamID, Spring.GetMyTeamID()) ) then
			glColor(allyHoverColor)
		else
			glColor(enemyHoverColor)
		end
		
		glUnit(data, true)
    elseif (pointedType == 'feature') and ValidFeatureID(data) then
		glColor(featureHoverColor)
		glFeature(data, true)
    end
  
end

local DrawVisibleUnits

DrawVisibleUnits = DrawHaloFunc

local MyDrawVisibleUnits = function()
  glClear(GL_COLOR_BUFFER_BIT,0,0,0,0)
  -- glClear(GL_DEPTH_BUFFER_BIT)
  --glCulling(GL_FRONT)
  DrawVisibleUnits()
  --glCulling(GL_BACK)
  --glCulling(false)
  glColor(1,1,1,1)
end
local maskGen = function()
  glClear(GL_COLOR_BUFFER_BIT,0,0,0,0)
  glUseShader(maskGenShader)
  glTexRect(-1-0.25/vsx,1+0.25/vsy,1+0.25/vsx,-1-0.25/vsy)
  --glTexRect(-1-1/vsx,1+1/vsy,1+1/vsx,-1-1/vsy)
end
local blur_h = function()
  glClear(GL_COLOR_BUFFER_BIT,0,0,0,0)
  glUseShader(blurShader_h)
    glUniform(uniformThicknessX, thickness)
  glTexRect(-1-0.25/vsx,1+0.25/vsy,1+0.25/vsx,-1-0.25/vsy)
  --glTexRect(-1-1/vsx,1+1/vsy,1+1/vsx,-1-1/vsy)
end
local blur_v = function()
  --glClear(GL_COLOR_BUFFER_BIT,0,0,0,0)
  glUseShader(blurShader_v)
    glUniform(uniformThicknessY, thickness)
  glTexRect(-1-0.25/vsx,1+0.25/vsy,1+0.25/vsx,-1-0.25/vsy)
  --glTexRect(-1-1/vsx,1+1/vsy,1+1/vsx,-1-1/vsy)
end

function widget:DrawWorldPreUnit()
  if Spring.IsGUIHidden() then
	return
  end
  -- glCopyToTexture(depthtex, 0, 0, 0, 0, vsx, vsy)

  glBlending(true)
  
  if (resChanged) then
    resChanged = false
    if (vsx==1) or (vsy==1) then return end
     glUseShader(blurShader_h)
    glUniformInt(uniformScreenX,  vsx )
     glUseShader(blurShader_v)
    glUniformInt(uniformScreenY,  vsy )
  end

  glDepthTest(GL.GEQUAL)
  glActiveFBO(fbo,MyDrawVisibleUnits)
  glDepthTest(false)

  glTexture(offscreentex)
  glRenderToTexture(outlinemasktex, maskGen)
  glRenderToTexture(blurtex, blur_h)
  glTexture(blurtex)
  glRenderToTexture(offscreentex, blur_v)
  
  glBlending(false)
end

function widget:DrawScreenEffects()
  if Spring.IsGUIHidden() then
  return
  end
  glBlending(true)

  glColor(1,1,1,gAlpha)

  glCallList(enter2d)
  glTexture(0, offscreentex)
  glTexture(1, outlinemasktex)
  glUseShader(maskApplyShader)
  glTexRect(-1-0.25/vsx,1+0.25/vsy,1+0.25/vsx,-1-0.25/vsy) --this line breaks mearth labels
  glCallList(leave2d)
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
--call ins

function widget:Initialize()
	showAlly = options.showally.value 
	
  if (not gl.CreateShader)or(not gl.CreateFBO) then
    Spring.Echo("Halo widget: your card is unsupported!")
    widgetHandler:RemoveWidget()
    return
  end

  vsx, vsy = widgetHandler:GetViewSizes()

  maskGenShader = gl.CreateShader({
    fragment = [[
      uniform sampler2D tex0;

      void main(void) {
        vec4 color = texture2D(tex0, gl_TexCoord[0].st);
        gl_FragColor = vec4(1.0 - ((color.r + color.g + color.b) * 255.0));
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
      uniform sampler2D tex0;
      uniform int screenX;
      uniform float thickness;

      void main(void) {
        vec2 texCoord  = vec2(gl_TextureMatrix[0] * gl_TexCoord[0]);
        gl_FragColor = vec4(0.0);

        float pixelsize = thickness/float(screenX);
        gl_FragColor += 0.6 * texture2D(tex0, vec2(texCoord.s + 2.0*pixelsize,texCoord.t) );
        gl_FragColor += 0.7 * texture2D(tex0, vec2(texCoord.s + pixelsize,texCoord.t) );

        gl_FragColor += texture2D(tex0, texCoord );

        gl_FragColor += 0.7 * texture2D(tex0, vec2(texCoord.s - 1.0*pixelsize,texCoord.t) );
        gl_FragColor += 0.6 * texture2D(tex0, vec2(texCoord.s - 2.0*pixelsize,texCoord.t) );

        gl_FragColor.rgb /= max(max(gl_FragColor.r, gl_FragColor.g), max(gl_FragColor.b, 1.0));
      }
    ]],
    uniformInt = {
      tex0 = 0,
      screenX = vsx,
    },
    uniformFloat = {
      thickness = 1.0,
    },
  })


  if (blurShader_h == nil) then
    Spring.Log(widget:GetInfo().name, LOG.ERROR, "Halo selection widget: hblur shader error: "..gl.GetShaderLog())
    widgetHandler:RemoveWidget()
    return false
  end

  blurShader_v = gl.CreateShader({
    fragment = [[      uniform sampler2D tex0;
      uniform int screenY;
      uniform float thickness;

      void main(void) {
        vec2 texCoord  = vec2(gl_TextureMatrix[0] * gl_TexCoord[0]);
        gl_FragColor = vec4(0.0);

        float pixelsize = thickness/float(screenY);
        gl_FragColor += 0.6 * texture2D(tex0, vec2(texCoord.s,texCoord.t + 2.0*pixelsize) );
        gl_FragColor += 0.7 * texture2D(tex0, vec2(texCoord.s,texCoord.t + pixelsize) );

        gl_FragColor += texture2D(tex0, texCoord );

        gl_FragColor += 0.7 * texture2D(tex0, vec2(texCoord.s,texCoord.t - 1.0*pixelsize) );
        gl_FragColor += 0.6 * texture2D(tex0, vec2(texCoord.s,texCoord.t - 2.0*pixelsize) );

        gl_FragColor.rgb /= max(max(gl_FragColor.r, gl_FragColor.g), max(gl_FragColor.b, 1.0));
      }
    ]],
    uniformInt = {
      tex0 = 0,
      screenY = vsy,
    },
    uniformFloat = {
      thickness = 1.0,
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
        gl_FragColor = texture2D(tex0, gl_TexCoord[0].st) * texture2D(tex1, gl_TexCoord[0].st);
      }
    ]],
    uniformInt = {
      tex0 = 0,
      tex1 = 1,
    },
  })

  if (maskApplyShader == nil) then
    Spring.Log(widget:GetInfo().name, LOG.ERROR, "Halo selection widget: mask application shader error: "..gl.GetShaderLog())
    widgetHandler:RemoveWidget()
    return false
  end

  uniformScreenX  = gl.GetUniformLocation(blurShader_h, 'screenX')
  uniformScreenY  = gl.GetUniformLocation(blurShader_v, 'screenY')
  uniformThicknessX = gl.GetUniformLocation(blurShader_h, 'thickness')
  uniformThicknessY = gl.GetUniformLocation(blurShader_v, 'thickness')

  fbo = gl.CreateFBO()

  self:ViewResize(vsx,vsy)

  enter2d = gl.CreateList(function()
    glUseShader(0)
    glMatrixMode(GL_PROJECTION); glPushMatrix(); glLoadIdentity()
    glMatrixMode(GL_MODELVIEW);  glPushMatrix(); glLoadIdentity()
  end)
  leave2d = gl.CreateList(function()
    glMatrixMode(GL_PROJECTION); glPopMatrix()
    glMatrixMode(GL_MODELVIEW);  glPopMatrix()
    glTexture(0, false)
    glTexture(1, false)
    glUseShader(0)
  end)
  
  
  ShowSelectionSquares(false)
end --init

function widget:ViewResize(viewSizeX, viewSizeY)
  vsx = viewSizeX
  vsy = viewSizeY

  fbo.color0 = nil

  gl.DeleteTexture(depthtex or 0)
  gl.DeleteTextureFBO(offscreentex or 0)
  gl.DeleteTextureFBO(blurtex or 0)
  gl.DeleteTextureFBO(outlinemasktex or 0)

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
  })

  outlinemasktex = gl.CreateTexture(vsx,vsy, {
    border = false,
    min_filter = GL.LINEAR,
    mag_filter = GL.LINEAR,
    wrap_s = GL.CLAMP,
    wrap_t = GL.CLAMP,
    fbo = true,
  })

  blurtex = gl.CreateTexture(math.floor(vsx*0.5),math.floor(vsy*0.5), {
    border = false,
    min_filter = GL.LINEAR,
    mag_filter = GL.LINEAR,
    wrap_s = GL.CLAMP,
    wrap_t = GL.CLAMP,
    fbo = true,
  })

  fbo.depth  = depthtex
  fbo.color0 = offscreentex
  fbo.drawbuffers = GL_COLOR_ATTACHMENT0_EXT

  resChanged = true
end


function widget:Shutdown()
  gl.DeleteTexture(depthtex)
  if (gl.DeleteTextureFBO) then
    gl.DeleteTextureFBO(offscreentex)
    gl.DeleteTextureFBO(blurtex)
    gl.DeleteTextureFBO(outlinemasktex)
  end

  if (gl.DeleteFBO) then
    gl.DeleteFBO(fbo or 0)
  end

  if (gl.DeleteShader) then
    gl.DeleteShader(maskGenShader or 0)
    gl.DeleteShader(blurShader_h or 0)
    gl.DeleteShader(blurShader_v or 0)
    gl.DeleteShader(maskApplyShader or 0)
  end

  gl.DeleteList(enter2d)
  gl.DeleteList(leave2d)
  
    ShowSelectionSquares(true)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

