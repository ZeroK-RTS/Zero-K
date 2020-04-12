local function Range(input)
	input[1] = input[1]/255
	input[2] = input[2]/255
	input[3] = input[3]/255
	return input
end

local colors = {
	myColor		= Range({ 050, 250, 050 }),	-- can only be 1 color
--	myColor		= Range({ 008, 192, 016 }),
	gaiaColor	= Range({ 200, 200, 200 }),	-- can only be 1 color
	
	allyColors = {
	  -- the first three ally colours are shades of blue
	  -- this is so that in a MM game (4v4 or less) you are the only one green
	  -- this is effectively soft simplecolors without the main disadvantage
	  Range({ 010, 080, 255 }),
	  Range({ 010, 250, 250 }),
	  Range({ 150, 150, 255 }),

	  Range({ 005, 120, 005 }),
	  Range({ 120, 175, 050 }),
	  Range({ 030, 120, 110 }),
	  Range({ 130, 255, 210 }),
	  Range({ 170, 190, 220 }),
	  Range({ 060, 170, 190 }),
	  Range({ 090, 040, 255 }), -- decently salient but too purple to be earlier in the list
	},

	enemyColors = {
	-- as many as needed
	  Range({ 255, 065, 065 }),
	  Range({ 255, 255, 040 }),
	  Range({ 255, 145, 030 }),
	  Range({ 240, 040, 150 }),
	  Range({ 230, 150, 170 }),
	  Range({ 200, 130, 110 }),
	  Range({ 225, 220, 140 }),
	  Range({ 255, 180, 050 }),
	  Range({ 255, 120, 220 }),
	  Range({ 200, 030, 075 }),
	  Range({ 180, 100, 100 }),
	  Range({ 160, 090, 015 }),
	  Range({ 170, 020, 100 }),
	  Range({ 125, 100, 020 }),
	  Range({ 170, 040, 040 }),
	  Range({ 125, 015, 060 }),
	},
}

local colorsTeal = {
	myColor		= Range({ 013, 245, 243 }),	-- can only be 1 color
--	myColor		= Range({ 008, 192, 016 }),
	gaiaColor	= Range({ 200, 200, 200 }),	-- can only be 1 color
	
	allyColors = {
	  Range({ 020, 105, 255 }),
	  Range({ 011, 100, 040 }),
	  Range({ 040, 190, 240 }),
	  Range({ 030, 230, 150 }),
	  Range({ 130, 255, 210 }),
	  Range({ 170, 190, 220 }),
	  Range({ 120, 120, 255 }),
	  Range({ 090, 040, 255 }),
	  Range({ 030, 120, 110 }),
	  Range({ 120, 175, 050 }),
	  Range({ 050, 250, 050 }),
	},

	enemyColors = {
	-- as many as needed
	  Range({ 255, 065, 065 }),
	  Range({ 255, 255, 040 }),
	  Range({ 255, 145, 030 }),
	  Range({ 240, 040, 150 }),
	  Range({ 230, 150, 170 }),
	  Range({ 200, 130, 110 }),
	  Range({ 225, 220, 140 }),
	  Range({ 255, 180, 050 }),
	  Range({ 255, 120, 220 }),
	  Range({ 200, 030, 075 }),
	  Range({ 180, 100, 100 }),
	  Range({ 160, 090, 015 }),
	  Range({ 170, 020, 100 }),
	  Range({ 125, 100, 020 }),
	  Range({ 170, 040, 040 }),
	  Range({ 125, 015, 060 }),
	},
}

local colorblind = {
	myColor		= Range({ 120, 255, 255 }),
	gaiaColor	= Range({ 200, 200, 200 }),
	
	allyColors = {
	  Range({ 020, 105, 255 }),
	  Range({ 090, 040, 255 }),
	  Range({ 120, 120, 255 }),
	  Range({ 030, 120, 255 }),
	  Range({ 120, 020, 255 }),
	  Range({ 030, 040, 255 }),
	  Range({ 130, 050, 255 }),
	  Range({ 040, 090, 230 }),
	  Range({ 170, 110, 255 }),
	},

	enemyColors = {
	  Range({ 255, 145, 030 }),
	  Range({ 200, 030, 075 }),
	  Range({ 255, 255, 040 }),
	  Range({ 240, 040, 150 }),
	  Range({ 230, 150, 170 }),
	  Range({ 255, 065, 065 }),
	  Range({ 200, 130, 110 }),
	  Range({ 225, 220, 140 }),
	  Range({ 255, 180, 050 }),
	  Range({ 255, 120, 220 }),
	  Range({ 180, 100, 100 }),
	  Range({ 160, 090, 015 }),
	  Range({ 170, 020, 100 }),
	  Range({ 125, 100, 020 }),
	  Range({ 170, 040, 040 }),
	  Range({ 125, 015, 060 }),
	},
}

local simpleColors = {
	myColor = colors.myColor,
	gaiaColor = colors.gaiaColor,
	allyColors = {colors.allyColors[1]},
	enemyColors = {colors.enemyColors[1]},
	enemyByTeamColors = colors.enemyColors,
}

local simpleColorsTeams = {
	myColor = colors.myColor,
	gaiaColor = colors.gaiaColor,
	allyColors = {colors.allyColors[1]},
	enemyColors = colors.enemyColors,
}

local simpleColorblind = {
	myColor = colorblind.myColor,
	gaiaColor = colorblind.gaiaColor,
	allyColors = {colorblind.allyColors[1]},
	enemyColors = {colorblind.enemyColors[1]},
	enemyByTeamColors = colorblind.enemyColors,
}

-- If order is non-sequential then things break.
local colorConfigs = {
	default = {
		order = 1,
		name = "Default",
		desc = "The default team colors. Allies are blue-ish, enemies are red-ish, self is green.",
		colors = colors
	},
	simple = {
		order = 2,
		name = "Simple",
		desc = "Simple colors. Allies are blue, enemies are red, self is green.",
		colors = simpleColors
	},
	defaultTeal = {
		order = 3,
		name = "Self Teal",
		desc = "Allies are blue/green-ish, enemies are red/yellow-ish, self is teal.",
		colors = colorsTeal
	},
	colorblind = {
		order = 4,
		name = "Colorblind",
		desc = "Allies are blue-ish, enemies are red-ish, self is teal.",
		colors = colorblind
	},
	simpleColorblind = {
		order = 5,
		name = "Simple Colorblind",
		desc = "Enemies are red, allies are blue, self is teal.",
		colors = simpleColorblind
	},
}
return colorConfigs
