--[[Shaman's Policy:
Do whatever you want with this code.
]]

function widget:GetInfo()
	return {
		name      = "Disable Bad Widgets",
		desc      = "Disables broken widgets based on config.",
		author    = "_Shaman",
		date      = "09/24/18",
		license   = "Shaman's Policy",
		layer     = 5,
		enabled   = true,
		alwaysStart = true,
	}
end

--[[Documentation:
The table below here controls what widgets are disabled. To add new widgets to it, simply add the line [2] = "widget human name"
(NOT the file name! It's the string in the name field of the widget!).

When the widget is loaded, it sees if widgets included in the table are loaded, and disables them if they are.
After this is completed, the widget removes itself.]]

-- Speed ups --
local spSendCommands = Spring.SendCommands
local spEcho = Spring.Echo

local badwidgets = {
	[1] = "*Mearth Location Tags*1.0",
}

function widget:Initialize()
	for i=1, #badwidgets do
		if widgetHandler:FindWidget(badwidgets[i]) then
			spSendCommands("luaui disablewidget " .. badwidgets[i])
			spEcho("disabled bad widget " .. badwidgets[i])
		end
	end
	widgetHandler:RemoveWidget()
end
