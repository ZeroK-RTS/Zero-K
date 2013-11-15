function widget:GetInfo()
  return {
    name     = "Disable Mouse Toggle",
    desc     = "Disable Mouse Toggle by default.",
    author   = "SirMaverick",
    date     = "2010",
    license  = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = disable
  }
end

-- FIXME: does not work atm
-- needs engine change so that config changes take effect in game

local GetConfigString = Spring.GetConfigString
local SetConfigString = Spring.SetConfigString

local configStr = "MouseDragScrollThreshold"
local threshold = 0.3 -- default

function widget:Initialize()
  threshold = tonumber(GetConfigString(configStr, 0.3))
  SetConfigString(configStr, string.format("%0.3f", -threshold))
end

function widget:Shutdown()
  -- reset
  SetConfigString(configStr, string.format("%0.3f", threshold))
end
