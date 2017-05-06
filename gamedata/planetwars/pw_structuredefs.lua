--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local STRUCTURE_COST_MULT = 4 -- Base cost matches planetwars metagame cost.

local fakeWeapondef = {
	name                    = [[Bogus Fake Targeter]],
	avoidGround             = false, -- avoid nothing, else attempts to move out to clear line of fine
	avoidFriendly           = false,
	avoidFeature            = false,
	avoidNeutral            = false,
	damage                  = {
		default = 11.34,
		planes  = 11.34,
		subs    = 0.567,
	},
	explosionGenerator      = [[custom:FLASHPLOSION]],
	noSelfDamage            = true,
	range                   = 300,
	reloadtime              = 1,
	tolerance               = 5000,
	turret                  = true,
	weaponType              = [[StarburstLauncher]],
	weaponVelocity          = 500,
}

local fakeWeapons = {
	{
		def                = "BOGUS_FAKE_TARGETER",
		badtargetcategory  = "FIXEDWING",
		onlytargetcategory = "FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER",
	},
}

local structureConfig = {
	generic_tech = function(unitDef)
		unitDef.maxdamage = 10000
		unitDef.objectname = "pw_techlab.obj"
		unitDef.script = "pw_techlab.lua"
		unitDef.footprintx = 8
		unitDef.footprintz = 9
		
		unitDef.buildpic = "pw_generic.png"
		
		unitDef.customparams.soundselect = "radar_select"
		unitDef.customparams.statsname = "generic_tech"
	end,

	pw_artefact = function(unitDef)
		unitDef.maxdamage = 100000
		unitDef.name = "Ancient Artefact"
		unitDef.description = "Mysterious Relic"
		unitDef.objectname = "pw_artefact.obj"
		unitDef.script = "pw_artefact.lua"
		unitDef.icontype = [[pw_special]]
		
		unitDef.footprintx = 4
		unitDef.footprintz = 4
		unitDef.buildcostmetal = 5000*STRUCTURE_COST_MULT
		
		unitDef.customparams.invincible = "1"
		unitDef.customparams.soundselect = "cloaker_select"
		
		unitDef.collisionvolumescales = [[60 70 60]]
		unitDef.collisionvolumetype	= [[CylY]]
		
		unitDef.featuredefs.dead.object = "pw_artefact_dead.dae"
	end,
	
	pw_dropfac = function(unitDef)
		unitDef.maxdamage = 25000
		unitDef.name = "Dropship Factory"
		unitDef.description = "Produces dropships"
		unitDef.objectname = "pw_dropfac.obj"
		unitDef.icontype = [[pw_dropfac]]
		unitDef.script = "pw_dropfac.lua"
		
		unitDef.footprintx = 20
		unitDef.footprintz = 16
		unitDef.buildcostmetal = 400*STRUCTURE_COST_MULT
		
		unitDef.customparams.soundselect = "building_select1"
		
		unitDef.collisionvolumescales = [[275 120 215]]
		
		-- builder-related stuff
		unitDef.showNanoSpray = false
		unitDef.builder = true
		unitDef.canmove = true
		unitDef.canattack = true
		unitDef.workertime = 10
		unitDef.buildoptions = { [[corvalk]], [[corbtrans]] }
		unitDef.customparams.nongroundfac = [[1]]
		unitDef.customparams.landflystate = [[0]]
		
		local yardmap = ""
		for i = 1, (unitDef.footprintx * unitDef.footprintz) do
			yardmap = yardmap .. "o"
		end
		unitDef.yardmap = yardmap
		
		unitDef.featuredefs.dead.object = "pw_dropfac_dead.dae"
		unitDef.featuredefs.heap.object = "debris8x8b.s3o"
	end,

	pw_bomberfac = function(unitDef)
		unitDef.maxdamage = 20000
		unitDef.name = "Bomber Factory"
		unitDef.description = "Produces bombers"
		unitDef.objectname = "pw_dropdepot.obj"
		unitDef.script = "pw_bomberfac.lua"
		unitDef.icontype = [[pw_bomberfac]]
		unitDef.waterline = 30
		
		unitDef.footprintx = 16
		unitDef.footprintz = 11
		unitDef.buildcostmetal = 400*STRUCTURE_COST_MULT
		
		unitDef.customparams.soundselect = "building_select1"
		
		unitDef.collisionvolumescales = [[240 160 120]]
		unitDef.collisionvolumeoffsets = [[0 -10 0]]
		
		-- builder-related stuff
		unitDef.showNanoSpray = false
		unitDef.builder = true
		unitDef.canmove = true
		unitDef.canattack = true
		unitDef.workertime = 10
		unitDef.buildoptions = { [[corshad]], [[corhurc2]], [[armstiletto_laser]], [[armcybr]] }
		unitDef.customparams.nongroundfac = [[1]]
		unitDef.customparams.landflystate = [[0]]
		
		local yardmap = ""
		for i = 1, (unitDef.footprintx * unitDef.footprintz) do
			yardmap = yardmap .. "o"
		end
		unitDef.yardmap = yardmap
		
		unitDef.buildpic = "pw_dropdepot.png"
		unitDef.featuredefs.dead.object = "pw_dropdepot_dead.dae"
		unitDef.featuredefs.heap.object = "debris8x8b.s3o"
	end,
	
	pw_mine = function(unitDef)
		unitDef.maxdamage = 10000
		unitDef.name = "Power Generator Unit"
		unitDef.description = "Produces 50 energy/turn" 
		unitDef.objectname = "pw_mine2.obj"
		unitDef.script = "pw_mine2.lua"
		unitDef.icontype = [[pw_energy]]
		
		unitDef.customparams = unitDef.customparams or {}
		unitDef.customparams.pylonrange = 300
		unitDef.customparams.removewait = 1
		unitDef.energymake = 4
		
		unitDef.footprintx = 7
		unitDef.footprintz = 7
		unitDef.buildcostmetal = 100*STRUCTURE_COST_MULT
		
		unitDef.collisionvolumescales = [[90 125 90]]
		
		unitDef.customparams.soundselect = "building_select2"
		
		unitDef.featuredefs.dead.object = "pw_mine2_dead.dae"
	end,
		
	pw_mine2 = function(unitDef)
		unitDef.maxdamage = 16000
		unitDef.name = "Orbital Solar Array"
		unitDef.description = "Produces 100 energy/turn" 
		unitDef.objectname = "pw_mine.obj"
		unitDef.script = "pw_mine.lua"
		
		unitDef.customparams = unitDef.customparams or {}
		unitDef.customparams.pylonrange = 400
		unitDef.customparams.removewait = 1
		unitDef.energymake = 6
		
		unitDef.footprintx = 4
		unitDef.footprintz = 4
		unitDef.buildcostmetal = 275*STRUCTURE_COST_MULT
		
		unitDef.collisionvolumescales = [[56 120 56]]
		unitDef.collisionvolumetype	= [[CylY]]
		unitDef.collisionvolumeoffsets = [[0 10 0]]
		
		unitDef.customparams.soundselect = "building_select2"
		
		unitDef.featuredefs.dead.object = "pw_mine_dead.dae"
		unitDef.featuredefs.heap.object = "debris4x4b.s3o"
	end,
		
	pw_mine3 = function(unitDef)
		unitDef.maxdamage = 24000
		unitDef.name = "Planetary Geothermal Tap"
		unitDef.description = "Produces 250 energy/turn" 
		unitDef.objectname = "pw_mine3.obj"
		unitDef.script = "pw_mine3.lua"
		unitDef.icontype = [[pw_energy2]]
		
		unitDef.customparams = unitDef.customparams or {}
		unitDef.customparams.pylonrange = 500
		unitDef.customparams.removewait = 1
		unitDef.energymake = 8
		
		unitDef.footprintx = 12
		unitDef.footprintz = 12
		unitDef.buildcostmetal = 625*STRUCTURE_COST_MULT
		
		unitDef.explodeas = "NUCLEAR_MISSILE"
		unitDef.selfdestructas = "NUCLEAR_MISSILE"
		
		unitDef.customparams.soundselect = "building_select2"
		
		unitDef.collisionvolumescales = [[130 130 130]]
		
		unitDef.featuredefs.dead.object = "pw_mine3_dead.dae"
	end,
		
	pw_garrison = function(unitDef)
		unitDef.maxdamage = 16000
		unitDef.name = "Field Garrison"
		unitDef.description = "Reduces Influence gain"
		unitDef.objectname = "pw_wormhole.obj"
		unitDef.icontype = [[pw_defense]]
		unitDef.script = "pw_wormhole.lua"
		
		unitDef.canattack = true
		unitDef.sightdistance = 330
		
		unitDef.footprintx = 11
		unitDef.footprintz = 6
		unitDef.buildcostmetal = 250*STRUCTURE_COST_MULT
		
		unitDef.customparams.soundselect = "factory_select"
		
		unitDef.weapondefs = {bogus_fake_targeter = CopyTable(fakeWeapondef, true)}
		unitDef.weapons = CopyTable(fakeWeapons, true)
		
		unitDef.collisionvolumescales = [[160 65 80]]
		
		unitDef.featuredefs.dead.object = "pw_wormhole_dead.dae"
	end,
		
	pw_interception = function(unitDef)
		unitDef.maxdamage = 16000
		unitDef.name = "Interception Network"
		unitDef.description = "Intercepts planetary bombers"
		unitDef.objectname = "pw_warpjammer.s3o"
		unitDef.script = "pw_warpjammer.lua"
		unitDef.icontype = [[pw_interception]]
		
		unitDef.footprintx = 6
		unitDef.footprintz = 6
		unitDef.buildcostmetal = 250*STRUCTURE_COST_MULT
		
		unitDef.customparams.soundselect = "radar_select"
		
		unitDef.sightdistance = 800
		unitDef.radardistance = 2100
		unitDef.radaremitheight = 150
		unitDef.losemitheight = 150
		unitDef.onoffable = true
		unitDef.energyuse = 0.8
		unitDef.customparams.priority_misc = 2
		
		unitDef.collisionvolumescales = [[100 80 100]]
		unitDef.collisionvolumetype	= [[Box]]
		
		unitDef.featuredefs.dead.object = "pw_warpjammer_dead.dae"
	end,
	
	pw_grid = function(unitDef)
		unitDef.maxdamage = 20000
		unitDef.name = "Planetary Defense Grid"
		unitDef.description = "Defends against everything"
		unitDef.objectname = "pw_wormhole2.obj"
		unitDef.icontype = [[pw_defense2]]
		unitDef.script = "pw_wormhole2.lua"
		
		unitDef.footprintx = 8
		unitDef.footprintz = 8
		unitDef.buildcostmetal = 750*STRUCTURE_COST_MULT
		
		unitDef.canattack = true
		unitDef.sightdistance = 495
		
		unitDef.customparams.soundselect = "turret_select"
		
		unitDef.weapondefs = {bogus_fake_targeter = CopyTable(fakeWeapondef, true)}
		unitDef.weapondefs.bogus_fake_targeter.range = 450
		unitDef.weapons = CopyTable(fakeWeapons, true)
		
		unitDef.collisionvolumescales = [[100 90 100]]
		unitDef.collisionvolumetype	= [[CylY]]
		
		unitDef.featuredefs.dead.object = "pw_wormhole2_dead.dae"
	end,
	
	pw_wormhole = function(unitDef)
		unitDef.maxdamage = 12500
		unitDef.name = "Wormhole Generator"
		unitDef.description = "Links this planet to nearby planets"
		unitDef.objectname = "pw_estorage.obj"
		unitDef.icontype = [[pw_wormhole]]
		
		unitDef.footprintx = 3
		unitDef.footprintz = 3
		unitDef.buildcostmetal = 75*STRUCTURE_COST_MULT
		
		unitDef.customparams.evacuation_speed = "1"
		
		unitDef.customparams.soundselect = "shield_select"
		
		unitDef.collisionvolumescales = [[40 45 40]]
		unitDef.collisionvolumetype	= [[CylY]]
		
		unitDef.featuredefs.dead.object = "pw_estorage_dead.dae"
	end,
	
	pw_wormhole2 = function(unitDef)
		unitDef.maxdamage = 17500
		unitDef.name = "Improved Wormhole"
		unitDef.description = "Links this planet to nearby planets"
		unitDef.objectname = "pw_gaspowerstation.obj"
		unitDef.script = "pw_gaspowerstation.lua"
		unitDef.icontype = [[pw_wormhole2]]
		
		unitDef.footprintx = 6
		unitDef.footprintz = 6
		unitDef.buildcostmetal = 250*STRUCTURE_COST_MULT
		
		unitDef.customparams.evacuation_speed = "2"
		
		unitDef.customparams.pw_replaces = "pw_wormhole"
		unitDef.customparams.soundselect = "shield_select"
		
		unitDef.collisionvolumescales = [[70 60 70]]
		unitDef.collisionvolumetype	= [[CylY]]
		
		unitDef.featuredefs.dead.object = "pw_gaspowerstation_dead.dae"
	end,
	
	pw_warpgate = function(unitDef)
		unitDef.maxdamage = 15000
		unitDef.name = "Warp Gate"
		unitDef.description = "Produces warp cores"
		unitDef.objectname = "pw_techlab.obj"
		unitDef.script = "pw_techlab.lua"
		unitDef.icontype = [[pw_warpgate]]
		
		unitDef.footprintx = 8
		unitDef.footprintz = 9
		unitDef.buildcostmetal = 500*STRUCTURE_COST_MULT
		
		unitDef.customparams.soundselect = "cloaker_select"
		
		unitDef.featuredefs.dead.object = "pw_techlab_dead.dae"
	end,
	
	pw_warpjammer = function(unitDef)
		unitDef.maxdamage = 12000
		unitDef.name = "Warp Jammer"
		unitDef.description = "Prevents warp attacks"
		unitDef.objectname = "pw_warpgate.obj"
		unitDef.script = "pw_warpgate.lua"
		unitDef.icontype = [[pw_jammer]]
		
		unitDef.footprintx = 8
		unitDef.footprintz = 8
		unitDef.buildcostmetal = 300*STRUCTURE_COST_MULT
		
		unitDef.explodeas = "GRAV_BLAST"
		unitDef.selfdestructas = "GRAV_BLAST"
		
		unitDef.customparams.soundselect = "radar_select"
		
		unitDef.customparams.area_cloak = 1
		unitDef.customparams.area_cloak_upkeep = 12
		unitDef.customparams.area_cloak_radius = 550
		unitDef.customparams.area_cloak_decloak_distance = 75
		unitDef.radardistancejam = 550
		unitDef.onoffable = true
		unitDef.energyuse = 1.5
		unitDef.customparams.priority_misc = 2
		
		unitDef.collisionvolumescales = [[120 100 120]]
		unitDef.collisionvolumetype	= [[CylY]]
		
		unitDef.featuredefs.dead.object = "pw_warpgate_dead.dae"
	end,

	pw_inhibitor = function(unitDef)
		unitDef.maxdamage = 15000
		unitDef.name = "Wormhole Inhibitor"
		unitDef.description = "Blocks Influence Spread"
		unitDef.objectname = "pw_mstorage2.obj"
		unitDef.icontype = [[pw_riot]]
		
		unitDef.footprintx = 7
		unitDef.footprintz = 5
		unitDef.buildcostmetal = 350*STRUCTURE_COST_MULT
		
		unitDef.customparams.soundselect = "shield_select"
		
		unitDef.collisionvolumescales = [[80 25 60]]
		unitDef.collisionvolumetype	= [[Box]]
		
		unitDef.featuredefs.dead.object = "pw_mstorage2_dead.dae"
	end,
	
	pw_guerilla = function(unitDef)
		unitDef.maxdamage = 15000
		unitDef.name = "Guerilla Jumpgate"
		unitDef.description = "Spreads Influence remotely"
		unitDef.objectname = "pw_gaspowerstation.obj"
		unitDef.script = "pw_gaspowerstation.lua"
		
		unitDef.footprintx = 6
		unitDef.footprintz = 6
		unitDef.buildcostmetal = 750*STRUCTURE_COST_MULT
		
		unitDef.customparams.soundselect = "shield_select"
		
		unitDef.collisionvolumescales = [[70 60 70]]
		unitDef.collisionvolumetype	= [[CylY]]
		
		unitDef.featuredefs.dead.object = "pw_gaspowerstation_dead.dae"
	end,
	
	------------------------------------------------------------------------
	-- the following are presently just for missions
	------------------------------------------------------------------------
	pw_gaspowerstation = function(unitDef)
		unitDef.maxdamage = 15000
		unitDef.name = "Gas Power Station"
		unitDef.description = "Produces Energy"
		unitDef.objectname = "pw_gaspowerstation.obj"
		unitDef.script = "pw_gaspowerstation.lua"
		
		unitDef.footprintx = 6
		unitDef.footprintz = 6
		
		unitDef.customparams.soundselect = "geo_select"
		
		unitDef.collisionvolumescales = [[70 60 70]]
		unitDef.collisionvolumetype	= [[CylY]]
		
		unitDef.featuredefs.dead.object = "pw_gaspowerstation_dead.dae"
	end,
	
	pw_mstorage2 = function(unitDef)
		unitDef.maxdamage = 15000
		unitDef.name = "Metal Storage"
		unitDef.description = "Stores metal"
		unitDef.objectname = "pw_mstorage2.obj"
		
		unitDef.footprintx = 7
		unitDef.footprintz = 5
		
		--unitDef.customparams.soundselect = "shield_select"
		unitDef.customparams.helptext = "Stores a large quantity of metal for planetary use."
		
		unitDef.collisionvolumescales = [[80 25 60]]
		unitDef.collisionvolumetype	= [[Box]]
		
		unitDef.featuredefs.dead.object = "pw_mstorage2_dead.dae"
	end,
	
	pw_estorage = function(unitDef)
		unitDef.maxdamage = 10000
		unitDef.name = "Energy Storage"
		unitDef.description = "Stores energy"
		unitDef.objectname = "pw_estorage.obj"
		
		unitDef.footprintx = 3
		unitDef.footprintz = 3
		
		unitDef.customparams.soundselect = "fusion_select"
		unitDef.customparams.helptext = "A large capacitor bank."
		
		unitDef.collisionvolumescales = [[40 45 40]]
		unitDef.collisionvolumetype	= [[CylY]]
		
		unitDef.featuredefs.dead.object = "pw_estorage_dead.dae"
	end,
	
	pw_estorage2 = function(unitDef)
		unitDef.maxdamage = 15000
		unitDef.name = "Double Energy Storage"
		unitDef.description = "Stores energy"
		unitDef.objectname = "pw_estorage2.obj"
		
		unitDef.footprintx = 5
		unitDef.footprintz = 3
		
		unitDef.customparams.soundselect = "fusion_select"
		unitDef.customparams.helptext = "A large double capacitor bank."
		
		unitDef.collisionvolumescales = [[60 45 40]]
		unitDef.collisionvolumetype	= [[Box]]
		
		unitDef.featuredefs.dead.object = "pw_estorage2_dead.dae"
	end,
	
	pw_warpgatealt = function(unitDef)
		unitDef.maxdamage = 15000
		unitDef.name = "Warp Gate"
		unitDef.description = "Produces warp cores"
		unitDef.objectname = "pw_warpgate.obj"
		unitDef.script = "pw_warpgate.lua"
		
		unitDef.footprintx = 8
		unitDef.footprintz = 8
		
		unitDef.explodeas = "GRAV_BLAST"
		unitDef.selfdestructas = "GRAV_BLAST"
		
		unitDef.customparams.soundselect = "cloaker_select"
		unitDef.customparams.statsname = "pw_warpgate"
		
		unitDef.collisionvolumescales = [[120 100 120]]
		unitDef.collisionvolumetype	= [[CylY]]
		
		unitDef.featuredefs.dead.object = "pw_warpgate_dead.dae"
	end,
}

return structureConfig
