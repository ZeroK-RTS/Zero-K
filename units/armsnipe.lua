unitDef = {
  unitname               = [[armsnipe]],
  name                   = [[Sharpshooter]],
  description            = [[Sniper Walker (Skirmish/Anti-Armor)]],
  acceleration           = 0.12,
  bmcode                 = [[1]],
  brakeRate              = 0.1942,
  buildCostEnergy        = 750,
  buildCostMetal         = 750,
  builder                = false,
  buildPic               = [[ARMSNIPE.png]],
  buildTime              = 750,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  cloakCost              = 1,
  cloakCostMoving        = 5,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[35 64 35]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[CylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_bp = [[Robô Sniper]],
    description_es = [[Caminante tirador]],
    description_fi = [[Tarkka-ampujarobotti]],
    description_fr = [[Marcheur Sniper]],
    description_it = [[Camminatore Cecchino]],
	description_de = [[Scharfschützen Walker (Skirmish/Anti-Rüstung)]],
    helptext       = [[The Sharpshooter's energy rifle inflicts massive damage to a single target. It can fire while cloaked; however its visible round betrays its position. It requires a lot of energy to keep cloaked and fire. The best way to locate a Sharpshooter is by sweeping the area with many scout units.]],
    helptext_bp    = [[Sharpshooter ? uma unidade de artilharia invis?vel a radar e capaz de se camuflar. Pode atirar enquanto camuflado, mas seus tiros vis?veis indicam sua posi?ao. Requer muita energia para manter camuflado e atirando. Quando destru?do, uma onda de PEM paraliza unidades pr?ximas. Usado melhor s?zinho.]],
    helptext_es    = [[El Sharpshooter es una unidad ocultada de artilleria costosa. Puede disparar mientras ocultado, pero la bala visible revela su posición. Necesita mucha energía para disparar mientras ocultado. La mejor manera de encontrar un sharpshooter es de ispeccionar el área con unidades de exploración.]],
    helptext_fi    = [[Kallis, vihollisen tutkaan ilmaantumaton ja n?kym?tt?myyskentt?? hy?dynt?v? Sharpshooter on tehokas erikoisteht?vien yksikk?. Sharpshooterin korkeaenergisen, pitk?n kantaman pulssiplasma-aseen k?ytt?minen sek? n?kym?tt?m?n? pit?minen vaativat paljon energiaa. Tehokkain tapa paikantaa t?m? yksikk? on l?hett?? lukuisia tiedustelijoita alueelle.]],
    helptext_fr    = [[Le Sharpshooter est une unit? d'artillerie furtive, camouflable et coutant tres cher. Il peut faire feu tout en restant camoufl?. Son tir tres visible peut cependant r?veler sa position. La quantit?e d'?nergie qu'il n?cessite pour tirer et rester camoufler en m?me temps est ?lev?e. Sa destruction ?met une onde de choque EMP qui immobilise les unit?s qui se trouve a proximit?. Il est le plus utile en tant que tireur isol?.]],
    helptext_it    = [[Il Sharpshooter é un unita costosa occultata d'artiglieria. Puo sparare mentre é occultata; pero il proiettile visibile tradisce la sua posizione. Richiede molta energia per tenerlo occultato mentre spara. la migliore maniera di trovare un Sharpshooter é di ispezionare l'area con unita di ricognizione]],
	helptext_de    = [[Sein energetisches Gewehr richtet riesigen Schaden bei einzelnen Zielen an. Er kann auch schießen, wenn er getarnt ist. Dennoch verrät ihn sein sichtbarer Schuss. Um getarnt zu bleiben und schießen zu können, benötigt der Scharfschütze eine Menge Energie. Die einfachst Möglichkeit einen Scharfschützen ausfindig zu machen, ist die, indem man ein Gebiet mit vielen Scouteinheiten überschwemmt.]],
  },

  decloakOnFire          = false,
  defaultmissiontype     = [[Standby]],
  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[sniper]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  initCloaked            = true,
  maneuverleashlength    = [[640]],
  mass                   = 245,
  maxDamage              = 560,
  maxSlope               = 36,
  maxVelocity            = 1.7,
  maxWaterDepth          = 22,
  minCloakDistance       = 155,
  movementClass          = [[KBOT2]],
  moveState              = 0,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP SUB]],
  objectName             = [[sharpshooter.s3o]],
  radarDistanceJam       = 10,
  seismicSignature       = 16,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:WEAPEXP_PUFF]],
      [[custom:MISSILE_EXPLOSION]],
    },

  },

  side                   = [[ARM]],
  sightDistance          = 400,
  smoothAnim             = true,
  steeringmode           = [[2]],
  TEDClass               = [[KBOT]],
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 22,
  turninplace            = 0,
  turnRate               = 1338,
  upright                = true,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[SHOCKRIFLE]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    SHOCKRIFLE = {
      name                    = [[Pulsed Particle Projector]],
      areaOfEffect            = 16,
      colormap                = [[0 0 0 0   0 0 0.2 0.2   0 0 0.5 0.5   0 0 0.7 0.7   0 0 1 1   0 0 1 1]],
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 1500,
        planes  = 1500,
        subs    = 75,
      },

      explosionGenerator      = [[custom:megapartgun]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noSelfDamage            = true,
      range                   = 700,
      reloadtime              = 15,
      renderType              = 4,
      rgbColor                = [[1 0.2 0.2]],
      separation              = 0.5,
      size                    = 5,
      sizeDecay               = 0,
      soundHit                = [[weapon/laser/heavy_laser6]],
      soundStart              = [[weapon/gauss_fire]],
      startsmoke              = [[1]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 1000,
    },

  },


  featureDefs            = {

    DEAD = {
      description      = [[Wreckage - Sharpshooter]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 560,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 300,
      object           = [[sharpshooter_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 300,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP = {
      description      = [[Debris - Sharpshooter]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 560,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 150,
      object           = [[debris2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 150,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armsnipe = unitDef })
