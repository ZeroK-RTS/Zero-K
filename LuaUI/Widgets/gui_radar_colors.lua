
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
	Spring.SetLosViewColors(
		{ 0.17, 0.33, 0, 0.16 }, 
		{ 0.05, 0.42, 0.07, 0 }, 
		{ 0.15, 0.35, 0, 0 }
	)
	widgetHandler:RemoveWidget()
end



