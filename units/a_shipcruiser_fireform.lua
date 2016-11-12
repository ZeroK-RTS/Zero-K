unitDef = {
  unitname               = [[a_shipcruiser_fireform]],
  name                   = [[Cavalier (Napalm)]],
  description            = [[Morphable Cruiser (Artillery)]],
  acceleration           = 0.0417,
  activateWhenBuilt      = true,
  brakeRate              = 0.142,
  buildCostEnergy        = 850,
  buildCostMetal         = 850,
  builder                = false,
  buildPic               = [[armroy_fire.png]],
  buildTime              = 850,
  canAttack              = true,
  canMove                = true,
  category               = [[SHIP]],
  collisionVolumeOffsets = [[0 1 3]],
  collisionVolumeScales  = [[32 32 132]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],

  customParams           = {
    helptext       = [[This morphed Cruiser packs a long-range napalm cannon, useful for bombarding larger groups of enemies. Beware of aircraft, submarines and raider ships.]],

    extradrawrange = 200,
    modelradius    = [[17]],
    turnatfullspeed = [[1]],
	
	morphto = [[a_shipcruiser]],
    morphtime = [[10]],
  },

  explodeAs              = [[BIG_UNITEX]],
  floater                = true,
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[a_shipcruiser]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  losEmitHeight          = 25,
  maxDamage              = 3000,
  maxVelocity            = 1.7,
  minCloakDistance       = 75,
  minWaterDepth          = 10,
  movementClass          = [[BOAT4]],
  noChaseCategory        = [[TERRAFORM FIXEDWING GUNSHIP TOOFAST]],
  objectName             = [[armroy.s3o]],
  script                 = [[a_shipcruiser.cob]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],
  sightDistance          = 660,
  sonarDistance          = 660,
  turninplace            = 0,
  turnRate               = 350,
  waterline              = 0,

  weapons                = {

    {
      def                = [[NAPALM_MORTAR]],
      badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SHIP SINK TURRET FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs             = {

	NAPALM_MORTAR = {
      name                    = [[Napalm Cannon]],
      accuracy                = 400,
      areaOfEffect            = 196,
	  avoidFeature            = false,
	  cegTag                  = [[custom:gravityless_flamer]],
      craterBoost             = 1,
      craterMult              = 2,
      
	  customParams        	  = {
	    setunitsonfire = "1",
		burntime = 60,

		area_damage = 1,
		area_damage_radius = 128,
		area_damage_dps = 20,
		area_damage_duration = 6,

		--lups_heat_fx = [[firewalker]],
	  },
	  
      damage                  = {
        default = 80,
        planes  = 80,
        subs    = 4,
      },

      explosionGenerator      = [[custom:napalm_firewalker]],
      firestarter             = 180,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      myGravity               = 0.1,
      range                   = 1100,
      reloadtime              = 6,
      rgbColor                = [[1 0.5 0.2]],
      size                    = 8,
      soundHit                = [[weapon/cannon/wolverine_hit]],
      soundStart              = [[weapon/cannon/wolverine_fire]],
      sprayangle              = 1024,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 340,
    },

  },

  featureDefs            = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[armroy_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4b.s3o]],
    },

  },

}

return lowerkeys({ a_shipcruiser_fireform = unitDef })
