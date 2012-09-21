--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Exported Functions:
--  gl.Utilities.DrawMyBox(minX,minY,minZ, maxX,maxY,maxZ)
--  gl.Utilities.DrawMyCylinder(x,y,z, height,radius,divs)
--  gl.Utilities.DrawGroundRectangle(x1,z1,x2,z2)
--  gl.Utilities.DrawGroundCircle(x,z,radius)
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


local function CreateSinCosTable(divs)
  local sinTable = {}
  local cosTable = {}
  
  local divAngle = TWO_PI / divs
  local alpha = 0
  local i = 1
  repeat
    sinTable[i] = sin(alpha)
    cosTable[i] = cos(alpha)
    
    alpha = alpha + divAngle
    i = i + 1
  until (alpha >= TWO_PI)
  sinTable[i] = 0.0 -- sin(TWO_PI)
  cosTable[i] = 1.0 -- cos(TWO_PI)
  
  return sinTable, cosTable
end


function gl.Utilities.DrawMyCylinder(x,y,z, height,radius,divs)
  divs = divs or 25
  local sinTable, cosTable = CreateSinCosTable(divs)
  local bottomY = y - (height / 2)
  local topY    = y + (height / 2)
  
  gl.BeginEnd(GL.TRIANGLE_STRIP, function()
    --// top
    for i = #sinTable, 1, -1 do
      glVertex(x + radius*sinTable[i], topY, z + radius*cosTable[i])
      glVertex(x, topY, z)
    end

    --// degenerate
    glVertex(x, topY   , z)
    glVertex(x, bottomY, z)
    glVertex(x, bottomY, z)

    --// bottom
    for i = #sinTable, 1, -1 do
      glVertex(x + radius*sinTable[i], bottomY, z + radius*cosTable[i])
      glVertex(x, bottomY, z)
    end

    --// degenerate
    glVertex(x, bottomY, z)
    glVertex(x, bottomY, z+radius)
    glVertex(x, bottomY, z+radius)

    --// sides
    for i = 1, #sinTable do
      local rx = x + radius * sinTable[i]
      local rz = z + radius * cosTable[i]
      glVertex(rx, topY   , rz)
      glVertex(rx, bottomY, rz)
    end
  end)
end


local heightMargin = 2000
local minheight, maxheight = Spring.GetGroundExtremes()  --the returned values do not change even if we terraform the map
local averageGroundHeight = (minheight + maxheight) / 2
local shapeHeight = heightMargin + (maxheight - minheight) + heightMargin

local box = gl.CreateList(gl.Utilities.DrawMyBox,0,0.5,0,1,0.5,1)
function gl.Utilities.DrawGroundRectangle(x1,z1,x2,z2)
  gl.PushMatrix()
  gl.Translate(x1, averageGroundHeight, z1)
  gl.Scale(x2-x1, shapeHeight, z2-z1)
  gl.Utilities.DrawVolume(box)
  gl.PopMatrix()
end

local cylinder = gl.CreateList(gl.Utilities.DrawMyCylinder,0,0,0,1,1,35)
function gl.Utilities.DrawGroundCircle(x,z,radius)
  gl.PushMatrix()
  gl.Translate(x, averageGroundHeight, z)
  gl.Scale(radius, shapeHeight, radius)
  gl.Utilities.DrawVolume(cylinder)
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
