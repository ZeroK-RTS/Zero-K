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
	3 = fighter
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
		},
		factoryByDefId = {	
			[UnitDefNames['factoryveh'].id] = {
				defenceQuota = {2,0.6,0.3},
				defenceRange = 500,
				airDefenceQuota = {2,1,0.1},
				importance = 1,
				BPQuota = 70,
				minFacCount = 0,
				
				[1] = { -- con
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['corned'].id, chance = 1},
				},
				
				[2] = {-- scout
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['corfav'].id, chance = 1},
				},
				
				[3] = { -- raider
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['corgator'].id, chance = 1},
				},
				
				[4] = { -- arty
					importanceMult = 1,
					count = 2,
					[1] = {ID = UnitDefNames['corgarp'].id, chance = 0.9},
					[2] = {ID = UnitDefNames['armmerl'].id, chance = 0.1},
				},
				
				[5] = { --assault
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['corraid'].id, chance = 1},
				},
				
				[6] = { -- skirm
					importanceMult = 0.3,
					count = 1,
					[1] = {ID = UnitDefNames['cormist'].id, chance = 1},
				},	
				
				[7] = { -- riot
					importanceMult = 1.2,
					count = 2,
					[1] = {ID = UnitDefNames['cormist'].id, chance = 0.25},
					[2] = {ID = UnitDefNames['corlevlr'].id, chance = 0.75},
				},
				
				[8] = { -- aa
					importanceMult = 0.4,
					count = 1,
					[1] = {ID = UnitDefNames['cormist'].id, chance = 1},
				},
			},
			[UnitDefNames['factoryjump'].id] = {
				defenceQuota = {2,0.6,0.3},
				defenceRange = 500,
				airDefenceQuota = {2,1,0.1},
				importance = 0.8,
				BPQuota = 70,
				minFacCount = 1,
				
				[1] = { -- con
					importanceMult = 0.8,
					count = 1,
					[1] = {ID = UnitDefNames['corfast'].id, chance = 1},
				},
				
				[2] = { -- scout
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['puppy'].id, chance = 1},
				},
				
				[3] = { -- raider
					importanceMult = 1,
					count = 2,
					[1] = {ID = UnitDefNames['puppy'].id, chance = 0.6},
					[2] = {ID = UnitDefNames['corpyro'].id, chance = 0.4},
				},
				
				[4] = { -- arty
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['punisher'].id, chance = 1},	
				},
				
				[5] = { --assault
					importanceMult = 1,
					count = 2,
					[1] = {ID = UnitDefNames['corcan'].id, chance = 0.9},
					[2] = {ID = UnitDefNames['corsumo'].id, chance = 0.1},
				},
				
				[6] = { -- skirm
					importanceMult = 0.6,
					count = 1,
					[1] = {ID = UnitDefNames['slowmort'].id, chance = 1},
				},
				
				[7] = { -- riot
					importanceMult = 1,
					count = 2,
					[1] = {ID = UnitDefNames['corcan'].id, chance = 0.9},
					[2] = {ID = UnitDefNames['corsumo'].id, chance = 0.1},
				},
				
				[8] = { -- aa
					importanceMult = 0.8,
					count = 1,
					[1] = {ID = UnitDefNames['armaak'].id, chance = 1},
				},				
			},
			[UnitDefNames['factoryspider'].id] = {
				defenceQuota = {2,0.6,0.3},
				defenceRange = 500,
				airDefenceQuota = {2,1,0.1},
				importance = 1,
				BPQuota = 70,
				minFacCount = 1,
				
				[1] = { -- con
					importanceMult = 0.9,
					count = 1,
					[1] = {ID = UnitDefNames['arm_spider'].id, chance = 1},
				},
				
				[2] = { -- scout
					importanceMult = 1.2,
					count = 2,
					[1] = {ID = UnitDefNames['armflea'].id, chance = 0.95},
					[2] = {ID = UnitDefNames['armspy'].id, chance = 0.05},
				},
				
				[3] = { -- raider
					importanceMult = 1,
					count = 2,
					[1] = {ID = UnitDefNames['armflea'].id, chance = 0.7},
					[2] = {ID = UnitDefNames['arm_venom'].id, chance = 0.3},
				},
				
				[4] = { -- arty
					importanceMult = 0,
					count = 0,
				},
				
				[5] = { -- assault
					importanceMult = 1,
					count = 2,
					[1] = {ID = UnitDefNames['spiderassault'].id, chance = 0.95},
					[2] = {ID = UnitDefNames['armcrabe'].id, chance = 0.05},
				},
				
				[6] = { -- skirm
					importanceMult = 1.2,
					count = 1,
					[1] = {ID = UnitDefNames['armsptk'].id, chance = 1},
				},
				
				[7] = { -- riot
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['arm_venom'].id, chance = 1},
				},
				
				[8] = { -- aa
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['spideraa'].id, chance = 1},
				},	
			},
			[UnitDefNames['factorycloak'].id] = {
				defenceQuota = {2,0.6,0.3},
				defenceRange = 500,
				airDefenceQuota = {2,1,0.1},
				importance = 1,
				BPQuota = 70,
				minFacCount = 0,
				
				[1] = { -- con
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['armrectr'].id, chance = 1},
				},
				
				[2] = { -- scout
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['armpw'].id, chance = 1},
				},
				
				[3] = { -- raid
					importanceMult = 1,
					count = 2,
					[1] = {ID = UnitDefNames['armpw'].id, chance = 0.7},
					[2] = {ID = UnitDefNames['spherepole'].id, chance = 0.3},
				},
				
				[4] = { -- arty
					importanceMult = 1,
					count = 2,
					[1] = {ID = UnitDefNames['armham'].id, chance = 0.9},
					[2] = {ID = UnitDefNames['armsnipe'].id, chance = 0.1},
				},
				
				[5] = { --assault
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['armzeus'].id, chance = 1},
				},	
				
				[6] = { -- skirm
					importanceMult = 1.2,
					count = 1,
					[1] = {ID = UnitDefNames['armrock'].id, chance = 1},
				},
				
				[7] = { -- riot
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['armwar'].id, chance = 1},
				},
				
				[8] = { -- aa
					importanceMult = 1.3,
					count = 1,
					[1] = {ID = UnitDefNames['armjeth'].id, chance = 1},
				},	
			},
			[UnitDefNames['factoryshield'].id] = {
				defenceQuota = {2,0.6,0.3},
				defenceRange = 500,
				airDefenceQuota = {2,1,0.1},
				importance = 1,
				BPQuota = 70,
				minFacCount = 0,
				
				[1] = { -- con
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['cornecro'].id, chance = 1},
				},
				
				[2] = { -- scout
					importanceMult = 2,
					count = 1,
					[1] = {ID = UnitDefNames['corclog'].id, chance = 1},
				},
				
				[3] = { -- raid
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['corak'].id, chance = 1},
				},
				
				[4] = { -- arty
					importanceMult = 0,
					count = 0,				
				},
				
				[5] = { --assault
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['corthud'].id, chance = 1},
				},	
				
				[6] = { -- skirm
					importanceMult = 1.2,
					count = 1,
					[1] = {ID = UnitDefNames['corstorm'].id, chance = 1},
				},
				
				[7] = { -- riot
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['cormak'].id, chance = 1},
				},
				
				[8] = { -- aa
					importanceMult = 1.3,
					count = 1,
					[1] = {ID = UnitDefNames['corcrash'].id, chance = 1},
				},	
			},
			[UnitDefNames['factoryhover'].id] = {
				defenceQuota = {2,0.6,0.3},
				defenceRange = 500,
				airDefenceQuota = {2,1,0.1},
				importance = 1,
				BPQuota = 70,
				minFacCount = 0,
				
				[1] = { -- con
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['corch'].id, chance = 1},
				},
				
				[2] = { -- scout
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['corsh'].id, chance = 1},
				},
				
				[3] = { -- raider
					importanceMult = 1,
					count = 2,
					[1] = {ID = UnitDefNames['corsh'].id, chance = 0.5},
					[2] = {ID = UnitDefNames['hoverassault'].id, chance = 0.5},
				},
				
				[4] = { -- arty
					importanceMult = 0.5,
					count = 1,
					[1] = {ID = UnitDefNames['armmanni'].id, chance = 1},
				},
				
				[5] = { --assault
					importanceMult = 1.2,
					count = 2,
					[1] = {ID = UnitDefNames['hoverassault'].id, chance = 0.65},
					[2] = {ID = UnitDefNames['nsaclash'].id, chance = 0.35},
				},
				
				[6] = { -- skirm
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['nsaclash'].id, chance = 1},
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
				defenceRange = 500,
				airDefenceQuota = {2,1,0.1},
				importance = 1,
				BPQuota = 100,
				minFacCount = 1,
				
				[1] = { -- con
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['coracv'].id, chance = 1},
				},
				
				[2] = { -- scout
					importanceMult = 1,
					count = 1,
					[1] = {ID = UnitDefNames['logkoda'].id, chance = 1},
				},
				
				[3] = { -- raider
					importanceMult = 1,
					count = 2,
					[1] = {ID = UnitDefNames['logkoda'].id, chance = 0.3},
					[2] = {ID = UnitDefNames['panther'].id, chance = 0.7},
				},
				
				[4] = { -- arty
					importanceMult = 1,
					count = 2,
					[1] = {ID = UnitDefNames['cormart'].id, chance = 0.7},
					[2] = {ID = UnitDefNames['trem'].id, chance = 0.3},
				},
				
				[5] = { --assault
					importanceMult = 1,
					count = 3,
					[1] = {ID = UnitDefNames['correap'].id, chance = 0.75},
					[2] = {ID = UnitDefNames['tawf114'].id, chance = 0.15},
					[3] = {ID = UnitDefNames['corgol'].id, chance = 0.1},
				},
				
				[6] = { -- skirm
					importanceMult = 0.4,
					count = 1,
					[1] = {ID = UnitDefNames['cormart'].id, chance = 1},
				},
				
				[7] = { -- riot
					importanceMult = 0.8,
					count = 1,
					[1] = {ID = UnitDefNames['tawf114'].id, chance = 1},
				},
				
				[8] = { -- aa
					importanceMult = 0.8,
					count = 1,
					[1] = {ID = UnitDefNames['corsent'].id, chance = 1},
				},	
			},
			[UnitDefNames['factoryplane'].id] = {
				defenceQuota = {2,0.6,0.3},
				defenceRange = 500,
				airDefenceQuota = {2,1,0.1},
				airFactory = true,
				importance = 1,
				BPQuota = 70,
				minFacCount = 1,
				
				[1] = { -- con
					importanceMult = 0.8,
					count = 1,
					[1] = {ID = UnitDefNames['armca'].id, chance = 1},
				},
				
				[2] = { -- scout
					importanceMult = 0.6,
					count = 1,
					[1] = {ID = UnitDefNames['corawac'].id, chance = 1},
				},
				
				[3] = { -- fighter
					importanceMult = 1,
					count = 2,
					[1] = {ID = UnitDefNames['fighter'].id, chance = 0.7},
					[2] = {ID = UnitDefNames['corvamp'].id, chance = 0.3},
				},
				
				[4] = { -- bomber
					importanceMult = 1,
					count = 2,
					[1] = {ID = UnitDefNames['corshad'].id, chance = 0.4},
					[2] = {ID = UnitDefNames['corhurc2'].id, chance = 0.6},
				},
				
				[5] = { -- gunship
					importanceMult = 0,
					count = 0,
				},	
			},
			[UnitDefNames['factorygunship'].id] = {
				defenceQuota = {2,0.6,0.3},
				defenceRange = 500,
				airDefenceQuota = {2,1,0.1},
				airFactory = true,
				importance = 1,
				BPQuota = 70,
				minFacCount = 1,
				
				[1] = { -- con
					importanceMult = 0.8,
					count = 1,
					[1] = {ID = UnitDefNames['armca'].id, chance = 1},
				},
				
				[2] = { -- scout
					importanceMult = 0.6,
					count = 1,
					[1] = {ID = UnitDefNames['blastwing'].id, chance = 1},
				},
				
				[3] = { -- fighter
					importanceMult = 0.6,
					count = 2,
					[1] = {ID = UnitDefNames['corape'].id, chance = 0.7},
					[2] = {ID = UnitDefNames['armkam'].id, chance = 0.3},
				},
				
				[4] = { -- bomber
					importanceMult = 0,
					count = 0,
				},
				
				[5] = { -- gunship
					importanceMult = 1.4,
					count = 4,
					[1] = {ID = UnitDefNames['corape'].id, chance = 0.25},
					[2] = {ID = UnitDefNames['armkam'].id, chance = 0.35},
					[3] = {ID = UnitDefNames['armbrawl'].id, chance = 0.2},
					[4] = {ID = UnitDefNames['blackdawn'].id, chance = 0.2},
				},	
			},
		},

		radarIds = {
			count = 1,
			[1] = {ID = UnitDefNames['corrad'].id, chance = 1},
		},

		mexIds = {
			count = 1,
			[1] = {ID = UnitDefNames['cormex'].id, chance = 1},
		},

		energyIds = {
			count = 3,
			[1] = {ID = UnitDefNames['armfus'].id}, 
			[2] = {ID = UnitDefNames['armsolar'].id}, 
			[3] = {ID = UnitDefNames['armwin'].id}, 
		},
		econByDefId = {
			[UnitDefNames['armfus'].id] = {
				energyGreaterThan = 30, 
				energySpacing = 400,
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
			
			[UnitDefNames['armsolar'].id] = {
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
			
			[UnitDefNames['armwin'].id] = {
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
			
			[UnitDefNames['cormex'].id] = {
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
				[1] = {ID = UnitDefNames['corllt'].id, chance = 0.4},
				[2] = {ID = UnitDefNames['corrl'].id, chance = 0.6},
			},
			
			[2] = {
				count = 3,
				[1] = {ID = UnitDefNames['armdeva'].id, chance = 0.4},
				[2] = {ID = UnitDefNames['armartic'].id, chance = 0.3},
				[3] = {ID = UnitDefNames['corgrav'].id, chance = 0.3},
			},
			
			[3] = {
				count = 1,
				[1] = {ID = UnitDefNames['corhlt'].id, chance = 1},
			},
			
		},

		defenceByDefId = {
			[UnitDefNames['corllt'].id] = {
				level = 1,
				index = 1,
			},
			[UnitDefNames['corrl'].id] = {
				level = 1,
				index = 2,
			},
			[UnitDefNames['armdeva'].id] = {
				level = 2,
				index = 1,
			},
			[UnitDefNames['armartic'].id] = {
				level = 2,
				index = 2,
			},
			[UnitDefNames['corgrav'].id] = {
				level = 2,
				index = 3,
			},
			[UnitDefNames['corhlt'].id] = {
				level = 3,
				index = 1,
			},
		},

		airDefenceIds = {
			[1] = {
				count = 1,
				[1] = {ID = UnitDefNames['corrl'].id, chance = 1},
			},
			
			[2] = {
				count = 2,
				[1] = {ID = UnitDefNames['corrazor'].id, chance = 0.7},
				[2] = {ID = UnitDefNames['missiletower'].id, chance = 0.3},
			},
			
			[3] = {
				count = 2,
				[1] = {ID = UnitDefNames['armcir'].id, chance = 0.7},
				[2] = {ID = UnitDefNames['corflak'].id, chance = 0.3},
			},
		},

		airDefenceByDefId = {
			[UnitDefNames['corrl'].id] = {
				level = 1,
				index = 1,
			},
			[UnitDefNames['corrazor'].id] = {
				level = 2,
				index = 1,
			},
			[UnitDefNames['missiletower'].id] = {
				level = 2,
				index = 2,
			},
			[UnitDefNames['armcir'].id] = {
				level = 3,
				index = 1,
			},
			[UnitDefNames['corflak'].id] = {
				level = 3,
				index = 2,
			},
		},

		airpadDefID = UnitDefNames['armasp'].id,
		nanoDefID = UnitDefNames['armnanotc'].id,
	}
}