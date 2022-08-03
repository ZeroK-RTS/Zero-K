return { hoverheavyraid = {
  unitname            = [[hoverheavyraid]],
  name                = [[Bolas]],
  description         = [[Disruptor Hovercraft]],
  acceleration        = 0.18,
  brakeRate           = 0.516,
  buildCostMetal      = 180,
  builder             = false,
  buildPic            = [[hoverheavyraid.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[HOVER TOOFAST]],
  collisionVolumeOffsets = [[0 -4 0]],
  collisionVolumeScales  = [[22 22 40]],
  collisionVolumeType    = [[cylZ]],
  corpse              = [[DEAD]],

  customParams        = {
    modelradius       = [[25]],
    selection_scale   = 0.85,
    aim_lookahead     = 120,
    turnatfullspeed_hover = [[1]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[hoverraider]],
  maxDamage           = 700,
  maxSlope            = 36,
  maxVelocity         = 3.2,
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
  turnRate            = 848,

  weapons             = {

    {
      def                = [[DISRUPTOR]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    DISRUPTOR      = {
      name                    = [[Disruptor Pulse Beam]],
      areaOfEffect            = 24,
      beamdecay               = 0.9,
      beamTime                = 1/30,
      beamttl                 = 50,
      coreThickness           = 0.25,
      craterBoost             = 0,
      craterMult              = 0,
  
      customParams            = {
        timeslow_damagefactor = 1.667,
        light_camera_height   = 2000,
        light_color           = [[0.85 0.33 1]],
        light_radius          = 120,
      },
      
      damage                  = {
        default = 34,
      },
  
      explosionGenerator      = [[custom:flash2purple]],
      fireStarter             = 30,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 4.33,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 225,
      reloadtime              = 0.3 + 2/30,
      rgbColor                = [[0.3 0 0.4]],
      soundStart              = [[weapon/laser/heavy_laser5]],
      soundStartVolume        = 3,
      soundTrigger            = true,
      sweepfire               = false,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 8,
      tolerance               = 18000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 500,
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
