-----------------------------------------------------------------------------
-- Tiberium03
-----------------------------------------------------------------------------
local featureDef	=	{
	name				= "ore_tiberium2",
	blocking			= true,
	category			= "rocks",
	damage				= 125000,
	description			= "Crystal Ore",
	energy				= 0,
	flammable			= 0,
	footprintX			= 2,
	footprintZ			= 2,
	height				= 27,
	hitdensity			= "5",
	indestructible			= true, 
	metal				= 1,
	object				= "tiberium03.s3o",
	reclaimable			= true,
	autoreclaimable			= true,
	blocking			= false;
	upright				= false;
	world				= "All Worlds",
	customparams = { 
		randomrotate		= "true", 
	}, 
}
return lowerkeys({[featureDef.name] = featureDef})

