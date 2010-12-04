--//=============================================================================
--// GlassSkin

local skin = {
  info = {
    name    = "EmptyScrollbar",
    version = "0.11",
    author  = "Licho",

    depend = {
      "Robocracy",
    },
  }
}

--//=============================================================================
--//
skin.scrollpanel = {
  BorderTileImage = ":cl:empty.png",
  bordertiles = {14,14,14,14},

  BackgroundTileImage = ":cl:empty.png",
  bkgndtiles = {14,14,14,14},

  TileImage = ":cl:tech_scrollbar.png",
  tiles     = {7,7,7,7},
  KnobTileImage = ":cl:tech_scrollbar_knob.png",
  KnobTiles     = {6,8,6,8},

  HTileImage = ":cl:tech_scrollbar.png",
  htiles     = {7,7,7,7},
  HKnobTileImage = ":cl:tech_scrollbar_knob.png",
  HKnobTiles     = {6,8,6,8},

  KnobColorSelected = {1,0.7,0.1,0.8},

  scrollbarSize = 11,
  DrawControl = DrawScrollPanel,
  DrawControlPostChildren = DrawScrollPanelBorder,
}


--//=============================================================================
--//

return skin
