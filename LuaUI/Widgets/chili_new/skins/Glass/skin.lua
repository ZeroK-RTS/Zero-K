--//=============================================================================
--// GlassSkin

local skin = {
  info = {
    name    = "Glass",
    version = "0.2",
    author  = "jK",
  }
}

--//=============================================================================
--//

skin.general = {
  --font        = "FreeSansBold.ttf",
  fontsize    = 13,
  textColor   = {0.1,0.1,0.1,1},
  focusColor   = {0.35, 0.35, 1.0, 0.9},
  borderColor  = {1.0, 1.0, 1.0, 1.0},

  --padding         = {5, 5, 5, 5}, --// padding: left, top, right, bottom
  backgroundColor = {0.1, 0.1, 0.1, 0.7},

  font = {
    outlineColor     = {0.2,0.2,0.2,0.3},
    --autoOutlineColor = false,
    --shadow           = true,
  },
}

skin.icons = {
  imageplaceholder = ":cl:placeholder.png",
}

skin.button = {
  TileImageFG = ":cl:glassFG.png",
  TileImageBK = ":cl:glassBK.png",
  tiles       = {17,15,17,20},

  textColor = {1,1,1,1},

  padding = {12, 12, 12, 12},
  backgroundColor = {0.1, 0.1, 0.1, 0.7},

  DrawControl = DrawButton,
}


skin.combobox = {
	TileImageFG = ":cl:glassFG.png",
	TileImageBK = ":cl:glassBK.png",
	TileImageArrow = ":cl:combobox_ctrl_arrow.png",
	tiles       = {17,15,17,20},
	padding     = {10, 10, 26, 10},

	textColor = {1,1,1,1},
	backgroundColor = {0.1, 0.1, 0.1, 0.7},

	DrawControl = DrawComboBox,
}


skin.combobox_window = {
	clone     = "window";
	TileImage = ":cl:combobox_wnd.png",
	padding   = {4, 3, 3, 4};
}


skin.combobox_scrollpanel = {
	clone       = "scrollpanel";
	borderColor = {1, 1, 1, 0};
	padding     = {0, 0, 0, 0};
}


skin.combobox_item = {
	clone       = "button";
}


skin.editbox = {
  textColor       = {1.0, 1.0, 1.0, 1.0},
  backgroundColor = {0.1, 0.1, 0.1, 0.7},
  cursorColor     = {0.35, 0.35, 1.0, 0.9},
}

skin.checkbox = {
  TileImageFG = ":cl:checkbox_arrow.png",
  TileImageBK = ":cl:checkbox.png",
  tiles       = {3,3,3,3},
  boxsize     = 13,

  DrawControl = DrawCheckbox,
}


skin.imagelistview = {
  imageFolder      = "folder.png",
  imageFolderUp    = "folder_up.png",

  --DrawControl = DrawBackground,

  colorFG          = {0.75,0.75,0.75,0.65},
  colorFG_selected = {1,1,1,0.65},
  imageFG          = ":cl:itemlistview_item_fg.png",

  colorBK          = {0.5, 0.5, 0.5, 0.1},
  colorBK_selected = {0.35,0.35,1,0.9},
  imageBK          = ":cl:glassBK.png",

  tiles = {17,15,17,20},

  DrawItemBackground = DrawItemBkGnd,
}
--[[
skin.imagelistviewitem = {
  imageFG = ":cl:glassFG.png",
  imageBK = ":cl:glassBK.png",
  tiles = {17,15,17,20},

  padding = {12, 12, 12, 12},

  DrawSelectionItemBkGnd = DrawSelectionItemBkGnd,
}
--]]

skin.panel = {
  TileImageFG = ":cl:glassFG.png",
  TileImageBK = ":cl:glassBK.png",
  tiles = {17,15,17,20},

  DrawControl = DrawPanel,
}

skin.progressbar = {
  TileImageFG = ":cl:progressbar_full.png",
  TileImageBK = ":cl:progressbar_empty.png",
  tiles       = {3,3,3,3},

  DrawControl = DrawProgressbar,
}

skin.scrollpanel = {
  BorderTileImage = ":cl:panel.png",
  bordertiles = {14,10,14,8},

  TileImage = ":cl:scrollbar.png",
  tiles     = {6,3,6,3},
  KnobTileImage = ":cl:scrollbar_knob.png",
  KnobTiles     = {6,7,6,7},

  HTileImage = ":cl:hscrollbar.png",
  htiles     = {3,6,3,6},
  HKnobTileImage = ":cl:scrollbar_knob.png",
  HKnobTiles     = {6,7,6,9},
  
  KnobColorSelected = {0.35, 0.35, 1.0, 0.9},

  padding       = {1,1,1,1},

  scrollbarSize = 11,
  DrawControl = DrawScrollPanel,
  DrawControlPostChildren = DrawScrollPanelBorder,
}

skin.trackbar = {
  TileImage = ":cl:trackbar.png",
  tiles     = {6, 3, 6, 3}, --// tile widths: left,top,right,bottom

  ThumbImage = ":cl:trackbar_thumb.png",
  StepImage  = ":cl:trackbar_step.png",

  hitpadding  = {4, 4, 4, 4},

  DrawControl = DrawTrackbar,
}

skin.treeview = {
  ImageNodeSelected = ":cl:node_selected.png",
  tiles = {10,9,10,22},

  ImageExpanded  = ":cl:treeview_node_expanded.png",
  ImageCollapsed = ":cl:treeview_node_collapsed.png",
  treeColor = {0,0,0,0.4},

  DrawNode = DrawTreeviewNode,
  DrawNodeTree = DrawTreeviewNodeTree,
}

skin.window = {
  TileImage = ":cl:glass.png",
  tiles = {22, 24, 22, 23}, --// tile widths: left,top,right,bottom
  padding = {14, 23, 14, 14},
  hitpadding = {10, 4, 10, 10},

  captionColor = {0, 0, 0, 0.55},

  boxes = {
    resize = {-25, -25, -14, -14},
    drag = {0, 0, "100%", 24},
  },

  NCHitTest = NCHitTestWithPadding,
  NCMouseDown = WindowNCMouseDown,
  NCMouseDownPostChildren = WindowNCMouseDownPostChildren,

  DrawControl = DrawWindow,
  DrawDragGrip = DrawDragGrip,
  DrawResizeGrip = DrawResizeGrip,
}

skin.line = {
  TileImage = ":cl:glass_line.png",
  tiles = {0, 0, 0, 0},
  TileImageV = ":cl:glass_line_vert.png",
  tilesV = {0, 0, 0, 0},
  DrawControl = DrawLine,
}
  
skin.control = skin.general


--//=============================================================================
--//

return skin
