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
    alwaysStart = true,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local i = 1
local v = 1
local files = nil

local function MaybeAddFile(fileName)
	if string.find(fileName, "%.dds") or string.find(fileName, "%.png") then
		files[#files+1] = fileName
	end
end

local function AddDir(path)
	for _, f in ipairs(VFS.DirList(path)) do
		MaybeAddFile(f)
	end
	--[[for _, f in ipairs(VFS.SubDirs(path)) do
		if (f ~= "." and f ~=".." and f~=".svn") then
			AddDir(f)
		end
	end]]--
end

function widget:Initialize()
	if Spring.GetGameFrame() > 0 then
	      Spring.Log(widget:GetInfo().name, LOG.INFO, "Game has started. Widget removed.")
	      widgetHandler:RemoveWidget()
	end
end

function widget:DrawGenesis()
	if files == nil then
		files = {}
		AddDir("LuaUI/Images/commands/Bold")
		AddDir("LuaUI/Images/commands/states")
		AddDir("LuaUI/Widgets/chili/Skins/Evolved")
		AddDir("icons")
	else
		if (UnitDefs[i]) then
			gl.Texture(7,'#'..i)
			gl.Texture(7,false)
			i = i + 1
		else
			local file = files[v]
			if file then
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
