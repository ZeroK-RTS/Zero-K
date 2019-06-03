--- Grid module

--- Grid fields.
-- Inherits from LayoutPanel.
-- @see layoutpanel.LayoutPanel
-- @table Grid
Grid = LayoutPanel:Inherit{
  classname = "grid",
  resizeItems = true,
  itemPadding = {0, 0, 0, 0},
}

local this = Grid
local inherited = this.inherited
