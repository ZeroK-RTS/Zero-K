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
		healthRegen = 40,
		submergedAt = 40,
		baseHeight = 5,
		bonusProjectiles = 7.5,
		scalingRange = 200,
		baseRange = 100,
	},
	[UnitDefNames["amphbomb"].id] = {
		tankMax = 100,
		shotCost = 10,
		tankRegenRate = 5,
		healthRegen = 10,
		submergedAt = 40,
		baseHeight = 20,
		bonusProjectiles = 19,
		scalingRange = 0,
		baseRange = 280,
	},
	[UnitDefNames["amphcon"].id] = {
		healthRegen = 10,
		submergedAt = 40,
	},
	[UnitDefNames["amphraider3"].id] = {
		healthRegen = 10,
		submergedAt = 40,
	},
	[UnitDefNames["amphfloater"].id] = {
		healthRegen = 60,
		submergedAt = 30,
	},
	[UnitDefNames["amphriot"].id] = {
		healthRegen = 10,
		submergedAt = 40,
	},
	[UnitDefNames["amphassault"].id] = {
		healthRegen = 40,
		submergedAt = 40,
	},
	[UnitDefNames["amphaa"].id] = {
		healthRegen = 20,
		submergedAt = 40,
	},
	[UnitDefNames["amphtele"].id] = {
		healthRegen = 30,
		submergedAt = 40,
	},
}

return unitDefData, waterCannonIterable, waterCannonIndexable