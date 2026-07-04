
local OVERKILL_STATES = 5

-- Value is the default state of the command
local handledUnitDefIDs = {
	[UnitDefNames["turretmissile"].id]    = 2,
	[UnitDefNames["turretaafar"].id]      = 2,
	[UnitDefNames["hoverskirm"].id]       = 2,
	[UnitDefNames["hoverdepthcharge"].id] = 2,
	[UnitDefNames["turretaaclose"].id]    = 2,
	[UnitDefNames["turretaaheavy"].id]    = 2,
	[UnitDefNames["amphaa"].id]           = 2,
	[UnitDefNames["jumpscout"].id]        = 2,
	[UnitDefNames["planefighter"].id]     = 2,
	[UnitDefNames["hoveraa"].id]          = 2,
	[UnitDefNames["tankraid"].id]         = 2,
	[UnitDefNames["spideraa"].id]         = 2,
	[UnitDefNames["vehaa"].id]            = 2,
	[UnitDefNames["gunshipaa"].id]        = 2,
	[UnitDefNames["gunshipskirm"].id]     = 2,
	[UnitDefNames["gunshipassault"].id]   = 2,
	[UnitDefNames["cloaksnipe"].id]       = 2,
	[UnitDefNames["amphraid"].id]         = 2,
	[UnitDefNames["amphimpulse"].id]      = 2,
	[UnitDefNames["amphriot"].id]         = 2,
	[UnitDefNames["shieldaa"].id]         = 2,
	[UnitDefNames["vehsupport"].id]       = 2,
	[UnitDefNames["tankriot"].id]         = 2, --HT's banisher
	[UnitDefNames["shieldarty"].id]       = 2, --Shields's racketeer
	[UnitDefNames["bomberprec"].id]       = 3,
	[UnitDefNames["bomberstrike"].id]     = 3,
	[UnitDefNames["shipscout"].id]        = 0, --Defaults to off because of strange disarm + normal damage behaviour.
	[UnitDefNames["shiptorpraider"].id]   = 2,
	[UnitDefNames["shipskirm"].id]        = 2,
	[UnitDefNames["subraider"].id]        = 2,
	[UnitDefNames["turretheavylaser"].id] = 2,
	[UnitDefNames["amphassault"].id]      = 2,
	[UnitDefNames["hoverarty"].id]        = 2,
	[UnitDefNames["turretantiheavy"].id]  = 2,

	-- Static only OKP below
	[UnitDefNames["amphfloater"].id]      = 2,
	[UnitDefNames["amphsupport"].id]      = 2,
	[UnitDefNames["vehheavyarty"].id]     = 2,
	[UnitDefNames["shieldskirm"].id]      = 2,
	[UnitDefNames["shieldassault"].id]    = 2,
	[UnitDefNames["spiderassault"].id]    = 2,
	[UnitDefNames["cloakskirm"].id]       = 2,
	[UnitDefNames["cloakarty"].id]        = 2,
	[UnitDefNames["tankarty"].id]         = 2,
	[UnitDefNames["striderdetriment"].id] = 2,
	[UnitDefNames["shipassault"].id]      = 2,
	[UnitDefNames["shiparty"].id]         = 2,
	[UnitDefNames["spiderskirm"].id]      = 2,
	[UnitDefNames["tankassault"].id]      = 2,
	[UnitDefNames["vehassault"].id]       = 2,
	[UnitDefNames["tankheavyassault"].id] = 2,
	[UnitDefNames["spidercrabe"].id]      = 2,
}

local blackHoleUnitDefs = {
	[UnitDefNames["jumpblackhole"].id] = 2,
}

local blackHoleWeaponDefs = {
	[WeaponDefNames["jumpblackhole_black_hole"].id] = true,
}

local lobsterUnitDefs = {
	[UnitDefNames["amphlaunch"].id] = 3,
}


return handledUnitDefIDs, blackHoleUnitDefs, blackHoleWeaponDefs, lobsterUnitDefs, OVERKILL_STATES
