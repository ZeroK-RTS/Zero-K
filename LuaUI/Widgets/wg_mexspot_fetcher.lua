
function widget:GetInfo()
  return {
    name      = "Mexspot Fetcher",
    desc      = "Fetches metal spot data from synced.",
    author    = "Google Frog", -- 
    date      = "22 April 2012",
    license   = "GNU GPL, v2 or later",
    layer     = -30000,
    enabled   = true  --  loaded by default?
  }
end

function widget:Initialize()
	widgetHandler:RegisterGlobal("SendMetalSpots", SendMetalSpots)
	Spring.SendLuaRulesMsg("RequestMetalSpots")
	Spring.Echo("Mexspot Fetcher fetching")
	--Spring.MarkerAddPoint(0,0,0,"")
end

function SendMetalSpots(playerID, metalSpots, metalSpotsByPos)
	WG.metalSpots = metalSpots
	WG.metalSpotsByPos = metalSpotsByPos
	Spring.Echo("Mexspot Fetcher received")
	widgetHandler:RemoveWidget(self)
end