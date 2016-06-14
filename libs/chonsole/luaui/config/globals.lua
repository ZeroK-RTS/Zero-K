-- constants
local grey = { 0.7, 0.7, 0.7, 1 }
local white = { 1, 1, 1, 1 }
local blue = { 0, 0, 1, 1 }
local teal = { 0, 1, 1, 1 }
local red =  { 1, 0, 0, 1 }
local green = { 0, 1, 0, 1 }
local yellow = { 1, 1, 0, 1 }

-- General
config = {
	console = {
		x = "50%",
		bottom = 0,
		width = "22%",
		height = 30,
		font = {
-- 			font = "LuaUI/DejaVuSansMono.ttf",
			size = 18,
		},
		cursorColor = { 0.9, 0.9, 0.9, 0.7 },
		borderColor = { 0, 0, 0, 0 },
		focusColor = { 0, 0, 0, 0 },

		keepFocus = true,
	},
	suggestions = {
		height = "40%",
		font = {
			size = 16,
		},

		disableMenu = true, -- if set to true, the suggestion popup menu won't appear
		offsetY = 0, -- distance from input editbox in absolute values
		--offsetY = 150,
		forceDirection = nil, -- can be set to "up" or "down" to force suggestions appearing up or down
		suggestionPadding = 4,
		pageUpFactor = 10,
		pageDownFactor = 10,

		selectedColor = { 0, 1, 1, 0.4 },
		subsuggestionColor = { 0, 0, 0, 0 },
		suggestionColor = white,
		descriptionColor = grey,

		cheatEnabledColor = green,
		cheatDisabledColor = red,
		autoCheatColor = yellow,
	},
	chat = {
		canSpecChat = false,
		sayChatColor = {1, 1, 1, 1},
		allyChatColor = {0, 1, 0.2, 1},
		specChatColor = {0.6, 0.8, 1, 1},
	},
}
