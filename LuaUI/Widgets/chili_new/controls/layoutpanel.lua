--//=============================================================================
--// This control is the base of any auto-layout panel, this includes:
--//   grid, stackpanel, tables, itemlistview, listbox, radiogroups, ...
--//
--// Internal all childrens/items are handled via cells, which can be
--// freely aligned (table-grid, free movable like in imagelistviews, ...).
--//
--// Also most subclasses should use an items table to create their child
--// objects, so the user just define the captions, filenames, ... instead
--// of creating checkboxes, images, ... directly.
--// This doesn't affect simple containers like grids & stackcontrols, which
--// don't create any controls themselves (instead they just align their children).

--- LayoutPanel module

--- LayoutPanel fields.
-- Inherits from Control.
-- @see control.Control
-- @table LayoutPanel
-- @tparam {left,top,right,bottom} itemPadding table of item padding, (default {5,5,5,5})
-- @tparam {left,top,right,bottom} itemMargin table of item margin, (default {5,5,5,5})
-- @int[opt=1] minWidth minimum item width
-- @int[opt=0] maxWidth maximum item width
-- @int[opt=1] minHeight minimum item height
-- @int[opt=0] maxHeight maximum item height
-- @string[opt="horizontal] orientation orientation of the items
-- @bool[opt=false] resizeItems items are resized
-- @bool[opt=true] centerItems items are centered
-- @bool[opt=false] selectable items can be selected
-- @bool[multiSelect=true] multiSelect multiple items can be selected
-- @tparam {func1,func2,...} OnSelectItem function listeners to be called on item selection change (default {})
-- @tparam {func1,func2,...} OnDrawItem function listeners to be called when an item is drawn (default {})
-- @tparam (func1,func2,...} OnDblClickItem function listeners to be called on double click (default {})
LayoutPanel = Control:Inherit{
  classname = "layoutpanel",

  itemMargin    = {5, 5, 5, 5},
  itemPadding   = {5, 5, 5, 5},
  minItemWidth  = 1,
  maxItemWidth  = 0,
  minItemHeight = 1,
  maxItemHeight = 0,

  autosize = false,

  rows          = nil,
  columns       = nil,
  orientation   = "horizontal", --// "horizontal" or "vertical"
  autoArrangeH  = false, --FIXME rename
  autoArrangeV  = false, --FIXME rename
  grid          = false, --FIXME not implemented yet // if true, each row should have the same number of columns (table layout)
  resizeItems   = false,
  centerItems   = true,

  --[[ takes weights into account when resizing items (instead of same size for all)
       - e.g. "component1.weight = 1, component2.weight = 2" => component2 will be 2 times larger than component1
       - if all components have same weight -> same layout as without weightedResize
       - default value is 1 (nil interpreted as 1)
  ]]
  weightedResize = false,

  selectable    = false,
  multiSelect   = true,
  selectedItems = {},

  OnSelectItem = {},
  OnDrawItem = {}, --FIXME
  OnDblClickItem = {},

  _rows = nil,
  _columns = nil,
  _cells = nil,
}

local this = LayoutPanel
local inherited = this.inherited

--//=============================================================================

function LayoutPanel:New(obj)
  obj = inherited.New(self,obj)
  if (obj.selectable) then
    obj:SelectItem(1)
  end
  return obj
end

--//=============================================================================

--- Set the panel's orientation
-- @string orientation new orientation
function LayoutPanel:SetOrientation(orientation)
  self.orientation = orientation
  inherited.UpdateClientArea(self)
end

--//=============================================================================

local tsort = table.sort

--//=============================================================================

local function compareSizes(a,b)
  return a[2] < b[2]
end

function LayoutPanel:_JustCenterItemsH(startCell,endCell,freeSpace)
  local _cells = self._cells
  local perItemAlloc = freeSpace / ((endCell - startCell) + 1)
  local n=0

  for i=startCell,endCell do
    local cell = _cells[i]
    --if (self.orientation == "horizontal") then
      cell[1] = cell[1] + n * perItemAlloc
      cell[3] = cell[3] + perItemAlloc
    --else
    --  cell[2] = cell[2] + n * perItemHalfAlloc
    --  cell[4] = cell[4] + perItemHalfAlloc
    --end
    n = n+1
  end
end

function LayoutPanel:_JustCenterItemsV(startCell,endCell,freeSpace)
  local _cells = self._cells
  local perItemAlloc = freeSpace / ((endCell - startCell) + 1)
  local n=0

  for i=startCell,endCell do
    local cell = _cells[i]
    --if (self.orientation == "horizontal") then
      cell[2] = cell[2] + n * perItemAlloc
      cell[4] = cell[4] + perItemAlloc
    --else
    --  cell[1] = cell[1] + n * perItemHalfAlloc
    --  cell[3] = cell[3] + perItemHalfAlloc
    --end
    n = n+1
  end
end


function LayoutPanel:_EnlargeToLineHeight(startCell, endCell, lineHeight)
  local _cells = self._cells
  local _cellPaddings = self._cellPaddings

  for i=startCell,endCell do
    local cell = _cells[i]
    local padding = _cellPaddings[i]
    --if (self.orientation == "horizontal") then
      cell[4] = lineHeight - padding[2] - padding[4]
    --else
    --  cell[3] = lineHeight
    --end
  end
end


function LayoutPanel:_AutoArrangeAbscissa(startCell,endCell,freeSpace)
  if (startCell > endCell) then
    return
  end

  if (not self.autoArrangeH) then
    if (self.centerItems) then
      self:_JustCenterItemsH(startCell,endCell,freeSpace)
    end
    return
  end

  local _cells = self._cells

  if (startCell == endCell) then
    local cell = self._cells[startCell]
    if (self.orientation == "horizontal") then
      cell[1] = cell[1] + freeSpace/2
    else
      cell[2] = cell[2] + freeSpace/2
    end
    return
  end

  --// create a sorted table with the cell sizes
  local cellSizesCount = 0
  local cellSizes = {}
  for i=startCell,endCell do
    cellSizesCount = cellSizesCount + 1
    if (self.orientation == "horizontal") then
      cellSizes[cellSizesCount] = {i,_cells[i][3]}
    else
      cellSizes[cellSizesCount] = {i,_cells[i][4]}
    end
  end
  tsort(cellSizes,compareSizes)

  --// upto this index all cells have the same size (in the cellSizes table)
  local sameSizeIdx = 1
  local shortestCellSize = cellSizes[1][2]

  while (freeSpace>0)and(sameSizeIdx<cellSizesCount) do

    --// detect the cells, which have the same size
    for i=sameSizeIdx+1,cellSizesCount do
      if (cellSizes[i][2] ~= shortestCellSize) then
        break
      end
      sameSizeIdx = sameSizeIdx + 1
    end

    --// detect 2. shortest cellsize
    local nextCellSize = 0
    if (sameSizeIdx >= cellSizesCount) then
      nextCellSize = self.maxItemWidth --FIXME orientation
    else
      nextCellSize = cellSizes[sameSizeIdx+1][2]
    end


    --// try to fillup the shorest cells to the 2. shortest cellsize (so we can repeat the process on n+1 cells)
    --// (if all/multiple cells have the same size share the freespace between them)
    local spaceToAlloc = shortestCellSize - nextCellSize
    if (spaceToAlloc > freeSpace) then
      spaceToAlloc = freeSpace
      freeSpace    = 0
    else
      freeSpace    = freeSpace - spaceToAlloc
    end
    local perItemAlloc = (spaceToAlloc / sameSizeIdx)


    --// set the cellsizes/share the free space between cells
    for i=1,sameSizeIdx do
      local celli = cellSizes[i]
      celli[2] = celli[2] + perItemAlloc --FIXME orientation

      local cell = _cells[ celli[1] ]
      cell[3] = cell[3] + perItemAlloc --FIXME orientation

      --// adjust the top/left startcoord of all following cells (in the line)
      for j=celli[1]+1,endCell do
        local cell = _cells[j]
        cell[1] = cell[1] + perItemAlloc --FIXME orientation
      end
    end

    shortestCellSize = nextCellSize
  end
end


function LayoutPanel:_AutoArrangeOrdinate(freeSpace)
  if (not self.autoArrangeV) then
    if (self.centerItems) then
      local startCell = 1
      local endCell = 1
      for i=2,#self._lines do
        endCell = self._lines[i] - 1
        self:_JustCenterItemsV(startCell,endCell,freeSpace)
        startCell = endCell + 1
      end
    end
    return
  end

  local _lines = self._lines
  local _cells = self._cells

  --// create a sorted table with the line sizes
  local lineSizes = {}
  for i=1,#_lines do
    local first_cell_in_line = _cells[ _lines[i] ]
    if (self.orientation == "horizontal") then --FIXME
      lineSizes[i] = {i,first_cell_in_line[4]}
    else
      lineSizes[i] = {i,first_cell_in_line[3]}
    end
  end
  tsort(lineSizes,compareSizes)
  local lineSizesCount = #lineSizes

  --// upto this index all cells have the same size (in the cellSizes table)
  local sameSizeIdx = 1
  local shortestLineSize = lineSizes[1][2]

  while (freeSpace>0)and(sameSizeIdx<lineSizesCount) do

    --// detect the lines, which have the same size
    for i=sameSizeIdx+1,lineSizesCount do
      if (lineSizes[i][2] ~= shortestLineSize) then
        break
      end
      sameSizeIdx = sameSizeIdx + 1
    end

    --// detect 2. shortest linesize
    local nextLineSize = 0
    if (sameSizeIdx >= lineSizesCount) then
      nextLineSize = self.maxItemHeight --FIXME orientation
    else
      nextLineSize = lineSizes[sameSizeIdx+1][2]
    end


    --// try to fillup the shorest lines to the 2. shortest linesize (so we can repeat the process on n+1 lines)
    --// (if all/multiple have the same size share the freespace between them)
    local spaceToAlloc = shortestLineSize - nextLineSize
    if (spaceToAlloc > freeSpace) then
      spaceToAlloc = freeSpace
      freeSpace    = 0
    else
      freeSpace    = freeSpace - spaceToAlloc
    end
    local perItemAlloc = (spaceToAlloc / sameSizeIdx)


    --// set the linesizes
    for i=1,sameSizeIdx do
      local linei = lineSizes[i]
      linei[2] = linei[2] + perItemAlloc --FIXME orientation

      --// adjust the top/left startcoord of all following lines (in the line)
      local nextLineIdx = linei[1]+1
      local nextLine = ((nextLineIdx <= #_lines) and _lines[ nextLineIdx ]) or #_cells+1
      for j=_lines[ linei[1] ],nextLine-1 do
        local cell = _cells[j]
        cell[4] = cell[4] + perItemAlloc --FIXME orientation
      end
      for j=nextLine,#_cells do
        local cell = _cells[j]
        cell[2] = cell[2] + perItemAlloc --FIXME orientation
      end
    end

    shortestLineSize = nextLineSize
  end
end

--//=============================================================================

function LayoutPanel:GetMaxWeight()
  --// calculate max weights for each column and row
  local mweightx = {}
  local mweighty = {}

  local cn = self.children

  local dir1,dir2
  if (self.orientation == "vertical") then
    dir1,dir2 = self._columns,self._rows
  else
    dir1,dir2 = self._rows,self._columns
  end

  local n,x,y = 1
  for i=1, dir1 do
    for j=1, dir2 do
      local child = cn[n]
      if not child then break end

      if (self.orientation == "vertical") then
        x,y = i,j
      else
        x,y = j,i
      end

      local we = child.weight or 1
      if ((mweightx[x] or 0.001) < we) then
        mweightx[x] = we
      end
      if ((mweighty[y] or 0.001) < we) then
        mweighty[y] = we
      end
      n = n + 1
    end
  end

  local weightx = table.sum(mweightx)
  local weighty = table.sum(mweighty)
  return mweightx,mweighty,weightx, weighty
end


function LayoutPanel:_GetMaxChildConstraints(child)
  local children = self.children

  if (self._cells and not self._inUpdateLayout) then
    for i=1, #children do
      if CompareLinks(children[i], child) then
        local cell = self._cells[i]
        if (cell) then
          return unpack4(cell)
        end
      end
    end
  end

  local itemPadding = self.itemPadding
  local margin      = child.margin or self.itemMargin
  local maxChildWidth  = -margin[1] - itemPadding[1] + self.clientWidth  - itemPadding[3] - margin[3]
  local maxChildHeight = -margin[2] - itemPadding[2] + self.clientHeight - itemPadding[4] - margin[4]
  return margin[1] + itemPadding[1], margin[2] + itemPadding[2], maxChildWidth, maxChildHeight
end

--//=============================================================================

function LayoutPanel:GetMinimumExtents()
--[[
  local old = self.autosize
  self.autosize = false
  local right, bottom = inherited.GetMinimumExtents(self)
  self.autosize = old

  return right, bottom
--]]
  if (not self.autosize) then
    local right  = self.x + self.width
    local bottom = self.y + self.height

    return right, bottom
  else
--FIXME!!!
    local right  = self.x + self.width
    local bottom = self.y + self.height

    return right, bottom
  end
end

--//=============================================================================
--// Note: there are two different layput functions depending on resizeItems

function LayoutPanel:_LayoutChildrenResizeItems()
  local cn = self.children
  local cn_count = #cn

  --FIXME take minWidth/height maxWidth/Height into account! (and try to reach a 1:1 pixel ratio)
  if self.columns and self.rows then
    self._columns = self.columns
    self._rows    = self.rows
  elseif (not self.columns) and self.rows then
    self._columns = math.ceil(cn_count/self.rows)
    self._rows    = self.rows
  elseif (not self.rows) and self.columns then
    self._columns = self.columns
    self._rows    = math.ceil(cn_count/self.columns)
  else
    local size    = math.ceil(cn_count^0.5)
    self._columns = size
    self._rows    = math.ceil(cn_count/size)
  end

  local childWidth  = self.clientArea[3]/self._columns
  local childHeight = self.clientArea[4]/self._rows
  local childPosx = 0
  local childPosy = 0

  self._cells  = {}
  local _cells = self._cells

  local weightsx,weightsy, maxweightx, maxweighty
  if (self.weightedResize) then
    weightsx,weightsy, maxweightx, maxweighty = self:GetMaxWeight()
    --// special setup for weightedResize
    childWidth = 0
    childHeight = 0
  end

  local dir1,dir2
  if (self.orientation == "vertical") then
    dir1,dir2 = self._columns,self._rows
  else
    dir1,dir2 = self._rows,self._columns
  end

  local n,x,y = 1
  for i=1, dir1 do
    for j=1, dir2 do
      local child = cn[n]
      if not child then break end
      local margin = child.margin or self.itemMargin

      if (self.orientation == "vertical") then
        x,y = i,j
      else
        x,y = j,i
      end

      if (self.weightedResize) then
        --// weighted Position
        if dir1 == 1 then
          childPosx = 0
        else
          childPosx = childPosx + childWidth
        end
        if dir2 == 1 then
          childPosy = 0
        else
          childPosy = childPosy + childHeight
        end
        childWidth  = (self.clientArea[3]) * weightsx[x]/maxweightx
        childHeight = (self.clientArea[4]) * weightsy[y]/maxweighty
      else
        --// position without weightedResize
        childPosx = childWidth * (x-1)
        childPosy = childHeight * (y-1)
      end


      local childBox = {
        childPosx + margin[1],
        childPosy + margin[2],
        childWidth - margin[1] - margin[3],
        childHeight - margin[2] - margin[4]
      }
      child:_UpdateConstraints(unpack4(childBox))
      _cells[n] = childBox
      n = n+1
    end
  end
end


function LayoutPanel:_LayoutChildren()
  local cn = self.children
  local cn_count = #cn

  self._lines  = {1}
  local _lines = self._lines
  self._cells  = {}
  local _cells = self._cells
  self._cellPaddings  = {}
  local _cellPaddings = self._cellPaddings

  local itemMargin  = self.itemMargin
  local itemPadding = self.itemPadding

  local cur_x,cur_y = 0,0
  local curLine, curLineSize = 1,self.minItemHeight
  local totalChildWidth,totalChildHeight = 0
  local lineHeights = {}
  local lineWidths = {}

  --// Handle orientations
  local X,Y,W,H = "x","y","width","height"
  local LEFT,TOP,RIGHT,BOTTOM = 1,2,3,4
  local WIDTH, HEIGHT = 3,4
  local minItemWidth, minItemHeight = self.minItemWidth, self.minItemHeight
  local clientAreaWidth,clientAreaHeight = self.clientArea[3],self.clientArea[4]

  --// FIXME: finish me (use those vars in the loops below!)
--[[
  if (self.orientation ~= "horizontal") then
    X,Y,W,H = "y","x","height","width"
    LEFT,TOP,RIGHT,BOTTOM = 2,1,4,3
    WIDTH, HEIGHT = 4,3
    curLineSize = minItemWidth
    minItemWidth, minItemHeight = minItemHeight, minItemWidth
    clientAreaWidth,clientAreaHeight = clientAreaHeight, clientAreaWidth
  end
--]]

--[[FIXME breaks ListImageView!
  if (self.autosize) then
    local maxChildWidth = minItemWidth
    for i=1, cn_count do
      local child = cn[i]

      local childWidth = math.max(child[W], minItemWidth)
      if (child.GetMinimumExtents) then
        local extents = {child:GetMinimumExtents()}
	childWidth = math.max(extents[LEFT], childWidth)
      end

      maxChildWidth = math.max(childWidth, maxChildWidth)
    end
    totalMaxChildWidth  = itemPadding[LEFT] +  maxChildWidth  + itemPadding[RIGHT]

    if (self.orientation == "horizontal") then
      self:Resize(nil, totalMaxChildWidth, true, true)
      clientAreaWidth,clientAreaHeight = self.clientArea[4],self.clientArea[3]
    else
      self:Resize(totalMaxChildWidth, nil, true, true)
      clientAreaWidth,clientAreaHeight = self.clientArea[3],self.clientArea[4]
    end
  end
--]]

  for i=1, cn_count do
    local child = cn[i]
    if not child then break end
    local margin = child.margin or itemMargin

    local childWidth  = math.max(child[W],minItemWidth)
    local childHeight = math.max(child[H],minItemHeight)

    local itemMarginL = margin[LEFT]
    local itemMarginT = (curLine > 1) and margin[TOP] or 0
    local itemMarginR = margin[RIGHT]
    local itemMarginB = (i < cn_count) and margin[BOTTOM] or 0

    totalChildWidth  = margin[LEFT] + itemPadding[LEFT] +  childWidth  + itemPadding[RIGHT] + margin[RIGHT] --// FIXME add margin just for non-border controls
    totalChildHeight = itemMarginT + itemPadding[TOP] + childHeight + itemPadding[BOTTOM] + itemMarginB

    local cell_top    = cur_y + itemPadding[TOP]  + itemMarginT
    local cell_left   = cur_x + itemPadding[LEFT] + itemMarginL
    local cell_width  = childWidth
    local cell_height = childHeight

    cur_x = cur_x + totalChildWidth

    if
      (i>1)and
      (self.columns and (((i - 1) % self.columns) < 1))or
      ((not self.columns) and (cur_x > clientAreaWidth))
    then
      lineHeights[curLine] = curLineSize
      lineWidths[curLine]  = cur_x - totalChildWidth

      --// start a new line
      cur_x = totalChildWidth
      cur_y = cur_y + curLineSize

      curLine = curLine+1
      curLineSize = math.max(minItemHeight, totalChildHeight)
      cell_top  = cur_y + itemMarginT + itemPadding[TOP]
      cell_left = itemMarginL + itemPadding[LEFT]
      _lines[curLine] = i
    end

    _cells[i] = {cell_left, cell_top, cell_width, cell_height}
    _cellPaddings[i] = {itemMarginL + itemPadding[LEFT], itemMarginT + itemPadding[TOP], itemMarginR + itemPadding[RIGHT], itemMarginB + itemPadding[BOTTOM]}

    if (totalChildHeight > curLineSize) then
      curLineSize = totalChildHeight
    end
  end

  lineHeights[curLine] = curLineSize
  lineWidths[curLine]  = cur_x

  --// Move cur_y to the bottom of the new ClientArea/ContentArea
  cur_y = cur_y + curLineSize

  --// Share remaining free space between items
  if (self.centerItems or self.autoArrangeH or self.autoArrangeV) then
    for i=1,#lineWidths do
      local startcell = _lines[i]
      local endcell   = (_lines[i+1] or (#cn+1)) - 1
      local freespace = clientAreaWidth - lineWidths[i]
      self:_AutoArrangeAbscissa(startcell, endcell, freespace)
    end

    for i=1,#lineHeights do
      local lineHeight = lineHeights[i]
      local startcell  = _lines[i]
      local endcell    = (_lines[i+1] or (#cn+1)) - 1
      self:_EnlargeToLineHeight(startcell, endcell, lineHeight)
    end
    self:_AutoArrangeOrdinate(clientAreaHeight - cur_y)
  end

  --// Resize the LayoutPanel if needed
  --FIXME do this in resize too!
  if (self.autosize) then
    --if (self.orientation == "horizontal") then
      self:Resize(nil, cur_y, true, true)
    --else
    --  self:Resize(nil, cur_y, true, true)
    --end
  elseif (cur_y > clientAreaHeight) then
    --Spring.Echo(debug.traceback())
  end

  --// Update the Children constraints
  for i=1, cn_count do
    local child = cn[i]
    if not child then break end

    local cell = _cells[i]
    local cposx,cposy = cell[LEFT],cell[TOP]
    if (self.centerItems) then
      cposx = cposx + (cell[WIDTH] - child[W]) * 0.5
      cposy = cposy + (cell[HEIGHT] - child[H]) * 0.5
    end

    --if (self.orientation == "horizontal") then
      --FIXME use child:Resize or something like that 
      child:_UpdateConstraints(cposx,cposy)
    --else
    --  child:_UpdateConstraints(cposy,cposx)
    --end
  end
end


--//=============================================================================

function LayoutPanel:UpdateLayout()
  if (not self.children[1]) then
--FIXME redundant?
    if (self.autosize) then
      if (self.orientation == "horizontal") then
        self:Resize(0, nil, false)
      else
        self:Resize(nil, 0, false)
      end
    end
    return
  end

  self._inUpdateLayout = true

  self:RealignChildren()

  --FIXME add check if any item.width > maxItemWidth (+Height) & add a new autosize tag for it

  if (self.resizeItems) then
    self:_LayoutChildrenResizeItems()
  else
    self:_LayoutChildren()
  end

  self._inUpdateLayout = false

  self:RealignChildren() --FIXME split SetPos from AlignControl!!!

  return true
end

--//=============================================================================

function LayoutPanel:DrawBackground()
end


function LayoutPanel:DrawItemBkGnd(index)
end


function LayoutPanel:DrawControl()
  self:DrawBackground(self)
end


function LayoutPanel:DrawChildren()
  local cn = self.children
  if (not cn[1]) then return end

  gl.PushMatrix()
  gl.Translate(self.clientArea[1], self.clientArea[2], 0)
  for i=1,#cn do
    self:DrawItemBkGnd(i)
  end
  if (self.debug) then
    gl.Color(1,0,0,0.5)
    for i=1,#self._cells do
      local x,y,w,h = unpack4(self._cells[i])
      gl.Rect(x,y,x+w,y+h)
    end
  end
  gl.PopMatrix()

  self:_DrawChildrenInClientArea('Draw')
end


function LayoutPanel:DrawChildrenForList()
  local cn = self.children
  if (not cn[1]) then return end

  if (self.debug) then
    gl.Color(0,1,0,0.5)
    gl.PolygonMode(GL.FRONT_AND_BACK,GL.LINE)
    gl.LineWidth(2)
    gl.Rect(0, 0, self.width, self.height)
    gl.LineWidth(1)
    gl.PolygonMode(GL.FRONT_AND_BACK,GL.FILL)
  end

  gl.PushMatrix()
  gl.Translate(self.clientArea[1], self.clientArea[2], 0)
  for i=1,#cn do
    self:DrawItemBkGnd(i)
  end
  if (self.debug) then
    gl.Color(1,0,0,0.5)
    for i=1,#self._cells do
      local x,y,w,h = unpack4(self._cells[i])
      gl.Rect(x,y,x+w,y+h)
    end
  end
  gl.PopMatrix()

  self:_DrawChildrenInClientArea('DrawForList')
end

--//=============================================================================

function LayoutPanel:GetItemIndexAt(cx,cy)
  local cells = self._cells
  local itemPadding = self.itemPadding
  for i=1,#cells do
    local cell  = cells[i]
    local cellbox = ExpandRect(cell,itemPadding)
    if (InRect(cellbox, cx,cy)) then
      return i
    end
  end
  return -1
end


function LayoutPanel:GetItemXY(itemIdx)
  local cell = self._cells[itemIdx]
  if (cell) then
    return unpack4(cell)
  end
end

--//=============================================================================

function LayoutPanel:MultiRectSelect(item1,item2,append)
  --// note: this functions does NOT update self._lastSelected!

  --// select all items in the convex hull of those 2 items
  local cells = self._cells
  local itemPadding = self.itemPadding

  local cell1,cell2 = cells[item1],cells[item2]

  local convexHull = {
    math.min(cell1[1],cell2[1]),
    math.min(cell1[2],cell2[2]),
  }
  convexHull[3] = math.max(cell1[1]+cell1[3],cell2[1]+cell2[3]) - convexHull[1]
  convexHull[4] = math.max(cell1[2]+cell1[4],cell2[2]+cell2[4]) - convexHull[2]

  local oldSelected = {} -- need to copy tables to not overwrite things
  for k, v in pairs(self.selectedItems) do
    oldSelected[k] = v
  end  

  self.selectedItems = append and self.selectedItems or {}

  for i=1,#cells do
    local cell  = cells[i]
    local cellbox = ExpandRect(cell,itemPadding)
    if (AreRectsOverlapping(convexHull,cellbox)) then
      self.selectedItems[i] = true
    end
  end

  if (not append) then
    for itemIdx,selected in pairs(oldSelected) do
      if (selected)and(not self.selectedItems[itemIdx]) then
        self:CallListeners(self.OnSelectItem, itemIdx, false)
      end
    end
  end
  -- this needs to happen either way
  for itemIdx,selected in pairs(self.selectedItems) do
    if (selected)and(not oldSelected[itemIdx]) then
      self:CallListeners(self.OnSelectItem, itemIdx, true)
    end
  end

  self:Invalidate()
end

--- Toggle item selection
-- @int itemIdx id of the item for which the selection will be toggled
function LayoutPanel:ToggleItem(itemIdx)
  local newstate = not self.selectedItems[itemIdx]
  self.selectedItems[itemIdx] = newstate
  self._lastSelected = itemIdx
  self:CallListeners(self.OnSelectItem, itemIdx, newstate)
  self:Invalidate()
end

--- Select the item
-- @int itemIdx id of the item to be selected
-- @bool append whether the old selection should be kept
function LayoutPanel:SelectItem(itemIdx, append)
  if (self.selectedItems[itemIdx]) then
    return
  end

  if (append) then
    self.selectedItems[itemIdx] = true
  else
    local oldItems = self.selectedItems
    self.selectedItems = {[itemIdx]=true}
    for oldItemIdx in pairs(oldItems) do
      if (oldItemIdx ~= itemIdx) then
        self:CallListeners(self.OnSelectItem, oldItemIdx, false)
      end
    end
  end
  self._lastSelected = itemIdx
  self:CallListeners(self.OnSelectItem, itemIdx, true)
  self:Invalidate()
end

--- Deselect item
-- @int itemIdx id of the item to deselect
function LayoutPanel:DeselectItem(itemIdx)
  if (not self.selectedItems[itemIdx]) then
    return
  end

  self.selectedItems[itemIdx] = false
  self._lastSelected = itemIdx
  self:CallListeners(self.OnSelectItem, itemIdx, false)
  self:Invalidate()
end

--- Select all items
function LayoutPanel:SelectAll()
  for i=1,#self.children do
    self:SelectItem(i, append)
  end
end

--- Deselect all items
function LayoutPanel:DeselectAll()
  for idx in pairs(self.selectedItems) do
    self:DeselectItem(idx)
  end
end


--//=============================================================================

function LayoutPanel:MouseDown(x,y,button,mods)
  local clickedChild = inherited.MouseDown(self,x,y,button,mods)
  if (clickedChild) then
    return clickedChild
  end

  if (not self.selectable) then return end

  --//FIXME HitTest just returns true when we hover a children -> this won't get called when you hit on in empty space!
  if (button==3) then
    self:DeselectAll()
    return self
  end

  local cx,cy = self:LocalToClient(x,y)
  local itemIdx = self:GetItemIndexAt(cx,cy)

  if (itemIdx>0) then
    if (self.multiSelect) then
      if (mods.shift and mods.ctrl) then
        self:MultiRectSelect(itemIdx,self._lastSelected or 1, true)
      elseif (mods.shift) then
        self:MultiRectSelect(itemIdx,self._lastSelected or 1)
      elseif (mods.ctrl) then
        self:ToggleItem(itemIdx)
      else
        self:SelectItem(itemIdx)
      end
    else
      self:SelectItem(itemIdx)
    end

    return self
  end
end


function LayoutPanel:MouseDblClick(x,y,button,mods)
  local clickedChild = inherited.MouseDown(self,x,y,button,mods)
  if (clickedChild) then
    return clickedChild
  end

  if (not self.selectable) then return end

  local cx,cy = self:LocalToClient(x,y)
  local itemIdx = self:GetItemIndexAt(cx,cy)

  if (itemIdx>0) then
    self:CallListeners(self.OnDblClickItem, itemIdx)
    return self
  end
end

--//=============================================================================
