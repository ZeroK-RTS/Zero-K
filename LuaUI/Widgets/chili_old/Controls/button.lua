--//=============================================================================

Button = Control:Inherit{
  classname= "button",
  caption  = 'button',
  defaultWidth  = 70,
  defaultHeight = 20,
  noFont = false,
}

local this = Button
local inherited = this.inherited

--//=============================================================================

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
