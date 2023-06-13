return { assaultcruiser = {
  unitname               = [[assaultcruiser]],
  name                   = [[Vanquisher]],
  description            = [[Heavy Cruiser (Assault)]],
  acceleration           = 0.384,
  activateWhenBuilt      = true,
  brakeRate              = 0.42,
  buildCostMetal         = 1600,
  builder                = false,
  buildPic               = [[assaultcruiser.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[SHIP]],
  collisionVolumeOffsets = [[0 4 -2]],
  collisionVolumeScales  = [[72 42 128]],
  collisionVolumeType    = [[Box]],
  corpse                 = [[DEAD]],

  customParams           = {
  },

  explodeAs              = [[BIG_UNIT]],
  floater                = true,
  footprintX             = 5,
  footprintZ             = 5,
  iconType               = [[vanquisher]],
  maxDamage              = 9600,
  maxVelocity            = 2.7,
  minWaterDepth          = 15,
  movementClass          = [[BOAT5]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB SINK TURRET]],
  objectName             = [[cremcrus.s3o]],
  script                 = [[assaultcruiser.lua]],
  selfDestructAs         = [[BIG_UNIT]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:brawlermuzzle]],
      [[custom:pulvmuzzle]],
    },

  },
  sightDistance          = 600,
  sonarDistance           = 800,
  turninplace            = 0,
  turnRate               = 260,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[FAKELASER]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
    },
    
    {
      def                = [[GAUSS]],
      mainDir            = [[-1 0 1]],
      maxAngleDif        = 240,
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
    
    {
      def                = [[GAUSS]],
      mainDir            = [[1 0 1]],
      maxAngleDif        = 240,
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
    
    {
      def                = [[GAUSS]],
      mainDir            = [[-1 0 -1]],
      maxAngleDif        = 240,
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
    
    {
      def                = [[GAUSS]],
      mainDir            = [[1 0 -1]],
      maxAngleDif        = 240,
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
    
    {
      def                = [[MISSILE]],
      mainDir            = [[-1 0 0]],
      maxAngleDif        = 240,
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER SUB]],
    },

    {
      def                = [[MISSILE]],
      mainDir            = [[1 0 0]],
      maxAngleDif        = 240,
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER SUB]],
    },
    
  },


  weaponDefs             = {
  
    FAKELASER     = {
      name                    = [[Fake Laser]],
      areaOfEffect            = 12,
      beamTime                = 0.1,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 0,
      },

      duration                = 0.11,
      fireStarter             = 70,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      laserFlareSize          = 5.53,
      range                   = 400,
      reloadtime              = 0.1,
      rgbColor                = [[0 1 0]],
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 5,
      turret                  = true,
      weaponType              = [[BeamLaser]],
    },
    
    GAUSS = {
      name                    = [[Gauss Cannon]],
      alphaDecay              = 0.12,
      areaOfEffect            = 16,
      bouncerebound           = 0.15,
      bounceslip              = 1,
      burst                   = 2,
      burstrate               = 0.4,
      cegTag                  = [[gauss_tag_l]],
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 200,
        planes  = 200,
      },

      explosionGenerator      = [[custom:gauss_hit_m]],
      groundbounce            = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 0,
      noExplode               = true,
      numbounce               = 40,
      range                   = 450,
      reloadtime              = 5,
      rgbColor                = [[0.5 1 1]],
      separation              = 0.5,
      size                    = 0.8,
      sizeDecay               = -0.1,
      soundHit                = [[weapon/gauss_hit]],
      soundStart              = [[weapon/gauss_fire]],
      sprayangle              = 800,
      stages                  = 32,
      turret                  = true,
      waterbounce             = 1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 2400,
    },
    
    MISSILE      = {
      name                    = [[Cruiser Missiles]],
      areaOfEffect            = 48,
      burst                    = 2,
      burstRate                = 0.233,
      cegTag                  = [[missiletrailyellow]],
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 160,
      },

      edgeEffectiveness       = 0.5,
      fireStarter             = 100,
      fixedLauncher              = true,
      flightTime              = 4,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_m_hailstorm.s3o]],
      noSelfDamage            = true,
      range                   = 420,
      reloadtime              = 3.2,
      smokeTrail              = true,
      soundHit                = [[weapon/missile/missile_fire12]],
      soundStart              = [[weapon/missile/missile_fire10]],
      startVelocity           = 300,
      tolerance               = 4000,
      tracks                  = true,
      trajectoryHeight        = 0.5,
      turnrate                = 30000,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 300,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 600,
    },
  },


  featureDefs            = {

    DEAD = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 5,
      footprintZ       = 5,
      object           = [[cremcrus_dead.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4a.s3o]],
    },

  },

} }
