--//=============================================================================

--- Trackbar module

--- Trackbar fields.
-- Inherits from Control.
-- @see control.Control
-- @table Trackbar
-- @int[opt=0] min minimum value of the Trackbar
-- @int[opt=100] max maximum value of the Trackbar
-- @int[opt=50] value value of the Trackbar
-- @int[opt=50] step step value
-- @tparam {func1,fun2,...} OnChange function listeners for value change (default {})
Trackbar = Control:Inherit{
  classname = "trackbar",
  value     = 50,
  min       = 0,
  max       = 100,
  step      = 1,
  useValueTooltip = nil,

  defaultWidth     = 90,
  defaultHeight    = 20,

  hitpadding  = {0, 0, 0, 0},

  OnChange = {},
}

local this = Trackbar
local inherited = this.inherited

--//=============================================================================

local function FormatNum(num)
  if (num == 0) then
    return "0"
  else
    local strFormat = string.format
    local absNum = math.abs(num)
    if (absNum < 0.01) then
      return strFormat("%.3f", num)
    elseif (absNum < 1) then
      return strFormat("%.2f", num)
    elseif (absNum < 10) then
      return strFormat("%.1f", num)
    else
      return strFormat("%.0f", num)
    end
  end
end


function Trackbar:New(obj)
  obj = inherited.New(self,obj)

  if ((not obj.tooltip) or (obj.tooltip == '')) and (obj.useValueTooltip ~= false) then
    obj.useValueTooltip = true
  end

  obj:SetMinMax(obj.min,obj.max)
  obj:SetValue(obj.value)

  return obj
end

--//=============================================================================

function Trackbar:_Clamp(v)
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

function Trackbar:_GetPercent(x,y)
  if (x) then
    local pl,pt,pr,pb = unpack4(self.hitpadding)
    if (x<pl) then
      return 0
    end
    if (x>self.width-pr) then
      return 1
    end

    local cx = x - pl
    local barWidth = self.width - (pl + pr)

    return (cx/barWidth)
  else
    return (self.value-self.min)/(self.max-self.min)
  end
end

--//=============================================================================

--- Sets the minimum and maximum value of the track bar
-- @int[opt=0] min minimum value
-- @int[opt=1] max maximum value (why is 1 the default?)
function Trackbar:SetMinMax(min,max)
  self.min = tonumber(min) or 0
  self.max = tonumber(max) or 1
  self:SetValue(self.value)
end


--- Sets the value of the track bar
-- @int v value of the track abr
function Trackbar:SetValue(v)
  if type(v) ~= "number" then
    Spring.Log("Chili", "error", "Wrong param to Trackbar:SetValue(number v)")
    return
  end
  local r = v % self.step
  if (r > 0.5*self.step) then
    v = v + self.step - r
  else
    v = v - r
  end
  v = self:_Clamp(v)
  local oldvalue = self.value
  self.value = v
  if self.useValueTooltip then
    self.tooltip = "Current: "..FormatNum(self.value)
  end
  self:CallListeners(self.OnChange,v,oldvalue)
  self:Invalidate()
end

--//=============================================================================

function Trackbar:DrawControl()
end

--//=============================================================================

function Trackbar:HitTest()
  return self
end

function Trackbar:MouseDown(x,y,button)
  if (button==1) then
    inherited.MouseDown(self,x,y)
    local percent = self:_GetPercent(x,y)
    self:SetValue(self.min + percent*(self.max-self.min))
  end
  return self
end

function Trackbar:MouseMove(x,y,dx,dy,button)
  if (button==1) then
    inherited.MouseMove(self,x,y,dx,dy,button)
    local percent = self:_GetPercent(x,y)
    self:SetValue(self.min + percent*(self.max-self.min))
  end
  return self
end

--//=============================================================================
