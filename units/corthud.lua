unitDef = {
  unitname            = [[corthud]],
  name                = [[Thug]],
  description         = [[Shielded Assault Bot]],
  acceleration        = 0.114,
  activateWhenBuilt   = true,
  bmcode              = [[1]],
  brakeRate           = 0.2275,
  buildCostEnergy     = 160,
  buildCostMetal      = 160,
  builder             = false,
  buildPic            = [[CORTHUD.png]],
  buildTime           = 160,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    description_bp = [[Robô assaltante]],
    description_fr = [[Robot d'Assaut]],
    helptext       = [[Weak on its own, the Thug makes an excellent screen for Outlaws and Rogues. The linking shield gives Thugs strength in numbers, but can be defeated by AoE weapons or focus fire.]],
    helptext_bp    = [[Thug é um robô assaultante. Pode resistir muito dano, e é útil como um escudo para os mais fracos porém mais potentes Rogues.]],
    helptext_fr    = [[Le Thug est extraordinairement r?sistant pour sa taille. Si ses canons ? plasma n'ont pas la pr?cision requise pour abattre les cibles rapides, il reste n?anmoins un bouclier parfait pour des unit?s moins solides telles que les Rogues.]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[walkerassault]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  maneuverleashlength = [[640]],
  mass                = 147,
  maxDamage           = 800,
  maxSlope            = 36,
  maxVelocity         = 1.925,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[KBOT2]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[thud.s3o]],
  onoffable           = true,
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:THUDMUZZLE]],
      [[custom:THUDSHELLS]],
      [[custom:THUDDUST]],
    },

  },

  side                = [[CORE]],
  sightDistance       = 420,
  smoothAnim          = true,
  steeringmode        = [[2]],
  TEDClass            = [[KBOT]],
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ComTrack]],
  trackWidth          = 22,
  turninplace         = 0,
  turnRate            = 1099,
  upright             = true,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[THUD_WEAPON]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def = [[SHIELD]],
    },

  },


  weaponDefs          = {

    SHIELD      = {
      name                    = [[Energy Shield]],
      craterMult              = 0,

      damage                  = {
        default = 10,
      },

      exteriorShield          = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      isShield                = true,
      shieldAlpha             = 0.4,
      shieldBadColor          = [[1 0.1 0.1]],
      shieldGoodColor         = [[0.1 0.1 1]],
      shieldInterceptType     = 3,
      shieldPower             = 1000,
      shieldPowerRegen        = 11,
      shieldPowerRegenEnergy  = 0,
      shieldRadius            = 80,
      shieldRepulser          = false,
      shieldStartingPower     = 600,
      smartShield             = true,
      texture1                = [[wakelarge]],
      visibleShield           = true,
      visibleShieldHitFrames  = 4,
      visibleShieldRepulse    = true,
      weaponType              = [[Shield]],
    },


    THUD_WEAPON = {
      name                    = [[Light Plasma Cannon]],
      areaOfEffect            = 36,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 150,
        planes  = 150,
        subs    = 7.5,
      },

      explosionGenerator      = [[custom:MARY_SUE]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      minbarrelangle          = [[-35]],
      noSelfDamage            = true,
      range                   = 280,
      reloadtime              = 4,
      renderType              = 4,
      soundHit                = [[explosion/ex_med5]],
      soundStart              = [[weapon/cannon/cannon_fire5]],
      startsmoke              = [[1]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 200,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Thug]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 700,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 64,
      object           = [[thug_d.s3o]],
      reclaimable      = true,
      reclaimTime      = 64,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Thug]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 700,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 64,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 64,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Thug]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 700,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 32,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 32,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ corthud = unitDef })
