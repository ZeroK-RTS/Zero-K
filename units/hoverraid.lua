return { hoverraid = {
  unitname            = [[hoverraid]],
  name                = [[Dagger]],
  description         = [[Fast Attack Hovercraft]],
  acceleration        = 0.33,
  activateWhenBuilt   = true,
  brakeRate           = 0.835,
  buildCostMetal      = 80,
  builder             = false,
  buildPic            = [[hoverraid.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[HOVER]],
  collisionVolumeOffsets = [[0 -2 0]],
  collisionVolumeScales  = [[19 19 36]],
  collisionVolumeType    = [[cylZ]],
  corpse              = [[DEAD]],

  customParams        = {
    modelradius    = [[25]],
  },

  explodeAs           = [[SMALL_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[hoverraider]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maxDamage           = 300,
  maxSlope            = 36,
  maxVelocity         = 4.8,
  minCloakDistance    = 75,
  movementClass       = [[HOVER2]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SUB]],
  objectName          = [[corsh.s3o]],
  script              = [[hoverraid.lua]],
  selfDestructAs      = [[SMALL_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:HOVERS_ON_GROUND]],
      [[custom:flashmuzzle1]],
    },

  },

  sightDistance       = 640,
  sonarDistance       = 640,
  turninplace         = 0,
  turnRate            = 673,
  workerTime          = 0,
  
  weapons             = {

    {
      def                = [[GAUSS]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SUB SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    GAUSS = {
      name                    = [[Gauss Cannon]],
      alphaDecay              = 0.12,
      areaOfEffect            = 16,
      avoidfeature            = false,
      bouncerebound           = 0.15,
      bounceslip              = 1,
      burst                   = 1,
      cegTag                  = [[gauss_tag_l]],
      craterBoost             = 0,
      craterMult              = 0,

      customParams = {
        burst = Shared.BURST_RELIABLE,

        single_hit = true,
        
        light_camera_height = 1200,
        light_radius = 180,
      },
      
      damage                  = {
        default = 95.01,
      },
      
      explosionGenerator      = [[custom:gauss_hit_l]],
      groundbounce            = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      leadLimit               = 0,
      noExplode               = true,
      noSelfDamage            = true,
      numbounce               = 40,
      range                   = 210,
      reloadtime              = 3,
      rgbColor                = [[0.5 1 1]],
      separation              = 0.5,
      size                    = 0.8,
      sizeDecay               = -0.1,
      soundHit                = [[weapon/gauss_hit]],
      soundHitVolume          = 2.5,
      soundStart              = [[weapon/gauss_fire]],
      soundTrigger            = true,
      soundStartVolume        = 2,
      sprayangle              = 400,
      stages                  = 32,
      turret                  = true,
      waterweapon             = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 2200,
    },

  },

  featureDefs         = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[corsh_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3c.s3o]],
    },

  },

} }
