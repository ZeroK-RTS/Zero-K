-- $Id$
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local unitInfo = {}

local function DrawUnit(unitid, material, materialID)
  local info = unitInfo[unitid]
  if (not info) then
    info = {dir=0, lx=0, lz=0}
    unitInfo[unitid] = info
  end

  local vx,vy,vz = Spring.GetUnitVelocity(unitid)
  local speed = (vx*vx+vy*vy+vz*vz)^0.5

  local curFrame = Spring.GetGameFrame()
  if (info.n ~= curFrame) then
    info.n = curFrame;
    local lx = info.lx
    local lz = info.lz
    local dx,dy,dz = Spring.GetUnitDirection(unitid)
    info.dir =  info.dir*0.95 + (lx*dz - lz*dx) / ( (lx*lx+lz*lz)^0.5 + (dx*dx+dz*dz)^0.5 );
    info.lx,info.lz = dx,dz;
  end

  gl.Uniform(material.frameLoc, Spring.GetGameFrame()%360)
  gl.Uniform(material.speedLoc, info.dir,0,speed)

  return false --// engine should still draw it (we just set the uniforms for the shader)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local materials = {
   shark = {
      shader    = include(GADGET_DIR .. "UnitMaterials/Shaders/shark.lua"),
      force     = true, --// always use the shader even when normalmapping is disabled
      usecamera = false,
      culling   = GL.BACK,
      texunits  = {
        [0] = '%%UNITDEFID:0',
        [1] = '%%UNITDEFID:1',
        [2] = '$shadow',
        [3] = '$specular',
        [4] = '$reflection',
      },
      DrawUnit = DrawUnit
   }
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- affected unitdefs

local unitMaterials = {
   angelshark = "shark",
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return materials, unitMaterials

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
