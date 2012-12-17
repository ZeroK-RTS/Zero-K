-- just some comm cloning stuff (to avoid having to maintain multiple unitdefs)

local statsByLevel = {
	mainstats = {
		[2] = {
			collisionvolumescales  = [[50 59 50]],
		},
		[3] = {
			collisionvolumescales  = [[55 65 55]],
			explodeas = "estor_building",
			selfdestructas = "estor_building",
			footprintx = 3,
			footprintz = 3,
			movementclass = [[AKBOT3]],
		},
		[4] = {
			collisionvolumescales  = [[60 70 60]],	
			explodeas = "estor_building",
			selfdestructas = "estor_building",
			footprintx = 3,
			footprintz = 3,
			movementclass = [[AKBOT3]],			
		},
		[5] = {
			collisionvolumescales  = [[65 75 65]],	
			explodeas = "estor_building",
			selfdestructas = "estor_building",
			footprintx = 3,
			footprintz = 3,
			movementclass = [[AKBOT3]],			
		},		
	},
	customparams = {
	},
	heapmodel = {
		[2] = "debris3x3b.s3o", [3] = "debris3x3c.s3o", [4] = "debris4x4b.s3o", [5] = "debris4x4c.s3o",
	}
}

--stats here take precedence over statsByLevel
local copy = {
	armcom1 = {
		armcom2 = {
			level = 2,
			mainstats = {maxdamage = 3000, objectname = "armcom2.3do", collisionvolumescales  = [[50 55 50]],},
			customparams = {rangebonus = "0.025"},
			wreckmodel = "armcom2_dead",
		},
		armcom3 = {
			level = 3,
			mainstats = {maxdamage = 4000, objectname = "armcom3.3do", collisionvolumescales  = [[55 60 55]],},
			customparams = {rangebonus = "0.05"},
			wreckmodel = "armcom3_dead",
		},
		armcom4 = {
			level = 4,
			mainstats = {maxdamage = 5000, objectname = "armcom4.3do", collisionvolumescales  = [[60 65 60]],},
			customparams = {rangebonus = "0.075"},
			wreckmodel = "armcom4_dead",
		},
		armcom5 = {
			level = 5,
			mainstats = {maxdamage = 6000, objectname = "armcom5.3do", collisionvolumescales  = [[65 70 65]],},
			customparams = {rangebonus = "0.1"},
			wreckmodel = "armcom5_dead",
		},		
	},
	corcom1 = {
		corcom2 = {
			level = 2,
			mainstats = {maxdamage = 3800, objectname = "corcomAlt2.s3o", },
			customparams = {damagebonus = "0.05"},
			wreckmodel = "corcom2_dead.s3o",
		},
		corcom3 = {
			level = 3,
			mainstats = {maxdamage = 4900, objectname = "corcomAlt3.s3o", },
			customparams = {damagebonus = "0.1"},
			wreckmodel = "corcom3_dead.s3o",
		},
		corcom4 = {
			level = 4,
			mainstats = {maxdamage = 6000, objectname = "corcomAlt4.s3o", },
			customparams = {damagebonus = "0.15"},
			wreckmodel = "corcom4_dead.s3o",
		},
		corcom5 = {
			level = 5,
			mainstats = {maxdamage = 7200, objectname = "corcomAlt5.s3o", },
			customparams = {damagebonus = "0.2"},
			wreckmodel = "corcom5_dead.s3o",
		},		
	},
	commrecon1 = {
		commrecon2 = {
			level = 2,
			mainstats = {maxdamage = 2300, objectname = "commrecon2.s3o"},
			customparams = {speedbonus = "0.05"},
			wreckmodel = "commrecon2_dead.s3o",
		},
		commrecon3 = {
			level = 3,
			mainstats = {maxdamage = 2800, objectname = "commrecon3.s3o",},
			customparams = {speedbonus = "0.1"},
			wreckmodel = "commrecon3_dead.s3o",
		},
		commrecon4 = {
			level = 4,
			mainstats = {maxdamage = 3400, objectname = "commrecon4.s3o",},
			customparams = {speedbonus = "0.15"},
			wreckmodel = "commrecon4_dead.s3o",
		},
		commrecon5 = {
			level = 5,
			mainstats = {maxdamage = 4000, objectname = "commrecon5.s3o",},
			customparams = {speedbonus = "0.2"},
			wreckmodel = "commrecon5_dead.s3o",
		},		
	},
	commsupport1 = {
		commsupport2 = {
			level = 2,
			mainstats = {maxdamage = 2500, workertime = 12.5, description = "Econ/Support Commander, Builds at 12.5 m/s", objectname = "commsupport2.s3o"},
			customparams = {rangebonus = "0.05"},
			wreckmodel = "commsupport2_dead.s3o",
		},
		commsupport3 = {
			level = 3,
			mainstats = {maxdamage = 3000, workertime = 15, description = "Econ/Support Commander, Builds at 15 m/s", objectname = "commsupport3.s3o",},
			customparams = {rangebonus = "0.1"},
			wreckmodel = "commsupport3_dead.s3o",
		},
		commsupport4 = {
			level = 4,
			mainstats = {maxdamage = 3700, workertime = 17.5, description = "Econ/Support Commander, Builds at 17.5 m/s", objectname = "commsupport4.s3o",},
			customparams = {rangebonus = "0.15"},
			wreckmodel = "commsupport4_dead.s3o",
		},
		commsupport5 = {
			level = 5,
			mainstats = {maxdamage = 4500, workertime = 20, description = "Econ/Support Commander, Builds at 20 m/s", objectname = "commsupport5.s3o",},
			customparams = {rangebonus = "0.2"},
			wreckmodel = "commsupport5_dead.s3o",
		},		
	},
	cremcom1 = {
		cremcom2 = {
			level = 2,
			mainstats = {maxdamage = 3000, objectname = "cremcom2.s3o", collisionvolumescales  = [[50 55 50]],},
			customparams = {speedbonus = "0.05"},
			wreckmodel = "armcom2_dead",
		},
		cremcom3 = {
			level = 3,
			mainstats = {maxdamage = 4000, objectname = "cremcom3.s3o", collisionvolumescales  = [[55 60 55]],},
			customparams = {speedbonus = "0.1"},
			wreckmodel = "armcom3_dead",
		},
		cremcom4 = {
			level = 4,
			mainstats = {maxdamage = 5000, objectname = "cremcom4.s3o", collisionvolumescales  = [[60 65 60]],},
			customparams = {speedbonus = "0.15"},
			wreckmodel = "armcom4_dead",
		},
		cremcom5 = {
			level = 5,
			mainstats = {maxdamage = 6000, objectname = "cremcom5.s3o", collisionvolumescales  = [[65 70 65]],},
			customparams = {speedbonus = "0.2"},
			wreckmodel = "armcom5_dead",
		},			
	},
	benzcom1 = {
		benzcom2 = {
			level = 2,
			mainstats = {maxdamage = 2600, objectname = "benzcom2.s3o"},
			customparams = {rangebonus = "0.075"},
			wreckmodel = "benzcom2_wreck.s3o",
		},
		benzcom3 = {
			level = 3,
			mainstats = {maxdamage = 3300, objectname = "benzcom3.s3o",},
			customparams = {rangebonus = "0.15"},
			wreckmodel = "benzcom3_wreck.s3o",
		},
		benzcom4 = {
			level = 4,
			mainstats = {maxdamage = 4000, objectname = "benzcom4.s3o",},
			customparams = {rangebonus = "0.225"},
			wreckmodel = "benzcom4_wreck.s3o",
		},
		benzcom5 = {
			level = 5,
			mainstats = {maxdamage = 4700,objectname = "benzcom5.s3o",},
			customparams = {rangebonus = "0.3"},
			wreckmodel = "benzcom5_wreck.s3o",
		},
	},
}

for sourceName, copyTable in pairs(copy) do
	for cloneName, stats in pairs(copyTable) do
		-- some further modification
		UnitDefs[cloneName] = CopyTable(UnitDefs[sourceName], true)
		UnitDefs[cloneName].unitname = cloneName
		
		-- copy from by-level table
		for statName, value in pairs(statsByLevel.mainstats[stats.level]) do
			UnitDefs[cloneName][statName] = value
		end
		--for statName, value in pairs(statsByLevel.customparams[stats.level]) do
		--	UnitDefs[cloneName].customparams[statName] = value
		--end		
		
		-- copy from specific table
		for statName, value in pairs(stats.mainstats) do
			UnitDefs[cloneName][statName] = value
		end
		for statName, value in pairs(stats.customparams) do
			UnitDefs[cloneName].customparams[statName] = value
		end
		UnitDefs[cloneName].trackwidth = UnitDefs[cloneName].trackwidth * (0.9 + 0.1*(stats.level))
		-- features
		UnitDefs[cloneName].featuredefs.dead.object = stats.wreckmodel
		UnitDefs[cloneName].featuredefs.dead.footprintx = UnitDefs[cloneName].footprintx
		UnitDefs[cloneName].featuredefs.dead.footprintz = UnitDefs[cloneName].footprintz
		UnitDefs[cloneName].featuredefs.heap.object = stats.heapmodel
		UnitDefs[cloneName].featuredefs.heap.footprintx = UnitDefs[cloneName].footprintx
		UnitDefs[cloneName].featuredefs.heap.footprintz = UnitDefs[cloneName].footprintz
		
		UnitDefs[cloneName].customparams.level = stats.level
		UnitDefs[cloneName].name = (UnitDefs[cloneName].name) .. " - Level " .. stats.level
		UnitDefs[cloneName].icontype = "commander"..stats.level
	end
end