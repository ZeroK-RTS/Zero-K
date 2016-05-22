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
-- 			file = "LuaUI/fonts/dejavu-sans-mono/DejaVuSansMono.ttf",
			size = 18,
		},
		cursorColor = { 0.9, 0.9, 0.9, 0.7 },
		borderColor = { 0, 0, 0, 0 },
		focusColor = { 0, 0, 0, 0 },
	},
	suggestions = {
		h = 0.4, -- FIXME: use chili-style positions
		y = 150, -- distance from input editbox in absolute values
		inverted = true, -- if set to true, it will appear above the console
		fontSize = 16,
		padding = 4,
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
}
