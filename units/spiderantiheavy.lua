return { spiderantiheavy = {
  unitname              = [[spiderantiheavy]],
  name                  = [[Widow]],
  description           = [[Cloaked Scout/Anti-Heavy]],
  acceleration          = 0.9,
  activateWhenBuilt     = true,
  brakeRate             = 5.4,
  buildCostMetal        = 280,
  buildPic              = [[spiderantiheavy.png]],
  canGuard              = true,
  canMove               = true,
  canPatrol             = true,
  category              = [[LAND]],
  cloakCost              = 5,
  cloakCostMoving        = 15,
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[30 30 30]],
  selectionVolumeType    = [[ellipsoid]],
  corpse                = [[DEAD]],

  customParams          = {
    bait_level_default = 2,
    dontfireatradarcommand = '1',
    cus_noflashlight = 1,
  },

  explodeAs             = [[BIG_UNITEX]],
  fireState             = 0,
  footprintX            = 2,
  footprintZ            = 2,
  iconType              = [[spiderspecialscout]],
  leaveTracks           = true,
  initCloaked           = true,
  maxDamage             = 270,
  maxSlope              = 36,
  maxVelocity           = 2.55,
  maxWaterDepth         = 22,
  minCloakDistance      = 60,
  movementClass         = [[TKBOT2]],
  moveState             = 0,
  noChaseCategory       = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName            = [[infiltrator.s3o]],
  script                = [[spiderantiheavy.lua]],
  selfDestructAs        = [[BIG_UNITEX]],
  sightDistance         = 550,
  trackOffset           = 0,
  trackStrength         = 8,
  trackStretch          = 1,
  trackType             = [[ChickenTrackPointyShort]],
  trackWidth            = 45,
  turnRate              = 2160,

  weapons               = {

    {
      def                = [[spy]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER FIXEDWING GUNSHIP]],
    },

  },

  weaponDefs            = {

    spy = {
      name                    = [[Electro-Stunner]],
      areaOfEffect            = 8,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        burst = Shared.BURST_RELIABLE,
        light_color = [[1.85 1.85 0.45]],
        light_radius = 300,
      },

      damage                  = {
        default        = 8000.1,
      },

      duration                = 8,
      explosionGenerator      = [[custom:YELLOW_LIGHTNINGPLOSION]],
      fireStarter             = 0,
      heightMod               = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 12,
      interceptedByShieldType = 1,
      paralyzer               = true,
      paralyzeTime            = 30,
      range                   = 120,
      reloadtime              = 35,
      rgbColor                = [[1 1 0.25]],
      soundStart              = [[weapon/LightningBolt]],
      soundTrigger            = true,
      targetborder            = 0.9,
      texture1                = [[lightning]],
      thickness               = 10,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[LightningCannon]],
      weaponVelocity          = 450,
    },

  },

  featureDefs           = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[Infiltrator_wreck.s3o]],
    },

    HEAP = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2a.s3o]],
    },

  },

} }
