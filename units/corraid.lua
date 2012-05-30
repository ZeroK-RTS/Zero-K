unitDef = {
  unitname               = [[corraid]],
  name                   = [[Ravager]],
  description            = [[Assault Vehicle]],
  acceleration           = 0.027,
  brakeRate              = 0.0385,
  buildCostEnergy        = 250,
  buildCostMetal         = 250,
  builder                = false,
  buildPic               = [[corraid.png]],
  buildTime              = 250,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 1 0]],
  collisionVolumeScales  = [[47 36 45]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_bp = [[Veículo de assalto]],
    description_fr = [[Véhicule d'Assaut]],
	description_de = [[Sturmfahrzeug]],
    helptext       = [[Expensive and powerful, the Ravager is capable of holding its own against most opposition. Though its manueverability is terrible, its strength is when moving at a considerable top speed in a straight line. Due to this, it is almost impossible to skirmish using raiders. In combat, you should attempt to keep travelling forward and not turn too suddenly, so as to maintain top speed. Circling your target at the edge of your range is a good tactic. An arcing projectile allows it to shoot over corpses, other tanks, etc. Vulnerable to crawling bombs when in swarms.]],
    helptext_bp    = [[Ravager é um tanque de assalto. Caro mais poderoso, pode lutar eficientemente contra a maioria dos inimigos. ? pouco ágil mas sua velocidade é alta, portanto é recomendável cargar diretamente contra o inimigo, especialmente se forem escaramuçadores or agressores. O ângulo de seus disparos possibilita atirar sobre obstáculos. ? vulnerável a bombas rastejantes.]],
    helptext_fr    = [[Le Ravager est un tank d'assaut. Sont blindage lui permet de faire face r nombre de menaces, et son canon plasma lui permet de tirer au dessus de ses alliés et des carcasses. Son moteur met du temps r atteindre sa vitesse maximale, mais celle ci est assez élevée pour qu'il ne puisse pas se faire harrasser par des tirailleurs qui seront trop occupés r le suivre.  Attention donc, r ne pas lui faire prendre de virages trop secs afin de conserver sa vitesse.]],
	helptext_de    = [[Zwar teuer, aber auch kraftvoll ist der Ravager, der in der Lage ist, sich selbst gegen die meisten Gegner am Leben zu halten. Obwohl seine Manövrierfähigkeit unglaublich schlecht ist, seine Stärke ist sich mit der Maximalgeschwindigkeit geradeaus zu bewegen. Währenddessen ist es fast unmöglich gegen ihn zu kämpfen. Deshalb solltest du auch darauf achten, dass du ihn im Kampf immer geradeaus bewegst. Das Projektil ermöglicht auch den bogenförmigen Beschuß, um z.B. über Wracks oder Einheiten zu schießen. Anfällig gegen Massen von Crawling Bomben.]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[vehicleassault]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  mass                   = 212,
  maxDamage              = 1850,
  maxSlope               = 18,
  maxVelocity            = 2.95,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[TANK3]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[CORRAID.s3o]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
      [[custom:RAIDDUST]],
    },

  },

  side                   = [[CORE]],
  sightDistance          = 385,
  smoothAnim             = true,
  trackOffset            = 6,
  trackStrength          = 5,
  trackStretch           = 1,
  trackType              = [[StdTank]],
  trackWidth             = 30,
  turninplace            = 0,
  turnRate               = 430,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[PLASMA]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    PLASMA = {
      name                    = [[Light Plasma Cannon]],
      areaOfEffect            = 32,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 210,
        planes  = 210,
        subs    = 11.5,
      },

      explosionGenerator      = [[custom:INGEBORG]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 320,
      reloadtime              = 2,
      soundHit                = [[weapon/cannon/cannon_hit2]],
      soundStart              = [[weapon/cannon/medplasma_fire]],
      startsmoke              = [[1]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 230,
    },

  },


  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Ravager]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 1850,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 100,
      object           = [[corraid_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 100,
    },


    HEAP  = {
      description      = [[Debris - Ravager]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1850,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 50,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 50,
    },

  },

}

return lowerkeys({ corraid = unitDef })
