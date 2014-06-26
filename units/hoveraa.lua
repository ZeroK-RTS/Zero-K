unitDef = {
  unitname            = [[hoveraa]],
  name                = [[Flail]],
  description         = [[AA Hover]],
  acceleration        = 0.048,
  brakeRate           = 0.043,
  buildCostEnergy     = 300,
  buildCostMetal      = 300,
  builder             = false,
  buildPic            = [[hoveraa.png]],
  buildTime           = 300,
  canAttack           = true,
  canGuard            = true,
  canHover            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[HOVER]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[40 40 40]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]], 
  corpse              = [[DEAD]],

  customParams        = {
    description_de = [[Fulgabwehrgleiter]],
    description_pl = [[Poduszkowiec przeciwlotniczy]],
    helptext       = [[The Flail launches a single large, short-medium range SAM that does heavy damage.]],
	helptext_de    = [[Der Flail verschie�t ein einzige, gro�e SAM auf mittlerer Distanz, die wirklich gro�en Schaden anrichtet.]],
	helptext_pl    = [[Flail wystrzeliwuje rakiety przeciwlotnicze sredniego zasiegu, ktore zadaja wysokie obrazenia.]],
	modelradius    = [[20]],
	midposoffset   = [[0 8 -5]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[hoveraa]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  mass                = 200,
  maxDamage           = 1300,
  maxSlope            = 36,
  maxVelocity         = 3.54,
  minCloakDistance    = 75,
  movementClass       = [[HOVER3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM LAND SINK TURRET SHIP SATELLITE SWIM FLOAT SUB HOVER]],
  objectName          = [[hoveraa.s3o]],
  onoffable           = true,
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:HEAVYHOVERS_ON_GROUND]],
      [[custom:RAIDMUZZLE]],
    },

  },

  side                = [[CORE]],
  sightDistance       = 660,
  smoothAnim          = true,
  turninplace         = 0,
  turnRate            = 616,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[WEAPON]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs          = {

    WEAPON = {
      name                    = [[Medium SAM]],
      areaOfEffect            = 64,
      canattackground         = false,
      cegTag                  = [[missiletrailbluebig]],
      collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,

	  customParams        	  = {
		isaa = [[1]],
	  },

      damage                  = {
        default = 37.5,
        planes  = 375,
        subs    = 20.625,
      },

      edgeEffectiveness       = 0.5,
      explosionGenerator      = [[custom:STARFIRE]],
      fireStarter             = 100,
      fixedlauncher           = true,
      flighttime              = 6,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[hovermissile.s3o]],
      noautorange             = [[1]],
      noSelfDamage            = true,
      range                   = 800,
      reloadtime              = 5,
      smokedelay              = [[0.1]],
      smokeTrail              = true,
      soundHit                = [[weapon/missile/vlaunch_hit]],
      soundStart              = [[weapon/missile/missile_fire8]],
      startsmoke              = [[1]],
      startvelocity           = 200,
      texture2                = [[AAsmoketrail]],
      tolerance               = 4000,
      tracks                  = true,
      turnRate                = 64000,
      twoPhase                = true,
      vlaunch                 = true,
      weaponAcceleration      = 300,
      weaponTimer             = 1,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 1400,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Flail]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 1600,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 200,
      object           = [[hoveraa_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 200,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Flail]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1600,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      hitdensity       = [[100]],
      metal            = 200,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 200,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Flail]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1600,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      hitdensity       = [[100]],
      metal            = 100,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 100,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ hoveraa = unitDef })
