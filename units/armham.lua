unitDef = {
  unitname               = [[armham]],
  name                   = [[Hammer]],
  description            = [[Light Artillery/Skirmisher Bot]],
  acceleration           = 0.25,
  brakeRate              = 0.25,
  buildCostEnergy        = 130,
  buildCostMetal         = 130,
  buildPic               = [[ARMHAM.png]],
  buildTime              = 130,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[29 43 29]],
  collisionVolumeType    = [[cylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_bp = [[Robô de artilharia]],
    description_de = [[Leichter Artillerie/Skirmisher Roboter]],
    description_es = [[Robot de artilleria]],
    description_fi = [[Tykist?/kahakkarobotti]],
    description_fr = [[Robot d'Artillerie]],
    description_it = [[Robot d'artiglieria]],
    description_pl = [[Bot Artyleryjski]],
    helptext       = [[The Hammer has a long range plasma cannon that allows indirect fire over obstacles, and outranges static defenses up to heavy laser towers. Although effective versus mobile units, it should be guarded in order to prevent raiders and other fast units from closing range.]],
    helptext_bp    = [[O hammer ? o rob? b?sico de artilharia de Nova, que tamb?m serve como escaramu?ador. Ele tem um canhao de plasma de longo alcan?e que permite fogo indireto sobre obst?culos, e possui alcan?e superior a defesas fixas b?sicas at? no m?ximo a Torre de laser pesada. Embora efetivo contra unidades m?veis, ? recomend?vel defende-los com warriors para evitar que agressores ou outras unidades r?pidas se aproximem.]],
    helptext_de    = [[Der Hammer besitzt eine weitreichende Plasmakanone, die es ihm erlaubt über Hindernisse zu schießen und sich dabei außer Reichweite von gegnerischen Verteidigungsanlagen zu finden. Obwohl er auch effektiv gegen mobile Einheiten ist, sollte er beschützt werden, um Raider und andere schnelle Einheiten von ihm Fern zu halten.]],
    helptext_es    = [[El Hammer tiene un ca?ón al plasma de largo alcance que le permite hacer fuego indirecto sobre obstáculos. Tiene mayor alcance que defensas básicas hasta la HLT. Aunque es efectivo contra unidades móbiles, es aconsejable defenderlos con warriors para que las unidades de invasión no se acerquen demasiado]],
    helptext_fi    = [[Hammer omaa pitk?n kantaman plasmatykin, joka mahdollistaa ep?suoran tulituksen yksik?iden ylitse. Sen kantama on pidempi, kuin peruspuolustusten aina HLT:hen saakka. Vaikka Hammer on tehokas my?s yksik?it? vastaan, sit? tulee suojata eteenkin nopeasti liikkuvia yksik?it? vastaan, sill? ne pystyv?t v?ist?m??n Hammerin ammukset.]],
    helptext_fr    = [[Le Hammer a un canon plasma longue port?e qui lui permet de tirer indirectement au dessus des obstacles, et a une port?e plus grande que les tour de d?fense basic jusqu'au HLT. Bien qu'il soit ?fficace contre les unit?es mobiles, il est n?c?ssaire de le d?fendre avec des Warriors pour le prot?ger des unit?s rapide et de raid.]],
    helptext_it    = [[Il Hammer ha un cannone al plasma da lungo raggio che gli permette di fare fuoco indiretto sopra ostacoli, ed ha un raggio maggiore di molte difese basiche fino alla HLT. Anche se é efficace contro unitá mobili, é consigliabile difenderli con warriors per prevenire che le unitá da invasione si avvicinino troppo]],
    helptext_pl    = [[Hammer ma działo dalekiego zasięgu, które pozwala mu strzelać nad niskimi przeszkodami i ma większy zasięg niż podstawowe wieżyczki. Choć jest dosyć efektywny przeciwko ruchomym jednostkom, powinno się zapewnić mu ochronę przed lżejszymi jednostkami, które mogą unikać jego powolnych pocisków.]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[kbotarty]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 350,
  maxSlope               = 36,
  maxVelocity            = 1.62,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT2]],
  moveState              = 0,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP]],
  objectName             = [[Milo.s3o]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:THUDMUZZLE]],
      [[custom:THUDSHELLS]],
      [[custom:THUDDUST]],
    },

  },

  sightDistance          = 660,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 22,
  turnRate               = 1500,
  upright                = true,

  weapons                = {

    {
      def                = [[HAMMER_WEAPON]],
      badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SHIP SINK TURRET FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs             = {

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
	  myGravity               = 0.09,
      noSelfDamage            = true,
      range                   = 840,
      reloadtime              = 6,
      soundHit                = [[explosion/ex_med5]],
      soundStart              = [[weapon/cannon/cannon_fire1]],
      targetMoveError         = 0.3,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 260,
    },

  },

  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Hammer]],
      blocking         = true,
      damage           = 350,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 52,
      object           = [[milo_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 52,
    },

    HEAP  = {
      description      = [[Debris - Hammer]],
      blocking         = false,
      damage           = 350,
      energy           = 0,
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 26,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 26,
    },

  },

}

return lowerkeys({ armham = unitDef })
