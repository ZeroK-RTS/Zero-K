local waterCannonIterable = {
	WeaponDefNames["amphraider2_watercannon"].id,
	WeaponDefNames["amphbomb_watercannon"].id,
}

local waterCannonIndexable = {
	[WeaponDefNames["amphraider2_watercannon"].id] = true,
	[WeaponDefNames["amphbomb_watercannon"].id] = true,
}

local unitDefData = {
	[UnitDefNames["amphraider2"].id] = {
		tankMax = 180,
		shotCost = 1.2,
		tankRegenRate = 14,
		baseHeight = 5,
		bonusProjectiles = 6.5,
		scalingRange = 200,
		baseRange = 100,
	},
	[UnitDefNames["amphbomb"].id] = {
		tankMax = 100,
		shotCost = 10,
		tankRegenRate = 5,
		baseHeight = 20,
		bonusProjectiles = 5.5,
		scalingRange = 0,
		baseRange = 250,
	},
}

return unitDefData, waterCannonIterable, waterCannonIndexable
