local CopyTable = Spring.Utilities.CopyTable

local weaponsList = VFS.DirList("gamedata/modularcomms/weapons", "*.lua") or {}
for i = 1, #weaponsList do
	local name, array = VFS.Include(weaponsList[i])
	WeaponDefs[name] = lowerkeys(array)
end
