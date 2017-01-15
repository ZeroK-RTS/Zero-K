unitDef = {
  unitname            = [[tawf114]],
  name                = [[Banisher]],
  description         = [[Heavy Riot Support Tank]],
  acceleration        = 0.02181,
  brakeRate           = 0.04282,
  buildCostEnergy     = 520,
  buildCostMetal      = 520,
  builder             = false,
  buildPic            = [[TAWF114.png]],
  buildTime           = 520,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    description_fr = [[Tank Lance-Missile Lourd]],
	description_de = [[Schwerer Riot Unterstützungspanzer]],
    helptext       = [[Remarkably mobile for a riot platform, the Banisher packs twin high-velocity fragmentation missiles that are devastating to light units and aircraft alike, although they have limited range. Like other riot units, the Banisher does not have the range and speed to hold its own against most skirmishers. The missile is quite effective at flattening terrain so it is particularly useful at knocking down walls that Welders cannot reach.]],
    helptext_fr    = [[Les Banishers sont arm?s de deux lance-missiles lourds ? t?te chercheuse. Capable d'attaquer les cibles au sol ou dans les airs, ils font d'?normes d?g?ts, mais sont lent a recharger. Impuissant contre les nu?es d'ennemis et indispensable contre les grosses cibles, son blindage ne lui permet pas d'?tre en premi?re ligne.]],
	helptext_de    = [[Erstaunlich beweglich für eine Rioteinheit. Der Banisher ist mit Zwillings-Hochgeschwindigkeits Splitterraketen ausgerüstet, die verheerend für leichte Einheiten und Lufteinheiten sind, obwohl sie nur eine begrenzte Reichweite haben. Der Banisher wird schnell von Sturmeinheiten überrascht und sogar von Raider, weshalb du ihn mit deinen Abschirmungseinheiten beschützen musst. Anders als andere Rioteinheiten besitzt der Banisher die nötige Geschwindigkeit und Reichweite, um sich gegen die meisten Skirmishern zu halten.]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[tankriot]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  maxDamage           = 1650,
  maxSlope            = 18,
  maxVelocity         = 2.3,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[TANK4]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE SUB]],
  objectName          = [[corbanish.s3o]],
  script              = [[tawf114.lua]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],
  sightDistance       = 400,
  trackOffset         = 8,
  trackStrength       = 10,
  trackStretch        = 1,
  trackType           = [[StdTank]],
  trackWidth          = 48,
  turninplace         = 0,
  turnRate            = 355,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[TAWF_BANISHER]],
      mainDir            = [[0 0 1]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    TAWF_BANISHER = {
      name                    = [[Heavy Missile]],
      areaOfEffect            = 160,
	  cegTag                  = [[BANISHERTRAIL]],
      craterBoost             = 1,
      craterMult              = 2,

	  customParams            = {
	    gatherradius = [[120]],
	    smoothradius = [[80]],
	    smoothmult   = [[0.25]],
		
		light_color = [[1.4 1 0.7]],
		light_radius = 320,
	  },
	  
      damage                  = {
        default = 440.5,
        subs    = 22,
      },

      edgeEffectiveness       = 0.4,
      explosionGenerator      = [[custom:xamelimpact]],
      fireStarter             = 20,
      flightTime              = 4,
      impulseBoost            = 0,
      impulseFactor           = 0.6,
      interceptedByShieldType = 2,
      model                   = [[corbanishrk.s3o]],
      noSelfDamage            = true,
      range                   = 340,
      reloadtime              = 2.3,
      smokeTrail              = false,
      soundHit                = [[weapon/bomb_hit]],
      soundStart              = [[weapon/missile/banisher_fire]],
      startVelocity           = 400,
      tolerance               = 9000,
      tracks                  = true,
      trajectoryHeight        = 0.45,
      turnRate                = 22000,
      turret                  = true,
      weaponAcceleration      = 70,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 400,
    },

  },


  featureDefs         = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[corbanish_dead.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3a.s3o]],
    },

  },

}

return lowerkeys({ tawf114 = unitDef })
