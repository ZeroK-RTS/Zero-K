unitDef = {
  unitname              = [[jumpblackhole]],
  name                  = [[Placeholder]],
  description           = [[Black Hole Launcher]],
  acceleration          = 0.4,
  brakeRate             = 0.4,
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
  corpse                = [[DEAD]],

  customParams          = {
    description_pl = [[Wyrzutnia czarnych dziur]],
    helptext       = [[The Placeholder is a support unit. Its projectiles create a vacuum that sucks in nearby units, clustering and holding them in place to help finish them off.]],
    helptext_pl    = [[Pociski Placeholdera zasysaja i utrzymuja w miejscu okoliczne jednostki, co pozwala je skutecznie wykonczyc.]],
  },

  explodeAs             = [[BIG_UNITEX]],
  footprintX            = 2,
  footprintZ            = 2,
  iconType              = [[kbotwideriot]],
  idleAutoHeal          = 5,
  idleTime              = 1800,
  leaveTracks           = true,
  mass                  = 157,
  maxDamage             = 900,
  maxSlope              = 36,
  maxVelocity           = 2,
  maxWaterDepth         = 22,
  minCloakDistance      = 75,
  movementClass         = [[KBOT2]],
  noAutoFire            = false,
  noChaseCategory       = [[FIXEDWING SATELLITE GUNSHIP SUB TURRET UNARMED]],
  objectName            = [[freaker.s3o]],
  script		        = [[jumpriot.lua]],
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

  side                  = [[CORE]],
  sightDistance         = 605,
  smoothAnim            = true,
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
      startsmoke              = [[1]],
      targetMoveError         = 0,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 550,
    },

  },


  featureDefs           = {

    DEAD  = {
      description      = [[Wreckage - Placeholder]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 900,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 100,
      object           = [[m-5_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 100,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

	
    HEAP  = {
      description      = [[Debris - Placeholder]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 900,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      hitdensity       = [[100]],
      metal            = 50,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 50,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ jumpblackhole = unitDef })
