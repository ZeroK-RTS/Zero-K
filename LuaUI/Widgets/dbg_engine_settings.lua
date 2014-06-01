--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Engine Setting Fix",
    desc      = "Fixes engine settings as appropriate for engine",
    author    = "KingRaptor",
    date      = "2013.04.14",
    license   = "Public Domain",
    layer     = 0,
    enabled   = true --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local tags = {
  WorkerThreadSpinTime = 0,
}

function widget:Initialize()
  if not ((Game.version:find('91.0') == 1)) then
    for tag, value in pairs(tags) do
      Spring.SetConfigInt(tag, value)
    end
    Spring.Log(widget:GetInfo().name, LOG.WARNING, "Setting WorkerThreadSpinTime = 0")
    --Spring.SendCommands("luaui disablewidget " .. widget:GetInfo().name)
    widgetHandler:RemoveWidget()
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------