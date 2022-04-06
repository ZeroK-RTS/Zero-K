return { amphassault = {
  unitname            = [[amphassault]],
  name                = [[Grizzly]],
  description         = [[Heavy Amphibious Assault Walker]],
  acceleration        = 0.3,
  activateWhenBuilt   = true,
  brakeRate           = 1.8,
  buildCostMetal      = 2000,
  buildPic            = [[amphassault.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND SINK]],
  collisionVolumeOffsets  = [[0 0 0]],
  --collisionVolumeScales = [[70 70 70]],
  --collisionVolumeType   = [[ellipsoid]],
  corpse              = [[DEAD]],

  customParams        = {
    bait_level_default = 1,
    amph_regen = 40,
    amph_submerged_at = 40,
    sink_on_emp    = 0,
    floattoggle    = [[1]],
    aimposoffset   = [[0 30 0]],
    midposoffset   = [[0 6 0]],
    modelradius    = [[42]],
  },

  explodeAs           = [[BIG_UNIT]],
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[amphassault]],
  leaveTracks         = true,
  maxDamage           = 8400,
  maxSlope            = 36,
  maxVelocity         = 1.5,
  maxReverseVelocity  = 0,
  movementClass       = [[AKBOT4]],
  noChaseCategory     = [[TERRAFORM FIXEDWING SUB]],
  objectName          = [[amphassault.s3o]],
  script              = [[amphassault.lua]],
  selfDestructAs      = [[BIG_UNIT]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:watercannon_muzzle]],
      [[custom:bubbles_small]],
    },

  },

  sightDistance       = 660,
  sonarDistance       = 660,
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ComTrack]],
  trackWidth          = 66,
  turnRate            = 600,
  upright             = false,

  weapons                       = {
    {
      def                = [[LASER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
    {
      def                = [[FAKE_LASER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs                    = {

    LASER = {
      name                    = [[High-Energy Laserbeam]],
      areaOfEffect            = 14,
      beamTime                = 0.8,
      beamttl                 = 1,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        burst = Shared.BURST_UNRELIABLE,

        light_color = [[0.5 0.5 1.5]],
        light_radius = 180,
      },

      damage                  = {
        default = 750.1,
        planes  = 750.1,
      },

      explosionGenerator      = [[custom:flash1bluedark]],
      fireTolerance           = 8192, -- 45 degrees
      fireStarter             = 90,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 10.4,
      leadLimit               = 18,
      minIntensity            = 1,
      noSelfDamage            = true,
      projectiles             = 2,
      range                   = 600,
      reloadtime              = 6,
      rgbColor                = [[0 0 1]],
      scrollSpeed             = 5,
      soundStart              = [[weapon/laser/heavy_laser3]],
      soundStartVolume        = 3,
      sweepfire               = false,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 10.4024486300101,
      tileLength              = 300,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 2250,
    },

    FAKE_LASER = {
      name                    = [[Fake High-Energy Laserbeam]],
      areaOfEffect            = 14,
      beamTime                = 0.8,
      beamttl                 = 1,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        bogus = 1,
      },

      damage                  = {
        default = 300,
      },

      explosionGenerator      = [[custom:flash1bluedark]],
      fireStarter             = 90,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 10.4,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 600,
      reloadtime              = 6,
      rgbColor                = [[0 0 1]],
      scrollSpeed             = 5,
      soundStart              = [[weapon/laser/heavy_laser3]],
      soundStartVolume        = 3,
      sweepfire               = false,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 10.4024486300101,
      tileLength              = 300,
      tolerance               = 10000,
      turret                  = true,
      waterWeapon             = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 2250,
    },
  },

  featureDefs         = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[amphassault_wreck.s3o]],
    },

    HEAP = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4c.s3o]],
    },

  },

} }
