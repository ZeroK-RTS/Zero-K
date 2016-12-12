unitDef = {
  unitname               = [[shipscout]],
  name                   = [[Cutter]],
  description            = [[Picket Ship (Disarming Scout)]],
  acceleration           = 0.0984,
  activateWhenBuilt      = true,
  brakeRate              = 0.0475,
  buildCostEnergy        = 70,
  buildCostMetal         = 70,
  builder                = false,
  buildPic               = [[shipscout.png]],
  buildTime              = 70,
  canAttack              = true,
  canMove                = true,
  category               = [[SHIP]],
  collisionVolumeOffsets = [[0 5 0]],
  collisionVolumeScales  = [[20 20 60]],
  collisionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],

  customParams           = {
    helptext       = [[Cheap, fast, and fragile, this Picket Ship is a good scout and spotter for more expensive ships. In numbers, their disarming missiles are effective against larger targets.]],
    modelradius    = [[12]],
    turnatfullspeed = [[1]],
  },

  explodeAs              = [[SMALL_UNITEX]],
  floater                = true,
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[shipscout]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  maxDamage              = 240,
  maxVelocity            = 5.2,
  minCloakDistance       = 75,
  movementClass          = [[BOAT3]],
  noChaseCategory        = [[TERRAFORM SUB]],
  objectName             = [[shipscout.s3o]],
  script                 = [[shipscout.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[SMALL_UNITEX]],

  sfxtypes                      = {
  
    explosiongenerators = {
      [[custom:PULVMUZZLE]],
    },

  },
  
  sightDistance          = 800,
  sonarDistance          = 800,
  turninplace            = 0,
  turnRate               = 740,
  waterline              = 2,

  weapons                = {
  
    {
      def                = [[FAKEWEAPON]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 60,
    },

    {
      def                = [[MISSILE]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP LAND SINK TURRET SHIP SWIM FLOAT HOVER]],
    },

  },

  weaponDefs             = {

    FAKEWEAPON = {
      name                    = [[Fake Missile]],
      areaOfEffect            = 8,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting       = 1,

      damage                  = {
        default = 0,
      },

      explosionGenerator      = [[custom:FLASH2]],
      fireStarter             = 70,
      fixedlauncher           = true,
      flightTime              = 4,
      heightmod               = 0.5,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 2,
      model                   = [[wep_m_fury.s3o]],
      range                   = 330,
      reloadtime              = 2,
      smokeTrail              = true,
      startVelocity           = 300,
      tolerance               = 10000,
      tracks                  = true,
      trajectoryHeight        = 1.2,
      turnRate                = 60000,
      turret                  = true,
      weaponAcceleration      = 350,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 750,
    },

    MISSILE   = {
      name                    = [[Light Disarm Missile]],
      areaOfEffect            = 8,
      --burst                 = 2,
      --burstRate             = 0.4,
      cegTag                  = [[yellowdisarmtrail]],
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting       = 1,

      customParams        = {
        disarmDamageMult = 5.0,
        disarmDamageOnly = 0,
        disarmTimer      = 3, -- seconds
		
		light_color = [[1 1 1]],
      },
	  
      damage                  = {
        default = 34.1,
        subs    = 5,
      },

      explosionGenerator      = [[custom:mixed_white_lightning_bomb_small]],
      fireStarter             = 70,
      fixedlauncher           = true,
      flightTime              = 4,
      heightmod               = 0.5,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_armpt.s3o]],
      range                   = 330,
      reloadtime              = 1.5,
      smokeTrail              = true,
      soundHit                = [[weapon/missile/small_lightning_missile]],
      soundStart              = [[weapon/missile/missile_fire7]],
      startVelocity           = 100,
      texture2                = [[lightsmoketrail]],
      tolerance               = 10000,
      tracks                  = true,
      turnRate                = 60000,
      turret                  = true,
      weaponAcceleration      = 300,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 800,
    },

  },

  featureDefs            = {

    DEAD = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[shipscout_dead.s3o]],
    },

    HEAP = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris4x4a.s3o]],
    },

  },

}

return lowerkeys({ shipscout = unitDef })
