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
		healthRegen = 20,
	},
	[UnitDefNames["amphcon"].id] = {
		healthRegen = 20,
	},
	[UnitDefNames["amphraider3"].id] = {
		healthRegen = 10,
	},
	[UnitDefNames["amphfloater"].id] = {
		healthRegen = 25,
	},
	[UnitDefNames["amphriot"].id] = {
		healthRegen = 25,
	},
	[UnitDefNames["amphassault"].id] = {
		healthRegen = 40,
	},
	[UnitDefNames["amphaa"].id] = {
		healthRegen = 20,
	},
	[UnitDefNames["amphtele"].id] = {
		healthRegen = 30,
	},
}

return unitDefData, waterCannonIterable, waterCannonIndexable