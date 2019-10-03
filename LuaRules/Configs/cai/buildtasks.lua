--[[
defenceQuota = how much of each level of defence the unit wants
	defence demand in an area is additive

minFacCount = min other facs that must exist for factory to be built
minTime = not used yet
	
factory job indexes:
	1 = con
	2 = scout
	3 = raider
	4 = arty
	5 = assault
	6 = skirm
	7 = riot
	8 = AA
	
	1 = con
	2 = scout
	3 = fighterheavy
	4 = bomber
	5 = gunship
--]]

factionBuildConfig = {
	robots = {
		airDefenceRange = {
			[1] = 600,
			[2] = 800,
			[3] = 700,
		},

		factoryIds = {
			count = 7,
			[1] = {ID = UnitDefNames['factoryveh'].id},
			[2] = {ID = UnitDefNames['factorytank'].id},
			[3] = {ID = UnitDefNames['factoryhover'].id},
			[4] = {ID = UnitDefNames['factorycloak'].id},
			[5] = {ID = UnitDefNames['factoryshield'].id},
			[6] = {ID = UnitDefNames['factoryspider'].id},
			[7] = {ID = UnitDefNames['factoryjump'].id},
			[8] = {ID = UnitDefNames['factoryamph'].id},
		},
		factoryByDefId = {
			[UnitDefNames['factoryveh'].id] = {
				defenceQuota = {2,0.6,0.3},
				defenceRange = 400,
				airDefenceQuota = {2,1,0.1},
				importance = 1,
				BPQuota = 70,
				minFacCount = 0,
				
				[1] = { -- con
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['vehcon'].id, chance = 1},
				},
				
				[2] = {-- scout
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['vehscout'].id, chance = 1},
				},
				
				[3] = { -- raider
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['vehraid'].id, chance = 1},
				},
				
				[4] = { -- arty
					importanceMult = 1,
					count = 2,
					[1] = {ID = UnitDefNames['veharty'].id, chance = 0.9},
					[2] = {ID = UnitDefNames['vehheavyarty'].id, chance = 0.1},
				},
				
				[5] = { --assault
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['vehassault'].id, chance = 1},
				},
				
				[6] = { -- skirm
					importanceMult = 0.3,
					count = 1,
					[1] = {ID = UnitDefNames['vehsupport'].id, chance = 1},
				},
				
				[7] = { -- riot
					importanceMult = 1.2,
					count = 2,
					[1] = {ID = UnitDefNames['vehsupport'].id, chance = 0.25},
					[2] = {ID = UnitDefNames['vehriot'].id, chance = 0.75},
				},
				
				[8] = { -- aa
					importanceMult = 0.4,
					count = 1,
					[1] = {ID = UnitDefNames['vehsupport'].id, chance = 1},
				},
			},
			[UnitDefNames['factoryjump'].id] = {
				defenceQuota = {2,0.6,0.3},
				defenceRange = 400,
				airDefenceQuota = {2,1,0.1},
				importance = 0.8,
				BPQuota = 70,
				minFacCount = 1,
				
				[1] = { -- con
					importanceMult = 0.8,
					count = 1,
					[1] = {ID = UnitDefNames['jumpcon'].id, chance = 1},
				},
				
				[2] = { -- scout
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['jumpscout'].id, chance = 1},
				},
				
				[3] = { -- raider
					importanceMult = 1,
					count = 2,
					[1] = {ID = UnitDefNames['jumpscout'].id, chance = 0.6},
					[2] = {ID = UnitDefNames['jumpraid'].id, chance = 0.4},
				},
				
				[4] = { -- arty
					importanceMult = 0.3,
					count = 1,
					[1] = {ID = UnitDefNames['jumparty'].id, chance = 1},
				},
				
				[5] = { --assault
					importanceMult = 1,
					count = 2,
					[1] = {ID = UnitDefNames['jumpassault'].id, chance = 1},
					--[2] = {ID = UnitDefNames['jumpsumo'].id, chance = 0},
				},
				
				[6] = { -- skirm
					importanceMult = 0.6,
					count = 1,
					[1] = {ID = UnitDefNames['jumpskirm'].id, chance = 1},
				},
				
				[7] = { -- riot
					importanceMult = 1,
					count = 2,
					[1] = {ID = UnitDefNames['jumpassault'].id, chance = 0.9},
					[2] = {ID = UnitDefNames['jumpsumo'].id, chance = 0.1},
				},
				
				[8] = { -- aa
					importanceMult = 0.8,
					count = 1,
					[1] = {ID = UnitDefNames['jumpaa'].id, chance = 1},
				},
			},
			[UnitDefNames['factoryspider'].id] = {
				defenceQuota = {2,0.6,0.3},
				defenceRange = 400,
				airDefenceQuota = {2,1,0.1},
				importance = 1,
				BPQuota = 70,
				minFacCount = 0,
				
				[1] = { -- con
					importanceMult = 0.9,
					count = 1,
					[1] = {ID = UnitDefNames['spidercon'].id, chance = 1},
				},
				
				[2] = { -- scout
					importanceMult = 1.2,
					count = 1,
					[1] = {ID = UnitDefNames['spiderscout'].id, chance = 1},
					--[2] = {ID = UnitDefNames['spiderantiheavy'].id, chance = 0.05},
				},
				
				[3] = { -- raider
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['spiderscout'].id, chance = 1},
				},
				
				[4] = { -- arty
					importanceMult = 0,
					count = 0,
				},
				
				[5] = { -- assault
					importanceMult = 1,
					count = 2,
					[1] = {ID = UnitDefNames['spiderassault'].id, chance = 0.95},
					[2] = {ID = UnitDefNames['spidercrabe'].id, chance = 0.05},
				},
				
				[6] = { -- skirm
					importanceMult = 1.5,
					count = 1,
					[1] = {ID = UnitDefNames['spiderskirm'].id, chance = 1},
				},
				
				[7] = { -- riot
					importanceMult = 0.5,
					count = 1,
					[1] = {ID = UnitDefNames['spideremp'].id, chance = 0.4},
					[2] = {ID = UnitDefNames['spiderriot'].id, chance = 0.6},
				},
				
				[8] = { -- aa
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['spideraa'].id, chance = 1},
				},
			},
			[UnitDefNames['factorycloak'].id] = {
				defenceQuota = {2,0.6,0.3},
				defenceRange = 400,
				airDefenceQuota = {2,1,0.1},
				importance = 1,
				BPQuota = 70,
				minFacCount = 0,
				
				[1] = { -- con
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['cloakcon'].id, chance = 1},
				},
				
				[2] = { -- scout
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['cloakraid'].id, chance = 1},
				},
				
				[3] = { -- raid
					importanceMult = 1,
					count = 2,
					[1] = {ID = UnitDefNames['cloakraid'].id, chance = 0.7},
					[2] = {ID = UnitDefNames['cloakheavyraid'].id, chance = 0.3},
				},
				
				[4] = { -- arty
					importanceMult = 1,
					count = 2,
					[1] = {ID = UnitDefNames['cloakarty'].id, chance = 0.9},
					[2] = {ID = UnitDefNames['cloaksnipe'].id, chance = 0.1},
				},
				
				[5] = { --assault
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['cloakassault'].id, chance = 1},
				},
				
				[6] = { -- skirm
					importanceMult = 1.2,
					count = 1,
					[1] = {ID = UnitDefNames['cloakskirm'].id, chance = 1},
				},
				
				[7] = { -- riot
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['cloakriot'].id, chance = 1},
				},
				
				[8] = { -- aa
					importanceMult = 1.3,
					count = 1,
					[1] = {ID = UnitDefNames['cloakaa'].id, chance = 1},
				},
			},
			[UnitDefNames['factoryshield'].id] = {
				defenceQuota = {2,0.6,0.3},
				defenceRange = 400,
				airDefenceQuota = {2,1,0.1},
				importance = 1,
				BPQuota = 70,
				minFacCount = 0,
				
				[1] = { -- con
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['shieldcon'].id, chance = 1},
				},
				
				[2] = { -- scout
					importanceMult = 2,
					count = 2,
					[1] = {ID = UnitDefNames['shieldscout'].id, chance = 0.4},
					[2] = {ID = UnitDefNames['shieldraid'].id, chance = 0.6},
				},
				
				[3] = { -- raid
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['shieldraid'].id, chance = 1},
				},
				
				[4] = { -- arty
					importanceMult = 0,
					count = 0,
				--	[1] = {ID = UnitDefNames['jumparty'].id, chance = 1},
				},
				
				[5] = { --assault
					importanceMult = 1.2,
					count = 1,
					[1] = {ID = UnitDefNames['shieldassault'].id, chance = 1},
				},
				
				[6] = { -- skirm
					importanceMult = 1.3,
					count = 1,
					[1] = {ID = UnitDefNames['shieldskirm'].id, chance = 1},
				},
				
				[7] = { -- riot
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['shieldriot'].id, chance = 1},
				},
				
				[8] = { -- aa
					importanceMult = 1.3,
					count = 1,
					[1] = {ID = UnitDefNames['shieldaa'].id, chance = 1},
				},
			},
			[UnitDefNames['factoryhover'].id] = {
				defenceQuota = {2,0.6,0.3},
				defenceRange = 400,
				airDefenceQuota = {2,1,0.1},
				importance = 1,
				BPQuota = 70,
				minFacCount = 0,
				
				[1] = { -- con
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['hovercon'].id, chance = 1},
				},
				
				[2] = { -- scout
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['hoverraid'].id, chance = 1},
				},
				
				[3] = { -- raider
					importanceMult = 1,
					count = 2,
					[1] = {ID = UnitDefNames['hoverraid'].id, chance = 0.5},
					[2] = {ID = UnitDefNames['hoverassault'].id, chance = 0.5},
				},
				
				[4] = { -- arty
					importanceMult = 0.5,
					count = 1,
					[1] = {ID = UnitDefNames['hoverarty'].id, chance = 1},
				},
				
				[5] = { --assault
					importanceMult = 1.2,
					count = 2,
					[1] = {ID = UnitDefNames['hoverassault'].id, chance = 0.65},
					[2] = {ID = UnitDefNames['hoverskirm'].id, chance = 0.35},
				},
				
				[6] = { -- skirm
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['hoverskirm'].id, chance = 1},
				},
				
				[7] = { -- riot
					importanceMult = 0.8,
					count = 1,
					[1] = {ID = UnitDefNames['hoverriot'].id, chance = 1},
				},
				
				[8] = { -- aa
					importanceMult = 0.8,
					count = 1,
					[1] = {ID = UnitDefNames['hoveraa'].id, chance = 1},
				},
			},
			[UnitDefNames['factorytank'].id] = {
				defenceQuota = {2,0.6,0.3},
				defenceRange = 400,
				airDefenceQuota = {2,1,0.1},
				importance = 1,
				BPQuota = 100,
				minFacCount = 1,
				
				[1] = { -- con
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['tankcon'].id, chance = 1},
				},
				
				[2] = { -- scout
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['tankraid'].id, chance = 1},
				},
				
				[3] = { -- raider
					importanceMult = 1,
					count = 2,
					[1] = {ID = UnitDefNames['tankraid'].id, chance = 0.3},
					[2] = {ID = UnitDefNames['tankheavyraid'].id, chance = 0.7},
				},
				
				[4] = { -- arty
					importanceMult = 1,
					count = 2,
					[1] = {ID = UnitDefNames['tankarty'].id, chance = 0.7},
					[2] = {ID = UnitDefNames['tankheavyarty'].id, chance = 0.3},
				},
				
				[5] = { --assault
					importanceMult = 1,
					count = 3,
					[1] = {ID = UnitDefNames['tankassault'].id, chance = 0.75},
					[2] = {ID = UnitDefNames['tankriot'].id, chance = 0.15},
					[3] = {ID = UnitDefNames['tankheavyassault'].id, chance = 0.1},
				},
				
				[6] = { -- skirm
					importanceMult = 0.4,
					count = 1,
					[1] = {ID = UnitDefNames['tankarty'].id, chance = 1},
				},
				
				[7] = { -- riot
					importanceMult = 0.8,
					count = 1,
					[1] = {ID = UnitDefNames['tankriot'].id, chance = 1},
				},
				
				[8] = { -- aa
					importanceMult = 0.8,
					count = 1,
					[1] = {ID = UnitDefNames['tankaa'].id, chance = 1},
				},
			},
			[UnitDefNames['factoryamph'].id] = {
				defenceQuota = {2,0.6,0.3},
				defenceRange = 400,
				airDefenceQuota = {2,1,0.1},
				importance = 0.8,
				BPQuota = 70,
				minFacCount = 0,
				
				[1] = { -- con
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['amphcon'].id, chance = 1},
				},
				
				[2] = { -- scout
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['amphraid'].id, chance = 1},
				},
				
				[3] = { -- raider
					importanceMult = 1,
					count = 2,
					[1] = {ID = UnitDefNames['amphraid'].id, chance = 0.8},
					[2] = {ID = UnitDefNames['amphimpulse'].id, chance = 0.2},
				},
				
				[4] = { -- arty
					importanceMult = 0.1,
					count = 1,
					[1] = {ID = UnitDefNames['amphassault'].id, chance = 0.7},
				},
				
				[5] = { --assault
					importanceMult = 0.7,
					count = 2,
					[1] = {ID = UnitDefNames['amphriot'].id, chance = 0.3},
					[2] = {ID = UnitDefNames['amphfloater'].id, chance = 0.7},
				},
				
				[6] = { -- skirm
					importanceMult = 1.4,
					count = 1,
					[1] = {ID = UnitDefNames['amphfloater'].id, chance = 1},
				},
				
				[7] = { -- riot
					importanceMult = 0.6,
					count = 2,
					[2] = {ID = UnitDefNames['amphimpulse'].id, chance = 0.7},
					[1] = {ID = UnitDefNames['amphriot'].id, chance = 0.3},
				},
				
				[8] = { -- aa
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['amphaa'].id, chance = 1},
				},
			},
			[UnitDefNames['factoryplane'].id] = {
				defenceQuota = {2,0.6,0.3},
				defenceRange = 400,
				airDefenceQuota = {2,1,0.1},
				airFactory = true,
				importance = 1,
				BPQuota = 70,
				minFacCount = 1,
				
				[1] = { -- con
					importanceMult = 0.8,
					count = 1,
					[1] = {ID = UnitDefNames['planecon'].id, chance = 1},
				},
				
				[2] = { -- scout
					importanceMult = 0.6,
					count = 1,
					[1] = {ID = UnitDefNames['planescout'].id, chance = 1},
				},
				
				[3] = { -- fighterheavy
					importanceMult = 1,
					count = 2,
					[1] = {ID = UnitDefNames['planefighter'].id, chance = 0.7},
					[2] = {ID = UnitDefNames['planeheavyfighter'].id, chance = 0.3},
				},
				
				[4] = { -- bomber
					importanceMult = 1,
					count = 2,
					[1] = {ID = UnitDefNames['bomberprec'].id, chance = 0.4},
					[2] = {ID = UnitDefNames['bomberriot'].id, chance = 0.6},
				},
				
				[5] = { -- gunship
					importanceMult = 0,
					count = 0,
				},
			},
			[UnitDefNames['factorygunship'].id] = {
				defenceQuota = {2,0.6,0.3},
				defenceRange = 400,
				airDefenceQuota = {2,1,0.1},
				airFactory = true,
				importance = 1,
				BPQuota = 70,
				minFacCount = 1,
				
				[1] = { -- con
					importanceMult = 0.8,
					count = 1,
					[1] = {ID = UnitDefNames['gunshipcon'].id, chance = 1},
				},
				
				[2] = { -- scout
					importanceMult = 0.6,
					count = 1,
					[1] = {ID = UnitDefNames['gunshipbomb'].id, chance = 1},
				},
				
				[3] = { -- fighterheavy
					importanceMult = 0.6,
					count = 2,
					[1] = {ID = UnitDefNames['gunshipskirm'].id, chance = 1},
				},
				
				[4] = { -- bomber
					importanceMult = 0,
					count = 0,
				},
				
				[5] = { -- gunship
					importanceMult = 1.4,
					count = 4,
					[1] = {ID = UnitDefNames['gunshipskirm'].id, chance = 0.30},
					[2] = {ID = UnitDefNames['gunshipraid'].id, chance = 0.35},
					[3] = {ID = UnitDefNames['gunshipheavyskirm'].id, chance = 0.175},
					[4] = {ID = UnitDefNames['gunshipassault'].id, chance = 0.175},
				},
			},
		},

		radarIds = {
			count = 1,
			[1] = {ID = UnitDefNames['staticradar'].id, chance = 1},
		},

		mexIds = {
			count = 1,
			[1] = {ID = UnitDefNames['staticmex'].id, chance = 1},
		},

		energyIds = {
			count = 4,
			[1] = {ID = UnitDefNames['energysingu'].id},
			[2] = {ID = UnitDefNames['energyfusion'].id},
			[3] = {ID = UnitDefNames['energysolar'].id},
			[4] = {ID = UnitDefNames['energywind'].id},
		},
		econByDefId = {
			[UnitDefNames['energyfusion'].id] = {
				energyGreaterThan = 30,
				energySpacing = 100,
				whileStall = false,
				makeNearFactory = 1800,
				chance = 0.8,
				minEtoMratio = 1.5,
				defenceQuota = {1,1,1},
				defenceRange = 600,
				airDefenceQuota = {2,1,0.1},
				index = 2,
				energy = true,
			},
			
			[UnitDefNames['energygeo'].id] = {
				energyGreaterThan = 20,
				energySpacing = 400,
				whileStall = false,
				makeNearFactory = 1800,
				chance = 0.8,
				minEtoMratio = 1.5,
				defenceQuota = {0.8,0.6,0.4},
				defenceRange = 600,
				airDefenceQuota = {1.5,0.8,0.1},
				index = 2,
				energy = true,
			},
			
			[UnitDefNames['energysingu'].id] = {
				energyGreaterThan = 120,
				energySpacing = 600,
				whileStall = false,
				makeNearFactory = 1800,
				chance = 0.3,
				minEtoMratio = 1.5,
				defenceQuota = {3,2,2},
				defenceRange = 800,
				airDefenceQuota = {3,2,1},
				index = 4,
				energy = true,
			},
			
			[UnitDefNames['energyheavygeo'].id] = {
				energyGreaterThan = 120,
				energySpacing = 900,
				whileStall = false,
				makeNearFactory = false,
				chance = 0.3,
				minEtoMratio = 1.5,
				defenceQuota = {3,2,2},
				defenceRange = 800,
				airDefenceQuota = {3,2,1},
				index = 4,
				energy = true,
			},
			
			[UnitDefNames['energysolar'].id] = {
				energyGreaterThan = 0,
				whileStall = true,
				makeNearFactory = false,
				energySpacing = 0,
				chance = 0.6,
				minEtoMratio = 0,
				defenceQuota = {0.5,0.3,0.07},
				defenceRange = 200,
				airDefenceQuota = {0,0.3,0.1},
				index = 2,
				energy = true,
			},
			
			[UnitDefNames['energywind'].id] = {
				energyGreaterThan = 0,
				whileStall = true,
				makeNearFactory = false,
				energySpacing = 60,
				chance = 1,
				minEtoMratio = 0,
				defenceQuota = {0.3,0.15,0.03},
				defenceRange = 200,
				airDefenceQuota = {0,0.2,0},
				index = 2,
				energy = true,
			},
			
			[UnitDefNames['staticmex'].id] = {
				defenceQuota = {1,0.4,0.15},
				defenceRange = 100,
				airDefenceQuota = {0,0,0},
				index = 1,
				energy = false,
			}
		},

		defenceIdCount = 3,
		airDefenceIdCount = 3,
		defenceIds = {
			[1] = {
				count = 2,
				[1] = {ID = UnitDefNames['turretlaser'].id, chance = 0.4},
				[2] = {ID = UnitDefNames['turretmissile'].id, chance = 0.6},
			},
			
			[2] = {
				count = 3,
				[1] = {ID = UnitDefNames['turretriot'].id, chance = 0.55},
				[2] = {ID = UnitDefNames['turretemp'].id, chance = 0.45},
				--[3] = {ID = UnitDefNames['turretimpulse'].id, chance = 0},
			},
			
			[3] = {
				count = 1,
				[1] = {ID = UnitDefNames['turretheavylaser'].id, chance = 1},
			},
			
		},

		defenceByDefId = {
			[UnitDefNames['turretlaser'].id] = {
				level = 1,
				index = 1,
			},
			[UnitDefNames['turretmissile'].id] = {
				level = 1,
				index = 2,
			},
			[UnitDefNames['turretriot'].id] = {
				level = 2,
				index = 1,
			},
			[UnitDefNames['turretemp'].id] = {
				level = 2,
				index = 2,
			},
			[UnitDefNames['turretimpulse'].id] = {
				level = 2,
				index = 3,
			},
			[UnitDefNames['turretheavylaser'].id] = {
				level = 3,
				index = 1,
			},
		},

		airDefenceIds = {
			[1] = {
				count = 1,
				[1] = {ID = UnitDefNames['turretmissile'].id, chance = 1},
			},
			
			[2] = {
				count = 2,
				[1] = {ID = UnitDefNames['turretaalaser'].id, chance = 0.7},
				[2] = {ID = UnitDefNames['turretaaclose'].id, chance = 0.3},
			},
			
			[3] = {
				count = 2,
				[1] = {ID = UnitDefNames['turretaafar'].id, chance = 0.7},
				[2] = {ID = UnitDefNames['turretaaflak'].id, chance = 0.3},
			},
		},

		airDefenceByDefId = {
			[UnitDefNames['turretmissile'].id] = {
				level = 1,
				index = 1,
			},
			[UnitDefNames['turretaalaser'].id] = {
				level = 2,
				index = 1,
			},
			[UnitDefNames['turretaaclose'].id] = {
				level = 2,
				index = 2,
			},
			[UnitDefNames['turretaafar'].id] = {
				level = 3,
				index = 1,
			},
			[UnitDefNames['turretaaflak'].id] = {
				level = 3,
				index = 2,
			},
		},

		airpadDefID = UnitDefNames['staticrearm'].id,
		nanoDefID = UnitDefNames['staticcon'].id,
		metalStoreDefID = UnitDefNames['staticstorage'].id,
	}
}
