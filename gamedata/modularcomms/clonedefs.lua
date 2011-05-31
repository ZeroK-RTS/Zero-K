-- just some comm cloning stuff (to avoid having to maintain multiple unitdefs)
-- TODO: rewrite in non-dumbass way
local copy = {
	armcom1 = {
		armcom2 = {
			level = 2,
			mainstats = {maxdamage = 3000, objectname = "armcom2.3do"},
			customparams = {rangebonus = "0.05"},
			wreckmodel = "armcom2_dead",
			heapmodel = "debris3x3b.s3o",
		},
		armcom3 = {
			level = 3,
			mainstats = {maxdamage = 4000, objectname = "armcom3.3do",
				explodeas = "estor_building", selfdas = "estor_building",
				movementclass = [[AKBOT3]], footprintx = 3, footprintz = 3},
			customparams = {rangebonus = "0.1"},
			wreckmodel = "armcom3_dead",
			heapmodel = "debris3x3c.s3o",
		},
		armcom4 = {
			level = 4,
			mainstats = {maxdamage = 6000, objectname = "armcom4.3do",
				explodeas = "estor_building", selfdas = "estor_building",
				movementclass = [[AKBOT3]], footprintx = 3, footprintz = 3},
			customparams = {rangebonus = "0.2"},
			wreckmodel = "armcom4_dead",
			heapmodel = "debris4x4b.s3o",
		},
	},
	corcom1 = {
		corcom2 = {
			level = 2,
			mainstats = {maxdamage = 3600, objectname = "corcomAlt2.s3o"},
			customparams = {damagebonus = "0.1"},
			wreckmodel = "corcom2_dead.s3o",
			heapmodel = "debris3x3b.s3o",
		},
		corcom3 = {
			level = 3,
			mainstats = {maxdamage = 5000, objectname = "corcomAlt3.s3o",
				explodeas = "estor_building", selfdas = "estor_building",
				movementclass = [[AKBOT3]], footprintx = 3, footprintz = 3},
			customparams = {damagebonus = "0.2"},
			wreckmodel = "corcom3_dead.s3o",
			heapmodel = "debris3x3c.s3o",
		},
		corcom4 = {
			level = 4,
			mainstats = {maxdamage = 7200, objectname = "corcomAlt4.s3o",
				explodeas = "estor_building", selfdas = "estor_building",
				movementclass = [[AKBOT3]], footprintx = 3, footprintz = 3},
			customparams = {damagebonus = "0.3"},
			wreckmodel = "corcom4_dead.s3o",
			heapmodel = "debris4x4b.s3o",
		},
	},
	commrecon1 = {
		commrecon2 = {
			level = 2,
			mainstats = {maxdamage = 2400, objectname = "commrecon2.s3o"},
			customparams = {speedbonus = "0.075"},
			wreckmodel = "commrecon2_dead.s3o",
			heapmodel = "debris3x3b.s3o",
		},
		commrecon3 = {
			level = 3,
			mainstats = {maxdamage = 3150, objectname = "commrecon3.s3o",
				explodeas = "estor_building", selfdas = "estor_building",
				movementclass = [[AKBOT3]], footprintx = 3, footprintz = 3},
			customparams = {speedbonus = "0.15"},
			wreckmodel = "commrecon3_dead.s3o",
			heapmodel = "debris3x3c.s3o",
		},
		commrecon4 = {
			level = 4,
			mainstats = {maxdamage = 4000, objectname = "commrecon4.s3o",
				explodeas = "estor_building", selfdas = "estor_building",
				movementclass = [[AKBOT3]], footprintx = 3, footprintz = 3},
			customparams = {speedbonus = "0.3"},
			wreckmodel = "commrecon4_dead.s3o",
			heapmodel = "debris4x4b.s3o",
		},
	},
	commsupport1 = {
		commsupport2 = {
			level = 2,
			mainstats = {maxdamage = 2500, workertime = 15, description = "Econ/Support Commander, Builds at 15 m/s", objectname = "commsupport2.s3o"},
			customparams = {rangebonus = "0.1"},
			wreckmodel = "commsupport2_dead.s3o",
			heapmodel = "debris3x3b.s3o",
		},
		commsupport3 = {
			level = 3,
			mainstats = {maxdamage = 3200, workertime = 18, description = "Econ/Support Commander, Builds at 18 m/s", objectname = "commsupport3.s3o",
				explodeas = "estor_building", selfdas = "estor_building",
				movementclass = [[AKBOT3]], footprintx = 3, footprintz = 3},
			customparams = {rangebonus = "0.2"},
			wreckmodel = "commsupport3_dead.s3o",
			heapmodel = "debris3x3c.s3o",
		},
		commsupport4 = {
			level = 4,
			mainstats = {maxdamage = 4500, workertime = 24, description = "Econ/Support Commander, Builds at 24 m/s", objectname = "commsupport4.s3o",
				explodeas = "estor_building", selfdas = "estor_building",
				movementclass = [[AKBOT3]], footprintx = 3, footprintz = 3},
			customparams = {rangebonus = "0.3"},
			wreckmodel = "commsupport4_dead.s3o",
			heapmodel = "debris4x4b.s3o",
		},
	},
}

for sourceName, copyTable in pairs(copy) do
	for cloneName, stats in pairs(copyTable) do
		-- some further modification
		UnitDefs[cloneName] = CopyTable(UnitDefs[sourceName], true)
		UnitDefs[cloneName].unitname = cloneName
		for statName, value in pairs(stats.mainstats) do
			UnitDefs[cloneName][statName] = value
		end
		for statName, value in pairs(stats.customparams) do
			UnitDefs[cloneName].customparams[statName] = value
		end
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