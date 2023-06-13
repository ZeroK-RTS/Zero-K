return { turrettorp = {
  unitname          = [[turrettorp]],
  name              = [[Urchin]],
  description       = [[Torpedo Launcher (Anti-Sub)]],
  activateWhenBuilt = true,
  buildCostMetal    = 120,
  builder           = false,
  buildPic          = [[turrettorp.png]],
  category          = [[FLOAT]],
  collisionVolumeOffsets = [[0 -5 0]],
  collisionVolumeScales  = [[42 50 42]],
  collisionVolumeType    = [[CylY]],
  corpse            = [[DEAD]],

  customParams      = {
    aimposoffset   = [[0 15 0]],
    midposoffset   = [[0 15 0]],
  },

  explodeAs         = [[MEDIUM_BUILDINGEX]],
  footprintX        = 3,
  footprintZ        = 3,
  iconType          = [[defensetorp]],
  maxDamage         = 1020,
  maxSlope          = 18,
  maxVelocity       = 0,
  noAutoFire        = false,
  noChaseCategory   = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName        = [[torpedo launcher.s3o]],
  script            = [[turrettorp.lua]],
  selfDestructAs    = [[MEDIUM_BUILDINGEX]],

  sightDistance     = 653, -- Range*1.1 + 48 for radar overshoot
  sonarDistance     = 653,
  waterline         = 1,
  workerTime        = 0,
  yardMap           = [[wwwwwwwww]],

  weapons           = {

    {
      def                = [[TORPEDO]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[SWIM FIXEDWING LAND SUB SINK TURRET FLOAT SHIP GUNSHIP HOVER]],
    },

  },


  weaponDefs        = {

    TORPEDO = {
      name                    = [[Torpedo Launcher]],
      areaOfEffect            = 64,
      avoidFriendly           = false,
      bouncerebound           = 0.5,
      bounceslip              = 0.5,
      burnblow                = true,
      canAttackGround         = false,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,
      cegTag                  = [[torpedo_trail]],

      customparams = {
        stays_underwater = 1,
      },

      damage                  = {
        default = 190,
      },

      explosionGenerator      = [[custom:TORPEDO_HIT]],
      groundbounce            = 1,
      edgeEffectiveness       = 0.6,
      impulseBoost            = 0,
      impulseFactor           = 0.2,
      interceptedByShieldType = 1,
      model                   = [[wep_t_longbolt.s3o]],
      numbounce               = 4,
      range                   = 550,
      reloadtime              = 3.2,
      soundHit                = [[explosion/wet/ex_underwater]],
      --soundStart              = [[weapon/torpedo]],
      startVelocity           = 150,
      tracks                  = true,
      turnRate                = 22000,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 22,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 320,
    },

  },


  featureDefs       = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[torpedo launcher_dead.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3c.s3o]],
    },

  },

} }
