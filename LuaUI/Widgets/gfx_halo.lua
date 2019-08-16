-- $Id: gfx_halo.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    gfx_halo.lua
--  brief:
--  author:  jK
--
--  Copyright (C) 2008.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Halo",
    desc      = "Shows a halo in teamcolors around units. (Doesn't work on ati cards!)",
    author    = "jK",
    date      = "Jan, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = -10,
    enabled   = false  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--// user var

local gAlpha = 0.7

local limitToCommanders = false
local limitToWorkers    = false

--// app var

local offscreentex
local depthtex
local blurtex
local fbo

local blurShader_h
local blurShader_v
local uniformScreenX, uniformScreenY

local vsx, vsy = 0,0
local resChanged = false

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
local GetVisibleUnits = Spring.GetVisibleUnits
local GetUnitTeam     = Spring.GetUnitTeam

local GL_FRONT = GL.FRONT
local GL_BACK  = GL.BACK
local GL_MODELVIEW  = GL.MODELVIEW
local GL_PROJECTION = GL.PROJECTION
local GL_COLOR_BUFFER_BIT = GL.COLOR_BUFFER_BIT

local glUnit            = gl.Unit
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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
  if (not gl.CreateShader)or(not gl.CreateFBO) then
    Spring.Echo("Halo widget: your card is unsupported!")
    widgetHandler:RemoveWidget()
    return
  end

  vsx, vsy = widgetHandler:GetViewSizes()

  blurShader_h = gl.CreateShader({
    fragment = [[
      float kernel[7]; // = float[7]( 0.013, 0.054, 0.069, 0.129, 0.212, 0.301, 0.372);
      uniform sampler2D tex0;
      uniform int screenX;

      void InitKernel(void) {
        kernel[0] = 0.013;
        kernel[1] = 0.054;
        kernel[2] = 0.069;
        kernel[3] = 0.129;
        kernel[4] = 0.212;
        kernel[5] = 0.301;
        kernel[6] = 0.372;
      }

      void main(void) {
        InitKernel();

        int n;
        float pixelsize = 1.0/float(screenX);

        gl_FragColor = 0.4 * texture2D(tex0, gl_TexCoord[0].st );

        vec2 tc1 = gl_TexCoord[0].st;
        vec2 tc2 = gl_TexCoord[0].st;

        for(n=6; n>= 0; --n){
          tc1.s += pixelsize;
          tc2.s -= pixelsize;
          gl_FragColor += kernel[n] * ( texture2D(tex0, tc1 )+texture2D(tex0, tc2 ) );
        }
      }
    ]],
    uniformInt = {
      tex0 = 0,
      screenX = math.ceil(vsx*0.5),
    },
  })


  if (blurShader_h == nil) then
    Spring.Log(widget:GetInfo().name, LOG.ERROR, "Halo widget: hblur shader error: "..gl.GetShaderLog())
    widgetHandler:RemoveWidget()
    return false
  end

  blurShader_v = gl.CreateShader({
    fragment = [[
      float kernel[7]; // = float[7]( 0.013, 0.054, 0.069, 0.129, 0.212, 0.301, 0.372);
      uniform sampler2D tex0;
      uniform int screenY;

      void InitKernel(void) {
        kernel[0] = 0.013;
        kernel[1] = 0.054;
        kernel[2] = 0.069;
        kernel[3] = 0.129;
        kernel[4] = 0.212;
        kernel[5] = 0.301;
        kernel[6] = 0.372;
      }

      void main(void) {
        InitKernel();

        int n;
        float pixelsize = 1.0/float(screenY);

        gl_FragColor = 0.4 * texture2D(tex0, gl_TexCoord[0].st );

        vec2 tc1 = gl_TexCoord[0].st;
        vec2 tc2 = gl_TexCoord[0].st;

        for(n=6; n>= 0; --n){
          tc1.t += pixelsize;
          tc2.t -= pixelsize;
          gl_FragColor += kernel[n] * ( texture2D(tex0, tc1 )+texture2D(tex0, tc2 ) );
        }
      }
    ]],
    uniformInt = {
      tex0 = 0,
      screenY = math.ceil(vsy*0.5),
    },
  })

  if (blurShader_v == nil) then
    Spring.Log(widget:GetInfo().name, LOG.ERROR, "Halo widget: vblur shader error: "..gl.GetShaderLog())
    widgetHandler:RemoveWidget()
    return false
  end

  uniformScreenX  = gl.GetUniformLocation(blurShader_h, 'screenX')
  uniformScreenY  = gl.GetUniformLocation(blurShader_v, 'screenY')

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
    glTexture(false)
    glUseShader(0)
  end)
end

function widget:ViewResize(viewSizeX, viewSizeY)
  vsx = viewSizeX
  vsy = viewSizeY

  fbo.color0 = nil

  gl.DeleteTexture(depthtex or 0)
  gl.DeleteTextureFBO(offscreentex or 0)
  gl.DeleteTextureFBO(blurtex or 0)

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
  end

  if (gl.DeleteFBO) then
    gl.DeleteFBO(fbo)
  end

  if (gl.DeleteShader) then
    gl.DeleteShader(blurShader_h or 0)
    gl.DeleteShader(blurShader_v or 0)
  end

  gl.DeleteList(enter2d)
  gl.DeleteList(leave2d)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local teamColors = {}
local function SetTeamColor(teamID)
  local teamColor = teamColors[teamID]
  if (teamColor) then glColor(teamColor) return end
  teamColors[teamID] = {Spring.GetTeamColor(teamID)}
  glColor(teamColors[teamID])
end

local function DrawVisibleUnitsAll()
  local visibleUnits = GetVisibleUnits(ALL_UNITS,nil,true)
  for i=1,#visibleUnits do
    local unitID = visibleUnits[i]
    SetTeamColor(GetUnitTeam(unitID))
    glUnit(unitID,true)
  end
end

local function DrawVisibleUnitsLimited()
  local teams = Spring.GetTeamList()
  for _,teamID in ipairs(teams) do
    glColor(Spring.GetTeamColor(teamID))
    teamUnits = Spring.GetTeamUnitsSorted(teamID)
	teamUnits.n = nil -- REMOVE IN 0.83
    for unitDefID,unitIDs in pairs(teamUnits) do
      local UnitDef = UnitDefs[unitDefID]

      if (limitToCommanders and UnitDef.customParams.commtype)or
         (limitToWorkers and UnitDef.isBuilder)
      then
        for _,unitID in ipairs(unitIDs) do
          local losState = Spring.GetUnitLosState(unitID)
          if (Spring.IsUnitInView(unitID))and(((losState)and(losState.los))or(true)) then
            glUnit(unitID,true)
          end
        end
      end

    end
  end
end

local DrawVisibleUnits
if (limitToCommanders or limitToWorkers) then
  DrawVisibleUnits = DrawVisibleUnitsLimited
else
  DrawVisibleUnits = DrawVisibleUnitsAll
end


local MyDrawVisibleUnits = function()
  glClear(GL_COLOR_BUFFER_BIT,0,0,0,0)
  --glCulling(GL_FRONT)
  DrawVisibleUnits()
  --glCulling(GL_BACK)
  --glCulling(false)
  glColor(1,1,1,1)
end
local blur_h = function()
  glClear(GL_COLOR_BUFFER_BIT,0,0,0,0)
  glUseShader(blurShader_h)
  glTexRect(-1-0.25/vsx,1+0.25/vsy,1+0.25/vsx,-1-0.25/vsy)
end
local blur_v = function()
  --glClear(GL_COLOR_BUFFER_BIT,0,0,0,0)
  glUseShader(blurShader_v)
  glTexRect(-1-0.25/vsx,1+0.25/vsy,1+0.25/vsx,-1-0.25/vsy)
end

function widget:DrawWorldPreUnit()
  glCopyToTexture(depthtex, 0, 0, 0, 0, vsx, vsy)

  if (resChanged) then
    resChanged = false
    if (vsx==1) or (vsy==1) then return end
     glUseShader(blurShader_h)
    glUniformInt(uniformScreenX,  math.ceil(vsx*0.5) )
     glUseShader(blurShader_v)
    glUniformInt(uniformScreenY,  math.ceil(vsy*0.5) )
  end

  glDepthTest(true)
  glActiveFBO(fbo,MyDrawVisibleUnits)
  glDepthTest(false)

  glTexture(offscreentex)
  glRenderToTexture(blurtex, blur_h)
  glTexture(blurtex)
  glRenderToTexture(offscreentex, blur_v)
  glColor(1,1,1,gAlpha)

  glCallList(enter2d)
  glTexture(offscreentex)
  glTexRect(-1-0.5/vsx,1+0.5/vsy,1+0.5/vsx,-1-0.5/vsy)
  glCallList(leave2d)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
