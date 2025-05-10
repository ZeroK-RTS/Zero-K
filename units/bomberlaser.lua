return { bomberlaser = {
  name                = [[Laser Raven]],
  description         = [[Precision Bomber (Anti-Sub)]],
  brakerate           = 0.4,
  builder             = false,
  buildPic            = [[bomberprec.png]],
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[FIXEDWING]],
  collide             = false,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[100 18 50]],
  collisionVolumeType    = [[ellipsoid]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[129 34 81]],
  selectionVolumeType    = [[box]],
  corpse              = [[DEAD]],
  cruiseAltitude      = 180,

  customParams        = {
    modelradius      = [[15]],
    refuelturnradius = [[120]],
    reammoseconds    = [[8]],
    can_set_target   = [[1]],

    outline_x = 130,
    outline_y = 130,
    outline_yoff = 10,
  },

  explodeAs           = [[GUNSHIPEX]],
  floater             = true,
  footprintX          = 3,
  footprintZ          = 3,
  health              = 1000,
  iconType            = [[bomberassault]],
  maneuverleashlength = [[1380]],
  maxAcc              = 0.5,
  maxBank             = 0.6,
  maxElevator         = 0.02,
  maxRudder           = 0.013,
  maxFuel             = 1000000,
  maxPitch            = 0.4,
  metalCost           = 300,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP TOOFAST]],
  objectName          = [[corshad.s3o]],
  script              = [[bomberlaser.lua]],
  selfDestructAs      = [[GUNSHIPEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:light_red]],
      [[custom:light_green]],
    },

  },
  sightDistance       = 780,
  speed               = 234,
  turnRadius          = 300,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[BOGUS_BOMB]],
      onlyTargetCategory = [[LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER SUB]],
    },
    {
      def                = [[LASER]],
      mainDir            = [[0 -1 0]],
      maxAngleDif        = 0,
      onlyTargetCategory = [[NONE]],
    },
  },


  weaponDefs          = {

    BOGUS_BOMB = {
      name                    = [[Fake Bomb]],
      avoidFeature            = false,
      avoidFriendly           = false,
      burst                   = 2,
      burstrate               = 1,
      collideFriendly         = false,

      customParams            = {
        bogus = 1,
      },

      damage                  = {
        default = 0,
      },

      explosionGenerator      = [[custom:NONE]],
      interceptedByShieldType = 1,
      intensity               = 0,
      myGravity               = 40,
      noSelfDamage            = true,
      range                   = 20,
      reloadtime              = 1,
      sprayangle              = 2000,
      weaponType              = [[AircraftBomb]],
    },


    LASER = {
      name                    = [[High-Energy Laserbeam]],
      areaOfEffect            = 14,
      beamTime                = 9/30,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,
      
      customParams            = {
        burst = Shared.BURST_UNRELIABLE,
        prevent_overshoot_fudge = 15,

        light_color = [[0.25 1 0.25]],
        light_radius = 180,
      },

      damage                  = {
        default = 800.1,
        planes  = 800.1,
      },

      explosionGenerator      = [[custom:flash1green]],
      fireStarter             = 90,
      fireTolerance           = 8192, -- 45 degrees
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 10.4,
      leadLimit               = 18,
      minIntensity            = 1,
      noSelfDamage            = true,
      projectiles             = 1,
      range                   = 800,
      reloadtime              = 4.5,
      rgbColor                = [[0 1 0]],
      scrollSpeed             = 5,
      soundStart              = [[weapon/laser/heavy_laser3]],
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
  },


  featureDefs         = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[spirit_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
