-----------------------------------------------------------------------------
-- Tiberium01
-----------------------------------------------------------------------------
local featureDef	=	{
	name				= "ore_tiberium1",
	blocking			= true,
	category			= "rocks",
	damage				= 125000,
	description			= "Tiberium Crystal",
	energy				= 0,
	flammable			= 0,
	footprintX			= 2,
	footprintZ			= 2,
	height				= 27,
	hitdensity			= "5",
	indestructible			= true, 
	metal				= 1,
	object				= "tiberium01.s3o",
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

