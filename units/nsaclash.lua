unitDef = {
  unitname            = [[nsaclash]],
  name                = [[Scalpel]],
  description         = [[Skirmisher Hover (Anti-Heavy)]],
  acceleration        = 0.0435,
  activateWhenBuilt   = true,
  brakeRate           = 0.205,
  buildCostEnergy     = 220,
  buildCostMetal      = 220,
  builder             = false,
  buildPic            = [[nsaclash.png]],
  buildTime           = 220,
  canAttack           = true,
  canGuard            = true,
  canHover            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[HOVER]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[38 38 38]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]], 
  corpse              = [[DEAD]],

  customParams        = {
    description_bp = [[Hovercraft escaramuçador]],
    description_de = [[Skirmisher Gleiter (Anti-Heavy)]],
    description_fr = [[Hovercraft Tirailleur]],
    description_pl = [[Poduszkowiec harcownik]],
    helptext       = [[Use the Scalpel for hit-and-run attacks. Has a long reload time and not too many hit points, and should always be kept at range with the enemy. An arcing projectile allows it to shoot over obstacles and friendly units.]],
    helptext_de    = [[Nutze den Scalpel für Schlag-und-Renn Attacken. Er hat eine lange Nachladezeit und nicht allzu viele Lebenspunkte. Er sollte immer auf Distanz zum Feind gehalten werden. Die bogenförmige Schussbahn ermöglicht es über Hindernisse und freundliche Einheiten zu schießen.]],
    helptext_bp    = [[Scalpel é um escaramuçador: Use-o para ataques de bater e correr. Demora para recarregar e n?o é muito resistente, devendo sempre ser mantido a distância do inimigo. Seus projéteis de trajetória curva superam obstáculos.]],
    helptext_fr    = [[Le Scalpel est un tirailleur, il est utile pour harrasser l'ennemi ? l'aide de son lance roquette. Il tire des roquettes ? t?te chercheuse au dessus des obstacles, mais son temps de rechargement, sa maniabilit? et son faible blindage le rendent vuln?rable aux contre attaques.]],
    helptext_pl    = [[Scalpel najlepiej nadaje sie do atakow nekajacych. Dlugi czas przeladowania i niska wytrzymalosc powoduja, ze wymaga ochrony i poswiecenia uwagi, by nie zblizal sie zbytnio do wrogich jednostek. Zakrzywiona trajektoria pociskow pozwala Scalpelowi na strzelanie ponad przeszkodami i sojuszniczymi jednostkami.]],
	modelradius    = [[19]],
	turnatfullspeed = [[1]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[hoverskirm]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  mass                = 153,
  maxDamage           = 680,
  maxSlope            = 18,
  maxVelocity         = 2.1,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[HOVER3]],
  moveState           = 0,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE SUB]],
  objectName          = [[nsaclash.s3o]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:HEAVYHOVERS_ON_GROUND]],
      [[custom:JANUSMUZZLE]],
      [[custom:JANUSBACK]],
    },

  },

  side                = [[ARM]],
  sightDistance       = 484,
  sonarDistance       = 300,
  smoothAnim          = true,
  turninplace         = 0,
  turnRate            = 480,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[MISSILE]],
	  badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER SUB]],
    },

  },


  weaponDefs          = {

    MISSILE = {
      name                    = [[Heavy Missile Battery]],
      areaOfEffect            = 96,
      cegTag                  = [[missiletrailyellow]],
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 310,
      },

      fireStarter             = 70,
      fixedlauncher           = true,
      flightTime              = 3.5,
      impulseBoost            = 0.75,
      impulseFactor           = 0.3,
      interceptedByShieldType = 2,
	  leadlimit               = 0,
      model                   = [[wep_m_dragonsfang.s3o]],
      projectiles             = 2,
      range                   = 450,
      reloadtime              = 10,
      selfprop                = true,
      smokedelay              = [[.1]],
      smokeTrail              = true,
      soundHit                = [[explosion/ex_med5]],
      soundHitVolume          = 8,
      soundStart              = [[weapon/missile/rapid_rocket_fire2]],
      soundStartVolume        = 7,
      startsmoke              = [[1]],
      startVelocity           = 190,
      texture2                = [[lightsmoketrail]],
      tracks                  = true,
      trajectoryHeight        = 0.4,
      turnRate                = 24000,
      turret                  = true,
      weaponAcceleration      = 90,
      weaponTimer             = 3,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 200,
    },
	
  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Scalpel]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 620,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 88,
      object           = [[nsaclash_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 88,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Scalpel]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 620,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 88,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 88,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Scalpel]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 620,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 44,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 44,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ nsaclash = unitDef })
