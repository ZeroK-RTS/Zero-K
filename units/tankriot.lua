return { tankriot = {
  unitname            = [[tankriot]],
  name                = [[Ogre]],
  description         = [[Heavy Riot Support Tank]],
  acceleration        = 0.109,
  brakeRate           = 0.428,
  buildCostMetal      = 500,
  builder             = false,
  buildPic            = [[tankriot.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[55 55 55]],
  selectionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],

  customParams        = {
    cus_noflashlight = 1,
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[tankriot]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  maxDamage           = 1850,
  maxSlope            = 18,
  maxVelocity         = 2.3,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[TANK4]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE SUB]],
  objectName          = [[corbanish.s3o]],
  script              = [[tankriot.lua]],
  selfDestructAs      = [[BIG_UNITEX]],
  sightDistance       = 400,
  trackOffset         = 8,
  trackStrength       = 10,
  trackStretch        = 1,
  trackType           = [[StdTank]],
  trackWidth          = 50,
  turninplace         = 0,
  turnRate            = 355,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[TAWF_BANISHER]],
      mainDir            = [[0 0 1]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    TAWF_BANISHER = {
      name                    = [[Heavy Missile]],
      areaOfEffect            = 160,
      cegTag                  = [[BANISHERTRAIL]],
      craterBoost             = 1,
      craterMult              = 2,

      customParams            = {
        burst = Shared.BURST_RELIABLE,

        gatherradius = [[120]],
        smoothradius = [[80]],
        smoothmult   = [[0.25]],
        force_ignore_ground = [[1]],
        
        light_color = [[1.4 1 0.7]],
        light_radius = 320,
      },
      
      damage                  = {
        default = 420.1,
        subs    = 22,
      },

      edgeEffectiveness       = 0.4,
      explosionGenerator      = [[custom:xamelimpact]],
      fireStarter             = 20,
      flightTime              = 4,
      impulseBoost            = 0,
      impulseFactor           = 0.6,
      interceptedByShieldType = 2,
      model                   = [[corbanishrk.s3o]],
      noSelfDamage            = true,
      range                   = 320,
      reloadtime              = 2.133,
      smokeTrail              = false,
      soundHit                = [[weapon/bomb_hit]],
      soundStart              = [[weapon/missile/banisher_fire]],
      startVelocity           = 400,
      tolerance               = 9000,
      tracks                  = true,
      trajectoryHeight        = 0.45,
      turnRate                = 22000,
      turret                  = true,
      weaponAcceleration      = 70,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 400,
    },

  },


  featureDefs         = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[corbanish_dead.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3a.s3o]],
    },

  },

} }
