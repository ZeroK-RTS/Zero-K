--//=============================================================================
include("keysym.h.lua")

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
	elseif key == KEYSYMS.BACKSPACE then
		if #txt > 0 and cp > 1 then
			self.cursor = cp - 1
			self.text = txt:sub(1, cp - 2) .. txt:sub(cp, #txt)
		end
	elseif key == KEYSYMS.DELETE then
		if #txt > 0 and cp <= #txt then
			self.text = txt:sub(1, cp - 1) .. txt:sub(cp + 1, #txt)
		end
	elseif key == KEYSYMS.LEFT then
		if cp > 1 then
			self.cursor = cp - 1
		end
	elseif key == KEYSYMS.RIGHT then
		if cp <= #txt then
			self.cursor = cp + 1
		end
	elseif key == KEYSYMS.HOME then
		self.cursor = 1
	elseif key == KEYSYMS.END then
		self.cursor = #txt + 1
	else
		local char = nil
		local success, char = pcall(string.char, unicode)
		if success then
			success = not char:find("%c")
		end
		if not success then
			char = nil
		end
		if char then
			self.text = txt:sub(1, cp - 1) .. char .. txt:sub(cp, #txt)
			self.cursor = cp + 1
		else
			return false
		end
	end
	self._interactedTime = Spring.GetTimer()
	inherited.KeyPress(self, key, mods, isRepeat, label, unicode, ...)
	self:UpdateLayout()
	self:Invalidate()
	return self
end
--//=============================================================================
