--//=============================================================================
--// GlassSkin

local skin = {
  info = {
    name    = "BubbleBlack",
    version = "1.0",
    author  = "luckywaldo7",

    depend = {
      "Carbon",
    },
  }
}

--//=============================================================================
--//

skin.general = {
  textColor = {1,1,1,1},
}

skin.window = {
  TileImage = ":cl:BubbleBlack.png",
  tiles = {20, 20, 20, 20}, --// tile widths: left,top,right,bottom
  padding = {10, 10, 10, 10},
  hitpadding = {10, 10, 10, 10},

  captionColor = {1, 1, 1, 0.55},

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

--//=============================================================================
--//

return skin
