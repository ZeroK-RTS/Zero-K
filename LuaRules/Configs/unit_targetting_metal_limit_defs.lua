-- Value is the default state of the command
local metalThreshholdsByUnitDefIDs = {
	[UnitDefNames["hoverarty"].id] = {0, 0, 100, 300, 1000},
	[UnitDefNames["cloaksnipe"].id] = {0, 0, 100, 300, 1000},
	[UnitDefNames["turretheavylaser"].id] = {0, 0, 100, 300, 1000},
	[UnitDefNames["turretantiheavy"].id] = {0, 0, 100, 300, 1000},
	[UnitDefNames["striderarty"].id] = {0, 0, 100, 300, 1000},
	[UnitDefNames["bomberheavy"].id] = {0, 0, 100, 300, 1000},
	[UnitDefNames["bomberprec"].id] = {0, 0, 100, 300, 1000},
	[UnitDefNames["gunshipassault"].id] = {0, 0, 100, 300, 1000},
	[UnitDefNames["staticheavyarty"].id] = {0, 0, 100, 300, 1000},
	[UnitDefNames["turretaaheavy"].id] = {0, 0, 100, 300, 1000},
	[UnitDefNames["starlight_satellite"].id] = {0, 0, 100, 300, 1000},
	[UnitDefNames["raveparty"].id] = {0, 0, 100, 300, 1000},
	[UnitDefNames["hoverskirm"].id] = {0, 0, 100, 300, 1000},
	[UnitDefNames["shieldskirm"].id] = {0, 0, 100, 300, 1000},
	[UnitDefNames["shipheavyarty"].id] = {0, 0, 100, 300, 1000},
	[UnitDefNames["shiparty"].id] = {0, 0, 100, 300, 1000},
	[UnitDefNames["vehcapture"].id] = {0, 0, 100, 300, 1000},
	[UnitDefNames["jumpskirm"].id] = {0, 0, 100, 300, 1000},
}

return metalThreshholdsByUnitDefIDs