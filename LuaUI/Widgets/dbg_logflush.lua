--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "LogFlush Disabler",
    desc      = "Disables log flushing for Spring 94.1",
    author    = "KingRaptor",
    date      = "20130414",
    license   = "Public Domain",
    layer     = 0,
    enabled   = true --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
  if (Game.version:find('94') and (Game.version:find('94.1.1') == nil)) then
    Spring.SetConfigInt("LogFlush", 0)
    Spring.Log(widget:GetInfo().name, LOG.WARNING, "Spring 94.1 detected. Disabling LogFlush.")
    --Spring.SendCommands("luaui disablewidget " .. widget:GetInfo().name)
    widgetHandler:RemoveWidget()
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------