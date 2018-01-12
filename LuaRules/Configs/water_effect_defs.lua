local waterCannonIterable = {
	WeaponDefNames["amphimpulse_watercannon"].id,
}

local waterCannonIndexable = {
	[WeaponDefNames["amphimpulse_watercannon"].id] = true,
}

local unitDefData = {
	[UnitDefNames["amphimpulse"].id] = {
		tankMax = 180,
		shotCost = 0,
		tankRegenRate = 14,
		baseHeight = 5,
		bonusProjectiles = 6.5,
		scalingRange = 200,
		baseRange = 100,
	},
}

return unitDefData, waterCannonIterable, waterCannonIndexable
