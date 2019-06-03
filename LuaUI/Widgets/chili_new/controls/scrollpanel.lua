--//=============================================================================

--- ScrollPanel module

--- ScrollPanel fields.
-- Inherits from Control.
-- @see control.Control
-- @table ScrollPanel
-- @int[opt=12] scrollBarSize size of the scrollbar
-- @int[opt=0] scrollPosX position of the scrollbar
-- @int[opt=0] scrollPosY position of the scrollbar
-- @bool[opt=true] verticalScrollbar the vertical scroll bar is enabled
-- @bool[opt=true] horizontalScrollbar the horizontal scroll bar is enabled
-- @bool[opt=true] smoothScroll smooth scroll is enabled
-- @bool[opt=false] verticalSmartScroll if control is scrolled to bottom, keep scroll when layout changes
-- @number[opt=0.7] smoothScrollTime time of the smooth scroll, in seconds
-- @bool[opt=false] ignoreMouseWheel mouse wheel scrolling is enabled
ScrollPanel = Control:Inherit{
  classname     = "scrollpanel",
  padding       = {0,0,0,0},
  backgroundColor = {0,0,0,0},
  scrollbarSize = 12,
  scrollPosX    = 0,
  scrollPosY    = 0,
  verticalScrollbar   = true,
  horizontalScrollbar = true,
  verticalSmartScroll = false, 
  smoothScroll     = true,
  smoothScrollTime = 0.7, 
  ignoreMouseWheel = false,
}

local this = ScrollPanel
local inherited = this.inherited

--//=============================================================================

local function smoothstep(x)
  return x*x*(3 - 2*x)
end

--//=============================================================================

--- Sets the scroll position
-- @int x x position
-- @int y y position
function ScrollPanel:SetScrollPos(x,y,inview,smoothscroll)
  local dosmooth = self.smoothScroll and (smoothscroll or (smoothscroll == nil))
  if dosmooth then
    self._oldScrollPosX = self.scrollPosX
    self._oldScrollPosY = self.scrollPosY
  end

  if (x) then
    if (inview) then
      x = x - self.clientArea[3] * 0.5
    end
    self.scrollPosX = x
    if (self.contentArea) then
      self.scrollPosX = clamp(0, self.contentArea[3] - self.clientArea[3], self.scrollPosX)
    end
  end
  if (y) then
    if (inview) then
      y = y - self.clientArea[4] * 0.5
    end
    self.scrollPosY = y
    if (self.contentArea) then
      self.scrollPosY = clamp(0, self.contentArea[4] - self.clientArea[4], self.scrollPosY)
    end
  end

  if dosmooth then
    if (self._oldScrollPosX ~= self.scrollPosX)or(self._oldScrollPosY ~= self.scrollPosY) then
      self._smoothScrollEnd = Spring.GetTimer()
      self._newScrollPosX = self.scrollPosX
      self._newScrollPosY = self.scrollPosY
      self.scrollPosX = self._oldScrollPosX
      self.scrollPosY = self._oldScrollPosY
    end
  end

  self:InvalidateSelf()
end


function ScrollPanel:Update(...)
	local trans = 1
	if self.smoothScroll and self._smoothScrollEnd then
		local trans = Spring.DiffTimers(Spring.GetTimer(), self._smoothScrollEnd)
		trans = trans / self.smoothScrollTime

		if (trans >= 1) then
			self.scrollPosX = self._newScrollPosX
			self.scrollPosY = self._newScrollPosY
			self._smoothScrollEnd = nil
		else
			for n=1,3 do trans = smoothstep(trans) end
			self.scrollPosX = self._oldScrollPosX * (1 - trans) + self._newScrollPosX * trans
			self.scrollPosY = self._oldScrollPosY * (1 - trans) + self._newScrollPosY * trans
			self:InvalidateSelf()
		end
	end

	inherited.Update(self, ...)
end

--//=============================================================================

function ScrollPanel:LocalToClient(x,y)
  local ca = self.clientArea
  return x - ca[1] + self.scrollPosX, y - ca[2] + self.scrollPosY
end


function ScrollPanel:ClientToLocal(x,y)
  local ca = self.clientArea
  return x + ca[1] - self.scrollPosX, y + ca[2] - self.scrollPosY
end


function ScrollPanel:ParentToClient(x,y)
  local ca = self.clientArea
  return x - self.x - ca[1] + self.scrollPosX, y - self.y - ca[2] + self.scrollPosY
end


function ScrollPanel:ClientToParent(x,y)
  local ca = self.clientArea
  return x + self.x + ca[1] - self.scrollPosX, y + self.y + ca[2] - self.scrollPosY
end

--//=============================================================================

function ScrollPanel:GetCurrentExtents()
  local left = self.x
  local top  = self.y
  local right  = self.x + self.width
  local bottom = self.y + self.height

  if (left   < minLeft)   then minLeft   = left end
  if (top    < minTop )   then minTop    = top end

  if (right  > maxRight)  then maxRight  = right end
  if (bottom > maxBottom) then maxBottom = bottom end

  return minLeft, minTop, maxRight, maxBottom
end

--//=============================================================================

function ScrollPanel:_DetermineContentArea()
  local minLeft, minTop, maxRight, maxBottom = self:GetChildrenCurrentExtents()

  self.contentArea = {
    0,
    0,
    maxRight,
    maxBottom,
  }

  local contentArea = self.contentArea
  local clientArea = self.clientArea

  if (self.verticalScrollbar) then
    if (contentArea[4]>clientArea[4]) then
      if (not self._vscrollbar) then
        self.padding[3] = self.padding[3] + self.scrollbarSize
      end
      self._vscrollbar = true
    else
      if (self._vscrollbar) then
        self.padding[3] = self.padding[3] - self.scrollbarSize
      end
      self._vscrollbar = false
    end
  end

  if (self.horizontalScrollbar) then
    if (contentArea[3]>clientArea[3]) then
      if (not self._hscrollbar) then
        self.padding[4] = self.padding[4] + self.scrollbarSize
      end
      self._hscrollbar = true
    else
      if (self._hscrollbar) then
        self.padding[4] = self.padding[4] - self.scrollbarSize
      end
      self._hscrollbar = false
    end
  end

  self:UpdateClientArea()

  local contentArea = self.contentArea
  local clientArea = self.clientArea
  if (contentArea[4] < clientArea[4]) then
    contentArea[4] = clientArea[4]
  end
  if (contentArea[3] < clientArea[3]) then
    contentArea[3] = clientArea[3]
  end
end

--//=============================================================================


function ScrollPanel:UpdateLayout()
  --self:_DetermineContentArea()
  self:RealignChildren()
  local before = ((self._vscrollbar and 1) or 0) + ((self._hscrollbar and 2) or 0)
  self:_DetermineContentArea()
  local now = ((self._vscrollbar and 1) or 0) + ((self._hscrollbar and 2) or 0)
  if (before ~= now) then
    self:RealignChildren()
  end

  self.scrollPosX = clamp(0, self.contentArea[3] - self.clientArea[3], self.scrollPosX)

  local oldClamp = self.clampY or 0
  self.clampY = self.contentArea[4] - self.clientArea[4]

  if self.verticalSmartScroll and self.scrollPosY >= oldClamp then
    self.scrollPosY = self.clampY
  else
    self.scrollPosY = clamp(0, self.clampY, self.scrollPosY)
  end

  return true;
end

--//=============================================================================


function ScrollPanel:IsRectInView(x,y,w,h)
	if (not self.parent) then
		return false
	end

	if self._inrtt then
		return true
	end

	--//FIXME 1. don't create tables 2. merge somehow into Control:IsRectInView
	local cx = x - self.scrollPosX
	local cy = y - self.scrollPosY

	local rect1 = {cx,cy,w,h}
	local rect2 = {0,0,self.clientArea[3],self.clientArea[4]}
	local inview = AreRectsOverlapping(rect1,rect2)

	if not(inview) then
		return false
	end

	local px,py = self:ClientToParent(x,y)
	return (self.parent):IsRectInView(px,py,w,h)
end


--//=============================================================================

function ScrollPanel:DrawControl()
  --// gets overriden by the skin/theme
end


function ScrollPanel:_DrawInClientArea(fnc,...)
	local clientX,clientY,clientWidth,clientHeight = unpack4(self.clientArea)

	gl.PushMatrix()
	gl.Translate(clientX - self.scrollPosX, clientY - self.scrollPosY, 0)

	local sx,sy = self:LocalToScreen(clientX,clientY)
	sy = select(2,gl.GetViewSizes()) - (sy + clientHeight)

	if PushLimitRenderRegion(self, sx, sy, clientWidth, clientHeight) then
		fnc(...)
		PopLimitRenderRegion(self, sx, sy, clientWidth, clientHeight)
	end

	gl.PopMatrix()
end


--//=============================================================================

function ScrollPanel:IsAboveHScrollbars(x,y)
  if (not self._hscrollbar) then return false end
  return y >= (self.height - self.scrollbarSize) --FIXME
end


function ScrollPanel:IsAboveVScrollbars(x,y)
  if (not self._vscrollbar) then return false end
  return x >= (self.width - self.scrollbarSize) --FIXME
end


function ScrollPanel:HitTest(x, y)
  if self:IsAboveVScrollbars(x,y) then
    return self
  end
  if self:IsAboveHScrollbars(x,y) then
    return self
  end

  return inherited.HitTest(self, x, y)
end


function ScrollPanel:MouseDown(x, y, ...)
  if self:IsAboveVScrollbars(x,y) then
    self._vscrolling  = true
    local clientArea = self.clientArea
    local cy = y - clientArea[2]
    self:SetScrollPos(nil, (cy/clientArea[4])*self.contentArea[4], true, false)
    return self
  end
  if self:IsAboveHScrollbars(x,y) then
    self._hscrolling  = true
    local clientArea = self.clientArea
    local cx = x - clientArea[1]
    self:SetScrollPos((cx/clientArea[3])*self.contentArea[3], nil, true, false)
    return self
  end

  return inherited.MouseDown(self, x, y, ...)
end


function ScrollPanel:MouseMove(x, y, dx, dy, ...)
  if self._vscrolling then
    local clientArea = self.clientArea
    local cy = y - clientArea[2]
    self:SetScrollPos(nil, (cy/clientArea[4])*self.contentArea[4], true, false)
    return self
  end
  if self._hscrolling then
    local clientArea = self.clientArea
    local cx = x - clientArea[1]
    self:SetScrollPos((cx/clientArea[3])*self.contentArea[3], nil, true, false)
    return self
  end

  local old = (self._hHovered and 1 or 0) + (self._vHovered and 2 or 0)
  self._hHovered = self:IsAboveHScrollbars(x,y)
  self._vHovered = self:IsAboveVScrollbars(x,y)
  local new = (self._hHovered and 1 or 0) + (self._vHovered and 2 or 0)
  if (new ~= old) then
    self:InvalidateSelf()
  end

  return inherited.MouseMove(self, x, y, dx, dy, ...)
end


function ScrollPanel:MouseUp(x, y, ...)
  if self._vscrolling then
    self._vscrolling = nil
    local clientArea = self.clientArea
    local cy = y - clientArea[2]
    self:SetScrollPos(nil, (cy/clientArea[4])*self.contentArea[4], true, false)
    return self
  end
  if self._hscrolling then
    self._hscrolling = nil
    local clientArea = self.clientArea
    local cx = x - clientArea[1]
    self:SetScrollPos((cx/clientArea[3])*self.contentArea[3], nil, true, false)
    return self
  end

  return inherited.MouseUp(self, x, y, ...)
end


function ScrollPanel:MouseWheel(x, y, up, value, ...)
  if self._vscrollbar and not self.ignoreMouseWheel then
    self:SetScrollPos(nil, self.scrollPosY - value*30, false, false)
    return self
  end

  return inherited.MouseWheel(self, x, y, up, value, ...)
end


function ScrollPanel:MouseOut(...)
	inherited.MouseOut(self, ...)
	self._hHovered = false
	self._vHovered = false
	self:InvalidateSelf()
end
