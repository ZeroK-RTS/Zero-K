-- just some comm cloning stuff (to avoid having to maintain multiple unitdefs)

local statsByLevel = {
	mainstats = {
		[2] = {
			collisionvolumescales  = [[50 59 50]],
			modelradius    = [[30]],
		},
		[3] = {
			collisionvolumescales  = [[55 65 55]],
			modelradius    = [[33]],
			explodeas = "estor_building",
			selfdestructas = "estor_building",
			footprintx = 3,
			footprintz = 3,
			movementclass = [[AKBOT3]],
		},
		[4] = {
			collisionvolumescales  = [[60 70 60]],
			modelradius    = [[35]],
			explodeas = "estor_building",
			selfdestructas = "estor_building",
			footprintx = 3,
			footprintz = 3,
			movementclass = [[AKBOT3]],
		},
		[5] = {
			collisionvolumescales  = [[65 75 65]],
			modelradius    = [[38]],
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
		armcom0 = {
			level = 0,
		},
		armcom2 = {
			level = 2,
			mainstats = {maxdamage = 3000, autoheal = 12.5, objectname = "armcom2.3do", collisionvolumescales  = [[50 55 50]], aimposoffset = [[0 6 0]],},
			customparams = {modelradius = [[28]],},
			wreckmodel = "armcom2_dead.s3o",
		},
		armcom3 = {
			level = 3,
			mainstats = {maxdamage = 4000, autoheal = 20, objectname = "armcom3.3do", collisionvolumescales  = [[55 60 55]], aimposoffset = [[0 7 0]],},
			customparams = {modelradius = [[30]],},
			wreckmodel = "armcom3_dead.s3o",
		},
		armcom4 = {
			level = 4,
			mainstats = {maxdamage = 5000, autoheal = 27.5, objectname = "armcom4.3do", collisionvolumescales  = [[60 65 60]], aimposoffset = [[0 8 0]],},
			customparams = {modelradius = [[33]],},
			wreckmodel = "armcom4_dead.s3o",
		},
		armcom5 = {
			level = 5,
			mainstats = {maxdamage = 6000, autoheal = 35, objectname = "armcom5.3do", collisionvolumescales  = [[65 70 65]], aimposoffset = [[0 9 0]],},
			customparams = {modelradius = [[35]],},
			wreckmodel = "armcom5_dead.s3o",
		},
	},
	corcom1 = {
		corcom0 = {
			level = 0,
		},
		corcom2 = {
			level = 2,
			mainstats = {maxdamage = 3800, objectname = "corcomAlt2.s3o", aimposoffset = [[0 6 0]], },
			customparams = {damagebonus = "0.025"},
			wreckmodel = "corcom2_dead.s3o",
		},
		corcom3 = {
			level = 3,
			mainstats = {maxdamage = 4900, objectname = "corcomAlt3.s3o", aimposoffset = [[0 7 0]], },
			customparams = {damagebonus = "0.05"},
			wreckmodel = "corcom3_dead.s3o",
		},
		corcom4 = {
			level = 4,
			mainstats = {maxdamage = 6000, objectname = "corcomAlt4.s3o", aimposoffset = [[0 8 0]], },
			customparams = {damagebonus = "0.075"},
			wreckmodel = "corcom4_dead.s3o",
		},
		corcom5 = {
			level = 5,
			mainstats = {maxdamage = 7200, objectname = "corcomAlt5.s3o", aimposoffset = [[0 9 0]], },
			customparams = {damagebonus = "0.1"},
			wreckmodel = "corcom5_dead.s3o",
		},
	},
	commrecon1 = {
		commrecon0 = {
			level = 0,
		},
		commrecon2 = {
			level = 2,
			mainstats = {maxdamage = 2100, objectname = "commrecon2.s3o", aimposoffset = [[0 12 0]]},
			customparams = {},
			wreckmodel = "commrecon2_dead.s3o",
		},
		commrecon3 = {
			level = 3,
			mainstats = {maxdamage = 2600, objectname = "commrecon3.s3o", aimposoffset = [[0 14 0]]},
			customparams = {},
			wreckmodel = "commrecon3_dead.s3o",
		},
		commrecon4 = {
			level = 4,
			mainstats = {maxdamage = 3100, objectname = "commrecon4.s3o", aimposoffset = [[0 16 0]]},
			customparams = {},
			wreckmodel = "commrecon4_dead.s3o",
		},
		commrecon5 = {
			level = 5,
			mainstats = {maxdamage = 3600, objectname = "commrecon5.s3o", aimposoffset = [[0 18 0]]},
			customparams = {},
			wreckmodel = "commrecon5_dead.s3o",
		},
	},
	commsupport1 = {
		commsupport0 = {
			level = 0,
		},
		commsupport2 = {
			level = 2,
			mainstats = {maxdamage = 2500, workertime = 14, description = "Econ/Support Commander, Builds at 14 m/s", objectname = "commsupport2.s3o", aimposoffset = [[0 17 0]]},
			customparams = {},
			wreckmodel = "commsupport2_dead.s3o",
		},
		commsupport3 = {
			level = 3,
			mainstats = {maxdamage = 3000, workertime = 16, description = "Econ/Support Commander, Builds at 16 m/s", objectname = "commsupport3.s3o", aimposoffset = [[0 19 0]],},
			customparams = {},
			wreckmodel = "commsupport3_dead.s3o",
		},
		commsupport4 = {
			level = 4,
			mainstats = {maxdamage = 3700, workertime = 18, description = "Econ/Support Commander, Builds at 18 m/s", objectname = "commsupport4.s3o", aimposoffset = [[0 22 0]],},
			customparams = {},
			wreckmodel = "commsupport4_dead.s3o",
		},
		commsupport5 = {
			level = 5,
			mainstats = {maxdamage = 4500, workertime = 20, description = "Econ/Support Commander, Builds at 20 m/s", objectname = "commsupport5.s3o", aimposoffset = [[0 25 0]],},
			customparams = {},
			wreckmodel = "commsupport5_dead.s3o",
		},
	},
	cremcom1 = {
		cremcom0 = {
			level = 0,
		},
		cremcom2 = {
			level = 2,
			mainstats = {maxdamage = 3000, autoheal = 12.5, objectname = "cremcom2.s3o", collisionvolumescales  = [[50 55 50]],},
			customparams = {modelradius = [[28]],},
			wreckmodel = "cremcom2_dead.s3o",
		},
		cremcom3 = {
			level = 3,
			mainstats = {maxdamage = 4000, autoheal = 20, objectname = "cremcom3.s3o", collisionvolumescales  = [[55 60 55]],},
			customparams = {modelradius = [[30]],},
			wreckmodel = "cremcom3_dead.s3o",
		},
		cremcom4 = {
			level = 4,
			mainstats = {maxdamage = 5000, autoheal = 27.5, objectname = "cremcom4.s3o", collisionvolumescales  = [[60 65 60]], },
			customparams = {modelradius = [[33]],},
			wreckmodel = "cremcom4_dead.s3o",
		},
		cremcom5 = {
			level = 5,
			mainstats = {maxdamage = 6000, autoheal = 35, objectname = "cremcom5.s3o", collisionvolumescales  = [[65 70 65]],},
			customparams = {modelradius = [[35]],},
			wreckmodel = "cremcom5_dead.s3o",
		},
	},
	benzcom1 = {
		benzcom0 = {
			level = 0,
		},
		benzcom2 = {
			level = 2,
			mainstats = {maxdamage = 2700, objectname = "benzcom2.s3o"},
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
	commstrike1 = {
		commstrike0 = {
			level = 0,
		},
		commstrike2 = {
			level = 2,
			mainstats = {maxdamage = 3000, objectname = "strikecom_1.dae", collisionvolumescales  = [[50 55 50]],},
			customparams = {modelradius = [[28]],},
			wreckmodel = "strikecom_dead_1.dae",
		},
		commstrike3 = {
			level = 3,
			mainstats = {maxdamage = 4000, objectname = "strikecom_2.dae", collisionvolumescales  = [[55 60 55]],},
			customparams = {modelradius = [[30]],},
			wreckmodel = "strikecom_dead_2.dae",
		},
		commstrike4 = {
			level = 4,
			mainstats = {maxdamage = 5000, objectname = "strikecom_3.dae", collisionvolumescales  = [[58 66 58]],},
			customparams = { modelradius = [[33]],},
			wreckmodel = "strikecom_dead_3.dae",
		},
		commstrike5 = {
			level = 5,
			mainstats = {maxdamage = 6000, objectname = "strikecom_4.dae", collisionvolumescales  = [[60 72 60]],},
			customparams = {modelradius = [[36]],},
			wreckmodel = "strikecom_dead_4.dae",
		},
	},
	dynstrike1 = {
		dynstrike0 = {
			level = 0,
			customparams = {shield_emit_height = 38},
		},
		dynstrike2 = {
			level = 2,
			mainstats = {maxdamage = 4600, objectname = "strikecom_1.dae", collisionvolumescales  = [[50 55 50]],},
			customparams = {modelradius = [[28]], shield_emit_height = 41.8},
			wreckmodel = "strikecom_dead_1.dae",
		},
		dynstrike3 = {
			level = 3,
			mainstats = {maxdamage = 5200, objectname = "strikecom_2.dae", collisionvolumescales  = [[55 60 55]],},
			customparams = {modelradius = [[30]], shield_emit_height = 45.6},
			wreckmodel = "strikecom_dead_2.dae",
		},
		dynstrike4 = {
			level = 4,
			mainstats = {maxdamage = 5800, objectname = "strikecom_3.dae", collisionvolumescales  = [[58 66 58]],},
			customparams = {modelradius = [[33]], shield_emit_height = 47.5},
			wreckmodel = "strikecom_dead_3.dae",
		},
		dynstrike5 = {
			level = 5,
			mainstats = {maxdamage = 6400, objectname = "strikecom_4.dae", collisionvolumescales  = [[60 72 60]],},
			customparams = {modelradius = [[36]], shield_emit_height = 49.4},
			wreckmodel = "strikecom_dead_4.dae",
		},
	},
	dynrecon1 = {
		dynrecon0 = {
			level = 0,
			customparams = {shield_emit_height = 30},
		},
		dynrecon2 = {
			level = 2,
			mainstats = {maxdamage = 3400, objectname = "commrecon2.s3o", aimposoffset = [[0 12 0]]},
			customparams = {shield_emit_height = 33},
			wreckmodel = "commrecon2_dead.s3o",
		},
		dynrecon3 = {
			level = 3,
			mainstats = {maxdamage = 3600, objectname = "commrecon3.s3o", aimposoffset = [[0 14 0]]},
			customparams = {shield_emit_height = 36},
			wreckmodel = "commrecon3_dead.s3o",
		},
		dynrecon4 = {
			level = 4,
			mainstats = {maxdamage = 3800, objectname = "commrecon4.s3o", aimposoffset = [[0 16 0]]},
			customparams = {shield_emit_height = 37.5},
			wreckmodel = "commrecon4_dead.s3o",
		},
		dynrecon5 = {
			level = 5,
			mainstats = {maxdamage = 4000, objectname = "commrecon5.s3o", aimposoffset = [[0 18 0]]},
			customparams = {shield_emit_height = 39},
			wreckmodel = "commrecon5_dead.s3o",
		},
	},
	dynsupport1 = {
		dynsupport0 = {
			level = 0,
			customparams = {shield_emit_height = 36, builddistance = 220},
		},
		dynsupport2 = {
			level = 2,
			mainstats = {maxdamage = 4000, objectname = "commsupport2.s3o", aimposoffset = [[0 17 0]], builddistance = 244},
			customparams = {shield_emit_height = 39.6},
			wreckmodel = "commsupport2_dead.s3o",
		},
		dynsupport3 = {
			level = 3,
			mainstats = {maxdamage = 4300, objectname = "commsupport3.s3o", aimposoffset = [[0 19 0]], builddistance = 256},
			customparams = {shield_emit_height = 43.62},
			wreckmodel = "commsupport3_dead.s3o",
		},
		dynsupport4 = {
			level = 4,
			mainstats = {maxdamage = 4600, objectname = "commsupport4.s3o", aimposoffset = [[0 22 0]], builddistance = 268},
			customparams = {shield_emit_height = 45},
			wreckmodel = "commsupport4_dead.s3o",
		},
		dynsupport5 = {
			level = 5,
			mainstats = {maxdamage = 5000, objectname = "commsupport5.s3o", aimposoffset = [[0 25 0]], builddistance = 280},
			customparams = {shield_emit_height = 46.48},
			wreckmodel = "commsupport5_dead.s3o",
		},
	},
	dynassault1 = {
		dynassault0 = {
			level = 0,
			customparams = {shield_emit_height = 32.5},
		},
		dynassault2 = {
			level = 2,
			collisionvolumescales  = [[50 60 50]],
			mainstats = {maxdamage = 5000, objectname = "benzcom2.s3o"},
			customparams = {modelradius = [[30]], shield_emit_height = 35.75},
			wreckmodel = "benzcom2_wreck.s3o",
		},
		dynassault3 = {
			level = 3,
			collisionvolumescales  = [[55 65 55]],
			mainstats = {maxdamage = 5700, objectname = "benzcom3.s3o",},
			customparams = {modelradius = [[33]], shield_emit_height = 39},
			wreckmodel = "benzcom3_wreck.s3o",
		},
		dynassault4 = {
			level = 4,
			collisionvolumescales  = [[58 68 58]],
			mainstats = {maxdamage = 6600, objectname = "benzcom4.s3o",},
			customparams = {modelradius = [[34]], shield_emit_height = 40.625},
			wreckmodel = "benzcom4_wreck.s3o",
		},
		dynassault5 = {
			level = 5,
			collisionvolumescales  = [[60 71 60]],
			mainstats = {maxdamage = 7600, objectname = "benzcom5.s3o",},
			customparams = {modelradius = [[36]], shield_emit_height = 42.25},
			wreckmodel = "benzcom5_wreck.s3o",
		},
	},
	dynknight1 = {
		dynknight0 = {
			level = 0,
			customparams = {shield_emit_height = 30},
		},
		dynknight2 = {
			level = 2,
			mainstats = {maxdamage = 4600, objectname = "cremcom2.s3o", collisionvolumescales  = [[50 55 50]],},
			customparams = {modelradius = [[28]], shield_emit_height = 33},
			wreckmodel = "cremcom2_dead.s3o",
		},
		dynknight3 = {
			level = 3,
			mainstats = {maxdamage = 5200, objectname = "cremcom3.s3o", collisionvolumescales  = [[55 60 55]],},
			customparams = {modelradius = [[30]], shield_emit_height = 36},
			wreckmodel = "cremcom3_dead.s3o",
		},
		dynknight4 = {
			level = 4,
			mainstats = {maxdamage = 5800, objectname = "cremcom4.s3o", collisionvolumescales  = [[60 65 60]],},
			customparams = {modelradius = [[33]], shield_emit_height = 37.5},
			wreckmodel = "cremcom4_dead.s3o",
		},
		dynknight5 = {
			level = 5,
			mainstats = {maxdamage = 6400, objectname = "cremcom5.s3o", collisionvolumescales  = [[65 70 65]],},
			customparams = {modelradius = [[35]], shield_emit_height = 39},
			wreckmodel = "cremcom5_dead.s3o",
		},
	},
}

for sourceName, copyTable in pairs(copy) do
	for cloneName, stats in pairs(copyTable) do
		-- some further modification
		UnitDefs[cloneName] = CopyTable(UnitDefs[sourceName], true)
		UnitDefs[cloneName].unitname = cloneName
		
		if stats.level > 0 then
		
			-- copy from by-level table
			for statName, value in pairs(statsByLevel.mainstats[stats.level]) do
				UnitDefs[cloneName][statName] = value
			end
			--for statName, value in pairs(statsByLevel.customparams[stats.level]) do
			--	UnitDefs[cloneName].customparams[statName] = value
			--end
			
			-- copy from specific table
			for statName, value in pairs(stats.mainstats or {}) do
				UnitDefs[cloneName][statName] = value
			end
			for statName, value in pairs(stats.customparams or {}) do
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
		end
		
		UnitDefs[cloneName].customparams.level = stats.level
		UnitDefs[cloneName].name = (UnitDefs[cloneName].name) .. " - Level " .. stats.level
		UnitDefs[cloneName].icontype = "commander"..stats.level
	end
end
