unitDef = {
  unitname               = [[spiderassault]],
  name                   = [[Cudgel]],
  description            = [[All Terrain Assault Bot]],
  acceleration           = 0.1137,
  bmcode                 = [[1]],
  brakeRate              = 0.2275,
  buildCostEnergy        = 160,
  buildCostMetal         = 160,
  builder                = false,
  buildPic               = [[spiderassault.png]],
  buildTime              = 160,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[25 38 25]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[cylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_bp = [[Robô assaltante]],
    description_es = [[Robot de Asalto]],
    description_fr = [[Robot d'Assaut]],
    description_it = [[Robot d'assalto]],
    helptext       = [[The Cudgel can take an incredible beating, and is useful as a shield for the weaker, more-damaging Recluses.]],
    helptext_bp    = [[Thug é um robô assaultante. Pode resistir muito dano, e é útil como um escudo para os mais fracos porém mais potentes Recluses.]],
    helptext_es    = [[El Thud es increiblemente resistente, y es útil como esudo para los Recluse que hacen más da?o]],
    helptext_fr    = [[Le Thug est extraordinairement r?sistant pour sa taille. Si ses canons ? plasma n'ont pas la pr?cision requise pour abattre les cibles rapides, il reste n?anmoins un bouclier parfait pour des unit?s moins solides telles que les Recluses.]],
    helptext_it    = [[Il Thud é incredibilmente resistente, ed e utile come scudo per i Recluse che fanno piú danno]],
  },

  defaultmissiontype     = [[Standby]],
  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[spiderassault]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maneuverleashlength    = [[640]],
  mass                   = 175,
  maxDamage              = 1400,
  maxSlope               = 36,
  maxVelocity            = 1.85,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[TKBOT3]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[behecrash.s3o]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:THUDMUZZLE]],
      [[custom:THUDSHELLS]],
      [[custom:THUDDUST]],
    },

  },

  side                   = [[CORE]],
  sightDistance          = 420,
  smoothAnim             = true,
  steeringmode           = [[2]],
  TEDClass               = [[KBOT]],
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 22,
  turninplace            = 0,
  turnRate               = 1099,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[THUD_WEAPON]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    THUD_WEAPON = {
      name                    = [[Light Plasma Cannon]],
      areaOfEffect            = 36,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 140,
        planes  = 140,
        subs    = 7,
      },

      explosionGenerator      = [[custom:MARY_SUE]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      minbarrelangle          = [[-35]],
      noSelfDamage            = true,
      range                   = 350,
      reloadtime              = 3,
      renderType              = 4,
      soundHit                = [[explosion/ex_med5]],
      soundStart              = [[weapon/cannon/cannon_fire5]],
      startsmoke              = [[1]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 250,
    },

  },


  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Cudgel]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 1500,
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
      description      = [[Debris - Cudgel]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1500,
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
      description      = [[Debris - Cudgel]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1500,
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

return lowerkeys({ spiderassault = unitDef })
