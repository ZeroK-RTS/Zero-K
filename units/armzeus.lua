unitDef = {
  unitname               = [[armzeus]],
  name                   = [[Zeus]],
  description            = [[Assault/Battle Walker]],
  acceleration           = 0.2,
  brakeRate              = 0.2,
  buildCostEnergy        = 350,
  buildCostMetal         = 350,
  builder                = false,
  buildPic               = [[ARMZEUS.png]],
  buildTime              = 350,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[48 62 48]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_bp = [[Robô de assalto]],
    description_es = [[Caminante de Asalto]],
    description_fi = [[Rynn?kk?robotti]],
    description_fr = [[Marcheur d'Assaut]],
    description_it = [[Camminatore d'Assalto]],
	description_de = [[Sturm-/Kampfroboter]],
    helptext       = [[Slowly and steadily, groups of Zeuses can shrug off heavy fire as they make their way towards enemy fortifications, until they can field their short-range lightning cannon, which damages and stuns entrenched foes. Counter with anything that can reliably kite it, making sure that you don't get paralyzed (in which case you are as good as dead.)]],
    helptext_bp    = [[Zeus ? o principal rob? de assalto de Nova. Devagar e sempre, grupos de Zeus podem resistir fogo pesado a medida que avan?am contra fortifica?oes inimigas, at? poderem atirar seu canhao de raios de curto-alcan?e, que danifica e paraliza inimigos.]],
    helptext_es    = [[Lentamente, grupos de Zeus pueden soportar fuogo pesado mientras caminan hacia las fortificaciones enemigas, hasta che pueden usar su ca?on de rayos, que da?a y paraliza los enemigos atrincherados. Contrastalos con qualquier unidad che puede mantenerse fuera de su alcance, y no te dejes paralizar (que si pasa eres muerto.)]],
    helptext_fi    = [[Hitaasti mutta varmasti etenev? Zeus kest?? vihollisen tulitusta kohtuullisesti. Sen lyhyen kantaman tesla-ase halvaannuttaa ja vaurioittaa kohteensa tehokkaasti.]],
    helptext_fr    = [[Lentement mais surement, un groupe de Zeus peut encaisser les tirs enemis lourd jusqu'a ce qu'ils atteignent les fortifications et puissent utiliser leur canon éclair courte portée qui peut paralyser et endommager les enemis retranchés.]],
    helptext_it    = [[Lentamente, gruppi di Zeus possono sopportare fuoco pesante mentre camminano verso le fortificazioni nemiche, fino a che possono usare il loro cannone spara-fulmini a corto raggio, che danneggia e paralizza i nemici trincerati. Contrastali con qualunque cosa che puo tenersi fuori dal loro raggio, stando sicuro di non essere paralizzato (in quel caso sei morto.)]],
	helptext_de    = [[Langsam und zuverlässig, Gruppen von Zeus' können sogar starken Beschuss ignorieren und so schnell an die feindliche Festung herankommen, bis sie dort ihre Blitzschlagkanonen mit kurzer Reichweite zum Einsatz bringen können, welche feindliche Einheiten schädigt und betäubt. Kontere den Zeus mit Einheiten, die umherflitzen, damit sie nicht paralysiert werden (denn dann sind sie so gut wie tot).]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[kbotassault]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
   mass                   = 248,
  maxDamage              = 2400,
  maxSlope               = 36,
  maxVelocity            = 1.7,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  modelCenterOffset      = [[0 0 4]],
  movementClass          = [[KBOT2]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[spherezeus.s3o]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:zeusmuzzle]],
      [[custom:zeusgroundflash]],
    },

  },

  side                   = [[ARM]],
  sightDistance          = 325,
  smoothAnim             = true,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 26,
  turnRate               = 1400,
  upright                = true,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[LIGHTNING]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    LIGHTNING = {
      name                    = [[Lightning Gun]],
      areaOfEffect            = 8,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        extra_damage = [[240]],
      },

      cylinderTargetting      = 0,

      damage                  = {
        default        = 600,
        empresistant75 = 150,
        empresistant99 = 6,
      },

      duration                = 10,
      explosionGenerator      = [[custom:LIGHTNINGPLOSION]],
      fireStarter             = 50,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 12,
      interceptedByShieldType = 1,
      paralyzer               = true,
      paralyzeTime            = 1,
      range                   = 280,
      reloadtime              = 2.2,
      rgbColor                = [[0.5 0.5 1]],
      soundStart              = [[weapon/more_lightning]],
      soundTrigger            = true,
      startsmoke              = [[1]],
      targetMoveError         = 0.3,
      texture1                = [[lightning]],
      thickness               = 10,
      turret                  = true,
      waterweapon             = false,
      weaponType              = [[LightningCannon]],
      weaponVelocity          = 400,
    },

  },


  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Zeus]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 2400,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 140,
      object           = [[spherezeus_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 140,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Zeus]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 2400,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 70,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 70,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armzeus = unitDef })
