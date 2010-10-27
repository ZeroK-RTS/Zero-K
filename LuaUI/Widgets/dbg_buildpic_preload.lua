--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Buildpic Preloader",
    desc      = "Fixes buildpic issues",
    author    = "jK",
    date      = "@2009",
    license   = "GPLv2",
    layer     = 1000,
    enabled   = true,  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local i = 1
function widget:DrawGenesis()
  if (UnitDefs[i])or(Spring.GetGameFrame()>1) then
    gl.Texture(7,'#'..i)
    gl.Texture(7,false)
    i = i + 1
  else
    widgetHandler:RemoveWidget()
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------