--//=============================================================================

Progressbar = Control:Inherit{
  classname = "progressbar",

  defaultWidth     = 90,
  defaultHeight    = 20,

  min       = 0,
  max       = 100,
  value     = 100,
  orientation = "horizontal",
  reverse   = false,

  caption   = "",
  noFont = false,

  color     = {0,0,1,1},
  backgroundColor = {1,1,1,1},

  OnChange  = {},
}

local this = Progressbar
local inherited = this.inherited

--//=============================================================================

function Progressbar:New(obj)
  obj = inherited.New(self,obj)
  obj:SetMinMax(obj.min,obj.max)
  obj:SetValue(obj.value)
  return obj
end

--//=============================================================================

function Progressbar:_Clamp(v)
  if (self.min<self.max) then
    if (v<self.min) then
      v = self.min
    elseif (v>self.max) then
      v = self.max
    end
  else
    if (v>self.min) then
      v = self.min
    elseif (v<self.max) then
      v = self.max
    end
  end
  return v
end

--//=============================================================================

function Progressbar:SetColor(...)
  local color = _ParseColorArgs(...)
  table.merge(color,self.color)
  if (not table.iequal(color,self.color)) then
    self.color = color
    self:Invalidate()
  end
end


function Progressbar:SetMinMax(min,max)
  self.min = tonumber(min) or 0
  self.max = tonumber(max) or 1
  self:SetValue(self.value)
end


function Progressbar:SetValue(v,setcaption)
  v = self:_Clamp(v)
  local oldvalue = self.value
  if (v ~= oldvalue) then
    self.value = v

    if (setcaption) then
      self:SetCaption(v)
    end

    self:CallListeners(self.OnChange,v,oldvalue)
    self:Invalidate()
  end
end


function Progressbar:SetCaption(str)
  if (self.caption ~= str) then
    self.caption = str
    self:Invalidate()
  end
end

--//=============================================================================


function Progressbar:DrawControl()
  local percent = (self.value-self.min)/(self.max-self.min)
  local x = self.x
  local y = self.y
  local w = self.width
  local h = self.height

  gl.Color(self.backgroundColor)
  if (self.orientation == "horizontal") then
    if self.reverse then
      gl.Rect(x,y,x+w*(1-percent),y+h)
    else
      gl.Rect(x+w*percent,y,x+w,y+h)
    end
  else
    if self.reverse then
       gl.Rect(x,y,x+w,y+h*percent)
    else
      gl.Rect(x,y+h*(1-percent),x+w,y+h)
    end
  end

  gl.Color(self.color)
  if (self.orientation == "horizontal") then
    if self.reverse then
      gl.Rect(x+w*(1-percent),y,x+w,y+h)
    else
      gl.Rect(x,y,x+w*percent,y+h)
    end
  else
    if self.reverse then
      gl.Rect(x,y+h*percent,x+w,y+h)
    else
      gl.Rect(x,y,x+w,y+h*(1-percent))
    end
  end

  if (self.caption) and not self.noFont then
    (self.font):Print(self.caption, x+w*0.5, y+h*0.5, "center", "center")
  end
end


--//=============================================================================
