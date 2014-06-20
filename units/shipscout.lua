unitDef = {
  unitname               = [[shipscout]],
  name                   = [[Skeeter]],
  description            = [[Patrol Boat (Scout/Raider)]],
  acceleration           = 0.0984,
  activateWhenBuilt      = true,
  brakeRate              = 0.0475,
  buildCostEnergy        = 70,
  buildCostMetal         = 70,
  builder                = false,
  buildPic               = [[ARMPT.png]],
  buildTime              = 70,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[SHIP]],
  collisionVolumeOffsets = [[0 3 0]],
  collisionVolumeScales  = [[24 24 65]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_de = [[Wachboot (Scout/Raider)]],
    description_fr = [[Navire de Patrouille Éclaireur et Anti-Air]],
    description_pl = [[Łódź Patrolowa]],
    helptext       = [[Cheap, fast, and fragile, this Patrol Boat is good as a raider and spotting for longer-ranged ships. It lacks the firepower or armor for brawling.]],
    helptext_de    = [[Günstig, schnell und gebrechlich. Dieses Wachboot eignet sich gut als Raider und zum Auskundschaften von Schiffen mit größerer Reichweite. Zum Kämpfen fehlt es ihm an Feuerkraft und der nötigen Panzerung.]],
    helptext_fr    = [[Pas cher, rapide et peu solide, voici venir le Skeeter et ses canons laser. Utile en début de conflit ou en tant qu'éclaireur son blindage le rends trcs vite obsolcte.]],
    helptext_pl    = [[Lekki i szybki, Skeeter jest dobrym zwiadowcą dla większych okrętów. Nie ma jednak wytrzymałości ani siły ognia potrzebnych do dłuższej walki.]],
    modelradius    = [[12]],
	turnatfullspeed = [[1]],
  },

  explodeAs              = [[SMALL_UNITEX]],
  floater                = true,
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[scoutboat]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  maxDamage              = 240,
  maxVelocity            = 5,
  minCloakDistance       = 75,
  minWaterDepth          = 5,
  movementClass          = [[BOAT3]],
  moveState              = 0,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE SUB]],
  objectName             = [[scoutboat.s3o]],
  script				 = [[shipscout.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[SMALL_UNITEX]],

  sfxtypes                      = {
  
    explosiongenerators = {
      [[custom:PULVMUZZLE]],
    },

  },
  
  side                   = [[ARM]],
  sightDistance          = 800,
  sonarDistance          = 300,
  turninplace            = 0,
  turnRate               = 698,
  waterline              = 2,
  workerTime             = 0,

  weapons                = {
  
    {
      def                = [[FAKEWEAPON]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 60,
    },
	
    {
      def                = [[MISSILE]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP LAND SINK TURRET SHIP SWIM FLOAT HOVER]],
    },

  },


  weaponDefs             = {

    FAKEWEAPON = {
      name                    = [[Fake Missile]],
      areaOfEffect            = 8,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting      = 1,

      damage                  = {
        default = 0,
      },

      explosionGenerator      = [[custom:FLASH2]],
      fireStarter             = 70,
      fixedlauncher           = true,
      flightTime              = 4,
      heightmod               = 0.5,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 2,
      model                   = [[wep_m_fury.s3o]],
      range                   = 230,
      reloadtime              = 2,
      smokedelay              = [[0.1]],
      smokeTrail              = true,
      startsmoke              = [[1]],
      startVelocity           = 300,
      tolerance               = 10000,
      tracks                  = true,
      trajectoryHeight        = 1.2,
      turnRate                = 60000,
      turret                  = true,
      weaponAcceleration      = 350,
      weaponTimer             = 5,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 750,
    },


    MISSILE   = {
      name                    = [[Light Disarm Missile]],
      areaOfEffect            = 8,
	  --burst					  = 2,
	  --burstRate				  = 0.4,
	  cegTag                  = [[disarmtrail]],
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting      = 1,

      damage                  = {
        default = 45,
        planes  = 45,
        subs    = 5,
      },

	  customParams        = {
	    disarmDamageMult = 4,
		disarmDamageOnly = 0,
		disarmTimer      = 3, -- seconds
	  },

      explosionGenerator      = [[custom:FLASH2]],
      fireStarter             = 70,
      fixedlauncher           = true,
      flightTime              = 4,
      heightmod               = 0.5,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_armpt.s3o]],
      range                   = 260,
      reloadtime              = 2,
      smokedelay              = [[0.1]],
      smokeTrail              = true,
      soundHit                = [[weapon/missile/rocket_hit]],
      soundStart              = [[weapon/missile/missile_fire7]],
      startsmoke              = [[1]],
      startVelocity           = 100,
	  texture2                = [[lightsmoketrail]],
      tolerance               = 10000,
      tracks                  = true,
      turnRate                = 60000,
      turret                  = true,
      weaponAcceleration      = 300,
      weaponTimer             = 5,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 800,
    },

  },


  featureDefs            = {

    DEAD = {
      description      = [[Wreckage - Skeeter]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 240,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 28,
      object           = [[scoutboat_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 28,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

    HEAP = {
      description      = [[Debris - Skeeter]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 240,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      hitdensity       = [[100]],
      metal            = 14,
      object           = [[debris4x4a.s3o]],
      reclaimable      = true,
      reclaimTime      = 14,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ shipscout = unitDef })
