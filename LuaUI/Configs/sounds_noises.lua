-- needs select[1] and ok[1] (and build for cons)

local sounds = {
	-- Misc
	staticrearm = {
		select = {
			[1] = "building_select1",
		},
	},
	athena = {
		build = { "builder_start" },
		ok = {
			[1] = "gunship_move",
		},
		select = {
			[1] = "light_gunship_select",
		},
	},
	turrettorp = {
		ok = {
			[1] = "turret_move",
		},
		select = {
			[1] = "light_turret_select",
		},
	},
	corcom = {
		build = { "builder_start" },
		ok = {
			[1] = "heavy_bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	armcom = {
		build = { "builder_start" },
		ok = {
			[1] = "heavy_bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	commsupport = {
		build = { "builder_start" },
		ok = {
			[1] = "heavy_bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	commrecon = {
		build = { "builder_start" },
		ok = {
			[1] = "heavy_bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	striderantiheavy = {
		build = { "builder_start" },
		ok = {
			[1] = "heavy_bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	
	-- Spider
	spidercon = {
		build = { "builder_start" },
		ok = {
			[1] = "spider_move",
			volume = 0.95,
		},
		select = {
			[1] = "spider_select2",
		},
	},
	spiderassault = {
		ok = {
			[1] = "spider_move",
			volume = 0.95,
		},
		select = {
			[1] = "spider_select",
			volume = 0.95,
		},
	},
	spiderscout = {
		ok = {
			[1] = "light_bot_move",
		},
		select = {
			[1] = "crawlie_select",
		},
	},
	spiderskirm = {
		ok = {
			[1] = "spider_move",
			volume = 0.95,
		},
		select = {
			[1] = "spider_select",
			volume = 0.95,
		},
	},
	spiderriot = {
		ok = {
			[1] = "spider_move",
			volume = 0.95,
		},
		select = {
			[1] = "spider_select",
			volume = 0.95,
		},
	},
	spideremp = {
		ok = {
			[1] = "spider_move",
			volume = 0.95,
		},
		select = {
			[1] = "spider_select",
			volume = 0.95,
		},
	},
	spideraa = {
		ok = {
			[1] = "spider_move",
			volume = 0.95,
		},
		select = {
			[1] = "spider_select",
			volume = 0.95,
		},
	},

	spidercrabe = {
		ok = {
			[1] = "heavy_bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	spiderantiheavy = {
		ok = {
			[1] = "spy_move",
		},
		select = {
			[1] = "spy_select",
		},
	},
	
	-- Shield
	shieldcon = {
		build = { "builder_start" },
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "light_bot_select2",
		},
	},
	shieldscout = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	shieldraid = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	shieldskirm = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	shieldassault = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	shieldbomb = {
		ok = {
			[1] = "light_bot_move",
		},
		select = {
			[1] = "crawlie_select",
		},
	},
	shieldriot = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	shieldaa = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	shieldarty = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
    shieldfelon = {
		ok = {
			[1] = "heavy_bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	
	-- Jumper
	jumpcon = {
		build = { "builder_start" },
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "light_bot_select2",
		},
	},
	
	jumpscout = {
		ok = {
			[1] = "light_bot_move",
		},
		select = {
			[1] = "crawlie_select",
		},
	},
	jumpskirm = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	jumpsumo = {
		ok = {
			[1] = "heavy_bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	jumparty = {
		ok = {
			[1] = "heavy_bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	jumpraid = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	jumpblackhole = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	jumpimpulse = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	jumpassault = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	jumpaa = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	jumpbomb = {
		ok = {
			[1] = "light_bot_move",
		},
		select = {
			[1] = "crawlie_select",
		},
	},
	
	-- Cloak
	cloakcon = {
		build = { "builder_start" },
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "light_bot_select2",
		},
	},
	
	cloaksnipe = {
		ok = {
			[1] = "spy_move",
		},
		select = {
			[1] = "spy_select",
		},
	},
	cloakraid = {
		ok = {
			[1] = "light_bot_move",
		},
		select = {
			[1] = "light_bot_select",
		},
	},
	cloakheavyraid = {
		ok = {
			[1] = "spy_move",
		},
		select = {
			[1] = "spy_select",
		},
	},
	cloakskirm = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "medium_bot_select",
		},
	},
	cloakassault = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "medium_bot_select",
		},
	},
	cloakbomb = {
		ok = {
			[1] = "light_bot_move",
		},
		select = {
			[1] = "crawlie_select",
		},
	},
	cloakriot = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "medium_bot_select",
		},
	},
	cloakarty = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "medium_bot_select",
		},
	},
	cloakaa = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "medium_bot_select",
		},
	},
	
	-- Amphib
	amphcon = {
		build = { "builder_start" },
		ok = {
			[1] = "amph_move",
			volume = 0.8,
		},
		select = {
			[1] = "amph_select",
			volume = 0.6,
		},
	},
	amphimpulse = {
		ok = {
			[1] = "amph_move",
			volume = 0.8,
		},
		select = {
			[1] = "amph_select",
			volume = 0.6,
		},
	},
	amphraid = {
		ok = {
			[1] = "amph_move",
			volume = 0.8,
		},
		select = {
			[1] = "amph_select",
			volume = 0.6,
		},
	},
	amphfloater = {
		ok = {
			[1] = "amph_move",
			volume = 0.8,
		},
		select = {
			[1] = "amph_select",
			volume = 0.6,
		},
	},
	amphriot = {
		ok = {
			[1] = "amph_move",
			volume = 0.8,
		},
		select = {
			[1] = "amph_select",
			volume = 0.6,
		},
	},
	amphassault = {
		ok = {
			[1] = "amph_move",
			volume = 0.8,
		},
		select = {
			[1] = "amph_select",
			volume = 0.6,
		},
	},
	amphlaunch = {
		ok = {
			[1] = "amph_move",
			volume = 0.8,
		},
		select = {
			[1] = "teleport_select",
			volume = 0.7,
		},
	},
	amphaa = {
		ok = {
			[1] = "amph_move",
			volume = 0.8,
		},
		select = {
			[1] = "amph_select",
			volume = 0.6,
		},
	},
	amphtele = {
		ok = {
			[1] = "amph_move",
			volume = 0.8,
		},
		select = {
			[1] = "teleport_select",
			volume = 0.7,
		},
	},
	amphbomb = {
		ok = {
			[1] = "light_bot_move",
		},
		select = {
			[1] = "crawlie_select",
		},
	},
	
	-- Mech
	striderdante = {
		ok = {
			[1] = "heavy_bot_move",
		},
		select = {
			[1] = "heavy_bot_move",
		},
	},
	striderfunnelweb = {
		ok = {
			[1] = "heavy_bot_move",
		},
		select = {
			[1] = "heavy_bot_move",
		},
	},
	striderbantha = {
		ok = {
			[1] = "turret_select",
			volume = 0.7,
		},
		select = {
			[1] = "turret_select",
			volume = 0.7,
		},
	},
	striderarty = {
		ok = {
			[1] = "heavy_bot_move",
		},
		select = {
			[1] = "heavy_bot_move",
		},
	},
	striderscorpion = {
		ok = {
			[1] = "spy_move",
		},
		select = {
			[1] = "spy_select",
		},
	},
	striderdetriment = {
		ok = {
			[1] = "turret_select",
			volume = 0.7,
		},
		select = {
			[1] = "turret_select",
			volume = 0.7,
		},
	},
	nebula = {
		ok = {
			[1] = "gunship_move",
		},
		select = {
			[1] = "heavy_gunship_select",
			volume = 0.8,
		},
	},
	
	-- Vehicle
	vehcon = {
		build = { "builder_start" },
		ok = {
			[1] = "vehicle_move",
		},
		select = {
			[1] = "vehicle_select2",
		},
	},
	vehscout = {
		ok = {
			[1] = "vehicle_move",
		},
		select = {
			[1] = "vehicle_select2",
		},
	},
	vehsupport = {
		ok = {
			[1] = "vehicle_move",
		},
		select = {
			[1] = "vehicle_select2",
		},
	},
	vehraid = {
		ok = {
			[1] = "vehicle_move",
		},
		select = {
			[1] = "vehicle_select2",
		},
	},
	veharty = {
		ok = {
			[1] = "vehicle_move",
		},
		select = {
			[1] = "vehicle_select2",
		},
	},
	vehriot = {
		ok = {
			[1] = "vehicle_move",
		},
		select = {
			[1] = "vehicle_select2",
		},
	},
	vehassault = {
		ok = {
			[1] = "vehicle_move",
		},
		select = {
			[1] = "vehicle_select2",
		},
	},
	vehcapture = {
		ok = {
			[1] = "vehicle_move",
		},
		select = {
			[1] = "vehicle_select2",
		},
	},
	vehaa = {
		ok = {
			[1] = "vehicle_move",
		},
		select = {
			[1] = "vehicle_select2",
		},
	},
	
	-- Tank
	tankcon = {
		build = { "builder_start" },
		ok = {
			[1] = "light_tank_move2",
		},
		select = {
			[1] = "tank_select",
		},
	},
	tankheavyraid = {
		ok = {
			[1] = "light_tank_move2",
		},
		select = {
			[1] = "tank_select",
		},
	},
	tankraid = {
		ok = {
			[1] = "light_tank_move2",
		},
		select = {
			[1] = "tank_select",
		},
	},
	tankarty = {
		ok = {
			[1] = "tank_move",
		},
		select = {
			[1] = "tank_select",
		},
	},
	tankassault = {
		ok = {
			[1] = "tank_move",
		},
		select = {
			[1] = "tank_select",
		},
	},
	vehheavyarty = {
		ok = {
			[1] = "tank_move",
		},
		select = {
			[1] = "tank_select",
		},
	},
	tankheavyarty = {
		ok = {
			[1] = "tank_move",
		},
		select = {
			[1] = "tank_select",
		},
	},
	tankriot = {
		ok = {
			[1] = "tank_move",
		},
		select = {
			[1] = "tank_select",
		},
	},
	tankheavyassault = {
		ok = {
			[1] = "tank_move",
		},
		select = {
			[1] = "tank_select",
		},
	},
	tankaa = {
		ok = {
			[1] = "tank_move",
		},
		select = {
			[1] = "tank_select",
		},
	},
	
	-- Hovercraft
	hovercon = {
		build = { "builder_start" },
		ok = {
			[1] = "hovercraft_move",
		},
		select = {
			[1] = "hovercraft_select",
		},
	},
	hoverraid = {
		ok = {
			[1] = "hovercraft_move",
		},
		select = {
			[1] = "hovercraft_select",
		},
	},
	hoverheavyraid = {
		ok = {
			[1] = "hovercraft_move",
		},
		select = {
			[1] = "hovercraft_select",
		},
	},
	hoverskirm = {
		ok = {
			[1] = "hovercraft_move",
		},
		select = {
			[1] = "hovercraft_select",
		},
	},
	hoverassault = {
		ok = {
			[1] = "hovercraft_move",
		},
		select = {
			[1] = "hovercraft_select",
		},
	},
	hoverdepthcharge = {
		ok = {
			[1] = "hovercraft_move",
		},
		select = {
			[1] = "hovercraft_select",
		},
	},
	hoverriot = {
		ok = {
			[1] = "hovercraft_move",
		},
		select = {
			[1] = "hovercraft_select",
		},
	},
	hoverarty = {
		ok = {
			[1] = "hovercraft_move",
		},
		select = {
			[1] = "hovercraft_select",
		},
	},
	hoveraa = {
		ok = {
			[1] = "hovercraft_move",
		},
		select = {
			[1] = "hovercraft_select",
		},
	},
	
	-- Fixed wing
	planefighter = {
		ok = {
			[1] = "fighter_move",
		},
		select = {
			[1] = "fighter_select",
		},
	},
	planeheavyfighter = {
		ok = {
			[1] = "fighter_move",
		},
		select = {
			[1] = "fighter_select",
		},
	},
	bomberprec = {
		ok = {
			[1] = "bomber_move",
		},
		select = {
			[1] = "bomber_select",
		},
	},
	bomberriot = {
		ok = {
			[1] = "bomber_move",
		},
		select = {
			[1] = "bomber_select",
		},
	},
	bomberdisarm = {
		ok = {
			[1] = "bomber_move",
		},
		select = {
			[1] = "bomber_select",
		},
	},
	bomberheavy = {
		ok = {
			[1] = "bomber_move",
		},
		select = {
			[1] = "bomber_select",
		},
	},
	planescout = {
		ok = {
			[1] = "bomber_move",
		},
		select = {
			[1] = "bomber_select",
		},
	},
	planelightscout = {
		ok = {
			[1] = "fighter_move",
		},
		select = {
			[1] = "fighter_select",
		},
	},
	
	-- Gunship
	planecon = {
		build = { "builder_start" },
		ok = {
			[1] = "gunship_move",
		},
		select = {
			[1] = "light_gunship_select",
		},
	},
	gunshipcon = {
		build = { "builder_start" },
		ok = {
			[1] = "gunship_move",
		},
		select = {
			[1] = "light_gunship_select",
		},
	},
	gunshipemp = {
		ok = {
			[1] = "gunship_move",
		},
		select = {
			[1] = "light_gunship_select",
		},
	},
	gunshipbomb = {
		ok = {
			[1] = "gunship_move",
		},
		select = {
			[1] = "light_gunship_select",
		},
	},
	gunshipraid = {
		ok = {
			[1] = "gunship_move",
		},
		select = {
			[1] = "gunship_select",
		},
	},
	gunshipaa = {
		ok = {
			[1] = "gunship_move",
		},
		select = {
			[1] = "gunship_select",
		},
	},
	gunshipskirm = {
		ok = {
			[1] = "gunship_move",
		},
		select = {
			[1] = "gunship_select",
		},
	},
	gunshipheavyskirm = {
		ok = {
			[1] = "heavy_gunship_move",
		},
		select = {
			[1] = "heavy_gunship_select",
			volume = 0.8,
		},
	},
	gunshipassault = {
		ok = {
			[1] = "heavy_gunship_move",
		},
		select = {
			[1] = "heavy_gunship_select",
			volume = 0.8,
		},
	},
	gunshipkrow = {
		ok = {
			[1] = "gunship_move",
		},
		select = {
			[1] = "heavy_gunship_select",
			volume = 0.8,
		},
	},
	gunshiptrans = {
		ok = {
			[1] = "gunship_move",
		},
		select = {
			[1] = "gunship_select",
		},
	},
	gunshipheavytrans = {
		ok = {
			[1] = "gunship_move",
		},
		select = {
			[1] = "heavy_gunship_select",
			volume = 0.8,
		},
	},
	
	-- Sea
	
	-- New Ships
	shipcon = {
		build = { "builder_start" },
		ok = {
			[1] = "rumble2",
			volume = 1.6,
		},
		select = {
			[1] = "rumble1",
			volume = 1.6,
		},
	},
	shipscout = {
		ok = {
			[1] = "rumble2",
			volume = 1.6,
		},
		select = {
			[1] = "rumble1",
			volume = 1.6,
		},
	},
	shiptorpraider = {
		ok = {
			[1] = "rumble2",
			volume = 1.6,
		},
		select = {
			[1] = "rumble1",
			volume = 1.6,
		},
	},
	shipriot = {
		ok = {
			[1] = "rumble2",
			volume = 1.6,
		},
		select = {
			[1] = "rumble1",
			volume = 1.6,
		},
	},
	subraider = {
		ok = {
			[1] = "rumble2",
			volume = 1.6,
		},
		select = {
			[1] = "sub_select",
			volume = 1.1,
		},
	},
	shipassault = {
		ok = {
			[1] = "rumble2",
			volume = 1.6,
		},
		select = {
			[1] = "rumble1",
			volume = 1.6,
		},
	},
	shiparty = {
		ok = {
			[1] = "rumble2",
			volume = 1.6,
		},
		select = {
			[1] = "rumble1",
			volume = 1.6,
		},
	},
	shipskirm = {
		ok = {
			[1] = "rumble2",
			volume = 1.6,
		},
		select = {
			[1] = "rumble1",
			volume = 1.6,
		},
	},
	shipheavyarty = {
		ok = {
			[1] = "rumble2",
			volume = 1.6,
		},
		select = {
			[1] = "rumble1",
			volume = 1.6,
		},
	},
	shipcarrier = {
		ok = {
			[1] = "rumble2",
			volume = 1.6,
		},
		select = {
			[1] = "rumble1",
			volume = 1.6,
		},
	},
	subtacmissile = {
		ok = {
			[1] = "rumble2",
			volume = 1.6,
		},
		select = {
			[1] = "sub_select",
			volume = 1.1,
		},
	},
	shipaa = {
		ok = {
			[1] = "rumble2",
			volume = 1.6,
		},
		select = {
			[1] = "rumble1",
			volume = 1.6,
		},
	},
	
	-- Economy
	staticmex = {
		select = {
			[1] = "building_select2",
		},
	},
	energywind = {
		select = {
			[1] = "windmill",
		},
	},
	energysolar = {
		select = {
			[1] = "building_select1",
		},
	},
	energyfusion = {
		select = {
			[1] = "fusion_select",
		},
	},
	energypylon = {
		select = {
			[1] = "fusion_select",
		},
	},
	energysingu = {
		select = {
			[1] = "adv_fusion_select",
		},
	},
	energygeo = {
		select = {
			[1] = "geo_select",
		},
	},
	energyheavygeo = {
		select = {
			[1] = "geo_select",
		},
	},
	staticstorage = {
		select = {
			[1] = "building_select2",
		},
	},
	staticcon = {
		build = { "builder_start" },
		select = {
			[1] = "building_select1",
		},
	},
    striderhub = {
		build = { "builder_start" },
		select = {
			[1] = "building_select1",
		},
	},
	
	-- Factory
	factorycloak = {
		build = { "builder_start" },
		select = {
			[1] = "factory_select",
		},
	},
	factoryshield = {
		build = { "builder_start" },
		select = {
			[1] = "factory_select",
		},
	},
	factoryjump = {
		build = { "builder_start" },
		select = {
			[1] = "factory_select",
		},
	},
	factoryspider = {
		build = { "builder_start" },
		select = {
			[1] = "factory_select",
		},
	},
	factoryamph = {
		build = { "builder_start" },
		select = {
			[1] = "factory_select",
		},
	},
	factoryveh = {
		build = { "builder_start" },
		select = {
			[1] = "factory_select",
		},
	},
	factorytank = {
		build = { "builder_start" },
		select = {
			[1] = "factory_select",
		},
	},
	factoryhover = {
		build = { "builder_start" },
		select = {
			[1] = "factory_select",
		},
	},
	factoryplane = {
		build = { "builder_start" },
		select = {
			[1] = "factory_select",
		},
	},
	factorygunship = {
		build = { "builder_start" },
		select = {
			[1] = "factory_select",
		},
	},
	factoryship = {
		build = { "builder_start" },
		select = {
			[1] = "factory_select",
		},
	},
	
	-- Intel
	staticsonar = {
		select = {
			[1] = "sonar_select",
		},
	},
	staticradar = {
		select = {
			[1] = "radar_select",
		},
	},
	staticheavyradar = {
		select = {
			[1] = "radar_select",
		},
	},
	
	shieldshield = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "shield_select",
		},
	},
	staticjammer = {
		select = {
			[1] = "cloaker_select",
		},
	},
	cloakjammer = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "cloaker_select",
		},
	},
	
	-- Land Turrets
	turretlaser = {
		ok = {
			[1] = "turret_move",
		},
		select = {
			[1] = "light_turret_select",
		},
	},
	turretimpulse = {
		ok = {
			[1] = "turret_move",
		},
		select = {
			[1] = "light_turret_select",
		},
	},
	turretemp = {
		ok = {
			[1] = "turret_move",
		},
		select = {
			[1] = "faraday_select",
		},
	},
	turretriot = {
		ok = {
			[1] = "turret_move",
		},
		select = {
			[1] = "light_turret_select",
		},
	},
	turretheavylaser = {
		ok = {
			[1] = "light_turret_select",
		},
		select = {
			[1] = "turret_select",
		},
	},
	turretgauss = {
		ok = {
			[1] = "light_turret_select",
		},
		select = {
			[1] = "turret_select",
		},
	},
	turretantiheavy = {
		ok = {
			[1] = "light_turret_select",
		},
		select = {
			[1] = "turret_select",
		},
	},
	turretheavy = {
		ok = {
			[1] = "turret_select",
		},
		select = {
			[1] = "turret_select",
		},
	},
	turretsunlance = {
		ok = {
			[1] = "turret_select",
		},
		select = {
			[1] = "turret_select",
		},
	},
	staticheavyarty = {
		ok = {
			[1] = "turret_select",
		},
		select = {
			[1] = "turret_select",
		},
	},
	staticarty = {
		ok = {
			[1] = "turret_select",
		},
		select = {
			[1] = "turret_select",
		},
	},
	mahlazer = {
		ok = {
			[1] = "silo_select",
		},
		select = {
			[1] = "silo_select",
		},
	},
	zenith = {
		ok = {
			[1] = "silo_select",
		},
		select = {
			[1] = "silo_select",
		},
	},
	raveparty = {
		ok = {
			[1] = "silo_select",
		},
		select = {
			[1] = "silo_select",
		},
	},
	
	-- Air Turrets
	turretmissile = {
		ok = {
			[1] = "turret_move",
		},
		select = {
			[1] = "light_turret_select",
		},
	},
	turretaaclose = {
		ok = {
			[1] = "turret_move",
		},
		select = {
			[1] = "light_turret_select",
		},
	},
    turretaalaser = {
		ok = {
			[1] = "turret_move",
		},
		select = {
			[1] = "light_turret_select",
		},
	},
	turretaafar = {
		ok = {
			[1] = "light_turret_select",
		},
		select = {
			[1] = "turret_select",
		},
	},
	turretaaflak = {
		ok = {
			[1] = "light_turret_select",
		},
		select = {
			[1] = "turret_select",
		},
	},
	turretaaheavy = {
		ok = {
			[1] = "turret_select",
		},
		select = {
			[1] = "silo_select",
		},
	},
	
	-- Silo etc
	staticmissilesilo = {
		build = { "builder_start" },
		select = {
			[1] = "silo_select",
		},
	},
	tacnuke = {
		ok = {
			[1] = "turret_select",
		},
		select = {
			[1] = "silo_select",
		},
	},
	empmissile = {
		ok = {
			[1] = "turret_select",
		},
		select = {
			[1] = "silo_select",
		},
	},
	seismic = {
		ok = {
			[1] = "turret_select",
		},
		select = {
			[1] = "silo_select",
		},
	},
	staticantinuke = {
		ok = {
			[1] = "turret_select",
		},
		select = {
			[1] = "silo_select",
		},
	},
	staticnuke = {
		select = {
			[1] = "silo_select",
		},
	},
	wolverine_mine = {
		ok = {
			[1] = "turret_move",
		},
		select = {
			[1] = "crawlie_select",
		},
	},
	tele_beacon = {
		ok = {
			[1] = "turret_move",
		},
		select = {
			[1] = "teleport_select",
			volume = 0.7,
		},
	},
	
}

local function applyCustomParamSound(soundDef, soundName, customParams)
	local sound = customParams["sound" .. soundName]
	if not sound then
		return soundDef
	end

	soundDef = soundDef or {}
	soundDef[soundName] = { sound }
	return soundDef
end

local commanderUnderAttack = "alarm"
local function applyCommanderSound(soundDef, customParams)
	if not customParams.commtype then
		return soundDef
	end

	soundDef = soundDef or {}
	soundDef.underattack = {[1] = commanderUnderAttack, volume = 0.8}
	soundDef.attackdelay = function(hp) return 20*hp+2 end
	soundDef.attackonscreen = true
	soundDef.volume = 0.6
	return soundDef
end

local ret = {}
for udid, ud in pairs(UnitDefs) do
	local soundDef = sounds[ud.name]
	local cp = ud.customParams
	soundDef = applyCustomParamSound(soundDef, "ok"    , cp)
	soundDef = applyCustomParamSound(soundDef, "select", cp)
	soundDef = applyCustomParamSound(soundDef, "build" , cp)
	soundDef = applyCommanderSound(soundDef, cp, ud.name)
	ret[udid] = soundDef
end

return ret
