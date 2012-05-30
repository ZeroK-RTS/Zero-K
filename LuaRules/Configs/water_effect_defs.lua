local waterCannonIterable = {
	WeaponDefNames["amphraider2_watercannon"].id,
}

local waterCannonIndexable = {
	[WeaponDefNames["amphraider2_watercannon"].id] = true,
}

local unitDefData = {
	[UnitDefNames["amphraider2"].id] = {
		tankMax = 180,
		shotCost = 1.2,
		tankRegenRate = 6,
		healthRegen = 18,
	},
	[UnitDefNames["amphcon"].id] = {
		healthRegen = 18,
	},
}

return unitDefData, waterCannonIterable, waterCannonIndexable