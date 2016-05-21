--//=============================================================================

--- EditBox module

--- EditBox fields.
-- Inherits from Control.
-- @see control.Control
-- @table EditBox
-- @tparam {r,g,b,a} cursorColor cursor color, (default {0,0,1,0.7})
-- @tparam {r,g,b,a} selectionColor selection color, (default {0,1,1,0.3})
-- @string[opt="left"] align alignment
-- @string[opt="linecenter"] valign vertical alignment
-- @string[opt=""] text text contained in the editbox
-- @string[opt=""] hint hint to be displayed when there is no text and the control isn't focused
-- @int[opt=1] cursor cursor position
-- @bool passwordInput specifies whether the text should be treated as a password
EditBox = Control:Inherit{
  classname= "editbox",

  defaultWidth = 70,
  defaultHeight = 20,

  padding = {3,3,3,3},

  cursorColor = {0,0,1,0.7},
  selectionColor = {0,1,1,0.3},

  align    = "left",
  valign   = "linecenter",

  hintFont = table.merge({ color = {1,1,1,0.7} }, Control.font),

  text   = "",
  hint   = "",
  cursor = 1,
  offset = 1,
  selStart = nil,
  selEnd = nil,

  allowUnicode = true,
  passwordInput = false,
}
if Script.IsEngineMinVersion == nil or not Script.IsEngineMinVersion(97) then
    EditBox.allowUnicode = false
end

local this = EditBox
local inherited = this.inherited

--//=============================================================================

function EditBox:New(obj)
	obj = inherited.New(self,obj)
	obj._interactedTime = Spring.GetTimer()
	  --// create font
	obj.hintFont = Font:New(obj.hintFont)
	obj.hintFont:SetParent(obj)
	obj:SetText(obj.text)
	obj:RequestUpdate()
	return obj
end

function EditBox:Dispose(...)	
	Control.Dispose(self)
	self.hintFont:SetParent()
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
 	self.selStart = nil
 	self.selEnd = nil
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

function EditBox:_SetCursorByMousePos(x, y)
	local clientX = self.clientArea[1]
	if x - clientX < 0 then
		self.offset = self.offset - 1
		self.offset = math.max(0, self.offset)
		self.cursor = self.offset + 1
	else
		local text = self.text
		-- properly accounts for passworded text where characters are represented as "*"
		-- TODO: what if the passworded text is displayed differently? this is using assumptions about the skin
		if #text > 0 and self.passwordInput then 
			text = string.rep("*", #text)
		end
		self.cursor = #text + 1 -- at end of text
		for i = self.offset, #text do
			local tmp = text:sub(self.offset, i)
			if self.font:GetTextWidth(tmp) > (x - clientX) then
				self.cursor = i
				break
			end
		end
	end
end

function EditBox:MouseDown(x, y, ...)
	local _, _, _, shift = Spring.GetModKeyState()
	local cp = self.cursor
	self:_SetCursorByMousePos(x, y)
	if shift then
		if not self.selStart then
			self.selStart = cp
		end
		self.selEnd = self.cursor
	elseif self.selStart then
		self.selStart = nil
		self.selEnd = nil
	end
	
	self._interactedTime = Spring.GetTimer()
	inherited.MouseDown(self, x, y, ...)
	self:Invalidate()
	return self
end

function EditBox:MouseMove(x, y, dx, dy, button)
	if button ~= 1 then
		return inherited.MouseMove(self, x, y, dx, dy, button)
	end

	local _, _, _, shift = Spring.GetModKeyState()
	local cp = self.cursor
	self:_SetCursorByMousePos(x, y)
	if not self.selStart then
		self.selStart = cp
	end
	self.selEnd = self.cursor

	self._interactedTime = Spring.GetTimer()
	inherited.MouseMove(self, x, y, dx, dy, button)
	self:Invalidate()
	return self
end

function EditBox:MouseUp(...)
	inherited.MouseUp(self, ...)
	self:Invalidate()
	return self
end

function EditBox:Select(startIndex, endIndex)
	self.selStart = startIndex
	self.selEnd = endIndex
	self:Invalidate()
end

function EditBox:ClearSelected()
	local left = self.selStart
	local right = self.selEnd
	if left > right then
		left, right = right, left
	end
	self.cursor = right
	local i = 0
	while self.cursor ~= left do
		self.text, self.cursor = Utf8BackspaceAt(self.text, self.cursor)
		i = i + 1
		if i > 100 then
			break
		end
	end
	self.selStart = nil
	self.selEnd = nil
	self:Invalidate()
end


function EditBox:KeyPress(key, mods, isRepeat, label, unicode, ...)
	local cp = self.cursor
	local txt = self.text

	-- enter & return
	if key == Spring.GetKeyCode("enter") or key == Spring.GetKeyCode("numpad_enter") then
		return inherited.KeyPress(self, key, mods, isRepeat, label, unicode, ...) or true

	-- deletions
	elseif key == Spring.GetKeyCode("backspace") then
		if self.selStart == nil then
			if mods.ctrl then
				repeat
					self.text, self.cursor = Utf8BackspaceAt(self.text, self.cursor)
				until self.cursor == 1 or (self.text:sub(self.cursor-2, self.cursor-2) ~= " " and self.text:sub(self.cursor-1, self.cursor-1) == " ")
			else
				self.text, self.cursor = Utf8BackspaceAt(self.text, self.cursor)
			end
		else
			self:ClearSelected()
		end
	elseif key == Spring.GetKeyCode("delete") then
		if self.selStart == nil then
			if mods.ctrl then
				repeat
					self.text = Utf8DeleteAt(self.text, self.cursor)
				until self.cursor >= #self.text-1 or (self.text:sub(self.cursor, self.cursor) == " " and self.text:sub(self.cursor+1, self.cursor+1) ~= " ")
			else
			self.text = Utf8DeleteAt(txt, cp)
			end
		else
			self:ClearSelected()
		end

	-- cursor movement
	elseif key == Spring.GetKeyCode("left") then
		if mods.ctrl then
			repeat
				self.cursor = Utf8PrevChar(txt, self.cursor)
			until self.cursor == 1 or (txt:sub(self.cursor-1, self.cursor-1) ~= " " and txt:sub(self.cursor, self.cursor) == " ")
		else
		self.cursor = Utf8PrevChar(txt, cp)
		end
	elseif key == Spring.GetKeyCode("right") then
		if mods.ctrl then
			repeat
				self.cursor = Utf8NextChar(txt, self.cursor)
			until self.cursor >= #txt-1 or (txt:sub(self.cursor-1, self.cursor-1) == " " and txt:sub(self.cursor, self.cursor) ~= " ")
		else
		self.cursor = Utf8NextChar(txt, cp)
		end
	elseif key == Spring.GetKeyCode("home") then
		self.cursor = 1
	elseif key == Spring.GetKeyCode("end") then
		self.cursor = #txt + 1

	-- copy & paste
	elseif mods.ctrl and (key == Spring.GetKeyCode("c") or key == Spring.GetKeyCode("x")) then
		local s = self.selStart
		local e = self.selEnd
		if s and e then
			s,e = math.min(s,e), math.max(s,e)
			Spring.SetClipboard(txt:sub(s,e-1))
		end
		if key == Spring.GetKeyCode("x") and self.selStart ~= nil then
			self:ClearSelected()
		end
	elseif mods.ctrl and key == Spring.GetKeyCode("v") then
		self:TextInput(Spring.GetClipboard())

	-- select all
	elseif mods.ctrl and key == Spring.GetKeyCode("a") then
		self.selStart = 1
		self.selEnd = #txt + 1
	-- character input
	elseif unicode and unicode ~= 0 then
		-- backward compability with Spring <97
		self:TextInput(unicode)
	end
	
	-- text selection handling
	if key == Spring.GetKeyCode("left") or key == Spring.GetKeyCode("right") or key == Spring.GetKeyCode("home") or key == Spring.GetKeyCode("end") then
		if mods.shift then
			if not self.selStart then
				self.selStart = cp
			end
			self.selEnd = self.cursor
		elseif self.selStart then
			self.selStart = nil
			self.selEnd = nil
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
		if not success then
			unicode = nil
		end
	end

	if unicode then
		local cp  = self.cursor
		local txt = self.text
		if self.selStart ~= nil then
			self:ClearSelected()
			txt = self.text
			cp = self.cursor
		end
		self.text = txt:sub(1, cp - 1) .. unicode .. txt:sub(cp, #txt)
		self.cursor = cp + unicode:len()
	end

	self._interactedTime = Spring.GetTimer()
	inherited.TextInput(self, utf8char, ...)
	self:UpdateLayout()
	self:Invalidate()
	return self
end

--//=============================================================================
