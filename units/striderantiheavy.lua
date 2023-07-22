return { striderantiheavy = {
  name                   = [[Ultimatum]],
  description            = [[Cloaked Anti-Strider Walker (Undersea Fire)]],
  acceleration           = 0.54,
  activateWhenBuilt      = true,
  autoHeal               = 5,
  brakeRate              = 2.25,
  buildPic               = [[striderantiheavy.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  cloakCost              = 8,
  cloakCostMoving        = 24,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[42 42 42]],
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    bait_level_default = 0,
    modelradius    = [[21]],

    stats_show_death_explosion = 1,
  },

  explodeAs              = [[ESTOR_BUILDING]],
  footprintX             = 2,
  footprintZ             = 2,
  health                 = 2000,
  iconType               = [[corcommander]],
  initCloaked            = true,
  leaveTracks            = true,
  maxSlope               = 36,
  maxWaterDepth          = 5000,
  metalCost              = 2500,
  minCloakDistance       = 120,
  movementClass          = [[AKBOT2]],
  noChaseCategory        = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName             = [[noruas.s3o]],
  script                 = [[striderantiheavy.lua]],
  selfDestructAs         = [[ESTOR_BUILDING]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:laserbladestrike]],
    },

  },

  showNanoSpray          = false,
  sightDistance          = 500,
  sonarDistance          = 500,
  speed                  = 46.5,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 18,
  turnRate               = 1377,
  upright                = true,

  weapons                = {

    {
      def = [[DISINTEGRATOR]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SUB SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    DISINTEGRATOR = {
      name                    = [[Disintegrator]],
      areaOfEffect            = 48,
      avoidFeature            = false,
      avoidFriendly           = false,
      avoidGround             = false,
      avoidNeutral            = false,
      commandfire             = false,
      craterBoost             = 1,
      craterMult              = 6,

      damage                  = {
        default = 2000,
      },

      explosionGenerator      = [[custom:DGUNTRACE]],
      heightMod               = 1,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 0,
      leadLimit               = 80,
      noExplode               = true,
      noSelfDamage            = true,
      range                   = 250,
      reloadtime              = 2,
      size                    = 6,
      soundHit                = [[explosion/ex_med6]],
      soundStart              = [[weapon/laser/heavy_laser4]],
      soundTrigger            = true,
      tolerance               = 10000,
      turret                  = true,
      waterWeapon             = true,
      weaponType              = [[DGun]],
      weaponVelocity          = 300,
    },

  },


  featureDefs            = {

    DEAD      = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[ultimatum_d.s3o]],
    },


    HEAP      = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2b.s3o]],
    },

  },

} }
