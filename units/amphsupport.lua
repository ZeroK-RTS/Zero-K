return { amphsupport = {
  unitname               = [[Bulkhead]],
  name                   = [[amphsupport]],
  description            = [[Deployable Amphibious Fire Support (must stop to fire)]],
  acceleration           = 0.6,
  activateWhenBuilt      = true,
  brakeRate              = 2.4,
  buildCostMetal         = 220,
  builder                = false,
  buildPic               = [[amphsupport.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND SINK]],
  collisionVolumeOffsets = [[0 4 0]],
  collisionVolumeScales  = [[38 50 38]],
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    amph_regen        = 15,
    amph_submerged_at = 30,
    sink_on_emp       = 0,
    floattoggle       = [[1]],
    modelradius       = [[13]],
    aimposoffset      = [[0 10 0]],
    chase_everything  = [[1]], -- Does not get stupidtarget added to noChaseCats
    selection_scale   = 0.85,
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[amphsupport]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 1800,
  maxSlope               = 36,
  maxVelocity            = 1.7,
  minCloakDistance       = 75,
  movementClass          = [[AKBOT3]],
  moveState              = 0,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE SUB]],
  objectName             = [[amphdeploy.s3o]],
  script                 = [[amphsupport.lua]],
  pushResistant          = 0,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
      [[custom:RAIDDUST]],
      [[custom:THUDDUST]],
    },

  },

  sightDistance          = 660,
  sonarDistance          = 660,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 22,
  turnRate               = 1000,
  upright                = false,

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
      name                    = [[Light Plasma Cannon]],
      accuracy                = 480,
      areaOfEffect            = 40,
      craterBoost             = 0,
      craterMult              = 0,

      customParams        = {
        light_camera_height = 1400,
        light_color = [[0.80 0.54 0.23]],
        light_radius = 230,
      },

      damage                  = {
        default = 165.1,
        planes  = 165.1,
        subs    = 7.5,
      },

      edgeEffectiveness       = 0.1,
      explosionGenerator      = [[custom:INGEBORG]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      myGravity               = 0.12,
      noSelfDamage            = true,
      range                   = 600,
      reloadtime              = 1.8,
      soundHit                = [[explosion/ex_med5]],
      soundStart              = [[weapon/cannon/cannon_fire1]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 320,
    },

    FAKE_CANNON = {
      name                    = [[Fake Disruption Cannon]],
      accuracy                = 200,
      areaOfEffect            = 32,
      cegTag                  = [[beamweapon_muzzle_purple]],
      craterBoost             = 1,
      craterMult              = 2,

      customparams = {
        bogus = 1,
      },
  
      damage                  = {
        default = 170.1,
        subs    = 8.5,
      },

      explosionGenerator      = [[custom:flashslowwithsparks]],
      fireStarter             = 180,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.2,
      interceptedByShieldType = 2,
      myGravity               = 0.2,
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
      weaponVelocity          = 380,
    },

  },

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[amphdeploy_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3c.s3o]],
    },

  },

} }
