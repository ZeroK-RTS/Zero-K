--//=============================================================================
--//

function _DrawTextureAspect(x,y,w,h ,tw,th)
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

  local right  = math.ceil(x+w)
  local bottom = math.ceil(y+h)
  x = math.ceil(x)
  y = math.ceil(y)

  gl.TexRect(x,y,right,bottom,false,true)
end
local _DrawTextureAspect = _DrawTextureAspect


function _DrawTiledTexture(x,y,w,h, skLeft,skTop,skRight,skBottom, texw,texh, texIndex)
    texIndex = texIndex or 0

    local txLeft   = skLeft/texw
    local txTop    = skTop/texh
    local txRight  = skRight/texw
    local txBottom = skBottom/texh

    --//scale down the texture if we don't have enough space

    local scaleY = h/(skTop+skBottom)
    local scaleX = w/(skLeft+skRight)
    local scale = (scaleX < scaleY) and scaleX or scaleY
    if (scale<1) then
      skTop = skTop * scale
      skBottom = skBottom * scale
      skLeft = skLeft * scale
      skRight = skRight * scale
    end

    --//topleft
    gl.MultiTexCoord(texIndex,0,0)
    gl.Vertex(x,      y)

    gl.MultiTexCoord(texIndex,0,txTop)
    gl.Vertex(x,      y+skTop)
    gl.MultiTexCoord(texIndex,txLeft,0)
    gl.Vertex(x+skLeft, y)
    gl.MultiTexCoord(texIndex,txLeft,txTop)
    gl.Vertex(x+skLeft, y+skTop)

    --//topcenter
    gl.MultiTexCoord(texIndex,1-txRight,0)
    gl.Vertex(x+w-skRight, y)
    gl.MultiTexCoord(texIndex,1-txRight,txTop)
    gl.Vertex(x+w-skRight, y+skTop)

    --//topright
    gl.MultiTexCoord(texIndex,1,0)
    gl.Vertex(x+w,       y)
    gl.MultiTexCoord(texIndex,1,txTop)
    gl.Vertex(x+w,       y+skTop)

    --//right center
    gl.MultiTexCoord(texIndex,1,1-txBottom)
    gl.Vertex(x+w,       y+h-skBottom)    --//degenerate
    gl.MultiTexCoord(texIndex,1-txRight,txTop)
    gl.Vertex(x+w-skRight, y+skTop)
    gl.MultiTexCoord(texIndex,1-txRight,1-txBottom)
    gl.Vertex(x+w-skRight, y+h-skBottom)

    --//background
    gl.MultiTexCoord(texIndex,txLeft,txTop)
    gl.Vertex(x+skLeft,    y+skTop)
    gl.MultiTexCoord(texIndex,txLeft,1-txBottom)
    gl.Vertex(x+skLeft,    y+h-skBottom)

    --//left center
    gl.MultiTexCoord(texIndex,0,txTop)
    gl.Vertex(x,    y+skTop)
    gl.MultiTexCoord(texIndex,0,1-txBottom)
    gl.Vertex(x,    y+h-skBottom)

    --//bottom right
    gl.MultiTexCoord(texIndex,0,1)
    gl.Vertex(x,      y+h)    --//degenerate
    gl.MultiTexCoord(texIndex,txLeft,1-txBottom)
    gl.Vertex(x+skLeft, y+h-skBottom)
    gl.MultiTexCoord(texIndex,txLeft,1)
    gl.Vertex(x+skLeft, y+h)

    --//bottom center
    gl.MultiTexCoord(texIndex,1-txRight,1-txBottom)
    gl.Vertex(x+w-skRight, y+h-skBottom)
    gl.MultiTexCoord(texIndex,1-txRight,1)
    gl.Vertex(x+w-skRight, y+h)

    --//bottom right
    gl.MultiTexCoord(texIndex,1,1-txBottom)
    gl.Vertex(x+w, y+h-skBottom)
    gl.MultiTexCoord(texIndex,1,1)
    gl.Vertex(x+w, y+h)
end
local _DrawTiledTexture = _DrawTiledTexture


function _DrawTiledBorder(x,y,w,h, skLeft,skTop,skRight,skBottom, texw,texh, texIndex)
  texIndex = texIndex or 0

  local txLeft   = skLeft/texw
  local txTop    = skTop/texh
  local txRight  = skRight/texw
  local txBottom = skBottom/texh

  --//scale down the texture if we don't have enough space
  local scaleY = h/(skTop+skBottom)
  local scaleX = w/(skLeft+skRight)
  local scale = (scaleX < scaleY) and scaleX or scaleY
  if (scale<1) then
    skTop = skTop * scale
    skBottom = skBottom * scale
    skLeft = skLeft * scale
    skRight = skRight * scale
  end

  --//topleft
  gl.MultiTexCoord(texIndex,0,0)
  gl.Vertex(x,      y)
  gl.MultiTexCoord(texIndex,0,txTop)
  gl.Vertex(x,      y+skTop)
  gl.MultiTexCoord(texIndex,txLeft,0)
  gl.Vertex(x+skLeft, y)
  gl.MultiTexCoord(texIndex,txLeft,txTop)
  gl.Vertex(x+skLeft, y+skTop)

  --//topcenter
  gl.MultiTexCoord(texIndex,1-txRight,0)
  gl.Vertex(x+w-skRight, y)
  gl.MultiTexCoord(texIndex,1-txRight,txTop)
  gl.Vertex(x+w-skRight, y+skTop)

  --//topright
  gl.MultiTexCoord(texIndex,1,0)
  gl.Vertex(x+w,       y)
  gl.MultiTexCoord(texIndex,1,txTop)
  gl.Vertex(x+w,       y+skTop)

  --//right center
  gl.Vertex(x+w,         y+skTop)    --//degenerate
  gl.MultiTexCoord(texIndex,1-txRight,txTop)
  gl.Vertex(x+w-skRight, y+skTop)
  gl.MultiTexCoord(texIndex,1,1-txBottom)
  gl.Vertex(x+w,         y+h-skBottom)
  gl.MultiTexCoord(texIndex,1-txRight,1-txBottom)
  gl.Vertex(x+w-skRight, y+h-skBottom)

  --//bottom right
  gl.MultiTexCoord(texIndex,1,1)
  gl.Vertex(x+w,         y+h)
  gl.MultiTexCoord(texIndex,1-txRight,1)
  gl.Vertex(x+w-skRight, y+h)

  --//bottom center
  gl.Vertex(x+w-skRight, y+h)    --//degenerate
  gl.MultiTexCoord(texIndex,1-txRight,1-txBottom)
  gl.Vertex(x+w-skRight, y+h-skBottom)
  gl.MultiTexCoord(texIndex,txLeft,1)
  gl.Vertex(x+skLeft,    y+h)
  gl.MultiTexCoord(texIndex,txLeft,1-txBottom)
  gl.Vertex(x+skLeft,    y+h-skBottom)

  --//bottom left
  gl.MultiTexCoord(texIndex,0,1)
  gl.Vertex(x,        y+h)
  gl.MultiTexCoord(texIndex,0,1-txBottom)
  gl.Vertex(x,        y+h-skBottom)

  --//left center
  gl.Vertex(x,        y+h-skBottom)    --//degenerate
  gl.MultiTexCoord(texIndex,0,txTop)
  gl.Vertex(x,        y+skTop)
  gl.MultiTexCoord(texIndex,txLeft,1-txBottom)
  gl.Vertex(x+skLeft, y+h-skBottom)
  gl.MultiTexCoord(texIndex,txLeft,txTop)
  gl.Vertex(x+skLeft, y+skTop)
end
local _DrawTiledBorder = _DrawTiledBorder


local function _DrawDragGrip(obj)
  local x = 13
  local y = 8
  local w = obj.dragGripSize[1]
  local h = obj.dragGripSize[2]

  gl.Color(0.8,0.8,0.8,0.9)
  gl.Vertex(x, y + h*0.5)
  gl.Vertex(x + w*0.5, y)
  gl.Vertex(x + w*0.5, y + h*0.5)

  gl.Color(0.3,0.3,0.3,0.9)
  gl.Vertex(x + w*0.5, y + h*0.5)
  gl.Vertex(x + w*0.5, y)
  gl.Vertex(x + w, y + h*0.5)

  gl.Vertex(x + w*0.5, y + h)
  gl.Vertex(x, y + h*0.5)
  gl.Vertex(x + w*0.5, y + h*0.5)

  gl.Color(0.1,0.1,0.1,0.9)
  gl.Vertex(x + w*0.5, y + h)
  gl.Vertex(x + w*0.5, y + h*0.5)
  gl.Vertex(x + w, y + h*0.5)
end


local function _DrawResizeGrip(obj)
  if (obj.resizable) then
    local x = 0
    local y = 0

    local resizeBox = GetRelativeObjBox(obj,obj.boxes.resize)

    x = x-1
    y = y-1
    gl.Color(1,1,1,0.2)
      gl.Vertex(x + resizeBox[1], y + resizeBox[4])
      gl.Vertex(x + resizeBox[3], y + resizeBox[2])

      gl.Vertex(x + resizeBox[1] + math.ceil((resizeBox[3] - resizeBox[1])*0.33), y + resizeBox[4])
      gl.Vertex(x + resizeBox[3], y + resizeBox[2] + math.ceil((resizeBox[4] - resizeBox[2])*0.33))

      gl.Vertex(x + resizeBox[1] + math.ceil((resizeBox[3] - resizeBox[1])*0.66), y + resizeBox[4])
      gl.Vertex(x + resizeBox[3], y + resizeBox[2] + math.ceil((resizeBox[4] - resizeBox[2])*0.66))

    x = x+1
    y = y+1
    gl.Color(0.1, 0.1, 0.1, 0.9)
      gl.Vertex(x + resizeBox[1], y + resizeBox[4])
      gl.Vertex(x + resizeBox[3], y + resizeBox[2])

      gl.Vertex(x + resizeBox[1] + math.ceil((resizeBox[3] - resizeBox[1])*0.33), y + resizeBox[4])
      gl.Vertex(x + resizeBox[3], y + resizeBox[2] + math.ceil((resizeBox[4] - resizeBox[2])*0.33))

      gl.Vertex(x + resizeBox[1] + math.ceil((resizeBox[3] - resizeBox[1])*0.66), y + resizeBox[4])
      gl.Vertex(x + resizeBox[3], y + resizeBox[2] + math.ceil((resizeBox[4] - resizeBox[2])*0.66))
  end
end

local function _DrawCursor(x, y, w, h)
	gl.Vertex(x, y)
	gl.Vertex(x, y + h)
	gl.Vertex(x + w, y)
	gl.Vertex(x + w, y + h)
end


--//=============================================================================
--//

function DrawWindow(obj)
  local w = obj.width
  local h = obj.height

  local skLeft,skTop,skRight,skBottom = unpack4(obj.tiles)

  local c = obj.color
  if (c) then
    gl.Color(c)
  else
    gl.Color(1,1,1,1)
  end
  TextureHandler.LoadTexture(0,obj.TileImage,obj)
    local texInfo = gl.TextureInfo(obj.TileImage) or {xsize=1, ysize=1}
    local tw,th = texInfo.xsize, texInfo.ysize

    gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawTiledTexture, 0,0,w,h, skLeft,skTop,skRight,skBottom, tw,th)
  gl.Texture(0,false)

  if (obj.caption) then
    obj.font:Print(obj.caption, w*0.5, 9, "center")
  end
end

--//=============================================================================
--//

function DrawButton(obj)
  if obj.debug then Spring.Echo("DrawButton", obj.name, obj.state.pressed) end

  local w = obj.width
  local h = obj.height

  local skLeft,skTop,skRight,skBottom = unpack4(obj.tiles)

  local bgcolor = obj.backgroundColor
  if (obj.state.pressed) then
    bgcolor = mulColor(bgcolor, 0.4)
  elseif (obj.state.hovered) --[[ or (obj.state.focused)]] then
    bgcolor = obj.focusColor
    --bgcolor = mixColors(bgcolor, obj.focusColor, 0.5)
  end
  gl.Color(bgcolor)

  TextureHandler.LoadTexture(0,obj.TileImageBK,obj)
    local texInfo = gl.TextureInfo(obj.TileImageBK) or {xsize=1, ysize=1}
    local tw,th = texInfo.xsize, texInfo.ysize

    gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawTiledTexture, 0,0,w,h, skLeft,skTop,skRight,skBottom, tw,th, 0)
  --gl.Texture(0,false)

  local fgcolor = obj.borderColor
  if (obj.state.pressed) then
    fgcolor = mulColor(fgcolor, 0.4)
  elseif (obj.state.hovered) --[[ or (obj.state.focused)]] then
    fgcolor = obj.focusColor
  end
  gl.Color(fgcolor)

  TextureHandler.LoadTexture(0,obj.TileImageFG,obj)
    local texInfo = gl.TextureInfo(obj.TileImageFG) or {xsize=1, ysize=1}
    local tw,th = texInfo.xsize, texInfo.ysize

    gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawTiledTexture, 0,0,w,h, skLeft,skTop,skRight,skBottom, tw,th, 0)
  gl.Texture(0,false)

  if (obj.caption) then
    obj.font:Print(obj.caption, w*0.5, h*0.5, "center", "center")
  end
end


function DrawComboBox(self)
	DrawButton(self)

	if (self.state.pressed) then
		gl.Color(self.focusColor)
	else
		gl.Color(1,1,1,1)
	end
	TextureHandler.LoadTexture(0,self.TileImageArrow,self)
		local texInfo = gl.TextureInfo(self.TileImageArrow) or {xsize=1, ysize=1}
		local tw,th = texInfo.xsize, texInfo.ysize
		_DrawTextureAspect(self.width - self.padding[3], 0, self.padding[3], self.height, tw,th)
	gl.Texture(0,false)
end


function DrawEditBox(obj)
	local skLeft,skTop,skRight,skBottom = unpack4(obj.tiles)

	gl.Color(obj.backgroundColor)
	TextureHandler.LoadTexture(0,obj.TileImageBK,obj)
	local texInfo = gl.TextureInfo(obj.TileImageBK) or {xsize=1, ysize=1}
	local tw,th = texInfo.xsize, texInfo.ysize
	gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawTiledTexture, 0, 0, obj.width, obj.height,  skLeft,skTop,skRight,skBottom, tw,th)
	--gl.Texture(0,false)

	if obj.state.focused or obj.state.hovered then
		gl.Color(obj.focusColor)
	else
		gl.Color(obj.borderColor)
	end
	TextureHandler.LoadTexture(0,obj.TileImageFG,obj)
	local texInfo = gl.TextureInfo(obj.TileImageFG) or {xsize=1, ysize=1}
	local tw,th = texInfo.xsize, texInfo.ysize
	gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawTiledTexture, 0, 0, obj.width, obj.height,  skLeft,skTop,skRight,skBottom, tw,th)
	gl.Texture(0,false)

	if (obj.text) then
		if (obj.offset > obj.cursor) then
			obj.offset = obj.cursor
		end

		local clientX,clientY,clientWidth,clientHeight = unpack4(obj.clientArea)

		--// make cursor pos always visible (when text is longer than editbox!)
		repeat
			local txt = obj.text:sub(obj.offset, obj.cursor)
			local wt = obj.font:GetTextWidth(txt)
			if (wt <= clientWidth) then
				break
			end
			if (obj.offset >= obj.cursor) then
				break
			end
			obj.offset = obj.offset + 1
		until (false)

		local txt = obj.text:sub(obj.offset)

		--// strip part at the end that exceeds the editbox
		local lsize = math.max(0, obj.font:WrapText(txt, clientWidth, clientHeight):len() - 3) -- find a good start (3 dots at end if stripped)
		while (lsize <= txt:len()) do
			local wt = obj.font:GetTextWidth(txt:sub(1, lsize))
			if (wt > clientWidth) then
				break
			end
			lsize = lsize + 1
		end
		txt = txt:sub(1, lsize - 1)

		gl.Color(1,1,1,1)
		obj.font:DrawInBox(txt, clientX, clientY, clientWidth, clientHeight, obj.align, obj.valign)

		if obj.state.focused then
			local cursorTxt = obj.text:sub(obj.offset, obj.cursor - 1)
			local cursorX = obj.font:GetTextWidth(cursorTxt)

			local dt = Spring.DiffTimers(Spring.GetTimer(), obj._interactedTime)
			local as = math.sin(dt * 8);
			local ac = math.cos(dt * 8);
			if (as < 0) then as = 0 end
			if (ac < 0) then ac = 0 end
			local alpha = as + ac
			if (alpha > 1) then alpha = 1 end
			alpha = 0.8 * alpha

			local cc = obj.cursorColor
			gl.Color(cc[1], cc[2], cc[3], cc[4] * alpha)
			gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawCursor, cursorX + clientX - 1, clientY, 3, clientHeight)
		end
	end
end

--//=============================================================================
--//

function DrawPanel(obj)
  local w = obj.width
  local h = obj.height

  local skLeft,skTop,skRight,skBottom = unpack4(obj.tiles)

  gl.Color(obj.backgroundColor)
  TextureHandler.LoadTexture(0,obj.TileImageBK,obj)
    local texInfo = gl.TextureInfo(obj.TileImageBK) or {xsize=1, ysize=1}
    local tw,th = texInfo.xsize, texInfo.ysize

    gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawTiledTexture, 0,0,w,h, skLeft,skTop,skRight,skBottom, tw,th, 0)
  --gl.Texture(0,false)

  gl.Color(obj.borderColor)
  TextureHandler.LoadTexture(0,obj.TileImageFG,obj)
    local texInfo = gl.TextureInfo(obj.TileImageFG) or {xsize=1, ysize=1}
    local tw,th = texInfo.xsize, texInfo.ysize

    gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawTiledTexture, 0,0,w,h, skLeft,skTop,skRight,skBottom, tw,th, 0)
  gl.Texture(0,false)
end

--//=============================================================================
--//

function DrawItemBkGnd(obj,x,y,w,h,state)
  local skLeft,skTop,skRight,skBottom = unpack4(obj.tiles)

  if (state=="selected") then
    gl.Color(obj.colorBK_selected)
  else
    gl.Color(obj.colorBK)
  end
  TextureHandler.LoadTexture(0,obj.imageBK,obj)
    local texInfo = gl.TextureInfo(obj.imageBK) or {xsize=1, ysize=1}
    local tw,th = texInfo.xsize, texInfo.ysize
    gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawTiledTexture, x,y,w,h, skLeft,skTop,skRight,skBottom, tw,th, 0)
  --gl.Texture(0,false)

  if (state=="selected") then
    gl.Color(obj.colorFG_selected)
  else
    gl.Color(obj.colorFG)
  end
  TextureHandler.LoadTexture(0,obj.imageFG,obj)
    local texInfo = gl.TextureInfo(obj.imageFG) or {xsize=1, ysize=1}
    local tw,th = texInfo.xsize, texInfo.ysize
    gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawTiledTexture, x,y,w,h, skLeft,skTop,skRight,skBottom, tw,th, 0)
  gl.Texture(0,false)
end

--//=============================================================================
--//

function DrawScrollPanelBorder(self)
  local clientX,clientY,clientWidth,clientHeight = unpack4(self.clientArea)
  local contX,contY,contWidth,contHeight = unpack4(self.contentArea)

  do
      TextureHandler.LoadTexture(0,self.BorderTileImage,self)
      local texInfo = gl.TextureInfo(self.BorderTileImage) or {xsize=1, ysize=1}
      local tw,th = texInfo.xsize, texInfo.ysize

      local skLeft,skTop,skRight,skBottom = unpack4(self.bordertiles)

      local width = self.width
      local height = self.height
      if (self._vscrollbar) then
        width = width - self.scrollbarSize - 1
      end
      if (self._hscrollbar) then
        height = height - self.scrollbarSize - 1
      end

      gl.Color(self.borderColor)
      gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawTiledBorder, 0,0,width,height, skLeft,skTop,skRight,skBottom, tw,th, 0)
      gl.Texture(0,false)
  end
end

--//=============================================================================
--//

function DrawScrollPanel(obj)
  local clientX,clientY,clientWidth,clientHeight = unpack4(obj.clientArea)
  local contX,contY,contWidth,contHeight = unpack4(obj.contentArea)

  if (obj.BackgroundTileImage) then
      TextureHandler.LoadTexture(0,obj.BackgroundTileImage,obj)
      local texInfo = gl.TextureInfo(obj.BackgroundTileImage) or {xsize=1, ysize=1}
      local tw,th = texInfo.xsize, texInfo.ysize

      local skLeft,skTop,skRight,skBottom = unpack4(obj.bkgndtiles)

      local width = obj.width
      local height = obj.height
      if (obj._vscrollbar) then
        width = width - obj.scrollbarSize - 1
      end
      if (obj._hscrollbar) then
        height = height - obj.scrollbarSize - 1
      end

      gl.Color(obj.backgroundColor)
      gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawTiledTexture, 0,0,width,height, skLeft,skTop,skRight,skBottom, tw,th, 0)
      gl.Texture(0,false)
  end

  if obj._vscrollbar then
    local x = obj.width - obj.scrollbarSize
    local y = 0
    local w = obj.scrollbarSize
    local h = obj.height --FIXME what if hscrollbar is visible
    if (obj._hscrollbar) then
      h = h - obj.scrollbarSize
    end

    local skLeft,skTop,skRight,skBottom = unpack4(obj.tiles)

    TextureHandler.LoadTexture(0,obj.TileImage,obj)
      local texInfo = gl.TextureInfo(obj.TileImage) or {xsize=1, ysize=1}
      local tw,th = texInfo.xsize, texInfo.ysize

      gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawTiledTexture, x,y,w,h, skLeft,skTop,skRight,skBottom, tw,th, 0)
    --gl.Texture(0,false)

    if obj._vscrolling or obj._vHovered then
      gl.Color(obj.KnobColorSelected)
    else
      gl.Color(1,1,1,1)
    end

    TextureHandler.LoadTexture(0,obj.KnobTileImage,obj)
      texInfo = gl.TextureInfo(obj.KnobTileImage) or {xsize=1, ysize=1}
      tw,th = texInfo.xsize, texInfo.ysize

      skLeft,skTop,skRight,skBottom = unpack4(obj.KnobTiles)

      local pos = obj.scrollPosY / contHeight
      local visible = clientHeight / contHeight
      local gripy = math.floor(y + h * pos) + 0.5
      local griph = math.floor(h * visible)
      gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawTiledTexture, x,gripy,obj.scrollbarSize,griph, skLeft,skTop,skRight,skBottom, tw,th, 0)
    --gl.Texture(0,false)

    gl.Color(1,1,1,1)
  end

  if obj._hscrollbar then
    gl.Color(1,1,1,1)

    local x = 0
    local y = obj.height - obj.scrollbarSize
    local w = obj.width
    local h = obj.scrollbarSize
    if (obj._vscrollbar) then
      w = w - obj.scrollbarSize
    end

    local skLeft,skTop,skRight,skBottom = unpack4(obj.htiles)

    TextureHandler.LoadTexture(0,obj.HTileImage,obj)
      local texInfo = gl.TextureInfo(obj.HTileImage) or {xsize=1, ysize=1}
      local tw,th = texInfo.xsize, texInfo.ysize

      gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawTiledTexture, x,y,w,h, skLeft,skTop,skRight,skBottom, tw,th, 0)
    --gl.Texture(0,false)

    if obj._hscrolling or obj._hHovered then
      gl.Color(obj.KnobColorSelected)
    else
      gl.Color(1,1,1,1)
    end

    TextureHandler.LoadTexture(0,obj.HKnobTileImage,obj)
      texInfo = gl.TextureInfo(obj.HKnobTileImage) or {xsize=1, ysize=1}
      tw,th = texInfo.xsize, texInfo.ysize

      skLeft,skTop,skRight,skBottom = unpack4(obj.HKnobTiles)

      local pos = obj.scrollPosX / contWidth
      local visible = clientWidth / contWidth
      local gripx = math.floor(x + w * pos) + 0.5
      local gripw = math.floor(w * visible)
      gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawTiledTexture, gripx,y,gripw,obj.scrollbarSize, skLeft,skTop,skRight,skBottom, tw,th, 0)
    --gl.Texture(0,false)
  end

  gl.Texture(0,false)
end

--//=============================================================================
--//

function DrawCheckbox(obj)
  local boxSize = obj.boxsize

  local x = obj.width      - boxSize
  local y = obj.height*0.5 - boxSize*0.5
  local w = boxSize
  local h = boxSize

  local tx = 0
  local ty = obj.height * 0.5 --// verticale center

  if obj.boxalign == "left" then
    x  = 0
    tx = boxSize + 2
  end

  local skLeft,skTop,skRight,skBottom = unpack4(obj.tiles)


  if (obj.state.hovered) then
    gl.Color(obj.focusColor)
  else
    gl.Color(1,1,1,1)
  end
  TextureHandler.LoadTexture(0,obj.TileImageBK,obj)

  local texInfo = gl.TextureInfo(obj.TileImageBK) or {xsize=1, ysize=1}
  local tw,th = texInfo.xsize, texInfo.ysize
    gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawTiledTexture, x,y,w,h, skLeft,skTop,skRight,skBottom, tw,th, 0)
  --gl.Texture(0,false)

  if (obj.state.checked) then
    TextureHandler.LoadTexture(0,obj.TileImageFG,obj)
      gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawTiledTexture, x,y,w,h, skLeft,skTop,skRight,skBottom, tw,th, 0)
  end
  gl.Texture(0,false)

  gl.Color(1,1,1,1)
  if (obj.caption) then
    obj.font:Print(obj.caption, tx, ty, nil, "center")
  end
end

--//=============================================================================
--//

function DrawProgressbar(obj)
  local w = obj.width
  local h = obj.height

  local percent = (obj.value-obj.min)/(obj.max-obj.min)

  local skLeft,skTop,skRight,skBottom = unpack4(obj.tiles)

  gl.Color(obj.backgroundColor)
  TextureHandler.LoadTexture(0,obj.TileImageBK,obj)
    local texInfo = gl.TextureInfo(obj.TileImageBK) or {xsize=1, ysize=1}
    local tw,th = texInfo.xsize, texInfo.ysize

    gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawTiledTexture, 0,0,w,h, skLeft,skTop,skRight,skBottom, tw,th, 0)
  --gl.Texture(0,false)

  gl.Color(obj.color)
  TextureHandler.LoadTexture(0,obj.TileImageFG,obj)
    local texInfo = gl.TextureInfo(obj.TileImageFG) or {xsize=1, ysize=1}
    local tw,th = texInfo.xsize, texInfo.ysize

    gl.ClipPlane(1, -1,0,0, w*percent)
    gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawTiledTexture, 0,0,w,h, skLeft,skTop,skRight,skBottom, tw,th, 0)
    gl.ClipPlane(1, false)
  gl.Texture(0,false)

  if (obj.caption) then
    (obj.font):Print(obj.caption, w*0.5, h*0.5, "center", "center")
  end
end

--//=============================================================================
--//

function DrawTrackbar(self)
  local percent = self:_GetPercent()
  local w = self.width
  local h = self.height

  local skLeft,skTop,skRight,skBottom = unpack4(self.tiles)
  local pdLeft,pdTop,pdRight,pdBottom = unpack4(self.hitpadding)

  gl.Color(1,1,1,1)

  TextureHandler.LoadTexture(0,self.TileImage,self)
    local texInfo = gl.TextureInfo(self.TileImage) or {xsize=1, ysize=1}
    local tw,th = texInfo.xsize, texInfo.ysize
    gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawTiledTexture, 0,0,w,h, skLeft,skTop,skRight,skBottom, tw,th, 0)

  TextureHandler.LoadTexture(0,self.StepImage,self)
    local texInfo = gl.TextureInfo(self.StepImage) or {xsize=1, ysize=1}
    local tw,th = texInfo.xsize, texInfo.ysize

    --// scale the thumb down if we don't have enough space
    if (th>h) then
      tw = math.ceil(tw*(h/th))
      th = h
    end
    if (tw>w) then
      th = math.ceil(th*(w/tw))
      tw = w
    end

    local barWidth = w - (pdLeft + pdRight)
    local stepWidth = barWidth / ((self.max - self.min)/self.step)

    if ((self.max - self.min)/self.step)<20 then
      local newStepWidth = stepWidth
      if (newStepWidth<20) then
        newStepWidth = stepWidth*2
      end
      if (newStepWidth<20) then
        newStepWidth = stepWidth*5
      end
      if (newStepWidth<20) then
        newStepWidth = stepWidth*10
      end
      stepWidth = newStepWidth

      local my = h*0.5
      local mx = pdLeft+stepWidth
      while (mx<(pdLeft+barWidth)) do
        gl.TexRect(math.ceil(mx-tw*0.5),math.ceil(my-th*0.5),math.ceil(mx+tw*0.5),math.ceil(my+th*0.5),false,true)
        mx = mx+stepWidth
      end
    end

  if (self.state.hovered) then
    gl.Color(self.focusColor)
  else
    gl.Color(1,1,1,1)
  end

  TextureHandler.LoadTexture(0,self.ThumbImage,self)
    local texInfo = gl.TextureInfo(self.ThumbImage) or {xsize=1, ysize=1}
    local tw,th = texInfo.xsize, texInfo.ysize

    --// scale the thumb down if we don't have enough space
    tw = math.ceil(tw * (h / th))
    th = h

    local barWidth = w - (pdLeft + pdRight)
    local mx = pdLeft + barWidth * percent
    local my = h * 0.5
    mx = math.floor(mx - tw * 0.5)
    my = math.floor(my - th * 0.5)
    gl.TexRect(mx, my, mx + tw, my + th, false, true)

  gl.Texture(0,false)
end

--//=============================================================================
--//

function DrawTreeviewNode(self)
  if CompareLinks(self.treeview.selected,self) then
    local x = self.clientArea[1]
    local y = 0
    local w = self.children[1].width
    local h = self.clientArea[2] + self.children[1].height

    local skLeft,skTop,skRight,skBottom = unpack4(self.treeview.tiles)

    gl.Color(1,1,1,1)
    TextureHandler.LoadTexture(0,self.treeview.ImageNodeSelected,self)
      local texInfo = gl.TextureInfo(self.treeview.ImageNodeSelected) or {xsize=1, ysize=1}
      local tw,th = texInfo.xsize, texInfo.ysize

      gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawTiledTexture, 0,0,w,h, skLeft,skTop,skRight,skBottom, tw,th, 0)
    gl.Texture(0,false)
  end
end


local function _DrawLineV(x, y1, y2, width, next_func, ...)
  gl.Vertex(x-width*0.5, y1)
  gl.Vertex(x+width*0.5, y1)
  gl.Vertex(x-width*0.5, y2)

  gl.Vertex(x+width*0.5, y1)
  gl.Vertex(x-width*0.5, y2)
  gl.Vertex(x+width*0.5, y2)

  if (next_func) then
    next_func(...)
  end
end


local function _DrawLineH(x1, x2, y, width, next_func, ...)
  gl.Vertex(x1, y-width*0.5)
  gl.Vertex(x1, y+width*0.5)
  gl.Vertex(x2, y-width*0.5)

  gl.Vertex(x1, y+width*0.5)
  gl.Vertex(x2, y-width*0.5)
  gl.Vertex(x2, y+width*0.5)

  if (next_func) then
    next_func(...)
  end
end


function DrawTreeviewNodeTree(self)
  local x1 = math.ceil(self.padding[1]*0.5)
  local x2 = self.padding[1]
  local y1 = 0
  local y2 = self.height
  local y3 = self.padding[2] + math.ceil(self.children[1].height*0.5)

  if (self.parent)and(CompareLinks(self,self.parent.nodes[#self.parent.nodes])) then
    y2 = y3
  end

  gl.Color(self.treeview.treeColor)
  gl.BeginEnd(GL.TRIANGLES, _DrawLineV, x1-0.5, y1, y2, 1, _DrawLineH, x1, x2, y3-0.5, 1)

  if (not self.nodes[1]) then
    return
  end

  gl.Color(1,1,1,1)
  local image = self.ImageExpanded or self.treeview.ImageExpanded
  if (not self.expanded) then
    image = self.ImageCollapsed or self.treeview.ImageCollapsed
  end

  TextureHandler.LoadTexture(0, image, self)
  local texInfo = gl.TextureInfo(image) or {xsize=1, ysize=1}
  local tw,th = texInfo.xsize, texInfo.ysize

  _DrawTextureAspect(0,0,math.ceil(self.padding[1]),math.ceil(self.children[1].height) ,tw,th)
  gl.Texture(0,false)
end


--//=============================================================================
--//

function DrawLine(self)
  gl.Color(self.borderColor)

    if (self.style:find("^v")) then
      local skLeft,skTop,skRight,skBottom = unpack4(self.tilesV)
      TextureHandler.LoadTexture(0,self.TileImageV,self)
        local texInfo = gl.TextureInfo(self.TileImageV) or {xsize=1, ysize=1}
        local tw,th = texInfo.xsize, texInfo.ysize
      gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawTiledTexture, self.width * 0.5 - 2, 0, 4, self.height, skLeft,skTop,skRight,skBottom, tw,th, 0)
    else
      local skLeft,skTop,skRight,skBottom = unpack4(self.tiles)
      TextureHandler.LoadTexture(0,self.TileImage,self)
        local texInfo = gl.TextureInfo(self.TileImage) or {xsize=1, ysize=1}
        local tw,th = texInfo.xsize, texInfo.ysize
      gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawTiledTexture, 0, self.height * 0.5 - 2, self.width, 4, skLeft,skTop,skRight,skBottom, tw,th, 0)
    end

  gl.Texture(0,false)

  if (self.debug) then
    gl.Color(0,1,0,0.5)
    gl.PolygonMode(GL.FRONT_AND_BACK,GL.LINE)
    gl.LineWidth(2)
    gl.Rect(0,0,self.width,self.height)
    gl.LineWidth(1)
    gl.PolygonMode(GL.FRONT_AND_BACK,GL.FILL)
  end
end
--//=============================================================================
--//

function DrawTabBarItem(obj)
  local w = obj.width
  local h = obj.height

  local skLeft,skTop,skRight,skBottom = unpack4(obj.tiles)

  if (obj.state.pressed) then
    gl.Color(mulColor(obj.backgroundColor,0.4))
  elseif (obj.state.hovered) then
    gl.Color(obj.focusColor)
  elseif (obj.state.selected) then
    gl.Color(obj.focusColor)
  else
    gl.Color(obj.backgroundColor)
  end
  TextureHandler.LoadTexture(0,obj.TileImageBK,obj)
    local texInfo = gl.TextureInfo(obj.TileImageBK) or {xsize=1, ysize=1}
    local tw,th = texInfo.xsize, texInfo.ysize

    gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawTiledTexture, 0,0,w,h, skLeft,skTop,skRight,skBottom, tw,th, 0)
  --gl.Texture(0,false)

  if (obj.state.pressed) then
    gl.Color(0.6,0.6,0.6,1) --FIXME
  elseif (obj.state.selected) then
    gl.Color(obj.focusColor)
  else
    gl.Color(obj.borderColor)
  end

  TextureHandler.LoadTexture(0,obj.TileImageFG,obj)
    local texInfo = gl.TextureInfo(obj.TileImageFG) or {xsize=1, ysize=1}
    local tw,th = texInfo.xsize, texInfo.ysize

    gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawTiledTexture, 0,0,w,h, skLeft,skTop,skRight,skBottom, tw,th, 0)
  gl.Texture(0,false)

  if (obj.caption) then
    local cx,cy,cw,ch = unpack4(obj.clientArea)
    obj.font:DrawInBox(obj.caption, cx, cy, cw, ch, "center", "center")
  end
end

--//=============================================================================
--//

function DrawDragGrip(obj)
  gl.BeginEnd(GL.TRIANGLES, _DrawDragGrip, obj)
end


function DrawResizeGrip(obj)
  gl.BeginEnd(GL.LINES, _DrawResizeGrip, obj)
end

--//=============================================================================
--// HitTest helpers

function _ProcessRelative(code, total)
  --// FIXME: duplicated in control.lua!
  if (type(code) == "string") then
    local percent = tonumber(code:sub(1,-2)) or 0
    if (percent<0) then
      percent = 0
    elseif (percent>100) then
      percent = 100
    end
    return math.floor(total * percent)
  elseif (code<0) then
    return math.floor(total + code)
  else
    return math.floor(code)
  end
end


function GetRelativeObjBox(obj,boxrelative)
  return {
    _ProcessRelative(boxrelative[1], obj.width),
    _ProcessRelative(boxrelative[2], obj.height),
    _ProcessRelative(boxrelative[3], obj.width),
    _ProcessRelative(boxrelative[4], obj.height)
  }
end


--//=============================================================================
--//

function NCHitTestWithPadding(obj,mx,my)
  local hp = obj.hitpadding
  local x = hp[1]
  local y = hp[2]
  local w = obj.width - hp[1] - hp[3]
  local h = obj.height - hp[2] - hp[4]

  --// early out
  if (not InRect({x,y,w,h},mx,my)) then
    return false
  end

  local resizable   = obj.resizable
  local draggable   = obj.draggable
  local dragUseGrip = obj.dragUseGrip
  if IsTweakMode() then
    resizable   = resizable  or obj.tweakResizable
    draggable   = draggable  or obj.tweakDraggable
    dragUseGrip = draggable and obj.tweakDragUseGrip
  end

  if (resizable) then
    local resizeBox = GetRelativeObjBox(obj,obj.boxes.resize)
    if (InRect(resizeBox,mx,my)) then
      return obj
    end
  end

  if (dragUseGrip) then
    local dragBox = GetRelativeObjBox(obj,obj.boxes.drag)
    if (InRect(dragBox,mx,my)) then
      return obj
    end
  elseif (draggable) then
    return obj
  end
end

function WindowNCMouseDown(obj,x,y)
  local resizable   = obj.resizable
  local draggable   = obj.draggable
  local dragUseGrip = obj.dragUseGrip
  if IsTweakMode() then
    resizable   = resizable  or obj.tweakResizable
    draggable   = draggable  or obj.tweakDraggable
    dragUseGrip = draggable and obj.tweakDragUseGrip
  end

  if (resizable) then
    local resizeBox = GetRelativeObjBox(obj,obj.boxes.resize)
    if (InRect(resizeBox,x,y)) then
      obj:StartResizing(x,y)
      return obj
    end
  end

  if (dragUseGrip) then
    local dragBox = GetRelativeObjBox(obj,obj.boxes.drag)
    if (InRect(dragBox,x,y)) then
      obj:StartDragging()
      return obj
    end
  end
end

function WindowNCMouseDownPostChildren(obj,x,y)
  local draggable   = obj.draggable
  local dragUseGrip = obj.dragUseGrip
  if IsTweakMode() then
    draggable   = draggable  or obj.tweakDraggable
    dragUseGrip = draggable and obj.tweakDragUseGrip
  end

  if (draggable and not dragUseGrip) then
    obj:StartDragging()
    return obj
  end
end

--//=============================================================================
