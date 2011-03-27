function gadget:GetInfo()
  return {
    name      = "No Multithread",
    desc      = "Displays a message and exits when MT build is used.",
    author    = "KingRaptor (based on Autoquit widget by Evil4Zerggin & zwzsg)",
    date      = "22 Jan 2011",
    license   = "GNU LGPL, v2.1 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end


if (gadgetHandler:IsSyncedCode()) then return	-- silent removal

else
--------------------------------------------------------------------------------
--  UNSYNCED
--------------------------------------------------------------------------------

----------------------------------------------------------------
-- global variables
----------------------------------------------------------------
local delay = 30
local endTime
local key
local esc = 27	-- key number

----------------------------------------------------------------
-- speedups
----------------------------------------------------------------
local DiffTimers = Spring.DiffTimers
local GetTimer = Spring.GetTimer
local SendCommands = Spring.SendCommands
local Echo = Spring.Echo
local GetMouseState = Spring.GetMouseState
local glPopMatrix      = gl.PopMatrix
local glPushMatrix     = gl.PushMatrix
local glRotate         = gl.Rotate
local glScale          = gl.Scale
local glText           = gl.Text
local glTranslate      = gl.Translate

function gadget:Initialize()
  local version = tostring(Game.version)
  if not string.find(version, "MT") then
	Spring.Echo("<No Multithread> MT not detected, exiting")
	gadgetHandler:RemoveGadget()
  else
	  --SendCommands("luaui disable")
	  endTime = GetTimer()
	  key=nil
	  Echo("<No Multithread> Automatically exiting in " .. delay .. " seconds. Press Escape to cancel.")
  end
end

function gadget:Update(dt)
  if endTime then
    if key == esc then
      Echo("<No Multithread> Autoquit canceled.")
      endTime = false
      --gadgetHandler:RemoveGadget()
    elseif DiffTimers(GetTimer(), endTime) > delay then
      Echo("<No Multithread> Autoquit sending quit command.")
      SendCommands("quit")
      SendCommands("quitforce")
    end
  end
end

function gadget:KeyPress(k)
  key=k
  --Spring.Echo(key)
end

local font = "LuaUI/Fonts/FreeSansBold_30"
--local fh = fontHandler.UseFont(font)

local vsx, vsy = gadgetHandler:GetViewSizes()

function gadget:ViewResize(viewSizeX, viewSizeY)
  vsx = viewSizeX
  vsy = viewSizeY
end

function gadget:DrawScreen()
	if not endTime then return end
    local timer = gadgetHandler:GetHourTimer()
    local colorStr
    if (math.fmod(timer, 0.5) < 0.25) then
		colorStr = "\255\255\0\0"
    else
		colorStr = "\255\224\224\0"
    end
    local msg = colorStr .. "You are using the MT Build of Spring\nThis is not compatible with Zero-K\nExiting in "..delay.." seconds (press Escape to cancel)"
    glPushMatrix()
    glTranslate((vsx * 0.5), (vsy * 0.5) + 50, 0)
    glScale(1.5, 1.5, 1)
    -- glRotate(5 * math.sin(math.pi * 0.5 * timer), 0, 0, 1)
	glText(msg, 0, 0, 24, "oc")

    glPopMatrix()
end

end