unitDef = {
  unitname            = [[faith]],
  name                = [[Faith]],
  description         = [[Mobile Antinuke Shield]],
  acceleration        = 0.12,
  activateWhenBuilt   = true,
  bmcode              = [[1]],
  brakeRate           = 0.15,
  buildCostEnergy     = 1800,
  buildCostMetal      = 1800,
  builder             = false,
  buildPic            = [[faith.png]],
  buildTime           = 1800,
  canAttack           = false,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[LAND UNARMED]],
  corpse              = [[DEAD]],

  customParams        = {
    description_bp = [[Robô gerador de escudo]],
    description_fr = [[Marcheur Bouclier]],
    helptext_bp    = [[]],
    helptext_fr    = [[Le Aspis est un g?n?rateur ? bouclier d?flecteur portatif capable de prot?ger vos troupes. Le bouclier n'utilisera votre ?nergie que si il est pris pour cible par des tirs ennemis, la zone du bouclier est r?duite et le Aspis n'est pas solide. Malgr? ses d?faut il reste indispensable pour prot?ger vos unit?s les plus fragiles, comme l'artillerie.]],
  },

  defaultmissiontype  = [[Standby]],
  energyUse           = 1.5,
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[antinuke.dds]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[640]],
  mass                = 600,
  maxDamage           = 1200,
  maxSlope            = 36,
  maxVelocity         = 2.05,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[KBOT2]],
  moveState           = 0,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK]],
  objectName          = [[faith.s3o]],
  onoffable           = true,
  pushResistant       = 1,
  script              = [[faith.lua]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],
  
  sfxtypes            = {

    explosiongenerators = {
      [[custom:riotball]],
	  [[custom:megapartgun]],
    },

  },
  
  side                = [[ARM]],
  sightDistance       = 300,
  smoothAnim          = true,
  steeringmode        = [[1]],
  TEDClass            = [[KBOT]],
  turninplace         = 0,
  turnRate            = 900,
  upright             = true,
  workerTime          = 0,

  weapons             = {

    {
      def = [[NUCLEARSHIELD]],
    },

  },


  weaponDefs          = {

    NUCLEARSHIELD = {
      name                    = [[Anti-Nuclear Shield]],
      craterMult              = 0,

      damage                  = {
        default = 10,
      },

      exteriorShield          = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      isShield                = true,
      shieldAlpha             = 0.05,
      shieldBadColor          = [[1 0.1 0.1]],
      shieldGoodColor         = [[0.1 0.1 1]],
      shieldInterceptType     = 64,
      shieldPower             = 15000,
	  shieldStartingPower	  = 15000,
      shieldPowerRegen        = 1000,
      shieldPowerRegenEnergy  = 10,
      shieldRadius            = 1280,
      shieldRepulser          = false,
      smartShield             = true,
      texture1                = [[wake]],
      visibleShield           = true,
      visibleShieldHitFrames  = 4,
      visibleShieldRepulse    = true,
      weaponType              = [[Shield]],
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Faith]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 1200,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 1,
      footprintZ       = 1,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 720,
      object           = [[debris1x1a.s3o]],
      reclaimable      = true,
      reclaimTime      = 720,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Faith]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1200,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 1,
      footprintZ       = 1,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 720,
      object           = [[debris1x1a.s3o]],
      reclaimable      = true,
      reclaimTime      = 720,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Faith]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1200,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 1,
      footprintZ       = 1,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 360,
      object           = [[debris1x1a.s3o]],
      reclaimable      = true,
      reclaimTime      = 360,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ faith = unitDef })
