--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Highlight",
    desc      = "Draws colored circles around specified Chili elements",
    author    = "KingRaptor",
    date      = "2017.01.15",
    license   = "GNU GPL, v2 or later",
    layer     = -math.huge,
    enabled   = true,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local WHITE = {1,1,1}

local Chili

local circleDrawList

local controls = {} -- [control name] = {control = control, color = color}
local alpha = 1
local timer = 0
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function AddControl(name, color, width)
  controls[name] = {control = Chili.Screen0:GetObjectByName(name), color = color, width = width}
end

local function RemoveControl(name)
  controls[name] = nil
end

-- from gfx_commands_fx.lua
local function CircleVertices(circleDivs)
  for i = 1, circleDivs do
    local theta = 2 * math.pi * i / circleDivs
    gl.Vertex(math.cos(theta), math.sin(theta), 0)
  end
end

local function DrawCircle(control, color, width)
  local x, y = control:LocalToScreen(0, 0)
  y = Chili.Screen0.height - y
  y = y - control.height/2
  x = x + control.width/2
  gl.LineWidth(width)
  --Spring.Echo(x, y)
  gl.PushMatrix()
  gl.Translate(x, y, 0)
  gl.Scale(control.width/2, control.height/2, 1)
  --gl.Rotate(90, 0, 0, 0)
  gl.Color(color[1], color[2], color[3], alpha)
  gl.CallList(circleDrawList)
  gl.PopMatrix()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:DrawScreen()
  gl.LineStipple(true)
  for name, data in pairs(controls) do
    local control = data.control
    if control and (not control.disposed) then
      if control.visible then
        DrawCircle(control, data.color or WHITE, data.width or 4)
      end
    else
      RemoveControl(name)
    end
  end
  gl.LineWidth(1)
  gl.LineStipple(false)
  gl.Color(1,1,1,1)
end

function widget:Update(dt)
  timer = timer + dt * 2
  alpha = 0.6 + 0.25*math.sin(timer)
end

function widget:Initialize()
  Chili = WG.Chili
  
  WG.ChiliHighlight = {
    AddControl = AddControl,
    RemoveControl = RemoveControl
  }
  
  circleDrawList = gl.CreateList(gl.BeginEnd, GL.LINE_LOOP, CircleVertices, 18)
end


function widget:Shutdown()
  WG.ChiliHighlight = nil
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------