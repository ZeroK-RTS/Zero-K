--//=============================================================================

--- Object module

--- Object fields.
-- @table Object
-- @bool[opt=true] visible control is displayed
-- @tparam {Object1,Object2,...} children table of visible children objects (default {})
-- @tparam {Object1,Object2,...} children_hidden table of invisible children objects (default {})
-- @tparam {"obj1Name"=Object1,"obj2Name"=Object2,...} childrenByName table mapping name->child
-- @tparam {func1,func2,...} OnDispose  function listeners for object disposal, (default {})
-- @tparam {func1,func2,...} OnClick  function listeners for mouse click, (default {})
-- @tparam {func1,func2,...} OnDblClick  function listeners for mouse double click, (default {})
-- @tparam {func1,func2,...} OnMouseDown  function listeners for mouse press, (default {})
-- @tparam {func1,func2,...} OnMouseUp  function listeners for mouse release, (default {})
-- @tparam {func1,func2,...} OnMouseMove  function listeners for mouse movement, (default {})
-- @tparam {func1,func2,...} OnMouseWheel  function listeners for mouse scrolling, (default {})
-- @tparam {func1,func2,...} OnMouseOver  function listeners for mouse over...?, (default {})
-- @tparam {func1,func2,...} OnMouseOut  function listeners for mouse leaving the object, (default {})
-- @tparam {func1,func2,...} OnKeyPress  function listeners for key press, (default {})
-- @tparam {func1,func2,...} OnFocusUpdate  function listeners for focus change, (default {})
-- @bool[opt=false] disableChildrenHitTest if set childrens are not clickable/draggable etc - their mouse events are not processed
Object = {
  classname = 'object',
  --x         = 0,
  --y         = 0,
  --width     = 10,
  --height    = 10,
  defaultWidth  = 10, --FIXME really needed?
  defaultHeight = 10,

  visible  = true,
  --hidden   = false, --// synonym for above

  preserveChildrenOrder = false, --// if false adding/removing children is much faster, but also the order (in the .children array) isn't reliable anymore

  children    = {},
  children_hidden = {},
  childrenByName = CreateWeakTable(),

  OnDispose       = {},
  OnClick         = {},
  OnDblClick      = {},
  OnMouseDown     = {},
  OnMouseUp       = {},
  OnMouseMove     = {},
  OnMouseWheel    = {},
  OnMouseOver     = {},
  OnMouseOut      = {},
  OnKeyPress      = {},
  OnTextInput     = {},
  OnFocusUpdate   = {},

  disableChildrenHitTest = false, --// if set childrens are not clickable/draggable etc - their mouse events are not processed
} 

do
  local __lowerkeys = {}
  Object.__lowerkeys = __lowerkeys
  for i,v in pairs(Object) do
    if (type(i)=="string") then
      __lowerkeys[i:lower()] = i
    end
  end
end

local this = Object
local inherited = this.inherited

--//=============================================================================
--// used to generate unique objects names

local cic = {} 
local function GetUniqueId(classname)
  local ci = cic[classname] or 0
  cic[classname] = ci + 1
  return ci
end

--//=============================================================================

--- Object constructor
-- @tparam Object obj the object table
function Object:New(obj)
  obj = obj or {}

  --// check if the user made some lower-/uppercase failures
  for i,v in pairs(obj) do
    if (not self[i])and(isstring(i)) then
      local correctName = self.__lowerkeys[i:lower()]
      if (correctName)and(obj[correctName] == nil) then
        obj[correctName] = v
      end
    end
  end

  --// give name
  if (not obj.name) then
    obj.name = self.classname .. GetUniqueId(self.classname)
  end

  --// make an instance
  for i,v in pairs(self) do --// `self` means the class here and not the instance!
    if (i ~= "inherited") then
      local t = type(v)
      local ot = type(obj[i])
      if (t=="table")or(t=="metatable") then
        if (ot == "nil") then
          obj[i] = {};
          ot = "table";
        end
        if (ot ~= "table")and(ot ~= "metatable") then
          Spring.Echo("Chili: " .. obj.name .. ": Wrong param type given to " .. i .. ": got " .. ot .. " expected table.")
          obj[i] = {}
        end

        table.merge(obj[i],v)
        if (t=="metatable") then
          setmetatable(obj[i], getmetatable(v))
        end
      elseif (ot == "nil") then
        obj[i] = v
      end
    end
  end
  setmetatable(obj,{__index = self})

  --// auto dispose remaining Dlists etc. when garbage collector frees this object
  local hobj = MakeHardLink(obj)

  --// handle children & parent
  local parent = obj.parent
  if (parent) then
    obj.parent = nil
    --// note: we are using the hardlink here,
    --//       else the link could get gc'ed and dispose our object
    parent:AddChild(hobj)
  end
  local cn = obj.children
  obj.children = {}
  for i=1,#cn do
    obj:AddChild(cn[i],true)
  end

  --// sets obj._widget
  DebugHandler:RegisterObject(obj)

  return hobj
end


--- Disposes of the object.
-- Calling this releases unmanaged resources like display lists and disposes of the object.
-- Children are disposed too.
-- TODO: use scream, in case the user forgets.
-- nil -> nil
function Object:Dispose(_internal)
  if (not self.disposed) then

    --// check if the control is still referenced (if so it would indicate a bug in chili's gc)
    if _internal then
      if self._hlinks and next(self._hlinks) then
        local hlinks_cnt = table.size(self._hlinks)
        local i,v = next(self._hlinks)
        if hlinks_cnt > 1 or (v ~= self) then --// check if user called Dispose() directly
          Spring.Echo(("Chili: tried to dispose \"%s\"! It's still referenced %i times!"):format(self.name, hlinks_cnt))
        end
      end
    end
 
    self:CallListeners(self.OnDispose)

    self.disposed = true

    TaskHandler.RemoveObject(self)
    --DebugHandler:UnregisterObject(self) --// not needed

    if (UnlinkSafe(self.parent)) then
      self.parent:RemoveChild(self)
    end
    self:SetParent(nil)
    self:ClearChildren()
  end
end


function Object:AutoDispose()
  self:Dispose(true)
end


function Object:Clone()
  local newinst = {}
   -- FIXME
  return newinst
end


function Object:Inherit(class)
  class.inherited = self

  for i,v in pairs(self) do
    if (class[i] == nil)and(i ~= "inherited")and(i ~= "__lowerkeys") then
      t = type(v)
      if (t == "table") --[[or(t=="metatable")--]] then
        class[i] = table.shallowcopy(v)
      else
        class[i] = v
      end
    end
  end

  local __lowerkeys = {}
  class.__lowerkeys = __lowerkeys
  for i,v in pairs(class) do
    if (type(i)=="string") then
      __lowerkeys[i:lower()] = i
    end
  end

  --setmetatable(class,{__index=self})

  --// backward compability with old DrawControl gl state (change was done with v2.1)
  local w = DebugHandler.GetWidgetOrigin()
  if (w ~= widget)and(w ~= Chili) then
	class._hasCustomDrawControl = true
  end

  return class
end

--//=============================================================================

--- Sets the parent object
-- @tparam Object obj parent object
function Object:SetParent(obj)
  obj = UnlinkSafe(obj)
  local typ = type(obj)

  if (typ ~= "table") then
    self.parent = nil
    return
  end

  self.parent = MakeWeakLink(obj, self.parent)

  self:Invalidate()
end

--- Adds the child object
-- @tparam Object obj child object to be added
function Object:AddChild(obj, dontUpdate)
  local objDirect = UnlinkSafe(obj)

  if (self.children[objDirect]) then
    Spring.Echo(("Chili: tried to add multiple times \"%s\" to \"%s\"!"):format(obj.name, self.name))
    return
  end

  local hobj = MakeHardLink(objDirect)

  if (obj.name) then
    if (self.childrenByName[obj.name]) then
      error(("Chili: There is already a control with the name `%s` in `%s`!"):format(obj.name, self.name))
      return
    end
    self.childrenByName[obj.name] = hobj
  end

  if UnlinkSafe(obj.parent) then
    obj.parent:RemoveChild(obj)
  end
  obj:SetParent(self)

  local children = self.children
  local i = #children+1
  children[i] = objDirect
  children[hobj] = i
  children[objDirect] = i
  self:Invalidate()
end


--- Removes the child object
-- @tparam Object child child object to be removed
function Object:RemoveChild(child)
  if not isindexable(child) then
    return child
  end

  if CompareLinks(child.parent,self) then
    child:SetParent(nil)
  end

  local childDirect = UnlinkSafe(child)

  if (self.children_hidden[childDirect]) then
    self.children_hidden[childDirect] = nil
    return true
  end

  if (not self.children[childDirect]) then
    --Spring.Echo(("Chili: tried remove none child \"%s\" from \"%s\"!"):format(child.name, self.name))
    --Spring.Echo(DebugHandler.Stacktrace())
    return false
  end

  if (child.name) then
    self.childrenByName[child.name] = nil
  end

  for i,v in pairs(self.children) do
    if CompareLinks(childDirect,i) then
      self.children[i] = nil
    end
  end

  local children = self.children
  local cn = #children
  for i=1,cn do
    if CompareLinks(childDirect,children[i]) then
      if (self.preserveChildrenOrder) then
        --// slow
        table.remove(children, i)
      else
        --// fast
        children[i] = children[cn]
        children[cn] = nil
      end

      children[child] = nil --FIXME (unused/unuseful?)
      children[childDirect] = nil

      self:Invalidate()
      return true
    end
  end
  return false
end

--- Removes all children
function Object:ClearChildren()
  --// make it faster
  local old = self.preserveChildrenOrder
  self.preserveChildrenOrder = false

  --// remove all children  
    for i=1,#self.children_hidden do
      self:ShowChild(self.children_hidden[i])
    end

    for i=#self.children,1,-1 do
      self:RemoveChild(self.children[i])
    end

  --// restore old state
  self.preserveChildrenOrder = old
end

--- Specifies whether the object has any visible children
-- @treturn bool
function Object:IsEmpty()
  return (not self.children[1])
end

--//=============================================================================

--- Hides a specific child
-- @tparam Object obj child to be hidden
function Object:HideChild(obj)
  --FIXME cause of performance reasons it would be usefull to use the direct object, but then we need to cache the link somewhere to avoid the auto calling of dispose
  local objDirect = UnlinkSafe(obj)

  if (not self.children[objDirect]) then
    --if (self.debug) then
      Spring.Echo("Chili: tried to hide a non-child (".. (obj.name or "") ..")")
    --end
    return
  end

  if (self.children_hidden[objDirect]) then
    --if (self.debug) then
      Spring.Echo("Chili: tried to hide the same child multiple times (".. (obj.name or "") ..")")
    --end
    return
  end

  local hobj = MakeHardLink(objDirect)
  local pos = {hobj, 0, nil, nil}

  local children = self.children
  local cn = #children
  for i=1,cn+1 do
    if CompareLinks(objDirect,children[i]) then
      pos = {hobj, i, MakeWeakLink(children[i-1]), MakeWeakLink(children[i+1])}
      break
    end
  end

  self:RemoveChild(obj)
  self.children_hidden[objDirect] = pos
  obj.parent = self
end

--- Makes a specific child visible
-- @tparam Object obj child to be made visible
function Object:ShowChild(obj)
  --FIXME cause of performance reasons it would be usefull to use the direct object, but then we need to cache the link somewhere to avoid the auto calling of dispose
  local objDirect = UnlinkSafe(obj)

  if (not self.children_hidden[objDirect]) then
    --if (self.debug) then
      Spring.Echo("Chili: tried to show a non-child (".. (obj.name or "") ..")")
    --end
    return
  end

  if (self.children[objDirect]) then
    --if (self.debug) then
      Spring.Echo("Chili: tried to show the same child multiple times (".. (obj.name or "") ..")")
    --end
    return
  end

  local params = self.children_hidden[objDirect]
  self.children_hidden[objDirect] = nil

  local children = self.children
  local cn = #children

  if (params[3]) then
    for i=1,cn do
      if CompareLinks(params[3],children[i]) then
        self:AddChild(obj)
        self:SetChildLayer(obj,i+1)
        return true
      end
    end
  end

  self:AddChild(obj)
  self:SetChildLayer(obj,params[2])
  return true
end

--- Sets the visibility of the object
-- @bool visible visibility status
function Object:SetVisibility(visible)
  if (visible) then
    self.parent:ShowChild(self)
  else
    self.parent:HideChild(self)
  end
  self.visible = visible
  self.hidden  = not visible
end

--- Hides the objects
function Object:Hide()
  self:SetVisibility(false)
end

--- Makes the object visible
function Object:Show()
  self:SetVisibility(true)
end

--- Toggles object visibility
function Object:ToggleVisibility()
  self:SetVisibility(not self.visible)
end

--//=============================================================================

function Object:SetChildLayer(child,layer)
  child = UnlinkSafe(child)
  local children = self.children

  layer = math.min(layer, #children)

  --// it isn't at the same pos anymore, search it!
  for i=1,#children do
    if CompareLinks(children[i], child) then
      table.remove(children,i)
      break
    end
  end
  table.insert(children,layer,child)
  self:Invalidate()
end


function Object:SetLayer(layer)
  if (self.parent) then
    (self.parent):SetChildLayer(self, layer)
  end
end


function Object:BringToFront()
  self:SetLayer(1)
end

--//=============================================================================

function Object:InheritsFrom(classname)
  if (self.classname == classname) then
    return true
  elseif not self.inherited then
    return false
  else
    return self.inherited.InheritsFrom(self.inherited,classname)
  end
end

--//=============================================================================

--- Returns a child by name
-- @string name child name
-- @treturn Object child
function Object:GetChildByName(name)
  local cn = self.children
  for i=1,#cn do
    if (name == cn[i].name) then
      return cn[i]
    end
  end

  for c in pairs(self.children_hidden) do
    if (name == c.name) then
      return MakeWeakLink(c)
    end
  end
end

--// Backward-Compability
Object.GetChild = Object.GetChildByName


--- Resursive search to find an object by its name
-- @string name name of the object
-- @treturn Object
function Object:GetObjectByName(name)
  local r = self.childrenByName[name]
  if r then return r end

  for i=1,#self.children do
    local c = self.children[i]
    if (name == c.name) then
      return c
    else
      local result = c:GetObjectByName(name)
      if (result) then
        return result
      end
    end
  end

  for c in pairs(self.children_hidden) do
    if (name == c.name) then
      return MakeWeakLink(c)
    else
      local result = c:GetObjectByName(name)
      if (result) then
        return result
      end
    end
  end
end


--// Climbs the family tree and returns the first parent that satisfies a 
--// predicate function or inherites the given class.
--// Returns nil if not found.
function Object:FindParent(predicate)
  if not self.parent then
    return -- not parent with such class name found, return nil
  elseif (type(predicate) == "string" and (self.parent):InheritsFrom(predicate)) or
         (type(predicate) == "function" and predicate(self.parent)) then 
    return self.parent
  else
    return self.parent:FindParent(predicate)
  end
end


function Object:IsDescendantOf(object, _already_unlinked)
  if (not _already_unlinked) then
    object = UnlinkSafe(object)
  end
  if (UnlinkSafe(self) == object) then
    return true
  end
  if (self.parent) then
    return (self.parent):IsDescendantOf(object, true)
  end
  return false
end


function Object:IsAncestorOf(object, _level, _already_unlinked)
  _level = _level or 1

  if (not _already_unlinked) then
    object = UnlinkSafe(object)
  end

  local children = self.children

  for i=1,#children do
    if (children[i] == object) then
      return true, _level
    end
  end

  _level = _level + 1
  for i=1,#children do
    local c = children[i]
    local res,lvl = c:IsAncestorOf(object, _level, true)
    if (res) then
      return true, lvl
    end
  end

  return false
end

--//=============================================================================

function Object:CallListeners(listeners, ...)
  for i=1,#listeners do
    local eventListener = listeners[i]
    if eventListener(self, ...) then
      return true
    end
  end
end


function Object:CallListenersInverse(listeners, ...)
  for i=#listeners,1,-1 do
    local eventListener = listeners[i]
    if eventListener(self, ...) then
      return true
    end
  end
end


function Object:CallChildren(eventname, ...)
  local children = self.children
  for i=1,#children do
    local child = children[i]
    if (child) then
      local obj = child[eventname](child, ...)
      if (obj) then
        return obj
      end
    end
  end
end


function Object:CallChildrenInverse(eventname, ...)
  local children = self.children
  for i=#children,1,-1 do
    local child = children[i]
    if (child) then
      local obj = child[eventname](child, ...)
      if (obj) then
        return obj
      end
    end
  end
end


function Object:CallChildrenInverseCheckFunc(checkfunc,eventname, ...)
  local children = self.children
  for i=#children,1,-1 do
    local child = children[i]
    if (child)and(checkfunc(self,child)) then
      local obj = child[eventname](child, ...)
      if (obj) then
        return obj
      end
    end
  end
end


local function InLocalRect(cx,cy,w,h)
  return (cx>=0)and(cy>=0)and(cx<=w)and(cy<=h)
end


function Object:CallChildrenHT(eventname, x, y, ...)
  if self.disableChildrenHitTest then
    return nil
  end
  local children = self.children
  for i=1,#children do
    local c = children[i]
    if (c) then
      local cx,cy = c:ParentToLocal(x,y)
      if InLocalRect(cx,cy,c.width,c.height) and c:HitTest(cx,cy) then
        local obj = c[eventname](c, cx, cy, ...)
        if (obj) then
          return obj
        end
      end
    end
  end
end


function Object:CallChildrenHTWeak(eventname, x, y, ...)
  if self.disableChildrenHitTest then
    return nil
  end
  local children = self.children
  for i=1,#children do
    local c = children[i]
    if (c) then
      local cx,cy = c:ParentToLocal(x,y)
      if InLocalRect(cx,cy,c.width,c.height) then
        local obj = c[eventname](c, cx, cy, ...)
        if (obj) then
          return obj
        end
      end
    end
  end
end

--//=============================================================================

function Object:RequestUpdate()
  --// we have something todo in Update
  --// so we register this object in the taskhandler
  TaskHandler.RequestUpdate(self)
end


function Object:Invalidate()
  --FIXME should be Control only
end


function Object:Draw()
  self:CallChildrenInverse('Draw')
end


function Object:TweakDraw()
  self:CallChildrenInverse('TweakDraw')
end

--//=============================================================================

function Object:LocalToParent(x,y)
  return x + self.x, y + self.y
end


function Object:ParentToLocal(x,y)
  return x - self.x, y - self.y
end


Object.ParentToClient = Object.ParentToLocal
Object.ClientToParent = Object.LocalToParent


function Object:LocalToClient(x,y)
  return x,y
end


function Object:LocalToScreen(x,y)
  if (not self.parent) then
    return x,y
  end
  --Spring.Echo((not self.parent) and debug.traceback())
  return (self.parent):ClientToScreen(self:LocalToParent(x,y))
end


function Object:ClientToScreen(x,y)
  if (not self.parent) then
    return self:ClientToParent(x,y)
  end
  return (self.parent):ClientToScreen(self:ClientToParent(x,y))
end


function Object:ScreenToLocal(x,y)
  if (not self.parent) then
    return self:ParentToLocal(x,y)
  end
  return self:ParentToLocal((self.parent):ScreenToClient(x,y))
end


function Object:ScreenToClient(x,y)
  if (not self.parent) then
    return self:ParentToClient(x,y)
  end
  return self:ParentToClient((self.parent):ScreenToClient(x,y))
end


function Object:LocalToObject(x, y, obj)
  if CompareLinks(self,obj) then
    return x, y
  end
  if (not self.parent) then
    return -1,-1
  end
  x, y = self:LocalToParent(x, y)
  return self.parent:LocalToObject(x, y, obj)
end

--//=============================================================================

function Object:_GetMaxChildConstraints(child)
  return 0, 0, self.width, self.height
end

--//=============================================================================


function Object:HitTest(x,y)
  if not self.disableChildrenHitTest then 
    local children = self.children
    for i=1,#children do
      local c = children[i]
      if (c) then
        local cx,cy = c:ParentToLocal(x,y)
        if InLocalRect(cx,cy,c.width,c.height) then
          local obj = c:HitTest(cx,cy)
          if (obj) then
            return obj
          end
        end
      end
    end
  end 

  return false
end


function Object:IsAbove(x, y, ...)
  return self:HitTest(x,y)
end


function Object:MouseMove(...)
  if (self:CallListeners(self.OnMouseMove, ...)) then
    return self
  end

  return self:CallChildrenHT('MouseMove', ...)
end


function Object:MouseDown(...)
  if (self:CallListeners(self.OnMouseDown, ...)) then
    return self
  end

  return self:CallChildrenHT('MouseDown', ...)
end


function Object:MouseUp(...)
  if (self:CallListeners(self.OnMouseUp, ...)) then
    return self
  end

  return self:CallChildrenHT('MouseUp', ...)
end


function Object:MouseClick(...)
  if (self:CallListeners(self.OnClick, ...)) then
    return self
  end

  return self:CallChildrenHT('MouseClick', ...)
end


function Object:MouseDblClick(...)
  if (self:CallListeners(self.OnDblClick, ...)) then
    return self
  end

  return self:CallChildrenHT('MouseDblClick', ...)
end


function Object:MouseWheel(...)
  if (self:CallListeners(self.OnMouseWheel, ...)) then
    return self
  end

  return self:CallChildrenHTWeak('MouseWheel', ...)
end


function Object:MouseOver(...)
  if (self:CallListeners(self.OnMouseOver, ...)) then
    return self
  end
end


function Object:MouseOut(...)
  if (self:CallListeners(self.OnMouseOut, ...)) then
    return self
  end
end


function Object:KeyPress(...)
  if (self:CallListeners(self.OnKeyPress, ...)) then
    return self
  end

  return false
end


function Object:TextInput(...)
  if (self:CallListeners(self.OnTextInput, ...)) then
    return self
  end

  return false
end


function Object:FocusUpdate(...)
  if (self:CallListeners(self.OnFocusUpdate, ...)) then
    return self
  end

  return false
end

--//=============================================================================

