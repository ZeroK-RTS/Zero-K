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
    name      = "TeamCommEnds & Lavarise indicator",
    desc      = "Indicate Team Comm Ends state & Lavarise state & Halloween state (at game start)",
    author    = "trepan, dizekat, Tom Fyuri",
    date      = "Jul 9 2008, 2012 (lavarise), 2013 (halloween)",
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
  local lavamode = (Spring.GetModOptions().zkmode) == "lavarise"
  local halloween = (Spring.GetModOptions().zkmode) == "halloween" -- only lavamode OR halloween can be true at the same time
  local halloween_difficulty = Spring.GetModOptions().ghostdiff
  
  if endmode or lavamode or halloween then
    local timer = widgetHandler:GetHourTimer()
    local colorStr
    --if (math.fmod(timer, 0.5) < 0.25) then
      --colorStr = RedStr
    --else
      colorStr = YellowStr
    --end
    local mainText
    local secondText
    if endmode and lavamode then
      if (math.fmod(timer, 6) < 3) then
    	mainText = "Team Commander Ends!"
    	secondText = "When all commanders in a team are killed, team loses!"
      else 
    	mainText = "Lava Rise mode!"
    	secondText = "Lava will rise from the ground and will gradually consume everything!"
      end
    elseif endmode and halloween then
      if (math.fmod(timer, 6) < 3) then
    	mainText = "Team Commander Ends!"
    	secondText = "When all commanders in a team are killed, team loses!"
      else 
	if (halloween_difficulty ~= "nightmare") then
	  mainText = "Halloween mode!"
	else
	  mainText = "Halloween mode! NIGHTMARE DIFFICULTY! HE COMES!"
	end
    	secondText = "Ghosts will randomly possess units! Damage (<34%hp)/EMP(>0%) ghosted units to unpossess them!"
      end
    elseif endmode then
      mainText = "Team Commander Ends!"
      secondText = "When all commanders in a team are killed, team loses!"
    elseif lavamode then
      mainText = "Lava Rise mode!"
      secondText = "Lava will rise from the ground and will gradually consume everything!"
    elseif halloween then
      if (halloween_difficulty ~= "nightmare") then
	mainText = "Halloween mode!"
      else
	mainText = "Halloween mode! NIGHTMARE DIFFICULTY! HE COMES!"
      end
      secondText = "Ghosts will randomly possess units! Damage (<34%hp)/EMP(>0%) ghosted units to unpossess them!"
    end
    local msg = colorStr .. mainText
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

    --if endmode then
    msg = secondText,
    glTranslate(0, -50, 0)
    glText(msg, 0, 0, 12, "oc")
    --end
    glPopMatrix()

  end
end

