--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    gui_xray_shader.lua
--  brief:   xray shader
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "XrayShader",
    desc      = "XrayShader",
    author    = "trepan",
    date      = "Jul 15, 2007", --March 2nd, 2013
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

options_path = 'Settings/Graphics/Unit Visibility/XRay Shader'
options = {
        zMin = {
                name = 'Minimum distance',
                desc = 'Minimum distance for XRay effect to show up',
                type = 'number',
                min = 0, max = 10000, step = 100,
                value = 1200,
        },
        zMax = {
                name = 'Maximum distance',
                desc = 'Distance at which XRay effect is at full strength',
                type = 'number',
                min = 0, max = 10000, step = 100,
                value = 4200,
        },
}

local zMin = 1200
local zMax = 4200

local function OnchangeFunc()
        zMin              = options.zMin.value
        zMax              = options.zMax.value
end
for key,option in pairs(options) do
        option.OnChange = OnchangeFunc
end
OnchangeFunc()
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local GL_ONE                 = GL.ONE
local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA
local GL_SRC_ALPHA           = GL.SRC_ALPHA
local glBlending             = gl.Blending
local glColor                = gl.Color
local glCreateShader         = gl.CreateShader
local glDeleteShader         = gl.DeleteShader
local glDepthTest            = gl.DepthTest
local glFeature              = gl.Feature
local glGetShaderLog         = gl.GetShaderLog
local glPolygonOffset        = gl.PolygonOffset
local glSmoothing            = gl.Smoothing
local glUnit                 = gl.Unit
local glUseShader            = gl.UseShader
local spEcho                 = Spring.Echo
local spGetAllFeatures       = Spring.GetAllFeatures
local spGetTeamColor         = Spring.GetTeamColor
local spGetTeamList          = Spring.GetTeamList
local spGetTeamUnits         = Spring.GetTeamUnits
local spIsUnitVisible        = Spring.IsUnitVisible
local spIsUnitIconic         = Spring.IsUnitIconic


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not glCreateShader) then
  spEcho("Hardware is incompatible with Xray shader requirements")
  return false
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  simple configuration parameters
--

local edgeExponent = 2.5

local doFeatures = false

local featureColor = { 1, 0, 1 }

-- looks a lot nicer, esp. without FSAA  (but eats into the FPS too much)
local smoothPolys = glSmoothing and true


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local shader

local shaderFragZMinLoc = nil
local shaderFragZMaxLoc = nil


function widget:Shutdown()
  glDeleteShader(shader)
end


function widget:Initialize()

  shader = glCreateShader({

    uniform = {
      edgeExponent = edgeExponent,
      fragZMin = zMin,
      fragZMax = zMax,
    },

    vertex = [[
      // Application to vertex shader
      varying vec3 normal;
      varying vec3 eyeVec;
      varying vec3 color;
      varying vec3 position;
      uniform mat4 camera;
      uniform mat4 caminv;

      void main()
      {
        vec4 P = gl_ModelViewMatrix * gl_Vertex;
              
        eyeVec = P.xyz;
              
        normal  = gl_NormalMatrix * gl_Normal;
              
        color = gl_Color.rgb;
              
        gl_Position = gl_ProjectionMatrix * P;
        position = gl_Position;
      }
    ]],
 
    fragment = [[
      varying vec3 normal;
      varying vec3 eyeVec;
      varying vec3 color;
      varying vec3 position;

      uniform float edgeExponent;
      uniform float fragZMin;
      uniform float fragZMax;

      void main()
      {
        float opac = dot(normalize(normal), normalize(eyeVec));
        opac = (1.0 - abs(opac));
        opac = pow(opac, edgeExponent) * clamp((position.z - fragZMin) / max(fragZMax - fragZMin,0.01),0.0,1.0);
          
        gl_FragColor.rgb = color;
        gl_FragColor.a = opac;
      }
    ]],
  })

  if (shader == nil) then
    Spring.Log(widget:GetInfo().name, LOG.ERROR, glGetShaderLog())
    spEcho("Xray shader compilation failed.")
    widgetHandler:RemoveWidget()
  end

  shaderFragZMinLoc = gl.GetUniformLocation(shader, "fragZMin")
  shaderFragZMaxLoc = gl.GetUniformLocation(shader, "fragZMax")
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function DrawWorldFunc()
  if (smoothPolys) then
    glSmoothing(nil, nil, true)
  end

  glColor(1, 1, 1, 1)

  glUseShader(shader)

  glDepthTest(true)

  glBlending(GL_SRC_ALPHA, GL_ONE)

  glPolygonOffset(-2, -2)

  gl.Uniform(shaderFragZMinLoc, zMin)
  gl.Uniform(shaderFragZMaxLoc, zMax)

  for _, teamID in ipairs(spGetTeamList()) do
    glColor(spGetTeamColor(teamID))
    for _, unitID in ipairs(spGetTeamUnits(teamID)) do
      if (spIsUnitVisible(unitID, nil, true)) then
        glUnit(unitID, true)
      end
    end
  end

  if (doFeatures) then
    glColor(featureColor)
    for _, featureID in ipairs(spGetAllFeatures()) do
      glFeature(featureID, true)
    end
  end

  glPolygonOffset(false)

  glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

  glDepthTest(false)

  glUseShader(0)

  glColor(1, 1, 1, 1)

  if (smoothPolys) then
    glSmoothing(nil, nil, false)
  end
end

function widget:DrawWorld()
  DrawWorldFunc()
end
              
function widget:DrawWorldRefraction()
  local oldZMin, oldZMax = zMin, zMax
  zMin, zMax = zMin/1.2, zMax/1.2
  DrawWorldFunc()
  zMin, zMax = oldZMin, oldZMax
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
