
local data = {
	name = "TECH_UP",
	cmdID = 38412,
	
	commandType = CMDTYPE.ICON_UNIT_OR_AREA,
	isState = false, -- Hold fire etc
	isInstant = false, -- Such as Stop, Self-D etc
	humanName = "Tech Up",
	actionName = "techup",
	cursor = "Techup",
	image = "LuaUI/Images/commands/Bold/tech_up.png", -- If a state, then this should be a list of images.
	
	onCommandMenuByDefault = true,
	position = {pos = 7, priority = 0.1},
	stateNames = nil, -- A list of what the states are called.
	stateTooltip = nil, -- A list of tooltips to use for each state.
	tooltip = [[Tech Up: Upgrade a matching factory to the next tech level, or any structure to the current tech level.
Ctrl - Only upgrade metal extractors
Alt - Only upgrade energy]],
}

return data
