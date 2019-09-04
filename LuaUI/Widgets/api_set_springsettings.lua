
function widget:GetInfo()
	return {
		name      = "Set Springsettings and Config",
		desc      = "Sets some config values",
		author    = "GoogleFrog",
		date      = "12 November 2016",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true --  loaded by default?
	}
end

function widget:Initialize()
	Spring.SetConfigInt("RotateLogFiles", 1)
	Spring.SendCommands("maxviewrange 100000")
	Spring.SendCommands("minviewrange 0")
end
