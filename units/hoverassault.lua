return { hoverassault = {
  unitname            = [[hoverassault]],
  name                = [[Halberd]],
  description         = [[Blockade Runner Hover]],
  acceleration        = 0.288,
  activateWhenBuilt   = true,
  brakeRate           = 0.516,
  buildCostMetal      = 210,
  builder             = false,
  buildPic            = [[hoverassault.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[HOVER TOOFAST]],
  collisionVolumeOffsets = [[0 -8 0]],
  collisionVolumeScales  = [[30 34 36]],
  collisionVolumeType    = [[box]],
  corpse              = [[DEAD]],

  customParams        = {
    bait_level_default = 0,
    bait_level_target_armor = 1,
    modelradius       = [[25]],
    turnatfullspeed_hover = [[1]],
  },

  damageModifier      = 0.333,
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[hoverassault]],
  maxDamage           = 1450,
  maxSlope            = 36,
  maxVelocity         = 3.2,
  movementClass       = [[HOVER3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB DRONE]],
  objectName          = [[hoverassault.s3o]],
  script              = [[hoverassault.lua]],
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:HEAVYHOVERS_ON_GROUND]],
      [[custom:plasma_cannon_muzzle_blue]],
    },

  },

  sightDistance       = 385,
  sonarDistance       = 385,
  turninplace         = 0,
  turnRate            = 985,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[DEW]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs             = {

    DEW = {
      name                    = [[Direct Energy Weapon]],
      areaOfEffect            = 48,
      cegTag                  = [[halberd_trail]],
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      customParams              = {
        light_camera_height = 1600,
        light_color = [[0.7 0.7 2.3]],
        light_radius = 160,
      },

      damage                  = {
        default = 160.1,
      },

      duration                = 0.2,
      explosionGenerator      = [[custom:beamerray]],
      fireStarter             = 50,
      heightMod               = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 200,
      reloadtime              = 1.2,
      rgbColor                = [[0 0.3 1]],
      soundHit                = [[weapon/laser/small_laser_fire2]],
      soundStart              = [[weapon/laser/small_laser_fire3]],
      soundTrigger            = true,
      texture1                = [[energywave]],
      texture2                = [[null]],
      texture3                = [[null]],
      thickness               = 6,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 200,
    },

  },


  featureDefs         = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[hoverassault_dead.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3c.s3o]],
    },

  },

} }
