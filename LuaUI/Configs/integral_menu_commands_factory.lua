VFS.Include("LuaRules/Configs/customcmds.h.lua")

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
		planeheavyfighter = unitTypes.ANTI_AIR,
		planescout        = unitTypes.UTILITY,
		planelightscout   = unitTypes.WEIRD_RAIDER,
		bomberprec        = unitTypes.ASSAULT,
		bomberheavy       = unitTypes.HEAVY_SOMETHING,
		bomberassault     = unitTypes.ARTILLERY,
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
		tankcon           = unitTypes.CONSTRUCTOR,
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

return factoryUnitPosDef

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
