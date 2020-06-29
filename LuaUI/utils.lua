--  author:  Dave Rodgers, jK
--  Copyright (C) 2007-2011.
--  Licensed under the terms of the GNU GPL, v2 or later.

--  returns:  basename, dirname
function Basename(fullpath)
	local _,_,base = fullpath:find("([^\\/:]*)$")
	local _,_,path = fullpath:find("(.*[\\/:])[^\\/:]*$")
	if (path == nil) then path = "" end
	return base, path
end

function include(filename, envTable, VFSMODE)
	--[[ support legacy header paths for the time being
	     in case people use them in their local widgets ]]
	if filename == "colors.h.lua" then
		return include("colors.lua", envTable, VFSMODE)
	elseif filename == "keysym.h.lua" then
		return include("keysym.lua", envTable, VFSMODE)
	end

	if (not filename:find("/", 1, true))or(not VFS.FileExists(filename, VFSMODE or VFS.DEF_MODE)) then
		if VFS.FileExists(LUAUI_DIRNAME .. filename, VFSMODE or VFS.DEF_MODE) then
			filename = LUAUI_DIRNAME .. filename
		elseif VFS.FileExists("LuaHandler/" .. filename, VFSMODE or VFS.DEF_MODE) then
			filename = "LuaHandler/" .. filename
		end
	end

	return VFS.Include(filename, envTable, VFSMODE or VFS.DEF_MODE)
end
