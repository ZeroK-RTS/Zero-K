unitDef = {
  unitname            = [[armbrawl]],
  name                = [[Brawler]],
  description         = [[Close Air Support Gunship]],
  acceleration        = 0.24,
  amphibious          = true,
  bankscale           = [[1]],
  bmcode              = [[1]],
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
  canstop             = [[1]],
  canSubmerge         = false,
  category            = [[GUNSHIP]],
  collide             = true,
  corpse              = [[DEAD]],
  cruiseAlt           = 210,

  customParams        = {
    description_bp = [[Aeronave de ataque terrestre]],
    description_fr = [[ADAV d'Assaut Terrestre]],
    helptext       = [[The Brawler is an assault gunship that flies out of the reach of most ground mobiles. It has enough armor to survive limited anti-air fire, and its twin EMGs chew through composite armor as if it were paper.]],
    helptext_bp    = [[Brawler é a aeronave de assalto de Nova. Pode resistir fogo anti-aéreo considerável e destruir rapidamente o inimigo com suas metralhadoras de energia, mas ainda é aconselhável n?o envia-lá diretamente contra fogo anti-aéreo pesado.]],
    helptext_fr    = [[Le Brawler est un ADAV lourd, de par son blondage comme de par le calibre de ses mitrailleuses. Il peut donc résister r des défenses anti air assez longtemps pour s'en débarrasser. Un redoutable ADAV, mais cependant sans défense contre l'air.]],
  },

  defaultmissiontype  = [[VTOL_standby]],
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
  maxDamage           = 2400,
  maxVelocity         = 5.1345,
  minCloakDistance    = 75,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP SUB]],
  objectName          = [[stingray.s3o]],
  scale               = [[1]],
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
  steeringmode        = [[1]],
  TEDClass            = [[VTOL]],
  turnRate            = 792,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[EMG]],
      mainDir            = [[0 -0.35 1]],
      maxAngleDif        = 60,
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
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
        default = 20,
        subs    = 1,
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
      range                   = 420,
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
      featureDead      = [[DEAD2]],
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


    DEAD2 = {
      description      = [[Debris - Brawler]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 2600,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 340,
      object           = [[debris2x2c.s3o]],
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
