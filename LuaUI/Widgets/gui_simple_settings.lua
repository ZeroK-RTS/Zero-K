
function widget:GetInfo()
	return {
		name      = "Simple Settings",
		desc      = "Creates and manages the simple settings for simple settings mode.",
		author    = "GoogleFrog",
		date      = "1 June 2017",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,
		handler   = true,
	}
end

----------------------------------------------------
-- Options
----------------------------------------------------
options_path = 'Settings'
options_order = {'testOption'}
options = {
	testOption = {
		name  = "Test Option",
		type  = "bool", 
		value = true,
		simpleMode = true,
		desc = "bla.",
		noHotkey = true,
	},
}

----------------------------------------------------
-- Callins
----------------------------------------------------

function widget:Initialize(dt)
	
end
