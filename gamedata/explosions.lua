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

for edName, eDef in pairs(explosionDefs) do
	for fxName, fxDef in pairs(eDef) do
		if(type(fxDef) == 'table') then
			if fxDef.ground and fxDef.voidground == nil then
				fxDef.voidground = true
			end
		end
	end
end

return explosionDefs
