--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Image Preloader",
    desc      = "Preloads images; fixes buildpic issues",
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
local v = 1
local files = VFS.DirList("LuaUI/Images")

function widget:DrawGenesis()
	local file = files[v]
	if file then
		--Spring.Echo(file)
		gl.Texture(7, file)
		gl.Texture(7, false)
		v = v + 1
	elseif (UnitDefs[i])or(Spring.GetGameFrame()>1) then
		gl.Texture(7,'#'..i)
		gl.Texture(7,false)
		i = i + 1
	else
		widgetHandler:RemoveWidget()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------