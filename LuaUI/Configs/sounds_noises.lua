-- needs select[1] and ok[1] (and build for cons)

local volumeOverrides = {
	heavy_bot_move = 0.36,
	bot_select = 0.42,
}

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
			volume = 0.72,
			[1] = "light_gunship_select",
		},
	},
	turrettorp = {
		ok = {
			volume = 0.9,
			[1] = "turret_move",
		},
		select = {
			volume = 0.72,
			[1] = "light_turret_select",
		},
	},
	corcom = {
		build = { "builder_start" },
		ok = {
			volume = 0.58,
			[1] = "heavy_bot_move",
		},
		select = {
			volume = 0.5,
			[1] = "bot_select",
		},
	},
	armcom = {
		build = { "builder_start" },
		ok = {
			volume = 0.58,
			[1] = "heavy_bot_move",
		},
		select = {
			volume = 0.5,
			[1] = "bot_select",
		},
	},
	commsupport = {
		build = { "builder_start" },
		ok = {
			volume = 0.58,
			[1] = "heavy_bot_move",
		},
		select = {
			volume = 0.5,
			[1] = "bot_select",
		},
	},
	commrecon = {
		build = { "builder_start" },
		ok = {
			volume = 0.58,
			[1] = "heavy_bot_move",
		},
		select = {
			volume = 0.5,
			[1] = "bot_select",
		},
	},
	striderantiheavy = {
		build = { "builder_start" },
		ok = {
			volume = 0.58,
			[1] = "heavy_bot_move",
		},
		select = {
			volume = 0.5,
			[1] = "bot_select",
		},
	},
	
	-- Spider
	spidercon = {
		build = { "builder_start" },
		ok = {
			volume = 0.85,
			[1] = "spider_move",
		},
		select = {
			volume = 0.9,
			[1] = "spider_select2",
		},
	},
	spiderassault = {
		ok = {
			volume = 0.85,
			[1] = "spider_move",
		},
		select = {
			volume = 0.6,
			[1] = "spider_select",
		},
	},
	spiderscout = {
		ok = {
			[1] = "light_bot_move",
		},
		select = {
			volume = 0.75,
			[1] = "crawlie_select",
		},
	},
	spiderskirm = {
		ok = {
			volume = 0.85,
			[1] = "spider_move",
		},
		select = {
			volume = 0.6,
			[1] = "spider_select",
		},
	},
	spiderriot = {
		ok = {
			volume = 0.85,
			[1] = "spider_move",
		},
		select = {
			volume = 0.6,
			[1] = "spider_select",
		},
	},
	spideremp = {
		ok = {
			volume = 0.85,
			[1] = "spider_move",
		},
		select = {
			volume = 0.6,
			[1] = "spider_select",
		},
	},
	spideraa = {
		ok = {
			volume = 0.85,
			[1] = "spider_move",
		},
		select = {
			volume = 0.6,
			[1] = "spider_select",
		},
	},

	spidercrabe = {
		ok = {
			volume = 0.58,
			[1] = "heavy_bot_move",
		},
		select = {
			volume = 0.5,
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
			volume = 0.6,
			[1] = "bot_move",
		},
		select = {
			[1] = "light_bot_select2",
		},
	},
	shieldscout = {
		ok = {
			volume = 0.6,
			[1] = "bot_move",
		},
		select = {
			volume = 0.5,
			[1] = "bot_select",
		},
	},
	shieldraid = {
		ok = {
			volume = 0.6,
			[1] = "bot_move",
		},
		select = {
			volume = 0.5,
			[1] = "bot_select",
		},
	},
	shieldskirm = {
		ok = {
			volume = 0.6,
			[1] = "bot_move",
		},
		select = {
			volume = 0.5,
			[1] = "bot_select",
		},
	},
	shieldassault = {
		ok = {
			volume = 0.6,
			[1] = "bot_move",
		},
		select = {
			volume = 0.5,
			[1] = "bot_select",
		},
	},
	shieldbomb = {
		ok = {
			[1] = "light_bot_move",
		},
		select = {
			volume = 0.75,
			[1] = "crawlie_select",
		},
	},
	shieldriot = {
		ok = {
			volume = 0.6,
			[1] = "bot_move",
		},
		select = {
			volume = 0.5,
			[1] = "bot_select",
		},
	},
	shieldaa = {
		ok = {
			volume = 0.6,
			[1] = "bot_move",
		},
		select = {
			volume = 0.5,
			[1] = "bot_select",
		},
	},
	shieldarty = {
		ok = {
			volume = 0.6,
			[1] = "bot_move",
		},
		select = {
			volume = 0.5,
			[1] = "bot_select",
		},
	},
    shieldfelon = {
		ok = {
			volume = 0.58,
			[1] = "heavy_bot_move",
		},
		select = {
			volume = 0.5,
			[1] = "bot_select",
		},
	},
	
	-- Jumper
	jumpcon = {
		build = { "builder_start" },
		ok = {
			volume = 0.6,
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
			volume = 0.75,
			[1] = "crawlie_select",
		},
	},
	jumpskirm = {
		ok = {
			volume = 0.6,
			[1] = "bot_move",
		},
		select = {
			volume = 0.5,
			[1] = "bot_select",
		},
	},
	jumpsumo = {
		ok = {
			volume = 0.58,
			[1] = "heavy_bot_move",
		},
		select = {
			volume = 0.5,
			[1] = "bot_select",
		},
	},
	jumparty = {
		ok = {
			volume = 0.58,
			[1] = "heavy_bot_move",
		},
		select = {
			volume = 0.5,
			[1] = "bot_select",
		},
	},
	jumpraid = {
		ok = {
			volume = 0.6,
			[1] = "bot_move",
		},
		select = {
			volume = 0.5,
			[1] = "bot_select",
		},
	},
	jumpblackhole = {
		ok = {
			volume = 0.6,
			[1] = "bot_move",
		},
		select = {
			volume = 0.5,
			[1] = "bot_select",
		},
	},
	jumpimpulse = {
		ok = {
			volume = 0.6,
			[1] = "bot_move",
		},
		select = {
			volume = 0.5,
			[1] = "bot_select",
		},
	},
	jumpassault = {
		ok = {
			volume = 0.6,
			[1] = "bot_move",
		},
		select = {
			volume = 0.5,
			[1] = "bot_select",
		},
	},
	jumpaa = {
		ok = {
			volume = 0.6,
			[1] = "bot_move",
		},
		select = {
			volume = 0.5,
			[1] = "bot_select",
		},
	},
	jumpbomb = {
		ok = {
			[1] = "light_bot_move",
		},
		select = {
			volume = 0.75,
			[1] = "crawlie_select",
		},
	},
	
	-- Cloak
	cloakcon = {
		build = { "builder_start" },
		ok = {
			volume = 0.6,
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
			volume = 0.6,
			[1] = "bot_move",
		},
		select = {
			[1] = "medium_bot_select",
		},
	},
	cloakassault = {
		ok = {
			volume = 0.6,
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
			volume = 0.75,
			[1] = "crawlie_select",
		},
	},
	cloakriot = {
		ok = {
			volume = 0.6,
			[1] = "bot_move",
		},
		select = {
			[1] = "medium_bot_select",
		},
	},
	cloakarty = {
		ok = {
			volume = 0.6,
			[1] = "bot_move",
		},
		select = {
			[1] = "medium_bot_select",
		},
	},
	cloakaa = {
		ok = {
			volume = 0.6,
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
	amphsupport = {
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
			volume = 0.75,
			[1] = "crawlie_select",
		},
	},
	
	-- Mech
	striderdante = {
		ok = {
			volume = 0.58,
			[1] = "heavy_bot_move",
		},
		select = {
			volume = 0.58,
			[1] = "heavy_bot_move",
		},
	},
	striderfunnelweb = {
		ok = {
			volume = 0.58,
			[1] = "heavy_bot_move",
		},
		select = {
			volume = 0.6,
			[1] = "shield_select",
		},
	},
	striderbantha = {
		ok = {
			volume = 0.36,
			[1] = "turret_select",
		},
		select = {
			volume = 0.36,
			[1] = "turret_select",
		},
	},
	striderarty = {
		ok = {
			volume = 0.58,
			[1] = "heavy_bot_move",
		},
		select = {
			volume = 0.58,
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
			volume = 0.36,
			[1] = "turret_select",
		},
		select = {
			volume = 0.36,
			[1] = "turret_select",
		},
	},
	nebula = {
		ok = {
			[1] = "gunship_move",
		},
		select = {
			volume = 0.36,
			[1] = "heavy_gunship_select",
		},
	},
	
	-- Vehicle
	vehcon = {
		build = { "builder_start" },
		ok = {
			volume = 0.54,
			[1] = "vehicle_move",
		},
		select = {
			volume = 1,
			[1] = "vehicle_select2",
		},
	},
	vehscout = {
		ok = {
			volume = 0.54,
			[1] = "vehicle_move",
		},
		select = {
			volume = 1,
			[1] = "vehicle_select2",
		},
	},
	vehsupport = {
		ok = {
			volume = 0.54,
			[1] = "vehicle_move",
		},
		select = {
			volume = 1,
			[1] = "vehicle_select2",
		},
	},
	vehraid = {
		ok = {
			volume = 0.54,
			[1] = "vehicle_move",
		},
		select = {
			volume = 1,
			[1] = "vehicle_select2",
		},
	},
	veharty = {
		ok = {
			volume = 0.54,
			[1] = "vehicle_move",
		},
		select = {
			volume = 1,
			[1] = "vehicle_select2",
		},
	},
	vehriot = {
		ok = {
			volume = 0.54,
			[1] = "vehicle_move",
		},
		select = {
			volume = 1,
			[1] = "vehicle_select2",
		},
	},
	vehassault = {
		ok = {
			volume = 0.54,
			[1] = "vehicle_move",
		},
		select = {
			volume = 1,
			[1] = "vehicle_select2",
		},
	},
	vehcapture = {
		ok = {
			volume = 0.54,
			[1] = "vehicle_move",
		},
		select = {
			volume = 1,
			[1] = "vehicle_select2",
		},
	},
	vehaa = {
		ok = {
			volume = 0.54,
			[1] = "vehicle_move",
		},
		select = {
			volume = 1,
			[1] = "vehicle_select2",
		},
	},
	
	-- Tank
	tankcon = {
		build = { "builder_start" },
		ok = {
			volume = 0.56,
			[1] = "light_tank_move2",
		},
		select = {
			volume = 0.62,
			[1] = "tank_select",
		},
	},
	tankheavyraid = {
		ok = {
			volume = 0.56,
			[1] = "light_tank_move2",
		},
		select = {
			volume = 0.62,
			[1] = "tank_select",
		},
	},
	tankraid = {
		ok = {
			volume = 0.56,
			[1] = "light_tank_move2",
		},
		select = {
			volume = 0.62,
			[1] = "tank_select",
		},
	},
	tankarty = {
		ok = {
			volume = 0.52,
			[1] = "tank_move",
		},
		select = {
			volume = 0.62,
			[1] = "tank_select",
		},
	},
	tankassault = {
		ok = {
			volume = 0.52,
			[1] = "tank_move",
		},
		select = {
			volume = 0.62,
			[1] = "tank_select",
		},
	},
	vehheavyarty = {
		ok = {
			volume = 0.52,
			[1] = "tank_move",
		},
		select = {
			volume = 0.62,
			[1] = "tank_select",
		},
	},
	tankheavyarty = {
		ok = {
			volume = 0.52,
			[1] = "tank_move",
		},
		select = {
			volume = 0.62,
			[1] = "tank_select",
		},
	},
	tankriot = {
		ok = {
			volume = 0.52,
			[1] = "tank_move",
		},
		select = {
			volume = 0.62,
			[1] = "tank_select",
		},
	},
	tankheavyassault = {
		ok = {
			volume = 0.52,
			[1] = "tank_move",
		},
		select = {
			volume = 0.62,
			[1] = "tank_select",
		},
	},
	tankaa = {
		ok = {
			volume = 0.52,
			[1] = "tank_move",
		},
		select = {
			volume = 0.62,
			[1] = "tank_select",
		},
	},
	
	-- Hovercraft
	hovercon = {
		build = { "builder_start" },
		ok = {
			volume = 0.9,
			[1] = "hovercraft_move",
		},
		select = {
			[1] = "hovercraft_select",
		},
	},
	hoverraid = {
		ok = {
			volume = 0.9,
			[1] = "hovercraft_move",
		},
		select = {
			[1] = "hovercraft_select",
		},
	},
	hoverheavyraid = {
		ok = {
			volume = 0.9,
			[1] = "hovercraft_move",
		},
		select = {
			[1] = "hovercraft_select",
		},
	},
	hoverskirm = {
		ok = {
			volume = 0.9,
			[1] = "hovercraft_move",
		},
		select = {
			[1] = "hovercraft_select",
		},
	},
	hoverassault = {
		ok = {
			volume = 0.9,
			[1] = "hovercraft_move",
		},
		select = {
			[1] = "hovercraft_select",
		},
	},
	hoverdepthcharge = {
		ok = {
			volume = 0.9,
			[1] = "hovercraft_move",
		},
		select = {
			[1] = "hovercraft_select",
		},
	},
	hoverriot = {
		ok = {
			volume = 0.9,
			[1] = "hovercraft_move",
		},
		select = {
			[1] = "hovercraft_select",
		},
	},
	hoverarty = {
		ok = {
			volume = 0.9,
			[1] = "hovercraft_move",
		},
		select = {
			[1] = "hovercraft_select",
		},
	},
	hoveraa = {
		ok = {
			volume = 0.9,
			[1] = "hovercraft_move",
		},
		select = {
			[1] = "hovercraft_select",
		},
	},
	
	-- Fixed wing
	planefighter = {
		ok = {
			volume = 0.7,
			[1] = "fighter_move",
		},
		select = {
			volume = 0.6,
			[1] = "fighter_select",
		},
	},
	planeheavyfighter = {
		ok = {
			volume = 0.7,
			[1] = "fighter_move",
		},
		select = {
			volume = 0.6,
			[1] = "fighter_select",
		},
	},
	bomberprec = {
		ok = {
			volume = 0.72,
			[1] = "bomber_move",
		},
		select = {
			volume = 1.1,
			[1] = "bomber_select",
		},
	},
	bomberriot = {
		ok = {
			volume = 0.72,
			[1] = "bomber_move",
		},
		select = {
			volume = 1.1,
			[1] = "bomber_select",
		},
	},
	bomberdisarm = {
		ok = {
			volume = 0.72,
			[1] = "bomber_move",
		},
		select = {
			volume = 1.1,
			[1] = "bomber_select",
		},
	},
	bomberheavy = {
		ok = {
			volume = 0.72,
			[1] = "bomber_move",
		},
		select = {
			volume = 1.1,
			[1] = "bomber_select",
		},
	},
	planescout = {
		ok = {
			volume = 0.72,
			[1] = "bomber_move",
		},
		select = {
			volume = 1.1,
			[1] = "bomber_select",
		},
	},
	planelightscout = {
		ok = {
			volume = 0.7,
			[1] = "fighter_move",
		},
		select = {
			volume = 0.6,
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
			volume = 0.72,
			[1] = "light_gunship_select",
		},
	},
	gunshipcon = {
		build = { "builder_start" },
		ok = {
			[1] = "gunship_move",
		},
		select = {
			volume = 0.72,
			[1] = "light_gunship_select",
		},
	},
	gunshipemp = {
		ok = {
			[1] = "gunship_move",
		},
		select = {
			volume = 0.72,
			[1] = "light_gunship_select",
		},
	},
	gunshipbomb = {
		ok = {
			[1] = "gunship_move",
		},
		select = {
			volume = 0.72,
			[1] = "light_gunship_select",
		},
	},
	gunshipraid = {
		ok = {
			[1] = "gunship_move",
		},
		select = {
			volume = 0.7,
			[1] = "gunship_select",
		},
	},
	gunshipaa = {
		ok = {
			[1] = "gunship_move",
		},
		select = {
			volume = 0.7,
			[1] = "gunship_select",
		},
	},
	gunshipskirm = {
		ok = {
			[1] = "gunship_move",
		},
		select = {
			volume = 0.7,
			[1] = "gunship_select",
		},
	},
	gunshipheavyskirm = {
		ok = {
			[1] = "heavy_gunship_move",
		},
		select = {
			volume = 0.36,
			[1] = "heavy_gunship_select",
		},
	},
	gunshipassault = {
		ok = {
			[1] = "heavy_gunship_move",
		},
		select = {
			volume = 0.36,
			[1] = "heavy_gunship_select",
		},
	},
	gunshipkrow = {
		ok = {
			[1] = "gunship_move",
		},
		select = {
			volume = 0.36,
			[1] = "heavy_gunship_select",
		},
	},
	gunshiptrans = {
		ok = {
			[1] = "gunship_move",
		},
		select = {
			volume = 0.7,
			[1] = "gunship_select",
		},
	},
	gunshipheavytrans = {
		ok = {
			[1] = "gunship_move",
		},
		select = {
			volume = 0.36,
			[1] = "heavy_gunship_select",
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
			volume = 0.8,
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
			volume = 0.8,
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
			volume = 0.7,
			[1] = "building_select2",
		},
	},
	energywind = {
		select = {
			volume = 0.75,
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
			volume = 0.52,
			[1] = "fusion_select",
		},
	},
	energypylon = {
		select = {
			volume = 0.52,
			[1] = "fusion_select",
		},
	},
	energysingu = {
		select = {
			volume = 0.5,
			[1] = "adv_fusion_select",
		},
	},
	energygeo = {
		select = {
			volume = 0.6,
			[1] = "geo_select",
		},
	},
	energyheavygeo = {
		select = {
			volume = 0.6,
			[1] = "geo_select",
		},
	},
	staticstorage = {
		select = {
			volume = 0.7,
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
			volume = 0.5,
			[1] = "factory_select",
		},
	},
	factoryshield = {
		build = { "builder_start" },
		select = {
			volume = 0.5,
			[1] = "factory_select",
		},
	},
	factoryjump = {
		build = { "builder_start" },
		select = {
			volume = 0.5,
			[1] = "factory_select",
		},
	},
	factoryspider = {
		build = { "builder_start" },
		select = {
			volume = 0.5,
			[1] = "factory_select",
		},
	},
	factoryamph = {
		build = { "builder_start" },
		select = {
			volume = 0.5,
			[1] = "factory_select",
		},
	},
	factoryveh = {
		build = { "builder_start" },
		select = {
			volume = 0.5,
			[1] = "factory_select",
		},
	},
	factorytank = {
		build = { "builder_start" },
		select = {
			volume = 0.5,
			[1] = "factory_select",
		},
	},
	factoryhover = {
		build = { "builder_start" },
		select = {
			volume = 0.5,
			[1] = "factory_select",
		},
	},
	factoryplane = {
		build = { "builder_start" },
		select = {
			volume = 0.5,
			[1] = "factory_select",
		},
	},
	factorygunship = {
		build = { "builder_start" },
		select = {
			volume = 0.5,
			[1] = "factory_select",
		},
	},
	factoryship = {
		build = { "builder_start" },
		select = {
			volume = 0.5,
			[1] = "factory_select",
		},
	},
	
	-- plates
	platecloak = {
		build = { "builder_start" },
		select = {
			volume = 0.5,
			[1] = "factory_select",
		},
	},
	plateshield = {
		build = { "builder_start" },
		select = {
			volume = 0.5,
			[1] = "factory_select",
		},
	},
	platejump = {
		build = { "builder_start" },
		select = {
			volume = 0.5,
			[1] = "factory_select",
		},
	},
	platespider = {
		build = { "builder_start" },
		select = {
			volume = 0.5,
			[1] = "factory_select",
		},
	},
	plateamph = {
		build = { "builder_start" },
		select = {
			volume = 0.5,
			[1] = "factory_select",
		},
	},
	plateveh = {
		build = { "builder_start" },
		select = {
			volume = 0.5,
			[1] = "factory_select",
		},
	},
	platetank = {
		build = { "builder_start" },
		select = {
			volume = 0.5,
			[1] = "factory_select",
		},
	},
	platehover = {
		build = { "builder_start" },
		select = {
			volume = 0.5,
			[1] = "factory_select",
		},
	},
	plateplane = {
		build = { "builder_start" },
		select = {
			volume = 0.5,
			[1] = "factory_select",
		},
	},
	plategunship = {
		build = { "builder_start" },
		select = {
			volume = 0.5,
			[1] = "factory_select",
		},
	},
	plateship = {
		build = { "builder_start" },
		select = {
			volume = 0.5,
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
		ok = {
			volume = 0.9,
			[1] = "turret_move",
		},
		select = {
			volume = 0.3,
			[1] = "radar_select",
		},
	},
	staticheavyradar = {
		ok = {
			volume = 0.9,
			[1] = "turret_move",
		},
		select = {
			volume = 0.3,
			[1] = "radar_select",
		},
	},
	
	shieldshield = {
		ok = {
			volume = 0.6,
			[1] = "bot_move",
		},
		select = {
			volume = 0.6,
			[1] = "shield_select",
		},
	},
	staticshield = {
		ok = {
			volume = 0.9,
			[1] = "turret_move",
		},
		select = {
			volume = 0.6,
			[1] = "shield_select",
		},
	},
	staticjammer = {
		ok = {
			volume = 0.9,
			[1] = "turret_move",
		},
		select = {
			volume = 0.7,
			[1] = "cloaker_select",
		},
	},
	cloakjammer = {
		ok = {
			volume = 0.6,
			[1] = "bot_move",
		},
		select = {
			volume = 0.7,
			[1] = "cloaker_select",
		},
	},
	
	-- Land Turrets
	turretlaser = {
		ok = {
			volume = 0.9,
			[1] = "turret_move",
		},
		select = {
			volume = 0.72,
			[1] = "light_turret_select",
		},
	},
	turretimpulse = {
		ok = {
			volume = 0.9,
			[1] = "turret_move",
		},
		select = {
			volume = 0.72,
			[1] = "light_turret_select",
		},
	},
	turretemp = {
		ok = {
			volume = 0.9,
			[1] = "turret_move",
		},
		select = {
			[1] = "faraday_select",
		},
	},
	turretriot = {
		ok = {
			volume = 0.9,
			[1] = "turret_move",
		},
		select = {
			volume = 0.72,
			[1] = "light_turret_select",
		},
	},
	turretheavylaser = {
		ok = {
			volume = 0.72,
			[1] = "light_turret_select",
		},
		select = {
			volume = 0.36,
			[1] = "turret_select",
		},
	},
	turretgauss = {
		ok = {
			volume = 0.72,
			[1] = "light_turret_select",
		},
		select = {
			volume = 0.36,
			[1] = "turret_select",
		},
	},
	turretantiheavy = {
		ok = {
			volume = 0.72,
			[1] = "light_turret_select",
		},
		select = {
			volume = 0.36,
			[1] = "turret_select",
		},
	},
	turretheavy = {
		ok = {
			volume = 0.36,
			[1] = "turret_select",
		},
		select = {
			volume = 0.36,
			[1] = "turret_select",
		},
	},
	turretsunlance = {
		ok = {
			volume = 0.36,
			[1] = "turret_select",
		},
		select = {
			volume = 0.36,
			[1] = "turret_select",
		},
	},
	staticheavyarty = {
		ok = {
			volume = 0.36,
			[1] = "turret_select",
		},
		select = {
			volume = 0.36,
			[1] = "turret_select",
		},
	},
	staticarty = {
		ok = {
			volume = 0.36,
			[1] = "turret_select",
		},
		select = {
			volume = 0.36,
			[1] = "turret_select",
		},
	},
	mahlazer = {
		ok = {
			volume = 0.78,
			[1] = "silo_select",
		},
		select = {
			volume = 0.78,
			[1] = "silo_select",
		},
	},
	zenith = {
		ok = {
			volume = 0.78,
			[1] = "silo_select",
		},
		select = {
			volume = 0.78,
			[1] = "silo_select",
		},
	},
	raveparty = {
		ok = {
			volume = 0.78,
			[1] = "silo_select",
		},
		select = {
			volume = 0.78,
			[1] = "silo_select",
		},
	},
	
	-- Air Turrets
	turretmissile = {
		ok = {
			volume = 0.9,
			[1] = "turret_move",
		},
		select = {
			volume = 0.72,
			[1] = "light_turret_select",
		},
	},
	turretaaclose = {
		ok = {
			volume = 0.9,
			[1] = "turret_move",
		},
		select = {
			volume = 0.72,
			[1] = "light_turret_select",
		},
	},
    turretaalaser = {
		ok = {
			volume = 0.9,
			[1] = "turret_move",
		},
		select = {
			volume = 0.72,
			[1] = "light_turret_select",
		},
	},
	turretaafar = {
		ok = {
			volume = 0.72,
			[1] = "light_turret_select",
		},
		select = {
			volume = 0.36,
			[1] = "turret_select",
		},
	},
	turretaaflak = {
		ok = {
			volume = 0.72,
			[1] = "light_turret_select",
		},
		select = {
			volume = 0.36,
			[1] = "turret_select",
		},
	},
	turretaaheavy = {
		ok = {
			volume = 0.36,
			[1] = "turret_select",
		},
		select = {
			volume = 0.78,
			[1] = "silo_select",
		},
	},
	
	-- Silo etc
	staticmissilesilo = {
		build = { "builder_start" },
		select = {
			volume = 0.78,
			[1] = "silo_select",
		},
	},
	tacnuke = {
		ok = {
			volume = 0.36,
			[1] = "turret_select",
		},
		select = {
			volume = 0.78,
			[1] = "silo_select",
		},
	},
	empmissile = {
		ok = {
			volume = 0.36,
			[1] = "turret_select",
		},
		select = {
			volume = 0.78,
			[1] = "silo_select",
		},
	},
	seismic = {
		ok = {
			volume = 0.36,
			[1] = "turret_select",
		},
		select = {
			volume = 0.78,
			[1] = "silo_select",
		},
	},
	staticantinuke = {
		ok = {
			volume = 0.36,
			[1] = "turret_select",
		},
		select = {
			volume = 0.78,
			[1] = "silo_select",
		},
	},
	staticnuke = {
		select = {
			volume = 0.78,
			[1] = "silo_select",
		},
	},
	wolverine_mine = {
		ok = {
			volume = 0.9,
			[1] = "turret_move",
		},
		select = {
			volume = 0.75,
			[1] = "crawlie_select",
		},
	},
	tele_beacon = {
		ok = {
			volume = 0.9,
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
	soundDef[soundName] = {
		volume = volumeOverrides[sound] or tonumber(customParams["sound" .. soundName .. "_vol"] or 1),
		[1] = sound,
	}
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

local function OverrideVolume(def)
	if def and def[1] and volumeOverrides[def[1]] then
		def.volume = volumeOverrides[def[1]]
	end
end

local ret = {}
for udid, ud in pairs(UnitDefs) do
	local soundDef = sounds[ud.name]
	local cp = ud.customParams
	soundDef = applyCustomParamSound(soundDef, "ok"    , cp)
	soundDef = applyCustomParamSound(soundDef, "select", cp)
	soundDef = applyCustomParamSound(soundDef, "build" , cp)
	soundDef = applyCommanderSound(soundDef, cp, ud.name)
	
	if soundDef then
		OverrideVolume(soundDef.ok)
		OverrideVolume(soundDef.select)
		OverrideVolume(soundDef.build)
	end
	ret[udid] = soundDef
end

return ret
