--//=============================================================================

local glClipPlane	= gl.ClipPlane
local glColor		= gl.Color
local glTexture		= gl.Texture
local glTexRect		= gl.TexRect
local glTextureInfo	= gl.TextureInfo
local glMultiTexCoord	= gl.MultiTexCoord
local glVertex		= gl.Vertex
local glBeginEnd	= gl.BeginEnd

local GL_TRIANGLE_STRIP	= GL.TRIANGLE_STRIP
local GL_TRIANGLES	= GL.TRIANGLES
local GL_LINES		= GL.LINES

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

  glTexRect(x,y,right,bottom,false,true)
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
    glMultiTexCoord(texIndex,0,0)
    glVertex(x,      y)
    glMultiTexCoord(texIndex,0,txTop)
    glVertex(x,      y+skTop)
    glMultiTexCoord(texIndex,txLeft,0)
    glVertex(x+skLeft, y)
    glMultiTexCoord(texIndex,txLeft,txTop)
    glVertex(x+skLeft, y+skTop)

    --//topcenter
    glMultiTexCoord(texIndex,1-txRight,0)
    glVertex(x+w-skRight, y)
    glMultiTexCoord(texIndex,1-txRight,txTop)
    glVertex(x+w-skRight, y+skTop)

    --//topright
    glMultiTexCoord(texIndex,1,0)
    glVertex(x+w,       y)
    glMultiTexCoord(texIndex,1,txTop)
    glVertex(x+w,       y+skTop)

    --//right center
    glMultiTexCoord(texIndex,1,1-txBottom)
    glVertex(x+w,       y+h-skBottom)    --//degenerate
    glMultiTexCoord(texIndex,1-txRight,txTop)
    glVertex(x+w-skRight, y+skTop)
    glMultiTexCoord(texIndex,1-txRight,1-txBottom)
    glVertex(x+w-skRight, y+h-skBottom)

    --//background
    glMultiTexCoord(texIndex,txLeft,txTop)
    glVertex(x+skLeft,    y+skTop)
    glMultiTexCoord(texIndex,txLeft,1-txBottom)
    glVertex(x+skLeft,    y+h-skBottom)

    --//left center
    glMultiTexCoord(texIndex,0,txTop)
    glVertex(x,    y+skTop)
    glMultiTexCoord(texIndex,0,1-txBottom)
    glVertex(x,    y+h-skBottom)

    --//bottom right
    glMultiTexCoord(texIndex,0,1)
    glVertex(x,      y+h)    --//degenerate
    glMultiTexCoord(texIndex,txLeft,1-txBottom)
    glVertex(x+skLeft, y+h-skBottom)
    glMultiTexCoord(texIndex,txLeft,1)
    glVertex(x+skLeft, y+h)

    --//bottom center
    glMultiTexCoord(texIndex,1-txRight,1-txBottom)
    glVertex(x+w-skRight, y+h-skBottom)
    glMultiTexCoord(texIndex,1-txRight,1)
    glVertex(x+w-skRight, y+h)

    --//bottom right
    glMultiTexCoord(texIndex,1,1-txBottom)
    glVertex(x+w, y+h-skBottom)
    glMultiTexCoord(texIndex,1,1)
    glVertex(x+w, y+h)
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
  glMultiTexCoord(texIndex,0,0)
  glVertex(x,      y)
  glMultiTexCoord(texIndex,0,txTop)
  glVertex(x,      y+skTop)
  glMultiTexCoord(texIndex,txLeft,0)
  glVertex(x+skLeft, y)
  glMultiTexCoord(texIndex,txLeft,txTop)
  glVertex(x+skLeft, y+skTop)

  --//topcenter
  glMultiTexCoord(texIndex,1-txRight,0)
  glVertex(x+w-skRight, y)
  glMultiTexCoord(texIndex,1-txRight,txTop)
  glVertex(x+w-skRight, y+skTop)

  --//topright
  glMultiTexCoord(texIndex,1,0)
  glVertex(x+w,       y)
  glMultiTexCoord(texIndex,1,txTop)
  glVertex(x+w,       y+skTop)

  --//right center
  glVertex(x+w,         y+skTop)    --//degenerate
  glMultiTexCoord(texIndex,1-txRight,txTop)
  glVertex(x+w-skRight, y+skTop)
  glMultiTexCoord(texIndex,1,1-txBottom)
  glVertex(x+w,         y+h-skBottom)
  glMultiTexCoord(texIndex,1-txRight,1-txBottom)
  glVertex(x+w-skRight, y+h-skBottom)

  --//bottom right
  glMultiTexCoord(texIndex,1,1)
  glVertex(x+w,         y+h)
  glMultiTexCoord(texIndex,1-txRight,1)
  glVertex(x+w-skRight, y+h)

  --//bottom center
  glVertex(x+w-skRight, y+h)    --//degenerate
  glMultiTexCoord(texIndex,1-txRight,1-txBottom)
  glVertex(x+w-skRight, y+h-skBottom)
  glMultiTexCoord(texIndex,txLeft,1)
  glVertex(x+skLeft,    y+h)
  glMultiTexCoord(texIndex,txLeft,1-txBottom)
  glVertex(x+skLeft,    y+h-skBottom)

  --//bottom left
  glMultiTexCoord(texIndex,0,1)
  glVertex(x,        y+h)
  glMultiTexCoord(texIndex,0,1-txBottom)
  glVertex(x,        y+h-skBottom)

  --//left center
  glVertex(x,        y+h-skBottom)    --//degenerate
  glMultiTexCoord(texIndex,0,txTop)
  glVertex(x,        y+skTop)
  glMultiTexCoord(texIndex,txLeft,1-txBottom)
  glVertex(x+skLeft, y+h-skBottom)
  glMultiTexCoord(texIndex,txLeft,txTop)
  glVertex(x+skLeft, y+skTop)
end
local _DrawTiledBorder = _DrawTiledBorder


local function _DrawDragGrip(obj)
  local x = obj.x + 13
  local y = obj.y + 8
  local w = obj.dragGripSize[1]
  local h = obj.dragGripSize[2]

  glColor(0.8,0.8,0.8,0.9)
  glVertex(x, y + h*0.5)
  glVertex(x + w*0.5, y)
  glVertex(x + w*0.5, y + h*0.5)

  glColor(0.3,0.3,0.3,0.9)
  glVertex(x + w*0.5, y + h*0.5)
  glVertex(x + w*0.5, y)
  glVertex(x + w, y + h*0.5)

  glVertex(x + w*0.5, y + h)
  glVertex(x, y + h*0.5)
  glVertex(x + w*0.5, y + h*0.5)

  glColor(0.1,0.1,0.1,0.9)
  glVertex(x + w*0.5, y + h)
  glVertex(x + w*0.5, y + h*0.5)
  glVertex(x + w, y + h*0.5)
end


local function _DrawResizeGrip(obj)
  if (obj.resizable) then
    local x = obj.x
    local y = obj.y

    local resizeBox = GetRelativeObjBox(obj,obj.boxes.resize)

    x = x-1
    y = y-1
    glColor(1,1,1,0.2)
      glVertex(x + resizeBox[1], y + resizeBox[4])
      glVertex(x + resizeBox[3], y + resizeBox[2])

      glVertex(x + resizeBox[1] + math.ceil((resizeBox[3] - resizeBox[1])*0.33), y + resizeBox[4])
      glVertex(x + resizeBox[3], y + resizeBox[2] + math.ceil((resizeBox[4] - resizeBox[2])*0.33))

      glVertex(x + resizeBox[1] + math.ceil((resizeBox[3] - resizeBox[1])*0.66), y + resizeBox[4])
      glVertex(x + resizeBox[3], y + resizeBox[2] + math.ceil((resizeBox[4] - resizeBox[2])*0.66))

    x = x+1
    y = y+1
    glColor(0.1, 0.1, 0.1, 0.9)
      glVertex(x + resizeBox[1], y + resizeBox[4])
      glVertex(x + resizeBox[3], y + resizeBox[2])

      glVertex(x + resizeBox[1] + math.ceil((resizeBox[3] - resizeBox[1])*0.33), y + resizeBox[4])
      glVertex(x + resizeBox[3], y + resizeBox[2] + math.ceil((resizeBox[4] - resizeBox[2])*0.33))

      glVertex(x + resizeBox[1] + math.ceil((resizeBox[3] - resizeBox[1])*0.66), y + resizeBox[4])
      glVertex(x + resizeBox[3], y + resizeBox[2] + math.ceil((resizeBox[4] - resizeBox[2])*0.66))
  end
end

--//=============================================================================
--//

function DrawWindow(obj)
  local x = obj.x
  local y = obj.y
  local w = obj.width
  local h = obj.height

  local skLeft,skTop,skRight,skBottom = unpack4(obj.tiles)

  local c = obj.color
  if (c) then
    glColor(c)
  else
    glColor(1,1,1,1)
  end
  TextureHandler.LoadTexture(0,obj.TileImage,obj)
    local texInfo = glTextureInfo(obj.TileImage) or {xsize=1, ysize=1}
    local tw,th = texInfo.xsize, texInfo.ysize

    glBeginEnd(GL_TRIANGLE_STRIP, _DrawTiledTexture, x,y,w,h, skLeft,skTop,skRight,skBottom, tw,th)
  glTexture(0,false)

  if (obj.caption) then
    obj.font:Print(obj.caption, x+w*0.5, y+9, "center")
  end
end

--//=============================================================================
--//

function DrawButton(obj)
  local x = obj.x
  local y = obj.y
  local w = obj.width
  local h = obj.height

  local skLeft,skTop,skRight,skBottom = unpack4(obj.tiles)

  if (obj.state=="pressed") then
    glColor(mulColor(obj.backgroundColor,0.4))
  else
    glColor(obj.backgroundColor)
  end
  TextureHandler.LoadTexture(0,obj.TileImageBK,obj)
    local texInfo = glTextureInfo(obj.TileImageBK) or {xsize=1, ysize=1}
    local tw,th = texInfo.xsize, texInfo.ysize

    glBeginEnd(GL_TRIANGLE_STRIP, _DrawTiledTexture, x,y,w,h, skLeft,skTop,skRight,skBottom, tw,th, 0)
  --gl.Texture(0,false)

  if (obj.state=="pressed") then
    glColor(0.6,0.6,0.6,1)
  else
    glColor(1,1,1,1)
  end
  TextureHandler.LoadTexture(0,obj.TileImageFG,obj)
    local texInfo = glTextureInfo(obj.TileImageFG) or {xsize=1, ysize=1}
    local tw,th = texInfo.xsize, texInfo.ysize

    glBeginEnd(GL_TRIANGLE_STRIP, _DrawTiledTexture, x,y,w,h, skLeft,skTop,skRight,skBottom, tw,th, 0)
  glTexture(0,false)

  if (obj.caption) then
    obj.font:Print(obj.caption, x+w*0.5, y+h*0.5, "center", "center")
  end
end

--//=============================================================================
--//

function DrawPanel(obj)
  local x = obj.x
  local y = obj.y
  local w = obj.width
  local h = obj.height

  local skLeft,skTop,skRight,skBottom = unpack4(obj.tiles)

  glColor(obj.backgroundColor)
  TextureHandler.LoadTexture(0,obj.TileImageBK,obj)
    local texInfo = glTextureInfo(obj.TileImageBK) or {xsize=1, ysize=1}
    local tw,th = texInfo.xsize, texInfo.ysize

    glBeginEnd(GL_TRIANGLE_STRIP, _DrawTiledTexture, x,y,w,h, skLeft,skTop,skRight,skBottom, tw,th, 0)
  --gl.Texture(0,false)

  glColor(1,1,1,1)
  TextureHandler.LoadTexture(0,obj.TileImageFG,obj)
    local texInfo = glTextureInfo(obj.TileImageFG) or {xsize=1, ysize=1}
    local tw,th = texInfo.xsize, texInfo.ysize

    glBeginEnd(GL_TRIANGLE_STRIP, _DrawTiledTexture, x,y,w,h, skLeft,skTop,skRight,skBottom, tw,th, 0)
  glTexture(0,false)
end

--//=============================================================================
--//

function DrawItemBkGnd(obj,x,y,w,h,state)
  local skLeft,skTop,skRight,skBottom = unpack4(obj.tiles)

  local texInfo = glTextureInfo(obj.imageFG) or {xsize=1, ysize=1}
  local tw,th = texInfo.xsize, texInfo.ysize

  if (state=="selected") then
    glColor(obj.colorBK_selected)
  else
    glColor(obj.colorBK)
  end
  TextureHandler.LoadTexture(0,obj.imageBK,obj)
    glBeginEnd(GL_TRIANGLE_STRIP, _DrawTiledTexture, x,y,w,h, skLeft,skTop,skRight,skBottom, tw,th, 0)
  --gl.Texture(0,false)

  if (state=="selected") then
    glColor(obj.colorFG_selected)
  else
    gl.Color(obj.colorFG)
  end
  TextureHandler.LoadTexture(0,obj.imageFG,obj)
    glBeginEnd(GL_TRIANGLE_STRIP, _DrawTiledTexture, x,y,w,h, skLeft,skTop,skRight,skBottom, tw,th, 0)
  glTexture(0,false)
end

--//=============================================================================
--//

function DrawScrollPanelBorder(self)
  local clientX,clientY,clientWidth,clientHeight = unpack4(self.clientArea)
  local contX,contY,contWidth,contHeight = unpack4(self.contentArea)

  
  glColor(self.backgroundColor)
  --glColor(1,1,1,1)

  do
      TextureHandler.LoadTexture(0,self.BorderTileImage,self)
      local texInfo = glTextureInfo(self.BorderTileImage) or {xsize=1, ysize=1}
      local tw,th = texInfo.xsize, texInfo.ysize

      local skLeft,skTop,skRight,skBottom = unpack4(self.bordertiles)

      local width = self.width
      local height = self.height
      if (self._vscrollbar) then
        width = clientWidth + self.padding[1] - 1
      end
      if (self._hscrollbar) then
        height = clientHeight + self.padding[2] - 1
      end

      glBeginEnd(GL_TRIANGLE_STRIP, _DrawTiledBorder, self.x,self.y,width,height, skLeft,skTop,skRight,skBottom, tw,th, 0)
      glTexture(0,false)
  end
end

--//=============================================================================
--//

function DrawScrollPanel(obj)
  local clientX,clientY,clientWidth,clientHeight = unpack4(obj.clientArea)
  local contX,contY,contWidth,contHeight = unpack4(obj.contentArea)

  glColor(obj.backgroundColor)
  --glColor(1,1,1,1)

  if (obj.BackgroundTileImage) then
      TextureHandler.LoadTexture(0,obj.BackgroundTileImage,obj)
      local texInfo = glTextureInfo(obj.BackgroundTileImage) or {xsize=1, ysize=1}
      local tw,th = texInfo.xsize, texInfo.ysize

      local skLeft,skTop,skRight,skBottom = unpack4(obj.bkgndtiles)

      local width = obj.width
      local height = obj.height
      if (obj._vscrollbar) then
        width = clientWidth + obj.padding[1] - 1
      end
      if (obj._hscrollbar) then
        height = clientHeight + obj.padding[2] - 1
      end

      glBeginEnd(GL_TRIANGLE_STRIP, _DrawTiledTexture, obj.x,obj.y,width,height, skLeft,skTop,skRight,skBottom, tw,th, 0)
      glTexture(0,false)
  end
  
  glColor(1,1,1,1)

  if obj._vscrollbar then
    local x = obj.x + clientX + clientWidth
    local y = obj.y --+ clientY
    local w = obj.scrollbarSize
    local h = obj.height

    local skLeft,skTop,skRight,skBottom = unpack4(obj.tiles)

    TextureHandler.LoadTexture(0,obj.TileImage,obj)
      local texInfo = glTextureInfo(obj.TileImage) or {xsize=1, ysize=1}
      local tw,th = texInfo.xsize, texInfo.ysize

      glBeginEnd(GL_TRIANGLE_STRIP, _DrawTiledTexture, x,y,w,h, skLeft,skTop,skRight,skBottom, tw,th, 0)
    --glTexture(0,false)

    if obj._vscrolling then
      glColor(obj.KnobColorSelected)
    end

    TextureHandler.LoadTexture(0,obj.KnobTileImage,obj)
      texInfo = glTextureInfo(obj.KnobTileImage) or {xsize=1, ysize=1}
      tw,th = texInfo.xsize, texInfo.ysize

      skLeft,skTop,skRight,skBottom = unpack4(obj.KnobTiles)

      local pos = obj.scrollPosY/contHeight
      local visible = clientHeight/contHeight
      local gripy = y + clientHeight * pos
      local griph = clientHeight * visible
      glBeginEnd(GL_TRIANGLE_STRIP, _DrawTiledTexture, x,gripy,obj.scrollbarSize,griph, skLeft,skTop,skRight,skBottom, tw,th, 0)
    --glTexture(0,false)

    glColor(1,1,1,1)
  end

  if obj._hscrollbar then
    local x = obj.x
    local y = obj.y + clientY + clientHeight
    local w = obj.width
    local h = obj.scrollbarSize

    local skLeft,skTop,skRight,skBottom = unpack4(obj.htiles)

    TextureHandler.LoadTexture(0,obj.HTileImage,obj)
      local texInfo = glTextureInfo(obj.HTileImage) or {xsize=1, ysize=1}
      local tw,th = texInfo.xsize, texInfo.ysize

      glBeginEnd(GL_TRIANGLE_STRIP, _DrawTiledTexture, x,y,w,h, skLeft,skTop,skRight,skBottom, tw,th, 0)
    --glTexture(0,false)

    if obj._hscrolling then
      glColor(obj.KnobColorSelected)
    end

    TextureHandler.LoadTexture(0,obj.HKnobTileImage,obj)
      texInfo = glTextureInfo(obj.HKnobTileImage) or {xsize=1, ysize=1}
      tw,th = texInfo.xsize, texInfo.ysize

      skLeft,skTop,skRight,skBottom = unpack4(obj.HKnobTiles)

      local pos = obj.scrollPosX/contWidth
      local visible = clientWidth/contWidth
      local gripx = x + clientWidth * pos
      local gripw = clientWidth * visible
      glBeginEnd(GL_TRIANGLE_STRIP, _DrawTiledTexture, gripx,y,gripw,obj.scrollbarSize, skLeft,skTop,skRight,skBottom, tw,th, 0)
    --glTexture(0,false)
  end

  glTexture(0,false)
end

--//=============================================================================
--//

function DrawCheckbox(obj)
  local boxSize = obj.boxsize
  local x = obj.x + obj.width      - boxSize
  local y = obj.y + obj.height*0.5 - boxSize*0.5
  local w = boxSize
  local h = boxSize

  local skLeft,skTop,skRight,skBottom = unpack4(obj.tiles)

  glColor(1,1,1,1)
  TextureHandler.LoadTexture(0,obj.TileImageBK,obj)

  -- fixes issue #54
  --local texInfo = glTextureInfo(obj.TileImageFG) or {xsize=1, ysize=1}
  --local tw,th = texInfo.xsize, texInfo.ysize  
  local texInfo = gl.TextureInfo(obj.TileImageBK) or {xsize=1, ysize=1}
  local tw,th = texInfo.xsize, texInfo.ysize
  
    glBeginEnd(GL_TRIANGLE_STRIP, _DrawTiledTexture, x,y,w,h, skLeft,skTop,skRight,skBottom, tw,th, 0)
  --glTexture(0,false)

  if (obj.checked) then
    TextureHandler.LoadTexture(0,obj.TileImageFG,obj)
      glBeginEnd(GL_TRIANGLE_STRIP, _DrawTiledTexture, x,y,w,h, skLeft,skTop,skRight,skBottom, tw,th, 0)
  end
  glTexture(0,false)

  if (obj.caption) then
    local vc = obj.height*0.5 --//verticale center
    local tx = 0
    local ty = vc

    obj.font:Print(obj.caption, obj.x + tx, obj.y + ty, nil, "center")
  end
end

--//=============================================================================
--//

function DrawProgressbar(obj)
  local x = obj.x
  local y = obj.y
  local w = obj.width
  local h = obj.height

  local percent = (obj.value-obj.min)/(obj.max-obj.min)

  local skLeft,skTop,skRight,skBottom = unpack4(obj.tiles)

  glColor(obj.backgroundColor)
  if not obj.noSkin then
    TextureHandler.LoadTexture(0,obj.TileImageBK,obj)
    local texInfo = glTextureInfo(obj.TileImageBK) or {xsize=1, ysize=1}
    local tw,th = texInfo.xsize, texInfo.ysize

    glBeginEnd(GL_TRIANGLE_STRIP, _DrawTiledTexture, x,y,w,h, skLeft,skTop,skRight,skBottom, tw,th, 0)
    --glTexture(0,false)
  end

  glColor(obj.color)
  TextureHandler.LoadTexture(0,obj.TileImageFG,obj)
    local texInfo = glTextureInfo(obj.TileImageFG) or {xsize=1, ysize=1}
    local tw,th = texInfo.xsize, texInfo.ysize

    -- workaround for catalyst 12.6 drivers: do the "clipping" by multiplying width by percentage in glBeginEnd instead of using glClipPlane
    --glClipPlane(1, -1,0,0, x+w*percent)
    glBeginEnd(GL_TRIANGLE_STRIP, _DrawTiledTexture, x,y,w*percent,h, skLeft,skTop,skRight,skBottom, tw,th, 0)
    --glClipPlane(1, false)
  glTexture(0,false)

  if (obj.caption) then
    (obj.font):Print(obj.caption, x+w*0.5, y+h*0.5, "center", "center")
  end
end

--//=============================================================================
--//

function DrawTrackbar(self)
  local percent = self:_GetPercent()
  local x = self.x
  local y = self.y
  local w = self.width
  local h = self.height

  local skLeft,skTop,skRight,skBottom = unpack4(self.tiles)
  local pdLeft,pdTop,pdRight,pdBottom = unpack4(self.hitpadding)

  glColor(1,1,1,1)
  if not self.noDrawBar then
    TextureHandler.LoadTexture(0,self.TileImage,self)
    local texInfo = glTextureInfo(self.TileImage) or {xsize=1, ysize=1}
    local tw,th = texInfo.xsize, texInfo.ysize
    glBeginEnd(GL_TRIANGLE_STRIP, _DrawTiledTexture, x,y,w,h, skLeft,skTop,skRight,skBottom, tw,th, 0)
  end
    
  if not self.noDrawStep then
    TextureHandler.LoadTexture(0,self.StepImage,self)
    local texInfo = glTextureInfo(self.StepImage) or {xsize=1, ysize=1}
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

      local my = y+h*0.5
      local mx = x+pdLeft+stepWidth
      while (mx<(x+pdLeft+barWidth)) do
        glTexRect(math.ceil(mx-tw*0.5),math.ceil(my-th*0.5),math.ceil(mx+tw*0.5),math.ceil(my+th*0.5),false,true)
        mx = mx+stepWidth
      end
    end
  end

  if not self.noDrawThumb then
    TextureHandler.LoadTexture(0,self.ThumbImage,self)
    local texInfo = glTextureInfo(self.ThumbImage) or {xsize=1, ysize=1}
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
    local mx = x+pdLeft+barWidth*percent
    local my = y+h*0.5
    glTexRect(math.ceil(mx-tw*0.5),math.ceil(my-th*0.5),math.ceil(mx+tw*0.5),math.ceil(my+th*0.5),false,true)
  end
  
  glTexture(0,false)
end

--//=============================================================================
--//

function DrawTreeviewNode(self)
  if CompareLinks(self.treeview.selected,self) then
    local x = self.x + self.clientArea[1]
    local y = self.y
    local w = self.children[1].width
    local h = self.clientArea[2] + self.children[1].height

    local skLeft,skTop,skRight,skBottom = unpack4(self.treeview.tiles)

    glColor(1,1,1,1)
    TextureHandler.LoadTexture(0,self.treeview.ImageNodeSelected,self)
      local texInfo = glTextureInfo(self.treeview.ImageNodeSelected) or {xsize=1, ysize=1}
      local tw,th = texInfo.xsize, texInfo.ysize

      glBeginEnd(GL_TRIANGLE_STRIP, _DrawTiledTexture, x,y,w,h, skLeft,skTop,skRight,skBottom, tw,th, 0)
    glTexture(0,false)
  end
end


local function _DrawLineV(x, y1, y2, width, next_func, ...)
  glVertex(x-width*0.5, y1)
  glVertex(x+width*0.5, y1)
  glVertex(x-width*0.5, y2)

  glVertex(x+width*0.5, y1)
  glVertex(x-width*0.5, y2)
  glVertex(x+width*0.5, y2)

  if (next_func) then
    next_func(...)
  end
end


local function _DrawLineH(x1, x2, y, width, next_func, ...)
  glVertex(x1, y-width*0.5)
  glVertex(x1, y+width*0.5)
  glVertex(x2, y-width*0.5)

  glVertex(x1, y+width*0.5)
  glVertex(x2, y-width*0.5)
  glVertex(x2, y+width*0.5)

  if (next_func) then
    next_func(...)
  end
end


function DrawTreeviewNodeTree(self)
  local x1 = self.x + math.ceil(self.padding[1]*0.5)
  local x2 = self.x + self.padding[1]
  local y1 = self.y
  local y2 = self.y + self.height
  local y3 = self.y + self.padding[2] + math.ceil(self.children[1].height*0.5)

  if (self.parent)and(CompareLinks(self,self.parent.nodes[#self.parent.nodes])) then
    y2 = y3
  end

  glColor(self.treeview.treeColor)
  glBeginEnd(GL_TRIANGLES, _DrawLineV, x1-0.5, y1, y2, 1, _DrawLineH, x1, x2, y3-0.5, 1)

  if (not self.nodes[1]) then
    return
  end

  glColor(1,1,1,1)
  local image = self.ImageExpanded or self.treeview.ImageExpanded
  if (not self.expanded) then
    image = self.ImageCollapsed or self.treeview.ImageCollapsed
  end

  TextureHandler.LoadTexture(0, image, self)
  local texInfo = glTextureInfo(image) or {xsize=1, ysize=1}
  local tw,th = texInfo.xsize, texInfo.ysize

  _DrawTextureAspect(self.x,self.y,math.ceil(self.padding[1]),math.ceil(self.children[1].height) ,tw,th)
  glTexture(0,false)
end


--//=============================================================================
--// 

function DrawDragGrip(obj)
  glBeginEnd(GL_TRIANGLES, _DrawDragGrip, obj)
end


function DrawResizeGrip(obj)
  glBeginEnd(GL_LINES, _DrawResizeGrip, obj)
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
