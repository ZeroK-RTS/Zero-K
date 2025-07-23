return { planeheavyfighter = {
  name                   = [[Raptor]],
  description            = [[Air Superiority Fighter]],
  brakerate              = 0.4,
  buildPic               = [[planeheavyfighter.png]],
  canFly                 = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canSubmerge            = false,
  category               = [[FIXEDWING]],
  collide                = false,
  collisionVolumeOffsets = [[0 0 5]],
  collisionVolumeScales  = [[38 15 64]],
  collisionVolumeType    = [[ellipsoid]],
  selectionVolumeOffsets = [[0 0 10]],
  selectionVolumeScales  = [[81 81 108]],
  selectionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],
  crashDrag              = 0.01,
  cruiseAltitude         = 220,

  customParams           = {
    bait_level_default = 0,
    bait_level_target      = 3,

    midposoffset   = [[0 3 0]],
    aimposoffset   = [[0 3 0]],
    modelradius    = [[10]],
    refuelturnradius = [[120]],

    combat_slowdown = 0.35,
    selection_scale = 1.4,

    outline_x = 120,
    outline_y = 120,
    outline_yoff = 20,
  },

  explodeAs              = [[GUNSHIPEX]],
  fireState              = 2,
  floater                = true,
  footprintX             = 2,
  footprintZ             = 2,
  frontToSpeed           = 0.1,
  health                 = 1100,
  iconType               = [[stealthfighter]],
  maxAcc                 = 0.605,
  maxAileron             = 0.02,
  maxElevator            = 0.015,
  maxRudder              = 0.008,
  metalCost              = 300,
  mygravity              = 1,
  noChaseCategory        = [[TERRAFORM LAND SINK TURRET SHIP SWIM FLOAT SUB HOVER]],
  objectName             = [[fighter2.s3o]],
  script                 = [[planeheavyfighter.lua]],
  selfDestructAs         = [[GUNSHIPEX]],
  sightDistance          = 750,
  speed                  = 228,
  speedToFront           = 0.5,
  turnRadius             = 10,

  weapons                = {

    {
      def                = [[LASER]],
      badTargetCategory  = [[GUNSHIP]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 100,
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs             = {

    LASER = {
      name                    = [[Anti-Air Laser Battery]],
      areaOfEffect            = 12,
      avoidFriendly           = false,
      beamDecay               = 0.736,
      beamTime                = 1/30,
      beamttl                 = 15,
      canattackground         = false,
      canAttackGround         = 0,
      collideFriendly         = false,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting       = 1,

      customParams            = {
        isaa = [[1]],
      },

      damage                  = {
        default = 1.0,
        planes  = 10,
      },

      explosionGenerator      = [[custom:flash_teal7]],
      fireStarter             = 100,
      impactOnly              = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      laserFlareSize          = 2.9,
      minIntensity            = 1,
      range                   = 800,
      reloadtime              = 0.1,
      rgbColor                = [[0 1 1]],
      soundStart              = [[weapon/laser/rapid_laser]],
      soundTrigger            = true,
      soundStartVolume        = 5,
      thickness               = 1.95,
      tolerance               = 8192,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 2200,
    },

  },


  featureDefs            = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      collisionVolumeOffsets = [[0 0 5]],
      collisionVolumeScales  = [[35 15 45]],
      collisionVolumeType    = [[box]],
      object           = [[fighter2_dead.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2b.s3o]],
    },

  },

} }
