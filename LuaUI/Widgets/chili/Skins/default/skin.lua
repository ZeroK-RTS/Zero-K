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

local glColor		= gl.Color
local glRect		= gl.Rect
local glTranslate	= gl.Translate
local glTexture		= gl.Texture
local glTextureInfo	= gl.TextureInfo
local glVertex		= gl.Vertex
local glBeginEnd	= gl.BeginEnd
local glPushMatrix	= gl.PushMatrix
local glPopMatrix	= gl.PopMatrix

local GL_TRIANGLE_STRIP	= GL.TRIANGLE_STRIP
local GL_TRIANGLES	= GL.TRIANGLES
local GL_LINES		= GL.LINES

--//=============================================================================
--// Render Helpers

local function _DrawBorder(x,y,w,h,bt,color1,color2)
  glColor(color1)
  glVertex(x,     y+h)
  glVertex(x+bt,  y+h-bt)
  glVertex(x,     y)
  glVertex(x+bt,  y)
  glVertex(x+bt,  y)
  glVertex(x+bt,  y+bt)
  glVertex(x+w,   y)
  glVertex(x+w-bt,y+bt)

  glColor(color2)
  glVertex(x+w-bt,y+bt)
  glVertex(x+w,   y)
  glVertex(x+w-bt,y+h)
  glVertex(x+w,   y+h)
  glVertex(x+w-bt,y+h-bt)
  glVertex(x+w-bt,y+h)
  glVertex(x+bt,  y+h-bt)
  glVertex(x+bt,  y+h)
  glVertex(x,     y+h)
end


local function _DrawCheck(rect)
  local x,y,w,h = rect[1],rect[2],rect[3],rect[4]
  glVertex(x+w*0.25, y+h*0.5)
  glVertex(x+w*0.125,y+h*0.625)
  glVertex(x+w*0.375,y+h*0.625)
  glVertex(x+w*0.375,y+h*0.875)
  glVertex(x+w*0.75, y+h*0.25)
  glVertex(x+w*0.875,y+h*0.375)
end



local function _DrawDragGrip(obj)
  local x = obj.x + obj.borderThickness + 1
  local y = obj.y + obj.borderThickness + 1
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
  local resizable   = obj.resizable
  if IsTweakMode() then
    resizable   = resizable   or obj.tweakResizable
  end

  if (resizable) then
    local x = obj.x + obj.width - obj.padding[3] --obj.borderThickness - 1
    local y = obj.y + obj.height - obj.padding[4] --obj.borderThickness - 1
    local w = obj.resizeGripSize[1]
    local h = obj.resizeGripSize[2]

    x = x-1
    y = y-1
    glColor(1,1,1,0.2)
      glVertex(x - w, y)
      glVertex(x, y - h)

      glVertex(x - math.floor(w*0.66), y)
      glVertex(x, y - math.floor(h*0.66))

      glVertex(x - math.floor(w*0.33), y)
      glVertex(x, y - math.floor(h*0.33))

    x = x+1
    y = y+1
    glColor(0.1, 0.1, 0.1, 0.9)
      glVertex(x - w, y)
      glVertex(x, y - h)

      glVertex(x - math.floor(w*0.66), y)
      glVertex(x, y - math.floor(h*0.66))

      glVertex(x - math.floor(w*0.33), y)
      glVertex(x, y - math.floor(h*0.33))
  end
end


--//=============================================================================
--//

function DrawBorder(obj,state)
  local x = obj.x
  local y = obj.y
  local w = obj.width
  local h = obj.height
  local bt = obj.borderThickness

  glColor((state=='pressed' and obj.borderColor2) or obj.borderColor1)
  glVertex(x,     y+h)
  glVertex(x+bt,  y+h-bt)
  glVertex(x,     y)
  glVertex(x+bt,  y)
  glVertex(x+bt,  y)
  glVertex(x+bt,  y+bt)
  glVertex(x+w,   y)
  glVertex(x+w-bt,y+bt)

  glColor((state=='pressed' and obj.borderColor1) or obj.borderColor2)
  glVertex(x+w-bt,y+bt)
  glVertex(x+w,   y)
  glVertex(x+w-bt,y+h)
  glVertex(x+w,   y+h)
  glVertex(x+w-bt,y+h-bt)
  glVertex(x+w-bt,y+h)
  glVertex(x+bt,  y+h-bt)
  glVertex(x+bt,  y+h)
  glVertex(x,     y+h)
end


function DrawBackground(obj)
  glBeginEnd(GL_TRIANGLE_STRIP, _DrawBackground, obj)
end


function _DrawScrollbar(obj, type, x,y,w,h, pos, visiblePercent, state)
  glColor(obj.backgroundColor)
  glRect(x,y,x+w,y+h)

  if (type=='horizontal') then
    local gripx,gripw = x+w*pos, w*visiblePercent
    glBeginEnd(GL_TRIANGLE_STRIP, _DrawBorder, gripx,y,gripw,h, 1, obj.borderColor1, obj.borderColor2)
  else
    local gripy,griph = y+h*pos, h*visiblePercent
    glBeginEnd(GL_TRIANGLE_STRIP, _DrawBorder, x,gripy,w,griph, 1, obj.borderColor1, obj.borderColor2)
  end
end


function _DrawBackground(obj)
  local x = obj.x
  local y = obj.y
  local w = obj.width
  local h = obj.height
	
  glColor(obj.backgroundColor)
  glVertex(x,   y)
  glVertex(x,   y+h)
  glVertex(x+w, y)
  glVertex(x+w, y+h)
end


--//=============================================================================
--// Control Renderer

function DrawWindow(obj)
  glBeginEnd(GL_TRIANGLE_STRIP, _DrawBackground, obj, obj.state)
  glBeginEnd(GL_TRIANGLE_STRIP, DrawBorder, obj, obj.state)
end


function DrawButton(obj)
  glBeginEnd(GL_TRIANGLE_STRIP, _DrawBackground, obj, obj.state)
  glBeginEnd(GL_TRIANGLE_STRIP, DrawBorder, obj, obj.state)

  if (obj.caption) then
    local x = obj.x
    local y = obj.y
    local w = obj.width
    local h = obj.height

    obj.font:Print(obj.caption, x+w*0.5, y+h*0.5, "center", "center")
  end
end


function DrawPanel(obj)
  glBeginEnd(GL_TRIANGLE_STRIP, _DrawBackground, obj, obj.state)
  glBeginEnd(GL_TRIANGLE_STRIP, DrawBorder, obj, obj.state)
end


function DrawItemBkGnd(obj,x,y,w,h,state)
  if (state=="selected") then
    glColor(0.15,0.15,0.9,1)   
  else
    glColor({0.8, 0.8, 1, 0.45})
  end
  glRect(x,y,x+w,y+h)

  glBeginEnd(GL_TRIANGLE_STRIP, _DrawBorder, x,y,w,h, 1, obj.borderColor1, obj.borderColor2)
end


function DrawScrollPanel(obj)
  local clientX,clientY,clientWidth,clientHeight = unpack4(obj.clientArea)
  local contX,contY,contWidth,contHeight = unpack4(obj.contentArea)

  glPushMatrix()
  glTranslate(math.floor(obj.x + clientX),math.floor(obj.y + clientY),0)

  if obj._vscrollbar then
    _DrawScrollbar(obj, 'vertical', clientWidth,  0, obj.scrollbarSize, clientHeight,
                        obj.scrollPosY/contHeight, clientHeight/contHeight)
  end
  if obj._hscrollbar then
    _DrawScrollbar(obj, 'horizontal', 0, clientHeight, clientWidth, obj.scrollbarSize, 
                        obj.scrollPosX/contWidth, clientWidth/contWidth)
  end

  glPopMatrix()
end


function DrawTrackbar(obj)
  local percent = (obj.value-obj.min)/(obj.max-obj.min)
  local x = obj.x
  local y = obj.y
  local w = obj.width
  local h = obj.height

  glColor(0,0,0,1)
  glRect(x,y+h*0.5,x+w,y+h*0.5+1)

  local vc = y+h*0.5 --//verticale center
  local pos = x+percent*w

  glRect(pos-2,vc-h*0.5,pos+2,vc+h*0.5)
end


function DrawCheckbox(obj)
  local vc = obj.height*0.5 --//verticale center
  local tx = 0
  local ty = vc

  glPushMatrix()
  glTranslate(obj.x,obj.y,0)

  obj.font:Print(obj.caption, tx, ty, "left", "center")

  local box  = obj.boxsize
  local rect = {obj.width-box,obj.height*0.5-box*0.5,box,box}

  glColor(obj.backgroundColor)
  glRect(rect[1]+1,rect[2]+1,rect[1]+1+rect[3]-2,rect[2]+1+rect[4]-2)

  glBeginEnd(GL_TRIANGLE_STRIP, _DrawBorder, rect[1],rect[2],rect[3],rect[4], 1, obj.borderColor1, obj.borderColor2)

  if (obj.checked) then
    glBeginEnd(GL_TRIANGLE_STRIP,_DrawCheck,rect)
  end

  glPopMatrix()
end


function DrawColorbars(obj)
  glPushMatrix()
  glTranslate(obj.x,obj.y,0)

  local barswidth  = obj.width - (obj.height + 4)

  local color = obj.color
  local step = obj.height/7

  --bars
  local rX1,rY1,rX2,rY2 = 0,0*step,color[1]*barswidth,1*step
  local gX1,gY1,gX2,gY2 = 0,2*step,color[2]*barswidth,3*step
  local bX1,bY1,bX2,bY2 = 0,4*step,color[3]*barswidth,5*step
  local aX1,aY1,aX2,aY2 = 0,6*step,(color[4] or 1)*barswidth,7*step

  glColor(1,0,0,1)
  glRect(rX1,rY1,rX2,rY2)

  glColor(0,1,0,1)
  glRect(gX1,gY1,gX2,gY2)

  glColor(0,0,1,1)
  glRect(bX1,bY1,bX2,bY2)

  glColor(1,1,1,1)
  glRect(aX1,aY1,aX2,aY2)

  glColor(color)
  glRect(barswidth + 2,obj.height,obj.width - 2,0)

  glBeginEnd(GL_TRIANGLE_STRIP, _DrawBorder, barswidth + 2,0,obj.width - barswidth - 4,obj.height, 1, obj.borderColor1,obj.borderColor2)

  glPopMatrix()
end


function DrawDragGrip(obj)
  glBeginEnd(GL_TRIANGLES, _DrawDragGrip, obj)
end


function DrawResizeGrip(obj)
  glBeginEnd(GL_LINES, _DrawResizeGrip, obj)
end


local darkBlue = {0.0,0.0,0.6,0.9}
function DrawTreeviewNode(self)
  if CompareLinks(self.treeview.selected,self) then
    local x = self.x + self.clientArea[1]
    local y = self.y
    local w = self.children[1].width
    local h = self.clientArea[2] + self.children[1].height

    glColor(0.1,0.1,1,0.55)
    glRect(x,y,x+w,y+h)
    glBeginEnd(GL_TRIANGLE_STRIP, _DrawBorder, x,y,w,h, 1, darkBlue, darkBlue)
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

skin.general = {
  --font        = "FreeSansBold.ttf",
  fontOutline = false,
  fontsize    = 13,
  textColor   = {0,0,0,1},

  --padding         = {5, 5, 5, 5}, --// padding: left, top, right, bottom
  borderThickness = 1.5,
  borderColor1    = {1,1,1,0.6},
  borderColor2    = {0,0,0,0.8},
  backgroundColor = {0.8, 0.8, 1, 0.4},
}

skin.colorbars = {
  DrawControl = DrawColorbars,
}

skin.icons = {
  imageplaceholder = ":cl:placeholder.png",
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
}


skin.control = skin.general


--//=============================================================================
--//

return skin
