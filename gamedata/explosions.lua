local VFS = VFS
local vfsInclude = VFS.Include
local vfsDirList = VFS.DirList

vfsInclude("LuaRules/Utilities/tablefunctions.lua")
local suCopyTable = Spring.Utilities.CopyTable

local files = vfsDirList("effects", "*.lua")
suCopyTable(vfsDirList("gamedata/explosions", "*.lua", VFS.MAP), false, files)

local explosionDefs = {}
for i = 1, #files do
	suCopyTable(vfsInclude(files[i]), false, explosionDefs)
end
return explosionDefs
