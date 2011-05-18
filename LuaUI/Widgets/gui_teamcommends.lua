--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    gui_comm_ends.lua
--  brief:   shows a pre-game warning if commander-ends is enabled
--  author:  Dave Rodgers
--  modified by [K]dizekat to handle BA 6.3+ end modes
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Team Commander Ends",
    desc      = "Indicator for the Team Comm Ends state (at game start)",
    author    = "trepan, dizekat",
    date      = "Jul 9, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = -3,
    enabled   = true,  --  loaded by default?
  }
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local glPopMatrix      = gl.PopMatrix
local glPushMatrix     = gl.PushMatrix
local glRotate         = gl.Rotate
local glScale          = gl.Scale
local glText           = gl.Text
local glTranslate      = gl.Translate
local spGetGameSeconds = Spring.GetGameSeconds


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("colors.h.lua")

local floor = math.floor


local font = "LuaUI/Fonts/FreeSansBold_30"
local fh = fontHandler.UseFont(font)

local vsx, vsy = widgetHandler:GetViewSizes()
function widget:ViewResize(viewSizeX, viewSizeY)
  vsx = viewSizeX
  vsy = viewSizeY
end

function widget:DrawScreen()
  if (spGetGameSeconds() > 1) then
    widgetHandler:RemoveWidget()
  end
  
  local endmode = (Spring.GetModOptions().commends) == "1"
  
  if endmode then
    local timer = widgetHandler:GetHourTimer()
    local colorStr
    if (math.fmod(timer, 0.5) < 0.25) then
      colorStr = RedStr
    else
      colorStr = YellowStr
    end
    local msg = colorStr .. "Team Commander Ends!"
    glPushMatrix()
    glTranslate((vsx * 0.5), (vsy * 0.5) + 50, 0)
    glScale(1.5, 1.5, 1)
    -- glRotate(5 * math.sin(math.pi * 0.5 * timer), 0, 0, 1)
    if (fh) then
      fh = fontHandler.UseFont(font)
      fontHandler.DrawCentered(msg)
    else
      glText(msg, 0, 0, 24, "oc")
    end

    if endmode then
      msg = "When all commanders in a team are killed, team loses!",
      glTranslate(0, -50, 0)
      glText(msg, 0, 0, 12, "oc")
    end
    glPopMatrix()

  end
end

