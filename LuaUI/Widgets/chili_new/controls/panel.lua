--//=============================================================================

--- Panel module

--- Panel fields.
-- Inherits from Control.
-- @see control.Control
-- @table Panel
Panel = Control:Inherit{
  classname= "panel",
  defaultWidth  = 100,
  defaultHeight = 100,
}

local this = Panel
local inherited = this.inherited

--//=============================================================================
