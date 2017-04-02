--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

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
	range                   = 800,
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
			unitDef.customparams.helptext = "This structure unlocks a specific tech for its owning faction."
			unitDef.customparams.description_pl = "Stacja badawcza"
			unitDef.customparams.helptext_pl = "Ten budynek odblokowuje konkretna technologie dla swojej frakcji."
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
			
			unitDef.customparams.soundselect = "cloaker_select"
			unitDef.customparams.helptext = "This mysterious alien device houses unimaginable powers. Although it remains poorly understood by our scientists, "
							.."it could potentially be harnessed as a galaxy-dominating superweapon. The artefact is invulnerable to all known weapons."
			unitDef.customparams.helptext_pl = "Te tajemnicze artefakty obcych skrywaja niesamowita moc. Chociaz naukowcy nie rozumieja do konca zasady ich dzialania, to uwaza sie, "
							.."ze moga posluzyc za bron zdolna do dominacji nad galaktyka. Artefakt jest niewrazliwy na wszystkie znane rodzaje broni."
			unitDef.customparams.description_pl = "Artefakt obcych"
			
			unitDef.collisionvolumescales = [[60 70 60]]
			unitDef.collisionvolumetype	= [[CylY]]			
		end,		
		
	pw_dropfac = function(unitDef)
		unitDef.maxdamage = 25000
		unitDef.name = "Dropship Fabricator"
		unitDef.description = "Produces dropships"
		unitDef.objectname = "pw_dropfac.obj"
		unitDef.icontype = [[pw_dropfac]]
		unitDef.script = "pw_dropfac.lua"
		
		unitDef.footprintx = 20			
		unitDef.footprintz = 16
		
		unitDef.customparams.soundselect = "building_select1"
		unitDef.customparams.helptext = "Produces space dropships for invading hostile planets."
		--unitDef.customparams.helptext_pl = "Produkuje desantowce orbitalne do inwazji na wrogie planety."
		--unitDef.customparams.description_pl = "Produkuje desantowce"
		
		unitDef.collisionvolumescales = [[275 120 215]]
		unitDef.modelcenteroffset = [[0 00 0]]
		
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
		
		unitDef.customparams.soundselect = "building_select1"
		unitDef.customparams.helptext = "Increases the number of bombers that can be deployed to a single planet."
		
		unitDef.collisionvolumescales = [[225 140 120]]
		unitDef.collisionvolumeoffsets = [[-20 -30 0]]
		unitDef.modelcenteroffset = [[15 30 0]]
		
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
	end,
	
	pw_mine = function(unitDef)
			unitDef.maxdamage = 10000
			unitDef.name = "Power Generator Unit"
			unitDef.description = "Produces 50 energy/turn" 
			unitDef.objectname = "pw_mine2.obj"
			unitDef.script = "pw_mine2.lua"
			unitDef.icontype = [[pw_energy]]
			
			unitDef.footprintx = 7
			unitDef.footprintz = 7
			
			unitDef.collisionvolumescales = [[90 125 90]]
			unitDef.modelcenteroffset = [[0 10 0]]
			
			unitDef.customparams.soundselect = "building_select2"
			unitDef.customparams.helptext = "A small, efficient power generator."
			unitDef.customparams.helptext_pl = "Maly, efektywny generator planetarny."
			unitDef.customparams.description_pl = "Wytwarza 50 energii/ture"
			
			unitDef.customparams.base_economy_boost = "0.02"
		end,
		
	pw_mine2 = function(unitDef)
			unitDef.maxdamage = 16000
			unitDef.name = "Orbital Solar Array"
			unitDef.description = "Produces 100 energy/turn" 
			unitDef.objectname = "pw_mine.obj"
			unitDef.script = "pw_mine.lua"
			
			unitDef.footprintx = 4
			unitDef.footprintz = 4
			
			
			unitDef.collisionvolumescales = [[56 120 56]]
			unitDef.modelcenteroffset = [[0 10 0]]
			unitDef.collisionvolumetype	= [[CylY]]
			
			unitDef.customparams.soundselect = "building_select2"
			unitDef.customparams.helptext = "A larger power generator with increased output."
			unitDef.customparams.helptext_pl = "Sredni generator planetarny."
			unitDef.customparams.description_pl = "Wytwarza 100 energii/ture"
		end,
		
	pw_mine3 = function(unitDef)
			unitDef.maxdamage = 24000
			unitDef.name = "Planetary Geothermal Tap"
			unitDef.description = "Produces 250 energy/turn" 
			unitDef.objectname = "pw_mine3.obj"
			unitDef.script = "pw_mine3.lua"
			unitDef.icontype = [[pw_energy2]]
			
			unitDef.footprintx = 12		
			unitDef.footprintz = 12
			
			unitDef.explodeas = "NUCLEAR_MISSILE"
			unitDef.selfdestructas = "NUCLEAR_MISSILE"
			
			unitDef.customparams.soundselect = "building_select2"
			unitDef.customparams.helptext = "This massive complex draws energy directly from the planet's mantle. It goes up in a nuclear explosion if destroyed."
			unitDef.customparams.helptext_pl = "Planetarny kompleks energetyczny. Uzywa glownie mocy geotermicznych, ale takze nuklearnych, co powoduje niebezpieczenstwo wybuchu w razie zniszczenia."
			unitDef.customparams.description_pl = "Wytwarza 250 energii/ture."
			
			unitDef.collisionvolumescales = [[130 130 130]]
			unitDef.modelcenteroffset = [[0 10 0]]
			
			unitDef.customparams.base_economy_boost = "0.04"
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
		
		unitDef.customparams.soundselect = "factory_select"
		unitDef.customparams.helptext = "This structure maintains an army which reduces the Influence gained from battles."
		unitDef.customparams.helptext_pl = "Garnizon sprawuje piecze nad planeta, ograniczajac wrogie wplywy zyskane z bitew."
		unitDef.customparams.description_pl = "Garnizon - ogranicza wplywy"
		
		unitDef.weapondefs = {bogus_fake_targeter = CopyTable(fakeWeapondef, true)}
		unitDef.weapons = CopyTable(fakeWeapons, true)
		
		unitDef.collisionvolumescales = [[160 65 80]]
		unitDef.modelcenteroffset = [[0 30 0]]					
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
		
		unitDef.customparams.soundselect = "radar_select"
		unitDef.customparams.helptext = "This structure intercepts incoming bombers."
		unitDef.customparams.helptext_pl = "Ten budynek przechwytuje nadlatujace bombowce orbitalne."
		unitDef.customparams.description_pl = "Przechwytuje bombowce orbitalne."
		
		unitDef.sightdistance = 800
		unitDef.radardistance = 2100
		unitDef.radaremitheight = 150
		unitDef.losemitheight = 150
		unitDef.onoffable = true
		unitDef.energyuse = 0.8
		unitDef.customparams.priority_misc = 2
		
		unitDef.collisionvolumescales = [[100 80 100]]
		unitDef.modelcenteroffset = [[0 0 0]]
		unitDef.collisionvolumetype	= [[Box]]
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
		
		unitDef.canattack = true
		unitDef.sightdistance = 385
		
		unitDef.customparams.soundselect = "turret_select"
		unitDef.customparams.helptext = "This structure reduces Influence gains as well as intercepting incoming bombers."
		unitDef.customparams.helptext_pl = "Ten budynek zmniejsza wrogie wplywy z bitew i przechwytuje bombowce orbitalne."
		unitDef.customparams.description_pl = "Kompleks ochrony planetarnej"
		
		unitDef.weapondefs = {bogus_fake_targeter = CopyTable(fakeWeapondef, true)}
		unitDef.weapons = CopyTable(fakeWeapons, true)
		
		unitDef.collisionvolumescales = [[100 90 100]]
		unitDef.modelcenteroffset = [[0 20 0]]
		unitDef.collisionvolumetype	= [[CylY]]
	end,
		
	pw_wormhole = function(unitDef)
			unitDef.maxdamage = 12500
			unitDef.name = "Wormhole Generator Beacon"
			unitDef.description = "Links this planet to nearby planets"
			unitDef.objectname = "pw_estorage.obj"
			unitDef.icontype = [[pw_wormhole]]
			
			unitDef.footprintx = 3
			unitDef.footprintz = 3
			
			unitDef.customparams.evacuation_speed = "2"
			
			unitDef.customparams.soundselect = "shield_select"
			unitDef.customparams.helptext = "Allows ships to leave this planet for its connected neighbours, and projects influence spread to connected planets."
			unitDef.customparams.helptext_pl = "Tunel czasoprzestrzenny laczy planete z sasiadami - pozwala statkom orbitalnym opuszczac planete i szerzy wplywy."
			unitDef.customparams.description_pl = "Tunel czasoprzestrzenny"
			
			unitDef.collisionvolumescales = [[40 45 40]]
			unitDef.modelcenteroffset = [[0 0 0]]
			unitDef.collisionvolumetype	= [[CylY]]
		end,
		
	pw_wormhole2 = function(unitDef)
			unitDef.maxdamage = 17500
			unitDef.name = "Improved Wormhole Stabilizer"
			unitDef.objectname = "pw_gaspowerstation.obj"
			unitDef.script = "pw_gaspowerstation.lua"
			unitDef.icontype = [[pw_wormhole2]]
			
			unitDef.footprintx = 6
			unitDef.footprintz = 6
			
			unitDef.customparams.evacuation_speed = "4"
			
			unitDef.customparams.soundselect = "shield_select"
			unitDef.customparams.helptext = "This structure maintains a stronger wormhole for increased influence spread to neighboring planets."
			unitDef.customparams.helptext_pl = "Ulepszony tunel czasoprzestrzenny zwieksza wplywy na polaczonych planetach."
			unitDef.customparams.description_pl = "Ulepszony tunel czasoprzestrzenny"
			
			unitDef.collisionvolumescales = [[70 60 70]]
			unitDef.modelcenteroffset = [[0 0 0]]
			unitDef.collisionvolumetype	= [[CylY]]
		end,
		
	pw_warpgate = function(unitDef)
			unitDef.maxdamage = 15000
			unitDef.name = "Warp Core Fabricator"
			unitDef.description = "Produces warp cores"
			unitDef.objectname = "pw_techlab.obj"
			unitDef.script = "pw_techlab.lua"
			unitDef.icontype = [[pw_warpgate]]
			
			unitDef.footprintx = 8		
			unitDef.footprintz = 9
			
			unitDef.customparams.soundselect = "cloaker_select"
			unitDef.customparams.helptext = "This facility produces the coveted Warp Cores that can send ships across the galaxy in the blink of an eye."	
			unitDef.customparams.helptext_pl = "Tutaj produkowane sa Rdzenie Czasoprzestrzenne, ktore pozwalaja wysylac statki w dowolne miejsce w galaktyce w mgnieniu oka."	
			unitDef.customparams.description_pl = "Produkuje Rdzenie Czasoprzestrzenne"				
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
		
		unitDef.explodeas = "GRAV_BLAST"
		unitDef.selfdestructas = "GRAV_BLAST"
		
		unitDef.customparams.soundselect = "radar_select"
		unitDef.customparams.helptext = "The Warp Jammer protects the planet with a field that prevents warpcore-equipped ships from jumping to it."
		unitDef.customparams.helptext_pl = "Zagluszacz czasoprzestrzenny nie pozwala na skok czasoprzestrzenny przy uzyciu Rdzeni na ta planete."
		unitDef.customparams.description_pl = "Zagluszacz czasoprzestrzenny"
		
		unitDef.customparams.area_cloak = 1
		unitDef.customparams.area_cloak_upkeep = 12
		unitDef.customparams.area_cloak_radius = 550
		unitDef.customparams.area_cloak_decloak_distance = 75
		unitDef.radardistancejam = 550
		unitDef.onoffable = true
		unitDef.energyuse = 1.5
		unitDef.customparams.priority_misc = 2
		
		unitDef.collisionvolumescales = [[120 100 120]]
		unitDef.modelcenteroffset = [[0 0 0]]
		unitDef.collisionvolumetype	= [[CylY]]
	end,

	pw_inhibitor = function(unitDef)
			unitDef.maxdamage = 15000
			unitDef.name = "Wormhole Inhibitor"
			unitDef.description = "Blocks Influence Spread"
			unitDef.objectname = "pw_mstorage2.obj"
			unitDef.icontype = [[pw_riot]]
			
			unitDef.footprintx = 7
			unitDef.footprintz = 5
			
			unitDef.customparams.soundselect = "shield_select"
			unitDef.customparams.helptext = "Inhibits Influence spread from enemy planets."
			unitDef.customparams.helptext_pl = "Nie pozwala wrogim planetom szerzyc wplywow przez tunel czasoprzestrzenny."
			unitDef.customparams.description_pl = "Inhibitor tunelu czasoprzestrzennego"
			
			unitDef.collisionvolumescales = [[80 25 60]]
			unitDef.modelcenteroffset = [[0 0 0]]
			unitDef.collisionvolumetype	= [[Box]]					
		end,
	pw_guerilla = function(unitDef)
			unitDef.maxdamage = 15000
			unitDef.name = "Guerilla Jumpgate"
			unitDef.description = "Spreads Influence remotely"
			unitDef.objectname = "pw_gaspowerstation.obj"
			unitDef.script = "pw_gaspowerstation.lua"
			
			unitDef.footprintx = 6
			unitDef.footprintz = 6
			
			unitDef.customparams.soundselect = "shield_select"
			unitDef.customparams.helptext = "A jumpgate capable of sending Influence to any planet."
			unitDef.customparams.helptext_pl = "Ten budynek pozwala szerzyc wplywy na dowolnej innej planecie."
			unitDef.customparams.description_pl = "Zdalnie szerzy wplywy"
			
			unitDef.collisionvolumescales = [[70 60 70]]
			unitDef.modelcenteroffset = [[0 0 0]]
			unitDef.collisionvolumetype	= [[CylY]]					
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
			unitDef.customparams.helptext = "A gas-fired power generator."
			
			unitDef.collisionvolumescales = [[70 60 70]]
			unitDef.modelcenteroffset = [[0 0 0]]
			unitDef.collisionvolumetype	= [[CylY]]					
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
			unitDef.modelcenteroffset = [[0 0 0]]
			unitDef.collisionvolumetype	= [[Box]]					
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
			unitDef.modelcenteroffset = [[0 0 0]]
			unitDef.collisionvolumetype	= [[CylY]]					
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
			unitDef.modelcenteroffset = [[0 0 0]]
			unitDef.collisionvolumetype	= [[Box]]					
		end,
	pw_warpgatealt = function(unitDef)
			unitDef.maxdamage = 15000
			unitDef.name = "Warp Core Fabricator"
			unitDef.description = "Produces warp cores"
			unitDef.objectname = "pw_warpgate.obj"
			unitDef.script = "pw_warpgate.lua"
			
			unitDef.footprintx = 8
			unitDef.footprintz = 8
			
			unitDef.explodeas = "GRAV_BLAST"
			unitDef.selfdestructas = "GRAV_BLAST"
			
			unitDef.customparams.soundselect = "cloaker_select"
			unitDef.customparams.helptext = "This facility produces the coveted Warp Cores that can send ships across the galaxy in the blink of an eye."	
			unitDef.customparams.helptext_pl = "Tutaj produkowane sa Rdzenie Czasoprzestrzenne, ktore pozwalaja wysylac statki w dowolne miejsce w galaktyce w mgnieniu oka."	
			unitDef.customparams.description_pl = "Produkuje Rdzenie Czasoprzestrzenne"
			
			unitDef.collisionvolumescales = [[120 100 120]]
			unitDef.modelcenteroffset = [[0 0 0]]
			unitDef.collisionvolumetype	= [[CylY]]	
		end,
}

return structureConfig
