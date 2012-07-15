
function widget:GetInfo()
  return {
    name      = "Radar Colours",
    desc      = "Enables an alternate LOS and radar view colouration",
    author    = "Google Frog",
    date      = "8 April 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true --  loaded by default?
  }
end

function widget:Initialize()
	-- always, los, radar, jammer
	Spring.SetLosViewColors(
		{ 0.17, 0.23, 0.1, 0 }, 
		{ 0.17, 0.23, 0.1, -0.15 }, 
		{ 0.17, 0.23, 0.1, -0.15 }
	)
	widgetHandler:RemoveWidget()
end



