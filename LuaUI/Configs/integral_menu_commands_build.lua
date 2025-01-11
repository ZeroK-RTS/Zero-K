VFS.Include("LuaRules/Configs/customcmds.h.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Construction Panel Structure Positions

-- These positions must be distinct

local factory_commands = {
	factorycloak      = {order = 1, row = 1, col = 1},
	factoryshield     = {order = 2, row = 1, col = 2},
	factoryveh        = {order = 3, row = 1, col = 3},
	factoryhover      = {order = 4, row = 1, col = 4},
	factorygunship    = {order = 5, row = 1, col = 5},
	factoryplane      = {order = 6, row = 1, col = 6},
	factoryspider     = {order = 7, row = 2, col = 1},
	factoryjump       = {order = 8, row = 2, col = 2},
	factorytank       = {order = 9, row = 2, col = 3},
	factoryamph       = {order = 10, row = 2, col = 4},
	factoryship       = {order = 11, row = 2, col = 5},
	striderhub        = {order = 12, row = 2, col = 6},
	[CMD_BUILD_PLATE] = {order = 13, row = 3, col = 4},
}

local econ_commands = {
	staticmex         = {order = 1, row = 1, col = 1},
	energywind        = {order = 2, row = 2, col = 1},
	energysolar       = {order = 3, row = 2, col = 2},
	energygeo         = {order = 4, row = 2, col = 3},
	energyfusion      = {order = 5, row = 2, col = 4},
	energysingu       = {order = 6, row = 2, col = 5},
	staticstorage     = {order = 7, row = 3, col = 1},
	energypylon       = {order = 8, row = 3, col = 2},
	staticcon         = {order = 9, row = 3, col = 3},
	staticrearm       = {order = 10, row = 3, col = 4},
}

local defense_commands = {
	turretlaser       = {order = 2, row = 1, col = 1},
	turretmissile     = {order = 1, row = 1, col = 2},
	turretriot        = {order = 2, row = 1, col = 3},
	turretemp         = {order = 3, row = 1, col = 4},
	turretgauss       = {order = 5, row = 1, col = 5},
	turretheavylaser  = {order = 6, row = 1, col = 6},

	turretaaclose     = {order = 9, row = 2, col = 1},
	turretaalaser     = {order = 10, row = 2, col = 2},
	turretaaflak      = {order = 11, row = 2, col = 3},
	turretaafar       = {order = 12, row = 2, col = 4},
	turretaaheavy     = {order = 13, row = 2, col = 5},

	turretimpulse     = {order = 4, row = 3, col = 1},
	turrettorp        = {order = 14, row = 3, col = 2},
	turretheavy       = {order = 16, row = 3, col = 3},
	turretantiheavy   = {order = 17, row = 3, col = 4},
	staticshield      = {order = 18, row = 3, col = 5},
}

local special_commands = {
	staticradar       = {order = 10, row = 1, col = 1},
	staticjammer      = {order = 12, row = 1, col = 2},
	staticheavyradar  = {order = 14, row = 1, col = 3},
	staticmissilesilo = {order = 15, row = 1, col = 4},
	staticantinuke    = {order = 16, row = 1, col = 5},
	staticarty        = {order = 2, row = 2, col = 1},
	staticheavyarty   = {order = 3, row = 2, col = 2},
	staticnuke        = {order = 4, row = 2, col = 3},
	zenith            = {order = 5, row = 2, col = 4},
	raveparty         = {order = 6, row = 2, col = 5},
	mahlazer          = {order = 7, row = 2, col = 6},
	[CMD_RAMP]        = {order = 16, row = 3, col = 1},
	[CMD_LEVEL]       = {order = 17, row = 3, col = 2},
	[CMD_RAISE]       = {order = 18, row = 3, col = 3},
	[CMD_RESTORE]     = {order = 19, row = 3, col = 4},
	[CMD_SMOOTH]      = {order = 20, row = 3, col = 5},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return factory_commands, econ_commands, defense_commands, special_commands

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
