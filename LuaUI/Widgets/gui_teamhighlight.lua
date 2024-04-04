function widget:GetInfo() return {
	name    = "Teamhighlight option",
	desc    = "Adds the 'Lagging players flash' option",
	layer   = -10002,
	enabled = true,
} end

local function ToggleTeamhighlight(self)
	if self.value then
		-- at 1, flashing doesn't happen if you're a spec (inconsistent)
		Spring.SendCommands("teamhighlight 2")
	else
		Spring.SendCommands("teamhighlight 0")
	end
end

i18nPrefix = 'teamhighlightoption_'
options_path = "Settings/Interface/Team Colors"
options = {
	enable_th = {
		type = "bool",
		value = false,
		noHotkey = true,
		OnChange = ToggleTeamhighlight,
	},
}

function widget:Initialize()
	ToggleTeamhighlight (options.enable_th)
end
