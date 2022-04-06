return { hoversonic = {
  unitname            = [[hoversonic]],
  name                = [[Morningstar]],
  description         = [[Antisub Hovercraft]],
  acceleration        = 0.24,
  activateWhenBuilt   = true,
  brakeRate           = 0.43,
  buildCostMetal      = 300,
  builder             = false,
  buildPic            = [[hoversonic.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[HOVER]],
  corpse              = [[DEAD]],

  customParams        = {
    modelradius    = [[25]],
    turnatfullspeed_hover = [[1]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[hoverassault]],
  maxDamage           = 900,
  maxSlope            = 36,
  maxVelocity         = 3,
  movementClass       = [[HOVER3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[hovershotgun.s3o]],
  script              = [[hovershotgun.cob]],
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:HEAVYHOVERS_ON_GROUND]],
      [[custom:RAIDMUZZLE]],
    },

  },
  sightDistance       = 385,
  turninplace         = 0,
  turnRate            = 985,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[SONICGUN]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SUB SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs          = {
  
    SONICGUN         = {
        name                    = [[Sonic Blaster]],
        areaOfEffect            = 70,
        avoidFeature            = true,
        avoidFriendly           = true,
        burnblow                = true,
        craterBoost             = 0,
        craterMult              = 0,

        customParams            = {
            slot = [[5]],
            muzzleEffectFire = [[custom:HEAVY_CANNON_MUZZLE]],
            miscEffectFire   = [[custom:RIOT_SHELL_L]],
            lups_explodelife = 1.5,
            lups_explodespeed = 0.44,
        },

        damage                  = {
            default = 175,
            planes  = 175,
        },
        
        cegTag                  = [[sonictrail]],
        explosionGenerator      = [[custom:sonic]],
        edgeEffectiveness       = 0.75,
        fireStarter             = 150,
        impulseBoost            = 60,
        impulseFactor           = 0.5,
        interceptedByShieldType = 1,
        noSelfDamage            = true,
        range                   = 303,
        reloadtime              = 1.1,
        soundStart              = [[weapon/sonicgun2]],
        soundHit                = [[weapon/sonicgun_hit]],
        soundStartVolume        = 6,
        soundHitVolume          = 10,
        texture1                = [[sonic_glow]],
        texture2                = [[null]],
        texture3                = [[null]],
        rgbColor                = {0, 0.5, 1},
        thickness               = 20,
        corethickness           = 1,
        turret                  = true,
        weaponType              = [[LaserCannon]],
        weaponVelocity          = 700,
        waterweapon             = true,
        duration                = 0.15,
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
