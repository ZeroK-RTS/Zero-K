function widget:GetInfo()
	return {
		name      = "Disable Bad Widgets",
		desc      = "Disables broken widgets based on config.",
		author    = "Shaman",
		date      = "09/24/18",
		license   = "PD",
		layer     = 5,
		enabled   = true,
		alwaysStart = true,
		handler = true,
	}
end

--[[Documentation:
The table below here controls what widgets are disabled. To add new widgets to it, simply add the line [2] = "widget human name"
(NOT the file name! It's the string in the name field of the widget!).
When the widget is loaded, it sees if widgets included in the table are loaded, and disables them if they are.
The widget then, if necessary, waits to deliver a list of disabled widgets to users.
After this is completed, the widget removes itself.
Please also include the reason in the table itself under the key 'reason'.
If the type of widget you want to disable is a user made widget, be sure to make the type 'user' so a message is generated for the user.
Otherwise, make type equal to 'map' to put the reason in the infolog instead.]]

-- Speed ups --
local spEcho = Spring.Echo

-- variables --
local msg = "The following widgets have been disabled:\n" -- message to be displayed on game start.
local userContentDisabled = false
-- config --
local badwidgets = {
	[1] = {
		name = "*Mearth Location Tags*1.0", 
		reason = "Causes black ground on some graphics cards, possible copyright issues.",
		type = 'map', -- Map: Mearth_v4.
	},
	[2] = {
		name = "Metalspot Finder (map)",
		reason = "Breaks everything mex-related.", 
		type = 'map', -- oktogon v3
	},

}

-- callins --
function widget:Initialize()
	for i=1, #badwidgets do
		local widget = badwidgets[i]
		if widgetHandler:IsWidgetKnown(widget.name) then -- If this widget is loaded, unload it and echo a reason.
			if widget.type == 'user' then
				userContentDisabled = true
				msg = msg .. "\n" .. widget.name .. " (Reason: " .. tostring(widget.reason) .. ")" -- users should be aware of why their local widgets are disabled.
			else
				spEcho("Disabled '" .. widget.name .. "' (Reason: " .. tostring(widget.reason) .. ")") -- users don't need this info. Map makers can check infolog.
			end
			widgetHandler:DisableWidget(widget.name)
		end
	end
	if spGetGameFrame() > -1 and userContentDisabled then -- in case of reload
		spEcho("game_message: " .. msg)
		widgetHandler:RemoveWidget(widget)
	end
end

function widget:GameStart()
	if userContentDisabled then
		spEcho("game_message: " .. msg)
		widgetHandler:RemoveWidget(widget)
	end
end
