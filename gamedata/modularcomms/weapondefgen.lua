local CopyTable = Spring.Utilities.CopyTable

local weaponsList = VFS.DirList("gamedata/modularcomms/weapons", "*.lua") or {}
for i = 1, #weaponsList do
	local name, array = VFS.Include(weaponsList[i])
	local weapon = lowerkeys(array)
	for boost = 0, 8 do
		local weaponData = CopyTable(weapon, true)
		
		weaponData.size = (weaponData.size or (2 + math.min((weaponData.damage.default or 0) * 0.0025, (weaponData.areaofeffect or 0) * 0.1))) * (1 + boost/8)
		
		for armorname, dmg in pairs(weaponData.damage) do
			weaponData.damage[armorname] = dmg + dmg * boost*0.1
		end
		
		if (weaponData.customparams or {}).extra_damage_mult then
			weaponData.customparams.extra_damage = weaponData.customparams.extra_damage_mult * weaponData.damage.default
			weaponData.customparams.extra_damage_mult = nil
		end
		
		if weaponData.thickness then
			weaponData.thickness = weaponData.thickness * (1 + boost/8)
		end
		
		if weaponData.corethickness then
			weaponData.corethickness = weaponData.corethickness * (1 + boost/8)
		end
		
		WeaponDefs[boost .. "_" .. name] = weaponData
	end
end
