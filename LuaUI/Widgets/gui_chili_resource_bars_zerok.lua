--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Economy Panel with Balance Bar",
    desc      = "",
    author    = "jK, Shadowfury333",
    date      = "2014",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false,
    handler   = true,
  }
end

-- This widget exists because the "Chili Economy Panel with Balance Bar" widget 
-- was removed and people who used it would report that they had no resource
-- bar. Remove this widget in a few months once all active players have run it.

function widget:Initialize()
	widgetHandler:EnableWidget("Chili Economy Panel Default")
	widgetHandler:DisableWidget("Chili Economy Panel with Balance Bar")
end