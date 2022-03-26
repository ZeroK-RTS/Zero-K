return { hoverskirm2 = {
  unitname            = [[hoverskirm2]],
  name                = [[Trisula]],
  description         = [[Light Assault/Battle Hovercraft]],
  acceleration        = 0.15,
  brakeRate           = 0.43,
  buildCostMetal      = 180,
  builder             = false,
  buildPic            = [[hoverskirm2.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[HOVER]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[50 25 50]],
  collisionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],

  customParams        = {
    modelradius    = [[25]],
    turnatfullspeed_hover = [[1]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[hoverskirm]],
  maxDamage           = 1300,
  maxSlope            = 36,
  maxVelocity         = 2.5,
  movementClass       = [[HOVER2]],
  noChaseCategory     = [[TERRAFORM FIXEDWING SUB]],
  objectName          = [[hoverskirm.s3o]],
  onoffable           = true,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:HEAVYHOVERS_ON_GROUND]],
      [[custom:RAIDMUZZLE]],
      [[custom:flashmuzzle1]],
    },

  },

  sightDistance       = 450,
  turninplace         = 0,
  turnRate            = 800,

  weapons             = {

    {
      def                = [[SCATTER_LASER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    SCATTER_LASER = {
      name                    = [[Scatter Beam]],
      areaOfEffect            = 32,
      beamDecay               = 0.85,
      beamTime                = 1/30,
      beamttl                 = 45,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 40,
      },

      explosionGenerator      = [[custom:flash1red]],
      fireStarter             = 100,
      --impactOnly              = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      laserFlareSize          = 7.5,
      minIntensity            = 1,
      projectiles             = 9,
      range                   = 360,
      reloadtime              = 4,
      rgbColor                = [[1 0 0]],
      soundStart              = [[weapon/laser/mini_laser]],
      sprayangle              = 1640,
      thickness               = 4,
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
