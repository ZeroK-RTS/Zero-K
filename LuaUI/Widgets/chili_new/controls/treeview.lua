--//=============================================================================

--- TreeView module

--- TreeView fields.
-- Inherits from Control.
-- @see control.Control
-- @table TreeView
-- @bool[opt=true] autosize whether size is automatically determined
-- @int[opt=1] selected selected item
-- @tparam {TreeNode1,TreeNode2,...} nodes nodes of the tree
-- @tparam {func1,fun2,...} OnSelectNode function listeners for node selection (default {})
TreeView = Control:Inherit{
  classname = "treeview",

  autosize = true,

  minItemHeight = 16,

  defaultWidth  = "100%",
  defaultHeight = "100%",

  selected = 1,
  root = nil,
  nodes = {},

  defaultExpanded = false,

  OnSelectNode = {},
}

local this = TreeView
local inherited = this.inherited

--//=============================================================================

local function ParseInitTable(node, nodes)
  local lastnode = node
  for i=1,#nodes do
    local data = nodes[i]
    if (type(data)=="table") then
      ParseInitTable(lastnode, data)
    else
      lastnode = node:Add(data)
    end
  end
end


function TreeView:New(obj)
  local nodes = obj.nodes
  if (nodes) then
    obj.children = {}
  end

  obj = inherited.New(self,obj)

  obj.root = TreeViewNode:New{treeview = obj, root = true; minHeight = obj.minItemHeight; expanded = obj.defaultExpanded}
  if (nodes) then
    ParseInitTable(obj.root, nodes)
  end
  obj:AddChild(obj.root)

  obj:UpdateLayout()

  local sel = obj.selected
  obj.selected = false
  if ((sel or 0)>0) then
    obj:Select(sel)
  end

  return obj
end

--//=============================================================================

function TreeView:GetNodeByCaption(caption)
  return self.root:GetNodeByCaption(caption)
end


function TreeView:GetNodeByIndex(index)
  local result = self.root:GetNodeByIndex(index, 0)
  return (not IsNumber(result)) and result
end

--//=============================================================================

function TreeView:Select(item)
  local obj = UnlinkSafe(item)

  if (type(item) == "number") then
    obj = self:GetNodeByIndex(item)
  end

  if (obj and obj:InheritsFrom("treeviewnode")) then
    local oldSelected = self.selected
    self.selected = MakeWeakLink(obj)
    self.selected:Invalidate()
    if (oldSelected) then
      oldSelected:Invalidate()
    end

    obj:CallListeners(obj.OnSelectChange, true)
    if (oldSelected) then oldSelected:CallListeners(oldSelected.OnSelectChange, false) end
    self:CallListeners(self.OnSelectNode, self.selected, oldSelected)
  end
end

--//=============================================================================

function TreeView:UpdateLayout()
  local c = self.root
  c:_UpdateConstraints(0, 0, self.clientWidth)
  c:Realign()

  if (self.autosize) then
    self:Resize(nil, c.height, true, true)
  end

  return true
end

--//=============================================================================
