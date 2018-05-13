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
  classname = "editbox",

  defaultWidth = 70,
  defaultHeight = 20,

  padding = {3,3,3,3},

  cursorColor = {0,0,1,0.7},
  selectionColor = {0,1,1,0.3},

  align    = "left",
  valign   = "linecenter",

  hintFont = table.merge({ color = {1,1,1,0.7} }, Control.font),

  text   = "", -- Do NOT use directly.
  hint   = "",
  cursor = 1,
  offset = 1,
  lineSpacing = 0,
  selStart = nil,
  selEnd = nil,

  editable = true,
  selectable = true,
  multiline = false,

  passwordInput = false,
  lines = {},
  physicalLines = {},
  cursorX = 1,
  cursorY = 1,
  
  inedibleInput = {
    [Spring.GetKeyCode("enter")] = true,
    [Spring.GetKeyCode("numpad_enter")] = true,
    [Spring.GetKeyCode("esc")] = true,
  },
}

local this = EditBox
local inherited = this.inherited

--//=============================================================================

function EditBox:New(obj)
	obj = inherited.New(self,obj)
	obj._interactedTime = Spring.GetTimer()
	  --// create font
	obj.hintFont = Font:New(obj.hintFont)
	obj.hintFont:SetParent(obj)
	local text = obj.text
	obj.text = nil
	obj:SetText(text)
	obj:RequestUpdate()
	self._inRequestUpdate = true
	return obj
end

function EditBox:Dispose(...)
	Control.Dispose(self)
	self.hintFont:SetParent()
end

function EditBox:HitTest(x,y)
	return self.selectable and self
end

--//=============================================================================

local function explode(str)
	local arr = {}
	local i, j = 1, 1
	local N = str:len()

	while j <= N do
		local c = str:sub(j, j)
		if c == '\255' then
			j = j + 3
		elseif c == '\10' then
			arr[#arr + 1] = str:sub(i, j - 1)
			i = j + 1
		end
		j = j + 1
	end

	if i <= N then
		arr[#arr + 1] = str:sub(i, N)
	end

	return arr
end

--- Sets the EditBox text
-- @string newtext text to be set
function EditBox:SetText(newtext)
	if (self.text == newtext) then return end
	self.text = newtext
	self.cursor = 1
	self.physicalCursor = 1
	self.offset = 0
	self.selStart = nil
	self.selStartY = nil
	self.selEnd = nil
	self.selEndY = nil
	self.lines = {}
	self.physicalLines = {}
	for _, line in pairs(explode(self.text)) do
		self:AddLine(line)
	end
	self:UpdateLayout()
	self:Invalidate()
end

function EditBox:_SetSelection(selStart, selStartY, selEnd, selEndY)
	if #self.lines == 0 then
		return
	end
	self.selStart  = selStart        or self.selStart
	self.selStartY = selStartY       or self.selStartY
-- 	self.selStartY = self.selStartY  or 1
	self.selEnd    = selEnd          or self.selEnd
	self.selEndY   = selEndY         or self.selEndY
-- 	self.selEndY   = self.selEndY    or 1
	if selStart or selStartY then
		self.selStartPhysical  = self.selStart
		local logicalLine = self.lines[self.selStartY]
		if logicalLine == nil then
			-- FIXME: Don't ignore errors
			Spring.Log("Chobby", LOG.DEBUG, "self.selStartY", self.selStartY, #self.lines)
			return
		end
		for _, plID in pairs(logicalLine.pls) do
			local pl = self.physicalLines[plID]
			self.selStartPhysicalY = plID
			if #pl.text + 1 >= self.selStartPhysical or plID == #logicalLine.pls then
				break
			end
			self.selStartPhysical  = self.selStartPhysical - #pl.text
		end
	end

	if selEnd or selEndY then
		self.selEndPhysical  = self.selEnd
		local logicalLine = self.lines[self.selEndY]
		if logicalLine == nil then
			-- FIXME: Don't ignore errors
			Spring.Log("Chobby", LOG.DEBUG, "self.selEndY", self.selEndY, #self.lines)
			return
		end
		for _, plID in pairs(logicalLine.pls) do
			local pl = self.physicalLines[plID]
			self.selEndPhysicalY = plID
			if #pl.text + 1 >= self.selEndPhysical or plID == #logicalLine.pls then
				break
			end
			self.selEndPhysical = self.selEndPhysical - #pl.text
		end
	end
end

function EditBox:GetPhysicalLinePosition(distanceFromBottom)
	local lineID = #self.lines - distanceFromBottom + 1
	if lineID < 1 then
		return 0
	end

	local position = 0
	for i = #self.physicalLines, 1, -1 do
		local data = self.physicalLines[i]
		if data.lineID == lineID then
			position = data.y
		elseif data.lineID < lineID then
			return position
		end
	end
	return 0
end

function EditBox:_GeneratePhysicalLines(logicalLineID)
	local line = self.lines[logicalLineID]
	local text = line.text

	-- find colors
	local colors = {}
	local startIndex = 1
	while true do
		local cp = string.find(text, "\255", startIndex)
		if not cp then break end
		table.insert(colors, cp)
		startIndex = cp + 4
	end

	-- calculate size of physical lines
	local font = self.font
	local padding = self.padding
	local width  = self.width - padding[1] - padding[3]
	local height = self.height - padding[2] - padding[4]
	if self.autoHeight then
		height = 1e9
	end

	local wrappedText = font:WrapText(text, width, height)

	local y = 0
	local fontLineHeight = font:GetLineHeight() + self.lineSpacing
	local prevLine = self.physicalLines[#self.physicalLines]
	if prevLine ~= nil then
		y = prevLine.y + fontLineHeight
	end

	-- the first line's prefix is applied by default
	local colorPrefix = ""
	local totalLength = 0
	-- split the text into physical lines
	for lineIndex, lineText in pairs(explode(wrappedText)) do
	  local th, td = font:GetTextHeight(lineText)
	  local _txt = colorPrefix .. lineText
	  table.insert(self.physicalLines, {
		  text = _txt,
		  th   = th,
		  td   = td,
		  lh   = fontLineHeight,
		  tw   = font:GetTextWidth(lineText),
		  y    = y,
		  -- link to the logical line ID
		  lineID = logicalLineID,
	  })
	  y = y + fontLineHeight

	  -- link to the physical line ID
	  table.insert(line.pls, #self.physicalLines)

	  -- find color for next line
	  if #colors > 0 then
		totalLength = totalLength + #_txt
		local colorIndex = 1
		while colorIndex <= #colors do
			if colors[colorIndex] > totalLength then
				break
			end
			colorIndex = colorIndex + 1
		end
		colorIndex = colorIndex - 1

		colorPrefix = ""
		if colors[colorIndex] ~= nil then
			local cp = colors[colorIndex]
			colorPrefix = text:sub(cp, cp+3)
		end
	  end
    end

	if self.autoHeight then
		local totalHeight = #self.physicalLines * fontLineHeight
		self:Resize(nil, totalHeight, true, true)
	end
end

-- will automatically wrap into multiple lines if too long
function EditBox:AddLine(text, tooltips, OnTextClick)
	-- add logical line
	local line = {
		text = text,
		tooltips = tooltips,
		OnTextClick = OnTextClick,
		pls = {}, -- indexes of physical lines
	}
	table.insert(self.lines, line)
	local lineID = #self.lines
	self:_GeneratePhysicalLines(lineID)

	--   if self.autoHeight then
--     local textHeight,textDescender,numLines = font:GetTextHeight(self._wrappedText)
--     textHeight = textHeight-textDescender
--
--     if (self.autoObeyLineHeight) then
--       if (numLines>1) then
--         textHeight = numLines * font:GetLineHeight() + self.lineSpacing
--       else
--         --// AscenderHeight = LineHeight w/o such deep chars as 'g','p',...
--         textHeight = math.min( math.max(textHeight, font:GetAscenderHeight()), font:GetLineHeight() + self.lineSpacing)
--       end
--     end
--
--     self:Resize(nil, textHeight, true, true)
--   end
	self._inRequestUpdate = true
	self:RequestUpdate()
	self:Invalidate()
end

function EditBox:GetText()
	if not self.multiline then
		return self.text
	else
		local ls = {}
		for i = 1, #self.lines do
			table.insert(ls, self.lines[i].text)
		end
		return table.concat(ls, "\n")
	end
end

function EditBox:UpdateLayout()
--   if self.multiline then
-- 	local lines = {}
-- 	for i = 1, #self.lines do
-- 		table.insert(lines, self.lines[i].text)
-- 	end
-- 	local txt = table.concat(lines, "\n")
--
-- 	self:SetText(txt)
--   end
  local font = self.font
	if self.multiline then
		if self._inRequestUpdate then
			self._inRequestUpdate = false
		else
			self.physicalLines = {}
			for lineID = 1, #self.lines do
				self.lines[lineID].pls = {}
				self:_GeneratePhysicalLines(lineID)
			end
			self:_SetSelection(self.selStart, self.selStartY, self.selEnd, self.selEndY)
-- 			local txt = self:GetText()
-- 			self.text = nil
-- 			self:SetText(txt)
		end
	end

	if self.autoHeight then
		local fontLineHeight = font:GetLineHeight() + self.lineSpacing
		local totalHeight = #self.physicalLines * fontLineHeight
		self:Resize(nil, totalHeight, true, true)
	end
  --FIXME
  if (self.autosize) then
    local w = font:GetTextWidth(self.text);
    local h, d, numLines = font:GetTextHeight(self.text);

    if (self.autoObeyLineHeight) then
      h = math.ceil(numLines * (font:GetLineHeight() + self.lineSpacing))
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

	if self.state.focused and self.editable then
		self:RequestUpdate()
		if (os.clock() >= (self._nextCursorRedraw or -math.huge)) then
			self._nextCursorRedraw = os.clock() + 0.1 --10FPS
			self:Invalidate()
		end
	end
end

function EditBox:_GetCursorByMousePos(x, y)
	local retVal = {
		offset = self.offset,
		cursor = self.cursor,
		cursorY = self.cursorY,
		physicalCursor = self.physicalCursor,
		physicalCursorY = self.physicalCursorY
	}

	local clientX, clientY = self.clientArea[1], self.clientArea[2]
	if not self.multiline and x - clientX < 0 then
		retVal.offset  = retVal.offset - 1
		retVal.offset  = math.max(0, retVal.offset)
		retVal.cursor  = retVal.offset + 1
		retVal.cursorY = 1
		return retVal
	else
		local text = self.text
		-- properly accounts for passworded text where characters are represented as "*"
		-- TODO: what if the passworded text is displayed differently? this is using assumptions about the skin
		if #text > 0 and self.passwordInput then
			text = string.rep("*", #text)
		end
		retVal.cursorY = #self.physicalLines
		for i, line in pairs(self.physicalLines) do
			if line.y > y - clientY then
				retVal.cursorY = math.max(1, i-1)
				break
			end
		end
		local selLine = self.physicalLines[retVal.cursorY]
		if not selLine then return retVal end
		selLine = selLine.text
		if not self.multiline then
			selLine = text
		end
		retVal.cursor = #selLine + 1
		for i = 1, #selLine do
			local tmp = selLine:sub(1 + retVal.offset, i)
			if self.font:GetTextWidth(tmp) > (x - clientX) then
				retVal.cursor = i
				break
			end
		end


		-- convert back to logical line
		retVal.physicalCursorY = retVal.cursorY
		retVal.physicalCursor  = retVal.cursor

		local physicalLine = self.physicalLines[retVal.physicalCursorY]
		retVal.cursorY = physicalLine.lineID

		local logicalLine = self.lines[retVal.cursorY]
		for i, plID in pairs(logicalLine.pls) do
			-- FIXME when less tired
-- 			if i > 1 or #physicalLine.text + 1 == self.physicalCursor then
-- 				self.cursor = self.cursor - 1
-- 			end
-- 			if i > 1 then
-- 				self.cursor = self.cursor - 1
-- 			end
			if plID == retVal.physicalCursorY then
				break
			end
			retVal.cursor = retVal.cursor + #self.physicalLines[plID].text
		end
-- 		if logicalLine.pls[#logicalLine.pls] ~= self.physicalCursorY and  then
-- 			self.cursor = self.cursor - 1
-- 		end
-- 		Spring.Echo(self.cursor)
--         for i = self.offset, #text do
--            local tmp = text:sub(self.offset, i)
--            local h, d = self.font:GetTextHeight(tmp)
--            if h-d > (y - clientY) then
-- 				self.cursor = i
-- 				break
-- 			end
--         end
--         Spring.Echo(self.cursor, #text)
-- 		for i = self.cursor, #text do
-- 			local tmp = text:sub(self.offset, i)
-- 			if self.font:GetTextWidth(tmp) > (x - clientX) then
-- 				self.cursor = i
-- 				break
-- 			end
-- 		end
		return retVal
	end
end

function EditBox:_SetCursorByMousePos(x, y)
	local retVal = self:_GetCursorByMousePos(x, y)
	self.offset          = retVal.offset
	self.cursor          = retVal.cursor
	self.cursorY         = retVal.cursorY
	self.physicalCursor  = retVal.physicalCursor
	self.physicalCursorY = retVal.physicalCursorY
end


function EditBox:MouseDown(x, y, ...)
	-- FIXME: didn't feel like reimplementing Screen:MouseDown to capture MouseClick correctly, so clicking on text items is triggered in MouseDown
	-- handle clicking on text items
	local retVal = self:_GetCursorByMousePos(x, y)
	local line = self.lines[retVal.cursorY]
	if line and line.OnTextClick then
		local cx, cy = self:ScreenToLocal(x, y)
		for _, OnTextClick in pairs(line.OnTextClick) do
			if OnTextClick.startIndex <= retVal.cursor and OnTextClick.endIndex >= retVal.cursor then
				for _, f in pairs(OnTextClick.OnTextClick) do
					f(self, cx, cy, ...)
				end
				self._interactedTime = Spring.GetTimer()
				inherited.MouseDown(self, x, y, ...)
				self:Invalidate()
				return self
			end
		end
	end

	if not self.selectable then
		return false
	end
	local _, _, _, shift = Spring.GetModKeyState()
	local cp, cpy = self.cursor, self.cursorY
	self:_SetCursorByMousePos(x, y)
	if shift then
		if not self.selStart then
			self:_SetSelection(cp, cpy, nil, nil)
		end
		self:_SetSelection(nil, nil, self.cursor, self.cursorY)
	elseif self.selStart then
		self.selStart = nil
		self.selStartY = nil
		self.selEnd = nil
		self.selEndY = nil
	end

	self._interactedTime = Spring.GetTimer()
	inherited.MouseDown(self, x, y, ...)
	self:Invalidate()
	return self
end

function EditBox:MouseMove(x, y, dx, dy, button)
	if button == nil then -- handle tooltips
		local retVal = self:_GetCursorByMousePos(x, y)
		local line = self.lines[retVal.cursorY]
		if line and line.tooltips then
			for _, tooltip in pairs(line.tooltips) do
				if tooltip.startIndex <= retVal.cursor and tooltip.endIndex >= retVal.cursor then
					Screen0.currentTooltip = tooltip.tooltip
				end
			end
		end
	end

	if button ~= 1 then
		return inherited.MouseMove(self, x, y, dx, dy, button)
	end

	local _, _, _, shift = Spring.GetModKeyState()
	local cp, cpy = self.cursor, self.cursorY
	self:_SetCursorByMousePos(x, y)
	if not self.selStart then
		self:_SetSelection(cp, cpy, nil, nil)
	end
	self:_SetSelection(nil, nil, self.cursor, self.cursorY)

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
	self:_SetSelection(startIndex, endIndex, 1, 1)
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

-- TODO only works/tested for not multiline things, joy ^_^
function EditBox:UpdateLine(lineID, text)
	local logicalLine = self.lines[lineID]
	self.physicalLines = {} -- TODO
	if logicalLine == nil and lineID == 1 then
		self:AddLine(text)
	else
		logicalLine.text = text
		for lineID = 1, #self.lines do
			self.lines[lineID].pls = {}
			self:_GeneratePhysicalLines(lineID)
		end
	end
	self.selStartY = 1
end

function EditBox:KeyPress(key, mods, isRepeat, label, unicode, ...)
	local cp = self.cursor
	local txt = self.text
	local eatInput = true

	-- deletions
	if key == Spring.GetKeyCode("backspace") and self.editable then
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
	elseif key == Spring.GetKeyCode("delete") and self.editable then
		if self.selStart == nil then
			if mods.ctrl then
				repeat
					self.text = Utf8DeleteAt(self.text, self.cursor)
					self:UpdateLine(1, self.text)
				until self.cursor >= #self.text-1 or (self.text:sub(self.cursor, self.cursor) == " " and self.text:sub(self.cursor+1, self.cursor+1) ~= " ")
			else
				self.text = Utf8DeleteAt(txt, cp)
				self:UpdateLine(1, self.text)
			end
		else
			self:ClearSelected()
		end

	-- TODO: Fix cursor movement for multiline
	-- cursor movement
	elseif key == Spring.GetKeyCode("left") and not self.multiline then
		if mods.ctrl then
			repeat
				self.cursor = Utf8PrevChar(txt, self.cursor)
			until self.cursor == 1 or (txt:sub(self.cursor-1, self.cursor-1) ~= " " and txt:sub(self.cursor, self.cursor) == " ")
		else
		self.cursor = Utf8PrevChar(txt, cp)
		end
	elseif key == Spring.GetKeyCode("right") and not self.multiline then
		if mods.ctrl then
			repeat
				self.cursor = Utf8NextChar(txt, self.cursor)
			until self.cursor >= #txt-1 or (txt:sub(self.cursor-1, self.cursor-1) == " " and txt:sub(self.cursor, self.cursor) ~= " ")
		else
		self.cursor = Utf8NextChar(txt, cp)
		end
	elseif key == Spring.GetKeyCode("home") and not self.multiline then
		self.cursor = 1
	elseif key == Spring.GetKeyCode("end") and not self.multiline then
		self.cursor = #txt + 1

	-- copy & paste
	elseif mods.ctrl and (key == Spring.GetKeyCode("c") or (key == Spring.GetKeyCode("x") and self.editable)) then
		local sy = self.selStartY
		local ey = self.selEndY
		local s = self.selStart
		local e = self.selEnd
		if s and e then
			if self.multiline and sy > ey then
				sy, ey = sy, ey
				s, e = e, s
			elseif sy == ey and s > e then
				s, e = e, s
			end
			if self.multiline then
				txt = self.lines[sy].text
			end
			if not self.multiline or sy == ey then
-- 				Spring.Echo("SEL", txt:sub(s, e - 1))
				txt = txt:sub(s, e - 1)
			else
				local ls = {}
				local topText = self.lines[sy].text
				local bottomText = self.lines[ey].text
				table.insert(ls, topText:sub(s))
				for i = sy+1, ey-1 do
					table.insert(ls, self.lines[i].text)
				end
				table.insert(ls, bottomText:sub(1, e))
				txt = table.concat(ls, "\n")
			end
			Spring.SetClipboard(txt)
-- 			Spring.SetClipboard()
		end
		if key == Spring.GetKeyCode("x") and self.selStart ~= nil then
			self:ClearSelected()
		end
	elseif mods.ctrl and key == Spring.GetKeyCode("v") and self.editable then
		self:TextInput(Spring.GetClipboard())

	-- select all
	elseif mods.ctrl and key == Spring.GetKeyCode("a") then
		if not self.multiline then
			self.selStart = 1
			self.selStartPhysical = 1
			self.selEnd = #txt + 1
			self.selEndPhysical = #txt + 1
		else
			self:_SetSelection(1, 1, #self.lines[#self.lines].text + 1, #self.lines)
		end
	else
		eatInput = self.state.focused and not self.inedibleInput[key]
	end

	-- text selection handling
	if key == Spring.GetKeyCode("left") or key == Spring.GetKeyCode("right") or key == Spring.GetKeyCode("home") or key == Spring.GetKeyCode("end") then
		if mods.shift then
			if not self.selStart then
				self:_SetSelection(cp, nil, nil, nil)
			end
			self:_SetSelection(nil, nil, self.cursor, nil)
		elseif self.selStart then
			self.selStart = nil
			self.selEnd = nil
		end
	end


	self._interactedTime = Spring.GetTimer()
	eatInput = inherited.KeyPress(self, key, mods, isRepeat, label, unicode, ...) or eatInput
	self:UpdateLayout()
	self:Invalidate()
	return eatInput
end


function EditBox:TextInput(utf8char, ...)
	if not self.editable then
		return false
	end
	local unicode = utf8char

	if unicode then
		local cp  = self.cursor
		local txt = self.text
		if self.selStart ~= nil then
			self:ClearSelected()
			txt = self.text
			cp = self.cursor
		end
		self.text = txt:sub(1, cp - 1) .. unicode .. txt:sub(cp, #txt)
		self:UpdateLine(1, self.text)
		self.cursor = cp + unicode:len()
	end

	self._interactedTime = Spring.GetTimer()
	inherited.TextInput(self, utf8char, ...)
	self:UpdateLayout()
	self:Invalidate()
	return self
end

--//=============================================================================
