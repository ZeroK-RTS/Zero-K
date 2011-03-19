-- $Id: explosion_spawn_defs.lua 4050 2009-03-09 02:56:38Z midknight $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--Lists post-processing weapon names and the units to spawn when they go off

local spawn_defs = {
    corhurc_minebomb   = {name = "cormine_impulse", cost = 0, expire = 60},
	armcent_droppod = {name = "armpw", cost=0, expire=0},
	armpnix3_armadvbomb = {name = "armflea", cost=0, expire=0},
	cormine_cortruck_missile = {name = "corareamine", cost=0, expire=0},
	chicken_blimpy_dodobomb = {name = "chicken_dodo", cost=0, expire=30},
	corgarp_mine = {name = "wolverine_mine", cost=0, expire=60},
	
	chickenflyerqueen_dodobomb = {name = "chicken_dodo", cost=0, expire=30},
	chickenflyerqueen_basiliskbomb = {name = "chickenc", cost=0, expire=0},
	chickenflyerqueen_tiamatbomb = {name = "chicken_tiamat", cost=0, expire=0},
}

local shieldCollide = { -- unitDefs as the shield hit callin is setup really strangely
	corgarp = {damage = 220, gadgetDamage = 200}, -- gadgetDamage = damage - weapon default damage
}

return spawn_defs, shieldCollide
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
