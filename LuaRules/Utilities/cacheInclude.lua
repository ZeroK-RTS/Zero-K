
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local cache = {}

function Spring.Utilities.CacheInclude(path)
	cache[path] = cache[path] or VFS.Include(path)
	return cache[path]
end
