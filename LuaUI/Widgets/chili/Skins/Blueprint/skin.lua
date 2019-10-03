--// =============================================================================
--// Skin

local skin = {
	info = {
		name    = "Blueprint",
		version = "0.3",
		author  = "GoogleFrog?",
	}
}

--// =============================================================================
--//

skin.general = {
	focusColor  = {0.0, 0.6, 1.0, 1.0},
	borderColor = {1.0, 1.0, 1.0, 1.0},

	font = {
		--font    = "FreeSansBold.ttf",
		color        = {1, 1, 1, 1},
		outlineColor = {0.05, 0.05, 0.05, 0.9},
		outline = false,
		shadow  = true,
		size    = 13,
	},
}


skin.icons = {
	imageplaceholder = ":cl:placeholder.png",
}

skin.button = {
	TileImageBK = ":cl:tech_button.png",
	TileImageFG = ":cl:empty.png",
	tiles = {32, 32, 32, 32}, --// tile widths: left, top, right, bottom
	padding = {10, 10, 10, 10},

	backgroundColor = {1, 1, 1, 1.0},

	DrawControl = DrawButton,
}

skin.button_disabled = {
	TileImageBK = ":cl:tech_button.png",
	TileImageFG = ":cl:empty.png",
	tiles = {32, 32, 32, 32}, --// tile widths: left, top, right, bottom
	padding = {10, 10, 10, 10},

	color = {0.3, .3, .3, 1},
	backgroundColor = {0.1, 0.1, 0.1, 0.8},

	DrawControl = DrawButton,
}

skin.checkbox = {
	TileImageFG = ":cl:tech_checkbox_checked.png",
	TileImageBK = ":cl:tech_checkbox_unchecked.png",
	tiles       = {8, 8, 8, 8},
	boxsize     = 12,

	DrawControl = DrawCheckbox,
}

skin.imagelistview = {
	imageFolder      = "folder.png",
	imageFolderUp    = "folder_up.png",

	--DrawControl = DrawBackground,

	colorBK          = {1, 1, 1, 0.3},
	colorBK_selected = {1, 0.7, 0.1, 0.8},

	colorFG          = {0, 0, 0, 0},
	colorFG_selected = {1, 1, 1, 1},

	imageBK  = ":cl:node_selected_bw.png",
	imageFG  = ":cl:node_selected.png",
	tiles    = {9, 9, 9, 9},

	--tiles = {17, 15, 17, 20},

	DrawItemBackground = DrawItemBkGnd,
}
--[[
skin.imagelistviewitem = {
	imageFG = ":cl:glassFG.png",
	imageBK = ":cl:glassBK.png",
	tiles = {17, 15, 17, 20},

	padding = {12, 12, 12, 12},

	DrawSelectionItemBkGnd = DrawSelectionItemBkGnd,
}
--]]

skin.panel = {
	--TileImageFG = ":cl:glassFG.png",
	--TileImageBK = ":cl:glassBK.png",
	--tiles = {17, 15, 17, 20},
	TileImageBK = ":cl:panel_0000.png",
	TileImageFG = ":cl:empty.png",
	tiles = {32, 32, 32, 32},

	backgroundColor = {1, 1, 1, 0.8},

	DrawControl = DrawPanel,
}

for i = 0, 1 do
	for j = 0, 1 do
		for k = 0, 1 do
			for l = 0, 1 do
				local id = i .. j .. k .. l
				skin["panel_" .. id] = Spring.Utilities.CopyTable(skin.panel)
				skin["panel_" .. id].TileImageBK = ":cl:panel_" .. id .. ".png"
			end
		end
	end
end


skin.progressbar = {
	TileImageFG = ":cl:tech_progressbar_full.png",
	TileImageBK = ":cl:tech_progressbar_empty.png",
	tiles       = {16, 16, 16, 16},
	fillPadding     = {4, 3, 4, 3},

	font = {
		shadow = true,
	},

	DrawControl = DrawProgressbar,
}

skin.multiprogressbar = {
	fillPadding     = {4, 3, 4, 3},
}

skin.scrollpanel = {
	BorderTileImage = ":cl:panel2_border.png",
	bordertiles = {16, 16, 16, 16},

	BackgroundTileImage = ":cl:panel2_bg.png",
	bkgndtiles = {16, 16, 16, 16},

	TileImage = ":cl:tech_scrollbar.png",
	tiles     = {8, 8, 8, 8},
	KnobTileImage = ":cl:tech_scrollbar_knob.png",
	KnobTiles     = {8, 8, 8, 8},

	HTileImage = ":cl:tech_scrollbar.png",
	htiles     = {8, 8, 8, 8},
	HKnobTileImage = ":cl:tech_scrollbar_knob.png",
	HKnobTiles     = {8, 8, 8, 8},

	KnobColorSelected = {0.0, 0.6, 1.0, 1.0},

	scrollbarSize = 12,
	DrawControl = DrawScrollPanel,
	DrawControlPostChildren = DrawScrollPanelBorder,
}

skin.trackbar = {
	TileImage = ":cl:trackbar.png",
	tiles     = {16, 16, 16, 16}, --// tile widths: left, top, right, bottom

	ThumbImage = ":cl:trackbar_thumb.png",
	StepImage  = ":cl:trackbar_step.png",

	hitpadding  = {4, 4, 5, 4},

	DrawControl = DrawTrackbar,
}

skin.treeview = {
	--ImageNode         = ":cl:node.png",
	ImageNodeSelected = ":cl:node_selected.png",
	tiles = {16, 16, 16, 16},

	ImageExpanded  = ":cl:treeview_node_expanded.png",
	ImageCollapsed = ":cl:treeview_node_collapsed.png",
	treeColor = {1, 1, 1, 0.1},

	DrawNode = DrawTreeviewNode,
	DrawNodeTree = DrawTreeviewNodeTree,
}

skin.window = {
	TileImage = ":cl:tech_dragwindow.png",
	--TileImage = ":cl:tech_window.png",
	--TileImage = ":cl:window_tooltip.png",
	--tiles = {25, 25, 25, 25}, --// tile widths: left, top, right, bottom
	tiles = {64, 64, 64, 64}, --// tile widths: left, top, right, bottom
	padding = {13, 13, 13, 13},
	hitpadding = {4, 4, 4, 4},

	color = {1, 1, 1, 1.0},
	captionColor = {1, 1, 1, 0.45},

	boxes = {
		resize = {-21, -21, -10, -10},
		drag = {0, 0, "100%", 10},
	},

	NCHitTest = NCHitTestWithPadding,
	NCMouseDown = WindowNCMouseDown,
	NCMouseDownPostChildren = WindowNCMouseDownPostChildren,

	DrawControl = DrawWindow,
	DrawDragGrip = function() end,
	DrawResizeGrip = DrawResizeGrip,
}


skin.control = skin.general


--// =============================================================================
--//

return skin
