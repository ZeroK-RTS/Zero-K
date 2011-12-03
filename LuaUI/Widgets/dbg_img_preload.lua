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
local files = nil

local function AddDir(path) 
	for _, f in ipairs(VFS.DirList(path),"*.png") do 
		files[#files+1] = f 
	end 
	for _, f in ipairs(VFS.DirList(path),"*.dds") do 
		files[#files+1] = f 
	end 
	--[[for _, f in ipairs(VFS.SubDirs(path)) do 
		if (f ~= "." and f ~=".." and f~=".svn") then 
			AddDir(f)
		end 
	end]]--
end 



function widget:DrawGenesis()
	if files == nil then 
		files = {}
		--AddDir("LuaUI/Images")
		AddDir("icons")
	else 
		if (UnitDefs[i]) then
			gl.Texture(7,'#'..i)
			gl.Texture(7,false)
			i = i + 1
		else
			local file = files[v]
			if file then
				--Spring.Echo(file)
				gl.Texture(7, file)
				gl.Texture(7, false)
				v = v + 1
				
			else 
				widgetHandler:RemoveWidget()
			end 
		end 
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------