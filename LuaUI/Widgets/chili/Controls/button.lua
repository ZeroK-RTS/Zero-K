--//=============================================================================

Button = Control:Inherit{
  classname= "button",
  caption  = 'button',
  defaultWidth  = 70,
  defaultHeight = 20,
}

local this = Button
local inherited = this.inherited

--//=============================================================================

function Button:SetCaption(caption)
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
  self._down = true
  self.state = 'pressed'
  inherited.MouseDown(self, ...)
  self:Invalidate()
  return self
end

function Button:MouseUp(...)
  if (self._down) then
    self._down = false
    self.state = 'normal'
    inherited.MouseUp(self, ...)
    self:Invalidate()
    return self
  end
end

--//=============================================================================