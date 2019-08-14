function widget:GetInfo()
  return {
    name      = "Stupid Overlay Hax",
    desc      = "Handles overlay transitions because the slow transition is annoying.",
    author    = "GoogleFrog",
    date      = "2nd March 2015",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false,
  }
end

local heightMapEnabled = false
local pathMapEnabled = false
local losMapEnabled = false

function WG.Overlay_ToggleHeightMap()
	if heightMapEnabled then
		Spring.SendCommands('showelevation')
		if losMapEnabled then
			Spring.SendCommands('togglelos')
		end
		heightMapEnabled = false
	else
		if losMapEnabled then
			Spring.SendCommands('togglelos')
		end
		Spring.SendCommands('showelevation')
		heightMapEnabled = true
	end
end

function WG.Overlay_TogglePathMap()
	if pathMapEnabled then
		Spring.SendCommands('showpathtraversability')
		if losMapEnabled then
			Spring.SendCommands('togglelos')
		end
		pathMapEnabled = false
	else
		if losMapEnabled then
			Spring.SendCommands('togglelos')
		end
		Spring.SendCommands('showpathtraversability')
		pathMapEnabled = true
	end
end

function WG.Overlay_ToggleLOS()
	if heightMapEnabled or pathMapEnabled then
		heightMapEnabled = false
		pathMapEnabled = false
	else
		losMapEnabled = not losMapEnabled
	end
	Spring.SendCommands('togglelos')
end
