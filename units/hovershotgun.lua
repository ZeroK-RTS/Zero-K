return { hovershotgun = {
  unitname            = [[hovershotgun]],
  name                = [[Punisher]],
  description         = [[Shotgun Hover]],
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
      def                = [[SHOTGUN]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs          = {
  
   SHOTGUN = {
    name                    = [[Shotgun]],
    areaOfEffect            = 32,
    burst                   = 4,
    burstRate               = 0.033,
    coreThickness           = 0.5,
    craterBoost             = 0,
    craterMult              = 0,
    
    customParams            = {
        muzzleEffectFire = [[custom:HEAVY_CANNON_MUZZLE]],
        miscEffectFire = [[custom:RIOT_SHELL_L]],
    },
    
    damage                  = {
        default = 32,
        planes  = 32,
    },
    
    duration                = 0.02,
    explosionGenerator      = [[custom:BEAMWEAPON_HIT_YELLOW]],
    fireStarter             = 50,
    heightMod               = 1,
    impulseBoost            = 0,
    impulseFactor           = 0.4,
    interceptedByShieldType = 1,
    noSelfDamage            = true,
    projectiles             = 4,
    range                   = 235,
    reloadtime              = 3,
    rgbColor                = [[1 1 0]],
    soundHit                = [[weapon/laser/lasercannon_hit]],
    soundStart              = [[weapon/cannon/cannon_fire4]],
    soundStartVolume        = 0.6,
    soundTrigger            = true,
    sprayangle              = 2400,
    thickness               = 2,
    tolerance               = 10000,
    turret                  = true,
    weaponType              = [[LaserCannon]],
    weaponVelocity          = 880,
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
