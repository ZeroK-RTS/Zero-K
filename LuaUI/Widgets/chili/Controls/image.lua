--// =============================================================================

--- Image module

--- Image fields.
-- Inherits from Control.
-- @see button.Button
-- @table Image
-- @tparam {r, g, b, a} color color, (default {1, 1, 1, 1})
-- @string[opt = nil] file path
-- @bool[opt = true] keepAspect aspect should be kept
-- @tparam {func1, func2} OnClick function listeners to be invoked on click (default {})
Image = Button:Inherit{
	classname = "image",

	defaultWidth  = 64,
	defaultHeight = 64,
	padding = {0, 0, 0, 0},
	color = {1, 1, 1, 1},
	color2 = nil,

	file  = nil,
	file2 = nil,

	flip  = true;
	flip2 = true;

	keepAspect = true;
	
	checkFileExists = false;
	fallbackFile = false;
	imageLoadTime = 3.5; -- Seconds

	useRTT = false;

	OnClick  = {},

	noFont = true,
}


local this = Image
local inherited = this.inherited

--// =============================================================================

local function _DrawTextureAspect(x, y, w, h , tw, th, flipy)
	local twa = w/tw
	local tha = h/th

	local aspect = 1
	if (twa < tha) then
		aspect = twa
		y = y + h*0.5 - th*aspect*0.5
		h = th*aspect
	else
		aspect = tha
		x = x + w*0.5 - tw*aspect*0.5
		w = tw*aspect
	end

	local right  = math.ceil(x + w)
	local bottom = math.ceil(y + h)
	x = math.ceil(x)
	y = math.ceil(y)

	gl.TexRect(x, y, right, bottom, false, flipy)
end

function Image:DrawControl()
	local file = self.file
	local file2 = self.file2
	if (not (file or file2)) then
		return
	end
	
	if self.checkFileExists then
		if self._loadTimer then
			if Spring.DiffTimers(Spring.GetTimer(), self._loadTimer) > self.imageLoadTime then
				self.checkFileExists = false
			end
		elseif ((not file) or VFS.FileExists(file)) and ((not file2) or VFS.FileExists(file2)) then
			self._loadTimer = Spring.GetTimer()
		end
	
		if self.fallbackFile then
			file = self.fallbackFile
			file2 = nil
		else
			return
		end
	end
	
	if (self.keepAspect) then
		if (file2) then
			gl.Color(self.color2 or self.color)
			TextureHandler.LoadTexture(0, file2, self)
			local texInfo = gl.TextureInfo(file2) or {xsize = 1, ysize = 1}
			local tw, th = texInfo.xsize, texInfo.ysize
			_DrawTextureAspect(0, 0, self.width, self.height, tw, th, self.flip2)
		end
		if (file) then
			gl.Color(self.color)
			TextureHandler.LoadTexture(0, file, self)
			local texInfo = gl.TextureInfo(file) or {xsize = 1, ysize = 1}
			local tw, th = texInfo.xsize, texInfo.ysize
			_DrawTextureAspect(0, 0, self.width, self.height, tw, th, self.flip)
		end
	else
		if (file2) then
			gl.Color(self.color2 or self.color)
			TextureHandler.LoadTexture(0, file2, self)
			gl.TexRect(0, 0, self.width, self.height, false, self.flip2)
		end
		if (file) then
			gl.Color(self.color)
			TextureHandler.LoadTexture(0, file, self)
			gl.TexRect(0, 0, self.width, self.height, false, self.flip)
		end
	end
	gl.Texture(0, false)
end

--// =============================================================================

function Image:IsActive()
	local onclick = self.OnClick
	if (onclick and onclick[1]) then
		return true
	end
end

function Image:HitTest()
	--FIXME check if there are any eventhandlers linked (OnClick, OnMouseUp, ...)
	return self:IsActive() and self
end

function Image:MouseDown(...)
	--// we don't use `this` here because it would call the eventhandler of the button class,
	--// which always returns true, but we just want to do so if a calllistener handled the event
	return Control.MouseDown(self, ...) or self:IsActive() and self
end

function Image:MouseUp(...)
	return Control.MouseUp(self, ...) or self:IsActive() and self
end

function Image:MouseClick(...)
	return Control.MouseClick(self, ...) or self:IsActive() and self
end

--// =============================================================================
