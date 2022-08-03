return { hoverarty = {
  unitname            = [[hoverarty]],
  name                = [[Lance]],
  description         = [[Anti-Heavy Artillery Hovercraft]],
  acceleration        = 0.096,
  activateWhenBuilt   = true,
  brakeRate           = 1.776,
  buildCostMetal      = 1000,
  builder             = false,
  buildPic            = [[hoverarty.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[HOVER]],
  collisionVolumeOffsets = [[0 -6 0]],
  collisionVolumeScales  = [[40 56 56]],
  collisionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],

  customParams        = {
    bait_level_default = 1,
    modelradius    = [[32]],
    dontfireatradarcommand = '0',
    aimposoffset   = [[0 11 0]],
    turnatfullspeed_hover = [[1]],
  },

  explodeAs           = [[MEDIUM_BUILDINGEX]],
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[mobiletachyon]],
  leaveTracks         = true,
  losEmitHeight       = 40,
  maxDamage           = 1000,
  maxSlope            = 18,
  maxVelocity         = 1.65,
  maxWaterDepth       = 22,
  movementClass       = [[HOVER4]],
  moveState           = 0,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP]],
  objectName          = [[penetrator_lordmuffe.s3o]],
  script              = [[hoverarty.lua]],
  selfDestructAs      = [[MEDIUM_BUILDINGEX]],
  
  sfxtypes            = {

    explosiongenerators = {
      [[custom:HEAVYHOVERS_ON_GROUND]],
    },

  },
  
  sightDistance       = 660,
  sonarDistance       = 660,
  turninplace         = 0,
  turnRate            = 420,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[ATA]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SHIP SINK TURRET FLOAT GUNSHIP FIXEDWING HOVER]],
    },

  },


  weaponDefs          = {

    ATA = {
      name                    = [[Tachyon Accelerator]],
      areaOfEffect            = 20,
      beamTime                = 1,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,
      
      customParams            = {
        burst = Shared.BURST_RELIABLE,

        light_color = [[1.25 0.8 1.75]],
        light_radius = 320,
      },
      damage                  = {
        default = 3000.1,
        planes  = 3000.1,
      },

      explosionGenerator      = [[custom:ataalaser]],
      fireTolerance           = 8192, -- 45 degrees
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 10,
      leadLimit               = 18,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 980,
      reloadtime              = 20,
      rgbColor                = [[0.25 0 1]],
      soundStart              = [[weapon/laser/heavy_laser6]],
      soundStartVolume        = 15,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 16.9373846859543,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 1500,
    },

  },


  featureDefs         = {

    DEAD  = {
      blocking         = true,
      collisionVolumeScales  = [[40 40 60]],
      collisionVolumeType    = [[CylZ]],
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[Lordmuffe_Pene_dead.dae]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3b.s3o]],
    },

  },

} }
