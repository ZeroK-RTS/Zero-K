function widget:GetInfo()
	return {
		name      = "Settings Fixer",
		desc      = "BAR uses SetConfigInt in a way that screws up some settings.",
		author    = "GoogleFrog",
		date      = "12 November 2025",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,
	}
end

function widget:Initialize()
	Spring.SetConfigInt("SmallFontSize", 14) -- Engine default
	Spring.SetConfigInt("UnitIconsAsUI", 0)
end
