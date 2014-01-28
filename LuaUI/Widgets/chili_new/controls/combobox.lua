--//=============================================================================

--- ComboBox module

--- ComboBox fields.
-- Inherits from Control.
-- @see control.Control
-- @table ComboBox
-- @tparam {"item1","item2",...} items table of items in the ComboBox, (default {"items"})
-- @int[opt=1] selected id of the selected item
-- @tparam {func1,func2,...} OnSelect listener functions for selected item changes, (default {})
ComboBox = Button:Inherit{
  classname = "combobox",
  caption = 'combobox',
  defaultWidth  = 70,
  defaultHeight = 20,
  items = { "items" },
  selected = 1,
  OnSelect = {},
}

local ComboBoxWindow      = Window:Inherit{classname = "combobox_window", resizable = false, draggable = false, }
local ComboBoxScrollPanel = ScrollPanel:Inherit{classname = "combobox_scrollpanel", horizontalScrollBar = false, }
local ComboBoxStackPanel  = StackPanel:Inherit{classname = "combobox_stackpanel", autosize = true, resizeItems = false, borderThickness = 0, padding = {0,0,0,0}, itemPadding = {0,0,0,0}, itemMargin = {0,0,0,0}, }
local ComboBoxItem        = Button:Inherit{classname = "combobox_item"}

local this = ComboBox
local inherited = this.inherited

function ComboBox:New(obj)
  obj = inherited.New(self,obj)
  obj:Select(obj.selected or 1)
  return obj
end

--- Selects an item by id
-- @int itemIdx id of the item to be selected
function ComboBox:Select(itemIdx)
  if (type(itemIdx)=="number") then
    if not self.items[itemIdx] then
       return
    end
    self.selected = itemIdx
    self.caption = self.items[itemIdx]
    self:CallListeners(self.OnSelect, itemIdx, true)
    self:Invalidate()
  end
  --FIXME add Select(name)
end

function ComboBox:_CloseWindow()
  if self._dropDownWindow then
    self._dropDownWindow:Dispose()
    self._dropDownWindow = nil
  end
  if (self.state.pressed) then
    self.state.pressed = false
    self:Invalidate()
    return self
  end
end

function ComboBox:FocusUpdate()
  if not self.state.focused then
    self:_CloseWindow()
  end
end

function ComboBox:MouseDown(...)
  self.state.pressed = true
  if not self._dropDownWindow then
    local sx,sy = self:LocalToScreen(0,0)

    local labels = {}
    local labelHeight = 20
    for i = 1, #self.items do
      local newBtn = ComboBoxItem:New {
        caption = self.items[i],
        width = '100%',
        height = labelHeight,
	state = {focused = (i == self.selected), selected = (i == self.selected)},
        OnMouseUp = { function()
          self:Select(i)
          self:_CloseWindow()
        end }
      }
      labels[#labels+1] = newBtn
    end

    local height = math.min(200, labelHeight * #labels)

    local screen = self:FindParent("screen")
    local y = sy + self.height
    if y + height > screen.height then
      y = sy - height
    end

    self._dropDownWindow = ComboBoxWindow:New{
      parent = screen,
      width  = self.width,
      height = height,
      x = sx,
      y = y,
      children = {
        ComboBoxScrollPanel:New{
          width  = "100%",
          height = "100%",
          children = {
            ComboBoxStackPanel:New{
              width = '100%',
              children = labels,
            },
          },
        }
      }
    }
  else
    self:_CloseWindow()
  end

  self:Invalidate()
  return self
end

function ComboBox:MouseUp(...)
  self:Invalidate()
  return self
  -- this exists to override Button:MouseUp so it doesn't modify .state.pressed
end
