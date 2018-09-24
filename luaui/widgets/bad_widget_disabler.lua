function widget:GetInfo()
	return {
		name      = "Disable Bad Widgets",
		desc      = "Disables broken widgets based on config.",
		author    = "_Shaman",
		date      = "09/24/18",
		license   = "Resignateer license",
		layer     = -9999999999999999999999999999999999999999999999999,
		enabled   = true,
		alwaysStart = true,
	}
end

local badwidgets = {
	[1] = "*Mearth Location Tags*1.0",
}

function widget:Initialize()
	for i=1, #badwidgets do
		if widgetHandler:FindWidget(badwidgets[i]) then
			Spring.SendCommands("luaui disablewidget " .. badwidgets[i])
			Spring.Echo("disabled bad widget " .. badwidgets[i])
		end
	end
	widgetHandler:RemoveWidget()
end
