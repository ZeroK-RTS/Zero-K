unitDef = {
  unitname               = [[core_spectre]],
  name                   = [[Aspis]],
  description            = [[Linkable Shield Walker]],
  acceleration           = 0.12,
  activateWhenBuilt      = true,
  bmcode                 = [[1]],
  brakeRate              = 0.16,
  buildCostEnergy        = 480,
  buildCostMetal         = 480,
  builder                = false,
  buildPic               = [[core_spectre.png]],
  buildTime              = 480,
  canAttack              = false,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND UNARMED]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[34 39 29]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[box]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_bp = [[Robô gerador de escudo]],
    description_fr = [[Marcheur Bouclier]],
    helptext_bp    = [[]],
    helptext_fr    = [[Le Aspis est un g?n?rateur ? bouclier d?flecteur portatif capable de prot?ger vos troupes. Le bouclier n'utilisera votre ?nergie que si il est pris pour cible par des tirs ennemis, la zone du bouclier est r?duite et le Aspis n'est pas solide. Malgr? ses d?faut il reste indispensable pour prot?ger vos unit?s les plus fragiles, comme l'artillerie.]],
  },

  defaultmissiontype     = [[Standby]],
  designation            = [[UV-2-AB]],
  energyUse              = 1.5,
  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[walkershield]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  maneuverleashlength    = [[640]],
  mass                   = 212,
  maxDamage              = 700,
  maxSlope               = 36,
  maxVelocity            = 1.8567826125,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT2]],
  moveState              = 0,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK]],
  objectName             = [[m-8.s3o]],
  onoffable              = true,
  pushResistant          = 1,
  script                 = [[core_spectre.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],
  shootme                = [[1]],
  side                   = [[Core]],
  sightDistance          = 300,
  smoothAnim             = true,
  steeringmode           = [[1]],
  TEDClass               = [[KBOT]],
  turninplace            = 0,
  turnRate               = 1047,
  upright                = false,
  workerTime             = 0,

  weapons                = {

    {
      def = [[COR_SHIELD_SMALL]],
    },

  },


  weaponDefs             = {

    COR_SHIELD_SMALL = {
      name                    = [[Energy Shield]],
      craterMult              = 0,

      damage                  = {
        default = 10,
      },

      exteriorShield          = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      isShield                = true,
      shieldAlpha             = 0.1,
      shieldBadColor          = [[1 0.1 0.1]],
      shieldGoodColor         = [[0.1 0.1 1]],
      shieldInterceptType     = 3,
      shieldPower             = 3500,
      shieldPowerRegen        = 60,
      shieldPowerRegenEnergy  = 12,
      shieldRadius            = 350,
      shieldRepulser          = false,
      smartShield             = true,
      texture1                = [[wake]],
      visibleShield           = true,
      visibleShieldHitFrames  = 4,
      visibleShieldRepulse    = true,
      weaponType              = [[Shield]],
    },

  },


  featureDefs            = {

    DEAD = {
      description      = [[Wreckage - Aspis]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 700,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 1,
      footprintZ       = 1,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 192.4,
      object           = [[debris1x1a.s3o]],
      reclaimable      = true,
      reclaimTime      = 192.4,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP = {
      description      = [[Debris - Aspis]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 700,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 1,
      footprintZ       = 1,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 96.2,
      object           = [[debris1x1a.s3o]],
      reclaimable      = true,
      reclaimTime      = 96.2,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ core_spectre = unitDef })
