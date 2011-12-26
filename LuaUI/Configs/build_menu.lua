local MAX_COLUMNS = 11

local economy_commands = {
	[-UnitDefNames["cormex"].id] = {level = 1, order = 1},
	[-UnitDefNames["armwin"].id] = {level = 1, order = 2},
	[-UnitDefNames["armsolar"].id] = {level = 1, order = 3},
	[-UnitDefNames["armnanotc"].id] = {level = 2, order = 4},
	[-UnitDefNames["armfus"].id] = {level = 2, order = 5},
	[-UnitDefNames["geo"].id] = {level = 2, order = 6},
	[-UnitDefNames["armestor"].id] = {level = 3, order = 7},
	[-UnitDefNames["armmstor"].id] = {level = 3, order = 8},
	[-UnitDefNames["cafus"].id] = {level = 3, order = 9},
}

local turret_commands = {
	[-UnitDefNames["corllt"].id] = {level = 1, order = 1},
	[-UnitDefNames["armartic"].id] = {level = 1, order = 2},
	[-UnitDefNames["armdeva"].id] = {level = 1, order = 3},
	[-UnitDefNames["corgrav"].id] = {level = 2, order = 4},
	[-UnitDefNames["corhlt"].id] = {level = 2, order = 5},
	[-UnitDefNames["armpb"].id] = {level = 2, order = 6},
	[-UnitDefNames["armanni"].id] = {level = 3, order = 7},
	[-UnitDefNames["corbhmth"].id] = {level = 3, order = 8},
	[-UnitDefNames["armbrtha"].id] = {level = 3, order = 9},
}

local other_turret_commands = {
	[-UnitDefNames["corrl"].id] = {level = 1, order = 1},
	[-UnitDefNames["cortl"].id] = {level = 2, order = 10},
--	[-UnitDefNames["armatl"].id] = {level = 3, order = 11},
	[-UnitDefNames["corrazor"].id] = {level = 2, order = 4},
	[-UnitDefNames["missiletower"].id] = {level = 2, order = 5},
	[-UnitDefNames["armcir"].id] = {level = 3, order = 6},
	[-UnitDefNames["corflak"].id] = {level = 3, order = 7},
	[-UnitDefNames["screamer"].id] = {level = 3, order = 8},
}

local factory_commands = {
	[-UnitDefNames["factorycloak"].id] = {level = 1, order = 1},
	[-UnitDefNames["factoryshield"].id] = {level = 1, order = 2},
	[-UnitDefNames["factoryspider"].id] = {level = 2, order = 3},
	[-UnitDefNames["factoryjump"].id] = {level = 2, order = 4},
	[-UnitDefNames["factoryveh"].id] = {level = 1, order = 5},
	[-UnitDefNames["factoryhover"].id] = {level = 2, order = 6},
	[-UnitDefNames["factorytank"].id] = {level = 2, order = 7},
	[-UnitDefNames["factorygunship"].id] = {level = 2, order = 8},
	[-UnitDefNames["factoryplane"].id] = {level = 2, order = 9},
	[-UnitDefNames["armasp"].id] = {level = 2, order = 10},
	[-UnitDefNames["corsy"].id] = {level = 2, order = 11},z

}

local support_commands = {
	[-UnitDefNames["corrad"].id] = {level = 1, order = 3},
	[-UnitDefNames["armjamt"].id] = {level = 1, order = 4},
	[-UnitDefNames["corjamt"].id] = {level = 1, order = 5},
	[-UnitDefNames["armsonar"].id] = {level = 1, order = 6},
	[-UnitDefNames["armarad"].id] = {level = 2, order = 7},
	[-UnitDefNames["armamd"].id] = {level =  2, order = 8},
	[-UnitDefNames["missilesilo"].id] = {level =  2, order = 9},
	[-UnitDefNames["corsilo"].id] = {level = 3, order = 10},
	[-UnitDefNames["mahlazer"].id] = {level = 3, order = 11},
	[-UnitDefNames["cormine1"].id] = {level = 2, order = 1},
	[-UnitDefNames["armcsa"].id] = {level = 3, order = 12},
}


return economy_commands, turret_commands, other_turret_commands, factory_commands, support_commands, MAX_COLUMNS