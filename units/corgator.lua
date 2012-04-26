unitDef = {
  unitname               = [[corgator]],
  name                   = [[Scorcher]],
  description            = [[Raider Vehicle]],
  acceleration           = 0.057,
  brakeRate              = 0.07,
  buildCostEnergy        = 130,
  buildCostMetal         = 130,
  builder                = false,
  buildPic               = [[corgator.png]],
  buildTime              = 130,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 1 0]],
  collisionVolumeScales  = [[33 23 42]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_bp = [[Veículo escaramuçador]],
    description_fr = [[V?hicule Pilleur]],
	description_de = [[Raiderfahrzeug]],
    helptext       = [[Capable of taking damage and dishing it out, the Scorcher is a versatile unit that remains very useful for more than just raiding, though it pays the price in manueverability and in cost. Its regeneration dramatically decreases its losses vs inferior opposition- it is impossible to kill the scorcher with attrition. Though able to hold its own in combat, it is no match for anti-swarm or riot units or defenses.]],
    helptext_bp    = [[Scorcher é um tanque agressor. ? capaz de aguentar dano considerável e muito versátil, mas n?o t?o ágil quanto outras unidades agressoras. Sua regeneraç?o rápida lhe dá vantagem em pequenos combates onde estiver em maior número. Embora capaz em combate, n?o é pareo para unidades e defesas dispersadoras.]],
    helptext_fr    = [[Le Scorcher est rapide et solide. ?quip? d'une mitrailleuse laser il saura faire face de lui m?me ? un combat et ses nano-robots auto r?g?nerants se chargeront de le remettre sur pied pour la suite. Particuli?rement allergique aux anti-nu?es et au ?meutiers.]],
	helptext_de    = [[Der Scorcher ist fähig Schaden zukassieren und auch auszuteilen, was ihn zu einer vielseitigen Einheit macht, welche für mehr als nur zum Raiden nützlich ist, all dies aber zum Preis der Manövrierfähigkeit und der Kosten. Seine Regeneration verringert die Häufigkeit der Verlust gegen unterlegene Einheiten enorm - es ist unmöglich den Scorcher mit Zeitschaden zu besiegen. Obwohl er sich im Kampf meist selbsterhalten kann, taugt er nichts gegen größere Gruppen, Rioteinheiten oder gegen Verteidigung.]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[vehicleraider]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  mass                   = 118,
  maxDamage              = 420,
  maxSlope               = 18,
  maxVelocity            = 3.7,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[TANK2]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[corgator_512.s3o]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:BEAMWEAPON_MUZZLE_ORANGE_SMALL]],
    },

  },

  side                   = [[CORE]],
  sightDistance          = 400,
  smoothAnim             = true,
  trackOffset            = 5,
  trackStrength          = 5,
  trackStretch           = 1,
  trackType              = [[StdTank]],
  trackWidth             = 21,
  turninplace            = 0,
  turnRate               = 703,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[HEATRAY]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    HEATRAY = {
      name                    = [[Heat Ray]],
      accuracy                = 512,
      areaOfEffect            = 20,
      beamWeapon              = true,
      cegTag                  = [[HEATRAY_CEG]],
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 30.1,
        planes  = 30.1,
        subs    = 1.5,
      },

      duration                = 0.3,
      dynDamageExp            = 1,
      dynDamageInverted       = false,
      explosionGenerator      = [[custom:HEATRAY_HIT]],
      fallOffRate             = 1,
      fireStarter             = 90,
      heightMod               = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      lodDistance             = 10000,
      noSelfDamage            = true,
      proximityPriority       = 4,
      range                   = 310,
      reloadtime              = 0.1,
      renderType              = 0,
      rgbColor                = [[1 0.1 0]],
      rgbColor2               = [[1 1 0.25]],
      soundStart              = [[weapon/heatray_fire]],
      thickness               = 3,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 500,
    },

  },


  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Scorcher]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 420,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 52,
      object           = [[gatorwreck.s3o]],
      reclaimable      = true,
      reclaimTime      = 52,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Scorcher]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 420,
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
      description      = [[Debris - Scorcher]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 420,
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

return lowerkeys({ corgator = unitDef })
