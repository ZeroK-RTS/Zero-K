local VFS = VFS
local vfsInclude = VFS.Include

vfsInclude("LuaRules/Utilities/tablefunctions.lua")
local suCopyTable = Spring.Utilities.CopyTable

local explosionDefs = {}
local files = VFS.DirList("effects", "*.lua")
for i = 1, #files do
	suCopyTable(vfsInclude(files[i]), false, explosionDefs)
end
return explosionDefs
