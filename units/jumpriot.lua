unitDef = {
  unitname              = [[jumpriot]],
  name                  = [[Infernal]],
  description           = [[Riot Jumper]],
  acceleration          = 0.4,
  brakeRate             = 1.2,
  buildCostEnergy       = 260,
  buildCostMetal        = 260,
  builder               = false,
  buildPic              = [[jumpblackhole.png]],
  buildTime             = 260,
  canAttack             = true,
  canGuard              = true,
  canMove               = true,
  canPatrol             = true,
  canstop               = [[1]],
  category              = [[LAND FIREPROOF]],
  corpse                = [[DEAD]],

  customParams          = {
    canjump        = [[1]],
    fireproof      = [[1]],
    helptext       = [[The Infernal is a fire-based riot jumper.]],
	},

  explodeAs             = [[CORPYRO_PYRO_DEATH]],
  footprintX            = 2,
  footprintZ            = 2,
  iconType              = [[jumpjetriot]],
  idleAutoHeal          = 5,
  idleTime              = 1800,
  leaveTracks           = true,
  maxDamage             = 900,
  maxSlope              = 36,
  maxVelocity           = 2,
  maxWaterDepth         = 22,
  minCloakDistance      = 75,
  movementClass         = [[KBOT2]],
  noAutoFire            = false,
  noChaseCategory       = [[FIXEDWING SATELLITE GUNSHIP SUB]],
  objectName            = [[freaker.s3o]],
  script		        = [[jumpblackhole.lua]],
  seismicSignature      = 4,
  selfDestructAs        = [[CORPYRO_NAPALM]],
  selfDestructCountdown = 1,

  sfxtypes              = {

    explosiongenerators = {
      [[custom:PILOT]],
      [[custom:PILOT2]],
      [[custom:RAIDMUZZLE]],
      [[custom:VINDIBACK]],
    },

  },
  sightDistance         = 420,
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
      def                = [[NAPALM]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    NAPALM = {
      name                    = [[Impulse Cannon]],
      areaOfEffect            = 192,
      avoidFeature            = true,
      avoidFriendly           = true,
      burnblow                = true,
      craterBoost             = 1,
      craterMult              = 0.5,
	  
	  customParams        	  = {
	    setunitsonfire = "1",
		burntime = 60,
	  },
	  
      damage                  = {
        default = 120,
        planes  = 120,
        subs    = 6,
      },

      edgeEffectiveness       = 0.75,
      explosionGenerator      = [[custom:napalm_infernal]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 280,
      reloadtime              = 3,
      rgbColor                = [[1 0.5 0.2]],
      size                    = 5,
      soundHit                = [[weapon/cannon/generic_cannon]],
      soundStart              = [[weapon/cannon/outlaw_gun]],
      soundStartVolume        = 3,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 750,
    },

  },


  featureDefs           = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[m-5_dead.s3o]],
    },

	
    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ jumpriot = unitDef })
