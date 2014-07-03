unitDef = {
  unitname               = [[shiparty]],
  name                   = [[Crusader]],
  description            = [[Destroyer (Fire Support/Semi-Antisub)]],
  acceleration           = 0.0417,
  activateWhenBuilt      = true,
  brakeRate              = 0.142,
  buildAngle             = 16384,
  buildCostEnergy        = 550,
  buildCostMetal         = 550,
  builder                = false,
  buildPic               = [[armroy.png]],
  buildTime              = 550,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[SHIP]],
  collisionVolumeOffsets = [[0 1 3]],
  collisionVolumeScales  = [[35 35 132]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_fr = [[Destroyer Artillerie/Semi-Anti-Sous-Marins]],
    description_pl = [[Niszczyciel (Artyleria/Przeciw �odziom Podwodnym)]],
    description_de = [[Zerst�rer (Artillerie/Semi-U-Boot-Abwehr]],
    helptext       = [[This Destroyer packs a powerful, long-range main cannon, useful for bombarding fixed emplacements and shore targets, as well as a depth charge launcher for use against submarines. Beware of aircraft and Corvettes--the Destroyer's weapons have trouble hitting fast-moving targets.]],
    helptext_fr    = [[Ce Destroyer embarque un puissant canon longue port?e et un lance grenade sous marines. Utile pour se d?barrasser de menaces sous marines ou de positions fixes, son canon est cependant trop peu pr?cis pour d?truire des menaces rapides.]],
    helptext_pl    = [[Crusader posiada pot�n� armat� �redniego zasi�gu idealn� do bombardowania nieruchomych wie�yczek broni�cych wybrze�y. Jego drug� broni� jest wyrzutnia �adunk�w g��binowych. �atwo pada ofiar� jednostek lataj�cych i korwet, gdy� nie posiada broni skutecznym przeciwko szybkim celom.]],
    helptext_de    = [[Der Zerst�rer kombiniert eine kraftvolle, weitreichende Hauptkanone, n�tzlich f�r das Bombadieren von festen Standorten und K�stenzielen, mit einem Torpedowerfer gegen U-Boote. H�te dich vor Flugzeugen und Korvetten - Zerst�rer haben einige Probleme damit, schnelle Ziele zu treffen.]],
    extradrawrange = 200,
	modelradius    = [[17]],
	turnatfullspeed = [[1]],
  },

  explodeAs              = [[BIG_UNITEX]],
  floater                = true,
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[destroyer]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  mass                   = 320,
  maxDamage              = 1600,
  maxVelocity            = 1.9,
  minCloakDistance       = 75,
  minWaterDepth          = 10,
  movementClass          = [[BOAT4]],
  moveState              = 0,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE]],
  objectName             = [[armroy.s3o]],
  script	    	     = [[shiparty.cob]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],
  side                   = [[ARM]],
  sightDistance          = 660,
  smoothAnim             = true,
  sonarDistance          = 350,
  turninplace            = 0,
  turnRate               = 350,
  waterline              = 0,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[PLASMA]],
      badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SHIP SINK TURRET FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[DEPTHCHARGE]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[SWIM FIXEDWING LAND SUB SINK TURRET FLOAT SHIP GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    DEPTHCHARGE = {
      name                    = [[Depth Charge]],
      areaOfEffect            = 128,
      avoidFriendly           = false,
      collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 180,
      },

      edgeEffectiveness       = 0.6,
      explosionGenerator      = [[custom:TORPEDO_HIT_LARGE]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
	  leadlimit               = 0,
      model                   = [[depthcharge.s3o]],
      noSelfDamage            = true,
      predictBoost            = 1,
      range                   = 260,
      reloadtime              = 3,
      soundHit                = [[explosion/wet/ex_underwater]],
      soundStart              = [[weapon/torpedo]],
      startVelocity           = 50,
      tolerance               = 100000,
      tracks                  = true,
      turnRate                = 20000,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 30,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 150,
    },


    PLASMA      = {
      name                    = [[Plasma Cannon]],
      accuracy                = 100,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 600,
        planes  = 600,
        subs    = 30,
      },

      explosionGenerator      = [[custom:PLASMA_HIT_32]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
	  myGravity               = 0.11,
      noSelfDamage            = true,
      range                   = 950,
      reloadtime              = 4,
	  size                    = 3.8,
      soundHit                = [[weapon/cannon/cannon_hit2]],
      soundStart              = [[weapon/cannon/heavy_cannon]],
      startsmoke              = [[1]],
      targetMoveError         = 0.3,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 250,
    },

  },


  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Crusader]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 1800,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 5,
      footprintZ       = 5,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 220,
      object           = [[armroy_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 220,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

    
    HEAP  = {
      description      = [[Debris - Crusader]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1800,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      hitdensity       = [[100]],
      metal            = 110,
      object           = [[debris4x4b.s3o]],
      reclaimable      = true,
      reclaimTime      = 110,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ shiparty = unitDef })
