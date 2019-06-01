--//=============================================================================
--// default

local skin = {
  info = {
    name    = "default",
    version = "0.1",
    author  = "jK",
  }
}

--//=============================================================================
--// Render Helpers

local function _DrawBorder(x,y,w,h,bt,color1,color2)
  gl.Color(color1)
  gl.Vertex(x,     y+h)
  gl.Vertex(x+bt,  y+h-bt)
  gl.Vertex(x,     y)
  gl.Vertex(x+bt,  y)
  gl.Vertex(x+bt,  y)
  gl.Vertex(x+bt,  y+bt)
  gl.Vertex(x+w,   y)
  gl.Vertex(x+w-bt,y+bt)

  gl.Color(color2)
  gl.Vertex(x+w-bt,y+bt)
  gl.Vertex(x+w,   y)
  gl.Vertex(x+w-bt,y+h)
  gl.Vertex(x+w,   y+h)
  gl.Vertex(x+w-bt,y+h-bt)
  gl.Vertex(x+w-bt,y+h)
  gl.Vertex(x+bt,  y+h-bt)
  gl.Vertex(x+bt,  y+h)
  gl.Vertex(x,     y+h)
end


local function _DrawCheck(rect)
  local x,y,w,h = rect[1],rect[2],rect[3],rect[4]
  gl.Vertex(x+w*0.25, y+h*0.5)
  gl.Vertex(x+w*0.125,y+h*0.625)
  gl.Vertex(x+w*0.375,y+h*0.625)
  gl.Vertex(x+w*0.375,y+h*0.875)
  gl.Vertex(x+w*0.75, y+h*0.25)
  gl.Vertex(x+w*0.875,y+h*0.375)
end


local function _DrawHLine(x,y,w,bt,color1,color2)
  gl.Color(color1)
  gl.Vertex(x,     y)
  gl.Vertex(x,     y+bt)
  gl.Vertex(x+w,   y)
  gl.Vertex(x+w,   y+bt)

  gl.Color(color2)
  gl.Vertex(x+w,   y+bt)
  gl.Vertex(x+w,   y+2*bt)
  gl.Vertex(x,     y+bt)
  gl.Vertex(x,     y+2*bt)
end


local function _DrawVLine(x,y,h,bt,color1,color2)
  gl.Color(color1)
  gl.Vertex(x,     y)
  gl.Vertex(x+bt,  y)
  gl.Vertex(x,     y+h)
  gl.Vertex(x+bt,  y+h)

  gl.Color(color2)
  gl.Vertex(x+bt,  y+h)
  gl.Vertex(x+2*bt,y+h)
  gl.Vertex(x+bt,  y)
  gl.Vertex(x+2*bt,y)
end


local function _DrawDragGrip(obj)
  local x = obj.borderThickness + 1
  local y = obj.borderThickness + 1
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
  local resizable   = obj.resizable
  if IsTweakMode() then
    resizable   = resizable   or obj.tweakResizable
  end

  if (resizable) then
    local x = obj.width - obj.padding[3] --obj.borderThickness - 1
    local y = obj.height - obj.padding[4] --obj.borderThickness - 1
    local w = obj.resizeGripSize[1]
    local h = obj.resizeGripSize[2]

    x = x-1
    y = y-1
    gl.Color(1,1,1,0.2)
      gl.Vertex(x - w, y)
      gl.Vertex(x, y - h)

      gl.Vertex(x - math.floor(w*0.66), y)
      gl.Vertex(x, y - math.floor(h*0.66))

      gl.Vertex(x - math.floor(w*0.33), y)
      gl.Vertex(x, y - math.floor(h*0.33))

    x = x+1
    y = y+1
    gl.Color(0.1, 0.1, 0.1, 0.9)
      gl.Vertex(x - w, y)
      gl.Vertex(x, y - h)

      gl.Vertex(x - math.floor(w*0.66), y)
      gl.Vertex(x, y - math.floor(h*0.66))

      gl.Vertex(x - math.floor(w*0.33), y)
      gl.Vertex(x, y - math.floor(h*0.33))
  end
end


--//=============================================================================
--//

function DrawBorder(obj,state)
  local x = 0
  local y = 0
  local w = obj.width
  local h = obj.height
  local bt = obj.borderThickness

  gl.Color((state.pressed and obj.borderColor2) or obj.borderColor)
  gl.Vertex(x,     y+h)
  gl.Vertex(x+bt,  y+h-bt)
  gl.Vertex(x,     y)
  gl.Vertex(x+bt,  y)
  gl.Vertex(x+bt,  y)
  gl.Vertex(x+bt,  y+bt)
  gl.Vertex(x+w,   y)
  gl.Vertex(x+w-bt,y+bt)

  gl.Color((state.pressed and obj.borderColor) or obj.borderColor2)
  gl.Vertex(x+w-bt,y+bt)
  gl.Vertex(x+w,   y)
  gl.Vertex(x+w-bt,y+h)
  gl.Vertex(x+w,   y+h)
  gl.Vertex(x+w-bt,y+h-bt)
  gl.Vertex(x+w-bt,y+h)
  gl.Vertex(x+bt,  y+h-bt)
  gl.Vertex(x+bt,  y+h)
  gl.Vertex(x,     y+h)
end


function DrawBackground(obj)
  gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawBackground, obj)
end


function _DrawScrollbar(obj, type, x,y,w,h, pos, visiblePercent, state)
  gl.Color(obj.backgroundColor)
  gl.Rect(x,y,x+w,y+h)

  if (type=='horizontal') then
    local gripx,gripw = x+w*pos, w*visiblePercent
    gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawBorder, gripx,y,gripw,h, 1, obj.borderColor, obj.borderColor2)
  else
    local gripy,griph = y+h*pos, h*visiblePercent
    gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawBorder, x,gripy,w,griph, 1, obj.borderColor, obj.borderColor2)
  end
end


function _DrawBackground(obj)
  local x = 0
  local y = 0
  local w = obj.width
  local h = obj.height

  gl.Color(obj.backgroundColor)
  gl.Vertex(x,   y)
  gl.Vertex(x,   y+h)
  gl.Vertex(x+w, y)
  gl.Vertex(x+w, y+h)
end


function _DrawTabBackground(obj)
  local x = 0
  local y = 0
  local w = obj.width
  local h = obj.height
  local bt= 2

  gl.Color(obj.backgroundColor)
  gl.Vertex(x+bt,   y+bt)
  gl.Vertex(x+bt,   y+h)
  gl.Vertex(x+w-bt, y+bt)
  gl.Vertex(x+w-bt, y+h)
end


local function _DrawTabBorder(obj, state)
  local x = 0
  local y = 0
  local w = obj.width
  local h = obj.height
  local bt= 2

  gl.Color(obj.borderColor)
  gl.Vertex(x,      y+h)
  gl.Vertex(x+bt,   y+h)
  gl.Vertex(x,      y+bt)
  gl.Vertex(x+bt,   y+bt)
  gl.Vertex(x+bt,   y)
  gl.Vertex(x+w-bt, y+bt)
  gl.Vertex(x+w-bt, y)

  gl.Color(obj.borderColor2)
  gl.Vertex(x+w-bt, y)
  gl.Vertex(x+w-bt, y+bt)
  gl.Vertex(x+w,    y+bt)
  gl.Vertex(x+w-bt, y+h)
  gl.Vertex(x+w,    y+h)
end


--//=============================================================================
--// Control Renderer

function DrawWindow(obj)
  gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawBackground, obj, obj.state)
  gl.BeginEnd(GL.TRIANGLE_STRIP, DrawBorder, obj, obj.state)
end


function DrawButton(obj)
  gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawBackground, obj, obj.state)
  gl.BeginEnd(GL.TRIANGLE_STRIP, DrawBorder, obj, obj.state)

  if (obj.caption) then
    local w = obj.width
    local h = obj.height

    obj.font:Print(obj.caption, w*0.5, h*0.5, "center", "center")
  end
end

function _DrawTriangle(obj)
  local w = obj.width
  local x = 0
  local y = 0
  local w = obj.width
  local h = obj.height
  local bt = obj.borderThickness

  local tw = 10
  gl.Color(obj.focusColor)
  gl.Vertex(x + w - tw*1.5, y + (h - tw) * 0.5)
  gl.Vertex(x + w - tw*0.5, y + (h - tw) * 0.5)
  gl.Vertex(x + w - tw, y + tw + (h - tw) * 0.5)
end


function DrawComboBox(obj)
    DrawButton(obj)
    --draw triangle that indicates this is a combobox
    gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawTriangle, obj)
end

function DrawCursor(x, y, w, h)
	gl.Vertex(x, y)
	gl.Vertex(x, y + h)
	gl.Vertex(x + w, y)
	gl.Vertex(x + w, y + h)
end


function DrawEditBox(obj)
	gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawBackground, obj, obj.state)
	if obj.state.focused then
		gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawBorder, 0, 0, obj.width, obj.height, obj.borderThickness, obj.focusColor, obj.focusColor)
	else
		gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawBorder, 0, 0, obj.width, obj.height, obj.borderThickness, obj.borderColor2, obj.borderColor)
	end

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
			gl.BeginEnd(GL.TRIANGLE_STRIP, DrawCursor, cursorX + clientX - 1, clientY, 3, clientHeight)
		end
	end
end


function DrawPanel(obj)
  gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawBackground, obj, obj.state)
  gl.BeginEnd(GL.TRIANGLE_STRIP, DrawBorder, obj, obj.state)
end


function DrawItemBkGnd(obj,x,y,w,h,state)
  if (state=="selected") then
    gl.Color(0.15,0.15,0.9,1)
  else
    gl.Color({0.8, 0.8, 1, 0.45})
  end
  gl.Rect(x,y,x+w,y+h)

  gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawBorder, x,y,w,h, 1, obj.borderColor, obj.borderColor2)
end


function DrawScrollPanel(obj)
  local clientX,clientY,clientWidth,clientHeight = unpack4(obj.clientArea)
  local contX,contY,contWidth,contHeight = unpack4(obj.contentArea)

  gl.PushMatrix()
  gl.Translate(clientX, clientY,0)

  if obj._vscrollbar and (contHeight > 0) then
    local height = (not obj._hscrollbar and obj.height) or (obj.height - obj.scrollbarSize)
    _DrawScrollbar(obj, 'vertical', obj.width - obj.scrollbarSize,  0, obj.scrollbarSize, height,
                        obj.scrollPosY/contHeight, clientHeight/contHeight)
  end
  if obj._hscrollbar and (contWidth > 0) then
    local width = (not obj._vscrollbar and obj.width) or (obj.width - obj.scrollbarSize)
    _DrawScrollbar(obj, 'horizontal', 0, obj.height - obj.scrollbarSize, width, obj.scrollbarSize,
                        obj.scrollPosX/contWidth, clientWidth/contWidth)
  end

  gl.PopMatrix()
end


function DrawTrackbar(obj)
  local percent = (obj.value-obj.min)/(obj.max-obj.min)
  local w = obj.width
  local h = obj.height

  gl.Color(0,0,0,1)
  gl.Rect(0,h*0.5,w,h*0.5+1)

  local vc = h*0.5 --//verticale center
  local pos = percent*w

  gl.Rect(pos-2,vc-h*0.5,pos+2,vc+h*0.5)
end


function DrawCheckbox(obj)
  local vc = obj.height*0.5 --//verticale center
  local tx = 0
  local ty = vc

  gl.PushMatrix()
  gl.Translate(0,0,0)

  obj.font:Print(obj.caption, tx, ty, "left", "center")

  local box  = obj.boxsize
  local rect = {obj.width-box,obj.height*0.5-box*0.5,box,box}

  gl.Color(obj.backgroundColor)
  gl.Rect(rect[1]+1,rect[2]+1,rect[1]+1+rect[3]-2,rect[2]+1+rect[4]-2)

  gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawBorder, rect[1],rect[2],rect[3],rect[4], 1, obj.borderColor, obj.borderColor2)

  if (obj.state.checked) then
    gl.BeginEnd(GL.TRIANGLE_STRIP,_DrawCheck,rect)
  end

  gl.PopMatrix()
end


function DrawColorbars(obj)
  gl.PushMatrix()
  gl.Translate(0,0,0)

  local barswidth  = obj.width - (obj.height + 4)

  local color = obj.color
  local step = obj.height/7

  --bars
  local rX1,rY1,rX2,rY2 = 0,0*step,color[1]*barswidth,1*step
  local gX1,gY1,gX2,gY2 = 0,2*step,color[2]*barswidth,3*step
  local bX1,bY1,bX2,bY2 = 0,4*step,color[3]*barswidth,5*step
  local aX1,aY1,aX2,aY2 = 0,6*step,(color[4] or 1)*barswidth,7*step

  gl.Color(1,0,0,1)
  gl.Rect(rX1,rY1,rX2,rY2)

  gl.Color(0,1,0,1)
  gl.Rect(gX1,gY1,gX2,gY2)

  gl.Color(0,0,1,1)
  gl.Rect(bX1,bY1,bX2,bY2)

  gl.Color(1,1,1,1)
  gl.Rect(aX1,aY1,aX2,aY2)

  gl.Color(color)
  gl.Rect(barswidth + 2,obj.height,obj.width - 2,0)

  gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawBorder, barswidth + 2,0,obj.width - barswidth - 4,obj.height, 1, obj.borderColor, obj.borderColor2)

  gl.PopMatrix()
end

function DrawLine(self)
	if (self.style:find("^v")) then
		gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawVLine, self.width * 0.5, 0, self.height, 1, self.borderColor, self.borderColor2)
	else
		gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawHLine, 0, self.height * 0.5, self.width, 1, self.borderColor, self.borderColor2)
	end
end


function DrawDragGrip(obj)
  gl.BeginEnd(GL.TRIANGLES, _DrawDragGrip, obj)
end


function DrawResizeGrip(obj)
  gl.BeginEnd(GL.LINES, _DrawResizeGrip, obj)
end


local darkBlue = {0.0,0.0,0.6,0.9}
function DrawTreeviewNode(self)
  if CompareLinks(self.treeview.selected,self) then
    local x = self.clientArea[1]
    local y = 0
    local w = self.children[1].width
    local h = self.clientArea[2] + self.children[1].height

    gl.Color(0.1,0.1,1,0.55)
    gl.Rect(0,0,w,h)
    gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawBorder, 0,0,w,h, 1, darkBlue, darkBlue)
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

function DrawTabBarItem(self)
	gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawTabBackground, self, self.state)
	gl.BeginEnd(GL.TRIANGLE_STRIP, _DrawTabBorder, self, self.state)

	if self.caption then
		local w = self.width
		local h = self.height
		local bt= 2

		local oldColor = self.font.color
		if self.state.selected then
			self.font:SetColor(self.focusColor)
		end
		self.font:Print(self.caption, w*0.5, bt+h*0.5, "center", "center")
		if self.state.selected then
			self.font:SetColor(oldColor)
		end
	end
end

--//=============================================================================
--//

skin.general = {
  --font        = "FreeSansBold.ttf",
  textColor   = {0,0,0,1},

  font = {
    outlineColor = {0,0,0,0.5},
    outline      = false,
    size         = 13,
  },

  --padding         = {5, 5, 5, 5}, --// padding: left, top, right, bottom
  borderThickness = 1.5,
  borderColor     = {1,1,1,0.6},
  borderColor2    = {0,0,0,0.8},
  backgroundColor = {0.8, 0.8, 1, 0.4},
}

skin.colorbars = {
  DrawControl = DrawColorbars,
}

skin.icons = {
  imageplaceholder = ":cl:placeholder.png",
}

skin.image = {
}

skin.button = {
  DrawControl = DrawButton,
}

skin.checkbox = {
  DrawControl = DrawCheckbox,
}

skin.imagelistview = {
  imageFolder      = "folder.png",
  imageFolderUp    = "folder_up.png",

  DrawItemBackground = DrawItemBkGnd,
}
--[[
skin.imagelistviewitem = {
  padding = {12, 12, 12, 12},

  DrawSelectionItemBkGnd = DrawSelectionItemBkGnd,
}
--]]

skin.panel = {
  DrawControl = DrawPanel,
}

skin.scrollpanel = {
  DrawControl = DrawScrollPanel,
}

skin.trackbar = {
  DrawControl = DrawTrackbar,
}

skin.treeview = {
  ImageExpanded  = ":cl:treeview_node_expanded.png",
  ImageCollapsed = ":cl:treeview_node_collapsed.png",
  treeColor = {0,0,0,0.6},

  minItemHeight = 16,

  DrawNode = DrawTreeviewNode,
  DrawNodeTree = DrawTreeviewNodeTree,
}

skin.window = {
  DrawControl = DrawWindow,
  DrawDragGrip = DrawDragGrip,
  DrawResizeGrip = DrawResizeGrip,

  hitpadding = {4, 4, 4, 4},
  boxes = {
    resize = {-21, -21, -10, -10},
    drag = {0, 0, "100%", 10},
  },
  NCHitTest = NCHitTestWithPadding,
  NCMouseDown = WindowNCMouseDown,
  NCMouseDownPostChildren = WindowNCMouseDownPostChildren,
}

skin.editbox = {
  DrawControl = DrawEditBox,
  backgroundColor = {1, 1, 1, 0.9},
}

skin.combobox = {
  DrawControl = DrawComboBox,
}

skin.line = {
  DrawControl = DrawLine,
}

skin.tabbaritem = {
  borderColor     = {1.0, 1.0, 1.0, 0.8},
  borderColor2    = {0.0, 0.0, 0.0, 0.8},
  backgroundColor = {0.8, 0.8, 1.0, 0.7},
  textColor       = {0.1, 0.1, 0.1, 1.0},
  DrawControl = DrawTabBarItem,
}

skin.control = skin.general


--//=============================================================================
--//

return skin
