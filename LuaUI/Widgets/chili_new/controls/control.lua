--//=============================================================================

Control = Object:Inherit{
  classname       = 'control',
  padding         = {5, 5, 5, 5},
  borderThickness = 1.5,
  borderColor     = {1.0, 1.0, 1.0, 0.6},
  borderColor2    = {0.0, 0.0, 0.0, 0.8},
  backgroundColor = {0.8, 0.8, 1.0, 0.4},
  focusColor      = {0.2, 0.2, 1.0, 0.6},

  autosize        = false,
  savespace       = true, --// iff autosize==true, it shrinks the control to the minimum needed space, if disabled autosize _normally_ only enlarges the control
  resizeGripSize  = {11, 11},
  dragGripSize    = {10, 10},

  dragUseGrip      = false,
  draggable        = false,
  resizable        = false,
  tweakDragUseGrip = false,
  tweakDraggable   = false,
  tweakResizable   = false,

  minWidth        = 10,
  minHeight       = 10,
  maxWidth        = 1e9,
  maxHeight       = 1e9,

  fixedRatio      = false,
  tooltip         = nil, --// JUST TEXT

  useDList        = true,
  safeOpengl      = true, --// enables scissors

  font = {
    font          = "FreeSansBold.otf",
    size          = 14,
    shadow        = false,
    outline       = false,
    outlineWidth  = 3,
    outlineWeight = 3,
    color         = {1,1,1,1},
    outlineColor  = {0,0,0,1},
    autoOutlineColor = true,
  },

  state = {
    focused  = false,
    hovered  = false,
    checked  = false,
    selected = false, --FIXME implement
    pressed  = false,
    enabled  = true, --FIXME implement
  },

  skin            = nil,
  skinName        = nil,

  OnResize        = {},

  noFont = true,
}

local this = Control
local inherited = this.inherited

--//=============================================================================

function Control:New(obj)
  --// backward compability
  BackwardCompa(obj)
  
  --//minimum size from minimum size table when minWidth & minHeight is not set (backward compatibility)
  local minimumSize = obj.minimumSize or {} 
  obj.minWidth = obj.minWidth or minimumSize[1] 
  obj.minHeight = obj.minHeight or minimumSize[2]

  --// load the skin for this control
  obj.classname = obj.classname or self.classname
  theme.LoadThemeDefaults(obj)
  SkinHandler.LoadSkin(obj, self)

  --// we want to initialize the children ourself (see downwards)
  local cn = obj.children
  obj.children = nil

  obj = inherited.New(self,obj)

  local p = obj.padding
  if (obj.clientWidth) then
    obj.width = obj.clientWidth + p[1] + p[3]
  end
  if (obj.clientHeight) then
    obj.height = obj.clientHeight + p[2] + p[4]
  end

  -- We don't create fonts for controls that don't need them
  -- This should drastically use memory usage for some cases
  if obj.noFont then
    obj.font = nil
  else
    if obj.objectOverrideFont then
      obj.font = obj.objectOverrideFont
    else
      --// create font
      obj.font = Font:New(obj.font)
      obj.font:SetParent(obj)
    end
  end

  obj:DetectRelativeBounds()
  obj:AlignControl()

  --// add children after UpdateClientArea! (so relative width/height can be applied correctly)
  if (cn) then
    for i=1,#cn do
      obj:AddChild(cn[i], true)
    end
  end

  if WG.ChiliRedraw then
    WG.ChiliRedraw.AddControl(obj, "New")
  end

  return obj
end


function Control:Dispose(...)
  if (self._all_dlist) then
    gl.DeleteList(self._all_dlist)
    self._all_dlist = nil
  end
  if (self._children_dlist) then
    gl.DeleteList(self._children_dlist)
    self._children_dlist = nil
  end
  if (self._own_dlist) then
    gl.DeleteList(self._own_dlist)
    self._own_dlist = nil
  end

  inherited.Dispose(self,...)
  if (not self.noFont) and (not self.objectOverrideFont) and self.font and self.font.SetParent then
    self.font:SetParent()
  end
end

--//=============================================================================

function Control:SetParent(obj)
  inherited.SetParent(self,obj)
  self:RequestRealign()
end

function Control:AddChild(obj, dontUpdate, index)
  inherited.AddChild(self,obj, dontUpdate, index)
  if (not dontUpdate) then
    self:RequestRealign()
  end
end

function Control:RemoveChild(obj)
  local found  = inherited.RemoveChild(self,obj)
  if (found) then
    self:RequestRealign()
  end
  return found
end

--//=============================================================================

function Control:Invalidate()
  self._needRedraw = true
  self:RequestUpdate()
end

--//=============================================================================

function Control:_GetMaxChildConstraints(child)
  return 0, 0, self.clientWidth, self.clientHeight
end


function Control:DetectRelativeBounds()
  --// we need min 2 x-dim coords to define a rect!
  local numconstraints = 0
  if (self.x) then
    numconstraints = numconstraints + 1
  end
  if (self.right) then
    numconstraints = numconstraints + 1
  end
  if (self.width) then
    numconstraints = numconstraints + 1
  end
  if (numconstraints<2) then
    if (numconstraints==0) then
      self.x = 0
      self.width = self.defaultWidth or 0
    else
      if (self.width) then
        self.x = 0
      else
        self.width = self.defaultWidth or 0
      end
    end
  end

  --// we need min 2 y-dim coords to define a rect!
  numconstraints = 0
  if (self.y) then
    numconstraints = numconstraints + 1
  end
  if (self.bottom) then
    numconstraints = numconstraints + 1
  end
  if (self.height) then
    numconstraints = numconstraints + 1
  end
  if (numconstraints<2) then
    if (numconstraints==0) then
      self.y = 0
      self.height = self.defaultHeight or 0
    else
      if (self.height) then
        self.y = 0
      else
        self.height = self.defaultHeight or 0
      end
    end
  end

  --// check which constraints are relative
  self._givenBounds  = {
    left   = self.x,
    top    = self.y,
    width  = self.width,
    height = self.height,
    right  = self.right,
    bottom = self.bottom,
  }
  local rb = {
    left   = IsRelativeCoord(self.x) and self.x,
    top    = IsRelativeCoord(self.y) and self.y,
    width  = IsRelativeCoord(self.width) and self.width,
    height = IsRelativeCoord(self.height) and self.height,
    right  = self.right,
    bottom = self.bottom,
  }
  self._relativeBounds = rb
  self._isRelative = (rb.left or rb.top or rb.width or rb.height or rb.right or rb.bottom)and(true)

  --// initialize relative constraints with 0
  self.x = ((not rb.left) and self.x) or 0
  self.y = ((not rb.top)  and self.y) or 0
  self.width  = ((not rb.width) and self.width) or 0
  self.height = ((not rb.height) and self.height) or 0
  --self.right  = (type(self.right)=='number')and(self.right>0)and(self.right) or 0
  --self.bottom = (type(self.bottom)=='number')and(self.bottom>0)and(self.bottom) or 0
end


function Control:GetRelativeBox(savespace)
  local t = {self.x, self.y, self.width, self.height}
  if (savespace) then
    t = {0,0,self.minWidth,self.minHeight}
  end

  if (not self._isRelative) then
    return t
  end

  local p = self.parent
  if not p or not UnlinkSafe(p) then
    return t
  end

  --// FIXME use pl & pt too!!!
  local pl,pt,pw,ph = p:_GetMaxChildConstraints(self)

  local givBounds = self._givenBounds
  local relBounds = self._relativeBounds
  local left   = self.x
  local top    = self.y
  local width  = (savespace and self.minWidth) or self.width
  local height = (savespace and self.minHeight) or self.height

  --// ProcessRelativeCoord is defined in util.lua
  if (relBounds.left) then
    left = ProcessRelativeCoord(relBounds.left, pw)
  end
  if (relBounds.top) then
    top = ProcessRelativeCoord(relBounds.top, ph)
  end
  if (relBounds.width) then
    width = ProcessRelativeCoord(relBounds.width, pw)
  end
  if (relBounds.height) then
    height = ProcessRelativeCoord(relBounds.height, ph)
  end

  if (relBounds.right) then
    if (not givBounds.left) then
      left = pw - width - ProcessRelativeCoord(relBounds.right, pw)
    else
      width = pw - left - ProcessRelativeCoord(relBounds.right, pw)
    end
  end
  if (relBounds.bottom) then
    if (not givBounds.top) then
      top = ph - height - ProcessRelativeCoord(relBounds.bottom, ph)
    else
      height = ph - top - ProcessRelativeCoord(relBounds.bottom, ph)
    end
  end

  return {left, top, width, height}
end


--//=============================================================================

function Control:UpdateClientArea()
  local padding = self.padding

  self.clientWidth  = self.width  - padding[1] - padding[3]
  self.clientHeight = self.height - padding[2] - padding[4]

  self.clientArea = {
    padding[1],
    padding[2],
    self.clientWidth,
    self.clientHeight
  }

  if (self.parent)and(self.parent:InheritsFrom('control')) then
    --FIXME sometimes this makes self:RequestRealign() redundant! try to reduce the Align() calls somehow
    self.parent:RequestRealign()
  end
  local needResize = false
  if (self.width ~= self._oldwidth_uca)or(self.height ~= self._oldheight_uca) then
    self:RequestRealign()
    needResize = true
    self._oldwidth_uca  = self.width
    self._oldheight_uca = self.height
  end

  if (self.debug) then
    Spring.Echo(self.name, self.width, self.height, self._realignRequested)
  end

  self:Invalidate() --FIXME correct place?
  if needResize then
    self:CallListeners(self.OnResize, self.clientWidth, self.clientHeight)
  end
end


function Control:AlignControl()
  local newBox = self:GetRelativeBox()
  self:_UpdateConstraints(newBox[1], newBox[2], newBox[3], newBox[4])
end


function Control:RequestRealign(savespace)
  if (not self._inRealign) then
    self._realignRequested = true
    self.__savespace = savespace
    self:RequestUpdate()
  end
end


function Control:DisableRealign()
  self._realignDisabled = (self._realignDisabled or 0) + 1
end


function Control:EnableRealign()
  self._realignDisabled = ((self._realignDisabled or 0)>1 and self._realignDisabled - 1) or nil
  if (self._realignRequested) then
    self:Realign()
    self._realignRequested = nil
  end
end


function Control:Realign(savespace)
  if (not self._realignDisabled) then
    if (not self._inRealign) then
      self._savespace = savespace or self.savespace
      self._inRealign = true
      self:AlignControl() --FIXME still needed?
      local childrenAligned = self:UpdateLayout()
      self._realignRequested = nil
      if (not childrenAligned) then
        self:RealignChildren()
      end
      self._inRealign = nil
      self._savespace = nil
    end
  else
    self:RequestRealign(savespace)
  end
end


function Control:UpdateLayout()
  if (self.autosize) then
    self:RealignChildren(true)

    local neededWidth, neededHeight = self:GetChildrenMinimumExtents()

    local relativeBox = self:GetRelativeBox(self._savespace or self.savespace)
    neededWidth  = math.max(relativeBox[3], neededWidth)
    neededHeight = math.max(relativeBox[4], neededHeight)

    neededWidth  = neededWidth  - self.padding[1] - self.padding[3]
    neededHeight = neededHeight - self.padding[2] - self.padding[4]

    if (self.debug) then
      local cminextW, cminextH = self:GetChildrenMinimumExtents()
      Spring.Echo("Control:UpdateLayout", self.name,
		      "GetChildrenMinimumExtents", cminextW, cminextH,
		      "GetRelativeBox", relativeBox[3], relativeBox[4],
		      "savespace", self._savespace)
    end

    self:Resize(neededWidth, neededHeight, true, true)
    self:RealignChildren()
    self:AlignControl() --FIXME done twice!!! (1st in Realign)
    return true
  end
end


function Control:RealignChildren(savespace)
  self:CallChildren("Realign", savespace)
end

--//=============================================================================

function Control:SetPos(x, y, w, h, clientArea, dontUpdateRelative)
  local changed = false

  --//FIXME add an API for relative constraints changes
  if (x)and(type(x) == "number") then
    if (self.x ~= x) then
      self.x = x
      changed = true
    end
    if (not dontUpdateRelative) then
      if (self._relativeBounds.left ~= x) then
        self._relativeBounds.left = false
        self._givenBounds.left = x
        self._relativeBounds.right = false
        self._givenBounds.right = false
        changed = true
      end
    end
  end

  if (y)and(type(y) == "number") then
    if (self.y ~= y) then
      self.y = y
      changed = true
    end
    if (not dontUpdateRelative) then
      if (self._relativeBounds.top ~= y) then
        self._relativeBounds.top = false
        self._givenBounds.top = y
        self._relativeBounds.bottom = false
        self._givenBounds.bottom = false
        changed = true
      end
    end
  end


  if (w)and(type(w) == "number") then
    w = (clientArea)and(w+self.padding[1]+self.padding[3]) or (w)
    w = math.max( w, self.minWidth )
    w = math.min( w, self.maxWidth )
    if (self.width ~= w) then
      self.width = w
      changed = true
    end
    if (not dontUpdateRelative) then
      if (self._relativeBounds.width ~= w) then
        self._relativeBounds.width = IsRelativeCoord(w) and w
        self._givenBounds.width = w
        changed = true
      end
    end
  end

  if (h)and(type(h) == "number") then
    h = (clientArea)and(h+self.padding[2]+self.padding[4]) or (h)
    h = math.max( h, self.minHeight )
    h = math.min( h, self.maxHeight )
    if (self.height ~= h) then
      self.height = h
      changed = true
    end
    if (not dontUpdateRelative) then
      if (self._relativeBounds.height ~= h) then
        self._relativeBounds.height = IsRelativeCoord(h) and h
        self._givenBounds.height = h
        changed = true
      end
    end
  end

  if (changed)or(not self.clientArea) then
    self:UpdateClientArea()
  end
end


function Control:SetPosRelative(x, y, w, h, clientArea, dontUpdateRelative)
  local changed = false

  --//FIXME add an API for relative constraints changes
  if x then
    if (not IsRelativeCoord(x)) then
      if (self.x ~= x) then
        self.x = x
        changed = true
      end
    end
    if (not dontUpdateRelative) then
      if (self._relativeBounds.left ~= x) then
        self._relativeBounds.left = IsRelativeCoord(x) and x
        self._givenBounds.left = x
        changed = true
      end
    end
  end

  if y then
    if (not IsRelativeCoord(y)) then
      if (self.y ~= y) then
        self.y = y
        changed = true
      end
    end
    if (not dontUpdateRelative) then
      if (self._relativeBounds.top ~= y) then
        self._relativeBounds.top = IsRelativeCoord(y) and y
        self._givenBounds.top = y
        changed = true
      end
    end
  end


  if w then
    if (not IsRelativeCoord(w)) then
      w = (clientArea)and(w+self.padding[1]+self.padding[3]) or (w)
      w = math.max( w, self.minWidth )
      w = math.min( w, self.maxWidth )
      if (self.width ~= w) then
        self.width = w
        changed = true
      end
    end
    if (not dontUpdateRelative) then
      if (self._relativeBounds.width ~= w) then
        self._relativeBounds.width = IsRelativeCoord(w) and w
        self._givenBounds.width = w
        changed = true
      end
    end
  end

  if h then
    if (not IsRelativeCoord(h)) then
      h = (clientArea)and(h+self.padding[2]+self.padding[4]) or (h)
      h = math.max( h, self.minHeight )
      h = math.min( h, self.maxHeight )
      if (self.height ~= h) then
        self.height = h
        changed = true
      end
    end
    if (not dontUpdateRelative) then
      if (self._relativeBounds.height ~= h) then
        self._relativeBounds.height = IsRelativeCoord(h) and h
        self._givenBounds.height = h
        changed = true
      end
    end
  end

  if (changed)or(not self.clientArea) then
    self:UpdateClientArea()
  end
end

function Control:Resize(w, h, clientArea, dontUpdateRelative)
  self:SetPosRelative(nil, nil, w, h, clientArea, dontUpdateRelative)
end


function Control:_UpdateConstraints(x, y, w, h)
  --// internal used
  self:SetPos(x, y, w, h, false, true)
end


--//=============================================================================

function Control:GetMinimumExtents()
  local maxRight, maxBottom = 0,0
  if (self.autosize) then
    --// FIXME handle me correctly!!! (:= do the parent offset)
    maxRight, maxBottom = self:GetChildrenMinimumExtents()
  end

  if (not self._isRelative) then
    local right  = self.x + self.width
    local bottom = self.y + self.height

    maxRight  = math.max(maxRight,  right)
    maxBottom = math.max(maxBottom, bottom)
  else
    local cgb = self._givenBounds
    local crb = self._relativeBounds

    local left, width, right = 0,0,0
    if (not crb.width) then if (self.autosize) then width = self.width or 0 else width = cgb.width or 0 end end
    if (not crb.left)  then left  = cgb.left or 0 end
    if (not IsRelativeCoord(crb.right)) then right = crb.right or 0 end
    local totalWidth = left + width + right

    local top, height, bottom = 0,0,0
    if (not crb.height) then height = cgb.height or 0 end
    if (not crb.top)    then top    = cgb.top    or 0 end
    if (not IsRelativeCoord(crb.bottom)) then bottomt = crb.bottom or 0 end
    local totalHeight = top + height + bottom

--[[
    if (crb.width) then width = cgb.width or 0 end
    if (crb.left)  then left  = cgb.left or 0 end
    if (IsRelativeCoord(cgb.right)) then right = cgb.right or 0 end

    ...
--]]

    totalWidth  = math.max(totalWidth,  self.minWidth)
    totalHeight = math.max(totalHeight, self.minHeight)

    totalWidth  = math.min(totalWidth,  self.maxWidth)
    totalHeight = math.min(totalHeight, self.maxHeight)

    maxRight  = math.max(maxRight,  totalWidth)
    maxBottom = math.max(maxBottom, totalHeight)
  end

  return maxRight, maxBottom
end


function Control:GetChildrenMinimumExtents()
  local minWidth  = 0
  local minHeight = 0

  local cn = self.children
  for i=1,#cn do
    local c = cn[i]
    if (c.GetMinimumExtents) then
      local width, height = c:GetMinimumExtents()
      minWidth  = math.max(minWidth,  width)
      minHeight = math.max(minHeight, height)
    end
  end

  if (minWidth + minHeight > 0) then
    local padding = self.padding
    minWidth  = minWidth + padding[1] + padding[3]
    minHeight = minHeight + padding[2] + padding[4]
  end

  return minWidth, minHeight
end



function Control:GetCurrentExtents()
  local minLeft, minTop, maxRight, maxBottom = self:GetChildrenCurrentExtents()

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


function Control:GetChildrenCurrentExtents()
  local minLeft   = 0
  local minTop    = 0
  local maxRight  = 0
  local maxBottom = 0
 
  local cn = self.children
  for i=1,#cn do
    local c = cn[i]
    if (c.GetCurrentExtents) then
      local left, top, right, bottom = c:GetCurrentExtents()
      minLeft   = math.min(minLeft,   left)
      minTop    = math.min(minTop,    top)
      maxRight  = math.max(maxRight,  right)
      maxBottom = math.max(maxBottom, bottom)
    end
  end

  return minLeft, minTop, maxRight, maxBottom
end

--//=============================================================================

function Control:StartResizing(x,y)
  --//FIXME the x,y aren't needed check how drag is handled!
  self.resizing = {
    mouse = {x, y}, 
    size  = {self.width, self.height},
    pos   = {self.x, self.y},
  }
end


function Control:StopResizing(x,y)
  self.resizing = false
end


function Control:StartDragging(x,y)
  self.dragging = true
end


function Control:StopDragging(x,y)
  self.dragging = false
end

--//=============================================================================

function Control:LocalToClient(x,y)
  local ca = self.clientArea
  return x - ca[1], y - ca[2]
end


function Control:ClientToLocal(x,y)
  local ca = self.clientArea
  return x + ca[1], y + ca[2]
end


function Control:ParentToClient(x,y)
  local ca = self.clientArea
  return x - self.x - ca[1], y - self.y - ca[2] 
end


function Control:ClientToParent(x,y)
  local ca = self.clientArea
  return x + self.x + ca[1], y + self.y + ca[2] 
end


function Control:InClientArea(x,y)
  local clientArea = self.clientArea
  return x>=clientArea[1]               and y>=clientArea[2] and
         x<=clientArea[1]+clientArea[3] and y<=clientArea[2]+clientArea[4]
end

--//=============================================================================

function Control:Update()
	if (self._realignRequested) then
		self:Realign(self.__savespace)
		self._realignRequested = nil
	end

	if (self._needRedraw)and(self:IsInView()) then
		if (self.useDList) then
			--//FIXME don't recreate the own displaylist each time we _move_ a window
			self:_UpdateOwnDList()
			--self:_UpdateChildrenDList()
			self:_UpdateAllDList()
		end
		self._needRedraw = nil
	end
end


function Control:InstantUpdate()
	if self:IsInView() then
		if self._needRedraw then
			self:Update()
		else
			self:_UpdateAllDList()
		end
	end
end

--//=============================================================================

function Control:_UpdateOwnDList()
  if (not self.parent) then return end
  if not self:IsInView() then return end

  self:CallChildren('_UpdateOwnDList')

  if (self._needRedraw) then
    if (self._own_dlist) then
      gl.DeleteList(self._own_dlist)
      self._own_dlist = nil
    end

    self._own_dlist = gl.CreateList(self.DrawControl, self)

    self._needRedraw = nil
  end
end

--[[
function Control:_UpdateChildrenDList()
  if (self._children_dlist) then
    gl.DeleteList(self._children_dlist)
    self._children_dlist = nil
  end
  self._children_dlist = gl.CreateList(self.CallChildrenInverse, self, 'DrawForList')
end
--]]

function Control:_UpdateAllDList()
  if (not self.parent) then return end
  if not self:IsInView() then return end

  self._redrawCounter = (self._redrawCounter or 0) + 1

  if (self._all_dlist) then
    gl.DeleteList(self._all_dlist)
    self._all_dlist = nil
  end
  self._all_dlist = gl.CreateList(self.DrawForList,self)

  if (self.parent)and(not self.parent._needRedraw)and(self.parent._UpdateAllDList)and(self.parent.useDList) then
    TaskHandler.RequestInstantUpdate(self.parent)
  end
end

--//=============================================================================

function Control:_DrawInClientArea(fnc,...)
  local clientX,clientY,clientWidth,clientHeight = unpack4(self.clientArea)
  
  if WG.uiScale and WG.uiScale ~= 1 then
    clientWidth, clientHeight = clientWidth*WG.uiScale, clientHeight*WG.uiScale
  end
  
  if (self.safeOpengl) then
    local sx,sy = self:UnscaledLocalToScreen(clientX,clientY)
    sy = select(2,gl.GetViewSizes()) - (sy + clientHeight)

    PushScissor(sx,sy,math.ceil(clientWidth),math.ceil(clientHeight))
  end

  gl.PushMatrix()
  gl.Translate(math.floor(self.x + clientX),math.floor(self.y + clientY),0)
  fnc(...)
  gl.PopMatrix()

  if (self.safeOpengl) then
    PopScissor()
  end
end


function Control:IsInView()
	if UnlinkSafe(self.parent) then
		return self.parent:IsRectInView(self.x, self.y, self.width, self.height)
	end
	return false
end


function Control:IsChildInView(child)
	return self:IsRectInView(child.x, child.y, child.width, child.height)
end


function Control:IsRectInView(x,y,w,h)
	if not self.parent or not UnlinkSafe(self.parent) then 
		return false
	end

	local rect1 = {x,y,w,h}
	local rect2 = {0,0,self.clientArea[3],self.clientArea[4]}
	local inview = AreRectsOverlapping(rect1,rect2)

	if not(inview) then
		return false
	end

	local px,py = self:ClientToParent(x,y)
	return (self.parent):IsRectInView(px,py,w,h)
end


function Control:_DrawChildrenInClientArea(event)
	self:_DrawInClientArea(self.CallChildrenInverseCheckFunc, self, self.IsChildInView, event or 'Draw')
end

--//=============================================================================

--//FIXME move resize and drag to Window class!!!!
function Control:DrawBackground()
  --// gets overriden by the skin/theme
end

function Control:DrawDragGrip()
  --// gets overriden by the skin/theme
end

function Control:DrawResizeGrip()
  --// gets overriden by the skin/theme
end

function Control:DrawBorder()
  --// gets overriden by the skin/theme ??????
end


function Control:DrawGrips() -- FIXME this thing is a hack, fix it - todo ideally make grips appear only when mouse hovering over it
  local drawResizeGrip = self.resizable
  local drawDragGrip   = self.draggable and self.dragUseGrip
  --[[if IsTweakMode() then
    drawResizeGrip = drawResizeGrip or self.tweakResizable
    drawDragGrip   = (self.tweakDraggable and self.tweakDragUseGrip)
  end--]]

  if drawResizeGrip then
    self:DrawResizeGrip()
  end
  if drawDragGrip then
    self:DrawDragGrip()
  end
end


function Control:DrawControl()
  --//an option to make panel position snap to an integer
  if self.snapToGrid then 
    self.x = math.floor(self.x) + 0.5 
    self.y = math.floor(self.y) + 0.5 
  end 
  self:DrawBackground()
  self:DrawBorder()
end


function Control:DrawForList()
  if (self._own_dlist) then
    gl.CallList(self._own_dlist);
  else
    if WG.ChiliRedraw then
      WG.ChiliRedraw.AddControl(self, "DrawForList")
    end
    self:DrawControl();
  end

  if (self._children_dlist) then
    self:_DrawInClientArea(gl.CallList,self._children_dlist);
  else
    self:DrawChildrenForList();
  end

  if (self.DrawControlPostChildren) then
    self:DrawControlPostChildren();
  end

  self:DrawGrips();
end


function Control:Draw()
  if (self._all_dlist) then
    gl.CallList(self._all_dlist);
    return;
  end

  if (self._own_dlist) then
    gl.CallList(self._own_dlist);
  else
    if WG.ChiliRedraw then
      WG.ChiliRedraw.AddControl(self, "Draw")
    end
    self:DrawControl();
  end

  if (self._children_dlist) then
    self:_DrawInClientArea(gl.CallList,self._children_dlist);
  else
    self:DrawChildren();
  end

  if (self.DrawControlPostChildren) then
    self:DrawControlPostChildren();
  end

  self:DrawGrips();
end


function Control:TweakDraw()
  if (next(self.children)) then
    self:_DrawChildrenInClientArea('TweakDraw')
  end
end


function Control:DrawChildren()
  if (next(self.children)) then
    self:_DrawChildrenInClientArea('Draw')
  end
end


function Control:DrawChildrenForList()
  if (next(self.children)) then
    if WG.ChiliRedraw then
      WG.ChiliRedraw.AddControl(self, "DrawChildrenForList")
    end
    self:_DrawChildrenInClientArea('DrawForList')
  end
end

--//=============================================================================

local function InLocalRect(cx,cy,w,h)
  return (cx>=0)and(cy>=0)and(cx<=w)and(cy<=h)
end


function Control:HitTest(x,y)
  if (not self.disableChildrenHitTest) then
    if self:InClientArea(x,y) then
      local cax,cay = self:LocalToClient(x,y)
      local children = self.children
      for i=1,#children do
        local c = children[i]
        if (c) then
          local cx,cy = c:ParentToLocal(cax,cay)
          if InLocalRect(cx,cy,c.width,c.height) then
            local obj = c:HitTest(cx,cy)
            if (obj) then
              return obj
            end
          end
        end
      end
      --//an option that allow you to mouse click on empty panel
      if self.hitTestAllowEmpty then 
        return self 
      end
    end
  end

  if (self.NCHitTest) then
    local nchit = self:NCHitTest(x,y)
    if (nchit) then
      return nchit
    end
  end
  
  if self.noClickThrough and not IsTweakMode() then
    return self
  end
  
  return false
end


function Control:MouseDown(x, y, ...)
  if (self.NCMouseDown) then
    local result = self:NCMouseDown(x, y)
    if (result) then
      return result
    end
  end

  if (not self.disableChildrenHitTest) then
    if self:InClientArea(x,y) then
      local cx,cy = self:LocalToClient(x,y)
      local obj = inherited.MouseDown(self, cx, cy, ...)
      if (obj) then
        return obj
      end
    end
  end

  if (self.NCMouseDownPostChildren) then
    local result = self:NCMouseDownPostChildren(x, y)
    if (result) then
      return result
    end
  end

  if self.noClickThrough and not IsTweakMode() then
    return self
  end
end


function Control:MouseMove(x, y, dx, dy, ...)
  if self.dragging then
    self:SetPos(self.x + dx, self.y + dy)
    return self

  elseif self.resizing then
    local oldState = self.resizing
    local deltaMousePosX = x - oldState.mouse[1]
    local deltaMousePosY = y - oldState.mouse[2]

    local w = math.max(
      self.minWidth, 
      oldState.size[1] + deltaMousePosX
    )
    local h = math.max(
      self.minHeight,
      oldState.size[2] + deltaMousePosY
    )

    if self.fixedRatio == true then
      local ratioyx = self.height/self.width
      local ratioxy = self.width/self.height
      local oldSize = oldState.size
      local oldxy   = oldSize[1]/oldSize[2]
      local oldyx   = oldSize[2]/oldSize[1]
      if (ratioxy-oldxy < ratioyx-oldyx) then
        w = h*oldxy
      else
        h = w*oldyx
      end
    end

    self:SetPos(nil,nil,w,h)
    return self
  end

  local cx,cy = self:LocalToClient(x,y)
  return inherited.MouseMove(self, cx, cy, dx, dy, ...)
end


function Control:MouseUp(x, y, ...)
  self.resizing = nil
  self.dragging = nil
  local cx,cy = self:LocalToClient(x,y)
  return inherited.MouseUp(self, cx, cy, ...)
end


function Control:MouseClick(x, y, ...)
  local cx,cy = self:LocalToClient(x,y)
  return inherited.MouseClick(self, cx, cy, ...)
end


function Control:MouseDblClick(x, y, ...)
  local cx,cy = self:LocalToClient(x,y)
  return inherited.MouseDblClick(self, cx, cy, ...)
end


function Control:MouseWheel(x, y, ...)
  local cx,cy = self:LocalToClient(x,y)
  return inherited.MouseWheel(self, cx, cy, ...)
end


function Control:FocusUpdate(...)
  return inherited.FocusUpdate(self, ...)
end


function Control:MouseOver(...)
	inherited.MouseOver(self, ...)
	self.state.hovered = true
	self:Invalidate()
end


function Control:MouseOut(...)
	inherited.MouseOut(self, ...)
	self.state.hovered = false
	self:Invalidate()
end

--//=============================================================================
