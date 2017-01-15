local alwaysHoldPos = {
	[UnitDefNames["armcrabe"].id] = true,
    [UnitDefNames["cormist"].id] = true,
    [UnitDefNames["trem"].id] = true,
}

local holdPosException = {
	[UnitDefNames["armnanotc"].id] = true,
}

local dontFireAtRadarUnits = {
	[UnitDefNames["armsnipe"].id] = true,
	[UnitDefNames["armmanni"].id] = true,
	[UnitDefNames["armanni"].id] = true,
	[UnitDefNames["armmerl"].id] = true,
}

return alwaysHoldPos, holdPosException, dontFireAtRadarUnits