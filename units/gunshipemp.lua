return { gunshipemp = {
  unitname            = [[gunshipemp]],
  name                = [[Gnat]],
  description         = [[Anti-Heavy EMP Drone]],
  acceleration        = 0.264,
  brakeRate           = 0.2112,
  buildCostMetal      = 90,
  builder             = false,
  buildPic            = [[gunshipemp.png]],
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[GUNSHIP]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[18 18 18]],
  collisionVolumeType    = [[ellipsoid]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[28 28 28]],
  selectionVolumeType    = [[ellipsoid]],
  collide             = true,
  corpse              = [[DEAD]],
  cruiseAlt           = 78,

  customParams        = {
    airstrafecontrol = [[1]],
    modelradius    = [[9]],
  },

  explodeAs           = [[TINY_BUILDINGEX]],
  floater             = true,
  footprintX          = 2,
  footprintZ          = 2,
  hoverAttack         = true,
  iconType            = [[gunshipscout]],
  maxDamage           = 370,
  maxVelocity         = 7.5,
  noChaseCategory     = [[TERRAFORM SUB UNARMED]],
  objectName          = [[marshmellow.s3o]],
  script              = [[gunshipemp.lua]],
  selfDestructAs      = [[TINY_BUILDINGEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:VINDIBACK]],
    },

  },

  sightDistance       = 380,
  turnRate            = 1144,
  upright             = true,

  weapons             = {

    {
      def                = [[PARALYZER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs          = {

    PARALYZER = {
      name                    = [[Light Electro-Stunner]],
      areaOfEffect            = 8,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      customParams        = {
        combatrange = 70,
        light_camera_height = 1000,
        light_color = [[1 1 0.4]],
        light_radius = 150,
      },

      damage                  = {
        default        = 700,
      },

      duration                = 0.01,
      explosionGenerator      = [[custom:YELLOW_LIGHTNING_BOMB]],
      heightMod               = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 12,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      paralyzer               = true,
      paralyzeTime            = 2, -- was 2.5 but can only be int
      range                   = 160,
      reloadtime              = 1.2,
      rgbColor                = [[1 1 0.25]],
      sprayAngle              = 4500,
      soundStart              = [[weapon/small_lightning]],
      soundTrigger            = false,
      targetborder            = 0.9,
      texture1                = [[lightning]],
      thickness               = 1.2,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[LightningCannon]],
      weaponVelocity          = 800,
    },

  },
    
  featureDefs                   = {

    DEAD = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[gnat_d.dae]],
    },

    HEAP = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris1x1b.s3o]],
    },

  },

} }
