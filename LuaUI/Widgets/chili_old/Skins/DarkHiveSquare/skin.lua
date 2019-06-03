--//=============================================================================
--// Skin

local skin = {
  info = {
    name    = "DarkHiveSquare",
    version = "0.1",
    author  = "luckywaldo7",
    
    depend = {
      "DarkHive",
    },
  }
}

--//=============================================================================
--//
skin.button = {
  TileImageBK = ":cl:tech_button.png",
}

skin.button_disabled = {
  TileImageBK = ":cl:tech_button.png",
  color = {0.3,.3,.3,1},
  backgroundColor = {0.1,0.1,0.1,0.8},

  DrawControl = DrawButton,
}

skin.panel = {
  TileImageBK = ":cl:tech_button.png",
}

--//=============================================================================
--//
return skin
