-- $Id: explosion_spawn_defs.lua 4050 2009-03-09 02:56:38Z midknight $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--Lists post-processing weapon names and the units to spawn when they go off

local spawn_defs = {
	chicken_blimpy_dodobomb = {name = "chicken_dodo", cost=0, expire=30},
	veharty_mine = {name = "wolverine_mine", cost=0, expire=60},
	hoverminer_mine = {name = "wolverine_mine", cost=0, expire=60},
	zenith_meteor = {name = "asteroid_dead", cost=0, expire=0, feature = true},
	zenith_meteor_float = {name = "asteroid_dead", cost=0, expire=0, feature = true},
	zenith_meteor_aim = {name = "asteroid_dead", cost=0, expire=0, feature = true},
	zenith_meteor_uncontrolled = {name = "asteroid_dead", cost=0, expire=0, feature = true},

	chickenflyerqueen_dodobomb = {name = "chicken_dodo", cost=0, expire=30},
	chickenflyerqueen_basiliskbomb = {name = "chickenc", cost=0, expire=0},
	chickenflyerqueen_tiamatbomb = {name = "chicken_tiamat", cost=0, expire=0},
	chickenlandqueen_dodobomb = {name = "chicken_dodo", cost=0, expire=30},
	chickenlandqueen_basiliskbomb = {name = "chickenc", cost=0, expire=0},
	chickenlandqueen_tiamatbomb = {name = "chicken_tiamat", cost=0, expire=0},
}

local shieldCollide = { -- unitDefs as the shield hit callin is setup really strangely
	veharty_mine = {damage = 220, gadgetDamage = 200}, -- gadgetDamage = damage - weapon default damage
	-- Weapon name must be used
}

return spawn_defs, shieldCollide
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
