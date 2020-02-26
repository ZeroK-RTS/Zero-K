return { hoverheavyraid = {
  unitname            = [[hoverheavyraid]],
  name                = [[Cestus]],
  description         = [[Heavy Attack Hovercraft]],
  acceleration        = 0.15,
  brakeRate           = 0.43,
  buildCostMetal      = 200,
  builder             = false,
  buildPic            = [[hoverheavyraid.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[HOVER]],
  collisionVolumeOffsets = [[0 0 2]],
  collisionVolumeScales  = [[27 27 45]],
  collisionVolumeType    = [[cylZ]],
  corpse              = [[DEAD]],

  customParams        = {
    modelradius    = [[25]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[hoverraider]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maxDamage           = 720,
  maxSlope            = 36,
  maxVelocity         = 3.1,
  minCloakDistance    = 75,
  movementClass       = [[HOVER3]],
  noChaseCategory     = [[TERRAFORM FIXEDWING SUB]],
  objectName          = [[hoverskirm.s3o]],
  script              = [[hoverheavyraid.lua]],
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:HOVERS_ON_GROUND]],
      [[custom:RAIDMUZZLE]],
      [[custom:flashmuzzle1]],
    },

  },

  sightDistance       = 560,
  sonarDistance       = 560,
  turninplace         = 0,
  turnRate            = 560,

  weapons             = {

    {
      def                = [[PARTICLEBEAM]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    PARTICLEBEAM = {
      name                    = [[Auto Particle Beam]],
      beamDecay               = 0.85,
      beamTime                = 1/30,
      beamttl                 = 45,
      coreThickness           = 0.3,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        light_color = [[0.9 0.22 0.22]],
        light_radius = 80,
      },

      damage                  = {
        default = 40.01,
        subs    = 2,
      },

      explosionGenerator      = [[custom:flash1red]],
      fireStarter             = 100,
      impactOnly              = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      laserFlareSize          = 5.5,
      minIntensity            = 1,
      range                   = 240,
      reloadtime              = 0.2 + 2/30,
      rgbColor                = [[1 0 0]],
      soundStart              = [[weapon/laser/mini_laser]],
      soundStartVolume        = 3,
      thickness               = 2.5,
      tolerance               = 8192,
      turret                  = true,
      weaponType              = [[BeamLaser]],
    },

  },

  featureDefs         = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[hoverskirm_dead.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
