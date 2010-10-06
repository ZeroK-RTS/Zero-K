function widget:GetInfo()
  return {
    name      = "Test Version Warning",
    desc      = "Shows a warning that you are not playing the stable version.",
    author    = "SirMaverick",
    date      = "09.09.2009",
    license   = "GNU GPL, v2 or later",
    layer     = 100,
    enabled   = true
  }
end

local glColor	       = gl.Color
local glRect           = gl.Rect
local glText           = gl.Text
local glGetTextWidth   = gl.GetTextWidth
local glGetTextHeight  = gl.GetTextHeight
local spGetGameSeconds = Spring.GetGameSeconds

local GetGameSeconds = Spring.GetGameSeconds
local vsx, vsy = widgetHandler:GetViewSizes()

function widget:ViewResize(viewSizeX, viewSizeY)
  vsx = viewSizeX
  vsy = viewSizeY
end

local str
local str2
local fontsize
local textwidth
local textheight
local textwidth2
local textheight2
local boxoffset

function widget:Initialize()
  str = "You are playing " .. Game.modName
  str2 = "For normal games use a STABLE release."
  fontsize = 14
  textwidth = glGetTextWidth(str)*fontsize
  local theight, tdescender = glGetTextHeight(str)
  textheight = (theight - tdescender)*fontsize
  textwidth2 = glGetTextWidth(str2)*fontsize
  local theight2, tdescender2 = glGetTextHeight(str2)
  textheight2 = (theight2 - tdescender2)*fontsize
  boxoffset = 1

  if widgetHandler:isStable() or (GetGameSeconds() > 0) then
    widgetHandler:RemoveWidget()
  end
end

function widget:GameStart()
  widgetHandler:RemoveWidget()
end

local fade = 1
local time = 0
local periode = 5
function widget:Update(s)
  time = (time + s)%periode
  fade = math.abs(periode/2 - time)/(periode/2*0.75) + 0.25 -- [0.25, 1]
end

function widget:DrawScreen()
  local x, y

  for p1=1,3 do
    for p2=1,3 do
      repeat
      if (not (p1 == p2 or p1 + p2 == 4 )) then break end -- continue
      x = vsx*(p1/4)
      y = vsy*(p2/4 + (p2-2)/16)
      glColor(0.25, 0.25, 0.25, 0.75*fade)
      glRect(x - textwidth/2 - boxoffset, y - textheight/2 - boxoffset, x + textwidth/2 + boxoffset, y + textheight/2 + boxoffset)
      glColor(1.0, 0.2, 0.2, 0.5*fade)
      glText(str, x - textwidth/2, y - textheight/2, fontsize, "b")
      x = vsx*(p1/4)
      y = vsy*(p2/4 + (p2-2)/16) - textheight2 - 2*boxoffset - 1
      glColor(0.25, 0.25, 0.25, 0.75*fade)
      glRect(x - textwidth2/2 - boxoffset, y - textheight2/2 - boxoffset, x + textwidth2/2 + boxoffset, y + textheight2/2 + boxoffset)
      glColor(1.0, 0.2, 0.2, 0.5*fade)
      glText(str2, x - textwidth2/2, y - textheight2/2, fontsize, "b")
      until true
    end
  end

end

