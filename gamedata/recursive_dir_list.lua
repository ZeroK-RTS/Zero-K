-- similar to VFSUtils.lua, but doesn't pollute global namespace and conforms to future VFS.DirList API

local VFS = VFS
local vfsDirList = VFS.DirList
local vfsSubDirs = VFS.SubDirs

local function recursiveSearch(results, dir, pattern, modes)
	local files = vfsDirList(dir, pattern, modes)
	for i = 1, #files do
		results[#results + 1] = files[i]
	end

	local subfolders = VFS.SubDirs(dir, "*", modes)
	for i = 1, #subfolders do
		recursiveSearch(results, subfolders[i], pattern, modes)
	end
end

return function(dir, pattern, modes, recursive)
	if not recursive then
		return vfsDirList(dir, pattern, modes)
	else
		local results = {}
		recursiveSearch(results, dir, pattern, modes)
		return results
	end
end
