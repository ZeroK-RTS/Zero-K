return { planeheavyfighter = {
  unitname               = [[planeheavyfighter]],
  name                   = [[Raptor]],
  description            = [[Air Superiority Fighter]],
  brakerate              = 0.4,
  buildCostMetal         = 300,
  buildPic               = [[planeheavyfighter.png]],
  canFly                 = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canSubmerge            = false,
  category               = [[FIXEDWING]],
  collide                = false,
  collisionVolumeOffsets = [[0 0 5]],
  collisionVolumeScales  = [[30 12 50]],
  collisionVolumeType    = [[box]],
  selectionVolumeOffsets = [[0 0 10]],
  selectionVolumeScales  = [[60 60 80]],
  selectionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],
  crashDrag              = 0.01,
  cruiseAlt              = 220,

  customParams           = {
    midposoffset   = [[0 3 0]],
    aimposoffset   = [[0 3 0]],
    modelradius    = [[10]],
    refuelturnradius = [[120]],

    combat_slowdown = 0.5,
    selection_scale = 1.4,
  },

  explodeAs              = [[GUNSHIPEX]],
  fireState              = 2,
  floater                = true,
  footprintX             = 2,
  footprintZ             = 2,
  frontToSpeed           = 0.1,
  iconType               = [[stealthfighter]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  maxAcc                 = 0.5,
  maxDamage              = 1100,
  maxRudder              = 0.006,
  maxVelocity            = 7.6,
  minCloakDistance       = 75,
  mygravity              = 1,
  noChaseCategory        = [[TERRAFORM LAND SINK TURRET SHIP SWIM FLOAT SUB HOVER]],
  objectName             = [[fighter2.s3o]],
  script                 = [[planeheavyfighter.lua]],
  selfDestructAs         = [[GUNSHIPEX]],
  sightDistance          = 750,
  speedToFront           = 0.5,
  turnRadius             = 80,

  weapons                = {

    {
      def                = [[LASER]],
      badTargetCategory  = [[GUNSHIP]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 90,
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
        default = 0.96,
        planes  = 9.6,
        subs    = 0.96,
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
      soundStartVolume        = 1.9,
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
