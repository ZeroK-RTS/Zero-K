--- TextBox module

--- TextBox fields.
-- Inherits from Control.
-- @see control.Control
-- @table TextBox
-- @string[opt=""] text text contained in the editbox
-- @bool[opt=true] autoHeight sets height to text size, useful for embedding in scrollboxes
-- @bool[opt=true] autoObeyLineHeight (needs autoHeight) if true, autoHeight will obey the lineHeight (-> texts with the same line count will have the same height)
-- @int[opt=12] fontSize font size
TextBox = EditBox:Inherit{
  classname = "textbox",

  padding = {0,0,0,0},

  text      = "line1\nline2",
  autoHeight  = true,
  autoObeyLineHeight = true,

  editable = false,
  selectable = false,
  multiline = true,

  borderColor     = {0,0,0,0},
  focusColor      = {0,0,0,0},
  backgroundColor = {0,0,0,0},
}

local this = TextBox
local inherited = this.inherited

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function TextBox:DrawControl()
  local paddx, paddy = unpack4(self.clientArea)
  local x = paddx
  local y = paddy

  local font = self.font
  font:Draw(self._wrappedText, x, y)

  if (self.debug) then
    gl.Color(0,1,0,0.5)
    gl.PolygonMode(GL.FRONT_AND_BACK,GL.LINE)
    gl.LineWidth(2)
    gl.Rect(0,0,self.width,self.height)
    gl.LineWidth(1)
    gl.PolygonMode(GL.FRONT_AND_BACK,GL.FILL)
  end
end
