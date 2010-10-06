function widget:GetInfo() 
    return { 
        name = "Middle Mouse Scroll",
        desc = "Makes mid click toggle crosshair scroll mode",
        author = "BrainDamage, SirMaverick",
        date = "2010",
        license = "GNU GPL, v2 or later",
        layer = -1000,
        enabled = false
    } 
end 

local active
local hold
local time
local GetCameraState = Spring.GetCameraState
local SetCameraState =  Spring.SetCameraState
local GetModKeyState = Spring.GetModKeyState
local GetConfigInt = Spring.GetConfigInt
local GetConfigString = Spring.GetConfigString
local GetMouseState = Spring.GetMouseState
local IsAboveMiniMap = Spring.IsAboveMiniMap
local WarpMouse = Spring.WarpMouse
local SetMouseCursor = Spring.SetMouseCursor
local glColor = gl.Color
local glBeginEnd = gl.BeginEnd
local glEnable = gl.Enable
local glDisable = gl.Disable
local glLineWidth = gl.LineWidth
local GL_LINES = GL.LINES
local glVertex = gl.Vertex
local tan = math.tan
local camera
local scrollSpeed
local camTime
local vsx, vsy
local mx, my
local overHeadFov
local crossSize
local holdTime = 0.3

function widget:Initialize()
  scrollSpeed = GetConfigInt("OverheadScrollSpeed",0)
  middleClickScrollSpeed = tonumber(GetConfigString("MiddleClickScrollSpeed",0))
  overHeadFov = GetConfigInt("OverheadFOV", 45)
  crossSize = GetConfigInt("CrossSize",0)
  camTime = 0 --? camera's movement "smoothness"
  active = false
  hold = false
  vsx, vsy = widgetHandler:GetViewSizes()
  mx, my = GetMouseState()
end

function widget:ViewResize(viewSizeX, viewSizeY)
  vsx = viewSizeX
  vsy = viewSizeY
end

function widget:MousePress(x, y, button)
  camera = GetCameraState()
  if (camera.name ~=   "ta")    then
    active = false
    return false
  end
  time = Spring.GetTimer()
  if button ~= 2 or IsAboveMiniMap(x,y) then
    return false
  else
    if not active then
      hold = true
    end
    return true
  end
end


function widget:MouseRelease(x, y, button)
  camera = GetCameraState()
  if (camera.name ~=   "ta")    then
    active = false
  end
  if button ~= 2 then
    return false
  end

  if Spring.DiffTimers(Spring.GetTimer(), time) < holdTime or active then
    active = not active
    if not active then
      hold = false
    end
    return true
  end
  if hold then
    hold = false
    return true
  end
  return false
end

local function CrossHairMove( dx, dy )
  camera = GetCameraState()
  if (camera.name ~=   "ta")    then
    return false
  end
  if camera.flipped then
    dx = -dx
    dy = -dy
  end
  local _,_,shift = GetModKeyState()
  local speedMultiplier = 0.1
  if shift then
    speedMultiplier = speedMultiplier * 4
  end
  dx = dx * 100 * middleClickScrollSpeed
  dy = dy * 100 * middleClickScrollSpeed
  -- the following number is wrong if  we're in the mid of a camera transition, but I think no one sane would use it in such case 
  -- and the logic would be too complicated to replicate there
  local halfFov = overHeadFov * 0.008726646
  local tanHalfFov = tan(halfFov)
  local pixelsize =  tanHalfFov * 2/vsy * camera.height * 2
  camera.px = camera.px + dx * pixelsize * speedMultiplier * scrollSpeed
  camera.pz = camera.pz + dy * pixelsize * speedMultiplier * scrollSpeed
  -- move camera 
  SetCameraState(camera, camTime)
end

local function DrawCrosshair()
  if crossSize > 0 then
    glColor(1.0, 1.0, 1.0, 0.5)
    glLineWidth(1.49)
    glBeginEnd(GL_LINES, function() 
      glVertex(vsx/2 - crossSize, vsy/2)
      glVertex(vsx/2 + crossSize, vsy/2)
      glVertex(vsx/2, vsy/2 - crossSize)
      glVertex(vsx/2, vsy/2 + crossSize)
    end)
    glLineWidth(1.0)
  end
end

function widget:DrawScreen()
  if active then
    DrawCrosshair()
    --FIXME: does not work atm
    SetMouseCursor( "none" ) -- set no mouse cursor
  end
end

function widget:Update()
  local x, y = GetMouseState()
  crossSize = GetConfigInt("CrossSize",0)
  if active or hold then
    -- spring origins for mouse are bottom right, therefore y coordinate is reversed
    CrossHairMove( mx - x,  y - my )
    -- center mouse 
    WarpMouse(vsx/2, vsy/2)
    x = vsx / 2
    y = vsy / 2
  end
  mx = x
  my = y
end
