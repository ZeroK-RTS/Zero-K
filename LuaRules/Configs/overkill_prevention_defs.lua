
-- Value is the default state of the command
local handledUnitDefIDs = {
	[UnitDefNames["turretmissile"].id] = 1,
	[UnitDefNames["turretaafar"].id] = 1,
	[UnitDefNames["hoverskirm"].id] = 1,
	[UnitDefNames["hoverdepthcharge"].id] = 1,
	[UnitDefNames["turretaaclose"].id] = 1,
	[UnitDefNames["turretaaheavy"].id] = 1,
	[UnitDefNames["amphaa"].id] = 1,
	[UnitDefNames["jumpscout"].id] = 1,
	[UnitDefNames["planefighter"].id] = 1,
	[UnitDefNames["hoveraa"].id] = 1,
	[UnitDefNames["tankraid"].id] = 1,
	[UnitDefNames["spideraa"].id] = 1,
	[UnitDefNames["vehaa"].id] = 1,
	[UnitDefNames["gunshipaa"].id] = 1,
	[UnitDefNames["gunshipskirm"].id] = 1,
	[UnitDefNames["gunshipassault"].id] = 1,
	[UnitDefNames["cloaksnipe"].id] = 1,
	[UnitDefNames["amphraid"].id] = 1,
	[UnitDefNames["amphimpulse"].id] = 1,
	[UnitDefNames["amphriot"].id] = 1,
	[UnitDefNames["shieldaa"].id] = 1,
	[UnitDefNames["vehsupport"].id] = 1,
	[UnitDefNames["tankriot"].id] = 1, --HT's banisher
	[UnitDefNames["shieldarty"].id] = 1, --Shields's racketeer
	[UnitDefNames["bomberprec"].id] = 1,
	[UnitDefNames["bomberstrike"].id] = 1,
	[UnitDefNames["shipscout"].id] = 0, --Defaults to off because of strange disarm + normal damage behaviour.
	[UnitDefNames["shiptorpraider"].id] = 1,
	[UnitDefNames["shipskirm"].id] = 1,
	[UnitDefNames["subraider"].id] = 1,
	[UnitDefNames["turretheavylaser"].id] = 1,
	[UnitDefNames["amphassault"].id] = 1,
	[UnitDefNames["hoverarty"].id] = 1,
	[UnitDefNames["turretantiheavy"].id] = 1,

	-- Static only OKP below
	[UnitDefNames["amphfloater"].id] = 1,
	[UnitDefNames["amphsupport"].id] = 1,
	[UnitDefNames["vehheavyarty"].id] = 1,
	[UnitDefNames["shieldskirm"].id] = 1,
	[UnitDefNames["shieldassault"].id] = 1,
	[UnitDefNames["spiderassault"].id] = 1,
	[UnitDefNames["cloakskirm"].id] = 1,
	[UnitDefNames["cloakarty"].id] = 1,
	[UnitDefNames["tankarty"].id] = 1,
	[UnitDefNames["striderdetriment"].id] = 1,
	[UnitDefNames["shipassault"].id] = 1,
	[UnitDefNames["shiparty"].id] = 1,
	[UnitDefNames["spiderskirm"].id] = 1,
	[UnitDefNames["tankassault"].id] = 1,
	[UnitDefNames["vehassault"].id] = 1,
	[UnitDefNames["tankheavyassault"].id] = 1,
	[UnitDefNames["spidercrabe"].id] = 1,
}

local blackHoleUnitDefs = {
	[UnitDefNames["jumpblackhole"].id] = true,
}

local blackHoleWeaponDefs = {
	[WeaponDefNames["jumpblackhole_black_hole"].id] = true,
}

return handledUnitDefIDs, blackHoleUnitDefs, blackHoleWeaponDefs
