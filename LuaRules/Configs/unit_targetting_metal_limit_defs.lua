local STATES = {0, 0, 100, 300, 1000} -- first value is the default state of the command
local metalThreshholdsByUnitDefIDs = {
	[UnitDefNames["hoverarty"].id] = STATES,
	[UnitDefNames["cloaksnipe"].id] = STATES,
	[UnitDefNames["turretheavylaser"].id] = STATES,
	[UnitDefNames["turretantiheavy"].id] = STATES,
	[UnitDefNames["striderarty"].id] = STATES,
	[UnitDefNames["bomberheavy"].id] = STATES,
	[UnitDefNames["bomberprec"].id] = STATES,
	[UnitDefNames["gunshipassault"].id] = STATES,
	[UnitDefNames["staticheavyarty"].id] = STATES,
	[UnitDefNames["turretaaheavy"].id] = STATES,
	[UnitDefNames["starlight_satellite"].id] = STATES,
	[UnitDefNames["raveparty"].id] = STATES,
	[UnitDefNames["hoverskirm"].id] = STATES,
	[UnitDefNames["shieldskirm"].id] = STATES,
	[UnitDefNames["shipheavyarty"].id] = STATES,
	[UnitDefNames["shiparty"].id] = STATES,
	[UnitDefNames["vehcapture"].id] = STATES,
	[UnitDefNames["jumpskirm"].id] = STATES,
}

return metalThreshholdsByUnitDefIDs