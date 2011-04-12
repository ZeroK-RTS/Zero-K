-- just some comm cloning stuff (to avoid having to maintain multiple unitdefs)
local copy = {
	armcom1 = {
		armcom2 = {
			level = 2,
			mainstats = {maxdamage = 3000, objectname = "armcom2.3do"},
			customparams = {rangebonus = "0.05"},
		},
		armcom3 = {
			level = 3,
			mainstats = {maxdamage = 4000, objectname = "armcom3.3do",
				explodeas = "atomic_blastsml", selfdas = "atomic_blastsml"},
			customparams = {rangebonus = "0.1"},
		},
		armcom4 = {
			level = 4,
			mainstats = {maxdamage = 6000, objectname = "armcom4.3do",
				explodeas = "atomic_blastsml", selfdas = "atomic_blastsml"},
			customparams = {rangebonus = "0.2"},
		},
	},
	corcom1 = {
		corcom2 = {
			level = 2,
			mainstats = {maxdamage = 3600, objectname = "corcom2.s3o"},
			customparams = {damagebonus = "0.1"},
		},
		corcom3 = {
			level = 3,
			mainstats = {maxdamage = 5000, objectname = "corcom3.s3o",
				explodeas = "atomic_blastsml", selfdas = "atomic_blastsml"},
			customparams = {damagebonus = "0.2"},
		},
		corcom4 = {
			level = 4,
			mainstats = {maxdamage = 7200, objectname = "corcom4.s3o",
				explodeas = "atomic_blastsml", selfdas = "atomic_blastsml"},
			customparams = {damagebonus = "0.3"},
		},
	},
	commrecon1 = {
		commrecon2 = {
			level = 2,
			mainstats = {maxdamage = 2750, objectname = "commrecon2.s3o"},
			customparams = {speedbonus = "0.075"},
		},
		commrecon3 = {
			level = 3,
			mainstats = {maxdamage = 3600, objectname = "commrecon3.s3o",
				explodeas = "atomic_blastsml", selfdas = "atomic_blastsml"},
			customparams = {speedbonus = "0.15"},
		},
		commrecon4 = {
			level = 4,
			mainstats = {maxdamage = 5000, objectname = "commrecon4.s3o",
				explodeas = "atomic_blastsml", selfdas = "atomic_blastsml"},
			customparams = {speedbonus = "0.3"},
		},
	},
	commsupport1 = {
		commsupport2 = {
			level = 2,
			mainstats = {maxdamage = 2500, workertime = 15, description = "Econ/Support Commander, Builds at 15 m/s", objectname = "commsupport2.s3o"},
			customparams = {rangebonus = "0.1"},
		},
		commsupport3 = {
			level = 3,
			mainstats = {maxdamage = 3200, workertime = 18, description = "Econ/Support Commander, Builds at 18 m/s", objectname = "commsupport3.s3o",
				explodeas = "atomic_blastsml", selfdas = "atomic_blastsml"},
			customparams = {rangebonus = "0.2"},
		},
		commsupport4 = {
			level = 4,
			mainstats = {maxdamage = 4500, workertime = 24, description = "Econ/Support Commander, Builds at 24 m/s", objectname = "commsupport4.s3o",
				explodeas = "atomic_blastsml", selfdas = "atomic_blastsml"},
			customparams = {rangebonus = "0.3"},
		},
	},
}

for sourceName, copyTable in pairs(copy) do
	for cloneName, stats in pairs(copyTable) do
		UnitDefs[cloneName] = CopyTable(UnitDefs[sourceName], true)
		UnitDefs[cloneName].unitname = cloneName
		for statName, value in pairs(stats.mainstats) do
			UnitDefs[cloneName][statName] = value
		end
		for statName, value in pairs(stats.customparams) do
			UnitDefs[cloneName].customparams[statName] = value
		end
		UnitDefs[cloneName].customparams.level = stats.level
		UnitDefs[cloneName].name = (UnitDefs[cloneName].name) .. " - Level " .. stats.level
	end
end