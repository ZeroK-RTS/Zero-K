local alwaysHoldPos = {
	[UnitDefNames["spidercrabe"].id] = true,
    [UnitDefNames["vehsupport"].id] = true,
    [UnitDefNames["trem"].id] = true,
}

local holdPosException = {
	[UnitDefNames["staticcon"].id] = true,
}

local dontFireAtRadarUnits = {
	[UnitDefNames["cloaksnipe"].id] = true,
	[UnitDefNames["hoverarty"].id] = true,
	[UnitDefNames["turretantiheavy"].id] = true,
	[UnitDefNames["vehheavyarty"].id] = true,
}

local factoryDefs = { -- Standard factories
	[UnitDefNames["factorycloak"].id] = 0,
	[UnitDefNames["factoryshield"].id] = 0,
	[UnitDefNames["factoryspider"].id] = 0,
	[UnitDefNames["factoryjump"].id] = 0,
	[UnitDefNames["factoryveh"].id] = 0,
	[UnitDefNames["factoryhover"].id] = 0,
	[UnitDefNames["factoryamph"].id] = 0,
	[UnitDefNames["factorytank"].id] = 0,
	[UnitDefNames["factoryplane"].id] = 0,
	[UnitDefNames["factorygunship"].id] = 0,
	[UnitDefNames["factoryship"].id] = 0,
}

return alwaysHoldPos, holdPosException, dontFireAtRadarUnits, factoryDefs