if not Spring.ModularCommAPI then
	Spring.ModularCommAPI = {}
end
if not Spring.ModularCommAPI.Modules then
	local Modules = {}
	Spring.ModularCommAPI.Modules = Modules
	local moduleFiles = VFS.DirList("gamedata/modularcomms/modules", "*.lua") or {}
	for i = 1, #moduleFiles do
		local moduleDef = VFS.Include(moduleFiles[i])
		Modules[#Modules + 1] = moduleDef
	end
end
return Spring.ModularCommAPI.Modules
