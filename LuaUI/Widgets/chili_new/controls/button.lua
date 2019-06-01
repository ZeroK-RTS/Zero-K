--//=============================================================================

--- Button module

--- Button fields.
-- Inherits from Control.
-- @see control.Control
-- @table Button
-- @string[opt="button"] caption caption to be displayed
Button = Control:Inherit{
  classname= "button",
  caption  = 'button', 
  defaultWidth  = 70,
  defaultHeight = 20,
}

local this = Button
local inherited = this.inherited

--//=============================================================================

--- Sets the caption of the button
-- @string caption new caption of the button
function Button:SetCaption(caption)
  if (self.caption == caption) then return end
  self.caption = caption
  self:Invalidate()
end

--//=============================================================================

function Button:DrawControl()
  --// gets overriden by the skin/theme
end

--//=============================================================================

function Button:HitTest(x,y)
  return self
end

function Button:MouseDown(...)
  self.state.pressed = true
  inherited.MouseDown(self, ...)
  self:Invalidate()
  return self
end

function Button:MouseUp(...)
  if (self.state.pressed) then
    self.state.pressed = false
    inherited.MouseUp(self, ...)
    self:Invalidate()
    return self
  end
end

--//=============================================================================
