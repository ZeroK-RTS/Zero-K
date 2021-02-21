local STATES = {0, 0, 100, 300, 1000} -- first value is the default state of the command
local metalThreshholdsByUnitDefIDs = {
	[UnitDefNames["hoverarty"].id] = 1,
	[UnitDefNames["cloaksnipe"].id] = 1,
	[UnitDefNames["turretheavylaser"].id] = 1,
	[UnitDefNames["turretantiheavy"].id] = 1,
	[UnitDefNames["striderarty"].id] = 1,
	[UnitDefNames["bomberheavy"].id] = 1,
	[UnitDefNames["bomberprec"].id] = 1,
	[UnitDefNames["gunshipassault"].id] = 1,
	[UnitDefNames["staticheavyarty"].id] = 1,
	[UnitDefNames["turretaaheavy"].id] = 1,
	[UnitDefNames["starlight_satellite"].id] = 1,
	[UnitDefNames["raveparty"].id] = 1,
	[UnitDefNames["hoverskirm"].id] = 1,
	[UnitDefNames["shieldskirm"].id] = 1,
	[UnitDefNames["shipheavyarty"].id] = 1,
	[UnitDefNames["shiparty"].id] = 1,
	[UnitDefNames["vehcapture"].id] = 1,
	[UnitDefNames["jumpskirm"].id] = 1,
}

return metalThreshholdsByUnitDefIDs