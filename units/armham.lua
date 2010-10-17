unitDef = {
  unitname            = [[armham]],
  name                = [[Hammer]],
  description         = [[Artillery/Skirmisher Bot]],
  acceleration        = 0.12,
  bmcode              = [[1]],
  brakeRate           = 0.225,
  buildCostEnergy     = 130,
  buildCostMetal      = 130,
  builder             = false,
  buildPic            = [[ARMHAM.png]],
  buildTime           = 130,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    description_bp = [[Robô de artilharia]],
    description_es = [[Robot de artilleria]],
    description_fi = [[Tykist?/kahakkarobotti]],
    description_fr = [[Robot d'Artillerie]],
    description_it = [[Robot d'artiglieria]],
    helptext       = [[The Hammer has a long range plasma cannon that allows indirect fire over obstacles, and outranges basic fixed defense up to HLT. Though effective vs mobile units, it should be defended by Warriors in order to prevent raiders and other fast units from closing range.]],
    helptext_bp    = [[O hammer ? o rob? b?sico de artilharia de Nova, que tamb?m serve como escaramu?ador. Ele tem um canhao de plasma de longo alcan?e que permite fogo indireto sobre obst?culos, e possui alcan?e superior a defesas fixas b?sicas at? no m?ximo a Torre de laser pesada. Embora efetivo contra unidades m?veis, ? recomend?vel defende-los com warriors para evitar que agressores ou outras unidades r?pidas se aproximem.]],
    helptext_es    = [[El Hammer tiene un ca?ón al plasma de largo alcance que le permite hacer fuego indirecto sobre obstáculos. Tiene mayor alcance que defensas básicas hasta la HLT. Aunque es efectivo contra unidades móbiles, es aconsejable defenderlos con warriors para que las unidades de invasión no se acerquen demasiado]],
    helptext_fi    = [[Hammer omaa pitk?n kantaman plasmatykin, joka mahdollistaa ep?suoran tulituksen yksik?iden ylitse. Sen kantama on pidempi, kuin peruspuolustusten aina HLT:hen saakka. Vaikka Hammer on tehokas my?s yksik?it? vastaan, sit? tulee suojata eteenkin nopeasti liikkuvia yksik?it? vastaan, sill? ne pystyv?t v?ist?m??n Hammerin ammukset.]],
    helptext_fr    = [[Le Hammer a un canon plasma longue port?e qui lui permet de tirer indirectement au dessus des obstacles, et a une port?e plus grande que les tour de d?fense basic jusqu'au HLT. Bien qu'il soit ?fficace contre les unit?es mobiles, il est n?c?ssaire de le d?fendre avec des Warriors pour le prot?ger des unit?s rapide et de raid.]],
    helptext_it    = [[Il Hammer ha un cannone al plasma da lungo raggio che gli permette di fare fuoco indiretto sopra ostacoli, ed ha un raggio maggiore di molte difese basiche fino alla HLT. Anche se é efficace contro unitá mobili, é consigliabile difenderli con warriors per prevenire che le unitá da invasione si avvicinino troppo]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[kbotarty]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  maneuverleashlength = [[640]],
  mass                = 114,
  maxDamage           = 350,
  maxSlope            = 36,
  maxVelocity         = 1.72,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[KBOT2]],
  moveState           = 0,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP SUB]],
  objectName          = [[Milo.s3o]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:THUDMUZZLE]],
      [[custom:THUDSHELLS]],
      [[custom:THUDDUST]],
    },

  },

  side                = [[ARM]],
  sightDistance       = 450,
  smoothAnim          = true,
  steeringmode        = [[2]],
  TEDClass            = [[KBOT]],
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ComTrack]],
  trackWidth          = 22,
  turninplace         = 0,
  turnRate            = 500,
  upright             = true,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[HAMMER_WEAPON]],
      badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SHIP SINK FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    HAMMER_WEAPON = {
      name                    = [[Light Plasma Cannon]],
      accuracy                = 350,
      areaOfEffect            = 16,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 150,
        planes  = 150,
        subs    = 7.5,
      },

      edgeEffectiveness       = 0.1,
      explosionGenerator      = [[custom:MARY_SUE]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      minbarrelangle          = [[-35]],
      movingAccuracy          = 1400,
      noSelfDamage            = true,
      range                   = 860,
      reloadtime              = 6,
      renderType              = 4,
      soundHit                = [[explosion/ex_med5]],
      soundStart              = [[weapon/cannon/cannon_fire1]],
      startsmoke              = [[1]],
      targetMoveError         = 0.3,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 350,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Hammer]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 350,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 52,
      object           = [[wreck2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 52,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Hammer]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 350,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 52,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 52,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Hammer]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 350,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 26,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 26,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armham = unitDef })
