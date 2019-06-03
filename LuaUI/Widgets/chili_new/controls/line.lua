--//=============================================================================

--- Line module

--- Line fields.
-- Inherits from Control.
-- @see control.Control
-- @table Line
-- @string[opt="line"] caption text to be displayed on the line(?)
-- @string[opt="horizontal] style style of the line
Line = Control:Inherit{
  classname= "line",
  caption  = 'line',
  defaultWidth  = 100,
  defaultHeight = 1,
  style = "horizontal",
}

local this = Line
local inherited = this.inherited

--//=============================================================================
