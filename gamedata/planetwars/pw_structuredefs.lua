--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

structureConfig = {
	
	generic_tech = function(unitDef)
			unitDef.maxdamage = 35000
			unitDef.objectname = "pw_techlab.obj"
			unitDef.script = "pw_techlab.lua"
			unitDef.footprintx = 8		
			unitDef.footprintz = 9
			
			unitDef.buildpic = "pw_generic.png"
			
			unitDef.customparams.soundselect = "radar_select"
		end,

	pw_artefact = function(unitDef)
			unitDef.maxdamage = 100000
			unitDef.name = "Ancient Artefact"
			unitDef.description = "Mysterious Relic"
			unitDef.objectname = "pw_artefact.obj"
			unitDef.script = "pw_artefact.lua"
			
			unitDef.footprintx = 4			
			unitDef.footprintz = 4
			
			unitDef.customparams.soundselect = "cloaker_select"
			unitDef.canselfdestruct = false
		end,		
		
	pw_dropfac = function(unitDef)
			unitDef.maxdamage = 50000
			unitDef.name = "Dropship Factory"
			unitDef.description = "Produces 1 free dropship per turn"
			unitDef.objectname = "pw_dropfac.obj"
			
			unitDef.footprintx = 20			
			unitDef.footprintz = 16
			
			unitDef.customparams.soundselect = "building_select1"
		end,
		
	pw_dropdepot = function(unitDef)
			unitDef.maxdamage = 40000
			unitDef.name = "Dropship Hangar"
			unitDef.description = "Increases dropship capacity by 3"
			unitDef.objectname = "pw_dropdepot.obj"
			unitDef.waterline = 30
			
			unitDef.footprintx = 16			
			unitDef.footprintz = 11
			
			unitDef.customparams.soundselect = "building_select1"
		end,
		
	pw_mine = function(unitDef)
			unitDef.maxdamage = 20000
			unitDef.name = "Mining Outpost"
			unitDef.description = "Produces 50 credits/turn" 
			unitDef.objectname = "pw_mine.obj"
			unitDef.script = "pw_mine.lua"
			
			unitDef.footprintx = 4		
			unitDef.footprintz = 4
			
			unitDef.explodeas = "ESTOR_BUILDING"
			unitDef.selfdestructas = "ESTOR_BUILDING"
			
			unitDef.customparams.soundselect = "building_select2"
		end,
		
	pw_mine2 = function(unitDef)
			unitDef.maxdamage = 32000
			unitDef.name = "Automated Mines"
			unitDef.description = "Produces 150 credits/turn" 
			unitDef.objectname = "pw_mine2.obj"
			unitDef.script = "pw_mine2.lua"
			
			unitDef.footprintx = 7
			unitDef.footprintz = 7
			
			unitDef.customparams.soundselect = "building_select2"
		end,
		
	pw_mine3 = function(unitDef)
			unitDef.maxdamage = 45000
			unitDef.name = "Planetary Mining Complex"
			unitDef.description = "Produces 450 credits/turn" 
			unitDef.objectname = "pw_mine3.obj"
			unitDef.script = "pw_mine3.lua"
			
			unitDef.footprintx = 12		
			unitDef.footprintz = 12
			
			unitDef.explodeas = "NUCLEAR_MISSILE"
			unitDef.selfdestructas = "NUCLEAR_MISSILE"
			
			unitDef.customparams.soundselect = "building_select2"
		end,
		
	pw_wormhole = function(unitDef)
			unitDef.maxdamage = 25000
			unitDef.name = "Basic Wormhole Generator"
			unitDef.description = "Links this planet to nearby planets with 25% influence"
			unitDef.objectname = "pw_wormhole.obj"
			
			unitDef.footprintx = 11
			unitDef.footprintz = 6
			
			unitDef.customparams.soundselect = "shield_select"
		end,
		
	pw_wormhole2 = function(unitDef)
			unitDef.maxdamage = 35000
			unitDef.name = "Improved Wormhole Stabilizer"
			unitDef.description = "Improved link to nearby planets with 50% influence"
			unitDef.objectname = "pw_wormhole2.obj"
			
			unitDef.footprintx = 9
			unitDef.footprintz = 9
			
			unitDef.customparams.soundselect = "shield_select"
		end,
		
	pw_warpgate = function(unitDef)
			unitDef.maxdamage = 30000
			unitDef.name = "Warpgate"
			unitDef.description = "Allows planet owner to send drops to any point in the galaxy"
			unitDef.objectname = "pw_warpgate.obj"
			unitDef.script = "pw_warpgate.lua"
			
			unitDef.footprintx = 10
			unitDef.footprintz = 10
			
			unitDef.explodeas = "GRAV_BLAST"
			unitDef.selfdestructas = "GRAV_BLAST"
			
			unitDef.customparams.soundselect = "cloaker_select"
		end,
}

