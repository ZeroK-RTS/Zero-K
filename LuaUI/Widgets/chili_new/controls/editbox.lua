--//=============================================================================

--- EditBox module

include("keysym.h.lua")

--- EditBox fields.
-- Inherits from Control.
-- @see control.Control
-- @table EditBox
-- @tparam {r,g,b,a} cursorColor cursor color, (default {0,0,1,0.7})
-- @string[opt="left"] align alignment
-- @string[opt="linecenter"] valign vertical alignment
-- @string[opt=""] text text contained in the editbox
-- @int[opt=1] cursor cursor position
EditBox = Control:Inherit{
  classname= "editbox",

  defaultWidth = 70,
  defaultHeight = 20,

  padding = {3,3,3,3},

  cursorColor = {0,0,1,0.7},

  align    = "left",
  valign   = "linecenter",

  text   = "",
  cursor = 1,
  offset = 1,

  allowUnicode = true,
}

local this = EditBox
local inherited = this.inherited

--//=============================================================================

function EditBox:New(obj)
	obj = inherited.New(self,obj)
	obj._interactedTime = Spring.GetTimer()
	obj:SetText(obj.text)
	obj:RequestUpdate()
	return obj
end

function EditBox:HitTest(x,y)
	return self
end

--//=============================================================================

--- Sets the EditBox text
-- @string newtext text to be set
function EditBox:SetText(newtext)
	if (self.text == newtext) then return end
	self.text = newtext
	self.cursor = 1
	self.offset = 1
	self:UpdateLayout()
	self:Invalidate()
end


function EditBox:UpdateLayout()
  local font = self.font

  --FIXME
  if (self.autosize) then
    local w = font:GetTextWidth(self.text);
    local h, d, numLines = font:GetTextHeight(self.text);

    if (self.autoObeyLineHeight) then
      h = math.ceil(numLines * font:GetLineHeight())
    else
      h = math.ceil(h-d)
    end

    local x = self.x
    local y = self.y

    if self.valign == "center" then
      y = math.round(y + (self.height - h) * 0.5)
    elseif self.valign == "bottom" then
      y = y + self.height - h
    elseif self.valign == "top" then
    else
    end

    if self.align == "left" then
    elseif self.align == "right" then
      x = x + self.width - w
    elseif self.align == "center" then
      x = math.round(x + (self.width - w) * 0.5)
    end

    w = w + self.padding[1] + self.padding[3]
    h = h + self.padding[2] + self.padding[4]

    self:_UpdateConstraints(x,y,w,h)
  end

end

--//=============================================================================

function EditBox:Update(...)
	--FIXME add special UpdateFocus event?

	--// redraw every few frames for blinking cursor
	inherited.Update(self, ...)

	if self.state.focused then
		self:RequestUpdate()
		if (os.clock() >= (self._nextCursorRedraw or -math.huge)) then
			self._nextCursorRedraw = os.clock() + 0.1 --10FPS
			self:Invalidate()
		end
	end
end


function EditBox:MouseDown(x, y, ...)
	local clientX = self.clientArea[1]
	self.cursor = #self.text + 1 -- at end of text
	for i = self.offset, #self.text do
		local tmp = self.text:sub(self.offset, i)
		if self.font:GetTextWidth(tmp) > (x - clientX) then
			self.cursor = i
			break
		end
	end
	self._interactedTime = Spring.GetTimer()
	inherited.MouseDown(self, x, y, ...)
	self:Invalidate()
	return self
end

function EditBox:MouseUp(...)
	inherited.MouseUp(self, ...)
	self:Invalidate()
	return self
end


function EditBox:KeyPress(key, mods, isRepeat, label, unicode, ...)
	local cp = self.cursor
	local txt = self.text
	if key == KEYSYMS.RETURN then
		return false
	elseif key == KEYSYMS.BACKSPACE then --FIXME use Spring.GetKeyCode("backspace")
		self.text, self.cursor = Utf8BackspaceAt(txt, cp)
	elseif key == KEYSYMS.DELETE then
		self.text   = Utf8DeleteAt(txt, cp)
	elseif key == KEYSYMS.LEFT then
		self.cursor = Utf8PrevChar(txt, cp)
	elseif key == KEYSYMS.RIGHT then
		self.cursor = Utf8NextChar(txt, cp)
	elseif key == KEYSYMS.HOME then
		self.cursor = 1
	elseif key == KEYSYMS.END then
		self.cursor = #txt + 1
	else
		local utf8char = UnicodeToUtf8(unicode)
		if (not self.allowUnicode) then
			local success
			success, utf8char = pcall(string.char, unicode)
			if success then
				success = not utf8char:find("%c")
			end
			if (not success) then
				utf8char = nil
			end
		end

		if utf8char then
			self.text = txt:sub(1, cp - 1) .. utf8char .. txt:sub(cp, #txt)
			self.cursor = cp + utf8char:len()
		--else
		--	return false
		end
	end
	self._interactedTime = Spring.GetTimer()
	inherited.KeyPress(self, key, mods, isRepeat, label, unicode, ...)
	self:UpdateLayout()
	self:Invalidate()
	return self
end


function EditBox:TextInput(utf8char, ...)
	local unicode = utf8char
	if (not self.allowUnicode) then
		local success
		success, unicode = pcall(string.char, utf8char)
		if success then
			success = not unicode:find("%c")
		end
		if (not success) then
			unicode = nil
		end
	end

	if unicode then
		local cp  = self.cursor
		local txt = self.text
		self.text = txt:sub(1, cp - 1) .. unicode .. txt:sub(cp, #txt)
		self.cursor = cp + unicode:len()
	--else
	--	return false
	end

	self._interactedTime = Spring.GetTimer()
	inherited.TextInput(utf8char, ...)
	self:UpdateLayout()
	self:Invalidate()
	return self
end

--//=============================================================================
