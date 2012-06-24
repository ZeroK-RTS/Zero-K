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
		tankRegenRate = 14,
		healthRegen = 20,
		submergedAt = 40,
		baseHeight = 5,
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
		healthRegen = 25,
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