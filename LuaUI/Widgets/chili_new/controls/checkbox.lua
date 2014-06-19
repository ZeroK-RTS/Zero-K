--//=============================================================================

--- Checkbox module

--- Checkbox fields.
-- Inherits from Control.
-- @see control.Control
-- @table Checkbox
-- @bool[opt=true] checked checkbox checked state
-- @string[opt="text"] caption caption to appear in the checkbox
-- @string[opt="left"] textalign text alignment
-- @string[opt="right"] boxalign box alignment
-- @int[opt=10] boxsize box size
-- @tparam {r,g,b,a} textColor text color, (default {0,0,0,1})
-- @tparam {func1,func2,...} OnChange listener functions for checked state changes, (default {})
Checkbox = Control:Inherit{
  classname = "checkbox",
  checked   = true,
  caption   = "text",
  textalign = "left",
  boxalign  = "right",
  boxsize   = 10,

  textColor = {0,0,0,1},

  defaultWidth     = 70,
  defaultHeight    = 18,

  OnChange = {}
}

local this = Checkbox
local inherited = this.inherited

--//=============================================================================

function Checkbox:New(obj)
	obj = inherited.New(self,obj)
	obj.state.checked = obj.checked
	return obj
end

--//=============================================================================

--- Toggles the checked state
function Checkbox:Toggle()
  self:CallListeners(self.OnChange,not self.checked)
  self.checked = not self.checked
  self.state.checked = self.checked
  self:Invalidate()
end

--//=============================================================================

function Checkbox:DrawControl()
  --// gets overriden by the skin/theme
end

--//=============================================================================

function Checkbox:HitTest()
  return self
end

function Checkbox:MouseDown()
  self:Toggle()
  return self
end

--//=============================================================================
