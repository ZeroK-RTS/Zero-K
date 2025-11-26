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
			mainstats = {health = 3000, autoheal = 12.5, objectname = "armcom2.s3o", collisionvolumescales  = [[50 55 50]], aimposoffset = [[0 6 0]],},
			customparams = {modelradius = [[28]],},
			wreckmodel = "armcom2_dead.s3o",
		},
		armcom3 = {
			level = 3,
			mainstats = {health = 4000, autoheal = 20, objectname = "armcom3.s3o", collisionvolumescales  = [[55 60 55]], aimposoffset = [[0 7 0]],},
			customparams = {modelradius = [[30]],},
			wreckmodel = "armcom3_dead.s3o",
		},
		armcom4 = {
			level = 4,
			mainstats = {health = 5000, autoheal = 27.5, objectname = "armcom4.s3o", collisionvolumescales  = [[60 65 60]], aimposoffset = [[0 8 0]],},
			customparams = {modelradius = [[33]],},
			wreckmodel = "armcom4_dead.s3o",
		},
		armcom5 = {
			level = 5,
			mainstats = {health = 6000, autoheal = 35, objectname = "armcom5.s3o", collisionvolumescales  = [[65 70 65]], aimposoffset = [[0 9 0]],},
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
			mainstats = {health = 3800, objectname = "corcomAlt2.s3o", aimposoffset = [[0 6 0]], },
			customparams = {damagebonus = "0.025"},
			wreckmodel = "corcom2_dead.s3o",
		},
		corcom3 = {
			level = 3,
			mainstats = {health = 4900, objectname = "corcomAlt3.s3o", aimposoffset = [[0 7 0]], },
			customparams = {damagebonus = "0.05"},
			wreckmodel = "corcom3_dead.s3o",
		},
		corcom4 = {
			level = 4,
			mainstats = {health = 6000, objectname = "corcomAlt4.s3o", aimposoffset = [[0 8 0]], },
			customparams = {damagebonus = "0.075"},
			wreckmodel = "corcom4_dead.s3o",
		},
		corcom5 = {
			level = 5,
			mainstats = {health = 7200, objectname = "corcomAlt5.s3o", aimposoffset = [[0 9 0]], },
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
			mainstats = {health = 2100, objectname = "commrecon2.s3o", aimposoffset = [[0 12 0]]},
			customparams = {},
			wreckmodel = "commrecon2_dead.s3o",
		},
		commrecon3 = {
			level = 3,
			mainstats = {health = 2600, objectname = "commrecon3.s3o", aimposoffset = [[0 14 0]]},
			customparams = {},
			wreckmodel = "commrecon3_dead.s3o",
		},
		commrecon4 = {
			level = 4,
			mainstats = {health = 3100, objectname = "commrecon4.s3o", aimposoffset = [[0 16 0]]},
			customparams = {},
			wreckmodel = "commrecon4_dead.s3o",
		},
		commrecon5 = {
			level = 5,
			mainstats = {health = 3600, objectname = "commrecon5.s3o", aimposoffset = [[0 18 0]]},
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
			mainstats = {health = 2500, workertime = 14, description = "Econ/Support Commander, Builds at 14 m/s", objectname = "commsupport2.s3o", aimposoffset = [[0 17 0]]},
			customparams = {},
			wreckmodel = "commsupport2_dead.s3o",
		},
		commsupport3 = {
			level = 3,
			mainstats = {health = 3000, workertime = 16, description = "Econ/Support Commander, Builds at 16 m/s", objectname = "commsupport3.s3o", aimposoffset = [[0 19 0]],},
			customparams = {},
			wreckmodel = "commsupport3_dead.s3o",
		},
		commsupport4 = {
			level = 4,
			mainstats = {health = 3700, workertime = 18, description = "Econ/Support Commander, Builds at 18 m/s", objectname = "commsupport4.s3o", aimposoffset = [[0 22 0]],},
			customparams = {},
			wreckmodel = "commsupport4_dead.s3o",
		},
		commsupport5 = {
			level = 5,
			mainstats = {health = 4500, workertime = 20, description = "Econ/Support Commander, Builds at 20 m/s", objectname = "commsupport5.s3o", aimposoffset = [[0 25 0]],},
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
			mainstats = {health = 3000, autoheal = 12.5, objectname = "cremcom2.s3o", collisionvolumescales  = [[50 55 50]],},
			customparams = {modelradius = [[28]],},
			wreckmodel = "cremcom2_dead.s3o",
		},
		cremcom3 = {
			level = 3,
			mainstats = {health = 4000, autoheal = 20, objectname = "cremcom3.s3o", collisionvolumescales  = [[55 60 55]],},
			customparams = {modelradius = [[30]],},
			wreckmodel = "cremcom3_dead.s3o",
		},
		cremcom4 = {
			level = 4,
			mainstats = {health = 5000, autoheal = 27.5, objectname = "cremcom4.s3o", collisionvolumescales  = [[60 65 60]], },
			customparams = {modelradius = [[33]],},
			wreckmodel = "cremcom4_dead.s3o",
		},
		cremcom5 = {
			level = 5,
			mainstats = {health = 6000, autoheal = 35, objectname = "cremcom5.s3o", collisionvolumescales  = [[65 70 65]],},
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
			mainstats = {health = 2700, objectname = "benzcom2.s3o"},
			customparams = {rangebonus = "0.075"},
			wreckmodel = "benzcom2_wreck.s3o",
		},
		benzcom3 = {
			level = 3,
			mainstats = {health = 3300, objectname = "benzcom3.s3o",},
			customparams = {rangebonus = "0.15"},
			wreckmodel = "benzcom3_wreck.s3o",
		},
		benzcom4 = {
			level = 4,
			mainstats = {health = 4000, objectname = "benzcom4.s3o",},
			customparams = {rangebonus = "0.225"},
			wreckmodel = "benzcom4_wreck.s3o",
		},
		benzcom5 = {
			level = 5,
			mainstats = {health = 4700, objectname = "benzcom5.s3o",},
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
			mainstats = {health = 3000, objectname = "strikecom_1.dae", collisionvolumescales  = [[50 55 50]],},
			customparams = {modelradius = [[28]],},
			wreckmodel = "strikecom_dead_1.dae",
		},
		commstrike3 = {
			level = 3,
			mainstats = {health = 4000, objectname = "strikecom_2.dae", collisionvolumescales  = [[55 60 55]],},
			customparams = {modelradius = [[30]],},
			wreckmodel = "strikecom_dead_2.dae",
		},
		commstrike4 = {
			level = 4,
			mainstats = {health = 5000, objectname = "strikecom_3.dae", collisionvolumescales  = [[58 66 58]],},
			customparams = { modelradius = [[33]],},
			wreckmodel = "strikecom_dead_3.dae",
		},
		commstrike5 = {
			level = 5,
			mainstats = {health = 6000, objectname = "strikecom_4.dae", collisionvolumescales  = [[60 72 60]],},
			customparams = {modelradius = [[36]],},
			wreckmodel = "strikecom_dead_4.dae",
		},
	},
}

local chassisAllDefs=VFS.Include("gamedata/modularcomms/chassises_all_defs.lua")

for i = 1, #chassisAllDefs do
	local chassisDef = chassisAllDefs[i].clonedefs
	for key, value in pairs(chassisDef) do
		copy[key]=value
	end
end
--[=[
VFS.Include("LuaRules/Utilities/wacky_utils.lua")
local utils=Spring.Utilities.wacky_utils
]=]
for sourceName, copyTable in pairs(copy) do
	for cloneName, stats in pairs(copyTable) do
		-- some further modification
		UnitDefs[cloneName] = CopyTable(UnitDefs[sourceName], true)
		UnitDefs[cloneName].unitname = cloneName
		
		if stats.level > 0 then
			stats.nomainstats=stats.nomainstats or {}
			-- copy from by-level table
			for statName, value in pairs(statsByLevel.mainstats[stats.level]) do
				if not stats.nomainstats[statName] then
					UnitDefs[cloneName][statName] = value
				end
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
			if UnitDefs[cloneName].featuredefs then
				UnitDefs[cloneName].featuredefs.dead.object = stats.wreckmodel or UnitDefs[cloneName].featuredefs.dead.object
				UnitDefs[cloneName].featuredefs.dead.footprintx = UnitDefs[cloneName].footprintx
				UnitDefs[cloneName].featuredefs.dead.footprintz = UnitDefs[cloneName].footprintz
				UnitDefs[cloneName].featuredefs.heap.object = stats.heapmodel or UnitDefs[cloneName].featuredefs.heap.object
				UnitDefs[cloneName].featuredefs.heap.footprintx = UnitDefs[cloneName].footprintx
				UnitDefs[cloneName].featuredefs.heap.footprintz = UnitDefs[cloneName].footprintz
			end
		end
		
		UnitDefs[cloneName].customparams.level = stats.level
		UnitDefs[cloneName].name = (UnitDefs[cloneName].name) .. " - Level " .. stats.level
		UnitDefs[cloneName].icontype = "commander"..stats.level
	end
end
