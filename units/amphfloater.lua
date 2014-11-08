unitDef = {
  unitname               = [[amphfloater]],
  name                   = [[Buoy]],
  description            = [[Inflatable Amphibious Bot]],
  acceleration           = 0.2,
  activateWhenBuilt      = true,
  brakeRate              = 0.4,
  buildCostEnergy        = 300,
  buildCostMetal         = 300,
  buildPic               = [[amphfloater.png]],
  buildTime              = 300,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND SINK]],
  corpse                 = [[DEAD]],

  customParams           = {
    amph_regen = 60,
    amph_submerged_at = 30,
    description_pl = [[Amfibijny bot plywak]],
    helptext       = [[The Buoy works around its inability to shoot while submerged by floating to the surface of the sea. Here it can fire a decently ranged cannon with slow damage. It is unable to move while floating.]],
    helptext_pl    = [[Buoy nie moze strzelac pod woda, ale radzi sobie z tym poprzez wyplywanie na powierzchnie. Wtedy moze atakowac przy uzyciu dzialka o dobrym zasiegu, zadajac dodatkowo obrazenia spowalniajace. Bedac na powierzchni nie moze sie poruszac.]],
    floattoggle    = [[1]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[amphskirm]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 1250,
  maxSlope               = 36,
  maxVelocity            = 1.4,
  minCloakDistance       = 75,
  movementClass          = [[AKBOT2]],
  noChaseCategory        = [[TERRAFORM FIXEDWING GUNSHIP]],
  objectName             = [[can.s3o]],
  script                 = [[amphfloater.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {
    explosiongenerators = {
    },
  },

  sightDistance          = 500,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 22,
  turnRate               = 1200,
  upright                = true,

  weapons                = {
    {
      def                = [[CANNON]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
    {
      def                = [[FAKE_CANNON]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
  },

  weaponDefs             = {

    CANNON = {
      name                    = [[Disruption Cannon]],
      accuracy                = 200,
      areaOfEffect            = 32,
      cegTag                  = [[beamweapon_muzzle_purple]],
      craterBoost             = 1,
      craterMult              = 2,

      customparams = {
        timeslow_damagefactor = 1.667,
      },

      damage                  = {
        default = 150,
        subs    = 7.5,
      },

      explosionGenerator      = [[custom:flashslowwithsparks]],
      fireStarter             = 180,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.2,
      interceptedByShieldType = 2,
      myGravity               = 0.2,
      predictBoost            = 1,
      range                   = 450,
      reloadtime              = 1.8,
      rgbcolor                = [[0.9 0.1 0.9]],
      soundHit                = [[weapon/laser/small_laser_fire]],
      soundHitVolume          = 2.2,
      soundStart              = [[weapon/laser/small_laser_fire3]],
      soundStartVolume        = 3.5,
      soundTrigger            = true,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 340,
    },

    FAKE_CANNON = {
      name                    = [[Fake Disruption Cannon]],
      accuracy                = 200,
      areaOfEffect            = 32,
      cegTag                  = [[beamweapon_muzzle_purple]],
      craterBoost             = 1,
      craterMult              = 2,

      customparams = {
        timeslow_damagefactor = 1.7,
      },
  
      damage                  = {
        default = 150,
        subs    = 7.5,
      },

      explosionGenerator      = [[custom:flashslowwithsparks]],
      fireStarter             = 180,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.2,
      interceptedByShieldType = 2,
      myGravity               = 0.2,
      predictBoost            = 1,
      range                   = 450,
      reloadtime              = 1.8,
      rgbcolor                = [[0.9 0.1 0.9]],
      soundHit                = [[weapon/laser/small_laser_fire]],
      soundHitVolume          = 2.2,
      soundStart              = [[weapon/laser/small_laser_fire3]],
      soundStartVolume        = 3.5,
      soundTrigger            = true,
      turret                  = true,
      waterWeapon             = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 340,
    },

  },

  featureDefs            = {

    DEAD      = {
      description      = [[Wreckage - Buoy]],
      blocking         = true,
      damage           = 1250,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 120,
      object           = [[can_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 120,
    },

    HEAP      = {
      description      = [[Debris - Buoy]],
      blocking         = false,
      damage           = 1250,
      energy           = 0,
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 60,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 60,
    },

  },

}

return lowerkeys({ amphfloater = unitDef })
