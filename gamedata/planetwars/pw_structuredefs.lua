--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

structureConfig = {
	
	generic_tech = function(unitDef)
			unitDef.maxdamage = 30000
		end,
		
	pw_mine2 = function(unitDef)
			unitDef.maxdamage = 30000
			unitDef.name = "Planetary Mine Level 2"
			unitDef.description = "Gives the owner moderate credit income" 
		end,
	pw_wormhole = function(unitDef)
			unitDef.maxdamage = 30000
			unitDef.name = "Basic Wormhole Generator"
			unitDef.description = "Links this planet to nearby planets" 
		end,
	pw_warpgate = function(unitDef)
			unitDef.maxdamage = 30000
			unitDef.name = "Warpgate"
			unitDef.description = "Allows the owner to send drops to any point in the galaxy" 
		end,
	
	


}

