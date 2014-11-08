unitDef = {
  unitname               = [[corroach]],
  name                   = [[Roach]],
  description            = [[Crawling Bomb]],
  acceleration           = 0.25,
  activateWhenBuilt      = true,
  brakeRate              = 0.4,
  buildCostEnergy        = 160,
  buildCostMetal         = 160,
  buildPic               = [[CORROACH.png]],
  buildTime              = 160,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  cloakCost              = 0,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[16 16 16]],
  collisionVolumeType	 = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_bp = [[Bomba rastejante]],
    description_es = [[Bomba móvil]],
    description_fr = [[Bombe Rampante]],
    description_it = [[Bomba mobile]],
	description_de = [[Crawling Bombe]],
	description_pl = [[Ruchoma bomba]],
    helptext       = [[This fast-moving suicide unit is very good against massed units, particularly assault tanks. It features a cloaking device which is automatically activated once the unit stands still, effectifely turning it into a mine. Chain explodes terribly, so best not to mass it. Counter with defenders and missile trucks, or single cheap units to set off a premature detonation.]],
    helptext_bp    = [[Essa rápida unidade suicida é muito boa contra unidades agrupadas, particularmente tanques de assalto. Explode em cadeia com muita facilidade, ent?o é melhor n?o agrupalas. Defenda-se com defenders ou caminh?es de mísseis, ou com uma única unidade barata para ativar uma explos?o pre-matura.]],
    helptext_es    = [[Esta rápida unidad suicida es buena contra masas de unidades, especialmente carros armados de asalte. Explotan a cadena terribilmente, asi que es mejor no amasarlas. Contrastalas con torres o carros de misil o síngolas unidades baratas para causar detonaciones inmaduras.]],
    helptext_fr    = [[Le Roach est une unité suicide ultra-rapide. Il est indispensable de savoir la manier pour se débarrasser rapidement des nuées ennemies. Des unités lance-missiles ou tirant avec précision pouront cependant le faire exploser prématurément.]],
    helptext_it    = [[Questa veloce unitá suicida é buona contro unitá ammassate, specialmente carri armati d'assalto. Esplode a catena terribilmente, sicche é meglio non ammassarle. Contrastale con carri o torri lancia-razzi o singole unitá economiche per provocare una detonazione prematura.]],
	helptext_de    = [[Diese flinke Kamikazeeinheit ist effektiv gegen größere Einheiten, besonderns Sturmpanzer. Sie besitzt eine Tarnvorrichting welche automatisch aktiviert wird sobald diese Einheit still steht. Bewahre Abstand zwischen diesen Einheiten, da sie in einer Kettenreaktion explodieren. Der Defender oder Raketenlaster sind effektiv gegen sie. Außerdem auch billige einzelne Einheiten, um eine frühzeitige Explosion zu erwirken.]],
	helptext_pl    = [[Ta szybka jednostka samobojcza swietnie niszczy jednostki w grupach, przede wszystim jednostki szturmowe. Gdy nie porusza sie, wlacza maskowanie, dzieki czemu dziala jak mina. Mozna ja skutecznie zniszczyc celnymi jednostkami lub poswiecic lekka jednostke, aby przedwczesnie sie zdetonowala.]],
	modelradius    = [[7]],
	idle_cloak = 1,
  },

  explodeAs              = [[CORROACH_DEATH]],
  fireState              = 0,
  footprintX             = 1,
  footprintZ             = 1,
  iconType               = [[walkerbomb]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  kamikaze               = true,
  kamikazeDistance       = 80,
  kamikazeUseLOS         = true,
  maxDamage              = 60,
  maxSlope               = 36,
  maxVelocity            = 4,
  maxWaterDepth          = 15,
  minCloakDistance       = 75,
  movementClass          = [[KBOT1]],
  noChaseCategory        = [[FIXEDWING LAND SINK TURRET SHIP SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName             = [[logroach.s3o]],
  pushResistant          = 0,
  script                 = [[corroach.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[CORROACH_DEATH]],
  selfDestructCountdown  = 0,

  sfxtypes               = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
      [[custom:VINDIBACK]],
      [[custom:digdig]],
    },

  },

  sightDistance          = 240,
  turnRate               = 3000,
  
  featureDefs            = {

    DEAD      = {
      description      = [[Wreckage - Roach]],
      blocking         = false,
      damage           = 60,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      metal            = 64,
      object           = [[wreck2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 64,
    },

    HEAP      = {
      description      = [[Debris - Roach]],
      blocking         = false,
      damage           = 60,
      energy           = 0,
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 32,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 32,
    },

  },
}

--------------------------------------------------------------------------------

local weaponDefs = {
  CORROACH_DEATH = {
    areaOfEffect       = 384,
    craterBoost        = 1,
    craterMult         = 3.5,
    edgeEffectiveness  = 0.4,
    explosionGenerator = "custom:ROACHPLOSION",
    explosionSpeed     = 10000,
    impulseBoost       = 0,
    impulseFactor      = 0.3,
    name               = "Explosion",
    soundHit           = "explosion/mini_nuke",
    damage = {
      default          = 1200,
    },
  },
}
unitDef.weaponDefs = weaponDefs

--------------------------------------------------------------------------------
return lowerkeys({ corroach = unitDef })
