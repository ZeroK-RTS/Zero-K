unitDef = {
  unitname              = [[jumpblackhole]],
  name                  = [[Placeholder]],
  description           = [[Black Hole Launcher]],
  acceleration          = 0.4,
  brakeRate             = 1.2,
  buildCostEnergy       = 250,
  buildCostMetal        = 250,
  builder               = false,
  buildPic              = [[jumpblackhole.png]],
  buildTime             = 250,
  canAttack             = true,
  canGuard              = true,
  canMove               = true,
  canPatrol             = true,
  canstop               = [[1]],
  category              = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[30 48 30]],
  collisionVolumeType    = [[cylY]],
  corpse                = [[DEAD]],

  customParams          = {
    helptext       = [[The Placeholder is a support unit. Its projectiles create a vacuum that sucks in nearby units, clustering and holding them in place to help finish them off.]],
    midposoffset   = [[0 10 0]],
  },

  explodeAs             = [[BIG_UNITEX]],
  footprintX            = 2,
  footprintZ            = 2,
  iconType              = [[kbotwideriot]],
  idleAutoHeal          = 5,
  idleTime              = 1800,
  leaveTracks           = true,
  losEmitHeight         = 40,
  maxDamage             = 900,
  maxSlope              = 36,
  maxVelocity           = 2,
  maxWaterDepth         = 22,
  minCloakDistance      = 75,
  movementClass         = [[KBOT2]],
  noAutoFire            = false,
  noChaseCategory       = [[FIXEDWING SATELLITE GUNSHIP SUB TURRET UNARMED]],
  objectName            = [[freaker.s3o]],
  script		        = [[jumpblackhole.lua]],
  seismicSignature      = 4,
  selfDestructAs        = [[BIG_UNITEX]],
  selfDestructCountdown = 5,

  sfxtypes              = {

    explosiongenerators = {
      [[custom:PILOT]],
      [[custom:PILOT2]],
      [[custom:RAIDMUZZLE]],
      [[custom:VINDIBACK]],
    },

  },
  sightDistance         = 605,
  trackOffset           = 0,
  trackStrength         = 8,
  trackStretch          = 1,
  trackType             = [[ComTrack]],
  trackWidth            = 22,
  turnRate              = 1400,
  upright               = true,
  workerTime            = 0,

 weapons             = {

    {
      def                = [[BLACK_HOLE]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING HOVER SWIM LAND SHIP GUNSHIP]],
    },

  },


  weaponDefs          = {

    BLACK_HOLE = {
      name                    = [[Black Hole Launcher]],
      accuracy                = 350,
      areaOfEffect            = 300,
	  avoidFeature            = false,
      avoidFriendly           = false,
      burnblow                = true,
      collideFeature          = false,
      collideFriendly         = false,
      craterBoost             = 100,
      craterMult              = 2,

	  customParams            = {
	    falldamageimmunity = [[120]],

		area_damage = 1,
		area_damage_radius = 70,
		area_damage_dps = 5600,
		area_damage_is_impulse = 1,
		area_damage_duration = 13.3,
		area_damage_range_falloff = 0.4,
		area_damage_time_falloff = 0.6,
		
		light_color = [[1 1 1]],
		light_radius = 500,
	  },
	  
      damage                  = {
        default = 0,
      },

      explosionGenerator      = [[custom:black_hole_long]],
      explosionSpeed          = 50,
      impulseBoost            = 150,
      impulseFactor           = -2.5,
	  intensity               = 0.9,
      interceptedByShieldType = 1,
      myGravity               = 0.1,
      projectiles             = 1,
      range                   = 475,
      reloadtime              = 14,
      rgbColor                = [[0.05 0.05 0.05]],
      size                    = 16,
      soundHit                = [[weapon/blackhole_impact]],
      soundStart              = [[weapon/blackhole_fire]],
      soundStartVolume        = 6000,
      soundHitVolume          = 6000,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 550,
    },

  },


  featureDefs           = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[freaker_dead.s3o]],
    },

	
    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ jumpblackhole = unitDef })
