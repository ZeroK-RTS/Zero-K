--- TextBox module

--- TextBox fields.
-- Inherits from Control.
-- @see control.Control
-- @table TextBox
-- @string[opt=""] text text contained in the editbox
-- @bool[opt=true] autoHeight sets height to text size, useful for embedding in scrollboxes
-- @bool[opt=true] autoObeyLineHeight (needs autoHeight) if true, autoHeight will obey the lineHeight (-> texts with the same line count will have the same height)
-- @int[opt=12] fontSize font size
TextBox = Control:Inherit{
  classname = "textbox",

  padding = {0,0,0,0},

  text      = "line1\nline2",
  autoHeight  = true, 
  autoObeyLineHeight = true, 
  fontsize = 12,

  _lines = {},
}

local this = TextBox
local inherited = this.inherited

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- Set text
-- @string t sets the text
function TextBox:SetText(t)
  if (self.text == t) then
    return
  end
  self.text = t
  self:RequestRealign()
  self:Invalidate() -- seems RequestRealign() doesn't always cause an invalidate
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function Split(s, separator)
  local results = {}
  for part in s:gmatch("[^"..separator.."]+") do
    results[#results + 1] = part
  end
  return results
end

-- remove first n elemets from t, return them
local function Take(t, n)
  local removed = {}
  for i=1, n do
    removed[#removed+1] = table.remove(t, 1)
  end
  return removed
end

-- appends t1 to t2 in-place
local function Append(t1, t2)
  local l = #t1
  for i = 1, #t2 do
    t1[i + l] = t2[i]
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function TextBox:UpdateLayout()
  local font = self.font
  local padding = self.padding
  local width  = self.width - padding[1] - padding[3]
  local height = self.height - padding[2] - padding[4]
  if self.autoHeight then
    height = 1e9
  end

  self._wrappedText = font:WrapText(self.text, width, height)

  if self.autoHeight then
    local textHeight,textDescender,numLines = font:GetTextHeight(self._wrappedText)
    textHeight = textHeight-textDescender

    if (self.autoObeyLineHeight) then
      if (numLines>1) then
        textHeight = numLines * font:GetLineHeight()
      else
        --// AscenderHeight = LineHeight w/o such deep chars as 'g','p',...
        textHeight = math.min( math.max(textHeight, font:GetAscenderHeight()), font:GetLineHeight())
      end
    end

    self:Resize(nil, textHeight, true, true)
  end
end


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
