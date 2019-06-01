--// ============================================================================= 
--// GlassSkin

local skin = {
	info = {
		name    = "Twilight",
		version = "0.1",
		author  = "KingRaptor",

		depend = {
			"DarkGlass",
		},
	}
}

--// ============================================================================= 
--//

skin.general = {
	borderColor     = {0.2, 0.8, 1, 1},
	backgroundColor = {0.1, 0.4, 0.6, 0.4},
	textColor   = {1, 1, 1, 1},
	
	TileImageFG = ":cl:glassFG.png",
}

skin.button = {
	TileImageFG = ":cl:glass.png",
	TileImageBK = ":cl:empty.png",
	tiles = {22, 22, 22, 22}, --// tile widths: left, top, right, bottom
	padding = {10, 10, 10, 10},
}

skin.button_disabled = {
	TileImageFG = ":cl:glass.png",
	TileImageBK = ":cl:empty.png",
	tiles = {22, 22, 22, 22}, --// tile widths: left, top, right, bottom
	padding = {10, 10, 10, 10},

	color = {0.3, .3, .3, 1},
	backgroundColor = {0.1, 0.1, 0.1, 0.8},

	DrawControl = DrawButton,
}

skin.progressbar = {
	TileImageFG = ":cl:tech_progressbar_full.png",
	TileImageBK = ":cl:tech_progressbar_empty.png",
	tiles       = {10, 10, 10, 10},
	backgroundColor = {0, 0.4, 0.4, 0.7},
	
	font = {
		shadow = true,
		outline = true,
	},
}

skin.panel = {
	TileImageBK = ":cl:glass.png",
	TileImageFG = ":cl:empty.png",
	backgroundColor = {0, 0.7, 0.7, 0.6},
}

skin.window = {
	color = {0, 0.7, 0.7, 1},
	tiles = {62, 62, 62, 62}, --// tile widths: left, top, right, bottom
	padding = {13, 13, 13, 13},
	hitpadding = {4, 4, 4, 4},
	boxes = {
		resize = {-21, -21, -10, -10},
		drag = {0, 0, "100%", 10},
	},
}

skin.control = skin.general
--// ============================================================================= 
--//

return skin
