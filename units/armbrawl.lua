unitDef = {
  unitname            = [[armbrawl]],
  name                = [[Brawler]],
  description         = [[Assault/Skirmish Gunship]],
  acceleration        = 0.24,
  amphibious          = true,
  bankscale           = [[1]],
  brakeRate           = 4.41,
  buildCostEnergy     = 850,
  buildCostMetal      = 850,
  builder             = false,
  buildPic            = [[ARMBRAWL.png]],
  buildTime           = 850,
  canAttack           = true,
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[GUNSHIP]],
  collide             = true,
  collisionVolumeOffsets = [[0 0 -5]],
  collisionVolumeScales  = [[60 20 60]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],
  cruiseAlt           = 210,

  customParams        = {
    airstrafecontrol = [[1]],
    description_bp = [[Aeronave de ataque terrestre]],
    description_fr = [[ADAV d'Assaut Terrestre]],
	description_de = [[Luftnaher Unterstützungskampfhubschrauber]],
	helptext_de    = [[Der Brawler ist eine Angriffseinheit, die den meisten Bodenrakten ausweichen kann. Der Brawler besitzt genug Munition, um begrenztes Anti-Air Feuer zu überleben und seine Zwillings-EMGs zerfetzen die Panzerung als wäre es Papier.]],
    helptext       = [[The Brawler is an assault gunship that flies out of the reach of most ground mobiles. It has enough armor to survive limited anti-air fire, and its twin EMGs chew through composite armor as if it were paper.]],
    helptext_bp    = [[Brawler é a aeronave de assalto de Nova. Pode resistir fogo anti-aéreo considerável e destruir rapidamente o inimigo com suas metralhadoras de energia, mas ainda é aconselhável n?o envia-lá diretamente contra fogo anti-aéreo pesado.]],
    helptext_fr    = [[Le Brawler est un ADAV lourd, de par son blondage comme de par le calibre de ses mitrailleuses. Il peut donc résister r des défenses anti air assez longtemps pour s'en débarrasser. Un redoutable ADAV, mais cependant sans défense contre l'air.]],
	modelradius    = [[10]],
  },

  explodeAs           = [[GUNSHIPEX]],
  floater             = true,
  footprintX          = 3,
  footprintZ          = 3,
  hoverAttack         = true,
  iconType            = [[heavygunship]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[1280]],
  mass                = 322,
  maxDamage           = 2800,
  maxVelocity         = 4,
  minCloakDistance    = 75,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP SUB]],
  objectName          = [[stingray.s3o]],
  script              = [[armbrawl.lua]],
  seismicSignature    = 0,
  selfDestructAs      = [[GUNSHIPEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:brawlermuzzle]],
      [[custom:emg_shells_m]],
    },

  },

  side                = [[ARM]],
  sightDistance       = 480,
  smoothAnim          = true,
  turnRate            = 792,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[EMG]],
      mainDir            = [[0 -0.35 1]],
      maxAngleDif        = 100,
	  badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SHIP SINK TURRET FLOAT GUNSHIP FIXEDWING HOVER]],
    },

  },


  weaponDefs          = {

    EMG = {
      name                    = [[Heavy Pulse MG]],
      areaOfEffect            = 40,
      avoidFeature            = false,
      burst                   = 4,
      burstrate               = 0.1,
      collideFriendly         = false,
      craterBoost             = 0.15,
      craterMult              = 0.3,

      damage                  = {
        default = 21.6,
        subs    = 1.08,
      },

      edgeEffectiveness       = 0.5,
      endsmoke                = [[0]],
      explosionGenerator      = [[custom:EMG_HIT_HE]],
      firestarter             = 70,
      impulseBoost            = 0,
      impulseFactor           = 0.2,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noSelfDamage            = true,
      pitchtolerance          = 12000,
      range                   = 600,
      reloadtime              = 0.45,
      renderType              = 4,
      rgbColor                = [[1 0.95 0.5]],
      soundHit                = [[weapon/cannon/emg_hit]],
      soundStart              = [[weapon/cannon/brawler_emg]],
      sprayAngle              = 1600,
      startsmoke              = [[0]],
      sweepfire               = false,
      tolerance               = 2000,
      turret                  = true,
      weaponTimer             = 1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 450,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Brawler]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 2600,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 340,
      object           = [[brawler_d.s3o]],
      reclaimable      = true,
      reclaimTime      = 340,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

    HEAP  = {
      description      = [[Debris - Brawler]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 2600,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 170,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 170,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armbrawl = unitDef })
