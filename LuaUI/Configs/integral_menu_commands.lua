VFS.Include("LuaRules/Configs/customcmds.h.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Order and State Panel Positions

-- Commands are placed in their position, with conflicts resolved by pushng those
-- with less priority (higher number = less priority) along the positions if
-- two or more commands want the same position.
-- The command panel is propagated left to right, top to bottom.
-- The state panel is propagate top to bottom, right to left.
-- * States can use posSimple to set a different position when the panel is in
--   four-row mode.
-- * Missing commands have {pos = 1, priority = 100}

local cmdPosDef = {
	-- Commands
	[CMD.STOP]          = {pos = 1, priority = 1},
	[CMD.FIGHT]         = {pos = 1, priority = 2},
	[CMD_RAW_MOVE]      = {pos = 1, priority = 3},
	[CMD.PATROL]        = {pos = 1, priority = 4},
	[CMD.ATTACK]        = {pos = 1, priority = 5},
	[CMD_JUMP]          = {pos = 1, priority = 6},
	[CMD_AREA_GUARD]    = {pos = 1, priority = 10},
	[CMD.AREA_ATTACK]   = {pos = 1, priority = 11},
	
	[CMD_UPGRADE_UNIT]  = {pos = 7, priority = -8},
	[CMD_UPGRADE_STOP]  = {pos = 7, priority = -7},
	[CMD_MORPH]         = {pos = 7, priority = -6},
	
	[CMD_STOP_NEWTON_FIREZONE] = {pos = 7, priority = -4},
	[CMD_NEWTON_FIREZONE]      = {pos = 7, priority = -3},
	
	[CMD.MANUALFIRE]      = {pos = 7, priority = 0.1},
	[CMD_PLACE_BEACON]    = {pos = 7, priority = 0.2},
	[CMD_ONECLICK_WEAPON] = {pos = 7, priority = 0.24},
	[CMD.STOCKPILE]       = {pos = 7, priority = 0.25},
	[CMD_ABANDON_PW]      = {pos = 7, priority = 0.3},
	[CMD_GBCANCEL]        = {pos = 7, priority = 0.4},
	[CMD_STOP_PRODUCTION] = {pos = 7, priority = 0.7},
	
	[CMD_BUILD]         = {pos = 7, priority = 0.8},
	[CMD_AREA_MEX]      = {pos = 7, priority = 1},
	[CMD.REPAIR]        = {pos = 7, priority = 2},
	[CMD.RECLAIM]       = {pos = 7, priority = 3},
	[CMD.RESURRECT]     = {pos = 7, priority = 4},
	[CMD.WAIT]          = {pos = 7, priority = 5},
	[CMD_FIND_PAD]      = {pos = 7, priority = 6},
	
	[CMD.LOAD_UNITS]    = {pos = 7, priority = 7},
	[CMD.UNLOAD_UNITS]  = {pos = 7, priority = 8},
	[CMD_RECALL_DRONES] = {pos = 7, priority = 10},
	
	[CMD_AREA_TERRA_MEX]= {pos = 13, priority = 1},
	[CMD_UNIT_SET_TARGET_CIRCLE] = {pos = 13, priority = 2},
	[CMD_UNIT_CANCEL_TARGET]     = {pos = 13, priority = 3},
	[CMD_EMBARK]        = {pos = 13, priority = 5},
	[CMD_DISEMBARK]     = {pos = 13, priority = 6},
	[CMD_EXCLUDE_PAD]   = {pos = 13, priority = 7},

	-- States
	[CMD.REPEAT]              = {pos = 1, priority = 1},
	[CMD_RETREAT]             = {pos = 1, priority = 2},
	
	[CMD.MOVE_STATE]          = {pos = 6, posSimple = 5, priority = 1},
	[CMD.FIRE_STATE]          = {pos = 6, posSimple = 5, priority = 2},
	[CMD_FACTORY_GUARD]       = {pos = 6, posSimple = 5, priority = 3},
	
	[CMD_SELECTION_RANK]      = {pos = 6, posSimple = 1, priority = 1.5},
	
	[CMD_PRIORITY]            = {pos = 1, priority = 10},
	[CMD_MISC_PRIORITY]       = {pos = 1, priority = 11},
	[CMD_CLOAK_SHIELD]        = {pos = 1, priority = 11.5},
	[CMD_WANT_CLOAK]          = {pos = 1, priority = 11.6},
	[CMD_WANT_ONOFF]          = {pos = 1, priority = 13},
	[CMD_PREVENT_BAIT]        = {pos = 1, priority = 13.1},
	[CMD_PREVENT_OVERKILL]    = {pos = 1, priority = 13.2},
	[CMD_FIRE_TOWARDS_ENEMY]  = {pos = 1, priority = 13.25},
	[CMD_FIRE_AT_SHIELD]      = {pos = 1, priority = 13.3},
	[CMD.TRAJECTORY]          = {pos = 1, priority = 14},
	[CMD_UNIT_FLOAT_STATE]    = {pos = 1, priority = 15},
	[CMD_TOGGLE_DRONES]       = {pos = 1, priority = 16},
	[CMD_PUSH_PULL]           = {pos = 1, priority = 17},
	[CMD.IDLEMODE]            = {pos = 1, priority = 18},
	[CMD_AP_FLY_STATE]        = {pos = 1, priority = 19},
	[CMD_AUTO_CALL_TRANSPORT] = {pos = 1, priority = 21},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Factory Units Panel Positions

-- These positions must be distinct

-- Locally defined intermediate positions to cut down repetitions.
local unitTypes = {
	CONSTRUCTOR     = {order = 1, row = 1, col = 1},
	RAIDER          = {order = 2, row = 1, col = 2},
	SKIRMISHER      = {order = 3, row = 1, col = 3},
	RIOT            = {order = 4, row = 1, col = 4},
	ASSAULT         = {order = 5, row = 1, col = 5},
	ARTILLERY       = {order = 6, row = 1, col = 6},

	-- note: row 2 column 1 purposefully skipped, since
	-- that allows giving facs Attack orders via hotkey
	WEIRD_RAIDER    = {order = 7, row = 2, col = 2},
	ANTI_AIR        = {order = 8, row = 2, col = 3},
	HEAVY_SOMETHING = {order = 9, row = 2, col = 4},
	SPECIAL         = {order = 10, row = 2, col = 5},
	UTILITY         = {order = 11, row = 2, col = 6},
}

local factoryUnitPosDef = {
	factorycloak = {
		cloakcon          = unitTypes.CONSTRUCTOR,
		cloakraid         = unitTypes.RAIDER,
		cloakheavyraid    = unitTypes.WEIRD_RAIDER,
		cloakriot         = unitTypes.RIOT,
		cloakskirm        = unitTypes.SKIRMISHER,
		cloakarty         = unitTypes.ARTILLERY,
		cloakaa           = unitTypes.ANTI_AIR,
		cloakassault      = unitTypes.ASSAULT,
		cloaksnipe        = unitTypes.HEAVY_SOMETHING,
		cloakbomb         = unitTypes.SPECIAL,
		cloakjammer       = unitTypes.UTILITY,
	},
	factoryshield = {
		shieldcon         = unitTypes.CONSTRUCTOR,
		shieldscout       = unitTypes.WEIRD_RAIDER,
		shieldraid        = unitTypes.RAIDER,
		shieldriot        = unitTypes.RIOT,
		shieldskirm       = unitTypes.SKIRMISHER,
		shieldarty        = unitTypes.ARTILLERY,
		shieldaa          = unitTypes.ANTI_AIR,
		shieldassault     = unitTypes.ASSAULT,
		shieldfelon       = unitTypes.HEAVY_SOMETHING,
		shieldbomb        = unitTypes.SPECIAL,
		shieldshield      = unitTypes.UTILITY,
	},
	factoryveh = {
		vehcon            = unitTypes.CONSTRUCTOR,
		vehscout          = unitTypes.WEIRD_RAIDER,
		vehraid           = unitTypes.RAIDER,
		vehriot           = unitTypes.RIOT,
		vehsupport        = unitTypes.SKIRMISHER, -- Not really but nowhere else to go
		veharty           = unitTypes.ARTILLERY,
		vehaa             = unitTypes.ANTI_AIR,
		vehassault        = unitTypes.ASSAULT,
		vehheavyarty      = unitTypes.HEAVY_SOMETHING,
		vehcapture        = unitTypes.SPECIAL,
	},
	factoryhover = {
		hovercon          = unitTypes.CONSTRUCTOR,
		hoverraid         = unitTypes.RAIDER,
		hoverheavyraid    = unitTypes.WEIRD_RAIDER,
		hoverdepthcharge  = unitTypes.SPECIAL,
		hoverriot         = unitTypes.RIOT,
		hoverskirm        = unitTypes.SKIRMISHER,
		hoverarty         = unitTypes.ARTILLERY,
		hoveraa           = unitTypes.ANTI_AIR,
		hoverassault      = unitTypes.ASSAULT,
	},
	factorygunship = {
		gunshipcon        = unitTypes.CONSTRUCTOR,
		gunshipemp        = unitTypes.WEIRD_RAIDER,
		gunshipraid       = unitTypes.RAIDER,
		gunshipheavyskirm = unitTypes.ARTILLERY,
		gunshipskirm      = unitTypes.SKIRMISHER,
		gunshiptrans      = unitTypes.SPECIAL,
		gunshipheavytrans = unitTypes.UTILITY,
		gunshipaa         = unitTypes.ANTI_AIR,
		gunshipassault    = unitTypes.ASSAULT,
		gunshipkrow       = unitTypes.HEAVY_SOMETHING,
		gunshipbomb       = unitTypes.RIOT,
	},
	factoryplane = {
		planecon          = unitTypes.CONSTRUCTOR,
		planefighter      = unitTypes.RAIDER,
		bomberriot        = unitTypes.RIOT,
		bomberstrike      = unitTypes.SKIRMISHER,
		-- No Plane Artillery
		planeheavyfighter = unitTypes.WEIRD_RAIDER,
		planescout        = unitTypes.UTILITY,
		planelightscout   = unitTypes.ARTILLERY,
		bomberprec        = unitTypes.ASSAULT,
		bomberheavy       = unitTypes.HEAVY_SOMETHING,
		bomberdisarm      = unitTypes.SPECIAL,
	},
	factoryspider = {
		spidercon         = unitTypes.CONSTRUCTOR,
		spiderscout       = unitTypes.RAIDER,
		spiderriot        = unitTypes.RIOT,
		spiderskirm       = unitTypes.SKIRMISHER,
		-- No Spider Artillery
		spideraa          = unitTypes.ANTI_AIR,
		spideremp         = unitTypes.WEIRD_RAIDER,
		spiderassault     = unitTypes.ASSAULT,
		spidercrabe       = unitTypes.HEAVY_SOMETHING,
		spiderantiheavy   = unitTypes.SPECIAL,
	},
	factoryjump = {
		jumpcon           = unitTypes.CONSTRUCTOR,
		jumpscout         = unitTypes.WEIRD_RAIDER,
		jumpraid          = unitTypes.RAIDER,
		jumpblackhole     = unitTypes.RIOT,
		jumpskirm         = unitTypes.SKIRMISHER,
		jumparty          = unitTypes.ARTILLERY,
		jumpaa            = unitTypes.ANTI_AIR,
		jumpassault       = unitTypes.ASSAULT,
		jumpsumo          = unitTypes.HEAVY_SOMETHING,
		jumpbomb          = unitTypes.SPECIAL,
	},
	factorytank = {
		tankcon           = unitTypes. CONSTRUCTOR,
		tankraid          = unitTypes.WEIRD_RAIDER,
		tankheavyraid     = unitTypes.RAIDER,
		tankriot          = unitTypes.RIOT,
		tankarty          = unitTypes.ARTILLERY,
		tankheavyarty     = unitTypes.UTILITY,
		tankaa            = unitTypes.ANTI_AIR,
		tankassault       = unitTypes.ASSAULT,
		tankheavyassault  = unitTypes.HEAVY_SOMETHING,
	},
	factoryamph = {
		amphcon           = unitTypes.CONSTRUCTOR,
		amphraid          = unitTypes.RAIDER,
		amphimpulse       = unitTypes.WEIRD_RAIDER,
		amphriot          = unitTypes.RIOT,
		amphfloater       = unitTypes.SKIRMISHER,
		amphsupport       = unitTypes.ASSAULT,
		amphaa            = unitTypes.ANTI_AIR,
		amphassault       = unitTypes.HEAVY_SOMETHING,
		amphlaunch        = unitTypes.ARTILLERY,
		amphbomb          = unitTypes.SPECIAL,
		amphtele          = unitTypes.UTILITY,
	},
	factoryship = {
		shipcon           = unitTypes.CONSTRUCTOR,
		shiptorpraider    = unitTypes.RAIDER,
		shipriot          = unitTypes.RIOT,
		shipskirm         = unitTypes.SKIRMISHER,
		shiparty          = unitTypes.ARTILLERY,
		shipaa            = unitTypes.ANTI_AIR,
		shipscout         = unitTypes.WEIRD_RAIDER,
		shipassault       = unitTypes.ASSAULT,
		-- No Ship HEAVY_SOMETHING (yet)
		subraider         = unitTypes.SPECIAL,
	},
	pw_bomberfac = {
		bomberriot        = unitTypes.RIOT,
		bomberprec        = unitTypes.ASSAULT,
		bomberheavy       = unitTypes.HEAVY_SOMETHING,
		bomberdisarm      = unitTypes.SPECIAL,
	},
	pw_dropfac = {
		gunshiptrans      = unitTypes.SPECIAL,
		gunshipheavytrans = unitTypes.UTILITY,
	},
}

-- Factory plates copy their parents.
factoryUnitPosDef.platecloak   = Spring.Utilities.CopyTable(factoryUnitPosDef.factorycloak)
factoryUnitPosDef.plateshield  = Spring.Utilities.CopyTable(factoryUnitPosDef.factoryshield)
factoryUnitPosDef.plateveh     = Spring.Utilities.CopyTable(factoryUnitPosDef.factoryveh)
factoryUnitPosDef.platehover   = Spring.Utilities.CopyTable(factoryUnitPosDef.factoryhover)
factoryUnitPosDef.plategunship = Spring.Utilities.CopyTable(factoryUnitPosDef.factorygunship)
factoryUnitPosDef.plateplane   = Spring.Utilities.CopyTable(factoryUnitPosDef.factoryplane)
factoryUnitPosDef.platespider  = Spring.Utilities.CopyTable(factoryUnitPosDef.factoryspider)
factoryUnitPosDef.platejump    = Spring.Utilities.CopyTable(factoryUnitPosDef.factoryjump)
factoryUnitPosDef.platetank    = Spring.Utilities.CopyTable(factoryUnitPosDef.factorytank)
factoryUnitPosDef.plateamph    = Spring.Utilities.CopyTable(factoryUnitPosDef.factoryamph)
factoryUnitPosDef.plateship    = Spring.Utilities.CopyTable(factoryUnitPosDef.factoryship)

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

return cmdPosDef, factoryUnitPosDef, factory_commands, econ_commands, defense_commands, special_commands

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
