function widget:GetInfo()
	return {
		name    = "Loading failure pop-up",
		desc    = "Lets the game fail gracefully instead of crashing",
		author  = "Sprung, Histidine",
		date    = "2023-08-10",
		license = "GNU GPL, v2 or later",
		layer   = math.huge, -- over any other elements
		enabled = true
	}
end


function widget:Initialize()
	if not UnitDefNames.unitdefs_failed_to_load then
		widgetHandler:RemoveWidget()
		return
	end

	local Chili = WG.Chili
	local window =  Chili.Window:New{
		classname = "main_window_small",
		x = 2,
		y = 100,
		width = 950,
		height = 400,
		parent = Chili.Screen0,
	}

	Chili.TextBox:New {
		x = 6,
		y = 6,
		right = 6,
		bottom = 100,
		text = "UNIT DEFS FAILED TO LOAD!\nLOOK FOR \"UNIT DEFS LOADING ERROR\" IN INFOLOG.TXT FOR LOGS",
		fontSize = 64,
		parent = window,
	}

	Chili.Button:New {
		x = 300,
		height = 80,
		bottom = 6,
		right = 5,
		caption = "EXIT TO LOBBY",
		OnClick = {function ()
			if Spring.GetMenuName and Spring.GetMenuName() ~= "" then
				Spring.Reload("")
			else
				Spring.SendCommands("quitforce")
			end
		end},
		fontSize = 64,
		parent = window,
	}
end
