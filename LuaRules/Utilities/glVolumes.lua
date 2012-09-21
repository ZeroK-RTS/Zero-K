--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Exported Functions:
--  gl.Utilities.DrawGroundCircle(x,z,radius)
--  gl.Utilities.DrawMyBox(minX,minY,minZ, maxX,maxY,maxZ)
--  gl.Utilities.DrawMyCylinder(x,y,z, height,radius,divs)
--  gl.Utilities.DrawVolume(vol_dlist)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gl) then
	return
end

gl.Utilities = gl.Utilities or {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local min    = math.min
local max    = math.max
local sin    = math.sin
local cos    = math.cos
local TWO_PI = math.pi * 2

local glVertex = gl.Vertex

GL.KEEP      = 0x1E00
GL.INCR_WRAP = 0x8507
GL.DECR_WRAP = 0x8508
GL.INCR      = 0x1E02
GL.DECR      = 0x1E03
GL.INVERT    = 0x150A

local stencilBit1 = 0x01
local stencilBit2 = 0x10

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gl.Utilities.DrawMyBox(minX,minY,minZ, maxX,maxY,maxZ)
  gl.BeginEnd(GL.QUADS, function()
    --// top
    glVertex(minX, maxY, minZ)
    glVertex(maxX, maxY, minZ)
    glVertex(maxX, maxY, maxZ)
    glVertex(minX, maxY, maxZ)
    --// bottom
    glVertex(minX, minY, minZ)
    glVertex(minX, minY, maxZ)
    glVertex(maxX, minY, maxZ)
    glVertex(maxX, minY, minZ)
  end)
  gl.BeginEnd(GL.QUAD_STRIP, function()
    --// sides
    glVertex(minX, minY, minZ)
    glVertex(minX, maxY, minZ)
    glVertex(minX, minY, maxZ)
    glVertex(minX, maxY, maxZ)
    glVertex(maxX, minY, maxZ)
    glVertex(maxX, maxY, maxZ)
    glVertex(maxX, minY, minZ)
    glVertex(maxX, maxY, minZ)
    glVertex(minX, minY, minZ)
    glVertex(minX, maxY, minZ)
  end)
end


function gl.Utilities.DrawMyCylinder(x,y,z, height,radius,divs)
  divs = divs or 25
  local halfHeight = height / 2
  local divAngle = TWO_PI / divs
  
  gl.BeginEnd(GL.TRIANGLE_STRIP, function()
    --//Note: We can't use for-loops here cause of precision issues!

    --// top
    local alpha = -divAngle
    repeat
      alpha = alpha + divAngle
      alpha = min(alpha, TWO_PI)

      local sa = sin(alpha)
      local ca = cos(alpha)
      glVertex(x+radius*sa, y+halfHeight, z+radius*ca)
      glVertex(x, y+halfHeight, z)
    until (alpha >= TWO_PI)

    --// degenerate
    glVertex(x, y+halfHeight, z)
    glVertex(x, y-halfHeight, z)
    glVertex(x, y-halfHeight, z)

    --// bottom
    alpha = divAngle
    repeat
      alpha = alpha - divAngle
      alpha = max(alpha, -TWO_PI)

      local sa = sin(alpha)
      local ca = cos(alpha)
      glVertex(x+radius*sa, y-halfHeight, z+radius*ca)
      glVertex(x, y-halfHeight, z)
    until (alpha <= -TWO_PI)

    --// degenerate
    glVertex(x, y-halfHeight, z)
    glVertex(x, y-halfHeight, z+radius)
    glVertex(x, y-halfHeight, z+radius)

    --// sides
    alpha = -divAngle
    repeat
      alpha = alpha + divAngle
      alpha = min(alpha, TWO_PI)

      local sa = sin(alpha)
      local ca = cos(alpha)
      glVertex(x+radius*sa, y+halfHeight, z+radius*ca)
      glVertex(x+radius*sa, y-halfHeight, z+radius*ca)
    until (alpha >= TWO_PI)
  end)
end


local heightMargin = 2000
local minheight, maxheight = Spring.GetGroundExtremes()  --the returned values do not change even if we terraform the map
local averageGroundHeight = (minheight + maxheight) / 2
local shapeHeight = heightMargin + (maxheight - minheight) + heightMargin

local cylinder = gl.CreateList(gl.Utilities.DrawMyCylinder,0,0,0,1,1,35)
function gl.Utilities.DrawGroundCircle(x,z,radius)
  gl.PushMatrix()
  gl.Translate(x, averageGroundHeight, z)
  gl.Scale(radius, shapeHeight, radius)
  gl.Utilities.DrawVolume(cylinder)
  gl.PopMatrix()
end

local box = gl.CreateList(gl.Utilities.DrawMyBox,0,0.5,0,1,0.5,1)
function gl.Utilities.DrawGroundRectangle(x1,z1,x2,z2)
  gl.PushMatrix()
  gl.Translate(x1, averageGroundHeight, z1)
  gl.Scale(x2-x1, shapeHeight, z2-z1)
  gl.Utilities.DrawVolume(box)
  gl.PopMatrix()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gl.Utilities.DrawVolume(vol_dlist)
  gl.DepthMask(false)
  if (gl.DepthClamp) then gl.DepthClamp(true) end
  gl.StencilTest(true)

  gl.Culling(false)
  gl.DepthTest(true)
  gl.ColorMask(false, false, false, false)
  gl.StencilOp(GL.KEEP, GL.INCR, GL.KEEP)
  --gl.StencilOp(GL.KEEP, GL.INVERT, GL.KEEP)
  gl.StencilMask(3)
  gl.StencilFunc(GL.ALWAYS, 0, 0)

  gl.CallList(vol_dlist)

  gl.Culling(GL.FRONT)
  gl.DepthTest(false)
  gl.ColorMask(true, true, true, true)
  gl.StencilOp(GL.ZERO, GL.ZERO, GL.ZERO)
  gl.StencilMask(3)
  gl.StencilFunc(GL.NOTEQUAL, 0, 0+1)

  gl.CallList(vol_dlist)

  if (gl.DepthClamp) then gl.DepthClamp(false) end
  gl.StencilTest(false)
  gl.DepthTest(true)
  gl.Culling(false)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
