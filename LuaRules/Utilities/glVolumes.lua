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

GL.KEEP = 0x1E00
GL.INCR_WRAP = 0x8507
GL.DECR_WRAP = 0x8508
GL.INCR = 0x1E02
GL.DECR = 0x1E03
GL.INVERT = 0x150A

local stencilBit1 = 0x01
local stencilBit2 = 0x10

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gl.Utilities.DrawMyBox(minX,minY,minZ, maxX,maxY,maxZ)
  gl.BeginEnd(GL.QUADS, function()
    --// top
    gl.Vertex(minX, maxY, minZ);
    gl.Vertex(maxX, maxY, minZ);
    gl.Vertex(maxX, maxY, maxZ);
    gl.Vertex(minX, maxY, maxZ);
    --// bottom
    gl.Vertex(minX, minY, minZ);
    gl.Vertex(minX, minY, maxZ);
    gl.Vertex(maxX, minY, maxZ);
    gl.Vertex(maxX, minY, minZ);
  end);
  gl.BeginEnd(GL.QUAD_STRIP, function()
    --// sides
    gl.Vertex(minX, minY, minZ);
    gl.Vertex(minX, maxY, minZ);
    gl.Vertex(minX, minY, maxZ);
    gl.Vertex(minX, maxY, maxZ);
    gl.Vertex(maxX, minY, maxZ);
    gl.Vertex(maxX, maxY, maxZ);
    gl.Vertex(maxX, minY, minZ);
    gl.Vertex(maxX, maxY, minZ);
    gl.Vertex(minX, minY, minZ);
    gl.Vertex(minX, maxY, minZ);
  end);
end


function gl.Utilities.DrawMyCylinder(x,y,z, height,radius,divs)
  divs = divs or 25
  gl.BeginEnd(GL.TRIANGLE_STRIP, function()
    --//Note: We can't use for-loops here cause of precision issues!

    --// top
    local alpha=-(2*math.pi)/divs
    repeat
      alpha = alpha + (2*math.pi)/divs
      alpha = math.min(alpha,2*math.pi)

      local sa = math.sin(alpha % (2*math.pi))
      local ca = math.cos(alpha % (2*math.pi))
      gl.Vertex(x+radius*sa, y+height/2, y+radius*ca);
      gl.Vertex(x, y+height/2, y);
    until (alpha >= 2*math.pi)

    --// degenerate
    gl.Vertex(x, y+height/2, y);
    gl.Vertex(x, y-height/2, y);
    gl.Vertex(x, y-height/2, y);

    --// bottom
    alpha=(2*math.pi)/divs
    repeat
      alpha = alpha - (2*math.pi)/divs
      alpha = math.max(alpha,-2*math.pi)

      local sa = math.sin(alpha)
      local ca = math.cos(alpha)
      gl.Vertex(x+radius*sa, y-height/2, y+radius*ca);
      gl.Vertex(x, y-height/2, y);
    until (alpha <= -2*math.pi)

    --// degenerate
    gl.Vertex(x, y-height/2, y);
    gl.Vertex(x, y-height/2, y+radius);
    gl.Vertex(x, y-height/2, y+radius);

    --// sides
    alpha=-(2*math.pi)/divs
    repeat
      alpha = alpha + (2*math.pi)/divs
      alpha = math.min(alpha,2*math.pi)

      local sa = math.sin(alpha)
      local ca = math.cos(alpha)
      gl.Vertex(x+radius*sa, y+height/2, y+radius*ca);
      gl.Vertex(x+radius*sa, y-height/2, y+radius*ca);
    until (alpha >= 2*math.pi)
  end);
end


local cylinder = gl.CreateList(gl.Utilities.DrawMyCylinder,0,0,0,1,1,35)
function gl.Utilities.DrawGroundCircle(x,z,radius)
  local minheight, maxheight = Spring.GetGroundExtremes()

  gl.PushMatrix()
  gl.Translate(x, minheight, z)
  gl.Scale(radius, (maxheight-minheight)*3 , radius)
  gl.Utilities.DrawVolume(cylinder)
  gl.PopMatrix()
end

local box = gl.CreateList(gl.Utilities.DrawMyBox,0,0,0,1,1,1)
function gl.Utilities.DrawGroundRectangle(x1,z1,x2,z2)
  local minheight, maxheight = Spring.GetGroundExtremes()

  gl.PushMatrix()
  gl.Translate(x1, minheight, z1)
  gl.Scale(x2-x1, (maxheight-minheight)*3 , z2-z1)
  gl.Utilities.DrawVolume(box)
  gl.PopMatrix()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gl.Utilities.DrawVolume(vol_dlist)
  gl.DepthMask(false);
  if (gl.DepthClamp) then gl.DepthClamp(true); end
  gl.StencilTest(true);

  gl.Culling(false);
  gl.DepthTest(true);
  gl.ColorMask(false, false, false, false);
  gl.StencilOp(GL.KEEP, GL.INCR, GL.KEEP);
  --gl.StencilOp(GL.KEEP, GL.INVERT, GL.KEEP);
  gl.StencilMask(3);
  gl.StencilFunc(GL.ALWAYS, 0, 0);

  gl.CallList(vol_dlist)

  gl.Culling(GL.FRONT);
  gl.DepthTest(false);
  gl.ColorMask(true, true, true, true);
  gl.StencilOp(GL.ZERO, GL.ZERO, GL.ZERO);
  gl.StencilMask(3);
  gl.StencilFunc(GL.NOTEQUAL, 0, 0+1);

  gl.CallList(vol_dlist)

  if (gl.DepthClamp) then gl.DepthClamp(false); end
  gl.StencilTest(false);
  gl.DepthTest(true);
  gl.Culling(false);
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
